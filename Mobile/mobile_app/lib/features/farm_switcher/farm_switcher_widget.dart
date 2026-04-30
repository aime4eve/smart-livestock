import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class FarmSwitcher extends ConsumerWidget {
  const FarmSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmState = ref.watch(farmSwitcherControllerProvider);
    if (!farmState.hasMultipleFarms) return const SizedBox.shrink();

    final activeFarmId = farmState.farms
            .any((farm) => farm.id == farmState.activeFarmId)
        ? farmState.activeFarmId
        : farmState.farms.first.id;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const Key('farm-switcher'),
              value: activeFarmId,
              isDense: true,
              icon: const Icon(Icons.expand_more),
              items: [
                for (final farm in farmState.farms)
                  DropdownMenuItem(
                    value: farm.id,
                    child: Text(
                      farm.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (farmId) {
                if (farmId == null) return;
                ref
                    .read(farmSwitcherControllerProvider.notifier)
                    .switchFarm(farmId);
              },
            ),
          ),
        ),
      ),
    );
  }
}
