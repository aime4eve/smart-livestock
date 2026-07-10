# 牧场面板告警 UI 前端实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 owner 牧场 Tab 底部面板从凌乱的长列表重构为钻取式告警管理系统（围栏+健康两条业务主线）。

**Architecture:** 四层钻取（收起态→卡片仪表盘→告警列表→详情），通知中心模型（已读/未读），围栏缓冲带三层空间可视化。前端先用 Mock JSON 数据验证 UI，后端 API 后续独立对接。

**Tech Stack:** Flutter 3.x / Dart 3.x / flutter_riverpod / go_router / flutter_map / fl_chart

**Spec:** `docs/superpowers/specs/2026-06-10-ranch-panel-alert-ui-design.md`

**Scope:** 仅前端 Flutter 代码（`Mobile/mobile_app/`）。后端 Spring Boot Flyway V19 + API 变更为独立计划。

---

## File Structure

### Create
- `lib/features/ranch/presentation/widgets/status_dashboard_card.dart` — 仪表盘卡片（围栏/健康分组）
- `lib/features/ranch/presentation/widgets/alert_card.dart` — 告警列表项（未读/已读 + 类型标签）
- `lib/features/ranch/presentation/widgets/device_info_line.dart` — 低调设备信息辅助行
- `lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart` — 围栏告警详情（地图型）
- `lib/features/ranch/presentation/widgets/auto_resolved_section.dart` — 已自动解除折叠区
- `lib/features/ranch/presentation/widgets/fence_buffer_layer.dart` — 地图缓冲带图层

### Modify
- `lib/features/ranch/domain/ranch_models.dart` — 扩展模型（read, distance, direction, fenceAlertSummary, healthAlertSummary, inFenceRate, 新告警类型）
- `lib/features/ranch/domain/ranch_repository.dart` — 新增 markRead / dismiss 抽象方法
- `lib/features/ranch/data/ranch_api_repository.dart` — 实现 markRead / dismiss
- `lib/features/ranch/presentation/ranch_controller.dart` — 钻取状态 + markRead / dismiss actions
- `lib/features/ranch/presentation/widgets/health_bottom_sheet.dart` — **重构**为钻取式架构
- `lib/features/pages/ranch_page.dart` — 缓冲带渲染 + 牲畜标注变色
- `lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart` — 新状态标签
- `lib/features/pages/fever_detail_page.dart` — 设备行 + 能力边界 + 标已读
- `lib/features/pages/digestive_detail_page.dart` — 同上
- `lib/features/pages/estrus_detail_page.dart` — 同上

### Test
- `test/features/ranch/ranch_models_test.dart` — 新字段解析
- `test/features/ranch/alert_card_test.dart` — 未读/已读视觉
- `test/features/ranch/status_dashboard_card_test.dart` — 数量 0 隐藏
- `test/features/ranch/health_bottom_sheet_test.dart` — 钻取层级渲染
- `test/features/ranch/fence_alert_detail_test.dart` — 围栏详情要素

---

## Task 1: 扩展数据模型

**Files:**
- Modify: `lib/features/ranch/domain/ranch_models.dart`
- Test: `test/features/ranch/ranch_models_test.dart`

在 `ranch_models.dart` 中扩展以下内容：
- `RanchOverviewStats` 增加 `inFenceRate`（归栏率）
- `RanchAlertData` 增加 `read`（bool）、`distance`（double?）、`direction`（String?）、`resolvedType`（String?）
- 新增 `RanchAlertSummary`（告警分类计数：每种类型的活跃数量）
- `RanchOverview` 增加 `fenceAlertSummary`、`healthAlertSummary`
- 新增围栏告警类型常量

- [ ] **Step 1: 写模型测试**

创建 `test/features/ranch/ranch_models_test.dart`，测试新字段解析：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

void main() {
  group('RanchOverviewStats', () {
    test('parses inFenceRate', () {
      final stats = RanchOverviewStats.fromJson({
        'totalLivestock': 256,
        'healthyRate': 0.94,
        'alertCount': 3,
        'criticalCount': 1,
        'deviceOnlineRate': 0.95,
        'inFenceRate': 0.98,
      });
      expect(stats.inFenceRate, 0.98);
    });

    test('inFenceRate defaults to 0 when missing', () {
      final stats = RanchOverviewStats.fromJson({});
      expect(stats.inFenceRate, 0.0);
    });
  });

  group('RanchAlertData', () {
    test('parses read field', () {
      final alert = RanchAlertData.fromJson({
        'id': '1', 'type': 'FENCE_BREACH', 'severity': 'CRITICAL',
        'status': 'ACTIVE', 'message': 'test', 'read': true,
        'distance': 120.5, 'direction': 'NW',
      });
      expect(alert.read, true);
      expect(alert.distance, 120.5);
      expect(alert.direction, 'NW');
    });

    test('read defaults to false', () {
      final alert = RanchAlertData.fromJson({
        'id': '1', 'type': 'TEMPERATURE_ABNORMAL', 'severity': 'WARNING',
        'status': 'ACTIVE', 'message': 'test',
      });
      expect(alert.read, false);
      expect(alert.distance, isNull);
      expect(alert.direction, isNull);
    });

    test('parses resolvedType', () {
      final alert = RanchAlertData.fromJson({
        'id': '1', 'type': 'FENCE_BREACH', 'severity': 'CRITICAL',
        'status': 'AUTO_RESOLVED', 'message': 'test',
        'resolvedType': 'AUTO', 'resolvedAt': '2026-06-10T08:30:00Z',
      });
      expect(alert.resolvedType, 'AUTO');
    });
  });

  group('RanchAlertSummary', () {
    test('parses fence and health summaries', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {
          'totalLivestock': 256, 'healthyRate': 0.94,
          'alertCount': 5, 'criticalCount': 1, 'deviceOnlineRate': 0.95,
          'inFenceRate': 0.98,
        },
        'fenceAlertSummary': {
          'FENCE_BREACH': 1, 'FENCE_APPROACH': 2, 'ZONE_APPROACH': 1,
        },
        'healthAlertSummary': {
          'TEMPERATURE_ABNORMAL': 2, 'DIGESTIVE_ABNORMAL': 1, 'ESTRUS': 3,
        },
        'alerts': [], 'fences': [], 'livestockMarkers': [],
        'sceneSummary': null, 'pendingTasks': [],
      });
      expect(overview.fenceAlertSummary['FENCE_BREACH'], 1);
      expect(overview.fenceAlertSummary['FENCE_APPROACH'], 2);
      expect(overview.healthAlertSummary['ESTRUS'], 3);
    });

    test('summaries default to empty map', () {
      final overview = RanchOverview.fromJson({
        'overallStats': {}, 'alerts': [], 'fences': [],
        'livestockMarkers': [], 'sceneSummary': null, 'pendingTasks': [],
      });
      expect(overview.fenceAlertSummary, isEmpty);
      expect(overview.healthAlertSummary, isEmpty);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/mobile_app && flutter test test/features/ranch/ranch_models_test.dart
```

Expected: FAIL — `inFenceRate` getter not found, `read` not found, `RanchAlertSummary` not found.

- [ ] **Step 3: 实现模型扩展**

在 `RanchOverviewStats` 中添加 `inFenceRate` 字段：

```dart
final double inFenceRate;

// in fromJson constructor:
inFenceRate: (m['inFenceRate'] as num?)?.toDouble() ?? 0.0,
```

在 `RanchAlertData` 中添加新字段：

```dart
final bool read;
final double? distance;
final String? direction;
final String? resolvedType;

// in fromJson:
read: m['read'] as bool? ?? false,
distance: (m['distance'] as num?)?.toDouble(),
direction: m['direction'] as String?,
resolvedType: m['resolvedType'] as String?,
```

在 `RanchOverview` 中添加：

```dart
final Map<String, int> fenceAlertSummary;
final Map<String, int> healthAlertSummary;

// in fromJson:
fenceAlertSummary: (m['fenceAlertSummary'] as Map<String, dynamic>?)
    ?.map((k, v) => MapEntry(k, v as int)) ?? {},
healthAlertSummary: (m['healthAlertSummary'] as Map<String, dynamic>?)
    ?.map((k, v) => MapEntry(k, v as int)) ?? {},
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/mobile_app && flutter test test/features/ranch/ranch_models_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: 运行现有测试确保无回归**

```bash
cd Mobile/mobile_app && flutter test
```

Expected: All existing tests still pass.

- [ ] **Step 6: 提交**

```bash
git add lib/features/ranch/domain/ranch_models.dart test/features/ranch/ranch_models_test.dart
git commit -m "feat(ranch): extend models with read/distance/summary fields for alert UI"
```

---

## Task 2: 扩展 Repository 层

**Files:**
- Modify: `lib/features/ranch/domain/ranch_repository.dart`
- Modify: `lib/features/ranch/data/ranch_api_repository.dart`

- [ ] **Step 1: 在 ranch_repository.dart 添加抽象方法**

```dart
abstract class RanchRepository {
  Future<RanchOverview> loadOverview();
  Future<void> markRead(String alertId);
  Future<void> dismiss(String alertId);
  Future<void> batchRead(List<String> alertIds);
}
```

- [ ] **Step 2: 在 ranch_api_repository.dart 实现**

```dart
class RanchApiRepository implements RanchRepository {
  const RanchApiRepository();

  @override
  Future<RanchOverview> loadOverview() async {
    final data = await ApiClient.instance.farmGet('/ranch-overview');
    return RanchOverview.fromJson(data);
  }

  @override
  Future<void> markRead(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/read', null);
  }

  @override
  Future<void> dismiss(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/dismiss', null);
  }

  @override
  Future<void> batchRead(List<String> alertIds) async {
    await ApiClient.instance.farmPost('/alerts/batch-read', {
      'alertIds': alertIds,
    });
  }
}
```

- [ ] **Step 3: 编译验证**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/
```

Expected: No errors.

- [ ] **Step 4: 提交**

```bash
git add lib/features/ranch/domain/ranch_repository.dart lib/features/ranch/data/ranch_api_repository.dart
git commit -m "feat(ranch): add markRead/dismiss/batchRead to repository layer"
```

---

## Task 3: 扩展 Controller（钻取状态）

**Files:**
- Modify: `lib/features/ranch/presentation/ranch_controller.dart`

Controller 需要管理钻取状态（当前查看的告警类别）和 markRead/dismiss 操作。

- [ ] **Step 1: 在 RanchController 中添加钻取状态和操作方法**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/data/ranch_api_repository.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_repository.dart';

/// 钻取层级
enum RanchDrillLevel { dashboard, list, detail }

class RanchController extends FarmScopedAsyncNotifier<RanchOverview> {
  RanchDrillLevel _drillLevel = RanchDrillLevel.dashboard;
  String? _selectedCategory; // e.g. 'FENCE_BREACH', 'TEMPERATURE_ABNORMAL'
  String? _selectedAlertId;

  RanchDrillLevel get drillLevel => _drillLevel;
  String? get selectedCategory => _selectedCategory;
  String? get selectedAlertId => _selectedAlertId;

  @override
  Future<RanchOverview> build() async {
    watchActiveFarmId();
    return ref.read(ranchRepositoryProvider).loadOverview();
  }

  // ── Drill-down navigation ──

  void showDashboard() {
    state = AsyncData(state.value!); // trigger rebuild
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
  }

  void showCategoryList(String category) {
    _drillLevel = RanchDrillLevel.list;
    _selectedCategory = category;
    _selectedAlertId = null;
    state = AsyncData(state.value!);
  }

  void showAlertDetail(String alertId) {
    _drillLevel = RanchDrillLevel.detail;
    _selectedAlertId = alertId;
    state = AsyncData(state.value!);
    // Mark as read (fire-and-forget)
    markRead(alertId);
  }

  // ── Alert actions ──

  Future<void> markRead(String alertId) async {
    try {
      await ref.read(ranchRepositoryProvider).markRead(alertId);
      // Optimistically update local state
      final overview = state.value;
      if (overview != null) {
        final updatedAlerts = overview.alerts.map((a) {
          if (a.id == alertId) return a.copyWith(read: true);
          return a;
        }).toList();
        state = AsyncData(RanchOverview(
          overallStats: overview.overallStats,
          sceneSummary: overview.sceneSummary,
          pendingTasks: overview.pendingTasks,
          fences: overview.fences,
          livestockMarkers: overview.livestockMarkers,
          alerts: updatedAlerts,
          fenceAlertSummary: overview.fenceAlertSummary,
          healthAlertSummary: overview.healthAlertSummary,
        ));
      }
    } catch (_) {
      // Silently fail — read status is non-critical
    }
  }

  Future<void> dismiss(String alertId) async {
    await ref.read(ranchRepositoryProvider).dismiss(alertId);
    refresh();
  }

  Future<void> batchRead(List<String> alertIds) async {
    await ref.read(ranchRepositoryProvider).batchRead(alertIds);
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ranchRepositoryProvider).loadOverview(),
    );
    // Reset to dashboard on refresh
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
  }
}

final ranchControllerProvider =
    AsyncNotifierProvider<RanchController, RanchOverview>(
  RanchController.new,
);
```

注意：`RanchAlertData` 的 `const` 构造函数需改为普通构造函数（如果还没有），或在 `ranch_models.dart` 中添加 `copyWith` 方法。选择添加 `copyWith`：

在 `RanchAlertData` 中添加：

```dart
RanchAlertData copyWith({bool? read, double? distance, String? direction, String? resolvedType}) {
  return RanchAlertData(
    id: id, type: type, severity: severity, status: status,
    message: message, livestockId: livestockId, fenceId: fenceId,
    occurredAt: occurredAt,
    read: read ?? this.read, distance: distance ?? this.distance,
    direction: direction ?? this.direction, resolvedType: resolvedType ?? this.resolvedType,
  );
}
```

- [ ] **Step 2: 编译验证**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/ranch_controller.dart
```

- [ ] **Step 3: 提交**

```bash
git add lib/features/ranch/presentation/ranch_controller.dart lib/features/ranch/domain/ranch_models.dart
git commit -m "feat(ranch): add drill-down state and markRead/dismiss to controller"
```

---

## Task 4: 新建 StatusDashboardCard + AlertCard 组件

**Files:**
- Create: `lib/features/ranch/presentation/widgets/status_dashboard_card.dart`
- Create: `lib/features/ranch/presentation/widgets/alert_card.dart`
- Test: `test/features/ranch/status_dashboard_card_test.dart`
- Test: `test/features/ranch/alert_card_test.dart`

- [ ] **Step 1: 实现 StatusDashboardCard**

`status_dashboard_card.dart` — 告警分类卡片，显示图标 + 标签 + 数量，数量为 0 则返回 SizedBox.shrink()：

```dart
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

class StatusDashboardCard extends StatelessWidget {
  const StatusDashboardCard({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: InkWell(
          key: Key('dashboard-card-$label'),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text('$count',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 实现 AlertCard**

`alert_card.dart` — 告警列表项，未读（加粗+实心点）vs 已读（淡化+空心圈）：

```dart
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  final RanchAlertData alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !alert.read;
    final typeColor = _typeColor(alert.type);
    final severityColor = _severityColor(alert.severity);

    return Card(
      key: Key('alert-card-${alert.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: BorderSide(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Opacity(
            opacity: isUnread ? 1.0 : 0.7,
            child: Row(
              children: [
                // Read/unread dot
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isUnread ? severityColor : null,
                    border: isUnread ? null : Border.all(color: AppColors.textSecondary),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Type tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_typeLabel(alert.type),
                    style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Message
                Expanded(
                  child: Text(alert.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                ),
                // Distance (for fence alerts)
                if (alert.distance != null)
                  Text('${alert.distance!.toStringAsFixed(0)}m',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
    'FENCE_BREACH' => AppColors.danger,
    'FENCE_APPROACH' => AppColors.warning,
    'ZONE_APPROACH' => const Color(0xFF1565C0),
    'TEMPERATURE_ABNORMAL' => const Color(0xFF7B1FA2),
    'DIGESTIVE_ABNORMAL' => const Color(0xFFF57F17),
    'ESTRUS' => const Color(0xFFC2185B),
    'EPIDEMIC' => const Color(0xFF00695C),
    _ => AppColors.textSecondary,
  };

  String _typeLabel(String type) => switch (type) {
    'FENCE_BREACH' => '越界',
    'FENCE_APPROACH' => '接近',
    'ZONE_APPROACH' => '重点区',
    'TEMPERATURE_ABNORMAL' => '发热',
    'DIGESTIVE_ABNORMAL' => '消化',
    'ESTRUS' => '发情',
    'EPIDEMIC' => '疫病',
    _ => type,
  };

  Color _severityColor(String severity) => switch (severity) {
    'CRITICAL' => AppColors.danger,
    'HIGH' => AppColors.danger,
    'WARNING' => AppColors.warning,
    'MEDIUM' => AppColors.warning,
    _ => AppColors.info,
  };
}
```

- [ ] **Step 3: 写 StatusDashboardCard 测试**

```dart
// test/features/ranch/status_dashboard_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/status_dashboard_card.dart';

void main() {
  testWidgets('shows card when count > 0', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Row(children: [
        StatusDashboardCard(icon: Icons.fence, label: '越界', count: 3,
          color: AppColors.danger, onTap: () {}),
      ]),
    ));
    expect(find.byType(StatusDashboardCard), findsOneWidget);
    expect(find.text('越界'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('hides card when count is 0', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Row(children: [
        StatusDashboardCard(icon: Icons.fence, label: '越界', count: 0,
          color: AppColors.danger, onTap: () {}),
      ]),
    ));
    // SizedBox.shrink — no text '越界'
    expect(find.text('越界'), findsNothing);
  });
}
```

- [ ] **Step 4: 运行测试**

```bash
cd Mobile/mobile_app && flutter test test/features/ranch/status_dashboard_card_test.dart
```

Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/ranch/presentation/widgets/status_dashboard_card.dart lib/features/ranch/presentation/widgets/alert_card.dart test/features/ranch/status_dashboard_card_test.dart
git commit -m "feat(ranch): add StatusDashboardCard and AlertCard widgets"
```

---

## Task 5: 新建 DeviceInfoLine + AutoResolvedSection 组件

**Files:**
- Create: `lib/features/ranch/presentation/widgets/device_info_line.dart`
- Create: `lib/features/ranch/presentation/widgets/auto_resolved_section.dart`

- [ ] **Step 1: 实现 DeviceInfoLine**

低调的设备信息行——灰色小字 + 分隔线，故障时升级为警示色：

```dart
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

class DeviceInfoLine extends StatelessWidget {
  const DeviceInfoLine({
    super.key,
    required this.icon,
    required this.deviceName,
    required this.batteryPercent,
    required this.signalStrength, // 1-4
    this.fault,
  });

  final IconData icon;
  final String deviceName;
  final int batteryPercent;
  final int signalStrength;
  final String? fault; // null = normal

  @override
  Widget build(BuildContext context) {
    final hasFault = fault != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 4),
        Text(
          '$deviceName  电量${batteryPercent}% · ${_signalLabel()} · ${hasFault ? fault! : '✓正常'}',
          style: TextStyle(
            fontSize: 11,
            color: hasFault ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _signalLabel() {
    if (signalStrength >= 4) return '信号强';
    if (signalStrength >= 3) return '信号中';
    return '信号弱';
  }
}
```

- [ ] **Step 2: 实现 AutoResolvedSection**

已自动解除折叠区：

```dart
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

class AutoResolvedSection extends StatefulWidget {
  const AutoResolvedSection({
    super.key,
    required this.count,
    required this.children,
  });

  final int count;
  final List<Widget> children;

  @override
  State<AutoResolvedSection> createState() => _AutoResolvedSectionState();
}

class _AutoResolvedSectionState extends State<AutoResolvedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        children: [
          InkWell(
            key: const Key('auto-resolved-toggle'),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text('✓ 已自动解除（${widget.count}）',
                    style: TextStyle(fontSize: 12, color: AppColors.success)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('无需处理', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Column(children: widget.children),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 编译验证 + 提交**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/widgets/device_info_line.dart lib/features/ranch/presentation/widgets/auto_resolved_section.dart
git add lib/features/ranch/presentation/widgets/device_info_line.dart lib/features/ranch/presentation/widgets/auto_resolved_section.dart
git commit -m "feat(ranch): add DeviceInfoLine and AutoResolvedSection widgets"
```

---

## Task 6: 重写 HealthBottomSheet（钻取式架构）

**Files:**
- Rewrite: `lib/features/ranch/presentation/widgets/health_bottom_sheet.dart`（779 行 → 钻取式）
- Test: `test/features/ranch/health_bottom_sheet_test.dart`

这是最大的任务。将 `HealthBottomSheet` 从单列表重构为钻取式：peek 条 → 仪表盘 → 列表 → 详情。

**架构**：同一个 Widget 内部根据 `RanchController.drillLevel` 切换渲染内容。三个 `_buildXxx` 方法对应三个层级。

- [ ] **Step 1: 重写 health_bottom_sheet.dart**

核心结构（关键代码片段，非完整文件）：

```dart
class HealthBottomSheet extends ConsumerStatefulWidget {
  const HealthBottomSheet({super.key, required this.overview});
  final RanchOverview overview;
  @override
  ConsumerState<HealthBottomSheet> createState() => _HealthBottomSheetState();
}

class _HealthBottomSheetState extends ConsumerState<HealthBottomSheet> {
  _SnapLevel _snap = _SnapLevel.peek;
  // ... snap logic unchanged ...

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(ranchControllerProvider.notifier);
    final drillLevel = controller.drillLevel;
    final stats = widget.overview.overallStats;

    return ClipRect(
      child: AnimatedContainer(/* snap height logic unchanged */),
    );
  }

  Widget _buildPeekBar(BuildContext context, RanchOverviewStats stats) {
    // NEW: 头数 · 归栏率 · 健康率
    return Container(
      height: _peekHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 40, height: 4, /* drag handle */),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${stats.totalLivestock}头', /* ... */),
          const SizedBox(width: AppSpacing.md),
          Text('归栏率 ${(stats.inFenceRate * 100).toStringAsFixed(0)}%', /* ... */),
          const SizedBox(width: AppSpacing.md),
          Text('健康率 ${(stats.healthyRate * 100).toStringAsFixed(0)}%', /* ... */),
        ]),
      ]),
    );
  }

  Widget _buildDashboard(BuildContext context, RanchOverview overview) {
    final fenceSummary = overview.fenceAlertSummary;
    final healthSummary = overview.healthAlertSummary;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg), children: [
      Text('🚧 围栏情况', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        StatusDashboardCard(icon: Icons.fence, label: '越界',
          count: fenceSummary['FENCE_BREACH'] ?? 0, color: AppColors.danger,
          onTap: () => _showCategory('FENCE_BREACH')),
        StatusDashboardCard(icon: Icons.warning_amber, label: '接近',
          count: fenceSummary['FENCE_APPROACH'] ?? 0, color: AppColors.warning,
          onTap: () => _showCategory('FENCE_APPROACH')),
        StatusDashboardCard(icon: Icons.location_on, label: '重点区',
          count: fenceSummary['ZONE_APPROACH'] ?? 0, color: const Color(0xFF1565C0),
          onTap: () => _showCategory('ZONE_APPROACH')),
      ]),
      const SizedBox(height: AppSpacing.lg),
      Text('❤️ 健康情况', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        StatusDashboardCard(icon: Icons.thermostat, label: '发热',
          count: healthSummary['TEMPERATURE_ABNORMAL'] ?? 0, color: const Color(0xFF7B1FA2),
          onTap: () => _showCategory('TEMPERATURE_ABNORMAL')),
        StatusDashboardCard(icon: Icons.grain, label: '消化',
          count: healthSummary['DIGESTIVE_ABNORMAL'] ?? 0, color: const Color(0xFFF57F17),
          onTap: () => _showCategory('DIGESTIVE_ABNORMAL')),
        StatusDashboardCard(icon: Icons.favorite, label: '发情',
          count: healthSummary['ESTRUS'] ?? 0, color: const Color(0xFFC2185B),
          onTap: () => _showCategory('ESTRUS')),
      ]),
    ]);
  }

  Widget _buildAlertList(BuildContext context, RanchOverview overview, String category) {
    final controller = ref.read(ranchControllerProvider.notifier);
    final activeAlerts = overview.alerts
        .where((a) => a.type == category && a.status == 'ACTIVE')
        .toList();
    final autoResolved = overview.alerts
        .where((a) => a.type == category && a.status == 'AUTO_RESOLVED')
        .toList();
    // Sort: unread first, then by severity
    activeAlerts.sort((a, b) {
      if (a.read != b.read) return a.read ? 1 : -1;
      return _severityOrder(a.severity).compareTo(_severityOrder(b.severity));
    });

    return Column(children: [
      // Header with back button + "全部已读"
      Row(children: [
        TextButton.icon(onPressed: () => controller.showDashboard(),
          icon: const Icon(Icons.arrow_back, size: 16), label: Text(categoryLabel)),
        const Spacer(),
        TextButton(onPressed: () => controller.batchRead(activeAlerts.map((a) => a.id).toList()),
          child: const Text('全部已读')),
      ]),
      Expanded(child: ListView(children: [
        for (final alert in activeAlerts)
          AlertCard(alert: alert, onTap: () => _showDetail(alert)),
        AutoResolvedSection(
          count: autoResolved.length,
          children: [for (final a in autoResolved) AlertCard(alert: a, onTap: () {})],
        ),
      ])),
    ]);
  }

  void _showCategory(String category) {
    ref.read(ranchControllerProvider.notifier).showCategoryList(category);
  }

  void _showDetail(RanchAlertData alert) {
    ref.read(ranchControllerProvider.notifier).showAlertDetail(alert.id);
  }

  int _severityOrder(String s) => switch (s) {
    'CRITICAL' => 0, 'HIGH' => 0, 'WARNING' => 1, 'MEDIUM' => 1, _ => 2,
  };
}
```

详情态（第④层）根据告警类型弹出不同的 BottomSheet：
- 围栏告警 → `FenceAlertDetailSheet`（Task 7）
- 健康告警 → 复用现有健康详情页或弹出简化版

- [ ] **Step 2: 编译验证**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/widgets/health_bottom_sheet.dart
```

- [ ] **Step 3: 手动验证 peek 条新指标**

运行 app，owner 登录后打开牧场 Tab，确认 peek 条显示 `256头 · 归栏率 98% · 健康率 94%`。

- [ ] **Step 4: 提交**

```bash
git add lib/features/ranch/presentation/widgets/health_bottom_sheet.dart
git commit -m "feat(ranch): restructure bottom sheet to drill-down alert architecture"
```

---

## Task 7: 新建 FenceAlertDetailSheet（空间型详情）

**Files:**
- Create: `lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart`

围栏告警详情——地图为中心，显示空间关系、设备信息、能力边界。

- [ ] **Step 1: 实现 FenceAlertDetailSheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';

class FenceAlertDetailSheet extends StatelessWidget {
  const FenceAlertDetailSheet({
    super.key,
    required this.alert,
    required this.fence,
    this.onLocateOnMap,
    this.onDismiss,
  });

  final RanchAlertData alert;
  final RanchFenceData? fence;
  final VoidCallback? onLocateOnMap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isBreach = alert.type == 'FENCE_BREACH';
    final headerColor = isBreach ? AppColors.danger : AppColors.warning;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, /* ... */)),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(children: [
            Container(padding: /* type tag */, child: Text(typeLabel)),
            const SizedBox(width: AppSpacing.sm),
            Text(alert.message, style: Theme.of(context).textTheme.titleMedium),
          ]),

          // Mini map (placeholder — full implementation uses FlutterMap with fence + buffer)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: const Center(child: Text('🗺️ 小地图（牲畜位置 + 围栏 + 缓冲带）')),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Spatial info
          _InfoRow('围栏', fence?.name ?? '-'),
          if (alert.distance != null)
            _InfoRow('位置', '围栏${isBreach ? '外' : '附近'} ${alert.distance!.toStringAsFixed(0)}m'),
          if (alert.direction != null)
            _InfoRow('方向', alert.direction!),
          _InfoRow('发生', alert.occurredAt ?? '-'),

          // Device info (de-emphasized)
          DeviceInfoLine(
            icon: Icons.gps_fixed,
            deviceName: '📡 追踪器',
            batteryPercent: 85, // TODO: from real device data
            signalStrength: 4,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Capability boundary
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text('💡 系统能通知你牛已${isBreach ? '越界' : '接近围栏'}，需线下处理。',
              style: TextStyle(fontSize: 11, color: AppColors.warning)),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Actions
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: onLocateOnMap,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('大地图定位'),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(
              onPressed: onDismiss,
              child: const Text('忽略此告警'),
            )),
          ]),
        ]),
      ),
    );
  }

  String get typeLabel => switch (alert.type) {
    'FENCE_BREACH' => '越界',
    'FENCE_APPROACH' => '接近',
    'ZONE_APPROACH' => '重点区',
    _ => alert.type,
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 48, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ]),
    );
  }
}
```

- [ ] **Step 2: 编译验证 + 提交**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart
git add lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart
git commit -m "feat(ranch): add FenceAlertDetailSheet (spatial detail view)"
```

---

## Task 8: 优化健康告警详情页

**Files:**
- Modify: `lib/features/pages/fever_detail_page.dart`
- Modify: `lib/features/pages/digestive_detail_page.dart`
- Modify: `lib/features/pages/estrus_detail_page.dart`

为每个健康详情页添加：(1) 标已读调用 (2) 设备信息辅助行 (3) 能力边界说明 (4) 忽略按钮。

以 `fever_detail_page.dart` 为例，其他两个页面类似。

- [ ] **Step 1: 在 fever_detail_page.dart 中添加设备行和能力边界**

在 `_buildChart` 之后、结尾之前，添加：

```dart
// Device info line (de-emphasized)
const DeviceInfoLine(
  icon: Icons.medication,
  deviceName: '💊 瘤胃胶囊',
  batteryPercent: 72, // TODO: from real device data
  signalStrength: 3,
),
const SizedBox(height: 12),

// Capability boundary
Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.orange.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(8),
  ),
  child: const Text('💡 系统能通知你体温异常，需线下排查（炎症/感染/环境）。',
    style: TextStyle(fontSize: 11, color: Colors.orange)),
),
```

在 AppBar actions 中添加忽略按钮（owner 角色）。

- [ ] **Step 2: 对 digestive_detail_page.dart 和 estrus_detail_page.dart 做同样修改**

- [ ] **Step 3: 编译验证 + 提交**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/pages/fever_detail_page.dart lib/features/pages/digestive_detail_page.dart lib/features/pages/estrus_detail_page.dart
git add lib/features/pages/fever_detail_page.dart lib/features/pages/digestive_detail_page.dart lib/features/pages/estrus_detail_page.dart
git commit -m "feat(health): add device info line + capability boundary to health detail pages"
```

---

## Task 9: 缓冲带地图图层

**Files:**
- Create: `lib/features/ranch/presentation/widgets/fence_buffer_layer.dart`
- Modify: `lib/features/pages/ranch_page.dart`

在地图上渲染围栏外侧缓冲带环（橙色虚线）和牲畜标注按区域变色。

- [ ] **Step 1: 实现 FenceBufferLayer widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

/// Renders fence buffer zones as semi-transparent orange polygons.
class FenceBufferLayer extends StatelessWidget {
  const FenceBufferLayer({
    super.key,
    required this.fences,
    required this.bufferDistance, // meters
  });

  final List<FenceBufferData> fences;
  final double bufferDistance;

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: [
        for (final fence in fences)
          Polygon(
            points: fence.bufferPoints,
            color: Colors.orange.withValues(alpha: 0.12),
            borderColor: Colors.orange.withValues(alpha: 0.5),
            borderStrokeWidth: 2,
            pattern: const StrokePattern.dashed(segments: [8, 6]),
          ),
      ],
    );
  }
}

/// Simplified data for buffer zone rendering.
class FenceBufferData {
  const FenceBufferData({required this.id, required this.bufferPoints});
  final String id;
  final List<LatLng> bufferPoints;
}
```

> **注**：`bufferPoints` 的预计算（从围栏顶点外扩 N 米）是一个几何算法。当前 MVP 阶段可使用简单的纬度/经度偏移近似（每 1° ≈ 111km，所以 50m ≈ 0.00045°），后续接入后端 `buffer_polygon` 字段后替换为精确数据。

- [ ] **Step 2: 在 ranch_page.dart 中集成缓冲带图层 + 牲畜标注变色**

在 `FlutterMap` 的 children 中，在围栏 PolygonLayer 之后添加：

```dart
FenceBufferLayer(fences: bufferData, bufferDistance: 50),
```

修改牲畜 Marker 的颜色逻辑——根据牲畜是否在围栏内/缓冲带/围栏外来决定标注颜色（绿/橙/红）。

当前 `HealthMarker` 根据 `healthStatus` 着色。改为结合位置状态着色：
- 如果在围栏外 → 红色（越界），覆盖健康状态颜色
- 如果在缓冲带 → 橙色（接近），覆盖健康状态颜色
- 否则 → 使用健康状态颜色

- [ ] **Step 3: 编译验证 + 手动验证**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/pages/ranch_page.dart
flutter run -d chrome --dart-define=APP_MODE=live
```

确认地图上围栏外圈有橙色半透明缓冲带，牛标注按区域变色。

- [ ] **Step 4: 提交**

```bash
git add lib/features/ranch/presentation/widgets/fence_buffer_layer.dart lib/features/pages/ranch_page.dart
git commit -m "feat(ranch): add fence buffer zone layer and zone-based marker coloring"
```

---

## Task 10: 更新 LivestockDetailSheet（新状态标签）

**Files:**
- Modify: `lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart`

将旧状态标签（待处理/已确认/已处理/已归档）替换为通知中心模型标签。

- [ ] **Step 1: 更新 `_statusLabel` 和 `_statusColor` 方法**

```dart
String _statusLabel(String status) => switch (status) {
  'ACTIVE' => '活跃',
  'DISMISSED' => '已忽略',
  'AUTO_RESOLVED' => '已自动解除',
  // Legacy compatibility
  'PENDING' => '活跃',
  'ACKNOWLEDGED' => '活跃',
  'HANDLED' => '已忽略',
  'ARCHIVED' => '已自动解除',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'ACTIVE' => AppColors.warning,
  'DISMISSED' => AppColors.textSecondary,
  'AUTO_RESOLVED' => AppColors.success,
  // Legacy
  'PENDING' => AppColors.warning,
  'ACKNOWLEDGED' => AppColors.info,
  'HANDLED' => AppColors.success,
  'ARCHIVED' => AppColors.textSecondary,
  _ => AppColors.textSecondary,
};
```

- [ ] **Step 2: 编译验证 + 提交**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart
git add lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart
git commit -m "fix(ranch): update status labels to notification-center model"
```

---

## Task 11: 全局回归测试 + 静态分析

- [ ] **Step 1: 运行全量测试**

```bash
cd Mobile/mobile_app && flutter test
```

Expected: All tests pass.

- [ ] **Step 2: 运行静态分析**

```bash
cd Mobile/mobile_app && flutter analyze
```

Expected: No issues.

- [ ] **Step 3: 运行 app 做端到端验证**

```bash
cd Mobile/mobile_app && flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

验证验收标准（来自 spec 第 14 节）：
1. peek 条显示 `头数 · 归栏率 · 健康率`
2. 展开后看到围栏/健康两组卡片，0 的隐藏
3. 点击卡片进入告警列表，未读/已读区分
4. 点击告警进入详情（围栏=地图型 / 健康=图表型）
5. 缓冲带环 + 重点区域圈 + 变色标注
6. 设备信息低调
7. 自动解除折叠区

- [ ] **Step 4: 最终提交**

```bash
git add -A && git commit -m "chore(ranch): regression test pass for alert UI redesign"
```

---

## 后端计划（独立）

后端 Flyway V19 迁移 + AlertStatus 枚举变更 + 新 API 端点 + 自动解除逻辑需要单独的实施计划，涉及：
- `smart-livestock-server/` Spring Boot 代码
- Flyway V19 SQL（alert_read_status、fence_zones、fences 扩展、数据迁移）
- AlertStatus 枚举 `{ACTIVE, DISMISSED, AUTO_RESOLVED}`
- AlertApplicationService（markRead、dismiss、autoResolve）
- GpsLogApplicationService（缓冲带检测 + 自动解除触发）
- DashboardApplicationService（inFenceRate 计算）
- 5 个新 API 端点

> 前端 Mock 数据阶段，后端 API 未就绪时，`RanchApiRepository` 会收到解析错误。此时可临时 fallback 到旧格式或提供 Mock JSON。建议后端先完成 V19 迁移再联调。
