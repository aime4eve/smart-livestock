const { Router } = require('express');
const { requirePermission } = require('../middleware/auth');
const { featureKeys } = require('../middleware/feature-flag');
const { animals } = require('../data/seed');
const fenceStore = require('../data/fenceStore');
const { boundaryStatusForPoint } = require('../utils/geo');

const router = Router();

router.get(
  '/trajectories',
  requirePermission('map:view'),
  featureKeys('gps_location', 'trajectory'),
  (req, res) => {
    const { animalId, range } = req.query;

    if (!range || !['24h', '7d', '30d'].includes(range)) {
      return res.fail(422, 'VALIDATION_ERROR', 'range 必须为 24h / 7d / 30d');
    }

    const selected = animals.find((a) => a.id === animalId) || animals[0];

    const now = new Date('2026-04-08T10:00:00Z');
    const rangeMs = { '24h': 86400000, '7d': 604800000, '30d': 2592000000 }[range];
    const since = new Date(now.getTime() - rangeMs);

    const points = generateTrajectory(selected, since, now);

    const fenceList = fenceStore.getAll();
    const animalsOut = animals.map((a) => {
      const boundaryStatus = boundaryStatusForPoint(fenceList, a.lng, a.lat);
      return {
        id: a.id,
        earTag: a.earTag,
        lat: a.lat,
        lng: a.lng,
        fenceId: a.fenceId,
        boundaryStatus,
      };
    });

    res.ok({
      animals: animalsOut,
      selectedAnimalId: selected.id,
      selectedRange: range,
      summaryText: `${selected.earTag} · ${range}`,
      points,
      fences: fenceList,
      fallbackList: animals.slice(0, 5).map((a) => ({ label: `${a.earTag} · 最近点` })),
    });
  },
);

function generateTrajectory(animal, start, end) {
  const points = [];
  let lat = animal.lat;
  let lng = animal.lng;
  let seed = 42 + (animal.earTag || '').length;
  function rand() {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  }

  const t = new Date(start);
  while (t < end) {
    const hour = t.getUTCHours();
    const step = hour >= 6 && hour < 18 ? 0.0003 : 0.00005;
    lat += (rand() - 0.5) * step * 2;
    lng += (rand() - 0.5) * step * 2;
    points.push({ lat: +lat.toFixed(4), lng: +lng.toFixed(4), ts: t.toISOString() });
    t.setTime(t.getTime() + 3600000);
  }
  return points;
}

module.exports = router;
