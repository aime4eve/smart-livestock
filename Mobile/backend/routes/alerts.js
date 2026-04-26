const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { alerts: seedAlerts } = require('../data/seed');

const router = Router();

// In-memory alerts (clone from seed so we can mutate)
let alerts = seedAlerts.map((a) => ({ ...a }));

const VALID_STAGES = ['pending', 'acknowledged', 'handled', 'archived'];
const VALID_BATCH_ACTIONS = ['ack', 'handle', 'archive'];
const STAGE_TRANSITIONS = {
  pending: 'acknowledged',
  acknowledged: 'handled',
  handled: 'archived',
};
const ACTION_TARGET_STAGE = {
  ack: 'acknowledged',
  handle: 'handled',
  archive: 'archived',
};

/**
 * GET /api/alerts?stage=&page=&pageSize=
 */
router.get(
  '/',
  authMiddleware,
  requirePermission('alert:view'),
  (req, res) => {
    const { stage, page = '1', pageSize = '20' } = req.query;
    const p = Math.max(1, parseInt(page, 10) || 1);
    const ps = Math.max(1, parseInt(pageSize, 10) || 20);

    let filtered = alerts;
    if (stage && VALID_STAGES.includes(stage)) {
      filtered = alerts.filter((a) => a.stage === stage);
    }

    const total = filtered.length;
    const start = (p - 1) * ps;
    const items = filtered.slice(start, start + ps);

    res.ok({ items, page: p, pageSize: ps, total });
  }
);

/**
 * POST /api/alerts/:id/ack
 */
router.post(
  '/:id/ack',
  authMiddleware,
  requirePermission('alert:ack'),
  (req, res) => {
    transitionAlert(req, res, 'acknowledged');
  }
);

/**
 * POST /api/alerts/:id/handle
 */
router.post(
  '/:id/handle',
  authMiddleware,
  requirePermission('alert:handle'),
  (req, res) => {
    transitionAlert(req, res, 'handled');
  }
);

/**
 * POST /api/alerts/:id/archive
 */
router.post(
  '/:id/archive',
  authMiddleware,
  requirePermission('alert:archive'),
  (req, res) => {
    transitionAlert(req, res, 'archived');
  }
);

/**
 * POST /api/alerts/batch-handle
 */
router.post(
  '/batch-handle',
  authMiddleware,
  requirePermission('alert:batch'),
  (req, res) => {
    const { alertIds, action } = req.body || {};
    if (!Array.isArray(alertIds) || !alertIds.length) {
      return res.fail(422, 'VALIDATION_ERROR', 'alertIds 必须为非空数组');
    }
    if (!VALID_BATCH_ACTIONS.includes(action)) {
      return res.fail(422, 'VALIDATION_ERROR', `action 必须为 ${VALID_BATCH_ACTIONS.join(' / ')}`);
    }

    const updated = [];
    const errors = [];

    for (const id of alertIds) {
      const alert = alerts.find((a) => a.id === id);
      if (!alert) {
        errors.push({ id, error: 'NOT_FOUND' });
        continue;
      }
      const expected = STAGE_TRANSITIONS[alert.stage];
      if (expected !== ACTION_TARGET_STAGE[action]) {
        errors.push({ id, error: 'INVALID_TRANSITION', currentStage: alert.stage });
        continue;
      }
      alert.stage = STAGE_TRANSITIONS[alert.stage];
      updated.push(alert);
    }

    res.ok({ updated: updated.length, errors });
  }
);

/**
 * Helper: transition a single alert's stage
 */
function transitionAlert(req, res, targetStage) {
  const { id } = req.params;
  const alert = alerts.find((a) => a.id === id);
  if (!alert) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '告警不存在');
  }
  const expected = STAGE_TRANSITIONS[alert.stage];
  if (expected !== targetStage) {
    return res.fail(409, 'CONFLICT', `告警当前状态为 ${alert.stage}，无法直接变为 ${targetStage}`);
  }
  alert.stage = targetStage;
  res.ok(alert);
}

module.exports = router;
