const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;

describe('apiKeyAuth middleware', () => {
  let apiKeyAuth, apiKeyStore, tenantStore;

  beforeEach(() => {
    delete require.cache[require.resolve('../middleware/apiKeyAuth')];
    delete require.cache[require.resolve('../data/apiKeyStore')];
    delete require.cache[require.resolve('../data/tenantStore')];
    delete require.cache[require.resolve('../data/apiTierStore')];
    apiKeyAuth = require('../middleware/apiKeyAuth').apiKeyAuthMiddleware;
    apiKeyStore = require('../data/apiKeyStore');
    tenantStore = require('../data/tenantStore');
    apiKeyStore.reset();
    tenantStore.reset();
  });

  function mockReq(headers) {
    return { headers: headers ?? {} };
  }

  function mockRes() {
    const calls = [];
    return {
      fail: (status, code, message) => {
        calls.push({ fail: true, status, code, message });
      },
      getFailCalls: () => calls,
    };
  }

  function callMiddleware(req, res) {
    let nextCalled = false;
    apiKeyAuth(req, res, () => { nextCalled = true; });
    const failCalls = res.getFailCalls();
    if (failCalls.length > 0) {
      return { nextCalled: false, fail: failCalls[0] };
    }
    return { nextCalled };
  }

  test('valid API key sets req.apiConsumer, req.apiTier, req.accessibleFarmTenantIds', () => {
    // Generate a valid key for tenant_a001
    const { rawKey } = apiKeyStore.generate('tenant_a001');

    const req = mockReq({ 'x-api-key': rawKey });
    const res = mockRes();

    const result = callMiddleware(req, res);
    assert.ok(result.nextCalled, 'valid key should call next()');
    assert.ok(req.apiConsumer, 'req.apiConsumer should be set');
    assert.equal(req.apiConsumer.tenantId, 'tenant_a001');
    assert.equal(req.apiConsumer.tier, 'growth');
    assert.equal(req.apiTier, 'growth');
    // tenant_a001 has accessibleFarmTenantIds: ['tenant_001'] from seed
    assert.deepEqual(req.accessibleFarmTenantIds, ['tenant_001']);
  });

  test('invalid API key returns 401', () => {
    const req = mockReq({ 'x-api-key': 'sl_apikey_invalid_key_1234567890abcdef' });
    const res = mockRes();

    const result = callMiddleware(req, res);
    assert.ok(!result.nextCalled, 'invalid key should not call next()');
    assert.ok(result.fail, 'should call res.fail');
    assert.equal(result.fail.status, 401);
    assert.equal(result.fail.code, 'AUTH_INVALID');
    assert.equal(result.fail.message, 'API Key 无效');
  });

  test('missing X-API-Key header returns 401', () => {
    const req = mockReq({});  // no x-api-key header
    const res = mockRes();

    const result = callMiddleware(req, res);
    assert.ok(!result.nextCalled, 'missing header should not call next()');
    assert.ok(result.fail, 'should call res.fail');
    assert.equal(result.fail.status, 401);
    assert.equal(result.fail.code, 'AUTH_REQUIRED');
    assert.equal(result.fail.message, '缺少 API Key');
  });

  test('valid key with no matching tenant defaults accessibleFarmTenantIds to []', () => {
    // Create an api tenant in apiKeyStore that does NOT exist in tenantStore
    // We do this by generating a key and then removing the tenant
    const { rawKey } = apiKeyStore.generate('tenant_a001');

    // Remove the tenant_a001 from tenantStore (simulate no matching tenant)
    // We can't directly remove it without knowing the index, so let's use a
    // tenantId that won't exist in tenantStore
    // Instead, we'll override validate to return a non-existent tenant id
    const originalValidate = apiKeyStore.validate;
    apiKeyStore.validate = function(raw) {
      const base = originalValidate.call(this, raw);
      if (base) {
        // Return a made-up tenant id that won't be in tenantStore
        return { apiTenantId: 'tenant_nonexistent_999', apiTier: 'free' };
      }
      return null;
    };

    const req = mockReq({ 'x-api-key': rawKey });
    const res = mockRes();

    const result = callMiddleware(req, res);
    assert.ok(result.nextCalled, 'valid key should call next()');
    assert.ok(req.apiConsumer, 'req.apiConsumer should be set');
    assert.deepEqual(req.accessibleFarmTenantIds, [],
      'should default to empty array when tenant not found');
  });
});
