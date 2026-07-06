import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';

/// Which online source is currently active.
enum _OnlineSource { primary, secondary, offline }

/// Per-tile smart router with dual online sources + offline fallback.
///
/// Priority chain (each tile independently):
/// 1. Local mbtiles — zero latency, zero network
/// 2. Primary online (OSM) — full zoom, global, WGS-84
/// 3. Secondary online (高德) — when OSM unreachable (e.g. China), GCJ-02
/// 4. Server tileserver — when both online sources fail (z12-15, WGS-84)
///
/// This dual-source design ensures the app works in both international markets
/// (OSM primary) and China (高德 fallback when OSM is blocked).
///
/// See docs/superpowers/specs/2026-07-04-smart-tile-routing-design.md
class SmartTileProvider extends TileProvider {
  final List<MBTilesTileProvider> mbtilesProviders;

  /// Primary online tile URL template (OSM, WGS-84).
  final String onlineUrl;

  /// Secondary online tile URL template (高德, GCJ-02). Null disables.
  final String? fallbackOnlineUrl;

  /// Server tileserver-gl URL (last-resort fallback). Null if unavailable.
  final String? serverTileUrl;

  _OnlineSource _activeSource = _OnlineSource.primary;
  bool _initialized = false;
  int _consecutiveFailures = 0;
  Timer? _probeTimer;
  VoidCallback? onSourceChanged;

  SmartTileProvider({
    required this.mbtilesProviders,
    required this.onlineUrl,
    this.fallbackOnlineUrl,
    this.serverTileUrl,
    this.onSourceChanged,
  });

  static Future<SmartTileProvider> create({
    required List<MBTilesTileProvider> mbtilesProviders,
    required String onlineUrl,
    String? fallbackOnlineUrl,
    String? serverTileUrl,
    VoidCallback? onSourceChanged,
  }) async {
    return SmartTileProvider(
      mbtilesProviders: mbtilesProviders,
      onlineUrl: onlineUrl,
      fallbackOnlineUrl: fallbackOnlineUrl,
      serverTileUrl: serverTileUrl,
      onSourceChanged: onSourceChanged,
    );
  }

  bool get isOnline => _activeSource != _OnlineSource.offline;

  /// GCJ-02 transform needed only when using 高德 (secondary source).
  bool shouldTransformCoordinates() =>
      _activeSource == _OnlineSource.secondary;

  void probeConnectivity() {
    _initialized = true;
    _probe();
  }

  void startConnectivityMonitor({
    Duration interval = const Duration(seconds: 30),
  }) {
    _initialized = true;
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(interval, (_) => _probe());
  }

  /// Probe primary (OSM) → secondary (高德) → offline.
  void _probe() async {
    // 1. Try primary (OSM)
    if (await _tryUrl(onlineUrl)) {
      _consecutiveFailures = 0;
      _switchSource(_OnlineSource.primary);
      return;
    }

    // 2. Try secondary (高德)
    if (fallbackOnlineUrl != null && await _tryUrl(fallbackOnlineUrl!)) {
      _consecutiveFailures = 0;
      _switchSource(_OnlineSource.secondary);
      return;
    }

    // 3. Both failed
    _consecutiveFailures++;
    if (_consecutiveFailures >= 3) {
      _switchSource(_OnlineSource.offline);
    }
  }

  Future<bool> _tryUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse(_buildUrl(url, 0, 0, 0)))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void simulateOffline() {
    _initialized = true;
    _consecutiveFailures = 3;
    _switchSource(_OnlineSource.offline);
  }

  @visibleForTesting
  void simulateSecondary() {
    _initialized = true;
    _switchSource(_OnlineSource.secondary);
  }

  void _switchSource(_OnlineSource source) {
    if (_activeSource == source) return;
    _activeSource = source;
    onSourceChanged?.call();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. Local mbtiles
    for (final p in mbtilesProviders) {
      if (p.meta.containsTile(coordinates.z, coordinates.x, coordinates.y)) {
        return p.getImage(coordinates, options);
      }
    }

    // Before first probe, default to primary so map renders immediately
    final source = _initialized ? _activeSource : _OnlineSource.primary;

    switch (source) {
      case _OnlineSource.primary:
        return NetworkImage(
            _buildUrl(onlineUrl, coordinates.x, coordinates.y, coordinates.z));
      case _OnlineSource.secondary:
        final url = fallbackOnlineUrl ?? onlineUrl;
        return NetworkImage(
            _buildUrl(url, coordinates.x, coordinates.y, coordinates.z));
      case _OnlineSource.offline:
        if (serverTileUrl != null) {
          return NetworkImage(_buildUrl(
              serverTileUrl!, coordinates.x, coordinates.y, coordinates.z));
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
    _probeTimer?.cancel();
    for (final p in mbtilesProviders) {
      p.dispose();
    }
    super.dispose();
  }

  /// Current tile source name for watermark display.
  String get activeSourceName {
    final s = _initialized ? _activeSource : _OnlineSource.primary;
    return tileSourceLabel(s);
  }
}

/// Human-readable label for tile source watermark.
String tileSourceLabel(_OnlineSource s) {
  switch (s) {
    case _OnlineSource.primary: return 'OSM';
    case _OnlineSource.secondary: return '高德';
    case _OnlineSource.offline: return 'Server';
  }
}
