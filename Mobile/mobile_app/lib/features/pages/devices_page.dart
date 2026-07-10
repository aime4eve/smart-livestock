import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/dashboard/presentation/dashboard_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/widgets/device_form_sheet.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_device_tile.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
 final _searchCtrl = TextEditingController();
 Timer? _debounce;
 bool _hasSearch = false;
 Map<String, String> _deviceIdToLivestockCode = {};
  Map<String, String> _deviceIdToLivestockId = {};
  Map<String, String> _deviceIdToInstallationId = {};

 @override
 void dispose() {
   _searchCtrl.dispose();
   _debounce?.cancel();
   super.dispose();
 }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInstallations());
  }

  void _onSearchChanged(String value) {
    setState(() => _hasSearch = value.trim().isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(devicesControllerProvider.notifier).search(value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _hasSearch = false);
    ref.read(devicesControllerProvider.notifier).search('');
  }

 void _openForm() {
   showModalBottomSheet(
     context: context,
     isScrollControlled: true,
     builder: (ctx) => DeviceFormSheet(),
   ).then((_) => ref.read(devicesControllerProvider.notifier).refresh());
 }

  Future<void> _loadInstallations() async {
   try {
    // Request a large page size to get all active installations in one call;
    // default pageSize=20 would miss devices beyond the first page.
    final data = await ApiClient.instance.farmGet('/installations?pageSize=500');
     final items = data['items'] as List? ?? [];

      // Fetch livestock codes for matching
      final livestockData = await ref.read(livestockRepositoryProvider).loadAll(pageSize: 200);
      final Map<String, String> livestockIdToCode = {};
      final Map<String, String> livestockIdToNumeric = {};
      for (final l in livestockData.items) {
        livestockIdToCode[l.id] = l.livestockCode;
        livestockIdToNumeric[l.id] = l.id;
      }

      final Map<String, String> codeMap = {};
      final Map<String, String> idMap = {};
      final Map<String, String> installationMap = {};
      for (final inst in items) {
        if (inst['active'] == true) {
          final devId = inst['deviceId']?.toString() ?? '';
          final liveId = inst['livestockId']?.toString() ?? '';
          final instId = inst['id']?.toString() ?? '';
          codeMap[devId] = livestockIdToCode[liveId] ?? '';
          idMap[devId] = livestockIdToNumeric[liveId] ?? liveId;
          if (instId.isNotEmpty) installationMap[devId] = instId;
        }
      }
      if (mounted) setState(() {
        _deviceIdToLivestockCode = codeMap;
        _deviceIdToLivestockId = idMap;
        _deviceIdToInstallationId = installationMap;
      });
    } catch (_) {}
  }

 @override
 Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(devicesControllerProvider);
    final controller = ref.read(devicesControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.devicesManagement),
        actions: [
          IconButton(
            key: const Key('device-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: _openForm,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              key: const Key('device-search'),
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.deviceSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          // Search result banner
          if (_hasSearch && asyncData is AsyncData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.deviceSearchResult(asyncData.value!.total),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('device-show-all'),
                    onPressed: _clearSearch,
                    child: Text(l10n.deviceShowAll),
                  ),
                ],
              ),
            ),
          // List + pagination
          Expanded(
            child: asyncData.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return Center(child: Text(l10n.devicesNoDevices));
                }
           return Column(
                 children: [
                   Expanded(
                     child: SingleChildScrollView(
                       key: const Key('page-devices'),
                       padding: const EdgeInsets.symmetric(
                           horizontal: AppSpacing.lg),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                           _DeviceOverviewCard(data: data),
                           const SizedBox(height: AppSpacing.md),
                           for (final device in data.items)
                             _DeviceWithBinding(
                               device: device,
                               boundLivestockCode: _deviceIdToLivestockCode[device.id] ?? '',
                              onActivate: !device.isActivated
                                  ? () => _activateDevice(context, ref, device)
                                  : null,
                              onInstall: device.isActivated && !_deviceIdToLivestockCode.containsKey(device.id)
                                  ? () => _showInstallDialog(context, ref, device)
                                  : null,
                              onUnbind: _deviceIdToInstallationId.containsKey(device.id)
                                  ? () => _showUnbindDialog(context, ref, device)
                                  : null,
                              onViewLocation: _deviceIdToLivestockId[device.id] != null
                                   ? () => context.go('/livestock/${_deviceIdToLivestockId[device.id]}')
                                   : () => context.go('/ranch'),
                             ),
                         ],
                       ),
                     ),
                   ),
                    _PaginationBar(
                      currentPage: controller.currentPage,
                      totalPages: controller.totalPages,
                      total: data.total,
                      onPrev: () => controller
                          .goToPage(controller.currentPage - 1),
                      onNext: () => controller
                          .goToPage(controller.currentPage + 1),
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
          ),
        ],
      ),
   );
 }

  Future<void> _activateDevice(
      BuildContext context, WidgetRef ref, DeviceItem device) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.instance.farmPut('/devices/${device.id}/activate');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.deviceActivateSuccess(device.name)),
          ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.deviceActivateFailed(e.toString())),
          ));
      }
    }
    await _loadInstallations();
    ref.invalidate(devicesControllerProvider);
    ref.invalidate(dashboardControllerProvider);
  }

  Future<void> _showUnbindDialog(
      BuildContext context, WidgetRef ref, DeviceItem device) async {
    final l10n = AppLocalizations.of(context)!;
    final installationId = _deviceIdToInstallationId[device.id];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deviceUnbind),
        content: Text(l10n.deviceUnbindConfirm(device.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('device-unbind-confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiClient.instance
          .farmPut('/installations/$installationId/uninstall');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.deviceUnbindSuccess(device.name)),
          ));
     }
     await _loadInstallations();
     ref.invalidate(devicesControllerProvider);
     ref.invalidate(dashboardControllerProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(l10n.deviceUnbindFailed(e.toString())),
          ));
      }
    }
  }

  Future<void> _showInstallDialog(
      BuildContext context, WidgetRef ref, DeviceItem device) async {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (ctx) => _InstallDialog(
        device: device,
        livestockRepo: ref.read(livestockRepositoryProvider),
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
         await _loadInstallations();
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
    required this.livestockRepo,
    required this.onConfirm,
  });

  final DeviceItem device;
  final LivestockRepository livestockRepo;
  final Future<void> Function(String livestockId) onConfirm;

  @override
  State<_InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<_InstallDialog> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<_LivestockOption> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 20;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() => _loading = true);
    _page = 1;
    _hasMore = true;
    try {
      final data = await widget.livestockRepo.loadAll(
        page: 1, pageSize: _pageSize,
        keyword: _keyword.isNotEmpty ? _keyword : null,
      );
      _items = data.items
          .map((l) => _LivestockOption(id: l.id, label: l.livestockCode, subtitle: l.breed.name))
          .toList();
      _hasMore = data.page * data.pageSize < data.total;
    } catch (_) {
      _items = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await widget.livestockRepo.loadAll(
        page: nextPage, pageSize: _pageSize,
        keyword: _keyword.isNotEmpty ? _keyword : null,
      );
      _items.addAll(data.items
          .map((l) => _LivestockOption(id: l.id, label: l.livestockCode, subtitle: l.breed.name)));
      _page = nextPage;
      _hasMore = data.page * data.pageSize < data.total;
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onSearchChanged(String value) {
    _keyword = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.devicesSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                  ? Center(child: Text(l10n.devicesNoMatchingLivestock))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final item = _items[i];
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

/// Wraps a device tile with real binding data from installations.
class _DeviceWithBinding extends StatelessWidget {
  const _DeviceWithBinding({
    required this.device,
    required this.boundLivestockCode,
    this.onActivate,
    this.onInstall,
    this.onUnbind,
    this.onViewLocation,
  });

  final DeviceItem device;
  final String boundLivestockCode;
  final VoidCallback? onActivate;
  final VoidCallback? onInstall;
  final VoidCallback? onUnbind;
  final VoidCallback? onViewLocation;

  @override
  Widget build(BuildContext context) {
   final effective = device.copyWith(boundLivestockCode: boundLivestockCode);
   return GestureDetector(
     onTap: () => DeviceHealthDialog.show(context, device, boundLivestockCode: boundLivestockCode),
     child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiDeviceTile(
        device: effective,
        onActivate: onActivate,
        onInstall: onInstall,
        onUnbind: onUnbind,
        onViewLocation: onViewLocation,
      ),
     ),
    );
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
              _Stat(label: l10n.devicesStatTotal, value: '${data.total}'),
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.devicePaginationInfo(currentPage, totalPages, total),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                key: const Key('device-prev-page'),
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 ? onPrev : null,
              ),
              Text('$currentPage / $totalPages'),
              IconButton(
                key: const Key('device-next-page'),
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class DeviceHealthDialog extends StatefulWidget {
  const DeviceHealthDialog({super.key, required this.device, this.boundLivestockCode});

  final DeviceItem device;
  final String? boundLivestockCode;

  static Future<void> show(BuildContext context, DeviceItem device, {String? boundLivestockCode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeviceHealthDialog(device: device, boundLivestockCode: boundLivestockCode),
    );
  }

  @override
  State<DeviceHealthDialog> createState() => _DeviceHealthDialogState();
}

class _DeviceHealthDialogState extends State<DeviceHealthDialog> {
  Map<String, dynamic>? _healthData;
    // unused
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
   try {
    final health = await ApiClient.instance.farmGet('/devices/${widget.device.id}/health');
     final d = health['data'];
      if (d is Map) _healthData = d.cast<String, dynamic>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.device;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppSpacing.md),

            // Header
            _HeaderTile(device: d, boundLivestockCode: widget.boundLivestockCode),

            // Health score card
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_healthData != null)
              _HealthScoreCard(score: _healthData!['score'] as int?, grade: _healthData!['grade'] as String?, dimensions: _healthData!['dimensions'] as Map<String, dynamic>?),
            const SizedBox(height: AppSpacing.md),

            // Signal card
            _InfoCard(title: '信号质量', icon: Icons.signal_cellular_alt, children: [
              if (d.rssi != null) _InfoRow(label: 'RSSI', value: '${d.rssi} dBm', badge: _rssiBadge(d.rssi!)),
              if (d.snr != null) _InfoRow(label: 'SNR', value: d.snr!),
              if (d.lastGateway != null) _InfoRow(label: '网关', value: d.lastGateway!, mono: true),
            ]),
            const SizedBox(height: AppSpacing.sm),

            // Device identity card
            _InfoCard(title: '设备信息', icon: Icons.memory, children: [
              if (d.devEui != null) _InfoRow(label: 'DevEUI', value: d.devEui!, mono: true),
              if (d.platformDeviceId != null) _InfoRow(label: '平台 ID', value: d.platformDeviceId.toString(), mono: true),
              if (d.softwareVersion != null) _InfoRow(label: '软件版本', value: d.softwareVersion!),
              if (d.hardwareVersion != null) _InfoRow(label: '硬件版本', value: d.hardwareVersion!),
              if (d.lastTelemetrySyncedAt != null) _InfoRow(label: '最后同步', value: _fmtTime(d.lastTelemetrySyncedAt!.toString())),
              _InfoRow(label: '运行状态', value: d.runtimeStatus ?? d.status.name, badge: _statusBadge(d)),
            ]),

            // Platform registration
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(title: '平台注册', icon: Icons.cloud, children: [
              Row(children: [
                Icon(d.isPlatformRegistered ? Icons.cloud_done : Icons.cloud_off, size: 20,
                    color: d.isPlatformRegistered ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(d.isPlatformRegistered ? '已注册 (agentic-middle-platform)' : '未注册'),
              ]),
              if (d.lastTelemetrySyncedAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('同步时间: ${_fmtTime(d.lastTelemetrySyncedAt!.toString())}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
            const SizedBox(height: AppSpacing.sm),

            // Binding info
            _InfoCard(title: '牲畜绑定', icon: Icons.link, children: [
              if (widget.boundLivestockCode != null && widget.boundLivestockCode!.isNotEmpty)
                _InfoRow(label: '绑定牲畜', value: widget.boundLivestockCode!)
              else
                Text('未绑定', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _rssiBadge(int rssi) {
    final color = rssi >= -50 ? AppColors.success : rssi >= -80 ? AppColors.warning : AppColors.danger;
    final label = rssi >= -50 ? '优良' : rssi >= -80 ? '一般' : '差';
    return _Badge(color: color, label: label);
  }

  Widget _statusBadge(DeviceItem d) {
    final online = d.runtimeStatus?.toLowerCase() == 'online' || d.status == 'ACTIVE';
    return _Badge(color: online ? AppColors.success : AppColors.danger, label: online ? '在线' : '离线');
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ts; }
  }
}

class _HeaderTile extends StatelessWidget {
  const _HeaderTile({required this.device, this.boundLivestockCode});
  final DeviceItem device;
  final String? boundLivestockCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(children: [
        Icon(_typeIcon(device.type), size: 36, color: _statusColor(device)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${device.deviceTypeName ?? device.type.name} · ${device.runtimeStatus ?? device.status.name} · 电量 ${device.batteryPercent ?? "?"}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          if (boundLivestockCode != null && boundLivestockCode!.isNotEmpty) Text('绑定: $boundLivestockCode', style: Theme.of(context).textTheme.bodySmall),
        ])),

      ]),
    );
  }

  IconData _typeIcon(dynamic t) {
    if (t is DeviceType) return switch (t) { DeviceType.gps => Icons.gps_fixed, DeviceType.rumenCapsule => Icons.medication, DeviceType.earTag => Icons.tag };
    return Icons.devices;
  }
  Color _statusColor(DeviceItem d) => (d.runtimeStatus?.toLowerCase() == 'online' || d.status.name.toLowerCase() == 'active') ? AppColors.success : AppColors.danger;
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({this.score, this.grade, this.dimensions});
  final int? score;
  final String? grade;
  final Map<String, dynamic>? dimensions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _gradeColor(grade).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gradeColor(grade).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          _HealthScoreCircle(score: score ?? 0, radius: 30, fontSize: 20),
          const SizedBox(width: AppSpacing.md),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('设备健康分', style: Theme.of(context).textTheme.titleMedium),
            Text(grade ?? '--', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _gradeColor(grade), fontWeight: FontWeight.bold)),
          ]),
        ]),
        if (dimensions != null) ...[
          const SizedBox(height: AppSpacing.md),
          ...dimensions!.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _DimBar(label: _dimLabel(e.key), value: (e.value as num).toInt(), color: _dimColor(e.key)),
          )),
        ],
      ]),
    );
  }

  Color _gradeColor(String? g) => switch (g?.toUpperCase()) { 'HEALTHY' => AppColors.success, 'WARNING' => AppColors.warning, _ => AppColors.danger };
  String _dimLabel(String k) => switch (k) { 'battery' => '电量', 'signal' => '信号', 'online' => '在线', 'tamper' => '防拆卸', 'reporting' => '数据上报', _ => k };
  Color _dimColor(String k) => switch (k) { 'battery' => Colors.orange, 'signal' => Colors.blue, 'online' => Colors.teal, 'tamper' => Colors.red, 'reporting' => Colors.purple, _ => Colors.grey };
}

class _DimBar extends StatelessWidget {
  const _DimBar({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: value / 100, backgroundColor: Colors.grey[200], color: color, minHeight: 8),
    )),
    SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall)),
  ]);
}

class _HealthScoreCircle extends StatelessWidget {
  const _HealthScoreCircle({required this.score, this.radius = 24, this.fontSize = 16});
  final int score;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.danger;
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15), border: Border.all(color: color, width: 3)),
      child: Center(child: Text('$score', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color))),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), const SizedBox(width: AppSpacing.sm), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
      const SizedBox(height: AppSpacing.sm),
      ...children,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.badge, this.mono = false});
  final String label;
  final String value;
  final Widget? badge;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
      Expanded(child: Text(value, style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 13))),
      if (badge != null) badge!,
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}
