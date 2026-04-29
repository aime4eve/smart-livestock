const { Router } = require('express');
const subscriptionStore = require('../data/subscriptions');
const { FEATURE_FLAGS } = require('../data/feature-flags');
const { getEffectiveTier } = require('../services/tierService');
const tenantStore = require('../data/tenantStore');

const router = Router();

// GET /subscription/current — return current subscription state
router.get('/current', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  if (!farmTenantId) return res.fail(400, 'BAD_REQUEST', '仅 farm 租户可查看订阅');

  const sub = subscriptionStore.getByTenantId(farmTenantId);
  if (!sub) return res.fail(404, 'RESOURCE_NOT_FOUND', '无订阅记录');

  res.ok(sub);
});

// GET /subscription/features — return Feature Flag list with current tier access state
router.get('/features', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  const tier = farmTenantId ? getEffectiveTier(farmTenantId) : 'basic';

  const features = Object.entries(FEATURE_FLAGS).map(([key, flag]) => ({
    key,
    tiers: Array.isArray(flag.tiers) ? flag.tiers : Object.keys(flag.tiers),
    shape: flag.shape,
    limit: flag.limit ?? null,
    requiredDevices: flag.requiredDevices ?? null,
    accessible: Array.isArray(flag.tiers) ? flag.tiers.includes(tier) : (tier in flag.tiers),
  }));

  res.ok({ tier, features });
});

// GET /subscription/plans — return plan list with prices
router.get('/plans', (req, res) => {
  const plans = [
    {
      id: 'basic', name: '基础版', monthlyPrice: 0, livestockLimit: 50,
      perUnitPrice: 0, trial: false,
      description: '基础牲畜管理功能',
    },
    {
      id: 'standard', name: '标准版', monthlyPrice: 299, livestockLimit: 200,
      perUnitPrice: 2, trial: false,
      description: '含历史轨迹和告警历史',
    },
    {
      id: 'premium', name: '高级版', monthlyPrice: 699, livestockLimit: 1000,
      perUnitPrice: 2, trial: true,
      description: '含健康评分、发情检测、疫病预警',
    },
    {
      id: 'enterprise', name: '企业版', monthlyPrice: null, livestockLimit: null,
      perUnitPrice: null, trial: false,
      description: '定制方案，联系销售',
      contactSales: true,
    },
  ];

  res.ok({ plans, devicePrices: { gps: 15, capsule: 30 } });
});

// POST /subscription/checkout — purchase/upgrade (idempotency key)
router.post('/checkout', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  if (!farmTenantId) return res.fail(400, 'BAD_REQUEST', '仅 farm 租户可操作');

  const { tier, livestockCount, idempotencyKey } = req.body || {};
  if (!tier || !['basic','standard','premium'].includes(tier)) {
    return res.fail(422, 'VALIDATION_ERROR', 'tier 必须为 basic/standard/premium');
  }
  if (typeof livestockCount !== 'number' || livestockCount < 0) {
    return res.fail(422, 'VALIDATION_ERROR', 'livestockCount 必须为非负整数');
  }

  const result = subscriptionStore.checkout(farmTenantId, tier, livestockCount, idempotencyKey);
  if (result.error === 'no_subscription') return res.fail(404, 'RESOURCE_NOT_FOUND', '无订阅记录，请先创建试用');
  if (result.error === 'invalid_tier') return res.fail(422, 'VALIDATION_ERROR', '无效的 tier');

  res.ok(result.subscription);
});

// POST /subscription/cancel — cancel subscription
router.post('/cancel', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  if (!farmTenantId) return res.fail(400, 'BAD_REQUEST', '仅 farm 租户可操作');

  const result = subscriptionStore.cancel(farmTenantId);
  if (result.error === 'no_subscription') return res.fail(404, 'RESOURCE_NOT_FOUND', '无订阅记录');

  res.ok(result.subscription);
});

// POST /subscription/renew — renew subscription
router.post('/renew', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  if (!farmTenantId) return res.fail(400, 'BAD_REQUEST', '仅 farm 租户可操作');

  const { livestockCount, idempotencyKey } = req.body || {};
  if (typeof livestockCount !== 'number' || livestockCount < 0) {
    return res.fail(422, 'VALIDATION_ERROR', 'livestockCount 必须为非负整数');
  }

  const result = subscriptionStore.renew(farmTenantId, livestockCount, idempotencyKey);
  if (result.error === 'no_subscription') return res.fail(404, 'RESOURCE_NOT_FOUND', '无订阅记录');
  if (result.error === 'not_active') return res.fail(400, 'BAD_REQUEST', '仅 active 状态可续费');

  res.ok(result.subscription);
});

// GET /subscription/usage — usage statistics
router.get('/usage', (req, res) => {
  const farmTenantId = req.activeFarmTenantId;
  if (!farmTenantId) return res.fail(400, 'BAD_REQUEST', '仅 farm 租户可查看');

  const sub = subscriptionStore.getByTenantId(farmTenantId);
  const tier = getEffectiveTier(farmTenantId);
  const tierInfo = {
    basic: { limit: 50 }, standard: { limit: 200 }, premium: { limit: 1000 }, enterprise: { limit: Infinity }
  }[tier] || { limit: 50 };

  res.ok({
    livestockCount: sub?.livestockCount ?? 0,
    livestockLimit: tierInfo.limit,
    deviceCount: 0,
    daysUntilExpiry: sub ? Math.ceil((new Date(sub.currentPeriodEnd) - new Date()) / 86400000) : 0,
    status: sub?.status ?? 'none',
  });
});

module.exports = router;
