import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { completeSession, createSession, toBrowserWebSocketUrl } from "@/lib/api/client";
import type { ClientEvent, ServerEvent } from "@/lib/ws/events";

type GuidanceState = {
  dx: number;
  dy: number;
  moveX: "left" | "right" | "hold";
  moveY: "up" | "down" | "hold";
  zoom: "in" | "out" | "hold";
  message: string;
};

type WsState = "idle" | "connecting" | "connected" | "closed" | "error";

export function useRealtimeSession() {
  const wsRef = useRef<WebSocket | null>(null);
  const frameCounterRef = useRef(0);
  const captureCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const captureInFlightRef = useRef(false);

  const [sessionId, setSessionId] = useState<string | null>(null);
  const [wsState, setWsState] = useState<WsState>("idle");
  const [uploadFps, setUploadFps] = useState(6);
  const [coverage, setCoverage] = useState(0);
  const [quality, setQuality] = useState(0);
  const [retinaDetected, setRetinaDetected] = useState(false);
  const [retinaLock, setRetinaLock] = useState(false);
  const [retinaConfidence, setRetinaConfidence] = useState(0);
  const [retinaMessage, setRetinaMessage] = useState("Retina not detected.");
  const [readyToComplete, setReadyToComplete] = useState(false);
  const [missingRegions, setMissingRegions] = useState<string[]>([]);
  const [guidance, setGuidance] = useState<GuidanceState>({
    dx: 0,
    dy: 0,
    moveX: "hold",
    moveY: "hold",
    zoom: "hold",
    message: "Start session to receive guidance."
  });
  const [totalFrames, setTotalFrames] = useState(0);
  const [acceptedFrames, setAcceptedFrames] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const closeSocket = useCallback(() => {
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
  }, []);

  const handleServerEvent = useCallback((event: ServerEvent) => {
    if (event.type === "frame.score") {
      if (event.accepted) {
        setAcceptedFrames((prev) => prev + 1);
      }
      setTotalFrames((prev) => prev + 1);
      setQuality((prev) => Math.max(prev, event.utility));
      return;
    }

    if (event.type === "guidance.vector") {
      setGuidance({
        dx: event.dx,
        dy: event.dy,
        moveX: event.move_x,
        moveY: event.move_y,
        zoom: event.zoom,
        message: event.message
      });
      return;
    }

    if (event.type === "retina.detected") {
      setRetinaDetected(event.detected);
      setRetinaLock(event.lock);
      setRetinaConfidence(event.confidence);
      setRetinaMessage(event.message);
      return;
    }

    if (event.type === "coverage.update") {
      setCoverage(event.coverage);
      setMissingRegions(event.missing_regions);
      return;
    }

    if (event.type === "session.ready_to_complete") {
      setReadyToComplete(event.min_criteria_met);
    }
  }, []);

  const startSession = useCallback(async () => {
    if (wsRef.current || wsState === "connecting") return;

    setError(null);
    setWsState("connecting");
    setCoverage(0);
    setQuality(0);
    setRetinaDetected(false);
    setRetinaLock(false);
    setRetinaConfidence(0);
    setRetinaMessage("Retina not detected.");
    setReadyToComplete(false);
    setMissingRegions([]);
    setTotalFrames(0);
    setAcceptedFrames(0);
    setUploadFps(6);
    frameCounterRef.current = 0;

    try {
      const created = await createSession();
      const wsUrl = toBrowserWebSocketUrl(created.ws_url);
      setSessionId(created.session_id);
      setUploadFps(Math.max(1, created.upload_fps));

      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        setWsState("connected");
        const initMessage: ClientEvent = {
          type: "session.init",
          session_id: created.session_id,
          fps: created.upload_fps,
          resolution: [720, 720]
        };
        ws.send(JSON.stringify(initMessage));
      };

      ws.onmessage = (messageEvent) => {
        try {
          const event = JSON.parse(messageEvent.data) as ServerEvent;
          handleServerEvent(event);
        } catch {
          setError("Received malformed websocket event.");
        }
      };

      ws.onerror = () => {
        setWsState("error");
        setError("Websocket connection error.");
      };

      ws.onclose = () => {
        setWsState("closed");
        wsRef.current = null;
      };
    } catch (caught) {
      setWsState("error");
      setError(caught instanceof Error ? caught.message : "Failed to start session.");
      closeSocket();
    }
  }, [closeSocket, handleServerEvent, wsState]);

  const sendFrameChunk = useCallback(async (videoElement: HTMLVideoElement | null) => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN || !sessionId) {
      return;
    }
    if (!videoElement || videoElement.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
      return;
    }
    if (captureInFlightRef.current) {
      return;
    }

    const sourceWidth = videoElement.videoWidth;
    const sourceHeight = videoElement.videoHeight;
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return;
    }

    captureInFlightRef.current = true;
    try {
      const targetWidth = 480;
      const targetHeight = Math.max(1, Math.round((sourceHeight / sourceWidth) * targetWidth));

      const canvas = captureCanvasRef.current ?? document.createElement("canvas");
      captureCanvasRef.current = canvas;
      canvas.width = targetWidth;
      canvas.height = targetHeight;

      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.drawImage(videoElement, 0, 0, targetWidth, targetHeight);

      const blob = await new Promise<Blob | null>((resolve) => {
        canvas.toBlob(resolve, "image/jpeg", 0.72);
      });
      if (!blob) return;

      const imageB64 = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
          if (typeof reader.result !== "string") {
            reject(new Error("Failed to encode frame."));
            return;
          }
          const [, data] = reader.result.split(",", 2);
          resolve(data ?? "");
        };
        reader.onerror = () => {
          reject(new Error("Failed to read frame blob."));
        };
        reader.readAsDataURL(blob);
      });

      frameCounterRef.current += 1;
      const payload: ClientEvent = {
        type: "frame.chunk",
        frame_id: frameCounterRef.current,
        ts_ms: Date.now(),
        width: targetWidth,
        height: targetHeight,
        mime: "image/jpeg",
        image_b64: imageB64
      };

      wsRef.current.send(JSON.stringify(payload));
    } finally {
      captureInFlightRef.current = false;
    }
  }, [sessionId]);

  const stopSession = useCallback(async () => {
    const currentSession = sessionId;
    closeSocket();
    setWsState("closed");
    setSessionId(null);
    if (!currentSession) return;
    try {
      await completeSession(currentSession);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Failed to complete session.");
    }
  }, [closeSocket, sessionId]);

  useEffect(() => {
    return () => {
      closeSocket();
    };
  }, [closeSocket]);

  const stats = useMemo(
    () => ({
      totalFrames,
      acceptedFrames,
      rejectedFrames: Math.max(totalFrames - acceptedFrames, 0)
    }),
    [acceptedFrames, totalFrames]
  );

  const rejectRatio = useMemo(() => {
    if (totalFrames <= 0) return 0;
    return Math.max(0, 1 - acceptedFrames / totalFrames);
  }, [acceptedFrames, totalFrames]);

  return {
    sessionId,
    wsState,
    uploadFps,
    coverage,
    quality,
    retinaDetected,
    retinaLock,
    retinaConfidence,
    retinaMessage,
    rejectRatio,
    missingRegions,
    readyToComplete,
    guidance,
    error,
    stats,
    startSession,
    stopSession,
    sendFrameChunk
  };
}
