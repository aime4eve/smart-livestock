// backend/data/apiTierStore.js
// API tier & usage tracking for api tenants

const _initialTiers = [
  {
    apiTenantId: 'tenant_a001',
    tier: 'growth',
    monthlyQuota: 10000,
    usedThisMonth: 0,
    overageUnitPrice: 0.01,
    resetAt: null,
  },
];

let _tiers = _initialTiers.map((t) => ({ ...t }));

function _now() {
  return new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

function reset() {
  _tiers = _initialTiers.map((t) => ({ ...t }));
}

/**
 * Get tier info for an api tenant.
 * Returns tier object or null if not found.
 */
function getByTenantId(apiTenantId) {
  return _tiers.find((t) => t.apiTenantId === apiTenantId) ?? null;
}

/**
 * Increment usage count for an api tenant.
 * Returns updated record, or null if tenant not found.
 */
function incrementUsage(apiTenantId, count) {
  const tier = _tiers.find((t) => t.apiTenantId === apiTenantId);
  if (!tier) return null;

  tier.usedThisMonth += count;
  return { ...tier };
}

/**
 * Check quota for an api tenant.
 * Returns { total, used, remaining } or null if tenant not found.
 */
function checkQuota(apiTenantId) {
  const tier = _tiers.find((t) => t.apiTenantId === apiTenantId);
  if (!tier) return null;

  return {
    total: tier.monthlyQuota,
    used: tier.usedThisMonth,
    remaining: Math.max(0, tier.monthlyQuota - tier.usedThisMonth),
  };
}

/**
 * Reset monthly usage for all api tenants.
 * Returns count of reset records.
 */
function resetMonthlyUsage() {
  const now = _now();
  let count = 0;
  _tiers.forEach((t) => {
    t.usedThisMonth = 0;
    t.resetAt = now;
    count++;
  });
  return count;
}

module.exports = {
  getByTenantId,
  incrementUsage,
  checkQuota,
  resetMonthlyUsage,
  reset,
};
