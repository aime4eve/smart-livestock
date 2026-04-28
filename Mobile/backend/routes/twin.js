const express = require('express');
const {
  overview,
  feverListItems,
  digestiveListItems,
  estrusListItems,
  epidemicSummary,
  epidemicContacts,
} = require('../data/twin_seed');
const { requirePermission } = require('../middleware/auth');
const { featureKeys } = require('../middleware/feature-flag');
const { injectDeviceGate, getCattleById } = require('../services/deviceGate');

const router = express.Router();
const perm = requirePermission('twin:view');

router.get('/overview', perm, (req, res) => {
  res.ok(overview);
});

router.get('/fever/list', perm, featureKeys('temperature_monitor'), (req, res) => {
  const items = injectDeviceGate(feverListItems, 'temperature_monitor');
  res.ok({
    items,
    page: 1,
    pageSize: 20,
    total: items.length,
  });
});

router.get('/fever/:id', perm, featureKeys('temperature_monitor'), (req, res) => {
  const item = feverListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  const cattle = getCattleById(item.livestockId);
  res.ok(injectDeviceGate(item, 'temperature_monitor', () => cattle));
});

router.get('/digestive/list', perm, featureKeys('peristaltic_monitor'), (req, res) => {
  const items = injectDeviceGate(digestiveListItems, 'peristaltic_monitor');
  res.ok({
    items,
    page: 1,
    pageSize: 20,
    total: items.length,
  });
});

router.get('/digestive/:id', perm, featureKeys('peristaltic_monitor'), (req, res) => {
  const item = digestiveListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  const cattle = getCattleById(item.livestockId);
  res.ok(injectDeviceGate(item, 'peristaltic_monitor', () => cattle));
});

router.get('/estrus/list', perm, featureKeys('estrus_detect'), (req, res) => {
  const items = injectDeviceGate(estrusListItems, 'estrus_detect');
  res.ok({
    items,
    page: 1,
    pageSize: 20,
    total: items.length,
  });
});

router.get('/estrus/:id', perm, featureKeys('estrus_detect'), (req, res) => {
  const item = estrusListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  const cattle = getCattleById(item.livestockId);
  res.ok(injectDeviceGate(item, 'estrus_detect', () => cattle));
});

router.get('/epidemic/summary', perm, featureKeys('epidemic_alert'), (req, res) => {
  res.ok(injectDeviceGate(epidemicSummary, 'epidemic_alert'));
});

router.get('/epidemic/contacts', perm, featureKeys('epidemic_alert'), (req, res) => {
  const items = injectDeviceGate(epidemicContacts, 'epidemic_alert');
  res.ok({
    items,
    page: 1,
    pageSize: 50,
    total: items.length,
  });
});

module.exports = router;
