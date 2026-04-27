# API Version Auth Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing Mobile live integration default to `/api/v1`, while keeping `/api` as a long-lived compatibility entry and moving authentication toward a JWT-first session model with controlled mock-token fallback.

**Architecture:** Implement the migration skeleton in the current Express Mock Server and Flutter app first, so the team can validate routing, auth-chain, compatibility, and live-mode behavior before a future AdonisJS backend replacement. Backend route registration is shared across `/api` and `/api/v1`; frontend API calls use a central base URL and auth header source; tests prove that core routes behave equivalently and live mode does not silently pass by using mock data.

**Tech Stack:** Node.js + Express 5 Mock Server, Node built-in `node:test`, Flutter/Dart, Riverpod session state, `http` package, existing `APP_MODE=mock|live` switch.

---

## Source Documents

- Spec: `Mobile/docs/superpowers/specs/2026-04-26-api-version-auth-migration-design.md`
- API contract: `Mobile/docs/api-contracts/2026-04-21-backend-api-contract.md`
- Backend infra requirements: `Mobile/docs/2026-04-21-backend-infra-requirements.md`

## Scope

This plan targets the existing repo state:

- Backend implementation is still `Mobile/backend` Express Mock Server, not AdonisJS.
- The goal is a migration-ready compatibility and auth skeleton, not a production JWT issuer backed by Postgres.
- JWT behavior in this plan uses deterministic mock JWT-shaped tokens so tests and Flutter flows can migrate away from hardcoded `mock-token-{role}`. Real RS256 verification belongs in the future AdonisJS backend plan.

## File Structure

### Backend

- Create: `Mobile/backend/config/runtimeConfig.js`
  - Parses environment variables for mock-token and response header behavior.
  - Contains fail-fast validation for production mock-token settings.

- Create: `Mobile/backend/middleware/requestContext.js`
  - Creates or forwards `X-Request-Id`.
  - Derives `req.apiVersion` from route prefix.
  - Writes `X-Request-Id` and non-sensitive version/auth headers when enabled.

- Modify: `Mobile/backend/middleware/envelope.js`
  - Uses `req.requestId` instead of generating unrelated response IDs.

- Modify: `Mobile/backend/middleware/auth.js`
  - Adds JWT-first parsing for mock JWT access tokens.
  - Adds `ENABLE_MOCK_TOKEN` fallback control.
  - Sets `req.authMode` and `req.user`.

- Create: `Mobile/backend/services/mockTokenService.js`
  - Issues and verifies deterministic mock JWT-shaped access tokens.
  - Issues in-memory refresh tokens for the mock server.

- Modify: `Mobile/backend/routes/auth.js`
  - Keeps role login compatibility.
  - Adds account/password login shape.
  - Adds `/refresh` and `/logout`.

- Modify: `Mobile/backend/routes/me.js`
  - Adds `tenantName` and profile fields to the canonical `/me` projection.

- Modify: `Mobile/backend/routes/profile.js`
  - Reuses the same user projection as `/me`.

- Create: `Mobile/backend/routes/registerApiRoutes.js`
  - Registers every route module under a supplied prefix.

- Modify: `Mobile/backend/server.js`
  - Calls `registerApiRoutes(app, '/api')` and `registerApiRoutes(app, '/api/v1')`.
  - Updates the startup route table for both prefixes.

- Create: `Mobile/backend/test/apiVersionRoutes.test.js`
  - Verifies `/api` and `/api/v1` route equivalence for core endpoints.

- Create: `Mobile/backend/test/authChain.test.js`
  - Verifies JWT-first behavior, mock-token fallback, and disabled mock-token failure.

- Modify: `Mobile/backend/test/tenantStore.test.js`
  - No behavior change required, but include it in `npm test`.

- Modify: `Mobile/backend/package.json`
  - Runs all backend tests, including new API/auth tests.

### Flutter

- Create: `Mobile/mobile_app/lib/core/api/api_auth.dart`
  - Centralizes API auth header creation.
  - Supports `ApiAuthTokens`, JWT access token, and explicit dev mock-token fallback control.

- Modify: `Mobile/mobile_app/lib/app/session/app_session.dart`
  - Stores `accessToken`, `refreshToken`, `expiresAt`, and user identity fields.

- Modify: `Mobile/mobile_app/lib/app/session/session_controller.dart`
  - Adds login methods that can accept token payloads.
  - Keeps existing role-only login path for mock mode compatibility.

- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`
  - Defaults `resolveApiBaseUrl()` to `/api/v1`.
  - Replaces `_headers(role)` with auth-token-aware headers and an explicit fallback flag.
  - Adds a visible-for-testing source marker for live API responses.

- Create: `Mobile/mobile_app/test/api_base_url_test.dart`
  - Verifies default base URL and override behavior.

- Create: `Mobile/mobile_app/test/api_auth_test.dart`
  - Verifies JWT-first headers and mock fallback headers.

- Modify: `Mobile/mobile_app/test/app_mode_switch_test.dart`
  - Adds assertion that live mode repositories still switch correctly with the new API auth layer.

### Docs

- Create: `Mobile/docs/api-contracts/api-compatibility-matrix.md`
  - Records `/api` compatibility commitments, owners, test state, and review cadence.

- Modify: `Mobile/docs/api-contracts/2026-04-21-backend-api-contract.md`
  - Notes `/api/v1` as the normative source and `/api` as compatibility entry.

---

## Task 1: Backend Runtime Config

**Files:**
- Create: `Mobile/backend/config/runtimeConfig.js`
- Test: `Mobile/backend/test/authChain.test.js`

- [ ] **Step 1: Write failing runtime config tests**

Add tests for config parsing and production mock-token safety:

```js
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { buildRuntimeConfig } = require('../config/runtimeConfig');

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
    /mock-token cannot be enabled in production/
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/authChain.test.js`

Expected: FAIL because `../config/runtimeConfig` does not exist.

- [ ] **Step 3: Implement runtime config**

Create `Mobile/backend/config/runtimeConfig.js`:

```js
function parseBool(value, fallback = false) {
  if (value === undefined) return fallback;
  return value === 'true' || value === true;
}

function buildRuntimeConfig(env = process.env) {
  const nodeEnv = env.NODE_ENV || 'development';
  const allowedEnvs = (env.MOCK_TOKEN_ALLOWED_ENVS || 'dev,development,staging')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  const breakGlass = parseBool(env.MOCK_TOKEN_BREAK_GLASS);
  const breakGlassExpiresAt = env.MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT || null;
  const requestedMockToken = parseBool(env.ENABLE_MOCK_TOKEN);

  let enableMockToken = requestedMockToken && allowedEnvs.includes(nodeEnv);

  if (nodeEnv === 'production' && requestedMockToken) {
    const expiresAt = breakGlassExpiresAt ? Date.parse(breakGlassExpiresAt) : Number.NaN;
    const isValidBreakGlass = breakGlass && Number.isFinite(expiresAt) && expiresAt > Date.now();
    if (!isValidBreakGlass) {
      throw new Error('mock-token cannot be enabled in production without unexpired break-glass');
    }
    enableMockToken = true;
  }

  return {
    nodeEnv,
    enableMockToken,
    allowedMockTokenEnvs: allowedEnvs,
    exposeDebugHeaders: parseBool(env.EXPOSE_API_DEBUG_HEADERS, nodeEnv !== 'production'),
  };
}

module.exports = { buildRuntimeConfig };
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Mobile/backend && node --test test/authChain.test.js`

Expected: PASS for runtime config tests.

- [ ] **Step 5: Commit**

```bash
git add Mobile/backend/config/runtimeConfig.js Mobile/backend/test/authChain.test.js
git commit -m "test: add backend auth runtime config"
```

---

## Task 2: Backend Request Context and Envelope

**Files:**
- Create: `Mobile/backend/middleware/requestContext.js`
- Modify: `Mobile/backend/middleware/envelope.js`
- Test: `Mobile/backend/test/apiVersionRoutes.test.js`

- [ ] **Step 1: Write failing request context tests**

Add tests that exercise a real HTTP request against an exported app:

```js
const assert = require('node:assert/strict');
const { test } = require('node:test');
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

test('request context forwards X-Request-Id into response envelope', async () => {
  const response = await request('/api/me', {
    Authorization: 'Bearer mock-token-owner',
    'X-Request-Id': 'req-test-001',
  });
  assert.equal(response.headers.get('x-request-id'), 'req-test-001');
  assert.equal(response.body.requestId, 'req-test-001');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: FAIL because `server.js` does not export `app` and request context is missing.

- [ ] **Step 3: Implement request context middleware**

Create `Mobile/backend/middleware/requestContext.js`:

```js
function createRequestId() {
  const ts = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 8);
  return `req_${ts}_${rand}`;
}

function requestContext(runtimeConfig) {
  return (req, res, next) => {
    req.requestId = req.headers['x-request-id'] || createRequestId();
    req.apiVersion = req.path.startsWith('/api/v1') ? 'v1' : 'legacy';
    res.setHeader('X-Request-Id', req.requestId);
    if (runtimeConfig.exposeDebugHeaders) {
      res.setHeader('X-Api-Version', req.apiVersion);
    }
    next();
  };
}

module.exports = { requestContext, createRequestId };
```

Modify `Mobile/backend/middleware/envelope.js` so `ok` and `fail` accept `requestId`:

```js
function ok(data, message = 'success', requestId = requestIdFallback()) {
  return { code: 'OK', message, requestId, data };
}

function fail(code, message, requestId = requestIdFallback()) {
  return { code, message, requestId };
}

function envelopeMiddleware(req, res, next) {
  res.ok = (data, message) => res.json(ok(data, message, req.requestId));
  res.fail = (status, code, message) =>
    res.status(status).json(fail(code, message, req.requestId));
  next();
}
```

Keep exported helper compatibility by renaming the old `requestId()` helper to `requestIdFallback()`.

Modify `Mobile/backend/server.js` in this task only enough to make tests run:

- Import `buildRuntimeConfig` and create `runtimeConfig`.
- Import `requestContext`.
- Apply `requestContext(runtimeConfig)` before `envelopeMiddleware`.
- Export `{ app }`.
- Wrap `app.listen()` in `if (require.main === module)`.

For this task, keep existing `/api/*` route registration unchanged; `/api/v1` is introduced in Task 3.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: PASS request ID assertions for `/api/me`.

- [ ] **Step 5: Commit**

```bash
git add Mobile/backend/middleware/requestContext.js Mobile/backend/middleware/envelope.js Mobile/backend/server.js Mobile/backend/test/apiVersionRoutes.test.js
git commit -m "feat: add backend request context"
```

---

## Task 3: Dual API Route Registration

**Files:**
- Create: `Mobile/backend/routes/registerApiRoutes.js`
- Modify: `Mobile/backend/server.js`
- Test: `Mobile/backend/test/apiVersionRoutes.test.js`

- [ ] **Step 1: Add failing route equivalence test**

Extend `apiVersionRoutes.test.js` with a helper that explicitly enables mock-token only for route-equivalence tests that run before Task 4 introduces access tokens. This avoids hidden reliance on the default runtime config.

```js
async function jsonRequest(path, options = {}) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
    return { status: response.status, headers: response.headers, body: await response.json() };
  } finally {
    server.close();
  }
}

function mockHeaders(role = 'owner') {
  process.env.ENABLE_MOCK_TOKEN = 'true';
  process.env.MOCK_TOKEN_ALLOWED_ENVS = 'development,dev,staging';
  return { Authorization: `Bearer mock-token-${role}` };
}

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
```

Also add first-batch route equivalence tests required by the spec:

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: FAIL because `/api/v1/me` is not registered.

- [ ] **Step 3: Extract shared route registration**

Create `Mobile/backend/routes/registerApiRoutes.js`:

```js
const authRoutes = require('./auth');
const meRoutes = require('./me');
const dashboardRoutes = require('./dashboard');
const mapRoutes = require('./map');
const alertsRoutes = require('./alerts');
const fencesRoutes = require('./fences');
const tenantsRoutes = require('./tenants');
const profileRoutes = require('./profile');
const twinRoutes = require('./twin');
const devicesRoutes = require('./devices');

function registerApiRoutes(app, prefix) {
  app.use(`${prefix}/auth`, authRoutes);
  app.use(`${prefix}/me`, meRoutes);
  app.use(`${prefix}/dashboard`, dashboardRoutes);
  app.use(`${prefix}/map`, mapRoutes);
  app.use(`${prefix}/alerts`, alertsRoutes);
  app.use(`${prefix}/fences`, fencesRoutes);
  app.use(`${prefix}/tenants`, tenantsRoutes);
  app.use(`${prefix}/profile`, profileRoutes);
  app.use(`${prefix}/twin`, twinRoutes);
  app.use(`${prefix}/devices`, devicesRoutes);
}

module.exports = { registerApiRoutes };
```

Modify `Mobile/backend/server.js`:

- Remove direct route imports.
- Import `buildRuntimeConfig`, `requestContext`, and `registerApiRoutes`.
- Call both `registerApiRoutes(app, '/api')` and `registerApiRoutes(app, '/api/v1')`.
- Keep the `requestContext(runtimeConfig)` and `module.exports = { app }` changes introduced in Task 2.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: PASS route equivalence test.

- [ ] **Step 5: Commit**

```bash
git add Mobile/backend/routes/registerApiRoutes.js Mobile/backend/server.js Mobile/backend/test/apiVersionRoutes.test.js
git commit -m "feat: register legacy and v1 api routes"
```

---

## Task 4: Backend Auth Chain and Mock JWT Tokens

**Files:**
- Create: `Mobile/backend/services/mockTokenService.js`
- Modify: `Mobile/backend/middleware/auth.js`
- Modify: `Mobile/backend/routes/auth.js`
- Test: `Mobile/backend/test/authChain.test.js`

- [ ] **Step 1: Add failing auth-chain tests**

Extend `authChain.test.js`:

```js
const { issueTokenPair } = require('../services/mockTokenService');
const { app } = require('../server');

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

test('auth chain accepts mock JWT access token first', async () => {
  const { accessToken } = issueTokenPair('owner');
  const response = await getMe(accessToken);
  assert.equal(response.status, 200);
  assert.equal(response.body.data.role, 'owner');
});

test('mock-token is rejected when fallback is disabled', async () => {
  const response = await getMe('mock-token-owner');
  assert.equal(response.status, 401);
  assert.equal(response.body.code, 'AUTH_UNAUTHORIZED');
});

test('mock-token is accepted when fallback is explicitly enabled', async () => {
  process.env.ENABLE_MOCK_TOKEN = 'true';
  process.env.MOCK_TOKEN_ALLOWED_ENVS = 'development,dev,staging';
  const response = await getMe('mock-token-owner');
  assert.equal(response.status, 200);
  assert.equal(response.body.data.role, 'owner');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/authChain.test.js`

Expected: FAIL because `mockTokenService` does not exist.

- [ ] **Step 3: Implement mock token service**

Create `Mobile/backend/services/mockTokenService.js`:

```js
const crypto = require('node:crypto');
const { users } = require('../data/seed');

const refreshTokens = new Map();

function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function issueAccessToken(role) {
  const user = users[role];
  if (!user) return null;
  const header = base64UrlJson({ alg: 'mock', typ: 'JWT' });
  const payload = base64UrlJson({
    userId: user.userId,
    tenantId: user.tenantId,
    role: user.role,
    permissions: user.permissions,
    exp: Math.floor(Date.now() / 1000) + 3600,
    jti: crypto.randomUUID(),
  });
  return `${header}.${payload}.mock-signature`;
}

function verifyAccessToken(token) {
  const parts = token.split('.');
  if (parts.length !== 3 || parts[2] !== 'mock-signature') return null;
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (!payload.exp || payload.exp < Math.floor(Date.now() / 1000)) return null;
    return users[payload.role] || null;
  } catch (_) {
    return null;
  }
}

function issueTokenPair(role) {
  const accessToken = issueAccessToken(role);
  if (!accessToken) return null;
  const refreshToken = crypto.randomUUID();
  refreshTokens.set(refreshToken, { role, expiresAt: Date.now() + 7 * 24 * 60 * 60 * 1000 });
  return {
    accessToken,
    refreshToken,
    expiresAt: new Date(Date.now() + 3600 * 1000).toISOString(),
  };
}

function refreshTokenPair(refreshToken) {
  const record = refreshTokens.get(refreshToken);
  if (!record || record.expiresAt < Date.now()) return null;
  refreshTokens.delete(refreshToken);
  return issueTokenPair(record.role);
}

function revokeRefreshToken(refreshToken) {
  refreshTokens.delete(refreshToken);
}

module.exports = {
  issueTokenPair,
  verifyAccessToken,
  refreshTokenPair,
  revokeRefreshToken,
};
```

- [ ] **Step 4: Implement JWT-first auth middleware**

Modify `Mobile/backend/middleware/auth.js`:

- Import `buildRuntimeConfig` and `verifyAccessToken`.
- Parse bearer token once.
- Try `verifyAccessToken(token)` first.
- If it fails, call `buildRuntimeConfig(process.env)` inside `authMiddleware` and allow `TOKEN_MAP[token]` only when `runtimeConfig.enableMockToken` is true. Building from `process.env` at request time keeps tests able to toggle fallback explicitly.
- Set `req.authMode = 'jwt'` or `'mock'`.
- If debug headers are exposed, set `X-Auth-Mode`.

- [ ] **Step 5: Extend auth routes**

Modify `Mobile/backend/routes/auth.js`:

- Keep `{ role }` login compatibility.
- Accept `{ account, password }` where `account` can map to `owner`, `worker`, or `ops` for mock server.
- Return `{ token, role, accessToken, refreshToken, expiresAt, user }` so legacy callers can keep using `token` while new callers can use `accessToken`.
- Add `POST /refresh`.
- Add `POST /logout`.

- [ ] **Step 6: Run tests**

Run: `cd Mobile/backend && node --test test/authChain.test.js`

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Mobile/backend/services/mockTokenService.js Mobile/backend/middleware/auth.js Mobile/backend/routes/auth.js Mobile/backend/test/authChain.test.js
git commit -m "feat: add jwt-first mock auth chain"
```

---

## Task 5: Canonical User Projection

**Files:**
- Create: `Mobile/backend/services/userProjectionService.js`
- Modify: `Mobile/backend/routes/me.js`
- Modify: `Mobile/backend/routes/profile.js`
- Test: `Mobile/backend/test/apiVersionRoutes.test.js`

- [ ] **Step 1: Add failing `/me` and `/profile` projection tests**

Extend `apiVersionRoutes.test.js`:

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: FAIL because `/me` lacks `tenantName` and `notificationEnabled`.

- [ ] **Step 3: Implement shared projection**

Create `Mobile/backend/services/userProjectionService.js`:

```js
const { tenants } = require('../data/seed');

function buildUserProjection(user) {
  const tenant = tenants.find((item) => item.id === user.tenantId);
  return {
    userId: user.userId,
    tenantId: user.tenantId,
    name: user.name,
    role: user.role,
    mobile: user.mobile,
    permissions: user.permissions,
    tenantName: tenant ? tenant.name : null,
    notificationEnabled: true,
  };
}

module.exports = { buildUserProjection };
```

Modify `me.js` and `profile.js` to call `buildUserProjection(req.user)`.

- [ ] **Step 4: Run tests**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Mobile/backend/services/userProjectionService.js Mobile/backend/routes/me.js Mobile/backend/routes/profile.js Mobile/backend/test/apiVersionRoutes.test.js
git commit -m "feat: align me and profile projection"
```

---

## Task 6: Fix Alert Batch Contract

**Files:**
- Modify: `Mobile/backend/routes/alerts.js`
- Test: `Mobile/backend/test/apiVersionRoutes.test.js`

- [ ] **Step 1: Add failing batch-handle contract test**

Extend `apiVersionRoutes.test.js`:

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: FAIL with `VALIDATION_ERROR` because current validation checks stage names, not `ack|handle|archive`.

- [ ] **Step 3: Implement contract fix**

Modify `Mobile/backend/routes/alerts.js`:

```js
const VALID_BATCH_ACTIONS = ['ack', 'handle', 'archive'];
const ACTION_TARGET_STAGE = {
  ack: 'acknowledged',
  handle: 'handled',
  archive: 'archived',
};
```

Then validate `VALID_BATCH_ACTIONS.includes(action)` and compare `expected !== ACTION_TARGET_STAGE[action]`.

- [ ] **Step 4: Run tests**

Run: `cd Mobile/backend && node --test test/apiVersionRoutes.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Mobile/backend/routes/alerts.js Mobile/backend/test/apiVersionRoutes.test.js
git commit -m "fix: align alert batch action contract"
```

---

## Task 7: Backend Test Script Coverage

**Files:**
- Modify: `Mobile/backend/package.json`

- [ ] **Step 1: Update test script**

Modify `Mobile/backend/package.json`:

```json
"test": "node --test test/*.test.js"
```

- [ ] **Step 2: Run all backend tests**

Run: `cd Mobile/backend && npm test`

Expected: PASS for `geo`, `fenceStore`, `tenantStore`, `apiVersionRoutes`, and `authChain`.

- [ ] **Step 3: Commit**

```bash
git add Mobile/backend/package.json
git commit -m "test: run all backend tests"
```

---

## Task 8: Flutter API Auth Model

**Files:**
- Create: `Mobile/mobile_app/lib/core/api/api_auth.dart`
- Modify: `Mobile/mobile_app/lib/app/session/app_session.dart`
- Modify: `Mobile/mobile_app/lib/app/session/session_controller.dart`
- Test: `Mobile/mobile_app/test/api_auth_test.dart`

- [ ] **Step 1: Write failing API auth tests**

Create `Mobile/mobile_app/test/api_auth_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  test('apiHeaders prefers access token', () {
    final headers = apiHeaders(
      role: DemoRole.owner,
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );
    expect(headers['Authorization'], 'Bearer jwt-token');
  });

  test('apiHeaders can use mock token fallback', () {
    final headers = apiHeaders(role: DemoRole.worker);
    expect(headers['Authorization'], isNull);
  });

  test('apiHeaders uses mock token only when fallback is enabled', () {
    final headers = apiHeaders(
      role: DemoRole.worker,
      allowMockTokenFallback: true,
    );
    expect(headers['Authorization'], 'Bearer mock-token-worker');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/mobile_app && flutter test test/api_auth_test.dart`

Expected: FAIL because `api_auth.dart` does not exist.

- [ ] **Step 3: Implement API auth helper**

Create `Mobile/mobile_app/lib/core/api/api_auth.dart`:

```dart
import 'package:smart_livestock_demo/core/models/demo_role.dart';

class ApiAuthTokens {
  const ApiAuthTokens({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
}

Map<String, String> apiHeaders({
  required DemoRole role,
  ApiAuthTokens? tokens,
  bool allowMockTokenFallback = false,
}) {
  final accessToken = tokens?.accessToken;
  final authorizationValue = accessToken ??
      (allowMockTokenFallback ? 'mock-token-${role.name}' : null);
  return {
    'Content-Type': 'application/json',
    if (authorizationValue != null) 'Authorization': 'Bearer $authorizationValue',
  };
}
```

- [ ] **Step 4: Extend session objects**

Modify `app_session.dart`:

- Add `accessToken`, `refreshToken`, `expiresAt`.
- Keep `AppSession.authenticated(DemoRole role)` for existing tests.
- Add `AppSession.withTokens(...)`.

Modify `session_controller.dart`:

- Keep `login(DemoRole role)`.
- Add `loginWithTokens({required DemoRole role, required String accessToken, String? refreshToken, DateTime? expiresAt})`.

- [ ] **Step 5: Run tests**

Run: `cd Mobile/mobile_app && flutter test test/api_auth_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_auth.dart Mobile/mobile_app/lib/app/session/app_session.dart Mobile/mobile_app/lib/app/session/session_controller.dart Mobile/mobile_app/test/api_auth_test.dart
git commit -m "feat: add api auth token model"
```

---

## Task 9: Flutter API Base URL Defaults to v1

**Files:**
- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`
- Test: `Mobile/mobile_app/test/api_base_url_test.dart`

- [ ] **Step 1: Write failing base URL tests**

Create `Mobile/mobile_app/test/api_base_url_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';

void main() {
  test('resolveApiBaseUrl defaults to versioned API', () {
    expect(resolveApiBaseUrl(), contains('/api/v1'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/mobile_app && flutter test test/api_base_url_test.dart`

Expected: FAIL because current default is `/api`.

- [ ] **Step 3: Update default base URL**

Modify `resolveApiBaseUrl()` in `api_cache.dart`:

```dart
return kIsWeb
    ? 'http://127.0.0.1:3001/api/v1'
    : 'http://localhost:3001/api/v1';
```

- [ ] **Step 4: Run test**

Run: `cd Mobile/mobile_app && flutter test test/api_base_url_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_cache.dart Mobile/mobile_app/test/api_base_url_test.dart
git commit -m "feat: default live api to v1"
```

---

## Task 10: Wire ApiCache to API Auth Helper

**Files:**
- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`
- Test: `Mobile/mobile_app/test/api_auth_test.dart`

- [ ] **Step 1: Add failing test for header delegation**

Extend `api_auth_test.dart` with a test around a visible-for-testing helper:

```dart
test('ApiCache headers use token helper semantics', () {
  final headers = ApiCache.headersForTesting(
    role: DemoRole.owner,
    tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
  );
  expect(headers['Authorization'], 'Bearer jwt-token');
});

test('ApiCache headers do not send mock-token when fallback is disabled', () {
  final headers = ApiCache.headersForTesting(role: DemoRole.owner);
  expect(headers['Authorization'], isNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/mobile_app && flutter test test/api_auth_test.dart`

Expected: FAIL because `ApiCache.headersForTesting` does not exist.

- [ ] **Step 3: Replace private `_headers` implementation**

Modify `api_cache.dart`:

- Import `api_auth.dart` and `DemoRole`.
- Change `_headers(String role)` to convert role string to `DemoRole` and call `apiHeaders`.
- Add an optional `ApiAuthTokens? tokens` and `bool allowMockTokenFallback = false` migration parameter to `init`, `refreshTenants`, write methods, and `headersForTesting`.
- Default behavior must not emit `mock-token-{role}`. Existing development compatibility call sites that still need role-token behavior must pass `allowMockTokenFallback: true` explicitly.
- Live verification tests must pass tokens and keep fallback disabled.
- Add `@visibleForTesting static Map<String, String> headersForTesting(...)`.

Keep existing method signatures that accept `String role` to minimize blast radius.

- [ ] **Step 4: Run tests**

Run: `cd Mobile/mobile_app && flutter test test/api_auth_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_cache.dart Mobile/mobile_app/test/api_auth_test.dart
git commit -m "refactor: centralize live api headers"
```

---

## Task 11: Live API Source Marker

**Files:**
- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`
- Test: `Mobile/mobile_app/test/api_base_url_test.dart`

- [ ] **Step 1: Add failing source-marker test**

Extend `api_base_url_test.dart`:

```dart
test('ApiCache starts without mock fallback source marker', () {
  ApiCache.instance.debugReset();
  expect(ApiCache.instance.lastLiveSource, isNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/mobile_app && flutter test test/api_base_url_test.dart`

Expected: FAIL because `lastLiveSource` does not exist.

- [ ] **Step 3: Implement source marker**

Modify `ApiCache`:

- Add `String? _lastLiveSource;`
- Add getter `String? get lastLiveSource => _lastLiveSource;`
- In `_get`, set `_lastLiveSource = 'api'` when a response returns `code == 'OK'`.
- Do not set `_lastLiveSource = 'mock'` inside `ApiCache`; mock fallback belongs in repository code.
- Reset `_lastLiveSource` in `debugReset()`.

- [ ] **Step 4: Run focused tests**

Run: `cd Mobile/mobile_app && flutter test test/api_base_url_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_cache.dart Mobile/mobile_app/test/api_base_url_test.dart
git commit -m "test: expose live api source marker"
```

---

## Task 12: Live v1 Verification Harness

**Files:**
- Create: `Mobile/mobile_app/lib/core/api/api_http_client.dart`
- Modify: `Mobile/mobile_app/lib/core/api/api_cache.dart`
- Create: `Mobile/mobile_app/test/api_live_contract_test.dart`

- [ ] **Step 1: Add failing live verification test**

Create `Mobile/mobile_app/test/api_live_contract_test.dart`. The test must prove `ApiCache.init()` issues real `/api/v1` HTTP requests for the current live preload set and does not send a mock-token when fallback is disabled:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';

class RecordingApiHttpClient implements ApiHttpClient {
  final uris = <Uri>[];
  final authHeaders = <String?>[];

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    uris.add(uri);
    authHeaders.add(headers?['Authorization']);
    return ApiHttpResponse(
      200,
      jsonEncode({'code': 'OK', 'message': 'success', 'requestId': 'req_test', 'data': _dataFor(uri.path)}),
      {'x-api-version': 'v1'},
    );
  }

  Map<String, dynamic> _dataFor(String path) {
    if (path.endsWith('/dashboard/summary')) return {'metrics': []};
    if (path.endsWith('/map/trajectories')) return {'animals': [], 'points': []};
    if (path.endsWith('/alerts') || path.endsWith('/fences') || path.endsWith('/tenants') || path.endsWith('/devices')) {
      return {'items': [], 'page': 1, 'pageSize': 20, 'total': 0};
    }
    if (path.contains('/twin/') && !path.endsWith('/overview') && !path.endsWith('/summary')) {
      return {'items': []};
    }
    return {};
  }
}

void main() {
  test('ApiCache live init requests v1 endpoints with access token', () async {
    final client = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
      allowMockTokenFallback: false,
    );

    expect(client.uris, isNotEmpty);
    expect(client.uris.every((uri) => uri.path.startsWith('/api/v1/')), isTrue);
    expect(client.authHeaders.every((value) => value == 'Bearer jwt-token'), isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Mobile/mobile_app && flutter test test/api_live_contract_test.dart`

Expected: FAIL because `api_http_client.dart` and `debugSetHttpClient` do not exist.

- [ ] **Step 3: Implement injectable HTTP client**

Create `Mobile/mobile_app/lib/core/api/api_http_client.dart`:

```dart
import 'package:http/http.dart' as http;

class ApiHttpResponse {
  const ApiHttpResponse(this.statusCode, this.body, this.headers);

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract class ApiHttpClient {
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers});
}

class DefaultApiHttpClient implements ApiHttpClient {
  const DefaultApiHttpClient();

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    return ApiHttpResponse(response.statusCode, response.body, response.headers);
  }
}
```

Modify `api_cache.dart` so `_get()` calls `_httpClient.get(...)`, and add:

```dart
ApiHttpClient _httpClient = const DefaultApiHttpClient();

@visibleForTesting
void debugSetHttpClient(ApiHttpClient client) {
  _httpClient = client;
}
```

Update `debugReset()` to restore `const DefaultApiHttpClient()`.

- [ ] **Step 4: Add manual live verification checklist**

Keep Task 14 smoke step mandatory and require:

- Backend logs show `/api/v1` requests.
- Core flow uses `X-Api-Version: v1` when debug headers are enabled.
- Core flow fails visibly if access token is removed and mock fallback is disabled.

- [ ] **Step 5: Run test**

Run: `cd Mobile/mobile_app && flutter test test/api_live_contract_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_http_client.dart Mobile/mobile_app/lib/core/api/api_cache.dart Mobile/mobile_app/test/api_live_contract_test.dart
git commit -m "test: add live api fallback guard"
```

---

## Task 13: Compatibility Matrix Doc

**Files:**
- Create: `Mobile/docs/api-contracts/api-compatibility-matrix.md`
- Modify: `Mobile/docs/api-contracts/2026-04-21-backend-api-contract.md`

- [ ] **Step 1: Create compatibility matrix**

Create `api-compatibility-matrix.md`:

```markdown
# API Compatibility Matrix

## Policy

- `/api/v1` is the normative contract source.
- `/api` is a long-lived compatibility entry for existing clients and rollback.
- `/api` must share backend implementation with `/api/v1`; adapter-only differences are allowed.

## Matrix

| Module | `/api` Compatibility | `/api/v1` Contract | Owner | Test State | Last Reviewed |
|--------|----------------------|--------------------|-------|------------|---------------|
| auth / me / profile | Keep login, refresh, logout, `/me`, `/profile` | Normative | Backend | Planned | 2026-04-26 |
| tenant | Keep Phase 1 CRUD, status, license | Normative | Backend | Planned | 2026-04-26 |
| fence | Keep list/detail/create/update/delete | Normative | Backend | Planned | 2026-04-26 |
| alert | Keep list, single transitions, batch-handle | Normative | Backend | Planned | 2026-04-26 |
| dashboard / map / devices / twin | Keep current live preload endpoints | Normative | Backend | Planned | 2026-04-26 |
| stats / livestock extension | No default backport | Normative | TBD | Not started | 2026-04-26 |
```

- [ ] **Step 2: Update API contract intro**

In `2026-04-21-backend-api-contract.md`, add a short note under Base URL:

```markdown
新后端迁移后 `/api/v1` 是规范契约源；`/api` 长期保留为兼容入口。兼容承诺见 `api-compatibility-matrix.md`。
```

- [ ] **Step 3: Commit**

```bash
git add Mobile/docs/api-contracts/api-compatibility-matrix.md Mobile/docs/api-contracts/2026-04-21-backend-api-contract.md
git commit -m "docs: add api compatibility matrix"
```

---

## Task 14: Full Verification

**Files:**
- No new files.

- [ ] **Step 1: Run backend tests**

Run: `cd Mobile/backend && npm test`

Expected: PASS.

- [ ] **Step 2: Run focused Flutter tests**

Run:

```bash
cd Mobile/mobile_app
flutter test test/api_auth_test.dart
flutter test test/api_base_url_test.dart
flutter test test/api_live_contract_test.dart
flutter test test/app_mode_switch_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run Flutter analyze**

Run: `cd Mobile/mobile_app && flutter analyze`

Expected: No new analyzer errors.

- [ ] **Step 4: Live smoke**

Start backend:

```bash
cd Mobile/backend && npm start
```

In another terminal:

```bash
cd Mobile/mobile_app
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api/v1
```

Expected: app launches and core pages load from `/api/v1`.

Manual checks:

- Backend startup output lists both `/api` and `/api/v1`.
- Browser/network logs show auth/me, tenant, fence, and alert requests using `/api/v1`.
- If mock fallback is disabled and the access token is removed, core live flow enters error/offline state instead of rendering mock success data.

- [ ] **Step 5: Commit final verification notes if needed**

If a plan completion record is added later:

```bash
git add Mobile/docs/superpowers/plans/2026-04-26-api-version-auth-migration-implementation.md
git commit -m "docs: add api migration implementation plan"
```

---

## Rollback Plan

- Frontend rollback: set `API_BASE_URL=http://127.0.0.1:3001/api`.
- Backend rollback: keep both route prefixes registered; disable mock-token fallback by setting `ENABLE_MOCK_TOKEN=false`.
- If auth-token changes break live mode, keep `AppSession.authenticated(role)` and mock-token fallback path available for dev while fixing token storage.

## Acceptance Checklist

- [ ] `/api` and `/api/v1` both serve core endpoints through shared route registration.
- [ ] Response envelopes reuse the request-scoped `requestId`.
- [ ] Auth middleware accepts mock JWT-shaped tokens before mock-token fallback.
- [ ] mock-token fallback is controlled by runtime config.
- [ ] `/me` and `/profile` share a compatible projection.
- [ ] `/alerts/batch-handle` accepts `ack|handle|archive`.
- [ ] Flutter live default base URL is `/api/v1`.
- [ ] Flutter API headers prefer access tokens and only fallback to `mock-token-{role}` in the helper.
- [ ] Compatibility matrix exists and names `/api` commitments.
- [ ] Backend tests and focused Flutter tests pass.

