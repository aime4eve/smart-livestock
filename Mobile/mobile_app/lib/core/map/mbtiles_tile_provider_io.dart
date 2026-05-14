import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'map_config.dart';

class MBTilesTileProvider extends TileProvider {
  final Database _db;
  bool _disposed = false;

  MBTilesTileProvider(String mbtilesPath) : _db = sqlite3.open(mbtilesPath);

  static Future<MBTilesTileProvider?> fromAsset() async {
    final data = await rootBundle.load(MapConfig.mbtilesAssetPath);
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/${MapConfig.mbtilesFileName}');
    await file.writeAsBytes(data.buffer.asUint8List());
    return MBTilesTileProvider(file.path);
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // TMS Y axis flip: XYZ slippy map y → TMS y
    final tmsY = (1 << coordinates.z) - 1 - coordinates.y;

    final rows = _db.select(
      'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',
      [coordinates.z, coordinates.x, tmsY],
    );

    if (rows.isEmpty || rows.first['tile_data'] == null) {
      return MemoryImage(TileProvider.transparentImage);
    }

    final blob = rows.first['tile_data'];
    final bytes = blob is Uint8List
        ? blob
        : Uint8List.fromList((blob as List).cast<int>());
    return MemoryImage(bytes);
  }

  String? getMetadata(String name) {
    final rows = _db.select(
      'SELECT value FROM metadata WHERE name = ?',
      [name],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  ({int min, int max})? get zoomRange {
    final rows = _db.select(
      'SELECT MIN(zoom_level) as min_z, MAX(zoom_level) as max_z FROM tiles',
    );
    if (rows.isEmpty) return null;
    return (min: rows.first['min_z'] as int, max: rows.first['max_z'] as int);
  }

  @override
  void dispose() {
    if (!_disposed) {
      _db.dispose();
      _disposed = true;
    }
  }
}
