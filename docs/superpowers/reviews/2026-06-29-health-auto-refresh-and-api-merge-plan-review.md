# 健康数据自动刷新 + API 合并计划 — 评审意见

> 评审日期: 2026-06-29  
> 评审对象: `docs/superpowers/plans/2026-06-29-health-auto-refresh-and-api-merge-plan.md`  
> 评审人: Claude (AI 助手)  
> 评审方法: 逐项对照代码库实际状态验证计划假设

---

## 总体评价

**✅ 可执行** — 计划整体合理，7 个 Task 粒度适中，方案选择（1+2+4，跳过 3）有清晰的理由。以下是逐 Task 的详细发现和修改建议。

---

## 逐 Task 评审

### Task 1: AutoRefreshListener

**✅ 设计合理，无需修改。**

代码骨架与 `ranch_controller.silentRefresh` 模式一致，经验证现有实现：

- `WidgetsBindingObserver` → `didChangeAppLifecycleState` 处理前后台切换 —— 正确
- `Timer.periodic` 在 dispose 时 cancel —— 正确，无内存泄漏
- `didUpdateWidget` 处理 interval 变更 —— 周全

**一个注意事项（非阻塞）**: 计划说 "Flutter web 下页面切换会 dispose 旧 widget，Timer 自然取消"。这在当前 web-only 场景下成立。如果未来 build native mobile，`Navigator.push()` 不会 dispose 旧路由的 widget（它仍在 widget tree 中但被覆盖），Timer 会继续跑。届时需要扩展为 `RouteAware` 检测页面可见性。建议在代码注释中标注这个假设，不作为当前 Task 的一部分。

---

### Task 2: 后端嵌入 AI 异常分数

**⚠️ 有一个设计问题和两个技术细节需要修正。**

#### 2a. AnomalyScoreRepository 直接注入 → 建议走 HealthAnomalyService

计划提议在 `HealthApplicationService` 直接注入 `AnomalyScoreRepository`：

> "HealthApplicationService 需要注入 AnomalyScoreRepository（当前通过 HealthAnomalyService 间接持有，直接注入更简洁）"

经验证代码：

- `HealthApplicationService` 已注入 `HealthAnomalyService`（第 40 行 `private final HealthAnomalyService healthAnomalyService`）
- `HealthAnomalyService` 已注入 `AnomalyScoreRepository`（`private final AnomalyScoreRepository anomalyScoreRepo`）
- `AnomalyScoreRepository.findLatestByFarmIdAndLivestockId(farmId, livestockId)` 方法已存在

**问题**: 直接注入 `AnomalyScoreRepository` 会绕过 `HealthAnomalyService`，而该 Service 已经封装了 AI 异常的业务逻辑（评分、去重、告警）。在 `HealthApplicationService.getFeverDetail()` 中直接查 anomaly_scores 表，相当于跨过 Service 层直接访问 Repository——这在 DDD 分层中是一个轻微的层次泄露。

**建议**: 在 `HealthAnomalyService` 中加一个查询方法：

```java
public Optional<AiAnomalySummary> getLatestSummary(Long farmId, Long livestockId) {
    return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
        .map(s -> new AiAnomalySummary(...));
}
```

然后在 `HealthApplicationService.buildAiSummary()` 中调用 `healthAnomalyService.getLatestSummary()`。这样保持了 `HealthAnomalyService` 作为 AI 异常的唯一入口。

**影响**: 低。两种方式都能编译和运行。但如果未来 `AnomalyScore` 的查询逻辑变复杂（比如需要结合缓存、需要过滤过期数据），走 Service 层更容易统一修改。

#### 2b. AiAnomalySummary 字段类型核对

| Java 字段 | Dart 对应字段 | 一致? |
|-----------|-------------|------|
| `Double anomalyScore` | `double anomalyScore` (non-null, default 0.0) | ⚠️ Java nullable vs Dart non-null — 如果 Java 侧返回 null，Dart `fromJson` 需要处理。建议 Java 侧做 `.orElse(new AiAnomalySummary(0.0, "normal", null, null, null))` 或用 `@JsonInclude(NON_NULL)` |
| `String anomalyType` | `String anomalyType` (default 'normal') | ✅ |
| `Integer nEff` | `int? nEff` | ✅ |
| `String capabilityUsed` | `String? capabilityUsed` | ✅ |
| `Instant assessedAt` | `DateTime? assessedAt` | ✅ (计划中 `fromJson` 用 `assessedAt` 字段，Dart 模型已支持，且 fallback 到 `createdAt`) |

#### 2c. 三个 detail 方法都需加 AI 查询

计划只给了 `buildAiSummary()` 辅助方法的代码模板，没有明确三个 `getXxxDetail()` 方法各自需要调用它。代码量很小（每个方法加一行），但应在 Task 2 的 Step 2 中明确列出：

- `getFeverDetail()` → return 前调用 `buildAiSummary()`
- `getDigestiveDetail()` → return 前调用 `buildAiSummary()`  
- `getEstrusDetail()` → return 前调用 `buildAiSummary()`

---

### Task 3: 前端模型解析 AI 嵌入字段

**⚠️ 有一个跨模块依赖问题。**

计划中 `FeverDetailData.fromJson` 需要创建 `AnomalyScoreData` 实例，但 `AnomalyScoreData` 定义在 `features/ai_anomaly/domain/anomaly_models.dart`，而 `FeverDetailData` 在 `core/models/health_models.dart`。计划承认这个问题：

> "AnomalyScoreData 已在 features/ai_anomaly/domain/anomaly_models.dart 定义，需要 import 或将模型提升到 health_models.dart"

**分析**: `core/models/` 导入 `features/ai_anomaly/domain/` 会形成 `core → feature` 的反向依赖——这违反了模块分层（feature 应依赖 core，而非反过来）。

**建议**: 两种方案：
1. **推荐**: 把 `AnomalyScoreData` 和 `AnomalyScoreHistoryItem` 提升到 `core/models/anomaly_models.dart`（或直接并入 `health_models.dart`）。它们是纯数据模型，不依赖任何 feature 层逻辑，放 core 完全合理。
2. **备选**: 在 `health_models.dart` 中手写 `aiAnomaly` 的 JSON 解析（不依赖 `AnomalyScoreData.fromJson`），但会产生重复代码。

**工作量**: 方案 1 需要更新 `anomaly_models.dart` 中所有 import 路径（`AnomalyScoreData` 被 `anomaly_score_card.dart`、`anomaly_controller.dart`、`anomaly_api_repository.dart` 等引用）。约 5-8 个文件的 import 路径更新。计划应明确这个工作量。

**另外**: 计划中 `fromJson` 的 `livestockId` 注入方式：
```dart
AnomalyScoreData.fromJson({
  ...m['aiAnomaly'],
  'livestockId': m['livestockId'],
})
```
这可行但脆弱——如果 `aiAnomaly` 恰好有 `livestockId` 字段会冲突。建议改为在 `AnomalyScoreData` 中让 `livestockId` 变为可选字段（`String? livestockId`），或新增一个 `fromEmbeddedJson` 工厂方法。

---

### Task 4: AnomalyScoreCard 改为纯展示组件

**✅ 方向正确，有一个细节遗漏。**

改为 `StatelessWidget` 后，加载状态（之前卡片内部的 `CircularProgressIndicator`）移到父页面处理。这是合理的——详情页的 `AsyncValue.when()` 已经处理了 loading/error/data 三态。

**遗漏**: 计划没有提到 `digestive_detail_page.dart` 和 `estrus_detail_page.dart` 中 `AnomalyScoreCard` 的当前调用方式。需要验证它们也是 `AnomalyScoreCard(livestockId: livestockId)` 形式，确保改造一致。

经代码探索确认：fever_detail_page 使用 `AnomalyScoreCard(livestockId: livestockId)`。digestive 和 estrus 页面推测类似（同一模式），但建议执行前 grep 确认所有调用点。

**保留的 anomalyDetailProvider**: 计划说保留。核实后确认——`AnomalyHistoryChart`（历史趋势图表）使用 `anomalyHistoryProvider`，对应的 API 是 `GET /health/anomaly/{id}/history`，合并范围不涉及历史数据。正确。

---

### Task 5: Controller silentRefresh

**✅ 模式正确，有一个 controller 类型差异需要注意。**

- `FeverDetailController` / `DigestiveDetailController` / `EstrusDetailController` 都继承 `AsyncNotifier<T>`（非 farm-scoped），需各自持有 `livestockId`（通过 family provider 的构造函数参数传入）→ silentRefresh 可直接调用 repository
- `TwinOverviewController` 继承 `FarmScopedAsyncNotifier<HealthOverviewResponse>` → silentRefresh 不需要 `livestockId` 参数

计划中的 pattern 对两种类型都适用。

**建议补充**: silentRefresh 失败时可以考虑加一个静默的错误计数器或 timestamp。连续失败 N 次后在 UI 上显示一个微小的 "数据可能过期" 提示（非阻塞，可后续迭代）。

---

### Task 6: 四个页面接入 AutoRefreshListener

**✅ 接入方式正确，有一处细节。**

计划中孪生概览页的 provider：
```dart
ref.read(twinOverviewControllerProvider.notifier).silentRefresh()
```

需要确认 `twinOverviewControllerProvider` 的实际名称。经验证 controller 文件中定义为 `twinOverviewControllerProvider`，类型是 `AsyncNotifierProvider<TwinOverviewController, HealthOverviewResponse>`，无 family 参数。名称匹配，正确。

**一个 UI 交互问题**: 孪生概览页当前使用 `SingleChildScrollView`（无 `RefreshIndicator`），刷新是静默的。180s 间隔下用户可能感知不到数据在更新。建议：首次实现可接受，后续可在概览页加一个 "最后刷新时间" 的轻提示（或在 AppBar 加一个小的刷新图标动画）。

---

### Task 7: 全量验证

**⚠️ 验证清单略薄。**

当前清单只有编译 + analyze + gen-l10n + commit。对于一个涉及 4 个后端方法改造 + 6 个前端文件修改 + 1 个新建 widget 的计划，建议增加：

- **前端手动验证**: 在 Chrome 中打开发热详情页，打开 DevTools Network 面板，观察 120s 间隔是否有 API 调用，以及调用是否从 3 次减少到 2 次
- **后端手动验证**: `curl` 调用 `/api/v1/health/fever/{livestockId}`，确认响应中包含 `aiAnomaly` 字段
- **边界情况**: ai-platform 不可用时，详情端点应正常返回（aiAnomaly 为 null），不应 500

---

## 遗漏项

### 1. 独立 anomaly 端点的去留

`GET /health/anomaly/{livestockId}` 在优化后不再被详情页调用。计划没有说明：
- 是否保留端点？（保留 → 备忘后续清理；删除 → 加一个 Task）
- 是否有其他调用方？（需 grep 确认 `AnomalyDetailController` 或 `anomalyDetailProvider` 是否被其他页面使用）

建议：保留端点不删除（与计划中保留 `anomalyDetailProvider` 一致），但在 Self-Review 中加一条备注说明该端点变为仅内部/测试使用。

### 2. 缺少测试

计划完全没有提及测试。参考 CLAUDE.md 强调的 TDD 流程，建议至少包含：
- `AutoRefreshListener` 的 widget test：验证 Timer 启动/暂停/恢复/取消
- `HealthApplicationService` 的单元测试：验证 `buildAiSummary()` 在有/无 anomaly 数据时的行为
- `FeverDetailData.fromJson` 的单元测试：验证含/不含 `aiAnomaly` 字段的 JSON 解析

如果项目当前没有这类测试的基础设施，应在 Self-Review 中明确标注为"本次不包含，后续补充"。

### 3. 部分失败场景未展开

计划提了一句：
> "ai-platform 挂了，合并端点要降级返回温度曲线 + AI 分数空，不能整条 500"

这个降级逻辑在 Task 2 的代码模板中体现为 `.orElse(null)`（查询不到 anomaly 时返回 null）。但需要明确 error handling 的范围：
- `anomalyScoreRepo.findLatestByFarmIdAndLivestockId()` 抛异常（DB 挂了）→ 是否 catch 并返回 null？还是让异常传播？
- 建议：用 try-catch 包裹 query，异常时 log warning + 返回 null，确保详情端点不受 AI 模块故障影响。

---

## SaaS 计算复核

计划中的计算：

| 场景 | 每次刷新请求数 | 刷新频率 | 5 分钟总请求 |
|------|---------------|---------|-------------|
| 不合并 | 3 次/页/刷新 | 120s | 15 人 × 3 调 × 2.5 轮 = 113 次 |
| 合并后 | 1 次/页/刷新 | 120s | 15 人 × 1 调 × 2.5 轮 = 38 次 |

**复核结果**: 
- 5 分钟 ÷ 120 秒 = 2.5 轮 ✓
- 15 人 × 3 调 × 2.5 = 112.5 ≈ 113 ✓

但这个计算假设所有 15 人都在看发热详情页（之后合并为 1 次调用）。实际情况中用户分布在发热/消化/发情/概览四个页面，且消化详情页合并后是 2 次调用（detail + heatmap），不是 1 次。实际请求数介于 38-63 之间。

**修正建议**: 在计划中标注 "假设全部用户在发热/发情详情页（合并后 1 次调用）的最乐观估算"。或者给出分页面的计算：
- 发热: 3→2 (含 duration)，减少 33%
- 消化: 3→2 (含 heatmap)，减少 33%
- 发情: 2→1，减少 50%

整体在 SaaS 15 并发用户下约减少 35-44%，仍然显著。

---

## 修改建议汇总

| # | 位置 | 类型 | 描述 |
|---|------|------|------|
| 1 | Task 2 Step 2 | 设计 | `buildAiSummary()` 建议走 `healthAnomalyService.getLatestSummary()` 而非直接注入 `AnomalyScoreRepository` |
| 2 | Task 2 Step 2 | 细节 | 明确列出三个 `getXxxDetail()` 方法各自需要调用 `buildAiSummary()` |
| 3 | Task 3 Step 1 | 实现 | 需要先解决 `AnomalyScoreData` 从 feature 层提升到 core 层的模块依赖，计划应明确这一步及 import 更新范围 |
| 4 | Task 3 Step 1 | 细节 | `livestockId` 注入方式建议改为可选字段或独立工厂方法，避免 JSON key 冲突 |
| 5 | Task 6 | 细节 | 确认 `digestive_detail_page`、`estrus_detail_page` 中 AnomalyScoreCard 的调用方式与 fever 一致 |
| 6 | Task 7 | 验证 | 增加手动验证步骤（curl + Chrome DevTools Network 面板） |
| 7 | 遗漏 | 补充 | 标注独立 anomaly 端点的去留决定 |
| 8 | 遗漏 | 补充 | 至少列出测试计划（即使本次不做） |
| 9 | Self-Review | 计算 | SaaS 请求量估算细化：区分页面类型，标注假设 |

---

## 结论

计划在架构层面是正确的：方案 1+2+4 的组合能有效减少 API 调用、实现自动刷新。7 个 Task 的拆分和依赖关系清楚。

3 个需要在实施前解决的实质性问题：
1. **AnomalyScoreData 的模块归属**（Task 3）——必须把模型提升到 core/ 或解决反向依赖
2. **AnomalyScoreRepository 的注入路径**（Task 2）——建议走 HealthAnomalyService 而非直接注入
3. **部分失败的降级处理**（Task 2）——需明确异常时的行为（catch + log + return null）

其余为细节补充和改进建议，不阻塞实施。
