import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_provider.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_resolver.dart';

/// Creates a fully-configured SmartTileProvider for any map page.
///
/// OSM is always the primary online source (for international markets).
/// 高德 is always the secondary fallback (for China where OSM is blocked).
/// The connectivity probe auto-detects which one works and switches accordingly.
Future<SmartTileProvider> loadSmartTileProvider(
  WidgetRef ref, {
  VoidCallback? onSourceChanged,
}) async {
  // 1. Collect local mbtiles providers
  final mbtilesProviders = <MBTilesTileProvider>[];

  if (!kIsWeb) {
    // User-downloaded tiles (highest priority)
    final mgr = ref.read(offlineTileManagerProvider);
    for (final path in mgr.getLocalMbtilesFiles()) {
      try {
        mbtilesProviders.add(MBTilesTileProvider.open(path));
      } catch (_) {}
    }
    // Built-in sample.mbtiles as last-resort fallback
    final builtin = await MBTilesTileProvider.fromAsset();
    if (builtin != null) mbtilesProviders.add(builtin);
  }

  // 2. Get tileserver URL from API (server-side offline fallback)
  String? serverTileUrl;
  if (ApiClient.instance.activeFarmId != null) {
    try {
      final sources = await ref.read(tileSourceResolverProvider).resolve();
      serverTileUrl = sources.isEmpty ? null : sources.first.tileUrl;
    } catch (_) {}
  }

  // 3. Create provider: OSM primary + 高德 secondary + tileserver offline
  final provider = await SmartTileProvider.create(
    mbtilesProviders: mbtilesProviders,
    onlineUrl: MapConfig.overseasFallbackUrl,
    fallbackOnlineUrl: MapConfig.chinaFallbackUrl,
    serverTileUrl: serverTileUrl,
    onSourceChanged: onSourceChanged,
  );

  // 4. Start background connectivity monitoring
  provider.probeConnectivity();
  provider.startConnectivityMonitor();

  return provider;
}
