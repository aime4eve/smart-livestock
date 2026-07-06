import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';

/// Per-tile smart router: local mbtiles → OSM online → tileserver fallback.
///
/// Each tile request independently chooses its source:
/// 1. Local mbtiles (user-downloaded or built-in) — zero latency, zero network
/// 2. OSM online — full zoom range, global coverage
/// 3. tileserver — server-side fallback when OSM is unreachable (z12-15)
///
/// Connectivity is tracked via periodic background probes (non-blocking).
/// See docs/superpowers/specs/2026-07-04-smart-tile-routing-design.md
class SmartTileProvider extends TileProvider {
  /// All local mbtiles providers (user-downloaded + built-in sample).
  final List<MBTilesTileProvider> mbtilesProviders;

  /// Primary online tile URL template (OSM or 高德).
  final String onlineUrl;

  /// Server tileserver-gl URL (offline fallback). Null if no server available.
  final String? serverTileUrl;

  /// Whether the online source uses GCJ-02 (true for 高德, false for OSM).
  final bool isGcj02Online;

  bool _online = true;
  int _consecutiveFailures = 0;
  Timer? _probeTimer;
  VoidCallback? onSourceChanged;

  SmartTileProvider({
    required this.mbtilesProviders,
    required this.onlineUrl,
    this.serverTileUrl,
    this.isGcj02Online = false,
    this.onSourceChanged,
  });

  static Future<SmartTileProvider> create({
    required List<MBTilesTileProvider> mbtilesProviders,
    required String onlineUrl,
    String? serverTileUrl,
    bool isGcj02Online = false,
    VoidCallback? onSourceChanged,
  }) async {
    // No blocking health check — return immediately, probe in background.
    return SmartTileProvider(
      mbtilesProviders: mbtilesProviders,
      onlineUrl: onlineUrl,
      serverTileUrl: serverTileUrl,
      isGcj02Online: isGcj02Online,
      onSourceChanged: onSourceChanged,
    );
  }

  /// Whether we're currently treating the online source as reachable.
  bool get isOnline => _online;

  /// Transform fence coordinates to GCJ-02 only when online + using 高德.
  /// Local mbtiles and tileserver are always WGS-84 (no transform).
  /// OSM is also WGS-84 (no transform).
  bool shouldTransformCoordinates() => _online && isGcj02Online;

  /// Fire-and-forget initial connectivity probe.
  void probeConnectivity() => _probe();

  /// Background probe every 30s. On 3 consecutive failures → go offline.
  /// On success → go online.
  void startConnectivityMonitor({Duration interval = const Duration(seconds: 30)}) {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(interval, (_) => _probe());
  }

  void _probe() async {
    try {
      final url = _buildUrl(onlineUrl, 0, 0, 0);
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _consecutiveFailures = 0;
        _setOnline(true);
      } else {
        _registerFailure();
      }
    } catch (_) {
      _registerFailure();
    }
  }

  void _registerFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= 3) _setOnline(false);
  }

  /// Test-only: simulate connectivity failures to trigger offline mode.
  @visibleForTesting
  void simulateOffline() {
    _consecutiveFailures = 3;
    _setOnline(false);
  }

  void _setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    onSourceChanged?.call();
  }


  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // 1. Check all local mbtiles (user-downloaded first, then built-in)
    for (final p in mbtilesProviders) {
      if (p.meta.containsTile(coordinates.z, coordinates.x, coordinates.y)) {
        return p.getImage(coordinates, options);
      }
    }

    // 2. Online: OSM (primary) or tileserver (offline fallback)
    if (_online) {
      return NetworkImage(
          _buildUrl(onlineUrl, coordinates.x, coordinates.y, coordinates.z));
    } else if (serverTileUrl != null) {
      return NetworkImage(
          _buildUrl(serverTileUrl!, coordinates.x, coordinates.y, coordinates.z));
    }
    return MemoryImage(TileProvider.transparentImage);
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
}
