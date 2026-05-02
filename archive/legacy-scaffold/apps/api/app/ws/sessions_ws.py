import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.services.frame_pipeline import decode_frame_chunk, evaluate_frame
from app.services.session_store import store

router = APIRouter(tags=["ws"])

MOVE_VALUE = {"left": -0.25, "right": 0.25, "hold": 0.0}
VERTICAL_VALUE = {"up": -0.18, "down": 0.18, "hold": 0.0}


def _compose_message(move_x: str, move_y: str, zoom: str) -> str:
    parts: list[str] = []
    if move_x != "hold":
        parts.append(f"move {move_x}")
    if move_y != "hold":
        parts.append(f"move {move_y}")
    if zoom != "hold":
        parts.append(f"zoom {zoom}")
    if not parts:
        return "Hold position"
    return ", ".join(parts).capitalize()


def _guidance_from_state(coverage: float, utility: float, retina_lock: bool) -> dict[str, object]:
    if not retina_lock:
        move_x = "hold"
        move_y = "hold"
        zoom = "in"
        return {
            "type": "guidance.vector",
            "dx": MOVE_VALUE[move_x],
            "dy": VERTICAL_VALUE[move_y],
            "move_x": move_x,
            "move_y": move_y,
            "zoom": zoom,
            "message": "Searching retina. Center pupil and move closer.",
        }

    if coverage < 0.33:
        move_x = "left"
        move_y = "hold"
    elif coverage < 0.66:
        move_x = "right"
        move_y = "up"
    elif coverage < 0.9:
        move_x = "left"
        move_y = "down"
    else:
        move_x = "hold"
        move_y = "hold"

    if utility < 0.68:
        zoom = "in"
    elif utility > 0.9:
        zoom = "out"
    else:
        zoom = "hold"

    return {
        "type": "guidance.vector",
        "dx": MOVE_VALUE[move_x],
        "dy": VERTICAL_VALUE[move_y],
        "move_x": move_x,
        "move_y": move_y,
        "zoom": zoom,
        "message": _compose_message(move_x, move_y, zoom),
    }


def _update_retina_lock(session, retina_detected: bool, retina_confidence: float) -> dict[str, object]:
    session.retina_confidence = retina_confidence
    previous_lock = session.retina_lock

    if retina_detected:
        session.retina_positive_streak += 1
        session.retina_negative_streak = 0
        if session.retina_positive_streak >= 3:
            session.retina_lock = True
    else:
        session.retina_negative_streak += 1
        session.retina_positive_streak = 0
        if session.retina_negative_streak >= 2:
            session.retina_lock = False

    lock_changed = session.retina_lock != previous_lock
    if session.retina_lock:
        message = "Retina lock acquired. Auto-capture active."
    else:
        message = "Retina not detected. Reposition to reacquire lock."

    return {
        "type": "retina.detected",
        "detected": retina_detected,
        "confidence": round(retina_confidence, 3),
        "lock": session.retina_lock,
        "lock_changed": lock_changed,
        "message": message,
    }


@router.websocket("/ws/sessions/{session_id}")
async def session_socket(websocket: WebSocket, session_id: str) -> None:
    session = store.get(session_id)
    if not session:
        await websocket.close(code=1008)
        return

    await websocket.accept()

    try:
        while True:
            raw = await websocket.receive_text()
            message = json.loads(raw)
            event_type = message.get("type")

            if event_type in {"frame.meta", "frame.chunk"}:
                frame_id = int(message.get("frame_id", 0))
                if event_type == "frame.chunk":
                    frame = decode_frame_chunk(str(message.get("image_b64", "")))
                    if frame is None:
                        utility = 0.0
                        accepted = False
                        retina_detected = False
                        retina_confidence = 0.0
                        reasons = ["decode_error"]
                    else:
                        evaluated = evaluate_frame(session, frame_id, frame)
                        utility = float(evaluated["utility"])
                        accepted = bool(evaluated["accepted"])
                        retina_detected = bool(evaluated["retina_detected"])
                        retina_confidence = float(evaluated["retina_confidence"])
                        reasons = list(evaluated["reasons"])
                else:
                    utility = min(0.85, 0.5 + (frame_id % 20) / 100)
                    accepted = utility > 0.78
                    retina_detected = True
                    retina_confidence = 0.5
                    reasons = [] if accepted else ["metadata_only_mode"]
                    session.total_frames += 1

                if accepted and event_type == "frame.meta":
                    session.accepted_frames += 1
                    session.coverage = min(1.0, session.coverage + 0.008)
                    session.quality_score = min(1.0, max(session.quality_score, utility))

                if session.total_frames > 0:
                    session.reject_ratio = max(0.0, 1.0 - (session.accepted_frames / session.total_frames))

                await websocket.send_json(
                    {
                        "type": "frame.score",
                        "frame_id": frame_id,
                        "utility": round(utility, 3),
                        "accepted": accepted,
                        "reasons": reasons,
                    }
                )

                retina_event = _update_retina_lock(session, retina_detected, retina_confidence)
                await websocket.send_json(retina_event)

                await websocket.send_json(
                    _guidance_from_state(session.coverage, utility, session.retina_lock)
                )

                await websocket.send_json(
                    {
                        "type": "coverage.update",
                        "coverage": round(session.coverage, 3),
                        "missing_regions": ["macula_inferior"] if session.coverage < 0.85 else [],
                    }
                )

                if session.coverage >= 0.85 and session.quality_score >= 0.8:
                    await websocket.send_json(
                        {
                            "type": "session.ready_to_complete",
                            "min_criteria_met": True,
                        }
                    )

            elif event_type == "session.init":
                await websocket.send_json({"type": "session.ack", "session_id": session_id})

    except WebSocketDisconnect:
        return
