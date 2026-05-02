#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

FEATURE_NAMES = [
    "area_score",
    "shape_score",
    "fill_score",
    "center_score",
    "ring_score",
    "color_score",
    "saturation_score",
    "texture_score",
]


@dataclass
class Dataset:
    x: np.ndarray
    y: np.ndarray
    sessions: set[str]


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Train retina detector weights from captured frame metrics.",
    )
    parser.add_argument(
        "--sessions-root",
        type=Path,
        default=root / "artifacts" / "sessions",
        help="Root directory containing session artifact folders.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "app" / "models" / "retina_detector_weights.json",
        help="Output JSON for trained detector weights.",
    )
    parser.add_argument("--epochs", type=int, default=1400, help="Gradient descent epochs.")
    parser.add_argument("--lr", type=float, default=0.08, help="Learning rate.")
    parser.add_argument("--l2", type=float, default=0.001, help="L2 regularization.")
    parser.add_argument(
        "--val-split",
        type=float,
        default=0.2,
        help="Validation split ratio (0.0 - 0.5).",
    )
    parser.add_argument("--seed", type=int, default=42, help="Random seed.")
    parser.add_argument(
        "--label-mode",
        choices=["retina_reason", "accepted_only"],
        default="retina_reason",
        help=(
            "retina_reason: positive unless reasons include retina_not_detected/decode_error. "
            "accepted_only: positive only when accepted=true."
        ),
    )
    return parser.parse_args()


def sigmoid(values: np.ndarray) -> np.ndarray:
    clipped = np.clip(values, -40.0, 40.0)
    return 1.0 / (1.0 + np.exp(-clipped))


def label_from_row(row: dict[str, object], label_mode: str) -> int:
    accepted = bool(row.get("accepted", False))
    reasons = [str(reason) for reason in row.get("reasons", [])]
    if label_mode == "accepted_only":
        return int(accepted)
    if any(reason in {"retina_not_detected", "decode_error"} for reason in reasons):
        return 0
    return 1


def load_dataset(sessions_root: Path, label_mode: str) -> Dataset:
    rows: list[list[float]] = []
    labels: list[int] = []
    sessions_used: set[str] = set()

    if not sessions_root.exists():
        raise FileNotFoundError(f"Session root not found: {sessions_root}")

    for metrics_file in sorted(sessions_root.glob("*/frame_metrics.jsonl")):
        session_id = metrics_file.parent.name
        sessions_used.add(session_id)
        with metrics_file.open("r", encoding="utf-8") as handle:
            for raw in handle:
                raw = raw.strip()
                if not raw:
                    continue
                row = json.loads(raw)
                retina = row.get("retina", {})
                if not isinstance(retina, dict):
                    continue

                try:
                    feature_values = [float(retina[name]) for name in FEATURE_NAMES]
                except Exception:
                    continue

                label = label_from_row(row, label_mode)
                rows.append(feature_values)
                labels.append(label)

    if not rows:
        raise RuntimeError("No training data found. Capture sessions first to generate frame_metrics.jsonl.")

    return Dataset(
        x=np.asarray(rows, dtype=np.float64),
        y=np.asarray(labels, dtype=np.float64),
        sessions=sessions_used,
    )


def split_dataset(x: np.ndarray, y: np.ndarray, val_split: float, seed: int) -> tuple[np.ndarray, ...]:
    rng = np.random.default_rng(seed)
    pos_idx = np.where(y == 1)[0]
    neg_idx = np.where(y == 0)[0]
    rng.shuffle(pos_idx)
    rng.shuffle(neg_idx)

    if x.shape[0] < 8 or len(pos_idx) == 0 or len(neg_idx) == 0:
        return x, y, x, y

    val_pos = int(round(len(pos_idx) * val_split))
    val_neg = int(round(len(neg_idx) * val_split))
    val_pos = max(1, min(len(pos_idx) - 1, val_pos))
    val_neg = max(1, min(len(neg_idx) - 1, val_neg))

    val_idx = np.concatenate([pos_idx[:val_pos], neg_idx[:val_neg]])
    train_idx = np.concatenate([pos_idx[val_pos:], neg_idx[val_neg:]])
    rng.shuffle(val_idx)
    rng.shuffle(train_idx)
    return x[train_idx], y[train_idx], x[val_idx], y[val_idx]


def standardize(x_train: np.ndarray, x_val: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    mean = x_train.mean(axis=0)
    std = x_train.std(axis=0)
    std = np.where(std < 1e-8, 1.0, std)
    return (x_train - mean) / std, (x_val - mean) / std, mean, std


def train_logistic(
    x_train: np.ndarray,
    y_train: np.ndarray,
    epochs: int,
    lr: float,
    l2: float,
) -> tuple[np.ndarray, float]:
    n_samples, n_features = x_train.shape
    weights = np.zeros(n_features, dtype=np.float64)
    bias = 0.0

    for _ in range(epochs):
        logits = x_train @ weights + bias
        probs = sigmoid(logits)
        error = probs - y_train

        grad_w = (x_train.T @ error) / n_samples + l2 * weights
        grad_b = float(np.mean(error))

        weights -= lr * grad_w
        bias -= lr * grad_b

    return weights, bias


def metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict[str, float]:
    y_true = y_true.astype(int)
    y_pred = y_pred.astype(int)
    tp = int(np.sum((y_true == 1) & (y_pred == 1)))
    tn = int(np.sum((y_true == 0) & (y_pred == 0)))
    fp = int(np.sum((y_true == 0) & (y_pred == 1)))
    fn = int(np.sum((y_true == 1) & (y_pred == 0)))
    total = max(1, tp + tn + fp + fn)

    precision = tp / max(1, tp + fp)
    recall = tp / max(1, tp + fn)
    f1 = 0.0 if precision + recall == 0 else 2 * precision * recall / (precision + recall)
    accuracy = (tp + tn) / total
    return {
        "accuracy": round(float(accuracy), 4),
        "precision": round(float(precision), 4),
        "recall": round(float(recall), 4),
        "f1": round(float(f1), 4),
        "tp": tp,
        "tn": tn,
        "fp": fp,
        "fn": fn,
    }


def pick_threshold(y_true: np.ndarray, probs: np.ndarray) -> float:
    best_threshold = 0.5
    best_f1 = -1.0
    best_acc = -1.0
    for threshold in np.linspace(0.2, 0.85, 66):
        pred = (probs >= threshold).astype(int)
        m = metrics(y_true, pred)
        if (m["f1"] > best_f1) or (m["f1"] == best_f1 and m["accuracy"] > best_acc):
            best_threshold = float(threshold)
            best_f1 = float(m["f1"])
            best_acc = float(m["accuracy"])
    return best_threshold


def main() -> None:
    args = parse_args()
    dataset = load_dataset(args.sessions_root, args.label_mode)

    x_train, y_train, x_val, y_val = split_dataset(dataset.x, dataset.y, args.val_split, args.seed)
    x_train_norm, x_val_norm, mean, std = standardize(x_train, x_val)

    weights, bias = train_logistic(
        x_train=x_train_norm,
        y_train=y_train,
        epochs=args.epochs,
        lr=args.lr,
        l2=args.l2,
    )

    train_probs = sigmoid(x_train_norm @ weights + bias)
    val_probs = sigmoid(x_val_norm @ weights + bias)
    threshold = pick_threshold(y_val, val_probs)

    train_pred = (train_probs >= threshold).astype(int)
    val_pred = (val_probs >= threshold).astype(int)

    result = {
        "version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "label_mode": args.label_mode,
        "feature_names": FEATURE_NAMES,
        "features": FEATURE_NAMES,
        "weights": [round(float(value), 8) for value in weights.tolist()],
        "bias": round(float(bias), 8),
        "threshold": round(float(threshold), 6),
        "mean": {name: round(float(mean[idx]), 8) for idx, name in enumerate(FEATURE_NAMES)},
        "std": {name: round(float(std[idx]), 8) for idx, name in enumerate(FEATURE_NAMES)},
        "dataset": {
            "samples": int(dataset.x.shape[0]),
            "positive": int(dataset.y.sum()),
            "negative": int(dataset.x.shape[0] - dataset.y.sum()),
            "sessions_used": sorted(dataset.sessions),
        },
        "train_metrics": metrics(y_train, train_pred),
        "val_metrics": metrics(y_val, val_pred),
        "training": {
            "epochs": args.epochs,
            "learning_rate": args.lr,
            "l2": args.l2,
            "seed": args.seed,
        },
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Saved model to: {args.output}")
    print(json.dumps(result["val_metrics"], indent=2))


if __name__ == "__main__":
    main()
