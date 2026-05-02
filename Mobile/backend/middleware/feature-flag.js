const { getEffectiveTier } = require('../services/tierService');
const { applyShapingRules } = require('../data/feature-flags');

/**
 * Apply apiTier-based response shaping.
 * Phase 2b: pass-through (no filtering), architectural preparation for future
 * tier-specific response shaping on Open API endpoints.
 */
function applyApiTierShaping(data, apiTier) {
  // Tier-based endpoint filtering is done in route handlers themselves.
  // This is a hook for future per-tier response field filtering.
  return data;
}

function shapingMiddleware(req, res, next) {
  const originalOk = res.ok.bind(res);

  res.ok = function(data, message) {
    // Open API: use apiTier for feature gating
    if (req.apiTier) {
      const shaped = applyApiTierShaping(data, req.apiTier);
      return originalOk(shaped, message);
    }

    const farmTenantId = req.activeFarmTenantId;
    // platform_admin / b2b_admin / api_consumer 无 farm context，直接跳过 shaping
    if (!farmTenantId) return originalOk(data, message);

    const tier = getEffectiveTier(farmTenantId);
    const featureKeys = req.routeFeatureKeys ?? [];

    let shaped = { ...data };
    if (featureKeys.length > 0) {
      shaped = applyShapingRules(shaped, tier, featureKeys);
    }

    return originalOk(shaped, message);
  };

  next();
}

// 辅助中间件：设置当前路由的 feature keys
function featureKeys(...keys) {
  return (req, res, next) => {
    req.routeFeatureKeys = keys;
    next();
  };
}

module.exports = { shapingMiddleware, featureKeys };
