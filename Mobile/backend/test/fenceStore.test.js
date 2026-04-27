const assert = require('assert');
const fenceStore = require('../data/fenceStore');

fenceStore.reset();

const created = fenceStore.createFence({
  name: '  新围栏  ',
  type: 'rectangle',
  coordinates: [
    [112.1, 28.1],
    [112.2, 28.2],
    [112.3, 28.3],
  ],
  alarmEnabled: false,
});
assert.ok(!created.error);
assert.strictEqual(created.fence.name, '新围栏');
assert.strictEqual(created.fence.type, 'rectangle');
assert.strictEqual(created.fence.alarmEnabled, false);

const invalidCreate = fenceStore.createFence({
  name: '',
  type: 'triangle',
  coordinates: [[112.1, 28.1]],
});
assert.strictEqual(invalidCreate.error, 'name_required');

const invalidType = fenceStore.createFence({
  name: '围栏2',
  type: 'triangle',
});
assert.strictEqual(invalidType.error, 'type_invalid');

const invalidCoordinates = fenceStore.createFence({
  name: '围栏3',
  coordinates: [[112.1, 28.1]],
});
assert.strictEqual(invalidCoordinates.error, 'coordinates_invalid');

const invalidAlarmEnabled = fenceStore.createFence({
  name: '围栏4',
  coordinates: [
    [112.1, 28.1],
    [112.2, 28.2],
    [112.3, 28.3],
  ],
  alarmEnabled: 'yes',
});
assert.strictEqual(invalidAlarmEnabled.error, 'alarm_enabled_invalid');

const existedFence = fenceStore.getAll()[0];
const updated = fenceStore.updateFence(existedFence.id, {
  name: '  更新后围栏  ',
  status: 'inactive',
});
assert.ok(!updated.error);
assert.strictEqual(updated.fence.name, '更新后围栏');
assert.strictEqual(updated.fence.status, 'inactive');

const invalidUpdateStatus = fenceStore.updateFence(existedFence.id, {
  status: 'disabled',
});
assert.strictEqual(invalidUpdateStatus.error, 'status_invalid');

const invalidUpdateName = fenceStore.updateFence(existedFence.id, {
  name: '   ',
});
assert.strictEqual(invalidUpdateName.error, 'name_required');

const notFoundUpdate = fenceStore.updateFence('missing-id', {
  name: 'x',
});
assert.strictEqual(notFoundUpdate.error, 'not_found');

const removed = fenceStore.removeFence(existedFence.id);
assert.ok(!removed.error);
assert.strictEqual(removed.removed.id, existedFence.id);

const notFoundRemove = fenceStore.removeFence('missing-id');
assert.strictEqual(notFoundRemove.error, 'not_found');

// Version conflict: providing wrong version returns error
fenceStore.reset();
const vFence = fenceStore.getAll()[0];
const initialVersion = vFence.version;
assert.strictEqual(initialVersion, 1);

const versionConflict = fenceStore.updateFence(vFence.id, {
  name: '冲突更新',
  version: initialVersion + 1,
});
assert.strictEqual(versionConflict.error, 'version_conflict');
assert.strictEqual(versionConflict.currentVersion, initialVersion);

// Version match: providing correct version succeeds and increments version
const correctVersion = fenceStore.updateFence(vFence.id, {
  name: '正确版本更新',
  version: initialVersion,
});
assert.ok(!correctVersion.error);
assert.strictEqual(correctVersion.fence.name, '正确版本更新');
assert.strictEqual(correctVersion.fence.version, initialVersion + 1);

// Update without version works (backwards compatible)
const noVersion = fenceStore.updateFence(vFence.id, {
  name: '无版本更新',
});
assert.ok(!noVersion.error);
assert.strictEqual(noVersion.fence.version, initialVersion + 2);

console.log('fenceStore.test.js OK');
