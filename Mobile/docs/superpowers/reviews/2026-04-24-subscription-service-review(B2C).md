# SaaS 订阅服务设计规格 — 评审

**评审日期**: 2026-04-25
**评审文件**: `docs/superpowers/specs/2026-04-24-subscription-service-design(B2C).md`

## 总体评价

规格整体**设计清晰、与现有架构契合度高**。Feature Flag 清单、shaping 策略、数据模型定义完整。以下按严重程度列出问题。

---

## Critical（必须修改）

### 1. `res.ok()` 包装时序问题 — shaping 中间件无法拦截已发送的响应

`middleware/envelope.js:34` 中 `res.ok` 的实现是：

```js
res.ok = (data, message) => res.json(ok(data, message));
```

`res.json()` 会**立即序列化并发送响应**。shaping 中间件包装 `res.ok` 的设计（spec 第 88-98 行）看起来可行，但有一个前提：**`envelopeMiddleware` 必须在 `shapingMiddleware` 之前注册**。当前 `server.js` 的注册顺序是先 `envelopeMiddleware` 再路由，如果 shaping 中间件挂载在路由级别（而非全局），时序正确。但 spec 未明确中间件注册顺序。

**建议**：在 spec 中明确 `shapingMiddleware` 必须在 `envelopeMiddleware` 之后、路由处理函数之前执行，并给出 `server.js` 修改后的完整注册顺序。

### 2. `GET /api/map/positions` 端点不存在

Spec 第 206 行提到 `GET /api/map/positions` 受 shaping 影响，但当前 `routes/map.js` 中只有 `GET /api/map/trajectories`，没有 `positions` 端点。同样，`ApiCache.init()` 也没有预加载 positions。

**建议**：删除 `positions` 行或说明这是需要新增的端点。

### 3. `req.tenantId` 未在 auth 中间件中设置

shaping 中间件通过 `getSubscriptionTier(req.tenantId)` 获取订阅层级（第 92 行），但当前 `middleware/auth.js` 只设置了 `req.userRole` 和 `req.user`，没有设置 `req.tenantId`。虽然 `req.user.tenantId` 存在，但 spec 假设 `req.tenantId` 已可用。

**建议**：在 spec 中明确需要修改 `authMiddleware` 添加 `req.tenantId = req.user.tenantId`，或 shaping 中间件使用 `req.user.tenantId`。

---

## Important（应当修改）

### 4. Feature Flag `dashboard_summary` 的 `limit` 策略未定义

Feature Flag 表中 `dashboard_summary` 对 basic 是 `✓ limit`，但 shaping 配置示例中没有 `dashboard_summary` 的 limit 规则。"隐藏高级指标"的语义不清晰——是隐藏某些 metric？还是减少 metric 数量？

**建议**：添加 `dashboard_summary` 的 shaping 配置示例，明确 basic 用户隐藏哪些 metric。

### 5. `data_retention_days` 作为 filter 策略缺少数据源说明

filter 策略按 `timestamp` 过滤，但：
- alerts 数据中字段叫 `occurredAt` 不是 `timestamp`
- fences 数据没有时间字段
- twin 数据使用 `timestamp` 但散布在不同结构中

`filterField: 'timestamp'` 不能一概而论。

**建议**：为每个使用 filter 的端点单独指定 `filterField`（alerts 用 `occurredAt`，twin 用 `timestamp`），或在 shaping 配置中支持端点级别覆盖。

### 6. 前端 subscription 路由与 `AppRoute` 枚举的集成方式不明确

Spec 第 294-297 行添加了 `subscription` 和 `checkout` 两个路由，但放在 `ShellRoute` 外部。当前 `AppRoute` 是 enhanced enum，需要：
- 新增两个 enum 值
- 修改 `app_router.dart` 在 `ShellRoute` 之外注册
- 修改 redirect guard 允许 owner 访问

Spec 只给了代码片段，未说明完整的路由注册位置。

**建议**：给出 `app_route.dart` 完整的修改后 enum 值、`app_router.dart` 中路由树的插入位置（相对于现有 `ShellRoute` 的前后）。

### 7. `SubscriptionPermission` 的实现方式缺失

Spec 定义了"两层权限体系"（第 279-290 行），但只说了概念，没给实现。前端需要：
- 一个类似于 `RolePermission` 的 `SubscriptionPermission` 静态工具类
- 或者从 API 响应的 `locked` / `limit` 字段动态判断

**建议**：明确前端订阅权限的判断方式——是从本地 `SubscriptionController` 状态判断，还是纯粹依赖后端返回的 `locked` 字段？

### 8. Mock 模式下 LiveRepository 的 shaping 兼容性

当前 `AppMode.mock` 使用 `MockXxxRepository`（纯本地数据，不经过网络请求），如果 shaping 只在后端实现，mock 模式下的 `MockSubscriptionRepository` 需要自己模拟 `locked`/`limit` 注入，否则前端 Mock 模式看不到 locked 遮罩。

**建议**：在测试策略中增加 mock 模式下 locked 状态的测试场景，或说明 mock repository 需要自行注入 locked 字段。

---

## Minor（建议修改）

### 9. `SubscriptionTier.monthlyPrice` 用"分"为单位与 Feature Flag 表不一致

数据模型中 `monthlyPrice` 单位为"分"（29900），但 Feature Flag 表标题行写的是 ¥299。容易在实现时混淆。

**建议**：在数据模型旁注明"前端展示时需要除以 100 转换为元"。

### 10. `enterprise` 层级的 `perUnitPrice` / `perUnitSize` 未定义

数据模型中 `perUnitPrice` 和 `perUnitSize` 没有"仅对 standard/premium 有效"的约束说明。enterprise 的这两个字段应该为 null 或 -1。

**建议**：在 `SubscriptionTier` 模型中添加约束说明。

### 11. 幂等性 key 的服务端存储策略未说明

`idempotencyKey` 防双击（第 330 行），服务端需"记忆最近一个 key"。对于内存 mock server 来说需要：
- 存储结构（Map？）
- 过期/清理策略

**建议**：简要说明 mock server 中 key 存储方式（如 `Map<string, result>` + 不清理，或 5 分钟 TTL）。

### 12. 缺少 `GET /api/map/positions` 端点

Spec 影响表中列出 `/api/map/positions`，但后端和前端均不存在此端点。`ApiCache.init()` 也未加载它。同时 spec 中列出的预加载端点没有 `GET /api/devices`，但当前 `ApiCache.init()` 已经加载了 devices。

**建议**：用现有实际端点替换虚拟端点，确保与 `ApiCache.init()` 当前的 13 个请求一致。

### 13. LockedOverlay 组件设计缺少 loading/transition 状态

当用户升级后 `ApiCache.instance.init()` 重新加载期间，locked 状态如何过渡？是立即解除锁还是等缓存刷新完？

**建议**：在 ApiCache 集成部分补充 checkout 成功后的 UI 过渡说明（loading spinner → 刷新完成 → 锁解除）。

---

## 架构层面赞赏

1. **响应塑造（Response Shaping）设计**非常优雅——通过包装 `res.ok()` 实现零侵入后端逻辑，路由代码完全不需要感知订阅，这是正确的关注点分离。
2. **Feature Flag 清单**完整且覆盖了现有所有功能模块。
3. **两层权限体系**（Role + Subscription）互不干扰的设计合理，worker 继承 owner 订阅的决策正确。
4. **LockedOverlay 统一组件**方案好，一个组件覆盖所有 locked 场景，避免了散落的条件判断。
5. **测试策略**覆盖了后端 shaping + 前端 locked 的关键路径。

---

## 总结

| 级别 | 数量 | 关键问题 |
|------|------|---------|
| Critical | 3 | 不存在的端点、tenantId 缺失、中间件顺序 |
| Important | 5 | limit 策略缺失、filter 字段名、路由集成、SubscriptionPermission、mock 兼容 |
| Minor | 5 | 单位标注、enterprise 约束、幂等 key 存储、端点一致性、过渡状态 |

建议修复 3 个 Critical 问题后开始实施，Important 问题在实施过程中逐步解决。
