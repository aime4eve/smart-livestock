import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/tile_auto_trigger.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/domain/b2b_worker_management_repository.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/presentation/b2b_worker_management_controller.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/presentation/widgets/async_fallback_views.dart';

// ═══════════════════════════════════════════════════════════════
//  B2B Worker Detail Page — map + fences + offline tiles
// ═══════════════════════════════════════════════════════════════

class B2bWorkerDetailPage extends ConsumerStatefulWidget {
  const B2bWorkerDetailPage({super.key, required this.farmId});

  final String farmId;

  @override
  ConsumerState<B2bWorkerDetailPage> createState() =>
      _B2bWorkerDetailPageState();
}

class _B2bWorkerDetailPageState extends ConsumerState<B2bWorkerDetailPage> {
  List<B2bSubFarmWorker> _workers = [];
  List<Map<String, dynamic>> _fences = [];
  LatLng? _farmCenter;
  bool _busy = false;
  bool _mapLoaded = false;

  // Tile state

  SmartTileProvider? _tileProvider;
  List<Map<String, dynamic>> _tileRegions = [];
  int _tabIndex = 0;
  final _mapKey = GlobalKey<_MapPreviewState>();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _showEditFarmDialog(B2bSubFarm farm) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: farm.name);
    final latCtrl = TextEditingController(text: farm.latitude?.toStringAsFixed(6) ?? '');
    final lngCtrl = TextEditingController(text: farm.longitude?.toStringAsFixed(6) ?? '');
    final areaCtrl = TextEditingController(text: farm.areaHectares?.toStringAsFixed(1) ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.b2bWorkerEditFarmInfo),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.farmCreationNameLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '名称不能为空' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.farmCreationLatLabel,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.farmCreationLngLabel,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: areaCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.farmCreationAreaLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final body = <String, dynamic>{
                'name': nameCtrl.text.trim(),
                if (latCtrl.text.isNotEmpty) 'latitude': double.tryParse(latCtrl.text),
                if (lngCtrl.text.isNotEmpty) 'longitude': double.tryParse(lngCtrl.text),
                if (areaCtrl.text.isNotEmpty) 'areaHectares': double.tryParse(areaCtrl.text),
              };
              try {
                await ApiClient.instance.put('/farms/${farm.id}', body: body);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.b2bWorkerFarmUpdated), backgroundColor: const Color(0xFF2E7D32)),
                  );
                  ref.invalidate(b2bDashboardControllerProvider);
                  ref.invalidate(b2bWorkerManagementControllerProvider);
                  _loadAll();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('更新失败: \$e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadWorkers(),
      _loadMapData(),
    ]);
  }

  Future<void> _loadWorkers() async {
    final workers = await ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .getSubFarmWorkers(widget.farmId);
    if (mounted) setState(() => _workers = workers);
  }

  Future<void> _loadMapData() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.farmGet('/map/overview', farmId: widget.farmId),
        ApiClient.instance.get('/farms/${widget.farmId}'),
        _safeCall(() =>
            ApiClient.instance.farmGet('/tile-source', farmId: widget.farmId)),
        _safeCall(() =>
            ApiClient.instance.farmGet('/tile-status', farmId: widget.farmId)),
      ]);

      final mapData = results[0] as Map<String, dynamic>;
      final farmData = results[1] as Map<String, dynamic>;
      final tileSourceData = results[2];
      final tileStatusData = results[3];

      // Parse fences
      final fenceList = (mapData['fences'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [];

      // Parse farm center
      final lat = (farmData['latitude'] as num?)?.toDouble();
      final lng = (farmData['longitude'] as num?)?.toDouble();
      final center = (lat != null && lng != null) ? LatLng(lat, lng) : null;

      // Parse tile source URL
      String? resolvedUrl;
      if (tileSourceData != null) {
        final sources = tileSourceData['value'] as List?;
        if (sources != null && sources.isNotEmpty) {
          resolvedUrl = (sources.first as Map<String, dynamic>)['tileUrl'] as String?;
        }
      }

      // P3 块2：缺自建 region 时自动触发下载任务（fire-and-forget，不阻塞渲染）
      if (resolvedUrl == null && center != null) {
        TileAutoTrigger.triggerIfMissing(
          farmKey: 'farm-${widget.farmId}',
          centerLon: center.longitude,
          centerLat: center.latitude,
        );
      }

      // Parse tile status regions
      List<Map<String, dynamic>> regions = [];
      if (tileStatusData != null) {
        final regionList = tileStatusData['regions'] as List?;
        if (regionList != null) {
          regions = regionList.whereType<Map<String, dynamic>>().toList();
        }
      }

      // Initialize SmartTileProvider
      final tileProvider = await loadSmartTileProvider(
        ref,
        onSourceChanged: () { if (mounted) setState(() {}); },
      );
      // Set tile coverage bounds to suppress 404 for out-of-range tiles
      // changsha-demo covers [112.8, 28.1, 113.1, 28.4]

      if (mounted) {
        setState(() {
          _fences = fenceList;
          _farmCenter = center;
          _mapLoaded = true;

          _tileProvider = tileProvider;
          _tileRegions = regions;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mapLoaded = true);
    }
  }

  Future<Map<String, dynamic>?> _safeCall(
      Future<Map<String, dynamic>> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(b2bWorkerManagementControllerProvider);

    return asyncData.when(
      data: (data) {
        final farm =
            data.subFarms.where((f) => f.id == widget.farmId).firstOrNull;
        if (farm == null) {
          return const Scaffold(
              body: B2bEmptyView(key: Key('b2b-worker-detail-not-found')));
        }
        return _buildContent(context, farm);
      },
      loading: () => const Scaffold(
          body: Center(
            key: Key('b2b-worker-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        ),
      error: (e, _) => Scaffold(
          body: B2bErrorView(
            key: const Key('b2b-worker-detail-error'),
            message: e.toString(),
          ),
        ),
    );
  }

  Widget _buildContent(BuildContext context, B2bSubFarm farm) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          key: const Key('page-b2b-worker-detail'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BreadcrumbBar(
                key: const Key('b2b-worker-detail-breadcrumb'),
                farmName: farm.name,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: AppSpacing.md),

              _FarmStatsCard(farm: farm),
              const SizedBox(height: AppSpacing.lg),

              // ── Tab bar ──
              _SegmentedTabBar(
                tabs: const ['地图与围栏', '牧工'],
                selectedIndex: _tabIndex,
                onSelected: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Tab content ──
              if (_tabIndex == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _SectionHeader(
                        title: '地图与围栏',
                        trailing: '${_fences.length} 个围栏',
                      ),
                    ),
                    IconButton(
                      key: const Key('edit-farm-info'),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: '编辑牧场信息',
                      onPressed: () => _showEditFarmDialog(farm),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapPreview(
                  key: _mapKey,
                  farmCenter: _farmCenter,
                  fences: _fences,
                  loaded: _mapLoaded,
                  tileProvider: _tileProvider,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_tileRegions.isNotEmpty) ...[
                  _TileStatusCard(
                    regions: _tileRegions,
                    farmId: int.tryParse(widget.farmId) ?? 0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_fences.isNotEmpty)
                  _FenceChips(fences: _fences, onFenceTap: (f) => _mapKey.currentState?.flyToFence(f)),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(
                      title: '牧工',
                      trailing: '${_workers.length} 人',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _busy ? null : () => _handleCreateWorker(farm),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l10n.workerAddWorker),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        TextButton.icon(
                          onPressed: _busy ? null : () => _handleAssign(farm),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: Text(l10n.b2bWorkerAssign),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_workers.isEmpty)
                  const _EmptyWorkerState(
                    key: Key('b2b-worker-detail-empty-workers'),
                  )
                else
                  ..._workers.map((worker) => _WorkerCard(
                        key: Key('b2b-worker-${worker.id}'),
                        worker: worker,
                        farmName: farm.name,
                        isBusy: _busy,
                        onTap: () => _handleEditWorker(worker),
                        onRemove: _busy ? null : () => _handleRemove(worker, farm),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }


  // ── Create Worker ─────────────────────────────────────────

  Future<void> _handleCreateWorker(B2bSubFarm farm) async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('b2b-create-worker-dialog'),
        title: Text(l10n.workerNewWorker),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '请输入姓名' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入手机号';
                    if (v.trim().length < 11) return '手机号格式不正确';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.authPasswordLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入密码';
                    if (v.trim().length < 3) return '密码至少3位';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '创建后将自动分配到「${farm.name}」',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.adminApiAuthCreate),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final notifier = ref.read(b2bWorkerManagementControllerProvider.notifier);
      final worker = await notifier.createWorker(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );
      // Auto-assign to current farm
      await notifier.assignWorker(farm.id, worker.id);
      await _loadWorkers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.b2bWorkerCreated(worker.name)), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workerCreateFailed(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  // ── Edit Worker ────────────────────────────────────────────

  Future<void> _handleEditWorker(B2bSubFarmWorker worker) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: worker.name);
    final phoneCtrl = TextEditingController(text: worker.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('b2b-edit-worker-dialog'),
        title: Text(worker.name),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '请输入姓名' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入手机号';
                    if (v.trim().length < 11) return '手机号格式不正确';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx, 'reset');
            },
            child: Text(l10n.b2bWorkerResetPwd, style: const TextStyle(color: AppColors.warning)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, 'save');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == 'save') {
      setState(() => _busy = true);
      try {
        await ref.read(b2bWorkerManagementControllerProvider.notifier).updateWorker(
          worker.id,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
        );
        await _loadWorkers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.b2bWorkerUpdated), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
      if (mounted) setState(() => _busy = false);
    } else if (confirmed == 'reset') {
      await _handleResetPassword(worker);
    }
  }

  Future<void> _handleResetPassword(B2bSubFarmWorker worker) async {
    final l10n = AppLocalizations.of(context)!;
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.b2bWorkerResetPwdTitle(worker.name)),
        content: SizedBox(
          width: 300,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordCtrl,
              decoration: InputDecoration(
                labelText: l10n.b2bWorkerNewPassword,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入新密码';
                if (v.trim().length < 3) return '密码至少3位';
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.b2bWorkerConfirmReset),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(b2bWorkerManagementControllerProvider.notifier).resetWorkerPassword(
        worker.id, passwordCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.b2bWorkerPwdReset), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonDeleteFailed(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  // ── Assign / Remove ────────────────────────────────────────

  Future<void> _handleAssign(B2bSubFarm farm) async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() => _busy = true);

    final available = await ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .getAvailableWorkers();

    if (!mounted) return;

    if (available.isEmpty) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.b2bWorkerAssignNone),
          backgroundColor: const Color(0xFF607D8B),
        ),
      );
      return;
    }

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('b2b-assign-worker-dialog'),
          title: Text(l10n.b2bWorkerAssignTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((w) {
                final isSelected = selected.contains(w.id);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(w.name),
                  subtitle: Text(w.role, style: const TextStyle(fontSize: 12)),
                  onChanged: (v) {
                    setDialogState(() {
                      if (v == true) {
                        selected.add(w.id);
                      } else {
                        selected.remove(w.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text(l10n.b2bWorkerAssignConfirm(selected.length.toString())),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selected.isNotEmpty && mounted) {
      final notifier = ref.read(b2bWorkerManagementControllerProvider.notifier);
      for (final wid in selected) {
        await notifier.assignWorker(farm.id, wid);
      }
      await _loadWorkers();
    }

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _handleRemove(
    B2bSubFarmWorker worker, B2bSubFarm farm) async {
    final l10n = AppLocalizations.of(context)!;
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.b2bWorkerRemoveTitle),
        content: Text(l10n.b2bWorkerRemoveConfirm(worker.name, farm.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.b2bWorkerConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .removeWorker(farm.id, worker.id);
    await _loadWorkers();
    if (mounted) setState(() => _busy = false);
  }
}

// ═══════════════════════════════════════════════════════════════
//  Widgets
// ═══════════════════════════════════════════════════════════════

/// ── Breadcrumb ───────────────────────────────────────────────
class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({super.key, required this.farmName, required this.onBack});
  final String farmName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go(AppRoute.b2bAdminFarms.path),
          child: Text(l10n.mineWorkerTitle, style: const TextStyle(fontSize: 14)),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        Text(farmName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

/// ── Farm stats card ─────────────────────────────────────────
class _FarmStatsCard extends StatelessWidget {
  const _FarmStatsCard({required this.farm});
  final B2bSubFarm farm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StatChip(icon: Icons.groups_outlined, value: '${farm.workerCount}', label: '牧工'),
          _StatChip(icon: Icons.pets_outlined, value: '${farm.livestockCount}', label: '牲畜'),
          _StatChip(icon: Icons.sensors_outlined, value: '${farm.deviceCount}', label: '设备'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// ── Section header ──────────────────────────────────────────
/// ── Segmented tab bar ──────────────────────────────────────
class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
                      : [],
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// ── Map preview with SmartTileProvider ─────────────────────
class _MapPreview extends StatefulWidget {
  const _MapPreview({
    super.key,
    required this.farmCenter,
    required this.fences,
    required this.loaded,
    required this.tileProvider,
  });

  final LatLng? farmCenter;
  final List<Map<String, dynamic>> fences;
  final bool loaded;
  final SmartTileProvider? tileProvider;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    final allPoints = _collectAllPoints();
    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(40),
        maxZoom: 16,
      ),
    );
  }

  List<LatLng> _collectAllPoints() {
    final points = <LatLng>[];
    for (final fence in widget.fences) {
      final verts = fence['vertices'] as List<dynamic>? ?? [];
      for (final v in verts.whereType<Map<String, dynamic>>()) {
        final lat = (v['lat'] as num?)?.toDouble() ?? 0;
        final lng = (v['lng'] as num?)?.toDouble() ?? 0;
        if (lat != 0 && lng != 0) points.add(LatLng(lat, lng));
      }
    }
    if (widget.farmCenter != null) points.add(widget.farmCenter!);
    return points;
  }

  void flyToFence(Map<String, dynamic> fence) {
    final verts = fence['vertices'] as List<dynamic>? ?? [];
    final points = verts.whereType<Map<String, dynamic>>().map((v) => LatLng(
      (v['lat'] as num?)?.toDouble() ?? 0,
      (v['lng'] as num?)?.toDouble() ?? 0,
    )).toList();
    if (points.isEmpty) return;
    if (points.length >= 3) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60), maxZoom: 17),
      );
    } else {
      _mapController.move(points.first, 16);
    }
  }

  static int _parseFenceColor(dynamic color) {
    if (color is int) return color;
    if (color is String) {
      final hex = color.replaceFirst("#", "");
      return int.tryParse(hex, radix: 16) ?? 0xFF2196F3;
    }
    return 0xFF2196F3;
  }

  List<Polygon> _buildPolygons(bool shouldTransform) {
    return widget.fences.map((fence) {
      final vertices = fence['vertices'] as List<dynamic>? ?? [];
      final coords = fence['coordinates'] as List<dynamic>? ?? [];

      List<LatLng> points;
      if (coords.isNotEmpty) {
        points = coords.whereType<Map<String, dynamic>>().map((c) => LatLng(
          (c['lat'] as num?)?.toDouble() ?? 0,
          (c['lng'] as num?)?.toDouble() ?? 0,
        )).toList();
      } else {
        points = vertices.whereType<Map<String, dynamic>>().map((v) => LatLng(
          (v['lat'] as num?)?.toDouble() ?? 0,
          (v['lng'] as num?)?.toDouble() ?? 0,
        )).toList();
      }

      if (points.length < 3) return null;
      if (shouldTransform) {
        points = CoordTransform.wgs84ToGcj02All(points);
      }

      final colorValue = _parseFenceColor(fence['color']);
      final fenceType = fence['fenceType'] as String? ?? 'sub';
      final isBoundary = fenceType == 'boundary';

      return Polygon(
        points: points,
        color: isBoundary
            ? const Color(0x1A2196F3)
            : Color(colorValue).withAlpha(40),
        borderColor: isBoundary
            ? const Color(0xFF2196F3)
            : Color(colorValue),
        borderStrokeWidth: isBoundary ? 3.0 : 2.5,
      );
    }).whereType<Polygon>().toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loaded) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final center = widget.farmCenter ?? const LatLng(28.229, 112.938);
    final shouldTransform = widget.tileProvider?.shouldTransformCoordinates() ?? false;
    final polygons = _buildPolygons(shouldTransform);

    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: shouldTransform ? CoordTransform.wgs84ToGcj02(center) : center,
          initialZoom: 14,
          minZoom: 5,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          if (widget.tileProvider != null)
            TileLayer(
              key: ValueKey(widget.tileProvider?.activeSourceName),
              tileProvider: widget.tileProvider,
              maxNativeZoom: 15,
              maxZoom: 18,
              userAgentPackageName: 'com.smartlivestock.app',
            )
          else
            TileLayer(
              urlTemplate: MapConfig.selfHostedTileUrl,
              userAgentPackageName: 'com.smartlivestock.app',
            ),
          PolygonLayer(polygons: polygons),
          if (widget.farmCenter != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: shouldTransform ? CoordTransform.wgs84ToGcj02(widget.farmCenter!) : widget.farmCenter!,
                  width: 24,
                  height: 24,
                  child: const Icon(Icons.agriculture, size: 24, color: AppColors.primary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TileStatusCard extends StatelessWidget {
  const _TileStatusCard({required this.regions, required this.farmId});
  final List<Map<String, dynamic>> regions;
  final int farmId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('离线瓦片',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...regions.map((r) => _TileRegionRow(region: r)),
          if (!kIsWeb) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('开始下载离线瓦片...')),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('下载离线地图'),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '离线下载仅在 App 端可用',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TileRegionRow extends StatelessWidget {
  const _TileRegionRow({required this.region});
  final Map<String, dynamic> region;

  @override
  Widget build(BuildContext context) {
    final name = (region['regionName'] as String?) ?? '未知区域';
    final status = (region['status'] as String?) ?? 'unknown';
    final fileSize = region['fileSize'] as int?;

    final isReady = status == 'ready' || status == 'downloaded';
    final color = isReady ? AppColors.success : AppColors.warning;
    final label = isReady ? '已就绪' : '生成中';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isReady ? Icons.check_circle_outline : Icons.hourglass_bottom,
            size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(name,
              style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          if (fileSize != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text('${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// ── Fence chips ─────────────────────────────────────────────
class _FenceChips extends StatelessWidget {
  const _FenceChips({required this.fences, this.onFenceTap});
  final List<Map<String, dynamic>> fences;
  final ValueChanged<Map<String, dynamic>>? onFenceTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: fences.map((fence) {
        final name = fence['name'] as String? ?? '未命名';
        final fenceType = fence['fenceType'] as String? ?? 'sub';
        final active = fence['active'] as bool? ?? true;
        final isBoundary = fenceType == 'boundary';

        return ActionChip(
          onPressed: () => onFenceTap?.call(fence),
          avatar: Icon(
            isBoundary ? Icons.crop_free : Icons.edit_location_alt_outlined,
            size: 16,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
          label: Text(name),
          labelStyle: TextStyle(
            fontSize: 12,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: isBoundary ? AppColors.primary : AppColors.border,
          ),
          backgroundColor: isBoundary ? AppColors.primarySoft : Colors.white,
        );
      }).toList(),
    );
  }
}

/// ── Worker card ─────────────────────────────────────────────
class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    super.key,
    required this.worker,
    required this.farmName,
    this.isBusy = false,
    this.onTap,
    required this.onRemove,
  });

  final B2bSubFarmWorker worker;
  final String farmName;
  final bool isBusy;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isActive = worker.status == 'active';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_outline, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${worker.role == "OWNER" ? "负责人" : "牧工"}${worker.phone != null ? " · ${worker.phone}" : ""}${worker.assignedAt != null ? " · ${_formatDate(worker.assignedAt!)}" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isActive ? Icons.check_circle : Icons.cancel, size: 14,
                    color: isActive ? AppColors.success : AppColors.warning),
                  const SizedBox(width: 4),
                  Text(isActive ? '在岗' : '离岗',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.success : AppColors.warning)),
                ],
              ),
            ),
            if (worker.role != 'OWNER') ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                key: Key('b2b-remove-worker-${worker.id}'),
                onPressed: isBusy ? null : onRemove,
                icon: const Icon(Icons.person_remove_outlined, size: 20, color: AppColors.danger),
                tooltip: '移除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.substring(0, iso.length > 10 ? 10 : iso.length);
    }
  }
}

/// ── Empty worker state ──────────────────────────────────────
class _EmptyWorkerState extends StatelessWidget {
  const _EmptyWorkerState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_add_outlined, size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            '暂无牧工，点击「添加牧工」创建或「分配」已有牧工',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
