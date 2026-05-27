import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class TenantSkeleton extends StatefulWidget {
  const TenantSkeleton({super.key});

  @override
  State<TenantSkeleton> createState() => _TenantSkeletonState();
}

class _TenantSkeletonState extends State<TenantSkeleton>
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 160, height: 18),
                const SizedBox(height: AppSpacing.md),
                _bar(width: 240, height: 12),
                const SizedBox(height: AppSpacing.xs),
                _bar(width: double.infinity, height: 6),
                const SizedBox(height: AppSpacing.sm),
                _bar(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HighfiCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _bar(width: 72, height: 32),
                _bar(width: 72, height: 32),
                _bar(width: 96, height: 32),
                _bar(width: 64, height: 32),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return HighfiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 100, height: 14),
          const SizedBox(height: AppSpacing.sm),
          _bar(width: double.infinity, height: 36),
        ],
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class TenantEmptyCard extends StatelessWidget {
  const TenantEmptyCard({
    super.key,
    required this.title,
    required this.icon,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary.withAlpha(100)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
