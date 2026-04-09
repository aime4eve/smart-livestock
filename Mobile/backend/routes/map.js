const { Router } = require('express');
const { authMiddleware, requirePermission } = require('../middleware/auth');
const { animals, trajectoryPoints, fences } = require('../data/seed');

const router = Router();

/**
 * GET /api/map/trajectories?animalId=&range=
 */
router.get(
  '/trajectories',
  authMiddleware,
  requirePermission('map:view'),
  (req, res) => {
    const { animalId, range } = req.query;

    if (!range || !['24h', '7d', '30d'].includes(range)) {
      return res.fail(422, 'VALIDATION_ERROR', 'range 必须为 24h / 7d / 30d');
    }

    const selected = animals.find((a) => a.id === animalId) || animals[0];

    res.ok({
      animals,
      selectedAnimalId: selected.id,
      selectedRange: range,
      summaryText: `${selected.earTag} · ${range}`,
      points: trajectoryPoints,
      fences,
      fallbackList: animals.map((a) => ({
        label: `${a.earTag} · 最近点`,
      })),
    });
  }
);

module.exports = router;
