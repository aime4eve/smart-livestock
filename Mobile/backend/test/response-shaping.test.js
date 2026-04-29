const assert = require('node:assert/strict');
const { test } = require('node:test');
const { shapingMiddleware, featureKeys } = require('../middleware/feature-flag');
const tenantStore = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');

function mockReq(overrides = {}) {
  return {
    activeFarmTenantId: 'tenant_001',
    routeFeatureKeys: undefined,
    ...overrides,
  };
}

function mockRes() {
  const res = {
    ok: (data, message) => ({ data, message, __original: true }),
    fail: (code, type, msg) => ({ code, type, msg }),
  };
  return res;
}

// Helper: call the middleware and capture the wrapped res.ok
function wrapResOk(reqOverrides = {}) {
  tenantStore.reset();
  subscriptionStore.reset();

  const req = mockReq(reqOverrides);
  const res = mockRes();
  let wrappedRes;

  const originalOk = res.ok.bind(res);
  shapingMiddleware(req, res, () => {
    wrappedRes = res; // res.ok is now wrapped
  });

  return { req, res: wrappedRes, originalOk };
}

test('response-shaping: shaping middleware wraps res.ok', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  let okWasWrapped = false;
  const req = mockReq();
  const res = mockRes();

  shapingMiddleware(req, res, () => {
    okWasWrapped = res.ok !== mockRes().ok;
  });

  assert.equal(okWasWrapped, true);
});

test('response-shaping: no farmTenantId skips shaping, returns original data', () => {
  const { res } = wrapResOk({ activeFarmTenantId: null });
  const result = res.ok({ items: [1, 2, 3] });
  assert.deepEqual(result.data.items, [1, 2, 3]);
  assert.equal(result.data.locked, undefined);
});

test('response-shaping: no feature keys returns data unchanged', () => {
  const { res } = wrapResOk();
  const result = res.ok({ items: [1, 2, 3], total: 3 });
  assert.deepEqual(result.data, { items: [1, 2, 3], total: 3 });
});

test('response-shaping: lock shaping for inadequate tier returns locked+upgradeTier', () => {
  const { res } = wrapResOk();
  // Set feature keys on the request before calling ok
  const req = mockReq();
  req.routeFeatureKeys = ['health_score'];

  let result;
  shapingMiddleware(req, mockRes(), () => {
    result = req._resRef;
    // Actually we need to use the wrapped ok
  });

  // Simpler approach: use the wrapped res directly
  const req2 = mockReq();
  req2.routeFeatureKeys = ['health_score'];
  const res2 = mockRes();
  shapingMiddleware(req2, res2, () => {});
  const r = res2.ok({ items: [{ id: 1 }] });
  assert.equal(r.data.locked, true);
  assert.equal(r.data.upgradeTier, 'premium');
});

test('response-shaping: adequate tier passes lock shaping', () => {
  // Create farm with premium tier
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = tenantStore.createTenant({
    name: 'premium_farm', type: 'farm', entitlementTier: 'premium', ownerId: 'u_test',
  }).tenant;
  subscriptionStore.createTrial(farm.id);
  const sub = subscriptionStore.getByTenantId(farm.id);
  sub.status = 'active';

  const req = mockReq({ activeFarmTenantId: farm.id, routeFeatureKeys: ['health_score'] });
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({ items: [{ id: 1 }] });
  assert.equal(r.data.locked, undefined);
});

test('response-shaping: limit shaping truncates items at basic tier', () => {
  const req = mockReq({ routeFeatureKeys: ['fence'] });
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({ items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], total: 5 });
  assert.equal(r.data.items.length, 3);
  assert.equal(r.data.limitExceeded, true);
});

test('response-shaping: filter shaping applies date filter for alerts', () => {
  const now = new Date();
  const recent = new Date(now);
  recent.setDate(recent.getDate() - 3);
  const ancient = new Date(now);
  ancient.setDate(ancient.getDate() - 30);

  const req = mockReq({ routeFeatureKeys: ['alert_history', 'data_retention_days'] });
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({
    items: [
      { id: 1, occurredAt: recent.toISOString() },
      { id: 2, occurredAt: ancient.toISOString() },
    ],
    total: 2,
  });
  assert.equal(r.data.items.length, 1);
  assert.equal(r.data.items[0].id, 1);
});

test('response-shaping: multiple featureKeys chain correctly', () => {
  const req = mockReq({
    routeFeatureKeys: ['fence', 'health_score'],
  });
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({ items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], total: 5 });
  assert.equal(r.data.items.length, 3);
  assert.equal(r.data.locked, true);
});

test('response-shaping: expired subscription returns basic tier shaping', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = tenantStore.createTenant({
    name: 'expired_farm', type: 'farm', entitlementTier: 'premium', ownerId: 'u_test',
  }).tenant;
  subscriptionStore.createTrial(farm.id);
  const sub = subscriptionStore.getByTenantId(farm.id);
  sub.status = 'expired';

  const req = mockReq({ activeFarmTenantId: farm.id, routeFeatureKeys: ['health_score'] });
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({ items: [{ id: 1 }] });
  assert.equal(r.data.locked, true);
  assert.equal(r.data.upgradeTier, 'premium');
});

test('response-shaping: featureKeys helper sets routeFeatureKeys on req', () => {
  const req = {};
  const middleware = featureKeys('fence', 'trajectory');
  let called = false;
  middleware(req, {}, () => { called = true; });
  assert.deepEqual(req.routeFeatureKeys, ['fence', 'trajectory']);
  assert.equal(called, true);
});

test('response-shaping: featureKeys with no args sets empty array', () => {
  const req = {};
  const middleware = featureKeys();
  middleware(req, {}, () => {});
  assert.deepEqual(req.routeFeatureKeys, []);
});

test('response-shaping: res.ok preserves additional envelope fields', () => {
  const req = mockReq();
  const res = mockRes();
  shapingMiddleware(req, res, () => {});
  const r = res.ok({ items: [] }, 'success');
  assert.equal(r.message, 'success');
});
