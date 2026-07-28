import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

/// Shared quality-grade badge (spec §9: EXCELLENT #16A34A / USABLE #2563EB /
/// MARGINAL #C2410C / UNAVAILABLE #DC2626). Used by the NIX-68 LINE panels;
/// the pre-existing private badges keep their own copies.
class GradeBadge extends StatelessWidget {
  const GradeBadge({super.key, required this.grade, this.compact = false});

  final QualityGrade grade;
  final bool compact;

  static Color gradeColor(QualityGrade grade) => switch (grade) {
        QualityGrade.excellent => const Color(0xFF16A34A),
        QualityGrade.usable => const Color(0xFF2563EB),
        QualityGrade.marginal => const Color(0xFFC2410C),
        QualityGrade.unavailable => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) {
    final label = switch (grade) {
      QualityGrade.excellent => 'EXCELLENT',
      QualityGrade.usable => 'USABLE',
      QualityGrade.marginal => 'MARGINAL',
      QualityGrade.unavailable => 'UNAVAILABLE',
    };
    final color = gradeColor(grade);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 1 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 4 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: compact ? 9 : 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
