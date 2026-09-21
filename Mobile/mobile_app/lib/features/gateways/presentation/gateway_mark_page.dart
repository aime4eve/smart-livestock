import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:latlong2/latlong.dart';

import 'gateway_controller.dart' show gatewayRepositoryProvider;
import '../domain/gateway_models.dart';

/// Mark / re-mark a gateway position (NIX-219 F1, prototype screen 2).
/// Current GPS fix first, drag-to-fine-tune on the map, and an overwrite
/// confirmation when the gateway already has a (globally unique) position.
class GatewayMarkPage extends ConsumerStatefulWidget {
  const GatewayMarkPage({super.key, required this.item});

  final GatewayDiscoveryItem item;

  static Future<void> push(BuildContext context, GatewayDiscoveryItem item) =>
      context.push('/mine/gateways/${Uri.encodeComponent(item.gatewayId)}',
          extra: item);

  @override
  ConsumerState<GatewayMarkPage> createState() => _GatewayMarkPageState();
}

class _GatewayMarkPageState extends ConsumerState<GatewayMarkPage> {
  final _mapController = MapController();
  SmartTileProvider? _tileProvider;

  LatLng? _pin;
  double? _accuracyM;
  String? _error;
  bool _submitting = false;
  StreamSubscription<Position>? _posSub;
  bool _follow = true; // auto-fill lat/lng from the phone GPS until the user drags

  // Coordinate-system rule (NIX-219): [_pin] is ALWAYS WGS-84 (what gets
  // saved and what the distance math expects). The rendering transform
  // follows the tiles actually serving the pin (高德 online → GCJ-02; local
  // offline/server OSM tiles → none), and a drag is converted back the same
  // way before it reaches [_pin].
  LatLng _toDisplay(LatLng p) {
    final t = _tileProvider;
    return t != null && t.shouldTransformAt(p)
        ? CoordTransform.wgs84ToGcj02(p)
        : p;
  }

  LatLng _fromDisplay(LatLng p) {
    final t = _tileProvider;
    return t != null && t.shouldTransformAt(p)
        ? CoordTransform.gcj02ToWgs84(p)
        : p;
  }

  void _recenterOnPin() {
    final pin = _pin;
    if (pin != null) _mapController.move(_toDisplay(pin), 16);
  }

  @override
  void initState() {
    super.initState();
    // Registered gateways start centred on their existing position (re-mark).
    final existing = widget.item;
    if (existing.registered && existing.latitude != null) {
      _pin = LatLng(existing.latitude!, existing.longitude!);
    } else {
      // Unregistered: start at a usable default so map picking always works.
      _pin = const LatLng(28.2280, 112.9400);
    }
    _initTileProvider();
    _startLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _tileProvider?.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    final provider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () {
        if (mounted) {
          setState(() {});
          // Projection changed with the tile source — re-anchor the view on
          // the pin so the marker stays centred and correctly placed.
          if (_tileProvider != null) _recenterOnPin();
        }
      },
    );
    if (mounted) setState(() => _tileProvider = provider);
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return !(permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever);
  }

  /// Auto-locate from the phone GPS: take an initial fix, then keep streaming —
  /// while follow mode is on the pin, the map centre and the lat/lng boxes
  /// fill themselves from the phone signal (NIX-219 marking flow).
  Future<void> _startLocation() async {
    try {
      if (!await _ensurePermission()) {
        if (mounted) {
          setState(() =>
              _error = AppLocalizations.of(context)!.gatewayLocPermDenied);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _applyPosition(pos, moveCamera: true);
      if (!mounted) return;
      setState(() => _error = null);
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((pos) => _applyPosition(pos, moveCamera: true));
    } catch (e) {
      // Browser定位可能不可用（权限拒绝/无实现），地图选点仍然可用。
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.gatewayLocUnavailable;
          _pin ??= const LatLng(28.2280, 112.9400);
        });
        _mapController.move(_toDisplay(_pin!), 16);
      }
    }
  }

  void _applyPosition(Position pos, {required bool moveCamera}) {
    if (!mounted) return;
    final target = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _accuracyM = pos.accuracy;
      if (_follow) _pin = target;
      _error = null;
    });
    if (moveCamera && _follow) {
      _mapController.move(_toDisplay(target), 16);
    }
  }

  /// Re-centre on the phone GPS and resume auto-follow (my-location button).
  Future<void> _locate() async {
    try {
      if (!await _ensurePermission()) {
        if (mounted) {
          setState(() =>
              _error = AppLocalizations.of(context)!.gatewayLocPermDenied);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _follow = true;
        _pin = LatLng(pos.latitude, pos.longitude);
        _accuracyM = pos.accuracy;
        _error = null;
      });
      _mapController.move(_toDisplay(LatLng(pos.latitude, pos.longitude)), 16);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = AppLocalizations.of(context)!.gatewayLocUnavailable);
      }
    }
  }

  bool get _accuracyGood => _accuracyM == null || _accuracyM! <= 50;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pin;
    if (pin == null) return;
    if (!_accuracyGood) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.gatewayAccuracyTooLow)));
      return;
    }
    if (widget.item.registered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.gatewayOverwriteTitle),
          content: Text(l10n.gatewayOverwriteBody(widget.item.markedAt == null
              ? '--'
              : '${widget.item.markedAt!.month.toString().padLeft(2, '0')}-${widget.item.markedAt!.day.toString().padLeft(2, '0')}')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel)),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.gatewayOverwriteConfirm)),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _submitting = true);
    try {
      final farmId =
          ref.read(sessionControllerProvider.select((s) => s.activeFarmId));
      if (farmId == null) {
        throw StateError('No active farm');
      }
      await ref.read(gatewayRepositoryProvider).markPosition(
            farmId,
            widget.item.gatewayId,
            latitude: pin.latitude,
            longitude: pin.longitude,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.item.registered
              ? l10n.gatewayMarkOverwrittenDone
              : l10n.gatewayMarkDone)));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pin = _pin;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
          title: Text(l10n.gatewayMarkTitle(widget.item.shortId))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _accuracyCard(l10n),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 240,
            child: pin == null || _tileProvider == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _toDisplay(pin),
                          initialZoom: 16,
                          interactionOptions:
                              const InteractionOptions(flags: InteractiveFlag.drag),
                          onPositionChanged: (_, hasGesture) {
                            if (!hasGesture) return;
                            // Dragging = manual fine-tune: stop auto-follow so the
                            // map stops fighting the user; pin stays at the centre.
                            if (mounted && _follow) {
                              setState(() => _follow = false);
                            }
                            final centre = _mapController.camera.center;
                            // Map centre is in tile coordinates (GCJ-02 on 高德)
                            // — convert back before it touches the stored pin.
                            if (mounted) setState(() => _pin = _fromDisplay(centre));
                          },
                        ),
                        children: [
                          TileLayer(
                            key: ValueKey(_tileProvider?.activeSourceName),
                            urlTemplate: _tileProvider == null
                                ? MapConfig.tileUrlTemplate
                                : null,
                            tileProvider: _tileProvider,
                            userAgentPackageName: 'com.smartlivestock.demo',
                          ),
                          CircleLayer(circles: [
                            if (_accuracyM != null)
                              CircleMarker(
                                point: _toDisplay(pin),
                                radius: _accuracyM!,
                                useRadiusInMeter: true,
                                color: (_accuracyM! <= 10
                                        ? AppColors.success
                                        : _accuracyM! <= 50
                                            ? AppColors.warning
                                            : AppColors.danger)
                                    .withValues(alpha: 0.18),
                                borderColor: _accuracyM! <= 10
                                    ? AppColors.success
                                    : _accuracyM! <= 50
                                        ? AppColors.warning
                                        : AppColors.danger,
                                borderStrokeWidth: 2,
                              ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: _toDisplay(pin),
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.location_on,
                                  color: AppColors.primary, size: 30),
                            ),
                          ]),
                        ],
                      ),
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: FloatingActionButton.small(
                          heroTag: 'gateway-my-location',
                          backgroundColor: AppColors.surfaceAlt,
                          foregroundColor:
                              _follow ? AppColors.success : AppColors.info,
                          onPressed: _locate,
                          child: Icon(_follow
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: _coordBox(l10n.gatewayLat, pin?.latitude.toStringAsFixed(7)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _coordBox(l10n.gatewayLng, pin?.longitude.toStringAsFixed(7)),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  _accuracyGood ? AppColors.primary : AppColors.textSecondary,
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: _pin == null || _submitting ? null : _submit,
            child: Text(_submitting
                ? l10n.commonSubmitting
                : widget.item.registered
                    ? l10n.gatewayOverwriteSubmit
                    : l10n.gatewayMarkSubmit),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.gatewayMarkFootnote,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  Widget _accuracyCard(AppLocalizations l10n) {
    final ready = _accuracyM != null;
    final good = _accuracyGood;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ready
            ? (good ? AppColors.successSoft : AppColors.warningSoft)
            : AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: ready
                    ? (good ? AppColors.success : AppColors.warning)
                    : AppColors.info,
                width: 2),
            color: AppColors.surfaceAlt,
          ),
          child: const Icon(Icons.gps_fixed, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            ready
                ? (_follow
                    ? l10n.gatewayFollowLive(_accuracyM!.toStringAsFixed(0))
                    : l10n.gatewayAccuracyReady(_accuracyM!.toStringAsFixed(0)))
                : l10n.gatewayLocating,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        if (ready && !_follow)
          Text(l10n.gatewayFollowManual,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _coordBox(String label, String? value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text(value ?? '--',
                style: const TextStyle(
                    fontSize: 14, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      );
}
