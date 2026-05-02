type SessionHUDProps = {
  sessionId: string | null;
  wsState: "idle" | "connecting" | "connected" | "closed" | "error";
  coverage: number;
  quality: number;
  retinaDetected: boolean;
  retinaLock: boolean;
  retinaConfidence: number;
  retinaMessage: string;
  rejectRatio: number;
  acceptedFrames: number;
  totalFrames: number;
  readyToComplete: boolean;
};

export default function SessionHUD({
  sessionId,
  wsState,
  coverage,
  quality,
  retinaDetected,
  retinaLock,
  retinaConfidence,
  retinaMessage,
  rejectRatio,
  acceptedFrames,
  totalFrames,
  readyToComplete
}: SessionHUDProps) {
  return (
    <div className="rounded-xl bg-white/90 p-4 shadow-md">
      <h2 className="text-lg font-semibold">Session Metrics</h2>
      <ul className="mt-3 space-y-2 text-sm">
        <li>Session: {sessionId ?? "Not started"}</li>
        <li>WebSocket: {wsState}</li>
        <li>Coverage: {(coverage * 100).toFixed(0)}%</li>
        <li>Quality Score: {(quality * 100).toFixed(0)}%</li>
        <li>Retina detected: {retinaDetected ? "Yes" : "No"}</li>
        <li>Retina lock: {retinaLock ? "Locked" : "Searching"}</li>
        <li>Retina confidence: {(retinaConfidence * 100).toFixed(0)}%</li>
        <li>Retina status: {retinaMessage}</li>
        <li>Rejected Frames: {(rejectRatio * 100).toFixed(0)}%</li>
        <li>
          Accepted Frames: {acceptedFrames}/{totalFrames}
        </li>
        <li>Ready to complete: {readyToComplete ? "Yes" : "No"}</li>
      </ul>
    </div>
  );
}
