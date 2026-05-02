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
      'tenant:edit',
      'tenant:delete',
      'profile:view',
      'subscription:manage',
      'api-authorization:review',
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
  platform_admin: {
    userId: 'u_003',
    tenantId: null,
    name: '平台管理员',
    role: 'platform_admin',
    mobile: '13800000002',
    permissions: [
      'tenant:view',
      'tenant:create',
      'tenant:toggle',
      'license:manage',
      'tenant:edit',
      'tenant:delete',
      'contract:manage',
      'revenue:view',
      'revenue:calculate',
      'subscription-service:view',
      'subscription-service:manage',
      'api-key:manage',
      'api-authorization:review',
      'worker:manage:subfarm',
    ],
  },
  b2b_admin: {
    userId: 'u_004',
    tenantId: 'tenant_p001',
    name: '星辰牧业',
    role: 'b2b_admin',
    mobile: '13800000003',
    permissions: [
      'tenant:view',
      'farm:view_summary',
      'contract:view',
      'farm:create',
      'b2b:dashboard',
      'revenue:view',
      'worker:manage:subfarm',
    ],
  },
  api_consumer: {
    userId: 'u_005',
    tenantId: 'tenant_a001',
    name: '数据科技公司',
    role: 'api_consumer',
    mobile: '13800000004',
    permissions: ['api:access', 'api-authorization:request'],
  },
  u_006: {
    userId: 'u_006',
    tenantId: 'tenant_f_p001_001',
    name: '马七',
    role: 'owner',
    mobile: '13800000005',
    permissions: [
      'tenant:view', 'fence:view', 'fence:edit',
      'alert:view', 'alert:ack', 'dashboard:view',
      'subscription:view', 'profile:view',
    ],
  },
};

const dashboardMetrics = [
  { key: 'animal_total', title: '牲畜总数', value: '50' },
  { key: 'device_online', title: '在线设备', value: '85' },
  { key: 'alert_today', title: '今日告警', value: '8' },
  { key: 'health_rate', title: '健康率', value: '92%' },
];

function generateAnimals() {
  const breeds = ['西门塔尔牛', '安格斯牛', '利木赞牛'];
  const breedCounts = [20, 15, 15];
  let breedIdx = 0;
  const breedRemaining = [...breedCounts];

  const fenceConfigs = [
    { id: 'fence_pasture_a', count: 25, latMin: 28.2305, latMax: 28.2340, lngMin: 112.9400, lngMax: 112.9440 },
    { id: 'fence_pasture_b', count: 18, latMin: 28.2240, latMax: 28.2275, lngMin: 112.9320, lngMax: 112.9360 },
    { id: 'fence_rest', count: 4, latMin: 28.2280, latMax: 28.2295, lngMin: 112.9380, lngMax: 112.9400 },
    { id: 'fence_quarantine', count: 3, latMin: 28.2248, latMax: 28.2255, lngMin: 112.9400, lngMax: 112.9410 },
  ];

  const result = [];
  let seed = 42;
  function seededRandom() {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  }

  for (const fc of fenceConfigs) {
    for (let i = 0; i < fc.count; i++) {
      const n = result.length + 1;
      while (breedRemaining[breedIdx] <= 0) breedIdx++;
      breedRemaining[breedIdx]--;
      const nn = n.toString().padStart(3, '0');
      const deviceList = [];
      if (n % 5 !== 0) deviceList.push({ type: 'gps', id: `DEV-GPS-${String(n % 42 || 42).padStart(3, '0')}` });
      if (n % 4 === 0) deviceList.push({ type: 'capsule', id: `DEV-CAP-${String(n).padStart(3, '0')}` });
      result.push({
        id: `animal_${nn}`,
        earTag: `SL-2024-${nn}`,
        livestockId: n.toString().padStart(4, '0'),
        breed: breeds[breedIdx],
        fenceId: fc.id,
        devices: deviceList,
        lat: +(fc.latMin + seededRandom() * (fc.latMax - fc.latMin)).toFixed(4),
        lng: +(fc.lngMin + seededRandom() * (fc.lngMax - fc.lngMin)).toFixed(4),
        farmTenantId: 'tenant_001',
      });
    }
  }
  return result;
}

const animals = generateAnimals();

const fences = [
  {
    id: 'fence_pasture_a',
    name: '放牧A区',
    type: 'polygon',
    status: 'active',
    alarmEnabled: true,
    version: 1,
    coordinates: [
      [112.94, 28.234],
      [112.944, 28.234],
      [112.944, 28.2305],
      [112.94, 28.2305],
    ],
  },
  {
    id: 'fence_pasture_b',
    name: '放牧B区',
    type: 'polygon',
    status: 'active',
    alarmEnabled: true,
    version: 1,
    coordinates: [
      [112.932, 28.2275],
      [112.936, 28.2275],
      [112.936, 28.224],
      [112.932, 28.224],
    ],
  },
  {
    id: 'fence_rest',
    name: '夜间休息区',
    type: 'polygon',
    status: 'active',
    alarmEnabled: false,
    version: 1,
    coordinates: [
      [112.938, 28.2295],
      [112.94, 28.2295],
      [112.94, 28.228],
      [112.938, 28.228],
    ],
  },
  {
    id: 'fence_quarantine',
    name: '隔离区',
    type: 'polygon',
    status: 'active',
    alarmEnabled: true,
    version: 1,
    coordinates: [
      [112.94, 28.2255],
      [112.941, 28.2255],
      [112.941, 28.2248],
      [112.94, 28.2248],
    ],
  },
];

const alerts = [
  { id: 'alert-001', type: 'geofence', title: '越界 · SL-2024-003', occurredAt: '2026-04-08T14:23:00+08:00', stage: 'pending', level: 'critical', earTag: 'SL-2024-003', priority: 'P0' },
  { id: 'alert-002', type: 'fever', title: '体温异常 · SL-2024-048', occurredAt: '2026-04-08T11:05:00+08:00', stage: 'acknowledged', level: 'critical', earTag: 'SL-2024-048', priority: 'P0' },
  { id: 'alert-003', type: 'geofence', title: '越界 · SL-2024-017', occurredAt: '2026-04-07T16:30:00+08:00', stage: 'handled', level: 'critical', earTag: 'SL-2024-017', priority: 'P0' },
  { id: 'alert-004', type: 'fever', title: '体温异常 · SL-2024-049', occurredAt: '2026-04-07T09:15:00+08:00', stage: 'handled', level: 'critical', earTag: 'SL-2024-049', priority: 'P0' },
  { id: 'alert-005', type: 'offline', title: '设备离线 · SL-2024-043', occurredAt: '2026-04-08T13:40:00+08:00', stage: 'pending', level: 'warning', earTag: 'SL-2024-043', priority: 'P1' },
  { id: 'alert-006', type: 'lowbattery', title: '低电量 · SL-2024-045', occurredAt: '2026-04-08T12:20:00+08:00', stage: 'pending', level: 'warning', earTag: 'SL-2024-045', priority: 'P1' },
  { id: 'alert-007', type: 'offline', title: '设备离线 · SL-2024-044', occurredAt: '2026-04-08T08:50:00+08:00', stage: 'acknowledged', level: 'warning', earTag: 'SL-2024-044', priority: 'P1' },
  { id: 'alert-008', type: 'lowbattery', title: '低电量 · SL-2024-046', occurredAt: '2026-04-07T15:10:00+08:00', stage: 'handled', level: 'warning', earTag: 'SL-2024-046', priority: 'P1' },
  { id: 'alert-009', type: 'offline', title: '设备离线 · SL-2024-042', occurredAt: '2026-04-07T10:25:00+08:00', stage: 'handled', level: 'warning', earTag: 'SL-2024-042', priority: 'P1' },
  { id: 'alert-010', type: 'behavior', title: '行为异常 · SL-2024-047', occurredAt: '2026-04-08T09:30:00+08:00', stage: 'pending', level: 'info', earTag: 'SL-2024-047', priority: 'P2' },
  { id: 'alert-011', type: 'geofence', title: '围栏接近 · SL-2024-012', occurredAt: '2026-04-07T14:50:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-012', priority: 'P2' },
  { id: 'alert-012', type: 'behavior', title: '行为异常 · SL-2024-050', occurredAt: '2026-04-07T11:35:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-050', priority: 'P2' },
  { id: 'alert-013', type: 'geofence', title: '围栏接近 · SL-2024-008', occurredAt: '2026-04-06T16:45:00+08:00', stage: 'handled', level: 'info', earTag: 'SL-2024-008', priority: 'P2' },
  { id: 'alert-014', type: 'behavior', title: '行为异常 · SL-2024-030', occurredAt: '2026-04-06T10:00:00+08:00', stage: 'archived', level: 'info', earTag: 'SL-2024-030', priority: 'P2' },
  { id: 'alert-015', type: 'geofence', title: '越界 · SL-2024-005', occurredAt: '2026-04-05T09:10:00+08:00', stage: 'archived', level: 'critical', earTag: 'SL-2024-005', priority: 'P0' },
  { id: 'alert-016', type: 'offline', title: '设备离线 · SL-2024-041', occurredAt: '2026-04-04T14:30:00+08:00', stage: 'archived', level: 'warning', earTag: 'SL-2024-041', priority: 'P1' },
  { id: 'alert-017', type: 'lowbattery', title: '低电量 · SL-2024-047', occurredAt: '2026-04-03T11:20:00+08:00', stage: 'archived', level: 'warning', earTag: 'SL-2024-047', priority: 'P1' },
  { id: 'alert-018', type: 'fever', title: '体温异常 · SL-2024-050', occurredAt: '2026-04-02T08:00:00+08:00', stage: 'archived', level: 'critical', earTag: 'SL-2024-050', priority: 'P0' },
];

const tenants = [
  { id: 'tenant_001', name: '华东示范牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: 'u_001', status: 'active', licenseUsed: 50, licenseTotal: 200, contactName: '张国庆', contactPhone: '13900010001', contactEmail: 'zhang@eastdairy.cn', region: '华东', remarks: '总部示范牧场，最先部署 IoT 设备。', createdAt: '2025-08-12T09:00:00+08:00', updatedAt: '2026-04-20T14:30:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_002', name: '西部高原牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: null, status: 'active', licenseUsed: 120, licenseTotal: 200, contactName: '索南扎西', contactPhone: '13900020002', contactEmail: 'szz@westplateau.cn', region: '西北', remarks: '高原牦牛试点，海拔 3500m。', createdAt: '2025-10-05T11:00:00+08:00', updatedAt: '2026-04-18T09:15:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_003', name: '东北黑土地牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: null, status: 'active', licenseUsed: 180, licenseTotal: 250, contactName: '王大壮', contactPhone: '13900030003', contactEmail: 'wangdz@northeast.cn', region: '东北', remarks: '大型肉牛育肥场，年出栏 5000+。', createdAt: '2025-09-20T08:30:00+08:00', updatedAt: '2026-04-15T16:45:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_004', name: '华南热带牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: null, status: 'disabled', licenseUsed: 30, licenseTotal: 100, contactName: '林伟雄', contactPhone: '13900040004', contactEmail: 'linwx@southtropic.cn', region: '华南', remarks: '热带环境试点，夏季高温预警测试。', createdAt: '2025-11-01T10:00:00+08:00', updatedAt: '2026-03-30T11:20:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_005', name: '西南高山牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: null, status: 'active', licenseUsed: 95, licenseTotal: 150, contactName: '杨志勇', contactPhone: '13900050005', contactEmail: 'yangzy@swhigh.cn', region: '西南', remarks: '山地放牧模式，GPS 信号挑战场景。', createdAt: '2025-12-15T14:00:00+08:00', updatedAt: '2026-04-22T08:00:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_006', name: '华北草原牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: null, status: 'active', licenseUsed: 75, licenseTotal: 180, contactName: '赵牧仁', contactPhone: '13900060006', contactEmail: 'zhaomr@northgrass.cn', region: '华北', remarks: '草原散养奶牛，乳制品供应链上游。', createdAt: '2026-01-10T09:30:00+08:00', updatedAt: '2026-04-25T13:10:00+08:00', lastUpdatedBy: '平台管理员', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  { id: 'tenant_007', name: '张三的第二牧场', type: 'farm', parentTenantId: null, billingModel: 'direct', entitlementTier: 'basic', ownerId: 'u_001', status: 'active', contactName: '张三', contactPhone: '13800000001', contactEmail: 'zhangsan@example.com', region: '华北', remarks: 'owner 多 farm 演示', licenseUsed: 0, licenseTotal: 50, createdAt: '2026-04-29T00:00:00+08:00', updatedAt: '2026-04-29T00:00:00+08:00', lastUpdatedBy: '系统初始化', contractId: null, revenueShareRatio: null, deploymentType: null, serviceKey: null, heartbeatAt: null, apiTier: null, apiKey: null, apiCallQuota: null, accessibleFarmTenantIds: null, deviceConfigRatio: null, livestockCount: null },
  {
    id: 'tenant_p001',
    name: '星辰牧业（代理商）',
    type: 'partner',
    parentTenantId: null,
    billingModel: 'revenue_share',
    entitlementTier: 'standard',
    ownerId: null,
    status: 'active',
    contactName: '王五',
    contactPhone: '13800000003',
    contactEmail: 'wangwu@example.com',
    region: '华中',
    remarks: 'B端客户示例',
    licenseUsed: 0,
    licenseTotal: 500,
    createdAt: '2026-04-28T00:00:00+08:00',
    updatedAt: '2026-04-28T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: 'contract_001',
    revenueShareRatio: 0.15,
    deploymentType: 'cloud',
    serviceKey: null,
    heartbeatAt: null,
    apiTier: null,
    apiKey: null,
    apiCallQuota: null,
    accessibleFarmTenantIds: null,
    deviceConfigRatio: null,
    livestockCount: null,
  },
  {
    id: 'tenant_f_p001_001',
    name: '星辰合作牧场A',
    type: 'farm',
    parentTenantId: 'tenant_p001',
    billingModel: 'revenue_share',
    entitlementTier: null,
    ownerId: 'u_006',
    status: 'active',
    contactName: '马七',
    contactPhone: '13800000005',
    contactEmail: 'maqi@example.com',
    region: '华中',
    remarks: 'partner 旗下示例牧场',
    licenseUsed: 0,
    licenseTotal: 200,
    createdAt: '2026-04-28T00:00:00+08:00',
    updatedAt: '2026-04-28T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: null,
    serviceKey: null,
    heartbeatAt: null,
    apiTier: null,
    apiKey: null,
    apiCallQuota: null,
    accessibleFarmTenantIds: null,
    deviceConfigRatio: { gpsRatio: 0.8, capsuleRatio: 0.2 },
    livestockCount: 150,
  },
  {
    id: 'tenant_a001',
    name: '数据科技公司（API）',
    type: 'api',
    parentTenantId: null,
    billingModel: 'api_usage',
    entitlementTier: null,
    ownerId: null,
    status: 'active',
    contactName: '赵六',
    contactPhone: '13800000004',
    contactEmail: 'zhaoliu@example.com',
    region: '华北',
    remarks: 'API客户示例',
    licenseUsed: 0,
    licenseTotal: 0,
    createdAt: '2026-04-28T00:00:00+08:00',
    updatedAt: '2026-04-28T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: null,
    serviceKey: null,
    heartbeatAt: null,
    apiTier: 'growth',
    apiKey: null,
    apiCallQuota: 10000,
    accessibleFarmTenantIds: ['tenant_001'],
    deviceConfigRatio: null,
    livestockCount: null,
  },
  {
    id: 'tenant_p002',
    name: '独立部署客户A',
    type: 'partner',
    parentTenantId: null,
    billingModel: 'licensed',
    entitlementTier: 'premium',
    ownerId: null,
    status: 'active',
    contactName: '赵九',
    contactPhone: '13800000008',
    contactEmail: null,
    region: '西南',
    remarks: '独立部署合作伙伴示例',
    licenseUsed: 0,
    licenseTotal: 300,
    createdAt: '2026-05-01T00:00:00+08:00',
    updatedAt: '2026-05-01T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: 'on_premise',
    serviceKey: null,
    heartbeatAt: null,
    apiTier: null,
    apiKey: null,
    apiCallQuota: null,
    accessibleFarmTenantIds: null,
    deviceConfigRatio: null,
    livestockCount: null,
  },
  {
    id: 'tenant_f_p002_001',
    name: '独立部署客户A合作牧场',
    type: 'farm',
    parentTenantId: 'tenant_p002',
    billingModel: 'licensed',
    entitlementTier: null,
    ownerId: null,
    status: 'active',
    contactName: '钱十',
    contactPhone: '13800000009',
    contactEmail: null,
    region: '西南',
    remarks: '独立部署合作伙伴旗下示例牧场',
    licenseUsed: 0,
    licenseTotal: 300,
    createdAt: '2026-05-01T00:00:00+08:00',
    updatedAt: '2026-05-01T00:00:00+08:00',
    lastUpdatedBy: '系统初始化',
    contractId: null,
    revenueShareRatio: null,
    deploymentType: null,
    serviceKey: null,
    heartbeatAt: null,
    apiTier: null,
    apiKey: null,
    apiCallQuota: null,
    accessibleFarmTenantIds: null,
    deviceConfigRatio: { gpsRatio: 0.7, capsuleRatio: 0.3 },
    livestockCount: 280,
  },
];

function generateDevices() {
  const result = [];
  function addBatch(count, idPrefix, type, namePrefix, onlineCount, offlineCount, lowBatteryCount) {
    for (let i = 1; i <= count; i++) {
      const id = `${idPrefix}-${i.toString().padStart(3, '0')}`;
      const name = `${namePrefix}-${i.toString().padStart(3, '0')}`;
      const earTag = `SL-2024-${i.toString().padStart(3, '0')}`;
      let status;
      if (i <= onlineCount) {
        status = 'online';
      } else if (i <= onlineCount + offlineCount) {
        status = 'offline';
      } else {
        status = 'lowBattery';
      }
      let batteryPercent;
      let signalStrength;
      let lastSync;
      if (status === 'online') {
        batteryPercent = 60 + ((i * 3) % 35);
        signalStrength = i % 3 === 0 ? '中' : '强';
        lastSync = `${1 + (i % 5)} 分钟前`;
      } else if (status === 'lowBattery') {
        batteryPercent = 5 + (i % 10);
        signalStrength = '弱';
        lastSync = `${10 + (i % 20)} 分钟前`;
      } else {
        batteryPercent = null;
        signalStrength = '无';
        lastSync = `${1 + (i % 6)} 小时前`;
      }
      result.push({
        id,
        name,
        type,
        status,
        boundEarTag: earTag,
        batteryPercent,
        signalStrength,
        lastSync,
      });
    }
  }
  addBatch(50, 'DEV-GPS', 'gps', 'GPS追踪器', 42, 4, 4);
  addBatch(30, 'DEV-RC', 'rumenCapsule', '瘤胃胶囊', 26, 2, 2);
  addBatch(20, 'DEV-ACC', 'accelerometer', '加速度计', 17, 2, 1);
  return result;
}

const devices = generateDevices();

module.exports = { users, dashboardMetrics, animals, fences, alerts, tenants, devices };
