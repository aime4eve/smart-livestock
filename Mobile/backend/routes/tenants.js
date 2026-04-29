const { Router } = require('express');
const { requirePermission } = require('../middleware/auth');
const store = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');
const { devices } = require('../data/seed');

const router = Router();

const ERROR_MAP = {
  name_required: { status: 422, code: 'VALIDATION_ERROR', message: 'name 为必填项' },
  name_conflict: { status: 409, code: 'CONFLICT', message: '租户名称已存在' },
  license_invalid: { status: 422, code: 'VALIDATION_ERROR', message: 'licenseTotal 必须为非负整数' },
  license_below_used: { status: 422, code: 'VALIDATION_ERROR', message: '新配额不能小于当前已使用量' },
  status_invalid: { status: 422, code: 'VALIDATION_ERROR', message: 'status 必须为 active / disabled' },
  not_found: { status: 404, code: 'RESOURCE_NOT_FOUND', message: '租户不存在' },
};

function sendErr(res, tenantError, tenantContext) {
  const spec = ERROR_MAP[tenantError];
  if (!spec) return res.fail(500, 'INTERNAL_ERROR', '未知错误');
  const msg = tenantError === 'license_below_used' && tenantContext
    ? `${spec.message}（${tenantContext.licenseUsed}）`
    : spec.message;
  return res.fail(spec.status, spec.code, msg);
}

router.get(
  '/',
  requirePermission('tenant:view'),
  (req, res) => {
    const { page, pageSize, status, type, parentTenantId, search, sort, order } = req.query;
    res.ok(store.sliceForPage({ page, pageSize, status, type, parentTenantId, search, sort, order }));
  }
);

router.get(
  '/:id',
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');
    res.ok(tenant);
  }
);

router.post(
  '/',
  requirePermission('tenant:create'),
  (req, res) => {
    const { name, licenseTotal = 100, type, billingModel, entitlementTier, ownerId, parentTenantId } = req.body || {};
    const result = store.createTenant({ name, licenseTotal, type, billingModel, entitlementTier, ownerId, parentTenantId });
    if (result.error) return sendErr(res, result.error);
    // 为新 farm 租户创建试用订阅
    if (result.tenant.type === 'farm') {
      subscriptionStore.createTrial(result.tenant.id);
    }
    res.ok(result.tenant);
  }
);

router.put(
  '/:id',
  requirePermission('tenant:edit'),
  (req, res) => {
    const { name } = req.body || {};
    const result = store.updateTenant(req.params.id, { name });
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.delete(
  '/:id',
  requirePermission('tenant:delete'),
  (req, res) => {
    const result = store.removeTenant(req.params.id);
    if (result.error) return sendErr(res, result.error);
    res.ok({ id: result.removed.id });
  }
);

router.post(
  '/:id/status',
  requirePermission('tenant:toggle'),
  (req, res) => {
    const { status } = req.body || {};
    const result = store.toggleStatus(req.params.id, status);
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.post(
  '/:id/license',
  requirePermission('license:manage'),
  (req, res) => {
    const { licenseTotal } = req.body || {};
    const existing = store.findById(req.params.id);
    const result = store.adjustLicense(req.params.id, licenseTotal);
    if (result.error) return sendErr(res, result.error, existing);
    res.ok(result.tenant);
  }
);

router.get(
  '/:id/devices',
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');

    const tenantIdx = parseInt(tenant.id.split('_')[1], 10) || 1;
    // Distribute devices across tenants: tenant_001 gets all, others get a subset
    const subset = tenantIdx === 1
      ? devices
      : devices.filter((_, i) => (i % (tenantIdx + 2)) === 0);

    res.ok({
      items: subset,
      page: 1,
      pageSize: subset.length,
      total: subset.length,
    });
  }
);

router.get(
  '/:id/logs',
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');

    const logs = [
      { id: 'log-001', action: '租户创建', detail: `创建租户「${tenant.name}」`, operator: '运维管理员', createdAt: tenant.createdAt || '2025-08-12T09:00:00+08:00' },
      { id: 'log-002', action: 'License 调整', detail: `配额从 ${Math.max(tenant.licenseTotal - 50, 50)} 调整为 ${tenant.licenseTotal}`, operator: '运维管理员', createdAt: tenant.updatedAt || '2026-04-20T14:30:00+08:00' },
      { id: 'log-003', action: '状态变更', detail: `状态变更为「${tenant.status === 'active' ? '启用中' : '已禁用'}」`, operator: '运维管理员', createdAt: tenant.updatedAt || '2026-04-20T14:30:00+08:00' },
      { id: 'log-004', action: '信息更新', detail: '更新租户基本信息', operator: '运维管理员', createdAt: tenant.updatedAt || '2026-04-19T10:00:00+08:00' },
    ];

    res.ok({
      items: logs,
      page: 1,
      pageSize: logs.length,
      total: logs.length,
    });
  }
);

router.get(
  '/:id/stats',
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');

    const tenantIdx = parseInt(tenant.id.split('_')[1], 10) || 1;
    const deviceCount = tenantIdx === 1 ? 100 : Math.max(10, 100 - tenantIdx * 15);
    const onlineCount = Math.round(deviceCount * 0.85);
    const livestockCount = Math.round(tenant.licenseUsed * 1.0);
    const healthRate = 88 + (tenantIdx % 10);
    const alertCount = 3 + (tenantIdx % 6);

    res.ok({
      livestockTotal: livestockCount,
      deviceTotal: deviceCount,
      deviceOnline: onlineCount,
      deviceOnlineRate: deviceCount > 0 ? Math.round((onlineCount / deviceCount) * 100) : 0,
      healthRate,
      alertCount,
      lastSync: '2 分钟前',
    });
  }
);

function generateTrends(tenantId) {
  const now = new Date();
  const dailyStats = [];
  for (let i = 0; i < 30; i++) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const date = d.toISOString().substring(0, 10);
    const base = Math.abs(hashCode(tenantId + date));
    dailyStats.push({
      date,
      alerts: Math.max(0, Math.round((base % 8) + (Math.sin(i * 0.3) * 3))),
      deviceOnlineRate: Math.min(100, 80 + (base % 20)),
      healthRate: Math.min(100, 75 + (base % 25)),
    });
  }
  return { dailyStats };
}

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash + str.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

router.get(
  '/:id/trends',
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '租户不存在');
    }
    res.ok(generateTrends(req.params.id));
  }
);

module.exports = { router, generateTrends };
