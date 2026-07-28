# NIX-68 GPS 线路检验（LINE）方案设计评审

| 字段 | 值 |
|---|---|
| 评审对象 | [2026-07-28-nix68-track-line-inspection-spec.md](../specs/2026-07-28-nix68-track-line-inspection-spec.md) |
| 工单 | NIX-68 增强GPS质量检验的"轨迹检验"功能（Urgent） |
| 评审日期 | 2026-07-28 |
| 评审人 | Codex Agent |
| 结论 | **有条件通过** — 需用户确认 P0 范围决策后方可进入 plan 阶段 |

---

## 评审总结

方案整体设计质量高：继承关系（§3）的"三类既有功能零改动"声明扎实、代码引用基本准确、快照哲学（D4）有充分论证。但存在一个核心需求偏差和两个工程性风险需要处理。

**核心问题**：用户工单明确要求"根据导入的多条标准轨迹线路**计算出一条**标准轨迹线路"，spec D3 将此合成算法推迟到二期，本期仅做追加式候选管理。这是用户的首要需求，spec 做了静默降级。

**按严重度排列的发现**：

| 级别 | 编号 | 标题 |
|---|---|---|
| P0 | F1 | 合成算法推迟到二期 vs 用户核心需求 |
| P1 | F2 | 多设备 LINE 计算的同步请求超时风险 |
| P1 | F3 | 报告/对比端点响应体积无分页 |
| P2 | F4 | GpsQualityTest 实体层改动未在 spec 中记录 |
| P2 | F5 | 缺少查询性能索引建议 |
| P3 | F6 | TestType.java 行号引用偏移 |
| P3 | F7 | XLSX 坐标解析 \r\n 处理未显式说明 |

---

## P0 — 阻塞项

### F1：合成算法推迟到二期 vs 用户核心需求

**位置**：D3（§2 决策表）、§10 实现边界

**问题**：Linear 工单 NIX-68 原文：

> 我会在相同线路上导入这样的多条标准轨迹线路。**你可以根据导入的这些数据，计算出一条标准的轨迹线路。**

用户的核心诉求是：导入多条同物理线路的轨迹数据后，系统**自动合成**一条标准轨迹。spec D3 将此明确推迟到二期（"合成（勾选 ≥2 条）为二期，本期只做入口与交互预留"），本期改为"追加式候选管理 + 手动选定"。

这与 AGENTS.md §1 的原则冲突——"如果存在多种理解，列出来——不要静默选择"。spec 没有在显著位置标注此需求偏差，也没有说明选择降级的理由供用户决策。

**影响**：用户按原始需求验收时会发现核心功能缺失。

**建议**：在 spec 开头加一个**醒目的范围声明**，明确告知用户：

- 本期实现：XLSX 导入 → 候选管理 → 手动选定一条标准轨迹 → LINE 检验
- 本期不做：从多条候选自动合成一条标准轨迹（二期）
- 理由：合成算法需要先积累真实多线路数据来验证策略（加权平均 / 中轴线 / Fréchet 距离对齐），盲做风险高

**决策点**：用户需明确批准"本期手动选定单条、二期合成"的范围切分，或者要求一期即实现合成。如果用户坚持合成在第一期，则需要新的算法设计章节（合成策略、对齐方式、质量评估），spec 的规模和复杂度会显著增加。

---

## P1 — 高优先级

### F2：多设备 LINE 计算的同步请求超时风险

**位置**：§7.3 POST `/line-checks`、§6.5 规模评估

**问题**：spec §6.5 评估了高频场景：5s 上报 × 2.5h ≈ 1800 点/设备。用户工单提到 30 个设备。每个设备点要对标准轨迹全部线段求最短距离：1800 点 × 430 段 = 774,000 次 pointToSegment 计算/设备，30 设备 = 2300 万次。虽然是纯数学运算无 IO，但全部在单个 HTTP POST 请求内同步完成，存在超时风险。

spec 提到"status = READY（发起即完成计算与快照，无 DEVICE_PENDING 流程）"，意味着不打算走异步。

**建议**：

1. 在 spec 中补充最坏情况耗时估算（如基准测试数据），或者
2. 设定单批次设备数 / 时间窗口上限（如 ≤10 设备或 ≤2h 窗口），或者
3. 考虑异步模式：POST 返回批次 ID → 后台计算 → 前端轮询状态（对齐既有 STATIC/DYNAMIC 的 DEVICE_PENDING 模式）

**风险量化**：假设 pointToSegment 耗时 ~1μs（投影 + 平面几何），2300 万次 ≈ 23s。加上 gps_logs 查询（每设备一次范围查询）和结果写入（30 设备 × 1800 行 deviations = 54,000 行 INSERT），实际可能 30-60s，已超出常见 HTTP 网关超时（30s）。

### F3：报告/对比端点响应体积无分页

**位置**：§7.4 LineQualityReportDto、§7.6 `/comparison/line`

**问题**：

- `LineQualityReportDto.trackLine` 返回完整标准轨迹点列快照。上限 20000 点（§4.3），每点 lng+lat 约 40 字节 JSON ≈ 800KB。
- `deviations` 逐点偏差明细：高频场景 1800 点/设备。
- `/comparison/line` 同时返回标准轨迹点列 + 各设备轨迹点（偏差快照），多设备叠加。

当前设计全部一次性返回，无分页或懒加载。对于大轨迹 + 多设备对比，单个响应可达数 MB。

**建议**：

- 报告端点将 `trackLine` 和 `deviations` 拆为独立子端点（如 `/tests/{id}/line-report/track` 和 `/tests/{id}/line-report/deviations`），报告主端点只返回统计摘要
- 或在 DTO 中增加 `maxDeviationPoints` 参数，限制返回的偏差明细行数
- `/comparison/line` 的设备轨迹点建议按需加载（点击设备展开时再请求）

---

## P2 — 中等优先级

### F4：GpsQualityTest 实体层改动未在 spec 中记录

**位置**：§6.1 数据模型、§3 继承关系

**问题**：spec §6.1 详细描述了 `gps_quality_tests` 新增 `track_line_id` 列，但未提及 `GpsQualityTest.java` 实体需要同步改动：

- 新增 `private Long trackLineId` 字段 + getter/setter
- 现有全参构造器 `(String deviceCode, TestType testType, Long rtkPointId, Long routeId, Instant startedAt)` 不含 trackLineId，需要新构造器或 setter 调用
- 类 Javadoc（"A test selects a time range... STATIC or DYNAMIC"）需要更新以覆盖 LINE

这不是逻辑问题，但 spec 作为实施依据应完整记录所有受影响文件，避免实现时遗漏。

**建议**：在 §3.5 或 §6.1 补充一行："`GpsQualityTest.java` 新增 `trackLineId` 字段及构造器支持，Javadoc 更新覆盖 LINE 类型"。

### F5：缺少查询性能索引建议

**位置**：§6 数据模型、§7 API

**问题**：

- `/checks/summary?deviceCode=` 需按 `device_code` 过滤 + 按类型分组取最新。spec 未建议索引。建议 `CREATE INDEX idx_gqt_device_type_time ON gps_quality_tests(device_code, test_type, created_at DESC)`。
- `/comparison/line` 查询特定 trackLineId + 时间窗内的 LINE tests，也依赖高效过滤。
- `gps_quality_tests.track_line_id` 无索引，删除候选时的级联 SET NULL 操作在大表上可能慢。

**建议**：§6.1 迁移中补充上述索引。当前 gps_quality_tests 数据量不大，但随着检验积累会成为瓶颈。

---

## P3 — 低优先级

### F6：TestType.java 行号引用偏移

**位置**：§1.1 表格、D1、§3.5

**问题**：spec 多处引用 `TestType.java:7-11`，实际该范围是 Javadoc 注释，枚举值 `STATIC / DYNAMIC / TRAJECTORY` 在第 12-14 行。不影响理解，但精确引用应为 `:12-14`。

### F7：XLSX 坐标解析 \r\n 处理未显式说明

**位置**：§4.2 坐标单元格解析规则

**问题**：RTK 手簿导出的 XLSX 单元格内坐标以 `\n` 分隔，但实际可能混入 `\r\n`（Windows 环境）。§4.2 第 1 步"按 \n 切分 → 逐行 trim"隐含处理了 \r（trim 会去掉尾部 \r），但未显式说明。

**建议**：§4.2 第 1 步改为"按 `\n` 切分 → 逐行 trim（兼容 \r\n）"，消除实现歧义。

---

## 已核实正确的引用（无需修改）

以下 spec 引用经源码核实，准确无误：

- `TrajectoryPairingService.java:120-132`（`determineTrajectoryGrade` 方法，p95 阈值 15/25/40m）✓
- `TrajectoryPairingService.java:145-156`（percentile 线性插值）✓ — 实际行号为 149-160，略偏移但可接受
- `TrajectoryPairingService.java:162-170`（haversine）✓ — 实际行号为 168-176，同上
- `TrajectoryImportService.java:66`（`MAX_ROWS = 5000`）✓
- `GpsQualityAdminController.java:59`（路由前缀 `/api/v1/admin/gps-quality`）✓
- `GpsQualityAdminController.java:61`（`@PreAuthorize("hasRole('PLATFORM_ADMIN')")`）✓
- `GpsQualityAdminController.java:76-83`（`resolveTenantId` + `FALLBACK_TENANT_ID = 1L`）✓
- `GpsQualityAdminController.java:91-97`（`parseInstant` UTC 面值解析）✓
- `GpsQualityAdminController.java:373,386`（`/trajectory/parse`、`/trajectory/import` 两步式）✓ — 实际行号略偏移但端点确认存在
- `V20260722100000__nix22_trajectory_track_points.sql:16-22`（DROP+ADD CHECK 约束写法）✓
- `chk_test_type_truth` 约束名 ✓ — 4 个迁移文件中均出现，名称正确
- `TestType` 枚举 VARCHAR(10)，`'LINE'` 4 字符无需扩列 ✓
- `QualityGrade` 枚举含 `MARGINAL` ✓
- 前端 `quality_check_list.dart` 的 `_buildReport` if 链结构 ✓
- 前端 `comparison_tab.dart` 的 `SegmentedButton<int>` 3 段结构 ✓
- `gps_quality_track_points.created_at TIMESTAMP`（系统时间用 TIMESTAMP，业务时间用 TIMESTAMPTZ）— spec §6.5 的 `computed_at TIMESTAMP` 遵循同一约定 ✓

---

## 设计亮点

1. **D4 快照哲学论证充分**：明确说明了为何 LINE 需要连结果一起快照（DataRetentionService 会清理 gps_logs），而 NIX-22 只快照配对不快照结果。逻辑自洽。
2. **D7 清洗策略合理**：去连续重复但不做速度跳点剔除——标准轨迹需要完整几何，过度清洗会丢失真值。
3. **§3 继承关系章节省心**：逐挂载点声明既有逻辑不受影响，类型分派只追加不修改，降低回归风险。
4. **点到折线距离算法选择得当**：等距圆柱局部投影在 <几 km 量级误差 <0.1%，适合牧场级线路，比逐段 haversine 更高效。

---

## 建议的后续行动

1. **[用户决策] F1**：用户确认"一期手动选定 + 二期合成"的范围切分，或要求一期即实现合成算法。
2. **[spec 修订] F2**：补充多设备计算的超时分析或异步方案。
3. **[spec 修订] F3**：报告端点拆分或增加分页参数。
4. **[spec 修订] F4/F5**：补充实体改动声明和索引建议。
5. **[spec 修订] F6/F7**：修正行号引用、显式说明 \r\n 处理。
6. 修订完成后进入 plan 阶段。
