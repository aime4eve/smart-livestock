# 智慧畜牧统一商业模型设计 — 评审报告

**评审日期**: 2026-04-28
**评审文档**: `docs/superpowers/specs/2026-04-28-unified-business-model-design.md`
**评审人**: AI Code Reviewer
**状态**: 有条件通过（需解决 P0 问题后方可实施）

---

## 总体评价

文档结构清晰，`tenant = 付费实体` 的核心原则正确，三种 tenant type（partner/farm/api）的分型合理，Shaping 管道的复用策略得当。以下是按严重程度排列的具体问题。

---

## P0 — 架构阻塞问题（必须在实施前解决）

### P0-1. `activeFarmTenantId` 未定义实现机制

Section 6.2 提到引入 `req.activeFarmTenantId` 解决 owner 多 farm 问题，但未定义：

- 谁设置这个值？（auth 中间件？新中间件？）
- 从哪里提取？（请求参数？session？header？）
- Shaping 中间件如何读取它来查 tier？

**建议**：定义一个 `farmContextMiddleware`，在 auth 之后、shaping 之前注册。Phase 1 策略：从 `ownerId` 关联的 farm 列表中取第一个（按 `createdAt` ASC）。

### P0-2. Shaping 中间件的 tier 查找链未与现有设计对接

Section 2.3 定义了继承链 `farm.entitlementTier ?? parent.entitlementTier ?? 'basic'`，但当前订阅服务规格中的 `shapingMiddleware` 直接调用 `getSubscriptionTier(tenantId)`（只查 subscriptionStore）。新模型需要：

```
getEffectiveTier(farmTenantId):
  farm = tenantStore.findById(farmTenantId)
  if farm.entitlementTier: return farm.entitlementTier
  if farm.parentTenantId:
    parent = tenantStore.findById(farm.parentTenantId)
    return parent?.entitlementTier ?? 'basic'
  return 'basic'
```

**影响**：`shapingMiddleware` 和 `subscriptionStore.getByTenantId()` 的接口需要重新设计，不再是单纯的 `tenantId → subscription → tier` 查询。

### P0-3. device_gate 在 Shaping 中间件中的实现不可行

Section 4.1.1 描述 device_gate 需要查询"该请求对应的牛是否具备所需设备"，但 Shaping 中间件的工作方式是**包装 `res.ok()`**，它操作的是**响应数据**而非请求上下文。它无法知道当前请求是针对哪头牛的。

**建议**：device_gate 应该在**路由处理函数内部**实现，而非 Shaping 中间件。路由处理函数在组装数据时，检查每头牛的设备列表，在返回数据中标记 `deviceLocked: true`。Shaping 中间件只负责 tier 层面的 lock。

---

## P1 — 设计缺陷（会导致返工）

### P1-4. 三层计费公式语义模糊

Section 4.2 定义 `总月费 = 设备月费 + tier 月费 + 超出上限阶梯费`，但 "tier 包含牲畜数内不额外叠加设备溢价" 的含义不明：

- 解释 A：包含数内**只付设备费**（不含 tier 费），超出后**叠加 tier 费 + overage**
- 解释 B：包含数内**设备费已含在 tier 费中**，超出后**另收设备费 + overage**
- 解释 C：其他

**建议**：给出一个完整的 350 头牛、standard tier、GPS + 胶囊双配的端到端计费示例。

### P1-5. "都缺"场景的 UI 行为自相矛盾

Section 4.1.1 双门控表最后一行：

> 都缺（Tier 否 + 设备 否）→ 提示需升级（因为缺设备时升级也无意义）

如果升级也解决不了问题，显示"升级"是误导用户的。应改为显示设备缺失提示（与"缺设备"场景相同），因为设备缺失是根本原因。

### P1-6. owner 多 farm 的 Phase 1 数据隔离不安全

Section 7 Phase 1 说"前端仅展示第一个 farm 的数据"，但后端 API 没有对应的隔离保障。当前所有路由用 `req.user.tenantId` 过滤数据。owner 绑定多个 farm 后，`tenantId` 字段只有一个值，其余 farm 的数据对 owner 不可见——这不是"展示第一个"的问题，而是**API 只返回一个 farm 的数据**。

**建议**：Phase 1 明确声明 owner 只能绑定一个 farm tenant（`ownerId` 唯一约束），多 farm 推迟到 Phase 2。避免半实现的多租户隔离。

### P1-7. `ops → platform_admin` 改名影响范围被低估

Section 3.5 说这是"简单查找替换"，但实际影响：

- Backend: `auth.js` TOKEN_MAP、`seed.js` 3 个用户
- Flutter: `DemoRole` 枚举、`AppSession`、`SessionController`、`app_router.dart` redirect 逻辑、`demo_shell.dart` 导航逻辑、`role_permission.dart` 全部静态方法
- Tests: 所有引用 `DemoRole.ops` 的测试文件

**建议**：将此改名作为 Phase 1 的独立 Task，不要混入其他功能实现。或者 Phase 1 保留 `ops` 名称，仅新增 `b2b_admin` 和 `api_consumer`，改名推迟到 Phase 2。

---

## P2 — 设计完整性问题（Phase 2 前需补齐）

### P2-8. 缺少 worker-farm 关联表定义

Section 3.2 提到 worker 使用"关联表：`{ userId, farmTenantId }`"，但未定义：

- 表名/Store 名
- CRUD API
- 谁管理分配（owner? platform_admin?）

当前代码中 worker 只有一个 `tenantId`，不支持多 farm 分配。

### P2-9. API Key 生命周期未定义

`apiKey` 字段在 api tenant 上定义，但缺少：

- 生成算法/格式
- 轮换机制
- 撤销流程
- 多 Key 支持（生产环境通常需要多个 Key 做轮换）

### P2-10. `accessibleFarmTenantIds` 授权审批流程缺失

API 客户需要获得对 farm tenant 的访问授权，但未定义：

- 谁发起授权请求？
- 谁审批？（farm owner? platform_admin?）
- 授权有效期？

### P2-11. Open API 端点未接入 Shaping

Section 5.1 定义 Open API 端点调用"相同底层服务"，但未说明 Shaping 中间件是否对 Open API 请求生效。如果 API client 访问 `/api/open/v1/twin/estrus/:id`，是否受 tier 限制？按 api tier 还是 farm tier？

---

## P3 — 小问题与建议

### P3-12. Phase 1 字段范围过大

Review 报告建议 Phase 1 只加 `billingModel` + `entitlementTier`（2 个字段），本规格一次性加了 13 个字段（包括 `contractId`, `revenueShareRatio`, `licenseKey`, `heartbeatAt` 等 Phase 2 专用字段）。建议 Phase 1 只加通用字段（`type`, `parentTenantId`, `billingModel`, `entitlementTier`, `ownerId`），Phase 2 专用字段推迟。

### P3-13. `b2b_admin` 认证方式未指定

未说明 b2b_admin 使用 Bearer token 还是其他认证方式。Mock token 名 `mock-token-b2b-admin` 已被提及，但 JWT payload 结构未定义。

### P3-14. 缺少计费变更的事件通知机制

当 partner 的 tier 变更时，"对所有子 farm 立即生效"（Section 2.3），但前端如何感知？需要 WebSocket 推送还是下次请求时自然反映？建议明确。

### P3-15. Subscription spec 的 `calculatedPrice` 公式需更新

原订阅规格的 `calculatePrice(tierId, livestockCount)` 只计算 tier 月费 + overage。新增设备月费后，`SubscriptionStatus.calculatedPrice` 的定义需要明确是否包含设备费。

---

## 与关联文档的一致性检查

| 检查项 | 结果 |
|--------|------|
| 与订阅服务规格的 Feature Flag 20 key | ✅ 一致，但新增 `requiredDevices` 字段需更新 feature-flags.js |
| 与订阅服务规格的 Shaping 中间件 | ❌ **不一致**：tier 查找逻辑需改为继承链查找 |
| 与订阅服务规格的 SubscriptionStatus 模型 | ❌ **不一致**：`calculatedPrice` 定义需拆分 |
| 与评审报告的 Phase 1 范围 | ⚠️ **偏大**：评审报告建议 +15% 工时，本规格新增字段远超此范围 |
| 与 ML 需求说明书的设备依赖 | ✅ 一致，`requiredDevices` 映射与 ML 传感器规格吻合 |
| 种子数据兼容性声明 | ✅ 一致，默认值方案可行 |

---

## 建议优先级

1. **先解决 P0-1/P0-2/P0-3**（activeFarmTenantId 机制、tier 继承查找、device_gate 位置），再开始 Phase 1 实施
2. **P1-6 收紧 Phase 1 范围**：owner 单 farm，多 farm 推迟
3. **P1-7 拆分 ops 改名**：作为独立 Task 或推迟到 Phase 2
4. 补充计费示例（P1-4）消除歧义

---

## 代码库现状验证

以下发现基于对当前代码库的完整审查：

| 维度 | 当前状态 | 本规格需要的变化 |
|------|----------|-----------------|
| Tenant 模型 | 扁平，无层级（13 字段） | +13 新字段，三种类型 |
| 角色 | 3 个（owner/worker/ops） | → 5 个（+b2b_admin, api_consumer） |
| 权限 | 纯 permission 字符串 | +billingModel 条件路由 |
| Session | 仅 role + tokens | 需加 activeFarmTenantId |
| 订阅系统 | **不存在** | 整个模块新建 |
| Feature Flag | **不存在** | 整个模块新建 |
| owner → tenant | 一对一（tenantId 字段） | → 一对多（ownerId on farm） |
| worker → farm | 单 tenantId | → 关联表（多对多） |

---

**文档结束**
