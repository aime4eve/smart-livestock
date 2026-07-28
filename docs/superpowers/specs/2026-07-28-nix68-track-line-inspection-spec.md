# NIX-68 GPS 线路检验（标准轨迹检验 / LINE）— 方案设计文档

| 字段 | 值 |
|---|---|
| 工单 | NIX-68 GPS 线路检验（标准轨迹检验） |
| 优先级 | High |
| 类型 | 新功能（Feature） |
| 前置依赖 | NIX-20 动态检验、NIX-21 批量导入重构、NIX-22 RTK 轨迹导入动态检验（均已实施） |
| 设计日期 | 2026-07-28 |
| 状态 | 待评审 |
| 原型 | `docs/marketing/nix-68-track-line-inspection-prototype.html`（v3，已确认） |

---

## 1. 背景与目标

### 1.1 现状与缺口

现有 GPS 质量检验三种类型（`TestType.java:7-11`）：

| 类型 | 真值来源 | 匹配方式 | 局限 |
|---|---|---|---|
| STATIC 静态 | 固定 RTK 真值点 | 设备静止上报 vs 单点 | 只反映静止精度 |
| DYNAMIC 路线动态（NIX-20） | 固定 RTK 点序列路线 | 空间匹配（≤30m 算经过） | 需要节奏编排 |
| TRAJECTORY 轨迹动态（NIX-22） | 导入的随行 RTK 轨迹 | 时间配对（上报时刻↔同时刻 RTK 读数） | 每次外场都要重新采集真值；真值随用随弃，不沉淀 |

实际外场检验中，测试人员反复沿**同一物理线路**（如舍内中央通道）行走采集：RTK 手簿的"线路追踪"功能会记录整条高密度轨迹。这些轨迹是**可复用的线路级真值**——一次采集、长期作为该线路的"标准轨迹"，后续任何设备沿该线路走一遍即可检验其沿线定位偏差。本期把这种真值沉淀为平台的第三类真值基准，并新增第四种检验类型 **LINE（线路检验）**。

### 1.2 采集数据形态（用户真实样例）

RTK 手簿导出的 XLSX（样例：仓库根目录 `轨迹检验线路1/2/3.xlsx`）：

- 单 sheet「线路追踪」，表头 8 列：名称 / 类别 / 开始时间 / 结束时间 / 长度(单位:米) / 备注 / 线路类型 / 坐标
- **整条线路只有一行数据**；全部坐标点在「坐标」单元格内，为**换行分隔**的 `经度,纬度,高程` 三元组（WGS-84，如 `112.85174042202968,28.246855063618117,0`）
- **元数据不可信**（真实样例中即存在）：开始=结束时间、长度=0、`2026=07-28` 手误；静止时手簿产生大量连续重复坐标点（样例 1：原始 525 点 → 去连续重复后 430 点）

### 1.3 设计目标

- **G1**：真值管理 Tab 新增第三类真值「标准轨迹」：XLSX 导入 → 候选列表（查看/选定/删除/地图预览），追加式管理不归并
- **G2**：新增检验类型 LINE：查出有 gps_logs 数据的设备 → 选标准轨迹 → 逐设备做空间匹配：计算 GPS 点到标准折线的最短距离、按走廊阈值切出有效轨迹段（不做时间对齐，时间仅用于切段，I3）→ 统计 + 分级，结果快照
- **G3**：检验列表 Tab 新增「检验结果汇总」区：单设备 4 类检验统一视图；LINE 报告加入既有按类型分派机制
- **G4**：质量对比 Tab 类型选择器 3 段扩 4 段，线路检验横向对比 = 同图叠加地图（绿色标准线 + 多设备多色轨迹）+ 对比表
- **G5**：STATIC / DYNAMIC / TRAJECTORY 三类的报告面板、打开方式、API、分级逻辑**完全不变**（§3 继承关系）

### 1.4 范围声明（本期分期，已与用户确认）

> **本期范围**：XLSX 导入 → 候选管理（追加式不归并）→ **手动选定**一条标准轨迹 → LINE 检验。
> **本期不做**：从多条候选**自动合成**一条标准轨迹——二期实现，本期只做入口、勾选交互与提示弹窗（D3、§10）。

该分期已在 2026-07-28 与用户的对话中确认，**非静默降级**。理由：合成对齐策略（加权平均 / 中轴线 / Fréchet 距离对齐等）需以真实多线路数据验证后才能定型，缺乏数据积累时盲做风险高；本期先落地候选管理与检验闭环，同步积累真实线路数据，为二期合成提供验证基础。

---

## 2. 核心设计决策（与原型确认记录对应）

| # | 决策 | 说明 |
|---|---|---|
| D1 | **新增检验类型 LINE，三类既有类型不动** | `TestType` 枚举追加 `LINE`（`TestType.java:7-11`）；`gps_quality_tests` 统一会话表沿用，CHECK 约束按既有演进写法放开（§6.1） |
| D2 | **不开新顶层 Tab，报告下沉到两个既有维度** | 设备维度 → 检验列表（统一报告区 + 类型分派）；横向对比维度 → 质量对比（第 4 段）。顶部 3 Tab 结构不变 |
| D3 | **标准轨迹追加式管理，不归并** | 一次导入 = 一条独立候选（status=CANDIDATE）；同一文件重复导入**新增记录而不覆盖**；选定（SELECTED）不互斥仅标记；合成（勾选 ≥2 条）为二期，本期只做入口与交互预留 |
| D4 | **检验发起时快照，删除候选不影响历史报告** | 发起 LINE 检验时把标准轨迹点列快照进 `gps_quality_line_points`；计算结果（逐设备统计 + 逐点偏差）快照进 `gps_quality_line_results` / `gps_quality_line_deviations`。与 NIX-22 D2 的快照哲学一致；此处连结果也快照，因为 LINE 计算依赖 `gps_logs` 查询（I3 后为设备全量点列空间匹配），而 `DataRetentionService` 会清理 gps_logs——若现算，历史报告会随遥测清理而变化或消失 |
| D5 | **只支持 RTK 手簿 XLSX 版式** | 单 sheet「线路追踪」、8 列单行、坐标列换行分隔三元组。不做多格式识别（非目标） |
| D6 | **元数据不采信，一切以坐标实算** | 开始/结束时间、长度字段仅展示不入库，解析失败不阻断；点数 = 去连续重复后计数；全长 = 去重后逐段 haversine 累加；名称默认取「名称」列可改 |
| D7 | **清洗 = 去连续重复点 + 忽略高程** | 仅剔除与前一保留点完全相同的连续点；不做速度跳点剔除、不做抽稀（线路真值需要完整几何） |
| D8 | **导入沿用 parse 预检 → import 落库两段式** | 对齐 `/trajectory/parse`、`/trajectory/import`（`GpsQualityAdminController.java:373,386`）；上限沿用 MAX_ROWS 思路按解析后坐标点数限制（`TrajectoryImportService.java:66` 的 `MAX_ROWS = 5000`，本期按点数 20000 限） |
| D9 | **LINE 检验只由「新建线路检验」流程产生** | `create_check_dialog.dart:75-97` 的两段选择器（STATIC/DYNAMIC）不变；新建线路检验是左栏工具条新入口打开的独立弹窗（与 TRAJECTORY 只由导入产生同一思路，NIX-22 D8） |
| D10 | **分级沿用现有 QualityGrade 口径，无配对率维度** | LINE 的样本是空间匹配出的有效轨迹段内 gps_logs 点（I3 修订，原为时间窗内全部点），无"配对"概念，故不设 pairRate 约束：samples ≥10 且 p95 ≤15m → EXCELLENT；≥6 且 ≤25m → USABLE；≥4 且 ≤40m → MARGINAL；否则 UNAVAILABLE。阈值与 `TrajectoryPairingService.determineTrajectoryGrade`（`TrajectoryPairingService.java:120-132`）的 p95 档位一致 |
| D11 | **时间解析沿用 UTC 面值惯例** | 前端 datetime-local 提交 naive 时间，后端按 `GpsQualityAdminController.parseInstant`（`GpsQualityAdminController.java:91-97`）面值解析（lesson #17：不做时区猜测，两端同一基准）；前端不做 `toUtc()`。**I3 变更**：LINE 端点与 UI 已完全去掉时间范围参数（匹配键改为空间），本条不再适用于 LINE 发起/对比流程，仍适用于 TRAJECTORY 等既有带时间窗的流程 |
| D12 | **计算下沉纯 domain service** | 新建 `TrackLineCalculator`（点到折线最短距离 + 统计聚合 + 分级），无 IO、可单测，与 `TrajectoryPairingService`（`TrajectoryPairingService.java:28-30`）同一模式 |

---

## 3. 继承关系（三类既有功能零改动声明）

本章为用户明确要求单列的章节：逐项说明 LINE 新增内容**挂载在哪个既有点**，以及既有逻辑为何不受影响。

### 3.1 检验列表「查看报告」的类型分派点

现状（`quality_check_list.dart:693-710`，`_buildReport`）：

```dart
if (check.status == 'FAILED') return _buildFailedReport(...);   // :699
if (check.checkType == 'STATIC')    return _StaticReportCard(...);      // :703-704，定义于 :923
else if (check.checkType == 'TRAJECTORY') return TrajectoryReportPanel(...); // :705-706
else return _DynamicReportCard(...);                              // :707-708，定义于 :1002
```

- **打开方式**：点击右栏检验时间轴上的类型段 → 选中该 checkId → 报告面板**内联**展示在右栏报告区（非弹窗）。原型 v3 中 LINE 报告以弹窗呈现仅为单文件原型的展示限制，落地按现状**内联面板**实现
- **本期改动**：if 链在 TRAJECTORY 分支后追加一个 `check.checkType == 'LINE'` → `LineReportPanel(testId: checkId)` 分支。既有三个分支的条件、widget、provider（`qualityReportProvider` / `dynamicReportProvider:134` / `trajectoryReportProvider:205`）与后端报告端点（`/tests/{id}/report`:332、`/tests/{id}/dynamic-report`:340、`/tests/{id}/trajectory-report`:416）**全部不改**
- LINE 报告数据来自新端点 `/tests/{id}/line-report`（读快照，§7），与三类既有报告端点互不交叉

### 3.2 统一报告区（纯新增聚合层）

- 检验列表右栏概览卡与时间轴之间插入「检验结果汇总」卡：对当前选中设备，按 STATIC / DYNAMIC / TRAJECTORY / LINE 各取**最近一次**检验，一行一条（类型标记 / 最近检验时间 / Grade 徽章 / 关键指标 / 查看报告）
- 「查看报告」= 把该检验设为当前选中 checkId，自然落入 §3.1 的既有分派——**不复制任何报告生成逻辑**
- 数据来自新端点 `/checks/summary?deviceCode=`（§7.5），不改动现有 `/checks`（:193）响应结构
- 该层只做只读聚合展示，三类既有检验的创建、计算、报告逻辑均不感知它的存在

### 3.3 质量对比 Tab

现状（`comparison_tab.dart:40-58`）：`SegmentedButton<int>` **3 段**（0=静态按真值点 / 1=动态按路线 / 2=轨迹按设备，轨迹段为 NIX-22 所加，见 `_buildTrajectoryComparison`:303）。

- **本期改动**：`_segment` 追加第 4 段「线路」→ `_buildLineComparison`；前三段的选择器、下拉过滤、对比逻辑与界面**不变**
- LINE 横向对比数据来自新端点 `/comparison/line`（§7.6），静态段 `/comparison`（:452）、动态段 `/comparison/dynamic`（:466）、轨迹段 `/comparison/trajectory`（:438）不改

### 3.4 真值管理 Tab

现状（`truth_reference_tab.dart`）：左卡 RTK 真值点（按 locationName 分组的 ExpansionTile，:83-104）+ 右卡动态路线（CRUD + 点位序列，:125-165）。

- **本期改动**：Tab 顶部新增三分类页签（RTK 真值点 / 动态路线 / **标准轨迹**），既有两个面板原样迁入前两个页签，RTK 点/路线的 CRUD 与 provider（`rtkPointsProvider` / `dynamicRoutesProvider`）不改
- 「标准轨迹」页签为全新面板 `StandardTracksPanel`

### 3.5 后端沿用清单

| 既有件 | 沿用方式 |
|---|---|
| `gps_quality_tests` 统一会话表 | LINE 复用；CHECK 约束按 `V20260722100000__nix22_trajectory_track_points.sql:16-22` 的 DROP+ADD 写法演进（§6.1） |
| 路由与鉴权 | 全部新端点挂在 `/api/v1/admin/gps-quality`（`GpsQualityAdminController.java:59`）+ `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`（:61） |
| 租户 | `resolveTenantId()` 的 `TenantContext` + `FALLBACK_TENANT_ID = 1L` fallback（:76-83） |
| 响应包装 | `ApiResponse`（:35）统一返回 |
| 时间解析 | `parseInstant` UTC 面值（:91-97，lesson #17） |
| 报告现算/快照 | NIX-22 确立"配对快照 + 报告现算"；本期因 gps_logs 生命周期原因扩展为"结果也快照"（D4），三类既有报告仍现算不动 |
| XLSX 解析 | Apache POI `XSSFWorkbook`（`build.gradle:88` poi-ooxml 5.2.5；`TrajectoryImportService.java:24-25` 已在用） |
| 分位数/haversine | 沿用 `TrajectoryPairingService.percentile` 线性插值（:145-156）与 haversine（:162-170）的同一约定；退化规则沿用：p50 <5 点用 max、p95 <20 点用 max（:109-110） |

---

## 4. 文件格式（RTK 手簿 XLSX 导出版式）

### 4.1 版式定义

- `.xlsx`，单 sheet「线路追踪」（sheet 名按首个 sheet 容忍，不强制校名）
- 第 1 行表头 8 列；第 2 行起每行一条线路（本期只取**第一条数据行**，多行时在预览中提示"仅导入第 1 条"）

| 列 | 字段 | 系统使用 | 说明 |
|---|---|---|---|
| A | 名称 | **使用** | 候选线路默认名称（可改），如 `自动追踪_20260728153839`；为空时回退文件名 |
| B | 类别 | 忽略 | 手簿内部字段 |
| C | 开始时间 | **不采信** | 仅预览展示，解析失败不阻断（D6） |
| D | 结束时间 | **不采信** | 同上（真实脏例：`2026=07-28 16:19:35`） |
| E | 长度(单位:米) | **不采信** | 全长由坐标实算（真实脏例：0） |
| F | 备注 | 忽略 | — |
| G | 线路类型 | 忽略 | — |
| H | 坐标 | **使用** | 单元格内换行分隔的 `经度,纬度,高程` 三元组；高程列忽略（D7） |

### 4.2 坐标单元格解析规则

```
输入：坐标列字符串（真实样例行首有前导空格，如 "112.85...,28.24...,0 \n 112.85..."）
1. 按 \n 切分 → 逐行 trim（兼容 \r\n）→ 空行跳过
2. 每行按 , 切分：恰好 3 段；lng ∈ [-180,180]、lat ∈ [-90,90]；第 3 段忽略
3. 任一段非数值或越界 → 该行跳过并计入 invalidPoints（不阻断整体）
4. 去连续重复：与前一保留点 (lng,lat) 完全相同 → 剔除（D7）
5. 去重后点数 < 2 → 文件级校验失败「有效坐标点不足」
```

### 4.3 文件约束

- 仅 `.xlsx`；坐标点数（原始）上限 **20000**（对齐 `TrajectoryImportService.MAX_ROWS` 的限量思路，D8）
- 行级/点级问题不阻断：在预览中展示 原始点数 / 去重后点数 / 去除数 / 无效点数
- 提供示例文件下载（由真实样例 `轨迹检验线路1.xlsx` 派生）

### 4.4 parse 预览输出（与原型第 2 步一致）

原始点数 525 / 去重后点数 430（去连续重复 95）/ 实算全长 1177m / 起点 112.85174,28.24686 / 终点 112.85174,28.24687 + 前 8 个坐标点表 + 元数据不可信警告。

---

## 5. 检验算法（`TrackLineCalculator`，纯 domain，无 IO）

### 5.1 点到折线最短距离

```
输入：设备点 P(lat,lng)，标准轨迹点列 L[0..n-1]（去重后，n≥2）
输出：(deviationMeters, segmentNo)

for i in 0..n-2:
    d_i = pointToSegment(P, L[i], L[i+1])
deviation = min(d_i)，segmentNo = argmin 的 i（取首个最小值，确定性）

pointToSegment(P, A, B):
    # 小范围（线路 < 几 km）采用等距圆柱局部投影，以 P 为原点：
    #   x = (lng - P.lng) * cos(P.lat) * 111320,  y = (lat - P.lat) * 110540
    # 投影后平面几何求点到线段 AB 最短距离（垂足在线段内取垂距，否则取端点距）
    # 与既有 haversine（TrajectoryPairingService.java:162-170）在 <1km 量级误差 <0.1%
```

- **时间只用于切段，不进入偏差计算**：设备点的 recordedAt 仅用于按时间升序排序与相邻点间隔切段（§5.2），偏差本身纯空间（与 TRAJECTORY 时间配对的本质区别，§1.1）
- 线段局部投影的纬度系数与既有 haversine 约定一致；算法说明写在 javadoc

### 5.2 空间匹配与轨迹段切分（I3 修订：空间匹配取代时间窗匹配）

```
输入：标准轨迹点列 L（去重后，n≥2）+ 单设备全部 gps_logs 点列（按 recorded_at 升序，不带时间窗过滤）
逐点：计算到折线 L 的最短距离（§5.1，等距圆柱投影）→ (recordedAt, lat, lng, deviation, segmentNo)
接近标记：deviation ≤ CORRIDOR_METERS(100m) → 该点"接近线路"
切段：相邻接近点的 recordedAt 间隔 ≤ GAP_SECONDS(300s) → 归同一轨迹段；超过则切段
过滤：段内点数 < MIN_SEGMENT_POINTS(4) → 整段丢弃（去孤点噪声）
有效样本 = 所有有效段合并后的点集（同一设备多趟合成一次检验）
```

三个常量：

| 常量 | 值 | 取值理由 |
|---|---|---|
| `CORRIDOR_METERS` | 100 | 走廊阈值，判定"经过线路"；必须 > 分级带宽上限 40m（D10 的 MARGINAL p95 档），否则 UNAVAILABLE 设备的点进不了样本，永远无法被检验区分 |
| `GAP_SECONDS` | 300 | 相邻点间隔容忍，覆盖 LoRaWAN 丢点/上报抖动，避免一次丢点把一趟切成两趟 |
| `MIN_SEGMENT_POINTS` | 4 | 单趟最小点数，剔除偶尔飘过走廊的孤点噪声 |

### 5.3 统计聚合

```
输入：有效样本点集（各有效段合并，保持时间升序）
聚合：
  sampleCount = 有效样本点数
  tripCount   = 有效轨迹段数
  mean / p50 / p95 / max（percentile 线性插值 + 退化规则沿用既有约定，§3.5）
  within15mPct / within25mPct / within40mPct = deviation ≤ 阈值 的占比
grade = determineLineGrade(stats)   # D10
无有效段 → sampleCount = 0 → grade = UNAVAILABLE（test 正常创建，结果快照照落）
```

### 5.4 分级（D10）

| Grade | 条件 | 最小样本 |
|---|---|---|
| EXCELLENT | p95 ≤ 15m | samples ≥ 10 |
| USABLE | p95 ≤ 25m | samples ≥ 6 |
| MARGINAL | p95 ≤ 40m | samples ≥ 4 |
| UNAVAILABLE | 其他 | samples < 4 |

p95 档位与 `determineTrajectoryGrade`（`TrajectoryPairingService.java:120-132`）一致；LINE 无 pairRate 约束（样本无需配对，D10）。复用后端 `QualityGrade` 枚举（`QualityGrade.java:3-8`，含 MARGINAL）与前端 `QualityGrade`（`gps_quality_models.dart:4`）。

---

## 6. 数据模型

### 6.1 `gps_quality_tests` 扩展

`test_type` 为 VARCHAR(10)，`'LINE'` 无需改列宽。新增可空列 `track_line_id`（关联标准轨迹，记录发起时选用的线路；配合点列快照 D4），CHECK 约束按 NIX-22 同写法演进：

```sql
ALTER TABLE gps_quality_tests ADD COLUMN track_line_id BIGINT
    REFERENCES standard_track_lines(id) ON DELETE SET NULL;

ALTER TABLE gps_quality_tests DROP CONSTRAINT chk_test_type_truth;
ALTER TABLE gps_quality_tests ADD CONSTRAINT chk_test_type_truth CHECK (
    (test_type = 'STATIC'     AND rtk_point_id IS NOT NULL AND route_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'DYNAMIC'    AND route_id IS NOT NULL AND rtk_point_id IS NULL  AND track_line_id IS NULL) OR
    (test_type = 'TRAJECTORY' AND rtk_point_id IS NULL AND route_id IS NULL      AND track_line_id IS NULL) OR
    (test_type = 'LINE'       AND rtk_point_id IS NULL AND route_id IS NULL)
);

-- 支撑 /checks/summary 按设备+类型取最近一次检验（§7.5）
CREATE INDEX idx_gqt_device_type_time ON gps_quality_tests(device_code, test_type, created_at DESC);
-- 支撑删除候选时级联 SET NULL 与按线路查检验（/comparison/line）
CREATE INDEX idx_gqt_track_line ON gps_quality_tests(track_line_id);
```

> **修正（V20260728130000）**：LINE 分支**不要求** `track_line_id IS NOT NULL`——FK 为 `ON DELETE SET NULL`，删除候选后 track_line_id 置空，若 CHECK 要求非空则删除操作必然违反约束（dev 集成测试实测触发）。track_line_id 只是候选存活期间的活引用，真值由快照表承载（D4）。

LINE 会话字段填充规则：

| 字段 | 值 |
|---|---|
| device_code / device_id | 发起时勾选的设备（多设备 = 每台一条 LINE test） |
| test_type | LINE |
| rtk_point_id / route_id | NULL |
| track_line_id | 发起时选定的标准轨迹 |
| started_at / ended_at | 有效样本首末 recordedAt（I3 修订：原为用户选择的时间范围）；无有效段时回退设备 gps_logs 数据首末；started_at 列 NOT NULL |
| status | READY（发起即完成计算与快照，无 DEVICE_PENDING 流程） |
| note | 标准轨迹名称（快照时点），如 `自动追踪_20260728153839` |

设备完全无 gps_logs 时不创建 test（I3）：发起响应中该设备条目返回 `testId=null, sampleCount=0, grade=UNAVAILABLE`。

`track_line_id ON DELETE SET NULL`：删除候选线路后历史检验保留（点列已快照），外键置空，note 仍可追溯名称。

实体同步改动：`GpsQualityTest.java` 新增 `trackLineId` 字段 + getter/setter；新增含 trackLineId 的构造器——现有全参构造器（`GpsQualityTest.java:62`，签名 `(String deviceCode, TestType testType, Long rtkPointId, Long routeId, Instant startedAt)`）不含 trackLineId；类 Javadoc 更新覆盖 LINE（`:13-14` 的真值来源列表与 `:57` 的 "STATIC or DYNAMIC" 表述）。

### 6.2 新表 `standard_track_lines`（标准轨迹候选）

```sql
CREATE TABLE standard_track_lines (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'CANDIDATE',   -- CANDIDATE / SELECTED
    point_count INTEGER NOT NULL,                      -- 去连续重复后点数（实算，D6）
    length_m NUMERIC(10,1) NOT NULL,                   -- 去重后逐段 haversine 累加（实算）
    start_lng NUMERIC(10,7) NOT NULL,                  -- 起点（实算，展示用）
    start_lat NUMERIC(10,7) NOT NULL,
    source_file VARCHAR(255),                          -- 来源文件名（追溯用，不参与唯一性）
    created_at TIMESTAMP NOT NULL DEFAULT NOW()        -- 导入时间
    -- 无 UNIQUE(name/文件)：重复导入新增不覆盖（D3）
);
CREATE INDEX idx_stl_tenant ON standard_track_lines(tenant_id, status);
```

### 6.3 新表 `standard_track_line_points`（标准轨迹点列，无时间戳）

```sql
CREATE TABLE standard_track_line_points (
    id BIGSERIAL PRIMARY KEY,
    line_id BIGINT NOT NULL REFERENCES standard_track_lines(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                      -- 去重后顺序，从 1 开始
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,                   -- 无 collected_at：元数据不采信（D6）
    UNIQUE (line_id, sequence_no)
);
```

### 6.4 新表 `gps_quality_line_points`（检验时点列快照，D4）

```sql
CREATE TABLE gps_quality_line_points (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    UNIQUE (test_id, sequence_no)
);
```

### 6.5 新表 `gps_quality_line_results` + `gps_quality_line_deviations`（结果快照，D4）

```sql
CREATE TABLE gps_quality_line_results (
    test_id BIGINT PRIMARY KEY REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sample_count INTEGER NOT NULL,
    trip_count INTEGER NOT NULL DEFAULT 0,               -- 有效轨迹段数（I3，V20260728140000 补列）
    mean_deviation_m NUMERIC(10,2) NOT NULL,
    p50_m NUMERIC(10,2) NOT NULL,
    p95_m NUMERIC(10,2) NOT NULL,
    max_deviation_m NUMERIC(10,2) NOT NULL,
    within15m_pct NUMERIC(5,1) NOT NULL,
    within25m_pct NUMERIC(5,1) NOT NULL,
    within40m_pct NUMERIC(5,1) NOT NULL,
    grade VARCHAR(12) NOT NULL,                        -- EXCELLENT/USABLE/MARGINAL/UNAVAILABLE
    first_recorded_at TIMESTAMPTZ,
    last_recorded_at TIMESTAMPTZ,
    computed_at TIMESTAMP NOT NULL DEFAULT NOW()       -- 差值类列精度对齐教训 #13（≥DECIMAL(10,2)）
);

CREATE TABLE gps_quality_line_deviations (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                      -- 时间升序
    recorded_at TIMESTAMPTZ NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    deviation_m NUMERIC(10,2) NOT NULL,
    segment_no INTEGER NOT NULL,                       -- 最近点所在标准轨迹线段序号
    UNIQUE (test_id, sequence_no)
);
CREATE INDEX idx_gld_test ON gps_quality_line_deviations(test_id, sequence_no);
```

规模评估：deviations 只落有效段内的点（I3）；单趟 30 分钟上报间隔 × 2.5h ≈ 5 点/设备，高频场景（5s 上报）单趟 2.5h ≈ 1800 点/设备，与 NIX-22 轨迹点同量级，可接受。

负载估算（评审 F2 补充）：

- **典型场景**：30 设备 × 5 点 ≈ 150 次点到折线计算，可忽略。
- **最坏场景**：30 设备 × 1800 点 × 430 段 ≈ 2300 万次等距圆柱投影——纯算术、无 IO（~1μs/次，秒级）+ 约 5.4 万行 deviations 批量 INSERT，预估总耗时 **<10s**。
- **结论**：最坏场景下同步 READY（发起即完成计算与快照）可接受，**本期保持同步计算，不引入 DEVICE_PENDING 异步流程**；若未来上报频率显著提高（如秒级上报常态化），再评估异步化。

> **I3 注**：匹配键改为空间后，计算输入为设备全部 gps_logs（不再按时间窗截取），单次计算量随设备历史数据量增长；但 deviations 只落有效段内的点（走廊外与被丢弃孤段的点不进快照），结果快照行数只降不升。

### 6.6 迁移命名

`V20260728100000__nix68_track_line_inspection.sql`：`track_line_id` 加列 + CHECK 演进 + 2 条新索引（`idx_gqt_device_type_time`、`idx_gqt_track_line`，§6.1）+ 4 张新表。**无种子数据**——标准轨迹来自用户导入（同 NIX-22 §5.4 的处理）。

`V20260728140000__nix68_line_trip_count.sql`（I3）：`gps_quality_line_results` 加列 `trip_count INTEGER NOT NULL DEFAULT 0`；存量行回填 0——既有结果是时间窗语义，无从追溯轨迹段数，回填 0 仅作占位。

---

## 7. API 设计

在 `GpsQualityAdminController`（`/api/v1/admin/gps-quality`，PLATFORM_ADMIN，ApiResponse 包装，TenantContext fallback）下新增端点；现有端点零改动（LINE 随 testType 自然流过 `/checks` 列表）。

### 7.1 标准轨迹管理

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/track-lines` | 候选列表（含状态/点数/全长/导入时间），tenant 过滤 |
| POST | `/track-lines/parse` | multipart XLSX → §4.4 预览（**不落库**），对齐 `/trajectory/parse` 两步式 |
| POST | `/track-lines/import` | multipart XLSX + `name`（可空→取文件名称列）→ 创建 CANDIDATE 候选 |
| POST | `/track-lines/{id}/select` | 标记 SELECTED（不互斥，D3） |
| POST | `/track-lines/{id}/unselect` | 回到 CANDIDATE |
| DELETE | `/track-lines/{id}` | 删除候选（点列 CASCADE；历史检验因快照不受影响，track_line_id SET NULL） |
| GET | `/track-lines/{id}/points` | 点列（地图预览用） |

### 7.2 parse 响应 DTO

```java
public class TrackLineParseResultDto {
    String defaultName;      // 文件「名称」列，空则为文件名
    int rawPointCount;       // 原始点数
    int pointCount;          // 去连续重复后点数
    int removedDuplicates;   // 去除连续重复数
    int invalidPoints;       // 无效坐标行数（跳过）
    double lengthMeters;     // 实算全长
    BigDecimal startLng, startLat, endLng, endLat;
    String metadataWarning;  // 元数据异常说明（开始=结束/长度为 0/时间解析失败），无则 null
    List<Point> previewPoints; // 前 8 个坐标点（去重后）
}
```

### 7.3 LINE 检验发起

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/line-checks/devices` | 查所有有 gps_logs 数据的设备列表（I3 起无 start/end 时间参数）：{deviceCode, deviceId, pointCount（总点数）, firstRecordedAt, lastRecordedAt} |
| POST | `/line-checks` | 发起：{trackLineId, deviceCodes[]}（I3 起无 start/end）→ 逐设备创建 LINE test + 快照点列 + 空间匹配计算 + 结果快照，返回逐设备 {testId, deviceCode, sampleCount, grade}；设备完全无 gps_logs → testId=null, sampleCount=0, grade=UNAVAILABLE（§6.1） |
| GET | `/tests/{id}/line-report` | LINE 报告统计摘要（读快照；testType≠LINE → 400），对齐 `/tests/{id}/trajectory-report`；点列与逐点偏差走子端点（§7.4） |

### 7.4 报告 DTO（读快照，不再回查 gps_logs；响应体积控制，评审 F3）

主端点 `GET /tests/{id}/line-report` 只返回统计摘要：

```java
public class LineQualityReportDto {
    Long testId;
    String deviceCode;
    Instant startedAt, endedAt; // 有效样本首末 recordedAt（无有效段时回退设备数据首末，§6.1）
    Long trackLineId;          // 发起时选用的标准轨迹（候选删除后置空，§6.1）
    String trackLineName;      // 快照时点名称（note）
    QualityGrade grade;
    int sampleCount;
    int tripCount;             // 有效轨迹段数（I3，§5.2）
    double meanDeviation, p50, p95, maxDeviation;
    double within15mPct, within25mPct, within40mPct;
}
```

标准轨迹点列与逐点偏差拆为两个子端点按需加载（点列上限 20000 点、高频场景偏差约 1800 行/设备，全量内联会使单响应达 MB 级）：

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/tests/{id}/line-report/track` | 标准轨迹点列快照（地图绿线）：`List<LinePoint> {sequenceNo, lng, lat}` |
| GET | `/tests/{id}/line-report/deviations?limit=` | 逐点偏差明细（时间升序）：`List<Deviation> {sequenceNo, recordedAt, lng, lat, deviationM, segmentNo}`；**只返回有效段内的点**（I3：走廊外与被丢弃孤段的点不进快照）；默认全量，`limit` 可选限量 |

### 7.5 统一报告区摘要端点

```
GET /checks/summary?deviceCode=
→ 4 类型各最近一次检验：[{checkType, testId, endedAt, grade, keyMetric}]
   keyMetric：STATIC→p95；DYNAMIC→p95；TRAJECTORY→meanError/pairRate；LINE→meanDeviation/p95
   某类型无检验 → 该类型条目不返回（前端显示「暂无」）
```

### 7.6 质量对比端点

```
GET /comparison/line?trackLineId=
→ 不传 deviceCode：返回该线路下每设备最新一条 READY 检验的统计对比表 + 标准轨迹点列（同图叠加地图绿线）：
   { trackLine: [{sequenceNo, lng, lat}, ...],
     rows: [{testId, deviceCode, sampleCount, tripCount, mean, p50, p95, max, within15/25/40, grade, startedAt, endedAt}] }
GET /comparison/line?trackLineId=&deviceCode=
→ 追加返回该设备的上报轨迹点（多色 polyline，来自偏差快照，仅有效段内点）；
  前端按设备逐个按需加载，避免多设备轨迹点一次性内联（评审 F3）
```

**I3 变更**：start/end 时间参数已随匹配键改空间而移除，对比口径改为"该线路下每设备最新一条 READY"。I2 的窗口相交口径（`startedAt <= end AND endedAt >= start`）随之废止，原始说明保留于本节下方备查。

> （已废止，I2 原文）时间窗过滤口径：检验记录按窗口相交匹配——检验窗口 [startedAt, endedAt] 与查询窗口 [start, end] 有重叠即纳入（`startedAt <= end AND endedAt >= start`）。最初实现为"startedAt 落在查询窗内"，用户查询窗起点晚于检验起点时会全部漏掉（如检验 08:02 发起、查询 08:35 开始），不符合直觉。

---

## 8. 前端设计（与原型 v3 的 ①~⑦ 一一对应）

> 基准目录：`Mobile/mobile_app/lib/features/admin/gps_quality/`。页面 3 Tab 结构不变。

### 8.1 Tab 2 真值管理（`truth_reference_tab.dart` 改造，原型 ①②）

- 顶部三分类页签：RTK 真值点（33）/ 动态路线（4）/ **标准轨迹**；既有左右两卡原样迁入前两个页签
- 新增 `standard_tracks_panel.dart`：
  - 工具栏：「导入轨迹」（打开 §8.2 向导）、「合成」（勾选 ≥2 条可用，点击弹二期提示弹窗，原型 ③）
  - 候选表格：☑ / 名称 / 点数 / 全长 / 导入时间 / 状态（候选·已选定）/ 操作（预览·选定/取消选定·删除）
  - 表格上方管理规则说明条（追加式不归并、重复导入新增不覆盖、快照不受删除影响、合成二期）
  - 数据源：`trackLinesProvider`（新增，FarmScoped 基类 + `watchActiveFarmId()`，遵循牧场切换刷新规则）
- 新增 `track_line_preview_dialog.dart`：左侧候选列表 + 右侧 flutter_map 叠加（标准线绿色实线 + 其余候选灰色）+ 底部统计条（点数/实算全长/起终点/导入时间）

### 8.2 新增 `track_line_import_dialog.dart`（原型 ②，3 步向导）

模式复刻 `trajectory_import_dialog.dart` 的 stepper 结构：

1. **上传 XLSX**：拖放/选择 + 示例下载 + 8 列版式说明表（逐列标注 使用/忽略/不采信）+ 清洗规则说明（去连续重复、忽略高程、元数据脏值容忍）
2. **解析预览**：统计条（原始点数/去重后/去除数/实算全长/起终点）+ 前 8 个坐标点表（序号/经度/纬度）+ 元数据不可信警告 + 命名行（默认取名称列）
3. **导入结果**：新建候选条目 + 追加式提示；完成后刷新 `trackLinesProvider`

### 8.3 Tab 1 检验列表（`quality_check_list.dart`，原型 ④⑤）

| 改动 | 说明 |
|---|---|
| 左栏工具条新入口 | 「新建线路检验」图标按钮 → `LineCheckCreateDialog`（§8.4）；既有 ＋/⬆/🛰 不变 |
| 设备分组行 + 时间轴 | 新增第四种类型标记「线路」：青绿 `Color(0xFF0F766E)`，时间轴「线」段同色系；tooltip 复用现有逻辑 |
| **检验结果汇总卡（新增）** | 概览卡与时间轴之间：4 行（类型/最近检验时间/Grade 徽章/关键指标/查看报告），数据 `/checks/summary`；「查看报告」= 选中该 checkId，落入既有分派（§3.1/§3.2） |
| 报告区分派 | `_buildReport`（:703-709）if 链追加 LINE 分支 → `LineReportPanel`，既有三分支不动 |

### 8.4 新增 `line_check_create_dialog.dart`（原型 ④）

打开即加载设备（`/line-checks/devices`，I3 起去时间范围步骤）→ 设备列表勾选（设备号/总点数/首末时间）→ 标准轨迹下拉（SELECTED 置顶带 ★，CANDIDATE 列后）→ 发起（`/line-checks`）→ 关闭并刷新 `checksProvider`。

### 8.5 新增 `line_report_panel.dart`（原型 ⑥，内联报告面板）

自上而下（与原型一致，结构对齐 `trajectory_report_panel.dart`）：

1. **标题行**：线路检验报告 + 类型标记 + Grade 徽章 + 标准轨迹名/有效样本首末时间
2. **指标 chips**：样本数 / 趟数 tripCount / mean / P50 / P95 / max / ≤15m / ≤25m / ≤40m 占比；chips 下方口径说明条：有效样本 = 连续接近线路的轨迹段（走廊 100m 内、间隔 5 分钟内、单趟 ≥4 点）
3. **地图对比**：flutter_map（§8.7）——标准轨迹绿色实线 Polyline + 设备上报红色虚线 Polyline + max 偏差点 Marker
4. **逐点偏差明细表**：# / 上报时间 / 设备经纬度 / 最近点所在线段 / 最短距离
5. 末尾 callout：多设备横向对比引导至质量对比 Tab

数据来源：标题行/指标 chips 来自 `/tests/{id}/line-report` 统计摘要；地图标准轨迹与设备轨迹、逐点偏差明细表分别来自 `/line-report/track`、`/line-report/deviations` 子端点（§7.4）。

### 8.6 Tab 3 质量对比（`comparison_tab.dart`，原型 ⑦）

- `SegmentedButton`（:40-58）3 段扩 4 段：静态/动态/轨迹/**线路**
- `_buildLineComparison`：条件条（标准轨迹下拉 + 设备 chip 带轨迹色；I3 起去时间范围，选轨迹即加载）→ `/comparison/line`（先取统计对比表 + 标准轨迹点列，设备轨迹点按 `deviceCode` 逐个按需加载，§7.6）→
  - **同图叠加地图**（flutter_map）：绿色标准线 + 每设备一色 Polyline（A01 红 #C2564B / A02 橙 #D97706 / A03 蓝 #2563EB，设备色板循环）
  - **横向对比 DataTable**（列与原型一致：设备/样本数/趟数/mean/P50/P95/max/≤15m/≤25m/≤40m/分级，样式对齐 `_buildTrajectoryComparison`:303 的 DataTable）
  - **导出 CSV**（I4）：标题行"导出 CSV"按钮，由已加载 rows 直接生成 UTF-8(BOM) CSV 下载（列同对比表，文件名 `line-comparison-yyyyMMdd-HHmmss.csv`），复用 `web_file_utils.downloadBytes`，不动后端

### 8.7 地图实现

复用 `trajectory_sheet.dart:631-650` 的 flutter_map + 离线瓦片模式：`TileLayer(tileProvider: _tileProvider, urlTemplate: '')` + `PolylineLayer(polylines: [Polyline(points, color, strokeWidth: 3.5)])` + `CameraFit.bounds`（:620-623）。标准线/设备轨迹/源轨迹均以此绘制，不引新依赖。

### 8.8 i18n

新增 key 同步写入 `app_zh.arb` / `app_en.arb`（两文件 gpsQuality 段现有各 504 行，key + `@key` 元数据成对），前缀 `gpsQualityLine*`：

- `gpsQualityLineCheck`（线路）、`gpsQualityLineReport`（线路检验报告）、`gpsQualityLineImport`（导入标准轨迹）
- `gpsQualityTrackLines`（标准轨迹）、`gpsQualityTrackLineCandidate`（候选）、`gpsQualityTrackLineSelected`（已选定）
- `gpsQualityLineMerge`（合成）、`gpsQualityLineMergePhase2`（合成算法二期实现提示）
- `gpsQualityLineSummaryMean` / `gpsQualityLineWithin15m` 等指标文案
- 既有 `gpsQualityTestTypeStatic/Dynamic`、`gpsQualityTrajectory*` 不变

---

## 9. 设计令牌与组件视觉规格

从原型 v3 `:root` 提取（38 个令牌），供 prototype-to-flutter-fidelity 流程解析；落地映射到 `AppColors` / `AppSpacing`。

### 9.1 令牌表

| 令牌 | 值 | 说明 / Flutter 映射 |
|---|---|---|
| `--primary` | `#2F6B3B` | 主色，AppColors.primary |
| `--primary-dark` | `#244F2D` | 主色深（tabbar 底） |
| `--primary-soft` | `#E3F0E4` | 主色浅底，AppColors.primarySoft |
| `--accent` | `#8BA95A` | 强调色，AppColors.accent |
| `--surface` | `#F8F6F0` | 页面背景，AppColors.surface |
| `--surface-alt` | `#FFFFFF` | 卡片背景 |
| `--border` | `#D7D2C6` | 描边，AppColors.border |
| `--text-primary` | `#263126` | 主文本 |
| `--text-secondary` | `#617061` | 次文本，AppColors.textSecondary |
| `--success` | `#4C9A5F` | 语义色 |
| `--warning` | `#D28A2D` | 语义色 |
| `--danger` | `#C2564B` | 语义色 |
| `--info` | `#4A7F9D` | 语义色 |
| `--c-static` | `#2563EB` | 检验类型色·静态（现有） |
| `--c-dynamic` | `#D97706` | 检验类型色·动态（现有） |
| `--c-traj` | `#7C3AED` | 检验类型色·轨迹（现有，NIX-22） |
| **`--c-line`** | **`#0F766E`** | **检验类型色·线路（本期新增，青绿）** |
| `--grade-ex` | `#16A34A` | 分级 EXCELLENT（对齐前端 _GradeBadge `comparison_tab.dart:390`） |
| `--grade-us` | `#2563EB` | 分级 USABLE |
| `--grade-mg` | `#C2410C` | 分级 MARGINAL（前端为 #B45309，以令牌为准统一） |
| `--grade-un` | `#DC2626` | 分级 UNAVAILABLE |
| `--xs/--sm/--md/--lg/--xl` | `4/8/12/16/24px` | 间距阶梯，AppSpacing |
| `--r-sm/--r-md/--r-lg` | `4/8/12px` | 圆角阶梯 |
| `--shadow-sm/md/lg` | `0 1px 3px .08` / `0 2px 8px .15` / `0 20px 60px .2` | 阴影阶梯 |
| `--fs-xs/sm/md/lg/xl/num` | `10/12/13/14/18/22px` | 字号阶梯 |

### 9.2 组件视觉规格（本期新增/改动件）

| 组件 | 规格 |
|---|---|
| 类型标记「线路」 | `.td-line`：底 `rgba(15,118,110,.1)`、字 `--c-line`、6px 圆点；时间轴「线」段实底 `--c-line` 白字 |
| 状态徽章 | 候选 `.t-cand`（#F1F5F9/#475569）；已选定 `.t-sel`（#CCFBF1/#0F766E，带 ★） |
| 分级徽章 | `.grade`：12px 圆角、0.5px 描边、四色见令牌表 |
| 指标 chip | `.stat-chip`：`--surface` 底 + `--border` 描边 + `--r-md`，数值 19px/700，标签 `--fs-xs` 次文本色 |
| 三分类页签 | `.subtab`：999px 圆角胶囊，选中态 `--primary` 实底白字，计数 `.cnt` 半透明底 |
| 对比设备 chip | `.dev-chip`：999px 圆角 + 9px 轨迹色圆点 + mono 设备号 |
| 变更标注 | `.anno`（17px 青绿圆点序号）/ `.anno-region`（2px 青绿虚线框）/ `.anno-panel`（青绿渐变说明条）——仅原型用，不落地 |
| 地图 | 标准线：绿 `#2F6B3B` 实线 3.5px；设备轨迹：红 `#C2564B` 虚线 2px + 2.4px 点；源轨迹：灰 `#9CA3AF/#B6BCC4`；max 偏差：`--warning` 虚线圈 |

---

## 10. 实现边界（本期不含）

| 不做 | 理由 |
|---|---|
| 候选合成算法（勾选 ≥2 条合成新线） | 二期实现；本期只做入口、勾选交互与提示弹窗（D3）；分期理由见 §1.4 范围声明 |
| 轨迹方向校验（顺/逆行） | 点到线距离不涉方向；方向异常暂靠人工地图判读 |
| 多格式导入识别（CSV/KML/GPX 等） | 决策只支持 RTK 手簿 XLSX 版式（D5），避免无需求的格式矩阵 |
| 修改 STATIC / DYNAMIC / TRAJECTORY 任何逻辑 | §3 继承关系：三类报告面板、分派、API、分级零改动 |
| 标准轨迹编辑（删点/截断） | 追加式模型下用"重新导入 + 删除旧候选"覆盖 |
| gps_logs 写路径任何改动 | 只读查询；不回写（同 NIX-22 D11 精神） |

---

## 11. 验收标准

- [ ] Flyway 迁移成功：`chk_test_type_truth` 允许 LINE；4 张新表建成（含 UNIQUE/CHECK/索引）；`V20260728140000` 后 `gps_quality_line_results` 含 trip_count（存量回填 0）；既有三类检验回归无变化
- [ ] 导入：仓库根目录 3 个真实样例文件依次导入 → 3 条独立候选：自动追踪_20260728153839（430 点 · 1177m）、自动追踪_20260728155125（387 点 · 1192m）、自动追踪_20260728155954（406 点 · 1192m），**点数/全长与坐标实算一致**（容差 ±1m）；元数据脏值（开始=结束、长度=0、`2026=07-28`）不阻断
- [ ] 追加式：同一文件再次导入 → 新增第 4 条候选而非覆盖；删除任一候选不影响其余
- [ ] parse 预览：原始点数/去重后/去除数/实算全长/起终点/前 8 点，与原型第 2 步一致；点级无效行跳过计数
- [ ] 发起：`/line-checks/devices` 不传时间参数即返回所有有 gps_logs 的设备（含总点数与首末时间）；POST `/line-checks`（无 start/end）后每设备生成一条 READY 的 LINE test，且 `gps_quality_line_points` 快照点列与标准轨迹一致；完全无 gps_logs 的设备返回 testId=null / sampleCount=0 / UNAVAILABLE 且不建 test
- [ ] 报告：`/tests/{id}/line-report` 输出统计摘要（mean/p50/p95/max、15/25/40m 占比、样本数、趟数 tripCount、trackLineId/trackLineName）；`/tests/{id}/line-report/track` 返回标准轨迹点列快照，`/tests/{id}/line-report/deviations` 返回逐点偏差（仅有效段内点，含 segment_no，`limit` 限量生效）；分级符合 D10（p95≤15 且 samples≥10 → EXCELLENT）；删除该检验所用候选线路后报告仍可完整打开（快照生效，track_line_id 置空）
- [ ] 前端：真值管理三页签；标准轨迹表格/导入向导/地图预览/合成入口交互与原型一致；检验列表出现青绿「线路」标记与「线」时间轴段；统一报告区 4 行展示且「查看报告」进入对应类型报告；LINE 报告内联展示指标卡（含趟数与口径说明条）+地图+明细表
- [ ] 质量对比：第 4 段「线路」无需选择时间范围，选轨迹即加载（该线路下每设备最新一条 READY），展示同图叠加地图（绿标准线+多设备多色）与对比表（含趟数列）；前三段回归无变化
- [ ] `TrackLineCalculator` 单测：点到线段（垂足内/外）、多点折线取 min、走廊接近标记（100m 边界）、间隔切段（≤300s 同段 / >300s 切段）、孤段丢弃（<4 点）、多趟合并与 tripCount 计数、无有效段 → sampleCount=0/UNAVAILABLE、percentile 退化规则、分级边界（p95=15.0 恰等阈值 → EXCELLENT）
- [ ] 后端 `./gradlew compileJava` + 前端 `flutter build web` 通过；`flutter gen-l10n` 无缺失 key，中英 arb 对齐
- [ ] dev 部署后 curl 验证：track-lines parse/import、line-checks devices/发起、line-report（含 track/deviations 子端点）、comparison/line（含 deviceCode 按需加载）、checks/summary 各端点返回正确

---

## 12. 修订记录

### 2026-07-28 评审核实处置修订

按评审文件 `docs/superpowers/reviews/2026-07-28-nix68-track-line-inspection-spec-review.md` 的 7 项发现逐条核实，处置方案经用户批准后修订：

| 编号 | 处置 | 说明 |
|---|---|---|
| F1 | **采纳**（确认为分期决策） | 新增 §1.4 范围声明：本期手动选定、二期自动合成的分期已在 2026-07-28 与用户对话确认，非静默降级；§10 合成条目同步标注 |
| F2 | **降级**（补负载估算，不上异步） | §6.5 补最坏场景估算：2300 万次投影为纯算术（秒级）+ 约 5.4 万行批量 INSERT，总耗时 <10s，同步 READY 可接受，本期不引入 DEVICE_PENDING 流程 |
| F3 | **采纳** | §7.4 报告端点拆分：主端点只返回统计摘要，新增 `/line-report/track` 与 `/line-report/deviations?limit=` 子端点；§7.6 `/comparison/line` 设备轨迹点按 `deviceCode` 逐个按需加载；§8.5/§8.6/§11 同步 |
| F4 | **采纳** | §6.1 补 `GpsQualityTest.java` 实体改动声明（trackLineId 字段 + getter/setter、新增含 trackLineId 的构造器、Javadoc 覆盖 LINE） |
| F5 | **采纳** | §6.1 迁移补 `idx_gqt_device_type_time`、`idx_gqt_track_line` 两条索引；§6.6 迁移清单同步 |
| F6 | **驳回** | 经核实 `TestType.java` 枚举值实际在第 9-11 行，评审声称的"12-14 行"不存在；spec 中 `TestType.java:7-11` 引用保持原样 |
| F7 | **采纳** | §4.2 第 1 步显式标注"逐行 trim（兼容 \r\n）" |

另：评审"已核实正确的引用"一节对 percentile/haversine 行号的"修正"（称实际为 149-160 / 168-176）经核实不成立，spec 原引用 `TrajectoryPairingService.java:145-156`、`:162-170` 保持不动。

### 2026-07-28 dev 集成测试修复

| 编号 | 处置 | 说明 |
|---|---|---|
| I1 | **修复** | §6.1 CHECK 约束缺陷：LINE 分支原要求 `track_line_id IS NOT NULL`，与 FK `ON DELETE SET NULL` 自相矛盾，删除候选必然违反约束（dev 实测 `chk_test_type_truth` violation）。新增迁移 `V20260728130000__nix68_line_check_allow_null_track_line.sql` 放开 LINE 分支非空要求；track_line_id 定位为候选存活期间的活引用，真值由快照承载 |
| I2 | **修复** | `/comparison/line` 时间窗口径：原实现"test.startedAt 落在查询窗内"，test 环境实测用户查询窗（08:35 起）晚于检验起点（08:02）时 22 条 LINE 检验全部漏掉。改为窗口相交（`startedAt <= end AND endedAt >= start`），§7.6 已注明（该口径后被 I3 废止） |
| I3 | **变更** | **空间匹配取代时间匹配**（用户 2026-07-28 拍板）：时间范围从端点与 UI 完全去掉、同一设备多趟合成一次检验、连续接近线路的轨迹段为有效样本。算法三常量：`CORRIDOR_METERS=100`（走廊阈值，须 > 40m 分级带宽上限，否则 UNAVAILABLE 设备进不了样本）、`GAP_SECONDS=300`（容忍 LoRaWAN 丢点）、`MIN_SEGMENT_POINTS=4`（去孤点噪声）；时间只用于切段，不进入偏差计算（§5.2）。端点去时间参数：`/line-checks/devices`、`POST /line-checks`、`/comparison/line`（对比口径改为该线路下每设备最新一条 READY，I2 窗口相交口径随之废止）。新增迁移 `V20260728140000__nix68_line_trip_count.sql` 补 trip_count（存量回填 0）。既有 22 条时间窗时代的 LINE 检验保留混排，不追溯重算 |
| I4 | **新增 + 修复** | **质量对比 LINE 段导出 CSV**（2026-07-28 用户追加需求）：前端由已加载的对比表数据直接生成 UTF-8(BOM) CSV 下载（列=设备/样本数/趟数/mean/P50/P95/max/≤15m/≤25m/≤40m 占比/分级，文件名 `line-comparison-yyyyMMdd-HHmmss.csv`），不动后端，§8.6 同步。同批修复：发起检验后 `lineComparisonProvider` 未失效导致对比页缓存不刷新（`line_check_create_dialog.dart` 发起成功后补 `ref.invalidate(lineComparisonProvider)`） |

---

## 13. 引用

- 原型：`docs/marketing/nix-68-track-line-inspection-prototype.html`（v3，已确认）
- 真实样例：仓库根目录 `轨迹检验线路1/2/3.xlsx`（解析统计见 §4.4）
- NIX-22 轨迹导入：`docs/superpowers/specs/2026-07-22-nix22-rtk-trajectory-import-spec.md`
- NIX-20 动态检验：`docs/superpowers/specs/2026-07-16-nix20-gps-dynamic-quality-spec.md`
- NIX-21 批量导入重构：`docs/superpowers/specs/2026-07-18-nix21-batch-import-and-quality-check-refactor.md`
