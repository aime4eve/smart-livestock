import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Colored quality-grade badge.
///
/// EXCELLENT=green / USABLE=blue / MARGINAL=amber / UNAVAILABLE=red.
class QualityGradeBadge extends StatelessWidget {
  const QualityGradeBadge({
    super.key,
    required this.grade,
    this.compact = false,
  });

  final QualityGrade grade;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = _spec(grade);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: spec.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(spec.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            _label(grade, l10n),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: spec.fg,
            ),
          ),
        ],
      ),
    );
  }

  String _label(QualityGrade g, AppLocalizations l10n) => switch (g) {
        QualityGrade.excellent => l10n.gpsQualityGradeExcellent,
        QualityGrade.usable => l10n.gpsQualityGradeUsable,
        QualityGrade.marginal => l10n.gpsQualityGradeMarginal,
        QualityGrade.unavailable => l10n.gpsQualityGradeUnavailable,
      };

  _BadgeSpec _spec(QualityGrade g) => switch (g) {
        QualityGrade.excellent => const _BadgeSpec(
            icon: '✅',
            fg: Color(0xFF16A34A),
            bg: Color(0xFFDCFCE7),
            border: Color(0xFFBBF7D0)),
        QualityGrade.usable => const _BadgeSpec(
            icon: '✅',
            fg: Color(0xFF2563EB),
            bg: Color(0xFFDBEAFE),
            border: Color(0xFFBFDBFE)),
        QualityGrade.marginal => const _BadgeSpec(
            icon: '⚠️',
            fg: Color(0xFFB45309),
            bg: Color(0xFFFEF3C7),
            border: Color(0xFFFDE68A)),
        QualityGrade.unavailable => const _BadgeSpec(
            icon: '❌',
            fg: Color(0xFFDC2626),
            bg: Color(0xFFFEE2E2),
            border: Color(0xFFFECACA)),
      };
}

class _BadgeSpec {
  const _BadgeSpec({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.border,
  });
  final String icon;
  final Color fg;
  final Color bg;
  final Color border;
}
