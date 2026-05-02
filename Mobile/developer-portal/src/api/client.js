const API_BASE = '/api/v1';

async function request(path, options = {}, token) {
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    throw new Error(errorBody.message || `HTTP ${response.status}`);
  }

  return response.json();
}

export function apiGet(path, token) {
  return request(path, { method: 'GET' }, token);
}

export function apiPost(path, body, token) {
  return request(path, { method: 'POST', body: JSON.stringify(body) }, token);
}

export function apiPut(path, body, token) {
  return request(path, { method: 'PUT', body: JSON.stringify(body) }, token);
}

export function apiDelete(path, token) {
  return request(path, { method: 'DELETE' }, token);
}
