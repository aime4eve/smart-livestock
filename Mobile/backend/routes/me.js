const { Router } = require('express');
const { authMiddleware } = require('../middleware/auth');
const { buildUserProjection } = require('../services/userProjectionService');

const router = Router();

/**
 * GET /api/me
 */
router.get('/', authMiddleware, (req, res) => {
  res.ok(buildUserProjection(req.user));
});

module.exports = router;
