import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class MBTilesTileProvider extends TileProvider {
  MBTilesTileProvider(String _);

  static Future<MBTilesTileProvider?> fromAsset() async => null;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }

  bool hasTile(int z, int x, int y) => false;

  @override
  void dispose() {}
}
