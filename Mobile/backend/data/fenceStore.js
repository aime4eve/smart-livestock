const { fences: seedFences } = require('./seed');

let fences = seedFences.map((f) => ({ ...f }));
let nextId = fences.length + 1;
const ALLOWED_TYPES = ['polygon', 'circle', 'rectangle'];
const ALLOWED_STATUS = ['active', 'inactive'];

function normalizeName(name) {
  return typeof name === 'string' ? name.trim() : name;
}

function isValidCoordinates(coordinates) {
  if (!Array.isArray(coordinates) || coordinates.length < 3) {
    return false;
  }
  for (const point of coordinates) {
    if (!Array.isArray(point) || point.length !== 2) {
      return false;
    }
    const [lng, lat] = point;
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
      return false;
    }
  }
  return true;
}

function getAll() {
  return fences;
}

function findById(id) {
  return fences.find((f) => f.id === id);
}

function createFence(body) {
  const {
    name: rawName,
    type = 'polygon',
    coordinates = [],
    alarmEnabled = true,
  } = body || {};
  const name = normalizeName(rawName);
  if (!name) {
    return { error: 'name_required' };
  }
  if (!ALLOWED_TYPES.includes(type)) {
    return { error: 'type_invalid' };
  }
  if (!isValidCoordinates(coordinates)) {
    return { error: 'coordinates_invalid' };
  }
  if (typeof alarmEnabled !== 'boolean') {
    return { error: 'alarm_enabled_invalid' };
  }
  const fence = {
    id: `fence_${String(nextId++).padStart(3, '0')}`,
    name,
    type,
    status: 'active',
    alarmEnabled,
    version: 1,
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
  const {
    name: rawName,
    type,
    coordinates,
    alarmEnabled,
    status,
    version,
  } = body || {};

  if (version !== undefined && version !== fence.version) {
    return { error: 'version_conflict', currentVersion: fence.version };
  }

  const name = normalizeName(rawName);
  if (rawName !== undefined && !name) {
    return { error: 'name_required' };
  }
  if (type !== undefined && !ALLOWED_TYPES.includes(type)) {
    return { error: 'type_invalid' };
  }
  if (coordinates !== undefined && !isValidCoordinates(coordinates)) {
    return { error: 'coordinates_invalid' };
  }
  if (alarmEnabled !== undefined && typeof alarmEnabled !== 'boolean') {
    return { error: 'alarm_enabled_invalid' };
  }
  if (status !== undefined && !ALLOWED_STATUS.includes(status)) {
    return { error: 'status_invalid' };
  }
  if (name !== undefined) fence.name = name;
  if (type !== undefined) fence.type = type;
  if (coordinates !== undefined) fence.coordinates = coordinates;
  if (alarmEnabled !== undefined) fence.alarmEnabled = alarmEnabled;
  if (status !== undefined) fence.status = status;
  fence.version = (fence.version || 1) + 1;
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

function reset() {
  fences = seedFences.map((f) => ({ ...f }));
  nextId = fences.length + 1;
}

module.exports = {
  getAll,
  findById,
  createFence,
  updateFence,
  removeFence,
  sliceForPage,
  reset,
};
