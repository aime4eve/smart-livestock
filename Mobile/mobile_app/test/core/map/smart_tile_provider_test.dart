import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';

void main() {
  const osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  const amapUrl =
      'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}';

  group('SmartTileProvider', () {
    test('OSM online → shouldTransformCoordinates returns false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        serverTileUrl: null,
        isGcj02Online: false,
      );
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('GCJ-02 online (高德) + online → shouldTransformCoordinates true', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        serverTileUrl: null,
        isGcj02Online: true,
      );
      expect(provider.shouldTransformCoordinates(), isTrue);
    });

    test('GCJ-02 online but offline → shouldTransformCoordinates false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: amapUrl,
        serverTileUrl: 'http://example.com/tiles/{z}/{x}/{y}.png',
        isGcj02Online: true,
      );
      provider.simulateOffline();
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('getImage with no local mbtiles + online → returns NetworkImage', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        serverTileUrl: null,
        isGcj02Online: false,
      );
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });

    test('getImage offline + no local mbtiles → falls to serverTileUrl', () {
      const serverUrl =
          'http://172.22.1.123:18080/tiles/changsha/{z}/{x}/{y}.png';
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        serverTileUrl: serverUrl,
        isGcj02Online: false,
      );
      provider.simulateOffline();
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });
  });
}
