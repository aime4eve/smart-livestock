const assert = require('node:assert/strict');
const { test } = require('node:test');
const { buildRuntimeConfig } = require('../config/runtimeConfig');
const { issueTokenPair } = require('../services/mockTokenService');
const { app } = require('../server');

const ENV_KEYS = [
  'ENABLE_MOCK_TOKEN',
  'MOCK_TOKEN_ALLOWED_ENVS',
  'MOCK_TOKEN_BREAK_GLASS',
  'MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT',
  'NODE_ENV',
];

function snapshotEnv() {
  return Object.fromEntries(ENV_KEYS.map((key) => [key, process.env[key]]));
}

function restoreEnv(snapshot) {
  for (const key of ENV_KEYS) {
    if (snapshot[key] === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = snapshot[key];
    }
  }
}

async function getMe(token) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}/api/v1/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return { status: response.status, body: await response.json(), headers: response.headers };
  } finally {
    server.close();
  }
}

async function postJson(path, body) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    return { status: response.status, body: await response.json(), headers: response.headers };
  } finally {
    server.close();
  }
}

test('runtimeConfig disables mock-token by default', () => {
  const config = buildRuntimeConfig({});
  assert.equal(config.enableMockToken, false);
});

test('runtimeConfig rejects production mock-token without break-glass', () => {
  assert.throws(
    () => buildRuntimeConfig({
      NODE_ENV: 'production',
      ENABLE_MOCK_TOKEN: 'true',
      MOCK_TOKEN_ALLOWED_ENVS: 'production',
    }),
    /mock-token cannot be enabled in production/,
  );
});

test('runtimeConfig allows unexpired production break-glass', () => {
  const config = buildRuntimeConfig({
    NODE_ENV: 'production',
    ENABLE_MOCK_TOKEN: 'true',
    MOCK_TOKEN_ALLOWED_ENVS: 'production',
    MOCK_TOKEN_BREAK_GLASS: 'true',
    MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT: '2999-01-01T00:00:00.000Z',
  });
  assert.equal(config.enableMockToken, true);
});

test('auth chain accepts mock JWT access token first', async () => {
  const { accessToken } = issueTokenPair('owner');
  const response = await getMe(accessToken);
  assert.equal(response.status, 200);
  assert.equal(response.body.data.role, 'owner');
  assert.equal(response.headers.get('x-auth-mode'), 'jwt');
});

test('mock-token is rejected when fallback is disabled', async () => {
  const env = snapshotEnv();
  try {
    delete process.env.ENABLE_MOCK_TOKEN;
    delete process.env.MOCK_TOKEN_ALLOWED_ENVS;
    const response = await getMe('mock-token-owner');
    assert.equal(response.status, 401);
    assert.equal(response.body.code, 'AUTH_UNAUTHORIZED');
  } finally {
    restoreEnv(env);
  }
});

test('mock-token is accepted when fallback is explicitly enabled', async () => {
  const env = snapshotEnv();
  try {
    process.env.ENABLE_MOCK_TOKEN = 'true';
    process.env.MOCK_TOKEN_ALLOWED_ENVS = 'development,dev,staging';
    process.env.NODE_ENV = 'development';
    const response = await getMe('mock-token-owner');
    assert.equal(response.status, 200);
    assert.equal(response.body.data.role, 'owner');
    assert.equal(response.headers.get('x-auth-mode'), 'mock');
  } finally {
    restoreEnv(env);
  }
});

test('login accepts account/password mock shape and returns token pair', async () => {
  const response = await postJson('/api/v1/auth/login', {
    account: 'worker',
    password: 'mock-password',
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.data.role, 'worker');
  assert.equal(response.body.data.token, response.body.data.accessToken);
  assert.equal(typeof response.body.data.refreshToken, 'string');
  assert.equal(response.body.data.user.role, 'worker');

  const me = await getMe(response.body.data.accessToken);
  assert.equal(me.status, 200);
  assert.equal(me.body.data.role, 'worker');
});

test('refresh rotates token pair and logout revokes refresh token', async () => {
  const login = await postJson('/api/v1/auth/login', { role: 'owner' });
  const refresh = await postJson('/api/v1/auth/refresh', {
    refreshToken: login.body.data.refreshToken,
  });

  assert.equal(refresh.status, 200);
  assert.equal(refresh.body.data.role, 'owner');
  assert.notEqual(refresh.body.data.refreshToken, login.body.data.refreshToken);

  const reused = await postJson('/api/v1/auth/refresh', {
    refreshToken: login.body.data.refreshToken,
  });
  assert.equal(reused.status, 401);
  assert.equal(reused.body.code, 'AUTH_UNAUTHORIZED');

  const logout = await postJson('/api/v1/auth/logout', {
    refreshToken: refresh.body.data.refreshToken,
  });
  assert.equal(logout.status, 200);

  const revoked = await postJson('/api/v1/auth/refresh', {
    refreshToken: refresh.body.data.refreshToken,
  });
  assert.equal(revoked.status, 401);
  assert.equal(revoked.body.code, 'AUTH_UNAUTHORIZED');
});
