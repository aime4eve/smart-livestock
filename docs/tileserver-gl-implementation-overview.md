# tileserver-gl 实现与业务流程总览

**日期**: 2026-06-17
**关联设计**: `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`
**关联部署文档**: `docs/tileserver-deployment-guide.md`

---

## 架构分层

整个瓦片系统分三层,各司其职:

```
[OSM 源] → [MBTiles 离线包] → [tileserver-gl 容器] → [nginx 代理] → [后端元数据 API] → [Flutter SmartTileProvider 三级降级]
```

---

## 一、基础设施层(Docker + nginx)

**`docker-compose.yml` 中的 tileserver 服务**(已从部署文档的 snap Docker 限制方案演化为命名卷方案):

```yaml
tileserver:
  image: maptiler/tileserver-gl:latest
  volumes:
    - tileserver-data:/data        # 命名卷,挂载所有 MBTiles
  ports:
    - "8081:8080"
  command: ["-c", "config.json", "--port", "8080"]
```

- 数据卷 `tileserver-data` 同时以只读方式挂到 app 容器 `/data/mbtiles:ro`,供后端直接读取 MBTiles 文件做下载分发。
- 部署文档 `docs/tileserver-deployment-guide.md:82-92` 记录的是早期 snap Docker 方案(数据放 `/home/agentic/tileserver-data/`,无 `ports`,靠 nginx 代理),当前 `docker-compose.yml` 已改为命名卷 + 端口映射,两者存在差异(见下文「值得注意的点」)。

**nginx 代理**(`infrastructure/nginx/nginx.conf`):

```nginx
location /tiles/ {
    proxy_pass http://tileserver:8080/data/;
    proxy_intercept_errors on;
    error_page 404 = @empty_tile;     # 404 → 透明 1×1 PNG
    add_header Cache-Control "public, max-age=2592000";
}
location @empty_tile { internal; rewrite ^ /empty.png last; }
```

- 关键设计:**nginx 把 tileserver 的 404 拦截后返回 `empty.png`(1×1 透明图)**,这样客户端不需要做瓦片范围判断,超出 MBTiles bbox 的请求自动变透明,无缝叠加。
- `empty.png` 是 nginx 镜像内的真实文件(`infrastructure/nginx/empty.png`),因为 nginx `return` 指令不解析 `\x` 十六进制转义,必须用文件。

---

## 二、后端元数据与下载层(Ranch 上下文)

后端不直接渲染瓦片,只管理 **瓦片区域注册表 + 生成任务 + 牧场-区域关联 + 下载分发**。5 张表(`V13` 迁移):

| 表 | 作用 |
|---|---|
| `tile_regions` | MBTiles 文件注册表(name/bbox/zoom/fileName/md5/status) |
| `tile_generation_tasks` | 瓦片生成任务(供外部脚本回调更新状态) |
| `farm_tile_tasks` | 牧场×区域多对多关联 + 下载状态(`UNIQUE(farm_id, region_id)`) |
| `tile_download_logs` | 客户端下载历史(V19 移除了 FK 约束) |

**三个 Controller:**

- `TileController`(`/api/v1`)— 同时承担 admin 和 app 职责:
  - `GET /admin/tiles/status` — 扫描 `/data/mbtiles` 目录列出 `.mbtiles` 文件
  - `GET /farms/{farmId}/offline-map?regionName=` — **MBTiles 文件下载**,带路径穿越防护(`normalize()` + `startsWith` 检查),按 farm 归属校验后返回 `FileSystemResource`
- `TileAdminController`(`/api/v1/admin/tiles`)— 区域/任务的 CRUD(管理后台用)
- `TileAppController`(`/api/v1/farms/{farmId}`)— App 端三个端点:
  - `GET /tile-status` — 该牧场可用的区域及状态
  - `GET /tile-source` — 返回 `TileSourceDto`(sourceName + `tileServerBaseUrl + "/tiles/" + name + "/{z}/{x}/{y}.png"`),这是给 Flutter 拼瓦片 URL 的
  - `POST /tile-download-log` — 记录下载日志

**`TileAdminService` 核心业务逻辑:**

- `handleFarmTileDetection(farmId, bbox, coverageRatio)` — 用 `TileCoverageCalculator` 算围栏 bbox 与覆盖率,查 `findIntersecting` 命中区域;覆盖率 <0.3 或无命中 → 自动创建自定义生成任务(`custom-farm-{id}`);命中则建 `FarmTileTask`(状态 pending/ready)
- `updateTaskStatus` — 外部生成脚本回调,任务 `done` 时自动推进所有关联 `FarmTileTask` 从 pending → ready(`advanceFarmTileTasks`)
- `getFarmTileSources` — 只返回 status=ready 的区域,拼出 tileserver URL

**`TileCoverageCalculator`** — 纯几何计算:围栏顶点 → bbox + Shoelace 公式算多边形面积 / bbox 面积 = 覆盖率,用于判断是否需要生成自定义区域。

---

## 三、前端 Flutter 层(三级降级)

**`SmartTileProvider`**(`lib/core/map/smart_tile_provider.dart`)是核心,三级回退:

```
1. tileserver-gl (selfHosted) → 2. 本地 MBTiles → 3. 高德/OSM 在线降级
```

- **健康检测**:启动时请求一张已知瓦片(z=12, x=3332, y=1712,长沙中心),2s 超时;失败则降级
- **定时恢复**:`startHealthMonitor` 每 60s 探测一次,自建服务恢复后自动切回
- **GCJ-02 处理**:`shouldTransformCoordinates()` — 降级到高德时需坐标偏移转换
- **MBTiles 兜底**:`mbtilesProvider.hasTile()` 判断本地是否有该瓦片,无则继续走 fallback

**`TileSourceResolver`**(`lib/core/map/tile_source_resolver.dart`)— 调 `GET /farms/{farmId}/tile-source` 拿到后端动态返回的瓦片 URL。

**`OfflineTileManager`**(`lib/features/offline_tiles/presentation/offline_tile_manager.dart`)— 离线下载管理:

- 查 `tile-status` → 逐区域下载 MBTiles → **MD5 校验**(服务端 md5 vs 本地 crypto md5)→ 写入本地 SQLite(`tile_metas` 表)+ 支持按牧场 pin/unpin

---

## 四、完整业务流程(端到端)

```
① 管理员准备瓦片:
   tooling/download_mbtiles.py 下载 OSM → 打包 MBTiles → 上传到 tileserver-data 卷
   → 后端 upsertRegion() 注册到 tile_regions 表

② 牧场匹配:
   创建牧场/画围栏 → TileCoverageCalculator 算 bbox + 覆盖率
   → findIntersecting 命中已有区域 → 建 farm_tile_tasks(status=ready)
   → 未命中 → 自动创建 tile_generation_tasks(custom) → 外部脚本生成 → 回调 done → farm_tile_tasks 推进为 ready

③ App 端地图渲染:
   ranch_page 启动 → SmartTileProvider.create() 健康检测
   → 优先 tileserver-gl(http://172.22.1.123:18080/tiles/{name}/{z}/{x}/{y}.png)
   → 失败降级本地 MBTiles → 再失败降级高德/OSM

④ App 端离线下载:
   OfflineTileManager → GET tile-status → 下载 offline-map MBTiles
   → MD5 校验 → 存本地 SQLite → POST tile-download-log
```

---

## 值得注意的点

- **部署文档与 docker-compose 不一致**:`tileserver-deployment-guide.md` 写的是 snap Docker 方案(数据在 `/home/agentic/tileserver-data/`,无 ports,靠 nginx 代理,`command: /data/config.json`),而当前 `docker-compose.yml` 用命名卷 + `ports: 8081:8080` + `command: ["-c", "config.json", "--port", "8080"]`。文档未同步更新,建议确认线上实际用的是哪套。
- **`TileController` 职责混合**:同时承载 `/admin/tiles/status`(管理)和 `/farms/{farmId}/offline-map`(App 下载),而 `TileAppController`、`TileAdminController` 已按职责拆分。`TileController` 的 admin 端点可考虑迁移到 `TileAdminController` 统一。
- **V24 种子数据**:15 个全球区域已 seed(长沙、内蒙古、新疆、青藏、澳大利亚、新西兰、斯堪的纳维亚驯鹿区等),farm 1/2/5 已按坐标匹配到 changsha 区域,状态均为 ready。
- **路径穿越防护**:`downloadOfflineMap` 做了 `normalize() + startsWith(TILES_DIR)` 校验,防止 `../../` 攻击,这点做得好。
