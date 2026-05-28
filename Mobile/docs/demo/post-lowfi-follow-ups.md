# 低保真 Demo 之后：后续 ToDo（Shell / 路由 / 权限）

> **语境**：当前 `mobile_app` 为**客户确认范围**用的可点击 Demo。`DemoShell` + `IndexedStack` + 本地假数据可满足演示与测试；**不等于**上线版导航与鉴权终态。  
> **此前说明**「路由与权限已够用、无需再改 shell」仅指 **Task 4 范围内**不必为串联流程再动 `demo_shell.dart`，**不是**免除下列工作。

---

## P0：从 Demo 切到可联调 / MVP 时必须做

- **命名路由或路由包**：用 `GoRouter` / `Navigator 2` 等替代「仅靠底部索引 + `IndexedStack`」；支持返回栈、深链接、Web 路径（若需要）。
- **鉴权与菜单单一事实来源**：权限以登录后 **`/api/me`（或等价）返回的 `role` / `permissions`** 为准，替代或同步当前硬编码的 `RolePermission` + 登录页角色开关（演示开关仅作 Debug 入口或删除）。
- **`DemoShell` 职责拆分**：登录态、租户上下文、底部导航、子路由出口分层；平台运维与牧场业务**两套壳**是否独立 `Scaffold` / 路由分支，需与规格 `12.1`、权限章一致。
- **状态管理**：告警阶段、地图筛选等从 `setState` 本地演示迁到 **Repository + 统一状态**（如 Riverpod / Bloc），并与 API 错误态、重试、分页对齐。
- **真地图**：替换地图占位与列表回退为地图 SDK（及权限、离线策略），保留「加载失败 → 列表回退」产品行为。

---

## P1：体验与一致性

- **国际化**：文案走 `l10n`，去掉测试/演示与产品文案混用（若保留演示模式，需单独 `AppMode.demo` 与文案前缀）。
- **设计体系**：颜色/字号与规格 `12.5` 对齐；`StatusTag` 与后端告警等级枚举一致。
- **可访问性**：关键操作用 `Semantics` / 语义标签，减少仅靠 `Key` 驱动测试（Key 可保留给集成测试）。

---

## P2：工程与交付

- **版本库**：仓库若需 Git，初始化后补 **worktree / 分支策略**（见项目协作规范）；Demo 阶段 `docs/demo/change-log.md` 可逐步改为正经 CHANGELOG 或关掉演示开关。
- **Task 5**：客户评审脚本、规格中「Demo 交付物与使用方式」若尚未写入，见计划 `2026-03-26-lowfi-demo-implementation.md` 中 Task 5。
- **高保真承接**：当前高保真评审脚本与变更追溯已拆到 `docs/demo/highfi-review-script.md` 与 `docs/demo/highfi-change-log.md`，后续 mock/live 切换、场景更新先改这两份再回填其他文档。
- **与总实施计划对齐**：全栈 MVP 路径仍以 `docs/superpowers/plans/2026-03-26-smart-livestock-app-implementation.md` 为准；本文仅列 **前端壳层与权限** 的显式欠账，避免误以为 Demo 即终态。

---

## 如何跟踪

建议在项目管理工具中为本文件每条 **P0** 建工单，并指向具体规格章节（如 `3.4` 权限、`12.1` 导航）。本文变更时在 `docs/demo/change-log.md` 末尾记一行「已更新 post-lowfi-follow-ups」即可。
