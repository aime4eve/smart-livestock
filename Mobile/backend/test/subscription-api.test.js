/**
 * Subscription API integration tests.
 *
 * Uses real Express app, following authChain.test.js conventions.
 * Each test starts a fresh server on a random port and sets up necessary state.
 */
const assert = require('node:assert/strict');
const { test, describe } = require('node:test');
const { app } = require('../server');
const tenantStore = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');

// ── Helpers ──

async function loginGetToken(role) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    const res = await fetch(`http://127.0.0.1:${port}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role }),
    });
    const json = await res.json();
    return json.data.token || json.data.accessToken;
  } finally {
    server.close();
  }
}

function setupTrialForTenant001() {
  subscriptionStore.createTrial('tenant_001');
}

// ── Subscription Store Unit Tests ──

describe('subscriptionStore unit', () => {
  test('createTrial creates 14-day premium trial', () => {
    subscriptionStore.reset();
    const result = subscriptionStore.createTrial('tenant_test');
    assert.equal(result.error, undefined);
    assert.equal(result.subscription.status, 'trial');
    assert.equal(result.subscription.tier, 'premium');
    assert.equal(result.subscription.trialEndsAt != null, true);

    const trialEnd = new Date(result.subscription.trialEndsAt);
    const now = new Date(result.subscription.createdAt);
    const diffDays = Math.ceil((trialEnd - now) / 86400000);
    assert.equal(diffDays, 14);
  });

  test('createTrial is idempotent for same tenant', () => {
    subscriptionStore.reset();
    const first = subscriptionStore.createTrial('tenant_test');
    const second = subscriptionStore.createTrial('tenant_test');
    assert.equal(second.error, 'already_exists');
    assert.equal(second.subscription.id, first.subscription.id);
  });

  test('getByTenantId returns null for unknown tenant', () => {
    subscriptionStore.reset();
    assert.equal(subscriptionStore.getByTenantId('nonexistent'), null);
  });

  test('checkout upgrades tier and sets active status', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    const result = subscriptionStore.checkout('tenant_test', 'standard', 100);
    assert.equal(result.error, undefined);
    assert.equal(result.subscription.status, 'active');
    assert.equal(result.subscription.tier, 'standard');
    assert.equal(result.subscription.livestockCount, 100);
    assert.equal(result.subscription.trialEndsAt, null);
  });

  test('checkout with idempotencyKey prevents duplicate', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    const first = subscriptionStore.checkout('tenant_test', 'standard', 100, 'key_001');
    const second = subscriptionStore.checkout('tenant_test', 'premium', 200, 'key_001');
    assert.equal(second.subscription.tier, 'standard');
  });

  test('checkout with non-existent tenant returns error', () => {
    subscriptionStore.reset();
    const result = subscriptionStore.checkout('nonexistent', 'standard', 100);
    assert.equal(result.error, 'no_subscription');
  });

  test('checkout calculates fees correctly', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    const result = subscriptionStore.checkout('tenant_test', 'standard', 50);
    assert.equal(result.subscription.calculatedDeviceFee, 50 * (15 + 30));
    assert.equal(result.subscription.calculatedTierFee, 299);
    assert.equal(result.subscription.calculatedTotal, 50 * 45 + 299);
  });

  test('checkout adds overage fee for livestock exceeding limit', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    const result = subscriptionStore.checkout('tenant_test', 'standard', 300);
    const deviceFee = 300 * 45;
    const tierFee = 299 + (300 - 200) * 2;
    assert.equal(result.subscription.calculatedTierFee, tierFee);
    assert.equal(result.subscription.calculatedTotal, deviceFee + tierFee);
  });

  test('cancel marks subscription as cancelled', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    subscriptionStore.checkout('tenant_test', 'standard', 50);
    const result = subscriptionStore.cancel('tenant_test');
    assert.equal(result.error, undefined);
    assert.equal(result.subscription.status, 'cancelled');
  });

  test('cancel non-existent subscription returns error', () => {
    subscriptionStore.reset();
    const result = subscriptionStore.cancel('nonexistent');
    assert.equal(result.error, 'no_subscription');
  });

  test('renew updates period and recalculates fees', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    subscriptionStore.checkout('tenant_test', 'standard', 50);
    const result = subscriptionStore.renew('tenant_test', 60);
    assert.equal(result.error, undefined);
    assert.equal(result.subscription.livestockCount, 60);
    assert.ok(new Date(result.subscription.currentPeriodEnd) > new Date());
    assert.equal(result.subscription.calculatedDeviceFee, 60 * 45);
  });

  test('renew non-active subscription returns error', () => {
    subscriptionStore.reset();
    subscriptionStore.createTrial('tenant_test');
    const result = subscriptionStore.renew('tenant_test', 50);
    assert.equal(result.error, 'not_active');
  });

  test('TIER_PRICES has correct values', () => {
    assert.equal(subscriptionStore.TIER_PRICES.basic, 0);
    assert.equal(subscriptionStore.TIER_PRICES.standard, 299);
    assert.equal(subscriptionStore.TIER_PRICES.premium, 699);
    assert.equal(subscriptionStore.TIER_PRICES.enterprise, null);
  });

  test('DEVICE_PRICES has correct values', () => {
    assert.equal(subscriptionStore.DEVICE_PRICES.gps, 15);
    assert.equal(subscriptionStore.DEVICE_PRICES.capsule, 30);
  });
});

// ── Subscription API Integration Tests ──

describe('subscription API endpoints', () => {
  test('GET /subscription/current returns trial subscription for owner', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/current`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.status, 'trial');
      assert.equal(body.data.tier, 'premium');
    } finally {
      server.close();
    }
  });

  test('GET /subscription/current returns 400 for ops (no farm context)', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    const token = await loginGetToken('ops');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/current`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      assert.equal(res.status, 400);
      assert.equal(body.code, 'BAD_REQUEST');
    } finally {
      server.close();
    }
  });

  test('GET /subscription/features returns all 20 features with accessible flag', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/features`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.features.length, 20);
      assert.equal(typeof body.data.features[0].accessible, 'boolean');
    } finally {
      server.close();
    }
  });

  test('GET /subscription/plans returns 4 plans with prices', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/plans`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.plans.length, 4);
      assert.equal(body.data.plans[0].id, 'basic');
      assert.equal(body.data.plans[0].monthlyPrice, 0);
      assert.equal(body.data.plans[1].monthlyPrice, 299);
      assert.equal(body.data.plans[2].monthlyPrice, 699);
      assert.equal(body.data.plans[3].id, 'enterprise');
      assert.equal(body.data.plans[3].contactSales, true);
    } finally {
      server.close();
    }
  });

  test('POST /subscription/checkout upgrades from trial to standard', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ tier: 'standard', livestockCount: 50 }),
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.status, 'active');
      assert.equal(body.data.tier, 'standard');
    } finally {
      server.close();
    }
  });

  test('POST /subscription/checkout with invalid tier returns 422', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ tier: 'enterprise', livestockCount: 50 }),
      });
      const body = await res.json();
      assert.equal(res.status, 422);
    } finally {
      server.close();
    }
  });

  test('POST /subscription/checkout with idempotency key prevents duplicate', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const headers = {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      };

      const first = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST', headers,
        body: JSON.stringify({ tier: 'standard', livestockCount: 50, idempotencyKey: 'test-key-001' }),
      });
      const firstBody = await first.json();
      assert.equal(first.status, 200);

      const second = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST', headers,
        body: JSON.stringify({ tier: 'premium', livestockCount: 200, idempotencyKey: 'test-key-001' }),
      });
      const secondBody = await second.json();
      assert.equal(second.status, 200);
      assert.equal(secondBody.data.tier, 'standard');
    } finally {
      server.close();
    }
  });

  test('POST /subscription/cancel cancels active subscription', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      // First checkout to make it active
      await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ tier: 'standard', livestockCount: 50 }),
      });

      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/cancel`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({}),
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.status, 'cancelled');
    } finally {
      server.close();
    }
  });

  test('POST /subscription/renew renews active subscription', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      await fetch(`http://127.0.0.1:${port}/api/v1/subscription/checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ tier: 'standard', livestockCount: 50 }),
      });

      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/renew`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ livestockCount: 60 }),
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.equal(body.data.livestockCount, 60);
      assert.equal(body.data.status, 'active');
    } finally {
      server.close();
    }
  });

  test('POST /subscription/renew with non-active trial returns 400', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/renew`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ livestockCount: 50 }),
      });
      const body = await res.json();
      assert.equal(res.status, 400);
      assert.equal(body.code, 'BAD_REQUEST');
    } finally {
      server.close();
    }
  });

  test('GET /subscription/usage returns usage data', async () => {
    tenantStore.reset();
    subscriptionStore.reset();
    setupTrialForTenant001();

    const token = await loginGetToken('owner');
    const server = app.listen(0);
    try {
      const { port } = server.address();
      const res = await fetch(`http://127.0.0.1:${port}/api/v1/subscription/usage`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      assert.equal(res.status, 200);
      assert.ok('livestockCount' in body.data);
      assert.ok('livestockLimit' in body.data);
      assert.ok('daysUntilExpiry' in body.data);
      assert.ok('status' in body.data);
    } finally {
      server.close();
    }
  });
});
