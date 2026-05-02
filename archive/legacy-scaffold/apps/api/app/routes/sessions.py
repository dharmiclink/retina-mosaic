from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request

from app.schemas.sessions import (
    SessionCompleteRequest,
    SessionCompleteResponse,
    SessionCreateRequest,
    SessionCreateResponse,
    SessionStatusResponse,
)
from app.services.session_store import store

router = APIRouter(tags=["sessions"])


@router.post("/sessions", response_model=SessionCreateResponse)
def create_session(payload: SessionCreateRequest, request: Request) -> SessionCreateResponse:
    session = store.create(
        patient_ref=payload.patient_ref,
        device_id=payload.device_id,
        mode=payload.mode,
    )

    ws_scheme = "wss" if request.url.scheme == "https" else "ws"
    ws_url = f"{ws_scheme}://{request.url.netloc}/v1/ws/sessions/{session.id}"

    return SessionCreateResponse(
        session_id=session.id,
        ws_url=ws_url,
        upload_fps=20,
    )


@router.get("/sessions/{session_id}", response_model=SessionStatusResponse)
def get_session(session_id: str) -> SessionStatusResponse:
    session = store.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    now = datetime.now(timezone.utc)
    duration = int((now - session.started_at).total_seconds())
    return SessionStatusResponse(
        status=session.status,
        coverage=round(session.coverage, 3),
        quality_score=round(session.quality_score, 3),
        duration_sec=max(duration, 0),
    )


@router.post("/sessions/{session_id}/complete", response_model=SessionCompleteResponse)
def complete_session(session_id: str, payload: SessionCompleteRequest) -> SessionCompleteResponse:
    _ = payload
    session = store.complete(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return SessionCompleteResponse(status=session.status)
