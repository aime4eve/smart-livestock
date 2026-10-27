# NIX-324 实施计划

> 依据：spec `docs/superpowers/specs/2026-10-27-nix324-subscription-health-dual-surface-spec.md` v1.0（原型已确认）
> 执行准则：AGENTS.md plan 确认后执行准则（子智能体串行按 Task 推进，主智能体评审，端到端验证）
> 预估：后端 3 Task + 前端 3 Task + 收口 1 Task

---

## Task 0：视觉保真准备
- 从原型 HTML 提取令牌映射表落 `docs/superpowers/specs/` 附录（CSS → Flutter Color/TextStyle/EdgeInsets 逐条）。
- 验证：映射表覆盖原型全部新增色/距/圆角；与 design-tokens.md 无冲突。

## Task 1：共享判定器 `SubscriptionHealthEvaluator`（后端）
- commerce 域新组件：输入 `Subscription` + `Instant now` + NIX-325 窗口配置，输出 spec §2 判定矩阵结果 record（healthStatus/level/trialActive/effectiveTier/daysToExpiry/degraded/exportWindow）。
- exportWindow 查询 `DataExportJobRepository.findByTenantIdOrderByIdDesc` 取最新 job。
- 单测：判定矩阵 #1–#6 全分支 + TRIAL 过期未翻转回归（裸 status 陷阱）+ 同日到期边界。
- 验证：单测全绿；判定口径与 TenantSubscriptionResolver/SubscriptionExportPolicy 三处一致（评审点）。

## Task 2：租户端接口扩展（后端）
- `GET /subscription` 响应加 `health` 块（Task 1 判定器）；契约文档 app-api.md 同步 + changelog。
- 验证：编译 + 单测；dev curl 实测 healthy/构造态两例。

## Task 3：管理端接口（后端）
- 新增 `GET /admin/subscription-overview`（platform_admin，分页/筛选/排序/同日分组标记）。
- admin-api.md 契约 + 单测（排序与分组边界）。
- 验证：dev curl 全量列表 vs subscriptions 表对账抽查。

## Task 4：租户端 Flutter（前端）
- `SubscriptionHealthBanner`（四型横幅）+ 订阅状态卡扩展 + `ExportEntitlementCard`（发起导出/下载/状态轮询接 NIX-325 API）+ RENEWAL_FAILED 补缴 CTA 接既有 checkout。
- i18n：`subscriptionHealth.*` 中英 ARB；gen-l10n + flutter analyze。
- 验证：Flutter Web 走查四态截图留证（改库造态）；按钮点击语义树断言。

## Task 5：管理端 Web（前端）
- platform_admin 租户菜单新增「订阅健康度」页：表格 + 筛选 chips + 同日分组 + 导出窗口列（跳转 /admin/data-export-jobs）。
- 验证：可达性倒查（菜单→页面 1 次点击）；对照原型逐项盘点挂载点（lessons #25）。

## Task 6：收口
- 内建浏览器端到端：判定矩阵逐态双端走查（对照 spec §6 验收清单）→ 部署 dev → 用户集成测试 → 提交/合并/关单。
- test 环境部署等用户通知（NIX-323/325 迁移同批首过更早基线库，盯 Flyway）。

---

## 依赖与风险
- Task 1 判定器是唯一共享关键路径，先做并被 2/3 复用。
- 前端造态依赖改库（dev 容器 psql），冒烟脚本随 Task 4/5 提供。
- 开放问题三项（spec §7）默认按 spec 缺省值执行，用户可随时改判。
