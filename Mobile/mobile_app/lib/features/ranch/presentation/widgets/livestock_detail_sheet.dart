import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Enhanced livestock quick panel shown when tapping a map marker.
class LivestockDetailSheet extends StatelessWidget {
  const LivestockDetailSheet({
    super.key,
    required this.marker,
    this.relatedAlerts = const [],
  });

  final RanchLivestockMarker marker;
  final List<RanchAlertData> relatedAlerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAlerts =
        relatedAlerts.where((a) => a.status == 'ACTIVE').toList();
    final healthColor = _healthColor(marker.healthStatus);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 24,
            color: Color.fromRGBO(38, 49, 38, 0.15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + close
          _buildHandle(context),
          // Health row: dot + code + status + detail link
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: healthColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  marker.livestockCode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _healthLabel(marker.healthStatus, l10n),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: healthColor,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/livestock/${marker.livestockId}');
                  },
                  child: Text(
                    l10n.ranchLivestockDetailBtn,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Active alert banner
          if (activeAlerts.isNotEmpty)
            _buildAlertBanner(context, activeAlerts.first, l10n),
          // Stats grid 2x2
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.livestockSheetLastLoc,
                    value:
                        '${marker.latitude.toStringAsFixed(2)}°\n${marker.longitude.toStringAsFixed(2)}°',
                    valueSize: 10,
                    sub: l10n.livestockSheetCurrentPos,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatCard(
                    label: l10n.livestockSheetHealthStatus,
                    value: _healthLabel(marker.healthStatus, l10n),
                    valueColor: healthColor,
                    sub: marker.primaryAlert.isNotEmpty
                        ? _alertLabel(marker.primaryAlert, l10n)
                        : l10n.livestockSheetNormal,
                  ),
                ),
              ],
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    label: l10n.alertActionTrajectory,
                    icon: Icons.show_chart,
                    bgColor: AppColors.aiAnomaly.withValues(alpha: 0.1),
                    fgColor: AppColors.aiAnomaly,
                    onTap: () {
                      Navigator.of(context).pop();
                      showTrajectorySheet(
                        context,
                        marker.livestockId,
                        livestockCode: marker.livestockCode,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _QuickAction(
                    label: l10n.alertActionLocate,
                    icon: Icons.location_on,
                    bgColor: AppColors.info,
                    fgColor: Colors.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                if (activeAlerts.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Expanded(
                    child: _QuickAction(
                      label: l10n.ranchSectionFenceAlerts,
                      icon: Icons.notifications,
                      bgColor: AppColors.danger.withValues(alpha: 0.1),
                      fgColor: AppColors.danger,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoute.alerts.path);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Related alerts
          if (relatedAlerts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.livestockSheetRelatedAlerts} (${relatedAlerts.length})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                itemCount: relatedAlerts.length,
                itemBuilder: (context, index) {
                  final alert = relatedAlerts[index];
                  final sevColor = _alertColor(alert.severity);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(_alertIcon(alert.type),
                              size: 11, color: sevColor),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alert.message,
                            style:
                                const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            alert.severity == 'CRITICAL'
                                ? l10n.alertSeverityCritical
                                : l10n.alertSeverityWarning,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: sevColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 14,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner(
      BuildContext context, RanchAlertData alert, AppLocalizations l10n) {
    final sevColor = _alertColor(alert.severity);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.push(AppRoute.alerts.path);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: sevColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sevColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: sevColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(_alertIcon(alert.type), size: 14, color: sevColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: sevColor,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _healthColor(String status) {
    return switch (status) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      _ => AppColors.success,
    };
  }

  String _healthLabel(String status, AppLocalizations l10n) {
    return switch (status) {
      'CRITICAL' => l10n.ranchHealthStatusCritical,
      'WARNING' => l10n.ranchHealthStatusWarning,
      _ => l10n.ranchHealthStatusNormal,
    };
  }

  String _alertLabel(String alert, AppLocalizations l10n) {
    return switch (alert) {
      'FENCE_BREACH' => l10n.alertTypeFenceBreach,
      'FENCE_APPROACH' => l10n.alertTypeFenceApproach,
      'ZONE_APPROACH' => l10n.alertTypeZoneApproach,
      'TEMPERATURE_ABNORMAL' => l10n.alertTypeTemperatureAbnormal,
      'DIGESTIVE_ABNORMAL' => l10n.alertTypeDigestiveAbnormal,
      'ESTRUS' => l10n.alertTypeEstrus,
      'EPIDEMIC' => l10n.alertTypeEpidemic,
      'AI_ANOMALY' => l10n.alertTypeAiAnomaly,
      _ => alert,
    };
  }

  Color _alertColor(String severity) {
    return switch (severity) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      'INFO' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  IconData _alertIcon(String type) {
    return switch (type) {
      'FENCE_BREACH' || 'FENCE_APPROACH' || 'ZONE_APPROACH' => Icons.fence,
      'TEMPERATURE_ABNORMAL' => Icons.thermostat,
      'DIGESTIVE_ABNORMAL' => Icons.pets,
      'ESTRUS' => Icons.favorite,
      'EPIDEMIC' => Icons.shield,
      'AI_ANOMALY' => Icons.psychology,
      'DEVICE_TAMPER' => Icons.sensors,
      'DEVICE_LOW_BATTERY' => Icons.battery_alert,
      _ => Icons.warning,
    };
  }
}

// ── Helper widgets ──

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.valueSize = 13,
  });
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
