// 合同内存 Store
// Phase 2b: 完整 CRUD 操作 (create, update, terminate, list, reset)

// Lazy-load tenantStore to avoid circular dependency (P0-2 fix)
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

const _contracts = [
  {
    id: 'contract_001',
    partnerTenantId: 'tenant_p001',
    status: 'active',
    effectiveTier: 'standard',
    revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00',
    expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五',
    createdAt: '2026-01-01T00:00:00+08:00',
    updatedAt: '2026-01-01T00:00:00+08:00',
    terminatedAt: null,
  },
];
let _nextId = 2;

function reset() {
  _contracts.length = 0;
  _contracts.push({
    id: 'contract_001',
    partnerTenantId: 'tenant_p001',
    status: 'active',
    effectiveTier: 'standard',
    revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00',
    expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五',
    createdAt: '2026-01-01T00:00:00+08:00',
    updatedAt: '2026-01-01T00:00:00+08:00',
    terminatedAt: null,
  });
  _nextId = 2;
}

function getById(id) {
  return _contracts.find((c) => c.id === id) ?? null;
}

function getByPartnerTenantId(partnerTenantId) {
  return _contracts.find((c) => c.partnerTenantId === partnerTenantId) ?? null;
}

function create(body) {
  const { partnerTenantId, effectiveTier, revenueShareRatio, expiresAt, signedBy } = body || {};

  // Validate required fields
  if (!partnerTenantId) {
    return { error: 'validation_error', message: 'partnerTenantId is required' };
  }
  if (!effectiveTier) {
    return { error: 'validation_error', message: 'effectiveTier is required' };
  }
  if (revenueShareRatio === undefined || revenueShareRatio === null || typeof revenueShareRatio !== 'number') {
    return { error: 'validation_error', message: 'revenueShareRatio is required and must be a number' };
  }

  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  const id = `contract_${String(_nextId++).padStart(3, '0')}`;

  const contract = {
    id,
    partnerTenantId,
    status: 'active',
    effectiveTier,
    revenueShareRatio,
    startedAt: now,
    expiresAt: expiresAt || null,
    signedBy: signedBy || null,
    createdAt: now,
    updatedAt: now,
    terminatedAt: null,
  };

  _contracts.push(contract);

  // Sync tenantStore fields
  const tenantStore = _getTenantStore();
  tenantStore.updateTenantField(partnerTenantId, 'contractId', id);
  tenantStore.updateTenantField(partnerTenantId, 'revenueShareRatio', revenueShareRatio);

  return { contract };
}

function update(id, body) {
  const contract = _contracts.find((c) => c.id === id);
  if (!contract) return { error: 'not_found' };

  const { effectiveTier, revenueShareRatio, expiresAt, signedBy } = body || {};

  if (effectiveTier !== undefined) contract.effectiveTier = effectiveTier;
  if (expiresAt !== undefined) contract.expiresAt = expiresAt;
  if (signedBy !== undefined) contract.signedBy = signedBy;

  if (revenueShareRatio !== undefined) {
    contract.revenueShareRatio = revenueShareRatio;
    // Sync revenueShareRatio to tenantStore
    const tenantStore = _getTenantStore();
    tenantStore.updateTenantField(contract.partnerTenantId, 'revenueShareRatio', revenueShareRatio);
  }

  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  contract.updatedAt = now;

  return { contract };
}

function terminate(id) {
  const contract = _contracts.find((c) => c.id === id);
  if (!contract) return { error: 'not_found' };

  contract.status = 'expired';
  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  contract.terminatedAt = now;
  contract.updatedAt = now;

  return { contract };
}

function list(query) {
  const { partnerId, status, page: rawPage, pageSize: rawPageSize } = query || {};

  let filtered = _contracts.slice();

  if (partnerId) {
    filtered = filtered.filter((c) => c.partnerTenantId === partnerId);
  }
  if (status) {
    filtered = filtered.filter((c) => c.status === status);
  }

  const page = Math.max(1, parseInt(rawPage, 10) || 1);
  const pageSize = Math.max(1, parseInt(rawPageSize, 10) || 20);
  const total = filtered.length;
  const start = (page - 1) * pageSize;
  const items = filtered.slice(start, start + pageSize);

  return { items, page, pageSize, total };
}

module.exports = { getById, getByPartnerTenantId, create, update, terminate, list, reset };
