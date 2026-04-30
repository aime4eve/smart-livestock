const assert = require('node:assert/strict');
const { test } = require('node:test');

function loadStore() {
  const storePath = require.resolve('../data/workerFarmStore');
  delete require.cache[storePath];
  return require('../data/workerFarmStore');
}

test('workerFarmStore: findByUserId returns assignments for worker u_002', () => {
  const store = loadStore();
  const assignments = store.findByUserId('u_002');
  assert.equal(assignments.length, 2);
  assert.deepEqual(assignments.map((a) => a.farmTenantId), ['tenant_001', 'tenant_007']);
});

test('workerFarmStore: findByFarmId returns workers for tenant_001', () => {
  const store = loadStore();
  const workers = store.findByFarmId('tenant_001');
  assert.equal(workers.length, 1);
  assert.equal(workers[0].userId, 'u_002');
});

test('workerFarmStore: assign creates new assignment with id and assignedAt', () => {
  const store = loadStore();
  const assignment = store.assign('u_009', 'tenant_001', 'worker');
  assert.ok(assignment.id);
  assert.equal(assignment.userId, 'u_009');
  assert.equal(assignment.farmTenantId, 'tenant_001');
  assert.equal(assignment.role, 'worker');
  assert.ok(assignment.assignedAt);
});

test('workerFarmStore: assign returns null for duplicate user and farm', () => {
  const store = loadStore();
  assert.equal(store.assign('u_002', 'tenant_001', 'worker'), null);
});

test('workerFarmStore: unassign removes assignment', () => {
  const store = loadStore();
  const assignment = store.assign('u_010', 'tenant_001', 'worker');
  assert.equal(store.unassign(assignment.id), true);
  assert.equal(store.findByUserId('u_010').length, 0);
});

test('workerFarmStore: unassign returns false for nonexistent id', () => {
  const store = loadStore();
  assert.equal(store.unassign('wfa_missing'), false);
});
