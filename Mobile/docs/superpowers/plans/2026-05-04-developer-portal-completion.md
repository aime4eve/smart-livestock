# 开发者门户补全 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补全开发者门户缺失的 Pinia Store、UsageChart 组件和测试文件，扩展后端 API Key 路由和授权接口，使门户从硬编码数据切换到真实 API 调用。

**Architecture:** 后端新建 apiKeyRoutes 暴露 Key 管理端点 + 扩展 apiAuthorizationRoutes 支持 api_consumer 查看自己的授权。前端新建 3 个 Pinia Store（apiKeys/authorizations/endpoints）+ UsageChart 组件（Chart.js 折线图），重构 4 个 View 使用 Store 替代硬编码数据。新增 4 个测试 + 更新 2 个现有测试。

**Tech Stack:** Vue 3 + Pinia + Chart.js (frontend), Node.js + Express 5 (backend), vitest + @vue/test-utils (tests)

**被实施规格:** `docs/superpowers/specs/2026-05-04-developer-portal-completion-design.md`

**前置 Issue:** #37

**状态:** ✅ 全部完成 — 22/22 测试通过

---

## File Structure

| 操作 | 文件 | 职责 |
|------|------|------|
| 新建 | `backend/routes/apiKeyRoutes.js` | API Key 列表 + 创建 + 轮换端点 |
| 修改 | `backend/routes/registerApiRoutes.js` | 注册 apiKeyRoutes |
| 修改 | `backend/routes/apiAuthorizationRoutes.js` | 增加 api_consumer GET 分支 |
| 修改 | `backend/data/apiAuthorizationStore.js` | 新增 expiresAt 字段（12 个月有效期） |
| 新建 | `developer-portal/src/components/UsageChart.vue` | Chart.js 折线图组件 |
| 修改 | `developer-portal/src/components/AppLayout.vue` | 修复 `<router-view />` → `<slot />` |
| 新建 | `developer-portal/src/stores/apiKeys.js` | API Key Pinia Store（含 createKey 返回 rawKey） |
| 新建 | `developer-portal/src/stores/authorizations.js` | 授权 Pinia Store |
| 新建 | `developer-portal/src/stores/endpoints.js` | 真实 OpenAPI 端点文档数据 |
| 修改 | `developer-portal/src/views/DashboardView.vue` | 插入 UsageChart |
| 修改 | `developer-portal/src/views/ApiKeysView.vue` | 用 Store + 创建/轮换 rawKey 展示 + 复制按钮 |
| 修改 | `developer-portal/src/views/AuthorizationsView.vue` | 用 Store + 可展开详情 + 到期提醒 + 重新申请 |
| 修改 | `developer-portal/src/views/EndpointsView.vue` | 用 Store + 认证/频率限制/错误码/可展开端点详情 |
| 修改 | `developer-portal/vite.config.js` | 添加 API proxy `/api` → `localhost:3001` |
| 修改 | `developer-portal/package.json` | 添加 chart.js 依赖 |
| 新建 | `developer-portal/test/AuthorizationsView.test.js` | 授权页测试（4 tests） |
| 新建 | `developer-portal/test/EndpointsView.test.js` | 端点页测试（4 tests） |
| 新建 | `developer-portal/test/SettingsView.test.js` | 设置页测试（3 tests） |
| 新建 | `developer-portal/test/RegisterView.test.js` | 注册页测试（3 tests） |
| 修改 | `developer-portal/test/DashboardView.test.js` | 增加 UsageChart 测试（3 tests） |
| 修改 | `developer-portal/test/ApiKeysView.test.js` | 改用 mock Store 测试（3 tests） |

---

## Task 1: Backend — API Key 路由（含创建端点）

**Files:**
- Create: `backend/routes/apiKeyRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`

- [x] **Step 1: 创建 apiKeyRoutes.js**

3 个端点：GET /（列表）、POST /（创建，返回 rawKey）、POST /:id/rotate（轮换，返回 rawKey）。

- [x] **Step 2: 注册路由到 registerApiRoutes.js**

- [x] **Step 3: Commit**

```
feat(backend): add API Key management routes for developer portal
```

---

## Task 2: Backend — 扩展 apiAuthorizationRoutes 支持 api_consumer

**Files:**
- Modify: `backend/routes/apiAuthorizationRoutes.js`
- Modify: `backend/data/apiAuthorizationStore.js`

- [x] **Step 1: 修改 GET `/` 处理器 — 增加 api_consumer 分支**

- [x] **Step 2: apiAuthorizationStore — 新增 expiresAt 字段**

`create()` 初始化 `expiresAt: null`，`approve()` 设置 `expiresAt = reviewedAt + 12 个月`。

- [x] **Step 3: Commit**

```
feat(backend): allow api_consumer to list own authorizations + add expiresAt
```

---

## Task 3: Frontend — 安装 Chart.js + 创建 UsageChart 组件

**Files:**
- Modify: `developer-portal/package.json`
- Create: `developer-portal/src/components/UsageChart.vue`

- [x] **Step 1: 安装 chart.js**
- [x] **Step 2: 创建 UsageChart.vue — Chart.js Line Chart，手动注册组件，绿色主色 `#2e7d32`，`tension: 0.4`**
- [x] **Step 3: Commit**

---

## Task 4: Frontend — 创建 endpoints Store + 重构 EndpointsView

**Files:**
- Create: `developer-portal/src/stores/endpoints.js`
- Modify: `developer-portal/src/views/EndpointsView.vue`

- [x] **Step 1: 创建 endpoints store — 真实 OpenAPI 端点数据**

Free（4 个 GET :id 端点）、Growth（3 个 GET list + 1 个 POST batch）、Scale（3 个 GET list + 1 个 POST batch）。每个端点含 params、query、body、response、errors。附带 authInfo（API Key）、rateLimit（100/min）、commonErrors。

- [x] **Step 2: 重构 EndpointsView — 认证方式卡片 + 频率限制卡片 + 通用错误码表 + 按层级分组端点 + 可展开详情（参数/响应/错误）**

- [x] **Step 3: Commit**

---

## Task 5: Frontend — 创建 apiKeys Store + 重构 ApiKeysView

**Files:**
- Create: `developer-portal/src/stores/apiKeys.js`
- Modify: `developer-portal/src/views/ApiKeysView.vue`

- [x] **Step 1: 创建 apiKeys store — fetchKeys、createKey（返回 rawKey）、rotateKey（返回 rawKey）**
- [x] **Step 2: 重构 ApiKeysView — Store 替代硬编码；创建 Key 对话框；轮换 Key 对话框；rawKey 展示对话框 + 复制按钮（clipboard API + fallback）**
- [x] **Step 3: Commit**

---

## Task 6: Frontend — 创建 authorizations Store + 重构 AuthorizationsView

**Files:**
- Create: `developer-portal/src/stores/authorizations.js`
- Modify: `developer-portal/src/views/AuthorizationsView.vue`

- [x] **Step 1: 创建 authorizations store — fetchAuthorizations、submitAuthorization**
- [x] **Step 2: 重构 AuthorizationsView — Store 替代硬编码；可展开详情行（审批时间/到期时间/备注）；到期提醒（30 天内红色）；被拒/撤销后"重新申请"；牧场下拉用真实 tenantId**
- [x] **Step 3: Commit**

---

## Task 7: Frontend — DashboardView 集成 UsageChart

**Files:**
- Modify: `developer-portal/src/views/DashboardView.vue`

- [x] **Step 1: 在 MetricCards 和表格之间插入 UsageChart，从 recentUsage 聚合每日总调用量**
- [x] **Step 2: Commit**

---

## Task 8: Frontend — 修复 AppLayout 无限递归 + Vite proxy

**Files:**
- Modify: `developer-portal/src/components/AppLayout.vue`
- Modify: `developer-portal/vite.config.js`

- [x] **Step 1: AppLayout.vue `<router-view />` → `<slot />` — 修复所有页面白屏（无限递归 bug）**
- [x] **Step 2: vite.config.js 添加 `proxy: { '/api': 'http://localhost:3001' }`**
- [x] **Step 3: Commit**

---

## Task 9: Tests — 新增 4 个测试 + 更新 2 个测试

**Files:**
- Create: `developer-portal/test/RegisterView.test.js`（3 tests）
- Create: `developer-portal/test/SettingsView.test.js`（3 tests）
- Create: `developer-portal/test/EndpointsView.test.js`（4 tests）
- Create: `developer-portal/test/AuthorizationsView.test.js`（4 tests）
- Modify: `developer-portal/test/DashboardView.test.js`（3 tests）
- Modify: `developer-portal/test/ApiKeysView.test.js`（3 tests）

- [x] **Step 1: 创建 RegisterView.test.js**
- [x] **Step 2: 创建 SettingsView.test.js**
- [x] **Step 3: 创建 EndpointsView.test.js — 更新断言匹配真实 OpenAPI 数据（Free/Growth/Scale、GET/POST、认证方式、X-API-Key、method-badge）**
- [x] **Step 4: 创建 AuthorizationsView.test.js — 含 mock API client**
- [x] **Step 5: 更新 DashboardView.test.js — 含 UsageChart stub**
- [x] **Step 6: 更新 ApiKeysView.test.js — mock API client + Store 架构**
- [x] **Step 7: 运行全部测试 — 22/22 PASS**
- [x] **Step 8: Commit**

---

## Task 10: 最终验证

- [x] **Step 1: `vitest run` 全部通过（22/22）**
- [x] **Step 2: 后端测试通过**
- [x] **Step 3: 构建验证通过**

---

## 实施记录

| 日期 | 变更 | 备注 |
|------|------|------|
| 2026-05-04 | Task 1-9 全部完成 | 22/22 测试通过 |
| 2026-05-04 | 修复 AppLayout 白屏 bug | `<router-view />` → `<slot />` |
| 2026-05-04 | 补充 API Key 创建端点 + rawKey 展示/复制 | POST / + 对话框 + clipboard API |
| 2026-05-04 | 授权详情增强 | 可展开行 + 到期提醒 + 重新申请 |
| 2026-05-04 | 接口文档重写 | 真实 OpenAPI 数据（参数/响应/错误码） |
| 2026-05-04 | 新增 expiresAt（12 个月有效期） | apiAuthorizationStore approve 时设置 |
