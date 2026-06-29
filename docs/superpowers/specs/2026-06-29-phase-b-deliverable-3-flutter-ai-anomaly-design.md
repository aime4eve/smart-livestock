# Phase B 交付物 3 — Flutter AI 异常分数双轨前端设计规格

> 版本: 1.0 | 日期: 2026-06-29 | 状态: 待评审
> 战略依据：[AI 健康路线图](./2026-06-19-ai-health-roadmap.md) §4 Phase B 交付物 3
> 后端 API：`AnomalyController`（Phase B 交付物 2，commit `5d17d612`）

## 1. 概述

在 Flutter 前端展示 ai-platform 的无监督健康异常检测结果，与现有规则引擎告警**双轨并排**展示。

### 核心原则

- **不替代规则引擎展示**：规则告警（发热/消化/发情/疫病/围栏）保持不变，AI 异常分数是**叠加层**
- **复用现有架构**：Riverpod 状态管理、go_router 路由、ApiClient.farmGet、FarmScopedNotifier 基类、FeatureFlags 门控
- **i18n 强制**：所有面向用户文案通过 `AppLocalizations` + `app_en.arb` / `app_zh.arb`，中英文同步

### 涉及的后端 API（Phase B 交付物 2 已实现）

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health/anomaly/{livestockId}` | GET | 最新 AI 异常分数（返回 anomalyScore + anomalyType） |
| `/health/anomaly/{livestockId}/history?limit=20` | GET | 历史异常分数列表 |
| `/farms/{farmId}/health/overview` | GET | 群体健康概览（后端需加 AI 统计字段） |
| `/farms/{farmId}/alerts` | GET | 告警列表（已含 source: RULE/AI） |
| `/health/overview` | GET | 群体健康概览（health_snapshots 表，后端已返回 ai_anomaly_score 列） |
| `/farms/{farmId}/alerts` | GET | 告警列表（后端 alerts 表已加 source 字段：RULE / AI） |

### 功能门控

AI 异常分数复用现有 `FeatureFlags.healthScore`（Standard 及以上 tier），与发热详情图表的锁定期望一致。

---

## 2. 架构

### 2.1 新增模块：`features/ai_anomaly/`

```
features/ai_anomaly/
├── domain/
│   └── anomaly_repository.dart          — Repository 接口 + 领域模型
├── data/
│   └── anomaly_api_repository.dart      — API 实现（ApiClient.farmGet）
└── presentation/
    ├── anomaly_controller.dart          — FarmScopedAsyncNotifier
    └── widgets/
        ├── anomaly_score_card.dart      — AI 分数卡片（单头）
        ├── anomaly_score_chip.dart      — AI 分数标签（列表行内）
        └── anomaly_history_chart.dart   — AI 分数历史趋势（详情页）
```

### 2.2 现有模块改动

| 模块 | 文件 | 改动 |
|------|------|------|
| **alerts** | `core_models.dart` | `AlertItem` 加 `source` 字段 |
| **alerts** | `alerts_api_repository.dart` | `_alertItemFromMap` 解析 `source` |
| **alerts** | `alerts_page.dart` | 按 source 分组展示（规则告警 + AI 告警） |
| **twin_overview** | `health_models.dart` | `HealthOverviewResponse.stats` 加 AI 统计字段 |
| **health 详情页** | `fever_detail_page.dart` 等 4 个 | 底部插入 AI 异常分数卡片 |
| **i18n** | `app_en.arb` / `app_zh.arb` | 新增 AI 异常相关 key |

### 2.3 不改动的部分

- 路由（`app_route.dart`）：AI 分数嵌入现有详情页，不新增路由
- 主 Shell / 底部导航栏：不加新 Tab
- 订阅模块：复用 `FeatureFlags.healthScore`，不新增 flag
- Mock server（`Mobile/backend/`）：AI 异常数据直接走真实后端，不进 mock

---

## 3. 领域模型

### 3.1 AnomalyScoreData（单头最新分数）

```dart
class AnomalyScoreData {
  final String livestockId;
  final double anomalyScore;       // 0.0 - 1.0
  final String anomalyType;        // normal / circadian_disruption / abrupt_change / multivariate
  final DateTime? assessedAt;
  final int? nEff;                 // 有效样本量
  final String? capabilityUsed;    // health_l1 / none
}
```

JSON 来源：`GET /health/anomaly/{livestockId}` 返回的结构：

```json
// 有数据时
{"livestockId": 1, "anomalyScore": 0.75, "anomalyType": "multivariate", ...}

// 无数据时（后端返回默认）
{"anomalyScore": 0.0, "anomalyType": "normal"}
```

### 3.2 AnomalyScoreHistoryItem（历史记录）

```dart
class AnomalyScoreHistoryItem {
  final String livestockId;
  final double anomalyScore;
  final String anomalyType;
  final DateTime assessedAt;
}
```

JSON 来源：`GET /health/anomaly/{livestockId}/history?limit=20`，返回 `List<Map>`。

### 3.3 AlertItem 扩展（source 字段）

```dart
// core_models.dart — AlertItem 加 source
class AlertItem {
  // ... 现有字段 ...
  final String source;  // 新增: "RULE" / "AI"，默认 "RULE"
}
```

### 3.4 HealthOverviewStats 扩展（群体 AI 统计）

```dart
// twin_models.dart — TwinOverviewStats 加 AI 字段
class TwinOverviewStats {
  // ... 现有字段 ...
  final int aiAnomalyCount;         // 新增: AI 检测到异常的牲畜数
  final double avgAiAnomalyScore;   // 新增: 群体平均 AI 分数
}
```

> 后端 `/health/overview` 的 stats 中，每个 livestock 的 health_snapshot 有 `aiAnomalyScore` 列。后端需在 stats 聚合中加入 AI 字段——**若后端尚未加，前端先不展示群体 AI 统计，只做单头展示**。

---

## 4. Repository + Controller

### 4.1 AnomalyRepository（domain）

```dart
abstract class AnomalyRepository {
  Future<AnomalyScoreData> fetchLatest(String livestockId);
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId, {int limit = 20});
}
```

### 4.2 AnomalyApiRepository（data）

```dart
class AnomalyApiRepository implements AnomalyRepository {
  const AnomalyApiRepository();

  @override
  Future<AnomalyScoreData> fetchLatest(String livestockId) async {
    // AnomalyController is NOT under /farms/{farmId} path (uses @RequestParam farmId)
    // After backend path alignment, this becomes: farmGet('/health/anomaly/$livestockId')
    final farmId = ref.read(sessionControllerProvider).activeFarmId ?? '1';
    final data = await ApiClient.instance.get(
        '/health/anomaly/$livestockId?farmId=$farmId');
    return AnomalyScoreData(
      livestockId: livestockId,
      anomalyScore: (data['anomalyScore'] as num?)?.toDouble() ?? 0.0,
      anomalyType: data['anomalyType'] as String? ?? 'normal',
      assessedAt: data['assessedAt'] != null
          ? DateTime.tryParse(data['assessedAt'] as String) : null,
      nEff: data['nEff'] as int?,
      capabilityUsed: data['capabilityUsed'] as String?,
    );
  }

  @override
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId, {int limit = 20}) async {
    final data = await ApiClient.instance.farmGet(
        '/health/anomaly/$livestockId/history?limit=$limit');
    final items = data['items'] as List? ?? data as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((m) => AnomalyScoreHistoryItem(
              livestockId: livestockId,
              anomalyScore: (m['anomalyScore'] as num?)?.toDouble() ?? 0.0,
              anomalyType: m['anomalyType'] as String? ?? 'normal',
              assessedAt: m['assessedAt'] != null
                  ? DateTime.tryParse(m['assessedAt'] as String) ?? DateTime.now()
                  : DateTime.now(),
            ))
        .toList();
  }
}
```

> 注意：`GET /health/anomaly/{id}` 不是 farm-scoped（后端 `AnomalyController` 直接用 `@RequestParam farmId`，不走 `/farms/{farmId}` 前缀）。但 `farmGet` 会加 `/farms/{farmId}` 前缀。

> **后端 API 路径已核实**：`AnomalyController` 的 `@RequestMapping` 是 `/api/v1/health/anomaly`（不在 `/farms/{farmId}` 路径下），用 `@RequestParam farmId` 接收牧场参数。其他 health controller（Fever/Digestive/Estrus/Epidemic）都在 `/api/v1/farms/{farmId}/health` 下，前端的 `farmGet` 能直接用。但 `AnomalyController` 不是 farm-scoped 路径。
>
> **前端对接方式**：前端需改用 `ApiClient.instance.get('/health/anomaly/$livestockId?farmId=$farmId')` 而非 `farmGet`。farmId 从 `sessionControllerProvider` 获取。
>
> **后端修正项**：为保持一致性，`AnomalyController` 应改为 `@RequestMapping("/api/v1/farms/{farmId}/health/anomaly")`，与 Fever/Digestive/Estrus/Epidemic 对齐。这样前端可直接用 `farmGet`。此改动归入本设计的前置依赖（后端一行路径修改）。

### 4.3 AnomalyController（presentation）

```dart
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

// Family provider for per-livestock AI anomaly data
final anomalyDetailProvider = AutoDisposeAsyncNotifierProvider.family<
    AnomalyDetailController, AnomalyScoreData, String>(
  AnomalyDetailController.new,
);
```

> `AutoDispose` + `family`：进入详情页加载，离开时自动释放。农场切换时 `watchActiveFarmId()` 触发重建。

---

## 5. UI 组件设计

### 5.1 AnomalyScoreCard（详情页卡片）

嵌入四个健康详情页（fever / digestive / estrus / epidemic）底部。

```
┌─────────────────────────────────────────┐
│  AI 异常检测                   Standard+ │
│                                         │
│  ┌─────────┐  异常类型: 多维联合异常    │
│  │  0.75   │  有效样本: 50             │
│  │ ███████ │  评估时间: 10分钟前        │
│  └─────────┘                            │
│                                         │
│  [查看历史趋势 →]                       │
└─────────────────────────────────────────┘
```

- 分数 < 0.001：灰色「暂无异常」状态
- 分数 0.001–0.7：黄色警示
- 分数 ≥ 0.7：红色告警
- Feature gating：basic tier 显示锁定覆盖层（复用 `LockedOverlay`）

### 5.2 AnomalyScoreChip（列表行内标签）

嵌入发热/消化/发情列表的每行右侧，显示 AI 分数状态。

```
┌──────────────────────────────────────────────────┐
│ SL-2024-003  体温 39.6°C  ⚠️ AI: 0.75  [详情 →]  │
└──────────────────────────────────────────────────┘
```

- 分数 < 0.001：不显示（避免列表行噪音）
- 分数 0.001–0.7：黄色圆角标签 `AI 0.xx`
- 分数 ≥ 0.7：红色圆角标签 `AI 0.xx ⚠`

### 5.3 AnomalyHistoryChart（历史趋势）

在 `AnomalyScoreCard` 的「查看历史趋势」点击后展开（或独立页面）。

```
1.0 ┤    ╭───╮
0.8 ┤   ╭╯   ╰╮
0.6 ┤  ╭╯     ╰───
0.4 ┤ ╭╯
0.2 ┤─╯
0.0 ┼──────────────────
    00:00  06:00  12:00  18:00  24:00
```

- 用 `fl_chart`（已有依赖，fever_detail_page 已用）
- 横轴：时间，纵轴：anomaly_score（0-1）
- 0.7 阈值线（虚线，标注「告警阈值」）

### 5.4 告警页 source 分组

`alerts_page.dart` 现有逻辑：全部告警按时间排列。

改动后：

```
┌─────────────────────────────────────────┐
│  告警 (12)                               │
│                                         │
│  ▸ 规则告警 (8)                          │
│    围栏越界 [SL-003]  CRITICAL  3分钟前  │
│    发热异常 [SL-007]  WARNING   8分钟前  │
│    ...                                   │
│                                         │
│  ▸ AI 异常 (4)                           │
│    多维联合异常 [SL-003]  AI 0.85  5分钟前│
│    温度突变 [SL-012]  AI 0.72  12分钟前  │
│    ...                                   │
└─────────────────────────────────────────┘
```

- `AlertItem.source` = "RULE" → 规则告警分组
- `AlertItem.source` = "AI" → AI 异常分组
- 默认全部（source 为 null 时归入 RULE）

---

## 6. 详情页接入点（逐个核实）

### 6.1 FeverDetailPage（发热详情）

文件：`features/pages/fever_detail_page.dart`

现有结构：状态卡片 → 设备信息 → 温度图表 → 发热时长图表 → 结论卡片。

接入点：在「结论卡片」之后追加 `AnomalyScoreCard`。需要检查 Feature gating（`hasHealthScore`），若 basic tier 则显示锁定覆盖层。

```dart
// fever_detail_page.dart — ListView children 末尾追加
if (hasHealthScore)
  AnomalyScoreCard(livestockId: livestockId)
else
  LockedOverlay(...),
```

### 6.2 DigestiveDetailPage（消化详情）

文件：`features/pages/digestive_detail_page.dart`

接入点：同样在详情内容末尾追加 `AnomalyScoreCard`。

### 6.3 EstrusDetailPage（发情详情）

文件：`features/pages/estrus_detail_page.dart`

接入点：同上。

### 6.4 EpidemicPage（疫病概览）

文件：`features/pages/epidemic_page.dart`

接入点：疫病页是群体概览（非单头详情），不嵌入 `AnomalyScoreCard`。AI 异常在群体层面的展示放在孪生概览页。

### 6.5 孪生概览页（TwinOverviewPage）

文件：`features/pages/twin_overview_page.dart`

接入点：在 `sceneSummary` 区域（发热/消化/发情/疫病四个卡片之后）新增一个「AI 异常检测概览」卡片，显示群体 AI 统计（若后端 `/health/overview` stats 已含 AI 字段）。

> **后端已核实**：`HealthApplicationService.getOverview()` 当前**不返回 AI 字段**。`HealthOverviewStats` 没有 `aiAnomalyCount` / `avgAiAnomalyScore`。`HealthSnapshot` 已有 `aiAnomalyScore` / `aiAnomalyType` / `aiAssessedAt` 列（Phase B 交付物 2 加的），但 overview 聚合没读它们。
>
> **后端修正项**：`getOverview()` 的 stats 和 sceneSummary 需加 AI 字段聚合（从 `snapshots.stream().filter(s -> s.getAiAnomalyScore() != null)` 统计）。`HealthOverviewStats` DTO 和 `SceneSummary` DTO 也需加字段。此改动归入本设计的前置依赖（后端 overview 扩展）。

### 6.6 告警页（AlertsPage）

文件：`features/pages/alerts_page.dart`

接入点：`_buildContent` 方法改为按 source 分组。

---

## 7. AlertItem source 字段改动（逐文件核实）

### 7.1 core_models.dart — AlertItem 加字段

```dart
class AlertItem {
  const AlertItem({
    // ... 现有参数 ...
    this.source = 'RULE',
  });

  // ... 现有字段 ...
  final String source;  // RULE / AI
}
```

### 7.2 alerts_api_repository.dart — _alertItemFromMap 解析

```dart
static AlertItem _alertItemFromMap(Map<String, dynamic> m) {
  // ... 现有解析 ...
  final source = (m['source'] as String?) ?? 'RULE';
  return AlertItem(
    // ... 现有字段 ...
    source: source,
  );
}
```

### 7.3 alerts_controller.dart — 无需改动

`AlertsController` 只是转发 repository 数据，`AlertItem` 加字段后自动包含。

### 7.4 alerts_page.dart — 按 source 分组

```dart
Widget _buildContent(BuildContext context, AlertsListData data, ...) {
  final ruleAlerts = data.items.where((a) => a.source != 'AI').toList();
  final aiAlerts = data.items.where((a) => a.source == 'AI').toList();

  return Column(
    children: [
      if (ruleAlerts.isNotEmpty) _buildAlertSection(ruleAlerts, l10n),
      if (aiAlerts.isNotEmpty) _buildAiAlertSection(aiAlerts, l10n),
    ],
  );
}
```

### 7.5 ranch 告警卡片 — 无需改动

`ranch/presentation/widgets/alert_card.dart` 和 `health_bottom_sheet.dart` 里的告警卡片不涉及 source 分组（它们按 type 分类），source 字段是透传的。

---

## 8. i18n 键（中英文同步）

新增 key 列表（写入 `app_en.arb` + `app_zh.arb`）：

```json
"aiAnomalyTitle": "AI Anomaly Detection",
"aiAnomalyTitleZh": "AI 异常检测",
"aiAnomalyScoreLabel": "Anomaly Score",
"aiAnomalyScoreLabelZh": "异常分数",
"aiAnomalyTypeNormal": "Normal",
"aiAnomalyTypeNormalZh": "正常",
"aiAnomalyTypeCircadian": "Circadian Disruption",
"aiAnomalyTypeCircadianZh": "节律异常",
"aiAnomalyTypeAbrupt": "Abrupt Change",
"aiAnomalyTypeAbruptZh": "突变",
"aiAnomalyTypeMultivariate": "Multivariate Anomaly",
"aiAnomalyTypeMultivariateZh": "多维联合异常",
"aiAnomalyNoData": "No anomaly data yet",
"aiAnomalyNoDataZh": "暂无异常数据",
"aiAnomalyEffSamples": "Effective samples",
"aiAnomalyEffSamplesZh": "有效样本",
"aiAnomalyAssessedAt": "Assessed",
"aiAnomalyAssessedAtZh": "评估时间",
"aiAnomalyViewHistory": "View history trend",
"aiAnomalyViewHistoryZh": "查看历史趋势",
"aiAnomalyAlertThreshold": "Alert threshold",
"aiAnomalyAlertThresholdZh": "告警阈值",
"aiAnomalyRuleAlerts": "Rule Alerts",
"aiAnomalyRuleAlertsZh": "规则告警",
"aiAnomalyAiAlerts": "AI Anomalies",
"aiAnomalyAiAlertsZh": "AI 异常",
"aiAnomalyOverview": "AI Anomaly Overview",
"aiAnomalyOverviewZh": "AI 异常概览",
"aiAnomalyAvgScore": "Average Score",
"aiAnomalyAvgScoreZh": "平均分数",
"aiAnomalyAnomalyCount": "Anomaly Count",
"aiAnomalyAnomalyCountZh": "异常数",
```

---

## 9. 实施顺序（依赖关系）

```
1. AlertItem source 字段 → 核心模型改动（所有后续依赖）
2. ai_anomaly 模块（domain + data + controller）→ API 对接
3. AnomalyScoreCard + AnomalyScoreChip + AnomalyHistoryChart → UI 组件
4. 健康详情页接入（fever/digestive/estrus）→ 嵌入组件
5. 告警页 source 分组 → 告警展示
6. i18n → gen-l10n 验证
7. flutter analyze + 编译验证
```

## 10. 边界与不做

- **不做**：AI 异常的独立页面/路由（嵌入现有详情页即可）
- **不做**：告警页的 source 筛选器 UI（只做分组展示，不做 tab/filter）
- **不做**：AI 异常的推送通知（告警已有通知渠道，source=AI 的告警自然走同一渠道）
- **不做**：Mock server 的 AI 异常数据（AI 数据走真实后端）
- **条件性做**：群体 AI 概览（孪生概览页），仅在后端 `/health/overview` stats 返回 AI 字段时

## 11. 关联文档

- 路线图：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` §4 Phase B
- 后端设计：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md` §6（持久化）/ §3（数据流）
- 后端实施计划：`docs/superpowers/plans/2026-06-26-phase-b-deliverable-2-java-integration-plan.md`
- 前端适配总览：`docs/superpowers/plans/2026-05-23-flutter-full-adaptation-plan.md`
