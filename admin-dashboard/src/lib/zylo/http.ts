import { API_URL } from './config';
import { clearToken, getToken } from './auth';

export type ApiError = {
  status: number;
  message: string;
};

export function toErrorMessage(err: unknown, fallback: string): string {
  if (typeof err === 'string' && err.trim()) return err;
  if (err && typeof err === 'object' && 'message' in err) {
    const msg = (err as { message?: unknown }).message;
    if (typeof msg === 'string' && msg.trim()) return msg;
  }
  return fallback;
}

async function parseError(res: Response): Promise<ApiError> {
  const status = res.status;
  const text = await res.text().catch(() => '');
  try {
    const json = JSON.parse(text);
    const message =
      (typeof json?.message === 'string' && json.message) ||
      (Array.isArray(json?.message) ? json.message.join(', ') : '') ||
      (typeof json?.error === 'string' ? json.error : '') ||
      text ||
      `HTTP ${status}`;
    return { status, message };
  } catch {
    return { status, message: text || `HTTP ${status}` };
  }
}

export async function apiFetch(path: string, init?: RequestInit): Promise<Response> {
  const token = getToken();

  const headers = new Headers(init?.headers ?? undefined);
  if (token) headers.set('Authorization', `Bearer ${token}`);

  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers,
  });

  if (res.status === 401) {
    clearToken();
  }

  return res;
}

export async function apiJson<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await apiFetch(path, init);
  if (!res.ok) throw await parseError(res);
  return (await res.json()) as T;
}
