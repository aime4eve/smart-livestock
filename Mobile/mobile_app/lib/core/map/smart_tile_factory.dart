import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_provider.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_resolver.dart';

/// Creates a fully-configured SmartTileProvider for a map page.
///
/// Loads user-downloaded mbtiles + built-in sample.mbtiles as local sources,
/// fetches the tileserver URL from the API, and selects the online source
/// (OSM for international, 高德 for China) based on the REGION dart-define.
///
/// Call `provider.probeConnectivity()` and `provider.startConnectivityMonitor()`
/// are already invoked inside this factory.
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

  // 3. Select online source based on REGION dart-define
  const region = String.fromEnvironment('REGION', defaultValue: 'overseas');
  final isChina = region == 'china';
  final onlineUrl =
      isChina ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl;

  // 4. Create provider (non-blocking, returns immediately)
  final provider = await SmartTileProvider.create(
    mbtilesProviders: mbtilesProviders,
    onlineUrl: onlineUrl,
    serverTileUrl: serverTileUrl,
    isGcj02Online: isChina,
    onSourceChanged: onSourceChanged,
  );

  // 5. Start background connectivity monitoring
  provider.probeConnectivity();
  provider.startConnectivityMonitor();

  return provider;
}
