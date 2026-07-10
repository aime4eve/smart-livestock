# 离线地图 + 围栏集成 — 三计划综合评审

> **评审对象**: 三份实施计划 vs 需求规格文档
> **规格文档**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **计划 A (后端)**: [2026-05-27-offline-map-backend-plan.md](../plans/2026-05-27-offline-map-backend-plan.md)
> **计划 B (Flutter 瓦片)**: [2026-05-27-offline-map-flutter-tiles-plan.md](../plans/2026-05-27-offline-map-flutter-tiles-plan.md)
> **计划 C (Flutter 围栏+可观测)**: [2026-05-27-offline-map-fences-plan.md](../plans/2026-05-27-offline-map-fences-plan.md)
> **评审日期**: 2026-05-28
> **结论**: ~~有条件通过~~ → **已修正** — 所有 P0/P1 问题已在三份计划中修正，复审通过

---

## 1. 总体评估

三份计划对规格文档的 **功能点覆盖率约 95%**，实施单元拆分合理，与现有代码库对齐准确。存在以下类别的问题：

| 类别 | 数量 | 说明 |
|------|------|------|
| P0 阻断 | 2 | 不修正会导致实施失败或数据损坏 |
| P1 重要 | 5 | 不修正会导致功能不完整或运行时异常 |
| P2 建议 | 4 | 影响可维护性或用户体验 |
| P3 低优 | 3 | 小改进，可后续迭代 |

---

## 2. P0 — 阻断问题

### 2.1 [P0] drift 数据库分裂：两个独立数据库冲突

**涉及计划**: Plan B + Plan C

**问题**: Plan B 创建 `LocalTileMetaStore`（独立 drift 数据库，含 `TileMetas` 表），Plan C 创建 `AppDatabase`（另一个独立 drift 数据库，含 `CachedFences` + `CachedLivestockPositions` + `AnalyticsEvents` 表）。两个 `@DriftDatabase` 类各有自己的 `.g.dart` 文件和 SQLite 数据库文件。

**风险**:
- `dart run build_runner build` 时两个 drift 数据库共享同一 build pipeline，如果并行执行（不同 worker），代码生成可能互相覆盖或冲突
- 两个 SQLite 文件无法做跨表事务（如删除牧场时同时清理瓦片元数据 + 围栏缓存）
- `part 'app_database.g.dart'` 和 `part 'local_tile_meta_store.g.dart'` 在 `lib/` 下各自生成，目录结构不够清晰

**建议**: 合并为单一 `AppDatabase`，包含所有 5 张表（`TileMetas`、`CachedFences`、`CachedLivestockPositions`、`AnalyticsEvents`、及未来扩展表）。Plan B Task 1 创建基础 AppDatabase + TileMetas，Plan C Task 1 通过 `schemaVersion` 升级追加其余 3 张表。

```dart
// core/database/app_database.dart — 统一入口
@DriftDatabase(tables: [TileMetas, CachedFences, CachedLivestockPositions, AnalyticsEvents])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // B 创建时 version=1, C 升级到 version=2
}
```

### 2.2 [P0] FenceItem 缺少 version/fenceType 字段，离线围栏编辑无法工作

**涉及计划**: Plan C (Task 3)

**问题**: Plan C Task 3 要求修改 `FenceController` 在离线时将围栏写入 `cached_fences`，但 `FenceItem`（`features/fence/domain/fence_item.dart`）当前字段不包含 `version` 和 `fenceType`。Plan C 的 modified files 表中列出了修改 `fence_repository.dart`（"Add version field to DTO"），但 **没有列出修改 `FenceItem`**——这是实际承载围栏数据的 data class。

**影响**: 如果 `FenceItem` 没有添加 `version` 字段：
- `FenceSyncService` 无法获取服务端版本号来检测冲突
- `cached_fences` 表写入时 `version` 无数据来源
- 冲突解决页面（dual-map）无法展示版本差异

**建议**: Plan C 的 Modified Files 表和 Task 3 中明确添加：
- 修改 `FenceItem` — 增加 `int version` 和 `String fenceType` 字段 + `copyWith` 扩展
- 修改 `FenceApiRepository` — 解析 API 响应中的 `version` 和 `fenceType` 字段
- 修改 `FenceRepository` 接口 — `update` 方法签名增加 `expectedVersion` 参数

---

## 3. P1 — 重要问题

### 3.1 [P1] SmartTileProvider 多区域加载机制不够详细

**涉及计划**: Plan B (Task 2)

**问题**: Plan B Task 2 "TileSourceResolver + 动态 SmartTileProvider" 描述了 API 调用和 `updateSources()` 方法，但现有 `SmartTileProvider` 接受单个 `MBTilesTileProvider?`。切换到支持多个 MBTiles 文件（跨区域牧场）需要：
- 持有 `List<MBTilesTileProvider>` 并按瓦片坐标查找
- 降级逻辑：第一个 MBTiles 命中 → 第二个 → 在线源 → fallback

计划中 `updateSources` 的签名为 `void updateSources(List<TileSource> sources)`，但 **Step 4 "修改 SmartTileProvider" 只有一行描述**，缺乏具体的多 MBTiles 文件查找逻辑。

**建议**: Task 2 Step 4 补充：
```dart
// SmartTileProvider 核心改造点
final List<MBTilesTileProvider> _mbtilesProviders = [];

@override
Future<TileProvider> getTileProvider(Coords xyz, TileLayerOptions options) async {
  for (final provider in _mbtilesProviders) {
    if (await provider.hasTile(xyz)) return provider;
  }
  // 降级到在线源 / fallback
}
```
注意：`MBTilesTileProvider` 当前可能没有 `hasTile()` 方法，需要扩展。

### 3.2 [P1] Pin/Unpin 使用逗号分隔字符串存储，存在数据一致性风险

**涉及计划**: Plan B (Task 4)

**问题**: `TileMetas` 表的 `farmIds` 和 `pinnedFarmIds` 使用逗号分隔字符串。在以下场景会出现问题：
- 删除牧场时需要从 `farmIds` 字符串中移除一个 ID（字符串操作，容易出错）
- 多个牧场同时 pin/unpin 同一区域，并发写入 `pinnedFarmIds` 字符串可能导致数据丢失
- 查询"哪些区域被 farmId=3 引用"需要 `LIKE '%3%'`，可能误匹配（如 farmId=3 匹配 farmId=13）

**建议**: 使用 drift 的关联表或在 `TileMetas` 中使用 JSON 数组存储，配合 `jsonDecode` 解析。更优方案是创建 `FarmTilePin` 关联表：

```dart
class FarmTilePins extends Table {
  IntColumn get farmId => integer()();
  IntColumn get tileMetaId => integer()();
  IntColumn get pinned => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {farmId, tileMetaId};
}
```

### 3.3 [P1] Farm 删除时瓦片/围栏/缓存级联清理未覆盖

**涉及计划**: 三份计划均未涉及

**问题**: 规格文档 §10 "不改动的部分" 未提及 farm 删除场景，但现有的 `FenceController` 有 `delete` 端点。当 farm 被删除时：
- 服务端：`farm_tile_tasks` 记录需级联删除（`farm_id` FK 有 `ON DELETE CASCADE`？需确认）
- 客户端：本地 `cached_fences` + `TileMetas` 中该 farm 的数据需清理
- 引用计数：如果某区域只被已删除 farm 引用，应触发 LRU 回收

**建议**: 在 Plan A Task 1 的迁移 SQL 中确认 `farm_tile_tasks.farm_id` 使用 `ON DELETE CASCADE`。Plan B/C 各增加一个任务或在现有任务中补充 farm 删除时的清理逻辑。

### 3.4 [P1] Plan C Task 7 Step 2 在后端新增 analytics 端点，但修改范围与 Plan A 重叠

**涉及计划**: Plan A + Plan C

**问题**: Plan A 的 Self-Review 明确说明 "可观测性 deferred to Flutter 客户端 Plan（Plan C Task 7 创建 `POST /api/v1/analytics/events` 端点，本计划不涉及）"。Plan C Task 7 Step 2 直接在 `TileController` 或新建 `AnalyticsController` 中添加端点。

风险：
- 如果 Plan A 和 Plan C 由不同 worker 并行执行，可能同时修改 `SecurityConfig` 或 controller 注册
- 新端点需要 Spring Security 白名单（`/api/v1/analytics/events` 需要 JWT 认证？还是公开？），Plan C 未提及 SecurityConfig 修改

**建议**: 将 analytics 端点移入 Plan A（服务端所有 API 变更在一个 plan 中完成），Plan C 只负责客户端上报逻辑。或者明确 Plan C 中标注"此步骤依赖 Plan A 已部署"。

### 3.5 [P1] 围栏同步的"先推后拉"边界条件未处理

**涉及计划**: Plan C (Task 2)

**问题**: Plan C Task 2 实现了 push-then-pull 同步，但以下边界条件未覆盖：

1. **推送时本地已删除（localDeleteFlag=1）**：推送一个 delete 到服务端，但服务端围栏已被其他用户删除 → 返回 404 → 如何处理？
2. **推送时网络中断**：推送了 3 条中的 2 条后断网 → 第 3 条未推送，但 pull 已执行 → 本地数据是否一致？
3. **Pull 时大量数据覆盖**：如果服务端有 100 条围栏更新，pull 全量替换可能导致正在编辑的围栏被覆盖

**建议**: Task 2 Step 2 的 sync 流程增加：
- 推送失败时跳过该条，继续推送下一条（而非中止整个同步）
- delete 推送遇到 404 视为成功（幂等）
- pull 使用增量同步（基于 `updated_at` 时间戳），而非全量替换

---

## 4. P2 — 建议改进

### 4.1 [P2] import_mbtiles.sh 容错不足

**涉及计划**: Plan A (Task 9)

`curl -sf` 静默失败后仅打印 "Failed: $base" 并继续。建议增加失败计数，全部完成后汇总报告。同时 `bounds` 提取依赖 python3，如果 python3 不可用会导致所有 region 跳过但脚本仍以 exit 0 结束。

### 4.2 [P2] 后台下载 iOS 限制未显式说明

**涉及计划**: Plan B (Task 7)

Plan B 提到使用 `workmanager` 做后台下载，但 iOS 的 `BGAppRefreshTask` 有严格限制（系统决定执行时机、不保证执行）。建议在 Task 7 中明确标注 iOS 后台下载为 "best-effort"，并确保前台下载流程（Task 3）是完整的用户体验路径。

### 4.3 [P2] TileAnalytics 生命周期管理

**涉及计划**: Plan C (Task 7)

`TileAnalytics` 使用内存 `_buffer` 收集事件。App 进入后台或被系统杀死时，buffer 中未满 20 条的事件会丢失。建议在 `WidgetsBindingObserver.didChangeAppLifecycleState` 中触发 `flush()`，或在 Plan C Task 7 Step 1 中添加 App 生命周期监听。

### 4.4 [P2] 缺少跨 Plan 集成测试

三份计划各自有单元测试和独立验证步骤，但没有跨 Plan 的集成测试场景。建议在 Plan C 最后增加一个端到端测试计划（手动或自动化），覆盖：

```
创建牧场 → 画边界围栏 → 服务端检测瓦片覆盖
→ 客户端下载瓦片 → 离线查看瓦片 + 围栏
→ 离线编辑围栏 → 上线同步 → 验证冲突检测
```

---

## 5. P3 — 低优先级

### 5.1 [P3] TileMetas.farmIds 字段命名歧义

`farmIds TEXT` 存储逗号分隔的 farm ID，但字段名暗示关联关系。如果采纳 P1 建议改用关联表，此问题自动解决。

### 5.2 [P3] drift 依赖版本锁定

Plan B 指定 `drift: ^2.18`，但 drift 更新较频繁。建议在 `pubspec.yaml` 中明确锁定小版本（如 `drift: ^2.18.0`），避免 `dart pub get` 时意外升级导致代码生成不兼容。

### 5.3 [P3] 覆盖率计算精度

Plan A 的 `TileCoverageCalculator` 使用外接矩形面积比计算覆盖率，对于凹多边形围栏可能高估覆盖率。当前可接受，但长期应考虑使用精确多边形面积计算（Shoelace formula）。

---

## 6. 规格覆盖度矩阵

| 规格章节 | 功能点 | Plan A | Plan B | Plan C | 覆盖状态 |
|---------|--------|--------|--------|--------|---------|
| §3.1 4 张新表 | tile_regions + tile_generation_tasks + farm_tile_tasks + tile_download_log | Task 1 | — | — | ✅ 完整 |
| §3.2 Fence version/type | version + fence_type 字段 | Task 1 | — | — | ✅ 完整 |
| §3.3 bbox 匹配 | 区域覆盖计算 | Task 6 | — | — | ✅ 完整 |
| §3.4 覆盖率三级分支 | ≥50% / 30-50% / <30% | Task 6 | — | — | ✅ 完整 |
| §4.1 API Key 认证 | SHA-256 + X-API-Key | Task 4 | — | — | ✅ 完整 |
| §4.2 API Key 管理 UI | 列表/创建/吊销/删除 | — | Task 8 | — | ✅ 完整 |
| §5.1 9 个瓦片 API | 管理端 + 客户端端点 | Task 6 | — | — | ✅ 完整 |
| §5.2 Farm 创建瓦片检测 | boundary + coverage | Task 7 | — | — | ✅ 完整 |
| §5.3 围栏 409 + forceUpdate | 版本冲突检测 | Task 1 | — | — | ✅ 完整 |
| §6.1 generate_mbtiles --task-id | API 驱动生成 | Task 8 | — | — | ✅ 完整 |
| §6.2 import_mbtiles DB 同步 | 导入后更新 DB | Task 9 | — | — | ✅ 完整 |
| §7.1 动态区域解析 | 多区域 tile-source | — | Task 2 | — | ⚠️ 细节不足（P1 3.1） |
| §7.2 OfflineTileManager | 下载/校验/LRU/pin | — | Task 3-5 | — | ⚠️ pin 存储方式（P1 3.2） |
| §7.2 前台下载 | wakelock + 进度 | — | Task 3 | — | ✅ 完整 |
| §7.2 后台下载 | workmanager | — | Task 7 | — | ✅ 完整 |
| §7.3 管理页面 | 离线瓦片管理 UI | — | Task 6 | — | ✅ 完整 |
| §7.4 更新检测 | generatedAt 对比 | — | Task 9 | — | ✅ 完整 |
| §7.5 drift + sqlite3 | 双方案选型 | — | Task 1 | — | ⚠️ 数据库分裂（P0 2.1） |
| §8.1 围栏缓存 + 同步 | drift cached_fences | — | — | Task 1-2 | ⚠️ 边界条件（P1 3.5） |
| §8.2 离线围栏编辑 | 本地编辑 + sync | — | — | Task 3 | ⚠️ FenceItem 缺字段（P0 2.2） |
| §8.3 冲突解决 | dual-map 对比 | — | — | Task 4 | ✅ 完整 |
| §8.4 Farm 创建集成 | boundary fence_type | — | — | Task 6 | ✅ 完整 |
| §8.5 牲畜位置缓存 | GPS 坐标离线 | — | — | Task 5 | ✅ 完整 |
| §9.1 埋点事件 | 8 类事件 | — | — | Task 7 | ✅ 完整 |
| §9.2 批量上报 | 20 条 flush + 离线持久化 | — | — | Task 7 | ⚠️ 生命周期（P2 4.3） |
| §9.3 服务端端点 | analytics/events | — | — | Task 7 | ⚠️ 跨 Plan 重叠（P1 3.4） |

**覆盖率**: 27 项中 19 项 ✅ 完整，6 项 ⚠️ 有问题需修正，2 项未显式覆盖（Farm 删除级联、跨 Plan 集成测试）

---

## 7. 计划间依赖关系验证

```
Plan A (Backend)
  ├── Task 1 (V13 迁移) ← 无依赖，可先行
  ├── Task 4 (API Key) ← 依赖 Task 1
  ├── Task 6 (瓦片 API) ← 依赖 Task 1
  ├── Task 7 (Farm 创建) ← 依赖 Task 6
  └── Task 8-9 (Tooling) ← 依赖 Task 4 + 6

Plan B (Flutter 瓦片) ← 依赖 Plan A Task 6 部署
  ├── Task 1 (drift + deps) ← 无 Plan A 依赖，可先行
  ├── Task 2 (SmartTileProvider) ← 需 Plan A Task 6 API
  ├── Task 3-5 (下载/校验/LRU) ← 需 Task 1-2
  ├── Task 6 (管理页面) ← 需 Task 4
  ├── Task 7 (后台下载) ← 需 Task 3
  └── Task 8 (API Key UI) ← 需 Plan A Task 4

Plan C (Flutter 围栏) ← 依赖 Plan A Task 1 + Plan B
  ├── Task 1 (AppDatabase) ← ⚠️ 与 Plan B Task 1 冲突（P0 2.1）
  ├── Task 2 (同步) ← 需 Plan A Task 1 (fence version)
  ├── Task 3 (离线编辑) ← 需 Task 1-2
  ├── Task 4 (冲突解决) ← 需 Plan A (409 API)
  ├── Task 5 (牲畜缓存) ← 需 Task 1
  ├── Task 6 (Farm 创建) ← 需 Plan A Task 7
  └── Task 7 (可观测) ← 需 Plan B + Plan A
```

**关键路径**: Plan A Task 1 → Task 6 → Plan B Task 2 → Task 3-5 → Plan C Task 2-4

**并行机会**: Plan A Task 1 和 Plan B Task 1（添加依赖）可并行；Plan C Task 4-5 可并行。

---

## 8. 与现有代码库对齐验证

| 计划声明 | 实际代码库 | 是否一致 |
|---------|-----------|---------|
| Plan A: 迁移版本 V13 | 最新为 V12 | ✅ 正确 |
| Plan A: Fence extends AggregateRoot | `Fence.java extends AggregateRoot` | ✅ 正确 |
| Plan A: ApiKeyAuthService 是 stub | Phase 1 stub，接受任意 key | ✅ 正确 |
| Plan A: ApiKeyAdminController 是 stub | 返回 placeholder 数据 | ✅ 正确 |
| Plan A: SecurityConfig 仅有 JWT filter | `addFilterBefore(jwtAuthenticationFilter)` | ✅ 正确 |
| Plan A: UpdateFenceCommand 无 expectedVersion | `record UpdateFenceCommand(name, vertices, color)` | ✅ 正确 |
| Plan A: TileController 使用文件扫描 + regions.json | 确认如此 | ✅ 正确 |
| Plan B: drift 不在 pubspec 中 | 确认不在 | ✅ 正确 |
| Plan B: api_authorization 模块已存在 | 确认存在，含 repository + page | ✅ 正确 |
| Plan B: SmartTileProvider 接受单个 MBTilesProvider | 确认如此 | ✅ 正确 |
| Plan C: core/database/ 不存在 | 确认不存在 | ✅ 正确 |
| Plan C: FenceItem 无 version/fenceType | 确认如此 | ⚠️ 但 Plan C 未列出修改 FenceItem |

---

## 9. 修正建议汇总

| # | 优先级 | 问题 | 建议修正 | 涉及 Plan |
|---|--------|------|---------|----------|
| 1 | P0 | drift 双数据库 | 合并为单一 AppDatabase | B+C |
| 2 | P0 | FenceItem 缺字段 | 添加 version + fenceType | C |
| 3 | P1 | SmartTileProvider 多区域细节 | 补充多 MBTiles 查找逻辑 | B |
| 4 | P1 | Pin 存储方式 | 改用关联表或 JSON 数组 | B |
| 5 | P1 | Farm 删除级联 | 确认 FK CASCADE + 补清理逻辑 | A+B+C |
| 6 | P1 | analytics 端点跨 Plan | 移入 Plan A 或明确依赖 | A+C |
| 7 | P1 | 同步边界条件 | 补充失败处理和增量同步 | C |
| 8 | P2 | import_mbtiles.sh 容错 | 增加失败计数和 exit code | A |
| 9 | P2 | iOS 后台下载限制 | 标注 best-effort | B |
| 10 | P2 | TileAnalytics 生命周期 | 添加 App lifecycle flush | C |
| 11 | P2 | 跨 Plan 集成测试 | 增加端到端测试场景 | C |

---

*初审完成。*

---

## 10. 修正验证总表（2026-05-28）

| # | 优先级 | 问题 | 修正内容 | 涉及 Plan | 状态 |
|---|--------|------|---------|----------|------|
| 1 | P0 | drift 双数据库分裂 | 合并为单一 `AppDatabase`；Plan B 创建（schemaVersion=1, TileMetas+FarmTilePins），Plan C 升级（schemaVersion=2, +3 tables） | B+C | ✅ 已修正 |
| 2 | P0 | FenceItem 缺 version/fenceType | Plan C Task 3 新增 Step 0：扩展 FenceItem + FenceApiRepository + FenceRepository | C | ✅ 已修正 |
| 3 | P1 | SmartTileProvider 多区域细节不足 | Plan B Task 2 Step 2 补充完整 `getImage()` 多 MBTiles 遍历代码 | B | ✅ 已修正 |
| 4 | P1 | Pin 存储用逗号字符串 | Plan B 新增 `FarmTilePins` 关联表替代 comma-separated 字段 | B | ✅ 已修正 |
| 5 | P1 | Farm 删除级联未覆盖 | Plan A Task 1 添加 `ON DELETE CASCADE` 注；Plan C 新增 Task 8 `deleteFarmData()` | A+C | ✅ 已修正 |
| 6 | P1 | analytics 端点跨 Plan 重叠 | Plan A 新增 Task 10 `AnalyticsController`；Plan C Task 7 改为验证端点存在 | A+C | ✅ 已修正 |
| 7 | P1 | 围栏同步边界条件 | Plan C Task 2 重写同步流程：per-record 错误处理、404 幂等、增量 pull | C | ✅ 已修正 |
| 8 | P2 | import_mbtiles.sh 容错 | Plan A Task 9 添加失败计数、python3 可用性检查、非零 exit code | A | ✅ 已修正 |
| 9 | P2 | iOS 后台下载限制 | Plan B Task 7 Step 3 添加 best-effort 说明 | B | ✅ 已修正 |
| 10 | P2 | TileAnalytics 生命周期 | Plan C Task 7 添加 `flushOnAppBackground()` + lifecycle observer | C | ✅ 已修正 |
| 11 | P2 | 跨 Plan 集成测试 | Plan C Task 9 新增 e2e 集成测试步骤 | C | ✅ 已修正 |

**11/11 问题全部修正。三份计划可进入实施阶段。**
