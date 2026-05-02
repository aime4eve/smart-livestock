const { Router } = require('express');
const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');
const { users } = require('../data/seed');

const router = Router();

function canManageFarm(req, farmId) {
  if (req.userRole === 'platform_admin') {
    return true;
  }
  if (req.userRole === 'b2b_admin') {
    const farm = tenantStore.findById(farmId);
    return farm?.parentTenantId === req.user.tenantId;
  }
  if (req.userRole !== 'owner') {
    return false;
  }
  const farm = tenantStore.findById(farmId);
  return farm?.ownerId === req.user.userId;
}

function findUserName(userId) {
  const user = Object.values(users).find((item) => item.userId === userId);
  return user?.name ?? userId;
}

function toWorkerItem(assignment) {
  return {
    id: assignment.id,
    userId: assignment.userId,
    userName: findUserName(assignment.userId),
    role: assignment.role,
    assignedAt: assignment.assignedAt,
  };
}

router.get('/:farmId/workers', (req, res) => {
  const { farmId } = req.params;
  if (!canManageFarm(req, farmId)) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权访问该牧场牧工');
  }

  const items = workerFarmStore.findByFarmId(farmId).map(toWorkerItem);
  return res.ok({ items, total: items.length });
});

router.post('/:farmId/workers', (req, res) => {
  const { farmId } = req.params;
  if (!canManageFarm(req, farmId)) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权管理该牧场牧工');
  }

  const { userId, role = 'worker' } = req.body || {};
  if (!userId) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少 userId');
  }

  const assignment = workerFarmStore.assign(userId, farmId, role);
  if (!assignment) {
    return res.fail(409, 'CONFLICT', '牧工已分配到该牧场');
  }

  return res.ok(assignment);
});

router.delete('/:farmId/workers/:id', (req, res) => {
  const { farmId, id } = req.params;
  if (!canManageFarm(req, farmId)) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权管理该牧场牧工');
  }

  const assignment = workerFarmStore.findByFarmId(farmId).find((item) => item.id === id);
  if (!assignment) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '牧工分配不存在');
  }

  workerFarmStore.unassign(id);
  return res.ok({ removed: true });
});

module.exports = router;
