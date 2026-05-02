from __future__ import annotations


def guidance_vector(coverage: float, drift_x: float, drift_y: float) -> dict[str, float | str]:
    if coverage >= 0.9:
        return {"dx": 0.0, "dy": 0.0, "message": "Coverage complete"}

    return {
        "dx": round(-drift_x, 3),
        "dy": round(-drift_y, 3),
        "message": "Tilt device toward uncovered region",
    }
