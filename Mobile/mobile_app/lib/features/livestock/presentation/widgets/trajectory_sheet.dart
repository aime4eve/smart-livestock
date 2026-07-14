import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/geo_utils.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Shows a bottom sheet displaying livestock GPS trajectory with a time
/// slider for dynamic playback.
void showTrajectorySheet(BuildContext context, String livestockId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TrajectorySheet(livestockId: livestockId),
  );
}

/// Time range options for trajectory data loading.
enum _TrajectoryRange { h24, d7, d30, custom }

/// GPS report interval — used to estimate expected point count and decide
/// whether server-side sampling is needed.
/// Current: 30 min. Future: may change to 5 min.
const Duration _gpsReportInterval = Duration(minutes: 30);

/// Maximum points for comfortable slider interaction (physical constraint:
/// phone slider width ~350px, 500 points = 0.7px per point).
const int _maxSliderPoints = 500;

/// Compute server sampleSize for a given range duration.
/// Returns null (no sampling) when expected points ≤ limit.
int? _computeSampleSize(Duration rangeDuration) {
  final expected = rangeDuration.inSeconds ~/ _gpsReportInterval.inSeconds;
  return expected > _maxSliderPoints ? _maxSliderPoints : null;
}

class _GpsPoint {
  const _GpsPoint({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.accuracy,
  });
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? accuracy;
}

class _TrajectorySheet extends ConsumerStatefulWidget {
  const _TrajectorySheet({required this.livestockId});
  final String livestockId;

  @override
  ConsumerState<_TrajectorySheet> createState() => _TrajectorySheetState();
}

class _TrajectorySheetState extends ConsumerState<_TrajectorySheet> {
  _TrajectoryRange _range = _TrajectoryRange.h24;
  DateTimeRange? _customRange;

  List<_GpsPoint> _points = [];
  bool _loading = true;

  // Playback state
  int _currentIdx = 0;
  bool _playing = false;
  int _speed = 1;
  Timer? _playTimer;

  // Map state
  SmartTileProvider? _tileProvider;
  final _mapController = MapController();
  bool _followMode = true;
  bool _lastTransformed = false;
  LatLngBounds? _lastBounds;

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
    _playTimer?.cancel();
    _tileProvider?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // === Data loading ===

  Duration get _rangeDuration {
    switch (_range) {
      case _TrajectoryRange.h24:
        return const Duration(hours: 24);
      case _TrajectoryRange.d7:
        return const Duration(days: 7);
      case _TrajectoryRange.d30:
        return const Duration(days: 30);
      case _TrajectoryRange.custom:
        final r = _customRange;
        if (r != null) {
          return r.end.difference(r.start);
        }
        return const Duration(hours: 24);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      late DateTime start;
      switch (_range) {
        case _TrajectoryRange.h24:
          start = now.subtract(const Duration(hours: 24));
          break;
        case _TrajectoryRange.d7:
          start = now.subtract(const Duration(days: 7));
          break;
        case _TrajectoryRange.d30:
          start = now.subtract(const Duration(days: 30));
          break;
        case _TrajectoryRange.custom:
          final r = _customRange;
          start = r != null
              ? DateTime(r.start.year, r.start.month, r.start.day)
              : now.subtract(const Duration(hours: 24));
          break;
      }

      final sampleSize = _computeSampleSize(_rangeDuration);
      // Use local time values as-is (no UTC conversion) to match the
      // backend's reportTime-as-UTC storage basis.
      String ts(DateTime dt) => DateTime.utc(
              dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
              dt.millisecond)
          .toIso8601String();

      var url =
          '/livestock/${widget.livestockId}/gps-logs?startTime=${ts(start)}&endTime=${ts(now)}';
      if (sampleSize != null) {
        url += '&sampleSize=$sampleSize';
      }

      final data = await ApiClient.instance.farmGet(url);
      final items = data['items'];
      final raw = items is List
          ? items.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      final parsed = raw
          .map((m) {
            final lat = (m['latitude'] as num?)?.toDouble();
            final lng = (m['longitude'] as num?)?.toDouble();
            final acc = (m['accuracy'] as num?)?.toDouble();
            // recordedAt is the backend field name
            final timeStr = (m['recordedAt'] ?? m['timestamp']) as String?;
            final recordedAt =
                timeStr != null ? DateTime.tryParse(timeStr) : null;
            return _GpsPoint(
              lat: lat ?? 0.0,
              lng: lng ?? 0.0,
              recordedAt: recordedAt ?? now,
              accuracy: acc,
            );
          })
          .where((p) => p.lat != 0.0 || p.lng != 0.0)
          .toList();

      // Sort ascending by recordedAt for correct slider playback order
      parsed.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

      if (mounted) {
        setState(() {
          _points = parsed;
          _loading = false;
          _currentIdx = parsed.isEmpty ? 0 : parsed.length - 1;
        });
        // Fit camera after data loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _points.isNotEmpty) _fitAll();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // === Playback ===

  void _play() {
    if (_points.length <= 1) return;
    setState(() => _playing = true);
    final tickMs = (300 / _speed).round().clamp(50, 300);
    _playTimer = Timer.periodic(Duration(milliseconds: tickMs), (_) {
      if (_currentIdx >= _points.length - 1) {
        _pause();
        return;
      }
      setState(() => _currentIdx++);
    });
  }

  void _pause() {
    _playTimer?.cancel();
    _playTimer = null;
    if (mounted) setState(() => _playing = false);
  }

  void _togglePlay() {
    if (_points.length <= 1) return;
    if (_playing) {
      _pause();
    } else {
      if (_currentIdx >= _points.length - 1) {
        setState(() => _currentIdx = 0);
      }
      _play();
    }
  }

  void _setSpeed(int s) {
    setState(() => _speed = s);
    if (_playing) {
      _playTimer?.cancel();
      _playTimer = null;
      _play();
    }
  }

  void _skipStart() {
    _pause();
    setState(() => _currentIdx = 0);
  }

  void _skipEnd() {
    _pause();
    setState(() => _currentIdx = _points.isEmpty ? 0 : _points.length - 1);
  }

  // === Map helpers ===

  void _fitAll() {
    if (_points.isEmpty) return;
    final latLngs = _transformAllPoints();
    if (latLngs.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(latLngs);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(30)),
    );
  }

  /// Transform ALL points (for bounds calculation).
  List<LatLng> _transformAllPoints() {
    final raw =
        _points.map((p) => LatLng(p.lat, p.lng)).toList();
    final shouldTransform =
        _tileProvider?.shouldTransformCoordinates() ?? false;
    return shouldTransform ? CoordTransform.wgs84ToGcj02All(raw) : raw;
  }

  /// Transform a sublist (0..idx) for display.
  List<LatLng> _transformVisible(int idx) {
    final raw = _points
        .sublist(0, idx + 1)
        .map((p) => LatLng(p.lat, p.lng))
        .toList();
    final shouldTransform =
        _tileProvider?.shouldTransformCoordinates() ?? false;
    return shouldTransform ? CoordTransform.wgs84ToGcj02All(raw) : raw;
  }

  String _fmtTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _fmtShort(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  String _fmtLabel(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    // Multi-day range shows date prefix; single-day shows time only
    if (_range == _TrajectoryRange.d7 ||
        _range == _TrajectoryRange.d30 ||
        (_range == _TrajectoryRange.custom &&
            _rangeDuration.inHours > 24)) {
      return '${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    }
    return _fmtShort(dt);
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

  // === Build ===

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header row
            _buildHeaderRow(l10n),
            const SizedBox(height: AppSpacing.sm),
            // Map (flex: 1)
            Expanded(child: _buildContent(l10n)),
            const SizedBox(height: AppSpacing.sm),
            // Slider
            _buildSliderSection(l10n),
            // Controls
            _buildControls(l10n),
            const SizedBox(height: AppSpacing.xs),
            // Stats
            _buildStats(l10n),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // === Header row ===

  Widget _buildHeaderRow(AppLocalizations l10n) {
    final rangeLabel = switch (_range) {
      _TrajectoryRange.h24 => l10n.livestockTrajectoryRange24h,
      _TrajectoryRange.d7 => l10n.livestockTrajectoryRange7d,
      _TrajectoryRange.d30 => l10n.livestockTrajectoryRange30d,
      _TrajectoryRange.custom => l10n.livestockTrajectoryRangeCustom,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(l10n.livestockTrajectoryTitle,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '#${widget.livestockId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Range selector
          PopupMenuButton<_TrajectoryRange>(
            onSelected: (r) async {
              if (r == _TrajectoryRange.custom) {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now,
                  initialDateRange: DateTimeRange(
                    start: now.subtract(const Duration(hours: 24)),
                    end: now,
                  ),
                );
                if (picked == null) return;
                setState(() {
                  _range = _TrajectoryRange.custom;
                  _customRange = picked;
                });
              } else {
                setState(() => _range = r);
              }
              _load();
            },
            itemBuilder: (ctx) => [
              _rangeMenuItem(l10n.livestockTrajectoryRange24h,
                  _TrajectoryRange.h24),
              _rangeMenuItem(l10n.livestockTrajectoryRange7d,
                  _TrajectoryRange.d7),
              _rangeMenuItem(l10n.livestockTrajectoryRange30d,
                  _TrajectoryRange.d30),
              _rangeMenuItem(l10n.livestockTrajectoryRangeCustom,
                  _TrajectoryRange.custom),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rangeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          )),
                  const Icon(Icons.arrow_drop_down,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_TrajectoryRange> _rangeMenuItem(
      String label, _TrajectoryRange value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          if (_range == value)
            const Icon(Icons.check, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  // === Map content ===

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.livestockTrajectoryLoading,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }
    if (_points.isEmpty) {
      return Center(child: Text(l10n.livestockTrajectoryEmpty));
    }

    final visible = _transformVisible(_currentIdx);
    final allLatLngs = _transformAllPoints();
    final bounds = LatLngBounds.fromPoints(allLatLngs);

    // Re-fit camera when tile source switches coordinate system
    final shouldTransform =
        _tileProvider?.shouldTransformCoordinates() ?? false;
    if (_lastTransformed != shouldTransform) {
      _lastTransformed = shouldTransform;
      _lastBounds = bounds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastBounds != null) {
          _mapController.fitCamera(
            CameraFit.bounds(
                bounds: _lastBounds!, padding: const EdgeInsets.all(30)),
          );
        }
      });
    }

    // Trail: last 5 visible points highlighted
    final trailStart = visible.length > 5 ? visible.length - 5 : 0;
    final trail = visible.sublist(trailStart);

    final currentPoint =
        visible.isNotEmpty ? visible[_currentIdx.clamp(0, visible.length - 1)] : null;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit:
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(30)),
            ),
            children: [
              TileLayer(
                tileProvider: _tileProvider,
                urlTemplate: '',
              ),
              if (visible.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: visible,
                      color: AppColors.primary,
                      strokeWidth: 3.5,
                    ),
                  ],
                ),
              if (trail.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trail,
                      color: AppColors.accent,
                      strokeWidth: 4.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (allLatLngs.isNotEmpty)
                    Marker(
                      point: allLatLngs.first,
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  if (currentPoint != null)
                    Marker(
                      point: currentPoint,
                      width: 20,
                      height: 20,
                      child: const _PulseMarker(),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Map overlay buttons
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            children: [
              _overlayButton(
                Icons.gps_fixed,
                _followMode,
                () => setState(() {
                  _followMode = !_followMode;
                  if (_followMode && currentPoint != null) {
                    _mapController.move(currentPoint,
                        _mapController.camera.zoom);
                  }
                }),
              ),
              const SizedBox(height: 4),
              _overlayButton(
                Icons.fit_screen_outlined,
                false,
                _fitAll,
                alwaysActive: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overlayButton(
      IconData icon, bool active, VoidCallback onTap,
      {bool alwaysActive = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: active ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }

  // === Slider section ===

  Widget _buildSliderSection(AppLocalizations l10n) {
    if (_points.isEmpty) return const SizedBox.shrink();
    final max = _points.length - 1;
    final cur = _points[_currentIdx.clamp(0, max)];
    final canInteract = _points.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Current time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.livestockTrajectoryCurrentTime,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
              const SizedBox(width: AppSpacing.xs),
              Text(_fmtTime(cur.recordedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
            ],
          ),
          // Slider
          if (canInteract)
            Slider(
              value: _currentIdx.toDouble().clamp(0, max.toDouble()),
              min: 0,
              max: max.toDouble(),
              divisions: max,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (v) {
                if (_playing) _pause();
                setState(() => _currentIdx = v.round());
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(_fmtShort(cur.recordedAt),
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          // Start / end labels
          if (_points.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtLabel(_points.first.recordedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          )),
                  Text(_fmtLabel(_points.last.recordedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // === Playback controls ===

  Widget _buildControls(AppLocalizations l10n) {
    final canPlay = _points.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 20),
            onPressed: canPlay ? _skipStart : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: AppColors.textSecondary,
          ),
          GestureDetector(
            onTap: canPlay ? _togglePlay : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: canPlay ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 20),
            onPressed: canPlay ? _skipEnd : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Speed selector
          for (final s in [1, 2, 4, 8]) ...[
            GestureDetector(
              onTap: () => _setSpeed(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _speed == s ? AppColors.primary : AppColors.surfaceAlt,
                  border: Border.all(
                      color: _speed == s
                          ? AppColors.primary
                          : AppColors.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${s}x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _speed == s
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            if (s != 8) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  // === Stats ===

  Widget _buildStats(AppLocalizations l10n) {
    final visible = _transformVisible(_currentIdx);
    final distance = totalPathDistance(visible
        .map((ll) => (lat: ll.latitude, lng: ll.longitude))
        .toList());
    final area = _calcArea(visible);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _statCard(
            l10n.livestockTrajectoryPoints,
            '${visible.length}/${_points.length}',
          ),
          const SizedBox(width: AppSpacing.xs),
          _statCard(
            l10n.livestockTrajectoryDistance,
            '${(distance / 1000).toStringAsFixed(2)} km',
          ),
          const SizedBox(width: AppSpacing.xs),
          _statCard(
            l10n.livestockTrajectoryRange,
            '${area.toStringAsFixed(2)} km²',
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Pulsing marker widget for current GPS position.
class _PulseMarker extends StatefulWidget {
  const _PulseMarker();

  @override
  State<_PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<_PulseMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final scale = 1.0 + _controller.value * 1.5;
              return Opacity(
                opacity: (1 - _controller.value) * 0.4,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
