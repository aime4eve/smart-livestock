# Phase B 交付物 3 实施计划 — Flutter AI 异常分数双轨前端

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** 在 Flutter 前端展示 ai-platform 无监督健康异常检测结果，与现有规则引擎告警双轨并排。新建 `features/ai_anomaly` 模块，修改 AlertItem 加 source 字段、告警页分组、四个健康详情页嵌入 AI 分数卡片、i18n 双语。

**Architecture:** 新建 `features/ai_anomaly/`（domain repository + API repository + controller + 3 个 widget），对接后端 `GET /farms/{farmId}/health/anomaly/{id}` 和 `GET /farms/{farmId}/health/anomaly/{id}/history`。复用 FarmScopedAsyncNotifier + ApiClient.farmGet + FeatureFlags.healthScore 门控 + fl_chart。

**关联文档:**
- 设计规格：`docs/superpowers/specs/2026-06-29-phase-b-deliverable-3-flutter-ai-anomaly-design.md`
- 后端前置：✅ AnomalyController 路径已对齐 + Overview AI 字段已加（commit `94c6f9ca`）

---

## Task 1: AlertItem source 字段

**Files:**
- Modify: `Mobile/mobile_app/lib/core/models/core_models.dart`

- [ ] **Step 1: AlertItem 加 source 字段**

```dart
class AlertItem {
  const AlertItem({
    // ... existing params ...
    this.source = 'RULE',
  });

  // ... existing fields ...
  final String source; // RULE / AI
}
```

- [ ] **Step 2: 编译验证**

Run: `cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub core/models/core_models.dart 2>&1 | tail -5`

- [ ] **Step 3: Commit**

---

## Task 2: alerts_api_repository 解析 source

**Files:**
- Modify: `Mobile/mobile_app/lib/features/alerts/data/alerts_api_repository.dart`

- [ ] **Step 1: _alertItemFromMap 解析 source**

```dart
static AlertItem _alertItemFromMap(Map<String, dynamic> m) {
  // ... existing parsing ...
  final source = (m['source'] as String?) ?? 'RULE';
  return AlertItem(
    // ... existing fields ...
    source: source,
  );
}
```

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 3: ai_anomaly 领域模型 + Repository

**Files:**
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/domain/anomaly_models.dart`
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/domain/anomaly_repository.dart`
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/data/anomaly_api_repository.dart`

- [ ] **Step 1: 领域模型**

`anomaly_models.dart`:
```dart
class AnomalyScoreData {
  final String livestockId;
  final double anomalyScore; // 0.0 - 1.0
  final String anomalyType;   // normal / circadian_disruption / abrupt_change / multivariate
  final DateTime? assessedAt;
  final int? nEff;
  final String? capabilityUsed;

  const AnomalyScoreData({
    required this.livestockId,
    required this.anomalyScore,
    required this.anomalyType,
    this.assessedAt,
    this.nEff,
    this.capabilityUsed,
  });

  factory AnomalyScoreData.fromJson(Map<String, dynamic> json) {
    return AnomalyScoreData(
      livestockId: (json['livestockId'] ?? '').toString(),
      anomalyScore: (json['anomalyScore'] as num?)?.toDouble() ?? 0.0,
      anomalyType: json['anomalyType'] as String? ?? 'normal',
      assessedAt: json['assessedAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['assessedAt'] ?? json['createdAt'])
          : null,
      nEff: json['nEff'] as int?,
      capabilityUsed: json['capabilityUsed'] as String?,
    );
  }
}

class AnomalyScoreHistoryItem {
  final double anomalyScore;
  final String anomalyType;
  final DateTime assessedAt;

  const AnomalyScoreHistoryItem({
    required this.anomalyScore,
    required this.anomalyType,
    required this.assessedAt,
  });

  factory AnomalyScoreHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnomalyScoreHistoryItem(
      anomalyScore: (json['anomalyScore'] as num?)?.toDouble() ?? 0.0,
      anomalyType: json['anomalyType'] as String? ?? 'normal',
      assessedAt: json['assessedAt'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['assessedAt'] ?? json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
```

- [ ] **Step 2: Repository 接口**

`anomaly_repository.dart`:
```dart
import '../domain/anomaly_models.dart';

abstract class AnomalyRepository {
  Future<AnomalyScoreData> fetchLatest(String livestockId);
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId, {int limit = 20});
}
```

- [ ] **Step 3: API Repository 实现**

`anomaly_api_repository.dart`:
```dart
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import '../domain/anomaly_models.dart';
import '../domain/anomaly_repository.dart';

class AnomalyApiRepository implements AnomalyRepository {
  const AnomalyApiRepository();

  @override
  Future<AnomalyScoreData> fetchLatest(String livestockId) async {
    final data = await ApiClient.instance.farmGet('/health/anomaly/$livestockId');
    final merged = <String, dynamic>{...data, 'livestockId': livestockId};
    return AnomalyScoreData.fromJson(merged);
  }

  @override
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId, {int limit = 20}) async {
    final data = await ApiClient.instance
        .farmGet('/health/anomaly/$livestockId/history?limit=$limit');
    final items = data['items'] as List? ?? data as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AnomalyScoreHistoryItem.fromJson)
        .toList();
  }
}
```

- [ ] **Step 4: 编译验证**

- [ ] **Step 5: Commit**

---

## Task 4: AnomalyController（Riverpod）

**Files:**
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/presentation/anomaly_controller.dart`

- [ ] **Step 1: Controller + Provider**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import '../data/anomaly_api_repository.dart';
import '../domain/anomaly_models.dart';
import '../domain/anomaly_repository.dart';

final anomalyRepositoryProvider = Provider<AnomalyRepository>(
  (_) => const AnomalyApiRepository(),
);

class AnomalyDetailController extends FarmScopedAsyncNotifier<AnomalyScoreData> {
  final String livestockId;

  AnomalyDetailController(this.livestockId);

  @override
  Future<AnomalyScoreData> build() async {
    watchActiveFarmId();
    return ref.read(anomalyRepositoryProvider).fetchLatest(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(anomalyRepositoryProvider).fetchLatest(livestockId),
    );
  }
}

final anomalyDetailProvider = AutoDisposeAsyncNotifierProvider.family<
    AnomalyDetailController, AnomalyScoreData, String>(
  AnomalyDetailController.new,
);

// History provider (for chart)
final anomalyHistoryProvider =
    FutureProvider.autoDispose.family<List<AnomalyScoreHistoryItem>, String>(
  (ref, livestockId) {
    ref.watch(AnomalyDetailController._farmIdProvider);
    return ref.read(anomalyRepositoryProvider).fetchHistory(livestockId);
  },
);
```

> 简化：history provider 直接用 FutureProvider.family（不需要 FarmScoped，因为 farmGet 自动处理）。

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 5: AnomalyScoreCard Widget

**Files:**
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/presentation/widgets/anomaly_score_card.dart`

- [ ] **Step 1: 卡片组件**

显示 AI 分数、异常类型、有效样本、评估时间。颜色按分数分级（<0.001 灰, 0.001-0.7 黄, >=0.7 红）。

- 分数 0（暂无数据）→ 灰色卡片「暂无异常数据」
- 分数 >0 → 彩色分数 + 异常类型翻译 + 元信息
- 嵌入详情页底部

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 6: AnomalyScoreChip Widget

**Files:**
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/presentation/widgets/anomaly_score_chip.dart`

- [ ] **Step 1: 列表行内标签**

分数 < 0.001 不显示，0.001-0.7 黄色标签，>=0.7 红色标签。

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 7: AnomalyHistoryChart Widget

**Files:**
- Create: `Mobile/mobile_app/lib/features/ai_anomaly/presentation/widgets/anomaly_history_chart.dart`

- [ ] **Step 1: fl_chart 趋势图**

纵轴 0-1，0.7 处虚线标注告警阈值。用 fl_chart（已有依赖）。

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 8: 健康详情页接入

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/fever_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/digestive_detail_page.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/estrus_detail_page.dart`

- [ ] **Step 1: fever_detail_page 底部插入 AnomalyScoreCard**

在 ListView children 末尾、结论卡片之后追加。检查 hasHealthScore 门控。

- [ ] **Step 2: digestive_detail_page 同上**

- [ ] **Step 3: estrus_detail_page 同上**

- [ ] **Step 4: 编译验证**

Run: `cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`

- [ ] **Step 5: Commit**

---

## Task 9: 告警页 source 分组

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/alerts_page.dart`

- [ ] **Step 1: _buildContent 按 source 分组**

```dart
final ruleAlerts = data.items.where((a) => a.source != 'AI').toList();
final aiAlerts = data.items.where((a) => a.source == 'AI').toList();
```

两组分别渲染，AI 组用不同标题（i18n key `aiAnomalyAiAlerts`）。

- [ ] **Step 2: 编译验证**

- [ ] **Step 3: Commit**

---

## Task 10: 孪生概览页 AI 概览卡片

**Files:**
- Modify: `Mobile/mobile_app/lib/core/models/health_models.dart`
- Modify: `Mobile/mobile_app/lib/features/pages/twin_overview_page.dart`

- [ ] **Step 1: HealthOverviewResponse stats 解析 AI 字段**

`TwinOverviewStats` 加 `aiAnomalyCount` / `avgAiAnomalyScore`，`_parseStats` 解析新字段。

- [ ] **Step 2: 孪生概览页 sceneSummary 区域加 AI 卡片**

在四个场景卡片之后加一个 AI 概览卡片。

- [ ] **Step 3: 编译验证**

- [ ] **Step 4: Commit**

---

## Task 11: i18n

**Files:**
- Modify: `Mobile/mobile_app/lib/l10n/app_en.arb`
- Modify: `Mobile/mobile_app/lib/l10n/app_zh.arb`

- [ ] **Step 1: app_en.arb 新增 26 个 key**

```json
"aiAnomalyTitle": "AI Anomaly Detection",
"aiAnomalyScoreLabel": "Anomaly Score",
"aiAnomalyTypeNormal": "Normal",
"aiAnomalyTypeCircadian": "Circadian Disruption",
"aiAnomalyTypeAbrupt": "Abrupt Change",
"aiAnomalyTypeMultivariate": "Multivariate Anomaly",
"aiAnomalyNoData": "No anomaly data yet",
"aiAnomalyEffSamples": "Effective samples",
"aiAnomalyAssessedAt": "Assessed",
"aiAnomalyViewHistory": "View history trend",
"aiAnomalyAlertThreshold": "Alert threshold",
"aiAnomalyRuleAlerts": "Rule Alerts",
"aiAnomalyAiAlerts": "AI Anomalies",
"aiAnomalyOverview": "AI Anomaly Overview",
"aiAnomalyAvgScore": "Average Score",
"aiAnomalyAnomalyCount": "Anomaly Count"
```

- [ ] **Step 2: app_zh.arb 同步中文翻译**

- [ ] **Step 3: gen-l10n**

Run: `cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 12: 全量验证

- [ ] **Step 1: flutter analyze 全项目**

Run: `cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
Expected: 无 error

- [ ] **Step 2: gen-l10n 无缺失 key**

Run: `cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n 2>&1 | tail -5`

- [ ] **Step 3: Commit（若有未提交改动）**

---

## Self-Review

**Spec 覆盖（design doc 章节 → Task）：**
- §3.1 AnomalyScoreData → Task 3 ✅
- §3.2 AnomalyScoreHistoryItem → Task 3 ✅
- §3.3 AlertItem source → Task 1 ✅
- §4.1-4.2 AnomalyRepository → Task 3 ✅
- §4.3 AnomalyController → Task 4 ✅
- §5.1 AnomalyScoreCard → Task 5 ✅
- §5.2 AnomalyScoreChip → Task 6 ✅
- §5.3 AnomalyHistoryChart → Task 7 ✅
- §6.1-6.3 健康详情页接入 → Task 8 ✅
- §6.6 告警页分组 → Task 9 ✅
- §6.5 孪生概览页 AI 概览 → Task 10 ✅
- §8 i18n → Task 11 ✅

**已知边界：**
- AnomalyController 已对齐为 farm-scoped 路径（commit `94c6f9ca`），前端用 `farmGet` 直接调用
- Overview AI 字段已加（commit `94c6f9ca`），Task 10 解析即可
- FeatureFlags.healthScore 复用现有 standard+ 门控
- 不新增路由，不新增 Tab，不改 Mock server
