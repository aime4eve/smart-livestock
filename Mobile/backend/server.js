const express = require('express');
const cors = require('cors');
const path = require('path');

const { buildRuntimeConfig } = require('./config/runtimeConfig');
const { envelopeMiddleware } = require('./middleware/envelope');
const { requestContext } = require('./middleware/requestContext');
const { authMiddleware } = require('./middleware/auth');
const { farmContextMiddleware } = require('./middleware/farmContext');
const { shapingMiddleware } = require('./middleware/feature-flag');
const { registerApiRoutes } = require('./routes/registerApiRoutes');
const subscriptionStore = require('./data/subscriptions');
const subscriptionServiceStore = require('./data/subscriptionServiceStore');
const apiKeyStore = require('./data/apiKeyStore');
const tenantStore = require('./data/tenantStore');

const app = express();
const PORT = 3001;
const runtimeConfig = buildRuntimeConfig();

// ===== 基础中间件 =====
app.use(cors());
app.use(express.json());
app.use(requestContext(runtimeConfig));
app.use(envelopeMiddleware);

// ===== 全局中间件链 =====
// 顺序约束（不可变）: auth → farmContext → shaping
app.use(authMiddleware);           // 1. 认证 + 注入 req.user
app.use(farmContextMiddleware);    // 2. 提取 req.activeFarmTenantId
app.use(shapingMiddleware);        // 3. 包装 res.ok() 加入 shaping

// ===== App API 路由 (/api/v1/*) =====
registerApiRoutes(app, '/api');
registerApiRoutes(app, '/api/v1');

// ===== Open API 路由 (/api/open/v1/*) =====
const openApiRouter = require('./routes/openApiRoutes');
app.use('/api/open/v1', openApiRouter);

// ===== 开发者门户静态托管 =====
app.use('/developer', express.static(path.join(__dirname, '../developer-portal/dist')));
// SPA fallback: 非静态文件子路由回退到 index.html
app.use('/developer', (req, res) => {
  if (req.method === 'GET') {
    res.sendFile(path.join(__dirname, '../developer-portal/dist/index.html'));
  }
});

// ===== 启动时全量扫描 =====
subscriptionServiceStore.scan();                        // 订阅服务状态扫描
apiKeyStore.scanRevokeRotatingKeys();                   // API Key 轮换撤销扫描

// ===== 定时任务 =====
setInterval(() => subscriptionServiceStore.scan(), 60_000);
setInterval(() => apiKeyStore.scanRevokeRotatingKeys(), 3_600_000);

// ===== seed trial subscriptions =====
const allTenants = tenantStore.getAll();
allTenants.filter(t => t.type === 'farm').forEach(t => {
  if (!subscriptionStore.getByTenantId(t.id)) {
    subscriptionStore.createTrial(t.id);
  }
});

// ===== seed revenue periods =====
const revenueStore = require('./data/revenueStore');
['2026-01', '2026-02', '2026-03', '2026-04'].forEach((p) => {
  revenueStore.calculate(p, 'monthly');
});
// 2026-01, 2026-02: both sides confirmed → settled
['2026-01', '2026-02'].forEach((period) => {
  const periods = revenueStore.getPeriods({}).items;
  const match = periods.find(p => p.period === period);
  if (match) {
    revenueStore.confirm(match.id, 'platform_admin', null);
    revenueStore.confirm(match.id, 'b2b_admin', 'tenant_p001');
  }
});
// 2026-03: platform pre-confirmed only, so b2b_admin confirm will settle it
{
  const periods = revenueStore.getPeriods({}).items;
  const match = periods.find(p => p.period === '2026-03');
  if (match) {
    revenueStore.confirm(match.id, 'platform_admin', null);
  }
}

// ===== 404 fallback =====
app.use((req, res) => {
  res.fail(404, 'RESOURCE_NOT_FOUND', `路由不存在: ${req.method} ${req.path}`);
});

// ===== ROUTE_DEFINITIONS =====
const API_PREFIXES = ['/api', '/api/v1'];
const ROUTE_DEFINITIONS = [
  // --- Phase 2a 现有端点 ---
  ['POST',   '/auth/login'],
  ['GET',    '/me'],
  ['GET',    '/dashboard/summary'],
  ['GET',    '/map/trajectories'],
  ['GET',    '/alerts'],
  ['POST',   '/alerts/:id/ack'],
  ['POST',   '/alerts/:id/handle'],
  ['POST',   '/alerts/:id/archive'],
  ['POST',   '/alerts/batch-handle'],
  ['GET',    '/fences'],
  ['GET',    '/fences/:id'],
  ['POST',   '/fences'],
  ['PUT',    '/fences/:id'],
  ['DELETE', '/fences/:id'],
  ['GET',    '/tenants'],
  ['GET',    '/tenants/:id'],
  ['POST',   '/tenants'],
  ['PUT',    '/tenants/:id'],
  ['DELETE', '/tenants/:id'],
  ['POST',   '/tenants/:id/status'],
  ['POST',   '/tenants/:id/license'],
  ['GET',    '/tenants/:id/devices'],
  ['GET',    '/tenants/:id/logs'],
  ['GET',    '/tenants/:id/stats'],
  ['GET',    '/tenants/:id/trends'],
  ['GET',    '/profile'],
  ['GET',    '/twin/overview'],
  ['GET',    '/twin/fever/list'],
  ['GET',    '/twin/fever/:id'],
  ['GET',    '/twin/digestive/list'],
  ['GET',    '/twin/digestive/:id'],
  ['GET',    '/twin/estrus/list'],
  ['GET',    '/twin/estrus/:id'],
  ['GET',    '/twin/epidemic/summary'],
  ['GET',    '/twin/epidemic/contacts'],
  ['GET',    '/devices'],
  ['GET',    '/subscription/current'],
  ['GET',    '/subscription/features'],
  ['GET',    '/subscription/plans'],
  ['POST',   '/subscription/checkout'],
  ['POST',   '/subscription/cancel'],
  ['POST',   '/subscription/renew'],
  ['GET',    '/subscription/usage'],
  ['GET',    '/b2b/dashboard'],
  ['GET',    '/b2b/farms'],
  ['POST',   '/b2b/farms'],
  ['GET',    '/b2b/contract/current'],
  ['GET',    '/b2b/contract/usage-summary'],
  ['GET',    '/farm/my-farms'],
  ['POST',   '/farm/switch-farm'],
  ['GET',    '/farms/:farmId/workers'],
  ['POST',   '/farms/:farmId/workers'],
  ['DELETE', '/farms/:farmId/workers/:id'],

  // --- E5 订阅服务管理 ---
  ['GET',    '/subscription-services'],
  ['POST',   '/subscription-services'],
  ['GET',    '/subscription-services/:id'],
  ['POST',   '/subscription-services/:id/renew'],
  ['POST',   '/subscription-services/:id/revoke'],
  ['POST',   '/subscription-services/heartbeat'],

  // --- E6 合同管理 ---
  ['GET',    '/contracts'],
  ['POST',   '/contracts'],
  ['GET',    '/contracts/:id'],
  ['PUT',    '/contracts/:id'],
  ['POST',   '/contracts/:id/terminate'],
  // --- E4 分润对账 ---
  ['GET',    '/revenue/periods'],
  ['GET',    '/revenue/periods/:id'],
  ['POST',   '/revenue/periods/:id/confirm'],
  ['POST',   '/revenue/calculate'],
];
const ROUTE_TABLE = API_PREFIXES.flatMap((prefix) =>
  ROUTE_DEFINITIONS.map(([method, path]) => [method, `${prefix}${path}`])
);

// --- G1 Open API (mounted at /api/open/v1/ via openApiRouter, NOT via registerApiRoutes) ---
const OPEN_API_ROUTES = [
  ['GET',    '/twin/fever/:id'],
  ['GET',    '/twin/estrus/:id'],
  ['GET',    '/twin/digestive/:id'],
  ['GET',    '/twin/health/:id'],
  ['GET',    '/twin/fever/list'],
  ['GET',    '/twin/estrus/list'],
  ['GET',    '/twin/epidemic/summary'],
  ['POST',   '/twin/health/batch'],
  ['GET',    '/cattle/list'],
  ['GET',    '/fence/list'],
  ['GET',    '/alert/list'],
  ['POST',   '/twin/fever/batch'],
  ['POST',   '/register'],
];

// Start server
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n  Mock API Server running at http://localhost:${PORT}\n`);
    console.log('  App API routes (/api + /api/v1):');
    ROUTE_TABLE.forEach(([method, path]) =>
      console.log(`  ${method.padEnd(7)} ${path}`)
    );
    console.log('\n  Open API routes (/api/open/v1):');
    OPEN_API_ROUTES.forEach(([method, path]) =>
      console.log(`  ${method.padEnd(7)} ${'/api/open/v1' + path}`)
    );
    console.log('');
  });
}

module.exports = { app };
