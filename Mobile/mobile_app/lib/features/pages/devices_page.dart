import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/presentation/devices_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_device_tile.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(devicesControllerProvider);
    final controller = ref.read(devicesControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
      floatingActionButton: FloatingActionButton(
        key: const Key('device-add-fab'),
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('演示：添加新设备待接入')));
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        key: const Key('page-devices'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.viewState == ViewState.normal) ...[
              _DeviceOverviewCard(data: data),
              const SizedBox(height: AppSpacing.md),
              _DeviceFilterBar(
                filter: data.filter,
                onFilterChanged: controller.setFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final device in data.devices)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: HighfiDeviceTile(
                    device: device,
                    onUnbind: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                            SnackBar(content: Text('演示：解绑 ${device.name}')));
                    },
                    onViewLocation: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                            SnackBar(content: Text('演示：查看 ${device.name} 位置')));
                    },
                  ),
                ),
            ] else
              _buildNonNormal(data),
          ],
        ),
      ),
    );
  }

  Widget _buildNonNormal(DevicesViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无设备',
          description: '可通过右上角添加新设备。',
          icon: Icons.devices_other,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '设备列表加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无权限查看设备',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线设备快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return const SizedBox.shrink();
    }
  }
}

class _DeviceOverviewCard extends StatelessWidget {
  const _DeviceOverviewCard({required this.data});

  final DevicesViewData data;

  @override
  Widget build(BuildContext context) {
    final online =
        data.devices.where((d) => d.status == DeviceStatus.online).length;
    final offline =
        data.devices.where((d) => d.status == DeviceStatus.offline).length;
    final lowBat =
        data.devices.where((d) => d.status == DeviceStatus.lowBattery).length;
    return HighfiCard(
      key: const Key('device-overview-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设备概览', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _Stat(label: '总数', value: '${data.devices.length}'),
              _Stat(label: '在线', value: '$online'),
              _Stat(label: '离线', value: '$offline'),
              _Stat(label: '低电', value: '$lowBat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _DeviceFilterBar extends StatelessWidget {
  const _DeviceFilterBar({
    required this.filter,
    required this.onFilterChanged,
  });

  final DeviceStatus? filter;
  final ValueChanged<DeviceStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FilterChip(
          label: '全部',
          selected: filter == null,
          onTap: () => onFilterChanged(null),
          color: AppColors.primary,
        ),
        _FilterChip(
          label: '在线',
          selected: filter == DeviceStatus.online,
          onTap: () => onFilterChanged(DeviceStatus.online),
          color: AppColors.success,
        ),
        _FilterChip(
          label: '离线',
          selected: filter == DeviceStatus.offline,
          onTap: () => onFilterChanged(DeviceStatus.offline),
          color: AppColors.textSecondary,
        ),
        _FilterChip(
          label: '低电',
          selected: filter == DeviceStatus.lowBattery,
          onTap: () => onFilterChanged(DeviceStatus.lowBattery),
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HighfiStatusChip(
        label: label,
        color: selected ? color : AppColors.border,
        icon: selected ? Icons.check_circle_outline : null,
      ),
    );
  }
}
