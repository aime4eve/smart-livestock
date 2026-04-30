const { Router } = require('express');
const router = Router();

const tenantStore = require('../data/tenantStore');
const contractStore = require('../data/contractStore');
const { users } = require('../data/seed');
const { registerMockUserToken } = require('../middleware/auth');

function requireB2bAdmin(req, res, next) {
  if (req.userRole !== 'b2b_admin') {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 B端客户可访问');
  }
  next();
}

router.use(requireB2bAdmin);

// GET /b2b/dashboard — 用量看板
router.get('/dashboard', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const farms = tenantStore.findByParentTenantId(partnerTenantId);

  const farmsWithStats = farms.map((f) => ({
    id: f.id,
    name: f.name,
    livestockCount: 120,
    deviceCount: 95,
    pendingAlerts: 5,
  }));

  const contract = contractStore.getByPartnerTenantId(partnerTenantId);

  res.ok({
    totalFarms: farms.length,
    totalLivestock: farmsWithStats.reduce((sum, f) => sum + f.livestockCount, 0),
    totalDevices: farmsWithStats.reduce((sum, f) => sum + f.deviceCount, 0),
    pendingAlerts: farmsWithStats.reduce((sum, f) => sum + f.pendingAlerts, 0),
    farms: farmsWithStats,
    contractStatus: contract?.status ?? null,
    contractExpiresAt: contract?.expiresAt ?? null,
  });
});

// GET /b2b/farms — 旗下 farm 列表
router.get('/farms', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const { search } = req.query;
  let farms = tenantStore.findByParentTenantId(partnerTenantId);

  if (search) {
    farms = farms.filter((f) => f.name.includes(search));
  }

  const items = farms.map((f) => ({
    id: f.id,
    name: f.name,
    status: f.status,
    ownerName: f.contactName ?? '',
    livestockCount: 120,
    region: f.region ?? '',
    createdAt: f.createdAt,
  }));

  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// POST /b2b/farms — 创建子 farm
router.post('/farms', (req, res) => {
  const { name, ownerName, contactPhone, region } = req.body;
  if (!name) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少牧场名称');
  }

  const partnerTenantId = req.user.tenantId;
  const partner = tenantStore.findById(partnerTenantId);
  const ownerId = ownerName ? `u_${Date.now()}` : null;

  const result = tenantStore.createTenant({
    name,
    type: 'farm',
    parentTenantId: partnerTenantId,
    billingModel: partner?.billingModel ?? 'revenue_share',
    entitlementTier: null,
    ownerId,
    status: 'active',
    contactName: ownerName ?? '',
    contactPhone: contactPhone ?? '',
    region: region ?? '',
  });

  if (result.error) {
    if (result.error === 'name_conflict') {
      return res.fail(409, 'CONFLICT', '牧场名称已存在');
    }
    return res.fail(400, 'VALIDATION_ERROR', result.error);
  }

  const farm = result.tenant;
  let ownerToken = null;

  if (ownerId && ownerName) {
    const ownerUser = {
      userId: ownerId,
      tenantId: farm.id,
      name: ownerName,
      role: 'owner',
      mobile: contactPhone ?? '',
      permissions: [...users.owner.permissions],
    };
    ownerToken = `mock-token-${ownerId}`;
    registerMockUserToken(ownerToken, ownerUser);
  }

  res.ok({
    ...farm,
    ...(ownerToken ? { ownerToken } : {}),
  });
});

// GET /b2b/contract/current — 合同信息
router.get('/contract/current', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const contract = contractStore.getByPartnerTenantId(partnerTenantId);
  res.ok(contract);
});

// GET /b2b/contract/usage-summary — 用量汇总
router.get('/contract/usage-summary', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const farms = tenantStore.findByParentTenantId(partnerTenantId);

  res.ok({
    totalFarms: farms.length,
    totalLivestock: farms.length * 120,
    totalDevices: farms.length * 95,
    monthlyBreakdown: [
      { month: '2026-03', livestockCount: 200, deviceCount: 150 },
      { month: '2026-04', livestockCount: farms.length * 120, deviceCount: farms.length * 95 },
    ],
  });
});

module.exports = router;
