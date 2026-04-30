const assert = require('node:assert/strict');
const { describe, test } = require('node:test');

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

describe('Farm switching API', () => {
  test('GET /my-farms returns farms and active farm for owner', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });

      assert.equal(res.status, 200);
      const body = await res.json();
      const farmIds = body.data.farms.map((farm) => farm.id);
      assert.ok(farmIds.includes('tenant_001'));
      assert.ok(farmIds.includes('tenant_007'));
      assert.ok(body.data.farms.length >= 2);
      assert.ok(body.data.activeFarmId);
    });
  });

  test('GET /my-farms returns farms for worker', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: { authorization: 'Bearer mock-token-worker' },
      });

      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.farms.length >= 1);
      assert.ok(body.data.activeFarmId);
    });
  });

  test('POST /switch-farm succeeds for owner farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/switch-farm`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-owner',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ farmTenantId: 'tenant_007' }),
      });

      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.activeFarmId, 'tenant_007');
      assert.ok(body.data.farmName);
    });
  });

  test('POST /switch-farm returns 403 for unauthorized worker farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/switch-farm`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-worker',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ farmTenantId: 'tenant_005' }),
      });

      assert.equal(res.status, 403);
    });
  });

  test('x-active-farm header selects active farm for owner', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: {
          authorization: 'Bearer mock-token-owner',
          'x-active-farm': 'tenant_007',
        },
      });

      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.activeFarmId, 'tenant_007');
    });
  });
});
