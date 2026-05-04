const assert = require('node:assert/strict');
const { test } = require('node:test');
const store = require('../data/tenantStore');

test('tenantStore: sliceForPage 默认分页返回全部', () => {
  store.reset();
  const res = store.sliceForPage({});
  assert.equal(res.page, 1);
  assert.equal(res.pageSize, 20);
  assert.equal(res.total, 14);
  assert.equal(res.items.length, 14);
});

test('tenantStore: sliceForPage 支持 status 过滤', () => {
  store.reset();
  const res = store.sliceForPage({ status: 'disabled' });
  assert.equal(res.items.length, 1);
  assert.equal(res.items[0].status, 'disabled');
});

test('tenantStore: sliceForPage 支持 search 名称模糊', () => {
  store.reset();
  const res = store.sliceForPage({ search: '草原' });
  assert.equal(res.items.length, 1);
  assert.equal(res.items[0].name, '华北草原牧场');
});

test('tenantStore: sliceForPage 支持 licenseUsage 排序', () => {
  store.reset();
  const res = store.sliceForPage({ sort: 'licenseUsage', order: 'desc' });
  assert.equal(res.items[0].name, '东北黑土地牧场');
});

test('tenantStore: findById 命中', () => {
  store.reset();
  const t = store.findById('tenant_001');
  assert.equal(t.name, '华东示范牧场');
});

test('tenantStore: createTenant 校验 name 必填', () => {
  store.reset();
  const { error } = store.createTenant({ licenseTotal: 100 });
  assert.equal(error, 'name_required');
});

test('tenantStore: createTenant 校验名称唯一', () => {
  store.reset();
  const { error } = store.createTenant({ name: '华东示范牧场', licenseTotal: 100 });
  assert.equal(error, 'name_conflict');
});

test('tenantStore: createTenant 成功', () => {
  store.reset();
  const { tenant } = store.createTenant({ name: '测试新租户', licenseTotal: 80 });
  assert.equal(tenant.name, '测试新租户');
  assert.equal(tenant.status, 'active');
  assert.equal(tenant.licenseUsed, 0);
  assert.equal(tenant.licenseTotal, 80);
});

test('tenantStore: updateTenant 改名冲突返回 name_conflict', () => {
  store.reset();
  const { error } = store.updateTenant('tenant_001', { name: '西部高原牧场' });
  assert.equal(error, 'name_conflict');
});

test('tenantStore: updateTenant 改名成功', () => {
  store.reset();
  const { tenant } = store.updateTenant('tenant_001', { name: '华东示范牧场（改）' });
  assert.equal(tenant.name, '华东示范牧场（改）');
});

test('tenantStore: adjustLicense 小于已用量返回 license_below_used', () => {
  store.reset();
  const { error } = store.adjustLicense('tenant_003', 100);
  assert.equal(error, 'license_below_used');
});

test('tenantStore: adjustLicense 正确更新', () => {
  store.reset();
  const { tenant } = store.adjustLicense('tenant_003', 300);
  assert.equal(tenant.licenseTotal, 300);
});

test('tenantStore: toggleStatus 非法值返回 status_invalid', () => {
  store.reset();
  const { error } = store.toggleStatus('tenant_001', 'paused');
  assert.equal(error, 'status_invalid');
});

test('tenantStore: removeTenant 不存在返回 not_found', () => {
  store.reset();
  const { error } = store.removeTenant('tenant_999');
  assert.equal(error, 'not_found');
});

test('tenantStore: removeTenant 成功', () => {
  store.reset();
  const { removed } = store.removeTenant('tenant_001');
  assert.equal(removed.id, 'tenant_001');
  assert.equal(store.findById('tenant_001'), undefined);
});

test('tenantStore: findByOwnerId returns farms owned by user', () => {
  store.reset();
  const ownerFarms = store.findByOwnerId('u_001');
  assert.ok(Array.isArray(ownerFarms), 'findByOwnerId should return an array');
  assert.equal(ownerFarms.length, 2, 'u_001 should own exactly 2 farms');
  assert.deepEqual(ownerFarms.map((f) => f.id), ['tenant_001', 'tenant_007']);
});

test('tenantStore: findByOwnerId with non-existent owner returns empty', () => {
  store.reset();
  const noFarms = store.findByOwnerId('nonexistent');
  assert.equal(noFarms.length, 0, 'non-existent owner should return empty array');
});

test('tenantStore: findByParentTenantId returns children', () => {
  store.reset();
  const children = store.findByParentTenantId('tenant_p001');
  assert.equal(children.length, 1, 'seed data has one child farm of tenant_p001');
  assert.equal(children[0].parentTenantId, 'tenant_p001');
});

test('tenantStore: createTenant with new fields', () => {
  store.reset();
  const result = store.createTenant({
    name: 'test_farm_fields',
    type: 'farm',
    billingModel: 'direct',
    entitlementTier: 'premium',
    ownerId: 'u_001',
  });
  assert.equal(result.error, undefined, 'create should succeed');
  const created = store.findById(result.tenant.id);
  assert.equal(created.type, 'farm');
  assert.equal(created.billingModel, 'direct');
  assert.equal(created.entitlementTier, 'premium');
  assert.equal(created.ownerId, 'u_001');
});

test('tenantStore: createTenant defaults for optional fields', () => {
  store.reset();
  const result2 = store.createTenant({ name: 'test_defaults' });
  assert.equal(result2.error, undefined);
  const created2 = store.findById(result2.tenant.id);
  assert.equal(created2.type, 'farm');
  assert.equal(created2.billingModel, 'direct');
  assert.equal(created2.entitlementTier, 'basic');
  assert.equal(created2.ownerId, null);
  assert.equal(created2.parentTenantId, null);
});

test('tenantStore: findByServiceKey returns undefined when no match', () => {
  store.reset();
  const result = store.findByServiceKey('some_hash');
  assert.equal(result, undefined);
});

test('tenantStore: findByApiKey returns undefined when no match', () => {
  store.reset();
  const result = store.findByApiKey('some_hash');
  assert.equal(result, undefined);
});

test('tenantStore: updateTenantField updates single field and returns tenant', () => {
  store.reset();
  const before = store.findById('tenant_001');
  const beforeUpdatedAt = before.updatedAt;
  const { tenant } = store.updateTenantField('tenant_001', 'deploymentType', 'cloud');
  assert.equal(tenant.deploymentType, 'cloud');
  assert.ok(tenant.updatedAt !== beforeUpdatedAt);
});

test('tenantStore: updateTenantField returns error for unknown id', () => {
  store.reset();
  const { error } = store.updateTenantField('tenant_999', 'deploymentType', 'cloud');
  assert.equal(error, 'not_found');
});

test('tenantStore: updateTenantField rejects field not in SYNCABLE_FIELDS allowlist', () => {
  store.reset();
  const { error } = store.updateTenantField('tenant_001', 'name', '新名称');
  assert.equal(error, 'field_not_allowed');
});

test('tenantStore: findByServiceKey returns tenant matching key hash', () => {
  store.reset();
  // Set a serviceKey on an existing tenant and find it
  store.updateTenantField('tenant_001', 'serviceKey', 'svc-hash-abc123');
  const found = store.findByServiceKey('svc-hash-abc123');
  assert.equal(found.id, 'tenant_001');
  assert.equal(found.serviceKey, 'svc-hash-abc123');
  // findByApiKey: set an apiKey and find it
  store.updateTenantField('tenant_002', 'apiKey', 'api-hash-xyz789');
  const apiFound = store.findByApiKey('api-hash-xyz789');
  assert.equal(apiFound.id, 'tenant_002');
  assert.equal(apiFound.apiKey, 'api-hash-xyz789');
  // Verify no false positive: empty search returns undefined (no match)
  assert.equal(store.findByServiceKey('nonexistent'), undefined);
  assert.equal(store.findByApiKey('nonexistent'), undefined);
});

test('tenantStore: updateTenantField accepts all SYNCABLE_FIELDS values', () => {
  store.reset();
  const testValues = {
    contractId: 'contract_test_001',
    revenueShareRatio: 0.25,
    deploymentType: 'cloud',
    serviceKey: 'svc-test-fields',
    heartbeatAt: '2026-05-02T12:00:00+08:00',
    apiTier: 'growth',
    apiKey: 'api-test-fields',
    apiCallQuota: 20000,
    accessibleFarmTenantIds: ['tenant_003', 'tenant_004'],
    deviceConfigRatio: { gpsRatio: 0.5, capsuleRatio: 0.5 },
    livestockCount: 300,
  };
  const fields = Object.keys(testValues);
  for (const field of fields) {
    const { error, tenant } = store.updateTenantField('tenant_001', field, testValues[field]);
    assert.equal(error, undefined, `${field} should be accepted`);
    assert.deepEqual(tenant[field], testValues[field], `${field} value should match`);
  }
});

test('tenantStore: createTenant accepts Phase 2 fields', () => {
  store.reset();
  const result = store.createTenant({
    name: 'Phase2测试租户',
    type: 'partner',
    billingModel: 'revenue_share',
    entitlementTier: 'premium',
    ownerId: 'u_001',
    contractId: 'contract_002',
    revenueShareRatio: 0.2,
    deploymentType: 'hybrid',
    serviceKey: 'test-svc-key',
    heartbeatAt: '2026-05-02T00:00:00+08:00',
    apiTier: 'enterprise',
    apiKey: 'test-api-key',
    apiCallQuota: 50000,
    accessibleFarmTenantIds: ['tenant_001', 'tenant_002'],
    deviceConfigRatio: { gpsRatio: 0.9, capsuleRatio: 0.1 },
    livestockCount: 500,
  });
  assert.equal(result.error, undefined);
  const created = store.findById(result.tenant.id);
  assert.equal(created.name, 'Phase2测试租户');
  assert.equal(created.type, 'partner');
  assert.equal(created.billingModel, 'revenue_share');
  assert.equal(created.entitlementTier, 'premium');
  assert.equal(created.ownerId, 'u_001');
  assert.equal(created.contractId, 'contract_002');
  assert.equal(created.revenueShareRatio, 0.2);
  assert.equal(created.deploymentType, 'hybrid');
  assert.equal(created.serviceKey, 'test-svc-key');
  assert.equal(created.heartbeatAt, '2026-05-02T00:00:00+08:00');
  assert.equal(created.apiTier, 'enterprise');
  assert.equal(created.apiKey, 'test-api-key');
  assert.equal(created.apiCallQuota, 50000);
  assert.deepEqual(created.accessibleFarmTenantIds, ['tenant_001', 'tenant_002']);
  assert.deepEqual(created.deviceConfigRatio, { gpsRatio: 0.9, capsuleRatio: 0.1 });
  assert.equal(created.livestockCount, 500);
});

test('tenantStore: seed includes tenant_a002 (api free trial)', () => {
  store.reset();
  const t = store.findById('tenant_a002');
  assert.ok(t, 'tenant_a002 should exist in seed');
  assert.equal(t.type, 'api');
  assert.equal(t.apiTier, 'free');
  assert.equal(t.apiCallQuota, 1000);
  assert.deepEqual(t.accessibleFarmTenantIds, ['tenant_001']);
});

test('tenantStore: seed includes tenant_008 (enterprise farm with API)', () => {
  store.reset();
  const t = store.findById('tenant_008');
  assert.ok(t, 'tenant_008 should exist in seed');
  assert.equal(t.type, 'farm');
  assert.equal(t.entitlementTier, 'enterprise');
  assert.equal(t.apiTier, 'free');
  assert.equal(t.apiCallQuota, 1000);
  assert.deepEqual(t.accessibleFarmTenantIds, ['tenant_008']);
});
