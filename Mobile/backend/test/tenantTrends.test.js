const assert = require('node:assert/strict');
const { test } = require('node:test');
const { generateTrends } = require('../routes/tenants');

test('tenantTrends: 生成 30 天趋势数据', () => {
  const trends = generateTrends('tenant_001');
  assert.equal(trends.dailyStats.length, 30);
  const first = trends.dailyStats[0];
  assert.ok(typeof first.date === 'string');
  assert.ok(typeof first.alerts === 'number');
  assert.ok(typeof first.deviceOnlineRate === 'number');
  assert.ok(typeof first.healthRate === 'number');
  assert.ok(first.deviceOnlineRate >= 0 && first.deviceOnlineRate <= 100);
  assert.ok(first.healthRate >= 60 && first.healthRate <= 100);
});

test('tenantTrends: 日期倒序排列（最新在前）', () => {
  const trends = generateTrends('tenant_001');
  const dates = trends.dailyStats.map(s => s.date);
  for (let i = 0; i < dates.length - 1; i++) {
    assert.ok(dates[i] >= dates[i + 1]);
  }
});

test('tenantTrends: 不同租户数据有差异', () => {
  const a = generateTrends('tenant_001');
  const b = generateTrends('tenant_002');
  const aSum = a.dailyStats.reduce((s, p) => s + p.alerts, 0);
  const bSum = b.dailyStats.reduce((s, p) => s + p.alerts, 0);
  assert.notEqual(aSum, bSum);
});
