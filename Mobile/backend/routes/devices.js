const { Router } = require('express');
const { devices } = require('../data/seed');
const { requirePermission } = require('../middleware/auth');

const router = Router();

router.get(
  '/',
  requirePermission('dashboard:view'),
  (req, res) => {
    res.ok({
      items: devices,
      page: 1,
      pageSize: devices.length,
      total: devices.length,
    });
  },
);

module.exports = router;
