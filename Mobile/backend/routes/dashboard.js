const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { dashboardMetrics } = require('../data/seed');

const router = Router();

/**
 * GET /api/dashboard/summary
 */
router.get(
  '/summary',
  authMiddleware,
  requirePermission('dashboard:view'),
  (req, res) => {
    res.ok({
      metrics: dashboardMetrics,
      lastSyncAt: new Date().toISOString(),
    });
  }
);

module.exports = router;
