# NIX-15 GPS 数据质量检查 — 实施计划评审

- **评审日期**: 2026-07-15
- **评审对象**: `docs/superpowers/plans/2026-07-15-gps-quality-check-plan.md`
- **关联 spec**: `docs/superpowers/specs/2026-07-15-gps-quality-check-spec-v2.md`
- **评审结论**: ⚠️ 有条件通过（1 个阻塞项 + 7 个建议项）

---

## 评审摘要

这是一份结构良好的实施计划：依赖图清晰、任务粒度合理、验证标准明确、完整覆盖了 spec review 的全部修正项（B1-B4, S1-S6）。主要问题是**安全授权遗漏**（缺少 `@PreAuthorize`）以及几个实现细节的模糊性。整体评为"修正阻塞项后可进入实施"。

---

## 🔴 阻塞项

### B1. GpsQualityAdminController 缺少 `@PreAuthorize` 角色检查

**位置**: Task C5（安全描述）

**问题**: 计划声称 "所有端点 `.anyRequest().authenticated()` 已覆盖"，但这仅确保用户已登录，**不限制角色**。现有代码库中，`TileAdminController` 使用类级 `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")`，`FenceController` 针对 platform_admin 端点使用 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`。SecurityConfig 使用 `@EnableMethodSecurity` 依赖方法/类注解进行角色控制，不在 HTTP security 层配置。

无 `@PreAuthorize` 的情况下，任何已认证用户（包括 owner/worker）都能访问 GPS 质量检查端点。

**修正**: Task C5 中明确 `GpsQualityAdminController` 需加类级注解：

```java
@RestController
@RequestMapping("/api/v1/admin/gps-quality")
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class GpsQualityAdminController { ... }
```

---

## 🟡 建议项

### S1. rtk_reference_points 时间字段类型不一致

**位置**: Task A1 DDL

`rtk_calibration_sessions` 的 `created_at`/`updated_at` 使用 `TIMESTAMPTZ`，但 `rtk_reference_points` 的同名字段使用 `TIMESTAMP`。自 V20260710160000 起，项目已标准化 `TIMESTAMPTZ`（`gps_logs.recorded_at` 已修正）。两张新表应统一为 `TIMESTAMPTZ`。

**建议**: A1 DDL 中将 `rtk_reference_points.created_at` 和 `updated_at` 改为 `TIMESTAMPTZ`。

### S2. A3 迁移 `AT TIME ZONE 'Asia/Shanghai'` 代入 blade 数据可能错误

**位置**: Task A3 DDL + spec v2 §5.5

`gps_logs` 修正（V20260710160000）用 `AT TIME ZONE 'Asia/Shanghai'` 是因为历史数据在 JVM 时区未统一配置时写入，存储的 TIMESTAMP 值是 Asia/Shanghai 本地时间。

但 `device_telemetry_logs` 由 V20260709120000 创建，blade 数据经 `parseReportTime()` 以 `toInstant(ZoneOffset.UTC)` 写入，当前 JVM=UTC + PG timezone=Etc/UTC。Hibernate 写 Instant 到 TIMESTAMP 列时，在 UTC 环境下剥离时区后字面值即 UTC 时间。此时 `AT TIME ZONE 'Asia/Shanghai'` 会将 UTC 字面值当作 Asia/Shanghai 解释再转 UTC，**产生 8 小时偏移**。

**建议**: Plan 阶段先验证 dtl 表的实际存储值：
```sql
SELECT report_time, report_time AT TIME ZONE 'UTC' AS as_utc
FROM device_telemetry_logs LIMIT 5;
```
如果 `report_time` 和 `as_utc` 一致（差值 0），说明存储值即 UTC → USING 应改为 `AT TIME ZONE 'UTC'` 或直接 `ALTER COLUMN TYPE TIMESTAMPTZ`（PostgreSQL 对 TIMESTAMP→TIMESTAMPTZ 无 USING 时默认按 session timezone 转换，当前为 Etc/UTC 则不变）。

此任务已标记为可选（A3），但如未来执行，错误的 USING clause 会破坏 blade 遥测数据时间语义。建议在 plan 文档中记录此验证步骤。

### S3. C4 跨租户设备查询实现路径不完整

**位置**: Task C4

计划说 "`DeviceRepository.findAllTrackers()` 或在现有 repository 增加方法"，但未说明 DDD 分层实现路径。参照现有架构：

| 层 | 需修改/新增的文件 |
|----|-----------------|
| domain port | `DeviceRepository.java` — 新增 `findAllTrackers()` |
| infrastructure JPA | `SpringDataDeviceRepository.java` — 新增 `findByDeviceType()` JPQL 查询 |
| infrastructure impl | `JpaDeviceRepositoryImpl.java` — 实现 domain port 方法 |

**建议**: 在 C4 产出文件清单中明确列出这三层的改动。

### S4. C3 `findByDeviceIdAndTimeRangeWithTelemetry` 返回类型不明确

**位置**: Task C3

GpsLogRepository（domain port）当前方法的返回类型是 `List<GpsLog>`，但 GPS+遥测 JOIN 查询返回的字段包含 `step_number`, `motion_intensity`, `activity_class`（来自 `device_telemetry_logs`），这些字段不在 `GpsLog` 领域模型中。需要一个新的 DTO 或投影类来承载 JOIN 结果。

**建议**: 明确：
- 新增 `GpsLogWithTelemetry` 投影 DTO（或在 application 层定义）
- native SQL JOIN 写在 `SpringDataGpsLogRepository`（JPA 层），返回投影
- domain port `GpsLogRepository` 增加方法签名
- JPA 实现层做投影→DTO 映射

### S5. POST /sessions 缺少请求体验证规则

**位置**: Task C2 + C5

计划描述了创建会话的核心逻辑（IN_PROGRESS 检查、重叠检测），但未列出请求体验证规则：

**建议**: Task C2 补充以下校验：
- `started_at` 不为 null
- 如 `ended_at` 不为 null：`ended_at > started_at`
- `rtk_point_id` 存在
- `device_id` 存在且为 TRACKER 类型（或至少 device 状态为 ACTIVE）
- 如回溯创建（`ended_at` 不为 null），窗口时长不超过 7 天（S2 性能约束）

### S6. 前端 trajectory_sheet 复用适配成本被低估

**位置**: Task D4

计划说「点击『查看完整移动轨迹』→ 弹出 trajectory_sheet（复用）」。但当前 `_TrajectorySheet` 是 livestock 视角：按 `livestockId` 查询 GPS 数据，数据源来自 `GpsLogController`（farm-scoped）。GPS 质量检查场景需要按 `deviceId` + 会话时间窗口查询，数据源来自 `sessions/{id}/trajectory`（平台级 API）。

这意味着要么：
- 前端新增一个 device-centric 的轨迹 widget（复用 haversine/地图渲染逻辑，但数据层不同）
- 或者改造 `_TrajectorySheet` 支持两种数据源

**建议**: Plan 阶段评估适配方式，Task D4 增加子任务说明轨迹组件的改动范围。

### S7. 补充 flyway_schema_history 验证步骤

**位置**: Task E3（部署验证）

现有验证步骤仅检查 `/actuator/health` 和 RTK 点数。根据经验判据 #12（Flyway checksum mismatch），应增加迁移记录验证：

```bash
# 确认新迁移成功记录
curl -s "http://172.22.1.123:19080/api/v1/actuator/flyway" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for m in d['migrations']:
    if m['script'].startswith('V20260716'):
        print(f\"{m['script']}: {m['state']} (checksum={m['checksum']})\")"
```

---

## 🟢 正面评价

1. **完整覆盖 spec review**: Phase A-C 逐一落实了 spec review 的 B3/B4/S1-S6 全部修正项，§12 Checklist 对照表一目了然
2. **依赖图清晰**: 阶段图 + 任务 DAG 正确表达了 A→B→C→E、D 可与 C 并行的拓扑关系
3. **预检充分**: plan 阶段已验证 DMS 转换公式、设备来源方式、JOIN 匹配率、版本号，减少返工风险
4. **风险表实用**: 4 个风险均有明确缓解措施，LEFT JOIN 容错 + 散点采样上限 + A3 可选标记
5. **验证标准具体**: 每个 Task 都标注了可执行的验证命令，不靠主观判断
6. **遵循 DDD 分层**: domain service（GpsQualityCalculator）纯计算、application service 组装、controller 薄层
7. **i18n/seed data 纳入计划**: D5 + A2 遵循 CLAUDE.md 强制规范
8. **时间评估合理**: 4 阶段总约 10h（含并行），不激进

---

## 📋 修正 checklist

- [ ] **B1**: C5 补充 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`
- [ ] S1: A1 DDL 中 `rtk_reference_points` 时间字段统一为 TIMESTAMPTZ
- [ ] S2: A3 补充 dtl 存储值验证步骤（确认 `AT TIME ZONE` 语义正确）
- [ ] S3: C4 明确三层（domain port → JPA → impl）文件清单
- [ ] S4: C3 明确 JOIN 投影 DTO + 各层方法签名
- [ ] S5: C2 补充请求体验证规则
- [ ] S6: D4 评估 trajectory_sheet 适配方式
- [ ] S7: E3 补充 flyway_schema_history 验证

---

## 总结

计划质量高，依赖关系和验证标准清晰。唯一的阻塞项（B1 `@PreAuthorize`）是规范性的代码行补充，不改动架构。修正后可进入实施。
