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
│  - tileserver-gl (internal :8080, host :8081)                    │
│    ← /data/mbtiles/*.mbtiles                                     │
│  - nginx:18080 /tiles/ → tileserver-gl:8080 (内部端口)            │
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
数据源：OSM Planet `.osm.pbf` → Mapnik + `openstreetmap-carto` 样式表 → `render_list` 渲染为 PNG 瓦片
输出：标准 MBTiles v1.3 格式（与现有 MBTilesTileProvider 兼容）
附带：`metadata.json`（bounds、zoom、tile count、md5、生成时间）

> 注：使用 `openstreetmap-carto` 样式表以保证瓦片风格与 OSM 默认一致。tileserver-gl 也支持矢量瓦片（.pbf + style JSON），存储更小但需要客户端渲染能力，当前方案选择栅格 PNG 以简化实现。

**`tooling/import_mbtiles.sh`**

1. `rsync` 从海外节点拉取 MBTiles 到 `/data/mbtiles/`
2. 验证 MD5 完整性
3. 自动扫描 `/data/mbtiles/*.mbtiles` 生成 `config.json`（避免手动维护文件名数组）
4. 发送 `SIGHUP` 重载 tileserver-gl 配置

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

**tileserver-gl `config.json` 由 `import_mbtiles.sh` 自动生成：**

```json
{
  "data": {
    "v3": {
      "mbtiles": ["changsha.mbtiles", "urumqi.mbtiles"]
    }
  }
}
```

`import_mbtiles.sh` 步骤 3 自动扫描 `/data/mbtiles/*.mbtiles` 目录生成此文件，无需手动维护。30 天缓存期间如需强制刷新，可递增路径版本段（如 `/tiles/v2/`）。

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

降级时已渲染瓦片保留直到新瓦片就绪（flutter_map 默认行为），避免空白闪烁。MBTiles 使用与 tileserver-gl 相同的 `openstreetmap-carto` 样式表生成（见 §2.2），保证主源与离线源之间视觉一致。唯一风格差异来自高德降级源（不同配色方案），属于可接受的降级体验。

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

### 3.3.1 平台条件实例化

Web 平台无 SQLite，`MBTilesTileProvider` 不可用。SmartTileProvider 实例化时按平台决定：

```dart
// 实例化逻辑（在 SmartTileProvider.factory() 中）
SmartTileProvider createTileProvider() {
  return SmartTileProvider(
    selfHostedTileUrl: MapConfig.selfHostedTileUrl,
    mbtilesProvider: kIsWeb ? null : MBTilesTileProvider.fromAsset(),
    fallbackUrl: _resolveFallbackUrl(),
    isGcj02Fallback: _isChinaRegion(),
  );
}
```

### 3.3.2 离线瓦片存储路径（原生平台）

下载的 MBTiles 文件存储在应用内部目录：

```
getApplicationSupportDirectory()/mbtiles/{farmId}.mbtiles
```

选择 `getApplicationSupportDirectory()` 的原因：Android 11+ Scoped Storage 限制外部存储访问，内部存储无需额外权限。Web 平台不支持 MBTiles，仅通过在线瓦片源服务。

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
| `map_config.dart` | `defaultCenter` 和 `cityPresets` 坐标从"编译期固定 GCJ-02"改为"运行时根据活跃瓦片源决定"；新增 `selfHostedTileUrl`/`chinaFallbackUrl`/`overseasFallbackUrl` 常量 |
| `fence_page.dart` | TileLayer 从 `urlTemplate` 改为 `tileProvider: SmartTileProvider(...)` |
| `fence_form_page.dart` | 同上 |
| `wizard_step_basic_info.dart` | 同上 |
| `wizard_step_fence_drawing.dart` | 同上 |
| `fence_page.dart` PolygonLayer | 当 `shouldTransformCoordinates()` 时，顶点经 `CoordTransform.wgs84ToGcj02()` 转换后渲染 |
| 围栏绘制保存 | 高德降级时，采集坐标经 `gcj02ToWgs84()` 逆转换为 WGS-84 后存储 |
| 所有使用 `MapConfig.defaultCenter` 的页面 | 坐标需通过 `SmartTileProvider.shouldTransformCoordinates()` 动态决定是否转换 |

### 3.5.1 MapConfig 坐标动态化

当前 `defaultCenter` 和 `cityPresets` 在编译期就做了 `wgs84ToGcj02()` 转换。改造方案：

- `MapConfig` 存储原始 WGS-84 坐标（纯数据，不依赖 TileProvider 实例）
- 坐标转换由调用方（FencePage 等）根据 `SmartTileProvider.shouldTransformCoordinates()` 决定
- 理由：MapConfig 保持纯数据角色；调用方已持有 SmartTileProvider 引用，转换逻辑自然归属渲染层；与 §4 的坐标转换规则一致（渲染时转换，存储时保持 WGS-84）

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
- `gcj02ToWgs84()` — 迭代法逆转换：初始猜测 = gcj02 点，反复调用 `wgs84ToGcj02(guess)` 计算偏差并修正，迭代终止条件为偏差 < 0.1m（中国境内 GCJ-02 偏移量约 50-500m，5-7 次迭代可收敛到 0.1m）
- `gcj02ToWgs84All()` — 批量逆转换
- **精度验证**：添加 round-trip 测试，`wgs84→gcj02→wgs84` 往返偏差应 < 0.5m（围栏越界判定精度要求在米级，0.5m 余量充足）

### 围栏绘制逆转换

围栏绘制保存是安全关键路径。高德降级时用户在 GCJ-02 地图上画围栏，保存前必须：

1. 检测当前瓦片源是否为 GCJ-02（`SmartTileProvider.shouldTransformCoordinates()`）
2. 若是，对所有绘制顶点调用 `gcj02ToWgs84()` 逆转换
3. 将 WGS-84 坐标发送到 API

涉及文件：`fence_edit_operations.dart`（绘制采集）、`fence_edit_toolbar.dart`（保存触发）、`live_fence_repository.dart`（提交 API）

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

### 与 PRD Phase 映射

| PRD Phase | 设计单元 | 说明 |
|-----------|---------|------|
| Phase 1: Tech Spike | — | 已完成，不在本设计范围 |
| Phase 2: 后端 MBTiles 生成 | 单元 1 + 2 + 6 | tileserver-gl 部署 + 生成工具 + API |
| Phase 3: Flutter 离线瓦片渲染 | 单元 3 + 4 + 5 | SmartTileProvider + 坐标转换 + 渲染适配 |
| Phase 4: 离线数据持久化 | — | 围栏/牲畜本地缓存，留给后续设计 |
| Phase 5: MBTiles 管理界面 | — | 下载/管理 UI，留给后续设计 |
| Phase 6: 集成测试与上线 | — | 端到端验证，留给后续设计 |

本设计覆盖 PRD Phase 2 + Phase 3，是 PRD 的第一阶段实施设计。Phase 4-6 在本设计实施完成后另行设计。

### 实施单元明细

| # | 单元 | 职责 | 对应 PRD Phase | 依赖 |
|---|------|------|---------------|------|
| 1 | tileserver-gl 部署 | Docker sidecar + nginx 代理 | Phase 2 | 海外服务器、MBTiles 数据 |
| 2 | 瓦片生成/导入工具 | 海外生成 MBTiles + 导入脚本 | Phase 2 | OSM Planet 数据 |
| 3 | SmartTileProvider | 三级回退 TileProvider | Phase 3 | flutter_map、现有 MBTilesTileProvider |
| 4 | CoordTransform 补充 | gcj02ToWgs84 逆转换 | Phase 3 | 现有 CoordTransform |
| 5 | 渲染层适配 | PolygonLayer 坐标转换 + TileLayer 替换 | Phase 3 | SmartTileProvider |
| 6 | 瓦片管理 API | Spring Boot 新增 tiles 端点 | Phase 2 | tileserver-gl 部署 |

---

*Generated: 2026-05-15*
