#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def _read_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload if isinstance(payload, dict) else {}


def _write_json(path: str, payload: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, separators=(",", ":"), sort_keys=True)


def _failure(code: str, message: str, status: str = "failed", runtime_stage: str = "dependency_check", **extra: Any) -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "ok": False,
        "status": status,
        "failure_code": code,
        "failure_message": message,
        "runtime_stage": runtime_stage,
    }
    payload.update(extra)
    return payload


def _family_config(backend_id: str, family_id: str) -> Dict[str, Any]:
    config = {
        "input_layout": "nchw",
        "color_order": "rgb",
        "normalize": "unit",
        "output_near_is_larger": False,
        "default_hw": (256, 256),
    }
    if backend_id == "openvino" or family_id.startswith("midas"):
        config.update({
            "normalize": "imagenet",
            "output_near_is_larger": True,
            "default_hw": (256, 256),
        })
    elif family_id.startswith("depth_anything"):
        config.update({
            "normalize": "imagenet",
            "output_near_is_larger": True,
            "default_hw": (518, 518),
        })
    elif family_id.startswith("fastdepth"):
        config.update({
            "normalize": "unit",
            "output_near_is_larger": False,
            "default_hw": (224, 224),
        })
    return config


def _load_image_bgr(image_path: str) -> Tuple[Any, Any]:
    try:
        import cv2  # type: ignore
    except Exception as exc:
        raise RuntimeError(f"OpenCV import failed: {exc}") from exc
    frame_bgr = cv2.imread(image_path, cv2.IMREAD_COLOR)
    if frame_bgr is None:
        raise RuntimeError(f"OpenCV failed to read preview image '{image_path}'")
    return cv2, frame_bgr


def _model_input_hw_from_shape(shape: Any, fallback_hw: Tuple[int, int]) -> Tuple[int, int]:
    dims = list(shape) if isinstance(shape, (list, tuple)) else []
    if len(dims) >= 4:
        h = dims[-2]
        w = dims[-1]
        if isinstance(h, int) and isinstance(w, int) and h > 0 and w > 0:
            return int(h), int(w)
    return fallback_hw


def _prepare_input(frame_bgr: Any, input_hw: Tuple[int, int], family_cfg: Dict[str, Any]) -> Any:
    import numpy as np  # type: ignore
    import cv2  # type: ignore

    input_h, input_w = input_hw
    frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    resized = cv2.resize(frame_rgb, (input_w, input_h), interpolation=cv2.INTER_CUBIC)
    tensor = resized.astype(np.float32) / 255.0
    if family_cfg.get("normalize") == "imagenet":
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        tensor = (tensor - mean) / std
    tensor = np.transpose(tensor, (2, 0, 1))[None, ...]
    return tensor


def _normalize_output_depth(raw_depth: Any, near_is_larger: bool) -> Any:
    import numpy as np  # type: ignore

    depth = np.asarray(raw_depth, dtype=np.float32)
    if depth.ndim == 4:
        depth = depth[0, 0]
    elif depth.ndim == 3:
        depth = depth[0]
    elif depth.ndim != 2:
        raise RuntimeError(f"Unexpected depth output shape {tuple(depth.shape)}")
    min_v = float(depth.min())
    max_v = float(depth.max())
    if max_v - min_v <= 1e-6:
        normalized = np.zeros_like(depth, dtype=np.float32)
    else:
        normalized = (depth - min_v) / (max_v - min_v)
    if near_is_larger:
        normalized = 1.0 - normalized
    return normalized.astype(np.float32)


def _resize_depth_to_frame(normalized_depth: Any, frame_shape: Tuple[int, int]) -> Any:
    import cv2  # type: ignore

    frame_h, frame_w = frame_shape
    return cv2.resize(normalized_depth, (frame_w, frame_h), interpolation=cv2.INTER_CUBIC)


def _sample_depth(depth_map: Any, point: Dict[str, Any]) -> float:
    h, w = depth_map.shape[:2]
    x = float(point.get("x", 0.5))
    y = float(point.get("y", 0.5))
    px = int(round(max(0.0, min(1.0, x)) * float(max(w - 1, 0))))
    py = int(round(max(0.0, min(1.0, y)) * float(max(h - 1, 0))))
    return float(depth_map[py, px])


def _probe_openvino(model_spec: Dict[str, Any]) -> Dict[str, Any]:
    artifact_dir = str(model_spec.get("artifact_path_abs", "")).strip()
    if artifact_dir == "" or not os.path.isdir(artifact_dir):
        return _failure("artifact_missing", f"OpenVINO artifact directory not found at '{artifact_dir}'")
    xml_candidates = sorted(str(path) for path in Path(artifact_dir).glob("*.xml"))
    if not xml_candidates:
        return _failure("artifact_missing", f"No OpenVINO .xml model file was found in '{artifact_dir}'")
    xml_path = xml_candidates[0]
    try:
        from openvino import Core  # type: ignore
    except Exception:
        try:
            from openvino.runtime import Core  # type: ignore
        except Exception as exc:
            return _failure("dependency_missing", f"OpenVINO import failed: {exc}")
    try:
        core = Core()
        model = core.read_model(xml_path)
        compiled = core.compile_model(model, "CPU")
        input_shape = list(compiled.input(0).shape)
    except Exception as exc:
        return _failure("model_load_failed", f"OpenVINO failed to load '{xml_path}': {exc}")
    return {
        "ok": True,
        "status": "ready",
        "runtime_stage": "sampling",
        "active_model_summary": "enabled; runtime ready via openvino backend",
        "runtime_provider": "OpenVINO CPU",
        "input_shape": input_shape,
    }


def _probe_onnx(model_spec: Dict[str, Any]) -> Dict[str, Any]:
    model_path = str(model_spec.get("artifact_path_abs", "")).strip()
    if model_path == "" or not os.path.isfile(model_path):
        return _failure("artifact_missing", f"ONNX artifact file not found at '{model_path}'")
    try:
        import onnxruntime as ort  # type: ignore
    except Exception as exc:
        return _failure("dependency_missing", f"onnxruntime import failed: {exc}")
    try:
        session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
        input_shape = list(session.get_inputs()[0].shape)
        providers = session.get_providers()
    except Exception as exc:
        return _failure("model_load_failed", f"onnxruntime failed to load '{model_path}': {exc}")
    return {
        "ok": True,
        "status": "ready",
        "runtime_stage": "sampling",
        "active_model_summary": "enabled; runtime ready via onnx backend",
        "runtime_provider": ",".join(providers),
        "input_shape": input_shape,
    }


def _infer_openvino(model_spec: Dict[str, Any], preview_image_path: str, sample_request: Dict[str, Any]) -> Dict[str, Any]:
    started_at = time.perf_counter()
    timing = {"preprocess": 0.0, "infer": 0.0, "postprocess": 0.0, "total": 0.0}
    family_cfg = _family_config("openvino", str(model_spec.get("family_id", "unknown")))
    probe = _probe_openvino(model_spec)
    if not probe.get("ok", False):
        probe["runtime_stage"] = "adapter_load"
        return probe
    artifact_dir = str(model_spec.get("artifact_path_abs", "")).strip()
    xml_path = sorted(str(path) for path in Path(artifact_dir).glob("*.xml"))[0]
    try:
        from openvino import Core  # type: ignore
    except Exception:
        from openvino.runtime import Core  # type: ignore
    try:
        import numpy as np  # type: ignore
        cv2, frame_bgr = _load_image_bgr(preview_image_path)
        frame_h, frame_w = frame_bgr.shape[:2]
        core = Core()
        model = core.read_model(xml_path)
        compiled = core.compile_model(model, "CPU")
        input_hw = _model_input_hw_from_shape(compiled.input(0).shape, family_cfg["default_hw"])
        t0 = time.perf_counter()
        tensor = _prepare_input(frame_bgr, input_hw, family_cfg)
        timing["preprocess"] = (time.perf_counter() - t0) * 1000.0
        t1 = time.perf_counter()
        infer_outputs = compiled([tensor])
        raw_output = next(iter(infer_outputs.values())) if isinstance(infer_outputs, dict) else infer_outputs[compiled.output(0)]
        timing["infer"] = (time.perf_counter() - t1) * 1000.0
        t2 = time.perf_counter()
        normalized_depth = _normalize_output_depth(raw_output, bool(family_cfg.get("output_near_is_larger", False)))
        normalized_depth = _resize_depth_to_frame(normalized_depth, (frame_h, frame_w))
        shoulder_depth = _sample_depth(normalized_depth, sample_request.get("shoulder", {}))
        wrist_depth = _sample_depth(normalized_depth, sample_request.get("wrist", {}))
        timing["postprocess"] = (time.perf_counter() - t2) * 1000.0
        timing["total"] = (time.perf_counter() - started_at) * 1000.0
        return {
            "ok": True,
            "status": "ready",
            "runtime_stage": "sampling",
            "active_model_summary": "enabled; runtime ready via openvino backend",
            "runtime_provider": str(probe.get("runtime_provider", "OpenVINO CPU")),
            "depth_orientation": "smaller_is_closer",
            "frame_size": [int(frame_w), int(frame_h)],
            "depth_map_size": [int(frame_w), int(frame_h)],
            "normalized_depth_map": None,
            "sample_metrics": {
                "wrist_closeness": float(shoulder_depth - wrist_depth),
                "wrist_depth": float(wrist_depth),
                "torso_depth": float(shoulder_depth),
                "sample_source": "fresh_inference",
                "sample_fresh": True,
            },
            "timing_ms": timing,
        }
    except Exception as exc:
        return _failure("infer_failed", f"OpenVINO depth inference failed: {exc}", runtime_stage="inference", timing_ms=timing)


def _infer_onnx(model_spec: Dict[str, Any], preview_image_path: str, sample_request: Dict[str, Any]) -> Dict[str, Any]:
    started_at = time.perf_counter()
    timing = {"preprocess": 0.0, "infer": 0.0, "postprocess": 0.0, "total": 0.0}
    family_id = str(model_spec.get("family_id", "unknown"))
    family_cfg = _family_config("onnx", family_id)
    probe = _probe_onnx(model_spec)
    if not probe.get("ok", False):
        probe["runtime_stage"] = "adapter_load"
        return probe
    model_path = str(model_spec.get("artifact_path_abs", "")).strip()
    try:
        import onnxruntime as ort  # type: ignore
        cv2, frame_bgr = _load_image_bgr(preview_image_path)
        frame_h, frame_w = frame_bgr.shape[:2]
        session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
        input_meta = session.get_inputs()[0]
        input_hw = _model_input_hw_from_shape(input_meta.shape, family_cfg["default_hw"])
        t0 = time.perf_counter()
        tensor = _prepare_input(frame_bgr, input_hw, family_cfg)
        timing["preprocess"] = (time.perf_counter() - t0) * 1000.0
        t1 = time.perf_counter()
        raw_output = session.run(None, {input_meta.name: tensor})[0]
        timing["infer"] = (time.perf_counter() - t1) * 1000.0
        t2 = time.perf_counter()
        normalized_depth = _normalize_output_depth(raw_output, bool(family_cfg.get("output_near_is_larger", False)))
        normalized_depth = _resize_depth_to_frame(normalized_depth, (frame_h, frame_w))
        shoulder_depth = _sample_depth(normalized_depth, sample_request.get("shoulder", {}))
        wrist_depth = _sample_depth(normalized_depth, sample_request.get("wrist", {}))
        timing["postprocess"] = (time.perf_counter() - t2) * 1000.0
        timing["total"] = (time.perf_counter() - started_at) * 1000.0
        return {
            "ok": True,
            "status": "ready",
            "runtime_stage": "sampling",
            "active_model_summary": "enabled; runtime ready via onnx backend",
            "runtime_provider": str(probe.get("runtime_provider", "CPUExecutionProvider")),
            "depth_orientation": "smaller_is_closer",
            "frame_size": [int(frame_w), int(frame_h)],
            "depth_map_size": [int(frame_w), int(frame_h)],
            "normalized_depth_map": None,
            "sample_metrics": {
                "wrist_closeness": float(shoulder_depth - wrist_depth),
                "wrist_depth": float(wrist_depth),
                "torso_depth": float(shoulder_depth),
                "sample_source": "fresh_inference",
                "sample_fresh": True,
            },
            "timing_ms": timing,
        }
    except Exception as exc:
        return _failure("infer_failed", f"ONNX depth inference failed: {exc}", runtime_stage="inference", timing_ms=timing)


def _handle_request(request: Dict[str, Any]) -> Dict[str, Any]:
    operation = str(request.get("operation", "probe"))
    backend_id = str(request.get("backend_id", "unknown"))
    model_spec = request.get("model_spec", {}) if isinstance(request.get("model_spec", {}), dict) else {}
    if operation == "probe":
        if backend_id == "openvino":
            return _probe_openvino(model_spec)
        if backend_id == "onnx":
            return _probe_onnx(model_spec)
        return _failure("unsupported_backend", f"Unsupported depth backend '{backend_id}'")
    if operation == "infer":
        preview_image_path = str(request.get("preview_image_path", "")).strip()
        if preview_image_path == "" or not os.path.isfile(preview_image_path):
            return _failure("preview_image_missing", f"Preview image path was not found at '{preview_image_path}'", status="blocked", runtime_stage="inference")
        sample_request = request.get("sample_request", {}) if isinstance(request.get("sample_request", {}), dict) else {}
        if backend_id == "openvino":
            return _infer_openvino(model_spec, preview_image_path, sample_request)
        if backend_id == "onnx":
            return _infer_onnx(model_spec, preview_image_path, sample_request)
        return _failure("unsupported_backend", f"Unsupported depth backend '{backend_id}'", runtime_stage="inference")
    return _failure("unsupported_operation", f"Unsupported depth runtime operation '{operation}'")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--request-file", required=True)
    parser.add_argument("--response-file", required=True)
    args = parser.parse_args()
    try:
        response = _handle_request(_read_json(args.request_file))
    except Exception as exc:
        response = _failure("bridge_crash", f"Depth runtime bridge crashed: {exc}")
    _write_json(args.response_file, response)
    return 0 if response.get("ok", False) else 1


if __name__ == "__main__":
    raise SystemExit(main())
