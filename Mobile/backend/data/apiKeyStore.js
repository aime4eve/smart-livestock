// backend/data/apiKeyStore.js
// Open API key management: generate, validate, rotate, revoke

const crypto = require('crypto');

// Lazy-load tenantStore to avoid circular dependency
let _tenantStore = null;
function _getTenantStore() {
  if (!_tenantStore) _tenantStore = require('./tenantStore');
  return _tenantStore;
}

// Lazy-load apiTierStore to avoid circular dependency
let _apiTierStore = null;
function _getApiTierStore() {
  if (!_apiTierStore) _apiTierStore = require('./apiTierStore');
  return _apiTierStore;
}

let _keys = [];
let _nextId = 1;

function _now() {
  return new Date().toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
}

function _generateRawKey() {
  return 'sl_apikey_' + crypto.randomBytes(20).toString('hex');
}

function _hashKey(raw) {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function reset() {
  _keys = [];
  _nextId = 1;

  // Seed key for tenant_008 (enterprise farm, free tier)
  const seedRawKey = 'sl_apikey_seed_tenant_008_0000000000000001';
  const seedKeyHash = _hashKey(seedRawKey);
  _keys.push({
    keyId: 'apikey_seed_008',
    apiTenantId: 'tenant_008',
    keyHash: seedKeyHash,
    keyPrefix: seedRawKey.substring(0, 10),
    keySuffix: seedRawKey.substring(seedRawKey.length - 4),
    status: 'active',
    createdAt: '2026-05-04T00:00:00+08:00',
    rotatedAt: null,
  });
  _nextId = 2;
}

/**
 * Generate a new API key for a given api tenant.
 * Returns { apiKey: { keyId, apiTenantId, keyPrefix, keySuffix, status, createdAt }, rawKey }
 */
function generate(apiTenantId) {
  const rawKey = _generateRawKey();
  const keyHash = _hashKey(rawKey);
  const keyPrefix = rawKey.substring(0, 10);
  const keySuffix = rawKey.substring(rawKey.length - 4);
  const now = _now();
  const keyId = 'apikey_' + String(_nextId++).padStart(3, '0');

  const apiKey = {
    keyId,
    apiTenantId,
    keyHash,
    keyPrefix,
    keySuffix,
    status: 'active',
    createdAt: now,
    rotatedAt: null,
  };

  _keys.push(apiKey);

  // Sync tenantStore: apiKey = keyHash
  const tenantStore = _getTenantStore();
  tenantStore.updateTenantField(apiTenantId, 'apiKey', keyHash);

  return {
    apiKey: {
      keyId,
      apiTenantId,
      keyHash,
      keyPrefix,
      keySuffix,
      status: 'active',
      createdAt: now,
      rotatedAt: null,
    },
    rawKey,
  };
}

/**
 * Validate a raw API key.
 * Returns { apiTenantId, apiTier } if valid and active, or null if not found or not active.
 */
function validate(rawKey) {
  if (!rawKey) return null;
  const keyHash = _hashKey(rawKey);
  const key = _keys.find((k) => k.keyHash === keyHash && (k.status === 'active' || k.status === 'rotating'));
  if (!key) return null;

  // Look up the api tenant's tier info
  const apiTierStore = _getApiTierStore();
  const tier = apiTierStore.getByTenantId(key.apiTenantId);

  return {
    apiTenantId: key.apiTenantId,
    apiTier: tier ? tier.tier : null,
  };
}

/**
 * Rotate API keys for a tenant:
 * - Generate new active key
 * - Set all existing active keys to 'rotating' with rotatedAt=now
 * Returns { newApiKey, rawKey }
 */
function rotate(apiTenantId) {
  const now = _now();

  // Mark all existing active keys as rotating
  _keys.forEach((k) => {
    if (k.apiTenantId === apiTenantId && k.status === 'active') {
      k.status = 'rotating';
      k.rotatedAt = now;
    }
  });

  // Generate new key (it becomes the only active one)
  const result = generate(apiTenantId);
  return { newApiKey: result.apiKey, rawKey: result.rawKey };
}

/**
 * Scan for keys that have been in 'rotating' status for more than 24 hours,
 * and mark them as 'revoked'.
 * Returns array of revoked keyIds.
 */
function scanRevokeRotatingKeys() {
  const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  const revokedIds = [];

  _keys.forEach((k) => {
    if (k.status === 'rotating' && k.rotatedAt) {
      // Parse the rotatedAt timestamp and compare
      const rotatedTime = new Date(k.rotatedAt.replace('+08:00', '+08:00')).getTime();
      if (rotatedTime < cutoff) {
        k.status = 'revoked';
        revokedIds.push(k.keyId);
      }
    }
  });

  return revokedIds;
}

/**
 * Immediately revoke an API key by keyId.
 * Returns { apiKey } or { error: 'not_found' }.
 */
function revoke(keyId) {
  const key = _keys.find((k) => k.keyId === keyId);
  if (!key) return { error: 'not_found' };

  key.status = 'revoked';
  return { apiKey: { ...key } };
}

/**
 * List all keys for a given api tenant.
 * Returns array with keyPrefix, keySuffix, status, createdAt, rotatedAt — NOT keyHash or rawKey.
 */
function listByTenantId(apiTenantId) {
  return _keys
    .filter((k) => k.apiTenantId === apiTenantId)
    .map((k) => ({
      keyId: k.keyId,
      apiTenantId: k.apiTenantId,
      keyPrefix: k.keyPrefix,
      keySuffix: k.keySuffix,
      status: k.status,
      createdAt: k.createdAt,
      rotatedAt: k.rotatedAt,
    }));
}

/**
 * Set rotatedAt for a key (used in tests to simulate time passage).
 */
function setRotatedAt(keyId, pastDate) {
  const key = _keys.find((k) => k.keyId === keyId);
  if (key) {
    key.rotatedAt = pastDate;
    return true;
  }
  return false;
}

module.exports = {
  generate,
  validate,
  rotate,
  scanRevokeRotatingKeys,
  revoke,
  listByTenantId,
  setRotatedAt,
  reset,
};
