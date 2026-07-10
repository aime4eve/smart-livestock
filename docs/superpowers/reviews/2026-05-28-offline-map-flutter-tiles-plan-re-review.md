# Flutter 离线瓦片实施计划 — 复审报告

> **评审对象**: [2026-05-27-offline-map-flutter-tiles-plan.md](../plans/2026-05-27-offline-map-flutter-tiles-plan.md)（修正后）
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **初评报告**: [2026-05-27-offline-map-flutter-tiles-plan-review.md](2026-05-27-offline-map-flutter-tiles-plan-review.md)
> **复审日期**: 2026-05-28

---

## 总结

初评提出 3 个 P0 + 7 个 P1 + 4 个 P2。修正后计划对所有 P0 和大部分 P1 进行了针对性改进，质量显著提升。**3 个 P0 全部已解决**，7 个 P1 中 5 个已解决、2 个部分解决。剩余问题均为 P2 级别，不阻塞执行。

**结论**: ✅ 可进入执行阶段。

---

## P0 修正验证

### ~~P0-1: SmartTileProvider 多 MBTiles 架构~~ — ✅ 已解决

**初评问题**: 未描述如何将单一 `MBTilesTileProvider` 扩展为多实例列表，缺少 `updateSources()` 签名和 TileLayer 重建机制。

**修正内容**（Task 2 Step 2）:
- 明确了重构方案：`List<MBTilesTileProvider> _mbtilesProviders` + `List<String> _selfHostedUrls` + `List<TileSource> _dynamicSources`
- 描述了 `getImage()` 多源遍历查找顺序：dynamicSources → mbtilesProviders → fallback
- 给出了 `updateSources()` 方法签名和职责
- 说明了 TileLayer 重建机制：`tileSourcesVersionProvider` 计数器 + Riverpod state change → widget rebuild

**残留关注**: `updateSources()` 内部重建 `_mbtilesProviders` 时需要关闭旧的 `Database` 连接（`sqlite3` 资源），计划未提及 `dispose()` 旧实例。这是实现细节，不阻塞。

### ~~P0-2: OfflineTileManager 方法签名~~ — ✅ 已解决

**初评问题**: 方法签名与规格 §7.2 不一致，缺少 `getTileStatus`、`getLocalTiles`、`enqueueBackgroundDownload`。

**修正内容**（Task 4 Step 1）:
- 方法签名完全对齐规格 §7.2：`startForegroundDownload(int farmId, {onProgress, onComplete, onError})`、`cancelDownload(int farmId)`、`getTileStatus(int farmId)`、`getLocalTiles()`、`enqueueBackgroundDownload(int farmId)` 全部补齐
- `downloadTile` + `resumeDownload` 合并为 `startForegroundDownload`，断点续传在内部处理
- `evictIfNeeded` 补充了 `maxBytes = 1024 * 1024 * 1024` 默认值
- 额外增加了 `removeFarmReference(int farmId)` 方法

### ~~P0-3: API Key 管理 UI 重复~~ — ✅ 已解决

**初评问题**: Task 8 创建全新 `LiveApiKeyRepository` + `ApiKeyManagementPage`，与已有 `api_authorization` 模块完全重复。

**修正内容**（Task 8）:
- 标题改为"API Key Management — Incremental Improvement"
- File Structure Note 明确说明"incrementally improves the existing `api_authorization` module"
- 所有文件从 Create 改为 Modify
- Step 1 增强现有 `ApiAuthorizationApiRepository`（补 `deleteApiKey`）
- Step 2 改进现有 `ApiAuthPage`（一次性 key 展示 + 吊销→删除两步操作）
- 路由使用已有的 `/admin/api-auth` 和 `/mine/api-auth`

---

## P1 修正验证

### ~~P1-4: drift 依赖声明~~ — ✅ 已解决

- `sqlite3_flutter_libs` 升级到 `^0.5.42`（Task 1 Step 1），注释标注"Upgrade from ^0.5.28 (spec §7.5)"
- `crypto` 包注释说明用途"Used for MD5 verification of downloaded MBTiles (spec §7.2)"

### ~~P1-5: TileMeta 表引用计数~~ — ⚠️ 部分解决

**修正内容**:
- 新增 `pinnedFarmIds` 列（`TextColumn`），存储 pin 了该区域的 farm ID 子集
- `getUnpinnedOldestFirst()` 查询改为 `pinnedFarmIds.equals('')`
- `removeFarmReference()` 有完整的引用计数逻辑描述
- `pinned` 字段注释明确为 derived field："1 if ANY referencing farm has pinned this region"

**残留问题**:
- `farmIds` 和 `pinnedFarmIds` 仍为逗号分隔文本，解析/更新有并发风险（SQLite 单写者模式下实际风险可控，但代码复杂度较高）。初评建议的关联表方案更优雅，但当前方案在功能上可行
- `getByFarmId` 使用 `LIKE '%$farmId%'`，如果 farmId 是数字子串（如 farmId=1 可能匹配到 `11,21`），存在误匹配风险。建议改为 `(',' || farmIds || ',') LIKE '%,$farmId,%'` 或在应用层过滤

**判定**: 功能可实现，但 `LIKE` 查询有潜在 bug。降级为 P2。

### ~~P1-6: 缺少 domain model 文件~~ — ✅ 已解决

File Structure 补充了 `domain/tile_status.dart`、`domain/local_tile_info.dart`、`domain/offline_tile_repository.dart`（含 interface with method signatures 注释）。

### ~~P1-7: 网络策略未覆盖~~ — ✅ 已解决

Task 5 Step 1 增加了完整的网络策略描述：
- WiFi 直接下载，移动网络弹出底部确认横幅
- 检测方式：HTTP 探测或 `NetworkException` 层次结构（不引入 `connectivity_plus`）
- 可选"仅 WiFi 下载"设置项

### ~~P1-8: 断点续传细节不足~~ — ✅ 已解决

Task 3 Step 1 补充了完整的断点续传方案（第一版简化实现）：
- 检查临时文件存在性 → 读取 size 作为 offset → Range header
- 服务端不支持 Range（返回 200 而非 206）时退化完整下载
- 状态记录用文件大小隐式表示（无额外 meta 文件）
- 明确标注降级策略

### ~~P1-9: TileSourceResolver 离线处理~~ — ✅ 已解决

Task 2 Step 1 `TileSourceResolver.resolveForFarm()` 实现了本地优先策略：
1. 先尝试在线 API
2. 成功则缓存结果（TODO: persist to drift）
3. 失败则回退到 `LocalTileMetaStore.getByFarmId()` 查找已下载的本地 MBTiles
4. 构造 `file://` URL 作为本地 source

**残留关注**: 代码中 `// TODO: persist to drift` 注释表明在线结果的本地持久化尚未设计。这意味着每次离线时都依赖已下载 MBTiles 的元数据来推断 tile-source，而非上次在线时缓存的完整 tile-source 响应。两者在大多数场景下等价，但如果用户从未下载过某牧场的瓦片，离线时将无法解析到任何 source。这在功能上可接受（没下载就没瓦片），不阻塞。

### ~~P1-10: 引用计数/多牧场共享~~ — ✅ 已解决

- 新增 `removeFarmReference(int farmId)` 方法，完整描述了引用计数逻辑
- `deleteLocalTiles(regionName)` 现在检查引用计数，多引用时只更新 meta 不删除文件
- Task 4 Step 2 测试用例增加了 `removeFarmReference deletes file only when no refs remain`

---

## P2 遗留与新发现

### 新 P2-1: `getByFarmId` 的 LIKE 查询误匹配

**来源**: P1-5 残留问题

`LocalTileMetaStore.getByFarmId(int farmId)` 使用 `t.farmIds.like('%$farmId%')`，当 farmId 为纯数字时可能产生子串匹配。例如 farmId=1 会匹配 `11,21`。

**建议**: 改为精确匹配，如：
```dart
(select(tileMetas)..where((t) =>
    const FunctionCallExpression<char>('instr', [Variable('$farmId,'), t.farmIds]).equals(1)
)).get();
```
或在应用层过滤（更简单可靠）：
```dart
final all = await select(tileMetas).get();
return all.where((m) => m.farmIds.split(',').contains(farmId.toString())).toList();
```

### 新 P2-2: TileSourceResolver 缓存持久化 TODO

**来源**: P1-9 残留

`resolveForFarm()` 中有 `// TODO: persist to drift` 注释，在线获取的 tile-source 信息未持久化。建议在后续迭代中补充，或在 Task 2 中标注为已知优化点。

### 原有 P2（保持不变）

- **P2-3**: Drift 代码生成验证步骤（初评 P2-11）
- **P2-4**: iOS 后台下载 30 秒限制说明（初评 P2-12）
- **P2-5**: drift schema `onUpgrade` 预留（初评 P2-14）

---

## 更新后规格覆盖率矩阵

| 规格章节 | 计划 Task | 覆盖状态 | 备注 |
|----------|-----------|----------|------|
| §7.1 动态区域解析 | Task 2 | ✅ 已覆盖 | 多源架构 + 离线回退 |
| §7.2 OfflineTileManager | Task 4 | ✅ 已覆盖 | 方法签名对齐 + 引用计数 |
| §7.2 前台下载 + wakelock | Task 3 | ✅ 已覆盖 | — |
| §7.2 后台下载 + workmanager | Task 7 | ✅ 已覆盖 | — |
| §7.2 MD5 校验 + 原子写入 | Task 3 | ✅ 已覆盖 | — |
| §7.2 Pin/Unpin + LRU | Task 4 | ✅ 已覆盖 | per-farm pinned 语义 |
| §7.2 网络策略 | Task 5 | ✅ 已覆盖 | WiFi/移动网络分流 |
| §7.2 断点续传 | Task 3 | ✅ 已覆盖 | 简化方案 + 降级策略 |
| §7.2 引用计数/多牧场共享 | Task 4 | ✅ 已覆盖 | removeFarmReference |
| §7.3 管理页面 | Task 6 | ✅ 已覆盖 | — |
| §7.4 更新检测 | Task 9 | ✅ 已覆盖 | — |
| §7.5 drift + sqlite3 | Task 1 | ✅ 已覆盖 | 版本已对齐 |
| §4.2 API Key 管理 UI | Task 8 | ✅ 已覆盖 | 增量改进现有模块 |

---

## 修正验证汇总

| 优先级 | # | 初评问题 | 修正状态 | 备注 |
|--------|---|----------|----------|------|
| P0 | 1 | SmartTileProvider 多 MBTiles 架构 | ✅ 已解决 | 多源架构 + TileLayer 重建机制完整 |
| P0 | 2 | OfflineTileManager 方法签名 | ✅ 已解决 | 完全对齐规格 §7.2 |
| P0 | 3 | API Key 管理 UI 重复 | ✅ 已解决 | 改为增量改进 |
| P1 | 4 | drift 依赖声明 | ✅ 已解决 | 版本升级 + 用途注释 |
| P1 | 5 | TileMeta 表引用计数 | ⚠️ 部分 | 功能可行，LIKE 查询有子串风险 |
| P1 | 6 | 缺少 domain model 文件 | ✅ 已解决 | — |
| P1 | 7 | 网络策略未覆盖 | ✅ 已解决 | — |
| P1 | 8 | 断点续传细节不足 | ✅ 已解决 | 简化方案 + 降级策略 |
| P1 | 9 | TileSourceResolver 离线处理 | ✅ 已解决 | 本地优先 + TODO 持久化 |
| P1 | 10 | 引用计数/多牧场共享 | ✅ 已解决 | removeFarmReference 逻辑完整 |

**最终评价**: 修正后计划质量显著提升。所有 P0 问题彻底解决，P1 问题除 `LIKE` 查询子串风险（降为 P2）外全部解决。计划的技术方案完整、可执行，建议进入实施阶段。实施过程中注意 `getByFarmId` 的精确匹配处理和 TileSourceResolver 缓存持久化的后续优化。

---

*Generated: 2026-05-28*
