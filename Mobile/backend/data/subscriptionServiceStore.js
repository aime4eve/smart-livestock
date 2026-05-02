// License 订阅服务内存 Store
// Phase 2b: 管理 licensed (on-premise) 合作伙伴的订阅服务
// 每个服务有唯一 serviceKey (SL-SUB-XXXX 格式)，使用 SHA-256 哈希存储
// 实现心跳感知的状态机：active → grace_period → degraded → revoked

const crypto = require('crypto');

// Lazy-load tenantStore to avoid circular dependencies
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

const _services = [];
let _nextId = 1;

function _timestamp() {
  return new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

function _generateServiceKey() {
  const seg1 = crypto.randomBytes(2).toString('hex').toUpperCase();
  const seg2 = crypto.randomBytes(2).toString('hex').toUpperCase();
  return `SL-SUB-${seg1}-${seg2}`;
}

function _hashKey(raw) {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function _findById(id) {
  return _services.find((s) => s.id === id) || null;
}

function _findByKeyHash(keyHash) {
  return _services.find((s) => s.keyHash === keyHash) || null;
}

// ---- CRUD ----

function reset() {
  _services.length = 0;
  _nextId = 1;
}

function create(body) {
  const {
    partnerTenantId,
    deploymentType,
    effectiveTier = 'standard',
    expiresAt = null,
  } = body || {};

  if (!partnerTenantId) {
    return { error: 'validation_error', message: 'partnerTenantId is required' };
  }

  const now = _timestamp();
  const id = `subsvc_${String(_nextId++).padStart(3, '0')}`;
  const rawKey = _generateServiceKey();
  const keyHash = _hashKey(rawKey);

  const subscription = {
    id,
    partnerTenantId,
    keyHash,
    effectiveTier,
    status: 'active',
    deployedAt: now,
    lastHeartbeatAt: null,
    heartbeatCount: 0,
    expiresAt,
    createdAt: now,
    updatedAt: now,
  };

  _services.push(subscription);

  // Sync to tenantStore: store the hash, not the raw key
  const tenantStore = _getTenantStore();
  tenantStore.updateTenantField(partnerTenantId, 'serviceKey', keyHash);
  if (deploymentType) {
    tenantStore.updateTenantField(partnerTenantId, 'deploymentType', deploymentType);
  }

  // rawServiceKey is returned ONLY at creation time
  return { subscription, rawServiceKey: rawKey };
}

// ---- Heartbeat (P2-11: receives RAW key, hashes internally) ----

function heartbeat(rawServiceKey, _instanceInfo) {
  const keyHash = _hashKey(rawServiceKey);
  const svc = _findByKeyHash(keyHash);

  if (!svc) {
    return { error: 'invalid_key' };
  }

  const now = _timestamp();
  svc.lastHeartbeatAt = now;
  svc.heartbeatCount = (svc.heartbeatCount || 0) + 1;
  svc.updatedAt = now;

  // Auto-recover from degraded back to active
  if (svc.status === 'degraded') {
    svc.status = 'active';
  }

  // Sync heartbeatAt to tenantStore
  const tenantStore = _getTenantStore();
  tenantStore.updateTenantField(svc.partnerTenantId, 'heartbeatAt', now);

  return { status: svc.status, message: 'ok' };
}

// ---- Status scanning ----

function scan() {
  const now = new Date();
  const affected = [];

  for (const svc of _services) {
    if (svc.status === 'revoked') continue;

    // If never had a heartbeat, treat as infinitely old
    const lastBeat = svc.lastHeartbeatAt
      ? new Date(svc.lastHeartbeatAt)
      : new Date(0);
    const msSinceHeartbeat = now - lastBeat;

    if (svc.status === 'active') {
      if (msSinceHeartbeat > 24 * 60 * 60 * 1000) {
        svc.status = 'grace_period';
        svc.updatedAt = _timestamp();
        affected.push(svc.id);
      }
    } else if (svc.status === 'grace_period') {
      if (msSinceHeartbeat > 15 * 24 * 60 * 60 * 1000) {
        svc.status = 'degraded';
        svc.updatedAt = _timestamp();
        affected.push(svc.id);
      }
    }
  }

  return affected;
}

// ---- Renew / Revoke ----

function renew(id, newExpiresAt) {
  const svc = _findById(id);
  if (!svc) return { error: 'not_found' };

  svc.expiresAt = newExpiresAt;
  if (svc.status === 'revoked') {
    svc.status = 'active';
  }
  svc.updatedAt = _timestamp();

  return { subscription: svc };
}

function revoke(id) {
  const svc = _findById(id);
  if (!svc) return { error: 'not_found' };

  svc.status = 'revoked';
  svc.revokedAt = _timestamp();
  svc.updatedAt = _timestamp();

  return { subscription: svc };
}

// ---- Query ----

function getById(id) {
  return _findById(id);
}

function getByPartnerTenantId(partnerTenantId) {
  return _services.find((s) => s.partnerTenantId === partnerTenantId) || null;
}

function list(query) {
  const {
    partnerTenantId,
    status,
    page: rawPage,
    pageSize: rawPageSize,
  } = query || {};

  let filtered = _services.slice();

  if (partnerTenantId) {
    filtered = filtered.filter((s) => s.partnerTenantId === partnerTenantId);
  }
  if (status) {
    filtered = filtered.filter((s) => s.status === status);
  }

  const page = Math.max(1, parseInt(rawPage, 10) || 1);
  const pageSize = Math.max(1, parseInt(rawPageSize, 10) || 20);
  const total = filtered.length;
  const start = (page - 1) * pageSize;
  const items = filtered.slice(start, start + pageSize);

  return { items, page, pageSize, total };
}

module.exports = {
  create,
  heartbeat,
  scan,
  renew,
  revoke,
  getById,
  getByPartnerTenantId,
  list,
  reset,
};
