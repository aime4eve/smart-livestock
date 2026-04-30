const { Router } = require('express');
const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');

const router = Router();

function toFarmSummary(farm) {
  return {
    id: farm.id,
    name: farm.name,
    status: farm.status,
    livestockCount: 0,
    region: farm.region,
  };
}

router.get('/my-farms', (req, res) => {
  const role = req.userRole;
  let farms = [];
  let activeFarmId = req.activeFarmTenantId;

  if (role === 'owner') {
    farms = tenantStore.findByOwnerId(req.user.userId).map(toFarmSummary);
  } else if (role === 'worker') {
    farms = workerFarmStore.findByUserId(req.user.userId).map((assignment) => {
      const farm = tenantStore.findById(assignment.farmTenantId);
      return toFarmSummary({
        id: assignment.farmTenantId,
        name: farm?.name ?? '未知牧场',
        status: farm?.status ?? 'unknown',
        region: farm?.region ?? '',
      });
    });
  } else {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 owner/worker 可查看 farm 列表');
  }

  if (!activeFarmId && farms.length > 0) {
    activeFarmId = farms[0].id;
  }

  return res.ok({ farms, activeFarmId });
});

router.post('/switch-farm', (req, res) => {
  const { farmTenantId } = req.body || {};
  if (!farmTenantId) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少 farmTenantId');
  }

  const role = req.userRole;
  let farm = null;

  if (role === 'owner') {
    farm = tenantStore
      .findByOwnerId(req.user.userId)
      .find((item) => item.id === farmTenantId) ?? null;
  } else if (role === 'worker') {
    const assignment = workerFarmStore
      .findByUserId(req.user.userId)
      .find((item) => item.farmTenantId === farmTenantId);
    farm = assignment ? tenantStore.findById(farmTenantId) : null;
  }

  if (!farm) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权切换到该牧场');
  }

  return res.ok({ activeFarmId: farmTenantId, farmName: farm.name });
});

module.exports = router;
