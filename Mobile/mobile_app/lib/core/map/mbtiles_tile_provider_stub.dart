import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Web stub — all methods are no-ops (no SQLite in browser).
class MbtilesMeta {
  final String filePath;
  final int minZoom;
  final int maxZoom;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  MbtilesMeta({
    required this.filePath,
    required this.minZoom,
    required this.maxZoom,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });

  bool containsTile(int z, int x, int y) => false;
}

class MBTilesTileProvider extends TileProvider {
  final MbtilesMeta meta;

  MBTilesTileProvider(this.meta);

  static MBTilesTileProvider open(String filePath) =>
      MBTilesTileProvider(MbtilesMeta(
        filePath: filePath,
        minZoom: 0, maxZoom: 0,
        minLon: 0, minLat: 0, maxLon: 0, maxLat: 0,
      ));

  static Future<MBTilesTileProvider?> fromAsset() async => null;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }

  bool hasTile(int z, int x, int y) => false;

  bool containsTile(int z, int x, int y) => false;

  @override
  void dispose() {}
}
