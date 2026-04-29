const tenantStore = require('../data/tenantStore');

function farmContextMiddleware(req, res, next) {
  if (req.user?.role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
  } else if (req.user?.role === 'worker') {
    req.activeFarmTenantId = req.user.tenantId ?? null;
  } else {
    // platform_admin, b2b_admin, api_consumer — no farm context
    req.activeFarmTenantId = null;
  }
  next();
}

module.exports = { farmContextMiddleware };
