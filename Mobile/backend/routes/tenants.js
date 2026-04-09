const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { tenants: seedTenants } = require('../data/seed');

const router = Router();

// In-memory tenants
let tenants = seedTenants.map((t) => ({ ...t }));
let nextId = tenants.length + 1;

/**
 * GET /api/tenants
 */
router.get(
  '/',
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const { page = '1', pageSize = '20' } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const ps = Math.max(1, parseInt(pageSize, 10) || 20);
    const total = tenants.length;
    const start = (p - 1) * ps;
    const items = tenants.slice(start, start + ps);

    res.ok({ items, page: p, pageSize: ps, total });
  }
);

/**
 * POST /api/tenants
 */
router.post(
  '/',
  authMiddleware,
  requirePermission('tenant:create'),
  (req, res) => {
    const { name, licenseTotal = 100 } = req.body || {};
    if (!name) {
      return res.fail(422, 'VALIDATION_ERROR', 'name 为必填项');
    }
    const tenant = {
      id: `tenant_${String(nextId++).padStart(3, '0')}`,
      name,
      status: 'active',
      licenseUsed: 0,
      licenseTotal,
    };
    tenants.push(tenant);
    res.ok(tenant);
  }
);

/**
 * POST /api/tenants/:id/status
 */
router.post(
  '/:id/status',
  authMiddleware,
  requirePermission('tenant:toggle'),
  (req, res) => {
    const { id } = req.params;
    const { status } = req.body || {};
    if (!['active', 'disabled'].includes(status)) {
      return res.fail(422, 'VALIDATION_ERROR', 'status 必须为 active / disabled');
    }
    const tenant = tenants.find((t) => t.id === id);
    if (!tenant) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '租户不存在');
    }
    tenant.status = status;
    res.ok(tenant);
  }
);

/**
 * POST /api/tenants/:id/license
 */
router.post(
  '/:id/license',
  authMiddleware,
  requirePermission('license:manage'),
  (req, res) => {
    const { id } = req.params;
    const { licenseTotal } = req.body || {};
    if (typeof licenseTotal !== 'number' || licenseTotal < 0) {
      return res.fail(422, 'VALIDATION_ERROR', 'licenseTotal 必须为非负整数');
    }
    const tenant = tenants.find((t) => t.id === id);
    if (!tenant) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '租户不存在');
    }
    tenant.licenseTotal = licenseTotal;
    res.ok(tenant);
  }
);

module.exports = router;
