import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/presentation/devices_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_device_tile.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(devicesControllerProvider);
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
            asyncData.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('暂无设备'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DeviceOverviewCard(data: data),
                    const SizedBox(height: AppSpacing.md),
                    for (final device in data.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HighfiDeviceTile(
                          device: device,
                          onInstall: () =>
                              _showInstallDialog(context, ref, device),
                          onUnbind: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content: Text('演示：解绑 ${device.name}')));
                          },
                          onViewLocation: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content:
                                      Text('演示：查看 ${device.name} 位置')));
                          },
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('加载失败: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.refresh(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallDialog(
      BuildContext context, WidgetRef ref, DeviceItem device) {
    // Build list of selectable livestock from ApiCache.
    final List<_LivestockOption> options;
    if (ApiCache.instance.initialized) {
      options = ApiCache.instance.animals.map((a) {
        final rawId = a['id'];
        final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
        return _LivestockOption(
          id: id,
          label: (a['livestockCode'] ?? a['earTag'] ?? id) as String,
          subtitle: (a['breed'] ?? '') as String,
        );
      }).toList();
    } else {
      options = [];
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => _InstallDialog(
        device: device,
        options: options,
        onConfirm: (livestockId) async {
          Navigator.of(ctx).pop();
          final session = ref.read(sessionControllerProvider);
          final role = session.role?.wireName ?? 'owner';
          final farmId = ApiCache.instance.activeFarmId ?? '';
          if (farmId.isEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('请先选择一个牧场')));
            return;
          }
          final ok = await ApiCache.instance.createInstallationRemote(
            role,
            farmId: farmId,
            deviceId: device.id,
            livestockId: livestockId,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(ok ? '安装成功：${device.name}' : '安装失败，请重试'),
              ));
          }
          if (ok) {
            ref.invalidate(devicesControllerProvider);
            ref.invalidate(dashboardControllerProvider);
          }
        },
      ),
    );
  }
}

class _LivestockOption {
  const _LivestockOption({
    required this.id,
    required this.label,
    required this.subtitle,
  });
  final String id;
  final String label;
  final String subtitle;
}

class _InstallDialog extends StatefulWidget {
  const _InstallDialog({
    required this.device,
    required this.options,
    required this.onConfirm,
  });

  final DeviceItem device;
  final List<_LivestockOption> options;
  final Future<void> Function(String livestockId) onConfirm;

  @override
  State<_InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<_InstallDialog> {
  String _query = '';
  bool _loading = false;

  List<_LivestockOption> get _filtered {
    if (_query.isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options
        .where((o) =>
            o.label.toLowerCase().contains(q) ||
            o.subtitle.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AlertDialog(
      key: const Key('install-device-dialog'),
      title: Text('安装到牲畜 — ${widget.device.name}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const Key('install-livestock-search'),
              decoration: const InputDecoration(
                hintText: '搜索耳标/品种',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              const Expanded(
                child: Center(child: Text('无匹配牲畜')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      key: Key('install-livestock-${item.id}'),
                      title: Text(item.label),
                      subtitle: Text(item.subtitle),
                      onTap: () => _select(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Future<void> _select(_LivestockOption item) async {
    setState(() => _loading = true);
    await widget.onConfirm(item.id);
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

class _DeviceOverviewCard extends StatelessWidget {
  const _DeviceOverviewCard({required this.data});

  final DevicesListData data;

  @override
  Widget build(BuildContext context) {
    final online =
        data.items.where((d) => d.status == DeviceStatus.online).length;
    final offline =
        data.items.where((d) => d.status == DeviceStatus.offline).length;
    final lowBat =
        data.items.where((d) => d.status == DeviceStatus.lowBattery).length;
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
              _Stat(label: '总数', value: '${data.items.length}'),
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
