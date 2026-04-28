// backend/data/subscriptions.js

let subscriptions = [];
let idempotencyKeys = new Map();  // key → { createdAt, result }

const TIER_PRICES = { basic: 0, standard: 299, premium: 699, enterprise: null };
const DEVICE_PRICES = { gps: 15, capsule: 30 };  // 元/牛/月
const TRIAL_DAYS = 14;
const PER_UNIT_PRICE = 2;  // 超出每头 ¥2/月
const TIER_LIMITS = { basic: 50, standard: 200, premium: 1000, enterprise: Infinity };

function reset() {
  subscriptions = [];
  idempotencyKeys = new Map();
}

function createTrial(tenantId) {
  const existing = subscriptions.find(s => s.tenantId === tenantId);
  if (existing) return { error: 'already_exists', subscription: existing };

  const now = new Date();
  const trialEnd = new Date(now);
  trialEnd.setDate(trialEnd.getDate() + TRIAL_DAYS);

  const sub = {
    id: `sub_${String(subscriptions.length + 1).padStart(3, '0')}`,
    tenantId,
    tier: 'premium',          // 试用高级版
    status: 'trial',
    trialEndsAt: trialEnd.toISOString(),
    currentPeriodStart: now.toISOString(),
    currentPeriodEnd: trialEnd.toISOString(),
    livestockCount: 50,       // 假设牧场有50头牛
    calculatedDeviceFee: 2250, // 50 × (15+30) = 2250元
    calculatedTierFee: 0,     // 试用期免费
    calculatedTotal: 2250,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  };
  subscriptions.push(sub);

  // 同步 tenant.entitlementTier
  try {
    const tenantStore = require('./tenantStore');
    const tenant = tenantStore.findById(tenantId);
    if (tenant) tenant.entitlementTier = sub.tier;
  } catch (_) { /* tenantStore not needed if not available */ }

  return { subscription: sub };
}

function getByTenantId(tenantId) {
  return subscriptions.find(s => s.tenantId === tenantId) ?? null;
}

function getAll() {
  return subscriptions;
}

function checkout(tenantId, tier, livestockCount, idempotencyKey) {
  // 幂等性检查（5分钟TTL）
  if (idempotencyKey) {
    const cached = idempotencyKeys.get(idempotencyKey);
    if (cached && (Date.now() - cached.createdAt) < 300000) return cached.result;
  }

  const sub = getByTenantId(tenantId);
  if (!sub) return { error: 'no_subscription' };
  if (!['basic','standard','premium'].includes(tier)) return { error: 'invalid_tier' };

  // 计算费用
  const tierPrice = TIER_PRICES[tier];
  const deviceFee = livestockCount * (DEVICE_PRICES.gps + DEVICE_PRICES.capsule);
  let tierFee = tierPrice;
  const limit = TIER_LIMITS[tier] || 0;
  if (livestockCount > limit) {
    tierFee += (livestockCount - limit) * PER_UNIT_PRICE;
  }
  const total = deviceFee + tierFee;

  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setMonth(periodEnd.getMonth() + 1);

  sub.tier = tier;
  sub.status = 'active';
  sub.trialEndsAt = null;
  sub.currentPeriodStart = now.toISOString();
  sub.currentPeriodEnd = periodEnd.toISOString();
  sub.livestockCount = livestockCount;
  sub.calculatedDeviceFee = deviceFee;
  sub.calculatedTierFee = tierFee;
  sub.calculatedTotal = total;
  sub.updatedAt = now.toISOString();

  // 同步 tenant.entitlementTier
  try {
    const tenantStore = require('./tenantStore');
    const tenant = tenantStore.findById(tenantId);
    if (tenant) tenant.entitlementTier = tier;
  } catch (_) { /* tenantStore not needed if not available */ }

  const result = { subscription: { ...sub } };
  if (idempotencyKey) idempotencyKeys.set(idempotencyKey, { createdAt: Date.now(), result });
  return result;
}

function cancel(tenantId) {
  const sub = getByTenantId(tenantId);
  if (!sub) return { error: 'no_subscription' };
  sub.status = 'cancelled';
  sub.updatedAt = new Date().toISOString();
  return { subscription: sub };
}

function renew(tenantId, livestockCount, idempotencyKey) {
  if (idempotencyKey) {
    const cached = idempotencyKeys.get(idempotencyKey);
    if (cached && (Date.now() - cached.createdAt) < 300000) return cached.result;
  }

  const sub = getByTenantId(tenantId);
  if (!sub) return { error: 'no_subscription' };
  if (sub.status !== 'active') return { error: 'not_active' };

  const tier = sub.tier;
  const tierPrice = TIER_PRICES[tier] || 0;
  const deviceFee = livestockCount * (DEVICE_PRICES.gps + DEVICE_PRICES.capsule);
  let tierFee = tierPrice;
  const limit = TIER_LIMITS[tier] || 0;
  if (livestockCount > limit) {
    tierFee += (livestockCount - limit) * PER_UNIT_PRICE;
  }
  const total = deviceFee + tierFee;

  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setMonth(periodEnd.getMonth() + 1);

  sub.currentPeriodStart = now.toISOString();
  sub.currentPeriodEnd = periodEnd.toISOString();
  sub.livestockCount = livestockCount;
  sub.calculatedDeviceFee = deviceFee;
  sub.calculatedTierFee = tierFee;
  sub.calculatedTotal = total;
  sub.updatedAt = now.toISOString();

  const result = { subscription: { ...sub } };
  if (idempotencyKey) idempotencyKeys.set(idempotencyKey, { createdAt: Date.now(), result });
  return result;
}

module.exports = {
  createTrial,
  getByTenantId,
  getAll,
  checkout,
  cancel,
  renew,
  reset,
  TIER_PRICES,
  DEVICE_PRICES,
  PER_UNIT_PRICE,
  TIER_LIMITS,
  TRIAL_DAYS,
};
