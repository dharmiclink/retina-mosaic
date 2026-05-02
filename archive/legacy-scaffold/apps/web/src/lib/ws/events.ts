export type ServerEvent =
  | { type: "session.ack"; session_id: string }
  | { type: "frame.score"; frame_id: number; utility: number; accepted: boolean; reasons: string[] }
  | {
      type: "retina.detected";
      detected: boolean;
      confidence: number;
      lock: boolean;
      lock_changed: boolean;
      message: string;
    }
  | {
      type: "guidance.vector";
      dx: number;
      dy: number;
      move_x: "left" | "right" | "hold";
      move_y: "up" | "down" | "hold";
      zoom: "in" | "out" | "hold";
      message: string;
    }
  | { type: "coverage.update"; coverage: number; missing_regions: string[] }
  | { type: "session.ready_to_complete"; min_criteria_met: boolean };

export type ClientEvent =
  | { type: "session.init"; session_id: string; fps: number; resolution: [number, number] }
  | { type: "frame.meta"; frame_id: number; ts_ms: number; exposure?: number }
  | {
      type: "frame.chunk";
      frame_id: number;
      ts_ms: number;
      width: number;
      height: number;
      mime: "image/jpeg";
      image_b64: string;
    };
