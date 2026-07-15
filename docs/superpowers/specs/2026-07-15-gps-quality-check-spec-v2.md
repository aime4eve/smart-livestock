# GPS 数据质量检查功能设计规格 v2 (NIX-15)

> **v2 变更**：根据评审意见核实修正 + 补充用户旅程设计  
> v1 位置：`docs/superpowers/specs/2026-07-15-gps-quality-check-spec.md`  
> 评审位置：`docs/superpowers/reviews/2026-07-15-gps-quality-check-spec-review.md`

---

## 0. 评审意见核实结论

### 评审事实性核查汇总

| 编号 | 评审论断 | 核查结论 | 修正 |
|------|---------|---------|------|
| B1 | "两个表都是 TIMESTAMP（无时区）" | **❌ 错误**：`gps_logs.recorded_at` 已被 V20260710160000 修正为 `TIMESTAMPTZ`。但两表类型不一致不影响 JOIN——`AgenticPlatformReportData.parseReportTime()` 用 `toInstant(ZoneOffset.UTC)`（经验判据 #17），同一个 Instant 写入两表，字面值一致，99.4% 匹配 | 不是 bug，见 §13 |
| B2 | "两表独立写入，毫秒精度差异导致 JOIN miss" | **❌ 错误**：同一个 `Instant effectiveRecordedAt` 在同一事务中写两个表，不存在独立写入差异。0.6% miss 是数据层面的边缘情况，非类型问题 | 不是 bug，见 §13 |
| B3 | "P99 在 N=20 时退化" | **✅ 数学正确**：N=20 时 P99 ≈ 第 19.8 个值 ≈ 最大值，P99 分量失效。但 `max(P99, 3×P95, 30m)` 的 fallback 机制仍有效 | §4 补充 |
| B4 | "样本点数定义不明确" | **✅ 正确**：spec 未区分 totalPoints 和 effectivePoints | §3+§6.3 修正 |
| S5 | "FarmScopeInterceptor 跳过逻辑描述偏差" | **✅ 正确**：实际是 `FarmIdPathParser.extractFarmId(uri)` 返回 null 时直接 `return true`，与 `isPlatformAdmin()` 无关 | §7.5 修正 |
| S1-S4,S6 | 建议项 | **✅ 全部合理** | 纳入 §5-§8 |

### B1+B2 合并修正：时间类型不一致问题

**现状（代码核实）**：

```
gps_logs.recorded_at          → TIMESTAMPTZ（V20260710160000 修正后）
device_telemetry_logs.report_time → TIMESTAMP（无时区，V20260709120000 创建后未修正）
```

两表由 `TelemetryIngestionService.ingest()` 在同一事务中写入，用同一个 `Instant recordedAt` 值。因此不存在"毫秒精度差异"问题（B2 前提不成立），但**类型不一致**（B1 真实存在）：

- Hibernate 将 `Instant` 写入 TIMESTAMPTZ 列 → 存储为 UTC
- Hibernate 将同一个 `Instant` 写入 TIMESTAMP 列 → 转换为 JVM 默认时区后剥离时区标识
- JOIN 时 PostgreSQL 将 TIMESTAMP 按 session timezone 解释

**修正方案**：新增 Flyway 迁移将 `device_telemetry_logs.report_time` 从 TIMESTAMP 改为 TIMESTAMPTZ，与 `gps_logs.recorded_at` 统一。同时 `rtk_calibration_sessions` 的时间字段用 TIMESTAMPTZ。

---

## 1-4. 背景与概念（同 v1，此处省略，补充如下）

---

## 3-补. 质量等级样本计数规则（B4 修正）

**"样本点数"指排除疑似移动点后的有效点数（effectivePoints）**。

API 响应同时返回 `totalPoints`（原始）和 `effectivePoints`（排除后），质量等级基于 `effectivePoints` 判定。

| 等级 | 判定条件（基于 effectivePoints） |
|------|------|
| ✅ 优秀 | P95 ≤ 15m 且 effectivePoints ≥ 20 |
| ✅ 可用 | P95 ≤ 25m 且 effectivePoints ≥ 20 |
| ⚠️ 勉强可用 | 25m < P95 ≤ 40m 且 effectivePoints ≥ 10 |
| ❌ 不可用 | P95 > 40m 或 effectivePoints < 10 |

---

## 4-补. 统计指标退化规则（B3 修正）

| 指标 | 最小样本量要求 | 低于门限的退化行为 |
|------|-------------|-----------------|
| P50 | ≥ 5 | 取中位数，无退化 |
| P95 | ≥ 20 | 取最大值近似，标注"低置信" |
| P99 | **≥ 100** | **不计算**，野点阈值降级为 `max(3×P95, 30m)` |
| 野点数 | — | outlier_threshold = N≥100 ? max(P99, 3×P95, 30m) : max(3×P95, 30m) |

---

## 5-补. 数据模型修正（B1 + S1 修正）

### 5.2 rtk_calibration_sessions（修正时间类型 + 约束）

```sql
CREATE TABLE rtk_calibration_sessions (
    id BIGSERIAL PRIMARY KEY,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                  -- null = 进行中
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- S1: 同一设备同一时间只能有 1 个 IN_PROGRESS 会话（DB 层强制）
CREATE UNIQUE INDEX uq_rtk_session_device_active
  ON rtk_calibration_sessions(device_id)
  WHERE status = 'IN_PROGRESS';

-- S1: 时间窗口不可重叠（应用层校验，DB 层难以用 exclusion constraint 跨状态实现）
```

### 5.5 新增迁移：device_telemetry_logs.report_time 统一为 TIMESTAMPTZ

```sql
-- V20260716100000__fix_dtl_report_time_timezone.sql
ALTER TABLE device_telemetry_logs ALTER COLUMN report_time TYPE TIMESTAMPTZ
  USING report_time AT TIME ZONE 'Asia/Shanghai';
```

> 注意：此迁移会影响分区表（`report_time` 是分区键），需在 plan 阶段验证 ALTER 是否对分区表有效。

---

## 7-补. 后端实现修正

### 7.5 安全与权限（S5 修正描述）

平台级 API 路径不含 `{farmId}` 变量，`FarmScopeInterceptor.preHandle()` 在 `FarmIdPathParser.extractFarmId(uri)` 返回 null 时直接 `return true`，**完全不进入 farm scope 校验逻辑**。`isPlatformAdmin()` 仅在含 `{farmId}` 的路径中用于跳过租户归属校验。

### 7.6 GPS + 遥测关联查询（B1+B2 修正）

两表在同一 `ingest()` 事务中用同一个 `Instant recordedAt` 写入，不存在毫秒差异。修正 `device_telemetry_logs.report_time` 为 TIMESTAMPTZ 后，可直接等值 JOIN：

```sql
SELECT gl.latitude, gl.longitude, gl.accuracy, gl.recorded_at,
       dtl.step_number, dtl.motion_intensity, dtl.activity_class
FROM gps_logs gl
LEFT JOIN device_telemetry_logs dtl
  ON dtl.device_id = gl.device_id
  AND dtl.report_time = gl.recorded_at
WHERE gl.device_id = :deviceId
  AND gl.recorded_at BETWEEN :startedAt AND :endedAt
  AND gl.latitude != 0 AND gl.longitude != 0
ORDER BY gl.recorded_at
```

**LEFT JOIN 而非 INNER JOIN**：极少数情况下遥测日志可能在分区边界外 miss（历史数据），GPS 点仍应纳入统计，只是缺 step_number（视为 suspect=false）。

### 7.7 抖动直径计算（S6 补充）

会话时间窗口建议不超过 7 天（30 分钟上报周期 × 7 天 = 336 点）。对 ≤ 500 点的集合，O(n²) 两两计算可接受（~125000 对）。

如点数 > 500，在 `GpsQualityCalculator` 中用凸包直径近似（凸包上的点两两取最大距离，O(n log n)）。

---

## 8-补. API 补充

### POST /sessions 请求体（S3 补充）

```json
{
  "rtkPointId": 11,
  "deviceId": 1,
  "startedAt": "2026-07-15T00:00:00Z",
  "endedAt": null
}
```

### POST /rtk-points 支持 DMS 格式（S4 补充）

接受的 DMS 格式：
- `28°14′43.40730″N` 或 `28°14'43.40730"N`（度分秒 + 方向）
- 纬度方向 N/S，经度方向 E/W
- 转换为十进制保留 7 位小数

### trajectory 端点（S3 补充）

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/gps-quality/sessions/{id}/trajectory` | GET | 返回该会话时间窗口内 GPS 点序列，供前端复用 trajectory_sheet 渲染 |

---

## 11. 用户旅程设计

### 11.0 角色与登录

| 项目 | 值 |
|------|------|
| 角色 | platform_admin（平台管理员） |
| 登录手机号 | 13800000000 |
| 登录密码 | 123 |
| 登录后首页 | 租户列表页（`/ops/admin`） |
| 页面 Shell | 极简 Scaffold：顶部 AppBar（标题"平台管理"）+ 右上角 PopupMenuButton（齿轮图标 ⚙）+ 退出登录按钮 |

### 11.1 页面入口

```
platform_admin 登录
  → 租户列表页（/ops/admin，首页）
  → 点击右上角齿轮图标 ⚙（PopupMenuButton）
  → 下拉菜单选择「GPS 质量检查」
  → 进入 GPS 质量检查页面（/admin/gps-quality）
```

> 「GPS 质量检查」是新增的菜单项，添加到现有 PopupMenuButton 中（与"瓦片管理"、"用量分析"等并列）。

### 11.2 旅程一：准备阶段 — 录入 RTK 真值

**前提**：管理员拿到 RTK 实测坐标清单（DMS 格式，如 customer-journey.md §8 的 33 个点）

```
1. 用 platform_admin 账号登录（手机号 13800000000，密码 123）
2. 点击右上角 ⚙ → 选择「GPS 质量检查」→ 进入页面
3. 默认在 Tab「RTK 标定管理」
4. 左侧手风琴列表中，点击已有位置（如"一期楼顶"）展开
   — 如果位置不存在，点击「+ 新增点位」→ 弹框中选择「+ 新建位置」
5. 点击「+ 新增点位」
   ├─ 选择位置（如"一期楼顶"）
   ├─ 填写点位编号（如"34号点"）
   ├─ 输入 RTK 坐标：可直接输入十进制或 DMS 格式（如 28°14′47.6″N）
   └─ 保存
6. 重复录入所有 33 个点位
```

**验证**：右侧表格显示所有点位，DMS 与十进制坐标一致。

### 11.3 旅程二：标定阶段 — 创建会话 + 采集数据

**前提**：管理员已将 5 台设备分别放置到一期楼顶的 5 个 RTK 点上（11/16/20/21/22 号点）

#### 场景 A：实时标定（前瞻）

```
1. 在「RTK 标定管理」Tab，选择位置「一期楼顶」
2. 点击「+ 创建标定会话」
   ├─ 选择 RTK 点位（11号点）
   ├─ 选择设备（85d8）
   ├─ 填写开始时间（2026-07-15 08:00，即放置时间）
   ├─ 结束时间留空（进行中）
   └─ 创建 → 会话状态 IN_PROGRESS
3. 为其余 4 台设备重复创建
   — 16号-85d4 / 20号-89f0 / 21号-85b9 / 22号-8ed2
4. 等待 24h ~ 48h，设备持续上报数据
5. 确认设备期间未被移动
   ├─ 在会话列表中找到状态为「进行中」的行
   ├─ 点击「结束」按钮
   ├─ 弹出确认框：显示设备/点位/开始时间/结束时间（自动取当前）
   ├─ 确认设备未被动过 → 点击「确认结束」
   └─ 会话状态 COMPLETED → 自动触发统计计算
```

#### 场景 B：回溯标定（事后）

```
1. 管理员回顾已有数据，想评估之前放在某个位置的设备质量
2. 点击「+ 创建标定会话」
   ├─ 选择 RTK 点位 + 设备
   ├─ 填写开始时间（过去的时间）
   ├─ 填写结束时间（过去的时间）
   └─ 创建 → 状态直接 COMPLETED → 立即触发统计
```

**验证**：5 台设备的会话全部 COMPLETED，右侧表格显示设备/测试时间/状态。

### 11.4 旅程三：评估阶段 — 查看质量报告 + 横向对比

**前提**：旅程二已完成，5 台设备均有 COMPLETED 会话

```
1. 点击 Tab「质量报告」
2. 筛选：位置选「一期楼顶」，时间范围选「全部已完成会话」
3. 查看多设备横向对比表

   ┌──────────┬──────┬──────┬──────┬────────┬──────┬────────┐
   │ 设备      │ 样本  │ P50  │ P95  │ 抖动直径│ 野点  │ 结论   │
   ├──────────┼──────┼──────┼──────┼────────┼──────┼────────┤
   │ 85b9     │ 50   │ 5.8m │ 17.2m│ 31.5m  │ 0    │ ✅ 优秀 │
   │ 85d8     │ 48   │ 6.2m │ 19.1m│ 35.4m  │ 1    │ ✅ 可用 │
   │ 85d4     │ 47   │ 8.1m │ 22.3m│ 41.2m  │ 2    │ ✅ 可用 │
   │ 89f0     │ 45   │ 12.4m│ 38.7m│ 62.1m  │ 3    │ ⚠️ 勉强 │
   └──────────┴──────┴──────┴──────┴────────┴──────┴────────┘

4. 发现 89f0 精度较差，点击该行进入单设备详情
5. 查看单设备质量详情：
   ├─ 质量结论 banner：⚠️ 勉强可用，P95=38.7m
   ├─ 概览栏：48 点 / 疑似移动 8 点
   │    └─ 勾选「排除疑似移动点」→ 统计重算，effectivePoints=40
   ├─ 统计指标卡（P50/P95/平均偏差/最大偏差/抖动直径/野点数）
   │    └─ 每个指标有 ❓ tooltip 说明计算方法
   ├─ 展开等级标准说明：确认 25m < 38.7m ≤ 40m → 勉强可用
   ├─ 静止 GPS 散点图：看到点偏离 RTK 真值中心的散布范围
   ├─ 偏差分布直方图：确认大部分点偏差在 10-15m，尾部有野点
   └─ 点击「查看完整移动轨迹」→ 弹出轨迹面板确认设备确实没动
6. 下结论：
   ├─ 85b9、85d8：精度优秀/可用，投放到牧场
   ├─ 85d4：可用但偏高，观察一段时间
   └─ 89f0：勉强可用，排查硬件问题（天线/芯片），不建议投放到围栏预警场景
```

### 11.5 旅程四：多批次对比 — 不同 RTK 位置

```
1. 在「质量报告」Tab
2. 筛选位置选「宿舍楼顶」→ 查看该位置下的设备质量
3. 筛选位置选「一期楼顶」→ 查看该位置下的设备质量
4. 对比同一设备在不同位置的 P95：
   ├─ 85d8 在宿舍楼顶 P95=15m vs 一期楼顶 P95=19m
   └─ 差异在正常范围内（不同位置的卫星可见性/多径效应不同）
```

### 11.6 异常场景

| 场景 | 处理 |
|------|------|
| 设备放置后被人碰过 | 会话列表中「取消」该会话（数据无意义），或结束后在详情中勾选排除疑似移动点 |
| 设备上报频率异常（数据量不足） | 统计结果显示 effectivePoints < 10 → 等级为「不可用（数据不足）」 |
| 同一设备时间窗口重叠创建 | 应用层校验拦截，返回错误提示 |
| RTK 点位坐标录入错误 | 在点位列表中编辑修正，已关联的会话自动使用新坐标重算 |
| 回溯标定时该时间段没有数据 | 统计结果为 0 点 → 等级为「不可用（数据不足）」 |

## 12. Plan 阶段 checklist（更新）

- [ ] B3: `GpsQualityCalculator` 中 P99 退化逻辑（N<100 时跳过）
- [ ] B4: API 响应区分 `totalPoints` 和 `effectivePoints`
- [ ] S1: partial unique index + 时间窗口重叠应用层校验
- [ ] S2: 分区表 JOIN 的 EXPLAIN ANALYZE
- [ ] S3: trajectory 端点补入端点表
- [ ] S4: DMS 格式转换实现
- [ ] S6: 抖动直径点数上限 + 凸包近似
- [ ] §10.2: 33 个 RTK 点 DMS → 十进制转换精度验证
- [ ] §10.3: Flyway 种子数据迁移版本号（V20260716...）
- [ ] 补充: GpsQualityCalculator 单元测试（含边界用例）
- [ ] 补充: GET /sessions 分页参数
- [ ] 补充: comparison 端点字段命名统一

---

## 13. GPS + 遥测关联查询技术说明

### 13.1 时间处理策略（遵循经验判据 #17）

blade 平台的遥测时间字段不带时区标识。代码遵循经验判据 #17："直接用原始数值不做换算（`toInstant(ZoneOffset.UTC)`），不要猜对方时区"。

```java
// AgenticPlatformReportData.parseReportTime() — 第 47 行
LocalDateTime ldt = LocalDateTime.parse(reportTime, fmt);
return ldt.toInstant(ZoneOffset.UTC);  // 原始值当 UTC，不猜时区
```

解析后的 `Instant reportTime` 传给 `TelemetryIngestionService.ingest()`，同一个值同时写入两个表。因此两表的时间值天然一致。

### 13.2 列类型差异

| 表 | 列 | 类型 | 说明 |
|----|----|------|------|
| `gps_logs` | `recorded_at` | TIMESTAMPTZ | V3 建为 TIMESTAMP → V20260710160000 修正 |
| `device_telemetry_logs` | `report_time` | TIMESTAMP | V20260709120000 创建，未修正 |

类型不一致是技术债，但在当前环境（JVM=UTC, PG timezone=Etc/UTC）下**不影响 JOIN 匹配**。Hibernate 写同一个 `Instant` 到两种列类型时，字面值一致。

### 13.3 数据验证（dev 环境 2026-07-15）

```
精确等值 JOIN (gl.recorded_at = dtl.report_time):
  total_gps  = 1727
  exact_match = 1717  (99.4%)
  missed     = 10     (0.6%)
```

10 条 miss 是数据层面的时间差（30-55 秒），非类型问题。关联查询用 **LEFT JOIN** 容错：缺 step_number 时默认 suspect=false。

### 13.4 JOIN 查询

```sql
SELECT gl.latitude, gl.longitude, gl.accuracy, gl.recorded_at,
       dtl.step_number, dtl.motion_intensity, dtl.activity_class
FROM gps_logs gl
LEFT JOIN device_telemetry_logs dtl
  ON dtl.device_id = gl.device_id
  AND dtl.report_time = gl.recorded_at
WHERE gl.device_id = :deviceId
  AND gl.recorded_at BETWEEN :startedAt AND :endedAt
  AND gl.latitude != 0 AND gl.longitude != 0
ORDER BY gl.recorded_at
```

**LEFT JOIN 而非 INNER JOIN**：容错 0.6% 边缘 miss，GPS 点仍纳入统计（缺 step_number 时 suspect=false）。

### 13.5 是否需要统一列类型

类型统一（TIMESTAMP → TIMESTAMPTZ）是建议的技术债清理，但：
- **不是 NIX-15 的阻塞项**（当前 JOIN 99.4% 匹配）
- 建议作为独立维护项处理，不混入本功能
- 如未来 PG timezone 或 JVM timezone 配置变更，可能需要补做
