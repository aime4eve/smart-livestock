const assert = require('node:assert/strict');
const { test } = require('node:test');
const store = require('../data/tenantStore');

test('tenantStore: sliceForPage 默认分页返回全部', () => {
  store.reset();
  const res = store.sliceForPage({});
  assert.equal(res.page, 1);
  assert.equal(res.pageSize, 20);
  assert.equal(res.total, 9);
  assert.equal(res.items.length, 9);
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
  assert.equal(children.length, 0, 'seed data has no child farms of tenant_p001');
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
