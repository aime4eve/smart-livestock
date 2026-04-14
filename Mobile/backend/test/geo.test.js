const assert = require('assert');
const { pointInRing, boundaryStatusForPoint } = require('../utils/geo');
const { fences: seedFences } = require('../data/seed');

const pastureA = seedFences.find((f) => f.id === 'fence_pasture_a');

assert.ok(pastureA, 'seed has fence_pasture_a');

const insideLng = 112.942;
const insideLat = 28.232;
assert.strictEqual(
  pointInRing(insideLng, insideLat, pastureA.coordinates),
  true,
  'point inside pasture A',
);

const outsideLng = 112.5;
const outsideLat = 28.0;
assert.strictEqual(
  pointInRing(outsideLng, outsideLat, pastureA.coordinates),
  false,
  'point outside pasture A',
);

const list = require('../data/fenceStore').getAll();
const st = boundaryStatusForPoint(list, insideLng, insideLat);
assert.strictEqual(st, 'inside');

const st2 = boundaryStatusForPoint(list, outsideLng, outsideLat);
assert.strictEqual(st2, 'outside');

console.log('geo.test.js OK');
