# 智能瓦片路由设计（P3）

**日期**: 2026-07-04
**状态**: DRAFT
**关联文档**: `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`（前序方案，三级降级）
**关联代码**: `smart_tile_provider.dart`、`mbtiles_tile_provider_io.dart`、`offline_tile_manager.dart`、`offline_tile_management_page.dart`

---

## 1. 背景

项目面向国际市场（欧洲、美洲、大洋洲），也需要覆盖中国。地图是围栏、地图监控、牧场管理等核心功能的基础。

### 1.1 现状

SmartTileProvider 采用**全局模式切换**：

```
启动 → 健康检查 tileserver（2s 超时）→ 锁定单一数据源
tileserver 可用 → 全部用 tileserver
tileserver 不可用 → 降级到 MBTiles
MBTiles 无瓦片 → 降级到 OSM/高德
```

### 1.2 问题

| 问题 | 原因 |
|------|------|
| 用户缩放到 z16+ 白屏 | tileserver 瓦片只有 z12-15，全局锁定后不逐瓦片降级 |
| 启动有 2s 阻塞 | `performHealthCheck()` await 超时后才开始渲染 |
| 离线瓦片没被实际使用 | `OfflineTileManager.startForegroundDownload()` 代码完整但管理页面没接通下载按钮 |
| 大文件下载 OOM | `startForegroundDownload()` 用 `http.get()` 一次性读入内存 |
| 逐瓦片 SQLite 查询慢 | `hasTile()` 每个可见瓦片做一次 SELECT |
| 无网时每瓦片等超时 | 没有 OSM 连通性缓存，离线时每张瓦片等 30s 超时 |
| tileserver URL 硬编码 changsha | `MapConfig.selfHostedTileUrl` 写死 region |

### 1.3 已有组件

| 组件 | 文件 | 状态 |
|------|------|------|
| MBTilesTileProvider | `core/map/mbtiles_tile_provider_io.dart` | 可用，但每次查 SQLite |
| SmartTileProvider | `core/map/smart_tile_provider.dart` | 全局模式切换，需重写 |
| OfflineTileManager | `offline_tiles/presentation/offline_tile_manager.dart` | 下载/删除/存储统计逻辑完整，未接通 UI |
| OfflineTileManagementPage | `offline_tiles/presentation/offline_tile_management_page.dart` | 只显示服务端状态，无下载/删除/存储 |
| tile-worker | `infrastructure/tile-worker/` | 服务端按牧场坐标生成 mbtiles |
| `/farms/{id}/offline-map` | `TileController.java` | 返回 mbtiles 文件 |
| `/farms/{id}/tile-tasks` | `TileAppController.java` | owner 触发生成 |
| `/farms/{id}/tile-status` | `TileAppController.java` | 返回已生成区域 |
| `/farms/{id}/tile-source` | `TileAppController.java` | 返回 tileserver URL |
| AppDatabase | `core/database/app_database_io.dart` | tile_metas 表（region_name/file_path/md5/status） |
| pubspec | sqlite3 ^2.4.6, path_provider, http, crypto | 已有依赖 |

### 1.4 已验证的事实

- tileserver 容器跑在服务器 172.22.1.123，通过 HTTP 提供瓦片（`/tiles/{region}/{z}/{x}/{y}.png`）
- 服务器上的 mbtiles 文件覆盖 z12-15（不同 region 范围不同）
- app 内置 `sample.mbtiles`（长沙 z12-14，~3.5MB）作为最终兜底
- OSM 和 tileserver 瓦片都是 WGS-84，坐标系统一
- 项目主要面向国际市场，OSM 全球覆盖好
- snap Docker 无法 bind mount `/data/agentic` 下的路径

---

## 2. 方案：逐瓦片智能路由

### 2.1 核心设计

去掉全局模式切换。每个瓦片请求（z/x/y）独立按优先级判断：

```
getImage(z, x, y):
  1. 本机已下载的 mbtiles 有这张瓦片？
     → 有：从本地文件读取（零延迟、零网络）

  2. OSM 在线加载（全缩放、全球覆盖）

  3. OSM 持续失败 → 切换到 tileserver 兜底
     （按 region URL 加载，覆盖 z12-15）
```

### 2.2 渲染优先级矩阵

| 场景 | 本机有瓦片 | 本机无瓦片 |
|------|-----------|-----------|
| 有互联网 | 本机 mbtiles（秒加载） | OSM 在线 |
| 无互联网 + 服务器可达 | 本机 mbtiles | tileserver（z12-15） |
| 无互联网 + 服务器不可达 | 本机 mbtiles | 空白（符合预期） |

### 2.3 连通性缓存

OSM 连通性状态缓存 30 秒：
- 最近 30s 内任意一次 OSM 请求成功 → `online = true`
- 最近 30s 内连续 3 次超时/失败 → `online = false`
- `online = false` 时跳过 OSM 直接走 tileserver
- 后台每 30s 探测一次恢复

这避免了无网时每个瓦片等超时（30s × 20 瓦片 = 10 分钟空白）。

### 2.4 MBTiles 内存元数据缓存

加载 mbtiles 文件时，将缩放范围和经纬度边界缓存到内存：

```dart
class MbtilesMeta {
  final String regionName;
  final String filePath;
  final int minZoom;
  final int maxZoom;
  final double minLon, minLat, maxLon, maxLat;
}
```

`getImage()` 先做内存判断（经纬度边界 + 缩放范围，微秒级），命中才查 SQLite。
多文件场景：遍历所有已加载文件的 meta，找到包含当前瓦片的那个文件，只查它的 SQLite。

### 2.5 离线瓦片管理

用户通过管理页面主动下载、查看、删除离线瓦片：

```
离线地图管理页面
├── 可用区域（服务端已生成的）
│   └── 下载按钮 → 流式下载 mbtiles → MD5 校验 → 存入本机 → 更新 SQLite
├── 已下载区域（本机已有的）
│   ├── 显示：区域名、大小、缩放范围
│   ├── 删除按钮 → 删文件 + 清 SQLite
│   └── 重新下载按钮（MD5 不匹配时）
├── 存储用量（总占用 / 设备可用空间）
└── 下载进度条（分区域显示百分比）
```

### 2.6 流式下载

`startForegroundDownload()` 改为流式：

```dart
final request = http.Request('GET', uri);
final response = await client.send(request);
final sink = File(tempPath).openWrite();
int received = 0;
await response.stream.listen(
  (chunk) { received += chunk.length; sink.add(chunk); onProgress(received / total); },
  onDone: () => sink.close(),
).asFuture();
```

### 2.7 tileserver URL 动态化

启动时从 `/farms/{farmId}/tile-source` 获取 region URL，传入 SmartTileProvider。
ranch_page / fence_page / fence_form_page 已实现此逻辑，需统一到所有地图页。

---

## 3. 范围

### 改动文件

| 文件 | 改动 |
|------|------|
| `smart_tile_provider.dart` | 重写：逐瓦片路由 + 连通性缓存 + 多 mbtiles 支持 |
| `mbtiles_tile_provider_io.dart` | 增加 MbtilesMeta 缓存 + 按坐标快速判断 |
| `offline_tile_manager.dart` | 流式下载 + 多文件管理 |
| `offline_tile_management_page.dart` | 完整 UI：下载/进度/存储/删除 |
| `map_config.dart` | 移除 selfHostedTileUrl 硬编码，默认源改 OSM |
| `app_database_io.dart` | tile_metas 查询优化（如需） |
| 6 处地图页 | 统一 SmartTileProvider 创建方式 |

### 不改

- 后端 API（已有端点足够）
- tile-worker（服务端生成逻辑不变）
- 坐标转换（国际场景不需要 GCJ-02 转换）

---

## 4. 验收标准

1. **流畅缩放**：有网时从 z3 到 z19 全程 OSM 在线渲染，无空白
2. **离线优先**：本机已下载的区域，对应缩放级别内秒加载
3. **自动降级**：无网时 OSM 请求不阻塞，30s 内切换到 tileserver
4. **离线下载**：管理页面能下载、查看、删除离线瓦片，大文件不 OOM
5. **存储管理**：显示已用空间，可删除释放
6. **启动无阻塞**：地图页打开即渲染（OSM 或本地），不等健康检查
7. **flutter analyze** 无错误
8. **冒烟测试**：有网/无网/有离线包/无离线包 四种组合验证通过

---

## 5. 技术约束

- Flutter Web 平台无 SQLite，mbtiles 功能仅限原生平台（已有 stub 处理）
- OSM 有 rate limit（~100 req/min），但配合连通性缓存和本地 mbtiles 命中，实际请求量可控
- 服务器在中国，国际用户无互联网时无法访问 tileserver——这是预期行为
- sample.mbtiles 保留作为最终兜底，不删除

---

## 6. 国际化（i18n）

新增 i18n key（app_zh.arb + app_en.arb 同步）：

- offlineTileDownload / offlineTileDownloading / offlineTileDownloadFailed
- offlineTileDelete / offlineTileDeleteConfirm
- offlineTileStorageUsed / offlineTileStorageAvailable
- offlineTileProgress / offlineTileRedownload
- tileSourceOnline / tileSourceOffline / tileSourceServer
