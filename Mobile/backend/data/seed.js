/**
 * Mock seed data — aligned with mobile_app/lib/core/data/demo_seed.dart
 */

const users = {
  owner: {
    userId: 'u_001',
    tenantId: 'tenant_001',
    name: '张三',
    role: 'owner',
    mobile: '13800000000',
    permissions: [
      'dashboard:view',
      'twin:view',
      'map:view',
      'alert:view',
      'alert:ack',
      'alert:handle',
      'alert:archive',
      'alert:batch',
      'fence:view',
      'fence:manage',
      'tenant:view',
      'tenant:create',
      'tenant:toggle',
      'license:manage',
      'profile:view',
    ],
  },
  worker: {
    userId: 'u_002',
    tenantId: 'tenant_001',
    name: '李四',
    role: 'worker',
    mobile: '13800000001',
    permissions: [
      'dashboard:view',
      'twin:view',
      'map:view',
      'alert:view',
      'alert:ack',
      'fence:view',
      'profile:view',
    ],
  },
  ops: {
    userId: 'u_003',
    tenantId: null,
    name: '运维管理员',
    role: 'ops',
    mobile: '13800000002',
    permissions: [
      'tenant:view',
      'tenant:create',
      'tenant:toggle',
      'license:manage',
    ],
  },
};

const dashboardMetrics = [
  { key: 'animal_total', title: '牲畜总数', value: '128' },
  { key: 'device_online', title: '在线设备', value: '96' },
  { key: 'alert_pending', title: '未处理告警', value: '7' },
  { key: 'health_watch', title: '健康关注', value: '12' },
];

const animals = [
  { id: 'animal_001', earTag: '耳标-001', lat: 28.2282, lng: 112.9385 },
  { id: 'animal_002', earTag: '耳标-002', lat: 28.2302, lng: 112.9375 },
  { id: 'animal_003', earTag: '耳标-003', lat: 28.2260, lng: 112.9410 },
];

const trajectoryPoints = [
  { lat: 28.2280, lng: 112.9380, ts: '2026-03-30T08:00:00' },
  { lat: 28.2288, lng: 112.9385, ts: '2026-03-30T08:15:00' },
  { lat: 28.2295, lng: 112.9390, ts: '2026-03-30T08:30:00' },
  { lat: 28.2300, lng: 112.9398, ts: '2026-03-30T08:45:00' },
  { lat: 28.2305, lng: 112.9405, ts: '2026-03-30T09:00:00' },
  { lat: 28.2298, lng: 112.9410, ts: '2026-03-30T09:15:00' },
  { lat: 28.2290, lng: 112.9400, ts: '2026-03-30T09:30:00' },
  { lat: 28.2285, lng: 112.9392, ts: '2026-03-30T09:45:00' },
  { lat: 28.2282, lng: 112.9385, ts: '2026-03-30T10:00:00' },
  { lat: 28.2288, lng: 112.9378, ts: '2026-03-30T10:15:00' },
  { lat: 28.2295, lng: 112.9370, ts: '2026-03-30T10:30:00' },
  { lat: 28.2302, lng: 112.9375, ts: '2026-03-30T10:45:00' },
];

const alerts = [
  {
    id: 'alert_001',
    title: '越界 · 耳标-001',
    occurredAt: '2026-03-26T10:12:00+08:00',
    stage: 'pending',
    level: 'warning',
  },
  {
    id: 'alert_002',
    title: '电池低电 · 耳标-002',
    occurredAt: '2026-03-26T11:30:00+08:00',
    stage: 'pending',
    level: 'critical',
  },
  {
    id: 'alert_003',
    title: '信号丢失 · 耳标-003',
    occurredAt: '2026-03-25T09:00:00+08:00',
    stage: 'acknowledged',
    level: 'info',
  },
  {
    id: 'alert_004',
    title: '越界 · 耳标-002',
    occurredAt: '2026-03-24T14:20:00+08:00',
    stage: 'handled',
    level: 'warning',
  },
  {
    id: 'alert_005',
    title: '越界 · 耳标-001',
    occurredAt: '2026-03-23T08:45:00+08:00',
    stage: 'archived',
    level: 'warning',
  },
  {
    id: 'alert_006',
    title: '电池低电 · 耳标-001',
    occurredAt: '2026-03-22T16:00:00+08:00',
    stage: 'pending',
    level: 'critical',
  },
  {
    id: 'alert_007',
    title: '信号丢失 · 耳标-002',
    occurredAt: '2026-03-22T10:30:00+08:00',
    stage: 'pending',
    level: 'info',
  },
  {
    id: 'alert_twin_001',
    type: 'fever_warning',
    title: '牛#3872 温度异常 — 当前39.8°C，基线38.6°C',
    occurredAt: '2026-04-07T10:30:00+08:00',
    stage: 'pending',
    level: 'critical',
  },
  {
    id: 'alert_twin_002',
    type: 'motility_stop',
    title: '牛#1205 蠕动停止',
    occurredAt: '2026-04-07T10:22:00+08:00',
    stage: 'pending',
    level: 'critical',
  },
  {
    id: 'alert_twin_003',
    type: 'estrus_high',
    title: '牛#2158 发情指数 92',
    occurredAt: '2026-04-07T09:58:00+08:00',
    stage: 'pending',
    level: 'warning',
  },
  {
    id: 'alert_twin_004',
    type: 'herd_abnormal',
    title: 'A区群体体温偏高',
    occurredAt: '2026-04-07T08:00:00+08:00',
    stage: 'pending',
    level: 'warning',
  },
];

const fences = [
  {
    id: 'fence_001',
    name: '北区围栏',
    type: 'polygon',
    status: 'active',
    alarmEnabled: true,
    coordinates: [
      [112.9360, 28.2310],
      [112.9430, 28.2310],
      [112.9430, 28.2260],
      [112.9360, 28.2260],
    ],
  },
  {
    id: 'fence_002',
    name: '河谷育肥区',
    type: 'circle',
    status: 'active',
    alarmEnabled: false,
    coordinates: [
      [112.9320, 28.2330],
      [112.9350, 28.2350],
    ],
  },
];

const tenants = [
  {
    id: 'tenant_001',
    name: '华东示范牧场',
    status: 'active',
    licenseUsed: 428,
    licenseTotal: 500,
  },
  {
    id: 'tenant_002',
    name: '西部高原牧场',
    status: 'active',
    licenseUsed: 120,
    licenseTotal: 200,
  },
];

module.exports = {
  users,
  dashboardMetrics,
  animals,
  trajectoryPoints,
  alerts,
  fences,
  tenants,
};
