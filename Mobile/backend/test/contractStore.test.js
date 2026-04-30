const { describe, test } = require('node:test');
const assert = require('node:assert/strict');

describe('contractStore', () => {
  let store;

  test('getByPartnerTenantId returns contract for known partner', () => {
    delete require.cache[require.resolve('../data/contractStore')];
    store = require('../data/contractStore');
    const contract = store.getByPartnerTenantId('tenant_p001');
    assert.ok(contract);
    assert.equal(contract.partnerTenantId, 'tenant_p001');
    assert.equal(contract.status, 'active');
    assert.equal(contract.effectiveTier, 'standard');
  });

  test('getByPartnerTenantId returns null for unknown partner', () => {
    const contract = store.getByPartnerTenantId('nonexistent');
    assert.equal(contract, null);
  });
});
