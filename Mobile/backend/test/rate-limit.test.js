const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;

describe('rateLimit middleware', () => {
  let rateLimit, resetWindows;

  beforeEach(() => {
    delete require.cache[require.resolve('../middleware/rateLimit')];
    const mod = require('../middleware/rateLimit');
    rateLimit = mod.rateLimitMiddleware;
    resetWindows = mod.resetWindows;
    resetWindows();
  });

  function mockReq(apiConsumer, apiTier) {
    return {
      apiConsumer: apiConsumer ?? null,
      apiTier: apiTier ?? undefined,
    };
  }

  function mockRes() {
    const headers = {};
    return {
      set: (key, value) => { headers[key] = value; },
      getHeaders: () => headers,
      fail: (status, code, message) => {
        const err = new Error(message);
        err.statusCode = status;
        err.errorCode = code;
        err.isRateLimited = true;
        throw err;
      },
    };
  }

  function callMiddleware(req, res) {
    let nextCalled = false;
    try {
      rateLimit(req, res, () => { nextCalled = true; });
    } catch (e) {
      if (e.isRateLimited) {
        return { rateLimited: true, status: e.statusCode, code: e.errorCode };
      }
      throw e;
    }
    return { nextCalled };
  }

  test('allows requests within limit', () => {
    const req = mockReq({ tenantId: 'tenant_a001', tier: 'growth' }, 'growth');
    const res = mockRes();

    // growth tier has 100/min, so 50 requests should all pass
    for (let i = 0; i < 50; i++) {
      const result = callMiddleware(req, res);
      assert.ok(result.nextCalled, `request ${i + 1} should be allowed`);
    }
    const headers = res.getHeaders();
    assert.ok(Number(headers['X-RateLimit-Limit']) > 0, 'X-RateLimit-Limit should be set');
    assert.equal(headers['X-RateLimit-Limit'], '100', 'growth tier limit is 100');
  });

  test('blocks requests exceeding limit (429)', () => {
    const req = mockReq({ tenantId: 'tenant_b001', tier: 'free' }, 'free');
    const res = mockRes();

    // free tier has 10/min, send exactly 10 (all should pass)
    for (let i = 0; i < 10; i++) {
      const result = callMiddleware(req, res);
      assert.ok(result.nextCalled, `request ${i + 1} should be allowed`);
    }

    // 11th request should be blocked
    const blocked = callMiddleware(req, res);
    assert.ok(blocked.rateLimited, '11th request should be rate limited');
    assert.equal(blocked.status, 429);
    assert.equal(blocked.code, 'RATE_LIMITED');
  });

  test('sets X-RateLimit-* headers', () => {
    const req = mockReq({ tenantId: 'tenant_c001', tier: 'growth' }, 'growth');
    const res = mockRes();

    callMiddleware(req, res);
    const headers = res.getHeaders();

    assert.ok(headers['X-RateLimit-Limit'], 'X-RateLimit-Limit should be set');
    assert.ok(headers['X-RateLimit-Remaining'], 'X-RateLimit-Remaining should be set');
    assert.ok(headers['X-RateLimit-Reset'], 'X-RateLimit-Reset should be set');

    assert.equal(Number(headers['X-RateLimit-Limit']), 100);
    // With 1 request made, remaining should be 99
    assert.equal(Number(headers['X-RateLimit-Remaining']), 99);

    // Remaining decreases with each request
    callMiddleware(req, res);
    assert.equal(Number(res.getHeaders()['X-RateLimit-Remaining']), 98);
  });

  test('different tiers have different limits', () => {
    const freeReq = mockReq({ tenantId: 'tenant_f001', tier: 'free' }, 'free');
    const growthReq = mockReq({ tenantId: 'tenant_g001', tier: 'growth' }, 'growth');
    const scaleReq = mockReq({ tenantId: 'tenant_s001', tier: 'scale' }, 'scale');

    const freeRes = mockRes();
    callMiddleware(freeReq, freeRes);
    assert.equal(freeRes.getHeaders()['X-RateLimit-Limit'], '10');

    const growthRes = mockRes();
    callMiddleware(growthReq, growthRes);
    assert.equal(growthRes.getHeaders()['X-RateLimit-Limit'], '100');

    const scaleRes = mockRes();
    callMiddleware(scaleReq, scaleRes);
    assert.equal(scaleRes.getHeaders()['X-RateLimit-Limit'], '1000');
  });

  test('resets windows correctly', () => {
    const req = mockReq({ tenantId: 'tenant_r001', tier: 'free' }, 'free');
    const res = mockRes();

    // Send requests up to limit
    for (let i = 0; i < 10; i++) {
      callMiddleware(req, res);
    }

    // Should be blocked now
    let blocked = callMiddleware(req, res);
    assert.ok(blocked.rateLimited, 'should be blocked at limit');

    // Reset windows
    resetWindows();

    // Should be allowed again
    const res2 = mockRes();
    const result = callMiddleware(req, res2);
    assert.ok(result.nextCalled, 'should be allowed after reset');
    assert.equal(res2.getHeaders()['X-RateLimit-Remaining'], '9');
  });

  test('anonymous tenants use free tier default', () => {
    // When req.apiConsumer is null/undefined, defaults to free tier (10/min)
    const req = mockReq(null, undefined);  // no apiConsumer, no apiTier
    const res = mockRes();

    callMiddleware(req, res);
    assert.equal(res.getHeaders()['X-RateLimit-Limit'], '10',
      'anonymous should get free tier limit');
  });

  test('separate tenants have independent rate limits', () => {
    const reqA = mockReq({ tenantId: 'tenant_a001', tier: 'free' }, 'free');
    const reqB = mockReq({ tenantId: 'tenant_b001', tier: 'free' }, 'free');

    const resA = mockRes();
    // Fill up tenant A
    for (let i = 0; i < 10; i++) {
      callMiddleware(reqA, resA);
    }

    // Tenant B should still be allowed (different tenant)
    const resB = mockRes();
    for (let i = 0; i < 10; i++) {
      const result = callMiddleware(reqB, resB);
      assert.ok(result.nextCalled, `tenant B request ${i + 1} should be allowed`);
    }

    // Tenant A should be blocked
    const blockedA = callMiddleware(reqA, resA);
    assert.ok(blockedA.rateLimited, 'tenant A should be blocked');
  });
});
