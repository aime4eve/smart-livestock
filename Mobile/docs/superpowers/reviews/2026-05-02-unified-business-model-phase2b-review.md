# 统一商业模型 Phase 2b 设计规格 — 评审报告

**评审日期**: 2026-05-02
**评审文档**: `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` (v1.0)
**前置文档**:
- `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3)
- `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md` (v1.3)
**评审人**: AI Code Reviewer
**状态**: 有条件通过

**修订历史**:
- v1.0 (2026-05-02): 初版评审报告
- v1.1 (2026-05-02): 评审意见判断与修复完成，所有 P0/P1/P2 已修正到规格文档 v1.1

---

## 总体评价

文档结构清晰、模块划分合理，依赖关系图和交付清单完整。9 大模块（E4~E9 + G1~G3）的端点设计、数据模型、前端 UI 描述充分。主要风险集中在全局中间件链与双认证体系的冲突，以及部分数据模型细节缺失。建议修复 P0 问题后再进入实施。

---

## P0 — 阻塞问题（必须在实施前修复）

### P0-1: E4 分润计算缺少设备配置单价定义

`4.1` 中的公式 `∑(每个 farm 的牛数 × 设备配置单价)` 引用了"设备配置单价"，但：
- 父规格 Section 4.2 定义 GPS 为 `¥c`/牛/月、胶囊为 `¥d`/牛/月，标注为 TBD
- Phase 2b 规格未给出确定值，也未标注 TBD
- `RevenueFarmItem.deviceFee` 的计算公式无法实现

**建议**：在 E4 中明确定义设备单价常量（至少给 Mock 环境的占位值，如 GPS=¥15/月、胶囊=¥30/月），与父规格端到端计费示例保持一致。

### P0-2: E5 心跳端点认证矛盾

`5.3` 端点表写 `POST /api/v1/subscription-services/heartbeat` 权限为"无需认证（凭 serviceKey）"。但：
- `authMiddleware` 是全局注册的（`server.js:25`），未认证请求在到达路由前就会被拦截
- 全局中间件链是 `auth → farmContext → shaping`，无认证的请求如何通过？

**建议**：在 `auth.js` 中为 `/api/v1/subscription-services/heartbeat` 路径添加白名单跳过 Bearer 校验；或在 Open API 中间件中统一处理。同时说明 `apiKeyAuthMiddleware` 和全局 `authMiddleware` 的注册顺序关系——Phase 2b 新增的两个中间件（`apiKeyAuth.js`、`rateLimit.js`）插在中间件链的哪个位置？

### P0-3: E9 apiKeyStore.validate() 返回 apiTier，但 apiTier 不在 apiKeyStore 中

`9.2` 定义 `validate(rawKey)` 返回 `apiTenantId + apiTier`。但 apiKeyStore 只存 `keyHash`、`keyPrefix` 等字段，apiTier 存储在 `apiTierStore` 中。validate 方法需要跨 Store 查询。

**建议**：明确 `validate()` 的跨 Store 依赖（查 apiKeyStore → 拿 apiTenantId → 查 apiTierStore → 组合返回），或在返回值中去掉 apiTier，让调用方自己查。

### P0-4: G1 Open API 与全局中间件链的冲突

父规格和 `server.js` 确认中间件链为 `auth → farmContext → shaping`（全局注册）。Phase 2b 新增 `/api/open/v1/*` 使用 `X-API-Key` 认证。但：
- 全局 `authMiddleware` 会要求 Bearer token，API Key 请求无法通过
- 全局 `farmContextMiddleware` 会为所有请求设置 `activeFarmTenantId`，但 API 请求不应有 farm context
- 全局 `shapingMiddleware` 使用 `getEffectiveTier(activeFarmTenantId)`，而 Open API 应使用 `req.apiTier`

规格 `横切关注点` 提到了 shaping 分叉，但未说明中间件注册策略变更。

**建议**：在 `横切关注点` 中明确中间件链的新设计：

```
方案A: auth 白名单 + shaping 内部分叉
  - auth.js: /api/open/v1/* 路径跳过 Bearer 校验
  - apiKeyAuth.js: 在 auth 之后注册，仅匹配 /api/open/v1/*
  - farmContext.js: 跳过有 req.apiConsumer 的请求
  - shaping: 内部分叉（已有描述）

方案B: Open API 使用独立 Express Router
  - app.use('/api/open/v1', openApiRouter)
  - openApiRouter 内部注册 apiKeyAuth + rateLimit
```

建议选择方案 B（独立 Router），更干净地隔离两套认证体系。

---

## P1 — 重要问题（实施时必须解决）

### P1-1: E6 Contract 新增端点与 Phase 2a 端点的数据一致性

`6.2` 定义 `PUT /api/v1/contracts/:id` 可编辑合同（含 `revenueShareRatio`）。但 Phase 2a 的 `GET /api/v1/b2b/contract/current` 缓存可能已在前端保留旧值。规格未提及：
- 合同编辑后如何通知 b2b_admin 端刷新
- tenant 上的 `revenueShareRatio` 快照何时同步（`E8 8.2` 说"合同创建/更新时同步"，但未定义是同步还是异步）

**建议**：在 E6 中明确合同变更后的同步时机（Mock 环境中可直接同步，无需异步）。

### P1-2: E7 权限扩展缺少 b2b_admin worker 管理的端点修改说明

`7.1` 扩展了 `/api/v1/farms/:farmId/workers` 的权限到 b2b_admin，校验逻辑为 `farm.parentTenantId === user.tenantId`。但 Phase 2a 的 `workerRoutes.js` 可能硬编码了 `owner` 和 `platform_admin` 角色。规格未列出需要修改的具体路由文件。

**建议**：在 `横切关注点/配套修改清单` 中明确 `workerRoutes.js` 需修改权限校验逻辑。

### P1-3: E8 tenant 模型 Phase 2 字段落地的迁移策略

`8.1` 在 tenant 模型上新增 `contractId`、`revenueShareRatio` 等字段。现有 seed 数据的 10 个 tenant 均无这些字段。规格未说明：
- 现有 tenant 的默认值策略（全部 `null`？）
- `createTenant()` 是否需要扩展参数

**建议**：在 E8 中明确 (1) 所有新字段默认为 `null`；(2) `createTenant()` 需扩展接受新字段。

### P1-4: E9 seed 数据中 api_consumer 的 tenantId 不一致

`9.4` 新增 api_consumer 定义中 `tenantId: 'tenant_api_001'`，但当前 `seed.js:69` 已有 api_consumer 且 `tenantId: 'tenant_a001'`。`9.4` 中新增的 api tenant ID 也是 `tenant_api_001'`，与现有 `tenant_a001` 冲突。

**建议**：明确是替换现有 `tenant_a001` 还是新增 `tenant_api_001`。若新增，需确认 api_consumer 用户绑定哪个 tenant。建议统一使用现有 `tenant_a001`，在现有 tenant 上扩展 Phase 2 字段。

### P1-5: G2 开发者门户放在 Mobile/ 目录下不合适

`G2` 新建 `Mobile/developer-portal/`（Vue 3 SPA）。`Mobile/` 当前包含 Flutter 前端和 Node.js 后端，都是移动端项目。Vue 3 SPA 是独立的 Web 项目，放在 Mobile/ 下语义不清。

**建议**：改为项目根目录下的 `developer-portal/`（与 `Mobile/`、`PC/` 平级），或明确说明放在 `Mobile/` 下的理由（如复用 backend 托管）。

### P1-6: G3 授权审批流程中 owner 审批的数据隔离

`G3` 定义 owner 可审批请求访问自己 farm 的授权。但 owner 可能拥有多个 farm（Phase 2a 已支持多 farm）。规格未说明 owner 如何看待多个 farm 各自的授权请求。

**建议**：明确 owner 端 API 授权列表按 farm 维度展示，或增加 `farmTenantId` 过滤参数。

### P1-7: 横切关注点中 LoginPage 新增 api_consumer 角色按钮

`配套修改清单` 提到 LoginPage 新增 api_consumer 角色按钮。但 api_consumer 使用开发者门户（Vue 3 SPA），不使用 Flutter App。在 App 登录页增加此按钮的目的是什么？

**建议**：若仅用于 Mock 演示，应标注说明；若非必要，删除此条。

---

## P2 — 建议改进（不阻塞实施）

### P2-1: E5 serviceKey 格式与 apiKey 格式风格不一致

`5.2` 定义 `serviceKey` 格式 `SL-SUB-XXXX-XXXX`，但 `9.2` apiKeyStore 定义 API Key 格式为 `sl_apikey_<uuid>`。两种 Key 的格式风格不一致（一个用大写分隔符，一个用小写前缀 + UUID）。

**建议**：统一 Key 格式规范，如 `SL-SUB-XXXX-XXXX-XXXX` 或 `sl_sub_<uuid>`。

### P2-2: E4 RevenuePeriod 缺少货币单位

`RevenuePeriod.totalDeviceFee` 和 `revenueShareAmount` 未标注单位。父规格统一使用"元"。

**建议**：明确标注单位为"元"。

### P2-3: E9 apiKeyStore 轮换机制的 24h 自动撤销

`9.2` 描述旧 Key 进入 `rotating` 状态 24h 后自动变为 `revoked`。Mock 环境中是 `setInterval` 实现吗？需注意 Mock 重启后定时器丢失。

**建议**：在定时扫描逻辑中一并处理，或说明 Mock 环境下 24h 简化为更短时间（如 60s）便于演示。

### P2-4: 缺少 Phase 2b 完成标准

文档未定义 Phase 2b 的验收标准（如"所有后端测试通过 + Flutter 全量回归 + 开发者门户可登录"）。

**建议**：在文档末尾增加"验收标准"章节。

### P2-5: seed 数据扩展缺少 licensed partner 的 farm

`9.4` 新增 `tenant_p002`（独立部署客户A），但未为其创建旗下 farm。E4 分润计算需要 farm 数据才能演示。

**建议**：为 `tenant_p002` 新增至少 1 个旗下 farm seed 数据。

---

## 交叉一致性检查

| 检查项 | 结果 |
|--------|------|
| 与父规格字段定义一致性 | ✅ E8 字段与父规格 Section 2.2 Phase 2 字段一致 |
| 与 Phase 2a 规格衔接 | ✅ E6 正确扩展 Phase 2a ContractStore；E7 正确扩展 Phase 2a worker 路由 |
| 端点路径命名一致性 | ✅ 所有端点使用 `/api/v1/` 前缀，与现有约定一致 |
| 数据模型 ID 格式 | ⚠️ `tenant_api_001` 与现有 `tenant_a001` 冲突（P1-4） |
| 权限点与角色矩阵 | ✅ 新增权限点与父规格 Section 3.3 权限矩阵一致 |
| 中间件链与现有架构 | ❌ 双认证体系未与全局中间件链对齐（P0-2、P0-4） |

---

## 问题汇总

| 级别 | 数量 | 编号 |
|------|------|------|
| P0 | 4 | P0-1 ~ P0-4 |
| P1 | 7 | P1-1 ~ P1-7 |
| P2 | 5 | P2-1 ~ P2-5 |
| **总计** | **16** | |

---

## 结论

文档整体设计合理，9 大模块覆盖了 B2B2C 核心能力和 API 开放平台。**核心阻塞点为 P0-2/P0-4（中间件链冲突）**——这是 Phase 2b 架构的基石问题。建议：

1. **优先解决**中间件链设计（在 auth 全局注册的前提下如何支持 Bearer + API Key 双认证体系）
2. **其次明确**设备单价（P0-1）和 apiKeyStore 跨 Store 查询（P0-3）
3. P1 问题在实施对应 Epic 前修复即可

修复 4 个 P0 后可进入实施阶段。

---
## 修复记录 (2026-05-02)

所有问题已在规格文档 v1.1 中修复：

| 编号 | 状态 | 修复内容 |
|------|------|---------|
| P0-1 | ✅ 已修复 | E4 4.1 添加设备配置单价（GPS=¥15/月, 胶囊=¥30/月）和货币单位 |
| P0-2 | ✅ 已修复 | E5 5.3 heartbeat 端点添加认证例外说明，需在 auth.js PUBLIC_PATHS 添加白名单 |
| P0-3 | ✅ 已修复 | E9 9.2 validate() 明确跨 Store 查询链：apiKeyStore → apiTierStore |
| P0-4 | ✅ 已修复 | G1 新增"认证与中间件架构"子章节：独立 Open API Router + 全局中间件适配清单 |
| P1-1 | ✅ 已修复 | E6 6.1 明确 Mock 环境同步是即时的（内存对象） |
| P1-2 | ✅ 已修复 | E7 7.1 明确修改 `backend/routes/workerRoutes.js` 的 `canManageFarm()` 函数 |
| P1-3 | ✅ 已修复 | E8 8.1 添加默认值策略（所有新字段默认为 null）+ createTenant() 扩展 |
| P1-4 | ✅ 已修复 | E9 9.4 统一 api tenant 为现有 `tenant_a001`（扩展字段），删除冗余 `tenant_api_001` |
| P1-5 | ✅ 已修复 | G2 项目结构移至项目根目录 `developer-portal/`（与 Mobile/ PC/ 平级） |
| P1-6 | ✅ 已修复 | G3 owner 授权列表支持多 farm + `?farmTenantId=` 过滤 |
| P1-7 | ✅ 已修复 | 横切关注点删除 LoginPage api_consumer 角色按钮 |
| P2-2 | ✅ 已修复 | E4 RevenuePeriod/RevenueFarmItem 金额字段标注单位"元" |
| P2-5 | ✅ 已修复 | seed 数据为 `tenant_p002` 新增旗下 farm `tenant_f_p002_001` |

未修复的 P2 建议：
- **P2-1**（Key 格式风格统一）：不阻塞实施，style 问题可在实施阶段统一
- **P2-3**（24h 自动撤销定时器）：Mock 环境简化说明已在 E5.5 心跳处理逻辑的 `setInterval 60s` 注释中覆盖
- **P2-4**（缺少验收标准）：非阻塞，可在实施 plan 中补充

---

**文档结束**
