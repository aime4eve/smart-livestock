# 统一商业模型 Phase 2b 设计规格 — R2 评审报告

**评审日期**: 2026-05-02
**评审文档**: `docs/superpowers/specs/2026-05-02-unified-business-model-phase2b-design.md` (v1.1)
**前置文档**:
- `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3)
- `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md` (v1.3)
**前置评审**: `docs/superpowers/reviews/2026-05-02-unified-business-model-phase2b-review.md` (v1.1)
**评审人**: AI Code Reviewer (R2)
**状态**: 有条件通过 — 全部 9 个问题已在 spec v1.2 中修复

---

## 总体评价

v1.1 对 v1.0 评审中全部 4 个 P0 + 7 个 P1 + 2 个 P2 的修复是**完整且正确的**。特别是 P0-4（中间件链冲突）的修复采用了独立 Open API Router + 全局中间件适配清单的方案，设计清晰。剩余问题集中在实现细节和一致性方面，不阻塞实施启动。

---

## 上一轮修复验证

| 编号 | 验证结果 | 备注 |
|------|---------|------|
| P0-1 | ✅ | 4.1 已定义设备单价（GPS=¥15/月，胶囊=¥30/月） |
| P0-2 | ✅ | 5.3 已明确 heartbeat 端点在 `PUBLIC_PATHS` 白名单中跳过 Bearer 校验 |
| P0-3 | ✅ | 9.2 `validate()` 已明确跨 Store 查询链 |
| P0-4 | ✅ | G1 新增独立 Open API Router 架构，三处中间件适配清单完整 |
| P1-1 | ✅ | 6.1 已明确 Mock 环境即时同步 |
| P1-2 | ✅ | 7.1 已明确 `workerRoutes.js` 需修改 |
| P1-3 | ✅ | 8.1 已明确默认值策略和 createTenant 扩展 |
| P1-4 | ✅ | 9.4 已统一为现有 `tenant_a001` |
| P1-5 | ✅ | G2 开发者门户已移至项目根目录 `developer-portal/` |
| P1-6 | ✅ | G3 owner 授权列表支持多 farm + `?farmTenantId=` 过滤 |
| P1-7 | ✅ | 横切关注点已删除 LoginPage api_consumer 条目 |
| P2-2 | ✅ | 金额字段已标注单位"元" |
| P2-5 | ✅ | 已新增 `tenant_f_p002_001` farm seed |

---

## 新发现问题

### P0 — 阻塞问题

无。

---

### P1 — 重要问题

### P1-R2-1: G1 中间件架构描述与 auth.js 现有匹配机制不一致

`横切关注点` 中间件适配清单（L514）写 authMiddleware `PUBLIC_PATHS` 新增 `'/api/open'`，用"前缀匹配所有 `/api/open/v1/*`"。但当前 `auth.js` 使用 `req.path.endsWith(p)` 进行匹配——这匹配的是**后缀**而非前缀。

例如 `/api/open/v1/twin/fever/123` 的 `req.path` 在 Express 中为 `/open/v1/twin/fever/123`（去掉挂载前缀后），`endsWith('/api/open')` 不会命中。需要改为 `req.path.startsWith('/open')` 或具体的 `req.path === '/open/v1/...'` 模式。

**建议**：将 authMiddleware 的白名单匹配逻辑改为前缀匹配（`req.path.startsWith('/open')`），或在 PUBLIC_PATHS 中列出 `/open/` 前缀，同时修改 `auth.js` 的匹配策略为 `startsWith` + `endsWith` 混合匹配。

### P1-R2-2: E4 分润计算公式缺少"设备配置"维度

4.1 定义公式为 `∑(每个 farm 的牛数 × 设备配置单价)`。但实际场景中一头牛可能只佩戴 GPS（¥15/月）、只佩戴胶囊（¥30/月）或双配（¥45/月）。公式假设每头牛使用固定单价，但设备配置是**按牛**的，不是按 farm 的。

4.2 的 `RevenueFarmItem` 只有 `livestockCount` 和 `deviceFee`，没有设备配置细项。结算计算时需要知道每头牛佩戴了哪些设备才能准确计算 `deviceFee`。

**建议**：在 `RevenueFarmItem` 中新增设备细项字段，或在公式说明中明确"设备配置单价按 farm 级别的设备配置比例估算"（简化模型）。若为简化模型，应在 seed 数据中明确 farm 的设备配置比例（如 70% GPS + 30% 胶囊）。

### P1-R2-3: E5 心跳端点路径在 PUBLIC_PATHS 白名单中的精确值未定义

5.3 说 heartbeat 端点需要在 `PUBLIC_PATHS` 中添加 `'/subscription-services/heartbeat'`。但当前 `PUBLIC_PATHS` 使用 `endsWith` 匹配，且现有值为短路径如 `'/auth/login'`。heartbeat 的实际请求路径取决于路由挂载方式（在 `registerApiRoutes` 中挂载为 `/subscription-services/heartbeat` 或其他前缀）。

**建议**：明确 PUBLIC_PATHS 中添加的精确路径字符串（与 Express 路由注册路径一致），避免实施时因路径不匹配导致白名单失效。

### P1-R2-4: E9 apiKeyStore.validate() 中 apiTierStore.getByTenantId() 方法名与 9.3 定义不一致

9.2 `validate()` 描述为"查 apiTierStore.getByTenantId() 拿 tier"。但 9.3 apiTierStore 的方法列表是 `getByTenantId(apiTenantId)`，这个方法确实存在。然而 9.3 也定义了 `checkQuota(apiTenantId)`。在 apiKeyAuthMiddleware（G1 L540-551）中，`result` 只返回 `apiTenantId` 和 `apiTier`——但 `apiTier` 是从哪里来的？

回顾 9.3 的数据模型，`ApiTier` 对象包含 `tier` 字段。`getByTenantId()` 应该返回整个 ApiTier 对象，从中取 `tier`。但 `validate()` 的实现描述只说"拿 apiTier"，未说明是取 `ApiTier.tier` 字段。

**建议**：在 9.2 `validate()` 的实现说明中明确 `apiTierStore.getByTenantId(apiTenantId).tier`，消除歧义。

---

### P2 — 建议改进

### P2-R2-1: G2 开发者门户 Mock token 登录流程

G2 Section "登录流程"（L681-684）说 api_consumer 输入 `mock-token-api-consumer`，然后 `POST /api/v1/auth/login` 获取 Bearer token。但当前 `/auth/login` 端点接受的是 `{ mobile, password }` 或 `{ token }` 格式（需确认）。Mock token 当前是直接放在 `Authorization: Bearer <token>` header 中的，不是通过 login 端点交换的。

**建议**：确认 Mock 环境下开发者门户的登录方式是直接设置 Bearer header 还是通过 login 端点。

### P2-R2-2: G1 Open API 端点缺少 cattle 数据源说明

G1 端点如 `/api/open/v1/twin/fever/:id` 需要查找牛只数据。当前 `twin_seed.js` 中的数据是全局的，没有按 farmTenantId 隔离。数据隔离通过 `accessibleFarmTenantIds` 过滤，但 twin_seed 数据结构中是否有 `farmTenantId` 字段？

**建议**：在 G1 数据隔离章节中说明 twin 数据的 farmTenantId 来源（是 cattleStore 中的字段还是通过其他方式关联）。

### P2-R2-3: E5 心跳后台扫描定时器与 E9 apiKey 轮换定时器

E5.5 提到 `setInterval 60s` 扫描心跳超时。P2-3（v1.0 评审）提到 apiKey 轮换也有 24h 自动撤销。两个定时器在 Mock 环境下重启后丢失。规格中已说明 Mock 环境用 `setInterval`，但未提到重启恢复策略。

**建议**：可在 server.js 启动时初始化这些定时器（作为启动流程一部分），或在定时扫描逻辑中处理"应该已过期但因重启未检测"的情况（如启动时执行一次全量扫描）。不阻塞实施，实施时注意即可。

### P2-R2-4: 依赖关系图中 G2 位置

依赖关系图（L40-49）中 G2 标注为"E7 之后"，但 G2 依赖的是 G1（端点就绪），不是 E7。图中的位置暗示 G2 等待 E7 完成，但实际上 G2 只需 G1 端点可用即可开始前端开发。

**建议**：G2 应标注为"E9 之后，依赖 G1"，而非依赖 E7。

### P2-R2-5: 测试策略中 G2 Vue 3 组件测试

横切关注点测试策略表中 G2 列为"Vue 3 组件测试（vitest）"。但 `developer-portal/` 是全新项目，需初始化 vitest 配置。规格中未提及 Vue 3 项目的测试配置。

**建议**：在 G2 技术栈表格中新增 vitest + @vue/test-utils 依赖项，或标注"测试框架在实施 plan 中确定"。

---

## 交叉一致性检查

| 检查项 | 结果 |
|--------|------|
| v1.0 所有 P0 修复验证 | ✅ 全部通过 |
| v1.0 所有 P1 修复验证 | ✅ 全部通过 |
| 与父规格字段定义一致性 | ✅ E8 字段与父规格 Section 2.2 Phase 2 字段一致 |
| 与 Phase 2a 规格衔接 | ✅ E6 正确扩展 ContractStore；E7 正确引用 workerRoutes.js |
| 与代码库中间件链对齐 | ⚠️ auth.js PUBLIC_PATHS 匹配机制需调整（P1-R2-1） |
| seed 数据 ID 冲突 | ✅ 已统一使用现有 tenant_a001 |
| 端点路径与代码库注册方式 | ⚠️ heartbeat 白名单路径需精确（P1-R2-3） |
| 新增文件列表完整性 | ✅ 后端 17 个新文件 + 前端 4 个新模块 + Vue 项目，覆盖所有 Epic |
| 权限点与角色矩阵 | ✅ 新增 7 个权限点与父规格权限矩阵一致 |
| 依赖关系图 | ⚠️ G2 位置有误（P2-R2-4） |

---

## 问题汇总

| 级别 | 数量 | 编号 |
|------|------|------|
| P0 | 0 | — |
| P1 | 4 | P1-R2-1 ~ P1-R2-4 |
| P2 | 5 | P2-R2-1 ~ P2-R2-5 |
| **总计** | **9** | |

与上一轮对比：上一轮 16 个问题（4 P0 + 7 P1 + 5 P2），本轮 9 个问题（0 P0 + 4 P1 + 5 P2），且均为实现层面细节，无架构设计问题。

---

## 结论

v1.1 规格已充分修复 v1.0 评审的全部阻塞性问题。**可以进入实施阶段**。

实施启动前建议优先确认：
1. **P1-R2-1**（auth.js 路径匹配机制）——这是 G1 的前提条件
2. **P1-R2-2**（分润计算设备配置维度）——这是 E4 的核心公式

其余 P1 和 P2 问题可在实施对应 Epic 时解决。

---

---

## R2 问题修复记录（spec v1.2）

| 编号 | 修复内容 | 位置 |
|------|---------|------|
| P1-R2-1 | auth.js 匹配策略从纯 `endsWith` 扩展为 `endsWith` + `startsWith` 混合（以 `/` 结尾为前缀匹配）；明确 `req.path` 为 Router 内部路径 | 横切关注点中间件适配清单 + 配套修改清单 |
| P1-R2-2 | RevenueFarmItem 新增 `deviceConfigRatio` 字段；公式改为 farm 级别的设备配置单价；添加 Phase 2b 简化模型说明及示例 | 4.1 + 4.2 + 9.4 seed |
| P1-R2-3 | 明确 `'/subscription-services/heartbeat'` 在 endsWith 下天然生效；标注 Router 内部注册的路径差异 | 5.3 认证例外说明 |
| P1-R2-4 | `validate()` 实现说明改为：`getByTenantId(apiTenantId)` → 获取 ApiTier 对象 → 取 `.tier` 字段 → 返回 `{ apiTenantId, apiTier }` | 9.2 |
| P2-R2-1 | Mock 环境直接使用 `Bearer mock-token-api-consumer` header（已在 TOKEN_MAP 中注册）；Live 环境保留 login 端点交换 | G2 登录流程 |
| P2-R2-2 | 添加 twin 数据隔离说明：通过 cattle 对象的 `farmTenantId` 字段关联，cattleStore 按 `cattleId` 反查 | G1 数据隔离 |
| P2-R2-3 | 添加启动时全量扫描（处理重启前超时）；apiKeyStore 24h 轮换撤销同理 | E5 心跳后端逻辑 |
| P2-R2-4 | G2 移至 G1 下（依赖 G1 端点就绪而非 E7）；E7 添加不依赖 E9 的说明 | 依赖关系图 |
| P2-R2-5 | G2 技术栈表格新增 vitest + @vue/test-utils | G2 技术栈 |

> 修复后 spec 版本号升级为 **v1.2**，修订日期 2026-05-02。

**文档结束**
