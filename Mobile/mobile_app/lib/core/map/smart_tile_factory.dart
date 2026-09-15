import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_provider.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_resolver.dart';
import 'package:hkt_livestock_agentic/core/timezone/time_zone_controller.dart';

/// Builds the app-wide [SmartTileProvider] from explicit inputs.
///
/// The online tile source is fixed by the client time zone: China
/// (北京/上海时区, [useChinaTileSource]) → 高德 (GCJ-02), otherwise OSM
/// (WGS-84). No cross-source switching; the connectivity probe only decides
/// when to fall back to the self-hosted tileserver ([serverTileUrl]).
Future<SmartTileProvider> buildSmartTileProvider({
  required List<MBTilesTileProvider> mbtilesProviders,
  required bool useChinaTileSource,
  Future<List<TileSource>> Function()? resolveTileSources,
  VoidCallback? onSourceChanged,
}) async {
  // Server-side offline fallback (best effort, never blocks map init).
  String? serverTileUrl;
  if (resolveTileSources != null) {
    try {
      final sources =
          await resolveTileSources().timeout(const Duration(seconds: 5));
      serverTileUrl = sources.isEmpty ? null : sources.first.tileUrl;
    } catch (_) {}
  }

  final provider = await SmartTileProvider.create(
    mbtilesProviders: mbtilesProviders,
    onlineUrl:
        useChinaTileSource ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl,
    onlineIsGcj02: useChinaTileSource,
    serverTileUrl: serverTileUrl,
    onSourceChanged: onSourceChanged,
  );

  provider.probeConnectivity();
  provider.startConnectivityMonitor();
  return provider;
}

/// Widget-side adapter: collects local state and delegates to
/// [buildSmartTileProvider].
Future<SmartTileProvider> loadSmartTileProvider(
  WidgetRef ref, {
  VoidCallback? onSourceChanged,
}) async {
  // Locally available mbtiles (user-downloaded regions only).
  final mbtilesProviders = <MBTilesTileProvider>[];
  if (!kIsWeb) {
    final mgr = ref.read(offlineTileManagerProvider);
    for (final path in mgr.getLocalMbtilesFiles()) {
      try {
        mbtilesProviders.add(MBTilesTileProvider.open(path));
      } catch (_) {}
    }
  }

  return buildSmartTileProvider(
    mbtilesProviders: mbtilesProviders,
    useChinaTileSource:
        ref.read(timeZoneControllerProvider.notifier).useChinaTileSource,
    resolveTileSources: ApiClient.instance.activeFarmId == null
        ? null
        : () => ref.read(tileSourceResolverProvider).resolve(),
    onSourceChanged: onSourceChanged,
  );
}
