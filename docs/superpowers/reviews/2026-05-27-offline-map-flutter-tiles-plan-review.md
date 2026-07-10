# Flutter 离线瓦片实施计划 — 评审报告

> **评审对象**: [2026-05-27-offline-map-flutter-tiles-plan.md](../plans/2026-05-27-offline-map-flutter-tiles-plan.md)
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **评审日期**: 2026-05-28

---

## 总结

计划聚焦规格文档 §7（Flutter 客户端离线瓦片），10 个 Task 拆分清晰，依赖顺序合理，Self-Review 覆盖率矩阵有助于验收。但存在 **3 个 P0 问题**（SmartTileProvider 多 MBTiles 架构与现有单例模型不兼容、OfflineTileManager 方法签名与规格不一致、API Key 管理 UI 与已有 `api_authorization` 模块重复）和 **7 个 P1 问题**（drift 依赖缺失 path、TileMeta 表结构与规格 meta.json 引用计数设计不匹配、File Structure 缺少 domain model 文件、网络策略未覆盖、断点续传细节不足、TileSourceResolver 未处理离线场景、引用计数/多牧场共享逻辑缺失），需要在执行前修正。

**结论**: 修正 P0 + P1 后可开始执行。

---

## P0 — 必须修正

### 1. SmartTileProvider 多 MBTiles 架构与现有单例模型不兼容

**规格要求**（§7.1）: "SmartTileProvider 加载多个 MBTiles 文件，按瓦片坐标在哪个文件有数据就取哪个。无瓦片的区域降级到高德/OSM。" 跨区域牧场返回多个 source。

**现有代码**（`core/map/smart_tile_provider.dart`）: `SmartTileProvider` 持有单个 `MBTilesTileProvider? mbtilesProvider`，不支持多实例。构造函数接受单一 `selfHostedTileUrl`。

**计划方案**（Task 2）: `TileSourceResolver` 调用 `GET /farms/{id}/tile-source` 后"更新 SmartTileProvider"。Task 5 在 farm switch 时调用 `SmartTileProvider.updateSources()`。

**问题**:
- 计划未描述如何将单一 `MBTilesTileProvider` 扩展为多实例列表。现有 `_activeSource` 枚举（`selfHosted/mbtiles/fallback`）不支持"多个 mbtiles + 多个 online source"的组合
- `getImage()` 方法中的查找逻辑需要从"单个 mbtilesProvider.hasTile()"变为"遍历多个 MBTiles 实例逐一查找，全部未命中则降级"
- 缺少 `updateSources()` 方法的具体签名和实现思路
- 现有 `SmartTileProvider` 继承 `TileProvider`（不可变语义），在 `flutter_map` 中通过 `TileLayer` 绑定。运行时切换 source 需要触发 `TileLayer` 重建，否则已缓存的瓦片不会更新

**建议**:
- 在 Task 2 中明确 SmartTileProvider 改造方案：将 `MBTilesTileProvider?` 改为 `List<MBTilesTileProvider>` + `List<String> selfHostedUrls`，`getImage()` 改为多源遍历
- 说明 `updateSources()` 触发 `TileLayer` 重建的机制（通过 Riverpod state change → widget rebuild）
- 增加一个 Task 0 或在 Task 2 中包含 SmartTileProvider 重构的代码示例和测试

### 2. OfflineTileManager 方法签名与规格不一致

**规格**（§7.2）明确定义了 `OfflineTileManager` 的公开方法：

```dart
Future<TileStatus> getTileStatus(int farmId);
Future<void> startForegroundDownload(int farmId, {onProgress, onComplete, onError});
Future<void> enqueueBackgroundDownload(int farmId);
void cancelDownload(int farmId);
Future<void> deleteLocalTiles(String regionName);
Future<List<LocalTileInfo>> getLocalTiles();
Future<int> getStorageUsed();
Future<void> evictIfNeeded({int maxBytes = 1024 * 1024 * 1024});
Future<void> pin(int farmId);
Future<void> unpin(int farmId);
Future<bool> isPinned(int farmId);
```

**计划**（Task 4 Step 1）的方法列表：

| 计划方法 | 规格方法 | 差异 |
|----------|----------|------|
| `downloadTile(farmId, regionName)` | `startForegroundDownload(int farmId, {onProgress, onComplete, onError})` | 签名完全不同：规格用回调参数 + farmId 驱动，计划用 farmId + regionName |
| `resumeDownload(regionName)` | 无对应 | 规格未单独暴露 resume，断点续传应在 startForegroundDownload 内部处理 |
| `cancelDownload(regionName)` | `cancelDownload(int farmId)` | 参数类型不同（regionName vs farmId） |
| `deleteLocalTiles(regionName)` | `deleteLocalTiles(String regionName)` | 一致 ✓ |
| `getStorageUsed()` | `getStorageUsed()` | 一致 ✓ |
| `evictIfNeeded({maxBytes})` | `evictIfNeeded({int maxBytes = 1024 * 1024 * 1024})` | 缺少默认值 |
| `pin(farmId)` / `unpin(farmId)` / `isPinned(farmId)` | 一致 ✓ | — |
| 缺少 | `getTileStatus(int farmId)` | 计划遗漏了核心查询方法 |
| 缺少 | `getLocalTiles()` | 计划遗漏了列表查询方法 |
| 缺少 | `enqueueBackgroundDownload(int farmId)` | 推迟到 Task 7 但 Task 4 接口定义应包含 |

**建议**: Task 4 的接口定义必须与规格 §7.2 完全对齐，将 `downloadTile` + `resumeDownload` 合并为 `startForegroundDownload`（内部处理断点续传逻辑），补齐遗漏的 3 个方法。

### 3. API Key 管理 UI 与已有模块重复

**现状**: 代码库中已存在完整的 `api_authorization` 模块：

```
features/api_authorization/
├── domain/api_authorization_repository.dart
├── data/api_authorization_api_repository.dart
└── presentation/api_authorization_controller.dart

features/admin/presentation/api_auth_page.dart
features/mine/presentation/api_auth_page.dart
```

路由中已注册 `platformApiAuth`（`/admin/api-auth`）和 `mineApiAuth`（`/mine/api-auth`）。

`ApiAuthorizationApiRepository` 已实现 `loadApiKeys()`、`createApiKey()`、`updateApiKeyStatus()`、`revokeApiKey()` 四个方法，调用后端 `/admin/api-keys` 端点。

**计划**（Task 8）: 创建全新的 `LiveApiKeyRepository` + `ApiKeyManagementPage`，调用 `GET/POST/PUT/DELETE /admin/api-keys`。

**问题**:
- Task 8 完全重复了已有功能，浪费工时
- 新建的 `LiveApiKeyRepository` 与现有 `ApiAuthorizationApiRepository` 职责完全重叠
- 新增路由 `/ops/admin/api-keys` 与已有 `/admin/api-auth` 混淆

**建议**:
- 如果规格 §4.2 要求的功能（创建时仅显示一次明文 key + 复制按钮、吊销/删除分离）现有页面未实现，应在 Task 8 中说明**增量改进**现有页面，而非从零创建
- 明确 Task 8 的具体增量：补充"吊销 → 删除"的两步操作、创建后一次性 key 展示等
- 删除 File Structure 中的 `features/admin/presentation/api_key_management_page.dart` 和 `features/api_authorization/data/live_api_key_repository.dart`
- 路由应使用已有的 `platformApiAuth` / `mineApiAuth`，而非新建

---

## P1 — 建议修正

### 4. drift 依赖声明缺少 `sqlite3_flutter_libs` 和 `path`

**规格**（§7.5）明确列出依赖：
```yaml
dependencies:
  drift: ^2.18
  sqlite3_flutter_libs: ^0.5.42  # 已有
  workmanager: ^0.5.2
  wakelock_plus: ^1.2
dev_dependencies:
  drift_dev: ^2.18
  build_runner: ^2.4
```

**计划**（Task 1 Step 1）:
```yaml
dependencies:
  drift: ^2.18
  path_provider: ^2.1.0
  path: ^1.9.0
  workmanager: ^0.5.2
  wakelock_plus: ^1.2
  crypto: ^3.0.3
```

**问题**:
- `sqlite3_flutter_libs` 已在 pubspec.yaml 中（版本 ^0.5.28），计划未提及版本对齐（规格要求 ^0.5.42）
- `crypto` 包计划新增了但规格未要求，需说明用途（推测是 MD5 校验，规格 §7.2 提到 MD5 但可用 `dart:crypto` 或直接用 `sqlite3` 的 md5 函数）
- 缺少规格要求的 `sqlite3_flutter_libs` 版本升级说明

**建议**: 在 Task 1 Step 1 注明升级 `sqlite3_flutter_libs` 从 `^0.5.28` 到 `^0.5.42`，说明 `crypto` 包用于 MD5 校验。

### 5. TileMeta 表结构与规格 meta.json 引用计数设计不匹配

**规格**（§7.2）: meta.json 记录引用该区域的 `farmId` 列表 + `pinned` 状态。

> "引用计数：meta.json 记录引用该区域的 farmId 列表 + pinned 状态，删除牧场时仅在该区域无其他牧场引用时才删除瓦片文件。"

**计划**（Task 1 Step 2）: `TileMetas` 表用 `TextColumn farmIds` 存储 farm ID 列表，`IntColumn pinned` 存储 0/1。

**问题**:
- `farmIds` 为 text 字段存储逗号分隔的 ID 列表，不利于查询和更新。当 pin/unpin 按 farmId 操作时，需要解析文本 → 修改 → 重写，存在并发风险
- `pinned` 是全局 0/1，但规格要求的是"per-farm pinned"——同一区域可能被多个牧场引用，其中某些 pinned 某些 unpinned。当前设计中 `pinned=1` 无法区分是哪个牧场 pin 的
- `evictIfNeeded` 的淘汰逻辑需要检查"该区域是否有任何 pinned 牧场引用"，当前的扁平结构无法高效实现此查询

**建议**:
- 方案 A（推荐）：将 `farmIds` 拆分为关联表 `tile_region_farm_refs(region_name, farm_id, pinned, last_accessed_at)`，支持精确的 per-farm pin/unpin 查询
- 方案 B：在计划中明确说明 `pinned` 字段的语义是"是否有任何牧场 pin 了此区域"（derived field），并在 OfflineTileManager 的 pin/unpin 方法中维护此聚合值
- 无论哪种方案，都需补充"删除牧场时清理引用计数"的逻辑描述

### 6. File Structure 缺少 domain model 文件

**规格**（§7.2）引用了 `TileStatus`、`LocalTileInfo` 等领域模型。

**计划**: File Structure 列出了 `domain/tile_meta.dart` 和 `domain/offline_tile_repository.dart`，但：
- `tile_meta.dart` 仅对应 drift 生成的数据类，不是完整的领域模型
- 缺少 `TileStatus` 模型（`getTileStatus` 的返回类型）
- 缺少 `LocalTileInfo` 模型（`getLocalTiles` 的返回类型）
- `OfflineTileRepository` 接口缺少方法签名

**建议**: 在 File Structure 的 `domain/` 目录下增加 `tile_status.dart` 和 `local_tile_info.dart`，或在 `tile_meta.dart` 中一并定义。补充 `OfflineTileRepository` 的方法签名。

### 7. 网络策略（WiFi/移动网络）未覆盖

**规格**（§7.2 网络策略）:
- WiFi：自动执行前台下载
- 移动网络：底部横幅提示确认后再下载

**计划**: Task 3（TileDownloader）和 Task 5（OfflineTileController）均未提及网络类型检测和移动网络确认弹窗。

**建议**: 在 Task 5（OfflineTileController）中增加步骤：
1. 在 `startDownload` 前检测当前网络类型
2. 移动网络时弹出确认底部横幅（BottomSheet 或 SnackBar）
3. 可选：增加"仅 WiFi 下载"设置项

### 8. 断点续传实现细节不足

**规格**（§7.2）: "使用 http 包 + Isolate 分段下载，配合 HTTP Range 头断点续传。"

**计划**（Task 3）: `TileDownloader` 提到了 HTTP Range 和临时文件，但缺少：
- 如何记录已下载的字节偏移（本地存储位置）
- 下载中断后恢复时如何确定起始 offset
- 服务端是否支持 Range 请求（需要后端配合说明）
- Isolate 下载的具体架构（compute isolate 还是自定义 ReceivePort）

**建议**: 在 Task 3 中补充断点续传的状态管理方案（例如在 drift 表或临时 `.download.meta` 文件中记录已下载字节数），或标注为"第一版仅支持完整下载，断点续传作为后续优化"以降低首版复杂度。

### 9. TileSourceResolver 未处理离线场景

**规格**（§7.1）: "切换牧场时调用 `GET /farms/{id}/tile-source`"。

**计划**（Task 2）: `TileSourceResolver` 直接调用 API。

**问题**: 离线时 API 不可达，切换牧场后无法获取 tile-source 列表。但本地已下载的 MBTiles 文件仍然可用。

**建议**: `TileSourceResolver` 应实现本地优先策略：
1. 检查本地 drift 缓存是否已有该 farm 的 tile-source 信息
2. 有缓存 → 使用缓存 + 标记为 stale
3. 无缓存 → 尝试在线请求
4. 在线请求失败 → 回退到已下载的 MBTiles 文件列表
5. 将在线获取的 tile-source 信息缓存到本地

在 Task 2 的代码示例中补充此逻辑。

### 10. 缺少引用计数/多牧场共享逻辑

**规格**（§7.2）: "本地存储（按区域名，多牧场共享同一区域的瓦片）" + "删除牧场时仅在该区域无其他牧场引用时才删除瓦片文件。"

**计划**（Task 4）: `deleteLocalTiles(regionName)` 直接删除文件 + meta，无引用检查。

**问题**:
- 如果牧场 A 和牧场 B 都引用"changsha"区域，删除牧场 A 的瓦片会影响牧场 B
- `OfflineTileManager` 缺少 `onFarmDeleted(farmId)` 方法来安全地清理引用

**建议**:
- 增加 `removeFarmReference(farmId)` 方法：从 `farmIds` 列表中移除 farmId，仅当列表为空时删除瓦片文件
- 在 Task 4 的方法列表中补充此方法
- 与 P1-5 的引用计数改进一并考虑

---

## P2 — 改进建议

### 11. Drift 代码生成步骤应在依赖安装后立即执行

Task 1 Step 2 创建了 `local_tile_meta_store.dart`（含 `part` 指令和 `@DriftDatabase` 注解），Step 3 编写测试。但 `build_runner` 生成 `.g.dart` 文件的命令放在 Step 2 末尾。

如果生成失败（版本不兼容、语法错误），测试步骤会直接报错。建议在 Step 2 后增加验证步骤：确认 `.g.dart` 生成成功且无编译错误。

### 12. workmanager 后台任务的平台限制说明

Task 7 使用 `workmanager` 处理后台下载，但未说明 iOS 平台的严格限制：
- `BGAppRefreshTask` 由系统决定执行时机，不保证及时执行
- iOS 后台执行时间约 30 秒，MBTiles 文件通常较大（数十到数百 MB），30 秒内难以完成
- 建议在 Task 7 中注明 iOS 后台下载为 best-effort，实际依赖用户保持前台

### 13. 版本冲突处理的测试覆盖

规格 §8.3 定义了详细的版本冲突检测和双栏地图对比页面，但本计划不涉及围栏部分（属于围栏计划范围）。建议在 Self-Review 覆盖率矩阵中明确标注此部分不在本计划范围内，并注明依赖的围栏计划。

### 14. drift schema 版本迁移策略

`LocalTileMetaStore.schemaVersion = 1`，但未提及后续 schema 升级的迁移策略（如 `onUpgrade` 回调）。建议在代码中预留 `onUpgrade` 方法框架，或在 Task 1 注释中说明后续演进方向。

---

## 规格覆盖率矩阵

| 规格章节 | 计划 Task | 覆盖状态 | 备注 |
|----------|-----------|----------|------|
| §7.1 动态区域解析 | Task 2 | ⚠️ 部分 | 未处理离线场景、未描述 SmartTileProvider 多源改造 |
| §7.2 OfflineTileManager | Task 4 | ⚠️ 部分 | 方法签名与规格不一致，缺少引用计数 |
| §7.2 前台下载 + wakelock | Task 3 | ✅ 覆盖 | — |
| §7.2 后台下载 + workmanager | Task 7 | ✅ 覆盖 | iOS 限制未说明 |
| §7.2 MD5 校验 + 原子写入 | Task 3 | ✅ 覆盖 | — |
| §7.2 Pin/Unpin + LRU | Task 4 | ⚠️ 部分 | pin 语义需对齐 per-farm |
| §7.2 网络策略（WiFi/移动网络） | 无 | ❌ 缺失 | — |
| §7.2 断点续传 | Task 3 | ⚠️ 部分 | 实现细节不足 |
| §7.2 引用计数/多牧场共享 | Task 4 | ❌ 缺失 | deleteLocalTiles 无引用检查 |
| §7.3 管理页面 | Task 6 | ✅ 覆盖 | — |
| §7.4 更新检测 | Task 9 | ✅ 覆盖 | — |
| §7.5 drift + sqlite3 | Task 1 | ✅ 覆盖 | 依赖版本需对齐 |
| §4.2 API Key 管理 UI | Task 8 | ❌ 重复 | 与已有模块完全重叠 |

---

## 修正优先级汇总

| 优先级 | # | 问题 | 修正建议 |
|--------|---|------|----------|
| P0 | 1 | SmartTileProvider 多 MBTiles 架构 | 补充改造方案 + updateSources 机制 |
| P0 | 2 | OfflineTileManager 方法签名 | 对齐规格 §7.2 接口定义 |
| P0 | 3 | API Key 管理 UI 重复 | 改为增量改进现有模块 |
| P1 | 4 | drift 依赖声明 | 补充 sqlite3_flutter_libs 版本升级 |
| P1 | 5 | TileMeta 表引用计数 | 拆分关联表或明确聚合语义 |
| P1 | 6 | 缺少 domain model 文件 | 补充 TileStatus、LocalTileInfo |
| P1 | 7 | 网络策略未覆盖 | Task 5 增加网络类型检测 |
| P1 | 8 | 断点续传细节不足 | 补充状态管理方案 |
| P1 | 9 | TileSourceResolver 离线处理 | 增加本地优先策略 |
| P1 | 10 | 引用计数/多牧场共享 | 增加 removeFarmReference 方法 |

**总体评价**: 计划的 Task 拆分和代码示例质量较高，能指导执行者快速上手。核心问题集中在 **SmartTileProvider 多源改造**（计划最关键的技术难点）和 **与已有代码库的对齐**（API Key 模块重复）。修正 3 个 P0 + 7 个 P1 后，计划可进入执行阶段。

---

*Generated: 2026-05-28*
