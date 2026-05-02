const { describe, test } = require('node:test');
const assert = require('node:assert/strict');

describe('contractStore', () => {
  let store;

  test('getByPartnerTenantId returns contract for known partner', () => {
    delete require.cache[require.resolve('../data/contractStore')];
    store = require('../data/contractStore');
    const contract = store.getByPartnerTenantId('tenant_p001');
    assert.ok(contract);
    assert.equal(contract.partnerTenantId, 'tenant_p001');
    assert.equal(contract.status, 'active');
    assert.equal(contract.effectiveTier, 'standard');
  });

  test('getByPartnerTenantId returns null for unknown partner', () => {
    const contract = store.getByPartnerTenantId('nonexistent');
    assert.equal(contract, null);
  });

  test('create validates required fields', () => {
    // Missing partnerTenantId
    let result = store.create({ effectiveTier: 'standard', revenueShareRatio: 0.15 });
    assert.equal(result.error, 'validation_error');

    // Missing effectiveTier
    result = store.create({ partnerTenantId: 'tenant_p001', revenueShareRatio: 0.15 });
    assert.equal(result.error, 'validation_error');

    // Missing revenueShareRatio
    result = store.create({ partnerTenantId: 'tenant_p001', effectiveTier: 'standard' });
    assert.equal(result.error, 'validation_error');
  });

  test('create creates a contract successfully', () => {
    const result = store.create({
      partnerTenantId: 'tenant_p002',
      effectiveTier: 'premium',
      revenueShareRatio: 0.2,
      expiresAt: '2027-06-01T00:00:00+08:00',
      signedBy: '李四',
    });
    assert.ok(result.contract);
    assert.equal(result.contract.partnerTenantId, 'tenant_p002');
    assert.equal(result.contract.effectiveTier, 'premium');
    assert.equal(result.contract.revenueShareRatio, 0.2);
    assert.equal(result.contract.status, 'active');
    assert.ok(result.contract.id);
    assert.ok(result.contract.createdAt);
    assert.ok(result.contract.updatedAt);
    assert.equal(result.contract.terminatedAt, null);
  });

  test('create syncs tenantStore fields', () => {
    const contract = store.getByPartnerTenantId('tenant_p002');
    assert.ok(contract);

    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_p002');
    assert.ok(tenant);
    assert.equal(tenant.contractId, contract.id);
    assert.equal(tenant.revenueShareRatio, 0.2);
  });

  test('update returns not_found for unknown id', () => {
    const result = store.update('nonexistent', { effectiveTier: 'basic' });
    assert.equal(result.error, 'not_found');
  });

  test('update modifies contract fields', () => {
    const contract = store.getByPartnerTenantId('tenant_p001');
    assert.ok(contract);

    const result = store.update(contract.id, {
      effectiveTier: 'premium',
      revenueShareRatio: 0.25,
      expiresAt: '2028-01-01T00:00:00+08:00',
      signedBy: '赵六',
    });
    assert.ok(result.contract);
    assert.equal(result.contract.effectiveTier, 'premium');
    assert.equal(result.contract.revenueShareRatio, 0.25);
    assert.equal(result.contract.expiresAt, '2028-01-01T00:00:00+08:00');
    assert.equal(result.contract.signedBy, '赵六');
    assert.ok(result.contract.updatedAt);
  });

  test('update syncs revenueShareRatio to tenantStore', () => {
    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_p001');
    assert.ok(tenant);
    assert.equal(tenant.revenueShareRatio, 0.25);
  });

  test('terminate returns not_found for unknown id', () => {
    const result = store.terminate('nonexistent');
    assert.equal(result.error, 'not_found');
  });

  test('terminate sets status to expired', () => {
    const contract = store.getByPartnerTenantId('tenant_p001');
    assert.ok(contract);

    const result = store.terminate(contract.id);
    assert.ok(result.contract);
    assert.equal(result.contract.status, 'expired');
    assert.ok(result.contract.terminatedAt);
  });

  test('list returns all contracts with pagination', () => {
    const result = store.list({});
    assert.ok(Array.isArray(result.items));
    assert.ok(result.items.length >= 2);
    assert.equal(result.page, 1);
    assert.equal(result.pageSize, 20);
    assert.ok(result.total >= 2);
  });

  test('list filters by partnerId', () => {
    const result = store.list({ partnerId: 'tenant_p001' });
    assert.ok(Array.isArray(result.items));
    assert.ok(result.items.length > 0);
    result.items.forEach((c) => {
      assert.equal(c.partnerTenantId, 'tenant_p001');
    });
  });

  test('list filters by status', () => {
    const result = store.list({ status: 'expired' });
    assert.ok(Array.isArray(result.items));
    result.items.forEach((c) => {
      assert.equal(c.status, 'expired');
    });
  });

  test('reset restores to seed state', () => {
    store.reset();
    const contracts = store.list({});
    assert.equal(contracts.items.length, 1);
    assert.equal(contracts.items[0].id, 'contract_001');

    // Terminated contract should be gone after reset
    const expired = store.list({ status: 'expired' });
    assert.equal(expired.items.length, 0);
  });
});
