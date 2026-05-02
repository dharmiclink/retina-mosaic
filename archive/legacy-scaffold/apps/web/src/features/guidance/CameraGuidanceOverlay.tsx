type CameraGuidanceOverlayProps = {
  moveX: "left" | "right" | "hold";
  moveY: "up" | "down" | "hold";
  zoom: "in" | "out" | "hold";
  retinaLock: boolean;
  retinaConfidence: number;
  retinaMessage: string;
  message: string;
};

function asMoveLabel(moveX: "left" | "right" | "hold", moveY: "up" | "down" | "hold"): string {
  const tokens: string[] = [];
  if (moveX !== "hold") tokens.push(moveX);
  if (moveY !== "hold") tokens.push(moveY);
  return tokens.length > 0 ? `Move ${tokens.join(" + ")}` : "Hold position";
}

function asZoomLabel(zoom: "in" | "out" | "hold"): string {
  if (zoom === "hold") return "Zoom hold";
  return zoom === "in" ? "Zoom in" : "Zoom out";
}

export default function CameraGuidanceOverlay({
  moveX,
  moveY,
  zoom,
  retinaLock,
  retinaConfidence,
  retinaMessage,
  message
}: CameraGuidanceOverlayProps) {
  const moveLabel = asMoveLabel(moveX, moveY);
  const zoomLabel = asZoomLabel(zoom);
  const lockLabel = retinaLock ? "Retina lock: ON" : "Retina lock: SEARCHING";

  return (
    <div className="pointer-events-none absolute inset-0 flex flex-col justify-between p-3">
      <div className="self-end rounded-md bg-black/60 px-3 py-2 text-xs text-white">
        <p className={retinaLock ? "text-emerald-300" : "text-amber-300"}>{lockLabel}</p>
        <p>Confidence {(retinaConfidence * 100).toFixed(0)}%</p>
        <p>{moveLabel}</p>
        <p>{zoomLabel}</p>
      </div>
      <div className="self-start rounded-md bg-black/60 px-3 py-2 text-xs text-white">
        <p>{retinaMessage}</p>
        <p>{message}</p>
      </div>
    </div>
  );
}
