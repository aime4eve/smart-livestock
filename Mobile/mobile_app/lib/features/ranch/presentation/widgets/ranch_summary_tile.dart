import 'package:flutter/material.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

/// One summary tile of the "morning dashboard" tile row (Plan D). Shared by
/// the ranch overview and the fence tab so both pages stay 1:1 identical.
class RanchSummaryTile extends StatelessWidget {
  const RanchSummaryTile({
    super.key,
    required this.colored,
    required Color c1,
    required Color c2,
    required this.label,
    required this.big,
    required this.sub,
    required this.subColor,
    this.badge,
    this.onTap,
  })  : _c1 = c1,
        _c2 = c2;

  final bool colored;
  final Color _c1;
  final Color _c2;
  final String label;
  final String big;
  final String sub;
  final Color subColor;
  final int? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final coloredStyle = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_c1, _c2],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3)),
      ],
    );
    final plainStyle = BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: colored ? coloredStyle : plainStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null && badge! > 0)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7)),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger)),
                ),
              ),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: colored
                        ? Colors.white
                        : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(big,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color:
                        colored ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(
                    fontSize: 8,
                    height: 1.3,
                    fontWeight: !colored && subColor == AppColors.success
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: colored
                        ? Colors.white.withValues(alpha: 0.85)
                        : subColor)),
          ],
        ),
      ),
    );
  }
}
