const { Router } = require('express');
const { requirePermission } = require('../middleware/auth');
const { featureKeys } = require('../middleware/feature-flag');
const fenceStore = require('../data/fenceStore');

const router = Router();

function handleValidationError(res, error) {
  if (error === 'name_required') {
    return res.fail(422, 'VALIDATION_ERROR', 'name 为必填项');
  }
  if (error === 'type_invalid') {
    return res.fail(422, 'VALIDATION_ERROR', 'type 必须为 polygon / circle / rectangle');
  }
  if (error === 'coordinates_invalid') {
    return res.fail(422, 'VALIDATION_ERROR', 'coordinates 必须为至少 3 个有效坐标点');
  }
  if (error === 'alarm_enabled_invalid') {
    return res.fail(422, 'VALIDATION_ERROR', 'alarmEnabled 必须为布尔值');
  }
  if (error === 'status_invalid') {
    return res.fail(422, 'VALIDATION_ERROR', 'status 必须为 active / inactive');
  }
  if (error === 'version_conflict') {
    return res.fail(409, 'CONFLICT', '围栏已被其他用户修改，请刷新后重试');
  }
  return null;
}

router.get(
  '/',
  requirePermission('fence:view'),
  featureKeys('fence'),
  (req, res) => {
    const { page = '1', pageSize = '20' } = req.query;
    res.ok(fenceStore.sliceForPage(page, pageSize));
  },
);

router.get(
  '/:id',
  requirePermission('fence:view'),
  (req, res) => {
    const { id } = req.params;
    const fence = fenceStore.findById(id);
    if (!fence) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    res.ok(fence);
  },
);

router.post(
  '/',
  requirePermission('fence:manage'),
  (req, res) => {
    const result = fenceStore.createFence(req.body || {});
    if (result.error) {
      return handleValidationError(res, result.error);
    }
    res.ok(result.fence);
  },
);

router.put(
  '/:id',
  requirePermission('fence:manage'),
  (req, res) => {
    const { id } = req.params;
    const result = fenceStore.updateFence(id, req.body || {});
    if (result.error === 'not_found') {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    if (result.error) {
      return handleValidationError(res, result.error);
    }
    res.ok(result.fence);
  },
);

router.delete(
  '/:id',
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
