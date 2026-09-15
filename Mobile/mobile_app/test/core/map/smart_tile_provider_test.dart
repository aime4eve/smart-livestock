import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';

void main() {
  const osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  const amapUrl =
      'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}';

  group('SmartTileProvider', () {
    test('OSM online → shouldTransformCoordinates false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
      );
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('高德 online → shouldTransformCoordinates true', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        onlineIsGcj02: true,
      );
      expect(provider.shouldTransformCoordinates(), isTrue);
    });

    test('高德 online but offline (server tiles) → transform false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        onlineIsGcj02: true,
        serverTileUrl: 'http://example.com/tiles/{z}/{x}/{y}.png',
      );
      provider.simulateOffline();
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('activeSourceName reflects the configured online source', () {
      final amap = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        onlineIsGcj02: true,
      );
      expect(amap.activeSourceName, '高德');
      final osm = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
      );
      expect(osm.activeSourceName, 'OSM');
      osm.simulateOffline();
      expect(osm.activeSourceName, 'Server');
    });

    test('getImage online → NetworkImage from configured source', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        onlineIsGcj02: true,
      );
      provider.simulatePrimary();
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
      final network = img as NetworkImage;
      expect(network.url, contains('autonavi.com'));
    });

    test('getImage offline + serverTileUrl → tileserver NetworkImage', () {
      const serverUrl =
          'http://172.22.1.123:18080/tiles/changsha/{z}/{x}/{y}.png';
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        serverTileUrl: serverUrl,
      );
      provider.simulateOffline();
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
      expect((img as NetworkImage).url,
          'http://172.22.1.123:18080/tiles/changsha/12/3332/1712.png');
    });
  });
}
