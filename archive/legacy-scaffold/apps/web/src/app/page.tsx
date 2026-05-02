"use client";

import { useCallback, useEffect, useState } from "react";
import SessionHUD from "@/components/SessionHUD";
import MosaicCanvas from "@/features/mosaic/MosaicCanvas";
import GuidanceArrow from "@/features/guidance/GuidanceArrow";
import CameraGuidanceOverlay from "@/features/guidance/CameraGuidanceOverlay";
import { useCamera } from "@/features/capture/useCamera";
import { useRealtimeSession } from "@/features/session/useRealtimeSession";

export default function HomePage() {
  const { videoRef, startCamera, stopCamera, isRunning, error: cameraError } = useCamera();
  const {
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
    error: sessionError,
    stats,
    startSession,
    stopSession,
    sendFrameChunk
  } = useRealtimeSession();
  const [isStarting, setIsStarting] = useState(false);

  const startAll = useCallback(async () => {
    if (isStarting) return;
    setIsStarting(true);
    try {
      const cameraStarted = await startCamera();
      if (!cameraStarted) return;
      await startSession();
    } finally {
      setIsStarting(false);
    }
  }, [isStarting, startCamera, startSession]);

  const stopAll = useCallback(async () => {
    stopCamera();
    await stopSession();
  }, [stopCamera, stopSession]);

  useEffect(() => {
    if (!isRunning || wsState !== "connected") return;
    const intervalMs = Math.max(50, Math.round(1000 / uploadFps));

    const intervalId = window.setInterval(() => {
      void sendFrameChunk(videoRef.current);
    }, intervalMs);

    return () => {
      window.clearInterval(intervalId);
    };
  }, [isRunning, sendFrameChunk, uploadFps, videoRef, wsState]);

  return (
    <main className="min-h-screen p-6">
      <div className="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[1.2fr_1fr]">
        <section className="rounded-xl bg-white/85 p-4 shadow-md">
          <h1 className="text-2xl font-semibold">Continuous Video Mosaicking</h1>
          <p className="mt-1 text-sm text-slate-700">Web MVP shell: capture, live canvas, and guidance stream.</p>

          <div className="mt-4 grid gap-4 md:grid-cols-2">
            <div>
              <div className="relative">
                <video
                  ref={videoRef}
                  autoPlay
                  muted
                  playsInline
                  className="h-72 w-full rounded-lg bg-slate-900 object-cover"
                />
                <CameraGuidanceOverlay
                  moveX={guidance.moveX}
                  moveY={guidance.moveY}
                  zoom={guidance.zoom}
                  retinaLock={retinaLock}
                  retinaConfidence={retinaConfidence}
                  retinaMessage={retinaMessage}
                  message={guidance.message}
                />
              </div>
              <div className="mt-3 flex gap-2">
                <button
                  className="rounded-md bg-accent px-4 py-2 text-white"
                  onClick={startAll}
                  disabled={isRunning || isStarting}
                >
                  {isStarting ? "Starting..." : "Start Session"}
                </button>
                <button
                  className="rounded-md border border-slate-400 px-4 py-2"
                  onClick={() => void stopAll()}
                  disabled={!isRunning}
                >
                  Stop Session
                </button>
              </div>
              {(cameraError || sessionError) && (
                <p className="mt-3 text-sm text-red-700">{cameraError ?? sessionError}</p>
              )}
            </div>
            <MosaicCanvas coverage={coverage} missingRegions={missingRegions} />
          </div>
        </section>

        <aside className="space-y-4">
          <SessionHUD
            sessionId={sessionId}
            wsState={wsState}
            coverage={coverage}
            quality={quality}
            retinaDetected={retinaDetected}
            retinaLock={retinaLock}
            retinaConfidence={retinaConfidence}
            retinaMessage={retinaMessage}
            rejectRatio={rejectRatio}
            acceptedFrames={stats.acceptedFrames}
            totalFrames={stats.totalFrames}
            readyToComplete={readyToComplete}
          />
          <GuidanceArrow
            dx={guidance.dx}
            dy={guidance.dy}
            moveX={guidance.moveX}
            moveY={guidance.moveY}
            zoom={guidance.zoom}
            message={guidance.message}
          />
        </aside>
      </div>
    </main>
  );
}
