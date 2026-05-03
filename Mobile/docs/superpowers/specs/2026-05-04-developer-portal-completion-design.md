# 开发者门户补全设计

> **状态**: Draft
> **Issue**: #37
> **所属计划**: Phase 2b — G2 开发者门户

## 背景

开发者门户骨架已搭建（7 个 View、3 个 Component、2 个 Store、3 个测试文件），但 Pinia stores 不完整，视图使用硬编码数据，部分组件和测试缺失。本设计补全 Store 层、新增 UsageChart 组件、创建缺失测试，并扩展后端 API 以支持 Store 调用真实接口。

### 当前状态

**已有**:
- 7 个 View（LoginView, RegisterView, DashboardView, ApiKeysView, EndpointsView, AuthorizationsView, SettingsView）
- 3 个 Component（AppLayout, MetricCard, ApiKeyDisplay）
- 2 个 Store（auth — 调用 `/api/v1/me`，dashboard — 硬编码数据）
- 1 个 API 模块（client.js — apiGet/apiPost/apiPut/apiDelete）
- 3 个测试文件（7 tests passing）

**缺失**:
- `UsageChart.vue` 组件（规格列出，用于 DashboardView 用量趋势图）
- `stores/apiKeys.js`（API Key 列表/轮换）
- `stores/authorizations.js`（授权申请列表/状态）
- `stores/endpoints.js`（端点文档数据）
- 4 个测试文件（AuthorizationsView, EndpointsView, SettingsView, RegisterView）

### 后端现状

- `apiKeyStore.js` 有完整 CRUD 数据层，但无 HTTP 路由暴露
- `apiAuthorizationRoutes.js` 的 GET `/` 仅允许 platform_admin 和 owner，api_consumer 无法查看自己的申请

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 图表库 | Chart.js | 成熟稳定，支持折线/柱状图，体积适中（~70KB gzip），与 Vue 3 兼容好 |
| 图表风格 | 折线图（Line Chart） | 最适合展示时间序列趋势，可叠加多端点对比线 |
| API Key 路由 | 新建后端路由 | apiKeyStore 已有数据层，只需薄路由层，保持三个 Store 模式统一 |
| 授权列表接口 | 扩展后端 GET `/` | 增加 api_consumer 分支，保持一致性 |
| Endpoints 数据来源 | 静态 JSON | 端点文档变更频率低，无需后端 API |

## 后端变更

### 1. 新建 `routes/apiKeyRoutes.js`

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/api-keys` | GET | 列出当前 api_consumer 的所有 Key | api_consumer |
| `/api/v1/api-keys/:id/rotate` | POST | 轮换指定 Key | api_consumer |

实现要点：
- GET `/`：从 `req.user.tenantId` 获取 api_consumer 的 tenantId，调 `apiKeyStore.listByTenantId(tenantId)`
- POST `/:id/rotate`：校验 keyId 属于当前 tenant，调 `apiKeyStore.rotate(tenantId)`（rotate 以 tenantId 为粒度，将所有 active key 标记为 rotating 并生成新 key）
- 注册到 `registerApiRoutes.js`

### 2. 扩展 `apiAuthorizationRoutes.js` GET `/`

在现有 platform_admin 和 owner 分支后，增加 api_consumer 分支：
- 从 `req.user.tenantId` 查询 `apiAuthorizationStore` 中该 tenant 提交的所有申请
- 支持分页参数

## 前端变更

### 3. 新增 `components/UsageChart.vue`

- **技术**: Chart.js Line Chart
- **Props**: `labels: string[]`（日期标签）、`datasets: object[]`（Chart.js dataset 格式）
- **实现**:
  - `<script setup>` + Canvas `<canvas ref="chartRef">`
  - `onMounted` 初始化 Chart.js 实例
  - `watch` props 变化时 `chart.update()`
  - `onBeforeUnmount` 调 `chart.destroy()`
- **默认配置**: 绿色主色 `#2e7d32`，平滑曲线 `tension: 0.4`，hover tooltip，无图例
- **依赖**: `npm install chart.js`

### 4. 新增 `stores/apiKeys.js`

```javascript
state: { keys: [], loading: false, error: null }
actions:
  - fetchKeys(token) → apiGet('/api-keys', token)
  - rotateKey(keyId, token) → apiPost(`/api-keys/${keyId}/rotate`, {}, token)
```

### 5. 新增 `stores/authorizations.js`

```javascript
state: { authorizations: [], loading: false, error: null }
actions:
  - fetchAuthorizations(token) → apiGet('/api-authorizations', token)
  - submitAuthorization({ farmTenantId, requestedScopes }, token)
    → apiPost('/api-authorizations', { farmTenantId, requestedScopes }, token)
```

### 6. 新增 `stores/endpoints.js`

```javascript
state: { tiers: [/* 静态数据，从 EndpointsView 迁移 */] }
actions:
  - loadEndpoints() — 从本地静态数据填充（不调 API）
```

将 EndpointsView 中现有的 `tiers` 数组移入此 Store。

### 7. 重构视图

| View | 变更 |
|------|------|
| ApiKeysView | 移除硬编码 `keys` ref → `useApiKeysStore().fetchKeys(token)` |
| AuthorizationsView | 移除硬编码 `authorizations` ref → `useAuthorizationsStore()` |
| EndpointsView | 移除硬编码 `tiers` → `useEndpointsStore()` |
| DashboardView | 导入 `UsageChart`，在 MetricCards 和表格之间插入趋势图 |

### 8. DashboardView 趋势图数据

从 `dashboardStore.recentUsage`（已有，按日期+端点的调用记录）聚合为每日总调用量，传给 UsageChart：
- `labels`: 去重日期列表（升序）
- `datasets[0].data`: 每日调用量总和

## 测试

### 新增测试文件

| 文件 | 覆盖内容 |
|------|---------|
| `test/AuthorizationsView.test.js` | 渲染授权列表、新建申请表单展开/收起、状态标签、提交逻辑（mock store） |
| `test/EndpointsView.test.js` | 渲染 tier 分组标题、端点表格行、方法标签（GET/POST 等）颜色 |
| `test/SettingsView.test.js` | 渲染账户信息表、API 使用限制文案、未登录时字段降级 |
| `test/RegisterView.test.js` | 渲染占位文案、联系信息、登录链接导航 |

### 更新现有测试

| 文件 | 变更 |
|------|------|
| `test/DashboardView.test.js` | 增加 UsageChart 组件渲染断言（stub Chart canvas） |
| `test/ApiKeysView.test.js` | 改为通过 mock Pinia store 测试（替代硬编码数据断言） |

### 测试模式

沿用现有模式：`vitest` + `@vue/test-utils` + `createPinia()` + stub `AppLayout`。Store 测试通过 `setActivePinia()` 初始化，mock `apiGet`/`apiPost` 的返回值。

## 验收标准

与 Issue #37 对齐：

- [ ] 新增 `UsageChart.vue` 组件，在 DashboardView 中展示调用量趋势
- [ ] 新增 `stores/apiKeys.js` — 调用 `/api/v1/api-keys` 接口（Key 列表、轮换）
- [ ] 新增 `stores/authorizations.js` — 调用 `/api/v1/api-authorizations` 接口
- [ ] 新增 `stores/endpoints.js` — 端点文档数据
- [ ] 补全 4 个缺失的测试文件
- [ ] `vitest run` 全部通过

## 涉及文件

| 操作 | 文件 |
|------|------|
| 新建 | `backend/routes/apiKeyRoutes.js` |
| 修改 | `backend/routes/registerApiRoutes.js` |
| 修改 | `backend/routes/apiAuthorizationRoutes.js` |
| 新建 | `developer-portal/src/components/UsageChart.vue` |
| 新建 | `developer-portal/src/stores/apiKeys.js` |
| 新建 | `developer-portal/src/stores/authorizations.js` |
| 新建 | `developer-portal/src/stores/endpoints.js` |
| 修改 | `developer-portal/src/views/DashboardView.vue` |
| 修改 | `developer-portal/src/views/ApiKeysView.vue` |
| 修改 | `developer-portal/src/views/AuthorizationsView.vue` |
| 修改 | `developer-portal/src/views/EndpointsView.vue` |
| 修改 | `developer-portal/package.json` |
| 新建 | `developer-portal/test/AuthorizationsView.test.js` |
| 新建 | `developer-portal/test/EndpointsView.test.js` |
| 新建 | `developer-portal/test/SettingsView.test.js` |
| 新建 | `developer-portal/test/RegisterView.test.js` |
| 修改 | `developer-portal/test/DashboardView.test.js` |
| 修改 | `developer-portal/test/ApiKeysView.test.js` |
