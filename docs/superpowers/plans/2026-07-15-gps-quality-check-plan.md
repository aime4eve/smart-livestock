# GPS 数据质量检查功能 — 实施计划 (NIX-15)

- **工单**: [NIX-15](https://linear.app/nix-agentic/issue/NIX-15)
- **日期**: 2026-07-15
- **spec**: `docs/superpowers/specs/2026-07-15-gps-quality-check-spec-v2.md`（v2，已确认）
- **原型**: `docs/marketing/nix-15-gps-quality-prototype.html`（已确认）
- **评审**: `docs/superpowers/reviews/2026-07-15-gps-quality-check-spec-review.md`（4 阻塞项已在 spec v2 修正，6 建议项纳入本计划）

---

## 0. 实施总览

### 0.1 阶段与依赖

```
Phase A 数据库迁移 ──────┐
                         ├──▶ Phase C 应用服务 + API ──▶ 编译验证 ──▶ 部署 dev ──▶ 集成测试 ──▶ 提交 PR
Phase B 领域模型 + 统计 ──┘                                          ▲
                                                                    │
Phase D 前端（可与 C 并行）────────────────────────────────────────────┘
```

### 0.2 预检结论（plan 阶段已验证）

| 验证项 | 结论 |
|--------|------|
| DMS→十进制转换公式 | `deg + min/60 + sec/3600`，保留 7 位小数（DECIMAL(10,7)）✅ 已抽样验证 11 个点 |
| 5 台已绑定设备来源 | blade 平台运行时同步（非 Flyway 种子），无法在迁移中写死 `device_id` → **种子仅含 33 个 RTK 点；5 个标定会话通过 API 创建** |
| Flyway 版本号 | 最新 `V20260715122000`，本功能用 `V20260716...` 时间戳格式 |
| TIMESTAMPTZ 统一（A3） | **已取消**（判据 #17 + plan 评审 S2）：DB 实测精确匹配（diff=0），任何 ALTER TYPE 都违背判据 #17 不做换算。A3 不执行 |
| GPS+遥测 JOIN | LEFT JOIN 容错 0.6% miss，缺 step_number 时 suspect=false |

### 0.3 产出文件清单

| 层 | 文件 | 说明 |
|----|------|------|
| DB | `V20260716090000__create_rtk_tables.sql` | 2 张表 + 索引 |
| DB | `V20260716093000__seed_rtk_reference_points.sql` | 33 个 RTK 点 |
| 后端 | `iot/domain/model/` | RtkReferencePoint, RtkCalibrationSession, CalibrationStatus |
| 后端 | `iot/domain/service/GpsQualityCalculator.java` | 统计计算核心 |
| 后端 | `iot/application/dto/GpsPointWithTelemetry.java` | GPS+遥测 JOIN 投影 DTO（S4） |
| 后端 | `iot/application/` | 3 个 Application Service |
| 后端 | `iot/interfaces/admin/` | GpsQualityAdminController + DTO |
| 前端 | `features/admin/gps_quality/` | domain + data + presentation |
| 前端 | `lib/l10n/app_*.arb` | i18n 双语 |
| 前端 | `lib/app/app_route.dart` + `main_shell.dart` | 路由 + 菜单项 |

---

## Phase A — 数据库迁移（后端，无依赖）

### Task A1: 创建 RTK 表结构

**文件**: `smart-livestock-server/src/main/resources/db/migration/V20260716090000__create_rtk_tables.sql`

**内容**（spec v2 §5.1 + §5.2）:

```sql
-- rtk_reference_points: RTK 真值点（与设备解耦）
CREATE TABLE rtk_reference_points (
    id BIGSERIAL PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    point_label VARCHAR(50) NOT NULL,
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_rtk_ref_location ON rtk_reference_points(location_name);

-- rtk_calibration_sessions: 标定会话（关联 RTK 点与设备）
-- 审计列用 TIMESTAMP（跟随项目约定，22:0）；业务时间列用 TIMESTAMPTZ（判据 #17"保持同一基准"，
-- started_at/ended_at 直接参与 gps_logs.recorded_at BETWEEN 比较）
CREATE TABLE rtk_calibration_sessions (
    id BIGSERIAL PRIMARY KEY,
    rtk_point_id BIGINT NOT NULL REFERENCES rtk_reference_points(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,                  -- null = 进行中
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- S1: 同一设备只能有 1 个 IN_PROGRESS 会话
CREATE UNIQUE INDEX uq_rtk_session_device_active
  ON rtk_calibration_sessions(device_id) WHERE status = 'IN_PROGRESS';

CREATE INDEX idx_rtk_session_point ON rtk_calibration_sessions(rtk_point_id);
CREATE INDEX idx_rtk_session_device ON rtk_calibration_sessions(device_id);
CREATE INDEX idx_rtk_session_status ON rtk_calibration_sessions(status);
```

**验证**: `./gradlew compileJava` 通过；部署后 `\d rtk_reference_points` / `\d rtk_calibration_sessions` 确认结构。

---

### Task A2: 种子数据 — 33 个 RTK 真值点

**文件**: `smart-livestock-server/src/main/resources/db/migration/V20260716093000__seed_rtk_reference_points.sql`

**数据来源**: `docs/product/customer-journey.md` §8（33 个点，DMS 格式，6 个位置）

**转换规则**: DMS → 十进制，`deg + min/60 + sec/3600`，保留 7 位小数。位置分布：

| 位置 | 点数 | 序号范围 |
|------|------|---------|
| 宿舍楼顶 | 4 | 1-4 |
| 西南门 | 2 | 5-6 |
| 东南门 | 2 | 7-8 |
| 北门 | 2 | 9-10 |
| 一期楼顶 | 21 | 11-30 |
| 一期电梯楼顶 | 3 | 31-33（西中/东中/东南） |

**抽样转换验证**（plan 阶段已算）:

| 序号 | DMS 纬度 | 十进制纬度 | DMS 经度 | 十进制经度 |
|------|----------|-----------|----------|-----------|
| 1 | 28°14′43.40730″N | 28.2453909 | 112°51′02.81475″E | 112.8507819 |
| 11 | 28°14′47.73855″N | 28.2465940 | 112°51′05.79753″E | 112.8516104 |
| 33 | 28°14′47.20097″N | 28.2464447 | 112°51′05.69850″E | 112.8515829 |

**验证**: 部署后 `SELECT count(*) FROM rtk_reference_points` → 33；抽样对比经纬度精度。

---

### Task A3: ~~TIMESTAMPTZ 类型统一~~ — 已取消（判据 #17）

**原计划**: 将 `device_telemetry_logs.report_time` 从 TIMESTAMP 改为 TIMESTAMPTZ。

**取消原因**（plan 评审 S2 核实 + 判据 #17）:

1. **判据 #17 明确规定**: "第三方平台时间字段不带时区标识 → 直接用原始数值不做换算，保持同一基准"
2. **DB 实测**: `dtl.report_time` 存储值为 UTC 字面值，与 `gps_logs.recorded_at`(TIMESTAMPTZ) 精确匹配（diff=0）
3. 任何 ALTER TYPE（含 `AT TIME ZONE 'UTC'`）都是"做换算操作"，违背判据 #17
4. 当前 LEFT JOIN 已容错 0.6% 边缘 miss，类型标签差异不影响 JOIN 正确性

**同步修正**: spec v2 §5.5 的 `AT TIME ZONE 'Asia/Shanghai'` 也应删除（原建议有 +8h 偏移风险）。

> 此项如未来 JVM/PG timezone 配置变更确实需要，应作为独立维护项重新评估，不混入 NIX-15。

---

## Phase B — 后端领域模型 + 统计计算（依赖 Phase A）

### Task B1: 领域模型

**文件**:
- `iot/domain/model/RtkReferencePoint.java` — RTK 真值点聚合根
- `iot/domain/model/RtkCalibrationSession.java` — 标定会话聚合根
- `iot/domain/model/CalibrationStatus.java` — 枚举：`IN_PROGRESS`, `COMPLETED`, `CANCELED`

**关键方法**:
- `RtkCalibrationSession.end()` — IN_PROGRESS → COMPLETED，设 ended_at=now
- `RtkCalibrationSession.cancel()` — 任意状态 → CANCELED
- `RtkCalibrationSession` 含状态机校验（不可重复结束已完成的会话）

**验证**: `./gradlew test --tests "*.domain.model.*"` 通过。

---

### Task B2: GpsQualityCalculator（统计计算核心）

**文件**: `iot/domain/service/GpsQualityCalculator.java`

**职责**: 接收 GPS 点列表 + RTK 真值坐标，计算全部统计指标。纯领域逻辑，无 IO 依赖。

**计算项**（spec v2 §3-补 + §4-补 + §4）:

| 指标 | 算法 | 退化规则 |
|------|------|---------|
| 偏差距离 | haversine(gps_point, rtk_truth) | — |
| totalPoints | 输入点总数 | — |
| suspectPoints | step_number > 0 的点数 | — |
| effectivePoints | excludeSuspect ? total - suspect : total | — |
| meanError | 有效点偏差算术平均 | — |
| P50 | 有效点偏差第 50 百分位 | N≥5 |
| P95 | 第 95 百分位 | N<20 取 max 近似，标"低置信" |
| P99 | 第 99 百分位 | **N<100 不计算**（B3 修正） |
| maxError | 最大偏差 | — |
| 抖动直径 | 两两 haversine 最大值 | **N>500 用凸包近似**（S6） |
| outlierThreshold | N≥100 ? max(P99,3×P95,30m) : max(3×P95,30m) | — |
| outlierCount | 偏差 > outlierThreshold 的点数 | — |
| grade | 优秀/可用/勉强可用/不可用 | 基于 effectivePoints + P95（B4 修正） |

**等级判定逻辑**（spec v2 §3-补）:

```
if effectivePoints < 10           → UNAVAILABLE（数据不足）
else if P95 <= 15 && eff >= 20    → EXCELLENT
else if P95 <= 25 && eff >= 20    → USABLE
else if P95 <= 40 && eff >= 10    → MARGINAL
else                              → UNAVAILABLE
```

**验证**: 单元测试覆盖边界用例：
- N=0（无数据）、N=5（低样本退化）、N=20（最低有效）、N=48（典型）、N>500（凸包退化）
- excludeSuspect=true/false 两种模式
- P95 边界值（14.9m / 15.0m / 15.1m / 25.0m / 40.0m / 40.1m）

---

### Task B3: 仓储层 + JPA 实体

**文件**:
- `iot/infrastructure/persistence/entity/RtkReferencePointJpaEntity.java`
- `iot/infrastructure/persistence/entity/RtkCalibrationSessionJpaEntity.java`
- `iot/infrastructure/persistence/mapper/RtkReferencePointMapper.java`
- `iot/infrastructure/persistence/mapper/RtkCalibrationSessionMapper.java`
- `iot/infrastructure/persistence/SpringDataRtkReferencePointRepository.java`（JPA Repository 接口）
- `iot/infrastructure/persistence/SpringDataRtkCalibrationSessionRepository.java`
- `iot/infrastructure/persistence/JpaRtkReferencePointRepositoryImpl.java`（domain repository 实现）
- `iot/infrastructure/persistence/JpaRtkCalibrationSessionRepositoryImpl.java`
- `iot/domain/repository/RtkReferencePointRepository.java`（domain port）
- `iot/domain/repository/RtkCalibrationSessionRepository.java`

**查询方法**:
- `RtkCalibrationSessionRepository.findActiveByDeviceId(deviceId)` — partial index 对应查询
- `RtkCalibrationSessionRepository.findByRtkPointIdOrderByStartedAtDesc(rtkPointId)` — 多设备对比
- `RtkCalibrationSessionRepository.findByDeviceId(deviceId)` — 时间窗口重叠校验

**验证**: `./gradlew compileJava` 通过。

---

## Phase C — 后端应用服务 + API（依赖 Phase B）

### Task C1: RtkReferencePointService

**文件**: `iot/application/RtkReferencePointService.java`

**职责**: RTK 真值点 CRUD + DMS 格式转换（S4）。

**DMS 转换**（spec v2 §8-补）:
- 接受格式：`28°14′47.6″N`、`28°14'47.6"N`（′/′′ 和 '/" 均可）
- 方向标识：纬度 N/S，经度 E/W
- 转换为十进制保留 7 位小数
- 实现工具类 `iot/domain/service/DmsCoordinateConverter.java`

**验证**: 单元测试 — 各种 DMS 格式输入 → 十进制输出正确；非法格式抛异常。

---

### Task C2: RtkCalibrationSessionService

**文件**: `iot/application/RtkCalibrationSessionService.java`

**职责**: 会话生命周期管理。

**核心逻辑**:
1. **创建会话**: 校验设备无 IN_PROGRESS 会话（DB partial index 兜底）+ 时间窗口不重叠（S1 应用层校验）
2. **结束会话**: status=IN_PROGRESS → COMPLETED，ended_at=now
3. **取消会话**: 任意状态 → CANCELED
4. **回溯创建**: started_at + ended_at 均为过去 → 直接 COMPLETED

**时间窗口重叠校验**（S1）:
```
新会话 [newStart, newEnd) 与设备已有 COMPLETED 会话 [existStart, existEnd) 不可重叠：
  newStart < existEnd AND newEnd > existStart → 冲突，拒绝
```

**请求体验证规则**（S5）:
- `rtk_point_id` 不为 null，且在 `rtk_reference_points` 中存在
- `device_id` 不为 null，且在 `devices` 中存在（类型为 TRACKER）
- `started_at` 不为 null
- 如 `ended_at` 不为 null（回溯创建）：`ended_at > started_at`，且窗口时长 ≤ 7 天（性能约束，spec S2）
- 如 `ended_at` 为 null（实时标定）：设备无 IN_PROGRESS 会话（partial index 兜底）

**验证**: 单元测试 — 创建→结束→不可重复结束；重叠检测拦截。

---

### Task C3: GpsQualityReportService（报告组装）

**文件**: `iot/application/GpsQualityReportService.java`

**职责**: 查数据 → 调 GpsQualityCalculator → 组装报告 DTO。

**流程**（spec v1 §7.3）:
1. 查 session → 获取 rtk_point_id, device_id, started_at, ended_at
2. 查 rtk_reference_point → 获取 RTK 真值坐标
3. GPS + 遥测关联查询（spec v2 §7.6）:
   ```sql
   SELECT gl.latitude, gl.longitude, gl.accuracy, gl.recorded_at,
          dtl.step_number, dtl.motion_intensity, dtl.activity_class
   FROM gps_logs gl
   LEFT JOIN device_telemetry_logs dtl
     ON dtl.device_id = gl.device_id AND dtl.report_time = gl.recorded_at
   WHERE gl.device_id = :deviceId
     AND gl.recorded_at BETWEEN :startedAt AND :endedAt
     AND gl.latitude != 0 AND gl.longitude != 0
   ORDER BY gl.recorded_at
   ```
4. 对每个点算 haversine 偏差 + step_number>0 标 suspect
5. excludeSuspect=true 时过滤 suspect
6. 调 GpsQualityCalculator 计算统计
7. 匹配等级 + 组装 scatter 数据

**多设备对比** (`generateComparison(rtkPointId)`): 查该 RTK 点下所有 COMPLETED 会话 → 逐个生成报告摘要 → 聚合返回。

**新增投影 DTO**（S4）:

JOIN 查询返回字段含 GPS 数据 + 遥测数据（step_number 等），`GpsLog` 领域模型不含这些字段。需新增投影类:

```
iot/application/dto/GpsPointWithTelemetry.java   // 投影 DTO
  - 字段: latitude, longitude, accuracy, recordedAt, stepNumber, motionIntensity, activityClass
```

**新增查询接口**（三层）:
- `iot/domain/repository/GpsLogRepository.java` — 新增 `findByDeviceIdAndTimeRangeWithTelemetry(deviceId, startedAt, endedAt): List<GpsPointWithTelemetry>`
- `iot/infrastructure/persistence/SpringDataGpsLogRepository.java` — 原生 SQL JOIN 查询（@Query nativeQuery）
- `iot/infrastructure/persistence/JpaGpsLogRepositoryImpl.java` — 实现映射

**验证**: `./gradlew compileJava` 通过；部署后 curl 单设备报告 + 多设备对比。

**性能验证**（S2）: 对 7 天窗口（~336 点）查询做 EXPLAIN ANALYZE，确认分区剪枝生效。

---

### Task C4: 平台级设备查询端点

**文件**: 同 `GpsQualityAdminController`

**端点**: `GET /api/v1/admin/gps-quality/devices` — 跨租户查 TRACKER 类型设备（创建会话时选设备用）。

**实现**（三层，S3）:

| 层 | 文件 | 改动 |
|----|------|------|
| domain port | `iot/domain/repository/DeviceRepository.java` | 新增 `findAllTrackers()` |
| infrastructure JPA | `iot/infrastructure/persistence/SpringDataDeviceRepository.java` | 新增 `findByDeviceType(DeviceType.TRACKER)` JPQL 查询 |
| infrastructure impl | `iot/infrastructure/persistence/JpaDeviceRepositoryImpl.java` | 实现 domain port 方法 |

**验证**: curl 返回跨租户设备列表。

---

### Task C5: GpsQualityAdminController + DTO

**文件**:
- `iot/interfaces/admin/GpsQualityAdminController.java`
- `iot/interfaces/admin/dto/RtkPointDto.java`
- `iot/interfaces/admin/dto/CalibrationSessionDto.java`
- `iot/interfaces/admin/dto/QualityReportDto.java`
- `iot/interfaces/admin/dto/ComparisonDto.java`

**完整端点清单**:

| # | 端点 | 方法 | 说明 |
|---|------|------|------|
| 1 | `/rtk-points` | GET | RTK 点列表（?locationName= 筛选） |
| 2 | `/rtk-points` | POST | 新增（支持 DMS） |
| 3 | `/rtk-points/{id}` | PUT | 编辑 |
| 4 | `/rtk-points/{id}` | DELETE | 删除 |
| 5 | `/devices` | GET | 跨租户 TRACKER 设备列表 |
| 6 | `/sessions` | GET | 会话列表（?rtkPointId=&deviceId=&status=&page=&size= 分页） |
| 7 | `/sessions` | POST | 创建会话 |
| 8 | `/sessions/{id}/end` | PATCH | 结束会话 |
| 9 | `/sessions/{id}` | DELETE | 取消/删除会话 |
| 10 | `/sessions/{id}/report` | GET | 单设备报告（?excludeSuspect=false） |
| 11 | `/sessions/{id}/trajectory` | GET | 会话轨迹点序列（S3 补入） |
| 12 | `/comparison` | GET | 多设备对比（?rtkPointId=） |

**安全**（B1 修正）:

`GpsQualityAdminController` **必须**加类级角色注解:

```java
@RestController
@RequestMapping("/api/v1/admin/gps-quality")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")    // ← 必须！HTTP 层仅 .authenticated() 不校验角色
public class GpsQualityAdminController { ... }
```

> 代码库用 `@EnableMethodSecurity` + `@PreAuthorize` 做角色控制（参照 `TileAdminController`、`FenceController`）。`.anyRequest().authenticated()` 只检查登录，不限制角色——owner/worker 登录后同样能访问。加此注解后才限制为 platform_admin。

`/api/v1/admin/` 路径不含 `{farmId}`，FarmScopeInterceptor 自动跳过（spec v2 §7.5）。

**响应字段修正**（S3+S4 checklist）:
- 报告响应含 `totalPoints` + `effectivePoints`（B4）
- 对比响应 `rtkPoint` 字段统一用 `label` + `locationName`（评审建议字段命名统一）

**验证**: `./gradlew bootJar -x test` 通过。

---

## Phase D — 前端（可与 Phase C 并行）

### Task D1: 路由 + 菜单入口

**文件**:
- `lib/app/app_route.dart` — 新增 `platformGpsQuality('/admin/gps-quality', ...)`
- `lib/app/app_router.dart` — 新增 GoRoute，platform_admin 守卫
- `lib/app/main_shell.dart` — PopupMenuButton 增加 `platformGpsQuality` 项
- `lib/core/l10n/app_route_l10n.dart` — 路由 label i18n

**验证**: `flutter analyze` 无报错；platform_admin 登录后齿轮菜单出现「GPS 质量检查」。

---

### Task D2: 数据层 + 状态管理

**文件**:
- `features/admin/gps_quality/domain/rtk_point.dart`
- `features/admin/gps_quality/domain/calibration_session.dart`
- `features/admin/gps_quality/domain/gps_quality_report.dart`
- `features/admin/gps_quality/data/gps_quality_api_repository.dart` — 平台级 API（用 `get/post`，非 `farmGet`）

**状态管理**: Controller 继承普通 `AsyncNotifier`（非 farm-scoped，spec v1 §8.3）。

**验证**: `flutter analyze` 通过。

---

### Task D3: RTK 标定管理 Tab

**文件**: `features/admin/gps_quality/presentation/rtk_calibration_tab.dart`

**交互**（原型已确认，spec v2 §11.2-§11.3）:
- 左侧手风琴列表：按 `location_name` 分组，展开显示点位
- 右侧会话表格：选中点位 → 显示该点位的标定会话列表
- 「+ 新增点位」弹框：选位置（可新建）+ 填坐标（十进制或 DMS）
- 「+ 创建标定会话」弹框：选 RTK 点 + 选设备 + 填时间
- 进行中会话行有「结束」按钮 → 确认弹框
- 会话状态徽章（IN_PROGRESS=蓝 / COMPLETED=绿 / CANCELED=灰）

**验证**: `flutter build web` 通过。

---

### Task D4: 质量报告 Tab

**文件**:
- `features/admin/gps_quality/presentation/quality_report_tab.dart`
- `features/admin/gps_quality/presentation/widgets/scatter_chart.dart` — SVG 散点图
- `features/admin/gps_quality/presentation/widgets/error_histogram.dart` — 偏差分布直方图
- `features/admin/gps_quality/presentation/widgets/quality_grade_badge.dart` — 等级标签

**交互**（原型已确认，spec v2 §11.4-§11.5）:
- 筛选：位置 + 时间范围 → 多设备横向对比表
- 点击设备行 → 展开详情：统计指标卡（P50/P95/平均偏差/最大偏差/抖动直径/野点数）
- 每个指标有 ❓ tooltip 说明计算方法
- 「排除疑似移动点」复选框 → 重算统计（effectivePoints）
- 等级标准说明面板（展示阈值定义）
- 散点图：GPS 点围绕 RTK 真值中心的散布
- 直方图：偏差分布
- 「查看完整移动轨迹」按钮 → 弹出轨迹面板

**轨迹适配子任务**（S6）:

现有 `_TrajectorySheet`（`trajectory_sheet.dart`）是 livestock-centric + farm-scoped:
- 参数 `livestockId`（非 `deviceId`）
- 数据源 `/livestock/{id}/gps-logs`（farm-scoped，非平台级）
- 用 `farmGet()`（非 `get()`）

GPS 质量检查场景需要 device-centric + 平台级 API，**不能直接复用**。采用方案：

**新增 `SessionTrajectorySheet` widget**（复用地图渲染/haversine 逻辑，但数据层独立）:
- 参数 `sessionId`（非 `livestockId`）
- 数据源 `/api/v1/admin/gps-quality/sessions/{id}/trajectory`（平台级）
- 用 `get()`（非 `farmGet()`）
- 复用 `_TrajectorySheet` 中的 flutter_map 渲染、时间轴、坐标转换逻辑（提取为共享 mixin/helper）

**验证**: `flutter build web` 通过。

---

### Task D5: i18n

**文件**: `lib/l10n/app_zh.arb` + `lib/l10n/app_en.arb`（中英文同步）

**新增 key 组**（按功能模块）:
- `gpsQuality.*` — 页面标题、Tab 标签
- `gpsQuality.rtk.*` — RTK 标定管理文案
- `gpsQuality.report.*` — 质量报告文案（指标名、等级名、tooltip）
- `gpsQuality.session.*` — 会话操作（创建、结束、取消）

**验证**: `flutter gen-l10n` 无缺失 key；`flutter analyze` 无未定义翻译引用。

---

## Phase E — 编译验证 + 部署 + 集成测试

### Task E1: 后端编译

```bash
cd smart-livestock-server
./gradlew compileJava -q
./gradlew test --tests "*.iot.domain.model.*"  # 领域模型测试
./gradlew bootJar -x test
```

**验证**: 0 error。

---

### Task E2: 前端编译

```bash
cd Mobile/mobile_app
flutter gen-l10n
flutter analyze
./build_web.sh
```

**验证**: 0 error，0 critical warning。

---

### Task E3: 部署 dev 环境

```bash
cd smart-livestock-server
./scripts/deploy.sh dev
```

**验证**（S7 修正）:

> 注意：`/actuator/flyway` 默认不暴露（application.yml 无 `management.endpoints.web.exposure` 配置），用业务数据验证迁移成功。

```bash
# 健康检查
curl -s "http://172.22.1.123:19080/api/v1/actuator/health" | head -5

# 登录获取 token
TOKEN=$(curl -s -X POST "http://172.22.1.123:19080/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"13800000000","password":"123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['accessToken'])")

# RTK 点列表
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://172.22.1.123:19080/api/v1/admin/gps-quality/rtk-points" | python3 -m json.tool | head -20

# 33 个 RTK 点确认（迁移成功的业务验证，替代 /actuator/flyway —— S7）
curl -s -H "Authorization: Bearer $TOKEN" \
  "http://172.22.1.123:19080/api/v1/admin/gps-quality/rtk-points" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d['data']['items']))"

# 如需确认 flyway_schema_history（经验判据 #12），SSH 进容器:
#   docker exec sl-dev-postgres-1 psql -U postgres -d smart_livestock \
#     -c "SELECT version, script, success FROM flyway_schema_history WHERE version >= '20260716090000';"
```

---

### Task E4: 用户集成测试

**用户执行**（spec v2 §11 用户旅程）:
1. platform_admin 登录 → 齿轮菜单 → 「GPS 质量检查」
2. RTK 标定管理 Tab → 确认 33 个点位已加载
3. 为 5 台已绑定设备创建回溯标定会话
4. 质量报告 Tab → 查看统计 + 散点图 + 横向对比

---

## 任务依赖图与执行顺序

```
A1 ─┬─▶ B1 ─┬─▶ B3 ─▶ C1 ─┐
    │       │              ├─▶ C5 ─▶ E1 ─┐
    └─▶ A2  └─▶ B2 ─▶ C2 ──┘            ├─▶ E3 ─▶ E4 ─▶ 提交 PR
                            C3 ──────────┘     ▲
                                               │
    D1 ─▶ D2 ─┬─▶ D3 ─▶ D5 ─▶ E2 ─────────────┘
              └─▶ D4
```

**建议执行顺序**:
1. A1 → A2（数据库，~30min）
2. B1 → B2 → B3（领域+统计，~2h）—— B2 可并行写单元测试
3. C1 → C2 → C3 → C4 → C5（应用+API，~3h）
4. D1 → D2 → D3/D4 → D5（前端，~4h，可与 C 并行）
5. E1 → E2 → E3 → E4（编译+部署+测试）

---

## Spec §12 Checklist 对照

| Checklist 项 | 对应 Task | 状态 |
|-------------|----------|------|
| B3: P99 退化逻辑（N<100 跳过） | B2 | ☐ |
| B4: API 响应区分 totalPoints/effectivePoints | B2 + C5 | ☐ |
| S1: partial unique index + 重叠应用层校验 | A1 + C2 | ☐ |
| S2: 分区表 JOIN EXPLAIN ANALYZE | C3 | ☐ |
| S3: trajectory 端点补入端点表 | C5 | ☐ |
| S4: DMS 格式转换实现 | C1 | ☐ |
| S6: 抖动直径点数上限 + 凸包近似 | B2 | ☐ |
| 33 个 RTK 点 DMS→十进制 | A2 | ☐ |
| Flyway 种子迁移版本号 | A1/A2 | ☐ |
| GpsQualityCalculator 单元测试 | B2 | ☐ |
| GET /sessions 分页参数 | C5 | ☐ |
| comparison 端点字段命名统一 | C5 | ☐ |
| **B1**: `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` | C5 | ☐ |
| **S1**: 审计列统一 TIMESTAMP，业务列保持 TIMESTAMPTZ | A1 | ☐ |
| **S2**: A3 取消（判据 #17），spec §5.5 同步删除 | — | ☐ |
| **S3**: C4 跨租户设备查询三层路径 | C4 | ☐ |
| **S4**: `GpsPointWithTelemetry` 投影 DTO | C3 | ☐ |
| **S5**: POST /sessions 请求体验证规则 | C2 | ☐ |
| **S6**: `SessionTrajectorySheet` 适配子任务 | D4 | ☐ |
| **S7**: E3 用业务数据验证替代 /actuator/flyway | E3 | ☐ |

---

## 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| 分区表 ALTER report_time 类型（Task A3） | 可能影响分区键 | A3 标为可选，不阻塞核心功能；如执行需先验证分区表 |
| GPS+遥测 LEFT JOIN miss 0.6% | 少量点缺 step_number | LEFT JOIN 容错，缺值时 suspect=false，不影响 GPS 统计 |
| 前端散点图大数据量渲染 | N>500 时卡顿 | 后端 scatter 限 500 点（采样）；凸包近似抖动直径 |
| 跨租户设备查询性能 | devices 表全表扫 | TRACKER 类型 + 状态过滤 + 分页 |
