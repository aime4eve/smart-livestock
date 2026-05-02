// backend/data/apiAuthorizationStore.js
// Manage API data access authorization — api_consumer developers request access to farm data,
// and platform_admin/owners approve or reject.

// Lazy-load tenantStore to avoid circular dependency
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

let _authorizations = [];
let _nextId = 1;

function _now() {
  return new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

/**
 * Reset all authorizations. Used for test isolation.
 */
function reset() {
  _authorizations = [];
  _nextId = 1;
}

/**
 * Create a new pending authorization record.
 *
 * @param {Object} body
 * @param {string} body.apiTenantId  - Required. The api_consumer tenant requesting access.
 * @param {string} body.farmTenantId - Required. The farm tenant to access.
 * @param {string} [body.requestedBy] - Optional. User id of the requester.
 * @param {string} [body.reason]      - Optional. Reason for the request.
 * @returns {{ authorization: Object }} or {{ error: string }}
 */
function create(body) {
  const { apiTenantId, farmTenantId, requestedBy, reason } = body || {};

  if (!apiTenantId || !farmTenantId) {
    return { error: 'validation_error' };
  }

  const now = _now();
  const id = 'auth_' + String(_nextId++).padStart(3, '0');

  const authorization = {
    id,
    apiTenantId,
    farmTenantId,
    status: 'pending',
    requestedBy: requestedBy || null,
    reviewedBy: null,
    reviewedAt: null,
    reason: reason || null,
    createdAt: now,
    updatedAt: now,
  };

  _authorizations.push(authorization);
  return { authorization };
}

/**
 * Approve a pending authorization.
 * Appends farmTenantId to the api consumer tenant's accessibleFarmTenantIds.
 *
 * @param {string} id         - Authorization record id.
 * @param {string} reviewedBy - User id of the reviewer.
 * @returns {{ authorization: Object }} or {{ error: string }}
 */
function approve(id, reviewedBy) {
  const auth = _authorizations.find((a) => a.id === id);
  if (!auth) return { error: 'not_found' };

  const now = _now();
  auth.status = 'approved';
  auth.reviewedBy = reviewedBy || null;
  auth.reviewedAt = now;
  auth.updatedAt = now;

  // CRITICAL: Append farmTenantId to the api consumer tenant's accessibleFarmTenantIds
  const tenantStore = _getTenantStore();
  const tenant = tenantStore.findById(auth.apiTenantId);
  if (tenant) {
    const currentIds = tenant.accessibleFarmTenantIds ?? [];
    if (!currentIds.includes(auth.farmTenantId)) {
      tenantStore.updateTenantField(auth.apiTenantId, 'accessibleFarmTenantIds', [...currentIds, auth.farmTenantId]);
    }
  }

  return { authorization: auth };
}

/**
 * Reject a pending authorization.
 *
 * @param {string} id         - Authorization record id.
 * @param {string} reviewedBy - User id of the reviewer.
 * @returns {{ authorization: Object }} or {{ error: string }}
 */
function reject(id, reviewedBy) {
  const auth = _authorizations.find((a) => a.id === id);
  if (!auth) return { error: 'not_found' };

  const now = _now();
  auth.status = 'rejected';
  auth.reviewedBy = reviewedBy || null;
  auth.reviewedAt = now;
  auth.updatedAt = now;

  return { authorization: auth };
}

/**
 * Revoke an approved authorization.
 * Removes farmTenantId from the api consumer tenant's accessibleFarmTenantIds.
 *
 * @param {string} id - Authorization record id.
 * @returns {{ authorization: Object }} or {{ error: string }}
 */
function revoke(id) {
  const auth = _authorizations.find((a) => a.id === id);
  if (!auth) return { error: 'not_found' };

  const now = _now();
  auth.status = 'revoked';
  auth.updatedAt = now;

  // Remove farmTenantId from tenant's accessibleFarmTenantIds
  const tenantStore = _getTenantStore();
  const tenant = tenantStore.findById(auth.apiTenantId);
  if (tenant) {
    const currentIds = tenant.accessibleFarmTenantIds ?? [];
    const filtered = currentIds.filter((tid) => tid !== auth.farmTenantId);
    if (filtered.length !== currentIds.length) {
      tenantStore.updateTenantField(auth.apiTenantId, 'accessibleFarmTenantIds', filtered);
    }
  }

  return { authorization: auth };
}

/**
 * List authorization records with optional filters and pagination.
 *
 * @param {Object} query
 * @param {string} [query.apiTenantId]  - Filter by api consumer tenant id.
 * @param {string} [query.farmTenantId] - Filter by farm tenant id.
 * @param {string} [query.status]       - Filter by status (pending/approved/rejected/revoked).
 * @param {string} [query.page]         - Page number (default 1).
 * @param {string} [query.pageSize]     - Items per page (default 20).
 * @returns {{ items: Array, page: number, pageSize: number, total: number }}
 */
function list(query) {
  const {
    apiTenantId,
    farmTenantId,
    status,
    page = '1',
    pageSize = '20',
  } = query || {};

  let filtered = _authorizations.slice();

  if (apiTenantId) {
    filtered = filtered.filter((a) => a.apiTenantId === apiTenantId);
  }
  if (farmTenantId) {
    filtered = filtered.filter((a) => a.farmTenantId === farmTenantId);
  }
  if (status) {
    filtered = filtered.filter((a) => a.status === status);
  }

  const p = Math.max(1, parseInt(page, 10) || 1);
  const ps = Math.max(1, parseInt(pageSize, 10) || 20);
  const total = filtered.length;
  const start = (p - 1) * ps;
  const items = filtered.slice(start, start + ps);

  return { items, page: p, pageSize: ps, total };
}

module.exports = {
  create,
  approve,
  reject,
  revoke,
  list,
  reset,
};
