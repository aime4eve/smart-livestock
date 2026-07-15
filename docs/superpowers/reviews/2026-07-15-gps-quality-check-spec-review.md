# NIX-15 GPS 数据质量检查 — 设计规格评审

- **评审日期**: 2026-07-15
- **评审对象**: `docs/superpowers/specs/2026-07-15-gps-quality-check-spec.md`
- **评审结论**: ⚠️ 有条件通过（4 个阻塞项需在设计阶段修正，6 个建议项在 plan 阶段处理）

---

## 评审摘要

这是一份质量较高的设计规格，问题定义清晰、非目标明确、DDD 分层合理、设计决策有理有据。主要问题集中在：数据模型时区不一致、JOIN 查询可行性未验证、统计指标在低样本量下的退化、以及部分 API 细节遗漏。以下按严重程度排列。

---

## 🔴 阻塞项（建议设计阶段修正后再进入 plan）

### B1. `TIMESTAMPTZ` vs `TIMESTAMP` 类型不一致导致查询语义模糊

**位置**: §5.2 `rtk_calibration_sessions` DDL + §7.6 JOIN 查询

`rtk_calibration_sessions.started_at` 和 `ended_at` 定义为 `TIMESTAMPTZ`，但 `gps_logs.recorded_at` 和 `device_telemetry_logs.report_time` 都是 `TIMESTAMP`（无时区）。当 `BETWEEN :startedAt AND :endedAt` 时，JDBC 驱动会将 `TIMESTAMPTZ` 参数转为 UTC 或 session timezone，而 `gps_logs.recorded_at` 存储的是 blade 平台原始时间戳（无时区语义），二者比较可能产生时区偏移。

**建议**: 统一为 `TIMESTAMPTZ` 或明确 `rtk_calibration_sessions` 的时间字段也使用 `TIMESTAMP`（与 `gps_logs` 保持一致）。考虑到 blade 平台时间戳无时区标识（见经验判据 #17），建议会话表统一用 `TIMESTAMP`，并在服务层明确所有时间比较基于 UTC 基准。

### B2. GPS + 遥测 JOIN 精确匹配不可靠，未给出替代方案

**位置**: §7.6 + §10 待验证项 #1

`gl.recorded_at = dtl.report_time` 精确等值 JOIN 在两个独立写入的表中极易因毫秒精度差异导致 miss。`gps_logs` 和 `device_telemetry_logs` 虽然在同一快照中写入，但 `device_telemetry_logs` 是分区表（按 `report_time` 分区），且两个字段都是 `TIMESTAMP` 而非 `TIMESTAMPTZ`。

**建议**: 在 plan 阶段优先验证以下替代方案：
- **方案 A** (推荐): 检查 blade 遥测快照是否有 `snapshot_id` 或 batch id 可用于关联，替代时间戳 JOIN
- **方案 B**: 使用时间窗口匹配，如 `dtl.report_time BETWEEN gl.recorded_at - INTERVAL '1 second' AND gl.recorded_at + INTERVAL '1 second'`
- **方案 C**: 如果 step_number 只在少数点有用（仅作为"疑似移动"辅助标记），考虑先查 `gps_logs`，再按 `(device_id, recorded_at)` 批量查 `device_telemetry_logs`，在应用层做近邻匹配

在 spec 中至少记录选择方案及容忍的 miss rate。

### B3. 统计指标 P99 在低样本量下退化严重

**位置**: §2 野点定义 + §4 统计指标

野点阈值定义为 `max(P99, 3×P95, 30m)`。对于 N=20 的会话（优秀/可用等级的最低要求），P99 就是第 19.8 个点 ≈ 最大值本身。这意味着对于小样本，"野点"检测几乎不可能触发（除非单点偏差 > 30m），因为 P99 ≈ max，而没有任何点能"超过"最大值。

**建议**: 
- 为 P99 添加最小样本量要求（如 N ≥ 100），低于此值时只使用 `max(3×P95, 30m)` 作为阈值
- 或在统计指标表中注明"P99 仅在 N ≥ 100 时有意义，小样本时野点判定降级为 `max(3×P95, 30m)`"

### B4. 质量等级的样本量判定时机未定义

**位置**: §3 质量等级标准

"样本 ≥ 20" 和 "样本 ≥ 10" 指的是原始点数还是排除疑似移动点后的有效点数？如果用户选择 `excludeSuspect=true`，一个 22 点有 5 个疑似移动点的会话，实际有效点只有 17 个，是否降级为"不可用"？

**建议**: 明确"样本点数"的定义：
- 如果样本数 = `totalPoints - suspectPoints`（排除后），需在 API 响应中同时返回 `totalPoints` 和 `effectivePoints`，等级基于 `effectivePoints`
- 如果样本数 = `totalPoints`（原始），需注明"包含疑似移动点"

---

## 🟡 建议项（plan 阶段处理）

### S1. 唯一约束缺少数据库层面强制执行

**位置**: §5.2 约束

"同一设备同一时间只能有 1 个 IN_PROGRESS 会话"需要 partial unique index：
```sql
CREATE UNIQUE INDEX idx_rtk_session_device_active
  ON rtk_calibration_sessions(device_id)
  WHERE status = 'IN_PROGRESS';
```

"同一设备的多个会话时间窗口不可重叠"在 DB 层面难以用约束实现（需 exclusion constraint + tsrange），建议明确由应用层校验（`RtkCalibrationSessionService` 在创建时检查重叠），并在 spec 中注明。

### S2. `device_telemetry_logs` 分区表对查询性能的影响

**位置**: §7.6

`device_telemetry_logs` 按 `report_time` 分区。如果会话时间窗口跨越多天且数据量大，JOIN 可能扫描多个分区。建议在 spec 中注明：
- 单次会话窗口建议不超过 7 天（确保分区剪枝有效）
- 如果单设备每日上报 ~288 点（5 分钟间隔），7 天约 2000 点，性能可控
- 需要在 plan 阶段用真实数据量做 EXPLAIN ANALYZE

### S3. 轨迹端点遗漏

**位置**: §6.4

"设备详情中「查看完整移动轨迹」复用现有...端点"表述矛盾：这是新端点还是复用已有？端点表（§6.2-6.3）中未列出该端点，但路径在 §6.4 中给出了。如果是新端点，应补入端点表。另外，该端点的权限和参数需明确（当前只说了路径，没说返回结构）。

### S4. DMS 格式转换规范缺失

**位置**: §6.1 POST RTK 真值点

"支持 DMS 格式自动转换"但没有定义接受的 DMS 格式。业界常见变体：
- `40°26'46.0"N 116°30'29.0"E`（度分秒 + 方向）
- `40:26:46.0N 116:30:29.0E`
- `40°26.767'N 116°30.483'E`（度 + 十进制分）

**建议**: 明确接受的 DMS 格式，并注明转换精度（至少保留 7 位小数）。

### S5. FarmScopeInterceptor 跳过逻辑的描述偏差

**位置**: §7.5

"路径前缀 `/api/v1/admin/` 已被 `FarmScopeInterceptor` 跳过 farm ownership 校验（见 `isPlatformAdmin()` 逻辑）"——实际代码逻辑是：`FarmScopeInterceptor.preHandle` 在 `FarmIdPathParser.extractFarmId(uri)` 返回 null 时直接 `return true`（即完全不拦截）。新端点路径不含 `{farmId}`，自然被跳过，与 `isPlatformAdmin()` 无关。`isPlatformAdmin()` 仅用于含 `{farmId}` 的路径跳过租户归属校验。

实际结论不变（平台级 API 不会被 farm scope 拦截），但描述应准确：**因为路径不含 `{farmId}` 变量，`FarmScopeInterceptor` 不做任何拦截**。

### S6. 抖动直径 O(n²) 计算成本

**位置**: §4

"抖动直径 = 所有点两两 haversine 距离的最大值"——48 个点约 1128 对，可接受。但如果会话窗口很大（如 30 天 × 288 点/天 = 8640 点），两两组合约 3700 万对，性能不可接受。

**建议**: 添加会话点数上限建议（如单次会话 ≤ 500 点），或在 `GpsQualityCalculator` 中用 convex hull 近似算法（凸包直径 ≈ 抖动直径）。

---

## 🟢 正面评价

1. **问题边界清晰**: §1.3 非目标明确排除了实时漂移修正、围栏预警改造、加速度计优化，避免范围蔓延
2. **设计决策有据**: §9 的 5 个决策都附有理由，特别是"静止由时间窗口定义不由传感器推断"基于加速度计 27-34% 误报率实测数据
3. **数据模型解耦**: RTK 真值与设备分表，支持多对多测试关系（同一位置多设备、同一设备多位置）
4. **DDD 分层合理**: `GpsQualityCalculator` 放在 domain/service，报告组装在 application，职责分离清晰
5. **统计结果实时计算**: 不持久化统计结果，避免缓存一致性问题，会话点数量小，计算成本低
6. **i18n 和 seed data**: §8.4 和 §5.4 遵循了 CLAUDE.md 的强制规范
7. **正确使用平台级 API**: 识别到 platform_admin 无 farm scope，未错误使用 farm-scoped 端点

---

## 📋 Plan 阶段 checklist（从 spec §10 提取 + 本评审补充）

- [ ] B1: 统一时间字段类型（TIMESTAMPTZ → TIMESTAMP 或反之）
- [ ] B2: GPS + 遥测 JOIN 方案选择与验证（优先 snapshot_id / 时间窗口 / 应用层匹配）
- [ ] B3: P99 小样本退化 → 补充样本量门限
- [ ] B4: 质量等级样本计数规则（排除 suspect 前后）
- [ ] S1: IN_PROGRESS partial unique index + 时间窗口重叠应用层校验
- [ ] S2: 分区表 EXPLAIN ANALYZE + 会话窗口上限建议
- [ ] S3: trajectory 端点补入端点表，明确返回结构
- [ ] S4: DMS 格式规范 + 转换精度
- [ ] S6: 抖动直径点数上限 / 凸包近似
- [ ] §10.1: 时间戳精确匹配可靠性验证
- [ ] §10.2: 33 个 RTK 点 DMS → 十进制转换精度验证
- [ ] §10.3: Flyway 种子数据迁移版本号分配（使用时间戳格式 `V20260715...`）
- [ ] §10.4: 散点图 SVG 渲染性能（真实数据量）
- [ ] §10.5: 轨迹复用方案（按 deviceId → 与现有 livestockId 查询的差异评估）
- [ ] 补充: 测试策略（GpsQualityCalculator 单元测试 + 统计查询集成测试）
- [ ] 补充: GET /sessions 分页参数
- [ ] 补充: POST /sessions 请求体定义（创建时需要哪些字段？）
- [ ] 补充: comparison 端点响应中 `rtkPoint.label` 与 `locationName` 字段命名不一致修正

---

## 总结

这份 spec 在架构决策、DDD 分层、API 设计方面是扎实的。4 个阻塞项都集中在数据层：时区一致性、JOIN 可行性、统计边界条件。这些问题不涉及架构改动，在设计阶段澄清即可。建议修正后再进入 plan 阶段。
