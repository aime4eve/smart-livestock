const { Router } = require('express');
const router = Router();

const tenantStore = require('../data/tenantStore');
const contractStore = require('../data/contractStore');
const workerFarmStore = require('../data/workerFarmStore');
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
  const partner = tenantStore.findById(partnerTenantId);
  const farms = tenantStore.findByParentTenantId(partnerTenantId);

  const farmsWithStats = farms.map((f) => {
    const workerCount = workerFarmStore.findByFarmId(f.id).length;
    // Estimate devices: livestock × gpsRatio (GPS tracker is primary device)
    const livestock = f.livestockCount ?? 0;
    const gpsRatio = f.deviceConfigRatio?.gpsRatio ?? 0.8;
    const deviceCount = Math.round(livestock * gpsRatio);
    return {
      id: f.id,
      name: f.name,
      status: f.status ?? 'active',
      ownerName: f.contactName ?? '',
      livestockCount: livestock,
      region: f.region ?? '',
      deviceCount,
      workerCount,
    };
  });

  const contract = contractStore.getByPartnerTenantId(partnerTenantId);

  const totalLivestock = farmsWithStats.reduce((sum, f) => sum + f.livestockCount, 0);
  const totalDevices = farmsWithStats.reduce((sum, f) => sum + f.deviceCount, 0);
  const totalWorkers = farmsWithStats.reduce((sum, f) => sum + f.workerCount, 0);

  // Revenue calculation: devices × unit price × share ratio
  const unitPrice = 19.5;
  const shareRatio = contract?.revenueShareRatio ?? partner?.revenueShareRatio ?? 0.15;
  const monthlyRevenue = totalDevices * unitPrice * shareRatio;

  const deviceOnlineRate = totalDevices > 0 ? 0.65 : 0;

  res.ok({
    totalFarms: farms.length,
    totalLivestock,
    totalDevices,
    totalWorkers,
    pendingAlerts: 5,
    monthlyRevenue: Math.round(monthlyRevenue * 100) / 100,
    deviceOnlineRate,
    partnerName: partner?.name ?? req.user.name ?? '',
    billingModel: partner?.billingModel ?? 'revenue_share',
    alertSummary: [
      { farmName: farmsWithStats[0]?.name ?? '', type: 'fence', message: '围栏越界告警', createdAt: '2026-05-03T08:30:00+08:00' },
      { farmName: farmsWithStats[0]?.name ?? '', type: 'health', message: '瘤胃温度异常', createdAt: '2026-05-03T07:15:00+08:00' },
      { farmName: farmsWithStats[0]?.name ?? '', type: 'device', message: 'GPS 设备离线', createdAt: '2026-05-02T22:00:00+08:00' },
    ],
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
  const partner = tenantStore.findById(partnerTenantId);

  if (!contract) {
    return res.ok(null);
  }

  res.ok({
    ...contract,
    partnerName: partner?.name ?? req.user.name ?? '',
    partnerTenantId,
    contractId: contract.id,
    billingModel: partner?.billingModel ?? 'revenue_share',
    deploymentType: partner?.deploymentType ?? 'cloud',
    subscriptionService: null,
  });
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
