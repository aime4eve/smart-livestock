# 离线地图与电子围栏集成设计

**日期**: 2026-05-27
**状态**: APPROVED
**关联 PRD**: `.claude/PRPs/prds/offline-first-map.prd.md`
**关联设计**: `docs/superpowers/specs/2026-05-15-multi-region-map-tiles-design.md`

---

## 1. 问题

离线地图瓦片管线（tileserver-gl + MBTiles + SmartTileProvider）和电子围栏系统各自独立运行，未形成闭环：

- 创建牧场时不画围栏，牧场与围栏无地理关联
- SmartTileProvider 硬编码 `changsha`，切换牧场后瓦片源不对
- 围栏数据无本地缓存，离线时围栏不可见
- 客户端无离线瓦片下载/管理能力
- tooling（generate_mbtiles.py / import_mbtiles.sh）手动运行，不受数据库驱动
- API Key 认证是 stub，tooling 无法安全调用管理 API

### 已有能力

| 能力 | 状态 | 文件 |
|------|------|------|
| tileserver-gl + 15 区域 MBTiles | ✅ 运行中 | 172.22.1.123:18080 |
| SmartTileProvider 三级降级 | ✅ 完成 | `core/map/smart_tile_provider.dart` |
| WGS-84 ↔ GCJ-02 坐标转换 | ✅ 完成 | `core/map/coord_transform.dart` |
| TileController 按 farm 匹配 MBTiles | ✅ 完成 | `TileController.java` |
| 围栏绘制/编辑/命中检测 | ✅ 完成 | `features/fence/` |
| Farm 创建向导（3 步） | ✅ 完成 | `features/farm_creation/` |
| api_keys 表 | ⚠️ 表存在，验证逻辑是 stub | V1 迁移 |

### 待解决问题

| 问题 | 影响 |
|------|------|
| Farm 与边界围栏无 1:1 绑定 | 无法根据围栏计算瓦片需求 |
| 无离线围栏缓存 | 离线时围栏不可见，核心功能失效 |
| 无客户端瓦片下载 | 15 个区域 MBTiles 无法预装到设备 |
| tooling 手动运行 | 新牧场创建后无法自动触发瓦片生成 |
| 无 API Key 认证 | tooling 无法安全调用管理 API |

---

## 2. 总体方案

数据库驱动的完整离线地图 + 围栏集成管线：

```
创建牧场（画边界围栏）
  → 服务端：Fence(type=boundary) + 检测 tile_regions 覆盖（牧场可跨多个区域）
     ├─ 已覆盖 → 每个匹配的 region 一条 farm_tile_tasks(status=ready)
     └─ 未覆盖 → tile_generation_tasks(status=pending)
                 + farm_tile_tasks(status=pending)（按缺失区域各一条）

管理员查看 pending 任务（UI / API）
  → 触发 generate_mbtiles.py --task-id N（API Key 认证）
     → 从 API 读取 bbox/zoom → 生成 MBTiles → 回调 API 更新状态
  → 运行 import_mbtiles.sh（同步到 tileserver + 更新 DB）
     → farm_tile_tasks → status=ready

客户端（WiFi 自动 / 移动网络提示）
  → GET /farms/{id}/tile-status → 返回该牧场关联的所有区域列表
  → 逐个下载各区域 MBTiles → 存本地（按区域名共享）
  → SmartTileProvider 加载该牧场关联的所有本地 MBTiles

围栏数据
  → 在线时缓存到本地 SQLite
  → 离线时可查看 + 可编辑
  → 上线后同步，版本冲突提示用户选择
```

---

## 3. 数据模型

### 3.1 新增 4 张表（Flyway V15）

```sql
-- 服务端已有的 MBTiles 文件（矩形，匹配瓦片网格格式）
CREATE TABLE tile_regions (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    min_lon     DOUBLE PRECISION NOT NULL,
    min_lat     DOUBLE PRECISION NOT NULL,
    max_lon     DOUBLE PRECISION NOT NULL,
    max_lat     DOUBLE PRECISION NOT NULL,
    min_zoom    INT NOT NULL DEFAULT 11,
    max_zoom    INT NOT NULL DEFAULT 15,
    file_name   VARCHAR(255),
    file_size   BIGINT,
    md5         VARCHAR(32),
    generated_at TIMESTAMPTZ,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 瓦片生成任务（服务端）
CREATE TABLE tile_generation_tasks (
    id              BIGSERIAL PRIMARY KEY,
    region_id       BIGINT REFERENCES tile_regions(id),
    min_lon         DOUBLE PRECISION NOT NULL,
    min_lat         DOUBLE PRECISION NOT NULL,
    max_lon         DOUBLE PRECISION NOT NULL,
    max_lat         DOUBLE PRECISION NOT NULL,
    min_zoom        INT NOT NULL DEFAULT 11,
    max_zoom        INT NOT NULL DEFAULT 15,
    region_name     VARCHAR(100) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    triggered_by    VARCHAR(50),
    tile_count      INT,
    file_size_mb    DOUBLE PRECISION,
    error_message   TEXT,
    started_at      TIMESTAMPTZ,
    finished_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 每个牧场 × 每个区域的瓦片下载状态（一个牧场可跨多个区域）
CREATE TABLE farm_tile_tasks (
    id              BIGSERIAL PRIMARY KEY,
    farm_id         BIGINT NOT NULL REFERENCES farms(id),
    region_id       BIGINT NOT NULL REFERENCES tile_regions(id),
    status          VARCHAR(30) NOT NULL DEFAULT 'pending',
    file_size       BIGINT,
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(farm_id, region_id)
);

-- 客户端下载历史（多设备场景）
CREATE TABLE tile_download_logs (
    id              BIGSERIAL PRIMARY KEY,
    farm_tile_task_id BIGINT NOT NULL REFERENCES farm_tile_tasks(id),
    user_id         BIGINT NOT NULL REFERENCES users(id),
    device_info     VARCHAR(255),
    bytes_downloaded BIGINT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at     TIMESTAMPTZ
);
```

### 3.2 Fence 表增加字段

```sql
ALTER TABLE fences ADD COLUMN version INT NOT NULL DEFAULT 1;
ALTER TABLE fences ADD COLUMN fence_type VARCHAR(20) NOT NULL DEFAULT 'sub';
```

每次 UPDATE fence 顶点时 `SET version = version + 1`，WHERE 条件加 `AND version = :expectedVersion`，不匹配则返回 409。

### 3.3 tile_regions 与围栏的匹配逻辑

围栏可以是任意多边形（含近似圆形），tile_regions 始终是矩形（匹配 MBTiles 瓦片网格）。匹配时取围栏顶点的外接矩形（bbox），检查与哪些 tile_region 的 bbox 有交集。一个牧场的 bbox 可能与多个 region 重叠（如内蒙古牧场同时覆盖 `inner-mongolia` 和 `mongolia`），此时为每个匹配的 region 创建独立的 farm_tile_task 记录。

---

## 4. API Key 认证补全

现有 `api_keys` 表（V1 迁移）含 `id, tenant_id, key_hash, name, role, active, expires_at, created_at`。

### 4.1 后端实现

| 组件 | 变更 |
|------|------|
| `ApiKeyAdminController` | 新增 CRUD 端点（创建、列表、吊销、删除） |
| `SecurityConfig` | 新增 `ApiKeyAuthFilter`，在 JWT filter 之后检查 `X-API-Key` header |
| `ApiKeyAuthFilter` | `X-API-Key` header → SHA-256 hash → 查 api_keys 表验证 → 加载角色权限 → 放入 SecurityContext |
| 所有管理 API | 同时支持 JWT 和 API Key 两种认证方式 |

Key 生成：`sk_live_` + 32 字节随机 hex，存 SHA-256 hash 到 `key_hash`，明文仅在创建响应中返回一次。

### 4.2 API Key 管理 UI（platform_admin）

**位置**：`/ops/admin/api-keys`，platform_admin 侧边导航新增入口。

| 功能 | 说明 |
|------|------|
| 列表 | 显示所有 API Key：名称、角色、创建时间、状态、最后使用时间 |
| 创建 | 弹窗输入名称 + 选择角色 → 创建后仅显示一次明文 key，提示复制保存 |
| 吊销 | 确认后设置 `active=false`，该 key 立即失效 |
| 删除 | 物理删除记录（仅已吊销的 key 可删） |

---

## 5. 服务端 API

### 5.1 瓦片管理 API

| API | 方法 | 认证 | 说明 |
|-----|------|------|------|
| `GET /admin/tiles/regions` | GET | JWT/API Key | 列出所有 tile_regions |
| `GET /admin/tiles/tasks` | GET | JWT/API Key | 列出生成任务（可按 status 过滤） |
| `POST /admin/tiles/tasks` | POST | JWT | 手动创建生成任务 |
| `PUT /admin/tiles/tasks/{id}/status` | PUT | API Key | 更新任务状态（tooling 调用） |
| `GET /admin/tiles/farm-tasks` | GET | JWT | 列出所有牧场的瓦片状态 |
| `GET /farms/{id}/tile-status` | GET | JWT | 查询单个牧场的瓦片状态 |
| `GET /farms/{id}/tile-source` | GET | JWT | 返回该牧场关联的所有瓦片源（数组，跨区域时多条） |
| `POST /farms/{id}/tile-download-log` | POST | JWT | 记录客户端下载完成 |
| `GET /farms/{id}/offline-map` | GET | JWT | 下载 MBTiles 文件（已有，不变） |

### 5.2 Farm 创建时的瓦片检测

```
FarmApplicationService.createFarm(name, boundaryVertices)
  1. 创建 Farm + 边界围栏（Fence, fence_type=boundary, version=1）
  2. 计算 boundaryVertices 的外接矩形 bbox
  3. 查询 tile_regions: bbox 与哪些 region 有交集?
     ├─ 有交集的 region → 每个匹配 region 一条 farm_tile_tasks(status=ready)
     └─ bbox 未被完全覆盖的部分 → tile_generation_tasks(status=pending)
                                  + farm_tile_tasks(status=pending)
  4. 返回 Farm + tileStatus（含关联区域列表）
```

### 5.3 围栏更新 API（版本冲突）

```
PUT /fences/{id}
Body: { vertices: [...], expectedVersion: 2 }

→ 200: 更新成功（version → 3）
→ 409 Conflict: { serverVersion: 3, serverVertices: [...] }

PUT /fences/{id}/force
Body: { vertices: [...], version: 3 }
→ 200: 强制更新成功（version → 4）
```

---

## 6. Tooling 集成

### 6.1 generate_mbtiles.py — 新增 --task-id 模式

```bash
# 推荐方式：环境变量（不暴露在 ps aux 中）
export SMART_LIVESTOCK_API_KEY="sk_live_xxxxx"
python3 tooling/generate_mbtiles.py \
  --task-id 7 \
  --api-url http://172.22.1.123:18080/api/v1

# 备选方式：从文件读取（适合 CI/CD）
python3 tooling/generate_mbtiles.py \
  --task-id 7 \
  --api-url http://172.22.1.123:18080/api/v1 \
  --api-key-file ~/.config/smart-livestock/api-key
```

脚本按以下优先级获取 API Key：
1. 环境变量 `SMART_LIVESTOCK_API_KEY`（推荐）
2. `--api-key-file` 指定的文件路径
3. `--api-key` 直接传值（仅限本地开发，**禁止在生产环境使用**，`ps aux` 可见）

流程：
1. `GET /admin/tiles/tasks/7` → 获取 bbox, zoom, region_name
2. `PUT /admin/tiles/tasks/7/status` → `{ "status": "running" }`
3. 用已有 `generate_mbtiles()` 下载瓦片
4. 完成 → `{ "status": "done", "tileCount": N, "fileSizeMb": X }`
5. 失败 → `{ "status": "failed", "errorMessage": "..." }`

认证通过 `X-API-Key` header 调用管理 API。

### 6.2 import_mbtiles.sh — 导入后同步 DB

导入完成后调用管理 API 更新 tile_regions（file_name, file_size, md5, status=ready），并推进关联的 farm_tile_tasks 到 ready。认证方式与 generate_mbtiles.py 相同（环境变量优先）。

---

## 7. Flutter 客户端 — 离线瓦片

### 7.1 SmartTileProvider 动态区域解析

切换牧场时调用 `GET /farms/{id}/tile-source`，返回该牧场关联的所有瓦片源（数组）。跨区域牧场返回多个 source：

```json
[
  { "sourceName": "inner-mongolia", "tileUrl": "http://172.22.1.123:18080/tiles/inner-mongolia/{z}/{x}/{y}.png" },
  { "sourceName": "mongolia", "tileUrl": "http://172.22.1.123:18080/tiles/mongolia/{z}/{x}/{y}.png" }
]
```

SmartTileProvider 加载多个 MBTiles 文件，按瓦片坐标在哪个文件有数据就取哪个。无瓦片的区域降级到高德/OSM。

### 7.2 OfflineTileManager（Riverpod 单例）

```dart
class OfflineTileManager {
  Future<TileStatus> getTileStatus(int farmId);
  Future<void> startForegroundDownload(int farmId, {onProgress, onComplete, onError});
  Future<void> enqueueBackgroundDownload(int farmId);
  void cancelDownload(int farmId);
  Future<void> deleteLocalTiles(String regionName);
  Future<List<LocalTileInfo>> getLocalTiles();
  Future<int> getStorageUsed();
  Future<void> evictIfNeeded({int maxBytes = 1024 * 1024 * 1024});

  // Pin/Unpin：保护瓦片不被 LRU 淘汰
  Future<void> pin(int farmId);
  Future<void> unpin(int farmId);
  Future<bool> isPinned(int farmId);
}
```

下载策略（两阶段）：

**阶段 1：前台下载（优先）**
- 用户主动触发或 App 在前台时执行
- 使用 `http` 包 + Isolate 分段下载，配合 HTTP Range 头断点续传
- 显示进度条 + 屏幕常亮（`wakelock`），用户可随时暂停/继续
- 一个牧场关联多个区域时逐个下载，汇总显示进度

**阶段 2：后台下载（降级）**
- 用户切到后台或锁屏时，前台下载中断
- 使用 `workmanager` 注册后台任务，在系统允许的时间窗口内继续分段下载
- iOS：使用 `BGAppRefreshTask`（系统决定时机，不保证执行）
- Android：使用 `WorkManager`（约束：WiFi + 充电时触发）
- 后台下载完成后发本地通知

**网络策略**：
- WiFi：自动执行前台下载，后台任务无网络约束
- 移动网络：底部横幅提示确认后再下载，后台任务仅 WiFi 约束下触发

本地存储（按区域名，多牧场共享同一区域的瓦片）：
```
getApplicationSupportDirectory()/mbtiles/{regionName}.mbtiles
getApplicationSupportDirectory()/mbtiles/{regionName}.meta.json
```

引用计数：meta.json 记录引用该区域的 farmId 列表 + pinned 状态，删除牧场时仅在该区域无其他牧场引用时才删除瓦片文件。

支持断点续传（HTTP Range 请求）。

**Pin/Unpin 机制**：

| 自动 pinned | 触发时机 |
|-------------|---------|
| 当前选中牧场 | 切换牧场时自动 pin 新牧场 |
| 用户手动标记 | 离线瓦片管理页长按牧场 → "保留离线地图" |

LRU 淘汰规则：仅淘汰 **unpinned** 且最久未访问的牧场关联区域。如果一个区域被多个牧场引用（包括 pinned 牧场），该区域不会被删除。

### 7.3 离线瓦片管理页面

**位置**：`/settings/offline-maps`，从「我的」页面进入。

显示：当前牧场瓦片状态、其他牧场瓦片列表、存储空间（默认上限 1GB）、操作（下载/暂停/删除/更新）。

### 7.4 瓦片更新检测

本地 `meta.json` 记录 `regionGeneratedAt`，WiFi 下 App 启动时对比服务端 `tile_regions.generated_at`，过期则提示更新。

### 7.5 本地数据库选型

项目中有两类 SQLite 使用场景，采用不同方案：

| 场景 | 方案 | 理由 |
|------|------|------|
| MBTiles 瓦片读取 | `sqlite3` + `sqlite3_flutter_libs`（已有） | MBTiles 是外部生成的标准格式，只需只读查询，不需要 migration |
| 围栏缓存、牲畜位置等结构化业务表 | **drift**（Flutter SQLite ORM） | 需要 migration 管理、类型安全查询、版本化 schema 演进、响应式 watch |

drift 的优势：
- **Schema 版本管理**：`schemaVersion` + `onUpgrade` 回调，cached_fences 加字段时自动迁移
- **类型安全**：Dart 代码生成查询，编译期发现 SQL 拼写错误
- **响应式**：`watch()` 方法监听表变化，UI 自动刷新（适合离线同步状态条）
- **事务支持**：围栏批量同步时保证原子性

依赖变更：
```yaml
# pubspec.yaml 新增
dependencies:
  drift: ^2.18
  sqlite3_flutter_libs: ^0.5.42  # 已有，drift 底层也用此包
  workmanager: ^0.5.2             # 后台分段下载
  wakelock_plus: ^1.2             # 前台下载时保持屏幕常亮
dev_dependencies:
  drift_dev: ^2.18
  build_runner: ^2.4
```

---

## 8. Flutter 客户端 — 离线围栏

### 8.1 围栏本地缓存（SQLite）

```sql
CREATE TABLE cached_fences (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    fence_type  TEXT NOT NULL,
    vertices    TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'active',
    version     INTEGER NOT NULL DEFAULT 1,
    synced      INTEGER NOT NULL DEFAULT 0,
    updated_at  TEXT NOT NULL,
    remote_id   INTEGER
);
```

同步策略：在线时 API 数据覆盖本地（跳过未同步修改），离线时读本地缓存渲染。

### 8.2 离线围栏编辑

离线时允许创建、编辑顶点、删除围栏。修改写入 `cached_fences`（`synced=0`），底部显示未同步数量。

### 8.3 上线同步 + 冲突检测

```
网络恢复 → 查 synced=0 → 逐条处理：
  ├─ 新建围栏 → POST /fences → 更新本地
  ├─ 版本一致 → PUT /fences/{id} → synced=1
  └─ 版本冲突 → 弹窗：放弃修改 或 覆盖服务端
```

### 8.4 Farm 创建集成

FarmCreationWizardPage Step 2 保存边界围栏后，服务端创建 `Fence(fence_type=boundary)` + 检测瓦片覆盖。Step 3 显示瓦片状态。

### 8.5 牲畜位置离线显示

```sql
CREATE TABLE cached_livestock_positions (
    livestock_id  INTEGER PRIMARY KEY,
    name          TEXT,
    latitude      REAL NOT NULL,
    longitude     REAL NOT NULL,
    recorded_at   TEXT NOT NULL,
    fence_id      INTEGER
);
```

在线时刷新缓存，离线时渲染 Marker + 时间戳（如"2 小时前"）。

---

## 9. 不改动的部分

- tileserver-gl 部署（已正常运行）
- 坐标转换（WGS-84 ↔ GCJ-02）
- 围栏绘制核心逻辑（fence_edit_operations.dart）
- 围栏命中检测（fence_hit_detection.dart）
- 围栏越界检测后端（FenceBreachDetector）
- Auth / JWT 认证流程
- 所有非地图/围栏的业务模块

---

## 10. 实施单元

| # | 单元 | 职责 | 依赖 |
|---|------|------|------|
| 1 | V15 迁移 + Fence version | 4 张新表 + fences 表扩展 | 无 |
| 2 | API Key 认证补全 | ApiKeyAuthFilter + 管理控制器 + 管理 UI | 单元 1 |
| 3 | TileAdminService + 瓦片管理 API | tile_regions/tasks 的 CRUD | 单元 1 |
| 4 | Farm 创建集成 | 创建时画边界围栏 + 检测瓦片覆盖 | 单元 1, 3 |
| 5 | Tooling 集成 | generate_mbtiles.py --task-id + import_mbtiles.sh 同步 DB | 单元 2, 3 |
| 6 | SmartTileProvider 动态区域 | 切换牧场时动态解析瓦片源 | 单元 3 |
| 7 | OfflineTileManager + 下载 | 客户端瓦片下载 + 断点续传 + LRU | 单元 6 |
| 8 | 离线瓦片管理 UI | 管理页面 + 存储 + 更新检测 | 单元 7 |
| 9 | 围栏本地缓存 | SQLite 缓存 + 在线/离线分支 | 单元 1 |
| 10 | 离线围栏编辑 + 冲突解决 | 本地编辑 + 版本冲突检测 | 单元 9 |
| 11 | 牲畜位置缓存 | GPS 坐标本地存储 + 离线渲染 | 单元 9 |

---

*Generated: 2026-05-27*
