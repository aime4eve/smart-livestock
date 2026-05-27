# 设计规格评审：Flutter 前端全量适配 Spring Boot 后端

> **评审对象**: [2026-05-23-flutter-full-adaptation-design.md](../specs/2026-05-23-flutter-full-adaptation-design.md)
> **评审日期**: 2026-05-23
> **评审结论**: 有条件通过，需解决 3 个 P0 阻塞项后可进入实施

---

## 总体评价

设计文档结构清晰，模块划分合理，依赖链正确。核心方向（后端驱动、删除 Mock、JWT 认证、path-based Farm Scope）完全正确。以下是发现的问题，按严重程度排列。

---

## P0 — 阻塞性问题（实施前必须解决）

### 1. Commerce API 端点与后端实际实现不一致（M11-M13）

设计规格中的端点与后端 `SubscriptionController` 实际暴露的 API 不匹配：

| 设计规格写的 | 后端实际实现的 |
|---|---|
| `POST /subscription/change` | `PUT /subscription/tier` |
| _(缺失)_ | `POST /subscription/checkout` |
| `GET /subscription/quotas` | `GET /subscription/usage` |
| `POST /subscription/cancel` | `POST /subscription/cancel` ✅ |

合同和对账端点也需要与后端 `CommerceController` 实际路径对齐。建议实施前逐一核对 `docs/api-contracts/app-api.md` 和后端 Controller 源码。

### 2. Farm Scope 路由设计自相矛盾

`docs/api-contracts/api-overview.md` §5.2 写的是：
> GoRouter 导航至 `/{farmId}/dashboard` 等路径

但设计规格 §7.3 写的是：
> 路由保持现有结构，不加 farmId 前缀：`/dashboard`、`/alerts`

两者必须统一。§7 的控制器管理模式（`FarmController` 持 `activeFarmId`，API 路径自动注入）在技术上是可行的，但与 api-overview.md 的约定冲突。**建议明确选择一种并更新 api-overview.md。**

### 3. 所有 Repository 接口从同步变异步 — 未评估影响

当前架构中，live repository 从 `ApiCache` **同步读取**预加载的数据。设计规格将 `ApiCache` 替换为按需请求的 `ApiClient`，意味着：

- 所有 repository 方法必须从 `List<T> getXxx()` 变成 `Future<List<T>> getXxx()`
- 所有 controller 中调用 repository 的地方必须加 `await`
- 所有 ConsumerWidget 中可能需要加 loading 状态处理

这是一个**贯穿全部 26 个模块**的接口变更，设计规格 §6.4 只展示了一个简化的代码片段，未评估这个影响范围。建议补充一个 transition plan（比如先让 mock repo 也返回 Future，统一接口后再切实现）。

---

## P1 — 重要问题（实施时需注意）

### 4. 订阅 Tier 名称不一致

| 当前 Flutter (`subscription_tier.dart`) | 后端 Commerce V6 | 设计规格 |
|---|---|---|
| `trial`, `basic`, `pro`, `enterprise` | `basic`, `standard`, `premium`, `enterprise` | 未提及 |

Flutter 端的 `SubscriptionTier` 枚举与后端不匹配。设计规格 D9 提到种子数据迁移，但未说明 tier 枚举如何对齐。

### 5. AppSession 模型中 `phone` 和 `userName` 无法从 JWT 获取

§5.3 的 `AppSession` 包含 `phone` 和 `userName`，但 JWT payload 只有 `{ sub, tid, role, iat, exp }`。§5.1 的登录流程缺少 `GET /me` 调用来获取这些字段。

建议在登录流程的第三步后加一步：`GET /me` → 填充 phone/userName。

### 6. 缺少离线/网络异常处理策略

当前 live repo 在 API 不可用时有 fallback 到 mock 数据的逻辑。设计规格 D3 决定"彻底删除 Mock"，但未说明：
- 后端不可达时的用户体验是什么？
- 是否需要本地缓存（如 Hive/SharedPreferences）作为离线降级？
- 网络请求超时/重试策略？

移动端网络环境不稳定，建议至少补充一个离线策略说明（哪怕是"显示网络错误提示"）。

### 7. 种子数据迁移脚本编号可能与已有迁移冲突

设计规格 M20 提议 V9-V12，但未确认 V9 是否已被占用。当前已有 V1-V8。如果 Commerce 实施过程中已经创建了更多迁移脚本，编号会冲突。建议实施前检查 `db/migration/` 目录的实际状态。

### 8. Feature Flag 迁移路径不清晰

当前 Flutter 有 18 个 feature flag + `LockedOverlay` 组件，基于 `SubscriptionTier` 做门控。设计规格 M11 只写了一句：
> mock `feature-flag.js` 的 tier 功能门控逻辑迁移为前端订阅状态 → 配额检查 → UI 锁定/解锁

但缺少：
- 18 个现有 feature flag 如何映射到后端配额系统
- `LockedOverlay` 组件是否保留（应该保留）
- 配额检查失败时 UI 行为与现有 flag 行为的对应关系

---

## P2 — 建议改进（不阻塞实施）

### 9. 缺少 `api_authorization` 和 `farm_creation` 模块的迁移计划

26 个功能模块中，`api_authorization` 和 `farm_creation` 未在任何 M 任务中显式提及。`api_authorization` 的后端 API Key 管理在 M17 中覆盖，但前端的 API 开发者门户 UI 在 M22 中标记为"未实现"。`farm_creation` 的后端 `POST /farms` 在 M14 涉及，但前端创建向导流程未明确。

### 10. 错误映射表可简化

§6.3 的错误映射表很详细，但前端实际处理可能只需要三个层级：
- 401 → 重新认证
- 403 → 无权限提示
- 其他 → 通用错误提示

建议实施时不要过度设计错误处理，先覆盖核心场景。

### 11. M1-M4 依赖链中的并行机会

§4 的依赖链说 `M3 + M4 → M5~M10`，但实际上 M4（Farm Switcher）只依赖 M3（API Client），可以和 Phase B 的部分模块并行。如果 M4 简单（只是改路径注入方式），甚至可以合并到 M3 中。

---

## 评审汇总

| 类别 | 数量 | 说明 |
|---|---|---|
| P0 阻塞 | 3 | Commerce 端点对齐、Farm Scope 路由统一、同步转异步影响评估 |
| P1 重要 | 5 | Tier 名称对齐、Session 字段补充、离线策略、迁移编号确认、Feature Flag 迁移 |
| P2 建议 | 3 | 遗漏模块补充、错误处理简化、并行机会 |

**核心建议**：解决 P0 问题 1（Commerce 端点对齐）和 P0 问题 3（同步转异步的影响评估）后再进入实施。P0 问题 2（Farm Scope 路由）需要与 api-overview.md 统一后明确一种方案。
