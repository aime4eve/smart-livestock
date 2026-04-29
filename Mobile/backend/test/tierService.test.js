const assert = require('node:assert/strict');
const { test } = require('node:test');
const { getEffectiveTier } = require('../services/tierService');
const tenantStore = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');

function setupFarm(overrides = {}) {
  return tenantStore.createTenant({
    name: `test_farm_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    ...overrides,
  }).tenant;
}

function setupSubscription(tenantId, overrides = {}) {
  subscriptionStore.reset();
  const result = subscriptionStore.createTrial(tenantId);
  const sub = result.subscription;
  Object.assign(sub, overrides);
  return sub;
}

test('tierService: direct farm with active subscription returns farm entitlementTier', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  setupSubscription(farm.id, { status: 'active' });
  assert.equal(getEffectiveTier(farm.id), 'premium');
});

test('tierService: direct farm with expired subscription returns basic', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  setupSubscription(farm.id, { status: 'expired' });
  assert.equal(getEffectiveTier(farm.id), 'basic');
});

test('tierService: direct farm with cancelled subscription past period end returns basic', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  const past = new Date();
  past.setDate(past.getDate() - 10);
  setupSubscription(farm.id, { status: 'cancelled', currentPeriodEnd: past.toISOString() });
  assert.equal(getEffectiveTier(farm.id), 'basic');
});

test('tierService: direct farm with cancelled subscription but period not ended keeps tier', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  const future = new Date();
  future.setDate(future.getDate() + 10);
  setupSubscription(farm.id, { status: 'cancelled', currentPeriodEnd: future.toISOString() });
  assert.equal(getEffectiveTier(farm.id), 'premium');
});

test('tierService: direct farm with trial expired returns basic', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  const past = new Date();
  past.setDate(past.getDate() - 1);
  setupSubscription(farm.id, { status: 'trial', trialEndsAt: past.toISOString() });
  assert.equal(getEffectiveTier(farm.id), 'basic');
});

test('tierService: direct farm with trial still active keeps tier', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  const future = new Date();
  future.setDate(future.getDate() + 7);
  setupSubscription(farm.id, { status: 'trial', trialEndsAt: future.toISOString() });
  assert.equal(getEffectiveTier(farm.id), 'premium');
});

test('tierService: direct farm without subscription record returns basic (null-sub defense)', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_test' });
  assert.equal(getEffectiveTier(farm.id), 'basic');
});

test('tierService: farm under partner inherits parent entitlementTier', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const parent = tenantStore.createTenant({
    name: 'partner_test', type: 'partner', entitlementTier: 'standard',
  }).tenant;
  const farm = setupFarm({
    type: 'farm', parentTenantId: parent.id, entitlementTier: null, ownerId: null,
  });
  assert.equal(getEffectiveTier(farm.id), 'standard');
});

test('tierService: farm under partner with own entitlementTier uses own value', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const parent = tenantStore.createTenant({
    name: 'partner_test2', type: 'partner', entitlementTier: 'standard',
  }).tenant;
  const farm = setupFarm({
    type: 'farm', parentTenantId: parent.id, entitlementTier: 'premium', ownerId: null,
  });
  assert.equal(getEffectiveTier(farm.id), 'premium');
});

test('tierService: farm under partner with null tier and parent without tier returns basic', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const parent = tenantStore.createTenant({
    name: 'partner_no_tier', type: 'partner', entitlementTier: null,
  }).tenant;
  const farm = setupFarm({
    type: 'farm', parentTenantId: parent.id, entitlementTier: null, ownerId: null,
  });
  assert.equal(getEffectiveTier(farm.id), 'basic');
});

test('tierService: unknown farmTenantId returns basic', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  assert.equal(getEffectiveTier('nonexistent_id'), 'basic');
});

test('tierService: partner tenant without subscription returns basic (null-sub defense applies)', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const partner = tenantStore.createTenant({
    name: 'partner_direct', type: 'partner', entitlementTier: 'standard',
  }).tenant;
  // partner has no parentTenantId, so direct-farm null-sub defense kicks in
  // Since partner has no subscription record → returns basic
  assert.equal(getEffectiveTier(partner.id), 'basic');
});

test('tierService: farm under enterprise partner inherits enterprise tier', () => {
  tenantStore.reset();
  subscriptionStore.reset();
  const parent = tenantStore.createTenant({
    name: 'enterprise_partner', type: 'partner', entitlementTier: 'enterprise',
  }).tenant;
  const farm = setupFarm({
    type: 'farm', parentTenantId: parent.id, entitlementTier: null, ownerId: null,
  });
  assert.equal(getEffectiveTier(farm.id), 'enterprise');
});
