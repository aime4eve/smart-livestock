# 多区域地图瓦片统一方案实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现自建 tileserver-gl + 三级回退 SmartTileProvider，解决国内地图瓦片被墙问题，同时保持 WGS-84 坐标系一致性。

**Architecture:** 海外服务器生成 MBTiles → rsync 到国内 tileserver-gl → Flutter SmartTileProvider 优先级链（tileserver → MBTiles → 高德/OSM 降级）。MapConfig 存 WGS-84 纯数据，调用方根据活跃瓦片源决定坐标转换。

**Tech Stack:** Flutter (flutter_map 8.2.2, sqlite3, http), Spring Boot 3.x, Docker (tileserver-gl, nginx), Python (OSM Planet + Mapnik)

**Design Spec:** `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`

---

## File Structure

### Flutter — Create

| File | Responsibility |
|------|---------------|
| `Mobile/mobile_app/lib/core/map/smart_tile_provider.dart` | 三级回退 TileProvider |
| `Mobile/mobile_app/test/core/map/coord_transform_test.dart` | gcj02ToWgs84 逆转换测试 |
| `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart` | SmartTileProvider 测试 |

### Flutter — Modify

| File | Change |
|------|--------|
| `Mobile/mobile_app/lib/core/map/coord_transform.dart` | 新增 `gcj02ToWgs84()` + `gcj02ToWgs84All()` |
| `Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_io.dart` | 新增 `hasTile()` 方法 |
| `Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_stub.dart` | 新增 `hasTile()` stub |
| `Mobile/mobile_app/lib/core/map/map_config.dart` | WGS-84 原始坐标 + 新 URL 常量 |
| `Mobile/mobile_app/lib/features/pages/fence_page.dart` | 替换为 SmartTileProvider + 围栏保存逆转换 |
| `Mobile/mobile_app/lib/features/pages/fence_form_page.dart` | 同上 |
| `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_basic_info.dart` | 同上 |
| `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_fence_drawing.dart` | 同上 + 保存时 gcj02ToWgs84 |

### Backend — Create

| File | Responsibility |
|------|---------------|
| `smart-livestock-server/infrastructure/tileserver/data/config.json` | tileserver-gl 配置 |
| `tooling/generate_mbtiles.py` | 海外 MBTiles 生成脚本 |
| `tooling/import_mbtiles.sh` | MBTiles 导入 + config.json 自动生成 |

### Backend — Modify

| File | Change |
|------|--------|
| `smart-livestock-server/docker-compose.yml` | 新增 tileserver 服务 |
| `smart-livestock-server/infrastructure/nginx/nginx.conf` | 新增 `/tiles/` location |

---

## Task 1: CoordTransform gcj02ToWgs84 逆转换

**Files:**
- Modify: `Mobile/mobile_app/lib/core/map/coord_transform.dart`
- Create: `Mobile/mobile_app/test/core/map/coord_transform_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/map/coord_transform_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';

void main() {
  group('gcj02ToWgs84', () {
    test('round-trip wgs84→gcj02→wgs84 偏差 < 0.5m', () {
      final points = [
        LatLng(28.2282, 112.9388),  // 长沙
        LatLng(39.9042, 116.4074),  // 北京
        LatLng(31.2304, 121.4737),  // 上海
        LatLng(43.8256, 87.6168),   // 乌鲁木齐
        LatLng(40.8422, 111.7500),  // 呼和浩特
      ];
      for (final wgs in points) {
        final gcj = CoordTransform.wgs84ToGcj02(wgs);
        final roundTrip = CoordTransform.gcj02ToWgs84(gcj);
        final distance = _haversine(wgs, roundTrip);
        expect(distance, lessThan(0.5),
            reason: '${wgs.latitude},${wgs.longitude} round-trip ${distance}m >= 0.5m');
      }
    });

    test('海外坐标不变', () {
      final sydney = LatLng(-33.8688, 151.2093);
      expect(CoordTransform.gcj02ToWgs84(sydney), equals(sydney));
    });

    test('迭代收敛精度 < 0.1m', () {
      final wgs = LatLng(28.2282, 112.9388);
      final gcj = CoordTransform.wgs84ToGcj02(wgs);
      final inverse = CoordTransform.gcj02ToWgs84(gcj);
      final distance = _haversine(wgs, inverse);
      expect(distance, lessThan(0.1),
          reason: '迭代收敛 ${distance}m >= 0.1m');
    });
  });

  group('gcj02ToWgs84All', () {
    test('批量逆转换', () {
      final originals = [
        LatLng(28.2282, 112.9388),
        LatLng(39.9042, 116.4074),
      ];
      final gcjPoints = CoordTransform.wgs84ToGcj02All(originals);
      final wgsPoints = CoordTransform.gcj02ToWgs84All(gcjPoints);
      expect(wgsPoints.length, 2);
      for (int i = 0; i < originals.length; i++) {
        expect(_haversine(originals[i], wgsPoints[i]), lessThan(0.5));
      }
    });
  });
}

double _haversine(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLng = (b.longitude - a.longitude) * pi / 180;
  final sin1 = sin(dLat / 2);
  final sin2 = sin(dLng / 2);
  final h = sin1 * sin1 +
      cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180) * sin2 * sin2;
  return 2 * r * asin(sqrt(h));
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/mobile_app && flutter test test/core/map/coord_transform_test.dart`
Expected: FAIL — `gcj02ToWgs84` 方法不存在

- [ ] **Step 3: 实现 gcj02ToWgs84**

在 `lib/core/map/coord_transform.dart` 的 `wgs84ToGcj02All` 方法后添加：

```dart
  /// GCJ-02 → WGS-84 迭代法逆转换（精度 < 0.1m）
  static LatLng gcj02ToWgs84(LatLng gcj) {
    if (_outOfChina(gcj.latitude, gcj.longitude)) return gcj;
    var guess = gcj;
    for (int i = 0; i < 10; i++) {
      final transformed = wgs84ToGcj02(guess);
      final dLat = guess.latitude - transformed.latitude;
      final dLng = guess.longitude - transformed.longitude;
      if (dLat.abs() < 1e-8 && dLng.abs() < 1e-8) break;
      guess = LatLng(guess.latitude + dLat, guess.longitude + dLng);
    }
    return guess;
  }

  /// 批量逆转换
  static List<LatLng> gcj02ToWgs84All(List<LatLng> points) {
    return points.map(gcj02ToWgs84).toList();
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/core/map/coord_transform_test.dart`
Expected: ALL PASS

- [ ] **Step 5: 运行全量测试确认无回归**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 与基线一致（300/303 通过，3 个已知失败）

- [ ] **Step 6: 提交**

```bash
git add Mobile/mobile_app/lib/core/map/coord_transform.dart \
        Mobile/mobile_app/test/core/map/coord_transform_test.dart
git commit -m "feat(flutter): add gcj02ToWgs84 inverse coordinate transform

Iterative convergence < 0.1m, round-trip accuracy < 0.5m"
```

---

## Task 2: MBTilesTileProvider.hasTile + SmartTileProvider

**Files:**
- Modify: `Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_io.dart`
- Modify: `Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_stub.dart`
- Create: `Mobile/mobile_app/lib/core/map/smart_tile_provider.dart`
- Create: `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart`

### 2a: MBTilesTileProvider.hasTile

- [ ] **Step 1: 在 IO 实现中添加 hasTile**

在 `mbtiles_tile_provider_io.dart` 的 `zoomRange` getter 后添加：

```dart
  /// 检查指定瓦片是否存在（用于 SmartTileProvider 回退判断）
  bool hasTile(int z, int x, int y) {
    if (_disposed) return false;
    final tmsY = (1 << z) - 1 - y;
    final rows = _db.select(
      'SELECT 1 FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ? LIMIT 1',
      [z, x, tmsY],
    );
    return rows.isNotEmpty;
  }
```

- [ ] **Step 2: 在 stub 中添加 hasTile**

在 `mbtiles_tile_provider_stub.dart` 的 `dispose()` 前添加：

```dart
  bool hasTile(int z, int x, int y) => false;
```

### 2b: SmartTileProvider

- [ ] **Step 3: 写 SmartTileProvider 测试**

```dart
// test/core/map/smart_tile_provider_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:smart_livestock_demo/core/map/smart_tile_provider.dart';

void main() {
  group('SmartTileProvider', () {
    test('selfHosted 可用时 shouldTransformCoordinates 返回 false', () {
      final provider = SmartTileProvider(
        selfHostedTileUrl:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
        selfHostedTileUrl:
            'http://172.22.1.123:18080/tiles/{z}/{x}/{y}.png',
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
```

- [ ] **Step 4: 运行测试确认失败**

Run: `cd Mobile/mobile_app && flutter test test/core/map/smart_tile_provider_test.dart`
Expected: FAIL — `SmartTileProvider` 类不存在

- [ ] **Step 5: 实现 SmartTileProvider**

```dart
// lib/core/map/smart_tile_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:smart_livestock_demo/core/map/mbtiles_tile_provider.dart';

enum _TileSource { selfHosted, mbtiles, fallback }

/// 三级回退 TileProvider：tileserver-gl → MBTiles → 高德/OSM
class SmartTileProvider extends TileProvider {
  final String? selfHostedTileUrl;
  final MBTilesTileProvider? mbtilesProvider;
  final String? fallbackUrl;
  final bool isGcj02Fallback;

  _TileSource _activeSource = _TileSource.selfHosted;
  VoidCallback? onSourceChanged;

  SmartTileProvider({
    this.selfHostedTileUrl,
    this.mbtilesProvider,
    this.fallbackUrl,
    this.isGcj02Fallback = false,
    this.onSourceChanged,
  }) {
    if (selfHostedTileUrl == null) {
      _activeSource =
          mbtilesProvider != null ? _TileSource.mbtiles : _TileSource.fallback;
    }
  }

  /// 异步工厂：初始化 MBTiles + 健康检查
  static Future<SmartTileProvider> create({
    String? selfHostedTileUrl,
    MBTilesTileProvider? mbtilesProvider,
    String? fallbackUrl,
    bool isGcj02Fallback = false,
    VoidCallback? onSourceChanged,
  }) async {
    final provider = SmartTileProvider(
      selfHostedTileUrl: selfHostedTileUrl,
      mbtilesProvider: mbtilesProvider,
      fallbackUrl: fallbackUrl,
      isGcj02Fallback: isGcj02Fallback,
      onSourceChanged: onSourceChanged,
    );
    await provider.performHealthCheck();
    return provider;
  }

  /// 当前活跃源是否使用 GCJ-02（渲染层据此决定坐标转换）
  bool shouldTransformCoordinates() =>
      _activeSource == _TileSource.fallback && isGcj02Fallback;

  bool get isSelfHostedActive => _activeSource == _TileSource.selfHosted;

  /// 健康检查：尝试从自建瓦片服务器获取一个瓦片
  Future<void> performHealthCheck() async {
    if (selfHostedTileUrl == null) return;
    try {
      final url = _buildUrl(selfHostedTileUrl!, 0, 0, 0);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode != 200) _degrade();
    } catch (_) {
      _degrade();
    }
  }

  /// 周期性重试主源（降级后每 60s 尝试恢复）
  void startHealthMonitor({Duration interval = const Duration(seconds: 60)}) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(interval, (_) async {
      if (_activeSource != _TileSource.selfHosted &&
          selfHostedTileUrl != null) {
        try {
          final url = _buildUrl(selfHostedTileUrl!, 0, 0, 0);
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            _switchTo(_TileSource.selfHosted);
          }
        } catch (_) {}
      }
    });
  }

  Timer? _healthTimer;

  void _degrade() {
    _switchTo(
        mbtilesProvider != null ? _TileSource.mbtiles : _TileSource.fallback);
  }

  void _switchTo(_TileSource source) {
    if (_activeSource == source) return;
    _activeSource = source;
    onSourceChanged?.call();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    switch (_activeSource) {
      case _TileSource.selfHosted:
        return NetworkImage(_buildUrl(
            selfHostedTileUrl!, coordinates.x, coordinates.y, coordinates.z));

      case _TileSource.mbtiles:
        if (mbtilesProvider != null &&
            mbtilesProvider!
                .hasTile(coordinates.z, coordinates.x, coordinates.y)) {
          return mbtilesProvider!.getImage(coordinates, options);
        }
        if (fallbackUrl != null) {
          return NetworkImage(_buildUrl(fallbackUrl!, coordinates.x,
              coordinates.y, coordinates.z));
        }
        return MemoryImage(TileProvider.transparentImage);

      case _TileSource.fallback:
        if (fallbackUrl != null) {
          return NetworkImage(_buildUrl(fallbackUrl!, coordinates.x,
              coordinates.y, coordinates.z));
        }
        return MemoryImage(TileProvider.transparentImage);
    }
  }

  static String _buildUrl(String template, int x, int y, int z) {
    return template
        .replaceFirst('{x}', x.toString())
        .replaceFirst('{y}', y.toString())
        .replaceFirst('{z}', z.toString());
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    mbtilesProvider?.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/core/map/smart_tile_provider_test.dart`
Expected: ALL PASS

- [ ] **Step 7: 运行全量测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 无回归

- [ ] **Step 8: 提交**

```bash
git add Mobile/mobile_app/lib/core/map/smart_tile_provider.dart \
        Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_io.dart \
        Mobile/mobile_app/lib/core/map/mbtiles_tile_provider_stub.dart \
        Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart
git commit -m "feat(flutter): add SmartTileProvider with 3-tier fallback

tileserver-gl → MBTiles → 高德/OSM, GCJ-02 coordinate awareness"
```

---

## Task 3: MapConfig 坐标动态化

**Files:**
- Modify: `Mobile/mobile_app/lib/core/map/map_config.dart`

- [ ] **Step 1: 修改 MapConfig — WGS-84 原始坐标 + 新 URL 常量**

关键变更：
- `defaultCenter` 和 `cityPresets` 改回 WGS-84 原始坐标（去掉 `CoordTransform.wgs84ToGcj02()`）
- 删除 `CoordTransform` import（MapConfig 不再做坐标转换）
- 新增 `selfHostedTileUrl`、`chinaFallbackUrl`、`overseasFallbackUrl`
- `tileUrlTemplate` 保留指向 `chinaFallbackUrl`（向后兼容，直到所有页面迁移到 SmartTileProvider）

```dart
import 'package:latlong2/latlong.dart';

class MapConfig {
  const MapConfig._();

  static const String defaultCity = '长沙';
  static const String defaultProvince = '湖南';
  static const String defaultCountry = '中国';

  /// 长沙市中心 WGS-84 坐标（渲染时根据瓦片源决定是否转 GCJ-02）
  static const LatLng defaultCenter = LatLng(28.2282, 112.9388);

  static const double defaultZoom = 13.0;
  static const double cacheRadius = 0.05;
  static const int cacheMinZoom = 11;
  static const int cacheMaxZoom = 15;

  // ── 瓦片源 URL ──

  static const String selfHostedTileUrl =
      'http://172.22.1.123:18080/tiles/{z}/{x}/{y}.png';

  static const String chinaFallbackUrl =
      'https://webrd02.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}';

  static const String overseasFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// 向后兼容（指向高德，迁移完成后可删除）
  static const String tileUrlTemplate = chinaFallbackUrl;

  static const String mbtilesAssetPath = 'assets/map/sample.mbtiles';
  static const String mbtilesFileName = 'sample.mbtiles';
  static const String cacheDirName = 'map_tiles';
  static const Duration cacheValidDuration = Duration(days: 30);

  /// 预设城市列表（WGS-84 原始坐标）
  static final List<MapPreset> cityPresets = [
    MapPreset(name: '长沙', province: '湖南', country: '中国', center: const LatLng(28.2282, 112.9388)),
    MapPreset(name: '北京', province: '北京', country: '中国', center: const LatLng(39.9042, 116.4074)),
    MapPreset(name: '上海', province: '上海', country: '中国', center: const LatLng(31.2304, 121.4737)),
    MapPreset(name: '乌鲁木齐', province: '新疆', country: '中国', center: const LatLng(43.8256, 87.6168)),
    MapPreset(name: '呼和浩特', province: '内蒙古', country: '中国', center: const LatLng(40.8422, 111.7500)),
    MapPreset(name: '悉尼', province: '新南威尔士', country: '澳大利亚', center: const LatLng(-33.8688, 151.2093)),
  ];
}

class MapPreset {
  const MapPreset({required this.name, required this.province, required this.country, required this.center});
  final String name;
  final String province;
  final String country;
  final LatLng center;
  String get displayName => '$country·$province·$name';
}
```

- [ ] **Step 2: 运行全量测试并修复坐标相关测试**

Run: `cd Mobile/mobile_app && flutter test`

测试中如有硬编码 GCJ-02 坐标值，需更新为 WGS-84 原始值（28.2282, 112.9388 等），或在测试中添加 `CoordTransform.wgs84ToGcj02()` 调用。

- [ ] **Step 3: 提交**

```bash
git add Mobile/mobile_app/lib/core/map/map_config.dart
git commit -m "refactor(flutter): MapConfig stores raw WGS-84 coordinates

Added selfHostedTileUrl, chinaFallbackUrl, overseasFallbackUrl.
Removed compile-time GCJ-02 transform — caller decides at render time."
```

---

## Task 4: fence_page.dart 渲染适配

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/fence_page.dart`

- [ ] **Step 1: 替换 fence_page.dart 的 TileLayer 和 PolygonLayer**

**a) 添加 import：**
```dart
import 'package:smart_livestock_demo/core/map/smart_tile_provider.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';
```

**b) 替换 State 字段：**

原来的 `MBTilesTileProvider? _mbtilesProvider` + `bool _mbtilesReady` 替换为：
```dart
SmartTileProvider? _tileProvider;
```

**c) 替换初始化逻辑：**

```dart
Future<void> _initTileProvider() async {
  MBTilesTileProvider? mbtiles;
  if (!kIsWeb) {
    mbtiles = await MBTilesTileProvider.fromAsset();
  }
  final region = const String.fromEnvironment('REGION', defaultValue: 'china');
  final isChina = region == 'china';
  _tileProvider = await SmartTileProvider.create(
    selfHostedTileUrl: MapConfig.selfHostedTileUrl,
    mbtilesProvider: mbtiles,
    fallbackUrl: isChina ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl,
    isGcj02Fallback: isChina,
    onSourceChanged: () { if (mounted) setState(() {}); },
  );
  _tileProvider!.startHealthMonitor();
  if (mounted) setState(() {});
}
```

**d) 替换 FlutterMap children 中的双 TileLayer 为单个：**
```dart
TileLayer(
  tileProvider: _tileProvider,
  maxZoom: MapConfig.cacheMaxZoom.toDouble(),
),
```

**e) 围栏顶点坐标转换辅助方法：**
```dart
List<LatLng> _mapVertices(List<LatLng> vertices) {
  if (_tileProvider?.shouldTransformCoordinates() ?? false) {
    return CoordTransform.wgs84ToGcj02All(vertices);
  }
  return vertices;
}
```

**f) 地图中心点根据瓦片源决定：**
```dart
final center = _tileProvider?.shouldTransformCoordinates() ?? false
    ? CoordTransform.wgs84ToGcj02(MapConfig.defaultCenter)
    : MapConfig.defaultCenter;
```

**g) dispose 清理：**
```dart
_tileProvider?.dispose();
```

- [ ] **Step 2: 运行全量测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 无回归

- [ ] **Step 3: 手动验证（可选）**

```bash
cd Mobile/mobile_app
flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

- [ ] **Step 4: 提交**

```bash
git add Mobile/mobile_app/lib/features/pages/fence_page.dart
git commit -m "feat(flutter): integrate SmartTileProvider into fence_page

Replace dual TileLayer with single SmartTileProvider.
Add GCJ-02 transform for polygon vertices when using 高德 fallback."
```

---

## Task 5: 其他围栏页面渲染适配

**Files:**
- Modify: `Mobile/mobile_app/lib/features/pages/fence_form_page.dart`
- Modify: `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_basic_info.dart`
- Modify: `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_fence_drawing.dart`

- [ ] **Step 1: 逐个页面替换 TileLayer**

每个页面做相同模式的修改：
1. 添加 import：`smart_tile_provider.dart`, `coord_transform.dart`
2. 添加 `SmartTileProvider? _tileProvider` 字段
3. 在 initState 或 didChangeDependencies 中初始化（同 Task 4 模式）
4. 替换 `TileLayer(urlTemplate: MapConfig.tileUrlTemplate, ...)` 为 `TileLayer(tileProvider: _tileProvider, ...)`
5. 地图中心点根据 `shouldTransformCoordinates()` 决定是否转换
6. dispose 中清理

**围栏绘制保存（wizard_step_fence_drawing.dart）的额外修改：**

提交围栏顶点到 API 前，检测是否需要逆转换：
```dart
List<LatLng> _verticesForSave(List<LatLng> drawnVertices) {
  if (_tileProvider?.shouldTransformCoordinates() ?? false) {
    return CoordTransform.gcj02ToWgs84All(drawnVertices);
  }
  return drawnVertices;
}
```

这是安全关键路径：高德降级时用户画的 GCJ-02 坐标必须逆转换为 WGS-84 后存储。

- [ ] **Step 2: 运行全量测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 无回归

- [ ] **Step 3: 提交**

```bash
git add Mobile/mobile_app/lib/features/fence/presentation/
git commit -m "feat(flutter): integrate SmartTileProvider into all fence pages

fence_form_page, wizard_step_basic_info, wizard_step_fence_drawing.
Add gcj02ToWgs84 inverse for fence drawing save path."
```

---

## Task 6: tileserver-gl Docker 部署

**Files:**
- Modify: `smart-livestock-server/docker-compose.yml`
- Modify: `smart-livestock-server/infrastructure/nginx/nginx.conf`
- Create: `smart-livestock-server/infrastructure/tileserver/data/config.json`

> **前提**：需要海外服务器（不被墙）可访问 OSM 数据，且已生成 MBTiles 文件。

- [ ] **Step 1: 创建 tileserver-gl 目录和配置**

```bash
mkdir -p smart-livestock-server/infrastructure/tileserver/data
```

```json
{
  "data": {
    "v3": {
      "mbtiles": ["changsha.mbtiles"]
    }
  },
  "options": {
    "port": 8080
  }
}
```

- [ ] **Step 2: 更新 docker-compose.yml 添加 tileserver 服务**

在 services 节点下添加：

```yaml
  tileserver:
    image: maptiler/tileserver-gl:latest
    volumes:
      - ./infrastructure/tileserver/data:/data
    ports:
      - "8081:8080"
    command: --port 8080 /data/config.json
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      timeout: 5s
      retries: 3
```

- [ ] **Step 3: 更新 nginx.conf 添加瓦片代理**

在 `location /api/v1/` 块之前添加：

```nginx
    location /tiles/ {
        proxy_pass http://tileserver:8080/data/v3/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        add_header Cache-Control "public, max-age=2592000";
    }
```

- [ ] **Step 4: 部署验证**

```bash
cd smart-livestock-server
rsync -avz --exclude='.git' --exclude='.gradle' . agentic@172.22.1.123:~/smart-livestock-server/
ssh agentic@172.22.1.123 "cd ~/smart-livestock-server && docker compose up -d tileserver"
curl -s http://172.22.1.123:18080/tiles/ | head -c 200
```

- [ ] **Step 5: 提交**

```bash
git add smart-livestock-server/docker-compose.yml \
        smart-livestock-server/infrastructure/nginx/nginx.conf \
        smart-livestock-server/infrastructure/tileserver/
git commit -m "feat(server): add tileserver-gl Docker deployment

Docker sidecar + nginx /tiles/ proxy + config.json"
```

---

## Task 7: MBTiles 生成/导入工具

**Files:**
- Create: `tooling/generate_mbtiles.py`
- Create: `tooling/import_mbtiles.sh`

> **前提**：海外服务器已安装 Mapnik + openstreetmap-carto，OSM Planet `.osm.pbf` 数据可用。

- [ ] **Step 1: 创建 generate_mbtiles.py**

```python
#!/usr/bin/env python3
"""按 bbox + zoom 范围从 OSM Planet 数据生成 MBTiles 文件。

用法：
    python generate_mbtiles.py --bbox 112.8,28.1,113.1,28.4 --zoom 11-15 --output changsha.mbtiles
"""
import argparse
import json
import hashlib
import subprocess
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


def generate_mbtiles(bbox: str, zoom: str, output: str):
    min_lon, min_lat, max_lon, max_lat = [float(x) for x in bbox.split(",")]
    min_zoom, max_zoom = [int(x) for x in zoom.split("-")]

    subprocess.run([
        "render_list",
        "-n", "4",
        "-z", str(min_zoom), "-Z", str(max_zoom),
        "-a", f"{min_lat},{min_lon},{max_lat},{max_lon}",
        "-o", output,
    ], check=True)

    mbtiles = Path(output)
    file_hash = hashlib.md5(mbtiles.read_bytes()).hexdigest()
    conn = sqlite3.connect(output)
    cur = conn.execute("SELECT COUNT(*) FROM tiles")
    tile_count = cur.fetchone()[0]
    conn.close()

    metadata = {
        "name": mbtiles.stem,
        "bounds": [min_lon, min_lat, max_lon, max_lat],
        "minzoom": min_zoom,
        "maxzoom": max_zoom,
        "tile_count": tile_count,
        "md5": file_hash,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    mbtiles.with_suffix(".metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    print(f"Generated: {output} ({tile_count} tiles, {mbtiles.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bbox", required=True, help="min_lon,min_lat,max_lon,max_lat")
    parser.add_argument("--zoom", default="11-15")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    generate_mbtiles(args.bbox, args.zoom, args.output)
```

- [ ] **Step 2: 创建 import_mbtiles.sh**

```bash
#!/usr/bin/env bash
# 从海外节点拉取 MBTiles 并更新 tileserver-gl 配置
set -euo pipefail

REMOTE_HOST="${1:?Usage: $0 <remote-host> [remote-path]}"
REMOTE_PATH="${2:-/data/mbtiles}"
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)/smart-livestock-server/infrastructure/tileserver/data"

mkdir -p "$LOCAL_DIR"

# 1. rsync MBTiles + metadata
rsync -avz --progress "$REMOTE_HOST:$REMOTE_PATH/*.mbtiles" "$LOCAL_DIR/"
rsync -avz "$REMOTE_HOST:$REMOTE_PATH/*.metadata.json" "$LOCAL_DIR/"

# 2. 验证 MD5
for meta in "$LOCAL_DIR"/*.metadata.json; do
    mbtiles="${meta%.metadata.json}.mbtiles"
    [ -f "$mbtiles" ] || continue
    expected=$(python3 -c "import json; print(json.load(open('$meta'))['md5'])")
    actual=$(md5 -q "$mbtiles" 2>/dev/null || md5sum "$mbtiles" | cut -d' ' -f1)
    if [ "$expected" != "$actual" ]; then
        echo "MD5 mismatch for $mbtiles: expected $expected, got $actual"
        exit 1
    fi
    echo "OK: $mbtiles"
done

# 3. 自动生成 config.json
python3 -c "
import json, glob
files = sorted(glob.glob('$LOCAL_DIR/*.mbtiles'))
names = [f.split('/')[-1] for f in files]
config = {'data': {'v3': {'mbtiles': names}}, 'options': {'port': 8080}}
json.dump(config, open('$LOCAL_DIR/config.json', 'w'), indent=2)
print(f'config.json updated: {names}')
"

echo "Import complete. Restart tileserver-gl to apply changes."
# 4. 重载 tileserver-gl（如在国内服务器上运行）
if command -v docker &> /dev/null; then
    docker kill --signal=SIGHUP $(docker ps -q --filter "ancestor=maptiler/tileserver-gl") 2>/dev/null || true
fi
```

```bash
chmod +x tooling/import_mbtiles.sh
```

- [ ] **Step 3: 提交**

```bash
git add tooling/generate_mbtiles.py tooling/import_mbtiles.sh
git commit -m "feat(tooling): add MBTiles generation and import scripts

generate_mbtiles.py: bbox + zoom → MBTiles via Mapnik + openstreetmap-carto
import_mbtiles.sh: rsync + MD5 verify + auto-generate config.json"
```

---

## Task 8: 瓦片管理 API

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/TileController.java`

- [ ] **Step 1: 新建 TileController**

```java
package com.smartlivestock.ranch.interfaces;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class TileController {

    private static final String TILES_DIR = "/data/mbtiles";

    @GetMapping("/admin/tiles/status")
    public ResponseEntity<List<Map<String, Object>>> getTileStatus() {
        File dir = new File(TILES_DIR);
        if (!dir.exists()) return ResponseEntity.ok(List.of());
        File[] files = dir.listFiles((d, name) -> name.endsWith(".mbtiles"));
        if (files == null) return ResponseEntity.ok(List.of());

        var statuses = Arrays.stream(files)
            .map(f -> Map.<String, Object>of(
                "name", f.getName(),
                "size", f.length(),
                "lastModified", f.lastModified()
            ))
            .toList();
        return ResponseEntity.ok(statuses);
    }

    @GetMapping("/farms/{farmId}/offline-map")
    public ResponseEntity<Resource> downloadOfflineMap(@PathVariable Long farmId) {
        Path mbtiles = Paths.get(TILES_DIR, "changsha.mbtiles");
        if (!mbtiles.toFile().exists()) return ResponseEntity.notFound().build();
        Resource resource = new FileSystemResource(mbtiles);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=\"changsha.mbtiles\"")
            .header(HttpHeaders.CONTENT_TYPE, "application/x-sqlite3")
            .contentLength(mbtiles.toFile().length())
            .body(resource);
    }
}
```

- [ ] **Step 2: 运行后端测试**

Run: `cd smart-livestock-server && ./gradlew test`
Expected: ALL PASS

- [ ] **Step 3: 提交**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/TileController.java
git commit -m "feat(server): add tiles management API

GET /admin/tiles/status — list imported MBTiles
GET /farms/{id}/offline-map — download MBTiles for offline use"
```

---

## Dependency Graph

```
Task 1 (gcj02ToWgs84) ─────┐
                             ├─→ Task 2 (SmartTileProvider) ──→ Task 3 (MapConfig)
                             │                                       │
                             │                                       ├─→ Task 4 (fence_page)
                             │                                       └─→ Task 5 (other pages)
Task 6 (tileserver Docker) ──┼─→ Task 8 (tiles API)
                             │
Task 7 (MBTiles tools) ──────┘
```

Tasks 1-2 和 Tasks 6-7 可并行。Task 3 依赖 Task 2。Tasks 4-5 依赖 Task 3。

---

*Plan generated: 2026-05-15*
*Design spec: `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`*
