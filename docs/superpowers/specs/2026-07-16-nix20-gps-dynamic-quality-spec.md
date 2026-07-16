# NIX-20 GPS 动态检验工具 — 方案设计文档

| 字段 | 值 |
|---|---|
| 工单 | NIX-20 GPS动态检验工具 |
| 优先级 | High |
| 类型 | 功能增强（Improvement） |
| 前置依赖 | NIX-15 GPS 质量检查（静态分析，已实现） |
| 设计日期 | 2026-07-16 |
| 状态 | ✅ 已确认（spec + 原型） |

---

## 1. 背景与目标

### 1.1 工单需求

在现有「GPS 质量检查」功能中，增加 **GPS 运动中数据准确性** 的检查能力：

1. RTK 真值点管理能力维持不变（33 个点已 seed）
2. 质量报告拆分为 **静态分析报告**（现有）和 **动态分析报告**（本次新增）
3. 动态分析报告的分析项与结论规则由本设计文档定义

### 1.2 静态 vs 动态的本质区别

| 维度 | 静态（NIX-15，已实现） | 动态（NIX-20，本次） |
|---|---|---|
| 设备状态 | 固定在单个 RTK 真值点上不动 | 运动中，依次经过多个 RTK 真值点 |
| 真值锚点 | 1 个固定点 | M 个点（33 个 RTK 真值点中的子集） |
| 采样几何 | 同一点反复采 N 次 | M 个点各采约 1 次 |
| 误差定义 | 每点到固定真值点的 haversine 距离 | 每个经过点到其匹配真值点的 haversine 距离 |
| 统计对象 | 单点散布（mean/p95/jitter） | 跨多点误差分布（mean/p95/逐点拆分） |
| 上报频率 | 不受 30 分钟限制（设备静止，可累积） | 30 分钟一次，测试人员编排使每次上报恰好到达下一个 RTK 点 |

### 1.3 测试方法（用户提供）

设备每 30 分钟上报一次。做动态测试时，测试人员控制运动节奏，使**设备每次上报时恰好物理位于某个 RTK 真值点附近（物理偏差 ≤ 5m）**。

这把 30 分钟稀疏采样的劣势翻转为优势：每次上报都是一次干净的、带真值锚的绝对精度样本，无需插值或推断。

### 1.4 设计目标

- **G1**：RTK 真值点管理不变（33 个真值点表不动），但**标定会话与动态测试会话统一为同一张表**（见 §5）
- **G2**：动态报告产出绝对精度评估（GPS 上报值 vs RTK 真值的误差分布）
- **G3**：每台设备静态/动态对比，验证「动态偏差 ≤ 静态偏差」这一行业规律
- **G4**：匹配算法稳定可靠，不产生选择性偏差
- **G5**：前端在现有 GPS 质量检查页面内整合（统一会话列表 + 动态报告），不另建入口
- **G6**：批量新增会话功能同步支持静态（设备+RTK点）和动态（设备+路线）两种类型

---

## 2. 物理基础（联网查证）

### 2.1 动态多径偏差小于静态的机制

依据 NOVATEL（Hexagon 旗下专业 GNSS 厂商）官方技术文档 *Understanding and Mitigating GNSS Multipath Interference*：

> **User motion**: For a **static antenna near a building, multipath changes slowly** as the satellite moves across the sky. For a **moving vehicle, the relationship between the antenna, satellite, and reflectors changes rapidly, causing the multipath error to fluctuate. This rapid change can sometimes average out the error, known as decorrelation.**
>
> **Stationary applications** ... are susceptible to **persistent, slowly varying multipath** from nearby structures.

**机制**：静态时反射几何固定，多径误差是持续同向偏置，不随采样数平均掉；动态时反射几何快速变化，多径方向与幅度随机化，正负误差相互抵消（decorrelation / 去相关）。

### 2.2 慢速场景的限定（关键设计考量）

NOVATEL 同文指出：

> **Agriculture and mining**: ... **Slow operational speeds can lead to more persistent errors.**

牲畜/人员步行属于慢速（~4 km/h），decorrelation 效应被削弱。因此「动态偏差一定小于静态」在畜牧场景下**是有条件的，不是无条件的**。本设计**不假设该规律成立，而让实测数据验证/证伪它**——这恰是静态/动态对比报告的核心价值。

### 2.3 消费级 GPS 精度量级（阈值锚点）

| 来源 | 数据 |
|---|---|
| gps.gov（美国官方） | 消费级手机开阔天空 ~4.9m；FAA 高质量单频 ≤1.82m(95%)；建筑物附近恶化 |
| GPS World | 良好多径 2-3m，恶劣多径 10m+，城市峡谷 NLOS 可达数百米 |
| NOVATEL | NLOS 可致数百米误差 |

---

## 3. 现有架构回顾（静态分析）

### 3.1 后端

> **注**：§3 描述的是**改造前**的现有架构。§5 提出统一会话表 `gps_quality_tests` 取代 `rtk_calibration_sessions`，以下代码路径为迁移起点。

```
smart-livestock-server/src/main/java/com/smartlivestock/iot/
├── domain/
│   ├── model/
│   │   ├── RtkReferencePoint.java        # RTK 真值点（id, locationName, pointLabel, lat, lng）
│   │   ├── RtkCalibrationSession.java    # 静态标定会话（绑定单个 rtkPointId）
│   │   ├── CalibrationStatus.java        # IN_PROGRESS / COMPLETED / CANCELED
│   │   └── QualityGrade.java             # EXCELLENT / USABLE / MARGINAL / UNAVAILABLE
│   ├── service/
│   │   └── GpsQualityCalculator.java     # 纯领域服务：haversine, percentile, convexHull, grade
│   └── port/dto/
│       ├── GpsPointWithTelemetry.java    # (lat,lng,accuracy,recordedAt,stepNumber,motionIntensity,activityClass)
│       └── GpsQualityStats.java          # (totalPoints,suspectPoints,...,p95,jitterDiameter,grade,within15/25/40m)
├── application/
│   └── GpsQualityReportService.java      # 组装报告：session→rtk→gpsLogs→calculator
└── interfaces/admin/
    ├── GpsQualityAdminController.java   # /api/v1/admin/gps-quality（PLATFORM_ADMIN）
    └── dto/ (QualityReportDto, CalibrationSessionDto, ComparisonDto, RtkPointDto)
```

### 3.2 前端

```
Mobile/mobile_app/lib/features/admin/gps_quality/
├── domain/gps_quality_models.dart        # RtkPoint, CalibrationSession, GpsQualityReport, GpsQualityStats, ScatterPoint
├── data/
│   ├── gps_quality_api_repository.dart
│   └── gps_quality_providers.dart
└── presentation/
    ├── gps_quality_page.dart             # TabController(length: 2)
    ├── rtk_calibration_tab.dart          # Tab 1: RTK 标定管理
    ├── quality_report_tab.dart           # Tab 2: 质量报告
    └── widgets/ (scatter_chart, quality_grade_badge, session_trajectory_sheet, batch_create_session_dialog)
```

### 3.3 可复用的领域工具

`GpsQualityCalculator` 的以下方法是 pure function，动态分析可直接复用：
- `haversine()` / `distance()` — 水平距离计算
- `percentile()` — 排序数组的分位数插值
- `determineGrade()` — 基于样本数 + p95 的分级（动态需另设阈值表）
- `convexHull()` + `maxPairwiseHaversine()` — 散布直径（可用于静止漂移检测）

---

## 4. 动态分析方案设计

### 4.1 匹配阈值 T — 正式定义

**匹配阈值 T**：判定一次 GPS 上报是否构成「对某 RTK 真值点的有效经过」的最大允许水平距离。它只负责**召回**（这个点算不算经过样本），不负责打分（设备好不好）。

#### 判定规则

对上报点 p，计算它到全部 RTK 真值点的水平距离，取最近者 d₁（对应真值点 R₁）和次近者 d₂（对应真值点 R₂）：

| 条件 | 判定 | 去向 |
|---|---|---|
| d₁ ≤ T 且 d₂ > T | **明确经过** R₁ | 进入绝对精度统计，误差 = d₁ |
| d₁ ≤ T 且 d₂ ≤ T | **歧义经过** | 进入统计但标记 ambiguous，报告中单独呈现 |
| d₁ > T | **非经过点**（移动途中 / 严重漂移 / 未到达） | 不参与精度统计，计入「漏过点」计数 |

#### 取值约束

| 约束 | 推导 | 结论 |
|---|---|---|
| 下界（不漏真实经过点） | 真实经过点 d₁ ≤ E_GPS(≤15m) + δ_phys(≤5m) ≈ 5~20m。T 必须 ≥ 此上界，否则把恶劣多径下的差设备真实经过点误判为非经过 → 选择性偏差 | T ≥ ~20m |
| 上界（不误纳移动途中点） | 移动途中点距最近 RTK 点约 km 量级（30min 步行 ≈ 2km） | T << 1000m，约束极宽松 |
| 歧义（不靠 T 解决） | 近距离点簇（如同一楼顶 11/12 号点隔 10m），T=30m 时一个点落入多圈。不靠收紧 T（会违反下界），而用歧义比 d₂/d₁ 标记 | 歧义独立处理 |

#### 默认值

**T = 30m（可配置）**

推导：下界 ~20m（GPS ≤15m + 物理 ≤5m）+ 约 2× 安全余量 = 30m；远低于 km 级途中点。该值在 20~50m 区间内不敏感（途中点都在 km 量级），靠实测校准。

#### 设计原则：T 与质量评估解耦

一旦点被召回为经过点，其误差 = 真实值 d₁，用 p50/p95 分位统计分级。**T 的宽窄不改变已匹配点的误差数值，只影响召回率**。因此 T 放宽不会污染精度测量。

---

### 4.2 匹配算法（路线驱动）

动态测试关联一条**计划路线**（有序 RTK 点序列，由用户录入并可跨设备复用）。匹配以路线为基准——逐个路线点在时间窗内找最近的 GPS 上报点，验证设备是否真正走过了这条路线。

```
输入：
  route[]       — 计划路线（有序 RTK 点 R₁..R_m，按录入顺序）
  gpsPoints[]   — 动态测试时间窗内的所有 GPS 上报点（按时间排序）
  T             — 匹配阈值（默认 30m）

步骤（对路线中每个 R_i，按顺序）：
  在 gpsPoints 中找离 R_i 最近的点 p_i，距离 d_i = haversine(R_i, p_i)
  if d_i <= T:
    R_i 标记为「已经过」，error_i = d_i，记录匹配点 p_i 的时间戳
    matchedCount++
  else:
    R_i 标记为「未经过（漏过点）」，missedCount++

输出：
  passSamples[]   — 已经过路线点，每条含 (R_i, matchedGpsPoint, error_i, sequenceNo)
  missedPoints[]  — 未经过路线点
  transitPoints[] — 未被任何路线点匹配的 GPS 点（多余上报）
  coverage        — matchedCount / m（路线完成度）
  inOrder         — 已经过点的 GPS 时间戳是否单调递增（合规性，见下）
```

#### 合规性检测

有了有序路线，可额外输出两类诊断：

| 指标 | 定义 | 判读 |
|---|---|---|
| inOrder | 已经过点匹配到的 GPS 时间戳是否随路线序号单调递增 | false → 出现逆序，设备走了回头路或 GPS 时序错乱 |
| 漏过点 | 路线中 d_i > T 的 RTK 点 | 该位置 GPS 定位失败 / 设备未到达 / 严重遮挡 |

#### 歧义处理

当路线中相邻两个 RTK 点间距很小（如同一楼顶的 11/12 号点隔 10m），同一次 GPS 上报可能离两者都很近。此时该上报点被分配给**路线序号靠前的未匹配点**，并标记 ambiguous=true。报告中对 ambiguous 匹配单独标注，不强行二选一。

#### 为什么路线驱动优于全局最近邻

原设计（全局最近邻）无法判断「设备是否按计划走」和「哪些点漏了」。路线驱动以计划路线为基准，天然输出覆盖率和合规性——这才是动态检验真正要回答的问题。

---

### 4.3 动态报告指标

#### A. 召回与覆盖（匹配质量自评）

| 指标 | 定义 | 意义 |
|---|---|---|
| totalReports | 时间窗内 GPS 上报总数 | 样本基线 |
| matchedCount | 匹配为经过点的上报数 | 有效样本量 |
| ambiguousCount | 其中歧义经过数 | 数据可靠性 |
| transitCount | 移动途中点数 | 非统计样本 |
| coverage | distinct matched RTK / 33 | 路线完成度 |

#### B. 绝对精度（核心指标）

跨所有经过样本的误差分布：
| 指标 | 定义 | 退化规则 |
|---|---|---|
| meanError | 算术均值 | matchedCount=0 → 0 |
| p50 / p95 | 线性插值分位数 | <5 点 → 用 max；<20 点 → p95 用 max |
| maxError | 最大单点误差 | — |

**误差按 RTK 真值点拆分**：每个被经过的 RTK 点显示其经过次数 + 平均误差。诊断价值：某点误差持续偏大 → 该位置存在信号遮挡（多径源）。

#### C. 运动状态交叉验证

对每个经过点关联其上报时刻的遥测数据（`device_telemetry_logs` JOIN）：
| 指标 | 定义 | 用途 |
|---|---|---|
| activityClass | activity 分类（stationary/walking/...） | 确认设备确实在运动中 |
| motionIntensity | 运动强度 | 排除「设备静止却报动态测试」的误用 |

#### D. 自报精度可信度

| 指标 | 定义 | 判读 |
|---|---|---|
| reportedAccuracyP50 | GPS 自报 accuracy 的 p50 | 基线 |
| accuracyBiasP50 | (实际误差 - 自报accuracy) 的 p50 | >0 → 设备过度自信；<0 → 保守 |

---

### 4.4 分级规则

复用 `QualityGrade` 枚举（EXCELLENT / USABLE / MARGINAL / UNAVAILABLE），但动态阈值**比静态更严**（因动态偏差本应更小）：

| Grade | 静态阈值（现有） | 动态阈值（本次，初版，可校准） | 最小样本 |
|---|---|---|---|
| EXCELLENT | p95 ≤ 15m 且 N ≥ 20 | p95 ≤ 10m 且 coverage ≥ 50% | matched ≥ 10 |
| USABLE | p95 ≤ 25m 且 N ≥ 20 | p95 ≤ 20m 且 coverage ≥ 30% | matched ≥ 6 |
| MARGINAL | p95 ≤ 40m 且 N ≥ 10 | p95 ≤ 35m 且 coverage ≥ 20% | matched ≥ 4 |
| UNAVAILABLE | 其他 | 其他 | matched < 4 |

> 阈值为初版建议值，部署后用真实动态测试数据校准。分级逻辑用独立方法 `determineDynamicGrade()`，不改动静态 `determineGrade()`。

---

### 4.5 静态 / 动态对比

每台设备如同时有静态标定会话和动态测试，报告页并排展示：

| 维度 | 静态 | 动态 |
|---|---|---|
| p95 误差 | (静态报告) | (动态报告) |
| Grade | EXCELLENT | USABLE |
| 结论 | — | 动态 p95 比静态大 X m / 小 Y m |

这直接验证 NOVATEL 文档的 decorrelation 理论在畜牧慢速场景下是否成立——是本功能最有价值的业务结论。

---

## 5. 数据模型（统一会话 + 路径实体）

### 5.1 核心决策：静态/动态会话统一

工单约束「RTK 真值点管理维持不变」针对的是真值**点**表（`rtk_reference_points`，33 个点不动）。而"使用真值去测试"的**会话**表属于可重新设计的部分。

静态标定会话和动态测试会话剥掉"真值基准"后本质相同——都是 **device_id + 时间范围 + status**：

| | 静态 | 动态 |
|---|---|---|
| 真值基准 | 单个 RTK 点 (`rtk_point_id`) | 一条路线 (`route_id`) |
| 其余字段 | device_id, started_at, ended_at, status | 完全相同 |
| 状态机 | IN_PROGRESS → COMPLETED / CANCELED | 完全相同 |

因此**统一为一张表 `gps_quality_tests`**，用 `test_type` 区分，`rtk_point_id` 和 `route_id` 互斥可空（由 CHECK 约束保证一致性）。

### 5.2 路径实体：`dynamic_test_routes` + `dynamic_test_route_points`

路径是**独立可复用实体**——一条路径是若干 RTK 真值点的有序序列，由用户录入，**可被多个设备的动态测试引用**（对应"多设备共用同一套测试路径"的场景）。

```sql
-- 路径定义
CREATE TABLE dynamic_test_routes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,            -- 路径名称，如 "地面门岗巡回路线"
    description TEXT,                      -- 可选说明
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 路径上的有序 RTK 点序列（多对一关联路径）
CREATE TABLE dynamic_test_route_points (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES dynamic_test_routes(id) ON DELETE CASCADE,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    sequence_no INTEGER NOT NULL,          -- 经过顺序（从 1 开始）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (route_id, sequence_no)
);

CREATE INDEX idx_dtrp_route ON dynamic_test_route_points(route_id, sequence_no);
```

设计要点：
- `sequence_no` 定义经过顺序，匹配算法按此顺序逐点找最近 GPS 上报点（§4.2 路线驱动）
- 同一 RTK 点可在一条路径中重复出现（设备绕回再经过）
- `ON DELETE CASCADE`：删路径时连带删除其点位序列
- 一个 RTK 点可被多条路径引用（N×M 关系）

### 5.3 统一会话表：`gps_quality_tests`（取代 `rtk_calibration_sessions`）

```sql
CREATE TABLE gps_quality_tests (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    test_type VARCHAR(10) NOT NULL,        -- STATIC / DYNAMIC
    rtk_point_id BIGINT REFERENCES rtk_reference_points(id),  -- STATIC 时必填
    route_id BIGINT REFERENCES dynamic_test_routes(id),       -- DYNAMIC 时必填
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                   -- null = in progress
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',  -- IN_PROGRESS / COMPLETED / CANCELED
    note TEXT,                              -- 可选备注
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    -- 互斥约束：STATIC 必须有 rtk_point_id，DYNAMIC 必须有 route_id
    CONSTRAINT chk_test_type_truth CHECK (
        (test_type = 'STATIC'  AND rtk_point_id IS NOT NULL AND route_id IS NULL) OR
        (test_type = 'DYNAMIC' AND route_id IS NOT NULL AND rtk_point_id IS NULL)
    )
);

CREATE INDEX idx_gqt_device ON gps_quality_tests(device_id);
CREATE INDEX idx_gqt_status ON gps_quality_tests(status);
CREATE INDEX idx_gqt_type ON gps_quality_tests(test_type);
CREATE INDEX idx_gqt_point ON gps_dynamic_tests(rtk_point_id);
CREATE INDEX idx_gqt_route ON gps_quality_tests(route_id);
```

### 5.4 旧表迁移（`rtk_calibration_sessions` → `gps_quality_tests`）

新 Flyway 迁移按以下步骤完成统一：
1. 创建 `dynamic_test_routes` + `dynamic_test_route_points` + `gps_quality_tests` 三张表
2. **数据迁移**：`INSERT INTO gps_quality_tests SELECT id, device_id, 'STATIC', rtk_point_id, NULL, started_at, ended_at, status, NULL, created_at, updated_at FROM rtk_calibration_sessions`
3. 保留旧表 `rtk_calibration_sessions` 暂不删除（防回滚），但代码层全部切到新表；后续迁移可在确认稳定后 DROP

> 注意：上方 `idx_gqt_point` 索引名误写，实际为 `idx_gqt_point ON gps_quality_tests(rtk_point_id)`。

### 5.5 报告不持久化

报告结果（匹配样本、误差分布）**不持久化**——每次请求实时计算（与静态 `GpsQualityReportService.generate()` 一致）。理由：
- 数据量小（一次动态测试 = 路径点数 m × 时间窗内上报点数 n 的距离计算）
- 实时计算保证 RTK 坐标修正后立即生效
- 避免缓存一致性问题

### 5.6 迁移命名

`V20260716100000__unify_gps_quality_tests.sql`（时间戳格式，> V20260716093000），含三张新表 + 旧表数据迁移。

## 6. API 设计

在现有 `GpsQualityAdminController`（`/api/v1/admin/gps-quality`）下统一端点，权限维持 PLATFORM_ADMIN。

### 6.1 计划路线 CRUD（路径实体）

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/admin/gps-quality/dynamic-routes` | 路径列表 |
| POST | `/api/v1/admin/gps-quality/dynamic-routes` | 创建路径（name/description） |
| PUT | `/api/v1/admin/gps-quality/dynamic-routes/{id}` | 修改路径信息 |
| DELETE | `/api/v1/admin/gps-quality/dynamic-routes/{id}` | 删除路径（级联删除点位序列） |

### 6.2 路径点位序列管理

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/admin/gps-quality/dynamic-routes/{id}/points` | 查询路径的有序 RTK 点序列（含 RTK 坐标，供前端绘制） |
| PUT | `/api/v1/admin/gps-quality/dynamic-routes/{id}/points` | **整体替换**路径点序列（body: `[{rtkPointId, sequenceNo}, ...]`） |

设计决策：点位序列用 **PUT 整体替换**而非逐条增删——路径是一次性录入的有序列表，整体替换实现简单且避免并发序号冲突。

### 6.3 统一测试会话 CRUD（取代原静态会话 CRUD）

原 `/sessions` 端点统一为 `/tests`，请求体增加 `testType` 字段：

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/admin/gps-quality/tests?testType=&deviceId=&routeId=&status=&page=&size=` | 统一会话列表（支持按类型/设备/路线/状态过滤） |
| POST | `/api/v1/admin/gps-quality/tests` | 创建会话（STATIC: device+rtkPointId+时间；DYNAMIC: device+routeId+时间） |
| POST | `/api/v1/admin/gps-quality/tests/batch` | **批量创建**（支持静态/动态混合，见 §6.4） |
| PATCH | `/api/v1/admin/gps-quality/tests/{id}/end` | 结束会话 |
| DELETE | `/api/v1/admin/gps-quality/tests/{id}` | 取消会话 |

> **向后兼容**：保留旧 `/sessions` 路径作为 `testType=STATIC` 的别名（转发到 `/tests`），避免前端未改造的调用立即崩溃。待前端切完后在下个迭代移除。

### 6.4 批量创建（统一静态/动态）

批量创建请求体支持两种行类型，由每行的 `testType` 决定：

```json
{
  "rows": [
    {"testType": "STATIC",  "deviceId": 1, "rtkPointId": 11, "startedAt": "...", "endedAt": "..."},
    {"testType": "STATIC",  "deviceId": 2, "rtkPointId": 11, "startedAt": "...", "endedAt": "..."},
    {"testType": "DYNAMIC", "deviceId": 1, "routeId": 1,     "startedAt": "...", "endedAt": "..."},
    {"testType": "DYNAMIC", "deviceId": 2, "routeId": 1,     "startedAt": "...", "endedAt": "..."}
  ]
}
```

**典型用法**：
- 同一 RTK 点，N 台设备同时静态标定 → N 行 STATIC，共享 `rtkPointId` + 共同时间窗
- 同一路线，N 台设备依次动态测试 → N 行 DYNAMIC，共享 `routeId`，各自时间窗

Excel 导入模板新增 `testType` 列（STATIC/DYNAMIC）；STATIC 行填 RTK 点标签，DYNAMIC 行填路线名称。

### 6.5 报告端点

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/v1/admin/gps-quality/tests/{id}/report?excludeSuspect=` | **静态报告**（testType=STATIC，复用现有逻辑） |
| GET | `/api/v1/admin/gps-quality/tests/{id}/report?threshold=30` | **动态报告**（testType=DYNAMIC，新逻辑） |
| GET | `/api/v1/admin/gps-quality/tests/{id}/trajectory` | 轨迹点（静态=散点，动态=路线匹配轨迹） |
| GET | `/api/v1/admin/gps-quality/tests/{id}/static-vs-dynamic` | 静态/动态对比（同设备，查其 STATIC + DYNAMIC 会话） |
| GET | `/api/v1/admin/gps-quality/comparison?rtkPointId=` | 多设备对比（静态，复用现有） |

> 报告端点根据 `test_type` 自动分发到静态或动态报告 Service，URL 统一为 `/tests/{id}/report`。

### 6.6 动态报告 DTO

```java
public class DynamicQualityReportDto {
    Long testId;
    Long deviceId;
    String deviceCode;
    Long routeId;
    String routeName;
    Instant startedAt;
    Instant endedAt;
    double threshold;              // 使用的匹配阈值
    QualityGrade grade;
    // 召回与覆盖
    int routePointCount;           // 路径 RTK 点数 m
    int matchedCount;              // 已经过的路线点数
    int missedCount;               // 漏过的路线点数
    int ambiguousCount;            // 歧义匹配数
    int transitCount;              // 未被匹配的多余上报点
    boolean inOrder;               // GPS 时间戳是否随序号单调递增（合规性）
    double coverage;               // matchedCount / m * 100%
    // 绝对精度
    double meanError, p50, p95, maxError;
    // 自报精度
    Double reportedAccuracyP50;
    Double accuracyBiasP50;
    // 逐 RTK 点拆分（按 sequenceNo 排序）
    List<PerRtkPointSummary> perPoint;   // [{rtkPointId, label, sequenceNo, passed, error, ambiguous}]
    // 静态对比（可选）
    StaticComparison staticComparison;   // {staticP95, staticGrade, deltaP95}
    // 匹配样本明细（地图绘制用）
    List<MatchedPass> passes;
}
```

## 7. 前端设计

### 7.1 Tab 结构调整

`GpsQualityPage` 的 Tab 结构保持 3 个，但内容重组：

| Tab | 名称 | 内容 | 改动 |
|---|---|---|---|
| Tab 1 | RTK 标定管理 | RTK 真值点管理（不变）+ **统一测试会话列表** | 会话列表改造：合并静态+动态 |
| Tab 2 | 静态分析 | 质量报告（静态） | 重命名「质量报告」→「静态分析」 |
| Tab 3 | 动态检验 | **动态分析报告**（路径预览 + 匹配轨迹 + 误差 + 静态/动态对比） | 新增 |

### 7.2 Tab 1 统一测试会话列表（改造现有 `rtk_calibration_tab.dart`）

现有该 Tab 是"按位置分组 → 每点下的静态会话列表"。改造为**统一会话列表**：

- 列表展示所有测试会话（STATIC + DYNAMIC），每行带类型图标：
  - 📍 STATIC：设备 + RTK 点标签 + 时间窗
  - 🚶 DYNAMIC：设备 + 路线名 + 时间窗
- 筛选：按 testType / 设备 / 状态 过滤
- **批量创建改造**（`BatchCreateSessionDialog`）：每行增加 testType 选择
  - 选 STATIC → 下拉选 RTK 点（现有逻辑）
  - 选 DYNAMIC → 下拉选路线
  - Excel 模板增加 testType 列；导入时按 testType 匹配 rtkPointLabel 或 routeName
- 批量场景：
  - N 台设备同一 RTK 点静态标定 → N 行 STATIC + 共同时间
  - N 台设备同一路线动态测试 → N 行 DYNAMIC + 各自时间窗

### 7.3 Tab 3 动态检验报告（新增）

选中某场 DYNAMIC 会话 → 展示动态分析报告：
- 召回概览卡（路线点数 / 已匹配 / 漏过 / 覆盖率 / 是否按序 / Grade）
- 误差分布散点图（复用 `GpsScatterChart` 风格）
- 逐 RTK 点误差表（按 sequenceNo 排序，含 passed/ambiguous 标记）
- 静态/动态对比卡
- 轨迹地图（GPS 轨迹 + RTK 点 + 计划路线连线 + 匹配连线）

### 7.4 i18n

新增 key 写入 `lib/l10n/app_zh.arb` + `app_en.arb`，前缀 `gpsQuality`：
- `gpsQualityTabDynamic`（动态检验）
- `gpsQualityTestTypeStatic` / `gpsQualityTestTypeDynamic`
- `gpsQualityRoute` / `gpsQualityCoverage` / `gpsQualityMatchedCount` 等
- 现有 `gpsQualitySessionList` 改为 `gpsQualityTestList`（或保留为兼容）

## 8. 实现边界（本期不含）

| 不做 | 理由 |
|---|---|
| 参考轨迹（map-matching 横向偏差） | 需额外采集带时间戳的 RTK 真值序列，成本高；本期用离散经过点已满足需求 |
| 自动路线规划 | 测试人员手动编排，系统不规划 |
| 报告持久化/历史趋势 | 实时计算即可，避免缓存一致性 |
| 动态测试的连续性分析（速度跳变检测） | 30 分钟间隔下速度计算意义有限，列为后续 |
| 删除旧 `rtk_calibration_sessions` 表 | 本期保留作回滚保险，代码全部切到 `gps_quality_tests`；下迭代 DROP |

> **关于静态功能**：本期对静态功能做**统一迁移**（表名变更 + 字段统一 + 批量新增改造），但**静态报告的计算逻辑、阈值、Grade 判定完全不变**。迁移后静态报告结果与迁移前一致。

## 9. 验收标准

- [ ] 数据库迁移成功：`gps_quality_tests` 建表 + 旧 `rtk_calibration_sessions` 数据完整导入（含 test_type=STATIC）
- [ ] 静态报告（STATIC 会话）结果与迁移前一致（回归通过）
- [ ] 路径管理：创建路径 + 有序勾选 RTK 点 + 地图预览连线
- [ ] 创建动态测试（DYNAMIC 会话）→ 设备经过 ≥4 个 RTK 点 → 生成报告含召回/精度/分级
- [ ] 匹配阈值 T 可通过 query param 调整，默认 30m
- [ ] 歧义经过点在报告中单独标记（同门点 5/6、7/8、9/10 验证）
- [ ] 静态/动态对比正确展示同设备的两项结果
- [ ] **批量新增**：支持 STATIC 行（设备+RTK点）和 DYNAMIC 行（设备+路线）混合批量创建
- [ ] 前端中英文 i18n 完整
- [ ] 后端编译通过 + 前端 `flutter build web` 通过
- [ ] dev 部署后 curl 验证报告端点返回正确 JSON

## 10. 引用来源

- [NOVATEL — Understanding and Mitigating GNSS Multipath Interference](https://novatel.com/tech-talk/an-introduction-to-gnss/resources/understanding-and-mitigating-gnss-multipath-interference-and-error)（decorrelation 机制、农业慢速场景限定）
- [gps.gov — GPS Accuracy](https://archive.gps.gov/systems/gps/performance/accuracy/)（消费级精度 4.9m、FAA ≤1.82m）
- GPS World — *Accuracy in the Palm of Your Hand*（良好多径 2-3m，恶劣 10m+）
