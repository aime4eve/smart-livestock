# AGENTS.md — 智慧畜牧项目 Agent 行为规则

用中文输出。代码注释用英文，面向用户的文案和解释用中文。

> **参考资料（按需查阅，不在此文件维护）**：
> - 项目概述/技术栈/限界上下文/迁移表/Controller/路线图 → `docs/reference/project-overview.md`
> - 部署/端口/凭据/Seed/Flyway → `docs/reference/deployment.md`
> - 踩坑经验（五段式）→ `docs/reference/lessons-learned.md`
> - API 契约 → `docs/api-contracts/`

---

## 1. Build / Deploy / Test 分工

- **编译**：Agent 可自行执行（`./gradlew compileJava`、`flutter build` 等），验证代码可构建。
- **部署**：Agent 可自行执行 dev 部署（`cd smart-livestock-server && ./scripts/deploy.sh dev`）；test 环境必须等用户通知后再执行。
- **集成测试**：仅在部署完成后执行；不得在部署前提前运行。
- **顺序**：编码 → 编译验证 → 部署 → 集成测试。
- **全量测试基线**：后端全量测试当前有 19 个既有失败（14 个 Testcontainers Docker 环境初始化 + 5 个 `AlertReadStatusTest` mock 债务）。判断本次回归时优先运行目标测试，并对比失败集合是否扩大。

---

## 2. 当前工程基线

- **主线**：`Mobile/mobile_app/` + `smart-livestock-server/`；`PC/` 仅历史归档。
- **数据文档事实源**：代码、Flyway 迁移、部署验证记录优先于历史 checklist；`docs/features/*` 与 `Mobile/docs/*` 是历史快照。
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
- 产出物归档：原型 `docs/marketing/`，spec `docs/superpowers/specs/`，plan `docs/superpowers/plans/`
- 参考：NIX-52（告警 UI/UX 重设计）是包含视觉保真闭环的范例

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
- 沙箱 Flutter 崩：一律 `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true` — #4

**部署 / 前端**
- 前端入口/功能"缺失"，代码里有 key → 先 grep 容器内 `main.dart.js`，不一致则是 nginx 镜像未重建 — #6
- API curl 正常但前端无变化 → 前端未重新构建部署（`build_web.sh` + `deploy.sh` 两步缺一不可）— #7

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

---
