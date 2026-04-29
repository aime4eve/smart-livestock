const { Router } = require('express');
// authMiddleware is now global (registered in server.js)
const { buildUserProjection } = require('../services/userProjectionService');

const router = Router();

/**
 * GET /api/me
 */
router.get('/', (req, res) => {
  res.ok(buildUserProjection(req.user));
});

module.exports = router;
