let assignments = [
  {
    id: 'wfa_001',
    userId: 'u_002',
    farmTenantId: 'tenant_001',
    role: 'worker',
    assignedAt: '2026-04-28T00:00:00+08:00',
  },
  {
    id: 'wfa_002',
    userId: 'u_002',
    farmTenantId: 'tenant_007',
    role: 'worker',
    assignedAt: '2026-04-29T00:00:00+08:00',
  },
];
let nextId = assignments.length + 1;

function findByUserId(userId) {
  return assignments.filter((a) => a.userId === userId);
}

function findByFarmId(farmTenantId) {
  return assignments.filter((a) => a.farmTenantId === farmTenantId);
}

function assign(userId, farmTenantId, role = 'worker') {
  if (assignments.some((a) => a.userId === userId && a.farmTenantId === farmTenantId)) {
    return null;
  }
  const assignedAt = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  const assignment = {
    id: `wfa_${String(nextId++).padStart(3, '0')}`,
    userId,
    farmTenantId,
    role,
    assignedAt,
  };
  assignments.push(assignment);
  return assignment;
}

function unassign(id) {
  const idx = assignments.findIndex((a) => a.id === id);
  if (idx === -1) {
    return false;
  }
  assignments.splice(idx, 1);
  return true;
}

module.exports = {
  findByUserId,
  findByFarmId,
  assign,
  unassign,
};
