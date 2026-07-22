# NIX-22 RTK 轨迹导入动态检验 — 方案设计文档

| 字段 | 值 |
|---|---|
| 工单 | NIX-22（暂定编号）动态检验数据获取方式改进：RTK 随行轨迹导入 |
| 优先级 | High |
| 类型 | 功能增强（Improvement） |
| 前置依赖 | NIX-20 动态检验（路线驱动，已实施）、NIX-21 批量导入重构（已实施） |
| 设计日期 | 2026-07-22 |
| 状态 | 待评审 |
| 原型 | `docs/marketing/nix-22-rtk-trajectory-import-prototype.html`（v2，已确认） |

---

## 1. 背景与目标

### 1.1 现状痛点

NIX-20 实现的动态检验是**路线驱动**的：测试人员须编排运动节奏，使设备 30 分钟一次的稀疏上报**恰好物理落在某个固定 RTK 真值点附近（≤5m）**。该方式对测试执行要求极高，动态数据获取困难。

### 1.2 新的采集方式（用户提供）

测试人员携带 RTK 设备与被检追踪器**一起移动**，在设备上报数据时记录当时 RTK 设备读出的经纬度，形成如下格式的数据文件：

| 设备EUI | 采集时间 | RTK纬度 | RTK经度 | 设备纬度（可选） | 设备经度（可选） |
|---|---|---|---|---|---|

这把动态检验从「空间匹配（是否经过固定点）」变为「**时间配对（上报时刻的真值对比）**」——每次设备上报都是有效样本，与身处何地无关，彻底摆脱"恰好经过真值点"的编排负担。这正是测绘行业标准的移动基线验证法。

### 1.3 与现有功能的关系（两条动态检验路径并存）

| | 路线动态（NIX-20，现有） | 轨迹动态（NIX-22，本期） |
|---|---|---|
| 真值来源 | 33 个固定 RTK 真值点的有序路线 | 随行 RTK 轨迹文件（随导入产生） |
| 匹配方式 | 空间匹配：上报点距真值点 ≤30m 算经过 | 时间配对：上报时刻 ↔ 同时刻 RTK 读数 |
| 适用场景 | 标准巡回路线、反复使用 | 任意路径的外场检验 |
| 前置编排 | 需要（节奏编排） | 不需要 |

两种方式**并存**，不互相替代。本设计不改动路线动态的任何逻辑。

### 1.4 设计目标

- **G1**：支持从文件（CSV/Excel）按固定 6 列格式导入轨迹检验数据
- **G2**：设备经纬度列（E/F）可选；缺省时系统按「设备EUI + 采集时间」从 `gps_logs` 自动配对，配对结果**导入时固化**（快照），报告读取已配对数据
- **G3**：一次导入按设备 EUI 自动分组，每台设备生成一条 TRAJECTORY 检验会话（多台被检设备同行只需导入一次）
- **G4**：复用 `gps_quality_tests` 统一会话表与检验列表 UI，新增第三种检验类型 TRAJECTORY，界面集成关系与已确认原型 v2 一致（§7）
- **G5**：轨迹动态报告产出绝对精度评估（误差分布 + 逐样本明细 + 静动态对比），计入质量对比 Tab 的「动态」一侧

---

## 2. 核心设计决策（与原型确认记录对应）

| # | 决策 | 说明 |
|---|---|---|
| D1 | **新增检验类型 TRAJECTORY** | 复用 `gps_quality_tests` 表，扩展 CHECK 约束允许 `test_type='TRAJECTORY'`（rtk_point_id / route_id 均空）。会话时间窗 = 该设备轨迹点采集时间的 min/max，由文件推导，无需用户填写 |
| D2 | **配对在导入时完成并固化** | 配对结果（设备坐标、来源、时间差）快照存入新表 `gps_quality_track_points`；报告仅读取快照做统计聚合，不再回查 `gps_logs`。理由：gps_logs 可能被清理；导入时刻数据最完整；报告结果可复现 |
| D3 | **配对时间容差默认 ±60 秒，可调** | 库内配对取该 EUI 在 gps_logs 中距采集时间最近的一条上报，超出容差记为「未配对」。容差在导入预览步可调，并随会话持久化 |
| D4 | **时钟基准** | 文件中「采集时间」按 Asia/Shanghai（UTC+8）本地时间解析为 Instant，与 `gps_logs.recorded_at` 保持同一基准（遵循经验教训 #17：不做时区猜测，两端同一基准） |
| D5 | **未配对样本保留但不参与统计** | 未配对轨迹点仍入库（match_source=UNPAIRED），在报告中单独列出，不计入误差分布与分级 |
| D6 | **E/F 列必须同时填或同时空** | 只填一个坐标属于行格式错误，校验失败 |
| D7 | **去重策略** | 同一 EUI 已存在 (started_at, ended_at) 完全相同的 TRAJECTORY 检验 → 该设备跳过并在导入结果中标注「已存在，跳过」（沿用 NIX-21「同 EUI + 同时段只一条检验」的思路） |
| D8 | **轨迹动态只由文件导入产生** | 「新建检验」「批量导入会话」两个现有入口不变，仍只创建 STATIC / DYNAMIC；轨迹导入是左栏工具条第三个独立入口（🛰） |
| D9 | **评级阈值对齐静态档 + 配对率约束** | 轨迹动态样本是"每次上报一次真值对比"，密度与代表性优于路线动态，采用与静态相同的误差档位（§6.3），使原型示例（P95=12.4m → EXCELLENT）成立。阈值为初版建议值，部署后用真实数据校准 |
| D10 | **质量对比 Tab 数据源扩展** | 真实 Tab 3 结构为「静态（按真值点）/ 动态（按路线）」分段切换，无逐设备静动态对照表。最小一致改法：分段切换器新增第三段「轨迹」，展示各设备最近一次 TRAJECTORY 检验的对比表（新端点 `/comparison/trajectory`）；静态/动态两段逻辑与界面不变 |
| D11 | **导入的设备坐标不回写 gps_logs** | 文件中 E/F 列的设备坐标仅用于本次检验配对，快照存 `gps_quality_track_points`（D2）后即完成使命。不回写理由：① gps_logs 无 source 来源标记，回写会污染围栏告警/轨迹/健康等真实遥测消费链路（经验判据 #11）；② `DataRetentionService` 会定期清理 gps_logs，回写拷贝无长期价值；③ gps_logs 无 (device_id, recorded_at) 唯一约束，blade 管道补传后会产生重复行。"把缺失设备数据补进主数据湖"属于数据修复功能，如需应单独设计（source 标记 + 去重 + 告警豁免），不在本期范围 |

---

## 3. 文件格式

### 3.1 列定义（列顺序固定，表头可省略，自动检测）

| 列 | 字段 | 必填 | 校验规则 |
|---|---|---|---|
| A | 设备 EUI | 必填 | 非空；须在 `devices` 表存在（按 device_code 匹配），否则行校验失败「EUI 未注册」 |
| B | 采集时间 | 必填 | 支持 `yyyy-MM-dd HH:mm:ss` / `yyyy-MM-dd HH:mm` / ISO-8601；按 UTC+8 解析；解析失败记「时间格式错误」 |
| C | RTK 纬度 | 必填 | -90~90 十进制度 |
| D | RTK 经度 | 必填 | -180~180 十进制度 |
| E | 设备纬度 | 可选 | 与 F 同时填或同时空（D6）；填则 -90~90 |
| F | 设备经度 | 可选 | 填则 -180~180 |

### 3.2 文件约束

- 支持 `.csv`（UTF-8）/ `.xlsx`，单次最多 **5000 行**
- 表头自动检测：首行 A 列非 EUI 形态（不含十六进制 EUI 特征）且 C/D 列非数值 → 视为表头跳过
- 行级校验失败不影响其他行：失败行在预览中标红并跳过（与 NIX-21 批量导入一致）
- 提供模板下载（CSV，含一行示例）

---

## 4. 配对算法

### 4.1 单行配对规则

```
输入：行 (eui, collectedAt, rtkLat, rtkLng, devLat?, devLng?)，容差 T（秒，默认 60）

if devLat/devLng 均填写:
    matchSource = FILE
    deviceLat/Lng = 文件值
    timeDiffSec = 0
else:
    device = devices.findByDeviceCode(eui)          # 行校验已保证存在
    log = gps_logs 中 device_id = device.id
          且 |recorded_at - collectedAt| ≤ T
          距 collectedAt 最近的一条
    if log 存在:
        matchSource = GPS_LOG
        deviceLat/Lng = log.latitude/longitude（快照）
        matchedGpsLogId = log.id
        timeDiffSec = |log.recorded_at - collectedAt|
    else:
        matchSource = UNPAIRED

误差 error = haversine(rtk, device)   # 仅 FILE / GPS_LOG 样本参与统计
```

### 4.2 边界规则

| 场景 | 规则 |
|---|---|
| 两条 gps_log 与采集时间等距 | 取较早的一条（确定性，便于测试） |
| 同一条 gps_log 被多个轨迹点匹配 | 允许（30min 上报间隔下极少发生）；不额外标记 |
| 同一文件内重复行（同 EUI + 同采集时间） | 保留先出现的行，后续行记校验失败「重复行」 |
| 采集时间超出 gps_logs 任何数据范围 | UNPAIRED（不报错） |

### 4.3 配对执行时机

- **预览（parse）**：执行完整配对，返回每行的 matchMode 与匹配到的 gps_log（含时间差），供用户核对
- **导入（import）**：重新执行配对并**持久化快照**（D2）。预览与导入使用同一文件 + 同一容差时结果一致

---

## 5. 数据模型

### 5.1 `gps_quality_tests` 扩展（CHECK 约束）

`test_type` 列为 VARCHAR(10)，`'TRAJECTORY'` 恰好 10 字符，无需改列宽。仅需更新 CHECK 约束：

```sql
ALTER TABLE gps_quality_tests DROP CONSTRAINT chk_test_type_truth;
ALTER TABLE gps_quality_tests ADD CONSTRAINT chk_test_type_truth CHECK (
    (test_type = 'STATIC'     AND rtk_point_id IS NOT NULL AND route_id IS NULL) OR
    (test_type = 'DYNAMIC'    AND route_id IS NOT NULL AND rtk_point_id IS NULL) OR
    (test_type = 'TRAJECTORY' AND rtk_point_id IS NULL AND route_id IS NULL)
);
```

TRAJECTORY 会话字段填充规则：

| 字段 | 值 |
|---|---|
| device_code / device_id | 文件 A 列 EUI / 解析出的设备 id |
| test_type | TRAJECTORY |
| rtk_point_id / route_id | NULL |
| started_at / ended_at | 该设备轨迹点 collected_at 的 min / max |
| status | READY（导入即完成，无 DEVICE_PENDING 流程——EUI 必须已注册，否则行级失败） |
| note | 导入文件名 + 容差（如 `rtk_walk_0721.csv · ±60s`），供列表/报告展示来源 |

### 5.2 新表 `gps_quality_track_points`

```sql
CREATE TABLE gps_quality_track_points (
    id BIGSERIAL PRIMARY KEY,
    test_id BIGINT NOT NULL REFERENCES gps_quality_tests(id) ON DELETE CASCADE,
    sequence_no INTEGER NOT NULL,                    -- 文件内行序（每设备内从 1 开始）
    collected_at TIMESTAMPTZ NOT NULL,               -- 采集时间（UTC+8 解析后的 Instant）
    rtk_latitude NUMERIC(10,7) NOT NULL,
    rtk_longitude NUMERIC(10,7) NOT NULL,
    device_latitude NUMERIC(10,7),                   -- 配对快照（FILE=文件值 / GPS_LOG=gps_logs 值）
    device_longitude NUMERIC(10,7),
    match_source VARCHAR(10) NOT NULL,               -- FILE / GPS_LOG / UNPAIRED
    matched_gps_log_id BIGINT,                          -- 普通引用，不加 FK：DataRetentionService 会清理旧 gps_logs，快照（D2）必须不受其生命周期牵制
    time_diff_seconds INTEGER,                       -- GPS_LOG 配对的时间差；FILE=0
    tolerance_seconds INTEGER NOT NULL DEFAULT 60,   -- 导入时使用的容差（随快照固化）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (test_id, sequence_no),
    CONSTRAINT chk_track_match CHECK (
        (match_source IN ('FILE','GPS_LOG')
            AND device_latitude IS NOT NULL AND device_longitude IS NOT NULL) OR
        (match_source = 'UNPAIRED'
            AND device_latitude IS NULL AND device_longitude IS NULL)
    )
);
CREATE INDEX idx_gtp_test ON gps_quality_track_points(test_id, sequence_no);
```

设计要点：
- `ON DELETE CASCADE`：删除检验（现有删除入口）时连带删除轨迹点，前端删除逻辑零改动
- 设备坐标双列快照（D2）：即使 gps_logs 后续被清理，报告仍可复现
- `tolerance_seconds` 固化在点上，报告展示"配对时间窗 ±Ns"与导入时一致

### 5.3 报告不持久化

与静态/路线动态一致：报告在请求时基于 `gps_quality_track_points` 快照实时聚合（均值/分位数/分级/静动态对比），不存报告表。

### 5.4 迁移命名

`V20260722100000__nix22_trajectory_track_points.sql`：更新 CHECK 约束 + 建 `gps_quality_track_points` 表。**无种子数据**——轨迹数据来自用户导入（§AGENTS 7.2：新表不产生需验证的种子规则，演示数据由部署后真实导入产生）。

---

## 6. API 设计

在现有 `GpsQualityAdminController`（`/api/v1/admin/gps-quality`，PLATFORM_ADMIN）下新增 4 个端点；列表/删除等现有端点零改动（TRAJECTORY 随 testType 自然流过）。

### 6.1 新增端点

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/trajectory/template` | 下载 CSV 导入模板（含表头 + 1 行示例） |
| POST | `/trajectory/parse` | multipart 上传文件 + `toleranceSec`（默认 60）→ 解析 + 行级校验 + 完整配对预览（§4.3），**不落库** |
| POST | `/trajectory/import` | multipart 上传文件 + `toleranceSec` → 按设备分组创建 TRAJECTORY 检验 + 轨迹点快照，返回逐设备结果 |
| GET | `/tests/{id}/trajectory-report` | 轨迹动态报告（testType=TRAJECTORY，否则 400） |

命名对齐现有 `/batch/parse`、`/batch/import` 两步式；`/tests/{id}/report`、`/tests/{id}/dynamic-report` 之后新增第三个报告端点，前端按 testType 分派调用。

### 6.2 parse 响应 DTO

```java
public class TrajectoryParseResultDto {
    int totalRows;            // 总行数（不含表头）
    int validRows;            // 校验通过
    int invalidRows;          // 校验失败（跳过）
    int deviceCount;          // 涉及设备数
    int filePaired;           // 文件内直接配对数
    int logPaired;            // 库内配对成功数
    int unpaired;             // 库内配对失败数
    List<Row> rows;

    public class Row {
        int rowNo;
        String deviceEui;
        Instant collectedAt;
        BigDecimal rtkLatitude, rtkLongitude;
        BigDecimal deviceLatitude, deviceLongitude;   // 文件值，可空
        String matchMode;     // FILE / GPS_LOG / UNPAIRED / INVALID
        String error;         // INVALID 时的原因：EUI 未注册 / 时间格式错误 / 坐标越界 / E-F 列不成对 / 重复行
        // GPS_LOG 配对信息（预览核对用）
        Instant matchedRecordedAt;
        Integer timeDiffSec;
    }
}
```

### 6.3 import 响应 DTO

```java
public class TrajectoryImportResultDto {
    int createdCount;         // 新建检验数
    int skippedCount;         // 跳过设备数（重复）
    List<DeviceResult> devices;

    public class DeviceResult {
        String deviceEui;
        Long testId;            // 新建检验 id（跳过时为已存在检验 id）
        String status;          // CREATED / SKIPPED_DUPLICATE
        int totalPoints, filePaired, logPaired, unpaired;
    }
}
```

### 6.4 报告 DTO（与原型报告视图一一对应）

```java
public class TrajectoryQualityReportDto {
    Long testId;
    String deviceCode;
    Instant startedAt, endedAt;
    int toleranceSec;
    QualityGrade grade;
    // 配对概览
    int totalPoints;          // 轨迹样本点
    int filePaired;           // 文件内直接配对
    int logPaired;            // gps_logs 库内配对
    int unpaired;             // 未配对
    double pairRate;          // (filePaired+logPaired)/totalPoints*100
    // 绝对精度（仅 FILE+GPS_LOG 样本）
    double meanError, p50, p95, maxError;
    // 逐样本明细（含未配对，按 collectedAt 升序）
    List<TrackPoint> points;  // {sequenceNo, collectedAt, rtkLat, rtkLng, deviceLat, deviceLng, error, matchSource, timeDiffSec}
    // 静态对比（同设备最近一次 STATIC 检验报告）
    StaticComparison staticComparison;  // {staticP95, staticGrade, deltaP95}，无静态检验时为 null
}
```

### 6.5 分级规则（D9，对齐静态档 + 配对率约束）

| Grade | 条件 | 最小样本 |
|---|---|---|
| EXCELLENT | p95 ≤ 15m 且 pairRate ≥ 80% | paired ≥ 10 |
| USABLE | p95 ≤ 25m 且 pairRate ≥ 60% | paired ≥ 6 |
| MARGINAL | p95 ≤ 40m | paired ≥ 4 |
| UNAVAILABLE | 其他 | paired < 4 |

复用 `QualityGrade` 枚举；新增独立方法 `determineTrajectoryGrade()`，不改动静态/路线动态分级。分位数退化规则沿用现有约定（<5 点 p50 用 max；<20 点 p95 用 max）。

---

## 7. 前端设计（与原型 v2 的 ①~⑥ 变更点一一对应）

> 基准文件：`Mobile/mobile_app/lib/features/admin/gps_quality/`。页面结构（3 Tab）不变，改动集中在 Tab 1。

### 7.1 Tab 1 检验列表（`quality_check_list.dart`）

| 原型标注 | 改动 |
|---|---|
| ① 左栏工具条 | 在 `create-check-btn`、`batch-import-btn` 后新增 `trajectory-import-btn`（`Icons.satellite_alt`，tooltip=导入 RTK 轨迹数据），打开 `TrajectoryImportDialog` |
| ② 设备分组行 | 新增第三种类型标记：`checkType == 'TRAJECTORY'` → 紫色 `Color(0xFF7C3AED)`，文案 `l10n.gpsQualityTrajectoryChecks`（轨迹） |
| ③ 检验时间轴 | 新增紫色「轨」段：TRAJECTORY → `Color(0xFF7C3AED)` + 字符「轨」；tooltip 显示类型+时间窗（复用现有 tooltip 逻辑） |
| ④ 报告区分派 | `_buildReport` 按 testType 分派：STATIC→散布图（现状）、DYNAMIC→路线匹配（现状）、TRAJECTORY→新增 `TrajectoryReportPanel` |

### 7.2 新增 `trajectory_import_dialog.dart`（3 步向导）

模式复刻 `batch_import_dialog.dart` 的 stepper 结构：

1. **上传文件**：拖放/选择 + 模板下载 + 6 列格式说明表（含 E/F「可选，留空则库内配对」提示）+ 时钟基准提示（UTC+8）
2. **校验与配对预览**：统计条（总行数/通过/失败/设备数/文件配对/待库内配对）+ 容差设置（默认 ±60s 可调，调整后重新 parse）+ 行级明细表（配对方式列：文件/库内配对/未配对/失败原因标红）
3. **导入结果**：逐设备卡片（EUI、点数、文件/库内/未配对分布、会话已创建/已存在跳过），完成后刷新 `checksProvider`

### 7.3 新增 `trajectory_report_panel.dart`（报告区）

自上而下（与原型一致）：

1. **标题行**：轨迹动态检验报告 + 类型标记 + Grade 徽章 + 文件名/时间窗（note + startedAt~endedAt）
2. **配对概览 chips**：样本点 / 文件配对 / 库内配对 / 未配对 / 配对率 / 平均误差 / P50 / P95 / 最大误差
3. **轨迹对比图**：扩展 `route_match_chart.dart` 绘制 RTK 真值轨迹（实线）+ 设备上报轨迹（虚线）+ 配对连线 + 未配对点标记
4. **误差分布直方图** + 静动态对比结论卡（staticComparison 为 null 时显示「无静态检验数据」）
5. **逐样本明细表**：# / 采集时间 / RTK 经纬度 / 设备经纬度 / 误差 / 数据来源（文件·库内）；末尾单独列出未配对样本

### 7.4 Tab 2 真值基准（⑥ 完全不变）

不改代码。轨迹真值随会话存储，不占用固定真值点与路线。

### 7.5 Tab 3 质量对比（⑤ 数据源扩展）

- 后端新增 `GET /comparison/trajectory`：每台设备取最近一次 READY 的 TRAJECTORY 检验，返回 {testId, deviceId, deviceCode, totalPoints, paired, pairRate, meanError, p50, p95, grade, startedAt, endedAt} 列表
- 前端 `comparison_tab.dart`：`SegmentedButton` 由 2 段（静态/动态）扩为 3 段（静态/动态/轨迹），选中「轨迹」时展示上述对比表；静态/动态两段不变

> 注：原型中"逐设备静态 P95 vs 动态 P95 对照表"为示意图，真实 Tab 3 无此表；按真实 UI 结构改为第三段「轨迹」对比，与原型 ⑤ 的意图（轨迹数据进入对比视图）一致。

### 7.6 i18n

新增 key 同步写入 `app_zh.arb` / `app_en.arb`，前缀 `gpsQualityTrajectory*`：
- `gpsQualityTrajectoryImport`（导入 RTK 轨迹数据）
- `gpsQualityTrajectoryChecks`（轨迹）
- `gpsQualityTrajectoryReport`（轨迹动态检验报告）
- `gpsQualityPairRate` / `gpsQualityFilePaired` / `gpsQualityLogPaired` / `gpsQualityUnpaired` / `gpsQualityPairTolerance` 等
- 既有 `gpsQualityTestTypeStatic/Dynamic` 不变

---

## 8. 实现边界（本期不含）

| 不做 | 理由 |
|---|---|
| RTK 设备实时对接/自动上传 | 文件导入已满足当前外场流程；实时接入成本高 |
| RTK 轨迹插值（1Hz 真值轨迹上插值上报时刻位置） | 当前采集方式即"上报时刻记一次 RTK 读数"，无需插值；未来若 RTK 连续记录再扩展 |
| 轨迹动态检验的手动创建入口 | D8：只由文件导入产生，避免无真值数据的空会话 |
| 速度/航向等运动学指标 | 30 分钟间隔下意义有限（沿用 NIX-20 结论） |
| 导入设备坐标回写 gps_logs | D11：检验数据与真实遥测语义不同，回写会污染围栏/轨迹/健康链路；数据修复属独立功能 |
| 轨迹文件版本管理/重新配对 | 报告基于导入时快照（D2）；重新配对 = 删除检验后重新导入 |
| 修改路线动态（NIX-20）任何逻辑 | 两种方式并存（§1.3） |

---

## 9. 验收标准

- [ ] Flyway 迁移成功：`chk_test_type_truth` 允许 TRAJECTORY；`gps_quality_track_points` 建表（含 CHECK/UNIQUE/索引）
- [ ] 模板下载返回合法 CSV；CSV 与 XLSX 均可解析；表头自动检测正确
- [ ] parse 预览：E/F 填写的行标 FILE；留空的行按 ±60s 从 gps_logs 配对（标 GPS_LOG + 时间差）；超容差标 UNPAIRED；EUI 未注册/时间格式错误/E-F 不成对/重复行标 INVALID 并跳过
- [ ] import：按设备分组创建 TRAJECTORY 检验（started_at/ended_at = 采集时间 min/max）；同 EUI 同时段重复导入标记 SKIPPED_DUPLICATE
- [ ] 报告端点：配对概览（样本/文件/库内/未配对/配对率）、误差分布（mean/p50/p95/max）、逐样本明细（含来源）、静动态对比，与原型一致；未配对样本不参与统计
- [ ] 分级：P95 ≤15m 且配对率 ≥80% 且配对 ≥10 → EXCELLENT（原型示例 12.4m/87.5%/21 对 → EXCELLENT 成立）
- [ ] 前端：左栏新增 🛰 入口；设备分组/时间轴出现紫色「轨迹/轨」；点击轨段展示配对报告；删除检验级联删除轨迹点
- [ ] 质量对比 Tab：轨迹动态计入动态侧并标注来源
- [ ] 路线动态（NIX-20）与静态检验功能回归无变化
- [ ] 后端 `./gradlew compileJava` + 前端 `flutter build web` 通过；中英文 i18n 完整
- [ ] dev 部署后 curl 验证：template 下载、parse、import、trajectory-report 四端点返回正确

---

## 10. 引用

- 原型：`docs/marketing/nix-22-rtk-trajectory-import-prototype.html`（v2，含界面关系总览）
- NIX-20 动态检验：`docs/superpowers/specs/2026-07-16-nix20-gps-dynamic-quality-spec.md`
- NIX-21 批量导入重构：`docs/superpowers/specs/2026-07-18-nix21-batch-import-and-quality-check-refactor.md`
