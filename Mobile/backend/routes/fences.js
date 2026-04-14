const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const fenceStore = require('../data/fenceStore');

const router = Router();

router.get(
  '/',
  authMiddleware,
  requirePermission('fence:view'),
  (req, res) => {
    const { page = '1', pageSize = '20' } = req.query;
    res.ok(fenceStore.sliceForPage(page, pageSize));
  },
);

router.post(
  '/',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const result = fenceStore.createFence(req.body || {});
    if (result.error === 'name_required') {
      return res.fail(422, 'VALIDATION_ERROR', 'name 为必填项');
    }
    res.ok(result.fence);
  },
);

router.put(
  '/:id',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const { id } = req.params;
    const result = fenceStore.updateFence(id, req.body || {});
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    res.ok(result.fence);
  },
);

router.delete(
  '/:id',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const { id } = req.params;
    const result = fenceStore.removeFence(id);
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    res.ok(result.removed);
  },
);

module.exports = router;
