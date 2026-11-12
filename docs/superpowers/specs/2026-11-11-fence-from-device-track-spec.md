# 从设备轨迹生成围栏草图 · Spec（需求确认稿 v2）

> 原型：`docs/prototypes/2026-11-11-fence-from-device-track-prototype.html`（已确认）
> 需求确认：2026-11-11 两轮裁决（多设备多选 / 30 天上限 / 95% 距离分位数剔除 / 参数放宽真机校准 / 第 5 入口 / 包络+轨迹叠加预览 / 记录生成元数据 / 权限同现有 / **双端覆盖含 Flutter Web**）
> 硬性规则：本 spec 未经用户批准不进入编码；涉 `fences` 表 Flyway 迁移与 `shared/` 无改动。

## 1. 需求与验收标准

### 1.1 需求

新增围栏流程增加第 5 种生成方式「从设备轨迹生成」：多选动物追踪器 + 时间范围（≤30 天）→ 后端拉取 `gps_logs` 历史轨迹并抽稀 → 客户端包络管线（95% 漫游剔除前置）生成围栏草图 → 预览（包络 + 轨迹叠加 + 统计）→ 载入围栏表单微调 → 保存（顶点 + 生成元数据）。移动端与 Flutter Web 双端可用。

### 1.2 验收标准

1. 双端新增围栏页均出现第 5 个入口；`canManage=false` 时入口不显示。
2. 选 1–N 台设备 + ≤30 天范围，典型数据（2 台 ×14 天 ≈ 7,500 点）10 秒内出预览。
3. 预览含：凹包草图（虚线=未确认）、半透明轨迹点叠加、琥珀色被剔除漫游点、统计条（有效点/漫游剔除/顶点/面积）、生成来源卡。
4. 载入表单后顶点可继续编辑；保存走现有 `POST /fences`（配额、乐观锁、告警判定零改动），`generation_metadata` 落库可查。
5. 失败路径（无轨迹 / 有效点<3 / 面积<25㎡ / 超 30 天）各有明确双语提示与可操作建议，唯一出口"返回调整条件"。
6. Web 宽屏为"左参数面板 + 右实时地图"单屏布局；移动端为三步向导。
7. i18n 双语齐全（`flutter gen-l10n` 无缺失）；Controller 走 `FarmScoped*` 基类，牧场切换自动刷新。
8. 设备多选上限 10 台、时间上限 30 天由后端硬校验（前端仅提示，不信任前端）。

## 2. 设计令牌表（确认后锁定）

### 2.1 新增令牌（7 个）

| Token | 值 | 用途 | Flutter 落点 |
|---|---|---|---|
| `track.dot` | `#4A7F9D` @35% | 预览轨迹点叠加 | 复用 `AppColors.info.withValues(alpha:.35)` |
| `envelope.fill` | `rgba(76,154,95,.14)` | 草图多边形填充 | `AppColors.success.withValues(alpha:.14)` |
| `envelope.stroke` | `#2F6B3B` | 草图边线 | `AppColors.primary` |
| `envelope.dash` | `[5,3]` 移动 / `[8,4]` Web | 草图虚线（确认载入后实线） | CustomPaint dash 参数 |
| `chip.selected.bg` | `#2F6B3B` | 时间快捷档/设备选中态 | `AppColors.primary` |
| `stat.strip.bg` | `#263126` | 预览统计条暗色底 | `AppColors.textPrimary`（同值复用，不新建色） |
| `wizard.panel.width` | 360px | Web 左侧参数面板宽 | `LayoutBuilder` 断点 ≥900px 启用宽屏布局 |

### 2.2 继承令牌（NIX-246 基线，不重复定义）

颜色 `--primary/primary-soft/surface/border/text-*/success/warning/danger/info`、间距 `--xs..xl`、圆角 `--radius-sm/md/lg`、阴影 `--shadow-card/elev/sheet`、步骤指示器灰 `--step-indicator-inactive = --border`。

**映射检查结论：全部新令牌可映射到现有 `AppColors`，不新增颜色常量**；新增的只有虚线参数、透明度、面板宽度三处数值常量（随组件定义）。

## 3. 组件视觉规格

### 3.1 入口卡（屏 1）

- 位置：新增围栏页"快速开始"区，实地采集卡之下；**不按 `kIsWeb` 隐藏**。
- 结构：`entry-card` = 图标(34×34 `primary-soft` 圆角 10) + 标题(11.5/800) + NEW 标签(primary 底) + 副标(9/text-secondary，2 行) + chevron。
- 选中边框 1.5px `primary`（与原型一致），Key：`fence-form-track-draft-entry`。

### 3.2 设备多选列表（屏 2 / Web 面板①）

- 行结构：checkbox(18 圆角6，选中 `chip.selected.bg` ✓) + 📡 + 名称(10.5/700) + 副标(耳标 · 最近定位相对时间) + 右侧 30 天点数(b 11/primary-dark + "30 天点数" 8)。
- 状态：选中 = `primary-soft` 底 + `primary` 边；最近定位 >24h = 副标内 `⚠ {n} 天前定位` 琥珀加粗 + 整行 65% 透明（仍可选）。
- 底部常驻：`已选 {n} 台 · 预估合并 {m} 点`（9.5/text-secondary，数字 primary-dark 加粗）。
- 数据源：§4.2 候选接口；列表按最近定位时间倒序。
- Key：`track-draft-device-row-{deviceId}`、`track-draft-device-next`。

### 3.3 时间选择（屏 3 / Web 面板②）

- 快捷档 chips（近 7/14/30 天，选中实底）+ 自定义起止 `date-box`（8.5 标签 + 11/700 值）。
- 硬上限 30 天：超限时起止框 `danger` 边 + 琥珀提示条替换信息提示条 + 禁用主按钮（`btn.disabled`）。
- 已选设备摘要卡（`meta-card`）：设备清单 + 预估点数/抽稀说明。
- Key：`track-draft-range-chip-{7|14|30}`、`track-draft-range-start/end`、`track-draft-generate`。

### 3.4 预览（屏 4 / Web 地图区）

- 地图三要素叠加顺序：轨迹点(`track.dot`，r2/r3) → 漫游剔除点(warning 色 r2.5/r4) → 包络草图(fill + 虚线 stroke + 顶点 r3/r5 primary 实点)。
- 图例行：草图色块 / 有效轨迹点 / 已剔除漫游点 ×{n}。
- 统计条 `stat-strip`（暗底白字，cell 间 1px 12% 白分隔）：有效点 / 剔除漫游 5%（琥珀值）/ 包络顶点 / 面积(亩)；Web 端加第 5 格"生成方式（凹包/凸包）"。
- 生成来源卡：设备、时间段；文案注明"将随围栏保存"。
- 操作：移动端「‹ 调整条件 / 载入围栏表单 ✓」；Web「‹ 返回表单 / 载入围栏表单 ✓」浮于地图右上。
- 顶点回传与坐标转换复用 `_applyCollectedVertices(List<LatLng>, {String? defaultName})`（`fence_form_page.dart:486`，GPX 导入与实地采集共用），WGS-84→GCJ-02 与默认名回传零改动。
- Key：`track-draft-preview-map`、`track-draft-stat-strip`、`track-draft-confirm`。

### 3.5 失败态（屏 5）

- 共用空态：图标(52 圆角16 warning 底) + 标题(12.5/800) + 原因(9.5) + 建议列表卡（① 延长时间 ② 增选设备 ③ 检查离线设备）。
- 保留清洗明细统计条（原始点/精度超限剔除/漫游剔除/剩余有效），让失败可诊断。
- 三类失败文案见 §6 i18n 表。

## 4. 后端契约

### 4.1 新增：轨迹来源拉取（向导第 3 步 / Web 生成预览）

```
POST /api/v1/farms/{farmId}/fences/track-draft/source
@PreAuthorize("hasAnyRole('OWNER','B2B_ADMIN')")
Body: { "deviceIds": [101,102], "startTime": "2026-10-29T00:00:00+08:00", "endTime": "2026-11-11T23:59:59+08:00" }
200: {
  "points": [{"lat":28.1,"lng":112.9,"accuracyM":8.5,"recordedAt":"..."} ...],  // 合并+抽稀 ≤5000
  "totalRaw": 16088, "perDevice": [{"deviceId":101,"raw":7986}],
  "truncated": true,   // 触发抽稀
  "sampledStride": 4
}
```

- 校验：`deviceIds` 1–10 个且都属于本牧场、设备类型为追踪器（`device_type = 'TRACKER'`，与 `V3__create_iot_tables.sql` CHECK 约束一致，实现时以安装关系为准）；时间跨度 ≤30 天（硬校验）；`endTime > startTime`。校验失败返回 **400 `VALIDATION_ERROR`**，消息键 `error.trackDraftRangeTooLong`——沿用 `GlobalExceptionHandler` 现有映射（VALIDATION_ERROR→400），**不新增 422**。
- 取数：**（勘误：经 ACL 端口调用，见 §4.2 下）** ranch 不直注 iot 仓储，轨迹 count/sample 经 `IoTQueryPort` 扩展方法（`countTrackPoints`/`sampleTrackPoints`）访问 `GpsLogRepository.sampleByDeviceIdAndTimeRange`（stride 语义 = ROW_NUMBER 升序每 stride 取 1，见 `SpringDataGpsLogRepository.sampleIdsByDeviceIdAndTimeRange`）；stride 按 `totalRaw/5000` 上取整估算（先 count 后采样，count 走 `(device_id, recorded_at)` 索引开销可忽略）；多设备**串行**取数（plan 裁决①：10 台 × 2 条索引查询远在 15s 预算内，规避 executor 生命周期/事务边界/异常聚合风险；实测超时再按 plan 预案开并行），合并后按 `recordedAt` 升序。10 台 ×30 天目标 ≤15s。
- `accuracyM` 为 null（`gps_logs.accuracy` 可空）时前端按 0（可信）处理，与 `TrackPoint.accuracyMeters` 缺省语义一致。
- **无包络计算**：与 NIX-213 一致，包络管线留在客户端纯函数，后端只供数据。
- `source` 过滤：只取合法来源（排除压测 `MANUAL_IMPORT` 数据？→ plan 阶段定：默认不排除，与轨迹回放一致；验收阶段若压测数据干扰再加 `source` 白名单参数）。
- 权限说明：沿用后端现有围栏写权限 `OWNER/B2B_ADMIN`；前端入口可见性沿用 `RolePermission.canEditFence`（owner-only）——**两者存在既有不一致（B2B_ADMIN 后端放行但前端无入口），属历史现状，本期不对齐、不作为 bug**。

### 4.2 新增：候选设备清单（向导第 1 步）

```
GET /api/v1/farms/{farmId}/fences/track-draft/candidates?days=30
200: { "devices": [{"deviceId":101,"name":"追踪器 A-012","earTag":"N0342",
       "lastFixAt":"...","pointCount":7986}, ...],
     "fenceQuota": {"current": 3, "limit": 20} }
```

- 范围：本牧场当前有活动安装（active installation，`removed_at IS NULL`）的追踪器设备；`pointCount` = 近 `days` 天 `countByDeviceIdAndRecordedAtBetween`；`lastFixAt` 取设备安装最新 `recorded_at`。
- **`fenceQuota`（勘误：plan 评审 B1 补）**：`current` = 本牧场现有围栏数；`limit` = 经 FeatureGate `fence_management`/license quota 解析的上限，enterprise/不限 返回 `null`——前端配额预检唯一数据源（§5.5）。
- **跨上下文通道（勘误：plan 评审 B3）**：ranch 访问 iot 走 `ranch/domain/port/IoTQueryPort` + `ranch/infrastructure/acl/IoTQueryPortImpl`（ranch→iot 唯一合法通道；iot 侧 `GatewayDistanceController` 的 `RanchQueryPort` 先例方向相反，不可套用）。端口新增 `findTrackerCandidates(farmId, days)`。
- 列表按 `lastFixAt` 倒序；空列表前端显示空态。

### 4.3 扩展：围栏保存携带生成元数据

```
POST /api/v1/farms/{farmId}/fences
Body 增加可选字段:
  "generationMetadata": {
    "method": "DEVICE_TRACK",
    "deviceIds": [101,102],
    "startTime": "...", "endTime": "...",
    "rawPointCount": 16088, "usedPoints": 7412,
    "outlierTrimmed": 371, "hullMethod": "concave"
  }
```

- `FenceDto` 增加 `generationMetadata`（JSON 原样回显，详情页"生成来源"卡数据源）。
- `CreateFenceCommand` record 增加 `Map<String,Object> generationMetadata`（可空）。
- **`Fence` 领域模型增加 `generationMetadata`（String，可空）**：`FenceDto.from(Fence)` 从领域对象取值，`FenceMapper.toJpaEntity / updateEntity / toDomain` 三处同步映射，`FenceApplicationService.createFence` 构造链透传。
- **编辑路径语义**：`PUT /fences/{id}` 普通编辑（改名/调顶点/开关）**保留**既有元数据——body 不传 `generationMetadata` 则不改动该列；元数据仅在创建时写入，不提供更新入口。
- 配额 `@QuotaCheck(fence_management)`、乐观锁、越界判定链路零改动。

### 4.4 Flyway 迁移

`V20261112100000__add_fence_generation_metadata.sql`：

```sql
ALTER TABLE fences ADD COLUMN generation_metadata jsonb NULL;
```

- `FenceJpaEntity` 新增字段，**沿用 vertices 的既有模式**：
  `@Column(name="generation_metadata", columnDefinition="jsonb")` + `@ColumnTransformer(write="?::jsonb")`，Java 侧 `String`（ObjectMapper 序列化）。
- 兼容：旧行 NULL；`FenceDto` 回显 NULL 时前端隐藏"生成来源"卡。
- CI 守护对账：jsonb 列必须带 `columnDefinition="jsonb"`（协议 §5b.4）；全新库 + 存量库双验证（经验 #20）。

## 5. 前端结构

### 5.1 新增文件

```
lib/features/fence/
  data/track_draft_repository.dart          # 4.1/4.2 两接口封装（farmGet/farmPost）
  domain/track_draft_params.dart            # 动物轨迹参数组（见 5.2）
  domain/roaming_trim.dart                  # 95% 距离分位数截断纯函数
  presentation/track_draft_controller.dart  # FarmScopedNotifier；步骤状态机
  presentation/track_draft_wizard_page.dart # 移动端三步向导（复用 ImportWizardShell）
  presentation/track_draft_desktop_panel.dart # Web 左面板 + 右地图单屏
  presentation/widgets/track_draft_device_picker.dart
  presentation/widgets/track_draft_range_picker.dart
  presentation/widgets/track_draft_preview.dart   # 地图叠加 + 统计条 + 来源卡
```

### 5.2 包络管线扩展（不动现有 RTK 参数与 GPX 行为）

- `TrackToEnvelopeConverter.convert(raw, {TrackDraftParams? params})` 增加可选参数组覆盖：动物轨迹组初值 `accuracyThresholdM=40`、`lMaxBaseM=40`、`speedOutlierMps=10` 不变（牛不可能 36km/h）、其余继承。**真机校准后只允许改参数组值，不改管线结构**。
- 前置步骤 `RoamingTrim.trim(points, quantile: 0.95)`：算各点到点集中心（中位数经纬）距离 → 距离升序取前 95% → 返回 `{kept, trimmed}`（trimmed 供预览琥珀显示）。在精度过滤**之后**、MAD 清洗**之前**执行；被裁点单独计数。
- **回归隔离（硬性）**：RoamingTrim 仅在动物轨迹参数组下生效——以参数组字段 `roamingQuantile`（动物轨迹组 = 0.95）控制，**GPX/RTK 默认参数组 `roamingQuantile=null`，此时管线输出与现状逐位一致**，既有 `track_to_envelope_converter_test` 基线不动。
- `TrackToEnvelopeResult` 扩展：`roamingTrimmed`（int，截断计数）与 `trimmedPoints`（List，仅预览琥珀叠加用，不进包络）；默认参数组下恒为 0 / 空。
- 顺序：精度过滤 → 速度离群 → 95% 漫游截断（仅动物轨迹组）→ MAD 清洗 → 投影 → 凹包/凸包 → DP 抽稀（≤100 顶点）。
- 已知算法边界（告知用户、验收观察项）：① **两片草场+转场路径**——走廊点可能落在 95% 内且抬高 MAD 阈值，围栏会把走廊包进来；"同场次提示条"是唯一防线，用户需在表单手修（狭长连接检测列入不做范围）；② L 形场地短臂末端真实点可能被裁，预览琥珀点供人工判断。

### 5.3 响应式断点

- `LayoutBuilder` ≥900px 用桌面面板布局（左 360px 面板 + 右地图），<900px 用三步向导页；两形态共享同一 `trackDraftControllerProvider` 状态机（selectedDeviceIds / range / result / phase）。

### 5.4 向导状态机

- phase 枚举：`editing / loading / previewing / failed(FailReason)`。
- `loading`：保留旧预览 + 半透明遮罩 + 生成中条（Web/移动端一致），按钮禁用。
- 参数（设备/时间）任何改动使 `previewing` 结果标 **stale**：Web 不自动重算，地图区显示"条件已变更，请重新生成"角标，必须手动点「生成预览」。
- `failed`：保留清洗明细统计条与可操作建议，唯一回边 → `editing`。
- 「调整条件」（移动端）= `previewing → editing`，**保留已选设备与时间**，用户增量修改后重新生成。

### 5.5 配额预检

- **（勘误 2026-11-11 plan 评审 B1）** `GET /api/v1/subscription/usage` 经核实仅含 livestock 维度字段、无围栏用量，且为 tenant 维度（围栏配额是 farm 维度）——**不调该端点**。
- 改为：候选设备接口（§4.2）响应附带本牧场围栏配额 `fenceQuota {current, limit|null}`（current=本牧场现有围栏数，limit 经 FeatureGate `fence_management`/license quota 解析，enterprise 返回 null 表示不限）；前端以此为**唯一预检数据源**。
- 向导第 1 步：已满（limit 非 null 且 current ≥ limit）则入口卡/首屏提示并禁用「下一步」，避免用户走完三步才在保存时被 403。
- 兜底：保存时仍可能 403（并发占用），`fenceTrackDraftQuotaExceeded` 双语提示走既有异常处理。

### 5.6 面积换算契约

- 统计条"面积(亩)"换算在**客户端**做：`1 亩 = 2000/3 ㎡ ≈ 666.67㎡`（新增常量 `sqmPerMu`），保留 1 位小数；<0.1 亩降级显示"约 {n} ㎡"。

### 5.7 牧场切换

- `TrackDraftController extends FarmScopedNotifier`，`build()` 首行 `watchActiveFarmId()`；候选设备列表随牧场切换重建。
- **新代码禁用 `setState`，一律 Riverpod Notifier**；`fence_form_page.dart` 既有 `setState` 属历史债务，本期不还、不效仿。

## 6. i18n 文案表（中文稿｜英文稿在 plan 阶段成表补全）

> Key 必须是合法 Dart 标识符：扁平 camelCase、**不含点**（ARB 约束；现有约定如 `fenceTrackMode`）。下表为完整 Key 全名。

| Key | 中文稿 |
|---|---|
| `fenceTrackDraftEntryTitle` / `fenceTrackDraftEntryDesc` | 从设备轨迹生成 ｜ 选追踪器 + 时间段，按动物实际活动范围自动画草图 |
| `fenceTrackDraftStepDevice` `fenceTrackDraftStepRange` `fenceTrackDraftStepPreview` | 选设备 ｜ 选时间 ｜ 预览 |
| `fenceTrackDraftSelectedSummary` | 已选 {n} 台 · 预估合并 {m} 点 |
| `fenceTrackDraftStaleFix` | ⚠ {n} 天前定位 |
| `fenceTrackDraftRangeHint` | 时间范围最长 30 天。时间越长活动范围越发散，建议用最近一次完整放牧周期。 |
| `fenceTrackDraftRangeTooLong` | 范围超限，请缩短至 30 天内 |
| `fenceTrackDraftSameLotHint` | 建议选同一放牧场次的设备；跨场次合并会把两个区域包进同一个围栏。 |
| `fenceTrackDraftStatValid` `fenceTrackDraftStatTrimmed` `fenceTrackDraftStatVertices` `fenceTrackDraftStatArea` `fenceTrackDraftStatHull` | 有效点 ｜ 剔除漫游 5% ｜ 包络顶点 ｜ 面积(亩) ｜ 生成方式 |
| `fenceTrackDraftLegendEnvelope` `fenceTrackDraftLegendTrackDots` `fenceTrackDraftLegendTrimmed` | 包络草图（未确认）｜ 有效轨迹点 ｜ 已剔除漫游点 ×{n} |
| `fenceTrackDraftSourceCardTitle` | 生成来源（将随围栏保存） |
| `fenceTrackDraftConfirm` `fenceTrackDraftAdjust` `fenceTrackDraftGenerate` | 载入围栏表单 ｜ 调整条件 ｜ 生成预览 |
| `fenceTrackDraftStaleNotice` | 条件已变更，请重新生成 |
| `fenceTrackDraftFailNoData` `fenceTrackDraftFailTooFew` `fenceTrackDraftFailDegenerate` | 该时间段无轨迹数据 ｜ 有效轨迹点不足（需 ≥3 个且面积 ≥25㎡）｜ 活动范围近似一条线，无法围合成围栏 |
| `fenceTrackDraftFailSuggests` | 建议：① 延长时间范围 ② 增选同场次追踪器 ③ 检查设备是否长期离线 |
| `fenceTrackDraftQuotaExceeded` | 围栏数量已达套餐上限，请升级套餐或删除闲置围栏 |
| `fenceTrackDraftOffline` | 当前离线，生成围栏草图需要网络连接 |

后端 properties（`messages_zh/en.properties`，带点键合法）：`error.trackDraftRangeTooLong`（400）、`error.trackDraftDeviceNotFound`（400/403 按归属判定）、`error.trackDraftTooManyDevices`（400）。

## 7. 调用链 / 改动文件汇总

```
[UI 入口] fence_form_page.dart（+第 5 入口，Web 不隐藏）
   → track_draft_wizard_page / desktop_panel（新）
   → track_draft_controller（新，FarmScopedNotifier）
   → track_draft_repository（新，farmGet/farmPost）
   → 后端 FenceController: +POST /track-draft/source、+GET /track-draft/candidates、POST /fences 扩展 generationMetadata
   → FenceTrackDraftService（新，ranch/application）→ GpsLogRepository（既有，零改动）
   → 客户端 RoamingTrim → TrackToEnvelopeConverter（参数组扩展）→ 顶点回传 fence_form_page
   → POST /fences（generation_metadata 落库，FenceJpaEntity + Flyway V20261112100000）
```

**改动文件清单**（新增 10 + 修改 8）：

| 类型 | 文件 |
|---|---|
| 修改（后端） | `FenceController.java`（+2 端点 +body 字段）、`CreateFenceCommand.java`（+字段）、`FenceDto.java`（+字段）、`Fence.java`（领域模型 +generationMetadata）、`FenceJpaEntity.java`（+列）、`FenceMapper.java`（toJpaEntity/updateEntity/toDomain 三处映射） |
| 修改（前端） | `fence_form_page.dart`（+第 5 入口 + `_save` 新建分支带 metadata）、`fence_page.dart`（`_FenceCard` +来源卡挂载点）、`ranch_fence_tab.dart`（`_FenceDetailCard` +来源卡挂载点）、`fence_item.dart`（+generationMetadata 字段，勘误：plan 评审 P0-2 补）、`fence_dto.dart`（fenceItemFromJson 解析透传，同勘误） |
| 修改（跨上下文） | `IoTQueryPort.java`（+3 轨迹查询方法，勘误：plan 评审 B3 补）、`IoTQueryPortImpl.java`（实现，同勘误） |
| 新增（后端） | `FenceTrackDraftService.java`、`TrackDraftSourceDto.java`、`TrackDraftCandidateDto.java`、迁移 SQL ×1 |
| 新增（前端） | §5.1 列出的 9 个文件 |
| i18n | `app_zh.arb` / `app_en.arb` + 后端 `messages_zh/en.properties`（400 错误键 ×3） |

> 详情页挂载点说明：本项目无独立围栏详情路由，"详情"UI 有两处——牧场页 `_FenceDetailCard`（`ranch_fence_tab.dart:961`）与围栏管理页 `_FenceCard`（`fence_page.dart:1169`），**两处都要挂"生成来源"卡**（经验判据 #25）。

## 8. 边界 · 安全 · 性能 · 兼容风险

| 类别 | 风险 | 对策 |
|---|---|---|
| 边界 | 设备跨牧场/已解绑 | 候选接口只出本牧场 active installation；source 接口逐设备校验 farm 归属，不符即 403 |
| 边界 | 多设备时空重叠（合群放牧） | 产品语义即合并包络；提示条已引导"同场次" |
| 安全 | deviceIds 注入/越权 | 服务端校验归属 + `@PreAuthorize` + `verifyFarmOwnership`；JSONB 写入走参数化 `@ColumnTransformer`（既有模式） |
| 性能 | 4 台 ×30 天 ≈ 3.4 万点 | 先 count 后 stride 采样，传输 ≤5000 点（复用 NIX-213 上限）；目标 10s 内 |
| 性能 | 预览地图 5000 点渲染 | 抽稀后 Web Canvas 可承载；实测卡顿则预览层再抽稀至 2000 点（仅显示层，不进管线） |
| 兼容 | 旧围栏无元数据 | NULL 兼容，详情页隐藏来源卡；`FenceDto` 字段可空 |
| 兼容 | Flyway 新旧库 | 全新库 + 存量库双跑（经验 #20）；不动既有迁移 |
| 算法 | 放宽阈值后误包 | 真机数据校准参数组；预览可视化 + 人工确认兜底 |
| 算法 | 95% 截断误伤 L 形场地 | 截断在 MAD 之前、以点集中心为基准；凹包保留凹角；预览显示被裁点供人工判断 |
| 兼容 | 离线场景 | 本功能依赖服务端历史轨迹、本质上必须在线：离线时第 5 入口置灰并提示（`fenceTrackDraftOffline`）；保存失败走既有离线兜底，**不进 `offline_fences` 队列** |

## 9. 测试方案

1. **纯函数单测**（镜像结构）：`roaming_trim_test`（分位数边界、全等距点、95% 恰好截断）；`track_to_envelope_converter_test` 增补动物轨迹参数组用例（40m 阈值、含时间戳速度剔除）。
2. **后端单测**：`FenceTrackDraftServiceTest`（stride 估算、合并排序、上限校验、设备归属校验）；`FenceController` 端点鉴权测试。
3. **真库集成测试**（Testcontainers，`remote-integration-test.sh` 通道）：迁移后 `fences` 表新列读写往返；fixture 遵守 CHECK 约束对账。
4. **Widget 测试**：入口可见性（含 `canManage=false` 隐藏）；三步向导状态机；超 30 天禁用；失败态三分支；`DemoApp(overrides:)` + Key 查找。
5. **端到端**（部署 dev 后）：种子账号登录 → 双端走完整链路 → curl 冒烟 3 个端点（200 且字段非空）→ 详情页来源卡回显 → 保存后围栏编辑/告警链路回归。
6. **CI**：`./scripts/precheck-ci.sh` + 涉迁移加跑 `./scripts/remote-integration-test.sh`；push 后盯双流水线绿。

### 9.1 真机校准（参数组验收门槛）

- **校准数据**：取 ≥2 个真实牧场、≥3 台在册追踪器、≥14 天连续数据（dev 环境真实采集，**禁用 datagen 合成数据充当校准依据**）。
- **验收门槛**：参数组校准后——① 包络面积与人工勾绘参考偏差 ≤15%；② DP 后顶点 ≤100；③ 同输入在 VM 与 dart2js（Web）下输出一致（历史死循环教训）；④ 95% 截断被裁点不含连续成片的真实活动段（人工目检预览）。
- **校准记录**：参数组终值 + 对比截图归档 `docs/superpowers/`，作为 spec §5.2 初值（40/40）的修订依据。

## 10. 不做范围（本期）

按牛群/羊群整群选择；密度聚类剔除；"重新生成/刷新围栏"；告警判定逻辑改动；`PC/` 归档目录；包络算法后端化。

---

## 修订记录 v2.1（2026-11-12，用户裁决：预览提供三种包络算法候选）

> 本节为文末追加补丁，不改动已确认正文。正文与本节冲突处以本节为准。

### 多候选机制

- 预览提供**三种包络算法候选**，共用同一份清洗后的点集（清洗段只跑一次，漫游/精度/速度/MAD 清洗统计三候选一致，不重复计算）：
  1. **凹包·简化**（`concave_simplified`）：凹包收紧 + DP 抽稀 + 外轮廓面积贡献精简（固定初始环面积为基准，迭代删除 ΔArea < 0.5% 的顶点）；
  2. **凹包·精细**（`concave`）：现状路径（凹包收紧 + DP 抽稀）；
  3. **凸包**（`convex`）：凸包 + DP 抽稀。
- 候选固定顺序 `[concaveSimplified, concave, convex]`；各候选独立 DP 抽稀与失败判定（顶点 <3 或面积 <25㎡ → 该候选标 failure，不抛）。
- **默认选中「凹包·简化」**；选中序为第一个可用候选（concaveSimplified → concave → convex）；全部不可用走既有失败分支（文案逻辑沿用，清洗统计填失败明细条）。
- 预览界面（移动 + 桌面双端）统计条上方提供算法切换 chips：选中=实底 primary 白字、未选=白底 border 边 textSecondary 字、不可用=置灰禁用（border 色底）。**切换不重算、不触网、不改 stale 标记**，仅替换预览展示（轨迹点层三候选一致）。

### metadata 契约变更

- `generationMetadata.hullMethod` 由两值扩为三值：`concave` / `convex` / `concave_simplified`，序列化跟随预览选中的候选。
- 旧数据兼容：详情卡遇无该键或两值旧数据正常回显（无该键隐藏算法行，两值映射到新显示名）。

### 验收补条

1. 算法切换 chips 移动端（向导第 3 步）与桌面端（地图悬浮层）均可见；
2. 默认选中「凹包·简化」（无手工操作时 metadata `hullMethod` = `concave_simplified`）；
3. 不可用候选置灰且点击无效果；
4. 切换算法后统计条「生成方式」格与顶点数联动更新，`previewStale` 保持 false；
5. 默认参数组回归门禁不变：`track_to_envelope_converter_test` 一个字不改全绿，默认参数组三候选与单次 `convert()` 输出逐位一致（`envelope_candidates_test` 钉死）。

### v2.2 修订（2026-11-12 集成测试反馈：凹包·简化与精细视觉差异不足）

- **根因**：密集 GPS 簇让凹包边界在簇内深绕行（进→出→进），逐点面积贡献精简对深绕行失效（删任一单点面积变化都巨大）——v2.1 的「凹包·简化」与「凹包·精细」几乎无差异（53 vs 67 顶点）。
- **对策**：「凹包·简化」候选输入前置 **30m 网格抽稀**（`TrackDraftParams.clusterCellM=30`，仅该候选消费）：每格保留离点集质心最远的点（保外轮廓），密集簇压到每格 1 点，绕行从源头消失；格以质心为原点对齐（小于一格的点集整体同格走 fallback，不因负零界被切分）。精细/凸包两候选与默认组零影响。
- **dev 实测**（11/12 号设备近 7 天）：简化 36 顶点/46.5 亩、精细 47 顶点/47.0 亩、凸包 17 顶点/56.3 亩——三档区分成立。
- **校准项**：`clusterCellM` 与 `areaContributionTolPct`（0.005）随真机校准一并调优；用户仍嫌简化不够「简」时优先调大 clusterCellM。
