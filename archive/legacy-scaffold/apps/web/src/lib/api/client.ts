const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

export type SessionCreateResponse = {
  session_id: string;
  ws_url: string;
  upload_fps: number;
};

export async function createSession(): Promise<SessionCreateResponse> {
  const res = await fetch(`${API_BASE}/v1/sessions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ patient_ref: "anon-001", device_id: "web-device", mode: "video_mosaic" })
  });

  if (!res.ok) {
    throw new Error(`Failed to create session (${res.status})`);
  }

  return res.json();
}

export async function completeSession(sessionId: string): Promise<{ status: string }> {
  const res = await fetch(`${API_BASE}/v1/sessions/${sessionId}/complete`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ operator_id: "web-operator", notes: "Completed from web client." })
  });

  if (!res.ok) {
    throw new Error(`Failed to complete session (${res.status})`);
  }

  return res.json();
}

export function toBrowserWebSocketUrl(url: string): string {
  if (url.startsWith("ws://") || url.startsWith("wss://")) {
    return url;
  }
  if (url.startsWith("http://")) {
    return url.replace("http://", "ws://");
  }
  if (url.startsWith("https://")) {
    return url.replace("https://", "wss://");
  }
  return `ws://${url}`;
}
