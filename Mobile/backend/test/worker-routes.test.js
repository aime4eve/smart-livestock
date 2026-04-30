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

describe('Farm worker API', () => {
  test('GET /farms/:farmId/workers returns workers for owner farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });

      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(Array.isArray(body.data.items));
      assert.ok(body.data.total >= 1);
    });
  });

  test('GET /farms/:farmId/workers returns 403 for unauthorized owner farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_005/workers`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });

      assert.equal(res.status, 403);
    });
  });

  test('POST /farms/:farmId/workers returns 409 for duplicate assignment', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-owner',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ userId: 'u_002', role: 'worker' }),
      });

      assert.equal(res.status, 409);
    });
  });

  test('DELETE /farms/:farmId/workers/:id returns 404 for missing assignment', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers/missing`, {
        method: 'DELETE',
        headers: { authorization: 'Bearer mock-token-owner' },
      });

      assert.equal(res.status, 404);
      const body = await res.json();
      assert.equal(body.message, '牧工分配不存在');
    });
  });
});
