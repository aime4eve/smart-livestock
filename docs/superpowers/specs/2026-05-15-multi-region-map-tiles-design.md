# 多区域地图瓦片统一方案设计

**日期**: 2026-05-15
**状态**: DRAFT
**关联 Issue**: #43 (离线地图), #48 (离线优先地图 PRD)
**关联 PRD**: `.claude/PRPs/prds/offline-first-map.prd.md`

---

## 1. 问题

地图瓦片和字体在国内网络被墙：

- `tile.openstreetmap.org` — 国内无法访问
- `fonts.gstatic.com` — 国内无法访问

项目需同时服务国内和海外市场，地图是围栏功能的基础设施。

### 已有能力

| 能力 | 状态 | 文件 |
|------|------|------|
| MBTilesTileProvider (原生平台离线) | 已实现 | `core/map/mbtiles_tile_provider_io.dart` |
| WGS-84→GCJ-02 坐标转换 | 已实现 | `core/map/coord_transform.dart` |
| 高德瓦片 (国内临时方案) | 已切换 | `core/map/map_config.dart` |
| sample.mbtiles (长沙 zoom 12-14) | 已生成 | `assets/map/sample.mbtiles` |
| NotoSansSC 字体本地打包 | 已完成 | `assets/fonts/NotoSansSC-*.ttf` |

### 已验证的事实

- 服务器 172.22.1.123 **无法**访问 `tile.openstreetmap.org`（超时）
- 服务器 **可以**访问高德瓦片（HTTP 200）
- API 围栏顶点坐标为 WGS-84（`lat`/`lng`，`@JsonProperty` 序列化）
- MBTiles 在 Web 平台不可用（浏览器无 SQLite），需在线瓦片

---

## 2. 方案：自建 tileserver-gl + 多源 SmartTileProvider

### 2.1 瓦片数据管线

```
┌─────────────────────────────────────────────────────────────────┐
│  海外节点 (不被墙)                                                │
│                                                                   │
│  OSM Planet .osm.pbf                                             │
│    → generate_mbtiles.py (按 bbox + zoom 11-15)                  │
│    → {region}.mbtiles + metadata.json                            │
│    → rsync 到国内服务器                                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  国内服务器 (172.22.1.123)                                        │
│                                                                   │
│  docker-compose:                                                  │
│  - tileserver-gl:8081  ← /data/mbtiles/*.mbtiles                │
│  - nginx:18080 /tiles/ → tileserver-gl:8081                     │
│  - app:8080            ← Spring Boot                             │
│  - postgres + redis                                               │
│                                                                   │
│  瓦片管理 API (新增):                                              │
│  - GET /admin/tiles/status → 已导入区域/大小/时间                  │
│  - GET /farms/{id}/offline-map → 下载 MBTiles 到 App             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 海外瓦片生成工具

**`tooling/generate_mbtiles.py`**

输入：bbox (经纬度范围) + zoom 范围 (默认 11-15) + 输出路径
数据源：OSM Planet `.osm.pbf` → `render_list` 渲染为 PNG 瓦片
输出：标准 MBTiles v1.3 格式（与现有 MBTilesTileProvider 兼容）
附带：`metadata.json`（bounds、zoom、tile count、md5、生成时间）

**`tooling/import_mbtiles.sh`**

1. `rsync` 从海外节点拉取 MBTiles 到 `/data/mbtiles/`
2. 验证 MD5 完整性
3. 发送 `SIGHUP` 重载 tileserver-gl 配置

### 2.3 Docker 部署

**docker-compose.yml 新增 tileserver-gl：**

```yaml
tileserver:
  image: maptiler/tileserver-gl:latest
  volumes:
    - ./infrastructure/tileserver/data:/data
  ports:
    - "8081:8080"
  command: --port 8080 /data/config.json
```

**nginx.conf 新增瓦片代理：**

```nginx
location /tiles/ {
    proxy_pass http://tileserver:8080/data/v3/;
    proxy_set_header Host $host;
    add_header Cache-Control "public, max-age=2592000";
}
```

---

## 3. Flutter SmartTileProvider

### 3.1 优先级链

```
TileRequest
  │
  ├─ 1. 自有 tileserver-gl (WGS-84)
  │     └─ 成功 → 渲染
  │     └─ 失败/超时(2s) ↓
  │
  ├─ 2. 本地 MBTiles (WGS-84, 原生平台)
  │     └─ 有瓦片 → 渲染
  │     └─ 无瓦片/Web平台 ↓
  │
  └─ 3. 降级源
        ├─ 国内 → 高德 (GCJ-02) + CoordTransform
        └─ 海外 → OSM CDN (WGS-84)
```

### 3.2 SmartTileProvider 接口

```dart
class SmartTileProvider extends TileProvider {
  final String? selfHostedTileUrl;
  final MBTilesTileProvider? mbtilesProvider;
  final String? fallbackUrl;
  final bool isGcj02Fallback;

  /// 当前活跃源是否使用 GCJ-02（渲染层据此决定坐标转换）
  bool shouldTransformCoordinates();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options);
}
```

### 3.3 各平台行为

| 平台 | 主源 | 回退 1 | 回退 2 |
|------|------|--------|--------|
| Web (国内) | tileserver-gl | — | 高德 + 坐标转换 |
| Web (海外) | tileserver-gl | — | OSM CDN |
| 原生 (国内) | tileserver-gl | MBTiles | 高德 + 坐标转换 |
| 原生 (海外) | tileserver-gl | MBTiles | OSM CDN |

### 3.4 配置

```dart
class MapConfig {
  static const String selfHostedTileUrl =
      'http://172.22.1.123:18080/tiles/{z}/{x}/{y}.png';

  static const String chinaFallbackUrl =
      'https://webrd02.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}';

  static const String overseasFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
```

降级源通过 `--dart-define=REGION=china|overseas` 选择，默认自动检测（tileserver-gl 可达则不降级）。

### 3.5 对现有代码的影响

| 文件 | 变更 |
|------|------|
| `fence_page.dart` | TileLayer 从 `urlTemplate` 改为 `tileProvider: SmartTileProvider(...)` |
| `fence_form_page.dart` | 同上 |
| `wizard_step_basic_info.dart` | 同上 |
| `wizard_step_fence_drawing.dart` | 同上 |
| `fence_page.dart` PolygonLayer | 当 `shouldTransformCoordinates()` 时，顶点经 `CoordTransform` 转换 |
| 围栏绘制保存 | 高德降级时，采集坐标逆转换为 WGS-84 后存储 |

---

## 4. 坐标系统

### 铁律

**数据库永远存 WGS-84。**

```
DB:       WGS-84
API:      WGS-84 (lat/lng, @JsonProperty)
Flutter:  WGS-84 存储，按地图源决定显示时是否转换
```

### 已验证的 API 响应

```json
{
  "vertices": [
    {"lat": 28.2166, "lng": 112.9248},
    {"lat": 28.2274, "lng": 112.9433}
  ]
}
```

坐标字段链路：
- `GpsCoordinate` record: `latitude`/`longitude`（Java 字段名）
- DB 存储 (`FenceMapper.toVerticesJson`): `"latitude"`/`"longitude"`
- API 响应 (`@JsonProperty`): `"lat"`/`"lng"`
- Flutter 解析 (`_normalizeFenceItem`): 转为 `"lat"`/`"lng"`

### 转换规则

| 场景 | 地图源 | 围栏顶点 | 围栏绘制保存 |
|------|--------|---------|-------------|
| 自有 tileserver-gl | WGS-84 | 直接渲染 | 直接存储 |
| MBTiles 离线 | WGS-84 | 直接渲染 | — |
| 高德降级 | GCJ-02 | `wgs84ToGcj02()` 显示时转换 | `gcj02ToWgs84()` 逆转换后存储 |
| OSM CDN 降级 | WGS-84 | 直接渲染 | 直接存储 |

### CoordTransform 补充

当前只有 `wgs84ToGcj02()`，需补充：
- `gcj02ToWgs84()` — 迭代法逆转换（精度 < 1m）
- `gcj02ToWgs84All()` — 批量逆转换

---

## 5. 字体处理

NotoSansSC 字体已本地打包在 `assets/fonts/`（3 个 TTF，共 30MB），`pubspec.yaml` 已声明。

Flutter Web 仍尝试从 `fonts.gstatic.com` 加载子集是引擎行为，本地字体作为主源已生效。**无需改动。**

如未来确认有字符缺失，可通过 `flutter build web --no-tree-shake-fonts` 禁用字体裁剪。

---

## 6. 不改动的部分

- Spring Boot 后端 API（坐标已统一 WGS-84）
- PostgreSQL 数据库（无坐标转换）
- Auth / JWT / 权限体系
- 所有业务逻辑

---

## 7. 实施单元

| # | 单元 | 职责 | 依赖 |
|---|------|------|------|
| 1 | tileserver-gl 部署 | Docker sidecar + nginx 代理 | 海外服务器、MBTiles 数据 |
| 2 | 瓦片生成/导入工具 | 海外生成 MBTiles + 导入脚本 | OSM Planet 数据 |
| 3 | SmartTileProvider | 三级回退 TileProvider | flutter_map、现有 MBTilesTileProvider |
| 4 | CoordTransform 补充 | gcj02ToWgs84 逆转换 | 现有 CoordTransform |
| 5 | 渲染层适配 | PolygonLayer 坐标转换 + TileLayer 替换 | SmartTileProvider |
| 6 | 瓦片管理 API | Spring Boot 新增 tiles 端点 | tileserver-gl 部署 |

---

*Generated: 2026-05-15*
