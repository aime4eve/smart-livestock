import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/core_models.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/presentation/devices_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_device_tile.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(devicesControllerProvider);
    final controller = ref.read(devicesControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesManagement)),
      floatingActionButton: FloatingActionButton(
        key: const Key('device-add-fab'),
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.devicesAddDemo)));
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l10n.devicesNoDevices),
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
                                  content: Text(l10n.devicesUnbindDemo(device.name))));
                          },
                          onViewLocation: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content:
                                      Text(l10n.devicesViewLocationDemo(device.name))));
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
                    Text('${l10n.commonLoadFailed}: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.refresh(),
                      child: Text(l10n.commonRetry),
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
    final l10n = AppLocalizations.of(context)!;
    // Livestock options from API (placeholder until async migration)
    const options = <_LivestockOption>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => _InstallDialog(
        device: device,
        options: options,
        onConfirm: (livestockId) async {
          Navigator.of(ctx).pop();
          final farmId = ApiClient.instance.activeFarmId ?? '';
          if (farmId.isEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.fencePleaseSelectFarm)));
            return;
          }
          try {
            await ApiClient.instance.farmPost('/installations', body: {
              'deviceId': device.id,
              'livestockId': livestockId,
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(l10n.devicesInstallSuccess(device.name)),
                ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(l10n.devicesInstallFailed(e.toString())),
                ));
            }
          }
          ref.invalidate(devicesControllerProvider);
          ref.invalidate(dashboardControllerProvider);
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
    final l10n = AppLocalizations.of(context)!;
    final items = _filtered;
    return AlertDialog(
      key: const Key('install-device-dialog'),
      title: Text(l10n.devicesInstallTo(widget.device.name)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              key: const Key('install-livestock-search'),
              decoration: InputDecoration(
                hintText: l10n.devicesSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (items.isEmpty)
              Expanded(
                child: Center(child: Text(l10n.devicesNoMatchingLivestock)),
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
          child: Text(l10n.commonCancel),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(l10n.devicesOverview, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _Stat(label: l10n.devicesStatTotal, value: '${data.items.length}'),
              _Stat(label: l10n.deviceStatusOnline, value: '$online'),
              _Stat(label: l10n.deviceStatusOffline, value: '$offline'),
              _Stat(label: l10n.deviceStatusLowBattery, value: '$lowBat'),
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
