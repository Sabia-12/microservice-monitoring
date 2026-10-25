/**
 * API client for the Microservice Monitoring backend.
 *
 * Base URL is read from the Vite environment variable VITE_API_BASE_URL.
 * Set this in a `.env` file at the frontend root for local development:
 *   VITE_API_BASE_URL=http://localhost:8000
 */

const BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined) ??
  "http://localhost:8000";

/** Generic JSON fetch wrapper with error handling. */
async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const url = `${BASE_URL}${path}`;
  const response = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      ...init?.headers,
    },
    ...init,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`API error ${response.status} for ${url}: ${text}`);
  }

  return response.json() as Promise<T>;
}

// ── Typed API methods ─────────────────────────────────────────────────────────

/** Response type for GET /api/v1/health */
export interface HealthResponse {
  status: string;
  version: string;
}

/** Check backend liveness. */
export async function getHealth(): Promise<HealthResponse> {
  return apiFetch<HealthResponse>("/api/v1/health");
}

/**
 * Create an SSE connection to the live event stream.
 *
 * @param onMessage - Callback invoked with each parsed event payload.
 * @param onError   - Optional error handler.
 * @returns The underlying EventSource (call .close() to disconnect).
 */
export function connectEventStream(
  onMessage: (data: unknown) => void,
  onError?: (event: Event) => void,
): EventSource {
  const es = new EventSource(`${BASE_URL}/api/v1/events`);
  es.onmessage = (event) => {
    try {
      onMessage(JSON.parse(event.data as string));
    } catch {
      onMessage(event.data);
    }
  };
  if (onError) es.onerror = onError;
  return es;
}

export default apiFetch;
