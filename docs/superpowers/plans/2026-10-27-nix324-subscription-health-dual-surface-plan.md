# NIX-324 实施计划

> 依据：spec `docs/superpowers/specs/2026-10-27-nix324-subscription-health-dual-surface-spec.md` v1.2（原型已确认，经两轮评审修订）
> 执行准则：AGENTS.md plan 确认后执行准则（子智能体串行按 Task 推进，主智能体评审，端到端验证）
> 预估：后端 3 Task + 前端 3 Task + 收口 1 Task

---

## Task 0：视觉保真准备
- 从原型 HTML 提取令牌映射表落 `docs/superpowers/specs/` 附录（CSS → Flutter Color/TextStyle/EdgeInsets 逐条）。
- 验证：映射表覆盖原型全部新增色/距/圆角；与 design-tokens.md 无冲突。

## Task 1：共享判定器 `SubscriptionHealthEvaluator`（后端）
- commerce 域新组件：输入 `Subscription` + `Instant now` + NIX-325 窗口配置，输出 spec §2 判定矩阵结果 record（healthStatus/level/trialActive/effectiveTier/daysToExpiry/degraded/exportWindow）。
- exportWindow 查询 `DataExportJobRepository.findByTenantIdOrderByIdDesc` 取最新 job。
- 单测：判定矩阵 #1–#7 全分支 + TRIAL 过期未翻转回归（裸 status 陷阱）+ 同日到期边界（**≥2 租户才置 sameDayGroup**）。
- **机械核对（v1.2 评审升级，不靠人审）**：同一组状态样例（每态至少 1 例 + TRIAL 过期未翻转、同日到期、窗口边界各 1 例）分别喂 `SubscriptionHealthEvaluator`（本 Task）/`TenantSubscriptionResolver`（NIX-323）/`SubscriptionExportPolicy`（NIX-325）三组件，断言 tier 与 eligible 口径一致；不一致即停修。
- 评审修订：矩阵纳入 SUSPENDED 态；CANCELLED 复活 CTA 落 `reactivate`/`changeTier`（**不渲染 changeTier 于 SUSPENDED**——该态仅 reactivate，避免 409）。

## Task 2：租户端接口扩展 + 导出 API JWT 通道 + 导出卷（后端）
- `GET /subscription` 响应加 `health` 块（Task 1 判定器）；契约文档 app-api.md 同步 + changelog。
- **导出 API 双通道（v1.2 评审阻断项）**：`OpenDataExportController` 请求主体解析回退——Key 属性优先、缺失回退 `TenantContext`（JWT）；`requestedBy` JWT 路径取当前用户。
- **导出文件持久化（v1.2 评审阻断项）**：compose dev/test/release 加 `exports-data:/app/data/exports` 命名卷（现仅 `tileserver-data:ro`，容器重建必丢 30 天窗内文件）；deploy 脚本若有卷初始化步骤同步。
- 验证：编译 + 单测；dev curl 实测 healthy/构造态两例；**JWT 通道冒烟**（无 X-API-Key 发起导出→下载 200）；**重启容器后下载仍 200**。

## Task 3：管理端接口（后端）
- 新增 `GET /admin/subscription-overview`（platform_admin，分页/筛选/排序/同日分组标记）。
- admin-api.md 契约 + 单测（排序与分组边界）。
- 验证：dev curl 全量列表 vs subscriptions 表对账抽查。

## Task 4：租户端 Flutter（前端）
- `SubscriptionHealthBanner`（四型横幅）+ 订阅状态卡扩展 + `ExportEntitlementCard`（发起导出/下载/状态轮询，**走 JWT 通道**）+ RENEWAL_FAILED 补缴 CTA 接既有 checkout。
- **b2b_admin 白名单（v1.2 评审阻断项）**：`app_router.dart` 的 b2b_admin redirect 白名单加订阅页路径——现仅 /b2b/admin/*、瓦片、设备配置，访问订阅页被弹回后台，提示无处挂载。
- 轮询规范（v1.2）：导出卡 10s 轮询 job 状态，COMPLETED/FAILED/窗口关闭即停；不轮询时静态展示。
- i18n：`subscriptionHealth.*` 中英 ARB；gen-l10n + flutter analyze。
- 验证：Flutter Web 走查七态截图留证（改库造态）；按钮点击语义树断言；**b2b_admin 角色登录可达订阅页**回归。

## Task 5：管理端 Web（前端）
- platform_admin 租户菜单新增「订阅健康度」页：表格 + 筛选 chips + 同日分组 + 导出窗口列（跳转 /admin/data-export-jobs）。
- 验证：可达性倒查（菜单→页面 1 次点击）；对照原型逐项盘点挂载点（lessons #25）。

## Task 6：收口
- **造态冒烟包（v1.2）**：六态造态 SQL 清单 + 每态恢复步骤（参考 10-27 renewal_failed 并行冲突教训——改库后必恢复，恢复语句与造态语句同脚本成对出现）。
- 内建浏览器端到端：判定矩阵逐态双端走查（对照 spec §6 验收 10 条）→ 部署 dev → 用户集成测试 → 提交/合并/关单。
- test 环境部署等用户通知（NIX-323/325 迁移同批首过更早基线库，盯 Flyway）。

---

## 依赖与风险
- Task 1 判定器是唯一共享关键路径，先做并被 2/3 复用；三组件同测集机械核对在 Task 1 完成。
- 前端造态依赖改库（dev 容器 psql），造态/恢复成对脚本随 Task 6 提供（Task 4/5 走查用）。
- v1.2 评审三阻断已转为本计划硬任务（Task 2 双通道+卷、Task 4 白名单）；完成前不得宣布 plan 就绪。
- 开放问题三项（spec §7）默认按 spec 缺省值执行，用户可随时改判。
