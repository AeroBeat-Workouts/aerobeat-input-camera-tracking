#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import random
from datetime import datetime, timezone
from pathlib import Path

from boxing_classifier_harness import (
    PUNCH_CLASS_ORDER,
    apply_standardization,
    classification_metrics,
    compute_standardization,
    flatten_frames,
    format_confusion_markdown,
    load_json,
    write_json,
)


class TinyTemporalCNN:
    def __init__(
        self,
        input_channels: int,
        time_steps: int,
        conv1_channels: int,
        conv2_channels: int,
        kernel_size: int,
        output_dim: int,
        seed: int,
    ) -> None:
        if kernel_size % 2 == 0:
            raise ValueError("kernel_size must be odd for same-padding conv")
        rng = random.Random(seed)
        self.input_channels = input_channels
        self.time_steps = time_steps
        self.conv1_channels = conv1_channels
        self.conv2_channels = conv2_channels
        self.kernel_size = kernel_size
        self.output_dim = output_dim
        self.padding = kernel_size // 2
        self.head_input_dim = time_steps * conv2_channels

        init_c1 = math.sqrt(6.0 / float((input_channels + conv1_channels) * kernel_size))
        init_c2 = math.sqrt(6.0 / float((conv1_channels + conv2_channels) * kernel_size))
        init_fc = math.sqrt(6.0 / float(self.head_input_dim + output_dim))

        self.conv1_w = [
            [[rng.uniform(-init_c1, init_c1) for _ in range(kernel_size)] for _ in range(input_channels)]
            for _ in range(conv1_channels)
        ]
        self.conv1_b = [0.0 for _ in range(conv1_channels)]
        self.conv2_w = [
            [[rng.uniform(-init_c2, init_c2) for _ in range(kernel_size)] for _ in range(conv1_channels)]
            for _ in range(conv2_channels)
        ]
        self.conv2_b = [0.0 for _ in range(conv2_channels)]
        self.fc_w = [[rng.uniform(-init_fc, init_fc) for _ in range(self.head_input_dim)] for _ in range(output_dim)]
        self.fc_b = [0.0 for _ in range(output_dim)]

    def _conv1d_same(self, sequence: list[list[float]], weights: list[list[list[float]]], bias: list[float]) -> list[list[float]]:
        time_steps = len(sequence)
        in_channels = len(sequence[0]) if sequence else 0
        out_channels = len(weights)
        outputs = [[0.0 for _ in range(out_channels)] for _ in range(time_steps)]
        for t in range(time_steps):
            for out_channel in range(out_channels):
                total = bias[out_channel]
                kernel_bank = weights[out_channel]
                for in_channel in range(in_channels):
                    kernel = kernel_bank[in_channel]
                    for kernel_offset in range(self.kernel_size):
                        source_t = t + kernel_offset - self.padding
                        if source_t < 0 or source_t >= time_steps:
                            continue
                        total += sequence[source_t][in_channel] * kernel[kernel_offset]
                outputs[t][out_channel] = total
        return outputs

    def forward(self, frames: list[list[float]]) -> dict:
        conv1_pre = self._conv1d_same(frames, self.conv1_w, self.conv1_b)
        conv1_act = [[value if value > 0.0 else 0.0 for value in row] for row in conv1_pre]
        conv2_pre = self._conv1d_same(conv1_act, self.conv2_w, self.conv2_b)
        conv2_act = [[value if value > 0.0 else 0.0 for value in row] for row in conv2_pre]
        flattened = []
        for row in conv2_act:
            flattened.extend(row)
        logits = []
        for output_index in range(self.output_dim):
            total = self.fc_b[output_index]
            weights = self.fc_w[output_index]
            for feature_index in range(self.head_input_dim):
                total += weights[feature_index] * flattened[feature_index]
            logits.append(total)
        return {
            "input": frames,
            "conv1_pre": conv1_pre,
            "conv1_act": conv1_act,
            "conv2_pre": conv2_pre,
            "conv2_act": conv2_act,
            "flattened": flattened,
            "logits": logits,
        }

    @staticmethod
    def softmax(logits: list[float]) -> list[float]:
        max_logit = max(logits)
        exps = [math.exp(value - max_logit) for value in logits]
        total = sum(exps)
        return [value / total for value in exps]

    def predict_proba(self, frames: list[list[float]]) -> list[float]:
        return self.softmax(self.forward(frames)["logits"])

    def train_batch(self, features: list[list[list[float]]], labels: list[int], lr: float, weight_decay: float) -> float:
        grad_conv1_w = [
            [[0.0 for _ in range(self.kernel_size)] for _ in range(self.input_channels)]
            for _ in range(self.conv1_channels)
        ]
        grad_conv1_b = [0.0 for _ in range(self.conv1_channels)]
        grad_conv2_w = [
            [[0.0 for _ in range(self.kernel_size)] for _ in range(self.conv1_channels)]
            for _ in range(self.conv2_channels)
        ]
        grad_conv2_b = [0.0 for _ in range(self.conv2_channels)]
        grad_fc_w = [[0.0 for _ in range(self.head_input_dim)] for _ in range(self.output_dim)]
        grad_fc_b = [0.0 for _ in range(self.output_dim)]
        total_loss = 0.0

        for frames, label_index in zip(features, labels):
            cache = self.forward(frames)
            probabilities = self.softmax(cache["logits"])
            total_loss += -math.log(max(probabilities[label_index], 1e-12))

            delta_logits = [probability for probability in probabilities]
            delta_logits[label_index] -= 1.0
            for output_index in range(self.output_dim):
                grad_fc_b[output_index] += delta_logits[output_index]
                for feature_index in range(self.head_input_dim):
                    grad_fc_w[output_index][feature_index] += delta_logits[output_index] * cache["flattened"][feature_index]

            delta_flattened = [0.0 for _ in range(self.head_input_dim)]
            for feature_index in range(self.head_input_dim):
                downstream = 0.0
                for output_index in range(self.output_dim):
                    downstream += self.fc_w[output_index][feature_index] * delta_logits[output_index]
                delta_flattened[feature_index] = downstream

            time_steps = len(cache["conv2_act"]) if cache["conv2_act"] else 1
            delta_conv2_act = []
            flat_index = 0
            for _ in range(time_steps):
                row = []
                for _ in range(self.conv2_channels):
                    row.append(delta_flattened[flat_index])
                    flat_index += 1
                delta_conv2_act.append(row)
            delta_conv2_pre = [[0.0 for _ in range(self.conv2_channels)] for _ in range(time_steps)]
            for t in range(time_steps):
                for out_channel in range(self.conv2_channels):
                    if cache["conv2_pre"][t][out_channel] > 0.0:
                        delta_conv2_pre[t][out_channel] = delta_conv2_act[t][out_channel]

            delta_conv1_act = [[0.0 for _ in range(self.conv1_channels)] for _ in range(time_steps)]
            for t in range(time_steps):
                for out_channel in range(self.conv2_channels):
                    delta = delta_conv2_pre[t][out_channel]
                    if delta == 0.0:
                        continue
                    grad_conv2_b[out_channel] += delta
                    for in_channel in range(self.conv1_channels):
                        kernel = self.conv2_w[out_channel][in_channel]
                        for kernel_offset in range(self.kernel_size):
                            source_t = t + kernel_offset - self.padding
                            if source_t < 0 or source_t >= time_steps:
                                continue
                            grad_conv2_w[out_channel][in_channel][kernel_offset] += delta * cache["conv1_act"][source_t][in_channel]
                            delta_conv1_act[source_t][in_channel] += delta * kernel[kernel_offset]

            delta_conv1_pre = [[0.0 for _ in range(self.conv1_channels)] for _ in range(time_steps)]
            for t in range(time_steps):
                for out_channel in range(self.conv1_channels):
                    if cache["conv1_pre"][t][out_channel] > 0.0:
                        delta_conv1_pre[t][out_channel] = delta_conv1_act[t][out_channel]

            for t in range(time_steps):
                for out_channel in range(self.conv1_channels):
                    delta = delta_conv1_pre[t][out_channel]
                    if delta == 0.0:
                        continue
                    grad_conv1_b[out_channel] += delta
                    for in_channel in range(self.input_channels):
                        kernel = self.conv1_w[out_channel][in_channel]
                        for kernel_offset in range(self.kernel_size):
                            source_t = t + kernel_offset - self.padding
                            if source_t < 0 or source_t >= time_steps:
                                continue
                            grad_conv1_w[out_channel][in_channel][kernel_offset] += delta * cache["input"][source_t][in_channel]

        batch_size = float(len(features)) if features else 1.0
        for out_channel in range(self.conv1_channels):
            for in_channel in range(self.input_channels):
                for kernel_offset in range(self.kernel_size):
                    grad = (grad_conv1_w[out_channel][in_channel][kernel_offset] / batch_size) + (weight_decay * self.conv1_w[out_channel][in_channel][kernel_offset])
                    self.conv1_w[out_channel][in_channel][kernel_offset] -= lr * grad
            self.conv1_b[out_channel] -= lr * (grad_conv1_b[out_channel] / batch_size)

        for out_channel in range(self.conv2_channels):
            for in_channel in range(self.conv1_channels):
                for kernel_offset in range(self.kernel_size):
                    grad = (grad_conv2_w[out_channel][in_channel][kernel_offset] / batch_size) + (weight_decay * self.conv2_w[out_channel][in_channel][kernel_offset])
                    self.conv2_w[out_channel][in_channel][kernel_offset] -= lr * grad
            self.conv2_b[out_channel] -= lr * (grad_conv2_b[out_channel] / batch_size)

        for output_index in range(self.output_dim):
            for feature_index in range(self.head_input_dim):
                grad = (grad_fc_w[output_index][feature_index] / batch_size) + (weight_decay * self.fc_w[output_index][feature_index])
                self.fc_w[output_index][feature_index] -= lr * grad
            self.fc_b[output_index] -= lr * (grad_fc_b[output_index] / batch_size)
        return total_loss / batch_size

    def to_json(self) -> dict:
        return {
            "input_channels": self.input_channels,
            "conv1_channels": self.conv1_channels,
            "conv2_channels": self.conv2_channels,
            "kernel_size": self.kernel_size,
            "time_steps": self.time_steps,
            "head_input_dim": self.head_input_dim,
            "output_dim": self.output_dim,
            "conv1_w": self.conv1_w,
            "conv1_b": self.conv1_b,
            "conv2_w": self.conv2_w,
            "conv2_b": self.conv2_b,
            "fc_w": self.fc_w,
            "fc_b": self.fc_b,
        }


def reshape_standardized_frames(flat_vectors: list[list[float]], frame_count: int, frame_feature_count: int) -> list[list[list[float]]]:
    shaped = []
    expected_dim = frame_count * frame_feature_count
    for vector in flat_vectors:
        if len(vector) != expected_dim:
            raise ValueError(f"expected standardized vector dim {expected_dim}, got {len(vector)}")
        frames = []
        for frame_index in range(frame_count):
            start = frame_index * frame_feature_count
            end = start + frame_feature_count
            frames.append([float(value) for value in vector[start:end]])
        shaped.append(frames)
    return shaped


def _validate_dataset_schema(dataset: dict) -> tuple[str, list[str], list[str]]:
    feature_set = str(dataset.get("feature_set", "baseline_v1"))
    frame_feature_names = [str(name) for name in dataset.get("frame_feature_names", [])]
    side_feature_names = [str(name) for name in dataset.get("side_feature_names", [])]
    frame_feature_count = int(dataset.get("frame_feature_count", 0))
    if frame_feature_names and len(frame_feature_names) != frame_feature_count:
        raise ValueError(f"dataset frame_feature_names length {len(frame_feature_names)} != frame_feature_count {frame_feature_count}")
    if side_feature_names and frame_feature_names and frame_feature_names != [f"left_{name}" for name in side_feature_names] + [f"right_{name}" for name in side_feature_names]:
        raise ValueError("dataset side/frame feature metadata mismatch")
    for sample in dataset.get("samples", []):
        sample_feature_names = [str(name) for name in sample.get("feature_names", [])]
        if frame_feature_names and sample_feature_names and sample_feature_names != frame_feature_names:
            raise ValueError(f"sample {sample.get('sample_id', '<unknown>')} feature_names mismatch dataset frame_feature_names")
        if frame_feature_count and int(sample.get("frame_feature_count", 0)) != frame_feature_count:
            raise ValueError(f"sample {sample.get('sample_id', '<unknown>')} frame_feature_count mismatch dataset frame_feature_count")
        if feature_set and str(sample.get("feature_set", feature_set)) != feature_set:
            raise ValueError(f"sample {sample.get('sample_id', '<unknown>')} feature_set mismatch dataset feature_set")
    return feature_set, side_feature_names, frame_feature_names


def _records_from_predictions(samples: list[dict], predicted_labels: list[str]) -> list[dict]:
    return [
        {
            "sample_id": sample["sample_id"],
            "split": sample["split"],
            "actual": sample["label"],
            "predicted": predicted_label,
        }
        for sample, predicted_label in zip(samples, predicted_labels)
    ]


def _load_threshold_records(samples: list[dict]) -> list[dict]:
    return [
        {
            "sample_id": sample["sample_id"],
            "split": sample["split"],
            "actual": sample["label"],
            "predicted": sample["threshold_baseline"]["predicted_label"],
        }
        for sample in samples
    ]


def _render_markdown(summary: dict) -> str:
    cnn_metrics = summary["temporal_cnn"]["test_metrics"]
    mlp_metrics = summary["mlp_baseline"]["test_metrics"]
    threshold_metrics = summary["threshold_baseline"]["test_metrics"]
    split_strategy = str(summary.get("split_strategy", "unknown"))
    lines = [
        "# Boxing Punch Classifier 1D Temporal CNN Baseline",
        "",
        f"- Trained at: `{summary['trained_at']}`",
        f"- Dataset: `{summary['dataset_path']}`",
        f"- MLP baseline: `{summary['mlp_baseline_path']}`",
        f"- Split strategy: `{split_strategy}`",
        f"- Model shape: `{summary['temporal_cnn']['model_shape']}`",
        f"- Epochs: **{summary['temporal_cnn']['epochs']}**",
        f"- Learning rate: **{summary['temporal_cnn']['learning_rate']}**",
        f"- Weight decay: **{summary['temporal_cnn']['weight_decay']}**",
        "",
        "## Test split comparison",
        "",
        f"- Temporal CNN accuracy: **{cnn_metrics['accuracy']:.3f}**",
        f"- Temporal CNN macro F1: **{cnn_metrics['macro_f1']:.3f}**",
        f"- Temporal MLP accuracy: **{mlp_metrics['accuracy']:.3f}**",
        f"- Temporal MLP macro F1: **{mlp_metrics['macro_f1']:.3f}**",
        f"- Threshold baseline accuracy: **{threshold_metrics['accuracy']:.3f}**",
        f"- Threshold baseline macro F1: **{threshold_metrics['macro_f1']:.3f}**",
        "",
        "## Temporal CNN confusion (test)",
        "",
        *format_confusion_markdown(cnn_metrics["confusion"], summary["class_order"]),
        "",
        "## Temporal MLP confusion (test)",
        "",
        *format_confusion_markdown(mlp_metrics["confusion"], summary["class_order"]),
        "",
        "## Threshold confusion (test)",
        "",
        *format_confusion_markdown(threshold_metrics["confusion"], summary["class_order"]),
        "",
        "## Notes",
        "",
        "- This is only a fixture-local same-harness directional comparison. Do not read it as real-world punch generalization.",
        (
            "- This run uses the hardened `chronological_holdout_v1` split rather than the earlier same-clip interleaved split."
            if split_strategy == "chronological_holdout_v1"
            else "- If you compare against older first-pass artifacts, remember those earlier runs used a leakier same-clip interleaved split."
        ),
        "- Compare models fairly inside the committed export protocol used for this dataset/snapshot.",
    ]
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Train and evaluate a tiny 1D temporal CNN boxing punch classifier baseline.")
    parser.add_argument("--dataset", required=True, help="Path to dataset.json produced by export_boxing_punch_classifier_dataset.py")
    parser.add_argument("--mlp-result", required=True, help="Path to mlp-result.json for apples-to-apples comparison output")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--conv1-channels", type=int, default=12)
    parser.add_argument("--conv2-channels", type=int, default=12)
    parser.add_argument("--kernel-size", type=int, default=3)
    parser.add_argument("--epochs", type=int, default=500)
    parser.add_argument("--learning-rate", type=float, default=0.02)
    parser.add_argument("--weight-decay", type=float, default=0.0005)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    dataset_path = Path(args.dataset).resolve()
    mlp_result_path = Path(args.mlp_result).resolve()
    dataset = load_json(dataset_path)
    mlp_result = load_json(mlp_result_path)
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    feature_set, side_feature_names, frame_feature_names = _validate_dataset_schema(dataset)
    samples = dataset["samples"]
    label_to_index = {label: idx for idx, label in enumerate(PUNCH_CLASS_ORDER)}
    frame_count = int(dataset.get("window_frame_count", 0))
    frame_feature_count = int(dataset.get("frame_feature_count", 0))

    train_samples = [sample for sample in samples if sample["split"] == "train"]
    test_samples = [sample for sample in samples if sample["split"] == "test"]
    train_flat = [flatten_frames(sample["frames"]) for sample in train_samples]
    test_flat = [flatten_frames(sample["frames"]) for sample in test_samples]
    means, stds = compute_standardization(train_flat)
    train_flat = apply_standardization(train_flat, means, stds)
    test_flat = apply_standardization(test_flat, means, stds)
    train_frames = reshape_standardized_frames(train_flat, frame_count, frame_feature_count)
    test_frames = reshape_standardized_frames(test_flat, frame_count, frame_feature_count)
    train_labels = [label_to_index[sample["label"]] for sample in train_samples]
    test_labels = [label_to_index[sample["label"]] for sample in test_samples]

    model = TinyTemporalCNN(
        input_channels=frame_feature_count,
        time_steps=frame_count,
        conv1_channels=args.conv1_channels,
        conv2_channels=args.conv2_channels,
        kernel_size=args.kernel_size,
        output_dim=len(PUNCH_CLASS_ORDER),
        seed=args.seed,
    )
    epoch_losses = []
    for _ in range(args.epochs):
        epoch_losses.append(model.train_batch(train_frames, train_labels, lr=args.learning_rate, weight_decay=args.weight_decay))

    def predict_labels(frame_batches: list[list[list[float]]]) -> list[str]:
        predictions = []
        for frames in frame_batches:
            probabilities = model.predict_proba(frames)
            best_index = max(range(len(probabilities)), key=lambda idx: probabilities[idx])
            predictions.append(PUNCH_CLASS_ORDER[best_index])
        return predictions

    train_predictions = predict_labels(train_frames)
    test_predictions = predict_labels(test_frames)
    train_records = _records_from_predictions(train_samples, train_predictions)
    test_records = _records_from_predictions(test_samples, test_predictions)
    threshold_train_records = _load_threshold_records(train_samples)
    threshold_test_records = _load_threshold_records(test_samples)

    summary = {
        "schema": "aerobeat.boxing_punch_classifier_temporal_cnn_result",
        "version": 1,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "dataset_path": dataset_path.as_posix(),
        "mlp_baseline_path": mlp_result_path.as_posix(),
        "class_order": list(PUNCH_CLASS_ORDER),
        "split_strategy": str(dataset.get("split_strategy", "unknown")),
        "dataset_window_shape": {
            "frame_count": frame_count,
            "frame_feature_count": frame_feature_count,
            "flattened_input_dim": frame_count * frame_feature_count,
        },
        "temporal_cnn": {
            "model_shape": f"{frame_count}x{frame_feature_count} -> conv1d({frame_feature_count}->{args.conv1_channels}, k={args.kernel_size}, same) -> relu -> conv1d({args.conv1_channels}->{args.conv2_channels}, k={args.kernel_size}, same) -> relu -> flatten({frame_count * args.conv2_channels}) -> logits({len(PUNCH_CLASS_ORDER)})",
            "conv1_channels": args.conv1_channels,
            "conv2_channels": args.conv2_channels,
            "kernel_size": args.kernel_size,
            "epochs": args.epochs,
            "learning_rate": args.learning_rate,
            "weight_decay": args.weight_decay,
            "seed": args.seed,
            "final_training_loss": epoch_losses[-1] if epoch_losses else None,
            "train_metrics": classification_metrics(train_records, PUNCH_CLASS_ORDER),
            "test_metrics": classification_metrics(test_records, PUNCH_CLASS_ORDER),
            "train_records": train_records,
            "test_records": test_records,
            "loss_curve": epoch_losses,
        },
        "mlp_baseline": {
            "model_shape": mlp_result.get("mlp", {}).get("model_shape", "unknown"),
            "train_metrics": mlp_result.get("mlp", {}).get("train_metrics", {}),
            "test_metrics": mlp_result.get("mlp", {}).get("test_metrics", {}),
        },
        "threshold_baseline": {
            "train_metrics": classification_metrics(threshold_train_records, PUNCH_CLASS_ORDER),
            "test_metrics": classification_metrics(threshold_test_records, PUNCH_CLASS_ORDER),
            "train_records": threshold_train_records,
            "test_records": threshold_test_records,
        },
        "standardization": {
            "means": means,
            "stds": stds,
        },
        "model": model.to_json(),
    }

    write_json(output_dir / "cnn-result.json", summary)
    write_json(output_dir / "cnn-model.json", {
        "class_order": list(PUNCH_CLASS_ORDER),
        "window_frame_count": frame_count,
        "frame_feature_count": frame_feature_count,
        "standardization": summary["standardization"],
        "network": summary["model"],
    })
    (output_dir / "cnn-result.md").write_text(_render_markdown(summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
