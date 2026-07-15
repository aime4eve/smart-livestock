import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// Shows a calibration session's full GPS movement trajectory.
///
/// Unlike [TrajectorySheet] this is platform-level (sessionId, not
/// livestockId) and uses ApiClient.get directly — no farm scope.
void showSessionTrajectorySheet(
  BuildContext context,
  int sessionId, {
  String? deviceCode,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _SessionTrajectorySheet(
      sessionId: sessionId,
      deviceCode: deviceCode,
    ),
  );
}

class _SessionTrajectorySheet extends ConsumerStatefulWidget {
  const _SessionTrajectorySheet({required this.sessionId, this.deviceCode});
  final int sessionId;
  final String? deviceCode;

  @override
  ConsumerState<_SessionTrajectorySheet> createState() =>
      _SessionTrajectorySheetState();
}

class _SessionTrajectorySheetState
    extends ConsumerState<_SessionTrajectorySheet> {
  List<TrajectoryPoint> _points = [];
  bool _loading = true;
  String? _error;
  SmartTileProvider? _tileProvider;
  final _mapController = MapController();

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

  Future<void> _load() async {
    try {
      final repo = ref.read(gpsQualityApiRepositoryProvider);
      final points = await repo.fetchTrajectory(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _points = points;
        _loading = false;
      });
      _fitBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _fitBounds() {
    if (_points.length < 2 || !mounted) return;
    final lats = _points.map((p) => p.latitude).toList();
    final lngs = _points.map((p) => p.longitude).toList();
    final bounds = LatLngBounds(
      LatLng(lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b)),
      LatLng(lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
    });
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          key: const Key('session-trajectory-sheet'),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(child: _buildBody(l10n, mediaQuery)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.deviceCode != null
                  ? '${l10n.gpsQualityDevice}: ${widget.deviceCode}'
                  : l10n.gpsQualityViewTrajectory,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            key: const Key('trajectory-close-btn'),
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, MediaQueryData mediaQuery) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $_error',
              style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }
    if (_points.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(l10n.gpsQualityNoData,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final polylinePoints = _points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Column(
      children: [
        SizedBox(
          height: mediaQuery.size.height * 0.5,
          child: _tileProvider == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  key: const Key('session-trajectory-map'),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: polylinePoints.first,
                    initialZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      tileProvider: _tileProvider,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: polylinePoints.first,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Marker(
                          point: polylinePoints.last,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('session-trajectory-list'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _points.length,
            itemBuilder: (context, index) {
              final p = _points[index];
              final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primarySoft,
                  child: Text('${index + 1}',
                      style: const TextStyle(fontSize: 11)),
                ),
                title: Text(
                  '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontSize: 13, fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  fmt.format(p.recordedAt.toLocal()),
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
