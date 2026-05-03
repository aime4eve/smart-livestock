# 统一商业模型 Phase 2b 设计规格 — R3 评审报告

**评审日期**: 2026-05-02
**评审文档**: `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` (v1.2)
**前置文档**:
- `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3)
- `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md` (v1.3)
**前置评审**:
- R1: `docs/superpowers/reviews/2026-05-02-unified-business-model-phase2b-review.md` (16 问题)
- R2: `docs/superpowers/reviews/2026-05-02-unified-business-model-phase2b-review-r2.md` (9 问题)
**评审人**: R3
**状态**: **通过** — 0 P0 / 0 P1 / 6 P2

---

## 总体评价

v1.2 对 R2 评审全部 9 个问题的修复**完整且精确**。经三轮评审（共 31 个问题），规格文档已高度成熟。P1-R2-1（auth.js 混合匹配策略）的修复尤为关键，完整解决了 Open API 与现有 Bearer 认证共存的基础设施前提。P1-R2-2（设备配置比例简化模型）的修复使分润公式在 Phase 2b 的 Mock 阶段具备可实施性。

本轮评审聚焦：(1) R2 修复的交叉一致性验证；(2) 与当前代码库的落地可行性；(3) 实施阶段可能遇到的边界情况。**未发现阻塞问题。**

---

## R2 修复验证

| 编号 | 验证结果 | 备注 |
|------|---------|------|
| P1-R2-1 | ✅ | 横切关注点中间件适配清单已定义 `endsWith` + `startsWith` 混合匹配策略，`req.path` 为 Router 内部路径已注明 |
| P1-R2-2 | ✅ | 4.1 新增设备配置单价说明+示例；4.2 RevenueFarmItem 含 `deviceConfigRatio`；9.4 seed 含 `deviceConfigRatio` |
| P1-R2-3 | ✅ | 5.3 认证例外说明明确 `endsWith` 对 heartbeat 后缀天然生效，并标注 Router 内部路径差异 |
| P1-R2-4 | ✅ | 9.2 `validate()` 实现链清晰：hash → 匹配 → `getByTenantId()` → 取 `.tier` → 返回 |
| P2-R2-1 | ✅ | Mock 环境直接使用 `Bearer mock-token-api-consumer`，与 TOKEN_MAP 一致 |
| P2-R2-2 | ✅ | G1 数据隔离章节说明 cattle `farmTenantId` 字段 + cattleStore 反查 |
| P2-R2-3 | ✅ | E5 后端逻辑新增启动时全量扫描 + apiKeyStore 同理 |
| P2-R2-4 | ✅ | 依赖关系图中 G2 已移至 G1 下方 |
| P2-R2-5 | ✅ | G2 技术栈表格已含 vitest + @vue/test-utils |

---

## 新发现问题

### P0 — 阻塞问题

无。

### P1 — 重要问题

无。

### P2 — 建议改进

### P2-R3-1: E5 subscriptionServiceStore 与 tenant 模型字段同步时机缺少异常处理说明

5.2 和 8.2 中提到 `tenant.serviceKey` 和 `tenant.heartbeatAt` 与 subscriptionServiceStore 同步。5.4 心跳处理逻辑步骤 3 中，降级恢复时同步 `tenant.entitlementTier` 为原 tier。

但在降级场景（status → `'degraded'`），规格说 `tenant.entitlementTier → 'basic'`。问题是：恢复时"原 tier"从哪里取？subscriptionServiceStore 的 `effectiveTier` 字段此时已被设为 `basic` 了吗？还是 `effectiveTier` 始终保持原始值？

**建议**：在 SubscriptionService 模型中明确 `effectiveTier` 字段存储的是"购买的 tier"（如 `'premium'`），恢复时从该字段读取。或者新增一个 `originalTier` / `purchasedTier` 字段用于恢复。当前规格 5.4 步骤 3 说"恢复为 `'active'`（恢复心跳自动复原），同步 `tenant.entitlementTier` 为原 tier"——"原 tier" 的来源应显式指向 `subscriptionService.effectiveTier`。

### P2-R3-2: E4 分润计算中 tenant_p001（revenue_share 模式）的旗下 farm 缺少 `deviceConfigRatio` seed

9.4 seed 数据为 `tenant_f_p002_001`（licensed partner 旗下 farm）添加了 `deviceConfigRatio`，但 Phase 2a 中已存在的 `tenant_f_p001_001`（`tenant_p001` 星辰牧业旗下 farm，billingModel=`revenue_share`）**没有** `deviceConfigRatio` 字段。

E4 的分润引擎需要计算所有 partner 旗下 farm 的设备费。`tenant_p001` 是 seed 中唯一的 revenue_share partner，旗下的 `tenant_f_p001_001` 应也有 `deviceConfigRatio` + `livestockCount`，否则分润计算演示会跳过这个 partner。

**建议**：在 9.4 seed 中为 `tenant_f_p001_001` 也补充 `deviceConfigRatio` 和 `livestockCount` 字段（可由实施 plan 中补充，不阻塞 spec）。

### P2-R3-3: G1 shapingMiddleware 对 Open API 的分叉逻辑需确认当前 feature-flag.js 的行为

当前 `feature-flag.js` (shapingMiddleware) 的逻辑是：如果 `req.activeFarmTenantId` 为 null，直接跳过 shaping（`return originalOk(data, message)`）。但 Open API 请求的 `activeFarmTenantId` 被设为 null（farmContextMiddleware 对 api_consumer 不设 farm context），且 `req.apiTier` 已被 apiKeyAuthMiddleware 注入。

规格 G1 认证与中间件架构部分说"shaping 由全局 shapingMiddleware 处理（检测 req.apiTier 分叉）"。但当前 `feature-flag.js` 代码中**完全没有** `req.apiTier` 的检测逻辑——它只检查 `farmTenantId`，为 null 时直接跳过。

这意味着 Phase 2b 需要修改 `feature-flag.js`，新增 `req.apiTier` 的分叉。规格配套修改清单中的 shapingMiddleware 行说"不改"（检测 `req.apiTier` 分叉"不改"），但实际上当前代码**没有这个分叉**，需要新增。

**建议**：将配套修改清单中 shapingMiddleware 行的"不改"改为"新增 `req.apiTier` 分叉逻辑"，与 G1 认证架构部分的描述一致。

### P2-R3-4: E9 apiKeyStore.validate() 的返回值在 apiKeyAuthMiddleware 和 rateLimitMiddleware 间的传递

9.2 中 `validate(rawKey)` 返回 `{ apiTenantId, apiTier }`。G1 的 apiKeyAuthMiddleware 代码（L551-561）将 `result` 解构为 `req.apiConsumer = { tenantId, tier }` 和 `req.apiTier = tier`。

但 `accessibleFarmTenantIds` 的注入点不在 apiKeyAuthMiddleware 代码中。G1 数据隔离章节说"apiKeyAuth 中间件将 accessibleFarmTenantIds 注入 req"——但实际的中间件伪代码只注入了 `apiConsumer` 和 `apiTier`。

**建议**：在 apiKeyAuthMiddleware 代码中补充 `req.accessibleFarmTenantIds` 的注入（从 tenant 的 `accessibleFarmTenantIds` 字段读取），与 G1 数据隔离章节文字描述一致。这是实现细节，不影响规格理解。

### P2-R3-5: G2 开发者门户 `express.static` 托管路径需调整

G2 说 Mock Server 通过 `app.use('/developer', express.static('../../developer-portal/dist'))` 托管。但 `Mobile/backend/` 是 server.js 所在目录，`../../developer-portal/dist` 的相对路径解析取决于 Node.js 进程的工作目录（`process.cwd()`），而非模块文件位置。

如果用 `cd Mobile/backend && node server.js` 启动，`../../developer-portal/dist` 会解析到项目根目录的同级目录，而非 `developer-portal/`。应该使用 `path.join(__dirname, '../../../developer-portal/dist')` 或在 plan 中明确工作目录要求。

**建议**：改为 `path.join(__dirname, '../../../developer-portal/dist')`，或在 G2 中标注"路径在实施 plan 中根据实际目录结构调整"。

### P2-R3-6: 横切关注点配套修改清单中 `farmContextMiddleware` 改动描述与 G1 认证架构不完全对齐

配套修改清单中 farmContextMiddleware 行写"api_consumer 明确设为 `activeFarmTenantId = null`"。当前 `farmContext.js` 对非 owner/worker 角色（else 分支）已设 `activeFarmTenantId = null`，api_consumer 自然走 else 分支。

但 G1 认证架构部分说 farmContextMiddleware 改动为"新增 `if (req.apiConsumer) { req.activeFarmTenantId = null; return next(); }`"——这个新分支是**显式**处理 API 消费者。当前 else 分支隐式处理（依赖 `req.user.role` 不是 owner/worker），效果相同但语义不同。

**建议**：两者等效，但显式分支更清晰且不依赖 `req.user` 的存在性。建议实施时采用 G1 中的显式分支写法。不阻塞规格。

---

## 交叉一致性检查

| 检查项 | 结果 |
|--------|------|
| R2 全部 9 个修复验证 | ✅ 全部通过 |
| 与父规格字段定义一致性 | ✅ E8 字段与父规格 Section 2.2 Phase 2 字段完全一致 |
| 与 Phase 2a 规格衔接 | ✅ E6 正确扩展 ContractStore；E7 正确引用 workerRoutes.js |
| 与代码库中间件链对齐 | ✅ auth.js 匹配策略修复方案可行 |
| seed 数据 ID 无冲突 | ✅ tenant_p002 / tenant_f_p002_001 无冲突；tenant_a001 复用已有 |
| 端点路径与代码库注册方式 | ✅ 新端点通过 registerApiRoutes.js 注册 |
| 新增文件列表完整性 | ✅ 后端 17 + 前端 4 + Vue 项目，覆盖所有 Epic |
| 权限点与角色矩阵 | ✅ 7 个新权限点与父规格权限矩阵一致 |
| shapingMiddleware 分叉逻辑 | ⚠️ 当前代码无 apiTier 分叉，需新增（P2-R3-3） |
| 分润 seed 完整性 | ⚠️ tenant_f_p001_001 缺 deviceConfigRatio（P2-R3-2） |

---

## 问题汇总

| 级别 | 数量 | 编号 |
|------|------|------|
| P0 | 0 | — |
| P1 | 0 | — |
| P2 | 6 | P2-R3-1 ~ P2-R3-6 |
| **总计** | **6** | |

与上一轮对比：R1 = 16 问题（4 P0），R2 = 9 问题（0 P0），R3 = 6 问题（0 P0）——问题数量和严重度持续下降。

---

## 结论

**规格通过，可进入实施阶段。**

6 个 P2 问题均为实现层面细节，不影响架构设计正确性。其中 P2-R3-3（shapingMiddleware apiTier 分叉）建议在实施 G1 时优先确认，因为它是 Open API 端点功能门控的前提。

经三轮评审的充分锤炼，本规格在以下方面表现优秀：
- 中间件架构设计（双认证体系共存）经过多轮推敲，方案成熟
- 数据所有权约定（8.2）清晰明确
- 依赖关系图合理，实施路径可行
- 测试策略覆盖完整

---

**文档结束**
