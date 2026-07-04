import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:math' as math;

import 'map_config.dart';

/// In-memory metadata for an mbtiles file, enabling O(1) tile containment
/// checks without SQLite queries.
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

  /// Fast in-memory check: does this file *potentially* contain the tile at
  /// (z, x, y)?  Returns false if the zoom is out of range or the tile's
  /// geographic extent falls entirely outside the file's bounds.
  bool containsTile(int z, int x, int y) {
    if (z < minZoom || z > maxZoom) return false;

    final n = 1 << z; // 2^z tiles per axis

    // Tile X → longitude: lon = x / n * 360 - 180
    final tileMinLon = x / n * 360.0 - 180.0;
    final tileMaxLon = (x + 1) / n * 360.0 - 180.0;
    if (tileMaxLon < minLon || tileMinLon > maxLon) return false;

    // Tile Y → latitude (Web Mercator inverse)
    final tileMaxLat = _yToLat(y, n);
    final tileMinLat = _yToLat(y + 1, n);
    if (tileMaxLat < minLat || tileMinLat > maxLat) return false;

    return true;
  }

  /// Web Mercator: slippy-map y at zoom with n = 2^z tiles → latitude.
  static double _yToLat(int y, int n) {
    final ratio = math.pi * (1.0 - 2.0 * y / n);
    // sinh(x) = (e^x - e^-x) / 2 — not in dart:math
    final sinhRatio = (math.exp(ratio) - math.exp(-ratio)) / 2.0;
    return math.atan(sinhRatio) * 180.0 / math.pi;
  }
}

class MBTilesTileProvider extends TileProvider {
  final Database _db;
  final MbtilesMeta meta;
  bool _disposed = false;

  MBTilesTileProvider(this.meta) : _db = sqlite3.open(meta.filePath);

  /// Open an mbtiles file from the filesystem, reading metadata into memory.
  static MBTilesTileProvider open(String filePath) {
    final db = sqlite3.open(filePath);
    final meta = _readMeta(db, filePath);
    db.dispose();
    return MBTilesTileProvider._withDb(meta, sqlite3.open(filePath));
  }

  MBTilesTileProvider._withDb(this.meta, this._db);

  static MbtilesMeta _readMeta(Database db, String filePath) {
    int minZoom = 0, maxZoom = 20;
    double minLon = -180, minLat = -85, maxLon = 180, maxLat = 85;

    try {
      final zoomRows = db.select(
        'SELECT MIN(zoom_level) as min_z, MAX(zoom_level) as max_z FROM tiles',
      );
      if (zoomRows.isNotEmpty) {
        minZoom = zoomRows.first['min_z'] as int? ?? 0;
        maxZoom = zoomRows.first['max_z'] as int? ?? 20;
      }
    } catch (_) {}

    try {
      final boundsRow = db.select(
        "SELECT value FROM metadata WHERE name = 'bounds'",
      );
      if (boundsRow.isNotEmpty) {
        final parts = (boundsRow.first['value'] as String).split(',');
        if (parts.length >= 4) {
          minLon = double.tryParse(parts[0]) ?? minLon;
          minLat = double.tryParse(parts[1]) ?? minLat;
          maxLon = double.tryParse(parts[2]) ?? maxLon;
          maxLat = double.tryParse(parts[3]) ?? maxLat;
        }
      }
    } catch (_) {}

    return MbtilesMeta(
      filePath: filePath,
      minZoom: minZoom,
      maxZoom: maxZoom,
      minLon: minLon,
      minLat: minLat,
      maxLon: maxLon,
      maxLat: maxLat,
    );
  }

  static Future<MBTilesTileProvider?> fromAsset() async {
    final data = await rootBundle.load(MapConfig.mbtilesAssetPath);
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/${MapConfig.mbtilesFileName}');
    await file.writeAsBytes(data.buffer.asUint8List());
    return MBTilesTileProvider.open(file.path);
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    if (!meta.containsTile(coordinates.z, coordinates.x, coordinates.y)) {
      return MemoryImage(TileProvider.transparentImage);
    }
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

  bool hasTile(int z, int x, int y) {
    if (_disposed) return false;
    if (!meta.containsTile(z, x, y)) return false;
    final tmsY = (1 << z) - 1 - y;
    final rows = _db.select(
      'SELECT 1 FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1',
      [z, x, tmsY],
    );
    return rows.isNotEmpty;
  }

  @override
  void dispose() {
    if (!_disposed) {
      _db.dispose();
      _disposed = true;
    }
  }
}
