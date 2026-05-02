// Revenue Settlement Routes (E4.1)
// Phase 2b: 分润对账 — 结算周期列表、详情、确认、手动触发月结算

const { Router } = require('express');
const revenueStore = require('../data/revenueStore');
const { requirePermission } = require('../middleware/auth');

const router = Router();

// GET /revenue/periods — 分页列表（支持 ?partnerId= 过滤）
router.get('/periods', requirePermission('revenue:view'), (req, res) => {
  const { partnerId, page, pageSize } = req.query;

  // b2b_admin data isolation: can only see their own partner periods
  let partnerTenantId = partnerId || null;
  if (req.userRole === 'b2b_admin') {
    // b2b_admin's tenantId is their partner tenant (e.g., tenant_p001)
    // If they pass a different partnerId, that's allowed but filtered to their own
    partnerTenantId = req.user.tenantId;
  }

  const query = { page, pageSize };
  if (partnerTenantId) {
    query.partnerTenantId = partnerTenantId;
  }

  const result = revenueStore.getPeriods(query);
  res.ok(result);
});

// GET /revenue/periods/:id — 详情 + farm 明细
router.get('/periods/:id', requirePermission('revenue:view'), (req, res) => {
  const period = revenueStore.getPeriod(req.params.id);
  if (!period) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '结算周期不存在');
  }

  // b2b_admin data isolation: can only see their own partner periods
  if (req.userRole === 'b2b_admin' && period.partnerTenantId !== req.user.tenantId) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问该结算周期');
  }

  res.ok(period);
});

// POST /revenue/periods/:id/confirm — 确认对账
router.post('/periods/:id/confirm', requirePermission('revenue:view'), (req, res) => {
  const result = revenueStore.confirm(req.params.id, req.userRole, req.user.tenantId);

  if (result.error) {
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '结算周期不存在');
    }
    if (result.error === 'forbidden') {
      return res.fail(403, 'AUTH_FORBIDDEN', '无权确认该结算周期');
    }
    return res.fail(400, 'BAD_REQUEST', '确认失败');
  }

  const msg = result.period.status === 'settled'
    ? '对账已确认，周期已结算'
    : '确认成功';

  res.ok(result.period, msg);
});

// POST /revenue/calculate — 手动触发月结算（仅 platform_admin）
router.post('/calculate', requirePermission('revenue:calculate'), (req, res) => {
  const { period } = req.body || {};
  if (!period) {
    return res.fail(422, 'VALIDATION_ERROR', 'period 为必填项（格式: 2026-05）');
  }

  const createdPeriods = revenueStore.calculate(period, 'monthly');

  if (createdPeriods.length === 0) {
    return res.ok([], '本次无新结算周期生成（可能已存在或无符合条件的合作伙伴）');
  }

  res.ok(createdPeriods, `已生成 ${createdPeriods.length} 个结算周期`);
});

module.exports = router;
