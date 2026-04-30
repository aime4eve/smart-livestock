const { describe, test } = require('node:test');
const assert = require('node:assert/strict');

process.env.ENABLE_MOCK_TOKEN = 'true';
process.env.MOCK_TOKEN_ALLOWED_ENVS = 'development,dev,staging';

const { app } = require('../server');

async function withServer(fn) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

describe('B2B Dashboard API', () => {
  const b2bAuth = 'Bearer mock-token-b2b-admin';

  test('GET /b2b/dashboard returns aggregate metrics', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/dashboard`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.totalFarms >= 1);
      assert.ok(body.data.totalLivestock >= 0);
      assert.ok(body.data.contractStatus);
    });
  });

  test('GET /b2b/farms returns partner farms', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/farms`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.items.length >= 1);
    });
  });

  test('POST /b2b/farms creates sub-farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/farms`, {
        method: 'POST',
        headers: {
          authorization: b2bAuth,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          name: '新合作牧场',
          ownerName: '钱八',
          contactPhone: '13800000006',
          region: '华北',
        }),
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.type, 'farm');
      assert.equal(body.data.parentTenantId, 'tenant_p001');
      assert.equal(body.data.ownerId.startsWith('u_'), true);
      assert.equal(body.data.ownerToken.startsWith('mock-token-u_'), true);
    });
  });

  test('GET /b2b/contract/current returns contract', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/contract/current`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data);
      assert.equal(body.data.status, 'active');
      assert.equal(body.data.effectiveTier, 'standard');
    });
  });

  test('GET /b2b/contract/usage-summary returns usage data', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/contract/usage-summary`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.totalFarms >= 1);
      assert.ok(body.data.monthlyBreakdown);
    });
  });

  test('non-b2b_admin cannot access /b2b/dashboard', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/dashboard`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 403);
    });
  });
});
