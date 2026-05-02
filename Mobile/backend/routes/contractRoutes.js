// Contract Routes (E6.1)
// Phase 2b: 合同 CRUD — 合同创建、列表、详情、编辑、终止
// 所有写操作仅限 platform_admin（contract:manage），读操作支持 platform_admin + b2b_admin（仅自己合同）

const { Router } = require('express');
const contractStore = require('../data/contractStore');
const { requirePermission } = require('../middleware/auth');

const router = Router();

// Helper to find contract by ID from the store's list
function findById(id) {
  const { items } = contractStore.list({ pageSize: 9999 });
  return items.find((c) => c.id === id) ?? null;
}

// GET /contracts — 分页列表（支持 ?partnerId=&status= 过滤），仅 platform_admin
router.get('/', requirePermission('contract:manage'), (req, res) => {
  const { partnerId, status, page, pageSize } = req.query;
  const result = contractStore.list({ partnerId, status, page, pageSize });
  res.ok(result);
});

// POST /contracts — 创建合同，仅 platform_admin
router.post('/', requirePermission('contract:manage'), (req, res) => {
  const { partnerTenantId, effectiveTier, revenueShareRatio, expiresAt, signedBy } = req.body || {};
  const result = contractStore.create({
    partnerTenantId,
    effectiveTier,
    revenueShareRatio,
    expiresAt,
    signedBy,
  });

  if (result.error) {
    return res.fail(422, 'VALIDATION_ERROR', result.message);
  }

  res.ok(result.contract, '合同创建成功');
});

// GET /contracts/:id — 详情，platform_admin + b2b_admin（仅自己的合同）
router.get('/:id', (req, res) => {
  // Allow both contract:manage (platform_admin) and contract:view (b2b_admin)
  const hasManage = req.user?.permissions?.includes('contract:manage');
  const hasView = req.user?.permissions?.includes('contract:view');
  if (!hasManage && !hasView) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问资源');
  }

  const contract = findById(req.params.id);
  if (!contract) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '合同不存在');
  }

  // b2b_admin data isolation: can only see their own partner contract
  if (req.userRole === 'b2b_admin' && contract.partnerTenantId !== req.user.tenantId) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问该合同');
  }

  res.ok(contract);
});

// PUT /contracts/:id — 编辑合同，仅 platform_admin
router.put('/:id', requirePermission('contract:manage'), (req, res) => {
  const result = contractStore.update(req.params.id, req.body);

  if (result.error) {
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '合同不存在');
    }
    return res.fail(400, 'BAD_REQUEST', '编辑失败');
  }

  res.ok(result.contract, '合同编辑成功');
});

// POST /contracts/:id/terminate — 终止合同，仅 platform_admin
router.post('/:id/terminate', requirePermission('contract:manage'), (req, res) => {
  const result = contractStore.terminate(req.params.id);

  if (result.error) {
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '合同不存在');
    }
    return res.fail(400, 'BAD_REQUEST', '终止失败');
  }

  res.ok(result.contract, '合同已终止');
});

module.exports = router;
