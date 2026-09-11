# NIX-15 实施计划评审意见核实报告

- **核实日期**: 2026-07-15
- **被核实文档**: `docs/superpowers/reviews/2026-07-15-gps-quality-check-plan-review.md`
- **核实方式**: 代码 grep + 数据库实测 + 配置文件核查
- **判据基准**: 经验判据 #17（第三方平台时间不带时区标识 → 不做换算，保持同一基准）
- **结论**: 1 阻塞项 + 7 建议项中，6 项成立、1 项部分成立、1 项事实性错误

---

## 核实结论汇总

| 编号 | 评审论断 | 核实结论 | 判定 |
|------|---------|---------|------|
| B1 | `@PreAuthorize` 角色检查遗漏 | `@EnableMethodSecurity` + `@PreAuthorize` 是项目角色控制标准模式，HTTP 层仅有 `.anyRequest().authenticated()` | ✅ **正确（阻塞）** |
| S1 | rtk_reference_points 时间字段应为 TIMESTAMPTZ | 不一致**客观存在**，但"项目标准化 TIMESTAMPTZ"**事实错误**（22:0）。真正依据是判据 #17"保持同一基准"——业务时间列用 TIMESTAMPTZ 正确 | ⚠️ **观察正确，论据错误** |
| S2 | A3 `AT TIME ZONE 'Asia/Shanghai'` 对 dtl 数据会偏移 | DB 实测确认存储值为 UTC 字面值。但判据 #17 结论更强：**A3 不应执行**——当前精确匹配，#17 禁止对 blade 时间做换算 | ✅ **正确，修正更彻底** |
| S3 | C4 跨租户设备查询三层路径未明确 | `DeviceRepository` 无跨租户查询方法，三层模式是项目标准 | ✅ **正确** |
| S4 | C3 JOIN 投影 DTO 缺失 | `GpsLog` 不含 step_number 等字段 | ✅ **正确** |
| S5 | POST /sessions 缺请求体验证规则 | 计划 C2 未列字段级校验 | ✅ **正确** |
| S6 | trajectory_sheet 复用成本被低估 | 确认 livestock-centric + farm-scoped，不能直接复用 | ✅ **正确** |
| S7 | 补充 `/actuator/flyway` 验证 | `application.yml` 无 exposure 配置，`/actuator/flyway` 默认 404 | ⚠️ **意图正确，方法不可行** |

---

## 🔴 B1. `@PreAuthorize` 角色检查遗漏 — ✅ 确认正确（阻塞项）

### 核实证据

**1. SecurityConfig 使用 `@EnableMethodSecurity`**:

```java
// SecurityConfig.java line 26
@EnableMethodSecurity
```

HTTP security 层（line 45-53）仅有:
```java
.authorizeHttpRequests(auth -> auth
    .requestMatchers(HttpMethod.POST, "/api/v1/auth/login", ...).permitAll()
    .requestMatchers("/health").permitAll()
    .requestMatchers("/api/v1/open/**").authenticated()
    .anyRequest().authenticated()    // ← 只检查登录，不检查角色
)
```

**2. 现有 Controller 均使用 `@PreAuthorize` 做角色控制**:

```java
// TileAdminController.java line 19 — 类级注解
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class TileAdminController { ... }

// FenceController.java line 117 — 端点级注解
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
```

**3. 计划声称的覆盖方式是错误的**:

计划原文："所有端点 `.anyRequest().authenticated()` 已覆盖（SecurityConfig 无需改动）"

这仅确保用户已登录，**不限制角色**。owner/worker 登录后同样能访问。

### 结论

**B1 成立**。`GpsQualityAdminController` 必须加类级 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`。

---

## ⚠️ S1. 时间字段类型不一致 — 观察正确，论据错误

### 评审论断核实

**评审原文**:
> "自 V20260710160000 起，项目已标准化 TIMESTAMPTZ（`gps_logs.recorded_at` 已修正）。两张新表应统一为 TIMESTAMPTZ。"

### 代码实测：项目审计列约定是 TIMESTAMP

全项目迁移文件中 `created_at` 列类型统计:

| 类型 | 出现次数 | 代表迁移 |
|------|---------|---------|
| `created_at TIMESTAMP`（无时区） | **22** | V1 identity, V2 ranch, V20 health, V20260709120000 device_telemetry_logs, V22 analytics |
| `created_at TIMESTAMPTZ` | **0** | — |

**V20260710160000 仅修正了 `gps_logs.recorded_at`**（一个业务数据列），不是项目级"标准化 TIMESTAMPTZ"。项目审计列（created_at/updated_at）约定一直是 `TIMESTAMP`。评审"项目已标准化 TIMESTAMPTZ"的论据**事实错误**。

### 计划中的真实不一致

| 表 | created_at/updated_at | started_at/ended_at |
|----|----------------------|-------------------|
| rtk_reference_points | TIMESTAMP | — |
| rtk_calibration_sessions | TIMESTAMPTZ | TIMESTAMPTZ |

审计列确实不一致（评审观察正确），但修正方向要看业务语义。

### 判据 #17 纠正："保持同一基准"决定业务列类型

判据 #17 核心原则："不做换算，保持同一基准"。

`rtk_calibration_sessions.started_at`/`ended_at` 直接参与 `gps_logs.recorded_at BETWEEN started_at AND ended_at` 比较。`gps_logs.recorded_at` 是 TIMESTAMPTZ（UTC 基准）。为"保持同一基准"，`started_at`/`ended_at` **必须是 TIMESTAMPTZ**——这不是跟随项目约定，而是判据 #17 的硬要求。

### 正确修正方向

- **审计列（created_at/updated_at）**: 两表统一为 `TIMESTAMP`（跟随项目 22:0 约定，审计列不参与 blade 数据 JOIN）
- **业务时间列（started_at/ended_at）**: 保持 `TIMESTAMPTZ`（判据 #17"保持同一基准"，与 `gps_logs.recorded_at` 直接可比，无隐式转换风险）

### 结论

**S1 观察成立（两表不一致需修正），但评审论据（"项目标准化 TIMESTAMPTZ"）事实错误，修正方向应限于审计列统一为 TIMESTAMP**。业务时间列用 TIMESTAMPTZ 是判据 #17 的正确要求，不需要改。

---

## ✅ S2. A3 不应执行 — 判据 #17 结论更强

### 评审论断核实

**评审原文**:
> "`device_telemetry_logs` 由 V20260709120000 创建，blade 数据经 `parseReportTime()` 以 `toInstant(ZoneOffset.UTC)` 写入。此时 `AT TIME ZONE 'Asia/Shanghai'` 会将 UTC 字面值当作 Asia/Shanghai 解释再转 UTC，产生 8 小时偏移。"

### 代码核实：同一 Instant 写两表

```
parseReportTime() → ldt.toInstant(ZoneOffset.UTC)     // 判据 #17：原始值当 UTC
        ↓ 同一个 effectiveRecordedAt (TelemetryIngestionService line 70)
   ├─ line 229: setReportTime(recordedAt)   → dtl.report_time (TIMESTAMP)
   └─ line 247: logGps(..., recordedAt)     → gps_logs.recorded_at (TIMESTAMPTZ)
```

blade reportTime 原始值（如 `2026-07-13 09:08:45`）被 `toInstant(ZoneOffset.UTC)` 解析后，同一个 Instant 写入两张表。

### 配置核实

```
Dockerfile:     FROM eclipse-temurin:17-jre（默认 TZ=UTC）
docker-compose: 无 TZ 环境变量
application.yml: 无 hibernate.jdbc.time_zone 配置
→ JVM 时区 = UTC
```

### 数据库实测（dev 环境 sl-dev-postgres-1，2026-07-15）

```sql
SELECT report_time, report_time AT TIME ZONE 'UTC' AS as_utc_tz
FROM device_telemetry_logs ORDER BY report_time DESC LIMIT 5;
```

```
     report_time     |       as_utc_tz
---------------------+------------------------
 2026-07-15 21:37:42 | 2026-07-15 21:37:42+00
```

存储值即 UTC 字面值（`report_time` 与 `as_utc_tz` 一致，无偏移）。

```sql
SELECT gl.recorded_at AS gps_time, dtl.report_time AS dtl_time,
       gl.recorded_at = dtl.report_time AS exact_match, ...
FROM gps_logs gl
LEFT JOIN device_telemetry_logs dtl ON dtl.device_id = gl.device_id AND dtl.report_time = gl.recorded_at
```

```
        gps_time        |      dtl_time       | exact_match | diff_seconds
------------------------+---------------------+-------------+--------------
 2026-07-13 09:08:45+00 | 2026-07-13 09:08:45 | t           |     0.000000
```

`gps_logs.recorded_at`（TIMESTAMPTZ, UTC）与 `dtl.report_time`（TIMESTAMP, UTC 字面值）**精确匹配，diff=0**。

### 判据 #17 纠正：A3 不应执行

之前我的结论是"A3 USING clause 应改为 `AT TIME ZONE 'UTC'`"。**这个结论不够**。

判据 #17 明确规定："直接用原始数值不做换算，不要猜对方时区；保持同一基准"。

当前事实：
1. 同一个 Instant 写两表，存储值字面一致
2. DB 实测 JOIN 精确匹配（diff=0）
3. 两表已在 UTC 基准下"保持同一基准"

A3 迁移（无论 USING clause 写什么）都是**对 blade 时间字段做换算操作**——直接违背判据 #17。即使写 `AT TIME ZONE 'UTC'` 或不带 USING，本质都是在"操作"一个判据明确说"不该动"的字段。

### 结论

**S2 偏移风险真实存在**（DB 实测确认 `AT TIME ZONE 'Asia/Shanghai'` 会 +8h），但判据 #17 给出更强结论：

> **A3 不应执行。spec v2 §5.5 的 `AT TIME ZONE 'Asia/Shanghai'` 应删除。**

理由：当前两表在 UTC 基准下精确匹配，判据 #17 禁止对 blade 时间做任何换算。类型不一致是 TIMESTAMP 列的"标签"问题，不影响 JOIN 正确性（DB 实测证明）。LEFT JOIN 容错已覆盖 0.6% 边缘 miss。

---

## ✅ S3. C4 跨租户设备查询三层路径未明确 — 确认正确

### 核实证据

`DeviceRepository`（domain port）现有方法:

```java
public interface DeviceRepository {
    Optional<Device> findByDeviceCode(String deviceCode);
    List<Device> findByTenantId(Long tenantId);                    // ← 租户级
    long countByTenantIdAndStatus(Long tenantId, String status);   // ← 租户级
    List<Device> findByTenantIdPaged(Long tenantId, int offset, int limit);
    List<Long> findActivePlatformDeviceIds(int offset, int limit);
}
```

**无跨租户查询所有 TRACKER 的方法**。

### 结论

**S3 成立**。C4 应明确三层：domain port → SpringData JPA → JpaImpl。

---

## ✅ S4. JOIN 投影 DTO 缺失 — 确认正确

### 核实证据

`GpsLog` 领域模型字段:

```java
public class GpsLog extends Entity {
    private Long deviceId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private Instant recordedAt;
}
```

JOIN 需要返回 `step_number`, `motion_intensity`, `activity_class`（来自 `device_telemetry_logs`），**不在 GpsLog 中**。

### 结论

**S4 成立**。需新增投影 DTO（如 `GpsPointWithTelemetry`）。

---

## ✅ S5. POST /sessions 缺请求体验证 — 确认正确

### 结论

计划 C2 描述了会话生命周期和时间窗口重叠校验，但未列请求体字段级校验规则。C2 应补充验证规则清单。

---

## ✅ S6. trajectory_sheet 复用成本被低估 — 确认正确

### 核实证据

`trajectory_sheet.dart`:

```dart
// line 20: 参数是 livestockId（不是 deviceId）
// line 181: '/livestock/${widget.livestockId}/gps-logs?...'  ← farm-scoped
// line 186: ApiClient.instance.farmGet(url)                    ← farm-scoped
```

GPS 质量检查需 deviceId + 平台级 API + `get()`。

### 结论

**S6 成立**。不能直接复用，需新增 device-centric 轨迹 widget 或改造 `_TrajectorySheet` 支持双数据源。D4 应增加适配子任务。

---

## ⚠️ S7. `/actuator/flyway` 验证步骤 — 意图正确，方法不可行

### 核实证据

`application.yml` 无 `management.endpoints.web.exposure` 配置。Spring Boot Actuator 默认仅暴露 `/actuator/health` 和 `/actuator/info`。`/actuator/flyway` **默认 404**。

### 结论

**S7 意图正确**（验证迁移成功，符合经验判据 #12），但 `/actuator/flyway` 不可用。E3 已有业务数据验证（`SELECT count(*) FROM rtk_reference_points` → 33）替代。

---

## 总结：Plan 修正清单

| 编号 | 判定 | 修正动作 |
|------|------|---------|
| **B1** | ✅ 正确（阻塞） | C5 加 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")` |
| S1 | ⚠️ 论据错误 | 审计列统一为 `TIMESTAMP`（跟随项目 22:0 约定）；业务列 started_at/ended_at 保持 `TIMESTAMPTZ`（判据 #17"保持同一基准"） |
| S2 | ✅ 正确，结论更强 | **A3 删除**——判据 #17 禁止对 blade 时间做换算，当前精确匹配无需操作；同步删除 spec v2 §5.5 |
| S3 | ✅ 正确 | C4 明确三层文件清单 |
| S4 | ✅ 正确 | C3 新增 `GpsPointWithTelemetry` 投影 DTO |
| S5 | ✅ 正确 | C2 补充请求体验证规则 |
| S6 | ✅ 正确 | D4 增加轨迹适配子任务 |
| S7 | ⚠️ 方法不可行 | E3 已有业务数据验证；flyway endpoint 需先配置 exposure |
