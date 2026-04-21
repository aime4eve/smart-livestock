const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const store = require('../data/tenantStore');

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
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const { page, pageSize, status, search, sort, order } = req.query;
    res.ok(store.sliceForPage({ page, pageSize, status, search, sort, order }));
  }
);

router.get(
  '/:id',
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) return sendErr(res, 'not_found');
    res.ok(tenant);
  }
);

router.post(
  '/',
  authMiddleware,
  requirePermission('tenant:create'),
  (req, res) => {
    const { name, licenseTotal = 100 } = req.body || {};
    const result = store.createTenant({ name, licenseTotal });
    if (result.error) return sendErr(res, result.error);
    res.ok(result.tenant);
  }
);

router.put(
  '/:id',
  authMiddleware,
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
  authMiddleware,
  requirePermission('tenant:delete'),
  (req, res) => {
    const result = store.removeTenant(req.params.id);
    if (result.error) return sendErr(res, result.error);
    res.ok({ id: result.removed.id });
  }
);

router.post(
  '/:id/status',
  authMiddleware,
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
  authMiddleware,
  requirePermission('license:manage'),
  (req, res) => {
    const { licenseTotal } = req.body || {};
    const existing = store.findById(req.params.id);
    const result = store.adjustLicense(req.params.id, licenseTotal);
    if (result.error) return sendErr(res, result.error, existing);
    res.ok(result.tenant);
  }
);

module.exports = router;
