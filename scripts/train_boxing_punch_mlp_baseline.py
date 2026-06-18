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


class TinyTemporalMLP:
    def __init__(self, input_dim: int, hidden_dim: int, output_dim: int, seed: int) -> None:
        rng = random.Random(seed)
        self.input_dim = input_dim
        self.hidden_dim = hidden_dim
        self.output_dim = output_dim
        init_ih = math.sqrt(6.0 / float(input_dim + hidden_dim))
        init_ho = math.sqrt(6.0 / float(hidden_dim + output_dim))
        self.w1 = [[rng.uniform(-init_ih, init_ih) for _ in range(input_dim)] for _ in range(hidden_dim)]
        self.b1 = [0.0 for _ in range(hidden_dim)]
        self.w2 = [[rng.uniform(-init_ho, init_ho) for _ in range(hidden_dim)] for _ in range(output_dim)]
        self.b2 = [0.0 for _ in range(output_dim)]

    def forward(self, x: list[float]) -> tuple[list[float], list[float], list[float]]:
        hidden_pre = []
        hidden = []
        for hidden_index in range(self.hidden_dim):
            total = self.b1[hidden_index]
            weights = self.w1[hidden_index]
            for input_index in range(self.input_dim):
                total += weights[input_index] * x[input_index]
            hidden_pre.append(total)
            hidden.append(total if total > 0.0 else 0.0)
        logits = []
        for output_index in range(self.output_dim):
            total = self.b2[output_index]
            weights = self.w2[output_index]
            for hidden_index in range(self.hidden_dim):
                total += weights[hidden_index] * hidden[hidden_index]
            logits.append(total)
        return hidden_pre, hidden, logits

    @staticmethod
    def softmax(logits: list[float]) -> list[float]:
        max_logit = max(logits)
        exps = [math.exp(value - max_logit) for value in logits]
        total = sum(exps)
        return [value / total for value in exps]

    def predict_proba(self, x: list[float]) -> list[float]:
        return self.softmax(self.forward(x)[2])

    def train_batch(self, features: list[list[float]], labels: list[int], lr: float, weight_decay: float) -> float:
        grad_w1 = [[0.0 for _ in range(self.input_dim)] for _ in range(self.hidden_dim)]
        grad_b1 = [0.0 for _ in range(self.hidden_dim)]
        grad_w2 = [[0.0 for _ in range(self.hidden_dim)] for _ in range(self.output_dim)]
        grad_b2 = [0.0 for _ in range(self.output_dim)]
        total_loss = 0.0

        for x, label_index in zip(features, labels):
            hidden_pre, hidden, logits = self.forward(x)
            probabilities = self.softmax(logits)
            total_loss += -math.log(max(probabilities[label_index], 1e-12))

            delta_out = [probability for probability in probabilities]
            delta_out[label_index] -= 1.0
            for output_index in range(self.output_dim):
                grad_b2[output_index] += delta_out[output_index]
                for hidden_index in range(self.hidden_dim):
                    grad_w2[output_index][hidden_index] += delta_out[output_index] * hidden[hidden_index]

            delta_hidden = [0.0 for _ in range(self.hidden_dim)]
            for hidden_index in range(self.hidden_dim):
                downstream = 0.0
                for output_index in range(self.output_dim):
                    downstream += self.w2[output_index][hidden_index] * delta_out[output_index]
                if hidden_pre[hidden_index] <= 0.0:
                    downstream = 0.0
                delta_hidden[hidden_index] = downstream
                grad_b1[hidden_index] += downstream
                for input_index in range(self.input_dim):
                    grad_w1[hidden_index][input_index] += downstream * x[input_index]

        batch_size = float(len(features)) if features else 1.0
        for hidden_index in range(self.hidden_dim):
            for input_index in range(self.input_dim):
                grad = (grad_w1[hidden_index][input_index] / batch_size) + (weight_decay * self.w1[hidden_index][input_index])
                self.w1[hidden_index][input_index] -= lr * grad
            self.b1[hidden_index] -= lr * (grad_b1[hidden_index] / batch_size)
        for output_index in range(self.output_dim):
            for hidden_index in range(self.hidden_dim):
                grad = (grad_w2[output_index][hidden_index] / batch_size) + (weight_decay * self.w2[output_index][hidden_index])
                self.w2[output_index][hidden_index] -= lr * grad
            self.b2[output_index] -= lr * (grad_b2[output_index] / batch_size)
        return total_loss / batch_size

    def to_json(self) -> dict:
        return {
            "input_dim": self.input_dim,
            "hidden_dim": self.hidden_dim,
            "output_dim": self.output_dim,
            "w1": self.w1,
            "b1": self.b1,
            "w2": self.w2,
            "b2": self.b2,
        }



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
    records = []
    for sample, predicted_label in zip(samples, predicted_labels):
        records.append({
            "sample_id": sample["sample_id"],
            "split": sample["split"],
            "actual": sample["label"],
            "predicted": predicted_label,
        })
    return records


def _render_markdown(summary: dict) -> str:
    baseline_metrics = summary["threshold_baseline"]["test_metrics"]
    mlp_metrics = summary["mlp"]["test_metrics"]
    lines = [
        "# Boxing Punch Classifier Temporal-MLP Baseline",
        "",
        f"- Trained at: `{summary['trained_at']}`",
        f"- Dataset: `{summary['dataset_path']}`",
        f"- Split strategy: `{summary.get('split_strategy', 'unknown')}`",
        f"- Model shape: `{summary['mlp']['model_shape']}`",
        f"- Epochs: **{summary['mlp']['epochs']}**",
        f"- Learning rate: **{summary['mlp']['learning_rate']}**",
        f"- Weight decay: **{summary['mlp']['weight_decay']}**",
        "",
        "## Test split comparison",
        "",
        f"- Temporal MLP accuracy: **{mlp_metrics['accuracy']:.3f}**",
        f"- Temporal MLP macro F1: **{mlp_metrics['macro_f1']:.3f}**",
        f"- Threshold baseline accuracy: **{baseline_metrics['accuracy']:.3f}**",
        f"- Threshold baseline macro F1: **{baseline_metrics['macro_f1']:.3f}**",
        "",
        "## Temporal MLP confusion (test)",
        "",
        *format_confusion_markdown(mlp_metrics["confusion"], summary["class_order"]),
        "",
        "## Threshold confusion (test)",
        "",
        *format_confusion_markdown(baseline_metrics["confusion"], summary["class_order"]),
        "",
        "## Notes",
        "",
        "- This benchmark is still small, but it now uses chronological holdout instead of interleaving nearby windows across train/test.",
        "- The threshold comparison reuses the same exported windows and reads the threshold detector's emitted events from the capture reports attached to the dataset export.",
    ]
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Train and evaluate a tiny temporal-MLP boxing punch classifier baseline.")
    parser.add_argument("--dataset", required=True, help="Path to dataset.json produced by export_boxing_punch_classifier_dataset.py")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--hidden-dim", type=int, default=24)
    parser.add_argument("--epochs", type=int, default=450)
    parser.add_argument("--learning-rate", type=float, default=0.045)
    parser.add_argument("--weight-decay", type=float, default=0.0005)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    dataset_path = Path(args.dataset).resolve()
    dataset = load_json(dataset_path)
    output_dir = Path(args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    feature_set, side_feature_names, frame_feature_names = _validate_dataset_schema(dataset)
    samples = dataset["samples"]
    label_to_index = {label: idx for idx, label in enumerate(PUNCH_CLASS_ORDER)}

    train_samples = [sample for sample in samples if sample["split"] == "train"]
    test_samples = [sample for sample in samples if sample["split"] == "test"]
    train_vectors = [flatten_frames(sample["frames"]) for sample in train_samples]
    test_vectors = [flatten_frames(sample["frames"]) for sample in test_samples]
    means, stds = compute_standardization(train_vectors)
    train_vectors = apply_standardization(train_vectors, means, stds)
    test_vectors = apply_standardization(test_vectors, means, stds)
    train_labels = [label_to_index[sample["label"]] for sample in train_samples]
    test_labels = [label_to_index[sample["label"]] for sample in test_samples]

    input_dim = len(train_vectors[0]) if train_vectors else len(test_vectors[0])
    model = TinyTemporalMLP(input_dim=input_dim, hidden_dim=args.hidden_dim, output_dim=len(PUNCH_CLASS_ORDER), seed=args.seed)
    epoch_losses = []
    for _ in range(args.epochs):
        loss = model.train_batch(train_vectors, train_labels, lr=args.learning_rate, weight_decay=args.weight_decay)
        epoch_losses.append(loss)

    def predict_labels(vectors: list[list[float]]) -> list[str]:
        predictions = []
        for vector in vectors:
            probabilities = model.predict_proba(vector)
            best_index = max(range(len(probabilities)), key=lambda idx: probabilities[idx])
            predictions.append(PUNCH_CLASS_ORDER[best_index])
        return predictions

    train_predictions = predict_labels(train_vectors)
    test_predictions = predict_labels(test_vectors)
    train_records = _records_from_predictions(train_samples, train_predictions)
    test_records = _records_from_predictions(test_samples, test_predictions)
    threshold_train_records = [
        {"sample_id": sample["sample_id"], "split": sample["split"], "actual": sample["label"], "predicted": sample["threshold_baseline"]["predicted_label"]}
        for sample in train_samples
    ]
    threshold_test_records = [
        {"sample_id": sample["sample_id"], "split": sample["split"], "actual": sample["label"], "predicted": sample["threshold_baseline"]["predicted_label"]}
        for sample in test_samples
    ]

    summary = {
        "schema": "aerobeat.boxing_punch_classifier_mlp_result",
        "version": 1,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "dataset_path": dataset_path.as_posix(),
        "class_order": list(PUNCH_CLASS_ORDER),
        "split_strategy": str(dataset.get("split_strategy", "unknown")),
        "feature_set": feature_set,
        "side_feature_names": side_feature_names,
        "frame_feature_names": frame_feature_names,
        "dataset_window_shape": {
            "frame_count": int(dataset.get("window_frame_count", 0)),
            "frame_feature_count": int(dataset.get("frame_feature_count", 0)),
            "flattened_input_dim": input_dim,
        },
        "mlp": {
            "model_shape": f"{dataset.get('window_frame_count', 0)}x{dataset.get('frame_feature_count', 0)} -> flatten({input_dim}) -> hidden({args.hidden_dim}) -> logits({len(PUNCH_CLASS_ORDER)})",
            "hidden_dim": args.hidden_dim,
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

    write_json(output_dir / "mlp-result.json", summary)
    write_json(output_dir / "mlp-model.json", {
        "class_order": list(PUNCH_CLASS_ORDER),
        "feature_set": feature_set,
        "side_feature_names": side_feature_names,
        "frame_feature_names": frame_feature_names,
        "window_frame_count": dataset.get("window_frame_count", 0),
        "frame_feature_count": dataset.get("frame_feature_count", 0),
        "flattened_input_dim": input_dim,
        "standardization": summary["standardization"],
        "network": summary["model"],
    })
    (output_dir / "mlp-result.md").write_text(_render_markdown(summary), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
