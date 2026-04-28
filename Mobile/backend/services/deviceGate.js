const { FEATURE_FLAGS } = require('../data/feature-flags');
const store = require('../data/tenantStore');

function getCattleById(livestockId) {
  const { animals } = require('../data/seed');
  return animals.find(a => a.livestockId === livestockId) || null;
}

function checkDeviceRequirement(cattle, featureKey) {
  if (!cattle) return true;
  const flag = FEATURE_FLAGS[featureKey];
  if (!flag || !flag.requiredDevices) return true;

  const required = Array.isArray(flag.requiredDevices)
    ? flag.requiredDevices
    : [flag.requiredDevices];

  const cattleDevices = (cattle.devices || []).map(d => d.type);
  return required.every(r => cattleDevices.includes(r));
}

function injectDeviceGate(data, featureKey, cattleGetter) {
  const flag = FEATURE_FLAGS[featureKey];
  if (!flag || !flag.requiredDevices) return data;

  if (Array.isArray(data)) {
    return data.map(item => {
      const cattle = typeof cattleGetter === 'function' ? cattleGetter(item) : getCattleById(item.livestockId);
      const hasDevices = checkDeviceRequirement(cattle, featureKey);
      return {
        ...item,
        deviceLocked: !hasDevices,
        deviceMessage: hasDevices ? null : buildDeviceMessage(flag.requiredDevices),
      };
    });
  }

  const cattle = typeof cattleGetter === 'function' ? cattleGetter(data) : getCattleById(data.livestockId || data.id);
  const hasDevices = checkDeviceRequirement(cattle, featureKey);
  return {
    ...data,
    deviceLocked: !hasDevices,
    deviceMessage: hasDevices ? null : buildDeviceMessage(flag.requiredDevices),
  };
}

function buildDeviceMessage(requiredDevices) {
  const req = Array.isArray(requiredDevices) ? requiredDevices : [requiredDevices];
  const names = req.map(d => d === 'gps' ? 'GPS追踪器' : '瘤胃胶囊').join('和');
  return `此功能需要安装${names}`;
}

module.exports = { checkDeviceRequirement, injectDeviceGate, getCattleById };
