const { Router } = require('express');
const { requirePermission } = require('../middleware/auth');
const { buildUserProjection } = require('../services/userProjectionService');

const router = Router();

/**
 * GET /api/profile
 */
router.get(
  '/',
  requirePermission('profile:view'),
  (req, res) => {
    res.ok(buildUserProjection(req.user));
  }
);

module.exports = router;
