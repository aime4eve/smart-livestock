const { tenants } = require('../data/seed');

function buildUserProjection(user) {
  const tenant = tenants.find((item) => item.id === user.tenantId);
  return {
    userId: user.userId,
    tenantId: user.tenantId,
    name: user.name,
    role: user.role,
    mobile: user.mobile,
    permissions: user.permissions,
    tenantName: tenant ? tenant.name : null,
    notificationEnabled: true,
  };
}

module.exports = { buildUserProjection };
