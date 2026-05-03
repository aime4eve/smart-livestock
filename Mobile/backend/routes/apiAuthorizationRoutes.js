// API Authorization Routes
// Phase 2b: API 数据访问授权管理 — api_consumer 申请访问牧场数据,
// platform_admin / owner 审批或拒绝

const { Router } = require('express');
const apiAuthorizationStore = require('../data/apiAuthorizationStore');
const tenantStore = require('../data/tenantStore');
const { requirePermission } = require('../middleware/auth');

const router = Router();

/**
 * Resolve an authorization record by id from the store's full list.
 * Returns null if not found.
 */
function _findById(id) {
  const all = apiAuthorizationStore.list({ page: '1', pageSize: '99999' });
  return all.items.find((a) => a.id === id) || null;
}

// ──────────────────────────────────────────────
// GET /api-authorizations — list (paginated)
// platform_admin sees all; owner sees only own farms
// ──────────────────────────────────────────────
router.get('/', (req, res) => {
  const role = req.userRole;

  // api_consumer: view own authorization applications
  if (role === 'api_consumer') {
    const result = apiAuthorizationStore.list({
      apiTenantId: req.user.tenantId,
      ...req.query,
    });
    return res.ok(result);
  }

  if (role !== 'platform_admin' && role !== 'owner') {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问资源');
  }

  // platform_admin: full visibility, delegate to store directly
  if (role === 'platform_admin') {
    const result = apiAuthorizationStore.list(req.query);
    return res.ok(result);
  }

  // owner: data isolation — only authorizations for farms they own
  const ownerFarms = tenantStore.findByOwnerId(req.user.userId);
  const ownerFarmIds = ownerFarms.map((f) => f.id);

  if (ownerFarmIds.length === 0) {
    return res.ok({ items: [], page: 1, pageSize: 20, total: 0 });
  }

  // Determine which farm IDs are allowed for this query.
  // If owner requests a specific farmTenantId, verify ownership and restrict to that one.
  let allowedFarmIds = ownerFarmIds;
  if (req.query.farmTenantId) {
    if (!ownerFarmIds.includes(req.query.farmTenantId)) {
      return res.fail(403, 'AUTH_FORBIDDEN', '无权访问该牧场授权');
    }
    allowedFarmIds = [req.query.farmTenantId];
  }

  // Fetch all matching items from store (exclude farmTenantId from store
  // query since we do owner-level filtering ourselves)
  const storeQuery = { ...req.query };
  delete storeQuery.farmTenantId;

  const allItems = apiAuthorizationStore.list({
    ...storeQuery,
    page: '1',
    pageSize: '99999',
  });

  // Filter to allowed farm IDs
  const filtered = allItems.items.filter((a) =>
    allowedFarmIds.includes(a.farmTenantId),
  );

  // Apply pagination
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const pageSize = Math.max(1, parseInt(req.query.pageSize, 10) || 20);
  const total = filtered.length;
  const start = (page - 1) * pageSize;
  const items = filtered.slice(start, start + pageSize);

  return res.ok({ items, page, pageSize, total });
});

// ──────────────────────────────────────────────
// POST /api-authorizations — submit application
// api_consumer only, creates pending authorization
// ──────────────────────────────────────────────
router.post('/', requirePermission('api-authorization:request'), (req, res) => {
  const { farmTenantId, requestedScopes } = req.body || {};

  if (!farmTenantId) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少 farmTenantId');
  }

  // Verify the target farm exists and is of type farm
  const farm = tenantStore.findById(farmTenantId);
  if (!farm || farm.type !== 'farm') {
    return res.fail(400, 'VALIDATION_ERROR', '牧场不存在');
  }

  const result = apiAuthorizationStore.create({
    apiTenantId: req.user.tenantId,
    farmTenantId,
    requestedBy: req.user.userId,
    requestedScopes: requestedScopes || null,
  });

  if (result.error) {
    return res.fail(422, 'VALIDATION_ERROR', '创建授权申请失败');
  }

  res.ok(result.authorization, '授权申请已提交');
});

// ──────────────────────────────────────────────
// Helper: verify review permission + owner farm ownership
// ──────────────────────────────────────────────
function _checkReviewPermission(req, auth) {
  if (!req.user.permissions.includes('api-authorization:review')) {
    return { error: true, status: 403, code: 'AUTH_FORBIDDEN', message: '无权审核授权' };
  }

  // Owner can only review authorizations for their own farms
  if (req.userRole === 'owner') {
    const farm = tenantStore.findById(auth.farmTenantId);
    if (!farm || farm.ownerId !== req.user.userId) {
      return { error: true, status: 403, code: 'AUTH_FORBIDDEN', message: '无权审核该牧场授权' };
    }
  }

  return { error: false };
}

// ──────────────────────────────────────────────
// POST /api-authorizations/:id/approve
// platform_admin or owner with api-authorization:review
// ──────────────────────────────────────────────
router.post('/:id/approve', (req, res) => {
  const auth = _findById(req.params.id);
  if (!auth) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '授权记录不存在');
  }

  const perm = _checkReviewPermission(req, auth);
  if (perm.error) {
    return res.fail(perm.status, perm.code, perm.message);
  }

  const result = apiAuthorizationStore.approve(req.params.id, req.user.userId);
  if (result.error) {
    return res.fail(400, 'BAD_REQUEST', '审批失败');
  }

  res.ok(result.authorization, '授权已批准');
});

// ──────────────────────────────────────────────
// POST /api-authorizations/:id/reject
// platform_admin or owner with api-authorization:review
// ──────────────────────────────────────────────
router.post('/:id/reject', (req, res) => {
  const auth = _findById(req.params.id);
  if (!auth) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '授权记录不存在');
  }

  const perm = _checkReviewPermission(req, auth);
  if (perm.error) {
    return res.fail(perm.status, perm.code, perm.message);
  }

  const result = apiAuthorizationStore.reject(req.params.id, req.user.userId);
  if (result.error) {
    return res.fail(400, 'BAD_REQUEST', '拒绝失败');
  }

  res.ok(result.authorization, '授权已拒绝');
});

// ──────────────────────────────────────────────
// POST /api-authorizations/:id/revoke
// platform_admin or owner with api-authorization:review
// ──────────────────────────────────────────────
router.post('/:id/revoke', (req, res) => {
  const auth = _findById(req.params.id);
  if (!auth) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '授权记录不存在');
  }

  const perm = _checkReviewPermission(req, auth);
  if (perm.error) {
    return res.fail(perm.status, perm.code, perm.message);
  }

  const result = apiAuthorizationStore.revoke(req.params.id);
  if (result.error) {
    return res.fail(400, 'BAD_REQUEST', '撤销失败');
  }

  res.ok(result.authorization, '授权已撤销');
});

module.exports = router;
