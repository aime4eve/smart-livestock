import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 采集结果：外包络顶点（WGS-84，闭合多边形）。
class TrackCollectResult {
  const TrackCollectResult({required this.vertices});

  final List<LatLng> vertices;
}

enum _CollectPhase { initializing, needPermission, serviceOff, ready, recording, paused, processing }

/// 全屏轨迹采集页（NIX-213）：沿场地边缘自由走动，实时采点；
/// 完成后跑外包络管线，确认结果回传围栏表单。
///
/// 采集策略：WhenInUse 定位 + distanceFilter 2m；采集中保持亮屏
/// （iOS WhenInUse 熄屏即停采）。坐标全程 WGS-84，仅显示时按瓦片源转换。
class TrackCollectPage extends ConsumerStatefulWidget {
  const TrackCollectPage({super.key});

  @override
  ConsumerState<TrackCollectPage> createState() => _TrackCollectPageState();
}

class _TrackCollectPageState extends ConsumerState<TrackCollectPage> {
  static const _ringBufferLimit = 5000;

  final _mapController = MapController();
  SmartTileProvider? _tileProvider;
  StreamSubscription<Position>? _positionSub;
  Timer? _elapsedTimer;
  Stopwatch _stopwatch = Stopwatch();

  _CollectPhase _phase = _CollectPhase.initializing;
  final List<TrackPoint> _track = [];
  LatLng? _currentWgs;
  double _lastAccuracy = 0;
  bool _centered = false;

  @override
  void initState() {
    super.initState();
    _initTileProvider();
    _bootstrap();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    final provider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() => _tileProvider = provider);
  }

  Future<void> _bootstrap() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _phase = _CollectPhase.serviceOff);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      setState(() => _phase = _CollectPhase.needPermission);
      return;
    }
    // 首个定位：用于地图初始居中
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      _applyFix(position, center: true);
      setState(() => _phase = _CollectPhase.ready);
    } catch (_) {
      if (mounted) setState(() => _phase = _CollectPhase.ready);
    }
  }

  void _applyFix(Position position, {bool center = false}) {
    _currentWgs = LatLng(position.latitude, position.longitude);
    _lastAccuracy = position.accuracy;
    if (center && !_centered) {
      _centered = true;
      try {
        _mapController.move(
          _displayPoint(_currentWgs!),
          MapConstants.defaultZoom + 1,
        );
      } catch (_) {}
    }
  }

  void _startRecording() {
    final l10n = AppLocalizations.of(context)!;
    WakelockPlus.enable();
    _stopwatch = Stopwatch()..start();
    _startStreamOnly(silent: true);
    setState(() => _phase = _CollectPhase.recording);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.fenceTrackKeepScreenOn)),
    );
  }

  void _pause() {
    _positionSub?.pause();
    _stopwatch.stop();
    if (mounted) setState(() => _phase = _CollectPhase.paused);
  }

  void _resume() {
    _positionSub?.resume();
    _stopwatch.start();
    if (mounted) setState(() => _phase = _CollectPhase.recording);
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context)!;
    _positionSub?.cancel();
    _positionSub = null;
    _elapsedTimer?.cancel();
    _stopwatch.stop();
    setState(() => _phase = _CollectPhase.processing);
    // 让"处理中"先渲染一帧，再进入同步计算
    await Future<void>.delayed(Duration.zero);

    TrackToEnvelopeResult result;
    try {
      result = TrackToEnvelopeConverter.convert(_track);
    } catch (_) {
      // 病态数据兜底：与转换失败同样处理
      result = TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints, _track.length);
    }
    if (!result.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.failure == EnvelopeFailure.degenerate
                ? l10n.fenceTrackDegenerate
                : l10n.fenceTrackTooFewPoints,
          ),
        ),
      );
      // 留在采集页继续走：恢复采流
      _startStreamOnly();
      return;
    }

    final confirmed = await _showResultDialog(result);
    if (!mounted) return;
    if (confirmed) {
      WakelockPlus.disable();
      Navigator.of(context).pop(TrackCollectResult(vertices: result.vertices));
      return;
    }
    // 继续走：恢复采流（保留已采轨迹）
    _startStreamOnly();
  }

  void _startStreamOnly({bool silent = false}) {
    final l10n = AppLocalizations.of(context)!;
    WakelockPlus.enable();
    _stopwatch.start();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase == _CollectPhase.recording) setState(() {});
    });
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen(
      (position) {
        _applyFix(position);
        _track.add(TrackPoint(
          lat: position.latitude,
          lng: position.longitude,
          accuracyMeters: position.accuracy,
          timestamp: position.timestamp,
        ));
        if (_track.length > _ringBufferLimit) {
          // 环形缓冲到顶：按 1/2 抽稀腾空间
          _track.removeRange(0, _track.length ~/ 2);
        }
        if (mounted) setState(() {});
      },
      onError: (_) {},
    );
    setState(() => _phase = _CollectPhase.recording);
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fenceTrackKeepScreenOn)),
      );
    }
  }

  Future<bool> _showResultDialog(TrackToEnvelopeResult result) async {
    final l10n = AppLocalizations.of(context)!;
    final notes = <String>[
      l10n.fenceTrackVertices(result.vertexCount),
      if (result.method == HullMethod.concave)
        l10n.fenceImportMethodConcave
      else
        l10n.fenceTrackConvexFallback,
      if (result.outliersDropped > 0)
        l10n.fenceTrackOutliersRemoved(result.outliersDropped),
      if (result.ringsDropped > 0) l10n.fenceTrackMultiArea,
    ];
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            key: const Key('fence-track-result-dialog'),
            title: Text(l10n.fenceTrackFinish),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final note in notes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(note),
                  ),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('fence-track-result-continue'),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.fenceTrackResume),
              ),
              FilledButton(
                key: const Key('fence-track-result-confirm'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.fenceImportApply),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fenceTrackDiscard),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.fenceTrackDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(null);
    }
  }

  /// WGS-84 → 显示坐标（高德瓦片时转 GCJ-02，存储仍为 WGS-84）。
  LatLng _displayPoint(LatLng wgs) =>
      (_tileProvider?.shouldTransformCoordinates() ?? false)
          ? CoordTransform.wgs84ToGcj02(wgs)
          : wgs;

  List<LatLng> get _displayTrack =>
      _track.map((p) => _displayPoint(p.toLatLng())).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recording =
        _phase == _CollectPhase.recording || _phase == _CollectPhase.paused;

    return Scaffold(
      key: const Key('page-fence-track-collect'),
      appBar: AppBar(
        title: Text(l10n.fenceTrackMode),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: recording ? _discard : () => Navigator.of(context).pop(null),
        ),
      ),
      body: switch (_phase) {
        _CollectPhase.initializing ||
        _CollectPhase.processing =>
          const Center(child: CircularProgressIndicator()),
        _CollectPhase.needPermission => _guidePage(
            l10n.fenceTrackPermissionDenied,
            onAction: () => Geolocator.openAppSettings(),
          ),
        _CollectPhase.serviceOff => _guidePage(
            l10n.fenceTrackServiceDisabled,
            onAction: () => Geolocator.openLocationSettings(),
          ),
        _ => _buildMap(l10n, recording),
      },
    );
  }

  Widget _guidePage(String message, {required VoidCallback onAction}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              key: const Key('fence-track-open-settings'),
              onPressed: onAction,
              child: Text(l10n.fenceTrackOpenSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AppLocalizations l10n, bool recording) {
    final displayTrack = _displayTrack;
    final currentDisplay = _currentWgs != null ? _displayPoint(_currentWgs!) : null;
    final accuracyWarn = _lastAccuracy > TrackToEnvelopeConverter.accuracyThresholdM;

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentWgs != null
            ? _displayPoint(_currentWgs!)
            : MapConstants.mapCenter,
        initialZoom: MapConstants.defaultZoom + 1,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          key: ValueKey(_tileProvider?.activeSourceName),
          urlTemplate:
              _tileProvider == null ? MapConfig.tileUrlTemplate : null,
          tileProvider: _tileProvider,
          userAgentPackageName: 'com.smartlivestock.demo',
        ),
        if (displayTrack.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: displayTrack,
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ],
          ),
        if (currentDisplay != null)
          MarkerLayer(
            markers: [
              Marker(
                key: const Key('fence-track-current'),
                point: currentDisplay,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.25),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.navigation, size: 18),
                ),
              ),
            ],
          ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.fenceTrackGuide,
                    key: const Key('fence-track-guide'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        key: const Key('fence-track-point-count'),
                        l10n.fenceTrackPointCount(_track.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        key: const Key('fence-track-accuracy'),
                        l10n.fenceTrackAccuracy(_lastAccuracy.round()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accuracyWarn ? AppColors.warning : null,
                              fontWeight: accuracyWarn
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                      ),
                      if (recording) ...[
                        const Spacer(),
                        Text(
                          _formatElapsed(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_phase == _CollectPhase.ready)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: FilledButton.icon(
              key: const Key('fence-track-start'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _track.isEmpty ? _startRecording : _startStreamOnly,
              icon: const Icon(Icons.play_arrow),
              label: Text(_track.isEmpty
                  ? l10n.fenceTrackStart
                  : l10n.fenceTrackResume),
            ),
          ),
        if (recording)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('fence-track-pause'),
                    onPressed:
                        _phase == _CollectPhase.recording ? _pause : _resume,
                    icon: Icon(_phase == _CollectPhase.recording
                        ? Icons.pause
                        : Icons.play_arrow),
                    label: Text(_phase == _CollectPhase.recording
                        ? l10n.fenceTrackPause
                        : l10n.fenceTrackResume),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('fence-track-finish'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _track.length >= 3 ? _finish : null,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.fenceTrackFinish),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatElapsed() {
    final s = _stopwatch.elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}
