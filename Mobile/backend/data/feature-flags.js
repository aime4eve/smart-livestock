// Feature Flag 定义 Map 与 shaping rules 引擎
// 基于 unified-business-model spec，实现 tier-based access control

const ALL_TIERS = ['basic', 'standard', 'premium', 'enterprise'];
const TIER_LEVEL = { basic: 0, standard: 1, premium: 2, enterprise: 3 };

// Feature Flag 定义 Map
// shape: 'none' (all tiers pass), 'lock' (deny below tier), 'limit' (truncate array), 'filter' (date filter)
// requiredDevices: ['gps'] | ['capsule'] | ['gps','capsule'] — used by route handlers, not shaping middleware
const FEATURE_FLAGS = {
  // location 分类
  gps_location:              { tiers: ALL_TIERS, shape: 'none' },
  fence:                     { tiers: ALL_TIERS, shape: 'limit', limit: 3,   requiredDevices: ['gps'] },
  trajectory:                { tiers: ['standard','premium','enterprise'], shape: 'lock', requiredDevices: ['gps'] },

  // health 分类
  temperature_monitor:       { tiers: ALL_TIERS, shape: 'none',  requiredDevices: ['capsule'] },
  peristaltic_monitor:       { tiers: ALL_TIERS, shape: 'none',  requiredDevices: ['capsule'] },
  health_score:              { tiers: ['premium','enterprise'], shape: 'lock',  requiredDevices: ['gps','capsule'] },
  estrus_detect:             { tiers: ['premium','enterprise'], shape: 'lock',  requiredDevices: ['gps','capsule'] },
  epidemic_alert:            { tiers: ['premium','enterprise'], shape: 'lock',  requiredDevices: ['gps','capsule'] },

  // analytics 分类
  gait_analysis:             { tiers: ['enterprise'], shape: 'lock' },
  behavior_stats:            { tiers: ['enterprise'], shape: 'lock' },
  api_access:                { tiers: ['enterprise'], shape: 'lock' },
  stats:                     { tiers: ALL_TIERS, shape: 'none' },
  dashboard_summary:         { tiers: ALL_TIERS, shape: 'limit', limit: 4 },

  // service 分类
  data_retention_days:       { tiers: { basic: 7, standard: 30, premium: 365, enterprise: Infinity }, shape: 'filter' },
  alert_history:             { tiers: ['standard','premium','enterprise'], shape: 'lock' },
  dedicated_support:         { tiers: ['premium','enterprise'], shape: 'lock' },

  // management 分类
  device_management:         { tiers: ALL_TIERS, shape: 'none' },
  livestock_detail:          { tiers: ALL_TIERS, shape: 'none' },
  profile:                   { tiers: ALL_TIERS, shape: 'none' },
  tenant_admin:              { tiers: ALL_TIERS, shape: 'none' },
};

// Check if tier has access to feature
function checkTierAccess(tier, tiersConfig) {
  if (Array.isArray(tiersConfig)) {
    return tiersConfig.includes(tier);
  }
  // tiersConfig is an object like { basic: 7, standard: 30, ... }
  return tier in tiersConfig;
}

// Get minimum tier required for a feature
function getMinTierForFeature(tiersConfig) {
  if (Array.isArray(tiersConfig)) {
    return tiersConfig[0] || null;
  }
  return Object.keys(tiersConfig)[0] || null;
}

// Get effective data retention days for a tier
function getEffectiveDataRetention(tier) {
  const flag = FEATURE_FLAGS['data_retention_days'];
  return flag.tiers[tier] ?? 7;
}

// Filter data by retention days. The featureKey context determines which date field to use.
// Mapping: alerts → occurredAt, trajectories → recordedAt, twin/sensor → timestamp
function applyFilter(data, retentionDays) {
  if (!data || !data.items || !Array.isArray(data.items)) return data;
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - retentionDays);

  const filtered = data.items.filter(item => {
    const dateStr = item.occurredAt || item.recordedAt || item.timestamp;
    if (!dateStr) return true; // keep items without date fields
    return new Date(dateStr) >= cutoff;
  });

  return { ...data, items: filtered, total: filtered.length, filteredTotal: data.items.length };
}

// Apply limit to array data
function applyLimit(data, limit) {
  if (!data || !data.items || !Array.isArray(data.items)) return data;
  if (data.items.length <= limit) return data;
  return {
    ...data,
    items: data.items.slice(0, limit),
    limitExceeded: true,
    limitValue: limit,
    totalBeforeLimit: data.items.length,
    total: limit,
  };
}

// Main shaping pipeline
// - 'lock': deny feature if tier lacks access → set locked+upgradeTier
// - 'limit': always truncate array to cap, regardless of tier access
// - 'filter': always apply retention-based date filtering, each tier has its own window
// - 'none': no action needed
function applyShapingRules(data, tier, featureKeys) {
  if (!featureKeys || featureKeys.length === 0) return data;

  let result = { ...data };
  for (const key of featureKeys) {
    const flag = FEATURE_FLAGS[key];
    if (!flag) continue;

    if (flag.shape === 'lock') {
      const hasAccess = checkTierAccess(tier, flag.tiers);
      if (!hasAccess) {
        result = { ...result, locked: true, upgradeTier: getMinTierForFeature(flag.tiers) };
      }
    } else if (flag.shape === 'filter') {
      result = applyFilter(result, getEffectiveDataRetention(tier));
    } else if (flag.shape === 'limit') {
      result = applyLimit(result, flag.limit);
    }
    // shape === 'none' → no action needed
  }
  return result;
}

module.exports = {
  FEATURE_FLAGS,
  ALL_TIERS,
  TIER_LEVEL,
  applyShapingRules,
  checkTierAccess,
  getMinTierForFeature,
};
