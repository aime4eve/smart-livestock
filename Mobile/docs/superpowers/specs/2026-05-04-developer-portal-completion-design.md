# 开发者门户补全设计

> **状态**: Implemented
> **Issue**: #37
> **所属计划**: Phase 2b — G2 开发者门户

## 背景

开发者门户骨架已搭建（7 个 View、3 个 Component、2 个 Store、3 个测试文件），但 Pinia stores 不完整，视图使用硬编码数据，部分组件和测试缺失。本设计补全 Store 层、新增 UsageChart 组件、创建缺失测试，并扩展后端 API 以支持 Store 调用真实接口。

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 图表库 | Chart.js（手动组件注册） | tree-shaking 友好，体积适中 |
| 图表风格 | 折线图（Line Chart） | 最适合展示时间序列趋势 |
| API Key 路由 | 新建后端路由 | apiKeyStore 已有数据层，只需薄路由层 |
| 授权列表接口 | 扩展后端 GET `/` | 增加 api_consumer 分支 |
| Endpoints 数据 | 真实 OpenAPI 端点数据 | 按实际 `/api/open/v1/*` 路由编写，含参数/响应/错误码 |
| AppLayout 修复 | `<router-view />` → `<slot />` | 原架构导致无限递归，改为 slot 透传 |
| Vite proxy | `/api` → `localhost:3001` | 前端 API 请求通过代理转发到后端 |
| Key 创建/轮换 | 操作后展示 rawKey + 复制按钮 | rawKey 仅创建时可见，关闭后无法再查看 |
| 授权详情 | 可展开行 + 到期提醒 + 重新申请 | 完整授权生命周期展示 |
| 授权 expiresAt | approve 时设置 reviewedAt + 12 个月 | 符合 Phase 2b 规格的 12 个月有效期 |
| 牧场下拉 | 真实 tenantId + 中文名映射 | 后端校验需要真实 tenantId，不能传中文名 |

## 后端变更

### 1. 新建 `routes/apiKeyRoutes.js`

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/api-keys` | GET | 列出当前 api_consumer 的所有 Key | api_consumer |
| `/api/v1/api-keys` | POST | 生成新 API Key | api_consumer |
| `/api/v1/api-keys/:id/rotate` | POST | 轮换指定 Key（以 tenant 粒度） | api_consumer |

### 2. 扩展 `apiAuthorizationRoutes.js` GET `/`

增加 `api_consumer` 分支，使用 `apiAuthorizationStore.list({ apiTenantId: req.user.tenantId, ...req.query })` 过滤。

### 3. 扩展 `apiAuthorizationStore.js` approve()

- 新增 `expiresAt` 字段：审批时间 + 12 个月
- `create()` 初始化 `expiresAt: null`

## 前端变更

### 4. 新增 `components/UsageChart.vue`

Chart.js Line Chart，手动注册组件（LineController, LineElement, PointElement, LinearScale, CategoryScale, Filler, Tooltip），绿色主色 `#2e7d32`，`tension: 0.4`。

### 5. 新增 `stores/apiKeys.js`

`fetchKeys`、`createKey`（返回 rawKey）、`rotateKey`（返回 rawKey）。

### 6. 新增 `stores/authorizations.js`

`fetchAuthorizations`、`submitAuthorization`。

### 7. 新增 `stores/endpoints.js`

真实 OpenAPI 端点数据：Free（4 个 GET :id 端点）、Growth（3 个 GET list + 1 个 POST batch）、Scale（3 个 GET list + 1 个 POST batch）。每个端点含 params、query、body、response、errors。附带认证方式、频率限制、通用错误码。

### 8. 重构视图

| View | 变更 |
|------|------|
| DashboardView | 导入 UsageChart，MetricCards 和表格之间插入趋势图 |
| ApiKeysView | 用 Store 替代硬编码；创建/轮换后弹出 rawKey 展示对话框 + 复制按钮 |
| AuthorizationsView | 用 Store 替代硬编码；可展开详情行（审批时间/到期时间/备注）；到期提醒（30天内红色）；被拒/撤销后"重新申请"；牧场下拉用真实 tenantId |
| EndpointsView | 用 Store 替代硬编码；展示认证方式/频率限制/错误码；可展开端点详情（参数/响应/错误） |
| AppLayout | `<router-view />` → `<slot />`（修复无限递归） |

### 9. Vite proxy 配置

`vite.config.js` 添加 `proxy: { '/api': 'http://localhost:3001' }`，前端 API 请求自动转发到后端。

## 测试

7 个测试文件，22 个测试，全部通过：

| 文件 | 测试数 |
|------|--------|
| LoginView.test.js | 2 |
| DashboardView.test.js | 3 |
| ApiKeysView.test.js | 3 |
| RegisterView.test.js | 3 |
| SettingsView.test.js | 3 |
| EndpointsView.test.js | 4 |
| AuthorizationsView.test.js | 4 |

## 验收标准

与 Issue #37 对齐，全部达成：

- [x] 新增 `UsageChart.vue` 组件，在 DashboardView 中展示调用量趋势
- [x] 新增 `stores/apiKeys.js` — 调用 `/api/v1/api-keys` 接口（Key 列表、创建、轮换）
- [x] 新增 `stores/authorizations.js` — 调用 `/api/v1/api-authorizations` 接口
- [x] 新增 `stores/endpoints.js` — 真实 OpenAPI 端点文档数据（含参数/响应/错误码）
- [x] 补全 4 个缺失测试文件
- [x] `vitest run` 全部通过（22/22）

## 涉及文件

| 操作 | 文件 |
|------|------|
| 新建 | `backend/routes/apiKeyRoutes.js` |
| 修改 | `backend/routes/registerApiRoutes.js` |
| 修改 | `backend/routes/apiAuthorizationRoutes.js` |
| 修改 | `backend/data/apiAuthorizationStore.js` |
| 新建 | `developer-portal/src/components/UsageChart.vue` |
| 新建 | `developer-portal/src/stores/apiKeys.js` |
| 新建 | `developer-portal/src/stores/authorizations.js` |
| 新建 | `developer-portal/src/stores/endpoints.js` |
| 修改 | `developer-portal/src/views/DashboardView.vue` |
| 修改 | `developer-portal/src/views/ApiKeysView.vue` |
| 修改 | `developer-portal/src/views/AuthorizationsView.vue` |
| 修改 | `developer-portal/src/views/EndpointsView.vue` |
| 修改 | `developer-portal/src/components/AppLayout.vue` |
| 修改 | `developer-portal/vite.config.js` |
| 修改 | `developer-portal/package.json` |
| 新建 | `developer-portal/test/AuthorizationsView.test.js` |
| 新建 | `developer-portal/test/EndpointsView.test.js` |
| 新建 | `developer-portal/test/SettingsView.test.js` |
| 新建 | `developer-portal/test/RegisterView.test.js` |
| 修改 | `developer-portal/test/DashboardView.test.js` |
| 修改 | `developer-portal/test/ApiKeysView.test.js` |
