const { Router } = require('express');
const { requirePermission } = require('../middleware/auth');
const { featureKeys } = require('../middleware/feature-flag');
const { dashboardMetrics } = require('../data/seed');

const router = Router();

router.get(
  '/summary',
  requirePermission('dashboard:view'),
  featureKeys('dashboard_summary'),
  (req, res) => {
    res.ok({
      metrics: dashboardMetrics,
      lastSyncAt: new Date().toISOString(),
    });
  }
);

module.exports = router;
