import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum AlertFilterTab { all, active, resolved }

/// Filter bar: segmented control (all/active/resolved) + horizontally
/// scrollable type chips.
class AlertFilterBar extends StatelessWidget {
  const AlertFilterBar({
    super.key,
    required this.activeTab,
    required this.unreadCount,
    required this.onTabChanged,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final AlertFilterTab activeTab;
  final int unreadCount;
  final void Function(AlertFilterTab) onTabChanged;

  /// Alert type codes present in the data, e.g. ['FENCE_BREACH', 'TEMPERATURE_ABNORMAL']
  final List<String> availableTypes;
  final String? selectedType; // null = "all types"
  final void Function(String?) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          _SegmentedTabs(
            activeTab: activeTab,
            unreadCount: unreadCount,
            onTabChanged: onTabChanged,
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 24,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TypeChip(
                  label: l10n.alertFilterAllTypes,
                  isSelected: selectedType == null,
                  dotColor: null,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 4),
                for (final type in availableTypes) ...[
                  _TypeChip(
                    label: _typeLabel(l10n, type),
                    isSelected: selectedType == type,
                    dotColor: _typeDotColor(type),
                    onTap: () => onTypeChanged(
                        selectedType == type ? null : type),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'FENCE_BREACH' => l10n.alertTypeFenceBreach,
      'FENCE_APPROACH' => l10n.alertTypeFenceApproach,
      'ZONE_APPROACH' => l10n.alertTypeZoneApproach,
      'TEMPERATURE_ABNORMAL' => l10n.alertTypeTemperatureAbnormal,
      'DIGESTIVE_ABNORMAL' => l10n.alertTypeDigestiveAbnormal,
      'ESTRUS' => l10n.alertTypeEstrus,
      'EPIDEMIC' => l10n.alertTypeEpidemic,
      'AI_ANOMALY' => l10n.alertTypeAiAnomaly,
      'DEVICE_TAMPER' => l10n.alertTypeDeviceTamper,
      'DEVICE_LOW_BATTERY' => l10n.alertTypeDeviceLowBattery,
      _ => type,
    };
  }

  Color _typeDotColor(String type) {
    return switch (type) {
      'FENCE_BREACH' => AppColors.danger,
      'FENCE_APPROACH' || 'TEMPERATURE_ABNORMAL' || 'DIGESTIVE_ABNORMAL' ||
      'EPIDEMIC' || 'DEVICE_LOW_BATTERY' || 'DEVICE_TAMPER' =>
        AppColors.warning,
      'ESTRUS' => AppColors.estrus,
      'AI_ANOMALY' => AppColors.aiAnomaly,
      'ZONE_APPROACH' => AppColors.info,
      _ => AppColors.textSecondary,
    };
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.activeTab,
    required this.unreadCount,
    required this.onTabChanged,
  });

  final AlertFilterTab activeTab;
  final int unreadCount;
  final void Function(AlertFilterTab) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              label: l10n.alertFilterAll,
              isActive: activeTab == AlertFilterTab.all,
              onTap: () => onTabChanged(AlertFilterTab.all),
            ),
          ),
          Expanded(
            child: _SegTab(
              label: l10n.alertFilterActive,
              badge: unreadCount > 0 ? unreadCount : null,
              isActive: activeTab == AlertFilterTab.active,
              onTap: () => onTabChanged(AlertFilterTab.active),
            ),
          ),
          Expanded(
            child: _SegTab(
              label: l10n.alertFilterResolved,
              isActive: activeTab == AlertFilterTab.resolved,
              onTap: () => onTabChanged(AlertFilterTab.resolved),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Color.fromRGBO(38, 49, 38, 0.06),
                  ),
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Color.fromRGBO(38, 49, 38, 0.04),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 12),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySoft
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
