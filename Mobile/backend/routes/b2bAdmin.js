const { Router } = require('express');
const router = Router();

// Note: authMiddleware is global (Task 9), not per-route
router.get('/status', (req, res) => {
  if (req.userRole !== 'b2b_admin') {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 B端客户可访问');
  }
  res.ok({ phase: 1, message: '功能开发中，敬请期待' });
});

module.exports = router;
