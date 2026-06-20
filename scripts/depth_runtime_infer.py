#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import secrets
import socket
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

PROTOCOL_VERSION = 1


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


def _find_openvino_xml(model_spec: Dict[str, Any]) -> str:
    artifact_dir = str(model_spec.get("artifact_path_abs", "")).strip()
    if artifact_dir == "" or not os.path.isdir(artifact_dir):
        raise RuntimeError(f"OpenVINO artifact directory not found at '{artifact_dir}'")
    xml_candidates = sorted(str(path) for path in Path(artifact_dir).glob("*.xml"))
    if not xml_candidates:
        raise RuntimeError(f"No OpenVINO .xml model file was found in '{artifact_dir}'")
    return xml_candidates[0]


class RuntimeSession:
    def __init__(self, backend_id: str, model_spec: Dict[str, Any]) -> None:
        self.backend_id = backend_id
        self.model_spec = dict(model_spec)
        self.runtime_key = str(model_spec.get("runtime_key", ""))
        self.family_id = str(model_spec.get("family_id", "unknown"))
        self.family_cfg = _family_config(backend_id, self.family_id)
        self.loaded_at = time.perf_counter()
        self.load_ms = 0.0
        self.input_shape: list[Any] = []
        self.runtime_provider = ""
        self.input_hw = self.family_cfg["default_hw"]
        self.session: Any = None
        self.input_name = ""
        self.output_key: Any = None

    def load(self) -> None:
        started_at = time.perf_counter()
        if self.backend_id == "openvino":
            self._load_openvino()
        elif self.backend_id == "onnx":
            self._load_onnx()
        else:
            raise RuntimeError(f"Unsupported depth backend '{self.backend_id}'")
        self.load_ms = (time.perf_counter() - started_at) * 1000.0
        self.loaded_at = time.perf_counter()

    def _load_openvino(self) -> None:
        xml_path = _find_openvino_xml(self.model_spec)
        try:
            from openvino import Core  # type: ignore
        except Exception:
            from openvino.runtime import Core  # type: ignore
        core = Core()
        model = core.read_model(xml_path)
        compiled = core.compile_model(model, "CPU")
        input_shape = list(compiled.input(0).shape)
        self.input_shape = input_shape
        self.runtime_provider = "OpenVINO CPU"
        self.input_hw = _model_input_hw_from_shape(input_shape, self.family_cfg["default_hw"])
        self.session = compiled
        self.output_key = compiled.output(0)

    def _load_onnx(self) -> None:
        model_path = str(self.model_spec.get("artifact_path_abs", "")).strip()
        if model_path == "" or not os.path.isfile(model_path):
            raise RuntimeError(f"ONNX artifact file not found at '{model_path}'")
        import onnxruntime as ort  # type: ignore
        session = ort.InferenceSession(model_path, providers=["CPUExecutionProvider"])
        input_meta = session.get_inputs()[0]
        self.input_shape = list(input_meta.shape)
        self.runtime_provider = ",".join(session.get_providers())
        self.input_hw = _model_input_hw_from_shape(input_meta.shape, self.family_cfg["default_hw"])
        self.session = session
        self.input_name = input_meta.name

    def probe_payload(self) -> Dict[str, Any]:
        return {
            "ok": True,
            "status": "ready",
            "runtime_stage": "sampling",
            "active_model_summary": f"enabled; runtime ready via {self.backend_id} backend",
            "runtime_provider": self.runtime_provider,
            "input_shape": self.input_shape,
            "model_loaded": True,
        }

    def infer(self, preview_image_path: str, sample_request: Dict[str, Any]) -> Dict[str, Any]:
        started_at = time.perf_counter()
        timing = {
            "preprocess": 0.0,
            "infer": 0.0,
            "postprocess": 0.0,
            "total": 0.0,
            "worker_load": 0.0,
            "session_warm": True,
        }
        try:
            cv2, frame_bgr = _load_image_bgr(preview_image_path)
            frame_h, frame_w = frame_bgr.shape[:2]
            t0 = time.perf_counter()
            tensor = _prepare_input(frame_bgr, self.input_hw, self.family_cfg)
            timing["preprocess"] = (time.perf_counter() - t0) * 1000.0
            t1 = time.perf_counter()
            raw_output = self._infer_raw(tensor)
            timing["infer"] = (time.perf_counter() - t1) * 1000.0
            t2 = time.perf_counter()
            normalized_depth = _normalize_output_depth(raw_output, bool(self.family_cfg.get("output_near_is_larger", False)))
            normalized_depth = _resize_depth_to_frame(normalized_depth, (frame_h, frame_w))
            shoulder_depth = _sample_depth(normalized_depth, sample_request.get("shoulder", {}))
            wrist_depth = _sample_depth(normalized_depth, sample_request.get("wrist", {}))
            timing["postprocess"] = (time.perf_counter() - t2) * 1000.0
            timing["total"] = (time.perf_counter() - started_at) * 1000.0
            return {
                "ok": True,
                "status": "ready",
                "runtime_stage": "sampling",
                "active_model_summary": f"enabled; runtime ready via {self.backend_id} backend",
                "runtime_provider": self.runtime_provider,
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
            timing["total"] = (time.perf_counter() - started_at) * 1000.0
            return _failure(
                "infer_failed",
                f"{self.backend_id.upper()} depth inference failed: {exc}",
                runtime_stage="inference",
                timing_ms=timing,
            )

    def _infer_raw(self, tensor: Any) -> Any:
        if self.backend_id == "openvino":
            infer_outputs = self.session([tensor])
            return next(iter(infer_outputs.values())) if isinstance(infer_outputs, dict) else infer_outputs[self.output_key]
        return self.session.run(None, {self.input_name: tensor})[0]


class WorkerState:
    def __init__(self) -> None:
        self.started_at = time.perf_counter()
        self.worker_generation = 1
        self.worker_pid = os.getpid()
        self.active_session: Optional[RuntimeSession] = None
        self.active_runtime_key = ""
        self.model_load_count = 0
        self.model_reload_count = 0
        self.request_count = 0
        self.last_request_id = ""

    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        self.request_count += 1
        self.last_request_id = str(request.get("request_id", ""))
        token = str(request.get("token", ""))
        operation = str(request.get("operation", "probe"))
        backend_id = str(request.get("backend_id", "unknown"))
        model_spec = request.get("model_spec", {}) if isinstance(request.get("model_spec", {}), dict) else {}
        preview_image_path = str(request.get("preview_image_path", "")).strip()
        sample_request = request.get("sample_request", {}) if isinstance(request.get("sample_request", {}), dict) else {}

        if operation == "hello":
            return self._decorate({
                "ok": True,
                "status": "ready",
                "runtime_stage": "dependency_check",
                "protocol_version": PROTOCOL_VERSION,
                "active_model_summary": "persistent depth worker ready",
            }, model_loaded=self.active_session is not None, session_warm=self.active_session is not None, request_id=self.last_request_id)

        if operation == "shutdown":
            return self._decorate({
                "ok": True,
                "status": "unloaded",
                "runtime_stage": "idle",
                "active_model_summary": "persistent depth worker shutting down",
            }, model_loaded=self.active_session is not None, session_warm=self.active_session is not None, request_id=self.last_request_id)

        if operation not in ("probe", "infer"):
            return self._decorate(_failure("unsupported_operation", f"Unsupported depth runtime operation '{operation}'"), request_id=self.last_request_id)

        ensure_started_at = time.perf_counter()
        try:
            session, load_ms, session_warm = self._ensure_session(backend_id, model_spec)
        except Exception as exc:
            return self._decorate(
                _failure("model_load_failed", f"{backend_id.upper()} runtime load failed: {exc}", runtime_stage="adapter_load"),
                request_id=self.last_request_id,
            )
        ensure_ms = (time.perf_counter() - ensure_started_at) * 1000.0

        if operation == "probe":
            response = session.probe_payload()
            response.setdefault("timing_ms", {})
            response["timing_ms"]["worker_load"] = load_ms
            response["timing_ms"]["session_warm"] = session_warm
            response["timing_ms"]["total"] = ensure_ms
            return self._decorate(response, model_loaded=True, session_warm=session_warm, request_id=self.last_request_id)

        if preview_image_path == "" or not os.path.isfile(preview_image_path):
            return self._decorate(
                _failure("preview_image_missing", f"Preview image path was not found at '{preview_image_path}'", status="blocked", runtime_stage="inference"),
                model_loaded=True,
                session_warm=session_warm,
                request_id=self.last_request_id,
            )

        response = session.infer(preview_image_path, sample_request)
        response.setdefault("timing_ms", {})
        response["timing_ms"]["worker_load"] = load_ms
        response["timing_ms"]["session_warm"] = session_warm
        return self._decorate(response, model_loaded=True, session_warm=session_warm, request_id=self.last_request_id)

    def _ensure_session(self, backend_id: str, model_spec: Dict[str, Any]) -> Tuple[RuntimeSession, float, bool]:
        runtime_key = str(model_spec.get("runtime_key", ""))
        if self.active_session is not None and runtime_key == self.active_runtime_key and backend_id == self.active_session.backend_id:
            return self.active_session, 0.0, True
        session = RuntimeSession(backend_id, model_spec)
        session.load()
        if self.active_session is None:
            self.model_load_count += 1
        else:
            self.model_reload_count += 1
            self.model_load_count += 1
        self.active_session = session
        self.active_runtime_key = runtime_key
        return session, session.load_ms, False

    def _decorate(self, response: Dict[str, Any], *, model_loaded: Optional[bool] = None, session_warm: Optional[bool] = None, request_id: str = "") -> Dict[str, Any]:
        response["worker_pid"] = self.worker_pid
        response["worker_generation"] = self.worker_generation
        response["worker_uptime_ms"] = (time.perf_counter() - self.started_at) * 1000.0
        response["worker_mode"] = "persistent_tcp"
        response["model_runtime_key"] = self.active_runtime_key
        response["model_loaded"] = self.active_session is not None if model_loaded is None else model_loaded
        response["model_load_count"] = self.model_load_count
        response["model_reload_count"] = self.model_reload_count
        response["request_id"] = request_id
        response["protocol_version"] = PROTOCOL_VERSION
        response.setdefault("timing_ms", {})
        if session_warm is not None:
            response["timing_ms"].setdefault("session_warm", session_warm)
        return response


def _probe_openvino(model_spec: Dict[str, Any]) -> Dict[str, Any]:
    try:
        session = RuntimeSession("openvino", model_spec)
        session.load()
        response = session.probe_payload()
        response["timing_ms"] = {"worker_load": session.load_ms, "session_warm": False, "total": session.load_ms}
        return response
    except Exception as exc:
        return _failure("model_load_failed", f"OpenVINO runtime load failed: {exc}")


def _probe_onnx(model_spec: Dict[str, Any]) -> Dict[str, Any]:
    try:
        session = RuntimeSession("onnx", model_spec)
        session.load()
        response = session.probe_payload()
        response["timing_ms"] = {"worker_load": session.load_ms, "session_warm": False, "total": session.load_ms}
        return response
    except Exception as exc:
        return _failure("model_load_failed", f"ONNX runtime load failed: {exc}")


def _infer_openvino(model_spec: Dict[str, Any], preview_image_path: str, sample_request: Dict[str, Any]) -> Dict[str, Any]:
    try:
        session = RuntimeSession("openvino", model_spec)
        session.load()
        response = session.infer(preview_image_path, sample_request)
        response.setdefault("timing_ms", {})
        response["timing_ms"]["worker_load"] = session.load_ms
        response["timing_ms"]["session_warm"] = False
        return response
    except Exception as exc:
        return _failure("model_load_failed", f"OpenVINO runtime load failed: {exc}")


def _infer_onnx(model_spec: Dict[str, Any], preview_image_path: str, sample_request: Dict[str, Any]) -> Dict[str, Any]:
    try:
        session = RuntimeSession("onnx", model_spec)
        session.load()
        response = session.infer(preview_image_path, sample_request)
        response.setdefault("timing_ms", {})
        response["timing_ms"]["worker_load"] = session.load_ms
        response["timing_ms"]["session_warm"] = False
        return response
    except Exception as exc:
        return _failure("model_load_failed", f"ONNX runtime load failed: {exc}")


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


def _read_line(conn: socket.socket) -> str:
    chunks = bytearray()
    while True:
        data = conn.recv(4096)
        if not data:
            break
        chunks.extend(data)
        if b"\n" in data:
            break
    raw = bytes(chunks)
    line = raw.split(b"\n", 1)[0]
    return line.decode("utf-8")


def _run_tcp_worker(ready_file: str, token: str, host: str, port: int) -> int:
    state = WorkerState()
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(8)
    actual_port = int(server.getsockname()[1])
    _write_json(ready_file, {
        "ok": True,
        "host": host,
        "port": actual_port,
        "pid": os.getpid(),
        "worker_generation": state.worker_generation,
        "protocol_version": PROTOCOL_VERSION,
        "token": token,
    })
    should_stop = False
    while not should_stop:
        conn, _addr = server.accept()
        with conn:
            try:
                request_text = _read_line(conn)
                request = json.loads(request_text) if request_text.strip() else {}
                if not isinstance(request, dict):
                    raise RuntimeError("Worker request must be a JSON object")
                if str(request.get("token", "")) != token:
                    response = _failure("unauthorized", "Depth worker token mismatch", status="blocked")
                else:
                    response = state.handle_request(request)
                conn.sendall((json.dumps(response, separators=(",", ":"), sort_keys=True) + "\n").encode("utf-8"))
                if str(request.get("operation", "")) == "shutdown" and str(request.get("token", "")) == token:
                    should_stop = True
            except Exception as exc:
                response = _failure("worker_request_failed", f"Depth worker request failed: {exc}")
                try:
                    conn.sendall((json.dumps(response, separators=(",", ":"), sort_keys=True) + "\n").encode("utf-8"))
                except Exception:
                    pass
    server.close()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--request-file")
    parser.add_argument("--response-file")
    parser.add_argument("--tcp-worker", action="store_true")
    parser.add_argument("--ready-file")
    parser.add_argument("--token", default=secrets.token_hex(16))
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=0)
    args = parser.parse_args()

    if args.tcp_worker:
        if not args.ready_file:
            print("--ready-file is required for --tcp-worker", file=sys.stderr)
            return 2
        return _run_tcp_worker(args.ready_file, args.token, args.host, args.port)

    if not args.request_file or not args.response_file:
        print("--request-file and --response-file are required in single-shot mode", file=sys.stderr)
        return 2

    try:
        response = _handle_request(_read_json(args.request_file))
    except Exception as exc:
        response = _failure("bridge_crash", f"Depth runtime bridge crashed: {exc}")
    _write_json(args.response_file, response)
    return 0 if response.get("ok", False) else 1


if __name__ == "__main__":
    raise SystemExit(main())
