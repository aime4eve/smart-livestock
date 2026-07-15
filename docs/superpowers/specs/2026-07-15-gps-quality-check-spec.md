# GPS 数据质量检查功能设计规格 (NIX-15)

- **日期**: 2026-07-15
- **工单**: [NIX-15](https://linear.app/nix-agentic/issue/NIX-15)
- **状态**: 设计阶段
- **高保真原型**: `docs/marketing/nix-15-gps-quality-prototype.html`

---

## 1. 背景与目标

### 1.1 问题

消费级 GPS 追踪器存在固有定位误差（CEP 2.5-10m）。设备静止时每次上报坐标略有不同（GPS 抖动）。围栏预警功能依赖 GPS 精度，但目前无法回答：**某台设备的 GPS 精度到底够不够用？**

### 1.2 目标

为 platform_admin 提供一套工具，用于评估设备静止时的 GPS 定位质量，判断是否达到围栏预警所需精度。核心能力：

1. **RTK 真值管理** — 录入 RTK 实测的已知坐标点（33 个点位已实测）
2. **标定会话** — 将设备放置在 RTK 点上，定义已知静止的时间窗口
3. **GPS 质量统计** — 对静止时间窗口内的 GPS 点计算偏差/散布/野点等指标
4. **多设备横向对比** — 同一 RTK 位置下多台设备的质量结果对比

### 1.3 不做什么

- 不做实时 GPS 漂移修正（不在本工单范围）
- 不做围栏预警算法改造（NIX-18 独立工单）
- 不做加速度计静止误报率优化（NIX-9 独立工单）

---

## 2. 核心概念

| 术语 | 定义 |
|------|------|
| **RTK 真值** | 用 RTK 设备在固定点位实测的精确坐标，作为地面真相（ground truth） |
| **RTK 参考点** | 系统中录入的 RTK 真值记录，含位置名称、点位编号、经纬度 |
| **标定会话** | 将设备放置在 RTK 点上静止采集 GPS 数据的一次测试，由开始/结束时间定义已知静止窗口 |
| **疑似移动点** | 会话时间窗口内 step_number > 0 的 GPS 点（可能有人碰过设备），由用户裁量是否排除 |
| **P50 偏差** | 所有点到 RTK 真值距离的中位数 |
| **P95（抖动半径）** | 偏差排序后第 95 百分位，围栏预警 STANDARD 档基准 |
| **抖动直径** | 所有点两两 haversine 距离的最大值 |
| **野点** | 偏差超过 max(P99, 3×P95, 30m) 的点 |

### 2.1 静止判定原则

**静止由标定会话的时间窗口定义，不由传感器推断。**

设备是否静止这一事实来自管理员的操作意图（把设备放到 RTK 点上）。加速度计静止误报率 27-34%（见 NIX-9 需求文档），不可作为可靠判据。

`step_number > 0` 仅作为**辅助提示**（橙色"疑似移动"标记），管理员拥有最终裁量权，可选择排除或纳入。

---

## 3. 质量等级标准

| 等级 | 判定条件 | 含义 | 投用建议 |
|------|---------|------|---------|
| ✅ **优秀** | P95 ≤ 15m 且 样本 ≥ 20 | 超过消费级 GPS 典型水平 | 全场景投用，围栏 STANDARD 档 |
| ✅ **可用** | P95 ≤ 25m 且 样本 ≥ 20 | 民用 GPS 正常范围（CEP 3-10m，P95 常见 15-25m） | 正常投用 |
| ⚠️ **勉强可用** | 25m < P95 ≤ 40m 且 样本 ≥ 10 | 精度偏差较大 | 低风险场景，围栏加大 buffer 或 LOW 档 |
| ❌ **不可用** | P95 > 40m 或 样本 < 10 | 精度太差或数据量不足 | 不投用，排查硬件问题 |

阈值依据：消费级 GPS 芯片标称 CEP 为 2.5-5m，实测 P95 通常 15-25m。P95 > 40m 明显偏离正常范围。

---

## 4. 统计指标定义

| 指标 | 计算方法 |
|------|---------|
| 样本点数 | 会话时间窗口内有效 GPS 点总数（排除 0,0） |
| 疑似移动点数 | step_number > 0 的点数 |
| 平均偏差 | 所有 GPS 点到 RTK 真值距离的算术平均 |
| P50（中位偏差） | 偏差值升序排列的第 50 百分位 |
| P95（抖动半径） | 偏差值升序排列的第 95 百分位 |
| 最大偏差 | 离 RTK 真值最远的点距离 |
| 抖动直径 | 所有点两两 haversine 距离的最大值 |
| 野点数 | 偏差超过 max(P99, 3×P95, 30m) 的点数 |

距离计算用 haversine 公式（球面两点间最短距离）。

---

## 5. 数据模型

### 5.1 rtk_reference_points（RTK 真值点）

```sql
CREATE TABLE rtk_reference_points (
    id BIGSERIAL PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,   -- 位置名称（分组键，如"一期楼顶"）
    point_label VARCHAR(50) NOT NULL,      -- 点位编号（如"11号点"）
    latitude DECIMAL(10,7) NOT NULL,       -- RTK 实测纬度（十进制）
    longitude DECIMAL(10,7) NOT NULL,      -- RTK 实测经度（十进制）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_rtk_ref_location ON rtk_reference_points(location_name);
```

### 5.2 rtk_calibration_sessions（标定会话）

```sql
CREATE TABLE rtk_calibration_sessions (
    id BIGSERIAL PRIMARY KEY,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                  -- null = 进行中
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',  -- IN_PROGRESS / COMPLETED / CANCELED
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_rtk_session_point ON rtk_calibration_sessions(rtk_point_id);
CREATE INDEX idx_rtk_session_device ON rtk_calibration_sessions(device_id);
CREATE INDEX idx_rtk_session_status ON rtk_calibration_sessions(status);
```

**约束**：
- 同一设备同一时间只能有 1 个 IN_PROGRESS 会话
- 同一设备的多个会话时间窗口不可重叠
- 同一 RTK 点可同时有多台设备的会话（允许多设备并排放置标定）

### 5.3 ER 关系

```
rtk_reference_points (1) ──< rtk_calibration_sessions (N) >── (1) devices
```

### 5.4 种子数据

33 个 RTK 真值点（来自 `docs/product/customer-journey.md` §8）作为 Flyway 迁移种子数据。DMS 格式预转换为十进制。

---

## 6. API 设计

所有端点为 **平台级 API**（非 farm-scoped），仅 `platform_admin` 可访问，路径前缀 `/api/v1/admin/gps-quality`。

### 6.1 RTK 真值点管理

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/gps-quality/rtk-points` | GET | 查询 RTK 真值点列表（支持按 location_name 筛选） |
| `/api/v1/admin/gps-quality/rtk-points` | POST | 新增 RTK 真值点（支持 DMS 格式自动转换） |
| `/api/v1/admin/gps-quality/rtk-points/{id}` | PUT | 编辑 RTK 真值点 |
| `/api/v1/admin/gps-quality/rtk-points/{id}` | DELETE | 删除 RTK 真值点 |

### 6.2 标定会话管理

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/gps-quality/sessions` | GET | 查询会话列表（支持按 rtk_point_id / device_id / status 筛选） |
| `/api/v1/admin/gps-quality/sessions` | POST | 创建标定会话 |
| `/api/v1/admin/gps-quality/sessions/{id}/end` | PATCH | 结束进行中的会话（ended_at = now） |
| `/api/v1/admin/gps-quality/sessions/{id}` | DELETE | 删除/取消会话 |

### 6.3 质量统计

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/gps-quality/sessions/{id}/report` | GET | 单设备质量报告（含统计指标 + 散点数据） |
| `/api/v1/admin/gps-quality/comparison` | GET | 多设备横向对比（参数：rtk_point_id） |

**单设备报告响应**：

```json
{
  "sessionId": 1,
  "deviceCode": "85d8",
  "rtkPoint": { "label": "11号点", "latitude": 28.246594, "longitude": 112.851610 },
  "startedAt": "2026-07-10T00:00:00Z",
  "endedAt": "2026-07-11T00:00:00Z",
  "stats": {
    "totalPoints": 48,
    "suspectPoints": 3,
    "meanError": 7.8,
    "p50": 6.2,
    "p95": 19.1,
    "maxError": 42.3,
    "jitterDiameter": 35.4,
    "outlierCount": 1
  },
  "grade": "USABLE",
  "scatter": [
    { "latitude": 28.24658, "longitude": 112.85160, "error": 5.2, "suspect": false, "recordedAt": "2026-07-10T08:00:00Z" }
  ]
}
```

**多设备对比响应**：

```json
{
  "rtkPoint": { "id": 11, "label": "一期楼顶", "locationName": "一期楼顶" },
  "devices": [
    {
      "sessionId": 1, "deviceCode": "85d8",
      "stats": { "totalPoints": 48, "p50": 6.2, "p95": 19.1, "jitterDiameter": 35.4, "outlierCount": 1 },
      "grade": "EXCELLENT"
    }
  ]
}
```

### 6.4 轨迹查看（复用）

设备详情中「查看完整移动轨迹」复用现有 `/api/v1/admin/gps-quality/sessions/{id}/trajectory` 端点，返回该会话时间窗口内的 GPS 点序列（供前端复用 trajectory_sheet 渲染）。

---

## 7. 后端实现

### 7.1 限界上下文

归入 **IoT** 限界上下文（与 GPS 数据、设备管理同属一个上下文）。

### 7.2 代码结构

```
iot/
├── domain/
│   ├── model/
│   │   ├── RtkReferencePoint.java
│   │   ├── RtkCalibrationSession.java
│   │   └── CalibrationStatus.java          // enum: IN_PROGRESS, COMPLETED, CANCELED
│   ├── repository/
│   │   ├── RtkReferencePointRepository.java
│   │   └── RtkCalibrationSessionRepository.java
│   └── service/
│       └── GpsQualityCalculator.java       // 统计计算核心逻辑
├── application/
│   ├── RtkReferencePointService.java
│   ├── RtkCalibrationSessionService.java
│   └── GpsQualityReportService.java        // 组装报告（查GPS+遥测→计算统计）
├── infrastructure/
│   └── persistence/
│       ├── SpringDataRtkReferencePointRepository.java
│       ├── SpringDataRtkCalibrationSessionRepository.java
│       └── JpaRtkReferencePointRepositoryImpl.java
└── interfaces/
    └── admin/
        ├── GpsQualityAdminController.java   // 所有端点入口
        └── dto/
            ├── RtkPointDto.java
            ├── CalibrationSessionDto.java
            ├── QualityReportDto.java
            └── ComparisonDto.java
```

### 7.3 统计计算流程

```
GpsQualityReportService.generateReport(sessionId, excludeSuspect)
  1. 查 session → 获取 rtk_point_id, device_id, started_at, ended_at
  2. 查 rtk_reference_point → 获取 RTK 真值坐标
  3. JOIN gps_logs + device_telemetry_logs（同 device_id + 同时间戳）
     WHERE recorded_at BETWEEN started_at AND ended_at
       AND latitude != 0 AND longitude != 0
  4. 对每个点：
     a. haversine(gps_point, rtk_truth) → 偏差距离
     b. step_number > 0 → 标记 suspect
  5. 如果 excludeSuspect=true，过滤掉 suspect 点
  6. 排序偏差值 → 计算 P50/P90/P95/P99
  7. 两两 haversine → 抖动直径
  8. outlier_threshold = max(P99, 3×P95, 30m) → 野点数
  9. 匹配质量等级
  10. 返回统计 + 散点数据
```

### 7.4 平台级设备查询

platform_admin 查询设备列表需要跨租户。新增端点：

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/admin/gps-quality/devices` | GET | 查询所有 TRACKER 类型设备（跨租户，用于创建会话时选设备） |

### 7.5 安全与权限

- 所有端点要求 `ROLE_PLATFORM_ADMIN`
- 路径前缀 `/api/v1/admin/` 已被 `FarmScopeInterceptor` 跳过 farm ownership 校验（见 `isPlatformAdmin()` 逻辑）
- 无需 `{farmId}` 路径变量，平台级直接查

### 7.6 GPS + 遥测关联查询

`gps_logs` 和 `device_telemetry_logs` 在同一遥测快照中同时写入，通过 `device_id + 时间戳` 关联：

```sql
SELECT gl.latitude, gl.longitude, gl.accuracy, gl.recorded_at,
       dtl.step_number, dtl.motion_intensity
FROM gps_logs gl
LEFT JOIN device_telemetry_logs dtl
  ON dtl.device_id = gl.device_id
  AND dtl.report_time = gl.recorded_at
WHERE gl.device_id = :deviceId
  AND gl.recorded_at BETWEEN :startedAt AND :endedAt
  AND gl.latitude != 0 AND gl.longitude != 0
ORDER BY gl.recorded_at
```

注意：JOIN 时间戳精确匹配可能因毫秒精度差异偶发 miss，需在 plan 阶段验证。

---

## 8. 前端实现

### 8.1 路由

| 路径 | 枚举 | 页面 |
|------|------|------|
| `/admin/gps-quality` | `platformGpsQuality` | GpsQualityPage（Tab 容器） |

路由守卫：路径以 `/admin/` 开头，platform_admin 可访问。

### 8.2 功能模块

```
features/admin/gps_quality/
├── domain/
│   ├── rtk_point.dart
│   ├── calibration_session.dart
│   └── gps_quality_report.dart
├── data/
│   └── gps_quality_api_repository.dart
└── presentation/
    ├── gps_quality_page.dart              // Tab 容器
    ├── rtk_calibration_tab.dart           // Tab 1: RTK 标定管理
    ├── quality_report_tab.dart            // Tab 2: 质量报告
    └── widgets/
        ├── scatter_chart.dart             // SVG 散点图
        └── quality_grade_badge.dart       // 等级标签
```

### 8.3 状态管理

使用 Riverpod，因为所有 API 是平台级（非 farm-scoped），Controller 继承普通 `AsyncNotifier`（不需要 `FarmScopedNotifier`）。

### 8.4 i18n

所有面向用户文案通过 `AppLocalizations` + `app_zh.arb` / `app_en.arb`。后端错误消息通过 `MessageSource` + `messages_zh.properties` / `messages_en.properties`。

### 8.5 轨迹复用

设备详情中「查看完整移动轨迹」按钮弹出 `_TrajectorySheet`，但数据源改为平台级 API（按 deviceId 而非 livestockId 查询）。

---

## 9. 关键设计决策记录

| # | 决策 | 理由 |
|---|------|------|
| 1 | RTK 真值与设备解耦（两张表） | 一个 RTK 点可被多台设备测试，一台设备也可在多个点测试 |
| 2 | 静止由会话时间窗口定义，不由传感器推断 | 加速度计静止误报率 27-34%，传感器不可靠 |
| 3 | step_number 仅作辅助标记，用户裁量排除 | 传感器数据从"判据"降级为"提示" |
| 4 | 统计结果实时计算，不持久化 | 会话数据量小（几十到几百点），计算成本低，避免缓存一致性 |
| 5 | 平台级 API 路径 `/api/v1/admin/gps-quality/` | platform_admin 无 farm scope，需跳过 FarmScopeInterceptor |

---

## 10. 待 plan 阶段验证项

1. `gps_logs.recorded_at` 与 `device_telemetry_logs.report_time` 的时间戳精确匹配可靠性
2. 33 个 RTK 点 DMS → 十进制转换精度验证
3. Flyway 种子数据迁移版本号分配
4. 前端散点图在真实数据下的渲染性能
5. 轨迹复用方案（按 deviceId 查询 vs 现有按 livestockId 查询的适配）
