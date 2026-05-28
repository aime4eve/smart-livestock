# 智慧畜牧统一商业模型设计 — 第二轮评审报告

**评审日期**: 2026-04-28
**评审文档**: `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.1)
**上一轮评审**: `docs/superpowers/reviews/2026-04-28-unified-business-model-review.md`
**评审人**: AI Code Reviewer (R2)
**状态**: 有条件通过（需解决 P0 问题后方可实施）

---

## 总体评价

v1.1 修订成功解决了 15 个原始问题中的 12 个（80%），3 个部分解决。文档结构清晰，商业模型框架完整。但存在关键的 tier 数据源冲突和计费公式不一致问题，必须在 Phase 1 实施前解决。

---

## 一、原始 15 个问题解决验证

| # | 问题 | 状态 | 说明 |
|---|------|------|------|
| P0-1 | `farmContextMiddleware` 定义 | ✅ | Section 6.2：完整函数体、注册顺序（auth → farmContext → shaping）、各角色逻辑均已定义 |
| P0-2 | `getEffectiveTier()` + Shaping 集成 | ⚠️ | 函数已定义但**不检查 subscriptionStore 状态**（试用/过期/取消），见新问题 N1 |
| P0-3 | device_gate 移至路由处理函数 | ✅ | Section 4.1.1：明确分离 `deviceLocked`（路由）vs `locked`（Shaping），前端优先级规则清晰 |
| P1-4 | 计费公式端到端示例 | ⚠️ | Section 4.2 有完整 350 头牛示例，但超额公式与订阅规格冲突，见跨文档问题 C2 |
| P1-5 | "都缺"场景 UI 行为 | ✅ | "都缺"现在显示设备缺失提示（与"缺设备"相同），不显示升级 |
| P1-6 | owner Phase 1 单 farm 约束 | ✅ | Section 2.2/3.2/7 均声明 `ownerId` 唯一约束 |
| P1-7 | `ops → platform_admin` 改名推迟 | ✅ | Section 3.5 明确推迟至 Phase 2，附完整影响面枚举 |
| P2-8 | worker-farm 关联表定义 | ✅ | Section 3.2：表名、字段、Phase 1/2 行为、管理权限均已定义 |
| P2-9 | API Key 生命周期 | ✅ | Section 2.2：生成算法、轮换（双 Key + 24h 过渡）、撤销、SHA-256 哈希存储 |
| P2-10 | `accessibleFarmTenantIds` 授权流程 | ✅ | Section 5.3：发起方/审批方/有效期（12个月）/撤销/通知，Phase 1 仅手动 |
| P2-11 | Open API Shaping 集成 | ✅ | Section 5.1：明确 API tier vs farm tier 分流规则 |
| P3-12 | Phase 1 字段范围缩减 | ✅ | Section 2.2：Phase 1 仅 5 个通用字段，Phase 2 专用字段 9 个推迟 |
| P3-13 | b2b_admin 认证方式 | ✅ | Section 3.5：Bearer token、mock token 名、JWT payload 结构 |
| P3-14 | tier 变更通知机制 | ✅ | Section 2.3：基于 `getEffectiveTier()` 实时查找的 pull 模式，无需推送 |
| P3-15 | `calculatedPrice` 字段更新 | ⚠️ | 已拆分为 3 个子字段，但单位不明确且无迁移计划，见新问题 N2 |

**统计**：12 完全解决 / 3 部分解决 / 0 未解决

---

## 二、新发现问题

### N1. [P0] `getEffectiveTier()` 忽略订阅状态 — 过期用户保留 premium 功能

**位置**: Section 2.3

函数仅读取 `tenantStore.entitlementTier`，不检查 `subscriptionStore` 状态。订阅规格定义了自动降级逻辑（试用期结束 → basic），但 `getEffectiveTier()` 会在订阅过期后仍返回 `premium`。

**影响**: Phase 1 direct-farm owner 的试用到期后仍可使用 premium 功能，整个订阅生命周期管理被绕过。

**建议修复**:

```
function getEffectiveTier(farmTenantId) {
  const farm = tenantStore.findById(farmTenantId);
  if (!farm) return 'basic';

  // direct farm 需检查订阅激活状态
  if (!farm.parentTenantId) {
    const sub = subscriptionStore.getByTenantId(farmTenantId);
    if (sub && (sub.status === 'expired' ||
        (sub.status === 'cancelled' && now > sub.currentPeriodEnd))) {
      return 'basic';
    }
    if (sub && sub.status === 'trial' && now > sub.trialEndsAt) {
      return 'basic';
    }
  }

  // 继承链
  if (farm.entitlementTier) return farm.entitlementTier;
  if (farm.parentTenantId) {
    const parent = tenantStore.findById(farm.parentTenantId);
    return parent?.entitlementTier ?? 'basic';
  }
  return 'basic';
}
```

### N2. [P1] `calculatedPrice` 子字段单位不明

**位置**: Section 4.2

订阅规格定义 `calculatedPrice: int // 单位：分`。商业模型示例中的值（15750, 599）看起来是**元**而非**分**。如果单位是分，15750 分 = ¥157.50，与示例中的 ¥15,750 设备月费不符。

**建议**: 明确声明单位。若保持订阅规格的"分"约定，示例值应为 `calculatedDeviceFee: 1575000, calculatedTierFee: 59900, calculatedTotal: 1634900`。或在两份规格中统一使用元。

### N3. [P1] 中间件注册方式矛盾：全局 vs per-route

**位置**: Section 6.2 vs 订阅规格 Section "中间件注册顺序"

商业模型规格使用**全局注册**:
```
app.use(authMiddleware);
app.use(farmContextMiddleware);
app.use(shapingMiddleware);
```

订阅规格推荐 **per-route 注册**:
```
router.use(authMiddleware);
router.use(shapingMiddleware);
```

如果 auth 是 per-route 而 farmContext 是全局的，`farmContextMiddleware` 在未认证路由上执行时 `req.user` 不存在，导致 `req.user.role` 抛出异常。

**建议**: 二选一并统一文档：
- **方案 A**: 三者全部全局注册
- **方案 B**: 三者全部 per-route 注册，farmContextMiddleware 加在 auth 和 shaping 之间

### N4. [P1] `tenant.entitlementTier` vs `subscriptionStore.tier` — 双数据源

**位置**: Section 2.2 + 订阅规格数据模型

tenant 模型新增 `entitlementTier` 字段，subscriptionStore 也有 `tier` 字段。direct farm 用户从 standard 升级到 premium 时，两处都需更新，存在一致性风险。

规格说"订阅相关 Store 的 `getByTenantId()` 改为调用此函数获取 effective tier，而非直接查 subscriptionStore"——暗示 subscriptionStore.tier 不再是 tier 决策的权威来源。但 subscriptionStore.tier 仍用于状态管理、试用到期检查和 UI 展示。

**建议**: 明确定义数据所有权：
- `tenant.entitlementTier`: **购买/选择的** tier（Shaping 的权威来源）
- `subscriptionStore.tier`: 变为**非规范化缓存**或移除
- `subscriptionStore.status/periodEnd/trialEndsAt`: 生命周期的权威来源

或更简方案：移除 `tenant.entitlementTier`，tier 仅存于 subscriptionStore，`getEffectiveTier()` 先查 subscriptionStore，再查 parent 的 subscriptionStore。

### N5. [P2] 角色表称 owner 管理 "1~N 个 farm" 与 Phase 1 矛盾

**位置**: Section 3.1

角色定义表写 `owner` 管理 "自己的 **1~N 个 farm**"，但 Phase 1 约束为单 farm。开发者可能误以为需要构建多 farm 支持。

**建议**: 改为 "Phase 1: 1 个 farm, Phase 2: 1~N 个 farm"。

### N6. [P2] list 端点的 device_gate 数据结构未定义

**位置**: Section 4.1.1

规格说"牛只列表按牛粒度逐条检查，返回 locked 标记"，但未展示响应结构。开发者不知道 `deviceLocked` 放在每条记录内还是信封级别。

**建议**: 补充 list 端点的响应结构示例：
```json
{
  "items": [
    { "cattleId": "c001", "deviceLocked": false, ... },
    { "cattleId": "c002", "deviceLocked": true, "deviceMessage": "此功能需要安装瘤胃胶囊", ... }
  ]
}
```

### N7. [P2] b2b_admin Phase 1 登录后无 UI

**位置**: Section 3.1, 3.5, 6.1

架构图展示 `/b2b/admin` 路由，但 Section 7 Phase 1 明确排除 "B端管理后台（b2b_admin UI）"。Phase 1 中 b2b_admin 用户登录后看到什么？

**建议**: 定义 Phase 1 降级方案（如跳转到"功能开发中"页面，或阻止登录并提示）。

---

## 三、与订阅服务规格的跨文档一致性检查

### C1. [P0] Shaping tier 查询函数冲突

| 维度 | 订阅规格 | 商业模型规格 |
|------|----------|-------------|
| 函数名 | `getSubscriptionTier(tenantId)` | `getEffectiveTier(farmTenantId)` |
| 数据源 | subscriptionStore | tenantStore |
| 输入 | tenantId（通用） | farmTenantId（仅 farm 类型） |

两份文档使用完全不同的函数和数据源查询 tier，未说明如何统一。

### C2. [P1] 超额计费公式不一致

**订阅规格**（Section "订阅层级"）:
- Standard 超额: 每 50 头 +¥50
- 350 头牛计算: ¥299 + (3 × ¥50) = **¥449**

**商业模型规格**（Section 4.2）:
- Standard 超额: 150 × ¥2/头 = **¥300**
- 350 头牛计算: ¥299 + ¥300 = **¥599**

两份文档的公式产生不同结果。订阅规格用批次定价（每 50 头一档），商业模型规格用每头定价。

**影响**: 开发者无法确定实现哪个公式。

### C3. [P1] `SubscriptionStatus.calculatedPrice` 模型分歧

| 维度 | 订阅规格 | 商业模型规格 |
|------|----------|-------------|
| 字段结构 | 单一 `calculatedPrice: int` | 3 个子字段: `calculatedDeviceFee` + `calculatedTierFee` + `calculatedTotal` |
| 单位 | 分 | 未声明（示例值看起来像元） |

无迁移说明。按订阅规格实现的开发者会创建错误的模型。

### C4. [P2] Feature Flag `requiredDevices` 字段未在订阅规格中定义

商业模型规格 Section 八说"每 key 新增 `requiredDevices` 字段"，但订阅规格的 `feature-flags.js` schema 无此字段。

### C5. [P2] 设备月费未反映在订阅规格的 checkout/renew 流程中

订阅规格的 `POST /api/subscription/checkout` 和 `POST /api/subscription/renew` 仅处理 tier 月费。新增设备月费后，checkout API 需返回合并总额，且需单独展示设备费。

### C6. [P2] device_gate 的 `locked` 响应结构不一致

订阅规格的 `locked` 在信封数据级别注入（`data.locked = true`）。商业模型规格的路由处理函数为牛只端点按条目添加 `deviceLocked`。list 端点中二者如何共存未定义：

```json
{
  "data": {
    "locked": true,
    "upgradeTier": "premium",
    "deviceLocked": ???,
    "items": [...]
  }
}
```

单牛端点 `deviceLocked` 可放在 `data` 级别。list 端点需 per-item。规格未为 list 定义此结构。

---

## 四、建议修复优先级

### 实施前必须解决（阻塞 Phase 1）

1. **N1 + C1**: 修复 `getEffectiveTier()` 加入 subscription status 检查 → 统一两份规格的 tier 查询函数
2. **N4**: 定义 tier 权威数据源（tenantStore vs subscriptionStore）
3. **N3**: 统一中间件注册方式（全局 or per-route）

### Phase 1 实施期间解决

4. **C2**: 对齐超额计费公式（选一种，更新两份文档）
5. **N2 + C3**: 明确 `calculatedPrice` 单位 + 迁移计划
6. **N5**: 修正角色表中 owner 的 farm 数量描述

### Phase 2 前解决

7. **C4**: 更新订阅规格的 feature-flags.js schema 添加 `requiredDevices`
8. **C5**: 更新订阅规格的 checkout/renew API 加入设备月费
9. **C6**: 定义 list 端点的 deviceLocked 响应结构
10. **N6**: 补充 list 端点 device_gate 数据结构示例
11. **N7**: 定义 b2b_admin Phase 1 降级方案

---

## 五、总结

| 维度 | 评价 |
|------|------|
| 原始问题解决率 | 12/15 完全解决（80%） |
| 新发现问题 | 7 个（1 P0, 3 P1, 3 P2） |
| 跨文档不一致 | 6 个（1 P0, 2 P1, 3 P2） |
| 实施阻塞问题 | 3 个（N1, C1, N4 互相关联） |
| **总体状态** | **有条件通过** — 解决 N1+C1+N4+N3 后可进入 Phase 1 实施 |

---

**文档结束**
