const assert = require('node:assert/strict');
const { test } = require('node:test');

process.env.EXPOSE_API_DEBUG_HEADERS = 'true';

const { app } = require('../server');

async function request(path, headers = {}) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}${path}`, { headers });
    return {
      status: response.status,
      headers: response.headers,
      body: await response.json(),
    };
  } finally {
    server.close();
  }
}

async function jsonRequest(path, options = {}) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
    return {
      status: response.status,
      headers: response.headers,
      body: await response.json(),
    };
  } finally {
    server.close();
  }
}

function mockHeaders(role = 'owner') {
  process.env.ENABLE_MOCK_TOKEN = 'true';
  process.env.MOCK_TOKEN_ALLOWED_ENVS = 'development,dev,staging';
  return { Authorization: `Bearer mock-token-${role}` };
}

test('request context forwards X-Request-Id into response envelope', async () => {
  const response = await request('/api/me', {
    ...mockHeaders('owner'),
    'X-Request-Id': 'req-test-001',
  });

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('x-request-id'), 'req-test-001');
  assert.equal(response.body.requestId, 'req-test-001');
});

test('request context reports legacy and v1 api version debug headers', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/me', headers);
  const v1 = await request('/api/v1/me', headers);

  assert.equal(legacy.headers.get('x-api-version'), 'legacy');
  assert.equal(v1.headers.get('x-api-version'), 'v1');
});

test('auth login route equivalence covers legacy and v1 prefixes', async () => {
  const body = JSON.stringify({ role: 'owner' });
  const legacy = await jsonRequest('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  const v1 = await jsonRequest('/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });

  assert.equal(legacy.status, v1.status);
  assert.equal(legacy.body.code, v1.body.code);
  assert.equal(legacy.body.data.role, v1.body.data.role);
  assert.equal(typeof legacy.body.data.token, 'string');
  assert.equal(typeof v1.body.data.token, 'string');
});

test('/api and /api/v1 return equivalent /me data', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/me', headers);
  const v1 = await request('/api/v1/me', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.userId, v1.body.data.userId);
  assert.equal(legacy.body.data.role, v1.body.data.role);
});

test('/me includes profile fields used by Flutter', async () => {
  const headers = mockHeaders('owner');
  const response = await request('/api/v1/me', {
    Authorization: headers.Authorization,
  });

  assert.equal(response.status, 200);
  assert.equal(response.body.data.tenantName, '华东示范牧场');
  assert.equal(response.body.data.notificationEnabled, true);
});

test('/profile and /me use compatible user projection', async () => {
  const headers = mockHeaders('owner');
  const me = await request('/api/v1/me', headers);
  const profile = await request('/api/v1/profile', headers);

  assert.equal(profile.body.data.userId, me.body.data.userId);
  assert.equal(profile.body.data.tenantName, me.body.data.tenantName);
});

test('core route equivalence covers GET tenants, fences, and alerts', async () => {
  const headers = mockHeaders('owner');
  const cases = [
    ['/tenants?pageSize=20'],
    ['/fences?pageSize=20'],
    ['/alerts?pageSize=20'],
  ];

  for (const [path] of cases) {
    const legacy = await request(`/api${path}`, headers);
    const v1 = await request(`/api/v1${path}`, headers);
    assert.equal(legacy.status, v1.status);
    assert.equal(legacy.body.code, v1.body.code);
  }
});

test('core route equivalence covers tenant and fence POST validation', async () => {
  const headers = { ...mockHeaders('owner'), 'Content-Type': 'application/json' };
  const cases = [
    ['/tenants', { name: '', licenseTotal: 100 }],
    ['/fences', { name: '', type: 'polygon', coordinates: [], alarmEnabled: true }],
  ];

  for (const [path, body] of cases) {
    const legacy = await jsonRequest(`/api${path}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
    const v1 = await jsonRequest(`/api/v1${path}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
    assert.equal(legacy.status, v1.status);
    assert.equal(legacy.body.code, v1.body.code);
  }
});

test('core route equivalence covers alert ack and batch validation', async () => {
  const headers = { ...mockHeaders('owner'), 'Content-Type': 'application/json' };
  const cases = [
    ['/alerts/does-not-exist/ack', {}],
    ['/alerts/batch-handle', { alertIds: [], action: 'ack' }],
  ];

  for (const [path, body] of cases) {
    const legacy = await jsonRequest(`/api${path}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
    const v1 = await jsonRequest(`/api/v1${path}`, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });
    assert.equal(legacy.status, v1.status);
    assert.equal(legacy.body.code, v1.body.code);
  }
});

test('batch-handle accepts action ack', async () => {
  const headers = mockHeaders('owner');
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}/api/v1/alerts/batch-handle`, {
      method: 'POST',
      headers: {
        Authorization: headers.Authorization,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ alertIds: ['alert-001'], action: 'ack' }),
    });
    const body = await response.json();
    assert.equal(response.status, 200);
    assert.equal(body.code, 'OK');
  } finally {
    server.close();
  }
});

test('batch-handle returns errors for invalid transitions without updating alert', async () => {
  const headers = { ...mockHeaders('owner'), 'Content-Type': 'application/json' };
  const invalidAck = await jsonRequest('/api/v1/alerts/batch-handle', {
    method: 'POST',
    headers,
    body: JSON.stringify({ alertIds: ['alert-002'], action: 'ack' }),
  });
  const validHandle = await jsonRequest('/api/v1/alerts/alert-002/handle', {
    method: 'POST',
    headers,
    body: JSON.stringify({}),
  });

  assert.equal(invalidAck.status, 200);
  assert.equal(invalidAck.body.code, 'OK');
  assert.deepEqual(invalidAck.body.data.errors, [
    { id: 'alert-002', error: 'INVALID_TRANSITION', currentStage: 'acknowledged' },
  ]);
  assert.equal(validHandle.status, 200);
  assert.equal(validHandle.body.code, 'OK');
  assert.equal(validHandle.body.data.stage, 'handled');
});

test('batch-handle success remains equivalent across legacy and v1 routes', async () => {
  const headers = { ...mockHeaders('owner'), 'Content-Type': 'application/json' };
  const legacy = await jsonRequest('/api/alerts/batch-handle', {
    method: 'POST',
    headers,
    body: JSON.stringify({ alertIds: ['alert-005'], action: 'ack' }),
  });
  const v1 = await jsonRequest('/api/v1/alerts/batch-handle', {
    method: 'POST',
    headers,
    body: JSON.stringify({ alertIds: ['alert-006'], action: 'ack' }),
  });

  assert.equal(legacy.status, v1.status);
  assert.equal(legacy.body.code, v1.body.code);
  assert.equal(legacy.body.data.updated, v1.body.data.updated);
  assert.deepEqual(legacy.body.data.errors, v1.body.data.errors);
});

// ── Second batch: live preload endpoints ──────────────────────────────

test('/api and /api/v1 return equivalent /dashboard/summary', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/dashboard/summary', headers);
  const v1 = await request('/api/v1/dashboard/summary', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.deepEqual(legacy.body.data.metrics, v1.body.data.metrics);
  assert.ok(typeof legacy.body.data.lastSyncAt === 'string');
  assert.ok(typeof v1.body.data.lastSyncAt === 'string');
});

test('/api and /api/v1 return equivalent /map/trajectories', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/map/trajectories?range=24h', headers);
  const v1 = await request('/api/v1/map/trajectories?range=24h', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.selectedAnimalId, v1.body.data.selectedAnimalId);
  assert.equal(legacy.body.data.selectedRange, v1.body.data.selectedRange);
  assert.equal(legacy.body.data.animals.length, v1.body.data.animals.length);
});

test('/map/trajectories validates range parameter across both prefixes', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/map/trajectories?range=invalid', headers);
  const v1 = await request('/api/v1/map/trajectories?range=invalid', headers);

  assert.equal(legacy.status, 422);
  assert.equal(v1.status, 422);
  assert.equal(legacy.body.code, 'VALIDATION_ERROR');
  assert.equal(v1.body.code, 'VALIDATION_ERROR');
});

test('/api and /api/v1 return equivalent /profile', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/profile', headers);
  const v1 = await request('/api/v1/profile', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.userId, v1.body.data.userId);
  assert.equal(legacy.body.data.tenantName, v1.body.data.tenantName);
});

test('/api and /api/v1 return equivalent /devices', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/devices', headers);
  const v1 = await request('/api/v1/devices', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.total, v1.body.data.total);
  assert.equal(legacy.body.data.items.length, v1.body.data.items.length);
});

test('/api and /api/v1 return equivalent /twin/overview', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/overview', headers);
  const v1 = await request('/api/v1/twin/overview', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.totalAnimals, v1.body.data.totalAnimals);
});

test('/api and /api/v1 return equivalent /twin/fever/list', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/fever/list', headers);
  const v1 = await request('/api/v1/twin/fever/list', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.total, v1.body.data.total);
  assert.equal(legacy.body.data.items.length, v1.body.data.items.length);
});

test('/api and /api/v1 return equivalent /twin/digestive/list', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/digestive/list', headers);
  const v1 = await request('/api/v1/twin/digestive/list', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.total, v1.body.data.total);
  assert.equal(legacy.body.data.items.length, v1.body.data.items.length);
});

test('/api and /api/v1 return equivalent /twin/estrus/list', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/estrus/list', headers);
  const v1 = await request('/api/v1/twin/estrus/list', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.total, v1.body.data.total);
  assert.equal(legacy.body.data.items.length, v1.body.data.items.length);
});

test('/api and /api/v1 return equivalent /twin/epidemic/summary', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/epidemic/summary', headers);
  const v1 = await request('/api/v1/twin/epidemic/summary', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.riskLevel, v1.body.data.riskLevel);
});

test('/api and /api/v1 return equivalent /twin/epidemic/contacts', async () => {
  const headers = mockHeaders('owner');
  const legacy = await request('/api/twin/epidemic/contacts', headers);
  const v1 = await request('/api/v1/twin/epidemic/contacts', headers);

  assert.equal(legacy.status, 200);
  assert.equal(v1.status, 200);
  assert.equal(legacy.body.code, 'OK');
  assert.equal(v1.body.code, 'OK');
  assert.equal(legacy.body.data.total, v1.body.data.total);
  assert.equal(legacy.body.data.items.length, v1.body.data.items.length);
});
