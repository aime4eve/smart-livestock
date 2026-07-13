import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/geo_utils.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Shows a bottom sheet displaying livestock GPS trajectory.
void showTrajectorySheet(BuildContext context, String livestockId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TrajectorySheet(livestockId: livestockId),
  );
}

enum _TimeRange { h24, d7, d30 }

class _TrajectorySheet extends ConsumerStatefulWidget {
  const _TrajectorySheet({required this.livestockId});
  final String livestockId;

  @override
  ConsumerState<_TrajectorySheet> createState() => _TrajectorySheetState();
}

class _TrajectorySheetState extends ConsumerState<_TrajectorySheet> {
  _TimeRange _range = _TimeRange.h24;
  List<Map<String, dynamic>> _points = [];
  bool _loading = true;
  SmartTileProvider? _tileProvider;

  @override
  void initState() {
    super.initState();
    _initTileProvider();
    _load();
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final delta = switch (_range) {
        _TimeRange.h24 => const Duration(hours: 24),
        _TimeRange.d7 => const Duration(days: 7),
        _TimeRange.d30 => const Duration(days: 30),
      };
      final start = now.subtract(delta);
      // Use local time values as-is (no UTC conversion) to match the
      // backend's reportTime-as-UTC storage basis.
      String ts(DateTime dt) =>
          DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute,
                  dt.second, dt.millisecond)
              .toIso8601String();
      final data = await ApiClient.instance.farmGet(
        '/livestock/${widget.livestockId}/gps-logs?startTime=${ts(start)}&endTime=${ts(now)}&pageSize=500',
      );
      final items = data['items'];
      if (mounted) {
        setState(() {
          _points = items is List
              ? items.whereType<Map<String, dynamic>>().toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeRange(_TimeRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.livestockTrajectoryTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              // Time range selector
              Row(
                children: [
                  _rangeButton(l10n.livestockRange24h, _TimeRange.h24),
                  const SizedBox(width: AppSpacing.sm),
                  _rangeButton(l10n.livestockRange7d, _TimeRange.d7),
                  const SizedBox(width: AppSpacing.sm),
                  _rangeButton(l10n.livestockRange30d, _TimeRange.d30),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildContent(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeButton(String label, _TimeRange range) {
    final selected = range == _range;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? AppColors.primary : AppColors.surface,
          foregroundColor: selected ? Colors.white : AppColors.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: () => _changeRange(range),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_points.isEmpty) {
      return Center(child: Text(l10n.livestockTrajectoryEmpty));
    }

    // Parse and downsample GPS points
    final rawPoints = _points
        .map((m) => (
              lat: (m['latitude'] as num?)?.toDouble() ?? 0.0,
              lng: (m['longitude'] as num?)?.toDouble() ?? 0.0,
            ))
        .where((p) => p.lat != 0.0 || p.lng != 0.0)
        .toList();
    final sampled = downsample(rawPoints, 500);
    var latLngs = sampled.map((p) => LatLng(p.lat, p.lng)).toList();
    // Transform WGS-84 GPS points to GCJ-02 when using 高德 fallback tiles
    // so the trajectory aligns with the map.
    final shouldTransform =
        _tileProvider?.shouldTransformCoordinates() ?? false;
    if (shouldTransform) {
      latLngs = CoordTransform.wgs84ToGcj02All(latLngs);
    }
    final distance = totalPathDistance(sampled);
    final bounds = LatLngBounds.fromPoints(latLngs);

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(40),
                ),
              ),
              children: [
                TileLayer(
                  tileProvider: _tileProvider,
                  urlTemplate: '',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: latLngs,
                      color: AppColors.primary,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (latLngs.isNotEmpty)
                      Marker(
                        point: latLngs.first,
                        width: 16, height: 16,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (latLngs.isNotEmpty)
                      Marker(
                        point: latLngs.last,
                        width: 20, height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _statCard(l10n.livestockTrajectoryPoints, '${sampled.length}'),
            const SizedBox(width: AppSpacing.sm),
            _statCard(l10n.livestockTrajectoryDistance,
                '${(distance / 1000).toStringAsFixed(1)} km'),
            const SizedBox(width: AppSpacing.sm),
            _statCard(l10n.livestockTrajectoryRange,
                '${_calcArea(latLngs).toStringAsFixed(1)} km²'),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  double _calcArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final latDist = haversineDistance(minLat, minLng, maxLat, minLng);
    final lngDist = haversineDistance(minLat, minLng, minLat, maxLng);
    return (latDist * lngDist) / 1_000_000; // km²
  }
}
