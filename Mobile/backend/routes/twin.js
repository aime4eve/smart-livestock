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

const router = express.Router();

router.use(requirePermission('twin:view'));

router.get('/overview', (req, res) => {
  res.ok(overview);
});

router.get('/fever/list', (req, res) => {
  res.ok({
    items: feverListItems,
    page: 1,
    pageSize: 20,
    total: feverListItems.length,
  });
});

router.get('/fever/:id', (req, res) => {
  const item = feverListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  res.ok(item);
});

router.get('/digestive/list', (req, res) => {
  res.ok({
    items: digestiveListItems,
    page: 1,
    pageSize: 20,
    total: digestiveListItems.length,
  });
});

router.get('/digestive/:id', (req, res) => {
  const item = digestiveListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  res.ok(item);
});

router.get('/estrus/list', (req, res) => {
  res.ok({
    items: estrusListItems,
    page: 1,
    pageSize: 20,
    total: estrusListItems.length,
  });
});

router.get('/estrus/:id', (req, res) => {
  const item = estrusListItems.find((x) => x.livestockId === req.params.id);
  if (!item) {
    return res.fail(404, 'RESOURCE_NOT_FOUND', '未找到个体');
  }
  res.ok(item);
});

router.get('/epidemic/summary', (req, res) => {
  res.ok(epidemicSummary);
});

router.get('/epidemic/contacts', (req, res) => {
  res.ok({
    items: epidemicContacts,
    page: 1,
    pageSize: 50,
    total: epidemicContacts.length,
  });
});

module.exports = router;
