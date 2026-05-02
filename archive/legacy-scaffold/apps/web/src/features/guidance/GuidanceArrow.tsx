type GuidanceArrowProps = {
  dx: number;
  dy: number;
  moveX: "left" | "right" | "hold";
  moveY: "up" | "down" | "hold";
  zoom: "in" | "out" | "hold";
  message: string;
};

export default function GuidanceArrow({ dx, dy, moveX, moveY, zoom, message }: GuidanceArrowProps) {
  const magnitude = Math.min(1, Math.sqrt(dx * dx + dy * dy));
  const angle = Math.atan2(dy, dx) * (180 / Math.PI);
  const moveText = [moveX, moveY].filter((value) => value !== "hold").join(" + ") || "hold";

  return (
    <div className="rounded-xl bg-white/90 p-4 shadow-md">
      <h2 className="text-lg font-semibold">Operator Guidance</h2>
      <div className="mt-3 flex items-center gap-4">
        <div className="relative h-20 w-20 rounded-full border border-slate-300">
          <div
            className="absolute left-1/2 top-1/2 h-1 w-8 origin-left rounded bg-accent"
            style={{
              transform: `translate(-2px, -50%) rotate(${angle}deg) scaleX(${0.3 + magnitude})`
            }}
          />
        </div>
        <div className="space-y-1 text-sm text-slate-700">
          <p>{message}</p>
          <p>Move: {moveText}</p>
          <p>Zoom: {zoom === "hold" ? "hold" : `zoom ${zoom}`}</p>
        </div>
      </div>
    </div>
  );
}
