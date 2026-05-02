// backend/middleware/apiKeyAuth.js
// Open API authentication — validates X-API-Key header

const apiKeyStore = require('../data/apiKeyStore');
const tenantStore = require('../data/tenantStore');

function apiKeyAuthMiddleware(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey) return res.fail(401, 'AUTH_REQUIRED', '缺少 API Key');

  const result = apiKeyStore.validate(apiKey);
  if (!result) return res.fail(401, 'AUTH_INVALID', 'API Key 无效');

  req.apiConsumer = { tenantId: result.apiTenantId, tier: result.apiTier };
  req.apiTier = result.apiTier;

  // inject accessibleFarmTenantIds from tenantStore
  const tenant = tenantStore.findById(result.apiTenantId);
  req.accessibleFarmTenantIds = tenant?.accessibleFarmTenantIds ?? [];

  next();
}

module.exports = { apiKeyAuthMiddleware };
