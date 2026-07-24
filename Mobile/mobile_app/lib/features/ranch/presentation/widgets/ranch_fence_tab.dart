import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Fence list tab content for the ranch bottom sheet.
/// Shows fence items with edit/delete, and an expandable detail card.
class RanchFenceTab extends ConsumerStatefulWidget {
  const RanchFenceTab({
    super.key,
    required this.fences,
    required this.alerts,
    required this.selectedFenceId,
    required this.onFenceSelected,
    this.canManage = false,
  });

  final List<RanchFenceData> fences;
  final List<RanchAlertData> alerts;
  final String? selectedFenceId;
  final void Function(String fenceId) onFenceSelected;
  final bool canManage;

  @override
  ConsumerState<RanchFenceTab> createState() => _RanchFenceTabState();
}

class _RanchFenceTabState extends ConsumerState<RanchFenceTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedId = widget.selectedFenceId;
    final selectedFence = selectedId == null
        ? null
        : widget.fences.where((f) => f.id == selectedId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Text(
                selectedFence != null
                    ? selectedFence.name
                    : '${l10n.alertFenceListTitle} (${widget.fences.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (selectedFence != null)
                GestureDetector(
                  onTap: () => widget.onFenceSelected(''),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      l10n.commonCollapse,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else if (widget.canManage)
                GestureDetector(
                  onTap: () => context
                      .push(AppRoute.fenceForm.path)
                      .then((_) => ref
                          .read(ranchControllerProvider.notifier)
                          .refresh()),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          l10n.alertFenceAddBtn,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Fence detail card (if selected)
        if (selectedFence != null) ...[
          _FenceDetailCard(
            fence: selectedFence,
            alerts: widget.alerts,
            canManage: widget.canManage,
            onDelete: () => _deleteFence(selectedFence),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Fence items
        for (final fence in widget.fences)
          _FenceListItem(
            fence: fence,
            isSelected: fence.id == selectedId,
            isDimmed: selectedId != null && fence.id != selectedId,
            canManage: widget.canManage,
            onTap: () {
              if (selectedId == fence.id) {
                widget.onFenceSelected('');
              } else {
                widget.onFenceSelected(fence.id);
              }
            },
            onEdit: () => context.push(
              '${AppRoute.fenceForm.path}?fenceId=${fence.id}',
            ),
            onDelete: () => _deleteFence(fence),
          ),
      ],
    );
  }

  Future<void> _deleteFence(RanchFenceData fence) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonConfirmDelete),
        content: Text(l10n.alertFenceDeleteConfirm(fence.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.alertFenceDeleteBtn,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiClient.instance.farmDelete('/fences/${fence.id}');
        if (!mounted) return;
        widget.onFenceSelected('');
        ref.read(ranchControllerProvider.notifier).refresh();
      } catch (_) {}
    }
  }
}

// ── Fence list item ──

class _FenceListItem extends StatelessWidget {
  const _FenceListItem({
    required this.fence,
    required this.isSelected,
    required this.isDimmed,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RanchFenceData fence;
  final bool isSelected;
  final bool isDimmed;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Opacity(
      opacity: isDimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.info.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              // Color dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fence.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l10n.alertFenceLivestockCount(fence.livestockCount),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  constraints: const BoxConstraints(
                      minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 13, color: AppColors.danger),
                  constraints: const BoxConstraints(
                      minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fence detail card ──

class _FenceDetailCard extends StatelessWidget {
  const _FenceDetailCard({
    required this.fence,
    required this.alerts,
    required this.canManage,
    required this.onDelete,
  });

  final RanchFenceData fence;
  final List<RanchAlertData> alerts;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAlerts =
        alerts.where((a) => a.fenceId == fence.id && a.status == 'ACTIVE').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Color(fence.colorValue), width: 3),
        ),
      ),
      child: Column(
        children: [
          // Metadata grid 2x2
          Row(
            children: [
              Expanded(
                child: _DetailField(
                    label: l10n.alertFenceAreaLabel,
                    value: l10n.alertFenceArea(fence.areaHectares.toStringAsFixed(1))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailField(
                    label: l10n.alertFenceTypeLabel, value: _typeLabel(fence.type, l10n)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DetailField(
                    label: l10n.alertFenceLivestockLabel,
                    value: l10n.alertFenceLivestockCount(fence.livestockCount)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailField(
                  label: l10n.alertFenceAlertLabel,
                  value: l10n.alertFenceAlertCount(activeAlerts),
                  valueColor:
                      activeAlerts > 0 ? AppColors.danger : null,
                ),
              ),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _DetailBtn(
                    label: l10n.alertFenceEditBoundary,
                    icon: Icons.edit_location_alt,
                    bgColor: AppColors.info,
                    fgColor: Colors.white,
                    onTap: () => context.push(
                      '${AppRoute.fenceForm.path}?fenceId=${fence.id}',
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _DetailBtn(
                    label: l10n.ranchSectionFenceAlerts,
                    icon: Icons.warning_amber,
                    bgColor: AppColors.primarySoft,
                    fgColor: AppColors.primaryDark,
                    onTap: () => context.push(AppRoute.alerts.path),
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 14, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    return switch (type.toUpperCase()) {
      'POLYGON' => l10n.fenceTypePolygon,
      'RECTANGLE' || 'RECT' => l10n.fenceTypeRectangle,
      'CIRCLE' => l10n.fenceTypeCircle,
      _ => type,
    };
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailBtn extends StatelessWidget {
  const _DetailBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
