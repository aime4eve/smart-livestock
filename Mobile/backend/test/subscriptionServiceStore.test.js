const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;
const crypto = require('crypto');

function hashKey(raw) {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function hoursAgo(hours) {
  const d = new Date(Date.now() - hours * 60 * 60 * 1000);
  return d.toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

function daysAgo(days) {
  return hoursAgo(days * 24);
}

let store;
beforeEach(() => {
  delete require.cache[require.resolve('../data/subscriptionServiceStore')];
  store = require('../data/subscriptionServiceStore');
  store.reset();
});

describe('subscriptionServiceStore', () => {
  // ---- Create ----
  test('create generates serviceKey with SL-SUB-XXXX format', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    assert.ok(result.rawServiceKey);
    assert.match(result.rawServiceKey, /^SL-SUB-[0-9A-F]{4}-[0-9A-F]{4}$/);
  });

  test('create stores only keyHash (SHA-256), not raw key', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    assert.ok(result.subscription.keyHash);
    assert.equal(result.subscription.keyHash, hashKey(result.rawServiceKey));
    // The subscription object should NOT have a rawServiceKey property
    assert.equal(result.subscription.rawServiceKey, undefined);
  });

  test('raw serviceKey returned only once at creation', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    assert.ok(result.rawServiceKey);

    // Subsequent calls to getByPartnerTenantId should not include rawServiceKey
    const svc = store.getByPartnerTenantId('tenant_p001');
    assert.ok(svc);
    assert.equal(svc.rawServiceKey, undefined);
    assert.equal(svc.keyHash, hashKey(result.rawServiceKey));
  });

  test('create syncs serviceKey (hash) to tenantStore', () => {
    store.create({ partnerTenantId: 'tenant_p002' });
    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_p002');
    assert.ok(tenant);
    // tenant.serviceKey should be set (the hash, not the raw key)
    assert.ok(tenant.serviceKey);
    // Verify it's a SHA-256 hash (64 hex chars)
    assert.match(tenant.serviceKey, /^[0-9a-f]{64}$/);
  });

  test('create validates required partnerTenantId', () => {
    const result = store.create({});
    assert.equal(result.error, 'validation_error');
    assert.equal(result.message, 'partnerTenantId is required');
  });

  // ---- Heartbeat ----
  test('heartbeat updates heartbeatAt and returns ok status', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const hb = store.heartbeat(result.rawServiceKey);
    assert.equal(hb.status, 'active');
    assert.equal(hb.message, 'ok');

    const svc = store.getByPartnerTenantId('tenant_p001');
    assert.ok(svc.lastHeartbeatAt);
    assert.equal(svc.heartbeatCount, 1);
  });

  test('heartbeat with invalid key returns error', () => {
    store.create({ partnerTenantId: 'tenant_p001' });
    const hb = store.heartbeat('INVALID-KEY');
    assert.equal(hb.error, 'invalid_key');
  });

  test('heartbeat auto-recovers degraded status back to active', () => {
    const result = store.create({ partnerTenantId: 'tenant_p002' });
    const svc = store.getByPartnerTenantId('tenant_p002');
    svc.status = 'degraded';

    const hb = store.heartbeat(result.rawServiceKey);
    assert.equal(hb.status, 'active');
    assert.equal(hb.message, 'ok');
    assert.equal(svc.status, 'active');
  });

  test('heartbeat syncs tenant.heartbeatAt', () => {
    const result = store.create({ partnerTenantId: 'tenant_p002' });
    store.heartbeat(result.rawServiceKey);
    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_p002');
    assert.ok(tenant.heartbeatAt);
  });

  // ---- Status scanning ----
  test('scan detects overdue heartbeats (>24h) and transitions to grace_period', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const svc = store.getByPartnerTenantId('tenant_p001');
    svc.lastHeartbeatAt = hoursAgo(25);

    const affected = store.scan();
    assert.ok(affected.includes(svc.id));
    assert.equal(svc.status, 'grace_period');
  });

  test('scan transitions grace_period to degraded when beyond 15 days', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const svc = store.getByPartnerTenantId('tenant_p001');
    svc.status = 'grace_period';
    svc.lastHeartbeatAt = daysAgo(16);

    const affected = store.scan();
    assert.ok(affected.includes(svc.id));
    assert.equal(svc.status, 'degraded');
  });

  test('scan does not transition services with recent heartbeat', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const svc = store.getByPartnerTenantId('tenant_p001');
    svc.lastHeartbeatAt = hoursAgo(1);

    const affected = store.scan();
    assert.ok(!affected.includes(svc.id));
    assert.equal(svc.status, 'active');
  });

  test('scan does not transition revoked services', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    store.revoke(result.subscription.id);
    const svc = store.getByPartnerTenantId('tenant_p001');
    svc.lastHeartbeatAt = hoursAgo(25);

    const affected = store.scan();
    assert.ok(!affected.includes(svc.id));
    assert.equal(svc.status, 'revoked');
  });

  // ---- Renew ----
  test('renew extends expiresAt', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const newExpiry = '2028-01-01T00:00:00+08:00';
    const renewResult = store.renew(result.subscription.id, newExpiry);
    assert.ok(renewResult.subscription);
    assert.equal(renewResult.subscription.expiresAt, newExpiry);
    assert.ok(renewResult.subscription.updatedAt);
  });

  test('renew returns error for unknown id', () => {
    const result = store.renew('nonexistent', '2028-01-01T00:00:00+08:00');
    assert.equal(result.error, 'not_found');
  });

  // ---- Revoke ----
  test('revoke changes status to revoked', () => {
    const result = store.create({ partnerTenantId: 'tenant_p001' });
    const revokeResult = store.revoke(result.subscription.id);
    assert.ok(revokeResult.subscription);
    assert.equal(revokeResult.subscription.status, 'revoked');
  });

  test('revoke returns error for unknown id', () => {
    const result = store.revoke('nonexistent');
    assert.equal(result.error, 'not_found');
  });

  // ---- List / Query ----
  test('getByPartnerTenantId returns service for a partner', () => {
    store.create({ partnerTenantId: 'tenant_p001' });
    store.create({ partnerTenantId: 'tenant_p002' });

    const svc = store.getByPartnerTenantId('tenant_p002');
    assert.ok(svc);
    assert.equal(svc.partnerTenantId, 'tenant_p002');
  });

  test('getByPartnerTenantId returns null for unknown partner', () => {
    const notFound = store.getByPartnerTenantId('nonexistent');
    assert.equal(notFound, null);
  });

  test('list returns paginated services', () => {
    store.create({ partnerTenantId: 'tenant_p001' });
    store.create({ partnerTenantId: 'tenant_p002' });
    store.create({ partnerTenantId: 'tenant_p001' });
    store.create({ partnerTenantId: 'tenant_p002' });

    const result = store.list({ page: 1, pageSize: 2 });
    assert.equal(result.items.length, 2);
    assert.equal(result.total, 4);
    assert.equal(result.page, 1);
    assert.equal(result.pageSize, 2);
  });

  test('list filters by partnerTenantId', () => {
    store.create({ partnerTenantId: 'tenant_p001' });
    store.create({ partnerTenantId: 'tenant_p002' });

    const result = store.list({ partnerTenantId: 'tenant_p001' });
    assert.equal(result.items.length, 1);
    assert.equal(result.items[0].partnerTenantId, 'tenant_p001');
  });

  test('list filters by status', () => {
    const r1 = store.create({ partnerTenantId: 'tenant_p001' });
    store.revoke(r1.subscription.id);
    store.create({ partnerTenantId: 'tenant_p002' });

    const activeResult = store.list({ status: 'active' });
    assert.equal(activeResult.items.length, 1);
    assert.equal(activeResult.items[0].status, 'active');

    const revokedResult = store.list({ status: 'revoked' });
    assert.equal(revokedResult.items.length, 1);
    assert.equal(revokedResult.items[0].status, 'revoked');
  });

  // ---- Reset ----
  test('reset clears all services', () => {
    store.create({ partnerTenantId: 'tenant_p001' });
    store.create({ partnerTenantId: 'tenant_p002' });

    store.reset();
    const result = store.list({});
    assert.equal(result.items.length, 0);
    assert.equal(result.total, 0);
  });
});
