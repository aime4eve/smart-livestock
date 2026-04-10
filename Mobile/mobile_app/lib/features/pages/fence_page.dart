import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

class FencePage extends ConsumerStatefulWidget {
  const FencePage({super.key});

  @override
  ConsumerState<FencePage> createState() => _FencePageState();
}

class _FencePageState extends ConsumerState<FencePage> {
  final _mapController = MapController();
  bool _panelOpen = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fenceState = ref.watch(fenceControllerProvider);
    final controller = ref.read(fenceControllerProvider.notifier);
    final role = ref.watch(sessionControllerProvider).role!;
    final canManage = RolePermission.canEditFence(role);

    return Scaffold(
      key: const Key('page-fence'),
      appBar: AppBar(title: const Text(MockConfig.ranchName)),
      body: _buildBody(context, fenceState, controller, canManage),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
  ) {
    switch (fenceState.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
      case ViewState.forbidden:
      case ViewState.offline:
        return Center(
          child: Text(
            fenceState.message ?? '围栏不可用',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      case ViewState.normal:
      case ViewState.empty:
        return _buildMapWithDrawer(context, fenceState, controller, canManage);
    }
  }

  Widget _buildMapWithDrawer(
    BuildContext context,
    FenceState fenceState,
    FenceController controller,
    bool canManage,
  ) {
    const panelAnimDuration = Duration(milliseconds: 280);
    const panelCurve = Curves.easeOutCubic;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelW = min(300.0, constraints.maxWidth * 0.82);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: DemoSeed.mapCenter,
                  initialZoom: DemoSeed.defaultZoom,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrlTemplate,
                    userAgentPackageName: 'com.smartlivestock.demo',
                    maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                  ),
                  PolygonLayer(
                    polygons: fenceState.fences.map((fence) {
                      final color = Color(fence.colorValue);
                      final selected = fence.id == fenceState.selectedFenceId;
                      return Polygon(
                        points: fence.points,
                        color: color.withValues(alpha: selected ? 0.4 : 0.2),
                        borderColor: color,
                        borderStrokeWidth: selected ? 3.5 : 2.0,
                      );
                    }).toList(),
                  ),
                  MarkerLayer(
                    markers: [
                      for (int i = 0;
                          i < DemoSeed.livestockLocations.length;
                          i++)
                        Marker(
                          point: DemoSeed.livestockLocations[i].toLatLng(),
                          width: 56,
                          height: 56,
                          child: _MapMarker(
                            label: DemoSeed
                                .earTags[i < DemoSeed.earTags.length ? i : 0],
                            isAlert: i == 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: panelAnimDuration,
              curve: panelCurve,
              left: _panelOpen ? 0 : -panelW,
              top: 0,
              bottom: 0,
              width: panelW,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black38,
                color: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppSpacing.lg),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  right: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '牧场 (${fenceState.fences.length})',
                              key: const Key('fence-drawer-title'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (canManage)
                              IconButton(
                                key: const Key('fence-add'),
                                onPressed: () =>
                                    context.push(AppRoute.fenceForm.path),
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: '新建围栏',
                              ),
                          ],
                        ),
                        if (fenceState.fences.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            child: Center(
                              child: Text(
                                '暂无围栏，打开菜单后点 + 创建',
                                key: const Key('fence-empty-hint'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          for (final fence in fenceState.fences)
                            _FenceCard(
                              fence: fence,
                              isSelected:
                                  fence.id == fenceState.selectedFenceId,
                              canManage: canManage,
                              onTap: () {
                                controller.select(fence.id);
                                _mapController.move(
                                  _fenceCenter(fence.points),
                                  16.0,
                                );
                                setState(() => _panelOpen = false);
                              },
                              onEdit: () => context.push(
                                '${AppRoute.fenceForm.path}?id=${fence.id}',
                              ),
                              onDelete: () => _showDeleteDialog(
                                  context, fence, controller),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: panelAnimDuration,
              curve: panelCurve,
              left: _panelOpen ? panelW + 12 : 12,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: FloatingActionButton.small(
                  key: const Key('fence-panel-toggle'),
                  heroTag: 'fence-panel-toggle',
                  onPressed: () =>
                      setState(() => _panelOpen = !_panelOpen),
                  tooltip: _panelOpen ? '收起牧场列表' : '牧场列表',
                  child: Icon(_panelOpen ? Icons.chevron_left : Icons.menu),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  LatLng _fenceCenter(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  void _showDeleteDialog(
    BuildContext context,
    FenceItem fence,
    FenceController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除「${fence.name}」？删除后无法恢复。'),
        actions: [
          TextButton(
            key: const Key('fence-delete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('fence-delete-confirm'),
            onPressed: () {
              controller.delete(fence.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('已删除「${fence.name}」')),
                );
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _FenceCard extends StatelessWidget {
  const _FenceCard({
    required this.fence,
    required this.isSelected,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FenceItem fence;
  final bool isSelected;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('fence-card-${fence.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: isSelected
            ? BorderSide(color: Color(fence.colorValue), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(fence.colorValue),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fence.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatusLabel(active: fence.active),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${fence.livestockCount}头',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage) ...[
                IconButton(
                  key: Key('fence-edit-${fence.id}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: Key('fence-delete-${fence.id}'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? '启用' : '停用',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? AppColors.success : AppColors.textSecondary,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, this.isAlert = false});

  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? AppColors.danger : AppColors.success;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
