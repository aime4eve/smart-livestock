# 从设备轨迹生成围栏草图 · 实施计划

> 依据：spec `docs/superpowers/specs/2026-11-11-fence-from-device-track-spec.md`（原型已确认，经子智能体评审修订：B1–B5 阻断已修、7 项建议已采纳）
> 执行准则：AGENTS.md「plan 确认后的执行准则」——子智能体串行按 Task 推进（**不并发**），每个 Task 先过本 plan 验证步骤，主智能体评审产物质量后再进下一 Task；全部完成后主智能体内建浏览器端到端验证，通过才部署 dev。
> 预估：准备 1 Task + 后端 2 Task + 前端 3 Task + 收口 1 Task
> plan 阶段裁决（spec 留白项 + plan 评审修订项）：
> ① 多设备取数=**串行**（上限 10 台 × 每台 2 条索引查询，远在 15s 预算内；并行引入 executor 生命周期/事务边界逃逸/CompletionException 异常聚合三类风险且无实测必要）。保留"并行与串行等价"测试作为将来启用并行的回归门；实测超 10s 需并行时：专用 bounded executor（上限 4，注册 shutdown）+ fan-out 在事务外 + CompletionException 解包映射回 VALIDATION_ERROR。（复核补遗：已核实 GPS 仓储实现层——`JpaGpsLogRepositoryImpl`/`SpringDataGpsLogRepository`——无 ThreadLocal 租户过滤、无 Hibernate `@Filter`，deviceId 直查，届时并行子线程无租户上下文传递负担。）
> ② `source` 过滤=**默认不排除 MANUAL_IMPORT**，与轨迹回放一致，验收若干扰再加白名单参数。
> ③ **配额预检数据源改道（spec §5.5 勘误，评审 B1）**：`GET /api/v1/subscription/usage` 经核实仅含 livestock 维度（livestockCount/livestockCap，无 fence 字段），且是 tenant 维度与 farm 维度配额不匹配——**不调该端点**；改由 candidates 接口响应附带 `fenceQuota {current, limit|null}`（后端信息齐全，见 Task 2），前端以此为唯一预检数据源。
> ④ **跨上下文访问走 ACL（评审 B3）**：ranch 访问 iot 唯一合法通道是 `IoTQueryPort` + `IoTQueryPortImpl`（GatewayDistanceController 先例在 iot 侧、方向相反，不可套用）；`FenceTrackDraftService` 只依赖端口，不直注 iot 仓储。
> 复核补遗（2026-11-12，评审意见 H1/M1/M2/L2 四项）：H1 补附录 A 双语文案表（spec §6「英文稿在 plan 阶段成表补全」交接义务，随本 plan 送用户确认后冻结）；M1 补 Task 3 既有 static const 引用点保护；M2 Task 1 改「新建 FenceMapperTest」（仓库现无此文件，非增补）；L2 既有 stride 下取整缺陷列入不做范围。

---

## Task 0：视觉保真准备

- 从原型 HTML（`docs/prototypes/2026-11-11-fence-from-device-track-prototype.html`）提取令牌映射表，**落独立文件** `docs/superpowers/fidelity/2026-11-11-fence-track-token-mapping.md`（**不写回已定稿 spec**，保持基线）：CSS `:root` 新增令牌 → Flutter 落点逐条（spec §2 已有结论：全部映射既有 `AppColors`，仅 3 处数值常量——虚线参数 `[5,3]`/`[8,4]`、透明度 0.35/0.14、面板宽 360）。
- 核对组件规格锚点：统计条/步骤指示器/设备行/日期框/空态 与原型逐屏对照，产出"组件-原型截图"对照清单（同文件附录）——**该清单即人工保真核对基线**：`prototype-to-flutter-fidelity` skill 在本会话技能目录不可用时，Task 4/5 按此清单人工核对 + 截图留证（评审 P1-6）。
- **验证**：映射表覆盖原型全部新增视觉元素；与 `AppColors/AppSpacing/AppTypography` 现有定义零冲突（grep 核对，不新增颜色常量）。

## Task 1：围栏生成元数据链路（后端）

- Flyway `V20261112100000__add_fence_generation_metadata.sql`：`ALTER TABLE fences ADD COLUMN generation_metadata jsonb NULL;`
- `FenceJpaEntity` 加字段，沿用 vertices 模式（`@Column(columnDefinition="jsonb")` + `@ColumnTransformer(write="?::jsonb")`，String 存储）。
- `Fence` 领域模型 + `generationMetadata`（String，可空）；`FenceMapper.toJpaEntity/updateEntity/toDomain` 三处同步。
- `CreateFenceCommand` record + `Map<String,Object> generationMetadata`（可空）；`FenceApplicationService.createFence` 构造链透传（ObjectMapper 序列化）。
- `FenceController.createFence` 解析 body 可选键 `generationMetadata`；`FenceDto` + 字段原样回显。
- **编辑保留语义**：`PUT /fences/{id}`（update/force）body 不传该键则列不变；`updateEntity` 不触碰 `generation_metadata`（已核实 `FenceMapper.updateEntity` 为白名单映射模式，保留语义天然成立，仍须测试锁住）。
- **写入范围显式化（评审 P2-11）**：仅 UI 创建链路（`FenceController.createFence`）携带元数据；`OpenFenceController` 只读无创建路径、建场边界围栏（`RanchCommandPortImpl`）、SQL seed 直插等链路列值均为 NULL——属预期，不补写。
- **验证**：
  - `./gradlew compileJava` 通过；
  - 单测：**新建 `FenceMapperTest`**（static 方法直测，仓库现无此文件，评审 M2 勘误——原「增补」表述会误导执行者去找不存在的文件）+ 增补 `FenceApplicationServiceTest`——创建带元数据往返、创建不带为 NULL、**编辑后元数据保留**（关键回归）；
  - CI 守护静态对账（§5b.4）：jsonb 列带 `columnDefinition`；迁移全新库跑通（本地无 Docker 则标记待 Task 6 远程通道验证，不得标通过）。

## Task 2：轨迹来源服务与端点（后端）

- **ACL 端口扩展（评审 B3）**：`ranch/domain/port/IoTQueryPort` 增加 `countTrackPoints(deviceId, from, to)` / `sampleTrackPoints(deviceId, from, to, stride)` / `findTrackerCandidates(farmId, days)`（签名以 ranch 侧 DTO 表达，不泄露 iot 类型）；`ranch/infrastructure/acl/IoTQueryPortImpl` 注入 iot `GpsLogRepository`/`DeviceRepository`/`InstallationRepository` 实现——ranch→iot 唯一合法通道。
- 新增 `FenceTrackDraftService`（ranch/application），**只依赖上述端口与 ranch 侧仓储**：
  - `candidates(farmId, days)`：本牧场 active installation（`removed_at IS NULL`）追踪器设备 → 每设备点数 + 最近定位时间；按 lastFixAt 倒序。
  - **响应附带 `fenceQuota {current, limit|null}`（评审 B1）**：current = 本牧场现有围栏计数（ranch 侧 `FenceRepository`）；limit 经既有配额解析链（FeatureGate `fence_management` LIMIT / license quota）取得，enterprise/none 返回 null 表示不限——前端预检唯一数据源。
  - `source(farmId, deviceIds, from, to)`：校验（1–10 台、归属本牧场、`device_type='TRACKER'`、跨度 ≤30 天、from<to；失败 **400 VALIDATION_ERROR**，消息键 `error.trackDraftRangeTooLong` / `error.trackDraftDeviceNotFound` / `error.trackDraftTooManyDevices`）→ 逐设备 count 求和 → `stride = ceil(totalRaw/5000)` → **串行** `sampleTrackPoints`（裁决①）→ 合并按 `recordedAt` 升序 → 组装 DTO（points/totalRaw/perDevice/truncated/sampledStride）。
  - `accuracy` null → DTO `accuracyM` 输出 null，由前端按 0（可信）处理（保持后端数据原样，不伪造精度）。
- `FenceController` +2 端点：`POST /track-draft/source`、`GET /track-draft/candidates?days=30`；`@PreAuthorize("hasAnyRole('OWNER','B2B_ADMIN')")` + `verifyFarmOwnership`。
- 新增 DTO 文件：`TrackDraftSourceDto.java`、`TrackDraftCandidateDto.java`。
- 后端 i18n：`messages_zh/en.properties` 双语 3 键（带点键合法）。
- **验证**：
  - 编译 + `FenceTrackDraftServiceTest`：stride 上取整（5499/5000→2 不返全量，对照既有下取整缺陷）、合并排序、三类校验失败、设备归属 400/403、fenceQuota 三态（有限额/enterprise null/满载）、**并行与串行等价**（裁决①回归门，串行实现下用等价测试钉住语义）；
  - ACL 方向检查：`FenceTrackDraftService` import 树不含 iot 包（grep 机械核对）；
  - `FenceController` 鉴权测试（OWNER 放行 / 非管理角色拒绝）；
  - properties 双语对齐检查（key 集合一致）。

## Task 3：包络管线扩展（前端纯函数）

- `lib/features/fence/domain/track_draft_params.dart`：`TrackDraftParams` 不可变参数组（动物轨迹组初值 `accuracyThresholdM=40, lMaxBaseM=40, roamingQuantile=0.95`；默认组 `roamingQuantile=null` 其余现值）。
- `lib/features/fence/domain/roaming_trim.dart`：`RoamingTrim.trim(points, quantile)` 纯函数——中位数中心 → 各点距离升序取前 95%（保原始时序返回 kept，trimmed 单独返回）。
- `TrackToEnvelopeConverter.convert` 加可选命名参数 `{TrackDraftParams? params}`；截断步骤仅 `params.roamingQuantile != null` 时执行；`TrackToEnvelopeResult` + `roamingTrimmed` + `trimmedPoints`（默认组恒 0/空）。
- **回归隔离（硬性）**：默认参数组输出与现状**逐位一致**。
- **验证**：
  - `roaming_trim_test.dart`：分位数边界、全等距点、恰 95% 截断、kept 保序、trimmed 为被裁集；
  - `track_to_envelope_converter_test.dart`：增补动物轨迹参数组用例（40m 阈值生效、截断计数正确、trimmedPoints 正确）+ **默认组既有断言原样通过（不改一个字）**；
  - **等价钉死（评审 P1-4）**：新增显式等价测试 `convert(raw) == convert(raw, params: TrackDraftParams.gpxDefault())`——顶点逐点相等，把"默认参数组 ≡ 不传参"钉死；
  - **既有引用点零改动（评审 M1）**：`accuracyThresholdM/speedOutlierMps/lMaxBaseM` static const 保留为默认参数组来源，**不删除、不改名**——`track_collect_page.dart:372` 直接引用 `TrackToEnvelopeConverter.accuracyThresholdM` 做 UI 精度警示（若删常量即编译错；若语义漂移则警示阈值与管线脱节）；`track_collect_page.dart:164` 与 `fence_track_import_dialog.dart:98` 的无参 `convert()` 零改动编译通过；
  - VM 与 dart2js 行为一致性用例保留（历史死循环教训，CI 规则 skip 约定遵守 §5b.5）。

## Task 4：向导与预览 UI（前端）

- `data/track_draft_repository.dart`：`candidates()`（farmGet）/ `source()`（farmPost）封装；`accuracyM` null→0 映射在此层完成；`fenceQuota` 解析透出。
- `presentation/track_draft_controller.dart`：`FarmScopedNotifier`，build 首行 `watchActiveFarmId()`；状态机四相位 `editing/loading/previewing/failed(reason)`（loading 保留旧预览+遮罩、「调整条件」保留已选条件——spec §5.4 全文落实，不仅引用）；参数改动标 stale。
- **配额预检（评审 B1 修订后）**：第 1 步随 candidates 响应读取 `fenceQuota`：已满（limit 非 null 且 current ≥ limit）则入口卡/首屏提示并禁用「下一步」；保存时 403 兜底不变（`fenceTrackDraftQuotaExceeded`）。
- **i18n 落地提前（评审 B2）**：本 Task 同步落地向导/预览所需 arb key（spec §6 中除 `fenceTrackDraftEntryTitle/EntryDesc/SourceCardTitle/Offline` 外的全部 key，中英双语同步）——gen-l10n 无 stub 机制，key 必须先入 arb 才能编译。
- `presentation/track_draft_wizard_page.dart`：移动端三步向导（复用 `ImportWizardShell`）；`track_draft_desktop_panel.dart`：≥900px 左 360px 面板 + 右地图单屏；widgets：device_picker / range_picker / preview（地图三层叠加 + 统计条 + 来源卡 + 失败态）。
- 面积换算（spec §5.6 + 附录 A 单位裁决扩展）：按 locale 分支封装在**单一换算函数**，禁止散落——中文 `亩`（`sqmPerMu = 2000/3`，1 位小数，<0.1 亩降级）、英文 `ha`（`sqmPerHa = 10000`，2 位小数——ha 表述惯例精度，<0.01 ha 降级）；降级统一显示原始 ㎡，文案用新增键 `fenceTrackDraftAreaSqmFallback`（附录 A #30）。
- **验证**：
  - Widget 测试：状态机全转移（editing→loading→previewing/failed、failed→editing 唯一回边、stale 标记）；设备行 stale 警示；超 30 天禁用；失败态三分支；配额满禁用；`DemoApp(overrides:)` + Key 查找（Key 清单按 spec §3）；**`ProviderContainer` 单测 override `initialSessionProvider` 提供有效 activeFarmId（Mobile/AGENTS.md 硬性要求）**；
  - **视觉保真验证**：对照 Task 0 产出的"组件-原型截图对照清单"逐屏人工核对 + 截图留证（移动端 5 屏 + Web 1 屏），重点核对统计条暗底、包络虚线、琥珀剔除点、空态版式（skill 可用时优先 `prototype-to-flutter-fidelity`）；
  - **禁用 setState**（spec §5.7），`flutter analyze` 零新增告警；
  - `flutter gen-l10n` 无缺失（本 Task arb 已落地，可真实通过）。

## Task 5：入口挂载与详情来源卡（前端）

- `fence_form_page.dart`：+第 5 入口卡（实地采集之下，**不按 kIsWeb 隐藏**；离线时置灰 + `fenceTrackDraftOffline` 提示）；`canManage=false` 隐藏入口（沿用 `RolePermission.canEditFence`，spec §4.1 权限说明）。
- **前端模型透传（评审 P0-2）**：`fence_item.dart` + `generationMetadata`（`Map<String,dynamic>?` 可空）、`fence_dto.dart` `fenceItemFromJson` 解析原样保留——来源卡两挂载点的数据源。
- 回传链路：向导确认 → `_applyCollectedVertices(vertices, defaultName:)`（fence_form_page.dart:486）→ 表单微调 → 保存。
- **保存链路改动点（评审 P0-3，明示）**：实际保存 body 组装在 `fence_form_page.dart` `_save()`（:534，body 于 :546-552 行内联组装后直连 `ApiClient.instance.farmPost/Put`，**不经 fence_api_repository/fence_controller**）——新增表单页状态字段持有向导回传的元数据（该页是 setState 历史债务区，新增状态克制为单一不可变字段），`_save` **新建分支** body 追加 `generationMetadata` 键；**编辑分支不加**（保留语义，widget 测试锁住）。
- 两处详情挂载点（经验 #25）：`fence_page.dart` `_FenceCard`（:1169）与 `ranch_fence_tab.dart` `_FenceDetailCard`（:961）+ "生成来源"卡（`generationMetadata==null` 隐藏）。
- **埋点（评审 P2-8）**：`fence_analytics.dart` 增补 3 事件——进入向导 / 生成成功（带点数与设备数）/ 载入围栏表单；风格与既有编辑埋点一致。
- i18n：本 Task 仅落地剩余 4 键（`fenceTrackDraftEntryTitle/EntryDesc/SourceCardTitle/Offline`，中英双语同步；其余 key 已在 Task 4 落地）。
- **验证**：
  - Widget 测试：入口可见性矩阵（web/mobile × canManage × offline）；来源卡两挂载点渲染与 NULL 隐藏；**编辑路径保存 body 不含 generationMetadata（保留语义锁）**；新建路径 body 含完整 metadata；
  - **视觉保真验证**：入口卡与既有 4 入口风格一致性、来源卡与详情卡视觉融合度（对照原型屏 1/4 + Task 0 清单）；
  - 可达性倒查：新增围栏页 → 入口 → 向导，双端各 ≤2 次点击（lessons #25）；
  - `flutter gen-l10n` 无缺失 + `flutter analyze` 通过。

## Task 6：收口（主智能体执行）

- **curl 冒烟**（lessons #25，部署 dev 后）：3 端点逐个带真实数据验证（200 且业务字段非空）：candidates、source、POST /fences 带 metadata → GET 回显。
- **迁移验证**：dev 存量库迁移成功 + `remote-integration-test.sh` 通道跑真库集成（新列读写往返）；**全新库跑通**（经验 #20）。
- **真机校准**（spec §9.1）：**先跑盘点 SQL**（按牧场/设备统计近 30 天 `gps_logs` 点数，排除 `DATAGEN` source）评估 dev 是否满足"≥2 牧场 ≥3 设备 ≥14 天"（注意 `DataRetentionService` 每日 purge 30 天前数据的滚动窗口——校准必须落在窗口内，评审 P2-9）→ 满足则校准参数组终值 → 4 条门槛核对 → 记录归档 `docs/superpowers/`；不满足则按既有兜底顺延（禁用 datagen 替代）。
- **API 契约归档（评审 P1-7）**：新增 2 端点 + `POST /fences` 扩展同步至 `docs/api-contracts/app-api.md` + changelog。
- **内建浏览器端到端**：种子账号登录 → Flutter Web 走完整链路（入口→选设备→选时间→预览→载入→编辑→保存→详情来源卡回显）→ 对照 spec §1.2 验收 8 条逐项核对 + 截图留证（lessons #25）。
- 部署 dev（`./scripts/deploy.sh dev`）→ 用户集成测试 → 提交 git + 合并 PR + 关闭工单。
- **CI**：push 前 `precheck-ci.sh`；push 后 `gh run list` 盯双流水线绿（§5b.3）。test 环境部署等用户通知。

---

## 依赖与风险

- **串行顺序不可乱**：Task 1（元数据列）是 **Task 5 保存链路**的前提（Task 2 两端点不依赖该列，评审 P2-10 修正）；Task 3（纯函数）是 Task 4 的算法前提；Task 4 完成后 Task 5 才能挂入口与回传。
- **Task 1 的"编辑保留"是关键回归点**：漏测会导致一次普通改名抹掉元数据（`updateEntity` 白名单模式天然保留，但必须测试锁住）。
- **Task 3 的回归隔离是硬性门禁**：默认参数组测试断言一个字符都不许改；GPX 导入路径逐位一致，由新增等价测试钉死。
- **真机校准依赖 dev 真实数据**：盘点 SQL 先行；数据不足则 Task 6 校准顺延但不得用 datagen 数据替代（AGENTS.md AI 仿真条款）；先用初值参数组完成端到端，校准记录后补。
- **预览 5000 点渲染**：Task 4 实测 Web 卡顿则显示层抽稀至 2000（不进管线），在 Task 4 验证步骤内闭环。
- **既有 stride 下取整缺陷不在本期修复范围（评审 L2）**：`GpsLogApplicationService.java:60` 的 `long stride = total / sampleSize` 下取整仅作 Task 2 验证对照引用，**不顺手修复**（防扩大回归面）；将来修复另立工单。
- **评审阻断项已全部转为 Task 验证步骤**（spec 评审 B1–B5 + plan 评审 B1–B3：B1→Task 2 fenceQuota/Task 4 预检改道、B2→Task 4 arb 提前、B3→Task 2 ACL 端口、P0-1→裁决①串行、P0-2/P0-3→Task 5 模型透传与 `_save` 改动点）。

---

## 附录 A：i18n 双语文案表（评审 H1 补遗，spec §6 交接义务落实）

> spec §6 仅有中文稿；本表随 plan 一并送用户确认，**确认后冻结**，Task 4/5 照表落地，不再临场自编英文。
> Key 分工：#1/#2/#19/#29（EntryTitle/EntryDesc/SourceCardTitle/Offline）在 Task 5 落地，其余在 Task 4 落地（评审 B2 分工不变）。
> 文案裁决（用户 2026-11-12，两项）：**① 面积单位国际化，按常规**——英文界面用公顷 `ha`（国际畜牧土地面积惯例），中文保留 `亩`；换算随 locale 分支（Task 4 面积换算行已扩写），spec §5.6 中文契约不变。**② #12 去掉百分数**——标签定「剔除漫游」/"Roaming trimmed"（数字照旧显示被剔点数；`roamingQuantile` 真机校准后无论怎么调，文案都不失真）。② 为对 spec §6/§3.4 该行的勘误，实施以本表为准，不改写 spec 文件（保持基线原则）。
> 勘误补记（主智能体 2026-11-12，随 Task 4/5 评审落账）：**#19 拆两键**——详情卡（已保存围栏）显示短标题「生成来源」/"Generation source"（再标"将随保存"反而错误）；向导预览/桌面面板用追加键 #19b 保留「（将随围栏保存）」语境。这是评审确认的合理语义修正，arb 以拆分后为准。

| # | Key | 中文 | English |
|---|---|---|---|
| 1 | `fenceTrackDraftEntryTitle` | 从设备轨迹生成 | From device tracks |
| 2 | `fenceTrackDraftEntryDesc` | 选追踪器 + 时间段，按动物实际活动范围自动画草图 | Pick trackers and a time range; the draft is drawn from the animals' actual grazing range |
| 3 | `fenceTrackDraftStepDevice` | 选设备 | Select devices |
| 4 | `fenceTrackDraftStepRange` | 选时间 | Select time range |
| 5 | `fenceTrackDraftStepPreview` | 预览 | Preview |
| 6 | `fenceTrackDraftSelectedSummary` | 已选 {n} 台 · 预估合并 {m} 点 | {n} devices selected · est. {m} points |
| 7 | `fenceTrackDraftStaleFix` | ⚠ {n} 天前定位 | ⚠ Last fix {n}d ago |
| 8 | `fenceTrackDraftRangeHint` | 时间范围最长 30 天。时间越长活动范围越发散，建议用最近一次完整放牧周期。 | Time range is capped at 30 days. Longer ranges make the range more diffuse — prefer the most recent complete grazing cycle. |
| 9 | `fenceTrackDraftRangeTooLong` | 范围超限，请缩短至 30 天内 | Range too long — shorten it to 30 days or less |
| 10 | `fenceTrackDraftSameLotHint` | 建议选同一放牧场次的设备；跨场次合并会把两个区域包进同一个围栏。 | Pick trackers from the same grazing session; merging sessions may wrap two separate areas into one fence. |
| 11 | `fenceTrackDraftStatValid` | 有效点 | Valid points |
| 12 | `fenceTrackDraftStatTrimmed` | 剔除漫游 | Roaming trimmed |
| 13 | `fenceTrackDraftStatVertices` | 包络顶点 | Envelope vertices |
| 14 | `fenceTrackDraftStatArea` | 面积(亩) | Area (ha) |
| 15 | `fenceTrackDraftStatHull` | 生成方式 | Method |
| 16 | `fenceTrackDraftLegendEnvelope` | 包络草图（未确认） | Draft envelope (unconfirmed) |
| 17 | `fenceTrackDraftLegendTrackDots` | 有效轨迹点 | Valid track points |
| 18 | `fenceTrackDraftLegendTrimmed` | 已剔除漫游点 ×{n} | Trimmed roaming points ×{n} |
| 19 | `fenceTrackDraftSourceCardTitle` | 生成来源 | Generation source |
| 19b | `fenceTrackDraftPreviewSourceTitle`（实现追加键：向导预览/桌面面板用） | 生成来源（将随围栏保存） | Source (saved with the fence) |
| 20 | `fenceTrackDraftConfirm` | 载入围栏表单 | Load into fence form |
| 21 | `fenceTrackDraftAdjust` | 调整条件 | Adjust conditions |
| 22 | `fenceTrackDraftGenerate` | 生成预览 | Generate preview |
| 23 | `fenceTrackDraftStaleNotice` | 条件已变更，请重新生成 | Conditions changed — please regenerate |
| 24 | `fenceTrackDraftFailNoData` | 该时间段无轨迹数据 | No track data in this time range |
| 25 | `fenceTrackDraftFailTooFew` | 有效轨迹点不足（需 ≥3 个且面积 ≥25㎡） | Too few valid track points (need ≥3 points and an area ≥25 ㎡) |
| 26 | `fenceTrackDraftFailDegenerate` | 活动范围近似一条线，无法围合成围栏 | The activity range is nearly a line and cannot form a fence |
| 27 | `fenceTrackDraftFailSuggests` | 建议：① 延长时间范围 ② 增选同场次追踪器 ③ 检查设备是否长期离线 | Suggestions: ① extend the time range ② add trackers from the same session ③ check for long-offline devices |
| 28 | `fenceTrackDraftQuotaExceeded` | 围栏数量已达套餐上限，请升级套餐或删除闲置围栏 | Fence quota reached — upgrade the plan or remove idle fences |
| 29 | `fenceTrackDraftOffline` | 当前离线，生成围栏草图需要网络连接 | You are offline — generating a fence draft requires a network connection |
| 30 | `fenceTrackDraftAreaSqmFallback` | 约 {n} ㎡ | ~{n} ㎡ |

> 实现中如发现 spec §3 组件规格尚有未入表的小键（时间档 chips「近 7/14/30 天」、日期框「起/止」标签、设备行「30 天点数」列标题、凹包/凸包取值、Web「‹ 返回表单」），**双语同步追加**并在该 Task 验证步骤列出追加清单，不得只落中文。
