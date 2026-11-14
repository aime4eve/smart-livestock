import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/core/map/mbtiles_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';

/// NIX-237: the GCJ-02 transform decision must follow the tiles ACTUALLY
/// serving a point, not the global online-source flag. Local mbtiles
/// (self-hosted OSM, WGS-84) and the server tileserver fallback (WGS-84)
/// suppress the transform; only the 高德 online source (GCJ-02) wants it.
void main() {
  // The decision path never touches the tile bytes — only meta.containsTile
  // (pure geometry) — so an empty sqlite file stands in for a real mbtiles.
  late Directory tempDir;
  late String fakeMbtilesPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nix237-mbtiles');
    fakeMbtilesPath = '${tempDir.path}/region.mbtiles';
    File(fakeMbtilesPath).writeAsBytesSync([]);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  MBTilesTileProvider regionProvider({
    double minLon = 112.0,
    double minLat = 28.0,
    double maxLon = 113.0,
    double maxLat = 29.0,
    int minZoom = 12,
    int maxZoom = 15,
  }) {
    final meta = MbtilesMeta(
      filePath: fakeMbtilesPath,
      minZoom: minZoom,
      maxZoom: maxZoom,
      minLon: minLon,
      minLat: minLat,
      maxLon: maxLon,
      maxLat: maxLat,
    );
    return MBTilesTileProvider(meta);
  }

  SmartTileProvider provider({
    required bool gcj,
    List<MBTilesTileProvider> mbtiles = const [],
  }) {
    return SmartTileProvider(
      mbtilesProviders: mbtiles,
      onlineUrl: 'https://tiles.example/{z}/{x}/{y}.png',
      onlineIsGcj02: gcj,
    );
  }

  const changsha = LatLng(28.2282, 112.9388);

  test('高德在线 + 无本地瓦片：需要变换（原全局 flag 语义，真高德区域）', () {
    final p = provider(gcj: true)..simulatePrimary();
    expect(p.shouldTransformAt(changsha), isTrue);
  });

  test('高德在线 + 本地 mbtiles 覆盖该点：不变换（离线瓦片是 WGS-84）', () {
    final p = provider(gcj: true, mbtiles: [regionProvider()])
      ..simulatePrimary();
    expect(p.shouldTransformAt(changsha), isFalse);
  });

  test('高德在线 + 本地 mbtiles 只覆盖远处：仍需变换', () {
    final p = provider(
      gcj: true,
      mbtiles: [regionProvider(minLon: 120.0, maxLon: 121.0)],
    )..simulatePrimary();
    expect(p.shouldTransformAt(changsha), isTrue);
  });

  test('高德在线 + mbtiles 覆盖但该 zoom 超出文件范围：需变换（在线接管）', () {
    final p = provider(gcj: true, mbtiles: [regionProvider(maxZoom: 15)])
      ..simulatePrimary();
    // z16 is beyond the file's maxZoom — the online source serves the tile.
    expect(p.shouldTransformAt(changsha, zoom: 16), isTrue);
    // z14 (default) stays inside the range → no transform.
    expect(p.shouldTransformAt(changsha), isFalse);
  });

  test('离线回落（server tileserver = WGS-84）：永不变换', () {
    final p = provider(gcj: true)..simulateOffline();
    expect(p.shouldTransformAt(changsha), isFalse);
  });

  test('非中国时区（OSM = WGS-84）：永不变换', () {
    final p = provider(gcj: false)..simulatePrimary();
    expect(p.shouldTransformAt(changsha), isFalse);
  });

  test('无锚点回落：全局 flag 语义保留（ranch_page 混合范式）', () {
    final gcjP = provider(gcj: true)..simulatePrimary();
    final offlineP = provider(gcj: true)..simulateOffline();
    expect(gcjP.shouldTransformCoordinates(), isTrue);
    expect(offlineP.shouldTransformCoordinates(), isFalse);
  });
}
