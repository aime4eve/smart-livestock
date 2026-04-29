// Integration tests: tier resolution + feature-flag shaping + middleware pipeline
// Exercises the full path: tenant setup → getEffectiveTier → applyShapingRules → shapingMiddleware

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { getEffectiveTier } = require('../services/tierService');
const { applyShapingRules } = require('../data/feature-flags');
const { shapingMiddleware } = require('../middleware/feature-flag');
const tenantStore = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function setupFarm(overrides = {}) {
  return tenantStore.createTenant({
    name: `int_test_farm_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
    ...overrides,
  }).tenant;
}

/**
 * Create a subscription for the given tenant.
 * createTrial() always sets tier='premium' and syncs tenant.entitlementTier to 'premium'.
 * For tests needing a different tier, pass { tier: 'basic' } etc. — this helper will
 * override both the subscription record AND the tenant's entitlementTier.
 */
function setupSubscription(tenantId, overrides = {}) {
  const result = subscriptionStore.createTrial(tenantId);
  const sub = result.subscription;
  Object.assign(sub, overrides);
  // createTrial syncs tenant.entitlementTier to 'premium'; re-sync if caller overrides tier
  if (overrides.tier) {
    const tenant = tenantStore.findById(tenantId);
    if (tenant) tenant.entitlementTier = overrides.tier;
  }
  return sub;
}

// ---------------------------------------------------------------------------
// 1. basic tier → fence limit applied
// ---------------------------------------------------------------------------

test('integration: basic tier → fence limit applied (items truncated to 3)', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const farm = setupFarm({ type: 'farm', entitlementTier: 'basic', ownerId: 'u_int' });
  setupSubscription(farm.id, { status: 'active', tier: 'basic' });

  // Verify tier resolution
  const tier = getEffectiveTier(farm.id);
  assert.equal(tier, 'basic');

  // Verify shaping: 5 fences → truncated to 3
  const data = {
    items: [{ id: 'f1' }, { id: 'f2' }, { id: 'f3' }, { id: 'f4' }, { id: 'f5' }],
    total: 5,
  };
  const shaped = applyShapingRules(data, tier, ['fence']);
  assert.equal(shaped.items.length, 3);
  assert.equal(shaped.limitExceeded, true);
  assert.equal(shaped.limitValue, 3);
  assert.equal(shaped.totalBeforeLimit, 5);
});

// ---------------------------------------------------------------------------
// 2. standard tier → alert history filter applied (30-day retention)
// ---------------------------------------------------------------------------

test('integration: standard tier → data_retention_days filters to 30 days', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const farm = setupFarm({ type: 'farm', entitlementTier: 'standard', ownerId: 'u_int' });
  setupSubscription(farm.id, { status: 'active', tier: 'standard' });

  const tier = getEffectiveTier(farm.id);
  assert.equal(tier, 'standard');

  const now = new Date();
  const recent = new Date(now); recent.setDate(recent.getDate() - 3);
  const old = new Date(now); old.setDate(old.getDate() - 60);

  const data = {
    items: [
      { id: 'a1', occurredAt: recent.toISOString() },
      { id: 'a2', occurredAt: old.toISOString() },
    ],
    total: 2,
  };
  const shaped = applyShapingRules(data, tier, ['data_retention_days']);
  assert.equal(shaped.items.length, 1);
  assert.equal(shaped.items[0].id, 'a1');
  assert.equal(shaped.filteredTotal, 2);
});

// ---------------------------------------------------------------------------
// 3. premium tier → estrus_detect unlocked
// ---------------------------------------------------------------------------

test('integration: premium tier → estrus_detect unlocked (no lock)', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const farm = setupFarm({ type: 'farm', entitlementTier: 'premium', ownerId: 'u_int' });
  setupSubscription(farm.id, { status: 'active' });

  const tier = getEffectiveTier(farm.id);
  assert.equal(tier, 'premium');

  const data = { items: [{ id: 'e1' }] };
  const shaped = applyShapingRules(data, tier, ['estrus_detect']);
  assert.equal(shaped.locked, undefined);
  assert.equal(shaped.items.length, 1);
});

// ---------------------------------------------------------------------------
// 4. basic tier → estrus_detect locked
// ---------------------------------------------------------------------------

test('integration: basic tier → estrus_detect locked (upgrade required)', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const farm = setupFarm({ type: 'farm', entitlementTier: 'basic', ownerId: 'u_int' });
  setupSubscription(farm.id, { status: 'active', tier: 'basic' });

  const tier = getEffectiveTier(farm.id);
  assert.equal(tier, 'basic');

  const data = { items: [{ id: 'e1' }] };
  const shaped = applyShapingRules(data, tier, ['estrus_detect']);
  assert.equal(shaped.locked, true);
  assert.equal(shaped.upgradeTier, 'premium');
});

// ---------------------------------------------------------------------------
// 5. enterprise tier → data retention unlimited (1095 days)
// ---------------------------------------------------------------------------

test('integration: enterprise tier → data retention is unlimited (1095 days coverage)', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const farm = setupFarm({ type: 'farm', entitlementTier: 'enterprise', ownerId: 'u_int' });
  setupSubscription(farm.id, { status: 'active', tier: 'enterprise' });

  const tier = getEffectiveTier(farm.id);
  assert.equal(tier, 'enterprise');

  // Enterprise retention is Infinity — the feature flag config confirms unlimited access
  const { FEATURE_FLAGS } = require('../data/feature-flags');
  assert.equal(FEATURE_FLAGS['data_retention_days'].tiers.enterprise, Infinity);

  // Verify that enterprise tier has no lock or limit applied to data_retention_days
  const data = { items: [{ id: 'd1' }], total: 1 };
  const shaped = applyShapingRules(data, tier, ['data_retention_days']);
  assert.equal(shaped.locked, undefined, 'enterprise should never be locked');
  assert.equal(shaped.limitExceeded, undefined, 'enterprise should never be limited');

  // Enterprise should have access to all locked features (comprehensive check)
  const lockFeatures = Object.entries(FEATURE_FLAGS)
    .filter(([, f]) => f.shape === 'lock');
  for (const [key] of lockFeatures) {
    const shapedLock = applyShapingRules({ items: [{ id: 1 }] }, tier, [key]);
    assert.equal(shapedLock.locked, undefined, `enterprise should access locked feature: ${key}`);
  }
});

// ---------------------------------------------------------------------------
// 6. Shaping middleware → no farmContext → skip shaping
// ---------------------------------------------------------------------------

test('integration: shapingMiddleware skips shaping when activeFarmTenantId is null', () => {
  tenantStore.reset();
  subscriptionStore.reset();

  const originalData = { items: [{ id: 'x1' }], total: 1 };

  const req = { activeFarmTenantId: null, routeFeatureKeys: ['fence'] };
  let captured = null;
  const res = {
    ok(data, message) {
      captured = { data, message };
    },
  };
  let nextCalled = false;
  const next = () => { nextCalled = true; };

  // Run the middleware
  shapingMiddleware(req, res, next);
  assert.equal(nextCalled, true, 'next() should be called');

  // Now call res.ok — shapingMiddleware should have patched it.
  // Since activeFarmTenantId is null, shaping is skipped and originalOk is used.
  res.ok(originalData);

  assert.deepEqual(captured.data, originalData, 'data should pass through unchanged');
});
