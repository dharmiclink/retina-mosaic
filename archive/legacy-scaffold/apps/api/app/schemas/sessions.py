from pydantic import BaseModel


class SessionCreateRequest(BaseModel):
    patient_ref: str
    device_id: str
    mode: str = "video_mosaic"


class SessionCreateResponse(BaseModel):
    session_id: str
    ws_url: str
    upload_fps: int


class SessionStatusResponse(BaseModel):
    status: str
    coverage: float
    quality_score: float
    duration_sec: int


class SessionCompleteRequest(BaseModel):
    operator_id: str
    notes: str | None = None


class SessionCompleteResponse(BaseModel):
    status: str
