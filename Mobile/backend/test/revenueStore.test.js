const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

function freshStore() {
  delete require.cache[require.resolve('../data/revenueStore')];
  const store = require('../data/revenueStore');
  store.reset();
  return store;
}

describe('revenueStore', () => {
  let store;

  beforeEach(() => {
    store = freshStore();
  });

  // ── Calculation tests ──────────────────────────────────────────────

  test('calculate generates RevenuePeriod for partners with contracts', () => {
    const periods = store.calculate('2026-05', 'monthly');
    assert.ok(Array.isArray(periods));
    // tenant_p001 has contract_001 → included
    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period, 'tenant_p001 should have a period');
    assert.equal(p001Period.contractId, 'contract_001');
    assert.equal(p001Period.revenueShareRatio, 0.15);
    // tenant_p002 has no contract yet → excluded initially
    const p002Period = periods.find((p) => p.partnerTenantId === 'tenant_p002');
    assert.ok(!p002Period, 'tenant_p002 has no contract and should be excluded');
  });

  test('calculate covers both billingModel partners after contract created', () => {
    // Create a contract for tenant_p002
    const contractStore = require('../data/contractStore');
    contractStore.reset();
    const contractResult = contractStore.create({
      partnerTenantId: 'tenant_p002',
      effectiveTier: 'premium',
      revenueShareRatio: 0.12,
      signedBy: '赵九',
    });
    assert.ok(contractResult.contract);

    const periods = store.calculate('2026-05', 'monthly');
    assert.ok(periods.length >= 2);

    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period);

    const p002Period = periods.find((p) => p.partnerTenantId === 'tenant_p002');
    assert.ok(p002Period, 'tenant_p002 should now have a period');
    assert.equal(p002Period.contractId, contractResult.contract.id);
    assert.equal(p002Period.revenueShareRatio, 0.12);
  });

  test('calculate formula: totalDeviceFee = sum of farm device fees', () => {
    const periods = store.calculate('2026-05', 'monthly');

    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period);

    // tenant_f_p001_001: livestockCount=150, gpsRatio=0.8, capsuleRatio=0.2
    // gpsFee = 150 * 0.8 * 15 = 1800
    // capsuleFee = 150 * 0.2 * 30 = 900
    // deviceFee = 2700
    // totalDeviceFee = 2700
    const farm = p001Period.farmDetails[0];
    assert.equal(farm.livestockCount, 150);
    assert.equal(farm.gpsFee, 1800);
    assert.equal(farm.capsuleFee, 900);
    assert.equal(farm.deviceFee, 2700);
    assert.equal(p001Period.totalDeviceFee, 2700);
  });

  test('calculate revenueShareAmount = totalDeviceFee * ratio', () => {
    const periods = store.calculate('2026-05', 'monthly');

    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period);
    // revenueShareAmount = 2700 * 0.15 = 405
    assert.equal(p001Period.revenueShareAmount, 405);
  });

  test('calculate snaps livestockCount and deviceConfigRatio from farm data', () => {
    const periods = store.calculate('2026-05', 'monthly');

    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period);

    const farm = p001Period.farmDetails[0];
    assert.equal(farm.farmTenantId, 'tenant_f_p001_001');
    assert.equal(farm.farmName, '星辰合作牧场A');
    assert.equal(farm.livestockCount, 150);
    assert.deepEqual(farm.deviceConfigRatio, { gpsRatio: 0.8, capsuleRatio: 0.2 });
  });

  test('calculate with mode=monthly only (realtime not implemented)', () => {
    const periods = store.calculate('2026-05', 'monthly');
    assert.ok(Array.isArray(periods));

    const p001Period = periods.find((p) => p.partnerTenantId === 'tenant_p001');
    assert.ok(p001Period);
    assert.equal(p001Period.period, '2026-05');
    assert.equal(p001Period.id, 'period_202605');

    // Returning same period should not duplicate
    const periods2 = store.calculate('2026-05', 'monthly');
    const periodIds = periods2.map((p) => p.id);
    const uniqueIds = [...new Set(periodIds)];
    assert.equal(periodIds.length, uniqueIds.length, 'should not create duplicate periods');
  });

  // ── Read tests ─────────────────────────────────────────────────────

  test('getPeriods returns paginated list', () => {
    store.calculate('2026-05', 'monthly');

    const result = store.getPeriods({});
    assert.ok(Array.isArray(result.items));
    assert.ok(result.items.length >= 1);
    assert.equal(result.page, 1);
    assert.equal(result.pageSize, 20);
    assert.ok(result.total >= 1);
  });

  test('getPeriods filters by partnerTenantId', () => {
    store.calculate('2026-05', 'monthly');

    const result = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    assert.ok(result.items.length > 0);
    result.items.forEach((p) => {
      assert.equal(p.partnerTenantId, 'tenant_p001');
    });
  });

  test('getPeriod returns single period with farm details', () => {
    store.calculate('2026-05', 'monthly');

    const list = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    assert.ok(list.items.length > 0);

    const period = store.getPeriod(list.items[0].id);
    assert.ok(period);
    assert.equal(period.id, list.items[0].id);
    assert.ok(Array.isArray(period.farmDetails));
    assert.ok(period.farmDetails.length > 0);
    assert.equal(period.partnerTenantId, 'tenant_p001');
  });

  test('getPeriod returns null for unknown period', () => {
    const period = store.getPeriod('nonexistent');
    assert.equal(period, null);
  });

  // ── Confirmation tests ─────────────────────────────────────────────

  test('confirm sets confirmedByPlatform when platform_admin', () => {
    store.calculate('2026-05', 'monthly');

    const list = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    const periodId = list.items[0].id;

    const result = store.confirm(periodId, 'platform_admin', null);
    assert.ok(result.period);
    assert.equal(result.period.confirmedByPlatform, true);
    assert.ok(result.period.confirmedByPlatformAt);
    assert.equal(result.period.confirmedByPartner, false);
    assert.equal(result.period.confirmedByPartnerAt, null);
  });

  test('confirm sets confirmedByPartner when matching b2b_admin tenantId', () => {
    store.calculate('2026-05', 'monthly');

    const list = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    const periodId = list.items[0].id;

    const result = store.confirm(periodId, 'b2b_admin', 'tenant_p001');
    assert.ok(result.period);
    assert.equal(result.period.confirmedByPartner, true);
    assert.ok(result.period.confirmedByPartnerAt);
    assert.equal(result.period.confirmedByPlatform, false);
    assert.equal(result.period.confirmedByPlatformAt, null);
  });

  test('confirm returns error for unknown period', () => {
    const result = store.confirm('nonexistent', 'platform_admin', null);
    assert.equal(result.error, 'not_found');
  });

  test('confirm returns forbidden for non-matching b2b_admin', () => {
    store.calculate('2026-05', 'monthly');

    const list = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    const periodId = list.items[0].id;

    const result = store.confirm(periodId, 'b2b_admin', 'wrong_tenant');
    assert.equal(result.error, 'forbidden');
  });

  test('status transitions to settled when both confirmed', () => {
    store.calculate('2026-05', 'monthly');

    const list = store.getPeriods({ partnerTenantId: 'tenant_p001' });
    const periodId = list.items[0].id;

    // Platform confirms
    store.confirm(periodId, 'platform_admin', null);
    let period = store.getPeriod(periodId);
    assert.equal(period.status, 'pending');

    // Partner confirms → should become settled
    const result = store.confirm(periodId, 'b2b_admin', 'tenant_p001');
    assert.ok(result.period);
    assert.equal(result.period.status, 'settled');
    assert.ok(result.period.settledAt);
    assert.equal(result.period.confirmedByPlatform, true);
    assert.equal(result.period.confirmedByPartner, true);
  });

  // ── Reset test ─────────────────────────────────────────────────────

  test('reset clears all periods', () => {
    store.calculate('2026-05', 'monthly');

    const before = store.getPeriods({});
    assert.ok(before.items.length > 0);

    store.reset();

    const after = store.getPeriods({});
    assert.equal(after.items.length, 0);
  });
});
