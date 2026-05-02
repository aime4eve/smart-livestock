const { tenants: seedTenants } = require('./seed');

const ALLOWED_STATUS = ['active', 'disabled'];
let tenants = seedTenants.map((t) => ({ ...t }));
let nextId = tenants.length + 1;

function reset() {
  tenants = seedTenants.map((t) => ({ ...t }));
  nextId = tenants.length + 1;
}

function getAll() {
  return tenants;
}

function findById(id) {
  return tenants.find((t) => t.id === id);
}

function findByOwnerId(ownerId) {
  return tenants.filter((t) => t.ownerId === ownerId);
}

function findByParentTenantId(parentTenantId) {
  return tenants.filter((t) => t.parentTenantId === parentTenantId);
}

function nameExists(name, excludeId) {
  return tenants.some((t) => t.name === name && t.id !== excludeId);
}

function sliceForPage(query) {
  const {
    page = '1',
    pageSize = '20',
    status,
    type,
    parentTenantId,
    search,
    sort = 'name',
    order = 'asc',
  } = query || {};
  const ALLOWED_TYPES = ['partner', 'farm', 'api'];
  let filtered = tenants.slice();

  if (status && ALLOWED_STATUS.includes(status)) {
    filtered = filtered.filter((t) => t.status === status);
  }
  if (type && ALLOWED_TYPES.includes(type)) {
    filtered = filtered.filter((t) => t.type === type);
  }
  if (parentTenantId) {
    filtered = filtered.filter((t) => t.parentTenantId === parentTenantId);
  }
  if (search && typeof search === 'string' && search.trim() !== '') {
    const kw = search.toLowerCase();
    filtered = filtered.filter((t) => t.name.toLowerCase().includes(kw));
  }

  const sortKey = sort === 'licenseUsage' ? 'licenseUsage' : 'name';
  const dir = order === 'desc' ? -1 : 1;
  filtered.sort((a, b) => {
    const va = sortKey === 'licenseUsage'
      ? (a.licenseTotal === 0 ? 0 : a.licenseUsed / a.licenseTotal)
      : a.name;
    const vb = sortKey === 'licenseUsage'
      ? (b.licenseTotal === 0 ? 0 : b.licenseUsed / b.licenseTotal)
      : b.name;
    if (va < vb) return -1 * dir;
    if (va > vb) return 1 * dir;
    return 0;
  });

  const p = Math.max(1, parseInt(page, 10) || 1);
  const ps = Math.max(1, parseInt(pageSize, 10) || 20);
  const total = filtered.length;
  const start = (p - 1) * ps;
  const items = filtered.slice(start, start + ps);
  return { items, page: p, pageSize: ps, total };
}

function createTenant(body) {
  const {
    name: rawName,
    licenseTotal = 100,
    contactName,
    contactPhone,
    contactEmail,
    region,
    remarks,
    type = 'farm',
    parentTenantId = null,
    billingModel = 'direct',
    entitlementTier = 'basic',
    ownerId = null,
    contractId = null, revenueShareRatio = null, deploymentType = null,
    serviceKey = null, heartbeatAt = null, apiTier = null, apiKey = null,
    apiCallQuota = null, accessibleFarmTenantIds = null,
    deviceConfigRatio = null, livestockCount = null,
  } = body || {};
  const name = typeof rawName === 'string' ? rawName.trim() : rawName;
  if (!name) return { error: 'name_required' };
  if (typeof licenseTotal !== 'number' || licenseTotal < 0) {
    return { error: 'license_invalid' };
  }
  if (nameExists(name)) return { error: 'name_conflict' };
  // ownerId 非唯一：同一 owner 可拥有多个 farm（Phase 2a 确认）
  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  const tenant = {
    id: `tenant_${String(nextId++).padStart(3, '0')}`,
    name,
    type,
    parentTenantId,
    billingModel,
    entitlementTier,
    ownerId,
    status: 'active',
    licenseUsed: 0,
    licenseTotal,
    contactName: contactName ?? null,
    contactPhone: contactPhone ?? null,
    contactEmail: contactEmail ?? null,
    region: region ?? null,
    remarks: remarks ?? null,
    createdAt: now,
    updatedAt: now,
    lastUpdatedBy: '平台管理员',
    contractId,
    revenueShareRatio,
    deploymentType,
    serviceKey,
    heartbeatAt,
    apiTier,
    apiKey,
    apiCallQuota,
    accessibleFarmTenantIds,
    deviceConfigRatio,
    livestockCount,
  };
  tenants.push(tenant);
  return { tenant };
}

function updateTenant(id, body) {
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  const { name: rawName, contactName, contactPhone, contactEmail, region, remarks } = body || {};
  if (rawName !== undefined) {
    const name = typeof rawName === 'string' ? rawName.trim() : rawName;
    if (!name) return { error: 'name_required' };
    if (nameExists(name, id)) return { error: 'name_conflict' };
    tenant.name = name;
  }
  if (contactName !== undefined) tenant.contactName = contactName ?? null;
  if (contactPhone !== undefined) tenant.contactPhone = contactPhone ?? null;
  if (contactEmail !== undefined) tenant.contactEmail = contactEmail ?? null;
  if (region !== undefined) tenant.region = region ?? null;
  if (remarks !== undefined) tenant.remarks = remarks ?? null;
  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  tenant.updatedAt = now;
  tenant.lastUpdatedBy = '平台管理员';
  return { tenant };
}

function toggleStatus(id, status) {
  if (!ALLOWED_STATUS.includes(status)) return { error: 'status_invalid' };
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  tenant.status = status;
  return { tenant };
}

function adjustLicense(id, licenseTotal) {
  if (typeof licenseTotal !== 'number' || licenseTotal < 0) {
    return { error: 'license_invalid' };
  }
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  if (licenseTotal < tenant.licenseUsed) {
    return { error: 'license_below_used' };
  }
  tenant.licenseTotal = licenseTotal;
  return { tenant };
}

function removeTenant(id) {
  const idx = tenants.findIndex((t) => t.id === id);
  if (idx === -1) return { error: 'not_found' };
  const [removed] = tenants.splice(idx, 1);
  return { removed };
}

function findByServiceKey(keyHash) {
  return tenants.find((t) => t.serviceKey === keyHash) || null;
}

function findByApiKey(keyHash) {
  return tenants.find((t) => t.apiKey === keyHash) || null;
}

function updateTenantField(id, field, value) {
  const SYNCABLE_FIELDS = ['contractId', 'revenueShareRatio', 'deploymentType', 'serviceKey',
    'heartbeatAt', 'apiTier', 'apiKey', 'apiCallQuota', 'accessibleFarmTenantIds',
    'deviceConfigRatio', 'livestockCount'];
  const tenant = findById(id);
  if (!tenant) return { error: 'not_found' };
  if (!SYNCABLE_FIELDS.includes(field)) return { error: 'field_not_allowed' };
  tenant[field] = value;
  const now = new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
  tenant.updatedAt = now;
  return { tenant };
}

module.exports = {
  getAll,
  findById,
  findByOwnerId,
  findByParentTenantId,
  sliceForPage,
  createTenant,
  updateTenant,
  toggleStatus,
  adjustLicense,
  removeTenant,
  reset,
  findByServiceKey,
  findByApiKey,
  updateTenantField,
};
