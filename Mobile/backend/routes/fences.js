const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { fences: seedFences } = require('../data/seed');

const router = Router();

// In-memory fences
let fences = seedFences.map((f) => ({ ...f }));
let nextId = fences.length + 1;

/**
 * GET /api/fences
 */
router.get(
  '/',
  authMiddleware,
  requirePermission('fence:view'),
  (req, res) => {
    const { page = '1', pageSize = '20' } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const ps = Math.max(1, parseInt(pageSize, 10) || 20);
    const total = fences.length;
    const start = (p - 1) * ps;
    const items = fences.slice(start, start + ps);

    res.ok({ items, page: p, pageSize: ps, total });
  }
);

/**
 * POST /api/fences
 */
router.post(
  '/',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const { name, type = 'polygon', coordinates = [], alarmEnabled = true } = req.body || {};
    if (!name) {
      return res.fail(422, 'VALIDATION_ERROR', 'name 为必填项');
    }
    const fence = {
      id: `fence_${String(nextId++).padStart(3, '0')}`,
      name,
      type,
      status: 'active',
      alarmEnabled,
      coordinates,
    };
    fences.push(fence);
    res.ok(fence);
  }
);

/**
 * PUT /api/fences/:id
 */
router.put(
  '/:id',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const { id } = req.params;
    const fence = fences.find((f) => f.id === id);
    if (!fence) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    const { name, type, coordinates, alarmEnabled } = req.body || {};
    if (name !== undefined) fence.name = name;
    if (type !== undefined) fence.type = type;
    if (coordinates !== undefined) fence.coordinates = coordinates;
    if (alarmEnabled !== undefined) fence.alarmEnabled = alarmEnabled;
    res.ok(fence);
  }
);

/**
 * DELETE /api/fences/:id
 */
router.delete(
  '/:id',
  authMiddleware,
  requirePermission('fence:manage'),
  (req, res) => {
    const { id } = req.params;
    const idx = fences.findIndex((f) => f.id === id);
    if (idx === -1) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '围栏不存在');
    }
    const [removed] = fences.splice(idx, 1);
    res.ok(removed);
  }
);

module.exports = router;
