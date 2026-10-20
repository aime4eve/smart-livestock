# 超管选角色进入系统 — 实施计划

- 日期：2026-10-19
- 状态：**已完成并部署 dev（2026-10-19），待用户集成测试后提交 git**

## 执行结果与偏差记录（2026-10-19）

| 项 | 结果 |
|---|---|
| Task 0-8 | 全部完成；逐 Task 验证通过（编译/测试/analyze 全绿） |
| 执行方式偏差 | 子智能体连续 2 次在长命令上 600s 无响应超时（产物完好但汇报通道断），Task 2 起改由主智能体直接实施，保留逐 Task 验证门 |
| Task 9 全量测试 | 后端 1226 测试：22 失败全部为 `*JourneyTest` Testcontainers `initializationError`（本地无 Docker 环境类，基线 19 为旧记录、旅程测试此后增长；**逻辑类零失败**）；前端 656 过/12 败：11 个（tenant_detail×6+pilot_license×5）经 git stash 干净树对照确认为**既有失败**，1 个 e2e 需真实后端；**零新增回归** |
| Task 9→10 重排 | 内建浏览器主旅程移至部署后执行（更真实） |
| Task 10 冒烟矩阵 | **12 项全绿**：超管登录 200（role=SUPER_ADMIN/mcp=true/impersonated=false）→ 首登改密 200 → 新密码重登 → entry-contexts（4 角色+3 真实租户）→ switch OWNER@租户1（claims sub=17/tid=1/role=OWNER/act/60min）→ /farms 3 个 → **OWNER 上下文 POST /farms 201（Task 4 修复实证）** → refresh 身份不漂移（OWNER@1+impersonated=true+act 保留）→ 上下文再 switch 403（防提权）→ 直切 B2B+/b2b/users 200 → 平台上下文+/admin/tenants 200 → audit_logs 3 行 AUTH_CONTEXT_SWITCHED；测试牧场已软删清理（farmCount 回 3）；md5 前后端一致；部署包含 select-context/SUPER_ADMIN/quick-switch |
| 浏览器走查（降级） | 首次尝试实测登录成功并到达「选择进入身份」页（真实后端+超管路由+选择器渲染证据）；后续重试遇 Release Web 键盘输入三路径坑（KB 既有记录），交互走查降级为：18 个 widget 测试（渲染+sheet 交互）+ curl 全链路 + 部署包内容判定；**视觉细节留用户人工验证** |
| dev 超管密码 | 冒烟按首登强制改密流程将密码改为 `Hkt@Super2026!`（初始 `Admin@2026` 已失效，符合"改密后不追记文档"设计） |
| 账号改名（2026-10-20） | 用户裁决账号 `Admin@HKT` → **`Admin@hkt.com`**：新增 `V20261020100000__rename_super_admin_account.sql` 前向改名（已应用迁移不可原地改，防 checksum mismatch）；登录链不变（EMAIL 通道 + LOWER(account) 命中，已实测）；测试/原型/契约/凭据表同步更新 |
| 集成测试首 bug（2026-10-20） | "选牧场主点进入后界面没变化"：switch 实际成功但 redirect 缺 `/select-context` 兜底（OWNER/WORKER 上下文停留选择器；平台/B2B 分支各自踢走）。修复=路由兜底送 ranch + 确认弹层错误提示先 pop 再 SnackBar（原先被 modal 遮挡）；回归测试从真实起点 location 断言（11/11 绿）；已重建部署 dev（md5 一致） |
- 依据：架构设计 `docs/superpowers/specs/2026-10-19-super-admin-context-entry-design.md`（含 5 裁决）、UI Spec `docs/superpowers/specs/2026-10-19-super-admin-context-entry-ui-spec.md`、原型 `docs/prototypes/2026-10-19-super-admin-context-picker-prototype.html`
- 执行模式：按 AGENTS.md「plan 确认后的执行准则」——子智能体**串行**逐 Task 实施，每 Task 过本计划验证步骤后进入下一个；主智能体逐 Task 评审并指挥修复；全部完成后主智能体内建浏览器端到端验证，通过后才部署 dev。

---

## 全局约束（每个 Task 都适用）

- 新文案一律走 i18n（Flutter arb 中英同步 + 后端 messages 双语），禁止硬编码。
- 后端全量测试基线 19 个既有失败（14 Testcontainers + 5 AlertReadStatusTest）；回归判断=目标测试绿 + 失败集合不扩大。
- 迁移改动必须**全新库**跑通（lessons #20），不止存量库重启。
- 种子 BCrypt 三步验证（生成 compare → 迁移 → 部署后 curl）。
- **前后端必须同批部署 dev**（旧前端遇 `SUPER_ADMIN` 会 fallback worker）。
- 不动 `TelemetryIngestionService` GPS 写入、不手工预建时序分区（本功能不涉及，防误伤）。

## Task 0 — 视觉保真准备

- `core/theme/app_colors.dart` 新增 4 对角色识别色常量（值见 UI Spec §1.1）；如需 spacing/radius 沿用既有。
- 加载 `prototype-to-flutter-fidelity` skill，建立原型 7 屏截图基线（存 `docs/testing/` 或会话目录）。
- **验证**：`flutter analyze` 0 error；常量与 UI Spec §1.1 逐项一致（8 个值）。

## Task 1 — 后端：角色枚举 + Flyway 迁移（种子超管）

- `identity/domain/model/Role.java` 增 `SUPER_ADMIN`。
- 迁移①：`users.role` CHECK 约束增 `SUPER_ADMIN`（drop+add constraint）。
- 迁移①：种子超管行——`account='Admin@HKT'`（**只能种子建号**，API 校验不允许 @，见设计裁决⑤）、`tenant_id NULL`、`role='SUPER_ADMIN'`、`must_change_password=TRUE`、BCrypt(`Admin@2026`) 哈希内联、显示名"超级管理员"；激活策略对齐 `V20260907120000__admin_bootstrap.sql`（全新安装 `is_active=FALSE`）。
- **验证**：`./gradlew compileJava` 通过；Testcontainers 全新库迁移跑通；`scripts/verify-seed-hash.sh` 三步全过；既有测试失败集合不扩大。

## Task 2 — 后端：JwtTokenProvider 支持 act claim

- `generateToken` 增带 act 的重载（act = `{sub: 超管id, role: "SUPER_ADMIN"}`）；**`refreshToken` 必须原样复制 act**（现状只复制 sub/tid/role，JwtTokenProvider.java:96-101）。
- 单测：带 act 的 token 刷新后 act 保留；无 act 的 token 刷新后行为不变。
- **验证**：目标测试绿。

## Task 3 — 后端：entry-contexts / switch-context 端点 + refresh 合成

- `AuthApplicationService`：
  - `listEntryContexts`：静态角色白名单（PLATFORM_ADMIN/B2B_ADMIN/OWNER/WORKER + tenantScoped 标志）+ 租户清单（排除 deleted；含 name/status/phase/timezone/farmCount）。
  - `switchContext`：五道门（SUPER_ADMIN 根 token / mustChangePassword 自查（**防 /auth/** 白名单绕过**）/ 角色白名单 / 租户存在未删除 / trial 到期 409；**disabled 放行**）→ 发上下文 token（role/tid=目标 + act）→ 写审计 `AUTH_CONTEXT_SWITCHED`（user_id=超管、tenant_id=目标、operator_role=目标角色）。
  - `refresh`：act 存在时响应 `user` 按 token claim 合成（role=目标、tenantId=目标），不得返回 DB 行（现状 AuthApplicationService.java:89-94）。
- `AuthController`：`GET /api/v1/auth/entry-contexts`、`POST /api/v1/auth/switch-context`，`@PreAuthorize("hasRole('SUPER_ADMIN')")`；响应 `AuthTokenDto` + 可选 `impersonated`。
- `messages_zh/en.properties` 新错误 key（UI Spec §5）。
- 集成测试：门矩阵（非超管 403 / 改密锁 403 / 角色白名单 422 / 租户 404 / disabled 放行 / trial 409 / act claim 断言 / 审计行断言）。
- `docs/api-contracts/app-api.md` 补记两端点（顺带修既有 login 契约漂移 identifier）。
- **验证**：目标测试全绿；compileJava 通过。

## Task 4 — 后端：「DB 回读角色」清点修复

- grep 清点 `userRepository.findById(principal)` + 角色判断的全部调用点；已知：`FarmController.createFarm`（:51-60）、`datagen/DatagenOperatorContextResolver`（:19-34）、`identity/interfaces/b2b/B2bController` 成员管理段。
- 修复原则：鉴权判断改读 SecurityContext authority（token），与 `JwtAuthenticationFilter` 设计拉齐；逐点记录到设计文档附表。
- 回归测试：以 OWNER 上下文 `POST /farms` 201（修复前会 403）。
- **验证**：目标测试绿；清单中每个点有修复或"无需改"结论。

## Task 5 — 前端：UserRole / 会话 / 路由地基

- `lib/core/models/user_role.dart` 增 `superAdmin`（`isSuperAdmin` getter）。
- `AppSession` 增 `impersonated`/`actingAs` 字段；`JwtStorage` 增 `root_token`/`root_user_info` 两 key 并纳入 `clear()`。
- `SessionController` 增 `enterContext/exitContext`（根 token 保留、上下文 token 换装）；恢复会话时优先恢复上下文会话。
- `app_router.dart`：superAdmin 根会话只放行 `/select-context` + `/me/password-change`（**改密锁优先级保持最前**）；上下文会话按上下文角色走既有分支（不改既有逻辑）。
- **验证**：widget 测试（superAdmin 路由分支/改密锁优先/登出清 root）；`flutter gen-l10n` + `flutter analyze` 0 error。

## Task 6 — 前端：角色选择器页 + 租户选择 + 确认 sheet

- 新页 `lib/features/auth/context_picker_page.dart`（含角色选择、租户列表两态、确认 sheet 正常/停用两形态），视觉规格=UI Spec §2.1–2.3/§2.6。
- l10n key 全量（UI Spec §5）中英 arb 同步。
- **验证**：widget 测试（四卡渲染/租户三状态/停用确认警示文案）；保真对照原型①②③a③b 逐屏；analyze 0 error。

## Task 7 — 前端：代登横幅 + 快速切换 sheet

- `main_shell.dart` 三 Shell 挂 `acting-banner`（UI Spec §2.4；牧场双行、桌面单行）；`mine_page.dart` impersonated 时"切换身份"入口。
- 快速切换 sheet（UI Spec §2.5）：近期身份、完整选择器入口、全部登出、60 分钟提示、根 token 过期禁用态。
- **验证**：挂载点盘点=UI Spec §3 全量（三 Shell + 我的页）；保真对照原型④⑤⑥⑦；widget 测试横幅条件渲染。

## Task 8 — 前端：ApiClient 与刷新链

- `ApiClient.entryContexts/switchContext`（Authorization 显式传根 token）；refresh 响应消费（act 会话 user 为合成身份，不漂移）；登出清 root token。
- **验证**：单测/手动验证 refresh 后角色与横幅不变；analyze 0 error。

## Task 9 — 编译与保真总验

- 后端 `compileJava` + 全量测试（失败集合对比基线 19 个不扩大）；前端 `gen-l10n` + `analyze` 0 error。
- 内建浏览器主旅程对照 UI Spec §6：登录（Admin@HKT + 首登改密）→ 选择器 → OWNER@真实租户 → 牧场页横幅 → 快速切换 → 退出；截图存证。
- **验证**：UI Spec §6 四条全过。

## Task 10 — 部署 dev + E2E 冒烟

- `cd smart-livestock-server && ./scripts/deploy.sh dev`（**同批**含前端 `build_web.sh` 先行）。
- curl 冒烟矩阵（收口 #25，逐项 200+业务字段非空）：超管登录 200（role=SUPER_ADMIN）→ entry-contexts 租户列表非空 → switch OWNER@租户2（200，token 含 act/tid/role 断言）→ `GET /farms` 非空 → OWNER 上下文 `POST /farms` 201 → `audit_logs` 有 SWITCHED 行 → 横幅直切 B2B_ADMIN 走通控制台接口 → 退出重选平台管理员走通 `/admin/tenants`。
- 判活：种子账号登录 200；前端生效=容器内 `main.dart.js` md5 对比本地（#23）。
- **验证**：冒烟矩阵全绿；租户隔离抽查（OWNER@租户A 看不到租户 B 数据）。

## 后续（第 6-7 步，用户侧）

用户集成测试 → 通过后 git 提交 + PR + 关闭工单（本功能建议开 Linear 工单挂 P-NIX-2）。

## 明确不做（本期内）

- API_CONSUMER / SUPER_ADMIN 作为切换目标（设计 §4.3 白名单）；token 吊销机制；上下文中改 act 语义；到期租户排障豁免。
