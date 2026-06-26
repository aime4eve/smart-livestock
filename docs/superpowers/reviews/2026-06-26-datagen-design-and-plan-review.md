# 评审：datagen 限界上下文设计 + v1 实施计划

> 评审对象：
> - 设计规格：`docs/superpowers/specs/2026-06-26-datagen-context-design.md`
> - 实施计划：`docs/superpowers/plans/2026-06-26-datagen-v1-plan.md`
> - 路线图关联：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` §4
> 评审日期：2026-06-26
> 评审维度：需求匹配 / 业务拉通 / 系统架构

---

## 总体评价

datagen 的核心设计决策是对的——把合成数据生成从 IoT 拆出来独立成上下文，用 ACL 端口隔离，GroundTruthLabel 作为一等实体。但设计文档和实施计划之间存在一致性缺口，洋葱架构的分层执行不完整（缺 domain repository 接口层），且几个运行时风险（事务传播、内存状态恢复、GPS 双写）未覆盖。建议修复后开始实施。

按严重度分类：P0 必须修复（阻塞实施），P1 应修复（影响正确性），P2 可改进（优化质量）。

---

## 一、需求匹配

### ✅ 做得好的地方

- **决策 #10 落地清晰**：合成数据从"临时占位"到"一等公民"的认知转变在设计文档中表述准确。GroundTruthLabel(source=SYNTHETIC) 自动标注 → EvaluationService 自动对比的链路完整且自洽。
- **TemporalShape.intensityFactor 设计精巧**：用 0-1 的进度因子表达"渐起→平台→恢复"三段式曲线，比 boolean 开关好一个量级，且为 Phase C 行为波形合成预留了复用空间。
- **前向兼容到位**：AnomalyPattern 枚举、LabelSource.MANUAL、EvaluationService 多分类输出，都为 Phase C 预留且不过度设计。

### P1 — 设计文档与最新路线图不一致

**问题**：设计文档 §8「与 Phase B 其余交付物的关系」仍然列了"标注基础设施(#56) → 依赖 datagen 的点"为 Phase B 交付物。但路线图已在最新提交（`83151ec6`）中明确将 #56 移至 Phase C。

设计文档 §8 原文：

| Phase B 交付物 | 依赖 datagen 的点 |
|---------------|-----------------|
| 标注基础设施（#56） | GroundTruthLabel 表是标注管道的存储层... |

这与路线图 Phase B 交付物表（只有 4 块，无标注）矛盾。

**建议**：更新设计文档 §8，将"标注基础设施(#56)"行移除或标注为"Phase C，已移出 Phase B"。

### P2 — selectAnomalyTargets 算法未定义

**问题**：SynthesisService.generate() 流程中提到"按 penetrationRate 从目标牛中随机选 N 头注入异常"，但设计文档 §5.3 和计划 Task 5 都没有定义选择算法：

- 每个周期重新随机选？还是首次选定后固定？
- 如果每个周期重选，同一头牛可能间歇性异常，违反 temporalShape 的连续性假设
- 如果首次选定后固定，SynthesisState 内存中记住，重启后丢失选集

**建议**：明确为"首次选定后写入 GroundTruthLabel.periodStart/periodEnd，后续周期查 label 判断是否在异常期"——这其实已经在 updateAnomalyState 中体现了，但 selectAnomalyTargets 的"何时调用"边界不清晰（应在 label 过期或场景首次启动时调用，不是每个周期）。

---

## 二、业务拉通

### ✅ 做得好的地方

- **ACL 方向正确**：datagen 作为 Customer（调用方），IoT/Health 作为 Supplier（被调用方），通过 port 接口依赖。与现有 RanchQueryPort / IoTQueryPort / HealthSubscriptionPort 模式一致。
- **IoT 零改动**：TelemetryIngestionService.ingest() 接口不变，datagen 喂数据和真实设备喂数据走完全相同路径——这是"数据来源解耦"的核心收益。
- **配置迁移策略合理**：telemetry.simulator.enabled → datagen.enabled，默认场景 NORMAL 替代原行为。

### P0 — GPS 三写冲突

**问题**：当前系统中 GPS 数据有两个生成源：

1. `TelemetrySimulator.generateTrackerReadings()` — 在 readings Map 里生成 `latitude`/`longitude`，由 `TelemetryIngestionService.extractAndLogGps()` 写入 `gps_logs` 表
2. `GpsSimulator` — 独立的 `@Scheduled` 组件，受 `gps.simulator.enabled` 控制，直接调 `GpsLogApplicationService.logGps()` 写 `gps_logs`

datagen 迁移后成为第三个源（替代源 1），**如果 datagen 的 generateTrackerReadings 也生成 GPS + GpsSimulator 仍 enabled=true，TRACKER 设备每个周期会产生两条 GPS 记录**（一条来自 datagen → ingest → extractAndLogGps，一条来自 GpsSimulator → logGps）。

GpsSimulator 的 GPS 是围栏感知的（在围栏内生成坐标），而 TelemetrySimulator 的 GPS 是固定中心点附近的随机偏移——两者精度不同，混在一起会导致地图抖动和越界告警误报。

**建议**：在 Task 11（迁移清理）之前，明确 GpsSimulator 的处置策略：
- 方案 A：datagen 不生成 GPS 坐标（从 readings Map 中移除 latitude/longitude），GPS 完全交给 GpsSimulator。但这样 IoT 的 extractAndLogGps 不会触发，需确认是否有其他逻辑依赖 readings 中的 GPS。
- 方案 B（推荐）：datagen 生成 GPS（保持与原 TelemetrySimulator 行为一致），同时将 `gps.simulator.enabled` 默认值改为 `false`，在 application.yml 注释说明两者互斥。
- 方案 C：datagen 不生成 GPS，将 GpsSimulator 迁移到 datagen（Phase B 不做，记为遗留）。

无论选哪个，必须在 Task 11 之前解决，否则部署后会出现双 GPS 记录。

### P1 — SynthesisScenario 应继承 AggregateRoot 而非 Entity

**问题**：计划 Task 3 让 SynthesisScenario 继承 `shared.domain.Entity`。但项目中已有 `shared.domain.AggregateRoot`（带 `registerEvent()` 域事件收集机制），用于所有聚合根。

现有模式：

```
shared.domain.Entity          — 普通实体（Installation extends Entity）
shared.domain.AggregateRoot   — 聚合根（extends Entity，加域事件收集）
```

SynthesisScenario 作为聚合根，应继承 AggregateRoot。例如场景启动/停止可以发 `ScenarioStartedEvent` / `ScenarioStoppedEvent`，供监控或审计消费。

**建议**：Task 3 中 `SynthesisScenario extends AggregateRoot`，而非 `extends Entity`。

### P1 — 缺少 domain repository 接口层

**问题**：项目现有模式是三层 repository 分离：

```
health/domain/repository/TemperatureLogRepository.java     — 领域接口
health/infrastructure/persistence/jpa/TemperatureLogJpaRepository.java — Spring Data
health/infrastructure/persistence/ — impl + mapper
```

领域 Service 依赖 domain repository 接口，不 import Spring Data 接口。但 datagen 计划 Task 5 中 `SynthesisService` 和 Task 6 中 `SynthesisRunner` 直接注入 `SynthesisScenarioRepository`（Spring Data 接口，返回 JPA Entity），**跳过了 domain repository 接口层和 mapper**。

这导致 application 层直接依赖 infrastructure 层类型，违反洋葱架构的依赖方向约束。

**建议**：新增 Task（或并入 Task 9）：
- `datagen/domain/repository/SynthesisScenarioRepository.java` — domain 接口，返回 domain `SynthesisScenario`
- `datagen/domain/repository/GroundTruthLabelRepository.java` — domain 接口，返回 domain `GroundTruthLabel`
- `datagen/infrastructure/persistence/JpaSynthesisScenarioRepositoryImpl.java` — 实现 domain 接口，委托 Spring Data + mapper

Task 5/6/7/8 中的 Service 注入 domain 接口，不是 Spring Data 接口。

### P2 — 历史数据无标签

**问题**：V38 创建 ground_truth_labels 表后，已有的历史遥测数据（temperature_logs 等已有数据）没有对应的 ground truth 标签。EvaluationService 评估时，这些历史时段会被当作"正常"（无 label = 无异常），但其中可能包含 TelemetrySimulator 之前随机注入的 `abnormalTemp=true` 数据。

**影响**：如果历史数据中有随机异常，评估会把这些误标为 TN（真阴性），拉低 precision。

**建议**：在 Task 1 的种子数据后追加一条说明："历史数据不补标。评估窗口从 datagen 启用后开始，不评估历史无标签数据。" 或者提供一个回填脚本（低优先级）。

### P2 — Admin API 缺少 i18n 和 DTO 层

**问题**：Task 10 的 DataGenAdminController 直接返回领域实体（`SynthesisScenario`、`GroundTruthLabel`）。按 AGENTS.md i18n 规范，Admin API 应：
- 返回 DTO 而非领域实体（避免泄露内部结构）
- 错误消息通过 MessageSource 管理双语

**建议**：Task 10 补充 DTO 类（`ScenarioDto`、`LabelDto`、`CreateScenarioRequest`），error 走现有 `ApiException` + `ErrorCode` 体系。

---

## 三、系统架构

### ✅ 做得好的地方

- **三层架构方向正确**：domain（无 IO）→ application（编排）→ infrastructure（ACL + persistence），与 Health/Commerce 一致。
- **AnomalyScoreQueryPortImpl 容错降级合理**：anomaly_scores 表不存在时返回空列表，使 datagen-v1 能独立交付，不阻塞于 Phase B 交付物 2。
- **TemporalShape 作为值对象独立测试**：计划 Task 2 的 intensityFactor 单元测试覆盖了全部分支，是正确的 TDD 起点。

### P0 — Task 依赖顺序与实施顺序不匹配

**问题**：计划中 Task 的编号顺序与实际依赖关系矛盾：

```
Task 5: SynthesisService   → 注入 GroundTruthLabelRepository + SynthesisScenarioRepository
Task 6: SynthesisRunner    → 注入 SynthesisScenarioRepository
Task 7: GroundTruthLabelService → 注入 GroundTruthLabelRepository
Task 9: 持久化层           → 创建 Repository 接口 + Spring Data + Impl + Mapper
```

Task 5/6/7 依赖 Task 9 的产物（Repository 接口和实现），但 Task 9 排在它们之后。如果按编号顺序执行，Task 5 编译时会找不到 Repository 类型。

**建议**：调整 Task 顺序为：
```
Task 1: V38 迁移
Task 2: 枚举（AnomalyPattern/TemporalShape/...）
Task 3: 领域模型（SynthesisScenario + GroundTruthLabel）
Task 4: domain repository 接口（新增，见 P1 上一条）
Task 5: ACL 端口接口 + 实现
Task 6: 持久化层（原 Task 9，提前）
Task 7: SynthesisService（原 Task 5）
Task 8: SynthesisRunner（原 Task 6）
Task 9: GroundTruthLabelService（原 Task 7）
Task 10: EvaluationService（原 Task 8）
Task 11: Admin API（原 Task 10）
Task 12: TelemetrySimulator 迁移 + 清理（原 Task 11）
Task 13: 全量验证（原 Task 12）
```

关键原则：**基础设施（persistence + ACL）先于 application service**，因为 service 依赖它们。

### P1 — AnomalyScoreQueryPortImpl 的 try-catch 反模式

**问题**：计划 Task 4 Step 4 的 `AnomalyScoreQueryPortImpl` 用 try-catch 包裹 native query，捕获所有异常返回空列表：

```java
try {
    var query = entityManager.createNativeQuery(...);
    ...
} catch (Exception e) {
    // Table might not exist yet
    return List.of();
}
```

这是反模式：
1. 捕获 `Exception` 过宽——会吞掉真实的连接错误、权限错误、SQL 语法错误
2. "表不存在"是迁移阶段的问题，不该靠运行时异常处理
3. 在生产环境中，如果 anomaly_scores 表本应存在但查询失败，静默返回空会隐藏严重问题

**建议**：改为显式可用性检查 + 精确异常类型：

```java
@Component
@RequiredArgsConstructor
public class AnomalyScoreQueryPortImpl implements AnomalyScoreQueryPort {
    private final EntityManager entityManager;
    private volatile boolean available = true;

    @Override
    public List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(...) {
        if (!available || livestockIds.isEmpty()) return List.of();
        try {
            // query...
        } catch (PersistenceException e) {
            available = false;
            log.warn("anomaly_scores table not available, evaluation will be empty: {}", e.getMessage());
            return List.of();
        }
    }
}
```

用 `PersistenceException`（JPA 标准异常基类）替代 `Exception`，并缓存可用性标志避免每次都触发异常。

### P1 — 内存状态重启丢失

**问题**：SynthesisService 的 `ConcurrentHashMap<Long, SynthesisState>` 是内存态。应用重启后：
- SynthesisState 丢失（tempBaselineOffset、activePattern、anomalyStart/End 全部归零）
- GroundTruthLabel 持久化了，但 SynthesisState 不知道
- 重启后同一头牛的 anomaly 会被判定为"无 active anomaly"，重新走 selectAnomalyTargets，可能产生第二条 label（重叠时段）

**影响**：非功能性——开发期间频繁重启不致命（只是多几条 label），但生产部署重启会产生脏数据。

**建议**：在 SynthesisState 初始化时，从 DB 恢复活跃异常状态：

```java
SynthesisState createOrRestore(Long livestockId) {
    // Check DB for active SYNTHETIC labels (periodEnd > now)
    List<GroundTruthLabel> active = labelRepo
        .findByLivestockIdAndSourceAndPeriodNotEnded(livestockId, SYNTHETIC, now);
    if (!active.isEmpty()) {
        var label = active.get(0);
        var state = SynthesisState.create(livestockId);
        state.setActivePattern(label.getPattern());
        state.setAnomalyStart(label.getPeriodStart());
        state.setAnomalyEnd(label.getPeriodEnd());
        state.setActiveLabel(label);
        return state;
    }
    return SynthesisState.create(livestockId);
}
```

或接受"重启会中断正在进行的异常注入，新周期重新选择"作为已知简化——但需在设计文档显式声明。

### P1 — 事务传播边界未定义

**问题**：SynthesisService.generate() 标注 `@Transactional`，内部循环调用 `ingestionPort.ingest()`（IoT 的 `TelemetryIngestionService.ingest()` 也标注 `@Transactional`）。

Spring 默认 `PROPAGATION_REQUIRED`：内层 ingest() 加入外层事务。如果第 5 头牛的 ingest() 抛异常，整个外层事务回滚——包括前 4 头牛已写入的时序数据和 ground_truth_labels。

但这不是期望行为：合成数据生成是"尽力而为"的批量操作，单头失败不应影响其他头。

原 TelemetrySimulator 也有 `@Transactional` 在 generateTelemetry() 上，但它在 catch 块里吞掉了 ingest 异常（`log.warn("Failed to ingest...")`），所以异常不会传播到外层。datagen 计划 Task 5 也有 try-catch，但 `@Transactional` 标注在方法级别，一旦任何异常被 throw 出方法边界（即使被 catch 了），Spring 的声明式事务在异常处理上可能有微妙差异。

**建议**：
- 明确 generate() 不加 `@Transactional`（它是批量循环，每头牛的 ingest 已有自己的事务边界）
- label 写入用独立事务（`@Transactional(propagation = REQUIRES_NEW)`）或放到 generate() 方法外
- 参考原 TelemetrySimulator：它的 `@Transactional` 在方法上，但 catch 了所有异常不外抛，实际效果是"成功部分写入，失败跳过"

### P2 — datagen 在生产环境的形态

**问题**：datagen 始终编译进 Spring Boot 主应用（`com.smartlivestock.datagen` 包在 src/main 中）。即使 `datagen.enabled=false`，SynthesisRunner 不运行，但 datagen 的 Entity、Repository、ACL 实现类仍然被 Spring 扫描和实例化（除非加 `@ConditionalOnProperty`）。

生产环境用真实设备时，datagen 的所有代码都存在但不工作——类似死代码。

**影响**：轻微。包大小增加几 KB，Bean 实例化开销可忽略。但概念上不够干净。

**建议**：Phase B 接受现状（`@ConditionalOnProperty` 在 SynthesisRunner 上已隔离了核心逻辑）。如果未来想更干净，可以用 Spring Profile `@Profile("datagen")` 隔离整个上下文，但这是过度优化，记为 backlog。

---

## 四、问题汇总与优先级

| # | 问题 | 维度 | 严重度 | 归属 Task |
|---|------|------|--------|-----------|
| 1 | GPS 三写冲突（datagen + GpsSimulator 双源） | 业务拉通 | **P0** | Task 11 前 |
| 2 | Task 依赖顺序：persistence 应在 service 之前 | 系统架构 | **P0** | Plan 重排 |
| 3 | 设计文档 §8 与路线图 #56 位置矛盾 | 需求匹配 | P1 | 设计文档更新 |
| 4 | 缺 domain repository 接口层 | 系统架构 | P1 | Plan 新增 Task |
| 5 | SynthesisScenario 应继承 AggregateRoot | 业务拉通 | P1 | Task 3 |
| 6 | AnomalyScoreQueryPortImpl try-catch 反模式 | 系统架构 | P1 | Task 4 |
| 7 | 内存状态重启丢失 | 系统架构 | P1 | Task 5 |
| 8 | 事务传播边界未定义 | 系统架构 | P1 | Task 5/6 |
| 9 | selectAnomalyTargets 选择算法未定义 | 需求匹配 | P2 | Task 5 |
| 10 | 历史数据无标签 | 需求匹配 | P2 | Task 1 注释 |
| 11 | Admin API 缺 DTO + i18n | 业务拉通 | P2 | Task 10 |
| 12 | datagen 生产环境形态 | 系统架构 | P2 | backlog |

---

## 五、修复建议总结

**实施前必须修复（P0）**：

1. GPS 冲突：Task 11 前明确 GpsSimulator 处置（推荐方案 B：datagen 生成 GPS，GpsSimulator 默认关闭）
2. Task 重排：persistence（原 Task 9）提到 ACL（Task 4）之后、SynthesisService（原 Task 5）之前

**实施时应修复（P1）**：

3. 更新设计文档 §8（移除 #56 作为 Phase B 交付物）
4. 新增 domain repository 接口 Task
5. SynthesisScenario extends AggregateRoot
6. AnomalyScoreQueryPortImpl 用 PersistenceException + 可用性标志
7. SynthesisState 从 DB 恢复活跃异常，或显式声明"重启中断"为已知简化
8. 明确事务边界：generate() 去掉 @Transactional，label 写入独立事务

**实施后可改进（P2）**：9-12 按需处理。

---

## 六、结论

datagen 的设计方向正确，ACL 隔离和 GroundTruthLabel 实体化的核心决策站得住。但实施计划需要修复 2 个 P0（GPS 冲突 + Task 重排）和 6 个 P1（架构分层不完整 + 运行时风险）才能开始执行。修复都是局部调整，不改变设计方向。建议修复后重新评审计划，再开始 Task-by-Task 实施。
