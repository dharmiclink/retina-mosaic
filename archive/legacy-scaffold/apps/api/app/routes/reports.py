from fastapi import APIRouter, HTTPException

from app.services.session_store import store

router = APIRouter(tags=["reports"])


@router.get("/sessions/{session_id}/report")
def get_report(session_id: str) -> dict[str, object]:
    session = store.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    return {
        "status": "ready" if session.status != "active" else "in_progress",
        "mosaic_url": session.mosaic_path,
        "coverage_score": round(session.coverage, 2),
        "quality_score": round(session.quality_score, 2),
        "rejected_frame_ratio": round(session.reject_ratio, 2),
        "total_frames": session.total_frames,
        "accepted_frames": session.accepted_frames,
        "retina_lock": session.retina_lock,
        "retina_confidence": round(session.retina_confidence, 3),
        "artifacts_dir": session.artifacts_dir,
    }
