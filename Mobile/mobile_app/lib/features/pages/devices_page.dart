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
import 'package:hkt_livestock_agentic/features/devices/presentation/widgets/device_health_card.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_device_tile.dart';
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
      final data = await ApiClient.instance.farmGet('/installations');
      final items = data['items'] as List? ?? [];
      final Map<String, String> map = {};

      // Fetch livestock codes for matching
      final livestockData = await ref.read(livestockRepositoryProvider).loadAll(pageSize: 200);
      final Map<String, String> livestockIdToCode = {};
      final Map<String, String> livestockIdToNumeric = {};
      for (final l in livestockData.items) {
        livestockIdToCode[l.id] = l.earTag;
        livestockIdToNumeric[l.id] = l.id;
      }

      final Map<String, String> codeMap = {};
      final Map<String, String> idMap = {};
      for (final inst in items) {
        if (inst['active'] == true) {
          final devId = inst['deviceId']?.toString() ?? '';
          final liveId = inst['livestockId']?.toString() ?? '';
          codeMap[devId] = livestockIdToCode[liveId] ?? '';
          idMap[devId] = livestockIdToNumeric[liveId] ?? liveId;
        }
      }
      if (mounted) setState(() {
        _deviceIdToLivestockCode = codeMap;
        _deviceIdToLivestockId = idMap;
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
                               onInstall: _deviceIdToLivestockCode.containsKey(device.id)
                                   ? null
                                   : () => _showInstallDialog(context, ref, device),
                               onUnbind: () {
                                 ScaffoldMessenger.of(context)
                                   ..hideCurrentSnackBar()
                                   ..showSnackBar(SnackBar(
                                       content: Text(l10n
                                           .devicesUnbindDemo(device.name))));
                               },
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
          .map((l) => _LivestockOption(id: l.id, label: l.earTag, subtitle: l.breed.name))
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
          .map((l) => _LivestockOption(id: l.id, label: l.earTag, subtitle: l.breed.name)));
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
    this.onInstall,
    this.onUnbind,
    this.onViewLocation,
  });

  final DeviceItem device;
  final String boundLivestockCode;
  final VoidCallback? onInstall;
  final VoidCallback? onUnbind;
  final VoidCallback? onViewLocation;

  @override
  Widget build(BuildContext context) {
   final effective = device.copyWith(boundEarTag: boundLivestockCode);
   return GestureDetector(
     onTap: () => DeviceHealthDialog.show(context, device, boundLivestockCode: boundLivestockCode),
     child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiDeviceTile(
        device: effective,
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
