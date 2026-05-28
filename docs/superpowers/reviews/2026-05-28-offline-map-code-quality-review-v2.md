# Plan A / B / C 代码质量评审报告 v2（Bug 修正后）

**日期**: 2026-05-28
**范围**: Plan A（Backend + Tooling）、Plan B（Flutter Offline Tiles）、Plan C（Offline Fences + Observability）
**评审方式**: 3 个专业 Agent 并行评审，逐一读取全部源文件后交叉审核
**关联 Plan**:
- `docs/superpowers/plans/2026-05-27-offline-map-backend-plan.md`
- `docs/superpowers/plans/2026-05-27-offline-map-flutter-tiles-plan.md`
- `docs/superpowers/plans/2026-05-27-offline-map-fences-plan.md`

---

## 评审结论

**状态: 阻断 — 发现 19 个严重问题、22 个高优先级问题，必须在合并前修复。**

三个 Plan 的架构设计是合理的（DDD 洋葱分层、Repository 模式、JPA 乐观锁、drift 离线存储），但实现层面存在较多缺陷。核心问题集中在：

1. **安全缺陷**（5 个）：admin 端点无权限、API Key filter 行为不一致、路径遍历风险、python3 代码注入、瓦片 URL 无访问控制
2. **数据正确性**（8 个）：乐观锁双重检查冗余、TileAdminController 传参错误、FarmTileTask 状态流转断裂、FenceSyncService 未注册 Provider、LRU 淘汰未实现、remoteId 未回写
3. **可靠性缺口**（6 个）：大文件 OOM、下载无超时/取消、JWT 过期未处理、离线冲突页面使用在线瓦片

---

## 全局统计

| Plan | 严重 | 高 | 中 | 低 | 合计 |
|------|------|-----|-----|-----|------|
| **Plan A** (Backend + Tooling) | 10 | 10 | 15 | 8 | **43** |
| **Plan B** (Flutter Offline Tiles) | 5 | 6 | 10 | 6 | **27** |
| **Plan C** (Offline Fences + Observability) | 4 | 6 | 8 | 4 | **22** |
| **总计** | **19** | **22** | **33** | **18** | **92** |

---

## Plan A — Backend + Tooling（43 个问题）

### 严重问题（10 个）

#### S1. AnalyticsController 全端点无认证保护
**文件**: `ranch/interfaces/AnalyticsController.java:16-43`
`/api/v1/analytics` 无 `@PreAuthorize`，无 Farm Scope 验证，任何已认证用户都能 POST 事件。端点收到事件后仅 `log.debug` 打印就丢弃，事件完全没有持久化。
**修复**: 持久化事件或标记为 `@Deprecated` 返回 501；添加权限注解。

#### S2. TileAppController.tile-download-log 使用 Map<String, Object> 直接取值
**文件**: `ranch/interfaces/TileAppController.java:50-63`
```java
Long farmTileTaskId = ((Number) body.get("farmTileTaskId")).longValue();
```
字段缺失/null 时 NPE，类型不符时 ClassCastException，返回 500 而非 400。
**修复**: 使用 DTO + `@Valid` 校验。

#### S3. TileController.downloadOfflineMap 路径遍历风险
**文件**: `ranch/interfaces/TileController.java:84-109`
`regions.json` 来自外部文件系统，如果内容被篡改（含 `../../etc/passwd`），虽然有 normalize 检查但依赖 `TILES_DIR` 是否以 `/` 结尾。
**修复**: 对 `matchedFile` 添加文件名白名单校验（只允许 `[a-zA-Z0-9_-]+\.mbtiles`）。

#### S4. ApiKeyAuthFilter 与 ApiKeyAuthService 的 Key 提取逻辑不一致
**文件**: `shared/security/ApiKeyAuthFilter.java:68-78` vs `shared/security/ApiKeyAuthService.java:53-63`
Filter 只匹配 `sk_live_` 前缀的 Bearer token，Service 对所有 Bearer token 都提取。两个类做同一件事但行为不同。
**修复**: 统一提取逻辑到 `ApiKeyAuthService`，Filter 调用 Service 的方法。

#### S5. ApiKeyAuthFilter 认证失败时直接写 response，绕过异常处理链
**文件**: `shared/security/ApiKeyAuthFilter.java:51-58`
Filter 直接返回 401 `{code: "AUTH_API_KEY_INVALID"}`，而 SecurityConfig 的 `authenticationEntryPoint` 返回 `AUTH_INVALID_TOKEN`。两处错误响应 code 不一致。
**修复**: 抛出 `AuthenticationException` 让 Spring Security 统一处理。

#### S6. FenceApplicationService.forceUpdateFence 的 version 参数完全未使用
**文件**: `ranch/application/FenceApplicationService.java:71-85`
`forceUpdateFence` 接收 `int version` 参数但方法体内未使用。"强制更新"仍依赖 JPA 乐观锁，并非真正忽略版本。
**修复**: 移除无用参数，或实现真正的强制更新（detach 实体 + 清空 version）。

#### S7. TileAdminController.listFarmTasks 传 regionId 当 farmId，数据完全错误
**文件**: `ranch/interfaces/TileAdminController.java:87-93`
```java
.map(r -> tileAdminService.getFarmTileStatus(r.id()))  // r.id() 是 TileRegion ID！
```
把 TileRegion 的 ID 当作 farmId 传入，查询 `farm_id = region_id` 的记录，结果无意义。
**修复**: 改为遍历所有 farm 或按 farm_tile_task 的 farm_id 分组。

#### S8. advanceFarmTileTasks 永远不执行——新创建的 TileGenerationTask 没有 regionId
**文件**: `ranch/application/TileAdminService.java:80-82,184-193`
`createTask` 创建的 TileGenerationTask 从未设置 `regionId`（只有 `regionName`），导致 `advanceFarmTileTasks` 中 `task.getRegionId() == null`，FarmTileTask 永远停在 pending。
**修复**: 在 `createTask` 时关联 regionId，或通过 regionName 查找 region 再推进。

#### S9. import_mbtiles.sh python3 命令注入风险
**文件**: `tooling/import_mbtiles.sh:18`
```bash
expected=$(python3 -c "import json; print(json.load(open('$meta'))['md5'])")
```
`$meta` 如果包含单引号，导致 python 代码注入。
**修复**: `python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['md5'])" "$meta"`

#### S10. TileAdminService.getFarmTileStatus 覆盖率硬编码为 0
**文件**: `ranch/application/TileAdminService.java:142`
```java
return new FarmTileStatusDto(farmId, regions, 0, false);
```
`coverageRatio` 永远返回 0，`coverageWarning` 永远 false。后续查询无法获知真实覆盖率。
**修复**: 缓存覆盖率或从关联数据重新计算。

### 高优先级问题（10 个）

| 编号 | 文件 | 问题 |
|------|------|------|
| H1 | `TileAdminController.java:30-71` | 全部端点使用 `Map<String, Object>` 接收参数，无类型安全，NPE/ClassCastException |
| H2 | `OpenDeviceRegisterController.java:89-97` | `resolveDeviceType` 无效值静默回退 TRACKER，可能导致设备类型错误 |
| H3 | `OpenDeviceRegisterController.java:107-113` | Rate Limit headers 是伪造的（Remaining 永远 = limit - 1） |
| H4 | `TileAdminService.java:93-95` | 覆盖率阈值判断逻辑矛盾——低覆盖率但有 intersecting regions 时丢弃匹配 |
| H5 | `FenceApplicationService.java:49-68` | updateFence 双重版本检查冗余且有 TOCTOU 问题 |
| H6 | `TileController.java:41` | `/api/v1/admin/tiles/status` 无 admin 角色限制 |
| H7 | `TileAdminService.java:157-158` | 瓦片 URL 只含 region name 无认证，知道 name 即可访问 |
| H8 | `ApiKeyApplicationService.java:60-61` | 每次 API 调用更新 lastUsedAt 导致额外 DB 写操作 |
| H9 | `FenceController.java:101-103` | catch STATE_CONFLICT 后 getFence 可能抛 RESOURCE_NOT_FOUND 导致 500 |
| H10 | `import_mbtiles.sh:11-12` | rsync 通配符远端无文件时脚本直接失败；`md5 -q` macOS 特有 |

### 中等问题（15 个）

| 编号 | 问题 |
|------|------|
| M1 | 所有 domain model 用 String 而非枚举表示 status |
| M2 | TileCoverageCalculator 用经纬度度数乘积代替面积，高纬度失真 |
| M3 | TileAdminService Collectors import 与全限定名混用 |
| M4 | TileRegion.intersectsBbox 方法存在但从未被调用 |
| M5 | TileAdminController.listFarmTasks 的 N+1 查询 |
| M6 | TileController 用 ResponseStatusException 而非统一 ApiException |
| M7 | TileController 用构造函数注入而其他 Controller 用 @RequiredArgsConstructor |
| M8 | TileController.getTileStatus 响应不包裹 ApiResponse |
| M9 | TileGenerationTaskDto.createdAt 永远为 null |
| M10 | FenceVersionTest 只有 3 个 mock 测试，缺少真实 JPA 乐观锁测试 |
| M11 | TileAdminServiceTest 未覆盖 upsertRegion、updateTaskStatus 等核心方法 |
| M12 | import_mbtiles.sh python3 嵌套引号易出错，应提取为独立 .py 文件 |
| M13 | SecurityConfig CORS 只配置 172.22.1.123，Open API 需额外域名 |
| M14 | TileController 与 TileAdminController 职责重叠 |
| M15 | V13 迁移 api_keys.role 默认值 'admin' 存在安全隐患 |

### 低优先级问题（8 个）

L1: FenceJpaEntity getter/setter 风格不一致 | L2: TileGenerationTaskDto.record 无自定义 toString | L3: updateTaskStatus 状态转换无校验 | L4: import_mbtiles.sh 缺少 usage 文档 | L5: AnalyticsController ALLOWED_EVENT_TYPES 硬编码 | L6: TileCoverageCalculator.shoelaceArea 对经纬度只给近似值 | L7: ApiKeyAuthService.validateFarmAccess 每次查数据库 | L8: 覆盖率阈值 0.3/0.5 硬编码

---

## Plan B — Flutter Offline Tiles（27 个问题）

### 严重问题（5 个）

#### S1. AppDatabase 默认构造函数同步打开 SQLite，Web 不支持且路径硬编码
**文件**: `core/database/app_database.dart:7-17,114-128`
`AppDatabase._()` 在 `instance` getter 中同步打开 sqlite3，Android 路径硬编码 `/data/data/com.example.smart_livestock_demo/databases`。Web 平台不支持同步 SQLite。
**修复**: 移除 `instance` 懒加载，强制使用 `createAsync()`。

#### S2. OfflineTileManager 下载无超时和取消支持
**文件**: `features/offline_tiles/presentation/offline_tile_manager.dart:70-76`
`http.get()` 无 `.timeout()`，MBTiles 文件可能几十 MB，弱网无限等待。无可取消机制。
**修复**: 添加 `.timeout(Duration(minutes: 5))` + 取消参数。

#### S3. 离线瓦片管理页路由在 ShellRoute 外，无底部导航
**文件**: `app/app_router.dart:368-372`
`offlineTileManagement` 路由定义在 `ShellRoute` 外，进入后"丢失"导航。
**修复**: 移入 `ShellRoute.routes` 列表。

#### S4. TileSourceResolver.resolve() 忽略 farmId 参数
**文件**: `core/map/tile_source_resolver.dart:22-32`
`resolve(int farmId)` 接受 farmId 但完全不用，依赖全局 activeFarmId，多牧场切换后可能返回旧牧场瓦片。
**修复**: 移除 farmId 参数或在方法内使用。

#### S5. LRU 淘汰机制完全缺失
**文件**: `offline_tile_manager.dart`, `app_database.dart`
`last_accessed_at` 从未在访问瓦片时更新，无 `evictOldest`/`ensureStorageLimit` 方法。离线瓦片无限增长。
**修复**: 实现 `evictToFit(int targetBytes)` 方法，访问时更新 `last_accessed_at`。

### 高优先级问题（6 个）

| 编号 | 文件 | 问题 |
|------|------|------|
| H1 | `offline_tile_manager.dart:70` | 整个 MBTiles 下载到内存，大文件 OOM（100MB 文件 → 峰值 200MB 内存） |
| H2 | `offline_tile_manager.dart:21-23` | 构造时固定 headers，JWT 过期后下载全部失败 |
| H3 | `offline_tile_management_page.dart` 全文 | 管理页无下载/删除/刷新/pin 操作，只能查看 |
| H4 | `app_database.dart:7-18` | AppDatabase 单例跨 Isolate 共享 sqlite3 连接，database is locked |
| H5 | `offline_tile_manager.dart:107-114` | deleteLocalTiles 混用同步 DB + 异步文件操作，中断后产生孤立文件 |
| H6 | `fence_conflict_page.dart:93-96` | 硬编码高德瓦片 URL，绕过 SmartTileProvider，离线时地图空白 |

### 中等问题（10 个）

| 编号 | 问题 |
|------|------|
| M1 | offline_tiles 只有 presentation 层，违反 domain/data/presentation 三层架构 |
| M2 | FenceSyncService.cacheFencesFromServer 硬编码 pageSize=100 |
| M3 | pushUnsyncedFences POST 成功后未更新 remoteId → 产生重复围栏 |
| M4 | TileAnalytics.flush() 的 map 语法有歧义，jsonDecode 异常导致整个 flush 中断 |
| M5 | OfflineTileManagementPage 不用 Riverpod Notifier + AsyncValue 模式 |
| M6 | insertTileMeta upsert 时覆盖 status，可能将 ready 覆盖为 downloading |
| M7 | getTileMetasSync/getStorageUsedSync 暴露同步 API，Web 平台崩溃 |
| M8 | SmartTileProvider._buildUrl 用 replaceFirst 不支持 {s} 子域名 |
| M9 | CachedFenceData.parseVertices 缺少错误处理，jsonDecode/type cast 异常 |
| M10 | TileSourceResolver 用 ApiClient，OfflineTileManager 用原始 http 包，风格不统一 |

### 低优先级问题（6 个）

L1: AppDatabase 五个表的 DDL/CRUD 集中在一个类 | L2: pin() 方法 pin 全部区域而非单个 | L3: FenceConflictPage 地图无 bounds padding | L4: OfflineEditBanner 无同步按钮 | L5: _buildUrl 用 replaceFirst 语义不如 replaceAll | L6: TileStatus 定义在 presentation 层

---

## Plan C — Offline Fences + Observability（22 个问题）

### 严重问题（4 个）

#### S1. FenceSyncService 未注册 Provider，同步流程是死代码
**文件**: `features/offline_fences/data/fence_sync_service.dart`
没有 Provider 注册，没有代码调用 `sync()`/`pushUnsyncedFences()`/`cacheFencesFromServer()`。离线编辑的围栏永远不会同步到服务端。
**修复**: 创建 `fence_sync_provider.dart`，注册 Provider，在 FenceController 或网络恢复回调中调用。

#### S2. 冲突检测机制不存在，FenceConflictPage 是死路由
**文件**: `fence_sync_service.dart:98-101`
PUT 请求返回 409 时静默跳过，无冲突捕获逻辑。无代码构造 `FenceConflict`，无导航到 `FenceConflictPage`。
**修复**: 处理 `statusCode == 409`，从响应提取服务端版本，构造 FenceConflict，导航到冲突页面。

#### S3. CachedFenceData.parseVertices 类型转换崩溃
**文件**: `features/offline_fences/domain/cached_fence.dart:36-37`
```dart
LatLng((e as Map)['lat'] as double, e['lng'] as double)
```
JSON 数值可能是 int（如 `28`），`as double` 抛 TypeError。
**修复**: 使用 `(e['lat'] as num).toDouble()`。

#### S4. AppDatabase 双实例风险——同步构造可能创建空库
**文件**: `core/database/app_database.dart:8-9,37-39`
如果代码在 `createAsync()` 之前访问 `instance`，会创建一个错误路径的空数据库。
**修复**: `instance` getter 中抛出 StateError 强制使用异步路径。

### 高优先级问题（6 个）

| 编号 | 文件 | 问题 |
|------|------|------|
| H1 | `fence_sync_service.dart:3,9` | 使用原始 http 包而非 ApiClient，JWT 过期后同步失败 |
| H2 | `fence_sync_service.dart:82-89` | POST 成功后未更新 remote_id，下次 pull 产生重复围栏 |
| H3 | `tile_analytics.dart:22-44` | flush 部分成功时标记全部已上报导致事件丢失；损坏 payload 导致 flush 死循环 |
| H4 | `offline_edit_banner.dart:10-14` | getUnsyncedFences() 全表扫描后内存过滤 farmId |
| H5 | `fence_conflict_page.dart:93-96` | 硬编码高德瓦片 URL，离线场景冲突页面完全不可用 |
| H6 | `cached_fence.dart` + `fence_sync_service.dart` | CachedFenceData 强类型模型从未使用，所有操作走 Map<String, dynamic> |

### 中等问题（8 个）

| 编号 | 问题 |
|------|------|
| M1 | cacheFencesFromServer 硬编码 pageSize=100，大牧场同步不完整 |
| M2 | FenceSyncService 没有 onConflict 回调机制 |
| M3 | TileAnalytics.log() 每次调用执行 INSERT + SELECT 两次 DB 操作 |
| M4 | analytics_events 表无清理机制，无限增长 |
| M5 | LivestockPositionCache 无 farmId 过滤，多牧场场景不适用 |
| M6 | FenceConflictPage 系统返回键未拦截，围栏卡在未同步中间态 |
| M7 | FenceConflictPage 两地图无视觉区分标签 |
| M8 | insertCachedFence 的 upsert-by-remoteId 非原子操作，有竞态窗口 |

### 低优先级问题（4 个）

L1: TileAnalytics Provider throw UnimplementedError 无文档 | L2: LivestockPositionCache 无错误处理日志 | L3: FenceConflictPage bounds 无 padding | L4: Plan C 零测试覆盖

---

## 跨 Plan 共性问题

以下问题在多个 Plan 中重复出现，属于系统性问题：

### 1. Map<String, Object> 代替 DTO（Plan A × 3 处）
TileAdminController、TileAppController、AnalyticsController 全部手动解析 Map 取值。无类型安全、无参数校验、NPE/ClassCastException 导致 500。

### 2. 硬编码在线瓦片 URL（Plan B + C）
FenceConflictPage 直接用高德 URL，绕过 SmartTileProvider。离线场景（正是 Plan C 要解决的）地图空白。

### 3. 数据库同步构造 vs 异步构造冲突（Plan B + C）
AppDatabase 的 `instance` getter 可能创建错误路径的空库，与 `createAsync()` 的真实库共存。

### 4. POST 成功不回写 remoteId（Plan B M3 + Plan C H2）
离线创建的围栏在同步后 remote_id 仍为 null，下次 pull 产生重复记录。

### 5. 缺少测试（Plan A M10/M11 + Plan B + Plan C L4）
三个 Plan 的核心业务逻辑（乐观锁、状态流转、同步冲突、下载重试）几乎没有测试覆盖。

---

## 优先修复路线图

### 第一优先级（阻断合并）
1. **Plan A S7** — TileAdminController 传参错误，端点返回无意义数据
2. **Plan A S8** — FarmTileTask 状态流转断裂，客户端永远拿不到 ready 状态
3. **Plan C S1** — FenceSyncService 未注册，离线同步完全不可用
4. **Plan C S2** — 冲突检测缺失，FenceConflictPage 是死路由
5. **Plan B S5** — LRU 淘汰缺失，离线瓦片无限增长

### 第二优先级（安全 + 数据正确性）
6. **Plan A S3+S9** — 路径遍历 + python3 注入
7. **Plan A S4+S5** — API Key 认证不一致
8. **Plan B S1** — AppDatabase 双实例风险
9. **Plan C S3** — parseVertices 崩溃
10. **Plan C H2** — remoteId 未回写

### 第三优先级（可靠性 + 用户体验）
11. **Plan B H1** — 大文件下载 OOM
12. **Plan B S2** — 下载无超时/取消
13. **Plan B+C H5** — 离线场景地图空白
14. **Plan B H3** — 管理页无操作能力
