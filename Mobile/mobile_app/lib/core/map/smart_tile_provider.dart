import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';

/// Which online source is currently active.
enum _OnlineSource { primary, offline }

/// Per-tile smart router with one online source + offline fallback.
///
/// The online source is fixed by the client time-zone setting (高德 for China,
/// OSM elsewhere) and passed in via [onlineUrl]; no cross-source switching.
/// Priority chain (each tile independently):
/// 1. Local mbtiles (user-downloaded) — zero latency, zero network
/// 2. Online ([onlineUrl]) — full zoom, global
/// 3. Server tileserver — when the online source is unreachable (z12-15)
class SmartTileProvider extends TileProvider {
  final List<MBTilesTileProvider> mbtilesProviders;

  /// Online tile URL template. GCJ-02 (高德) or WGS-84 (OSM) per time zone.
  final String onlineUrl;

  /// True when [onlineUrl] serves GCJ-02 tiles (高德).
  final bool onlineIsGcj02;

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
    this.onlineIsGcj02 = false,
    this.serverTileUrl,
    this.onSourceChanged,
  });

  static Future<SmartTileProvider> create({
    required List<MBTilesTileProvider> mbtilesProviders,
    required String onlineUrl,
    bool onlineIsGcj02 = false,
    String? serverTileUrl,
    VoidCallback? onSourceChanged,
  }) async {
    return SmartTileProvider(
      mbtilesProviders: mbtilesProviders,
      onlineUrl: onlineUrl,
      onlineIsGcj02: onlineIsGcj02,
      serverTileUrl: serverTileUrl,
      onSourceChanged: onSourceChanged,
    );
  }

  bool get isOnline => _activeSource != _OnlineSource.offline;

  /// GCJ-02 transform needed only when serving 高德 tiles online.
  bool shouldTransformCoordinates() =>
      _activeSource != _OnlineSource.offline && onlineIsGcj02;

 void probeConnectivity() {
   _probe();
 }

 void startConnectivityMonitor({
   Duration interval = const Duration(seconds: 30),
 }) {
   _initialized = true;
   _probeTimer?.cancel();
   _probeTimer = Timer.periodic(interval, (_) => _probe());
 }

 /// Probe online → offline.
 void _probe() async {
    final isFirstProbe = !_initialized;
   // 1. Try online
   if (await _tryUrl(onlineUrl)) {
     _consecutiveFailures = 0;
     _switchSource(_OnlineSource.primary);
      _finishFirstProbe(isFirstProbe);
     return;
   }

   // 2. Online unreachable
   _consecutiveFailures++;
   if (_consecutiveFailures >= 3) {
     _switchSource(_OnlineSource.offline);
     _finishFirstProbe(isFirstProbe);
   }
 }

 void _finishFirstProbe(bool isFirstProbe) {
   if (isFirstProbe) {
     _initialized = true;
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
  void simulatePrimary() {
    _initialized = true;
    _switchSource(_OnlineSource.primary);
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

    // The online source is fixed at construction (single-source design), so
    // tiles fetch immediately — including while the first probe is in flight.
    // Never return a "transparent" placeholder here: flutter_map caches it as
    // a successfully loaded tile and the map would stay blank forever.
    switch (_activeSource) {
      case _OnlineSource.primary:
        return NetworkImage(
            _buildUrl(onlineUrl, coordinates.x, coordinates.y, coordinates.z));
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
    if (!_initialized) return onlineIsGcj02 ? '高德' : 'OSM';
    switch (_activeSource) {
      case _OnlineSource.primary:
        return onlineIsGcj02 ? '高德' : 'OSM';
      case _OnlineSource.offline:
        return 'Server';
    }
  }
}
