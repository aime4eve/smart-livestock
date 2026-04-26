const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { buildUserProjection } = require('../services/userProjectionService');

const router = Router();

/**
 * GET /api/profile
 */
router.get(
  '/',
  authMiddleware,
  requirePermission('profile:view'),
  (req, res) => {
    res.ok(buildUserProjection(req.user));
  }
);

module.exports = router;
