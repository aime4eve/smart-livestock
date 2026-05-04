// backend/routes/apiKeyRoutes.js
// API Key management routes for api_consumer developers

const { Router } = require('express');
const apiKeyStore = require('../data/apiKeyStore');

const router = Router();

// GET / — list keys for current api_consumer
router.get('/', (req, res) => {
  const tenantId = req.user.tenantId;
  const keys = apiKeyStore.listByTenantId(tenantId);
  res.ok(keys);
});

// POST / — generate a new key for current api_consumer
router.post('/', (req, res) => {
  const tenantId = req.user.tenantId;
  const result = apiKeyStore.generate(tenantId);
  res.ok({ apiKey: result.apiKey, rawKey: result.rawKey }, 'API Key 已创建');
});

// POST /:id/rotate — rotate keys for the tenant that owns :id
router.post('/:id/rotate', (req, res) => {
  const tenantId = req.user.tenantId;
  const keys = apiKeyStore.listByTenantId(tenantId);
  const owned = keys.find((k) => k.keyId === req.params.id);
  if (!owned) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', 'API Key 不存在');
  }

  const result = apiKeyStore.rotate(tenantId);
  res.ok({ newApiKey: result.newApiKey, rawKey: result.rawKey }, 'API Key 已轮换');
});

module.exports = router;
