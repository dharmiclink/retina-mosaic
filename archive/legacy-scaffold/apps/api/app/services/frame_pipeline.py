from __future__ import annotations

import base64
import json
import math
from pathlib import Path
from typing import TYPE_CHECKING, Any

import cv2
import numpy as np

if TYPE_CHECKING:
    from app.services.session_store import Session

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "retina_detector_weights.json"
MODEL_FEATURES = [
    "area_score",
    "shape_score",
    "fill_score",
    "center_score",
    "ring_score",
    "color_score",
    "saturation_score",
    "texture_score",
]
_MODEL_CACHE: dict[str, Any] = {"mtime": None, "model": None}


def _clip01(value: float) -> float:
    return max(0.0, min(1.0, value))


def _sigmoid(value: float) -> float:
    if value >= 0:
        exp_neg = math.exp(-value)
        return 1.0 / (1.0 + exp_neg)
    exp_pos = math.exp(value)
    return exp_pos / (1.0 + exp_pos)


def _load_model() -> dict[str, Any] | None:
    if not MODEL_PATH.exists():
        _MODEL_CACHE["mtime"] = None
        _MODEL_CACHE["model"] = None
        return None

    mtime = MODEL_PATH.stat().st_mtime
    if _MODEL_CACHE["mtime"] == mtime:
        return _MODEL_CACHE["model"]

    try:
        data = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
    except Exception:
        _MODEL_CACHE["mtime"] = mtime
        _MODEL_CACHE["model"] = None
        return None

    required = {"features", "weights", "bias", "mean", "std", "threshold"}
    if not required.issubset(set(data.keys())):
        _MODEL_CACHE["mtime"] = mtime
        _MODEL_CACHE["model"] = None
        return None

    _MODEL_CACHE["mtime"] = mtime
    _MODEL_CACHE["model"] = data
    return data


def _model_confidence(features: dict[str, float]) -> tuple[float, float] | None:
    model = _load_model()
    if model is None:
        return None

    feature_names = model.get("features", [])
    weights = model.get("weights", [])
    mean = model.get("mean", {})
    std = model.get("std", {})
    bias = float(model.get("bias", 0.0))
    threshold = float(model.get("threshold", 0.6))

    if len(feature_names) != len(weights):
        return None

    z = bias
    for feature_name, weight in zip(feature_names, weights):
        if feature_name not in features:
            return None
        mu = float(mean.get(feature_name, 0.0))
        sigma = float(std.get(feature_name, 1.0))
        sigma = sigma if abs(sigma) > 1e-9 else 1.0
        normalized = (float(features[feature_name]) - mu) / sigma
        z += float(weight) * normalized

    return _sigmoid(z), threshold


def decode_frame_chunk(image_b64: str) -> np.ndarray | None:
    """Decode base64 JPEG payload into a BGR frame."""
    encoded = image_b64.split(",", 1)[-1]
    try:
        payload = base64.b64decode(encoded, validate=True)
    except Exception:
        return None

    buffer = np.frombuffer(payload, dtype=np.uint8)
    if buffer.size == 0:
        return None

    frame = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
    return frame


def score_frame(frame: np.ndarray) -> dict[str, float]:
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    contrast = float(gray.std())
    glare_pixels = float((gray > 245).sum())
    glare_ratio = glare_pixels / float(gray.size)

    sharpness_n = min(sharpness / 400.0, 1.0)
    contrast_n = min(contrast / 64.0, 1.0)
    glare_n = max(0.0, 1.0 - min(glare_ratio * 5.0, 1.0))
    utility = 0.45 * sharpness_n + 0.35 * contrast_n + 0.20 * glare_n

    return {
        "sharpness": round(sharpness_n, 4),
        "contrast": round(contrast_n, 4),
        "glare": round(glare_n, 4),
        "utility": round(float(utility), 4),
    }


def detect_retina(frame: np.ndarray) -> dict[str, float | bool]:
    """Estimate whether a frame contains a centered fundus-like retina region."""
    height, width = frame.shape[:2]
    if height == 0 or width == 0:
        return {"detected": False, "confidence": 0.0}

    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    lower_orange = np.array([5, 35, 20], dtype=np.uint8)
    upper_orange = np.array([35, 255, 255], dtype=np.uint8)
    lower_red = np.array([0, 30, 20], dtype=np.uint8)
    upper_red = np.array([10, 255, 255], dtype=np.uint8)

    orange_mask = cv2.inRange(hsv, lower_orange, upper_orange)
    red_mask = cv2.inRange(hsv, lower_red, upper_red)
    mask = cv2.bitwise_or(orange_mask, red_mask)
    kernel = np.ones((5, 5), dtype=np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        feature_vector = {
            "area_score": 0.0,
            "shape_score": 0.0,
            "fill_score": 0.0,
            "center_score": 0.0,
            "ring_score": 0.0,
            "color_score": 0.0,
            "saturation_score": 0.0,
            "texture_score": 0.0,
        }
        model_output = _model_confidence(feature_vector)
        if model_output is None:
            model_confidence = 0.0
            threshold = 0.6
        else:
            model_confidence, threshold = model_output
        return {
            "detected": False,
            "confidence": 0.0,
            "heuristic_confidence": 0.0,
            "model_confidence": round(float(model_confidence), 4),
            "threshold": round(float(threshold), 4),
            "area_score": 0.0,
            "shape_score": 0.0,
            "fill_score": 0.0,
            "center_score": 0.0,
            "ring_score": 0.0,
            "color_score": 0.0,
            "saturation_score": 0.0,
            "texture_score": 0.0,
        }

    largest = max(contours, key=cv2.contourArea)
    area = float(cv2.contourArea(largest))
    area_ratio = area / float(width * height)
    perimeter = float(cv2.arcLength(largest, True))
    circularity = (4.0 * np.pi * area / (perimeter * perimeter)) if perimeter > 0 else 0.0
    (_, _), radius = cv2.minEnclosingCircle(largest)
    enclosing_area = np.pi * float(radius) * float(radius) if radius > 0 else 1.0
    fill_ratio = area / enclosing_area

    moments = cv2.moments(largest)
    if moments["m00"] > 0:
        cx = float(moments["m10"] / moments["m00"])
        cy = float(moments["m01"] / moments["m00"])
    else:
        cx = width / 2.0
        cy = height / 2.0

    offset_x = abs(cx - (width / 2.0)) / (width / 2.0)
    offset_y = abs(cy - (height / 2.0)) / (height / 2.0)
    centeredness = 1.0 - _clip01((offset_x + offset_y) / 1.25)

    center_radius = int(min(width, height) * 0.24)
    ring_radius = int(min(width, height) * 0.46)
    center_mask = np.zeros((height, width), dtype=np.uint8)
    ring_mask = np.zeros((height, width), dtype=np.uint8)
    cv2.circle(center_mask, (width // 2, height // 2), center_radius, 255, -1)
    cv2.circle(ring_mask, (width // 2, height // 2), ring_radius, 255, -1)
    cv2.circle(ring_mask, (width // 2, height // 2), center_radius + 12, 0, -1)

    center_pixels = gray[center_mask > 0]
    ring_pixels = gray[ring_mask > 0]
    center_mean = float(center_pixels.mean()) if center_pixels.size > 0 else 0.0
    ring_mean = float(ring_pixels.mean()) if ring_pixels.size > 0 else 0.0
    center_ring_gap = center_mean - ring_mean

    b_mean = float(frame[:, :, 0].mean())
    g_mean = float(frame[:, :, 1].mean())
    r_mean = float(frame[:, :, 2].mean())
    red_dominance = r_mean - ((g_mean + b_mean) / 2.0)
    sat_channel = hsv[:, :, 1]
    sat_pixels = sat_channel[mask > 0]
    sat_mean = float(sat_pixels.mean()) if sat_pixels.size > 0 else 0.0

    green = frame[:, :, 1]
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(green)
    edges = cv2.Canny(enhanced, 40, 120)
    mask_pixels = int((mask > 0).sum())
    edge_density = float((edges[mask > 0] > 0).sum()) / float(mask_pixels) if mask_pixels > 0 else 0.0

    area_score = _clip01((area_ratio - 0.08) / 0.35)
    shape_score = _clip01((circularity - 0.45) / 0.4)
    fill_score = _clip01((fill_ratio - 0.62) / 0.28)
    center_score = centeredness
    ring_score = _clip01((center_ring_gap + 12.0) / 80.0)
    color_score = _clip01((red_dominance + 8.0) / 55.0)
    saturation_score = _clip01((sat_mean - 42.0) / 85.0)
    texture_score = _clip01((edge_density - 0.01) / 0.08)

    heuristic_confidence = (
        0.2 * area_score
        + 0.14 * shape_score
        + 0.14 * fill_score
        + 0.15 * center_score
        + 0.14 * ring_score
        + 0.11 * color_score
        + 0.06 * saturation_score
        + 0.06 * texture_score
    )

    feature_vector = {
        "area_score": float(area_score),
        "shape_score": float(shape_score),
        "fill_score": float(fill_score),
        "center_score": float(center_score),
        "ring_score": float(ring_score),
        "color_score": float(color_score),
        "saturation_score": float(saturation_score),
        "texture_score": float(texture_score),
    }

    model_output = _model_confidence(feature_vector)
    if model_output is None:
        model_confidence = heuristic_confidence
        threshold = 0.6
        confidence = heuristic_confidence
    else:
        model_confidence, threshold = model_output
        confidence = 0.65 * model_confidence + 0.35 * heuristic_confidence

    detected = confidence >= threshold

    return {
        "detected": bool(detected),
        "confidence": round(float(confidence), 4),
        "heuristic_confidence": round(float(heuristic_confidence), 4),
        "model_confidence": round(float(model_confidence), 4),
        "threshold": round(float(threshold), 4),
        "area_score": round(float(area_score), 4),
        "shape_score": round(float(shape_score), 4),
        "fill_score": round(float(fill_score), 4),
        "center_score": round(float(center_score), 4),
        "ring_score": round(float(ring_score), 4),
        "color_score": round(float(color_score), 4),
        "saturation_score": round(float(saturation_score), 4),
        "texture_score": round(float(texture_score), 4),
    }


def save_accepted_frame(session: Session, frame_id: int, frame: np.ndarray) -> str:
    accepted_dir = Path(session.artifacts_dir) / "accepted"
    accepted_dir.mkdir(parents=True, exist_ok=True)
    frame_path = accepted_dir / f"frame_{frame_id:06d}.jpg"
    cv2.imwrite(str(frame_path), frame)
    return str(frame_path)


def save_rejected_frame(session: Session, frame_id: int, frame: np.ndarray) -> str:
    rejected_dir = Path(session.artifacts_dir) / "rejected"
    rejected_dir.mkdir(parents=True, exist_ok=True)
    frame_path = rejected_dir / f"frame_{frame_id:06d}.jpg"
    cv2.imwrite(str(frame_path), frame)
    return str(frame_path)


def log_frame_metrics(
    session: Session,
    frame_id: int,
    utility: float,
    accepted: bool,
    reasons: list[str],
    metrics: dict[str, float],
    retina: dict[str, float | bool],
) -> None:
    log_path = Path(session.artifacts_dir) / "frame_metrics.jsonl"
    payload = {
        "frame_id": frame_id,
        "utility": round(utility, 4),
        "accepted": accepted,
        "reasons": reasons,
        "metrics": metrics,
        "retina": retina,
    }
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload) + "\n")


def update_mosaic(session: Session, frame: np.ndarray) -> str:
    if session.canvas is None:
        session.canvas = frame.copy()
    else:
        canvas = session.canvas
        h = min(canvas.shape[0], frame.shape[0])
        w = min(canvas.shape[1], frame.shape[1])
        alpha = 0.2
        canvas[:h, :w] = (canvas[:h, :w] * (1 - alpha) + frame[:h, :w] * alpha).astype(canvas.dtype)
        session.canvas = canvas

    mosaic_path = Path(session.artifacts_dir) / "mosaic.jpg"
    cv2.imwrite(str(mosaic_path), session.canvas)
    session.mosaic_path = str(mosaic_path)
    return str(mosaic_path)


def evaluate_frame(session: Session, frame_id: int, frame: np.ndarray, accept_threshold: float = 0.72) -> dict[str, Any]:
    metrics = score_frame(frame)
    retina = detect_retina(frame)
    utility = float(metrics["utility"])
    retina_detected = bool(retina["detected"])
    retina_confidence = float(retina["confidence"])
    accepted = retina_detected and (utility >= accept_threshold)

    session.total_frames += 1
    reasons = [] if accepted else (["retina_not_detected"] if not retina_detected else ["low_utility"])

    if accepted:
        session.accepted_frames += 1
        save_accepted_frame(session, frame_id, frame)
        update_mosaic(session, frame)
        session.coverage = min(1.0, session.coverage + 0.008 + utility * 0.004)
        session.quality_score = min(1.0, max(session.quality_score, utility))
    elif frame_id % 6 == 0:
        # Sample rejected frames for future detector training datasets.
        save_rejected_frame(session, frame_id, frame)

    if session.total_frames > 0:
        session.reject_ratio = max(0.0, 1.0 - (session.accepted_frames / session.total_frames))

    log_frame_metrics(
        session=session,
        frame_id=frame_id,
        utility=utility,
        accepted=accepted,
        reasons=reasons,
        metrics=metrics,
        retina=retina,
    )

    return {
        "accepted": accepted,
        "utility": utility,
        "retina_detected": retina_detected,
        "retina_confidence": retina_confidence,
        "reasons": reasons,
        "metrics": metrics,
        "retina": retina,
    }
