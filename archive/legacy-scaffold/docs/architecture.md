# Architecture

## Runtime flow

1. Browser captures camera stream.
2. Browser sends frame metadata and sampled frame payloads over websocket.
3. API delegates scoring/stitching logic to CV engine modules.
4. API emits `frame.score`, `guidance.vector`, `coverage.update` events.
5. Browser updates mosaic canvas and guidance arrows in near real-time.

## Separation

- Frontend handles UX and rendering.
- API handles orchestration/session state.
- CV engine handles deterministic image processing primitives.
