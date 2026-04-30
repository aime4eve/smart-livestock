const assert = require('node:assert/strict');
const { test } = require('node:test');
const { farmContextMiddleware } = require('../middleware/farmContext');
const tenantStore = require('../data/tenantStore');

function mockReq(user) {
  return { user, headers: {} };
}

function mockRes() {
  return {};
}

test('farmContext: owner role sets activeFarmTenantId from findByOwnerId', () => {
  tenantStore.reset();
  let capturedReq;
  const next = () => {};
  const req = mockReq({ userId: 'u_001', role: 'owner', tenantId: 'tenant_001' });

  farmContextMiddleware(req, mockRes(), next);
  assert.equal(req.activeFarmTenantId, 'tenant_001',
    'owner u_001 should resolve to tenant_001');
});

test('farmContext: worker role uses first farm assignment', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_002', role: 'worker', tenantId: 'tenant_002' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, 'tenant_001');
});

test('farmContext: worker without farm assignment gets null', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'nonexistent', role: 'worker' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, null);
});

test('farmContext: owner can select farm from x-active-farm header', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_001', role: 'owner', tenantId: 'tenant_001' });
  req.headers['x-active-farm'] = 'tenant_007';

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, 'tenant_007');
});

test('farmContext: worker can select assigned farm from x-active-farm header', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_002', role: 'worker', tenantId: 'tenant_001' });
  req.headers['x-active-farm'] = 'tenant_007';

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, 'tenant_007');
});

test('farmContext: platform_admin role sets activeFarmTenantId to null', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_003', role: 'platform_admin', tenantId: 'tenant_003' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, null);
});

test('farmContext: b2b_admin role sets activeFarmTenantId to null', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_004', role: 'b2b_admin', tenantId: 'tenant_p001' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, null);
});

test('farmContext: api_consumer role sets activeFarmTenantId to null', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'u_005', role: 'api_consumer', tenantId: 'tenant_a001' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, null);
});

test('farmContext: owner with no farm gets null', () => {
  tenantStore.reset();
  const req = mockReq({ userId: 'nonexistent', role: 'owner' });

  farmContextMiddleware(req, mockRes(), () => {});
  assert.equal(req.activeFarmTenantId, null,
    'owner with no farm should have null activeFarmTenantId');
});

test('farmContext: req without user does not crash', () => {
  tenantStore.reset();
  const req = {};

  farmContextMiddleware(req, mockRes(), () => {});
  // req.user is undefined, falls to else branch → activeFarmTenantId = null
  assert.equal(req.activeFarmTenantId, null);
});

test('farmContext: calls next after processing', () => {
  tenantStore.reset();
  let called = false;
  const req = mockReq({ userId: 'u_001', role: 'owner', tenantId: 'tenant_001' });

  farmContextMiddleware(req, mockRes(), () => { called = true; });
  assert.equal(called, true, 'next() must be called');
});
