const { Router } = require('express');
const { users } = require('../data/seed');

const router = Router();

/**
 * POST /api/auth/login
 * Body: { role: "owner" | "worker" | "ops" }
 */
router.post('/login', (req, res) => {
  const { role } = req.body || {};
  if (!role || !users[role]) {
    return res.fail(422, 'VALIDATION_ERROR', 'role 必须为 owner / worker / ops');
  }
  const token = `mock-token-${role}`;
  res.ok({ token, role });
});

module.exports = router;
