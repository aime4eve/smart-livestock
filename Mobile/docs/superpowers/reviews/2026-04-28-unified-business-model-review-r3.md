# 智慧畜牧统一商业模型设计 — 第三轮评审报告 (R3)

**评审日期**: 2026-04-28
**评审文档**: `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.2)
**上一轮评审**: `docs/superpowers/reviews/2026-04-28-unified-business-model-review-r2.md`
**评审人**: AI Code Reviewer (R3)
**状态**: 有条件通过

---

## 总体评价

v1.2 修订成功解决了 R2 的全部 13 个问题（13/13）。文档内部一致性良好，Phase 1 核心架构设计完整。新引入 4 个 P1-P2 问题（均不阻塞核心实现），订阅规格有 9 处待同步。补充少量细节后可进入 Phase 1 实施。

---

## 一、R2 全部 13 个问题解决验证

| # | 问题 | 状态 | 说明 |
|---|------|------|------|
| N1 | `getEffectiveTier()` 检查 subscription 状态 | ✅ | Section 2.3 新增 expired/cancelled/trial 三种状态降级逻辑，仅对 direct farm 检查 |
| C1 | 统一 tier 查询函数 | ✅ | Section 2.3 明确声明"取代订阅规格的 `getSubscriptionTier()`"，定义输入参数、数据源、继承链差异 |
| N2 | `calculatedPrice` 单位 | ✅ | Section 4.2 明确"单位统一为**元**"，附完整迁移计划 |
| N3 | 中间件注册方式统一 | ✅ | Section 6.2 三者全部全局注册，明确解释理由（避免 `req.user` 为 undefined） |
| N4 | tier 数据所有权 | ✅ | Section 2.2 新增"entitlementTier 数据所有权"段落，三层权威来源定义清晰 |
| C2 | 超额计费公式对齐 | ✅ | Section 4.2 明确采用每头定价（¥2/头），声明覆盖订阅规格的批次定价 |
| C3 | `calculatedPrice` 字段迁移 | ✅ | Section 4.2 拆为 3 个子字段 + 单位迁移 + Phase 1 无历史数据声明 |
| N5 | owner farm 数量描述 | ✅ | Section 3.1 角色表改为"Phase 1: 1 个 farm; Phase 2: 1~N 个 farm" |
| N6 | list 端点 deviceLocked 结构 | ✅ | Section 4.1.1 完整 JSON 示例，`locked` 在信封层、`deviceLocked` 在 item 层 |
| N7 | b2b_admin Phase 1 降级 | ✅ | Section 7 定义"功能开发中"占位页 + 基础 Shell（含退出登录） |
| C4 | `requiredDevices` 跨文档引用 | ✅ | Section 八明确标注"订阅规格 `feature-flags.js` schema 需同步添加此字段" |
| C5 | checkout/renew 设备月费 | ✅ | Section 4.4 两 API 均扩展，renew 明确"重算设备月费（牛数可能已变化）" |
| C6 | list 端点 locked/deviceLocked 共存 | ✅ | Section 4.1.1 JSON 示例 + 前端判断逻辑 `item.deviceLocked || data.locked` |

**统计：13/13 完全解决。**

---

## 二、新发现问题

### NEW-1. [P1] `getEffectiveTier()` 伪代码中 `now` 未定义

**位置**: Section 2.3

函数体使用 `now > sub.currentPeriodEnd` 和 `now > sub.trialEndsAt`，但 `now` 从未声明。开发者复制此伪代码时可能遗漏。

**建议**: 在函数开头加 `const now = new Date();`。

### NEW-2. [P1] direct farm 无 subscription 记录时的行为未定义

**位置**: Section 2.3

当 direct farm 在 subscriptionStore 中无对应记录（`sub` 为 null/undefined）时，函数跳过所有状态检查，直接返回 `farm.entitlementTier`。这在以下场景会产生问题：

- subscription 创建失败但 tenant 已创建
- 手动删除 subscription 记录
- 旧数据迁移时遗漏

**建议**: 加防御性 fallback（`if (!sub) return 'basic';`），或注释说明 Phase 1 假设所有 direct farm 均通过 `createTrial` 保证有 subscription 记录。

### NEW-3. [P2] 设备月费的计费周期与中途变更未定义

**位置**: Section 4.2

规格定义了"每头牛 × 设备 × 月"的计费模型和 checkout/renew 时的计算。但未定义：

- 中途新增牛只时，设备月费何时生效？
- 中途移除牛只（死亡/出售）时，费用是否退还？
- 设备更换（从 GPS 升级到双配）时，费用何时变更？

**建议**: Phase 1 简化为"仅在 checkout/renew 时重算"，并在文档中明确声明。

### NEW-4. [P2] 全局 shaping 中间件的"包装延迟执行"模式需说明

**位置**: Section 6.2

全局注册 `shapingMiddleware` 后，它会在路由匹配之前包装 `res.ok()`。实际 shaping 逻辑在路由处理函数调用 `res.ok()` 时执行——此时 per-route 中间件已设置 `req.routeFeatureKeys`。逻辑正确，但模式不直观。

**建议**: 加一句说明：全局注册仅包装 `res.ok()`，实际 shaping 逻辑延迟到路由处理函数调用 `res.ok()` 时执行，此时 `req.routeFeatureKeys` 已由 per-route 中间件设置完毕。

---

## 三、订阅服务规格待同步项

统一规格在多处声明"以本规格为准"，但订阅规格原文未更新。以下为开发者实施时需注意的差异清单：

| # | 维度 | 订阅规格原文 | 统一规格覆盖 | 需更新的订阅规格位置 |
|---|------|-------------|-------------|-------------------|
| S1 | tier 查询函数 | `getSubscriptionTier(tenantId)` 查 subscriptionStore | `getEffectiveTier(farmTenantId)` 查 tenant.entitlementTier | Section "后端架构" shapingMiddleware 代码块 |
| S2 | 中间件注册 | per-route 注册 | 全局注册 | Section "中间件注册顺序" |
| S3 | 超额公式 | 批次定价（每 50 头 +¥50） | 每头定价（¥2/头） | Section "订阅层级" 计费示例 |
| S4 | `calculatedPrice` | 单一字段，单位：分 | 3 子字段，单位：元 | Section "数据模型" SubscriptionStatus |
| S5 | `monthlyPrice`/`perUnitPrice` | 单位：分 | 暗含单位改为元（与 calculatedTotal 一致） | Section "数据模型" SubscriptionTier |
| S6 | feature-flags.js schema | 无 `requiredDevices` | 需新增 | Section "后端架构" schema 定义 |
| S7 | Shaping tier 来源 | `req.user?.tenantId` | `req.activeFarmTenantId` + `getEffectiveTier()` | Section "后端架构" shapingMiddleware |
| S8 | checkout/renew 响应 | 仅含 tier 费用 | 新增 `calculatedDeviceFee` + `calculatedTotal` | Section "订阅管理 API" |
| S9 | `SubscriptionTier` 模型 | `perUnitPrice`/`perUnitSize`（批次定价字段） | 每头定价，字段语义需更新 | Section "数据模型" SubscriptionTier |

**S5 特别注意**: 统一规格的迁移计划仅提及 `calculatedPrice` → 3 子字段的迁移，未显式提及 `SubscriptionTier.monthlyPrice` 和 `perUnitPrice` 的单位变更。如果只改 `calculatedPrice` 系列而保留 `monthlyPrice: 29900`（分），系统内会出现同一笔费用不同字段单位不一致的情况。

**建议**: 创建勘误表或更新订阅规格至 v1.1，标注"以下条目已被 SL-BIZ-2026-001 v1.2 覆盖"。

---

## 四、Phase 1 实施就绪度

### 可以开始编码

- ✅ tenant 数据模型扩展（5 个 Phase 1 字段）
- ✅ `b2b_admin`、`api_consumer` 角色定义 + seed 数据
- ✅ `farmContextMiddleware` 实现
- ✅ `getEffectiveTier()` 实现
- ✅ 全局中间件注册顺序
- ✅ device_gate 路由处理函数模式
- ✅ LockedOverlay 双层门控（tier + device）
- ✅ b2b_admin 占位页
- ✅ owner 单 farm 约束

### 实施前需补充/确认

| # | 内容 | 阻塞程度 | 建议 |
|---|------|---------|------|
| 1 | `getEffectiveTier()` 补充 `now` 定义和 null-sub 防御 | 低 | 在 spec 中补注释 |
| 2 | 设备月费中途变更策略 | 低 | 加一句"Phase 1 仅 checkout/renew 时重算"声明 |
| 3 | 订阅规格 9 处同步更新 | 中 | 创建勘误表或更新订阅规格版本 |
| 4 | `monthlyPrice`/`perUnitPrice` 单位对齐 | 中 | 明确所有价格字段统一使用元 |

---

## 五、总结

| 维度 | 评价 |
|------|------|
| R2 问题解决率 | 13/13（100%） |
| 新发现问题 | 4 个（2 P1, 2 P2） |
| 订阅规格待同步 | 9 处 |
| Phase 1 阻塞问题 | 无 |
| **总体状态** | **有条件通过** — 补充 NEW-1/NEW-2 + 订阅规格勘误后可进入 Phase 1 实施 |

### 建议下一步

1. 补充 NEW-1（`now` 定义）和 NEW-2（null-sub 防御）→ v1.3
2. 在订阅规格顶部添加勘误段落，列出 S1-S9 被覆盖项
3. 开发者可以 v1.2 + 勘误为基础开始 Phase 1 实施

---

**文档结束**
