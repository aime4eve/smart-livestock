import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/tile_source_resolver.dart';

TileSource _src(String url) => TileSource(sourceName: 'server', tileUrl: url);

void main() {
  group('buildSmartTileProvider — tile source by client time zone', () {
    test('China time zone → single 高德 source with GCJ-02 transform', () async {
      final provider = await buildSmartTileProvider(
        mbtilesProviders: const [],
        useChinaTileSource: true,
      );
      expect(provider.onlineUrl, MapConfig.chinaFallbackUrl);
      expect(provider.shouldTransformCoordinates(), isTrue);
      expect(provider.activeSourceName, '高德');
      provider.dispose();
    });

    test('non-China time zone → single OSM source, no transform', () async {
      final provider = await buildSmartTileProvider(
        mbtilesProviders: const [],
        useChinaTileSource: false,
      );
      expect(provider.onlineUrl, MapConfig.overseasFallbackUrl);
      expect(provider.shouldTransformCoordinates(), isFalse);
      expect(provider.activeSourceName, 'OSM');
      provider.dispose();
    });

    test('tile-source resolve failure never blocks provider creation',
        () async {
      final provider = await buildSmartTileProvider(
        mbtilesProviders: const [],
        useChinaTileSource: true,
        resolveTileSources: () async {
          await Future<void>.delayed(const Duration(seconds: 30));
          return [_src('http://server/{z}/{x}/{y}.png')];
        },
      );
      // resolve() is slow (>5s timeout) → serverTileUrl stays null, provider
      // is still created and online-capable.
      expect(provider.isOnline, isTrue);
      provider.dispose();
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('offline probe falls back to server tiles when online unreachable',
        () async {
      final provider = await buildSmartTileProvider(
        mbtilesProviders: const [],
        useChinaTileSource: true,
        resolveTileSources: () async => [_src('http://server/{z}/{x}/{y}.png')],
      );
      provider.simulateOffline();
      expect(provider.shouldTransformCoordinates(), isFalse);
      expect(provider.activeSourceName, 'Server');
      provider.dispose();
    });
  });
}
