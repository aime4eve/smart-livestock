// backend/services/tierService.js
const tenantStore = require('../data/tenantStore');

function getEffectiveTier(farmTenantId) {
  const farm = tenantStore.findById(farmTenantId);
  if (!farm) return 'basic';

  const now = new Date();

  // direct farm：需检查 subscription 状态
  if (!farm.parentTenantId) {
    const subscriptionStore = require('../data/subscriptions');
    const sub = subscriptionStore.getByTenantId(farmTenantId);
    // null-sub defense: 无 subscription 记录时降级 basic
    if (!sub) return 'basic';
    // 已过期
    if (sub.status === 'expired') return 'basic';
    // 已取消且当前周期结束
    if (sub.status === 'cancelled' && now > new Date(sub.currentPeriodEnd)) return 'basic';
    // 试用期结束
    if (sub.status === 'trial' && now > new Date(sub.trialEndsAt)) return 'basic';
  }

  // farm 自有值优先
  if (farm.entitlementTier) return farm.entitlementTier;

  // 查 parent partner
  if (farm.parentTenantId) {
    const parent = tenantStore.findById(farm.parentTenantId);
    return parent?.entitlementTier ?? 'basic';
  }

  return 'basic';
}

module.exports = { getEffectiveTier };
