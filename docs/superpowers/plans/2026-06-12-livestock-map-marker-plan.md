# 地图牛只状态标记实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将地图牛只标记从 HealthMarker + AlertMarker 两套互斥 widget 合并为统一的 LivestockMapMarker，实现健康状态（填充色）和围栏状态（边框样式）两个独立视觉通道。

**Architecture:** 单一 `LivestockMapMarker` widget 替代现有的 `HealthMarker`（静态）+ `AlertMarker`（脉冲）。健康类型通过填充色编码（绿/红/橙/粉/蓝），围栏状态通过边框样式编码（无边框/虚线/实线粗边框），仅 BREACH 有脉冲动画。使用 `CustomPaint` + `CustomPainter` 实现虚线和发光效果。

**Tech Stack:** Flutter StatefulWidget + AnimationController + CustomPainter

**Spec:** `docs/superpowers/specs/2026-06-12-livestock-map-marker-design.md`

---

### Task 1: 新增 AppColors 颜色 token

**Files:**
- Modify: `Mobile/mobile_app/lib/core/theme/app_colors.dart`

- [ ] **Step 1: 添加 3 个颜色常量**

在 `AppColors` 类的 `info` 行之后添加：

```dart
  static const Color estrus = Color(0xFFC25689);
  static const Color fenceApproach = Color(0xFF454F45);
  static const Color fenceBreach = Color(0xFF1A1F1A);
```

完整的 `AppColors` 类应为：

```dart
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2F6B3B);
  static const Color primaryDark = Color(0xFF244F2D);
  static const Color primarySoft = Color(0xFFE3F0E4);
  static const Color accent = Color(0xFF8BA95A);

  static const Color surface = Color(0xFFF8F6F0);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD7D2C6);

  static const Color textPrimary = Color(0xFF263126);
  static const Color textSecondary = Color(0xFF617061);

  static const Color success = Color(0xFF4C9A5F);
  static const Color warning = Color(0xFFD28A2D);
  static const Color danger = Color(0xFFC2564B);
  static const Color info = Color(0xFF4A7F9D);
  static const Color estrus = Color(0xFFC25689);
  static const Color fenceApproach = Color(0xFF454F45);
  static const Color fenceBreach = Color(0xFF1A1F1A);

  static const Color overlayDark = Color(0xB3000000);
}
```

- [ ] **Step 2: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze lib/core/theme/app_colors.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd Mobile/mobile_app
git add lib/core/theme/app_colors.dart
git commit -m "feat(colors): add estrus, fenceApproach, fenceBreach color tokens"
```

---

### Task 2: 编写健康颜色映射测试（TDD）

**Files:**
- Create: `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart`

- [ ] **Step 1: 创建测试文件，编写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/livestock_map_marker.dart';

void main() {
  group('livestockHealthColor', () {
    test('NORMAL returns success green', () {
      expect(livestockHealthColor('NORMAL', ''), AppColors.success);
    });

    test('WARNING + FEVER returns danger red', () {
      expect(livestockHealthColor('WARNING', 'FEVER'), AppColors.danger);
    });

    test('CRITICAL + FEVER returns danger red', () {
      expect(livestockHealthColor('CRITICAL', 'FEVER'), AppColors.danger);
    });

    test('WARNING + DIGESTIVE returns warning orange', () {
      expect(livestockHealthColor('WARNING', 'DIGESTIVE'), AppColors.warning);
    });

    test('CRITICAL + DIGESTIVE returns warning orange', () {
      expect(livestockHealthColor('CRITICAL', 'DIGESTIVE'), AppColors.warning);
    });

    test('WARNING + ESTRUS returns estrus pink', () {
      expect(livestockHealthColor('WARNING', 'ESTRUS'), AppColors.estrus);
    });

    test('WARNING + EPIDEMIC returns info blue', () {
      expect(livestockHealthColor('WARNING', 'EPIDEMIC'), AppColors.info);
    });

    test('abnormal with unknown alert type returns danger', () {
      expect(livestockHealthColor('WARNING', 'SOMETHING_ELSE'), AppColors.danger);
    });

    test('abnormal with empty alert returns danger', () {
      expect(livestockHealthColor('CRITICAL', ''), AppColors.danger);
    });
  });

  group('LivestockMapMarker widget', () {
    testWidgets('renders livestock code label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivestockMapMarker(
              livestockCode: 'SL-2024-001',
              healthStatus: 'NORMAL',
              primaryAlert: '',
              fenceStatus: 'SAFE',
            ),
          ),
        ),
      );
      expect(find.text('001'), findsOneWidget);
    });

    testWidgets('handles empty code gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivestockMapMarker(
              livestockCode: '',
              healthStatus: 'NORMAL',
              primaryAlert: '',
              fenceStatus: 'SAFE',
            ),
          ),
        ),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

Run: `cd Mobile/mobile_app && flutter test test/features/ranch/livestock_map_marker_test.dart`
Expected: FAIL — `livestock_map_marker.dart` file not found

---

### Task 3: 创建 LivestockMapMarker widget

**Files:**
- Create: `Mobile/mobile_app/lib/features/ranch/presentation/widgets/livestock_map_marker.dart`

- [ ] **Step 1: 实现完整 widget**

```dart
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

/// Maps health status + primary alert type to fill color.
Color livestockHealthColor(String healthStatus, String primaryAlert) {
  if (healthStatus == 'NORMAL') return AppColors.success;
  return switch (primaryAlert) {
    'FEVER' => AppColors.danger,
    'DIGESTIVE' => AppColors.warning,
    'ESTRUS' => AppColors.estrus,
    'EPIDEMIC' => AppColors.info,
    _ => AppColors.danger,
  };
}

/// Unified map marker for livestock showing health status (fill color)
/// and fence status (border style) as two independent visual channels.
///
/// Fill color encodes health type:
///   NORMAL=green, FEVER=red, DIGESTIVE=orange, ESTRUS=pink, EPIDEMIC=blue
///
/// Border style encodes fence status:
///   SAFE=none, APPROACH=dashed dark gray, BREACH=solid black + pulse glow
class LivestockMapMarker extends StatefulWidget {
  const LivestockMapMarker({
    super.key,
    required this.livestockCode,
    required this.healthStatus,
    required this.primaryAlert,
    required this.fenceStatus,
    this.onTap,
  });

  final String livestockCode;
  final String healthStatus; // NORMAL / WARNING / CRITICAL
  final String primaryAlert; // FEVER / DIGESTIVE / ESTRUS / EPIDEMIC / '' / ...
  final String fenceStatus; // SAFE / APPROACH / BREACH
  final VoidCallback? onTap;

  @override
  State<LivestockMapMarker> createState() => _LivestockMapMarkerState();
}

class _LivestockMapMarkerState extends State<LivestockMapMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breachController;

  @override
  void initState() {
    super.initState();
    _breachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant LivestockMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fenceStatus != oldWidget.fenceStatus) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.fenceStatus == 'BREACH') {
      _breachController.repeat(reverse: true);
    } else {
      _breachController.stop();
      _breachController.value = 0;
    }
  }

  @override
  void dispose() {
    _breachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortLabel = widget.livestockCode.replaceAll('SL-2024-', '');
    final fillColor = livestockHealthColor(widget.healthStatus, widget.primaryAlert);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: AnimatedBuilder(
          animation: _breachController,
          builder: (context, child) {
            return CustomPaint(
              painter: _LivestockMarkerPainter(
                fillColor: fillColor,
                fenceStatus: widget.fenceStatus,
                breachProgress: widget.fenceStatus == 'BREACH'
                    ? _breachController.value
                    : 0.0,
              ),
              child: child,
            );
          },
          child: Center(
            child: Text(
              shortLabel.isNotEmpty ? shortLabel : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for the livestock marker.
///
/// Draws a filled circle (health color) and an optional fence border:
/// - APPROACH: dashed dark gray circle
/// - BREACH: solid thick black circle with pulsing glow
class _LivestockMarkerPainter extends CustomPainter {
  const _LivestockMarkerPainter({
    required this.fillColor,
    required this.fenceStatus,
    required this.breachProgress,
  });

  final Color fillColor;
  final String fenceStatus;
  final double breachProgress;

  static const double _baseRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // BREACH: outer glow that pulses
    if (fenceStatus == 'BREACH') {
      final glowAlpha = 0.15 + 0.2 * breachProgress;
      final glowPaint = Paint()
        ..color = AppColors.fenceBreach.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, _baseRadius + 3, glowPaint);
    }

    // Filled circle (health color)
    canvas.drawCircle(center, _baseRadius, Paint()..color = fillColor);

    // Shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, _baseRadius + 1, shadowPaint);

    // Fence border
    if (fenceStatus == 'APPROACH') {
      _drawDashedCircle(canvas, center, _baseRadius + 2);
    } else if (fenceStatus == 'BREACH') {
      final borderAlpha = 0.6 + 0.4 * breachProgress;
      final borderPaint = Paint()
        ..color = AppColors.fenceBreach.withValues(alpha: borderAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, _baseRadius + 1.5, borderPaint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius) {
    const dashCount = 16;
    final sweepAngle = 2 * pi / dashCount;
    const dashFraction = 0.4;
    final halfDash = sweepAngle * dashFraction;

    final paint = Paint()
      ..color = AppColors.fenceApproach
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * sweepAngle;
      canvas.drawArc(rect, startAngle, halfDash, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LivestockMarkerPainter old) {
    return fillColor != old.fillColor ||
        fenceStatus != old.fenceStatus ||
        breachProgress != old.breachProgress;
  }
}
```

- [ ] **Step 2: 运行测试，确认通过**

Run: `cd Mobile/mobile_app && flutter test test/features/ranch/livestock_map_marker_test.dart`
Expected: ALL PASS

- [ ] **Step 3: 运行静态分析**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/ranch/presentation/widgets/livestock_map_marker.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
cd Mobile/mobile_app
git add lib/features/ranch/presentation/widgets/livestock_map_marker.dart test/features/ranch/livestock_map_marker_test.dart
git commit -m "feat(marker): create LivestockMapMarker with health color + fence border channels"
```

---

### Task 4: 更新 ranch_page.dart，删除旧文件

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/ranch_page.dart`
- Delete: `Mobile/mobile_app/lib/features/ranch/presentation/widgets/health_marker.dart`
- Delete: `Mobile/mobile_app/lib/features/ranch/presentation/widgets/alert_marker.dart`

- [ ] **Step 1: 替换 import 语句**

在 `ranch_page.dart` 中，删除第 23-24 行：

```dart
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/health_marker.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/alert_marker.dart';
```

替换为一行：

```dart
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/livestock_map_marker.dart';
```

- [ ] **Step 2: 删除 alertLivestockIds 逻辑**

删除 `_buildMapWithSheet` 方法中的第 121-126 行：

```dart
    final alertLivestockIds = <String>{};
    for (final alert in overview.alerts) {
      if (alert.status != 'HANDLED' && alert.status != 'ARCHIVED' && alert.livestockId != null) {
        alertLivestockIds.add(alert.livestockId!);
      }
    }
```

- [ ] **Step 3: 简化 MarkerLayer**

将 MarkerLayer 的 markers 列表（原第 185-229 行）替换为：

```dart
            MarkerLayer(
              markers: [
                // Fence name labels
                for (final fence in overview.fences)
                  if (fence.points.isNotEmpty)
                    Marker(
                      point: _fenceCenter(shouldTransform
                          ? CoordTransform.wgs84ToGcj02All(fence.points)
                          : fence.points),
                      width: 120,
                      height: 28,
                      child: _FenceMapNameChip(
                        name: fence.name,
                        colorValue: fence.colorValue,
                        selected: fence.id == _selectedFenceId,
                      ),
                    ),
                // Livestock markers (unified)
                for (final m in overview.livestockMarkers)
                  Marker(
                    point: m.toLatLng(),
                    width: 32,
                    height: 32,
                    child: LivestockMapMarker(
                      key: Key('livestock-${m.livestockId}'),
                      livestockCode: m.livestockCode,
                      healthStatus: m.healthStatus,
                      primaryAlert: m.primaryAlert,
                      fenceStatus: m.fenceStatus,
                      onTap: () => _showLivestockDetail(context, m, overview),
                    ),
                  ),
              ],
            ),
```

- [ ] **Step 4: 删除 _alertSeverityForLivestock 方法**

删除整个方法（原第 404-413 行）：

```dart
  String _alertSeverityForLivestock(String livestockId, RanchOverview overview) {
    for (final alert in overview.alerts) {
      if (alert.livestockId == livestockId &&
          alert.status != 'HANDLED' &&
          alert.status != 'ARCHIVED') {
        return alert.severity;
      }
    }
   return 'LOW';
 }
```

- [ ] **Step 5: 删除旧 widget 文件**

```bash
cd Mobile/mobile_app
rm lib/features/ranch/presentation/widgets/health_marker.dart
rm lib/features/ranch/presentation/widgets/alert_marker.dart
```

- [ ] **Step 6: 运行静态分析验证**

Run: `cd Mobile/mobile_app && flutter analyze lib/features/pages/ranch_page.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
cd Mobile/mobile_app
git add -A
git commit -m "refactor(ranch): replace HealthMarker + AlertMarker with unified LivestockMapMarker"
```

---

### Task 5: 全量验证

**Files:** 无新增

- [ ] **Step 1: 运行全量静态分析**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No issues found

- [ ] **Step 2: 运行全量测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: ALL PASS

- [ ] **Step 3: 确认旧文件已删除**

Run: `find Mobile/mobile_app/lib -name "health_marker.dart" -o -name "alert_marker.dart"`
Expected: 无输出（文件不存在）

- [ ] **Step 4: 确认新文件存在**

Run: `ls -la Mobile/mobile_app/lib/features/ranch/presentation/widgets/livestock_map_marker.dart`
Expected: 文件存在
