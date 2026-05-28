# Plan: 离线地图 Phase 1 — Tech Spike（MBTiles 渲染验证）

## Summary
验证 flutter_map 8.2.2 中自定义 MBTilesTileProvider 的渲染可行性。编写一个从本地 MBTiles（SQLite）读取瓦片的自定义 TileProvider，准备示例 MBTiles 文件，在 FencePage 中替换现有网络瓦片进行离线测试。

## User Story
As a 开发者,
I want 验证 flutter_map 能从本地 MBTiles 文件渲染地图瓦片,
So that 确认离线地图方案技术上可行，为后续 Phase 2-6 的全面实施奠定基础。

## Problem → Solution
**Current**: Flutter App 依赖在线 OSM 瓦片（`https://tile.openstreetmap.org/{z}/{x}/{y}.png`），断网后地图完全不可用。
**Desired**: 自定义 MBTilesTileProvider 能从本地 .mbtiles SQLite 文件读取瓦片数据，断网后地图正常渲染。

## Metadata
- **Complexity**: Medium
- **Source PRD**: `.claude/PRPs/prds/offline-first-map.prd.md`
- **PRD Phase**: Phase 1 — Tech Spike
- **Estimated Files**: 5-6 个新建 + 2 个修改

---

## UX Design

### Before
```
┌─────────────────────────────────┐
│  FencePage                      │
│  ┌───────────────────────────┐  │
│  │ FlutterMap                │  │
│  │  TileLayer(urlTemplate:   │  │
│  │    "tile.openstreetmap…") │  │
│  │  → 断网 = 灰色空白瓦片     │  │
│  │  PolygonLayer(围栏)       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### After
```
┌─────────────────────────────────┐
│  FencePage (Tech Spike)         │
│  ┌───────────────────────────┐  │
│  │ FlutterMap                │  │
│  │  TileLayer(               │  │
│  │    MBTilesTileProvider(   │  │
│  │      "assets/sample.mbtiles"))│
│  │  → 断网 = 正常渲染本地瓦片  │  │
│  │  PolygonLayer(围栏)       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### Interaction Changes
| Touchpoint | Before | After | Notes |
|---|---|---|---|
| 瓦片来源 | OSM CDN 网络请求 | 本地 MBTiles SQLite 文件 | Tech Spike 仅验证离线渲染 |
| 瓦片加载 | NetworkTileProvider | 自定义 MBTilesTileProvider | 不实现回退链，Phase 3 做 |
| 测试方式 | 无离线测试 | 飞行模式 + sample.mbtiles | 仅验证核心可行性 |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 (critical) | `Mobile/mobile_app/lib/core/map/map_config.dart` | all | 现有地图配置，zoom 范围、URL template |
| P0 (critical) | `Mobile/mobile_app/lib/features/pages/fence_page.dart` | 175-291 | FlutterMap + TileLayer 使用位置 |
| P1 (important) | `Mobile/mobile_app/lib/features/pages/fence_form_page.dart` | 568-654 | 第二处 TileLayer 使用 |
| P1 (important) | `Mobile/mobile_app/pubspec.yaml` | all | 依赖管理 |
| P2 (reference) | `Mobile/mobile_app/lib/features/farm_creation/presentation/wizard_step_fence_drawing.dart` | 336-341 | 第三处 TileLayer 使用 |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| flutter_map TileProvider API | docs.fleaflet.dev/plugins/create/tile-providers | 继承 `TileProvider`，覆写 `getImage(TileCoordinates, TileLayer)` 返回 `ImageProvider` |
| MBTiles Spec v1.3 | github.com/mapbox/mbtiles-spec | SQLite 格式，`tiles` 表含 (zoom_level, tile_column, tile_row, tile_data)，TMS Y 轴翻转 |
| flutter_map 内置 Provider | docs.fleaflet.dev/layers/tile-layer/tile-providers | NetworkTileProvider / FileTileProvider / AssetTileProvider 可参考 |

---

## Patterns to Mirror

### TILE_LAYER_USAGE
// SOURCE: Mobile/mobile_app/lib/features/pages/fence_page.dart:205-210
```dart
TileLayer(
  urlTemplate: MapConfig.tileUrlTemplate,
  userAgentPackageName: 'com.smartlivestock.demo',
  maxZoom: MapConfig.cacheMaxZoom.toDouble(),
)
```

### MAP_CONFIG_CONSTANTS
// SOURCE: Mobile/mobile_app/lib/core/map/map_config.dart
```dart
static const double defaultZoom = 13.0;
static const int cacheMinZoom = 11;
static const int cacheMaxZoom = 15;
static const String tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
```

### FLUTTER_MAP_WIDGET_STRUCTURE
// SOURCE: Mobile/mobile_app/lib/features/pages/fence_page.dart:178-210
```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: DemoSeed.mapCenter,
    initialZoom: DemoSeed.defaultZoom,
    ...
  ),
  children: [
    TileLayer(...),
    AnimatedBuilder(
      animation: _breathingController,
      builder: (context, _) => PolygonLayer(polygons: _buildBrowsePolygons(fenceState)),
    ),
    PolygonLayer(polygons: _buildEditPolygons(editSession)),
    PolylineLayer(polylines: ...),
    MarkerLayer(markers: ...),
  ],
)
```

### TEST_FILE_NAMING
// SOURCE: 项目约定
```
test/{feature}_test.dart
test/widget_smoke_test.dart
```

### PUBSPEC_DEPENDENCY_FORMAT
// SOURCE: Mobile/mobile_app/pubspec.yaml
```yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  http: ^1.2.0
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `Mobile/mobile_app/lib/core/map/mbtiles_tile_provider.dart` | CREATE | 自定义 MBTiles TileProvider 核心实现 |
| `Mobile/mobile_app/test/mbtiles_tile_provider_test.dart` | CREATE | TileProvider 单元测试 |
| `Mobile/mobile_app/tooling/generate_sample_mbtiles.py` | CREATE | 生成示例 MBTiles 测试文件的脚本 |
| `Mobile/mobile_app/assets/map/sample.mbtiles` | CREATE | 示例 MBTiles 测试文件（小区域） |
| `Mobile/mobile_app/lib/core/map/map_config.dart` | UPDATE | 添加 MBTiles 相关配置常量 |
| `Mobile/mobile_app/lib/features/pages/fence_page.dart` | UPDATE | Tech Spike：替换 TileLayer 为 MBTilesTileProvider |
| `Mobile/mobile_app/pubspec.yaml` | UPDATE | 添加 sqlite3 依赖 + assets 声明 |

## NOT Building

- 在线/离线自动回退链（Phase 3）
- MBTiles 下载 API（Phase 2）
- 围栏/GPS 数据离线持久化（Phase 4）
- MBTiles 管理界面（Phase 5）
- 多牧场 MBTiles 切换（Phase 3）
- 瓦片缓存回写（写入到 MBTiles）

---

## Step-by-Step Tasks

### Task 1: 添加 sqlite3 依赖和 assets 配置
- **ACTION**: 在 pubspec.yaml 中添加 sqlite3 依赖，声明 sample.mbtiles 为 asset
- **IMPLEMENT**:
  1. 添加 `sqlite3: ^2.4.6` 到 dependencies（用于直接读取 MBTiles SQLite 文件）
  2. 添加 `sqlite3_flutter_libs: ^0.5.28` 到 dependencies（移动端 SQLite 原生库）
  3. 在 flutter.assets 中添加 `assets/map/sample.mbtiles`
- **MIRROR**: PUBSPEC_DEPENDENCY_FORMAT
- **IMPORTS**: 无需 import（仅 pubspec 修改）
- **GOTCHA**: sqlite3 包（simolus3/sqlite3.dart）不同于 sqflite，它支持直接打开文件路径，更适合 MBTiles 读取场景
- **VALIDATE**: `flutter pub get` 成功无报错

### Task 2: 创建示例 MBTiles 测试文件
- **ACTION**: 用 Python 脚本生成一个包含小区域（长沙附近，zoom 12-14）瓦片的 MBTiles 文件
- **IMPLEMENT**:
  1. 创建 `Mobile/mobile_app/tooling/generate_sample_mbtiles.py`
  2. 脚本从 OSM CDN 下载瓦片（zoom 12-14，长沙附近约 50-100 个瓦片）
  3. 写入 MBTiles SQLite 格式：
     ```sql
     CREATE TABLE metadata (name TEXT, value TEXT);
     CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
     CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);
     ```
  4. metadata 插入: `name`, `format` (png), `bounds`, `minzoom`, `maxzoom`
  5. 输出到 `Mobile/mobile_app/assets/map/sample.mbtiles`
- **MIRROR**: MBTiles Spec v1.3
- **IMPORTS**: Python: sqlite3, urllib.request, math
- **GOTCHA**: MBTiles 的 tile_row 使用 TMS 坐标系（Y 轴翻转），写入时需转换：`tms_y = (2^z - 1) - y`
- **VALIDATE**: `sqlite3 sample.mbtiles "SELECT COUNT(*) FROM tiles"` 确认有数据；文件大小 < 5MB

### Task 3: 实现 MBTilesTileProvider
- **ACTION**: 创建自定义 TileProvider，从 MBTiles SQLite 文件读取瓦片数据
- **IMPLEMENT**:
  ```dart
  // lib/core/map/mbtiles_tile_provider.dart
  import 'dart:typed_data';
  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:sqlite3/sqlite3.dart';

  class MBTilesTileProvider extends TileProvider {
    final Database _db;
    bool _disposed = false;

    MBTilesTileProvider(String mbtilesPath)
        : _db = sqlite3.open(mbtilesPath);

    @override
    ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
      // TMS Y 轴翻转：XYZ slippy map y → TMS y
      final tmsY = (1 << coordinates.z) - 1 - coordinates.y;

      final rows = _db.select(
        'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',
        [coordinates.z, coordinates.x, tmsY],
      );

      if (rows.isEmpty || rows.first['tile_data'] == null) {
        return MemoryImage(_transparentPng);
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

    void dispose() {
      if (!_disposed) {
        _db.dispose();
        _disposed = true;
      }
    }

    static final Uint8List _transparentPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
      0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
      0x60, 0x82,
    ]);
  }
  ```
- **MIRROR**: flutter_map TileProvider API — 继承 `TileProvider`，覆写 `getImage`
- **IMPORTS**: `dart:typed_data`, `package:flutter/material.dart`, `package:flutter_map/flutter_map.dart`, `package:sqlite3/sqlite3.dart`
- **GOTCHA**:
  - TMS Y 轴翻转是 MBTiles 的核心陷阱：`tmsY = (1 << z) - 1 - y`，写错会渲染空白/错位
  - `sqlite3` 包的 blob 数据类型可能是 `Uint8List` 或 `List<int>`，需兼容处理
  - 1x1 透明 PNG 用于缺失瓦片，避免 flutter_map 报错
  - `dispose()` 必须关闭数据库连接
- **VALIDATE**: 单元测试验证 getImage 返回正确 ImageProvider

### Task 4: 更新 MapConfig
- **ACTION**: 在 MapConfig 中添加 MBTiles 相关配置常量
- **IMPLEMENT**:
  ```dart
  static const String mbtilesAssetPath = 'assets/map/sample.mbtiles';
  static const String mbtilesFileName = 'sample.mbtiles';
  ```
- **MIRROR**: MAP_CONFIG_CONSTANTS
- **IMPORTS**: 无新 import
- **GOTCHA**: 无
- **VALIDATE**: 编译通过

### Task 5: 单元测试 MBTilesTileProvider
- **ACTION**: 编写单元测试验证 MBTiles 读取逻辑
- **IMPLEMENT**:
  ```dart
  // test/mbtiles_tile_provider_test.dart
  // 测试用例：
  // 1. 能打开 sample.mbtiles 并读取 metadata
  // 2. getImage 返回有效 ImageProvider（zoom 12-14 范围内）
  // 3. 超出范围的坐标返回透明 PNG
  // 4. TMS Y 轴转换正确（验证边界 case：z=0 时 y=0 → tmsY=0）
  // 5. dispose 后不再可访问
  ```
- **MIRROR**: TEST_FILE_NAMING
- **IMPORTS**: `package:flutter_test/flutter_test.dart`, `package:flutter_map/flutter_map.dart`
- **GOTCHA**: 测试需要 sample.mbtiles 文件。如果 flutter test 不支持 asset 读取，需将 sample.mbtiles 复制到临时目录或使用内存 SQLite 创建测试用 MBTiles
- **VALIDATE**: `flutter test test/mbtiles_tile_provider_test.dart` 通过

### Task 6: 在 FencePage 中替换为 MBTilesTileProvider（Tech Spike 验证）
- **ACTION**: 临时修改 FencePage，使用 MBTilesTileProvider 替换网络瓦片
- **IMPLEMENT**:
  1. 在 FencePage 的 `initState` 中初始化 MBTilesTileProvider：
     ```dart
     late final MBTilesTileProvider _mbtilesProvider;
     bool _mbtilesReady = false;

     @override
     void initState() {
       super.initState();
       _initMBTiles();
     }

     Future<void> _initMBTiles() async {
       final data = await rootBundle.load(MapConfig.mbtilesAssetPath);
       final dir = await getApplicationSupportDirectory();
       final file = File('${dir.path}/${MapConfig.mbtilesFileName}');
       await file.writeAsBytes(data.buffer.asUint8List());
       _mbtilesProvider = MBTilesTileProvider(file.path);
       setState(() { _mbtilesReady = true; });
     }
     ```
  2. 替换 TileLayer：
     ```dart
     if (_mbtilesReady)
       TileLayer(
         tileProvider: _mbtilesProvider,
         maxZoom: MapConfig.cacheMaxZoom.toDouble(),
       )
     else
       TileLayer(urlTemplate: MapConfig.tileUrlTemplate)
     ```
- **MIRROR**: FLUTTER_MAP_WIDGET_STRUCTURE + TILE_LAYER_USAGE
- **IMPORTS**: `package:flutter/services.dart`, `package:path_provider/path_provider.dart`, `dart:io`
- **GOTCHA**:
  - sqlite3 无法直接读 asset（内存中的 byte data），必须先复制到本地文件路径
  - 需要添加 `path_provider: ^2.1.0` 到 pubspec.yaml（如果尚未存在）
  - 此为 Tech Spike 临时修改，Phase 3 会重写为正式的回退链方案
- **VALIDATE**: `flutter run` → 打开围栏页 → 开启飞行模式 → 地图仍正常显示 → 围栏多边形可见

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| 打开 MBTiles 文件 | sample.mbtiles 路径 | 无异常，metadata 可读 | 否 |
| 读取有效瓦片 | z=13, x,y 在范围内 | 返回 MemoryImage，bytes 非空 | 否 |
| 读取缺失瓦片 | z=5（超出范围） | 返回 1x1 透明 PNG | 是 |
| TMS Y 轴边界 | z=0, y=0 | tmsY = 0，正确 | 是 |
| dispose 后访问 | dispose() 后 getImage | 抛出 StateError 或安全降级 | 是 |

### Edge Cases Checklist
- [x] MBTiles 无瓦片的 zoom 级别 — 返回透明 PNG
- [ ] MBTiles 文件不存在 — Tech Spike 中假设文件存在
- [x] TMS Y 轴翻转边界条件
- [ ] 多次创建/销毁 Provider（Phase 3 处理）

---

## Validation Commands

### Static Analysis
```bash
cd Mobile/mobile_app && flutter analyze
```
EXPECT: Zero errors, zero warnings

### Unit Tests
```bash
cd Mobile/mobile_app && flutter test test/mbtiles_tile_provider_test.dart
```
EXPECT: All tests pass

### Integration Test (Manual)
```bash
cd Mobile/mobile_app && flutter run
```
EXPECT:
1. 打开围栏页面，地图正常渲染（从本地 MBTiles 加载）
2. 开启飞行模式，地图仍然显示
3. 围栏多边形在离线/在线均正确渲染

### Full Test Suite
```bash
cd Mobile/mobile_app && flutter test
```
EXPECT: No regressions

---

## Acceptance Criteria
- [ ] MBTilesTileProvider 能从本地 .mbtiles 文件读取并渲染瓦片
- [ ] 飞行模式下地图正常显示（有预载瓦片的区域）
- [ ] TMS Y 轴翻转正确，瓦片位置不偏移
- [ ] 缺失瓦片返回透明 PNG，不报错不 crash
- [ ] 所有现有 flutter test 通过（无回归）
- [ ] flutter analyze 零错误零警告

## Completion Checklist
- [ ] 代码遵循项目命名约定（snake_case 文件，UpperCamelCase 类）
- [ ] 无硬编码路径（使用 MapConfig 常量）
- [ ] dispose 正确清理 SQLite 连接
- [ ] sample.mbtiles 文件体积 < 5MB
- [ ] Tech Spike 验证结论已记录

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| sqlite3 包在 iOS/Android 上原生库加载失败 | L | H | sqlite3_flutter_libs 提供预编译库；Tech Spike 首先验证 `flutter run` 能否正常启动 |
| MBTiles 瓦片渲染错位（TMS Y 轴翻转错误） | M | M | 单元测试验证 Y 轴转换，边界条件测试 |
| sample.mbtiles asset 打包体积过大 | L | L | 控制在 zoom 12-14，约 50 个瓦片，< 5MB |
| flutter_map 8.2.2 TileProvider API 与文档不一致 | L | H | 先查看 flutter_map 源码中 TileProvider 基类定义 |

## Notes
- **Tech Spike 定位**: 仅验证"MBTiles 能否在 flutter_map 中渲染"这一个核心假设。
- **验证完的发现**: 完成后需在 PRD 中记录结论，决定是否继续 Phase 2-6 或调整方案。
- **Phase 3 接口预留**: MBTilesTileProvider 的 `dispose()` 和 `getMetadata()` 方法设计时已考虑 Phase 3 的回退链和多牧场切换需求。
- **sqlite3 vs sqflite**: 选择 sqlite3（simolus3）而非 sqflite，因为支持直接打开文件路径且 API 更轻量。
