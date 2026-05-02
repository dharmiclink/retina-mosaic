export type SessionInit = {
  type: "session.init";
  session_id: string;
  fps: number;
  resolution: [number, number];
};

export type FrameMeta = {
  type: "frame.meta";
  frame_id: number;
  ts_ms: number;
  exposure?: number;
};

export type FrameChunk = {
  type: "frame.chunk";
  frame_id: number;
  ts_ms: number;
  width: number;
  height: number;
  mime: "image/jpeg";
  image_b64: string;
};

export type GuidanceVector = {
  type: "guidance.vector";
  dx: number;
  dy: number;
  move_x: "left" | "right" | "hold";
  move_y: "up" | "down" | "hold";
  zoom: "in" | "out" | "hold";
  message: string;
};

export type RetinaDetected = {
  type: "retina.detected";
  detected: boolean;
  confidence: number;
  lock: boolean;
  lock_changed: boolean;
  message: string;
};

export type SessionAck = {
  type: "session.ack";
  session_id: string;
};

export type CoverageUpdate = {
  type: "coverage.update";
  coverage: number;
  missing_regions: string[];
};
