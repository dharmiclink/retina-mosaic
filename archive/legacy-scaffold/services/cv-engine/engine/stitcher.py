from __future__ import annotations

from typing import Any

import numpy as np


def stitch_incremental(canvas: np.ndarray, frame: np.ndarray, transform: np.ndarray | None = None) -> dict[str, Any]:
    """Placeholder incremental stitch logic.

    This function should be replaced by feature-based registration and blending.
    """
    if canvas.ndim != 3 or frame.ndim != 3:
        raise ValueError("Canvas and frame must be HxWxC arrays")

    h = min(canvas.shape[0], frame.shape[0])
    w = min(canvas.shape[1], frame.shape[1])
    alpha = 0.2
    canvas[:h, :w] = (canvas[:h, :w] * (1 - alpha) + frame[:h, :w] * alpha).astype(canvas.dtype)

    return {
        "transform": transform.tolist() if transform is not None else np.eye(3).tolist(),
        "blended_region": [0, 0, int(w), int(h)],
    }
