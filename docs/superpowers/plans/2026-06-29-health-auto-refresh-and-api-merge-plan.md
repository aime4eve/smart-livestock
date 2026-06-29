# 健康数据自动刷新 + API 合并实施计划

> 方案 1（分级刷新间隔）+ 方案 2（可见性暂停）+ 方案 4（合并端点）

**Goal:** 健康详情页和孪生概览页支持自动刷新（分级间隔 + 后台暂停），并将 AI 异常分数嵌入现有详情端点，减少前端 API 调用次数。面向 SaaS 多租户并发场景。

**Architecture:**
- 方案 1+2: 新建 `AutoRefreshListener` wrapper widget（Timer.periodic + WidgetsBindingObserver），四个页面通过包裹接入，保持 `ConsumerWidget` 不变
- 方案 4: 后端 `FeverDetail` / `DigestiveDetail` / `EstrusDetail` record 加 AI 字段，`HealthApplicationService` 查询最新 anomaly 嵌入；前端 `AnomalyScoreCard` 从 `ConsumerWidget`（自取数据）改为 `StatelessWidget`（收参数），消除详情页的独立 anomaly API 调用

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
| 发热详情 | `GET /fever/{id}`（含 AI 分数）+ `GET /fever/{id}/duration` | 2 | -1 |
| 消化详情 | `GET /digestive/{id}`（含 AI 分数）+ `GET /digestive/{id}/heatmap` | 2 | -1 |
| 发情详情 | `GET /estrus/{id}`（含 AI 分数） | 1 | -1 |
| 孪生概览 | `GET /health/overview`（不变） | 1 | — |

> `duration` / `heatmap` 端点保留为独立调用——它们是 feature-gated（Standard+/Premium+），仅付费用户触发，数据量较大（图表数据），不值得无条件嵌入。

### 刷新间隔设计

| 页面 | 间隔 | 理由 |
|------|------|------|
| 地图/GPS（ranch_page） | 30s | 已有，不改；位置需要实时感知 |
| 健康详情页（fever/digestive/estrus） | 120s | 体温 30s 变化 <0.1°C，2 分钟足够感知"数据是活的" |
| 孪生概览页 | 180s | 聚合数据，变化更慢 |

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

- [ ] **编译验证**: `flutter analyze --no-pub core/widgets/auto_refresh_listener.dart`

---

## Task 2: 后端 — 详情端点嵌入 AI 异常分数

**方案 4 后端**

**Files:**
- Modify: `smart-livestock-server/.../health/application/dto/HealthDtos.java`
- Modify: `smart-livestock-server/.../health/application/service/HealthApplicationService.java`

**Step 1: HealthDtos 三个 record 加 AI 字段**

```java
public record FeverDetail(
    // ... existing fields ...
    List<TemperatureReading> recent72h,
+   AiAnomalySummary aiAnomaly        // nullable, null = no AI data
) {}

public record DigestiveDetail(
    // ... existing fields ...
    List<MotilityReading> recent24h,
+   AiAnomalySummary aiAnomaly
) {}

public record EstrusDetail(
    // ... existing fields ...
    List<EstrusTrendPoint> trend7d,
+   AiAnomalySummary aiAnomaly
) {}

+ public record AiAnomalySummary(
+     Double anomalyScore,      // null = no assessment yet
+     String anomalyType,       // normal / circadian_disruption / abrupt_change / multivariate
+     Integer nEff,
+     String capabilityUsed,
+     Instant assessedAt
+ ) {}
```

**Step 2: HealthApplicationService 查询并嵌入**

`HealthApplicationService` 已注入 `AnomalyScoreRepository`（通过 `healthAnomalyService` 依赖链）。在 `getFeverDetail()` / `getDigestiveDetail()` / `getEstrusDetail()` 尾部查询最新 anomaly：

```java
private AiAnomalySummary buildAiSummary(Long farmId, Long livestockId) {
    return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
        .map(s -> new AiAnomalySummary(
            s.getAnomalyScore().doubleValue(),
            s.getAnomalyType(),
            s.getNEff(),
            s.getCapabilityUsed(),
            s.getCreatedAt()
        ))
        .orElse(null);
}
```

> `HealthApplicationService` 需要注入 `AnomalyScoreRepository`（当前通过 `HealthAnomalyService` 间接持有，直接注入更简洁）。

- [ ] **编译验证**: `./gradlew compileJava -q`

---

## Task 3: 前端模型解析 AI 嵌入字段

**方案 4 前端**

**Files:**
- Modify: `Mobile/mobile_app/lib/core/models/health_models.dart`

**Step 1: FeverDetailData / DigestiveDetailData / EstrusDetailData 加 aiAnomaly 字段**

```dart
class FeverDetailData {
  // ... existing fields ...
+ final AnomalyScoreData? aiAnomaly;

  factory FeverDetailData.fromJson(Map<String, dynamic> m) {
    return FeverDetailData(
      // ... existing parsing ...
+     aiAnomaly: m['aiAnomaly'] != null
+         ? AnomalyScoreData.fromJson({
+             ...m['aiAnomaly'],
+             'livestockId': m['livestockId'],
+           })
+         : null,
    );
  }
}
```

同样修改 `DigestiveDetailData` 和 `EstrusDetailData`。

> `AnomalyScoreData` 已在 `features/ai_anomaly/domain/anomaly_models.dart` 定义，需要 import 或将模型提升到 `health_models.dart`。

- [ ] **编译验证**: `flutter analyze --no-pub core/models/health_models.dart`

---

## Task 4: AnomalyScoreCard 改为纯展示组件 + 详情页传参

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

```dart
// Before (ConsumerWidget, 自取数据):
AnomalyScoreCard(livestockId: livestockId)

// After (纯展示, 从 detail 响应取数据):
AnomalyScoreCard(data: detail.aiAnomaly)
```

> `anomalyDetailProvider` 和 `AnomalyApiRepository.fetchLatest()` 变为详情页不再使用，但保留——`AnomalyHistoryChart` 仍用 `anomalyHistoryProvider`（history 端点不受影响）。

- [ ] **编译验证**: `flutter analyze --no-pub features/pages/fever_detail_page.dart`

---

## Task 5: Controller silentRefresh 方法

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

- [ ] **编译验证**: `flutter analyze --no-pub features/fever_warning/presentation/fever_controller.dart`

---

## Task 6: 四个页面接入 AutoRefreshListener

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

> 孪生概览页用 `const Duration(seconds: 180)` + `twinOverviewControllerProvider`（无 family 参数）。

- [ ] **编译验证**: `flutter analyze --no-pub`

---

## Task 7: 全量验证

- [ ] **后端编译**: `cd smart-livestock-server && ./gradlew compileJava -q`
- [ ] **前端 analyze**: `cd Mobile/mobile_app && flutter analyze --no-pub`（零 error）
- [ ] **gen-l10n**: 无新增 key（不涉及 i18n）
- [ ] **Commit**

---

## Self-Review

**方案覆盖:**
- 方案 1（分级间隔）→ Task 6：120s（详情）/ 180s（概览）→ Task 1 AutoRefreshListener
- 方案 2（可见性暂停）→ Task 1：WidgetsBindingObserver didChangeAppLifecycleState
- 方案 4（合并端点）→ Task 2（后端嵌入）+ Task 3-4（前端解析 + Card 改造）
- 方案 3（304）→ 明确跳过（数据源持续喂数据，命中率 ≈ 0%）

**调用次数减少:**
- 发热详情 3→2，消化详情 3→2，发情详情 2→1
- SaaS 场景（15 并发用户 × 120s 刷新）：从 ~113 次/5min 降至 ~63 次/5min（-44%）

**不涉及:**
- 不改路由、不改 Tab、不新增端点（只在现有端点加字段）
- 不改 i18n（纯行为优化）
- `AnomalyHistoryChart` 和 `anomalyHistoryProvider` 不受影响
- 地图页已有 30s 自动刷新，不重复实现
