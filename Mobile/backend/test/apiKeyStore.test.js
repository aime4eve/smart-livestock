const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert').strict;
const crypto = require('crypto');

function hashKey(raw) {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

let store;
beforeEach(() => {
  delete require.cache[require.resolve('../data/apiKeyStore')];
  store = require('../data/apiKeyStore');
  store.reset();
});

describe('apiKeyStore', () => {
  test('generate creates key with sl_apikey_ prefix', () => {
    const result = store.generate('tenant_a001');
    assert.ok(result.rawKey);
    assert.ok(result.rawKey.startsWith('sl_apikey_'));
    assert.equal(result.apiKey.apiTenantId, 'tenant_a001');
    assert.equal(result.apiKey.status, 'active');
    assert.ok(result.apiKey.keyId);
    assert.ok(result.apiKey.keyPrefix, 'sl_apikey_');
    assert.ok(result.apiKey.keySuffix);
  });

  test('generate stores keyHash (SHA-256), not raw key', () => {
    const result = store.generate('tenant_a001');
    const expectedHash = hashKey(result.rawKey);
    assert.equal(result.apiKey.keyHash, expectedHash);
    // Verify raw key is not stored
    assert.equal(result.apiKey.rawKey, undefined);
  });

  test('generate returns raw key only once', () => {
    const result = store.generate('tenant_a001');
    assert.ok(result.rawKey);

    // The stored record should NOT contain the raw key
    const keys = store.listByTenantId('tenant_a001');
    assert.ok(Array.isArray(keys));
    assert.ok(keys.length > 0);
    const stored = keys.find((k) => k.keyId === result.apiKey.keyId);
    if (stored) {
      assert.equal(stored.keyHash, undefined);
      assert.equal(stored.rawKey, undefined);
    }
  });

  test('validate returns { apiTenantId, apiTier } for valid key', () => {
    const result = store.generate('tenant_a001');
    const validation = store.validate(result.rawKey);
    assert.ok(validation);
    assert.equal(validation.apiTenantId, 'tenant_a001');
    assert.equal(validation.apiTier, 'growth');
  });

  test('validate returns null for invalid key', () => {
    const result = store.validate('sl_apikey_invalid_key_12345');
    assert.equal(result, null);
  });

  test('rotate creates new active key, old key enters rotating status', () => {
    const first = store.generate('tenant_a001');
    const rotateResult = store.rotate('tenant_a001');

    assert.ok(rotateResult.newApiKey);
    assert.ok(rotateResult.rawKey);
    assert.equal(rotateResult.newApiKey.status, 'active');

    // Verify old key is now 'rotating'
    const keys = store.listByTenantId('tenant_a001');
    const oldKey = keys.find((k) => k.keyId === first.apiKey.keyId);
    assert.ok(oldKey);
    assert.equal(oldKey.status, 'rotating');
    assert.ok(oldKey.rotatedAt);
  });

  test('rotate 24h auto-revoke: scanRevokeRotatingKeys revokes expired rotating keys', () => {
    const first = store.generate('tenant_a001');
    store.rotate('tenant_a001');

    // Manually set rotatedAt to >24h ago for the old key to simulate expiry
    const keys = store.listByTenantId('tenant_a001');
    const oldKey = keys.find((k) => k.status === 'rotating');
    assert.ok(oldKey);

    // Set rotatedAt to 25 hours ago
    const pastDate = new Date(Date.now() - 25 * 60 * 60 * 1000)
      .toISOString().replace('Z', '+08:00').replace(/\.\d{3}/, '');
    // Access internal data to simulate time passage
    store.setRotatedAt(oldKey.keyId, pastDate);

    const revoked = store.scanRevokeRotatingKeys();
    assert.ok(Array.isArray(revoked));
    assert.ok(revoked.length >= 1);
    assert.ok(revoked.includes(oldKey.keyId));

    // Verify status is now 'revoked'
    const afterKeys = store.listByTenantId('tenant_a001');
    const revokedKey = afterKeys.find((k) => k.keyId === oldKey.keyId);
    assert.equal(revokedKey.status, 'revoked');
  });

  test('revoke immediately changes status to revoked', () => {
    const result = store.generate('tenant_a001');
    const revokeResult = store.revoke(result.apiKey.keyId);
    assert.ok(revokeResult.apiKey);
    assert.equal(revokeResult.apiKey.status, 'revoked');

    // Verify via listByTenantId
    const keys = store.listByTenantId('tenant_a001');
    const key = keys.find((k) => k.keyId === result.apiKey.keyId);
    assert.equal(key.status, 'revoked');
  });

  test('listByTenantId returns all keys for an api tenant', () => {
    store.generate('tenant_a001');
    store.generate('tenant_a001');
    store.generate('tenant_a001');

    const keys = store.listByTenantId('tenant_a001');
    assert.ok(Array.isArray(keys));
    assert.equal(keys.length, 3);
  });

  test('listByTenantId returns empty array for unknown tenant', () => {
    const keys = store.listByTenantId('nonexistent');
    assert.ok(Array.isArray(keys));
    assert.equal(keys.length, 0);
  });

  test('two keys simultaneously valid during rotation period', () => {
    const first = store.generate('tenant_a001');
    const rotateResult = store.rotate('tenant_a001');

    // Both keys should be valid during rotation period (old is 'rotating' but not revoked)
    const firstValidation = store.validate(first.rawKey);
    assert.ok(firstValidation); // rotating keys are valid during 24h overlap
    assert.equal(firstValidation.apiTenantId, 'tenant_a001');

    const secondValidation = store.validate(rotateResult.rawKey);
    assert.ok(secondValidation);
    assert.equal(secondValidation.apiTenantId, 'tenant_a001');
  });

  test('reset clears all keys', () => {
    store.generate('tenant_a001');
    store.generate('tenant_a001');
    assert.equal(store.listByTenantId('tenant_a001').length, 2);

    store.reset();
    assert.equal(store.listByTenantId('tenant_a001').length, 0);
  });

  test('validate after revoke returns null', () => {
    const result = store.generate('tenant_a001');
    store.revoke(result.apiKey.keyId);
    const validation = store.validate(result.rawKey);
    assert.equal(validation, null);
  });

  test('revoke returns error for non-existent key', () => {
    const revokeResult = store.revoke('nonexistent_id');
    assert.equal(revokeResult.error, 'not_found');
  });

  test('apiKeyStore: seed key exists for tenant_008 (enterprise farm)', () => {
    // apiKeyStore.reset() restores initial state including seed key
    const keys = store.listByTenantId('tenant_008');
    assert.equal(keys.length, 1, 'tenant_008 should have exactly one seed key');
    assert.equal(keys[0].status, 'active');
  });

  test('apiKeyStore: validate seed key for tenant_008 end-to-end', () => {
    const result = store.validate('sl_apikey_seed_tenant_008_0000000000000001');
    assert.ok(result, 'seed key should validate');
    assert.equal(result.apiTenantId, 'tenant_008');
    assert.equal(result.apiTier, 'free');
  });
});
