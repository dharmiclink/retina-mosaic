from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from uuid import uuid4


@dataclass
class Session:
    id: str
    patient_ref: str
    device_id: str
    mode: str
    status: str = "active"
    coverage: float = 0.0
    quality_score: float = 0.0
    reject_ratio: float = 0.0
    total_frames: int = 0
    accepted_frames: int = 0
    retina_lock: bool = False
    retina_confidence: float = 0.0
    retina_positive_streak: int = 0
    retina_negative_streak: int = 0
    mosaic_path: str | None = None
    artifacts_dir: str = ""
    canvas: Any | None = None
    started_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    ended_at: datetime | None = None
    events: list[dict[str, Any]] = field(default_factory=list)


class SessionStore:
    def __init__(self) -> None:
        self._sessions: dict[str, Session] = {}

    def create(self, patient_ref: str, device_id: str, mode: str) -> Session:
        session_id = f"ses_{uuid4().hex[:8]}"
        artifacts_dir = Path(__file__).resolve().parents[2] / "artifacts" / "sessions" / session_id
        artifacts_dir.mkdir(parents=True, exist_ok=True)

        session = Session(
            id=session_id,
            patient_ref=patient_ref,
            device_id=device_id,
            mode=mode,
            artifacts_dir=str(artifacts_dir),
        )
        self._sessions[session_id] = session
        return session

    def get(self, session_id: str) -> Session | None:
        return self._sessions.get(session_id)

    def complete(self, session_id: str) -> Session | None:
        session = self._sessions.get(session_id)
        if not session:
            return None
        session.status = "processing_report"
        session.ended_at = datetime.now(timezone.utc)
        return session


store = SessionStore()
