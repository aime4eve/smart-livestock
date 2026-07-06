import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';

void main() {
  const osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  const amapUrl =
      'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}';

  group('SmartTileProvider', () {
    test('primary (OSM) → shouldTransformCoordinates false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        fallbackOnlineUrl: amapUrl,
      );
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('secondary (高德) → shouldTransformCoordinates true', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        fallbackOnlineUrl: amapUrl,
      );
      provider.simulateSecondary();
      expect(provider.shouldTransformCoordinates(), isTrue);
    });

    test('offline → shouldTransformCoordinates false', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        fallbackOnlineUrl: amapUrl,
        serverTileUrl: 'http://example.com/tiles/{z}/{x}/{y}.png',
      );
      provider.simulateOffline();
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('getImage primary → OSM NetworkImage', () {
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        fallbackOnlineUrl: amapUrl,
      );
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });

    test('getImage offline + serverTileUrl → tileserver NetworkImage', () {
      const serverUrl =
          'http://172.22.1.123:18080/tiles/changsha/{z}/{x}/{y}.png';
      final provider = SmartTileProvider(
        mbtilesProviders: [],
        onlineUrl: osmUrl,
        fallbackOnlineUrl: amapUrl,
        serverTileUrl: serverUrl,
      );
      provider.simulateOffline();
      const coords = TileCoordinates(3332, 1712, 12);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });
  });
}
