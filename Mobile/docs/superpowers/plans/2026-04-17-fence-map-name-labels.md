# 围栏地图名称标注 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在围栏浏览态地图上为每个围栏显示其名称，使用户无需打开侧栏即可识别各区域。

**Architecture:** 数据层已有 `FenceItem.name`，无需改 API。在 `fence_page.dart` 的浏览态 `MarkerLayer` 中，于每个围栏多边形质心（与 `_fenceCenter` 一致）叠加文字标签；标签使用 `IgnorePointer` 包裹，避免拦截地图点击与现有 `detectFenceHits` 行为冲突。选中态可通过字重或边框与围栏色联动以强化可读性。

**Tech Stack:** Flutter, flutter_map, flutter_riverpod, latlong2

## 完成记录

| 完成日期 | 备注 |
|----------|------|
| 2026-04-17 | 2 个 Task 全部完成，commits: dde70b4 (test), d851279 (feat) |

---

## File Structure

### New Files

| File | Responsibility |
|------|----------------|
| `Mobile/mobile_app/test/features/fence/fence_map_name_labels_test.dart` | 验证地图上出现带 Key 的围栏名称文案 |

### Modified Files

| File | Change |
|------|--------|
| `Mobile/mobile_app/lib/features/pages/fence_page.dart` | 新增 `_buildFenceNameMarkers`、`私有 Widget _FenceMapNameChip`；在浏览态 `MarkerLayer` 中追加名称 markers（置于牲畜 markers 之后以便叠在上层）；质心计算跳过 `points.isEmpty` |

---

## Task 1: 围栏地图名称 — 失败测试

**Files:**
- Create: `Mobile/mobile_app/test/features/fence/fence_map_name_labels_test.dart`
- Modify: (none)

- [x] **Step 1: 编写失败测试**

创建 `Mobile/mobile_app/test/features/fence/fence_map_name_labels_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('浏览态地图展示各围栏名称标签', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('fence-map-name-fence_pasture_a')),
      findsOneWidget,
    );
    expect(find.text('放牧A区'), findsWidgets);

    expect(
      find.byKey(const Key('fence-map-name-fence_pasture_b')),
      findsOneWidget,
    );
    expect(find.text('放牧B区'), findsWidgets);
  });
}
```

- [x] **Step 2: 运行测试确认失败**

Run:

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock/Mobile/mobile_app && flutter test test/features/fence/fence_map_name_labels_test.dart
```

Expected: FAIL（`findsOneWidget` 找不到 `fence-map-name-fence_pasture_a` 或 `find.text` 失败）

- [x] **Step 3: Commit**

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock && git add Mobile/mobile_app/test/features/fence/fence_map_name_labels_test.dart && git commit -m "test: add fence map name label widget test"
```

---

## Task 2: 浏览态质心名称 Marker

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/fence_page.dart`（`MarkerLayer` 子节点附近约 262–277 行；文件末尾 `_MapMarker` 之前新增私有 Widget）

- [x] **Step 1: 实现名称 markers 与 Chip 样式**

在 `Mobile/mobile_app/lib/features/pages/fence_page.dart` 的 `_FencePageState` 内、`MarkerLayer` 的 `markers:` 列表中，在 `if (!isEditing) ..._buildLivestockMarkers(appMode)` 之后追加：

```dart
if (!isEditing) ..._buildFenceNameMarkers(fenceState),
```

在同一 class 中 `_buildLivestockMarkers` 方法之前或之后新增：

```dart
List<Marker> _buildFenceNameMarkers(FenceState fenceState) {
  return [
    for (final fence in fenceState.fences)
      if (fence.points.isNotEmpty)
        Marker(
          key: Key('fence-map-name-${fence.id}'),
          point: _fenceCenter(fence.points),
          width: 140,
          height: 40,
          alignment: Alignment.center,
          child: _FenceMapNameChip(
            name: fence.name,
            colorValue: fence.colorValue,
            selected: fence.id == fenceState.selectedFenceId,
          ),
        ),
  ];
}
```

在文件中 `_MapMarker` class 定义之前插入：

```dart
class _FenceMapNameChip extends StatelessWidget {
  const _FenceMapNameChip({
    required this.name,
    required this.colorValue,
    required this.selected,
  });

  final String name;
  final int colorValue;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = Color(colorValue);
    return IgnorePointer(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3),
            ],
          ),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}
```

说明：`IgnorePointer` 保证用户点击标签区域时仍由底层地图触发 `_handleMapTap`；`FittedBox` + `maxWidth` 避免长名称撑破布局。

- [x] **Step 2: 运行测试**

Run:

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock/Mobile/mobile_app && flutter test test/features/fence/fence_map_name_labels_test.dart
```

Expected: PASS

- [x] **Step 3: 静态分析**

Run:

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock/Mobile/mobile_app && flutter analyze
```

Expected: No issues（或仅项目既有 info，无新增 error）

- [x] **Step 4: 全量测试回归**

Run:

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock/Mobile/mobile_app && flutter test
```

Expected: All tests passed

- [x] **Step 5: Commit**

```bash
cd /Users/hkt/wzy/产品开发/smart-livestock && git add Mobile/mobile_app/lib/features/pages/fence_page.dart && git commit -m "feat(fence): show fence name labels on map in browse mode"
```

---

## Self-Review

**1. Spec coverage**

| 需求 | 对应 Task |
|------|-----------|
| 地图上可区分各围栏名称 | Task 2：质心 `Marker` + `fence.name` |
| 不破坏点选围栏 / 重叠候选 | `IgnorePointer` + markers 仅浏览态 |

**2. Placeholder scan**

无 TBD/TODO；步骤含完整 Dart 与命令。

**3. Type consistency**

`FenceState.selectedFenceId`、`FenceItem.id`、`Key('fence-map-name-${fence.id}')` 与测试中的 `fence_pasture_a`、`fence_pasture_b` 与 `DemoSeed` 围栏 id 一致。

---

## Execution Handoff

Plan complete and saved to `Mobile/docs/superpowers/plans/2026-04-17-fence-map-name-labels.md`. Two execution options:

**1. Subagent-Driven (recommended)** — Dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?

If Subagent-Driven chosen:

- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development

If Inline Execution chosen:

- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
