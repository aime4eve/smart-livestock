import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/mock/mock_scenarios.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';
import 'package:smart_livestock_demo/features/map/presentation/map_controller.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(mapControllerProvider);
    final controller = ref.read(mapControllerProvider.notifier);
    return SingleChildScrollView(
      key: const Key('page-map'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapToolbar(),
          const SizedBox(height: AppSpacing.md),
          _MapControlPanel(
            data: data,
            onAnimalChanged: controller.selectAnimal,
            onRangeChanged: controller.selectRange,
          ),
          const SizedBox(height: 16),
          _buildMapBody(context, data),
        ],
      ),
    );
  }

  Widget _buildMapBody(BuildContext context, MapViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无定位数据',
          description: '当前没有可渲染的牲畜定位点位。',
          icon: Icons.location_off_outlined,
        );
      case ViewState.error:
        return HighfiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HighfiStatusChip(
                label: '地图不可用，已切换列表回退',
                color: AppColors.warning,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              ListView(
                key: const Key('map-fallback-list'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final item in data.fallbackItems)
                    ListTile(
                        contentPadding: EdgeInsets.zero, title: Text(item)),
                ],
              ),
            ],
          ),
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '暂无地图权限',
          description: data.message ?? '当前角色不可查看地图与围栏图层。',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighfiStatusChip.fromViewState(viewState: ViewState.offline),
              const SizedBox(height: AppSpacing.md),
              Text(
                MockScenarios.offlineFence.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case ViewState.normal:
        return HighfiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                MockScenarios.virtualFenceCanvas.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                MockScenarios.virtualFenceCanvas.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _RealMapView(data: data),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data.summaryText,
                key: const Key('map-flow-summary'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final layer in MockConfig.mapLayers)
                    HighfiStatusChip(
                      key: layer == '围栏'
                          ? const Key('map-layer-fence-toggle')
                          : null,
                      label: '$layer图层',
                      color: switch (layer) {
                        '围栏' => AppColors.primary,
                        '牲畜' => AppColors.info,
                        '告警' => AppColors.warning,
                        '轨迹' => AppColors.accent,
                        _ => AppColors.textSecondary,
                      },
                      icon: switch (layer) {
                        '围栏' => Icons.layers_outlined,
                        '牲畜' => Icons.pets_outlined,
                        '告警' => Icons.notification_important_outlined,
                        '轨迹' => Icons.route_outlined,
                        _ => Icons.radio_button_checked,
                      },
                    ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _RealMapView extends StatelessWidget {
  const _RealMapView({required this.data});

  final MapViewData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: data.mapCenter,
            initialZoom: data.zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: 'com.smartlivestock.demo',
              maxZoom: MapConfig.cacheMaxZoom.toDouble(),
            ),
            // Fence polygons
            PolygonLayer(
              polygons: data.fences.map((fence) {
                final color = Color(fence.colorValue);
                return Polygon(
                  points: fence.points,
                  color: color.withValues(alpha: 0.2),
                  borderColor: color,
                  borderStrokeWidth: 2.0,
                );
              }).toList(),
            ),
            // Trajectory polyline
            PolylineLayer(
              polylines: [
                if (data.trajectoryPoints.isNotEmpty)
                  Polyline(
                    points: data.trajectoryPoints.map((p) => p.toLatLng()).toList(),
                    color: AppColors.accent,
                    strokeWidth: 3.0,
                    pattern: StrokePattern.dashed(segments: [10, 6]),
                  ),
              ],
            ),
            // Livestock markers
            MarkerLayer(
              markers: [
                for (int i = 0; i < data.livestockLocations.length; i++)
                  Marker(
                    point: data.livestockLocations[i].toLatLng(),
                    width: 56,
                    height: 56,
                    child: _MapMarker(
                      label: DemoSeed.earTags[i < DemoSeed.earTags.length ? i : 0],
                      isAlert: i == 0,
                    ),
                  ),
              ],
            ),
          ],
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
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 14,
            ),
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

class _MapToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton.icon(
            key: const Key('map-toolbar-select'),
            onPressed: () {},
            icon: const Icon(Icons.ads_click_outlined),
            label: const Text('选择'),
          ),
          FilledButton.tonalIcon(
            key: const Key('map-toolbar-draw-fence'),
            onPressed: () {},
            icon: const Icon(Icons.draw_outlined),
            label: const Text('绘制围栏'),
          ),
          OutlinedButton.icon(
            key: const Key('map-toolbar-edit-fence'),
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑'),
          ),
          OutlinedButton.icon(
            key: const Key('map-toolbar-delete-fence'),
            onPressed: () {},
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
          OutlinedButton.icon(
            key: const Key('map-toolbar-measure'),
            onPressed: () {},
            icon: const Icon(Icons.straighten_outlined),
            label: const Text('测量'),
          ),
        ],
      ),
    );
  }
}

class _MapControlPanel extends StatelessWidget {
  const _MapControlPanel({
    required this.data,
    required this.onAnimalChanged,
    required this.onRangeChanged,
  });

  final MapViewData data;
  final ValueChanged<String> onAnimalChanged;
  final ValueChanged<TrajectoryRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MockConfig.ranchName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('牲畜筛选'),
              const SizedBox(width: 12),
              KeyedSubtree(
                key: const Key('map-livestock-filter'),
                child: DropdownButton<String>(
                  key: const Key('map-animal-filter'),
                  value: data.selectedAnimal,
                  items: [
                    for (final tag in data.availableAnimals)
                      DropdownMenuItem(value: tag, child: Text(tag)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onAnimalChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<TrajectoryRange>(
            key: const Key('map-range-toggle'),
            segments: const [
              ButtonSegment(value: TrajectoryRange.h24, label: Text('24h')),
              ButtonSegment(value: TrajectoryRange.d7, label: Text('7d')),
              ButtonSegment(value: TrajectoryRange.d30, label: Text('30d')),
            ],
            selected: {data.selectedRange},
            onSelectionChanged: (selection) {
              onRangeChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}
