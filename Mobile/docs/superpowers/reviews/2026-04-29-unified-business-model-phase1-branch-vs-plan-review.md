# 评审：`feature/unified-business-model-phase1` 与 Phase 1 实施计划对照

**评审日期：** 2026-04-29  
**对照文档：** `docs/superpowers/plans/2026-04-28-unified-business-model-phase1.md`  
**对照分支：** `feature/unified-business-model-phase1`  
**方法：** `git worktree list`、`git log master..branch`、`git ls-tree`、`git grep`、`git show`（未切换本地工作区默认分支）

---

## 结论摘要

计划正文中的 **Issue 索引 / 完成记录** 已标记为「✅ 已实现」，但以 **Scope、文件结构表与 Task 1–26** 为准，该分支 **未完全落地计划**：后端与订阅模块主体基本齐备，**前端全页门控与若干验收项仍缺失**。合并入 `master` 前建议补齐或修订计划范围。

---

## 已对齐的主要部分

- **后端：** `feature-flags.js`（约 20 key）、`subscriptions.js`、`tierService.js`、`farmContext.js`、shaping（`middleware/feature-flag.js`）、`subscription` 路由（7 端点：`current` / `features` / `plans` / `checkout` / `cancel` / `renew` / `usage`）、`deviceGate` 与 `twin.js` 集成、`b2bAdmin.js`、`server.js` 全局链 `auth → farmContext → shaping` 等。
- **前端：** `DemoRole` 扩展、`AppRoute` / `GoRouter`、`b2b_admin` 占位、`subscription` 域（repository、controller、组件）、`mine_page` 嵌入 `SubscriptionStatusCard`、`api_cache` 订阅预加载及 checkout/cancel/renew 写缓存等。
- **测试（分支上存在）：** 含 `tierService.test.js`、`feature-flags.test.js`、`response-shaping.test.js`、`subscription-api.test.js`、`farmContext.test.js` 等。

---

## 缺口与风险

| 项 | 说明 |
|----|------|
| `backend/test/tier-access-integration.test.js` | 计划「文件结构」列出，分支 **不存在**。 |
| Task 23：各业务页 `LockedOverlay` | `git grep` 在 `mobile_app/lib` 下 **仅** `locked_overlay.dart` 自身命中 **LockedOverlay**，Task 23 所列 **12 个页面均无** 相关 import/包裹。 |
| `SubscriptionRenewalBanner` | 仅在 widget 文件内定义，**未**挂到 `twin_overview_page` 等页面。 |
| Scope：到期 ≤7 天 **登录弹窗** | 分支上 **未见**与 `daysUntilExpiry` 或登录流程结合的实现痕迹。 |
| Mock：`applyMockShaping()` | `apply_mock_shaping.dart` 存在，**未被** `lib` 下其他文件调用。 |
| 套餐/结账页路径 | 实现在 `features/subscription/presentation/`，与计划中 `features/pages/` **路径不一致**（若路由已注册，属文档/目录约定问题）。 |
| 「地图」页 | 该分支 **`AppRoute` 无独立地图路由**，`features/pages/` 下 **无** `map_page.dart`；计划 Scope「地图页 LockedOverlay」须与产品现状对齐或更新计划。 |

---

## Task 23 页面逐项（`LockedOverlay` / `SubscriptionRenewalBanner` / `SubscriptionController`）

检索关键字：`LockedOverlay`、`locked_overlay`、`SubscriptionRenewalBanner`、`subscription_renewal_banner`、`subscription_controller`、`SubscriptionController`。

| 文件（相对 `mobile_app/lib/`） | 是否命中 |
|-------------------------------|----------|
| `features/pages/twin_overview_page.dart` | 否 |
| `features/pages/alerts_page.dart` | 否 |
| `features/pages/fence_page.dart` | 否 |
| `features/pages/fence_form_page.dart` | 否 |
| `features/pages/fever_warning_page.dart` | 否 |
| `features/pages/fever_detail_page.dart` | 否 |
| `features/pages/digestive_page.dart` | 否 |
| `features/pages/digestive_detail_page.dart` | 否 |
| `features/pages/estrus_page.dart` | 否 |
| `features/pages/estrus_detail_page.dart` | 否 |
| `features/pages/epidemic_page.dart` | 否 |
| `features/pages/stats_page.dart` | 否 |

组件定义位置（仅供定位，非页面集成）：

- `features/subscription/presentation/widgets/locked_overlay.dart`（类定义等）
- `features/subscription/presentation/widgets/subscription_renewal_banner.dart`（类定义等）

---

## 对照：`mine_page`（Task 24）

| 文件 | 订阅相关 |
|------|----------|
| `features/pages/mine_page.dart` | 含 `SubscriptionStatusCard`、订阅管理入口、`AppRoute.subscriptionPlan` 跳转等（与 Task 23 页面形成对比）。 |

---

## 与 `master` 的关系（同期结论）

`master..feature/unified-business-model-phase1` 仍有 **仅存在于特性分支的提交**（此前会话中统计为 **17** 个提交）；该 Phase 1 功能 **尚未合入** `master`。合入前建议跑通 `Mobile/backend` 测试与 `Mobile/mobile_app` 下 `flutter analyze` / `flutter test`。

---

## 建议后续动作

1. **补实现：** Task 23 各页接入 `LockedOverlay`（及计划要求的 feature key / device 逻辑）；孪生页挂载 `SubscriptionRenewalBanner`；Mock 模式接通 `applyMockShaping` 调用链；登录到期弹窗（若仍属 Phase 1）。  
2. **或修订计划：** 将未做项移至 Phase 1.x，并同步 Issue / 完成记录表，避免文档与代码不一致。  
3. **补测试：** 新增 `tier-access-integration.test.js` 或等价集成测试，并更新「文件结构」表与实际文件名一致。
