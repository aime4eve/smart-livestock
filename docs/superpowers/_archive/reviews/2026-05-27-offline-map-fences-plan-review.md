# Flutter 离线围栏 + 可观测性实施计划 — 评审报告

> **评审对象**: [2026-05-27-offline-map-fences-plan.md](../plans/2026-05-27-offline-map-fences-plan.md)
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **评审日期**: 2026-05-27

---

## 总结

计划覆盖了规格文档 §8（离线围栏）和 §9（可观测性）的全部内容，8 个 Task 拆分粒度合理，代码示例详尽，Self-Review 覆盖率矩阵有助于验收。但存在 **4 个 P0 问题**（`CachedFenceData` 字段不可变但代码中赋值——编译不过、`FenceSyncRepository` 接口缺少 `getByRemoteId` 方法、`AppDatabase` 继承了错误的基类、缺少 drift 代码生成步骤）和 **6 个 P1 问题**（缺少 Riverpod Provider 定义、`FenceConflict` 数据类未定义、无离线检测机制、`TileAnalytics` 绕过现有 `ApiClient`、`FenceItem.id` 类型不匹配、离线删除流程缺失）以及若干 P2 建议，需要在执行前修正。

**结论**: 修正 P0 + P1 后可开始执行。

---

## P0 — 必须修正

### 1. `CachedFenceData` 字段为 `final`，但 `FenceSyncService` 中直接赋值——编译失败

**位置**: Task 2 Step 4（`fence_sync_service.dart`）

**问题**: `CachedFenceData` 的所有字段均声明为 `final`：

```dart
final int? remoteId;   // ← final
final int synced;      // ← final
```

但 `FenceSyncService.sync()` 中有两处直接赋值：

```dart
fence.remoteId = response['id'];        // 编译错误
await _repo.updateLocal(fence..synced = 1);  // 编译错误
```

Dart 的 `final` 字段只能在构造函数中赋值，之后不可修改。

**建议**: 为 `CachedFenceData` 添加 `copyWith()` 方法（与现有 `FenceItem` 模式一致），所有修改操作通过 `copyWith` 创建新实例：

```dart
CachedFenceData copyWith({int? remoteId, int? synced, ...}) =>
    CachedFenceData(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      synced: synced ?? this.synced,
      ...
    );
```

`FenceSyncService` 改为：
```dart
final updated = fence.copyWith(remoteId: response['id'], synced: 1);
await _repo.updateLocal(updated);
```

### 2. `FenceSyncRepository` 接口缺少 `getByRemoteId` 方法

**位置**: Task 2 Step 2

**问题**: 接口定义只有 5 个方法：

```dart
abstract class FenceSyncRepository {
  Future<void> saveLocal(CachedFenceData fence);
  Future<void> updateLocal(CachedFenceData fence);
  Future<List<CachedFenceData>> getUnsynced();
  Future<void> markSynced(int localId);
  Future<void> upsertFromServer(CachedFenceData fence);
  Future<List<CachedFenceData>> getByFarm(int farmId);
}
```

但 `FenceSyncService.sync()` 的 Pull 阶段调用了 `getByRemoteId`：

```dart
final local = await _repo.getByRemoteId(sf.remoteId!);
```

此方法未在接口中声明，`FenceSyncRepositoryImpl` 也不会实现它。

**建议**: 在接口中新增：

```dart
Future<CachedFenceData?> getByRemoteId(int remoteId);
```

并在 `FenceSyncRepositoryImpl` 中实现对应的 drift 查询。

### 3. `AppDatabase` 继承了错误的基类

**位置**: Task 1 Step 1

**问题**: 代码中写的是：

```dart
@DriftDatabase(tables: [CachedFences, CachedLivestockPositions, AnalyticsEvents])
class AppDatabase extends Database {
```

drift 的正确用法是通过 `build_runner` 生成 `app_database.g.dart`，其中包含一个 `_$AppDatabase` 抽象类。数据库类应继承生成的类：

```dart
class AppDatabase extends _$AppDatabase {
```

`Database` 是 drift 包中的低级 API，不配合代码生成使用。

**建议**: 改为 `extends _$AppDatabase`，确保 `part 'app_database.g.dart';` 和 `build_runner` 配合正确。

### 4. 缺少 drift 代码生成步骤

**问题**: drift 依赖 `build_runner` 生成 `.g.dart` 文件（数据类、查询代码等）。计划从未提及运行代码生成命令。

**建议**: 在 Task 1 Step 2（创建表之后）和每个涉及 drift schema 变更的步骤后，增加代码生成步骤：

```bash
cd Mobile/mobile_app
dart run build_runner build --delete-conflicting-outputs
```

Task 1 的测试步骤也需要在代码生成之后执行。建议将此命令加入 Task 1 Step 2 的提交前命令中，并在 Task 8 验证中提及。

---

## P1 — 应当修正

### 5. 缺少 Riverpod Provider 定义

**问题**: 计划创建了 `AppDatabase`、`FenceSyncService`、`TileAnalytics`、`LivestockPositionCache` 等类，但未定义任何 Riverpod Provider。现有代码库严格使用 Provider 注入模式（如 `fenceRepositoryProvider`、`sessionControllerProvider`）。

没有 Provider，这些类无法在 Widget/Controller 中通过 `ref.read()` 获取。Task 3 修改 `FenceController` 时将无法访问 `AppDatabase`。

**建议**: 在 File Structure 中增加 `core/database/app_database_provider.dart`，或在 `app_database.dart` 底部添加：

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final fenceSyncServiceProvider = Provider<FenceSyncService>((ref) {
  return FenceSyncService(
    repo: ref.read(fenceSyncRepositoryProvider),
    baseUrl: ApiClient.instance.baseUrl,
  );
});

final tileAnalyticsProvider = Provider<TileAnalytics>((ref) {
  return TileAnalytics(
    db: ref.read(appDatabaseProvider),
    baseUrl: ApiClient.instance.baseUrl,
  );
});
```

### 6. `FenceConflict` 数据类被引用但从未定义

**位置**: Task 2 Step 4、Task 4

**问题**: `FenceSyncService` 中使用了 `FenceConflict`：

```dart
conflicts.add(FenceConflict(
  localFence: fence,
  serverVersion: result.serverVersion!,
  serverVertices: result.serverVertices!,
  lastModifiedBy: result.lastModifiedBy,
  lastModifiedAt: result.lastModifiedAt,
));
```

`FenceConflictPage` 也以 `final FenceConflict conflict` 作为参数。但整个计划没有定义 `FenceConflict` 类的步骤。

**建议**: 在 Task 2 中新增 Step（或在 domain 目录下创建 `fence_conflict.dart`）：

```dart
class FenceConflict {
  final CachedFenceData localFence;
  final int serverVersion;
  final List<LatLng> serverVertices;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  const FenceConflict({
    required this.localFence,
    required this.serverVersion,
    required this.serverVertices,
    this.lastModifiedBy,
    this.lastModifiedAt,
  });
}
```

### 7. 无离线检测机制

**问题**: Task 3 说"离线时写入本地缓存"、"在线时调用 API"，但计划未定义如何检测网络状态。

现有代码有 `ViewState.offline` 但没有网络监听器。`FenceController` 当前直接调用 API，捕获异常后设为 `ViewState.error`，不区分网络错误和其他错误。

**建议**:

方案 A（推荐）— 利用现有 `ApiException` 层次结构：
- `NetworkException` 已存在，`FenceController` 捕获 `NetworkException` 时切换到离线模式
- 在 `FenceController` 中新增 `bool _isOffline = false` 状态，catch 块中设置

方案 B — 添加 `connectivity_plus` 依赖做网络监听（需要添加新依赖，成本较高）

无论选哪种，Task 3 Step 1 应明确离线判断逻辑，并说明 `FenceController` 如何感知在线/离线状态变化。

### 8. `TileAnalytics` 绕过现有 `ApiClient`

**位置**: Task 7 Step 1

**问题**: `TileAnalytics` 直接使用 `http.post(Uri.parse('$_baseUrl/analytics/events'), ...)` 发请求，未使用现有的 `ApiClient` 单例。

现有代码库中所有 API 调用都通过 `ApiClient`（自动带 JWT header、base URL 管理、错误处理），绕过它会导致：
- 缺少 JWT 认证 header
- base URL 不走 `--dart-define` 覆盖
- 异常处理与项目统一模式不一致

**建议**: 将 `TileAnalytics` 改为依赖 `ApiClient`：

```dart
class TileAnalytics {
  final AppDatabase _db;
  final ApiClient _apiClient;  // 注入而非 baseUrl

  Future<void> flush() async {
    ...
    await _apiClient.post('/analytics/events', body: jsonEncode(batch));
    ...
  }
}
```

### 9. `FenceItem.id` 类型与 `CachedFenceData.id` 不匹配

**问题**: 现有 `FenceItem.id` 是 `String` 类型：

```dart
// features/fence/domain/fence_item.dart
final String id;
```

但 `CachedFenceData.id` 是 `int?`：

```dart
final int? id;
```

Task 3 要求在 `FenceController` 中合并在线数据（`FenceItem`）和离线缓存（`CachedFenceData`），但两者的 ID 类型不同，无法直接比较。

**建议**: 两种方案：

方案 A — `CachedFenceData` 的 `id` 和 `remoteId` 保持 `int`，但在 `FenceSyncRepositoryImpl` 中提供 `FenceItem ↔ CachedFenceData` 双向转换方法。

方案 B — 调查服务端 `fences` 表的 ID 是整数还是 UUID，统一两端类型。如果是整数，可能需要修改 `FenceItem.id` 为 `int`（影响面较大）。

至少应在计划中明确说明 ID 类型映射策略，避免实施时才暴露问题。

### 10. 离线删除流程缺失

**问题**: Task 3 Step 1 提到"When creating/editing/deleting a fence while offline"，但只描述了 create 和 edit 的处理方式（写入 `cached_fences`，`synced=0`）。删除操作未说明：

- 离线删除的围栏如何在本地标记？（不能物理删除，否则 sync 时不知道要删除服务端数据）
- sync 时如何推送删除？（需要调用 `DELETE /farms/{farmId}/fences/{id}`）
- 本地新增（`remoteId=null`）的围栏被离线删除时，直接物理删除即可

**建议**: 在 `CachedFences` 表或 `CachedFenceData` 中增加 `localDeleteFlag` 字段，或在 `status` 字段中使用 `'deleted'` 值标记离线删除。在 `FenceSyncService.sync()` 中增加删除阶段（在 push 创建/更新之后、pull 之前）。

---

## P2 — 建议改进

### 11. `fence_type` 语义混淆

**问题**: 现有 `FenceItem` 有 `FenceType` 枚举（`polygon`, `circle`, `rectangle`），表示围栏的**几何形状**。设计规格 §3.2 新增的 `fence_type` 列（`sub`/`boundary`）表示围栏的**用途类型**（子围栏/边界围栏）。

这是两个不同维度的概念，但都叫 `fenceType`，极易混淆。计划的 `CachedFences` 表中 `fenceType` 字段默认值为 `'sub'`，暗示存的是用途类型而非几何类型。

**建议**: 在 `CachedFenceData` 中将字段命名为 `fencePurpose` 或区分两个字段：`geometryType`（几何）+ `fencePurpose`（用途），减少实施时的歧义。

### 12. 未考虑坐标转换

**问题**: 项目已有 `coord_transform.dart`（WGS-84 ↔ GCJ-02）。围栏顶点在缓存和同步时是否需要坐标转换？服务端存储的是 WGS-84 还是 GCJ-02？

计划未提及坐标处理，可能导致缓存的 vertices 与服务端数据坐标系不一致。

**建议**: 在 `FenceSyncRepositoryImpl` 中明确缓存时使用哪种坐标系，并在拉取/推送时做必要的转换。如果服务端统一使用 WGS-84，客户端渲染时再转 GCJ-02，应在计划中注明。

### 13. 后端端点创建超出计划范围

**位置**: Task 7 Step 2

**问题**: 计划在 Flutter 客户端计划中包含了后端 `AnalyticsController` 的 Java 代码。但计划声明依赖 Plan A（后端）和 Plan B（OfflineTileManager），后端变更应在 Plan A 中完成。

**建议**: 将 Task 7 Step 2 标记为"需 Plan A 配合"，或移除后端代码改为引用 Plan A 的对应 Task。避免跨计划修改后端代码导致冲突。

### 14. Task 3 缺少测试步骤

**问题**: Task 3（离线围栏编辑集成）有 3 个 Step 但没有测试步骤。Task 1、2、4、7 都有测试，Task 3 和 Task 5 缺失。

**建议**: 为 Task 3 补充 widget 测试，验证：
- 离线时写入本地缓存
- `OfflineEditBanner` 正确显示未同步数量
- 在线时缓存与 API 数据合并逻辑

### 15. `reportBacklog()` 批量上报的数据格式

**位置**: Task 7 Step 1

**问题**: `reportBacklog()` 从 drift 读取 `data` 字段（JSON string），用 `jsonDecode(e.data)` 解析后放入 map 的 `'data'` key 中：

```dart
final batch = unreported.map((e) => {
  'event': e.event,
  'data': jsonDecode(e.data),
}).toList();
```

这导致上报的 JSON 格式为 `{"event": "...", "data": {"event": "...", "timestamp": "...", ...}}`，与 `flush()` 上报的扁平格式 `{"event": "...", "timestamp": "...", ...}` 不一致。

**建议**: `reportBacklog()` 应直接用 `jsonDecode(e.data)` 作为整个事件对象，不再嵌套：

```dart
final batch = unreported.map((e) => jsonDecode(e.data) as Map<String, dynamic>).toList();
```

### 16. `AppDatabase.forTesting` 缺少说明

**问题**: Task 1 定义了 `AppDatabase.forTesting(super.e)` 构造函数，但没有说明如何在测试中使用。drift 测试通常需要 `NativeDatabase.memory()`。

**建议**: 在 Task 1 的测试代码中补充 in-memory 数据库创建：

```dart
AppDatabase db = AppDatabase.forTesting(
  NativeDatabase.memory(),
);
```

---

## 规格覆盖度

| 规格章节 | 计划 Task | 覆盖度 | 备注 |
|---------|-----------|--------|------|
| §8.1 围栏本地缓存（drift） | Task 1 | ✅ 完整 | |
| §8.1 先推后拉同步 | Task 2 | ⚠️ 部分 | 缺 `getByRemoteId`、删除流程 |
| §8.2 离线围栏编辑 | Task 3 | ⚠️ 部分 | 无离线检测机制、无测试 |
| §8.3 冲突检测 + 双栏地图 | Task 4 | ✅ 完整 | `FenceConflict` 类未定义 |
| §8.4 Farm 创建边界围栏 | Task 6 | ✅ 完整 | |
| §8.5 牲畜位置缓存 | Task 5 | ✅ 完整 | 无测试 |
| §9.1 埋点事件（8 种） | Task 7 | ✅ 完整 | |
| §9.2 批量上报（20 flush） | Task 7 | ✅ 完整 | `reportBacklog` 格式有 bug |
| §9.2 离线持久化到 drift | Task 7 | ✅ 完整 | |
| §9.3 服务端 analytics 端点 | Task 7 | ⚠️ | 应在 Plan A 中完成 |

---

## 代码质量扫描

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 编译正确性 | ❌ | P0 #1（final 赋值）、P0 #3（继承错误）导致编译失败 |
| 接口一致性 | ❌ | P0 #2（缺少方法）、P1 #6（未定义类） |
| 代码生成 | ❌ | P0 #4（缺少 build_runner 步骤） |
| 依赖注入 | ❌ | P1 #5（缺少 Provider） |
| 现有模式匹配 | ⚠️ | P1 #8（绕过 ApiClient）、P1 #9（ID 类型不匹配） |
| Placeholder 扫描 | ✅ | 无 TBD/TODO |
| 代码风格一致性 | ✅ | 符合 AGENTS.md 规定的 snake_case、ConsumerWidget、Key 约定 |

---

## 问题汇总

| 级别 | 编号 | 概要 |
|------|------|------|
| P0 | 1 | `CachedFenceData` final 字段被赋值——编译错误 |
| P0 | 2 | `FenceSyncRepository` 缺少 `getByRemoteId` 方法 |
| P0 | 3 | `AppDatabase` 继承 `Database` 而非 `_$AppDatabase` |
| P0 | 4 | 缺少 `build_runner` 代码生成步骤 |
| P1 | 5 | 缺少 Riverpod Provider 定义 |
| P1 | 6 | `FenceConflict` 数据类未定义 |
| P1 | 7 | 无离线检测机制 |
| P1 | 8 | `TileAnalytics` 绕过 `ApiClient` |
| P1 | 9 | `FenceItem.id`(String) 与 `CachedFenceData.id`(int) 类型不匹配 |
| P1 | 10 | 离线删除流程缺失 |
| P2 | 11 | `fence_type` 几何 vs 用途语义混淆 |
| P2 | 12 | 未考虑 WGS-84/GCJ-02 坐标转换 |
| P2 | 13 | 后端端点创建超出计划范围 |
| P2 | 14 | Task 3 缺少测试 |
| P2 | 15 | `reportBacklog` 上报格式与 `flush` 不一致 |
| P2 | 16 | `AppDatabase.forTesting` 缺少使用说明 |

---

*评审生成时间: 2026-05-27*
