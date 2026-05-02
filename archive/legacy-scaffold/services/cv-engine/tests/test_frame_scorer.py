import numpy as np

from engine.frame_scorer import score_frame


def test_score_frame_shape() -> None:
    frame = np.zeros((128, 128, 3), dtype=np.uint8)
    result = score_frame(frame)
    assert set(result.keys()) == {"sharpness", "contrast", "glare", "utility"}


def test_score_bounds() -> None:
    frame = np.random.randint(0, 255, size=(64, 64, 3), dtype=np.uint8)
    result = score_frame(frame)
    assert 0.0 <= result["utility"] <= 1.0
