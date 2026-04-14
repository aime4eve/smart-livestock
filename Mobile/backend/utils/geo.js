function pointInRing(lng, lat, ring) {
  if (!ring || ring.length < 3) {
    return false;
  }
  const x = lng;
  const y = lat;
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const xi = ring[i][0];
    const yi = ring[i][1];
    const xj = ring[j][0];
    const yj = ring[j][1];
    const denom = yj - yi;
    const intersect =
      yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (denom === 0 ? 1e-12 : denom) + xi;
    if (intersect) {
      inside = !inside;
    }
  }
  return inside;
}

function pointInAnyFence(fences, lng, lat) {
  if (!fences || fences.length === 0) {
    return false;
  }
  for (const f of fences) {
    if (f.status && f.status !== 'active') {
      continue;
    }
    const coords = f.coordinates;
    if (!coords || coords.length < 3) {
      continue;
    }
    if (pointInRing(lng, lat, coords)) {
      return true;
    }
  }
  return false;
}

function boundaryStatusForPoint(fences, lng, lat) {
  return pointInAnyFence(fences, lng, lat) ? 'inside' : 'outside';
}

module.exports = { pointInRing, pointInAnyFence, boundaryStatusForPoint };
