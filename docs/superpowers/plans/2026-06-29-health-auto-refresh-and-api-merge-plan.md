# 健康数据自动刷新 + API 合并实施计划 (v2)

> 方案 1（分级刷新间隔）+ 方案 2（可见性暂停）+ 方案 4（合并端点）  
> v2 修订：采纳评审意见 #1-#9 中 7 条正确项，排除部分失败降级（不正确）

**Goal:** 健康详情页和孪生概览页支持自动刷新（分级间隔 + 后台暂停），并将 AI 异常分数嵌入现有详情端点，减少前端 API 调用次数。面向 SaaS 多租户并发场景。

**Architecture:**
- 方案 1+2: 新建 `AutoRefreshListener` wrapper widget（Timer.periodic + WidgetsBindingObserver），四个页面通过包裹接入，保持 `ConsumerWidget` 不变
- 方案 4: 后端 `FeverDetail` / `DigestiveDetail` / `EstrusDetail` record 加 `AiAnomalySummary` 字段，`HealthApplicationService` 通过 `HealthAnomalyService.getLatestSummary()` 查询嵌入；前端 `AnomalyScoreCard` 从 `ConsumerWidget`（自取数据）改为 `StatelessWidget`（收参数），消除详情页的独立 anomaly API 调用

---

## 当前状态

### API 调用次数（优化前）

| 详情页 | 调用 | 次数 |
|--------|------|------|
| 发热详情 | `GET /fever/{id}` + `GET /fever/{id}/duration` + `GET /anomaly/{id}` | 3 |
| 消化详情 | `GET /digestive/{id}` + `GET /digestive/{id}/heatmap` + `GET /anomaly/{id}` | 3 |
| 发情详情 | `GET /estrus/{id}` + `GET /anomaly/{id}` | 2 |
| 孪生概览 | `GET /health/overview` | 1 |

### API 调用次数（优化后）

| 详情页 | 调用 | 次数 | 变化 |
|--------|------|------|------|
| 发热详情 | `GET /fever/{id}`（含 AI 分数）+ `GET /fever/{id}/duration` | 2 | -1（-33%） |
| 消化详情 | `GET /digestive/{id}`（含 AI 分数）+ `GET /digestive/{id}/heatmap` | 2 | -1（-33%） |
| 发情详情 | `GET /estrus/{id}`（含 AI 分数） | 1 | -1（-50%） |
| 孪生概览 | `GET /health/overview`（不变） | 1 | — |

> `duration` / `heatmap` 端点保留为独立调用——它们是 feature-gated（Standard+/Premium+），仅付费用户触发，数据量较大（图表数据），不值得无条件嵌入。

### 刷新间隔设计

| 页面 | 间隔 | 理由 |
|------|------|------|
| 地图/GPS（ranch_page） | 30s | 已有，不改；位置需要实时感知 |
| 健康详情页（fever/digestive/estrus） | 120s | 体温 30s 变化 <0.1°C，2 分钟足够感知"数据是活的" |
| 孪生概览页 | 180s | 聚合数据，变化更慢 |

### SaaS 请求量估算

假设 5 牧场 × 3 牧工同时在线，分布在发热/消化/发情/概览页面，120s 刷新，5 分钟内（2.5 轮）：

| 页面分布 | 优化前 | 优化后 | 减少 |
|---------|-------|-------|------|
| 5 人在发热（3→2）| 37 次 | 25 次 | -12 |
| 4 人在消化（3→2）| 30 次 | 20 次 | -10 |
| 3 人在发情（2→1）| 15 次 | 8 次 | -7 |
| 3 人在概览（1→1）| 8 次 | 8 次 | 0 |
| **合计** | **90 次** | **61 次** | **-32%（约 1/3）** |

> 评审修正：原计划 Self-Review 的 `113→63（-44%）` 假设全部 15 人都在发热详情页，不现实。修正为按页面分布的混合估算，减少约 32%。

---

## Task 1: AutoRefreshListener — 可复用自动刷新组件

**方案 2 基础设施**

**Files:**
- Create: `Mobile/mobile_app/lib/core/widgets/auto_refresh_listener.dart`

**设计:**

一个 `StatefulWidget` wrapper，内部管理 `Timer.periodic` + `WidgetsBindingObserver`。包裹在页面 `Scaffold` 外层，详情页无需改为 `ConsumerStatefulWidget`。

```dart
class AutoRefreshListener extends StatefulWidget {
  const AutoRefreshListener({
    super.key,
    required this.interval,
    required this.onTick,
    required this.child,
  });

  final Duration interval;
  final VoidCallback onTick;
  final Widget child;

  @override
  State<AutoRefreshListener> createState() => _AutoRefreshListenerState();
}

class _AutoRefreshListenerState extends State<AutoRefreshListener>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) widget.onTick();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      widget.onTick(); // immediate refresh on resume
    } else {
      _stopTimer();
    }
  }

  @override
  void didUpdateWidget(covariant AutoRefreshListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

**关键设计决策:**
- `widget.onTick` 每次 tick 都读最新闭包（Dart widget 引用在 rebuild 时更新），无需比较函数相等
- `didChangeAppLifecycleState`：app 进入后台 → 停 Timer；回前台 → 重启 Timer + 立即刷新一次
- 不处理 go_router 页面覆盖暂停——Flutter web 下页面切换会 dispose 旧 widget，Timer 自然取消
- **评审注释（非阻塞）**：如果未来 build native mobile，`Navigator.push()` 不会 dispose 旧路由，Timer 会继续跑。届时需扩展为 `RouteAware` 检测页面可见性。在代码注释中标注这个假设。

- [ ] **编译验证**: `flutter analyze --no-pub core/widgets/auto_refresh_listener.dart`

---

## Task 2: AnomalyScoreData 模型提升到 core 层

**评审意见 #3 采纳：解决 core → feature 反向依赖**

**Files:**
- Create: `Mobile/mobile_app/lib/core/models/anomaly_models.dart`（从 `features/ai_anomaly/domain/` 移入）
- Delete: `Mobile/mobile_app/lib/features/ai_anomaly/domain/anomaly_models.dart`
- Modify: 所有引用 `AnomalyScoreData` / `AnomalyScoreHistoryItem` 的文件（更新 import 路径）

**Step 1: 移动模型文件**

将 `features/ai_anomaly/domain/anomaly_models.dart` 的内容移到 `core/models/anomaly_models.dart`。`AnomalyScoreData` 和 `AnomalyScoreHistoryItem` 是纯数据模型，不依赖任何 feature 层逻辑，放 core 完全合理。

**Step 2: 更新 import 路径**

引用 `AnomalyScoreData` 的文件（已 grep 确认约 5 个）：
- `features/ai_anomaly/domain/anomaly_repository.dart`
- `features/ai_anomaly/data/anomaly_api_repository.dart`
- `features/ai_anomaly/presentation/anomaly_controller.dart`
- `features/ai_anomaly/presentation/widgets/anomaly_score_card.dart`
- `features/ai_anomaly/presentation/widgets/anomaly_history_chart.dart`

import 从 `../domain/anomaly_models.dart` 改为 `package:hkt_livestock_agentic/core/models/anomaly_models.dart`。

**Step 3: `AnomalyScoreData.livestockId` 改为可选**

```dart
class AnomalyScoreData {
  const AnomalyScoreData({
-   required this.livestockId,
+   this.livestockId,
    // ...
  });
- final String livestockId;
+ final String? livestockId;  // nullable: embedded in detail responses
}
```

> 评审意见 #4 采纳：避免 `fromJson` 中 spread + 覆盖 `livestockId` 的脆弱写法。嵌入到详情响应时 `livestockId` 可为 null（详情端点已有 livestockId 上下文）。

- [ ] **编译验证**: `flutter analyze --no-pub`

---

## Task 3: 后端 — 详情端点嵌入 AI 异常分数

**方案 4 后端**

**Files:**
- Modify: `smart-livestock-server/.../health/application/dto/HealthDtos.java`
- Modify: `smart-livestock-server/.../health/application/service/HealthAnomalyService.java`
- Modify: `smart-livestock-server/.../health/application/service/HealthApplicationService.java`

**Step 1: HealthDtos 加 AiAnomalySummary record + 三个 detail record 加字段**

```java
public record AiAnomalySummary(
    Double anomalyScore,      // null = no assessment yet
    String anomalyType,       // normal / circadian_disruption / abrupt_change / multivariate
    Integer nEff,
    String capabilityUsed,
    Instant assessedAt
) {}
```

三个 detail record 各加 `AiAnomalySummary aiAnomaly`（nullable，null = 无 AI 数据）。`AiAnomalySummary` 所有字段为 nullable wrapper 类型（`Double` 而非 `double`），确保 Jackson 序列化 null 时不报错。

**Step 2: HealthAnomalyService 加 getLatestSummary() 方法**

```java
/**
 * Read-only query for embedding AI anomaly summary into detail responses.
 * Pure DB read (anomaly_scores table), does NOT call ai-platform.
 */
public Optional<AiAnomalySummary> getLatestSummary(Long farmId, Long livestockId) {
    return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
        .map(s -> new AiAnomalySummary(
            s.getAnomalyScore().doubleValue(),
            s.getAnomalyType(),
            s.getNEff(),
            s.getCapabilityUsed(),
            s.getCreatedAt()
        ));
}
```

> 评审意见 #1 采纳：走 `HealthAnomalyService` 而非直接注入 `AnomalyScoreRepository`。`HealthAnomalyService` 是 AI 异常的唯一入口，保持 DDD 分层。`HealthApplicationService` 已注入 `healthAnomalyService`（第 40 行）。
>
> 评审意见 #9（部分失败降级）核实后排除：`findLatestByFarmIdAndLivestockId()` 是纯 JPA DB 查询，不经过 ai-platform。ai-platform 故障不影响此查询（读旧数据或返回空 Optional）。唯一异常场景是 DB 本身挂了——但那时 temperature_logs 查询也会失败，整条端点本来就会 500。不存在独立的 AI 模块故障降级路径。

**Step 3: 三个 getXxxDetail() 方法调用嵌入**

评审意见 #2 采纳，明确列出三个方法各自需要调用：

- `getFeverDetail()` → return 前调用 `healthAnomalyService.getLatestSummary(farmId, livestockId).orElse(null)` 嵌入 `FeverDetail.aiAnomaly`
- `getDigestiveDetail()` → 同上嵌入 `DigestiveDetail.aiAnomaly`
- `getEstrusDetail()` → 同上嵌入 `EstrusDetail.aiAnomaly`

- [ ] **编译验证**: `cd smart-livestock-server && ./gradlew compileJava -q`

---

## Task 4: 前端模型解析 AI 嵌入字段

**方案 4 前端**

**Files:**
- Modify: `Mobile/mobile_app/lib/core/models/health_models.dart`

**Step 1: FeverDetailData / DigestiveDetailData / EstrusDetailData 加 aiAnomaly 字段**

```dart
class FeverDetailData {
  // ... existing fields ...
  final AnomalyScoreData? aiAnomaly;

  factory FeverDetailData.fromJson(Map<String, dynamic> m) {
    return FeverDetailData(
      // ... existing parsing ...
      aiAnomaly: m['aiAnomaly'] != null
          ? AnomalyScoreData.fromJson(m['aiAnomaly'])
          : null,
    );
  }
}
```

同样修改 `DigestiveDetailData` 和 `EstrusDetailData`。

> import 路径：`package:hkt_livestock_agentic/core/models/anomaly_models.dart`（Task 2 已提升）。
> `livestockId` 已在 Task 2 改为可选，`fromJson` 直接传 `m['aiAnomaly']`，无需 spread 注入。

- [ ] **编译验证**: `flutter analyze --no-pub core/models/health_models.dart`

---

## Task 5: AnomalyScoreCard 改为纯展示组件 + 详情页传参

**方案 4 前端**

**Files:**
- Modify: `Mobile/mobile_app/lib/features/ai_anomaly/presentation/widgets/anomaly_score_card.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/fever_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/digestive_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/estrus_detail_page.dart`

**Step 1: AnomalyScoreCard 改为 StatelessWidget**

```dart
class AnomalyScoreCard extends StatelessWidget {
  const AnomalyScoreCard({super.key, required this.data});
  final AnomalyScoreData? data;  // null = no data

  @override
  Widget build(BuildContext context) {
    // data == null or score <= 0.001 → 灰色"暂无异常数据"
    // 否则 → 分数卡片
  }
}
```

**Step 2: 三个详情页传参**

已 grep 确认三个页面当前调用方式一致（评审意见 #5 采纳）：
- `fever_detail_page.dart:52`: `AnomalyScoreCard(livestockId: livestockId)`
- `digestive_detail_page.dart:54`: `AnomalyScoreCard(livestockId: livestockId)`
- `estrus_detail_page.dart:53`: `AnomalyScoreCard(livestockId: livestockId)`

统一改为：
```dart
AnomalyScoreCard(data: detail.aiAnomaly)
```

> `anomalyDetailProvider` 和 `AnomalyApiRepository.fetchLatest()` 变为详情页不再使用，但保留——`AnomalyHistoryChart` 仍用 `anomalyHistoryProvider`（history 端点不受影响）。独立 `GET /health/anomaly/{id}` 端点变为仅内部/测试使用。

- [ ] **编译验证**: `flutter analyze --no-pub features/pages/fever_detail_page.dart`

---

## Task 6: Controller silentRefresh 方法

**方案 1 准备**

**Files:**
- Modify: `Mobile/mobile_app/lib/features/fever_warning/presentation/fever_controller.dart`
- Modify: `Mobile/mobile_app/lib/features/digestive/presentation/digestive_controller.dart`
- Modify: `Mobile/mobile_app/lib/features/estrus/presentation/estrus_controller.dart`
- Modify: `Mobile/mobile_app/lib/features/twin_overview/presentation/twin_overview_controller.dart`

**Pattern (复用 ranch_controller.silentRefresh):**

```dart
/// Silent refresh for auto-polling: no AsyncLoading spinner, keeps current data on error.
Future<void> silentRefresh() async {
  final next = await AsyncValue.guard(
    () => ref.read(repositoryProvider).fetchXxx(livestockId),
  );
  if (next.hasValue) state = next;
}
```

> 与 `refresh()` 的区别：`refresh()` 设 `AsyncLoading`（显示 spinner + 清空数据），`silentRefresh()` 只在成功时更新，失败时保留旧数据。
>
> 已确认 controller 类型差异：
> - `FeverDetailController` / `DigestiveDetailController` / `EstrusDetailController` 继承 `AsyncNotifier<T>`（非 farm-scoped），持有 `livestockId`
> - `TwinOverviewController` 继承 `FarmScopedAsyncNotifier<HealthOverviewResponse>`，无 livestockId

- [ ] **编译验证**: `flutter analyze --no-pub features/fever_warning/presentation/fever_controller.dart`

---

## Task 7: 四个页面接入 AutoRefreshListener

**方案 1+2 落地**

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/fever_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/digestive_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/estrus_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/twin_overview_page.dart`

**Pattern (每个页面 Scaffold 外层包裹):**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return AutoRefreshListener(
    interval: const Duration(seconds: 120),  // 详情页 120s; 概览页 180s
    onTick: () => ref.read(xxxControllerProvider(livestockId).notifier).silentRefresh(),
    child: Scaffold(
      // ... existing content ...
    ),
  );
}
```

> 孪生概览页用 `const Duration(seconds: 180)` + `twinOverviewControllerProvider`（无 family 参数，已确认名称匹配）。

- [ ] **编译验证**: `flutter analyze --no-pub`

---

## Task 8: 全量验证

- [ ] **后端编译**: `cd smart-livestock-server && ./gradlew compileJava -q`
- [ ] **后端 curl 验证**: `GET /farms/{farmId}/health/fever/{livestockId}` 响应包含 `aiAnomaly` 字段
- [ ] **前端 analyze**: `cd Mobile/mobile_app && flutter analyze --no-pub`（零 error）
- [ ] **gen-l10n**: 无新增 key（不涉及 i18n）
- [ ] **前端手动验证**: Chrome DevTools Network 面板确认 120s 间隔自动调用、调用次数从 3 减到 2
- [ ] **边界情况**: aiAnomaly 为 null 时详情页正常显示（不 500）
- [ ] **Commit**

---

## Self-Review

**方案覆盖:**
- 方案 1（分级间隔）→ Task 7：120s（详情）/ 180s（概览）→ Task 1 AutoRefreshListener
- 方案 2（可见性暂停）→ Task 1：WidgetsBindingObserver didChangeAppLifecycleState
- 方案 4（合并端点）→ Task 3（后端嵌入）+ Task 4-5（前端解析 + Card 改造）+ Task 2（模型提升）
- 方案 3（304）→ 明确跳过（数据源持续喂数据，命中率 ≈ 0%）

**调用次数减少:**
- 发热详情 3→2（-33%），消化详情 3→2（-33%），发情详情 2→1（-50%）
- SaaS 场景（15 并发用户 × 120s 刷新，混合分布）：约 90→61 次/5min（-32%）

**评审采纳项:**
- #1 AnomalyScoreData 从 feature 层提升到 core 层（Task 2，解决反向依赖）
- #2 buildAiSummary 走 HealthAnomalyService.getLatestSummary()（Task 3）
- #2c 三个 getXxxDetail() 方法显式列出（Task 3 Step 3）
- #4 AnomalyScoreData.livestockId 改为可选（Task 2 Step 3）
- #5 三个详情页调用方式已 grep 确认一致（Task 5 Step 2）
- #7 独立 anomaly 端点标注为仅内部/测试使用（Task 5 备注）
- #8 SaaS 计算修正为混合分布估算（SaaS 请求量估算表）

**评审排除项:**
- #9 部分失败降级 try-catch — `findLatestByFarmIdAndLivestockId()` 是纯 DB 查询，不经过 ai-platform，无独立失败路径

**测试计划（本次不实现，标注后续补充）:**
- `AutoRefreshListener` widget test：Timer 启动/暂停/恢复/取消
- `HealthApplicationService` 单元测试：getLatestSummary 有/无 anomaly 数据
- `FeverDetailData.fromJson` 单元测试：含/不含 aiAnomaly 字段

**不涉及:**
- 不改路由、不改 Tab、不新增端点（只在现有端点加字段）
- 不改 i18n（纯行为优化）
- `AnomalyHistoryChart` 和 `anomalyHistoryProvider` 不受影响
- 地图页已有 30s 自动刷新，不重复实现
