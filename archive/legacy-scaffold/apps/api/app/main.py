from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.reports import router as reports_router
from app.routes.sessions import router as sessions_router
from app.ws.sessions_ws import router as ws_router

app = FastAPI(title="Retina Mosaic API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sessions_router, prefix="/v1")
app.include_router(reports_router, prefix="/v1")
app.include_router(ws_router, prefix="/v1")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
