import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

/// NIX-324 subscription health banner — renders from the wall-clock
/// [SubscriptionHealth] block, never from the raw status column (spec §2).
/// Seven states collapse into four visual severities; CTA wiring follows the
/// state machine's allowed transitions (no changeTier on SUSPENDED etc.).
class SubscriptionHealthBanner extends StatelessWidget {
  const SubscriptionHealthBanner({
    super.key,
    required this.health,
    required this.onRenew,
    this.onExport,
    this.onSnooze,
  });

  final SubscriptionHealth health;
  final VoidCallback onRenew;
  final VoidCallback? onExport;

  /// NIX-334: present only while the prototype offers "稍后提醒" —
  /// EXPIRING_SOON at the 14/7-day levels (the 3-day state removes it).
  final VoidCallback? onSnooze;

  static bool showsSnooze(SubscriptionHealth health) =>
      health.healthStatus == 'EXPIRING_SOON' && (health.level ?? 14) > 3;

  @override
  Widget build(BuildContext context) {
    if (health.isHealthy) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final severity = _severityFor(health);
    final (title, body) = _copyFor(l10n, health);

    return Container(
      key: const Key('subscription-health-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severity.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severity.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: severity.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(fontSize: 12, height: 1.55)),
          if (_showsPrimaryCta(health.healthStatus)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  key: const Key('subscription-health-banner-cta'),
                  onPressed: onRenew,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_ctaLabel(l10n, health.healthStatus),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                if (onExport != null && health.hasExportWindow) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('subscription-health-banner-export'),
                    onPressed: onExport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.subscriptionHealthCtaExport,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
                if (onSnooze != null &&
                    showsSnooze(health)) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const Key('subscription-health-banner-snooze'),
                    onPressed: onSnooze,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.subscriptionHealthSnooze,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Spec §2 matrix colours: renewal_failed/suspended = warn orange;
  // trial and expiring_soon escalate through level (14 info → 7 warn →
  // 3 danger); cancelled/expired = danger red.
  static _Severity _severityFor(SubscriptionHealth h) {
    switch (h.healthStatus) {
      case 'TRIAL':
        // Matrix #1: info blue, ≤14/7/3 days reuse the level colours.
        return h.level != null ? _severityForLevel(h.level!) : _info;
      case 'RENEWAL_FAILED':
      case 'SUSPENDED':
        return _warn;
      case 'EXPIRING_SOON':
        return _severityForLevel(h.level ?? 14);
      case 'CANCELLED':
      case 'EXPIRED':
      default:
        return _danger;
    }
  }

  static const _info = _Severity(
      accent: Color(0xFF4A7F9D), background: Color(0xFFE2EDF4));
  static const _warn = _Severity(
      accent: Color(0xFFD28A2D), background: Color(0xFFF7EDDD));
  static const _danger = _Severity(
      accent: Color(0xFFC2564B), background: Color(0xFFF7E5E2));

  static _Severity _severityForLevel(int level) {
    if (level <= 3) return _danger;
    if (level <= 7) return _warn;
    return _info;
  }

  (String, String) _copyFor(dynamic l10n, SubscriptionHealth h) {
    switch (h.healthStatus) {
      case 'TRIAL':
        return (
          l10n.subscriptionHealthTrialTitle,
          l10n.subscriptionHealthTrialBody(h.daysToExpiry ?? 0)
        );
      case 'RENEWAL_FAILED':
        return (
          l10n.subscriptionHealthRenewalFailedTitle,
          l10n.subscriptionHealthRenewalFailedBody
        );
      case 'SUSPENDED':
        return (
          l10n.subscriptionHealthSuspendedTitle,
          l10n.subscriptionHealthSuspendedBody
        );
      case 'CANCELLED':
        return (
          l10n.subscriptionHealthCancelledTitle,
          l10n.subscriptionHealthCancelledBody
        );
      case 'EXPIRED':
        return (
          l10n.subscriptionHealthExpiredTitle,
          l10n.subscriptionHealthExpiredBody
        );
      case 'EXPIRING_SOON':
        return (
          l10n.subscriptionHealthExpiringTitle(h.daysToExpiry ?? 0),
          l10n.subscriptionHealthExpiringBody
        );
      default:
        return ('', '');
    }
  }

  static bool _showsPrimaryCta(String healthStatus) =>
      healthStatus != 'SUSPENDED';

  static String _ctaLabel(dynamic l10n, String healthStatus) {
    switch (healthStatus) {
      case 'RENEWAL_FAILED':
        return l10n.subscriptionHealthCtaRepay;
      case 'TRIAL':
        return l10n.subscriptionHealthCtaConvert;
      default:
        return l10n.subscriptionHealthCtaRenew;
    }
  }
}

class _Severity {
  final Color accent;
  final Color background;
  const _Severity({required this.accent, required this.background});
}
