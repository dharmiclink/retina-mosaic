from __future__ import annotations

import cv2
import numpy as np


def score_frame(frame: np.ndarray) -> dict[str, float]:
    """Score frame utility using simple proxies for sharpness, glare, and contrast."""
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
