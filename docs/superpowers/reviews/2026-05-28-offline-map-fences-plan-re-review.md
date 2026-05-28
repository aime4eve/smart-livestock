# Flutter 离线围栏 + 可观测性实施计划 — 复审报告（第 2 轮）

> **评审对象**: [2026-05-27-offline-map-fences-plan.md](../plans/2026-05-27-offline-map-fences-plan.md)（修正后版本，780 行）
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **前次评审**: [2026-05-27-offline-map-fences-plan-review.md](2026-05-27-offline-map-fences-plan-review.md)
> **复审日期**: 2026-05-28

---

## 总结

上次评审的 16 个问题（4 P0 + 6 P1 + 6 P2）中，**14 个已修正**，2 个 P2 未修正但不阻塞。修正质量高，核心编译和逻辑问题均已解决。但修正过程中引入了 **3 个新问题**（1 个 P0 语法错误、2 个 P1 包名/引用错误），需要在本轮修正后即可开始执行。

**结论**: 修正本轮 3 个新问题后可开始执行。

---

## 上轮问题修正追踪

### P0 — 上轮 4 项

| # | 问题 | 状态 | 验证 |
|---|------|------|------|
| 1 | `CachedFenceData` final 字段被赋值 | ✅ 已修正 | 第 294-311 行新增 `copyWith()` 方法，第 388 行改用 `fence.copyWith(remoteId: ..., synced: 1)` |
| 2 | `FenceSyncRepository` 缺少 `getByRemoteId` | ✅ 已修正 | 第 349 行接口新增 `getByRemoteId`，同时新增 `deleteLocal` 和 `getLocallyDeleted` |
| 3 | `AppDatabase` 继承 `Database` 而非 `_$AppDatabase` | ✅ 已修正 | 第 111 行改为 `extends _$AppDatabase` |
| 4 | 缺少 `build_runner` 代码生成步骤 | ✅ 已修正 | 第 158 行首次生成、第 214-223 行 Step 3 含生成+注释、Task 8 Step 1 含最终重新生成 |

### P1 — 上轮 6 项

| # | 问题 | 状态 | 验证 |
|---|------|------|------|
| 5 | 缺少 Riverpod Provider 定义 | ✅ 已修正 | Task 1 Step 4（第 225-254 行）新增 `app_database_provider.dart` |
| 6 | `FenceConflict` 数据类未定义 | ✅ 已修正 | Task 2 Step 2（第 315-335 行）新增 `fence_conflict.dart`，File Structure 同步更新 |
| 7 | 无离线检测机制 | ✅ 已修正 | Task 3 Step 1（第 441-446 行）明确使用 `NetworkException` 检测，不引入新依赖 |
| 8 | `TileAnalytics` 绕过 `ApiClient` | ✅ 已修正 | 第 630 行改为 `final ApiClient _apiClient`，第 648/666 行均通过 `_apiClient.post()` 调用 |
| 9 | `FenceItem.id`(String) 与 `CachedFenceData.id`(int) 类型不匹配 | ✅ 已修正 | 第 269-272 行新增"ID 类型映射策略"段落，明确双向转换方式 |
| 10 | 离线删除流程缺失 | ✅ 已修正 | 表新增 `localDeleteFlag` 列（第 85 行），sync 新增 Phase 0 处理删除（第 366-377 行），Task 3 Step 1 含删除说明（第 451 行） |

### P2 — 上轮 6 项

| # | 问题 | 状态 | 备注 |
|---|------|------|------|
| 11 | `fence_type` 几何 vs 用途语义混淆 | ⬜ 未修正 | 不阻塞执行，实施时注意区分即可 |
| 12 | 未考虑坐标转换 | ⬜ 未修正 | 不阻塞执行，建议在 `FenceSyncRepositoryImpl` 中注明坐标系 |
| 13 | 后端端点超出计划范围 | ⬜ 未修正 | Task 7 Step 2 仍含 Java 代码，建议标注"需 Plan A 配合" |
| 14 | Task 3 缺少测试 | ⬜ 未修正 | 建议后续补充 |
| 15 | `reportBacklog` 上报格式与 `flush` 不一致 | ✅ 已修正 | 第 664 行改为 `jsonDecode(e.data) as Map<String, dynamic>` 直接作为事件对象 |
| 16 | `AppDatabase.forTesting` 缺少使用说明 | ✅ 已修正 | 第 165 行测试中使用 `NativeDatabase.memory()` |

---

## 本轮新发现问题

### P0 — 必须修正

#### 1. `markReported` 方法存在语法错误（多余右括号）

**位置**: Task 1 Step 1（第 146 行）

**问题**: 代码如下：

```dart
Future<void> markReported(List<int> ids) =>
    (update(analyticsEvents)..where((t) => t.id.isIn(ids)))).write(
        const AnalyticsEventsCompanion(reported: Value(1)));
```

`ids))))` 有 4 个右括号，实际只需要 2 个。正确分解：
- `isIn(ids)` — 1 个
- `)` — 关闭 `where(`
- `)` — 关闭外层分组 `(`

第 4 个 `)` 是多余的，会导致编译错误。

**建议**: 改为：

```dart
Future<void> markReported(List<int> ids) =>
    (update(analyticsEvents)..where((t) => t.id.isIn(ids))).write(
        const AnalyticsEventsCompanion(reported: Value(1)));
```

### P1 — 应当修正

#### 2. Provider 文件中的 import 包名错误

**位置**: Task 1 Step 4（第 231-233 行）

**问题**: 代码中 import 路径使用 `package:mobile_app/...`：

```dart
import 'package:mobile_app/core/database/app_database.dart';
import 'package:mobile_app/features/offline_fences/data/fence_sync_service.dart';
import 'package:mobile_app/core/analytics/tile_analytics.dart';
```

但代码库实际包名是 `smart_livestock_demo`（所有现有文件均使用 `package:smart_livestock_demo/...`，如 `fence_controller.dart` 第 3-9 行）。这会导致编译失败。

**建议**: 全部改为 `package:smart_livestock_demo/...`：

```dart
import 'package:smart_livestock_demo/core/database/app_database.dart';
import 'package:smart_livestock_demo/features/offline_fences/data/fence_sync_service.dart';
import 'package:smart_livestock_demo/core/analytics/tile_analytics.dart';
```

#### 3. `fenceSyncRepositoryProvider` 被引用但从未定义

**位置**: Task 1 Step 4（第 241 行）

**问题**: `fenceSyncServiceProvider` 中引用了 `fenceSyncRepositoryProvider`：

```dart
final fenceSyncServiceProvider = Provider<FenceSyncService>((ref) {
  return FenceSyncService(
    repo: ref.read(fenceSyncRepositoryProvider),  // ← 未定义
    baseUrl: ApiClient.instance.baseUrl,
  );
});
```

整个计划的 File Structure 和所有 Task 步骤中从未创建 `fenceSyncRepositoryProvider`。Task 2 创建了 `FenceSyncRepositoryImpl` 但没有声明对应的 Riverpod Provider。此外，该 Provider 文件位于 `core/database/`，却 import 了 `features/offline_fences/` 的类，形成 core → features 的反向依赖，不符合项目分层约定。

**建议**:

方案 A（推荐）— 将 `fenceSyncServiceProvider` 移到 `features/offline_fences/` 模块内：
- 在 `fence_sync_repository_impl.dart` 底部或单独的 `fence_sync_providers.dart` 中定义 `fenceSyncRepositoryProvider` 和 `fenceSyncServiceProvider`
- `app_database_provider.dart` 只保留 `appDatabaseProvider` 和 `tileAnalyticsProvider`

方案 B — 在 `app_database_provider.dart` 中补全 `fenceSyncRepositoryProvider` 定义，并接受反向依赖。

无论选哪种，`fenceSyncRepositoryProvider` 必须被定义。

---

## 上轮遗留 P2 事项（不阻塞执行）

以下 P2 问题仍未修正，建议在实施过程中留意：

| # | 问题 | 建议 |
|---|------|------|
| 11 | `fence_type` 语义混淆（几何 vs 用途） | 实施时在 `CachedFenceData` 中添加文档注释区分 |
| 12 | 缓存/同步未考虑坐标转换 | 在 `FenceSyncRepositoryImpl` 中注明统一使用 WGS-84 |
| 13 | Task 7 Step 2 含后端 Java 代码 | 标注为"需 Plan A Task 配合"，或移除后端代码 |
| 14 | Task 3 无测试步骤 | 实施时补充离线写入 + banner 显示的 widget 测试 |

---

## 问题汇总

| 级别 | 来源 | 编号 | 概要 |
|------|------|------|------|
| P0 | 新引入 | 1 | `markReported` 方法多余右括号——语法错误 |
| P1 | 新引入 | 2 | Provider import 包名 `mobile_app` 应为 `smart_livestock_demo` |
| P1 | 新引入 | 3 | `fenceSyncRepositoryProvider` 被引用但从未定义 |
| P2 | 遗留 | 11-14 | fence_type 语义、坐标转换、后端代码、Task 3 测试 |

---

*复审生成时间: 2026-05-28*
