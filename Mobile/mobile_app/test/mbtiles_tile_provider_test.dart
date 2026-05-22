import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:smart_livestock_demo/core/map/mbtiles_tile_provider.dart';

void main() {
  late String testDbPath;
  late MBTilesTileProvider provider;

  setUp(() async {
    // Create a minimal MBTiles file in temp directory
    final dir = Directory.systemTemp.createTempSync('mbtiles_test_');
    testDbPath = '${dir.path}/test.mbtiles';

    final db = sqlite3.open(testDbPath);
    db.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
    db.execute(
      'CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)',
    );
    db.execute(
      'CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)',
    );

    // Insert metadata
    db.execute("INSERT INTO metadata (name, value) VALUES ('minzoom', '12')");
    db.execute("INSERT INTO metadata (name, value) VALUES ('maxzoom', '14')");
    db.execute("INSERT INTO metadata (name, value) VALUES ('format', 'png')");

    // Insert a test tile at z=13, x=13687, y=6892 (TMS y = 8191-6892 = 1299)
    // Using a minimal valid PNG (1x1 red pixel)
    final png = _makeTestPng();
    const tmsY = (1 << 13) - 1 - 6892; // = 1299
    db.execute(
      'INSERT INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?, ?, ?, ?)',
      [13, 13687, tmsY, png],
    );

    db.dispose();

    provider = MBTilesTileProvider(testDbPath);
  });

  tearDown(() {
    provider.dispose();
    final dir = Directory(testDbPath).parent;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('reads metadata from MBTiles', () {
    expect(provider.getMetadata('format'), 'png');
    expect(provider.getMetadata('minzoom'), '12');
    expect(provider.getMetadata('maxzoom'), '14');
    expect(provider.getMetadata('nonexistent'), isNull);
  });

  test('reads zoom range', () {
    final range = provider.zoomRange;
    expect(range, isNotNull);
    expect(range!.min, 13);
    expect(range.max, 13);
  });

  test('getImage returns MemoryImage for existing tile', () {
    final image = provider.getImage(
      TileCoordinates(13687, 6892, 13),
      TileLayer(urlTemplate: ''),
    );
    expect(image, isA<MemoryImage>());
    final mem = image as MemoryImage;
    expect(mem.bytes, isNotEmpty);
  });

  test('getImage returns transparent PNG for missing tile', () {
    final image = provider.getImage(
      TileCoordinates(0, 0, 5), // z=5 is outside our range
      TileLayer(urlTemplate: ''),
    );
    expect(image, isA<MemoryImage>());
    // Should be the transparent image
    final mem = image as MemoryImage;
    expect(mem.bytes, equals(TileProvider.transparentImage));
  });

  test('TMS Y axis boundary: z=0, y=0 → tmsY=0', () {
    // At z=0, there's only one tile: (0,0). TMS y = (1-1)-0 = 0
    // This tile doesn't exist in our test DB, so it returns transparent
    final image = provider.getImage(
      TileCoordinates(0, 0, 0),
      TileLayer(urlTemplate: ''),
    );
    expect(image, isA<MemoryImage>());
  });

  test('getImage for different TMS Y coordinates', () {
    // y=6891 (neighbor) should be missing
    final image = provider.getImage(
      TileCoordinates(13687, 6891, 13),
      TileLayer(urlTemplate: ''),
    );
    expect(image, isA<MemoryImage>());
    final mem = image as MemoryImage;
    expect(mem.bytes, equals(TileProvider.transparentImage));
  });
}

/// Minimal valid 1x1 red PNG
Uint8List _makeTestPng() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // RGB
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, // red pixel
    0x00, 0x01, 0x01, 0x00, 0x05, 0x18, 0xD8, 0x4A,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
    0xAE, 0x42, 0x60, 0x82,
  ]);
}
