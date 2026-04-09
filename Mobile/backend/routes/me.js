const { Router } = require('express');
const { authMiddleware } = require('../middleware/auth');

const router = Router();

/**
 * GET /api/me
 */
router.get('/', authMiddleware, (req, res) => {
  const { userId, tenantId, name, role, permissions } = req.user;
  res.ok({ userId, tenantId, name, role, permissions });
});

module.exports = router;
