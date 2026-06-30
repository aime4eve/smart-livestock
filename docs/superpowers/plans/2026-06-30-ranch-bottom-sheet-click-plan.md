# 牧场底部面板点击交互优化 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 HealthBottomSheet 的 peek bar 右侧加动态 chevron 图标，提示点击方向，改善 PC 鼠标操作体验。

**Architecture:** 仅修改 `health_bottom_sheet.dart` 单个文件。`_cycleSnap` 逻辑已满足需求（peek→half→full→peek），不需要改动。只需在 `_buildPeekBar` 的 Row children 末尾追加一个根据 `_snap` 状态变化的 `Icon`。

**Tech Stack:** Flutter / Dart

## Global Constraints

- 拖拽逻辑（`_onVerticalDragStart` / `_onVerticalDragEnd`）不变
- `_cycleSnap` 逻辑不变（已符合规格）
- i18n 无新增文案（图标无文字）
- `flutter analyze` 必须通过

---

### Task 1: peek bar 加动态 chevron 图标

**Files:**
- Modify: `Mobile/mobile_app/lib/features/ranch/presentation/widgets/health_bottom_sheet.dart:149-193`

**Interfaces:**
- Consumes: `_snap` (state field, `_SnapLevel` enum)
- Produces: 无新增公共接口

- [ ] **Step 1: 修改 `_buildPeekBar`，在 children 末尾追加 chevron 图标**

当前 `_buildPeekBar` 的 Row children（第 155-191 行）包含 3-4 个 Text/Container，末尾无图标。在 `]` 闭合前追加一个 `Icon`：

```dart
  // ── Peek bar: "头数 · 归栏率 · 健康率" ────────────────────────
  Widget _buildPeekBar(RanchOverviewStats stats) {
    final l10n = AppLocalizations.of(context)!;
    final inFencePct = (stats.inFenceRate * 100).toStringAsFixed(0);
    final healthPct = (stats.healthyRate * 100).toStringAsFixed(0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.ranchLivestockCountHead('${stats.totalLivestock}'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          l10n.ranchPeekInFence(inFencePct),
          style: TextStyle(
            fontSize: 13,
            color: stats.inFenceRate >= 0.9 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          l10n.ranchPeekHealth(healthPct),
          style: TextStyle(
            fontSize: 13,
            color: stats.healthyRate >= 0.9 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (stats.alertCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.ranchPeekAlertCount('${stats.alertCount}'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Icon(
          _snap == _SnapLevel.full
              ? Icons.keyboard_arrow_down
              : Icons.keyboard_arrow_up,
          size: 20,
          color: Colors.grey[600],
        ),
      ],
    );
  }
```

- [ ] **Step 2: 运行 `flutter analyze` 验证无编译/静态分析错误**

```bash
cd Mobile/mobile_app && flutter analyze
```

- [ ] **Step 3: 提交**

```bash
git add Mobile/mobile_app/lib/features/ranch/presentation/widgets/health_bottom_sheet.dart
git commit -m "feat(ranch): peek bar 加动态 chevron 图标，提示点击展开/收起方向"
```

---

## 验收核对

- [ ] peek 状态：手柄区右侧显示 `keyboard_arrow_up` 图标
- [ ] half 状态：手柄区右侧显示 `keyboard_arrow_up` 图标
- [ ] full 状态：手柄区右侧显示 `keyboard_arrow_down` 图标
- [ ] 图标颜色为灰色（`Colors.grey[600]`），尺寸 20px，与现有文字协调
- [ ] 手机端拖拽手势不受影响
- [ ] `flutter analyze` 通过
