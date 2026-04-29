const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  FEATURE_FLAGS, ALL_TIERS, TIER_LEVEL, applyShapingRules, checkTierAccess,
} = require('../data/feature-flags');

const FEATURE_COUNT = 20;

test('feature-flags: exactly 20 feature keys defined', () => {
  assert.equal(Object.keys(FEATURE_FLAGS).length, FEATURE_COUNT);
});

test('feature-flags: location category keys present', () => {
  assert.ok('gps_location' in FEATURE_FLAGS);
  assert.ok('fence' in FEATURE_FLAGS);
  assert.ok('trajectory' in FEATURE_FLAGS);
});

test('feature-flags: health category keys present', () => {
  assert.ok('temperature_monitor' in FEATURE_FLAGS);
  assert.ok('peristaltic_monitor' in FEATURE_FLAGS);
  assert.ok('health_score' in FEATURE_FLAGS);
  assert.ok('estrus_detect' in FEATURE_FLAGS);
  assert.ok('epidemic_alert' in FEATURE_FLAGS);
});

test('feature-flags: analytics category keys present', () => {
  assert.ok('gait_analysis' in FEATURE_FLAGS);
  assert.ok('behavior_stats' in FEATURE_FLAGS);
  assert.ok('api_access' in FEATURE_FLAGS);
  assert.ok('stats' in FEATURE_FLAGS);
  assert.ok('dashboard_summary' in FEATURE_FLAGS);
});

test('feature-flags: service category keys present', () => {
  assert.ok('data_retention_days' in FEATURE_FLAGS);
  assert.ok('alert_history' in FEATURE_FLAGS);
  assert.ok('dedicated_support' in FEATURE_FLAGS);
});

test('feature-flags: management category keys present', () => {
  assert.ok('device_management' in FEATURE_FLAGS);
  assert.ok('livestock_detail' in FEATURE_FLAGS);
  assert.ok('profile' in FEATURE_FLAGS);
  assert.ok('tenant_admin' in FEATURE_FLAGS);
});

test('feature-flags: 7 keys have requiredDevices', () => {
  const withDevices = Object.entries(FEATURE_FLAGS)
    .filter(([, flag]) => flag.requiredDevices && flag.requiredDevices.length > 0);
  assert.equal(withDevices.length, 7, '7 feature keys require devices');

  const fence = FEATURE_FLAGS['fence'];
  assert.ok(fence.requiredDevices.includes('gps'));

  const trajectory = FEATURE_FLAGS['trajectory'];
  assert.ok(trajectory.requiredDevices.includes('gps'));

  const temp = FEATURE_FLAGS['temperature_monitor'];
  assert.ok(temp.requiredDevices.includes('capsule'));

  const peri = FEATURE_FLAGS['peristaltic_monitor'];
  assert.ok(peri.requiredDevices.includes('capsule'));

  const health = FEATURE_FLAGS['health_score'];
  assert.ok(health.requiredDevices.includes('gps'));
  assert.ok(health.requiredDevices.includes('capsule'));
});

test('feature-flags: TIER_LEVEL has ascending values', () => {
  assert.ok(TIER_LEVEL.basic < TIER_LEVEL.standard);
  assert.ok(TIER_LEVEL.standard < TIER_LEVEL.premium);
  assert.ok(TIER_LEVEL.premium < TIER_LEVEL.enterprise);
});

test('feature-flags: ALL_TIERS contains 4 tiers', () => {
  assert.equal(ALL_TIERS.length, 4);
  assert.ok(ALL_TIERS.includes('basic'));
  assert.ok(ALL_TIERS.includes('standard'));
  assert.ok(ALL_TIERS.includes('premium'));
  assert.ok(ALL_TIERS.includes('enterprise'));
});

test('feature-flags: checkTierAccess with array tiersConfig', () => {
  assert.equal(checkTierAccess('basic', ['basic', 'standard']), true);
  assert.equal(checkTierAccess('standard', ['basic', 'standard']), true);
  assert.equal(checkTierAccess('premium', ['basic', 'standard']), false);
});

test('feature-flags: checkTierAccess with object tiersConfig', () => {
  assert.equal(checkTierAccess('basic', { basic: 7, standard: 30 }), true);
  assert.equal(checkTierAccess('premium', { basic: 7, standard: 30 }), false);
});

test('feature-flags: applyShapingRules no featureKeys returns data unchanged', () => {
  const data = { items: [{ id: 1 }], total: 1 };
  const result = applyShapingRules(data, 'basic', []);
  assert.deepEqual(result, data);
});

test('feature-flags: applyShapingRules lock shape blocks below-tier access', () => {
  const data = { items: [{ id: 1 }] };
  const result = applyShapingRules(data, 'basic', ['health_score']);
  assert.equal(result.locked, true);
  assert.equal(result.upgradeTier, 'premium');
});

test('feature-flags: applyShapingRules lock shape passes for adequate tier', () => {
  const data = { items: [{ id: 1 }] };
  const result = applyShapingRules(data, 'premium', ['health_score']);
  assert.equal(result.locked, undefined);
});

test('feature-flags: applyShapingRules limit shape truncates items at min tier', () => {
  const data = { items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], total: 5 };
  const result = applyShapingRules(data, 'basic', ['fence']);
  assert.equal(result.items.length, 3);
  assert.equal(result.limitExceeded, true);
  assert.equal(result.limitValue, 3);
  assert.equal(result.totalBeforeLimit, 5);
});

test('feature-flags: applyShapingRules limit shape does NOT truncate for higher tiers', () => {
  const data = { items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], total: 5 };
  const result = applyShapingRules(data, 'standard', ['fence']);
  assert.equal(result.items.length, 5);
  assert.equal(result.limitExceeded, undefined);
});

test('feature-flags: applyShapingRules filter shape filters by retention days', () => {
  const now = new Date();
  const recent = new Date(now);
  recent.setDate(recent.getDate() - 3);
  const old = new Date(now);
  old.setDate(old.getDate() - 30);

  const data = {
    items: [
      { id: 1, occurredAt: recent.toISOString() },
      { id: 2, occurredAt: old.toISOString() },
    ],
    total: 2,
  };
  const result = applyShapingRules(data, 'basic', ['data_retention_days']);
  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].id, 1);
  assert.equal(result.filteredTotal, 2);
});

test('feature-flags: applyShapingRules multi-key pipeline chains correctly', () => {
  const data = { items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }], total: 5 };
  const result = applyShapingRules(data, 'basic', ['fence', 'health_score']);
  assert.equal(result.locked, true);
  assert.equal(result.limitExceeded, true);
});

test('feature-flags: applyShapingRules unknown featureKey is skipped', () => {
  const data = { items: [{ id: 1 }] };
  const result = applyShapingRules(data, 'basic', ['nonexistent_feature']);
  assert.deepEqual(result, data);
});

test('feature-flags: applyShapingRules none shape does nothing', () => {
  const data = { items: [{ id: 1 }], total: 1 };
  const result = applyShapingRules(data, 'basic', ['gps_location']);
  assert.deepEqual(result, data);
});

test('feature-flags: applyShapingRules dashboard_summary limit=4', () => {
  const data = { items: [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }, { id: 6 }], total: 6 };
  const result = applyShapingRules(data, 'basic', ['dashboard_summary']);
  assert.equal(result.items.length, 4);
  assert.equal(result.limitExceeded, true);
  assert.equal(result.limitValue, 4);
});

test('feature-flags: enterprise tier has access to all lock features', () => {
  const lockFeatures = Object.entries(FEATURE_FLAGS)
    .filter(([, f]) => f.shape === 'lock');
  for (const [key] of lockFeatures) {
    const data = { items: [{ id: 1 }] };
    const result = applyShapingRules(data, 'enterprise', [key]);
    assert.equal(result.locked, undefined, `enterprise should access ${key}`);
  }
});
