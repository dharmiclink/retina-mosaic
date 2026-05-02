from __future__ import annotations

import numpy as np


def update_coverage(mask: np.ndarray) -> float:
    """Compute covered ratio from a binary mask where 1 means covered."""
    if mask.size == 0:
        return 0.0
    covered = float((mask > 0).sum())
    return covered / float(mask.size)
