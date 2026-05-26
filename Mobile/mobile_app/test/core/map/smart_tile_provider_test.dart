import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:smart_livestock_demo/core/map/smart_tile_provider.dart';

void main() {
  group('SmartTileProvider', () {
    test('selfHosted 可用时 shouldTransformCoordinates 返回 false', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        fallbackUrl:
            'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}',
        isGcj02Fallback: true,
      );
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('GCJ-02 降级时 shouldTransformCoordinates 返回 true', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl: null,
        fallbackUrl:
            'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}',
        isGcj02Fallback: true,
      );
      expect(provider.shouldTransformCoordinates(), isTrue);
    });

    test('WGS-84 降级时 shouldTransformCoordinates 返回 false', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl: null,
        fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        isGcj02Fallback: false,
      );
      expect(provider.shouldTransformCoordinates(), isFalse);
    });

    test('getImage 返回 selfHosted NetworkImage', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl: 'http://172.22.1.123:18080/tiles/{z}/{x}/{y}.png',
        fallbackUrl:
            'https://webrd02.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}',
        isGcj02Fallback: true,
      );
      final coords = TileCoordinates(851, 852, 10);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });

    test('selfHosted 为 null 时降级到 fallback', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl: null,
        fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        isGcj02Fallback: false,
      );
      final coords = TileCoordinates(851, 852, 10);
      final img = provider.getImage(coords, TileLayer());
      expect(img, isA<NetworkImage>());
    });
  });
}
