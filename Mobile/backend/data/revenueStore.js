// 结算分润 Store
// Phase 2b: 分润结算引擎，遍历合作方租户计算设备费用和分润金额

// P1-8 Fix — Device Unit Price Constants
const DEVICE_UNIT_PRICES = {
  GPS_PER_CATTLE: 15,
  CAPSULE_PER_CATTLE: 30,
};

// Lazy-load tenantStore and contractStore to avoid circular deps
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

let _contractStore = null;
function _getContractStore() {
  if (!_contractStore) _contractStore = require('./contractStore');
  return _contractStore;
}

let _periods = [];

function _timestamp() {
  return new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

/**
 * Calculate settlement periods for a given month.
 * mode='monthly' only (realtime not implemented).
 * Returns array of created RevenuePeriod objects.
 */
function calculate(period, mode = 'monthly') {
  if (mode !== 'monthly') {
    return []; // realtime not implemented
  }

  const tenantStore = _getTenantStore();
  const contractStore = _getContractStore();

  // Get all partner tenants
  const allTenants = tenantStore.getAll();
  const partnerTenants = allTenants.filter((t) => t.type === 'partner');

  const createdPeriods = [];

  for (const partner of partnerTenants) {
    // Only include partners with a contract
    const contract = contractStore.getByPartnerTenantId(partner.id);
    if (!contract || contract.status !== 'active') continue;

    // Find farm tenants belonging to this partner
    const farmTenants = allTenants.filter(
      (t) => t.type === 'farm' && t.parentTenantId === partner.id && t.status === 'active'
    );

    if (farmTenants.length === 0) continue;

    // Period ID: period_YYYYMM (strip hyphens from input like '2026-05')
    const normalizedPeriod = period.replace(/-/g, '');
    const periodId = `period_${normalizedPeriod}`;

    // Check if period already exists for this partner — skip duplicate
    const existing = _periods.find(
      (p) => p.id === periodId && p.partnerTenantId === partner.id
    );
    if (existing) continue;

    // Calculate farm details
    const farmDetails = farmTenants.map((farm) => {
      const { livestockCount, deviceConfigRatio } = farm;
      const gpsRatio = (deviceConfigRatio && deviceConfigRatio.gpsRatio) || 0;
      const capsuleRatio = (deviceConfigRatio && deviceConfigRatio.capsuleRatio) || 0;
      const count = livestockCount || 0;

      const gpsFee = +(count * gpsRatio * DEVICE_UNIT_PRICES.GPS_PER_CATTLE).toFixed(2);
      const capsuleFee = +(count * capsuleRatio * DEVICE_UNIT_PRICES.CAPSULE_PER_CATTLE).toFixed(2);
      const deviceFee = +(gpsFee + capsuleFee).toFixed(2);

      return {
        farmTenantId: farm.id,
        farmName: farm.name,
        livestockCount: count,
        deviceConfigRatio: { gpsRatio, capsuleRatio },
        gpsFee,
        capsuleFee,
        deviceFee,
      };
    });

    const totalDeviceFee = +(farmDetails.reduce((sum, f) => sum + f.deviceFee, 0)).toFixed(2);
    const revenueShareAmount = +(totalDeviceFee * contract.revenueShareRatio).toFixed(2);

    const now = _timestamp();

    const periodRecord = {
      id: periodId,
      period,
      status: 'pending',
      partnerTenantId: partner.id,
      contractId: contract.id,
      revenueShareRatio: contract.revenueShareRatio,
      billingModel: partner.billingModel,
      farmDetails,
      totalDeviceFee,
      revenueShareAmount,
      confirmedByPlatform: false,
      confirmedByPartner: false,
      confirmedByPlatformAt: null,
      confirmedByPartnerAt: null,
      settledAt: null,
      createdAt: now,
    };

    _periods.push(periodRecord);
    createdPeriods.push(periodRecord);
  }

  return createdPeriods;
}

/**
 * Get paginated list of settlement periods with optional filtering.
 */
function getPeriods(query) {
  const { partnerTenantId, page: rawPage, pageSize: rawPageSize } = query || {};

  let filtered = _periods.slice();

  if (partnerTenantId) {
    filtered = filtered.filter((p) => p.partnerTenantId === partnerTenantId);
  }

  const page = Math.max(1, parseInt(rawPage, 10) || 1);
  const pageSize = Math.max(1, parseInt(rawPageSize, 10) || 20);
  const total = filtered.length;
  const start = (page - 1) * pageSize;
  const items = filtered.slice(start, start + pageSize);

  return { items, page, pageSize, total };
}

/**
 * Get a single settlement period by ID, or null.
 */
function getPeriod(id) {
  return _periods.find((p) => p.id === id) ?? null;
}

/**
 * Confirm a settlement period.
 * platform_admin → confirmedByPlatform
 * b2b_admin with matching tenantId → confirmedByPartner
 * When both are confirmed → status transitions to 'settled'
 */
function confirm(id, role, tenantId) {
  const period = _periods.find((p) => p.id === id);
  if (!period) return { error: 'not_found' };

  const now = _timestamp();

  if (role === 'platform_admin') {
    period.confirmedByPlatform = true;
    period.confirmedByPlatformAt = now;
  } else if (role === 'b2b_admin') {
    if (tenantId !== period.partnerTenantId) {
      return { error: 'forbidden' };
    }
    period.confirmedByPartner = true;
    period.confirmedByPartnerAt = now;
  }

  // Check if both confirmed → settled
  if (period.confirmedByPlatform && period.confirmedByPartner) {
    period.status = 'settled';
    period.settledAt = now;
  }

  return { period };
}

/**
 * Reset all periods (P2-13).
 */
function reset() {
  _periods.length = 0;
}

module.exports = { calculate, getPeriods, getPeriod, confirm, reset };
