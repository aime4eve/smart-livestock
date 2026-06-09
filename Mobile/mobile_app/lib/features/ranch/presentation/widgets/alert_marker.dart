import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';

class AlertMarker extends StatefulWidget {
  const AlertMarker({
    super.key,
    required this.label,
    required this.severity,
    this.onTap,
  });

  final String label;
  final String severity; // HIGH, MEDIUM, LOW
  final VoidCallback? onTap;

  @override
  State<AlertMarker> createState() => _AlertMarkerState();
}

class _AlertMarkerState extends State<AlertMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.severity) {
        'HIGH' => AppColors.danger,
        'MEDIUM' => AppColors.warning,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final shortLabel = widget.label.replaceAll('SL-2024-', '');
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 + _controller.value * 0.3;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color.withValues(alpha: 0.3 + _controller.value * 0.4),
                border: Border.all(color: _color, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      shortLabel.isNotEmpty ? shortLabel : '!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
