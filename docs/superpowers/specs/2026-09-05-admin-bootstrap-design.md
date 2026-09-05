# 发布部署管理员账号设计与引导方案（提案）

> **状态**：设计提案，待评审后按 feature 流程实施（建议工单 NIX-191）。
> **背景**：86（HOSTED 托管验证）/ 223（ONPREM 离线独立部署）双机部署实战后暴露的账号治理问题。部署操作本身见 `release-deployment-playbook.md`。

## 1. 现状与风险

| 事实 | 影响 |
|------|------|
| Flyway `V4__seed_data.sql` 在**每一次**全新安装时都会创建 `platform_admin`（手机号 `13800000000`，角色 `PLATFORM_ADMIN`），口令为发布包内公开的演示口令（BCrypt 可查、文档可查） | 任何拿到发布包或读过文档的人，都拥有每一台 ONPREM 客户服务器的平台管理员权限；这是市场测试版对外交付的**最高危已知项** |
| 演示种子（Demo 牧场、owner、牧工、API Key 等）同样随安装落库 | 客户首次进入看到的"数据"是我方的演示数据；演示身份与生产身份无法区分 |
| 唯一的口令治理手段是 `PUT /api/v1/me/password`（自改口令），无强制改密机制 | 依赖人工自觉；无法保证交付前已轮换 |
| 86/223 当前共享同一管理员身份 | 操作不可归因（审计日志只有账号没有自然人） |

**目标**：① ONPREM 交付时，平台管理员身份归客户、口令不为我方/发布包所知；② 新装环境不存在已知口令的可登录管理账号；③ 首登强制改密；④ 托管环境（86）操作可归因到个人。
**非目标**：MFA/SSO/LDAP（后续工单）；在线支付与合同流程（工单外）；K8s/多机。

## 2. 方案对比

| 方案 | 思路 | 优点 | 缺点 | 结论 |
|------|------|------|------|------|
| **A. 环境变量引导 + 首登强制改密**（推荐） | `.env.release` 提供 `ADMIN_PHONE`/`ADMIN_INITIAL_PASSWORD`；应用启动幂等引导：不存在任何 PLATFORM_ADMIN 时创建；`must_change_password` 标记首登强制改 | 实现小、离线可用、口令只在安装者 env 里、与现有 compose/env 体系一致 | 初始口令在 env 明文（交付后即改密，风险窗口有限） | ✅ 采纳 |
| B. 一次性 setup token 向导 | 安装完成打印一次性 `/setup?token=` 链接，网页向导创建管理员 | 无明文口令落 env；体验正式 | 新公开端点+向导页+token 生命周期管理，实现量约为 A 的 3 倍；离线机打印链路也要做 | 后续增强 |
| C. CLI `create-admin` | `docker compose exec app ...` 命令行建号 | 零 Web 面 | 客户运维需进容器执行命令，交付体验差；难做强制改密 | 否 |

## 3. 方案 A 详细设计

### 3.1 引导创建（后端）

- 新增 `identity.application.AdminBootstrapInitializer`：`ApplicationReadyEvent` 触发、事务内、**幂等**：
  - 仅当系统中**不存在任何 active 的 PLATFORM_ADMIN** 时，按 env `ADMIN_PHONE` + `ADMIN_INITIAL_PASSWORD`（BCrypt）创建；已存在则跳过（绝不重置既有口令）。
  - 创建出的账号 `must_change_password = true`；写审计（AuditLog，仿试点授权）：`ADMIN_BOOTSTRAP_CREATED`，只记手机号后四位，不记口令/明文。
  - env 缺失或口令过弱（长度<10 或等于已知演示口令）→ 启动失败 **fail fast**（安装器已拦截模板值，这里是第二道闸）。HOSTED 的 dev/test compose 提供同值 env（`13800000000` + 熟悉的演示口令），开发者体验不变。
- 配置属性类 `smartlivestock.admin-bootstrap.*`，进 `.env.release.example` 并由 `check-env.sh`/安装器校验非模板、强度达标。

### 3.2 强制改密（后端 + Flutter）

- 迁移：`users` 增 `must_change_password BOOLEAN NOT NULL DEFAULT FALSE`；对**种子创建的已知管理员**置 `true`（见 3.3）。
- 登录响应与 `GET /me` 携带 `mustChangePassword`；为 true 时除登录/登出/自身改密/授权白名单外全部 API 返回 `PASSWORD_CHANGE_REQUIRED`（错误码+双语）。
- Flutter：登录后命中标记 → 强制进入改密页（新 arb key 中英同步）→ `PUT /me/password` 成功即清除标记放行。
- `PUT /me/password` 增加口令强度校验（长度/字符类别），失败 `VALIDATION_ERROR`。

### 3.3 演示种子与生产安装分离（关键一步）

现状：演示数据全在 `V4__seed_data.sql` 等迁移里，新装必然复现已知口令。迁移代码无法按环境分支，正确做法是**按 Flyway location 分离**：

- 新增 `db/demo/` location，**仅 dev/test 的 Spring profile 配置**（`spring.flyway.locations=classpath:db/migration,classpath:db/demo`）；release compose 的 app 不配置该 location → 全新客户安装不含任何演示身份/演示数据。
- 新增一条产品迁移：将历史种子创建的已知管理员置 `must_change_password=true`（存量 dev/test 库也会应用——开发者随后被引导改密，或依赖 dev profile 的 demo location 重建演示号；实施时定稿，倾向后者）。
- `V4` 等既有迁移**不改动**（checksum 已在多环境锁定，lesson #20/#12）。

### 3.4 安装/交付流程变化

- `.env.release.example` 增两个必填项 + 注释（口令强度、交付后即改）。
- `install-release.sh` 预检：非模板值、长度、非已知演示口令（安装器已有的"模板值拦截"模式照抄）。
- 安装指南/部署实战指南（playbook §5 加固清单第 1 项）同步更新：交付前改密从"人工自觉"变为"产品强制"。
- 交付客户（如 223 类机器）时：`ADMIN_PHONE` 填客户管理员手机号，初始口令现场生成、交付即改；我方不留存。

### 3.5 托管环境（86）账号治理

- 我方运营改为**个人实名**管理员账号（bootstrap 各自创建/管理员后台创建），停用共享账号；审计日志即可归因。
- 86 作为演示环境可保留 demo 种子（HOSTED 本就是演示/托管语境），但与生产管理员身份分离。

## 4. 实施拆解（建议 NIX-191，feature 流程）

| # | 任务 | 验证 |
|---|------|------|
| 1 | 迁移：`must_change_password` 字段 + 已知种子管理员置位 | 全新库跑通（lesson #20 口径） |
| 2 | `AdminBootstrapInitializer` + 配置属性 + fail fast + 审计 | 单测（存在/不存在/弱口令三分支） |
| 3 | 错误码 `PASSWORD_CHANGE_REQUIRED` + 登录//me 携带标记 + 改密清除 | Controller 测试 |
| 4 | `db/demo` location 分离 + dev/test profile 配置 + release compose 不含 | **dev、release 两种 profile 全新库各跑一遍** |
| 5 | Flutter 强制改密页 + 路由拦截 + arb 双语 | widget 测试 + gen-l10n |
| 6 | env 模板 + 安装器预检 + 三份指南更新 | verify + 安装演练 |
| 7 | 86/223 按新流程重装演练（含交付加固清单执行） | 双机实测 |

## 5. 交付前立即可做的临时加固（无需等本方案实现）

1. `PUT /api/v1/me/password` 轮换 86/223 的默认管理员口令（**会改变现用测试口令，由使用者自行择机执行**）。
2. 删除/停用不需要的演示账号与演示租户（223 交付客户场景必做）。
3. tile-worker key 轮换（运维指南 §2.4）、确认 JWT_SECRET/POSTGRES_PASSWORD 非模板（安装器已强制）。
4. 开启定期备份（运维指南 §3）。

## 6. 开放问题

1. `db/demo` location 分离后，dev 的演示数据范围是否需要扩充（当前 dev/test 共用一套演示种子）。
2. 口令强度策略（最小长度、字符类别、是否防TOP-N弱口令）需要产品定稿。
3. 管理员账号找回：ONPREM 离线场景管理员锁死后的恢复路径（建议：服务器本地 CLI 重置工具，作为方案 C 的最小版纳入范围与否）。
