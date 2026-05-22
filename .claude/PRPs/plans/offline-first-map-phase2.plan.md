## 设计 Section 1：瓦片数据管线 + 服务器部署
整体架构

┌─────────────────────────────────────────────────────────────────┐
│  海外节点 (不被墙，一次性或定期)                                    │
│                                                                   │
│  OSM Planet ──→ tileserver-gl ──→ MBTiles 生成                   │
│  或:  osm.pbf → generate_tiles.py → {region}.mbtiles            │
│                                                                   │
│  管理脚本:                                                        │
│  - 按牧场 bbox 生成指定 zoom 范围的 MBTiles                       │
│  - 验证/校验 MD5                                                  │
│  - rsync 到国内服务器                                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │ rsync / scp / S3
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  国内服务器 (172.22.1.123)                                        │
│                                                                   │
│  docker-compose:                                                  │
│  - tileserver-gl:8081  ← 加载 /data/mbtiles/*.mbtiles           │
│  - nginx:18080         ← 代理 /tiles/{z}/{x}/{y}.png → :8081   │
│  - app:8080            ← Spring Boot                             │
│  - postgres + redis                                               │
│                                                                   │
│  瓦片管理 API (Spring Boot 新增):                                  │
│  - POST /admin/tiles/generate  → 触发海外节点生成（未来自动化）    │
│  - GET  /admin/tiles/status    → 查看已导入区域/大小/时间          │
│  - GET  /farms/{id}/offline-map → 下载 MBTiles 到 App            │
└─────────────────────────────────────────────────────────────────┘
瓦片管理工具链
海外节点的生成脚本 (tooling/generate_mbtiles.py)：

输入：bbox (经纬度范围) + zoom 范围 (11-15) + 输出路径
数据源：OSM Planet .osm.pbf → render_list 渲染为 PNG
输出：标准 MBTiles v1.3 格式（与现有 MBTilesTileProvider 兼容）
生成后附带 metadata.json（bounds、zoom、tile count、md5、生成时间）
国内服务器的导入脚本 (tooling/import_mbtiles.sh)：

rsync 从海外节点拉取 MBTiles 到 /data/mbtiles/
自动 reload tileserver-gl 配置
验证 MD5 完整性
docker-compose 新增 tileserver-gl

tileserver:
  image: maptiler/tileserver-gl:latest
  volumes:
    - ./infrastructure/tileserver/data:/data
  ports:
    - "8081:8080"
  command: --port 8080 /data/config.json
nginx 新增瓦片代理

location /tiles/ {
    proxy_pass http://tileserver:8080/data/v3/;
    proxy_set_header Host $host;
    proxy_cache_valid 200 30d;
}

## 设计 Section 2：Flutter 多源 TileProvider
优先级链

TileRequest
  │
  ├─ 1. 自有 tileserver-gl (WGS-84, 全球统一)
  │     └─ 成功 → 渲染
  │     └─ 失败/超时(2s) ↓
  │
  ├─ 2. 本地 MBTiles (WGS-84, 原生平台离线)
  │     └─ 有瓦片 → 渲染
  │     └─ 无瓦片/Web平台 ↓
  │
  └─ 3. 高德 (GCJ-02, 国内降级)
        └─ 渲染 + CoordTransform 坐标转换
SmartTileProvider 设计

SmartTileProvider
  ├── tileServerUrl: String?    // 自有服务器瓦片地址
  ├── mbtilesProvider: MBTilesTileProvider?  // 原生平台离线
  ├── fallbackUrl: String?     // 降级源（高德）
  ├── _isGcj02Fallback: bool   // 降级源是否需要坐标转换
  │
  ├── getImage(coordinates)
  │     1. 尝试 tileServerUrl (NetworkTileProvider)
  │     2. 失败 → 尝试 mbtilesProvider
  │     3. 失败 → 尝试 fallbackUrl
  │
  └── shouldTransformCoordinates() → bool
        // 告知渲染层是否需要 WGS-84→GCJ-02 转换
各平台行为
平台	主源	回退1	回退2
Web (国内)	tileserver-gl	—	高德 + 坐标转换
Web (海外)	tileserver-gl	—	OSM CDN
原生 (国内)	tileserver-gl	MBTiles 离线	高德 + 坐标转换
原生 (海外)	tileserver-gl	MBTiles 离线	OSM CDN
配置来源
MapConfig 扩展：


class MapConfig {
  // 自有瓦片服务器（部署后设置）
  static const String selfHostedTileUrl =
      'http://172.22.1.123:18080/tiles/{z}/{x}/{y}.png';

  // 国内降级源
  static const String chinaFallbackUrl =
      'https://webrd02.is.autonavi.com/appmaptile?...&x={x}&y={y}&z={z}';

  // 海外降级源
  static const String overseasFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
通过 --dart-define=REGION=china|overseas 控制降级源选择，默认自动检测（tileserver-gl 可达则无需降级）。

对现有代码的影响
FencePage / FenceFormPage / FarmCreation：TileLayer 从 urlTemplate: MapConfig.tileUrlTemplate 改为 tileProvider: SmartTileProvider(...)
围栏坐标渲染：当 SmartTileProvider.shouldTransformCoordinates() 为 true 时，PolygonLayer 的顶点经过 CoordTransform.wgs84ToGcj02All() 转换
围栏绘制/编辑：用户在 GCJ-02 地图上画的顶点，保存前逆转换为 WGS-84

## 设计 Section 3：坐标系统 + 字体处理
坐标系统规则
铁律：数据库永远存 WGS-84。


存储层 (DB):        WGS-84 (GPS 原始坐标)
    ↕ 
应用层 (Spring Boot): WGS-84 (不做转换)
    ↕
API 传输:            WGS-84 (API 响应 lat/lng 字段，全部为 WGS-84 GPS 原始坐标。)
    ↕
Flutter 渲染层:      按地图源决定是否转换
场景	地图源	围栏顶点处理
自有 tileserver-gl	WGS-84	直接渲染，不转换
本地 MBTiles	WGS-84	直接渲染，不转换
高德降级	GCJ-02	CoordTransform.wgs84ToGcj02() 渲染时转换
围栏绘制(高德)	GCJ-02	采集坐标 → gcj02ToWgs84() 逆转换 → 存储为 WGS-84
需要在 CoordTransform 中补充反向转换 gcj02ToWgs84()（迭代法，精度 < 1m）。

字体处理
现状：NotoSansSC 已本地打包（3 个 TTF，共 30MB），pubspec.yaml 已声明。Flutter Web 仍尝试从 fonts.gstatic.com 加载子集是引擎行为，实际字体已从本地加载成功。

方案：无需改动。字体加载失败的警告不影响显示（本地字体作为主源已生效）。如果未来确认有字符缺失，可通过 flutter build web --no-tree-shake-fonts 禁用字体裁剪。

完整设计总结
三个独立单元：

单元	职责	依赖
瓦片数据管线	海外生成 MBTiles → 导入国内 tileserver-gl	海外服务器、Docker
SmartTileProvider	在线/离线/降级三级回退	flutter_map、现有 MBTilesTileProvider
坐标适配层	WGS-84↔GCJ-02 双向转换	CoordTransform（已有 + 补充逆转换）
不改动：后端 API、数据库、Spring Boot 业务逻辑、字体处理。