const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;

let store;
beforeEach(() => {
  delete require.cache[require.resolve('../data/apiTierStore')];
  store = require('../data/apiTierStore');
  store.reset();
});

describe('apiTierStore', () => {
  test('getByTenantId returns ApiTier object for tenant_a001 (P1-5 seed)', () => {
    const tier = store.getByTenantId('tenant_a001');
    assert.ok(tier);
    assert.equal(tier.apiTenantId, 'tenant_a001');
    assert.equal(tier.tier, 'growth');
    assert.equal(tier.monthlyQuota, 10000);
    assert.ok(tier.usedThisMonth !== undefined);
    assert.equal(tier.overageUnitPrice, 0.01);
  });

  test('getByTenantId returns null for non-api tenant', () => {
    const tier = store.getByTenantId('tenant_001');
    assert.equal(tier, null);
  });

  test('incrementUsage increases usedThisMonth', () => {
    const tier = store.getByTenantId('tenant_a001');
    const before = tier.usedThisMonth;

    store.incrementUsage('tenant_a001', 5);
    const updated = store.getByTenantId('tenant_a001');
    assert.equal(updated.usedThisMonth, before + 5);

    store.incrementUsage('tenant_a001', 3);
    const updated2 = store.getByTenantId('tenant_a001');
    assert.equal(updated2.usedThisMonth, before + 5 + 3);
  });

  test('incrementUsage allows over-quota calls', () => {
    store.incrementUsage('tenant_a001', 99999);
    const tier = store.getByTenantId('tenant_a001');
    assert.ok(tier.usedThisMonth >= 99999);
    // Should still be functional even though over quota
    assert.equal(tier.usedThisMonth, 99999);
  });

  test('checkQuota returns remaining count', () => {
    const quota = store.checkQuota('tenant_a001');
    assert.ok(quota);
    assert.equal(quota.total, 10000);
    assert.equal(quota.used, 0);
    assert.equal(quota.remaining, 10000);

    store.incrementUsage('tenant_a001', 3000);
    const quota2 = store.checkQuota('tenant_a001');
    assert.equal(quota2.used, 3000);
    assert.equal(quota2.remaining, 7000);
  });

  test('checkQuota returns null for non-api tenant', () => {
    const quota = store.checkQuota('tenant_001');
    assert.equal(quota, null);
  });

  test('getByTenantId returns free tier for tenant_a002 (free trial)', () => {
    const tier = store.getByTenantId('tenant_a002');
    assert.ok(tier);
    assert.equal(tier.apiTenantId, 'tenant_a002');
    assert.equal(tier.tier, 'free');
    assert.equal(tier.monthlyQuota, 1000);
    assert.equal(tier.usedThisMonth, 0);
    assert.equal(tier.overageUnitPrice, 0);
    assert.equal(tier.resetAt, null);
  });

  test('getByTenantId returns free tier for tenant_008 (enterprise farm)', () => {
    const tier = store.getByTenantId('tenant_008');
    assert.ok(tier);
    assert.equal(tier.apiTenantId, 'tenant_008');
    assert.equal(tier.tier, 'free');
    assert.equal(tier.monthlyQuota, 1000);
    assert.equal(tier.usedThisMonth, 0);
    assert.equal(tier.overageUnitPrice, 0);
    assert.equal(tier.resetAt, null);
  });

  test('resetMonthlyUsage resets at month boundary', () => {
    store.incrementUsage('tenant_a001', 5000);
    const count = store.resetMonthlyUsage();
    assert.equal(count, 3); // tenant_a001 + tenant_a002 + tenant_008

    const tier = store.getByTenantId('tenant_a001');
    assert.equal(tier.usedThisMonth, 0);
    assert.ok(tier.resetAt);
  });

  test('reset restores initial seed data', () => {
    store.incrementUsage('tenant_a001', 5000);
    store.resetMonthlyUsage();

    // Now reset everything back to initial
    store.reset();
    const tier = store.getByTenantId('tenant_a001');
    assert.ok(tier);
    assert.equal(tier.tier, 'growth');
    assert.equal(tier.monthlyQuota, 10000);
    assert.equal(tier.usedThisMonth, 0);
    assert.equal(tier.overageUnitPrice, 0.01);
    assert.equal(tier.resetAt, null);
  });

  test('incrementUsage for non-existent tenant returns null', () => {
    const result = store.incrementUsage('nonexistent', 10);
    assert.equal(result, null);
  });
});
