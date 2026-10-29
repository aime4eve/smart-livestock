# AGENTS.md — 智慧畜牧项目 Agent 行为规则

用中文输出。代码注释用英文，面向用户的文案和解释用中文。

> **参考资料（按需查阅，不在此文件维护）**：
> - 项目概述/技术栈/限界上下文/迁移表/Controller/路线图 → `docs/reference/project-overview.md`
> - 部署/端口/凭据/Seed/Flyway → `docs/reference/deployment.md`
> - 踩坑经验（五段式）→ `docs/reference/lessons-learned.md`
> - API 契约 → `docs/api-contracts/`

---

## 0. 工作区改码契约（所有代码修改任务的前提）

> 正本：[`../WORKFLOW.md`](../WORKFLOW.md)——分级适用、修改前四段输出（需求理解/验收标准/不做范围 → 调用链/改动文件 → 边界·安全·性能·兼容风险 → 实现与测试方案）、确认后小步修改、五件套交付。
> 与本文件 §3 分级流程叠加执行，冲突以更严者为准；涉 `smart-livestock-server/shared/`、Flyway 迁移、鉴权逻辑、部署脚本改动的方案**必须等用户确认后才能编码**。
> 红线：交付必须附实际执行过的构建/测试/检查命令及结果；**没有实际运行的验证不得标记为通过**。

---

## 1. Build / Deploy / Test 分工

- **编译**：Agent 可自行执行（`./gradlew compileJava`、`flutter build` 等），验证代码可构建。
- **部署**：Agent 可自行执行 dev 部署（`cd smart-livestock-server && ./scripts/deploy.sh dev`）；test 环境必须等用户通知后再执行。
- **4 环境全量部署链**（dev / test / 86 HOSTED / 223 ONPREM，用户明确要求"全部部署"时按序执行，实操细节见 `docs/deployment/release-deployment-playbook.md`、经验 #23）：前端 `Mobile/mobile_app/build_web.sh` → `deploy.sh dev`（19080）→ `deploy.sh test`（18080）→ 123 上 `build-release-package.sh --skip-web` 打包 + verify → Mac 两跳传输逐台升级 86/223（继承 `.env.release`+certs、sed RELEASE_VERSION 以打包日志为准、down 旧栈、`MIN_MEM_GB=15 MIN_DISK_GB=50` 覆盖安装、免 sudo）。**顺序不可颠倒**：86/223 包内 frontend 复用 dev/test 阶段 rsync 上去的新前端。各环境生效判据：容器内 `main.dart.js` md5 对比本地 + 种子账号登录 200。
- **集成测试**：仅在部署完成后执行；不得在部署前提前运行。
- **顺序**：编码 → 编译验证 → 部署 → 集成测试。
- **全量测试基线**：后端全量测试当前有 19 个既有失败（14 个 Testcontainers Docker 环境初始化 + 5 个 `AlertReadStatusTest` mock 债务）。判断本次回归时优先运行目标测试，并对比失败集合是否扩大。

---

## 2. 当前工程基线

- **主线**：`Mobile/mobile_app/` + `smart-livestock-server/`；`PC/` 仅历史归档。
- **数据文档事实源**：代码、Flyway 迁移、部署验证记录优先于历史 checklist；`docs/archive/features/*` 与 `Mobile/docs/*` 是历史快照。
- **时序分区**：`temperature_logs`、`rumen_motility_logs`、`activity_logs`、`device_telemetry_logs`、`anomaly_scores` 由 `PartitionMaintenanceService` 自动维护；不要手工预建分区，除非先说明与该服务的兼容性。
- **GPS 写入**：`TelemetryIngestionService` 主事务只写 `gps_ingestion_tasks`，由 `GpsIngestionTaskScheduler` 异步写 `gps_logs`；不要在 ingest 事务里重新直写 GPS。
- **GPS 幂等与清理**：以 `(device_id, recorded_at)` 为幂等键；压测/验证数据必须用明确时间窗和 `MANUAL_IMPORT` source，结束后清理并恢复设备快照。
- **多来源数据**：写入共享表时必须保留合法 `source`，不得把 `DATAGEN` 与真实来源混淆。
- **AI 仿真过渡**：datagen 仿真数据仅用于 Phase C 管道研发和模型预训练，不能作为真实效果验收；一旦可评估的真实采集遥测可用，必须按 C6/C7 切换到真实数据适配、微调和 real-only 评估，禁止用合成结果混充生产效果。

---

## 3. 新功能实施流程（按复杂度分级）

**根据变更规模选择对应流程，不要一刀切。**

> **硬性规则（用户裁决 2026-09-05）**：凡智能体自己设计的业务流程/新功能，**未经用户明确允许，一律不允许动手写代码**——只允许产出设计文档、方案说明和工单；编码必须等用户批准后才能开始。此规则优先于下述任何分级流程。

### trivial（单文件 bugfix、文案、样式微调）
- 直接改 + 编译验证，**免 spec/plan**。
- 验证：编译通过 + 相关测试通过。

### standard（模块内改动、新端点、新页面）
- 简要说明方案（会话内即可，不必产出独立 spec 文件）。
- 验证：编译通过 + 测试通过 + 关键路径自测。

### feature（新功能、跨模块、视觉重构）
- 完整分阶段确认工作流（每阶段需用户确认后才进入下一阶段）：
  1. **HTML 高保真原型** → 含 CSS `:root` 自定义属性（颜色/间距/圆角/阴影），可被 `prototype-to-flutter-fidelity` skill 解析
  2. **spec 设计文档** → 含设计令牌表 + 组件视觉规格，令牌确认后锁定
  3. **plan 实施计划** → 含 Task 0（视觉保真准备）+ 每个 Task 的保真验证步骤
  4. **编码 + 编译验证 + 视觉保真验证**（`prototype-to-flutter-fidelity` skill）
  5. **部署 dev**（`./scripts/deploy.sh dev`）
  6. **用户集成测试**
  7. **提交 git + 合并 PR + 关闭工单**
- 产出物归档：原型 `docs/prototypes/`，spec `docs/superpowers/specs/`，plan `docs/superpowers/plans/`
- 参考：NIX-52（告警 UI/UX 重设计）是包含视觉保真闭环的范例

### plan 确认后的执行准则（用户裁决 2026-09-29）

**适用范围**：feature 流程第 4 步（编码阶段），plan 经用户批准之后。

1. **子智能体按部就班做 Task**：由子智能体逐 Task 实施，**串行推进不并发**，保证产物质量；每个 Task 完成后先通过 plan 中该 Task 的验证步骤，再进入下一个 Task。
2. **主智能体评审 + 指挥修复**：每个 Task 的产物由主智能体评审编码质量（对照 plan 验证步骤、本文件规范、lessons-learned）；评审意见下达给子智能体，子智能体**先评估评审意见再执行修复**（有异议可提出，不盲改），修复后由主智能体复核。
3. **主智能体内建浏览器功能验证**：全部 Task 完成后，主智能体用内建浏览器完成端到端功能验证（对照 spec 验收标准与原型保真），通过后才进入第 5 步部署 dev。

---

## 4. 代码实现规范

### 4.1 国际化（i18n）

- 所有面向用户的文本必须通过国际化资源引用，禁止硬编码中/英文字符串。
- Flutter：`AppLocalizations` + `lib/l10n/app_*.arb`（中英文同步），`context.l10n.xxx` 访问。
- 后端：`MessageSource`（`messages_zh/en.properties` 双语同步），按 `Accept-Language` 返回。
- 校验：`flutter gen-l10n` 无缺失 key，`flutter analyze` 无未定义引用；后端编译通过且 properties 双语对齐。

### 4.2 种子数据（Seed Data）

- 新增表/枚举/业务规则时同步生成种子数据（Flyway 迁移），使新功能可直接验证。
- BCrypt hash 必须三步验证（生成时 bcrypt.compare → 写入迁移 → 部署后 curl 验证），不得跨迁移复制旧 hash。可用 `scripts/verify-seed-hash.sh`。
- 种子凭据/部署细节见 `docs/reference/deployment.md`。

---

## 5. 牧场切换数据刷新规则

**所有使用 farm-scoped API（ApiClient 的 farmGet / farmPost / farmPut / farmDelete）的 Controller：**

1. **继承基类**：使用 `FarmScopedNotifier` 或 `FarmScopedAsyncNotifier`（`core/api/farm_scoped_controller.dart`），不要直接继承 `Notifier` / `AsyncNotifier`。
2. **在 build() 开头调用 `watchActiveFarmId()`**：声明对 activeFarmId 的依赖，确保切换时自动重建刷新。
3. **checklist**：Repository 用 `farmGet()` 等方法 → Controller 必须继承 FarmScoped* 基类。
4. **违反症状**：牧场切换后页面数据不更新，仍显示旧牧场数据。

---

## 5b. CI 守护协议（2026-10-28 起，双流水线必须常绿）

> 背景：Backend CI 自 10-06、Flutter CI 自 09-28 连红近月无人感知。根因=CI 是事后验证不是门禁（直推 master，部署走本地 deploy.sh），且本地无 Docker 时 Testcontainers/schema-validate 类失败全被遮住。修复复盘见知识库 `10-Projects/02-smart-livestock/2026-10-28-GitHub-CI双流水线复绿.md`。

1. **push 前预检**：改动后端或前端代码后，跑 `./scripts/precheck-ci.sh`（≈6 分钟，本地逐字复刻两条流水线：后端全量单测 + flutter analyze + 全量测试，`CI=true` 使 golden/字体类测试与 CI 同步 skip）。纯 docs/marketing 改动可跳过。
2. **后端改动涉实体/迁移/测试装配时加跑远程集成测试**：`./scripts/remote-integration-test.sh`（≈1 分钟增量，借 123 服务器 Docker 跑本机跑不了的 Testcontainers 用例——schema validate、@DataJpaTest 装配、fixture CHECK。testbed 位于 `/data/agentic/ci-testbed/`，独立于打包目录）。`--with-journey` 可跑 integration/** 包 Journey 测试，但该批从未被 CI 执行、长期未维护（2026-10-28 首跑大面积挂为已知历史债），修复另立工单。
3. **push 后盯绿才算收口**：推送后用 `gh run list` 确认两条流水线绿（触发条件按 paths 过滤，只改后端只会跑 Backend CI）。红了**立即修**，不允许带着红 CI 结束会话或开始新任务。
4. **防 validate/约束类失败的静态对账**（写代码时就要做，CI 才能查）：
   - 实体字段类型必须与 Flyway 列类型一致：JSONB 列必带 `@Column(columnDefinition = "jsonb")`（带 converter 也一样）；`DOUBLE PRECISION` 列用 `Double` 不用 `BigDecimal`；UUID 列用 `java.util.UUID`。
   - `@DataJpaTest` 只注册 Spring Data 接口——测试注入手写 `@Repository` 实现类必须 `@Import`。
   - 集成测试 fixture 的插入值（枚举/状态列）必须对照迁移里的 CHECK 约束。
   - Hibernate validate 报错即停：修一处 mismatch 前，先全量静态对账该实体所有字段与迁移 DDL。
5. **golden 测试跨平台不可比**：一律 `skip: Platform.environment['CI']=='true'`（先例 `truth_reference_tab_visual_capture_test`），本地生成比对，禁止把 golden 比对留给 CI。

---

## 6. 故障层定位（先定位层，再查症状）

**先判断工作单元在哪一层损坏，只修那一层。最容易被编辑的层（代码）总替外层背锅。**

项目故障层（从外到内逐层排除）：

1. **环境层** — 工具链 / 沙箱 / 外置卷 → `._*` 污染、Flutter 崩、卷权限
2. **部署层** — Docker / nginx / 镜像 → API 正常但前端无变化、入口缺失
3. **数据层** — Flyway / 种子 / 表结构 → 接口返回空、字段溢出、checksum mismatch
4. **代码层** — 文件 / 函数 → 编译错误、逻辑 bug → 最后才改这里

Agent 自身出问题时（元故障）：

- 任务理解偏差 → 重读请求，明确假设，不要反复改代码
- 漏读约束 / 约定 → 查 AGENTS.md / docs / 相关代码
- 验证不充分 → 补编译 / 测试 / 端到端验证
- 提前停止 → 成功标准未满足就停了；"做了" ≠ "完成了"

下面的经验判据速查按症状定位，本节按层定位，互补使用。

---

## 7. 经验判据速查（每次会话生效）

> 完整五段式见 `docs/reference/lessons-learned.md`，遇下列症状先查编号再翻原文。

**环境 / 工具**
- `._` 污染：UTF-8 解码失败 / git `non-monotonic index` / 工具读到不该读的文件 → 先 `find . -name '._*' | head` — #1 #2
- 沙箱 Flutter 崩：一律 `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true`；**例外**：iOS 签名构建（build ipa / build_ios*.sh）必须用真实 HOME——keychain 按 HOME 定位，假 HOME 会报"无开发证书" — #4 #24

**部署 / 前端**
- 前端入口/功能"缺失"，代码里有 key → 先 grep 容器内 `main.dart.js`，不一致则是 nginx 镜像未重建 — #6
- API curl 正常但前端无变化 → 前端未重新构建部署（`build_web.sh` + `deploy.sh` 两步缺一不可）— #7
- 部署后判活：`/actuator/health` 502→401 是启动中正常轨迹（该端点要认证），种子账号登录 200 才是可用；前端生效看容器内 `main.dart.js` md5 对比本地 — #23
- 发布包升级：verify 11/13 属预期（2 条证书 FAIL = 继承成功，看 SHA256SUMS）；目标版本号以打包日志 `[OK] version` 为准（本地每次 deploy.sh 会使 build.number +1 并 rsync）— #23
- 远程进程探活禁裸 `pgrep -f <关键词>`：ssh 命令行自匹配误报 RUNNING，用 `pgrep -af ... | grep -v pgrep` 或产物 mtime/日志尾 — #23
- 86/223 升级免 sudo（hkt 在 docker 组）；资源预检 FAIL 先 `df -h` 核实再用 `MIN_MEM_GB/MIN_DISK_GB` 覆盖，旧版本目录留作回滚点 — #23

**后端 / 数据库**
- 接口返回空列表 → 先核代码 glob 与挂载路径，再进容器 `ls` 数据卷 — #3
- `@Query` 返回空无报错 → 检查 JPQL 参数名是否与保留字冲突 — #8
- 第三方时间字段 → 直接用原始数值不换算（`toInstant(ZoneOffset.UTC)`），前端也不做 `toUtc()` — #17
- 同步数据量不收敛 → 检查时间解析是否 fallback `now()` 导致 cursor 去重失效 — #10
- 新增写路径只有 mock 单测 → 库约束脱测，必须补真库集成测试（Testcontainers/部署后冒烟）— #19
- 迁移改动后只在存量库重启验证过 ≠ 通过 → 必须全新库跑通（生成列禁 SELECT *、哈希列用 VARCHAR、改动修 checksum）— #20
- 多数据源写同一表 → 必须有 `source` 字段 — #11
- Flyway checksum mismatch → 先查 `flyway_schema_history` 再对比 git 文件 — #12
- `numeric field overflow` → 定位列 precision/scale，差值列至少 DECIMAL(10,2) — #13
- GPS 轨迹查询空（`gps_logs` 有数据）→ 先查 active installation，再查时间格式 URL 编码 — #14
- Excel 数值列解析失败/显示带 `.0` → POI NUMERIC 单元格读出是 double，先按 Excel 显示语义去尾再解析；宽容解析+兜底默认值会让数据错误隐身 — #18

**代码审查**
- 评审路由/分档/状态机 → 从 design 原文时态主语倒推，代入调用方参数逐步求值，不要从阈值数字联想 — #5
- 修复功能后必须端到端走完整链路，不要只测一步 — #15
- `farmGet` 返回 404 且 URL farmId 与路径粘连 → suffix 缺前导 `/` — #16

**收口验证（宣布完成前的硬性清单，详见 #25）**
- 新端点逐个 curl 带真实数据冒烟（200 且业务字段非空），不许"等 UI 一起测" — #25
- 新页面做可达性倒查：哪个角色、从哪个入口、几次点击到达；入口缺失=未完成 — #25
- 新 UI 元素对照原型盘点全部挂载点（同一"详情"可能有弹层+独立页多处） — #25
- Flutter Web 内建浏览器走查主旅程并截图留证；插件异常不得把 `e.toString()` 裸露给用户 — #25
- 执行 SQL/部署前核对环境↔容器↔库名（dev=sl-dev-postgres-1，test=smart-livestock-server-postgres-1） — #25

---
