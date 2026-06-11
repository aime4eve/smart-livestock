import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

class HealthMarker extends StatelessWidget {
  const HealthMarker({
    super.key,
    required this.label,
    required this.healthStatus,
    this.fenceStatus,
    this.onTap,
  });

  final String label;
  final String healthStatus; // NORMAL, WARNING, CRITICAL
  final String? fenceStatus; // BREACHED, APPROACHING, SAFE (or null)
  final VoidCallback? onTap;

  Color get _color {
    // Fence status takes priority over health status
    if (fenceStatus != null) {
      switch (fenceStatus!) {
        case 'BREACHED': return AppColors.danger;
        case 'APPROACHING': return AppColors.warning;
        case 'SAFE': break; // fall through to health logic
      }
    }
    return switch (healthStatus) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      _ => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    final shortLabel = label.replaceAll('SL-2024-', '');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
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
    );
  }
}
