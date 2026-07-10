# 离线地图 + 围栏同步系统 — 代码质量评审报告

> **评审日期**: 2026-05-28
> **评审范围**: Plan A (Backend + Tooling) + Plan B (Flutter Offline Tiles) + Plan C (Flutter Offline Fences + Observability)
> **评审方法**: 3 个专业 agent 并行评审（Java 后端、Flutter 前端、安全），合并去重
> **评审结论**: **阻塞合并** — 17 个严重、18 个高危、23 个中等问题

---

## 严重问题 (S) — 阻塞合并

### S-1. TileController 路径遍历漏洞 — 任意文件读取
- **文件**: `smart-livestock-server/.../ranch/interfaces/TileController.java:59-67`
- **问题**: `Paths.get(TILES_DIR, matchedFile)` 使用来自 `regions.json` 的文件名，无边界检查。攻击者可通过篡改 `regions.json` 读取服务器任意文件（如 `../../etc/passwd`）
- **影响**: 任意文件读取漏洞
- **修复**: 验证解析路径在 `TILES_DIR` 内：
  ```java
  Path resolved = Paths.get(TILES_DIR).resolve(matchedFile).normalize();
  if (!resolved.startsWith(Paths.get(TILES_DIR).normalize())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Invalid path");
  }
  ```

### S-2. TileController 吞掉所有异常，掩盖安全事件
- **文件**: `smart-livestock-server/.../ranch/interfaces/TileController.java:93`
- **问题**: `catch (Exception ignored) {}` 完全静默吞掉异常，包括文件篡改、JSON 注入等安全相关异常
- **影响**: 安全事件无法通过日志检测
- **修复**: `catch (Exception e) { log.warn("Failed to read regions file: {}", e.getMessage()); }`

### S-3. handleFarmTileDetection 缺少去重 — UNIQUE 约束冲突
- **文件**: `smart-livestock-server/.../ranch/application/TileAdminService.java:102-106`
- **问题**: 每次调用无条件创建 `FarmTileTask(farmId, regionId)`，第二次调用触发 `UNIQUE(farm_id, region_id)` 约束违规，返回 500
- **影响**: Farm 创建重试时服务端崩溃
- **修复**: 调用前检查 `findByFarmIdAndRegionId()` 已存在则跳过

### S-4. Open API `permitAll()` + API Key 无效时静默放行
- **文件**: `smart-livestock-server/.../shared/security/SecurityConfig.java:46-49`, `ApiKeyAuthFilter.java:46-48`
- **问题**: `/api/v1/open/**` 配置为 `permitAll()`，完全绕过 Spring Security 框架。`ApiKeyAuthFilter` 对无效 Key 静默放行而非返回 401
- **影响**: 如果手动检查遗漏，Open API 数据完全暴露
- **修复**: 改为 `.authenticated()`；无效 API Key 时返回 401

### S-5. validateFarmAccess / requireDeviceRegisterScope 是空存根
- **文件**: `smart-livestock-server/.../shared/security/ApiKeyAuthService.java:35-41`
- **问题**: 两个方法都是空实现。任何 API Key 可访问任何租户的围栏数据，可在任何租户下注册设备
- **影响**: 跨租户数据泄露（IDOR）
- **修复**: 实现 `validateFarmAccess` 验证 farm 属于 Key 的租户

### S-6. OpenDeviceRegisterController.resolveTenantId() 硬编码返回 1L
- **文件**: `smart-livestock-server/.../iot/interfaces/open/OpenDeviceRegisterController.java:103-111`
- **问题**: 所有 API Key 都硬编码映射到租户 1
- **影响**: 任何 API Key 可在租户 1 下注册无限设备
- **修复**: 使用 API Key 关联的 `tenantId`

### S-7. Admin 端点无权限检查
- **文件**: `TileAdminController.java`, `TileAppController.java`, `FenceController.java`
- **问题**: Admin 路径下无 `hasRole("PLATFORM_ADMIN")` 检查，任何认证用户（包括 worker）可执行管理员操作
- **影响**: 低权限用户可修改瓦片管理数据、通过 forceUpdate 绕过乐观锁
- **修复**: 添加 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`

### S-8. 围栏/瓦片端点无租户隔离（IDOR）
- **文件**: `FenceController.java:29-41`, `TileAppController.java:25-46`, `TileController.java:52-68`
- **问题**: 所有端点接受 `farmId` 但不验证 farm 是否属于当前认证用户的租户
- **影响**: 跨租户数据泄露（围栏坐标、MBTiles 文件）
- **修复**: 添加 `verifyFarmOwnership(farmId)` 检查

### S-9. AppDatabase INSERT OR REPLACE 无 UNIQUE 约束 — 数据重复
- **文件**: `Mobile/mobile_app/lib/core/database/app_database.dart:124,164,202`
- **问题**: `cached_fences`、`tile_metas`、`cached_livestock_positions` 使用 `INSERT OR REPLACE` 但缺少 `UNIQUE` 约束（`remote_id`/`region_name`/`livestock_id`），每次 upsert 都插入新行
- **影响**: 同步产生重复行，LRU 删除可能删错行，版本比较永远只看最旧记录
- **修复**: 添加 `UNIQUE(remote_id)`、`UNIQUE(region_name)`、`UNIQUE(livestock_id)` 约束，使用 `ON CONFLICT DO UPDATE`

### S-10. AppDatabase 数据库路径硬编码 macOS，Android/iOS 不可用
- **文件**: `Mobile/mobile_app/lib/core/database/app_database.dart:89-93`
- **问题**: `_getApplicationSupportDirectorySync()` 硬编码 `~/Library/Application Support`，Android 上完全无效
- **影响**: Android 端数据库创建失败导致 crash
- **修复**: 改为异步工厂模式，使用 `await getApplicationSupportDirectory()`

### S-11. AppDatabase 无 schema 版本追踪和迁移机制
- **文件**: `Mobile/mobile_app/lib/core/database/app_database.dart:21-80`
- **问题**: 使用 `CREATE TABLE IF NOT EXISTS` 无版本号，schema 变更时旧表不会更新
- **影响**: 已有用户设备上升级后运行时错误
- **修复**: 添加 `PRAGMA user_version` 检查和迁移逻辑

### S-12. deleteLocalTiles 只删文件不删 DB 记录
- **文件**: `Mobile/mobile_app/lib/features/offline_tiles/presentation/offline_tile_manager.dart:107-113`
- **问题**: 删除文件后 `tile_metas` 表记录仍在，`getStorageUsed()` 永远偏大
- **影响**: 存储统计错误，下载时认为已存在而跳过
- **修复**: 删除文件后同时删除 DB 记录

### S-13. AnalyticsController 无请求体大小限制和输入验证
- **文件**: `smart-livestock-server/.../ranch/interfaces/AnalyticsController.java:22-24`
- **问题**: `@RequestBody List<Map<String, Object>> events` 接受任意大小的 JSON 数组，无大小限制、无事件类型白名单、无字段验证。`log.info` 以 INFO 级别记录客户端提交的任意事件数据。> ⚠️ **勘误**: 原评审称"无认证"不准确。`/api/v1/analytics/**` 不在 `permitAll()` 列表中，受 `SecurityConfig` 的 `.anyRequest().authenticated()` 保护，需 JWT 或 API Key。安全问题限于输入验证缺失和日志级别不当。
- **影响**: 恶意客户端可提交超大请求体（OOM 风险）、日志中 PII 泄露、无速率限制可填满日志
- **修复**: 添加 `@Size(max=100)` 或手动校验事件列表大小；改为 DEBUG 级别；验证事件类型白名单

### S-14. TileAdminController/TileAppController 接受原始 Map 输入，无 @Valid
- **文件**: `TileAdminController.java:28,57,74`, `TileAppController.java:37`
- **问题**: `@RequestBody Map<String, Object>` 无空值检查，`((Number) body.get("minLon")).doubleValue()` 缺键时 NPE
- **影响**: 运行时 500 错误而非 400，无范围检查
- **修复**: 创建请求 DTO + `@Valid @RequestBody`

### S-15. FenceJpaEntity 使用手动版本控制而非 JPA @Version — 并发窗口风险
- **文件**: `smart-livestock-server/.../ranch/infrastructure/persistence/entity/FenceJpaEntity.java`, `FenceApplicationService.java`
- **问题**: `version` 字段无 JPA `@Version` 注解。`FenceApplicationService.updateFence()` 手动比较 `expectedVersion` 并递增 `setVersion(getVersion()+1)`。在单线程场景下版本检查有效（应用层乐观锁），但读-比-写之间存在竞态窗口：两个并发请求可能同时读到 version=1，都通过校验后后写覆盖前写。
- **影响**: 并发围栏编辑时存在静默数据覆盖风险（非并发场景下正常工作）
- **修复**: 添加 JPA `@Version` 注解让数据库层保证原子性，捕获 `OptimisticLockException` 映射为 409；保留 `expectedVersion` 前置校验作为业务层快速失败

### S-16. import_mbtiles.sh Shell 注入风险
- **文件**: `tooling/import_mbtiles.sh:78,86`
- **问题**: `$base` 来自文件名，在 curl JSON 体中未转义，可注入任意 HTTP 数据或执行命令
- **影响**: 特制文件名可执行任意命令
- **修复**: 使用 `jq` 构建 JSON 或验证文件名只含安全字符

### S-17. ApiKeyAuthFilter 未设置 TenantContext — 下游租户隔离失效
- **文件**: `smart-livestock-server/.../shared/security/ApiKeyAuthFilter.java:39-51`
- **问题**: Filter 验证 API Key 后仅设置 `SecurityContextHolder`（含 principal=apiKeyId + role），但**完全未设置 `TenantContext`**。Filter 内部不存在任何 `TenantContext` 调用。下游依赖 TenantContext 的代码（如租户数据过滤）在 API Key 请求路径上失效。
> ⚠️ **勘误**: 原评审描述"使用了错误的 TenantContext API"不准确。实际情况是 Filter **从未调用** TenantContext，而非调用了错误的 API。
- **影响**: API Key 请求时租户隔离失效，跨租户数据泄露
- **修复**: 在设置 SecurityContext 后，从 `ApiKey` 对象获取 tenantId 并调用 `TenantContext.setCurrentTenant()`

---

## 高危问题 (H)

### H-1. getFarmTileStatus N+1 查询
- **文件**: `TileAdminService.java:117-132`
- **问题**: 每个 FarmTileTask 单独查一次 TileRegion
- **修复**: 批量获取或 JOIN FETCH

### H-2. advanceFarmTileTasks 全表扫描
- **文件**: `TileAdminService.java:170`
- **问题**: `findAll().stream().filter(...)` 加载全表到内存
- **修复**: 添加 `findByRegionIdAndStatus()` 下推过滤

### H-3. TileAdminController.listFarmTasks 指数级查询放大
- **文件**: `TileAdminController.java:85-91`
- **问题**: 遍历所有 region 调 `getFarmTileStatus(regionId)`（本身有 N+1），总查询 = regions × tasks
- **修复**: 创建专用查询一次性获取

### H-4. handleFarmTileDetection 不通知客户端已创建生成任务
- **文件**: `TileAdminService.java:89-99`
- **问题**: 低覆盖率时创建了 TileGenerationTask 但返回空 region 列表
- **修复**: 在 FarmTileStatusDto 中包含生成任务状态

### H-5. 跨限界上下文依赖 Identity → Ranch
- **文件**: `FarmApplicationService.java:10-15`
- **问题**: Identity 直接依赖 Ranch 的 TileAdminService，违反 DDD 限界上下文独立性
- **修复**: 定义端口接口 `TileDetectionPort` 或使用领域事件

### H-6. TileAdminService 缺少 @Transactional(readOnly=true)
- **文件**: `TileAdminService.java:34,38,45,117,134`
- **问题**: 5 个只读方法无 readOnly 标记，浪费连接池资源
- **修复**: 添加 `@Transactional(readOnly = true)`

### H-7. TileAppController.logDownload 信任客户端 userId
- **文件**: `TileAppController.java:38-39`
- **问题**: `userId` 和 `bytesDownloaded` 从请求体获取，客户端可伪造
- **修复**: 从 JWT SecurityContext 提取 userId

### H-8. FarmApplicationService.createFarm 瓦片检测失败会回滚 Farm 创建
- **文件**: `FarmApplicationService.java:36-53`
- **问题**: `@Transactional` 内调用瓦片检测，检测失败导致 Farm 创建也回滚
- **修复**: 分离为异步事件或 `REQUIRES_NEW` 传播

### H-9. TileSourceResolver 硬编码 baseUrl + 无认证 headers
- **文件**: `Mobile/mobile_app/lib/core/map/tile_source_resolver.dart:39-40`
- **问题**: baseUrl 硬编码 `http://127.0.0.1:18080`，headers 为空 Map，API 调用永远 401
- **修复**: 从 ApiClient 获取 baseUrl 和 token

### H-10. OfflineTileManager 所有 region 使用相同下载 URL
- **文件**: `Mobile/mobile_app/lib/features/offline_tiles/presentation/offline_tile_manager.dart:69`
- **问题**: 循环中每个 region 都用 `$_apiBaseUrl/farms/$farmId/offline-map`，不区分 regionName
- **影响**: 所有 region 下载相同文件
- **修复**: URL 应包含 regionName 参数

### H-11. pin/unpin 方法为空实现
- **文件**: `Mobile/mobile_app/lib/features/offline_tiles/presentation/offline_tile_manager.dart:119-125`
- **问题**: `pin()` 和 `unpin()` 方法体为空，LRU 淘汰可能删除正在使用的瓦片
- **修复**: 实现 pin/unpin 操作 farm_tile_pins 表

### H-12. 下载全量加载到内存，无流式写入
- **文件**: `Mobile/mobile_app/lib/features/offline_tiles/presentation/offline_tile_manager.dart:70-76`
- **问题**: `http.get()` 将整个 MBTiles 加载到 `response.bodyBytes`，大文件可能 OOM
- **修复**: 使用 `http.Client()` 流式写入

### H-13. FenceApiRepository 不读取 version/fenceType
- **文件**: `Mobile/mobile_app/lib/features/fence/data/fence_api_repository.dart:46-85`
- **问题**: `_fenceItemFromMap` 不解析 `version` 和 `fenceType`，永远用默认值 1/'sub'
- **影响**: 乐观锁完全失效，FenceSyncService 推送时 expectedVersion 永远是 1
- **修复**: 添加 `version: raw['version'] as int? ?? 1, fenceType: raw['fenceType'] as String? ?? 'sub'`

### H-14. FenceSyncService 不处理 409 冲突
- **文件**: `Mobile/mobile_app/lib/features/offline_fences/data/fence_sync_service.dart:93-100`
- **问题**: PUT 发送 expectedVersion 但 409 时静默忽略，围栏永远卡在 synced=0
- **修复**: 检测 409，获取服务端版本，构造 FenceConflict 触发解决流程

### H-15. FenceSyncService push 的 catch 块完全静默
- **文件**: `Mobile/mobile_app/lib/features/offline_fences/data/fence_sync_service.dart:102-104`
- **问题**: `catch (_) { /* Skip */ }` 吞掉所有异常包括认证失败
- **修复**: 至少 `debugPrint` 记录失败原因

### H-16. 所有新 Flutter 模块未集成到应用中 — 死代码
- **文件**: 多个文件
- **问题**: `OfflineTileManagementPage`、`FenceConflictPage`、`OfflineEditBanner`、`TileAnalytics`、`FenceSyncService` 均无路由注册和 Provider 覆盖
- **影响**: 所有新功能用户不可访问
- **修复**: 添加路由、覆盖 Providers、在相应页面中引用

### H-17. SmartTileProvider 健康检查使用 z=0/0/0 瓦片可能不存在
- **文件**: `Mobile/mobile_app/lib/core/map/smart_tile_provider.dart:59`
- **问题**: 请求 zoom=0 瓦片判断 tileserver 可用性，MBTiles 可能不含 zoom=0
- **影响**: 健康检查假阴性，始终使用降级源
- **修复**: 使用 tileserver 健康端点或已知存在的瓦片

### H-18. Nginx 无 TLS + 无安全头
- **文件**: `smart-livestock-server/infrastructure/nginx/nginx.conf`
- **问题**: 端口 80 HTTP 无 TLS，API Key 通过明文传输；无 HSTS/X-Frame-Options/X-Content-Type-Options
- **影响**: 网络嗅探可截获 API Key
- **修复**: 添加 TLS 终止和安全头

---

## 中等问题 (M)

| # | 文件 | 问题 |
|---|------|------|
| M-1 | 所有 domain model | 状态使用原始字符串而非枚举，无编译时安全 |
| M-2 | TileCoverageCalculator.java:22-38 | shoelace 公式用于地理坐标是近似值，高纬度不准确 |
| M-3 | TileController.java:23-24 | 硬编码 `/data/mbtiles` 路径无配置机制 |
| M-4 | TileRegionMapper.java:23 | `toDomain()` 用无参构造再逐字段覆盖，语义不够清晰 |
| M-5 | TileAdminService.java:31 | `@Value` 注解内嵌内部 IP 作默认值 |
| M-6 | ApiKeyAuthFilter.java:60 | API Key 检测耦合 `sk_live_` 前缀格式 |
| M-7 | ApiKeyAuthFilter + ApiKeyAuthService | 两处独立实现 API Key 提取逻辑，行为不一致 |
| M-8 | JWT + API Key 双重 Bearer 歧义 | JWT 过滤器对 `sk_live_` token 产生噪音日志 |
| M-9 | generate_mbtiles.py:363 | 默认 API URL 用 HTTP 硬编码 IP |
| M-10 | generate_mbtiles.py:156 | 固定速率无抖动 |
| M-11 | import_mbtiles.sh:18 | `$meta` 路径在 python3 命令中未转义 |
| M-12 | app_database.dart | 单例模式在测试中无法隔离，无注入内存数据库机制 |
| M-13 | offline_tile_manager.dart:128-130 | Provider 抛 UnimplementedError 无编译时检查 |
| M-14 | offline_tile_management_page.dart:45-53 | 管理页只显示总存储，不显示区域列表 |
| M-15 | tile_analytics.dart:41 | flush 失败静默忽略，未上报事件无限累积 |
| M-16 | tile_analytics.dart:14-15 | log() 同步写数据库可能阻塞 UI |
| M-17 | fence_sync_service.dart:13 | pageSize=100 硬编码，大牧场围栏不全 |
| M-18 | fence_conflict_page.dart:30-83 | 双地图在手机竖屏上不可用（每侧仅 ~180dp） |
| M-19 | fence_conflict_page.dart | 两个 FlutterMap 无 TileLayer，离线时纯白背景 |
| M-20 | offline_edit_banner.dart:6-10 | 直接依赖 AppDatabase.instance 绕过 DI |
| M-21 | fence_controller.dart | Plan 声明有"离线写入逻辑"但实际未实现，编辑后 app 重启丢失 |
| M-22 | livestock_position_cache.dart:12-13 | 类型转换无 null safety，格式不匹配时 crash |
| M-23 | CORS 配置 | 允许 `http://172.22.1.123:*` + 凭据，生产环境过于宽松 |

---

## 测试覆盖状况

### 后端（Plan A）
- ✅ 有测试: TileRegionTest, TileCoverageCalculatorTest, TileAdminServiceTest, ApiKeyApplicationServiceTest, FenceVersionTest
- ❌ 缺失: TileAdminController/TileAppController/TileController/AnalyticsController/ApiKeyAuthFilter/SecurityConfig 测试

### Flutter（Plan B + C）
- ❌ 所有 15 个新文件零测试覆盖
- 关键待测: AppDatabase schema + CRUD, FenceSyncService push-then-pull, OfflineTileManager 下载+LRU, TileAnalytics 批量上报

---

## 文件评审状态总览

### Plan A — Backend + Tooling

| 文件 | 状态 | 关键问题 |
|------|------|---------|
| V13 迁移 SQL | ✅ | — |
| TileRegion/TileGenerationTask/FarmTileTask/TileDownloadLog | ✅ | M-1 字符串状态 |
| 4× Repository 接口 | ✅ | — |
| 4× JPA 适配器 (16 files) | ✅ | — |
| TileCoverageCalculator | ⚠️ | M-2 shoelace 近似 |
| TileAdminService | 🔴 | S-3, H-1/H-2/H-4/H-6 |
| TileAdminController | 🔴 | S-7, S-14 |
| TileAppController | 🔴 | S-7, S-8, S-14, H-7 |
| TileController | 🔴 | S-1, S-2, S-8 |
| AnalyticsController | 🔴 | S-13 |
| FenceJpaEntity | 🔴 | S-15 |
| FenceApplicationService | 🔴 | S-15 |
| FenceController | 🔴 | S-7, S-8 |
| ApiKeyAuthFilter | 🔴 | S-4, S-17 |
| ApiKeyAuthService | 🔴 | S-5 |
| OpenDeviceRegisterController | 🔴 | S-6 |
| FarmApplicationService | 🔴 | S-8, H-5, H-8 |
| SecurityConfig | 🔴 | S-4 |
| generate_mbtiles.py | ⚠️ | M-9, M-10 |
| import_mbtiles.sh | 🔴 | S-16, M-11 |

### Plan B + C — Flutter

| 文件 | 状态 | 关键问题 |
|------|------|---------|
| app_database.dart | 🔴 | S-9, S-10, S-11, M-12 |
| tile_source_resolver.dart | 🔴 | H-9 |
| smart_tile_provider.dart | 🔴 | H-17 |
| offline_tile_manager.dart | 🔴 | S-12, H-10, H-11, H-12 |
| offline_tile_management_page.dart | 🔴 | H-16, M-14 |
| tile_analytics.dart | 🔴 | H-16, M-15, M-16 |
| cached_fence.dart | ⚠️ | — |
| fence_sync_service.dart | 🔴 | H-14, H-15, M-17 |
| fence_conflict_page.dart | 🔴 | H-16, M-18, M-19 |
| offline_edit_banner.dart | 🔴 | H-16, M-20 |
| fence_item.dart | ⚠️ | — |
| fence_api_repository.dart | 🔴 | H-13 |
| fence_controller.dart | ⚠️ | M-21 |
| fence_dto.dart | ⚠️ | — |
| livestock_position_cache.dart | ⚠️ | M-22 |

---

## 修复优先级建议

### P0 — 阻塞合并（必须立即修复）

| 问题 | 工作量 | 说明 |
|------|--------|------|
| S-1 路径遍历 | 0.5h | TileController 路径验证 |
| S-2 异常吞掉 | 0.5h | 添加 log.warn |
| S-3 FarmTileTask 去重 | 1h | findByFarmIdAndRegionId 检查 |
| S-4+S-17 Open API 安全 | 2h | permitAll→authenticated + TenantContext |
| S-5 空存根实现 | 2h | validateFarmAccess 逻辑 |
| S-6 硬编码 tenantId | 0.5h | 从 API Key 获取 |
| S-7 Admin 权限 | 1h | @PreAuthorize |
| S-8 租户隔离 | 3h | verifyFarmOwnership |
| S-9 UNIQUE 约束 | 2h | AppDatabase schema 修复 |
| S-10 数据库路径 | 2h | 异步工厂模式 |
| S-11 Schema 迁移 | 1h | PRAGMA user_version |
| S-12 删除 DB 记录 | 0.5h | deleteLocalTiles 补全 |
| S-15 @Version | 1h | FenceJpaEntity + 异常处理 |

### P1 — 下一个迭代（功能正确性）

| 问题 | 工作量 | 说明 |
|------|--------|------|
| H-1~H-3 查询优化 | 3h | N+1 + 全表扫描 + 指数放大 |
| H-5 跨 BC 依赖 | 2h | 端口接口或领域事件 |
| H-9 TileSourceResolver | 1h | ApiClient 集成 |
| H-10 下载 URL | 1h | regionName 参数 |
| H-11 Pin/Unpin | 2h | 实现 farm_tile_pins 操作 |
| H-13 version 解析 | 1h | _fenceItemFromMap 补全 |
| H-14 409 处理 | 2h | FenceSyncService 冲突检测 |
| H-16 模块集成 | 4h | 路由 + Provider 覆盖 |

### P2 — 后续迭代（代码质量）

| 问题 | 工作量 | 说明 |
|------|--------|------|
| S-16 Shell 注入 | 1h | jq 构建 JSON |
| H-8 事务分离 | 1h | 异步事件或 REQUIRES_NEW |
| H-12 流式下载 | 2h | http.Client 流式写入 |
| H-17 健康检查 | 1h | 改用 health 端点 |
| H-18 TLS | 2h | nginx SSL + 安全头 |
| M-1~M-23 | — | 枚举、测试、代码清理 |

---

## 规格覆盖缺口 — 评审遗漏项

> 以下问题在规格文档中有明确要求，但评审报告未提及。

| 缺口 | 规格章节 | 当前状态 | 说明 |
|------|---------|---------|------|
| LRU 淘汰 + 存储上限未实现 | §7 OfflineTileManager | `OfflineTileManager` 无 LRU 逻辑，无 500MB 上限管理 | 规格要求"LRU 淘汰 + pin 保护 + storage cap 500MB"，H-11 仅提到 pin 为空实现，未指出整个 LRU 机制缺失 |
| 离线分析事件补报缺失 | §9.2 上报机制 | `TileAnalytics.flush()` 仅在线时批量 POST | 规格明确要求"离线时写入本地 drift 表，上线后补报"，当前离线时事件已写入 `analytics_events` 表但无自动补报触发逻辑 |
| fence_edit_log 审计表缺失 | §5.2 围栏版本控制 | V13 迁移无此表 | 规格提到围栏编辑审计日志，用于追踪谁在何时修改了围栏。当前 V13 迁移仅添加 `version` 和 `fence_type` 列，无审计表 |
| 围栏同步链路未打通 | §8.3 围栏冲突解决 | `FenceSyncService` 存在但未被任何代码调用 | H-16 提到模块未集成，但未明确指出完整的"先推后拉 → 409 冲突 → 双栏对比 UI → 用户选择 → 写回"链路完全未连通 |

---

## 勘误汇总

| 条目 | 原始描述 | 修正内容 |
|------|---------|---------|
| S-13 | 隐含"无认证" | `/api/v1/analytics/**` 受 `.anyRequest().authenticated()` 保护，需 JWT 或 API Key。安全问题限于输入验证缺失和日志级别不当 |
| S-15 | "乐观锁名存实亡" | 手动版本控制在非并发场景有效（应用层乐观锁），改为标注"并发窗口风险"。影响描述从"静默数据覆盖"修正为"并发围栏编辑时存在静默数据覆盖风险" |
| S-17 | "使用了错误的 TenantContext API" | Filter **从未调用** TenantContext，而非调用了错误的 API。问题描述修正为"完全未设置 TenantContext" |

---

*报告由 3 个专业 agent（Java 后端评审、Flutter 前端评审、安全评审）并行生成，人工合并去重。*
*勘误基于 2026-05-28 源码逐行核实，修正了 3 处描述不准确的问题并补充了 4 项规格覆盖缺口。*
