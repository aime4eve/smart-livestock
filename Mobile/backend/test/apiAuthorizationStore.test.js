const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;

let store;
beforeEach(() => {
  delete require.cache[require.resolve('../data/apiAuthorizationStore')];
  delete require.cache[require.resolve('../data/tenantStore')];
  store = require('../data/apiAuthorizationStore');
  store.reset();
});

describe('apiAuthorizationStore', () => {
  test('create authorization record with pending status', () => {
    const result = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_001',
      requestedBy: 'u_005',
      reason: 'Need access to farm data for analysis',
    });

    assert.ok(result.authorization);
    assert.equal(result.authorization.apiTenantId, 'tenant_a001');
    assert.equal(result.authorization.farmTenantId, 'tenant_001');
    assert.equal(result.authorization.status, 'pending');
    assert.equal(result.authorization.requestedBy, 'u_005');
    assert.equal(result.authorization.reason, 'Need access to farm data for analysis');
    assert.equal(result.authorization.reviewedBy, null);
    assert.equal(result.authorization.reviewedAt, null);
    assert.ok(result.authorization.id);
    assert.ok(result.authorization.createdAt);
    assert.ok(result.authorization.updatedAt);
  });

  test('create returns validation error when required fields missing', () => {
    let result = store.create({ farmTenantId: 'tenant_001' });
    assert.equal(result.error, 'validation_error');

    result = store.create({ apiTenantId: 'tenant_a001' });
    assert.equal(result.error, 'validation_error');

    result = store.create({});
    assert.equal(result.error, 'validation_error');
  });

  test('approve changes status to approved and updates accessibleFarmTenantIds', () => {
    const created = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_001',
    });

    const result = store.approve(created.authorization.id, 'u_003');
    assert.ok(result.authorization);
    assert.equal(result.authorization.status, 'approved');
    assert.equal(result.authorization.reviewedBy, 'u_003');
    assert.ok(result.authorization.reviewedAt);
    assert.ok(result.authorization.updatedAt);

    // Verify tenant's accessibleFarmTenantIds was updated
    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_a001');
    assert.ok(tenant);
    assert.ok(Array.isArray(tenant.accessibleFarmTenantIds));
    assert.ok(tenant.accessibleFarmTenantIds.includes('tenant_001'));
  });

  test('approve does not duplicate farmTenantId in accessible list', () => {
    const created = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_001',
    });

    store.approve(created.authorization.id, 'u_003');

    // Create another authorization for the same apiTenantId+farmTenantId and approve it
    const second = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_001',
    });
    store.approve(second.authorization.id, 'u_003');

    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_a001');
    const count = tenant.accessibleFarmTenantIds.filter((id) => id === 'tenant_001').length;
    assert.equal(count, 1);
  });

  test('approve returns not_found for unknown id', () => {
    const result = store.approve('nonexistent', 'u_003');
    assert.equal(result.error, 'not_found');
  });

  test('reject changes status to rejected', () => {
    const created = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_002',
    });

    const result = store.reject(created.authorization.id, 'u_003');
    assert.ok(result.authorization);
    assert.equal(result.authorization.status, 'rejected');
    assert.equal(result.authorization.reviewedBy, 'u_003');
    assert.ok(result.authorization.reviewedAt);
    assert.ok(result.authorization.updatedAt);
  });

  test('reject returns not_found for unknown id', () => {
    const result = store.reject('nonexistent', 'u_003');
    assert.equal(result.error, 'not_found');
  });

  test('revoke removes farmTenantId from accessible list', () => {
    const created = store.create({
      apiTenantId: 'tenant_a001',
      farmTenantId: 'tenant_001',
    });

    // First approve
    store.approve(created.authorization.id, 'u_003');

    // Now revoke
    const result = store.revoke(created.authorization.id);
    assert.ok(result.authorization);
    assert.equal(result.authorization.status, 'revoked');
    assert.ok(result.authorization.updatedAt);

    // Verify tenant's accessibleFarmTenantIds no longer contains the farm
    const tenantStore = require('../data/tenantStore');
    const tenant = tenantStore.findById('tenant_a001');
    assert.ok(tenant);
    assert.ok(Array.isArray(tenant.accessibleFarmTenantIds));
    assert.equal(tenant.accessibleFarmTenantIds.includes('tenant_001'), false);
  });

  test('revoke returns not_found for unknown id', () => {
    const result = store.revoke('nonexistent');
    assert.equal(result.error, 'not_found');
  });

  test('list returns paginated results', () => {
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_003' });

    const result = store.list({});
    assert.ok(Array.isArray(result.items));
    assert.equal(result.items.length, 3);
    assert.equal(result.page, 1);
    assert.equal(result.pageSize, 20);
    assert.equal(result.total, 3);
  });

  test('list filters by apiTenantId', () => {
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_003' });
    // Create one for a different tenant
    store.create({ apiTenantId: 'tenant_a002', farmTenantId: 'tenant_004' });

    const result = store.list({ apiTenantId: 'tenant_a001' });
    assert.equal(result.total, 3);
    result.items.forEach((a) => {
      assert.equal(a.apiTenantId, 'tenant_a001');
    });
  });

  test('list filters by farmTenantId', () => {
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });

    const result = store.list({ farmTenantId: 'tenant_001' });
    assert.equal(result.total, 2);
    result.items.forEach((a) => {
      assert.equal(a.farmTenantId, 'tenant_001');
    });
  });

  test('list filters by status', () => {
    const a1 = store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    const a2 = store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_003' });

    store.approve(a1.authorization.id, 'u_003');
    store.reject(a2.authorization.id, 'u_003');

    const approved = store.list({ status: 'approved' });
    assert.equal(approved.total, 1);
    assert.equal(approved.items[0].farmTenantId, 'tenant_001');

    const rejected = store.list({ status: 'rejected' });
    assert.equal(rejected.total, 1);
    assert.equal(rejected.items[0].farmTenantId, 'tenant_002');

    const pending = store.list({ status: 'pending' });
    assert.equal(pending.total, 1);
    assert.equal(pending.items[0].farmTenantId, 'tenant_003');
  });

  test('list respects page and pageSize', () => {
    for (let i = 1; i <= 5; i++) {
      const id = `tenant_${String(i).padStart(3, '0')}`;
      store.create({ apiTenantId: 'tenant_a001', farmTenantId: id });
    }

    const page1 = store.list({ page: '1', pageSize: '2' });
    assert.equal(page1.items.length, 2);
    assert.equal(page1.page, 1);
    assert.equal(page1.pageSize, 2);
    assert.equal(page1.total, 5);

    const page3 = store.list({ page: '3', pageSize: '2' });
    assert.equal(page3.items.length, 1);
    assert.equal(page3.page, 3);
  });

  test('reset clears all authorizations', () => {
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });

    store.reset();
    const result = store.list({});
    assert.equal(result.items.length, 0);
    assert.equal(result.total, 0);
  });

  test('reset also resets _nextId', () => {
    store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_001' });
    store.reset();
    const first = store.create({ apiTenantId: 'tenant_a001', farmTenantId: 'tenant_002' });
    assert.equal(first.authorization.id, 'auth_001');
  });
});
