# Retina Mosaic Web App Scaffold

Monorepo scaffold for a continuous video-stream retinal mosaicking system.

## Layout

- `apps/web`: Next.js frontend for capture, live mosaic, and operator guidance.
- `apps/api`: FastAPI backend for session APIs and websocket realtime loop.
- `services/cv-engine`: Python CV modules (frame scoring, stitching, guidance).
- `packages/contracts`: OpenAPI + websocket event contracts.
- `packages/ui`: Shared UI primitives.
- `infra`: Dockerfiles and local compose stack.
- `docs`: Architecture and contract notes.

## Quick start

### Frontend

```bash
cd apps/web
npm install
npm run dev
```

### API

```bash
cd apps/api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### CV engine tests

```bash
cd services/cv-engine
python3 -m pytest
```

### Train Retina Detector

```bash
cd apps/api
source .venv/bin/activate
python scripts/train_retina_detector.py
```

This writes model weights to `apps/api/app/models/retina_detector_weights.json`.
Use `python scripts/train_retina_detector.py --help` for options such as `--label-mode`.
