"use client";

import { useEffect, useRef } from "react";

type MosaicCanvasProps = {
  coverage: number;
  missingRegions: string[];
};

export default function MosaicCanvas({ coverage, missingRegions }: MosaicCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    ctx.fillStyle = "#0b1a1f";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = "#1a7f6f";
    ctx.beginPath();
    ctx.arc(180, 140, 95, 0, Math.PI * 2);
    ctx.fill();

    ctx.globalAlpha = 1 - Math.max(0, Math.min(coverage, 1));
    ctx.fillStyle = "#070f12";
    ctx.beginPath();
    ctx.arc(180, 140, 95, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;

    ctx.fillStyle = "#0b1a1f";
    if (missingRegions.length > 0) {
      ctx.beginPath();
      ctx.arc(240, 165, 34, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.strokeStyle = "#d5fff8";
    ctx.lineWidth = 2;
    ctx.strokeRect(18, 18, canvas.width - 36, canvas.height - 36);

    ctx.fillStyle = "#d5fff8";
    ctx.font = "14px sans-serif";
    ctx.fillText("Live Mosaic Preview", 24, 34);
    ctx.fillText(`Coverage ${(coverage * 100).toFixed(0)}%`, 24, 54);
  }, [coverage, missingRegions]);

  return (
    <div className="rounded-lg bg-slate-900 p-2">
      <canvas ref={canvasRef} width={360} height={280} className="h-72 w-full rounded" />
    </div>
  );
}
