import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/dashboard/domain/dashboard_repository.dart';
import 'package:hkt_livestock_agentic/features/dashboard/presentation/dashboard_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_stat_tile.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final farmState = ref.watch(farmSwitcherControllerProvider);
    final session = ref.watch(sessionControllerProvider);

    // Show empty farm guide for owners who have no farms
    if (farmState.farms.isEmpty && session.role == UserRole.owner) {
      return const _EmptyFarmGuide();
    }

    final asyncData = ref.watch(dashboardControllerProvider);

    return SingleChildScrollView(
      key: const Key('page-dashboard'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          asyncData.when(
            data: (data) => _buildContent(context, data),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${l10n.commonLoadFailed}: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(dashboardControllerProvider.notifier)
                        .refresh(),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardViewData data) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _DashboardFarmHeader(),
        const SizedBox(height: AppSpacing.lg),
        if (data.metrics.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.dashboardNoData),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final m in data.metrics)
                SizedBox(
                  width: 160,
                  child: KeyedSubtree(
                    key: m.widgetKey == 'dashboard-metric-animal-total'
                        ? const Key('dashboard-metric-livestock')
                        : null,
                    child: HighfiStatTile(
                      key: Key(m.widgetKey),
                      title: m.title,
                      value: m.value,
                      caption: l10n.dashboardTodayOverview,
                      trend: '+1.8%',
                      onTap: () => context.go(
                        AppRoute.livestockDetail.path
                            .replaceFirst(':id', '001'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DashboardFarmHeader extends ConsumerWidget {
  const _DashboardFarmHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final farmName = ref.watch(farmSwitcherControllerProvider).activeFarmName;
    return HighfiCard(
      key: const Key('dashboard-farm-header'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(farmName.isNotEmpty ? farmName : l10n.dashboardFarmOverview, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '晴 18°C · 最近同步 2 分钟前',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyFarmGuide extends StatelessWidget {
  const _EmptyFarmGuide();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_business_outlined,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.dashboardNoFarm,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.dashboardCreateFirstFarmDesc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                key: const Key('create-first-farm-btn'),
                onPressed: () => context.go(AppRoute.farmCreation.path),
                child: Text(l10n.dashboardCreateFirstFarm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
