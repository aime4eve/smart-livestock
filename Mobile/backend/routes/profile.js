const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { tenants } = require('../data/seed');

const router = Router();

/**
 * GET /api/profile
 */
router.get(
  '/',
  authMiddleware,
  requirePermission('profile:view'),
  (req, res) => {
    const { userId, name, mobile, tenantId } = req.user;
    const tenant = tenants.find((t) => t.id === tenantId);
    res.ok({
      userId,
      name,
      mobile,
      tenantName: tenant ? tenant.name : null,
      notificationEnabled: true,
    });
  }
);

module.exports = router;
