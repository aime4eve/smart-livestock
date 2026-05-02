// backend/routes/openApiRoutes.js
// Open API v1 endpoints — apiKeyAuth + rateLimit middleware stack
// Tier model: free (4 endpoints) → growth (+4) → scale (+4)
//
// IMPORTANT: Specific path routes (e.g. /list) MUST be defined before
// parameterized routes (e.g. /:id) to avoid Express param capture.

const { Router } = require('express');
const { apiKeyAuthMiddleware } = require('../middleware/apiKeyAuth');
const { rateLimitMiddleware } = require('../middleware/rateLimit');
const { animals, alerts } = require('../data/seed');
const fenceStore = require('../data/fenceStore');
const {
  feverListItems,
  digestiveListItems,
  estrusListItems,
  epidemicSummary,
} = require('../data/twin_seed');

const router = Router();

// --- Open API middleware stack ---
router.use(apiKeyAuthMiddleware);
router.use(rateLimitMiddleware);

// --- Helpers ---

/**
 * Check if an animal (by livestockId) is accessible to the API consumer.
 * Returns the animal object or null.
 */
function checkAnimalAccess(livestockId, accessibleFarmTenantIds) {
  const animal = animals.find((a) => a.livestockId === livestockId);
  if (!animal || !accessibleFarmTenantIds.includes(animal.farmTenantId)) return null;
  return animal;
}

/**
 * Filter twin list items to only those belonging to accessible farms.
 */
function filterByFarmAccess(items, accessibleFarmTenantIds) {
  return items.filter((item) => {
    const animal = animals.find((a) => a.livestockId === item.livestockId);
    return animal && accessibleFarmTenantIds.includes(animal.farmTenantId);
  });
}

// ============================================================================
// Growth Tier — list endpoints MUST come before their :id counterparts
// ============================================================================

// 5. GET /open/v1/twin/fever/list — fever list (BEFORE /:id to avoid param capture)
router.get('/twin/fever/list', (req, res) => {
  const effectiveTier = req.apiTier || 'free';
  if (effectiveTier === 'free') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Growth 及以上套餐');
  }
  const items = filterByFarmAccess(feverListItems, req.accessibleFarmTenantIds);
  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// 6. GET /open/v1/twin/estrus/list — estrus list (BEFORE /:id to avoid param capture)
router.get('/twin/estrus/list', (req, res) => {
  const effectiveTier = req.apiTier || 'free';
  if (effectiveTier === 'free') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Growth 及以上套餐');
  }
  const items = filterByFarmAccess(estrusListItems, req.accessibleFarmTenantIds);
  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// 7. GET /open/v1/twin/epidemic/summary — epidemic summary
router.get('/twin/epidemic/summary', (req, res) => {
  const effectiveTier = req.apiTier || 'free';
  if (effectiveTier === 'free') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Growth 及以上套餐');
  }
  if (!req.accessibleFarmTenantIds || req.accessibleFarmTenantIds.length === 0) {
    return res.fail(403, 'FORBIDDEN', '无权访问任何牧场数据');
  }
  res.ok(epidemicSummary);
});

// 8. POST /open/v1/twin/health/batch — batch health check
router.post('/twin/health/batch', (req, res) => {
  const effectiveTier = req.apiTier || 'free';
  if (effectiveTier === 'free') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Growth 及以上套餐');
  }
  const { livestockIds } = req.body || {};
  if (!Array.isArray(livestockIds) || livestockIds.length === 0) {
    return res.fail(400, 'BAD_REQUEST', '请提供 livestockIds 数组');
  }
  const results = livestockIds.map((lid) => {
    const animal = animals.find((a) => a.livestockId === lid);
    if (!animal || !req.accessibleFarmTenantIds.includes(animal.farmTenantId)) {
      return { livestockId: lid, error: 'NOT_FOUND', message: '牛只不存在或无权访问' };
    }
    const feverItem = feverListItems.find((x) => x.livestockId === animal.livestockId);
    const digestiveItem = digestiveListItems.find((x) => x.livestockId === animal.livestockId);
    const healthScore =
      feverItem?.status === 'critical' ? 45
      : feverItem?.status === 'warning' ? 70
      : 92;
    return {
      livestockId: lid,
      earTag: animal.earTag,
      breed: animal.breed,
      healthScore,
      feverStatus: feverItem?.status ?? 'normal',
      digestiveStatus: digestiveItem?.status ?? 'normal',
      farmTenantId: animal.farmTenantId,
    };
  });
  res.ok({ items: results, total: results.length });
});

// ============================================================================
// Scale Tier — list endpoints (no :id conflicts here; different method for batch)
// ============================================================================

// 9. GET /open/v1/cattle/list — cattle list
router.get('/cattle/list', (req, res) => {
  if (req.apiTier !== 'scale') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Scale 及以上套餐');
  }
  const items = animals.filter((a) => req.accessibleFarmTenantIds.includes(a.farmTenantId));
  res.ok({ items, page: 1, pageSize: 50, total: items.length });
});

// 10. GET /open/v1/fence/list — fence list
router.get('/fence/list', (req, res) => {
  if (req.apiTier !== 'scale') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Scale 及以上套餐');
  }
  const allFences = fenceStore.getAll();
  // A fence is accessible if it contains animals from an accessible farm
  const accessibleFenceIds = new Set();
  animals
    .filter((a) => req.accessibleFarmTenantIds.includes(a.farmTenantId))
    .forEach((a) => accessibleFenceIds.add(a.fenceId));
  const items = allFences.filter((f) => accessibleFenceIds.has(f.id));
  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// 11. GET /open/v1/alert/list — alert list
router.get('/alert/list', (req, res) => {
  if (req.apiTier !== 'scale') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Scale 及以上套餐');
  }
  const items = alerts.filter((alert) => {
    const animal = animals.find((a) => a.earTag === alert.earTag);
    return animal && req.accessibleFarmTenantIds.includes(animal.farmTenantId);
  });
  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// 12. POST /open/v1/twin/fever/batch — batch fever check
router.post('/twin/fever/batch', (req, res) => {
  if (req.apiTier !== 'scale') {
    return res.fail(403, 'TIER_REQUIRED', '此端点需要 Scale 及以上套餐');
  }
  const { livestockIds } = req.body || {};
  if (!Array.isArray(livestockIds) || livestockIds.length === 0) {
    return res.fail(400, 'BAD_REQUEST', '请提供 livestockIds 数组');
  }
  const results = livestockIds.map((lid) => {
    const item = feverListItems.find((x) => x.livestockId === lid);
    if (!item) return { livestockId: lid, error: 'NOT_FOUND', message: '未找到发热数据' };
    if (!checkAnimalAccess(item.livestockId, req.accessibleFarmTenantIds)) {
      return { livestockId: lid, error: 'NOT_FOUND', message: '牛只不存在或无权访问' };
    }
    const animal = animals.find((a) => a.livestockId === lid);
    return {
      livestockId: lid,
      status: item.status,
      baselineTemp: item.baselineTemp,
      threshold: item.threshold,
      conclusion: item.conclusion,
      farmTenantId: animal.farmTenantId,
    };
  });
  res.ok({ items: results, total: results.length });
});

// ============================================================================
// Free Tier — :id param routes (MUST come AFTER their corresponding /list routes)
// ============================================================================

// 1. GET /open/v1/twin/fever/:id — single cattle fever status
router.get('/twin/fever/:id', (req, res) => {
  const item = feverListItems.find((x) => x.livestockId === req.params.id);
  if (!item) return res.fail(404, 'NOT_FOUND', '未找到该牛只发热数据');
  if (!checkAnimalAccess(item.livestockId, req.accessibleFarmTenantIds)) {
    return res.fail(404, 'NOT_FOUND', '牛只不存在或无权访问');
  }
  res.ok(item);
});

// 2. GET /open/v1/twin/estrus/:id — single cattle estrus score
router.get('/twin/estrus/:id', (req, res) => {
  const item = estrusListItems.find((x) => x.livestockId === req.params.id);
  if (!item) return res.fail(404, 'NOT_FOUND', '未找到该牛只发情数据');
  if (!checkAnimalAccess(item.livestockId, req.accessibleFarmTenantIds)) {
    return res.fail(404, 'NOT_FOUND', '牛只不存在或无权访问');
  }
  res.ok(item);
});

// 3. GET /open/v1/twin/digestive/:id — single cattle digestive status
router.get('/twin/digestive/:id', (req, res) => {
  const item = digestiveListItems.find((x) => x.livestockId === req.params.id);
  if (!item) return res.fail(404, 'NOT_FOUND', '未找到该牛只消化数据');
  if (!checkAnimalAccess(item.livestockId, req.accessibleFarmTenantIds)) {
    return res.fail(404, 'NOT_FOUND', '牛只不存在或无权访问');
  }
  res.ok(item);
});

// 4. GET /open/v1/twin/health/:id — single cattle health score
router.get('/twin/health/:id', (req, res) => {
  const animal = animals.find((a) => a.livestockId === req.params.id);
  if (!animal || !req.accessibleFarmTenantIds.includes(animal.farmTenantId)) {
    return res.fail(404, 'NOT_FOUND', '牛只不存在或无权访问');
  }
  const feverItem = feverListItems.find((x) => x.livestockId === animal.livestockId);
  const digestiveItem = digestiveListItems.find((x) => x.livestockId === animal.livestockId);
  const healthScore =
    feverItem?.status === 'critical' ? 45
    : feverItem?.status === 'warning' ? 70
    : 92;
  res.ok({
    livestockId: animal.livestockId,
    earTag: animal.earTag,
    breed: animal.breed,
    healthScore,
    feverStatus: feverItem?.status ?? 'normal',
    digestiveStatus: digestiveItem?.status ?? 'normal',
    farmTenantId: animal.farmTenantId,
  });
});

// ============================================================================
// Reserved endpoint
// ============================================================================

// 13. POST /open/v1/register — returns 501 Not Implemented
router.post('/register', (req, res) => {
  res.fail(501, 'NOT_IMPLEMENTED', '该端点尚未实现');
});

module.exports = router;
