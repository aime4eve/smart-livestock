import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/features/gateways/presentation/gateway_distance_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/l10n/enum_labels.dart';
import 'package:hkt_livestock_agentic/core/charts/temperature_axis.dart';
import 'package:hkt_livestock_agentic/core/charts/chart_readout_layer.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/widgets/auto_refresh_listener.dart';
import 'package:hkt_livestock_agentic/core/widgets/data_freshness_indicator.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/livestock_form_sheet.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/mark_diseased_action_row.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/widgets/physiology_record_card.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_card.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_detail_section.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';

class LivestockDetailPage extends ConsumerWidget {
  const LivestockDetailPage({super.key, required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(livestockDetailControllerProvider(livestockId));
    final refreshedAt = ref.watch(dataRefreshedAtProvider(livestockId));
    return AutoRefreshListener(
      interval: const Duration(seconds: 30),
      onTick: () async {
        // Page aggregates main detail + fever + digestive + estrus trends;
        // silent refresh keeps the UI stable while new telemetry arrives.
        final futures = <Future<void>>[
          ref
              .read(livestockDetailControllerProvider(livestockId).notifier)
              .silentRefresh(),
          ref
              .read(feverDetailControllerProvider(livestockId).notifier)
              .silentRefresh(),
          ref
              .read(digestiveDetailControllerProvider(livestockId).notifier)
              .silentRefresh(),
        ];
        // Estrus chart is premium-gated; only poll when its provider is active.
        if (ref.exists(estrusDetailControllerProvider(livestockId))) {
          futures.add(
            ref
                .read(estrusDetailControllerProvider(livestockId).notifier)
                .silentRefresh(),
          );
        }
        await Future.wait(futures);
        ref.read(dataRefreshedAtProvider(livestockId).notifier).mark();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.livestockDetailTitle),
          bottom: DataFreshnessIndicator(refreshedAt: refreshedAt),
          leading: IconButton(
            key: const Key('livestock-back'),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoute.livestockList.path);
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              key: const Key('livestock-detail-edit'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                final detail = asyncData.value;
                if (detail != null) {
                  _showEditForm(context, ref, detail);
                }
              },
            ),
            IconButton(
              key: const Key('livestock-detail-delete'),
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                final detail = asyncData.value;
                if (detail != null) {
                  _showDeleteConfirm(context, ref, detail);
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          key: const Key('page-livestock-detail'),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              asyncData.when(
                data: (detail) => _LivestockDetailBody(detail: detail),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${l10n.commonLoadFailed}: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(
                              livestockDetailControllerProvider(
                                livestockId,
                              ).notifier,
                            )
                            .refresh(),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail column as a stateful body so it can own the [GlobalKey] that
/// scrolls from the DrinkingCard to the drinking detail section (the
/// section lives further down the same scroll view, NIX-256).
class _LivestockDetailBody extends StatefulWidget {
  const _LivestockDetailBody({required this.detail});

  final LivestockDetail detail;

  @override
  State<_LivestockDetailBody> createState() => _LivestockDetailBodyState();
}

class _LivestockDetailBodyState extends State<_LivestockDetailBody> {
  final GlobalKey _drinkingDetailKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final hasCapsule = detail.devices.any(
      (d) => d.type == DeviceType.rumenCapsule,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LivestockInfoCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        _DeviceListCard(detail: detail),
        GatewayDistanceCard(livestockId: detail.livestockId),
        const SizedBox(height: AppSpacing.md),
        _HealthDataCard(detail: detail, drinkingSectionKey: _drinkingDetailKey),
        const SizedBox(height: AppSpacing.md),
        // ── Inline: drinking behavior summary card (NIX-256), same level
        // as the fever trend card; taps scroll to the detail section. ──
        DrinkingCard(
          livestockId: detail.livestockId,
          hasCapsule: hasCapsule,
          onTap: () {
            final ctx = _drinkingDetailKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: 0.0,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Inline: physiology record card (NIX-256) ──
        PhysiologyRecordCard(livestockId: detail.livestockId),
        const SizedBox(height: AppSpacing.md),
        _LocationCard(detail: detail),
      ],
    );
  }
}

class _LivestockInfoCard extends StatelessWidget {
  const _LivestockInfoCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-info-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Long livestock codes (e.g. SL-2024-012) plus the status
              // chip exceed the card width at 390px; ellipsize the code
              // instead of overflowing the row by ~4px.
              Flexible(
                child: Text(
                  detail.livestockCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              HighfiStatusChip(
                label: switch (detail.health) {
                  LivestockHealth.healthy => l10n.livestockHealthHealthy,
                  LivestockHealth.watch => l10n.livestockHealthWatch,
                  LivestockHealth.abnormal => l10n.livestockHealthAbnormal,
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
              _InfoItem(
                label: l10n.livestockBreed,
                value: detail.breed.localizedLabel(l10n),
              ),
              _InfoItem(
                label: l10n.livestockAgeMonthsLabel,
                value: l10n.livestockAgeMonthsValue(detail.ageMonths),
              ),
              _InfoItem(
                label: l10n.livestockWeight,
                value: '${detail.weightKg} kg',
              ),
              _InfoItem(
                label: l10n.livestockFormFieldGender,
                value: _genderLabel(l10n, detail.gender),
              ),
              _InfoItem(
                label: l10n.livestockFormFieldBirthDate,
                value: detail.birthDate != null
                    ? '${detail.birthDate!.year}-${detail.birthDate!.month.toString().padLeft(2, '0')}-${detail.birthDate!.day.toString().padLeft(2, '0')}'
                    : '--',
              ),
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

String _genderLabel(AppLocalizations l10n, String? gender) {
  if (gender == null) return '--';
  return gender.toUpperCase() == 'FEMALE'
      ? l10n.livestockGenderValueFemale
      : l10n.livestockGenderValueMale;
}

class _DeviceListCard extends ConsumerWidget {
  const _DeviceListCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-device-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.livestockBindDevices,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                        DeviceType.earTag => Icons.tag,
                      },
                      color: switch (device.status) {
                        DeviceStatus.online => AppColors.success,
                        DeviceStatus.offline => AppColors.textSecondary,
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
                          if (device.devEui != null &&
                              device.devEui!.isNotEmpty)
                            Text(
                              'DevEUI: ${device.devEui}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                            ),
                          Text(
                            [
                              if (device.batteryPercent != null)
                                l10n.deviceBatteryValue(device.batteryPercent!),
                              if (device.signalStrength != null)
                                l10n.deviceSignalValue(device.signalStrength!),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('livestock-unbind-device-${device.id}'),
                      tooltip: l10n.installUnbind,
                      icon: const Icon(Icons.link_off),
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          _showUnbindConfirm(context, ref, detail, device),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('livestock-bind-device'),
            onPressed: () => _showBindDeviceSheet(context, ref, detail),
            icon: const Icon(Icons.link),
            label: Text(l10n.installBindDevice),
          ),
        ],
      ),
    );
  }
}

void _showBindDeviceSheet(
  BuildContext context,
  WidgetRef ref,
  LivestockDetail detail,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _BindDeviceSheet(livestockId: detail.livestockId),
  ).then((_) {
    ref.invalidate(livestockListControllerProvider);
    ref
        .read(livestockDetailControllerProvider(detail.livestockId).notifier)
        .refresh();
  });
}

void _showUnbindConfirm(
  BuildContext context,
  WidgetRef ref,
  LivestockDetail detail,
  DeviceItem device,
) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.link_off, color: AppColors.warning, size: 48),
      title: Text(l10n.installUnbindConfirmTitle),
      content: Text(l10n.installUnbindConfirmMsg(device.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            _unbindDevice(context, ref, detail, device);
          },
          child: Text(l10n.installUnbind),
        ),
      ],
    ),
  );
}

Future<void> _unbindDevice(
  BuildContext context,
  WidgetRef ref,
  LivestockDetail detail,
  DeviceItem device,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    // Server-side livestockId filter: only this livestock's installations
    // come back, so the lookup stays correct no matter how many devices
    // the farm has bound overall.
    final installations = await ref
        .read(devicesRepositoryProvider)
        .loadInstallations(livestockId: detail.livestockId);
    Installation? installation;
    for (final i in installations) {
      if (i.active && i.deviceId == device.id) {
        installation = i;
        break;
      }
    }
    if (installation == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonLoadFailed)));
      return;
    }
    await ref.read(devicesRepositoryProvider).uninstall(installation.id);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.installUnbindSuccess)),
      );
      ref.invalidate(livestockListControllerProvider);
      ref
          .read(livestockDetailControllerProvider(detail.livestockId).notifier)
          .refresh();
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.commonLoadFailed}: $e')),
    );
  }
}

void _showEditForm(
  BuildContext context,
  WidgetRef ref,
  LivestockDetail detail,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => LivestockFormSheet(
      livestockId: detail.livestockId,
      livestockCode: detail.livestockCode,
      breed: detail.breed,
      gender: detail.gender,
      birthDate: detail.birthDate,
      weight: detail.weightKg,
    ),
  ).then((_) {
    ref.invalidate(livestockListControllerProvider);
    ref
        .read(livestockDetailControllerProvider(detail.livestockId).notifier)
        .refresh();
  });
}

void _showDeleteConfirm(
  BuildContext context,
  WidgetRef ref,
  LivestockDetail detail,
) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.warning,
        size: 48,
      ),
      title: Text(l10n.livestockDeleteConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.livestockDeleteConfirmMsg),
          if (detail.devices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...detail.devices.map(
              (d) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_off,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.livestockDeleteDeviceUnbind(d.name),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.archive_outlined,
                size: 14,
                color: AppColors.info,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.livestockDeleteArchiveNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await ref
                  .read(livestockRepositoryProvider)
                  .delete(detail.livestockId);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.livestockDeleted)));
                ref.invalidate(livestockListControllerProvider);
                context.go(AppRoute.livestockList.path);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.commonLoadFailed}: $e')),
                );
              }
            }
          },
          child: Text(l10n.commonConfirm),
        ),
      ],
    ),
  );
}

class _BindDeviceSheet extends ConsumerStatefulWidget {
  const _BindDeviceSheet({required this.livestockId});
  final String livestockId;

  @override
  ConsumerState<_BindDeviceSheet> createState() => _BindDeviceSheetState();
}

class _BindDeviceSheetState extends ConsumerState<_BindDeviceSheet> {
  static const _pageSize = 20;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  final List<DeviceItem> _devices = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _devices.clear();
      _page = 0;
      _hasMore = true;
      _loading = true;
    });
    await _loadPage();
  }

  Future<void> _loadPage() async {
    if (_loadingMore) return;
    final isInitial = _page == 0;
    if (!isInitial) setState(() => _loadingMore = true);
    try {
      final keyword = _searchCtrl.text.trim();
      final data = await ref
          .read(devicesRepositoryProvider)
          .loadDevices(
            page: _page + 1,
            pageSize: _pageSize,
            keyword: keyword.isNotEmpty ? keyword : null,
            unboundOnly: true,
          );
      // Conflict rule kept client-side: one device per type per livestock.
      // Unbound filtering itself is done server-side (unboundOnly=true).
      final detailVal = ref
          .read(livestockDetailControllerProvider(widget.livestockId))
          .value;
      final boundTypes = <DeviceType>{
        for (final d in detailVal?.devices ?? const <DeviceItem>[]) d.type,
      };
      if (!mounted) return;
      setState(() {
        _page += 1;
        _devices.addAll(data.items.where((d) => !boundTypes.contains(d.type)));
        _hasMore = data.items.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
      _maybeAutoFill();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  /// A page can come back full from the server yet shrink to almost nothing
  /// after the client-side type-conflict filter, leaving the list without a
  /// scrollable area — scroll-triggered pagination then never fires and the
  /// footer spinner spins forever. Keep fetching in that case until the
  /// viewport is scrollable or the server runs out of pages.
  void _maybeAutoFill() {
    if (!_hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || _loading || _loadingMore) return;
      final hasScrollSpace =
          _scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent > 0;
      if (!hasScrollSpace) _loadPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyword = _searchCtrl.text.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.installSelectDevice,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('bind-device-search'),
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.installSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _reload();
                        },
                      ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              Center(
                child: Text(
                  keyword.isNotEmpty
                      ? l10n.installNoSearchMatch
                      : l10n.installNoAvailableDevices,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  shrinkWrap: true,
                  itemCount: _devices.length + (_hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= _devices.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final d = _devices[i];
                    return ListTile(
                      key: Key('bind-device-${d.id}'),
                      leading: Icon(switch (d.type) {
                        DeviceType.gps => Icons.gps_fixed,
                        DeviceType.rumenCapsule => Icons.medication,
                        DeviceType.earTag => Icons.tag,
                      }),
                      title: Text(d.name),
                      subtitle: Text(d.type.localizedLabel(l10n)),
                      onTap: () => _install(d),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _install(DeviceItem device) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ApiClient.instance.farmPost(
        '/installations',
        body: {'deviceId': device.id, 'livestockId': widget.livestockId},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.installSuccess)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _HealthDataCard extends ConsumerWidget {
  const _HealthDataCard({required this.detail, this.drinkingSectionKey});

  final LivestockDetail detail;

  /// Key of the drinking detail section so the DrinkingCard can scroll
  /// to it (NIX-256).
  final Key? drinkingSectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;

    return HighfiCard(
      key: const Key('livestock-health-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.livestockHealthData,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InfoItem(
                label: l10n.livestockBodyTemp,
                value: '${detail.bodyTemp.toStringAsFixed(1)}°C',
              ),
              _InfoItem(
                label: l10n.livestockActivity,
                value: activityStatusLabel(l10n, detail.activityLevel),
              ),
              _InfoItem(
                label: l10n.livestockRumination,
                value: double.tryParse(detail.ruminationFreq) != null
                    ? l10n.livestockRuminationValue(detail.ruminationFreq)
                    : detail.ruminationFreq,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Mark-diseased entry (two states, spec §5.2 entry ①) ──
          MarkDiseasedEntryRow(detail: detail),
          const SizedBox(height: AppSpacing.md),
          // ── Inline: temperature trend chart ──
          _FeverTrendSection(livestockId: detail.livestockId),
          const SizedBox(height: AppSpacing.md),
          // ── Inline: rumen motility trend chart ──
          _DigestiveTrendSection(livestockId: detail.livestockId),
          const SizedBox(height: AppSpacing.md),
          // ── Inline: estrus score trend chart (Premium+) ──
          _EstrusTrendSection(livestockId: detail.livestockId, tier: tier),
          const SizedBox(height: AppSpacing.md),
          DrinkingDetailSection(
            key: drinkingSectionKey,
            livestockId: detail.livestockId,
          ),
        ],
      ),
    );
  }
}

/// Temperature trend chart with the drinking layer chips (NIX-256,
/// prototype screen 4): the existing fever LineChart gains three
/// toggleable overlay layers — fever marks / drinking events / baseline —
/// all on by default (F2).
///
/// Layer notes:
/// - Drinking layer: valley dots (r4 --drinking-event, white stroke 1.5)
///   as a dot-only second series aligned to the temperature index axis;
///   same dot style as the 48h overlay chart.
/// - Fever layer: the existing chart has no fever-window annotation and
///   the wire data has no time-granular fever windows, so this chip
///   toggles threshold-exceeded point markers (temperature ≥
///   fever.threshold) — a documented degradation from the prototype's
///   fever shadow region.
/// - Baseline layer: the existing per-cow baseline dashed line.
class _FeverTrendSection extends ConsumerStatefulWidget {
  const _FeverTrendSection({required this.livestockId});
  final String livestockId;

  @override
  ConsumerState<_FeverTrendSection> createState() => _FeverTrendSectionState();
}

class _FeverTrendSectionState extends ConsumerState<_FeverTrendSection> {
  bool _feverLayer = true;
  bool _drinkingLayer = true;
  bool _baselineLayer = true;

  /// Interpolated x index of [t] on the readings index axis, or null when
  /// outside the covered time span (valley dots then simply don't render).
  static double? _interpolatedIndex(
    List<TemperatureRecord> readings,
    DateTime t,
  ) {
    if (readings.isEmpty) return null;
    if (t.isBefore(readings.first.timestamp) ||
        t.isAfter(readings.last.timestamp)) {
      return null;
    }
    for (var i = 0; i < readings.length - 1; i++) {
      final a = readings[i].timestamp;
      final b = readings[i + 1].timestamp;
      if (!t.isBefore(a) && !t.isAfter(b)) {
        final span = b.difference(a).inMilliseconds;
        if (span <= 0) return i.toDouble();
        return i + t.difference(a).inMilliseconds / span;
      }
    }
    return (readings.length - 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final livestockId = widget.livestockId;
    final asyncFever = ref.watch(feverDetailControllerProvider(livestockId));

    return asyncFever.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 180,
        child: Center(child: Text(l10n.feverLoadFailed)),
      ),
      data: (fever) {
        final readings = fever.recent72h;
        if (readings.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                l10n.feverNoRecords,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        final spots = readings
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
            .toList();
        final timestamps = readings
            .map((reading) => reading.timestamp)
            .toList();
        // Drinking valleys inside the covered span (§15.3 counted rule),
        // aligned to the index axis.
        final valleySpots = _drinkingLayer
            ? ref
                  .watch(drinkingEventsControllerProvider(livestockId))
                  .maybeWhen(
                    data: (events) => events
                        .where(
                          (e) =>
                              e.label != DrinkingLabel.rejected &&
                              (!e.isCandidate ||
                                  e.label == DrinkingLabel.confirmed) &&
                              e.minTemp != null,
                        )
                        .map((e) {
                          final x = _interpolatedIndex(
                            readings,
                            e.eventStartAt,
                          );
                          return x == null ? null : FlSpot(x, e.minTemp!);
                        })
                        .whereType<FlSpot>()
                        .toList(),
                    orElse: () => const <FlSpot>[],
                  )
            : const <FlSpot>[];

        var minTemp =
            readings.map((r) => r.temperature).reduce((a, b) => a < b ? a : b) -
            0.3;
        var maxTemp =
            readings.map((r) => r.temperature).reduce((a, b) => a > b ? a : b) +
            0.3;
        for (final spot in valleySpots) {
          minTemp = minTemp < spot.y ? minTemp : spot.y - 0.1;
          maxTemp = maxTemp > spot.y ? maxTemp : spot.y + 0.1;
        }

        final latestPoint = readings.last.timestamp;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.feverDetailChartTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.latestDataAt(formatMdhm(latestPoint)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChartReadout(
                timestamps: timestamps,
                formatValue: (value) => '${value.toStringAsFixed(1)}°C',
                chartDataBuilder: (touchData) => LineChartData(
                  lineTouchData: touchData,
                  minY: minTemp,
                  maxY: maxTemp,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: temperatureAxisTitles(
                      minY: minTemp,
                      maxY: maxTemp,
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.danger,
                      barWidth: 2,
                      // Fever layer: threshold-exceeded point markers
                      // (degraded from the prototype's fever shadow
                      // region — no time-granular windows on the wire).
                      dotData: _feverLayer
                          ? FlDotData(
                              show: true,
                              checkToShowDot: (spot, _) =>
                                  spot.y >= fever.threshold,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                color: AppColors.fever,
                                radius: 3,
                                strokeColor: Colors.white,
                                strokeWidth: 1,
                              ),
                            )
                          : const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.danger.withValues(alpha: 0.3),
                            AppColors.danger.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    if (_baselineLayer)
                      LineChartBarData(
                        spots: [
                          FlSpot(0, fever.baselineTemp),
                          FlSpot(
                            (readings.length - 1).toDouble(),
                            fever.baselineTemp,
                          ),
                        ],
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                        dashArray: const [4, 4],
                        barWidth: 1,
                        dotData: const FlDotData(show: false),
                      ),
                    // Drinking layer: valley dots as a dot-only series.
                    if (valleySpots.isNotEmpty)
                      LineChartBarData(
                        spots: valleySpots,
                        color: AppColors.drinkingEvent,
                        barWidth: 0,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            color: AppColors.drinkingEvent,
                            radius: 4,
                            strokeColor: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chartLegend(AppColors.danger, l10n.feverLegendActual),
                const SizedBox(width: 12),
                _chartLegend(
                  AppColors.textSecondary.withValues(alpha: 0.4),
                  l10n.feverLegendBaseline,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // layer-chips row (prototype screen 4): three toggles, all on
            // by default.
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _LayerChip(
                  key: const Key('drinking-layer-fever'),
                  label: l10n.healthDrinkingLayerFever,
                  swatch: AppColors.fever,
                  on: _feverLayer,
                  onTap: () => setState(() => _feverLayer = !_feverLayer),
                ),
                _LayerChip(
                  key: const Key('drinking-layer-drinking'),
                  label: l10n.healthDrinkingLayerDrinking,
                  swatch: AppColors.drinkingEvent,
                  on: _drinkingLayer,
                  onTap: () => setState(() => _drinkingLayer = !_drinkingLayer),
                ),
                _LayerChip(
                  key: const Key('drinking-layer-baseline'),
                  label: l10n.healthDrinkingLayerBaseline,
                  swatch: AppColors.textSecondary,
                  on: _baselineLayer,
                  onTap: () =>
                      setState(() => _baselineLayer = !_baselineLayer),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// One layer-chip (prototype screen 4): fs9 fw700, r999, padding 3×8,
/// 7×7 round swatch; on → text-primary + border --drinking, off →
/// secondary + border --border.
class _LayerChip extends StatelessWidget {
  const _LayerChip({
    super.key,
    required this.label,
    required this.swatch,
    required this.on,
    required this.onTap,
  });

  final String label;
  final Color swatch;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on ? AppColors.drinking : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: on ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigestiveTrendSection extends ConsumerWidget {
  const _DigestiveTrendSection({required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDigestive = ref.watch(
      digestiveDetailControllerProvider(livestockId),
    );

    return asyncDigestive.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 180,
        child: Center(child: Text(l10n.digestiveLoadFailed)),
      ),
      data: (digestive) {
        final readings = digestive.recent24h
            .where((reading) => reading.frequency != null)
            .toList();
        if (readings.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                l10n.digestiveNoRecords,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        final spots = readings
            .asMap()
            .entries
            .map(
              (entry) => FlSpot(entry.key.toDouble(), entry.value.frequency!),
            )
            .toList();
        final timestamps = readings
            .map((reading) => reading.timestamp)
            .toList();
        final minFrequency =
            readings
                .map((reading) => reading.frequency!)
                .reduce((a, b) => a < b ? a : b) -
            0.5;
        final maxFrequency =
            readings
                .map((reading) => reading.frequency!)
                .reduce((a, b) => a > b ? a : b) +
            0.5;
        final baseline = digestive.motilityBaseline;

        final latestPoint = readings.last.timestamp;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.digestiveDetailChartTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.latestDataAt(formatMdhm(latestPoint)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChartReadout(
                timestamps: timestamps,
                formatValue: (value) => value.toStringAsFixed(1),
                chartDataBuilder: (touchData) => LineChartData(
                  lineTouchData: touchData,
                  minY: minFrequency,
                  maxY: maxFrequency,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: [
                        FlSpot(0, baseline),
                        FlSpot((readings.length - 1).toDouble(), baseline),
                      ],
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                      dashArray: const [4, 4],
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chartLegend(AppColors.primary, l10n.digestiveLegendActual),
                const SizedBox(width: 12),
                _chartLegend(
                  AppColors.textSecondary.withValues(alpha: 0.4),
                  l10n.digestiveLegendBaseline,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EstrusTrendSection extends ConsumerWidget {
  const _EstrusTrendSection({required this.livestockId, required this.tier});
  final String livestockId;
  final SubscriptionTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasEstrusDetect = checkTierAccess(tier, FeatureFlags.estrusDetect);

    if (!hasEstrusDetect) {
      return LockedOverlay(
        locked: true,
        upgradeTier: 'premium',
        onUpgrade: () => context.go(AppRoute.subscription.path),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💕 ${l10n.estrusDetailChartTitle}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 160,
                child: Center(
                  child: Icon(
                    Icons.favorite_outline,
                    size: 40,
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final asyncEstrus = ref.watch(estrusDetailControllerProvider(livestockId));

    return asyncEstrus.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 180,
        child: Center(child: Text(l10n.estrusLoadFailed)),
      ),
      data: (estrus) {
        final trend = estrus.trend7d;
        if (trend.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                l10n.estrusNoScores,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }
        final spots = trend
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.score))
            .toList();
        final timestamps = trend.map((point) => point.timestamp).toList();

        final latestPoint = trend.last.timestamp;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.estrusDetailChartTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.latestDataAt(formatMdhm(latestPoint)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LineChartReadout(
                timestamps: timestamps,
                formatValue: (value) => value.toInt().toString(),
                chartDataBuilder: (touchData) => LineChartData(
                  lineTouchData: touchData,
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 70,
                        color: AppColors.warning.withValues(alpha: 0.5),
                        dashArray: const [4, 4],
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.estrus,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chartLegend(AppColors.estrus, l10n.estrusLegendScore),
                const SizedBox(width: 12),
                _chartLegend(
                  AppColors.warning.withValues(alpha: 0.5),
                  l10n.estrusLegendThreshold,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-location-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.livestockLocation,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.livestockLastLocation(detail.lastLocation),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (detail.lastPositionAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.dataUpdatedAt(formatMdhm(detail.lastPositionAt!)),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('livestock-view-track'),
            onPressed: () => showTrajectorySheet(
              context,
              detail.livestockId,
              livestockCode: detail.livestockCode,
              breedLabel: detail.breed.localizedLabel(l10n),
              deviceName: detail.devices.isNotEmpty
                  ? detail.devices.first.name
                  : null,
            ),
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.livestockViewTrajectory),
          ),
        ],
      ),
    );
  }
}

Widget _chartLegend(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}
