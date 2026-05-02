// Subscription Service Routes (E5.1)
// Phase 2b: licensed (on-premise) 合作伙伴订阅服务管理
// 所有 CRUD 端点均需 platform_admin 角色，heartbeat 为 PUBLIC PATH

const { Router } = require('express');
const subscriptionServiceStore = require('../data/subscriptionServiceStore');
const { requirePermission } = require('../middleware/auth');

const router = Router();

// GET /subscription-services — 分页列表
router.get('/', requirePermission('subscription-service:view'), (req, res) => {
  const { partnerTenantId, status, page, pageSize } = req.query;
  const result = subscriptionServiceStore.list({ partnerTenantId, status, page, pageSize });
  res.ok(result);
});

// POST /subscription-services — 创建订阅服务
router.post('/', requirePermission('subscription-service:manage'), (req, res) => {
  const { partnerTenantId, deploymentType, effectiveTier, expiresAt } = req.body || {};
  if (!partnerTenantId) {
    return res.fail(422, 'VALIDATION_ERROR', 'partnerTenantId 为必填项');
  }

  const result = subscriptionServiceStore.create({
    partnerTenantId,
    deploymentType,
    effectiveTier,
    expiresAt,
  });

  if (result.error) {
    return res.fail(422, 'VALIDATION_ERROR', result.message);
  }

  // rawServiceKey is returned only at creation time (one-time secret)
  res.ok({
    subscription: result.subscription,
    rawServiceKey: result.rawServiceKey,
  }, '订阅服务创建成功');
});

// GET /subscription-services/:id — 详情
router.get('/:id', requirePermission('subscription-service:view'), (req, res) => {
  const svc = subscriptionServiceStore.getById(req.params.id);
  if (!svc) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '订阅服务不存在');
  }

  res.ok(svc);
});

// POST /subscription-services/:id/renew — 续期
router.post('/:id/renew', requirePermission('subscription-service:manage'), (req, res) => {
  const { expiresAt } = req.body || {};
  if (!expiresAt) {
    return res.fail(422, 'VALIDATION_ERROR', 'expiresAt 为必填项');
  }

  const result = subscriptionServiceStore.renew(req.params.id, expiresAt);
  if (result.error) {
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '订阅服务不存在');
    }
    return res.fail(400, 'BAD_REQUEST', result.message);
  }

  res.ok(result.subscription, '续期成功');
});

// POST /subscription-services/:id/revoke — 吊销
router.post('/:id/revoke', requirePermission('subscription-service:manage'), (req, res) => {
  const result = subscriptionServiceStore.revoke(req.params.id);
  if (result.error) {
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '订阅服务不存在');
    }
    return res.fail(400, 'BAD_REQUEST', result.message);
  }

  res.ok(result.subscription, '吊销成功');
});

// POST /subscription-services/heartbeat — 服务心跳（PUBLIC PATH）
router.post('/heartbeat', (req, res) => {
  const { serviceKey, instanceId, version, cattleCount, deviceCount } = req.body || {};

  if (!serviceKey) {
    return res.fail(422, 'VALIDATION_ERROR', 'serviceKey 为必填项');
  }

  const instanceInfo = { instanceId, version, cattleCount, deviceCount };
  const result = subscriptionServiceStore.heartbeat(serviceKey, instanceInfo);

  if (result.error) {
    if (result.error === 'invalid_key') {
      return res.fail(401, 'AUTH_UNAUTHORIZED', '无效的 serviceKey');
    }
    return res.fail(400, 'BAD_REQUEST', result.message);
  }

  // Build response — precedence: revoked > expired > status-based
  const GRACE_PERIOD_DAYS = subscriptionServiceStore.GRACE_PERIOD_DAYS;
  let responseStatus;
  let responseMessage = null;

  // 1. Revoked is terminal — check first
  if (result.status === 'revoked') {
    responseStatus = 'revoked';
    responseMessage = '订阅服务已吊销';
  }
  // 2. Expiry by date — check before status mapping
  else if (result.expiresAt && new Date(result.expiresAt) > new Date(0)) {
    const expiry = new Date(result.expiresAt);
    if (new Date() > expiry) {
      responseStatus = 'expired';
      responseMessage = '订阅服务已过期，请联系续期';
    }
  }

  // 3. Status-based mapping (only if not already set)
  if (!responseStatus) {
    switch (result.status) {
      case 'active':
        responseStatus = 'ok';
        break;
      case 'grace_period':
        responseStatus = 'grace_period';
        if (result.gracePeriodEnteredAt) {
          const enteredAt = new Date(result.gracePeriodEnteredAt);
          const now = new Date();
          const daysPassed = Math.floor((now - enteredAt) / (24 * 60 * 60 * 1000));
          const remaining = Math.max(0, GRACE_PERIOD_DAYS - daysPassed);
          responseMessage = `宽限期内，还有 ${remaining} 天恢复`;
        } else {
          responseMessage = '宽限期内，请尽快恢复服务连接';
        }
        break;
      case 'degraded':
        responseStatus = 'degraded';
        responseMessage = '订阅服务已过期，请联系续期';
        break;
      default:
        responseStatus = 'ok';
        break;
    }
  }

  res.ok({
    status: responseStatus,
    tier: result.tier || 'basic',
    message: responseMessage,
  });
});

module.exports = router;
