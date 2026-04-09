import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';
import 'package:smart_livestock_demo/features/livestock/presentation/livestock_controller.dart';

class LivestockDetailPage extends ConsumerWidget {
  const LivestockDetailPage({super.key, required this.earTag});

  final String earTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(livestockControllerProvider(earTag));
    return Scaffold(
      appBar: AppBar(
        title: const Text('牲畜详情'),
        leading: IconButton(
          key: const Key('livestock-back'),
          onPressed: () => context.go(AppRoute.twin.path),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-livestock-detail'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBody(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LivestockViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '未找到该牲畜',
          description: '该耳标号暂无对应数据。',
          icon: Icons.search_off,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无查看权限',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        final d = data.detail!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LivestockInfoCard(detail: d),
            const SizedBox(height: AppSpacing.md),
            _DeviceListCard(detail: d),
            const SizedBox(height: AppSpacing.md),
            _HealthDataCard(detail: d),
            const SizedBox(height: AppSpacing.md),
            _LocationCard(detail: d),
          ],
        );
    }
  }
}

class _LivestockInfoCard extends StatelessWidget {
  const _LivestockInfoCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('livestock-info-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                detail.earTag,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              HighfiStatusChip(
                label: switch (detail.health) {
                  LivestockHealth.healthy => '健康',
                  LivestockHealth.watch => '关注',
                  LivestockHealth.abnormal => '异常',
                },
                color: switch (detail.health) {
                  LivestockHealth.healthy => AppColors.success,
                  LivestockHealth.watch => AppColors.warning,
                  LivestockHealth.abnormal => AppColors.danger,
                },
                icon: switch (detail.health) {
                  LivestockHealth.healthy => Icons.check_circle_outline,
                  LivestockHealth.watch => Icons.visibility_outlined,
                  LivestockHealth.abnormal => Icons.warning_amber_rounded,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoItem(label: '品种', value: detail.breed),
              _InfoItem(label: '月龄', value: '${detail.ageMonths} 个月'),
              _InfoItem(label: '体重', value: '${detail.weightKg} kg'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('livestock-device-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('绑定设备', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final device in detail.devices)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      switch (device.type) {
                        DeviceType.gps => Icons.gps_fixed,
                        DeviceType.rumenCapsule => Icons.medication,
                        DeviceType.accelerometer => Icons.speed,
                      },
                      color: switch (device.status) {
                        DeviceStatus.online => AppColors.success,
                        DeviceStatus.offline => AppColors.textSecondary,
                        DeviceStatus.lowBattery => AppColors.warning,
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            [
                              if (device.batteryPercent != null)
                                '电量 ${device.batteryPercent}%',
                              if (device.signalStrength != null)
                                '信号${device.signalStrength}',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthDataCard extends StatelessWidget {
  const _HealthDataCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('livestock-health-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('健康数据', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InfoItem(label: '体温', value: '${detail.bodyTemp}°C'),
              _InfoItem(label: '活动量', value: detail.activityLevel),
              _InfoItem(label: '反刍频率', value: detail.ruminationFreq),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '体温趋势图（占位）',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      key: const Key('livestock-location-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('位置信息', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '最近位置：${detail.lastLocation}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('livestock-view-track'),
            onPressed: () => context.go(AppRoute.map.path),
            icon: const Icon(Icons.map_outlined),
            label: const Text('查看完整轨迹'),
          ),
        ],
      ),
    );
  }
}
