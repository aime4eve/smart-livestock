const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');

function farmContextMiddleware(req, res, next) {
  // API consumer requests (authenticated via X-API-Key) have no farm context
  if (req.apiConsumer) {
    req.activeFarmTenantId = null;
    return next();
  }

  const headerFarmId = req.headers?.['x-active-farm'];

  if (req.user?.role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    if (headerFarmId && farms.some((farm) => farm.id === headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
    }
  } else if (req.user?.role === 'worker') {
    const assignments = workerFarmStore.findByUserId(req.user.userId);
    const farmIds = assignments.map((assignment) => assignment.farmTenantId);
    if (headerFarmId && farmIds.includes(headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farmIds.length > 0 ? farmIds[0] : null;
    }
  } else {
    req.activeFarmTenantId = null;
  }
  next();
}

module.exports = { farmContextMiddleware };
