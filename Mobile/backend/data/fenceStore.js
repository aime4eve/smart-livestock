const { fences: seedFences } = require('./seed');

let fences = seedFences.map((f) => ({ ...f }));
let nextId = fences.length + 1;

function getAll() {
  return fences;
}

function findById(id) {
  return fences.find((f) => f.id === id);
}

function createFence(body) {
  const { name, type = 'polygon', coordinates = [], alarmEnabled = true } = body || {};
  if (!name) {
    return { error: 'name_required' };
  }
  const fence = {
    id: `fence_${String(nextId++).padStart(3, '0')}`,
    name,
    type,
    status: 'active',
    alarmEnabled,
    coordinates,
  };
  fences.push(fence);
  return { fence };
}

function updateFence(id, body) {
  const fence = findById(id);
  if (!fence) {
    return { error: 'not_found' };
  }
  const { name, type, coordinates, alarmEnabled, status } = body || {};
  if (name !== undefined) fence.name = name;
  if (type !== undefined) fence.type = type;
  if (coordinates !== undefined) fence.coordinates = coordinates;
  if (alarmEnabled !== undefined) fence.alarmEnabled = alarmEnabled;
  if (status !== undefined) fence.status = status;
  return { fence };
}

function removeFence(id) {
  const idx = fences.findIndex((f) => f.id === id);
  if (idx === -1) {
    return { error: 'not_found' };
  }
  const [removed] = fences.splice(idx, 1);
  return { removed };
}

function sliceForPage(page, pageSize) {
  const p = Math.max(1, parseInt(page, 10) || 1);
  const ps = Math.max(1, parseInt(pageSize, 10) || 20);
  const total = fences.length;
  const start = (p - 1) * ps;
  const items = fences.slice(start, start + ps);
  return { items, page: p, pageSize: ps, total };
}

module.exports = {
  getAll,
  findById,
  createFence,
  updateFence,
  removeFence,
  sliceForPage,
};
