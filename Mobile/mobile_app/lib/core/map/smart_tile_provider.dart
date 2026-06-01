import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:smart_livestock_demo/core/map/mbtiles_tile_provider.dart';

enum _TileSource { selfHosted, mbtiles, fallback }

/// 三级回退 TileProvider：tileserver-gl → MBTiles → 高德/OSM
///
/// nginx 已配置将 tileserver 的 404 转为透明 PNG，
/// 因此客户端不需要做瓦片范围判断。
class SmartTileProvider extends TileProvider {
  final String? selfHostedTileUrl;
  final MBTilesTileProvider? mbtilesProvider;
  final String? fallbackUrl;
  final bool isGcj02Fallback;

  _TileSource _activeSource = _TileSource.selfHosted;
  VoidCallback? onSourceChanged;

  SmartTileProvider({
    this.selfHostedTileUrl,
    this.mbtilesProvider,
    this.fallbackUrl,
    this.isGcj02Fallback = false,
    this.onSourceChanged,
  }) {
    if (selfHostedTileUrl == null) {
      _activeSource =
          mbtilesProvider != null ? _TileSource.mbtiles : _TileSource.fallback;
    }
  }

  static Future<SmartTileProvider> create({
    String? selfHostedTileUrl,
    MBTilesTileProvider? mbtilesProvider,
    String? fallbackUrl,
    bool isGcj02Fallback = false,
    VoidCallback? onSourceChanged,
  }) async {
    final provider = SmartTileProvider(
      selfHostedTileUrl: selfHostedTileUrl,
      mbtilesProvider: mbtilesProvider,
      fallbackUrl: fallbackUrl,
      isGcj02Fallback: isGcj02Fallback,
      onSourceChanged: onSourceChanged,
    );
    await provider.performHealthCheck();
    return provider;
  }

  bool shouldTransformCoordinates() =>
      _activeSource == _TileSource.fallback && isGcj02Fallback;

  bool get isSelfHostedActive => _activeSource == _TileSource.selfHosted;

  Future<void> performHealthCheck() async {
    if (selfHostedTileUrl == null) return;
    try {
      final url = _buildUrl(selfHostedTileUrl!, 3332, 1712, 12);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) _degrade();
    } catch (_) {
      _degrade();
    }
  }

  void startHealthMonitor({Duration interval = const Duration(seconds: 60)}) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(interval, (_) async {
      if (_activeSource != _TileSource.selfHosted &&
          selfHostedTileUrl != null) {
        try {
          final url = _buildUrl(selfHostedTileUrl!, 3332, 1712, 12);
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) _switchTo(_TileSource.selfHosted);
        } catch (_) {}
      }
    });
  }

  Timer? _healthTimer;

  void _degrade() {
    _switchTo(
        mbtilesProvider != null ? _TileSource.mbtiles : _TileSource.fallback);
  }

  void _switchTo(_TileSource source) {
    if (_activeSource == source) return;
    _activeSource = source;
    onSourceChanged?.call();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    switch (_activeSource) {
      case _TileSource.selfHosted:
        return NetworkImage(
            _buildUrl(selfHostedTileUrl!, coordinates.x, coordinates.y, coordinates.z));
      case _TileSource.mbtiles:
        if (mbtilesProvider != null &&
            mbtilesProvider!.hasTile(
                coordinates.z, coordinates.x, coordinates.y)) {
          return mbtilesProvider!.getImage(coordinates, options);
        }
        if (fallbackUrl != null) {
          return NetworkImage(
              _buildUrl(fallbackUrl!, coordinates.x, coordinates.y, coordinates.z));
        }
        return MemoryImage(TileProvider.transparentImage);
      case _TileSource.fallback:
        if (fallbackUrl != null) {
          return NetworkImage(
              _buildUrl(fallbackUrl!, coordinates.x, coordinates.y, coordinates.z));
        }
        return MemoryImage(TileProvider.transparentImage);
    }
  }

  static String _buildUrl(String template, int x, int y, int z) {
    return template
        .replaceFirst('{x}', x.toString())
        .replaceFirst('{y}', y.toString())
        .replaceFirst('{z}', z.toString());
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    mbtilesProvider?.dispose();
    super.dispose();
  }
}
