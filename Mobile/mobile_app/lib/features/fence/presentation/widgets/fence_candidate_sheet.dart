import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

Future<String?> showFenceCandidateSheet(
  BuildContext context,
  List<FenceItem> candidates,
) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
    ),
    builder: (ctx) => _CandidateList(
      key: const Key('fence-candidate-sheet'),
      candidates: candidates,
    ),
  );
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({super.key, required this.candidates});

  final List<FenceItem> candidates;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '选择围栏',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final fence in candidates)
            ListTile(
              key: Key('fence-candidate-${fence.id}'),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(fence.name),
              trailing: Text(
                '${fence.livestockCount}头',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              onTap: () => Navigator.of(context).pop(fence.id),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
