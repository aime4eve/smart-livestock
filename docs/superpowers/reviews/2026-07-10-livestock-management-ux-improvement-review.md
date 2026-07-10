# 畜牧管理前端体验优化 — 规格评审报告

> 评审日期: 2026-07-10 | 评审人: Claude Code  
> 规格文档: [2026-07-10-livestock-management-ux-improvement.md](../specs/2026-07-10-livestock-management-ux-improvement.md)

## 评审结论

**有条件通过**。规格文档整体方向正确，6 个改进项的业务价值清晰。但存在 1 个架构级问题、2 个数据准确性问题需要在实施前修正。

---

## 1. 严重问题（必须修正）

### 1.1 IoTCommandPort 放置位置违反 DDD 架构约定

**规格说**（§3, §8.1）:
```
iot/domain/port/IoTCommandPort.java       新建命令端口接口
iot/infrastructure/acl/IoTCommandPortImpl.java  实现
```

**实际架构约定**: 项目中所有跨上下文 Port 接口都定义在**调用方**限界上下文的 `domain/port/` 中，ACL 实现在同一上下文的 `infrastructure/acl/` 中。现有证据：

| Port | 定义位置 | 实现位置 |
|------|---------|---------|
| `IoTQueryPort` | `ranch/domain/port/IoTQueryPort.java` | `ranch/infrastructure/acl/IoTQueryPortImpl.java` |
| `IoTQueryPort` | `identity/domain/port/IoTQueryPort.java` | `identity/infrastructure/acl/IoTQueryPortImpl.java` |
| `RanchCommandPort` | `health/domain/port/RanchCommandPort.java` | `health/infrastructure/acl/RanchCommandPortImpl.java` |
| `RanchCommandPort` | `identity/domain/port/RanchCommandPort.java` | `identity/infrastructure/acl/RanchCommandPortImpl.java` |

**结论**: Port 接口**永远属于调用方上下文**，"谁调用，谁定义"是 DDD 防腐层的核心原则。将 `IoTCommandPort` 放在 `iot/` 上下文中会导致依赖方向错误（Ranch 需要知道 IoT 内部的包结构）。

**建议修正**:
```
ranch/domain/port/IoTCommandPort.java         新建（Ranch 上下文定义命令端口）
ranch/infrastructure/acl/IoTCommandPortImpl.java  新建（Ranch 上下文的 ACL 实现）
```

### 1.2 级联解绑时 `findActiveByLivestockId` 返回类型不足以支持"全部解绑"

**现状**: `InstallationRepository.findActiveByLivestockId(Long livestockId)` 返回 `Optional<Installation>`（单个）。但一头牲畜可以绑定**多个不同类型的设备**（如 GPS 追踪器 + 瘤胃胶囊），级联解绑需要找到**所有**活跃安装。

**证据**（`InstallationRepository.java:14`）:
```java
Optional<Installation> findActiveByLivestockId(Long livestockId);
```

**影响**: 规格 §3 的 `cascadeUninstallByLivestock(id)` 如果调用此方法，只能解绑第一个找到的设备，其他设备的安装记录会残留。这将导致 `deleteLivestock` 时抛出 `STATE_CONFLICT`（因为 `hasActiveInstallationByLivestock` 仍会返回 true）。

**建议修正**: 在 `InstallationRepository` 中新增方法：
```java
List<Installation> findAllActiveByLivestockId(Long livestockId);
```
并在 `SpringDataInstallationRepository` 中添加对应的 JPQL 查询：
```java
@Query("SELECT i FROM InstallationJpaEntity i WHERE i.livestockId = :livestockId AND i.removedAt IS NULL")
List<InstallationJpaEntity> findAllActiveByLivestockId(@Param("livestockId") Long livestockId);
```

---

## 2. 中等问题（建议修正）

### 2.1 改进项 6 文件清单有 3 个虚假文件 + 3 个遗漏

**规格清单中有但实际不需要修改的文件（3 个）**:

| 规格列出的文件 | 实际情况 |
|---------------|---------|
| `features/livestock/presentation/livestock_controller.dart` | 文件中**无任何 `earTag` 引用**，无需修改 |
| `features/ranch/presentation/widgets/livestock_detail_sheet.dart` | 已使用 `marker.livestockCode`，**无需修改** |
| `features/ranch/presentation/widgets/livestock_map_marker.dart` | 已使用 `widget.livestockCode`（第 28/35/84 行），**无需修改** |

**实际需要但规格遗漏的文件（3 个）**:

| 遗漏的文件 | `earTag` 使用情况 |
|-----------|------------------|
| `features/livestock/domain/livestock_repository.dart` | `LivestockSummary` 类有 `final String earTag` 字段声明 |
| `features/alerts/domain/alerts_repository.dart` | `AlertItem` 类有 `final String earTag` 字段声明 |
| `core/l10n/enum_labels.dart` | `DeviceType.earTag` 映射到 `l10n.earTagLabel`（需确认 i18n key 是否同步修改） |

> **注**: 规格提到了 `enum_labels.dart`（§7 "i18n 层"小节），但未列入影响文件清单（§7 的列表只列了 `app_en.arb`）。

**建议**: 删除 3 个虚假文件，补充 3 个遗漏文件，最终清单仍为 18 个文件。

### 2.2 `DeviceItem.boundEarTag` 被遗漏

规格 §7 提到 `DeviceItem` 含 `earTag`，但实际字段名是 `boundEarTag`（`core_models.dart:139`）。该字段语义为"绑定的牲畜编号"，应在改进项 6 中一并考虑是否重命名为 `boundLivestockCode`。

**影响范围**: `boundEarTag` 在以下文件中被引用：
- `devices_page.dart` — 列表渲染 livestock label
- `devices_api_repository.dart` — 解析 `boundEarTag` JSON key（注意：后端 API 返回的 JSON key 仍需确认是 `boundEarTag` 还是 `livestockCode`）
- `device_form_sheet.dart` — 表单回显

**建议**: 在改进项 6 中明确列出 `boundEarTag` → `boundLivestockCode` 的重命名，并确认后端 API 返回的 JSON 字段名是否需要同步调整。

### 2.3 `AlertItem.earTag` 实际存储的是 `livestockId`

`alerts_api_repository.dart:88`:
```dart
earTag: livestockId ?? '-',
```

`AlertItem` 的 `earTag` 字段（`alerts_repository.dart:43`）被赋值为 `livestockId`（数字 ID），而非牲畜编号字符串。这是一个**已有的语义 bug**——字段名暗示内容为耳标号，实际内容为 livestock ID。

**建议**: 重命名 `earTag` → `livestockCode` 时，确认此处的赋值语义。如果告警列表需要展示牲畜编号，应从 API 返回的 `livestockCode` 字段取值，而非 `livestockId`。需要与后端确认告警 API 是否已返回 `livestockCode`。

---

## 3. 轻微问题（建议关注）

### 3.1 改进项 5 边界情况处理不完整

| 场景 | 规格处理 | 建议补充 |
|------|---------|---------|
| 牲畜未分配围栏（`fenceId = null`） | 未提及 | 不绘制围栏边界虚线，仅展示轨迹 |
| GPS 数据超过 500 点 | "降采样"（未指定算法） | 建议用 Ramer–Douglas–Peucker 或均匀采样到 500 点 |
| 时间范围内无 GPS 数据 | 显示空状态 | 已覆盖，OK |
| 无活跃设备绑定 | 按钮置灰 | 已覆盖，OK |
| `Geolocator.distanceBetween` 依赖 | 未确认是否存在 | 需验证 `pubspec.yaml` 中是否已有 `geolocator` 依赖 |

### 3.2 改进项 4 设备筛选规则的前端预判 vs 后端防线

规格描述了前端预判规则（§5 表格），但后端 `install()` 的校验条件是：
1. `device.getStatus() == ACTIVE` — 前端预判一致 ✓
2. 设备未被其他牲畜安装 — 前端预判一致 ✓
3. 同类型已绑定 → 拒绝 — 前端预判一致 ✓

**但有一个遗漏**: 后端**不校验 livestock 是否存在**。如果前端传入一个不存在的 `livestockId`，安装会成功创建，产生孤儿安装记录。虽然前端不会主动传错误 ID，但作为后端防线应该补上（非本次范围，可单独提 issue）。

### 3.3 `LivestockDto` 是 Java record，新增 `List<DeviceBrief>` 需要注意

Java record 的 canonical constructor 会要求所有字段。规格建议 `List<DeviceBrief> devices` 默认空列表，实现方式：
- 方式 A: 自定义 compact constructor 设置默认值 `this.devices = devices == null ? List.of() : devices;`
- 方式 B: 保持现有 `LivestockDto.from(Livestock)` 工厂方法不变，在 `listByFarm` 中通过 `copyWith` 或 Builder 填充

建议在规格中明确采用哪种方式，避免实施时犹豫。

### 3.4 改进项 3 的 route 参数修正不够彻底

规格说路由参数 `earTag` → `livestockId`。但查看当前代码：

```dart
// app_router.dart:267-268
final earTag = state.uri.pathSegments.last;
return LivestockDetailPage(earTag: earTag);
```

以及列表页的导航：
```dart
// livestock_list_page.dart
context.go('/livestock/${item.id}');  // 传的是数字 ID
```

这说明 URL 中的 path segment 实际就是 `livestockId`，`earTag` 一直是错误命名。修正方案正确，但还需要确认 `LivestockDetailPage` 内部使用这个参数时——目前它作为 API 查询参数传给 `loadDetail(id)`，参数名叫 `earTag` 但值是数字 ID。改名后会减少混淆。

---

## 4. 规格质量评价

### 优点
- 设计原则明确（不引入新表、API 向后兼容、历史数据保留）
- 跨上下文数据流图清晰
- 每个改进项都有"现状→方案→不做的"结构
- 业务流程图（改进项 2 的级联确认流程）易懂
- 验收标准可验证且具体

### 可改进
- 改进项 6 的文件清单应基于 `grep -rn "earTag"` 的精确结果，而非手工枚举
- 改进项 1 的 `IoTQueryPort.findActiveDevicesByLivestockIds` 应考虑空列表的返回（空 Map vs 包含所有 key 的 Map，每个 value 为空列表）
- 实施计划中缺失**测试更新**步骤——所有后端/前端改动后应该运行测试确认无回归
- 改进项 5 的 `Geolocator.distanceBetween` 可能需要新增依赖，应在实施计划中列出

---

## 5. 修正汇总

| # | 问题 | 严重度 | 修正建议 |
|---|------|--------|---------|
| 1 | IoTCommandPort 放置位置错误 | 🔴 严重 | 改为 `ranch/domain/port/IoTCommandPort.java` + `ranch/infrastructure/acl/IoTCommandPortImpl.java` |
| 2 | InstallationRepository 缺少 `findAllActiveByLivestockId` | 🔴 严重 | 新增返回 `List<Installation>` 的查询方法 |
| 3 | 改进项 6 文件清单有 3 个虚假 + 3 个遗漏 | 🟡 中等 | 删除不存在引用的文件，补充遗漏文件 |
| 4 | `DeviceItem.boundEarTag` 被遗漏 | 🟡 中等 | 纳入重命名范围 |
| 5 | `AlertItem.earTag` 赋值语义错误 | 🟡 中等 | 重命名时确认赋值源 |
| 6 | 改进项 5 边界情况不完整 | 🟢 轻微 | 补充无围栏、降采样算法说明 |
| 7 | `Geolocator` 依赖未确认 | 🟢 轻微 | 确认 pubspec.yaml |
| 8 | 实施计划缺失测试步骤 | 🟢 轻微 | 每步增加测试验证 |
| 9 | `LivestockDto` record 默认值策略未明确 | 🟢 轻微 | 明确使用 compact constructor |

---

## 6. 附录：代码验证数据

### 后端关键文件验证

| 检查项 | 规格声称 | 实际代码 | 匹配 |
|--------|---------|---------|------|
| `LivestockDto` 无 `devices` 字段 | ✓ | 15 字段 record，无 devices | ✅ |
| `listByFarm` 无设备富化 | ✓ | 仅 `LivestockDto::from` 映射 | ✅ |
| `deleteLivestock` 检查活跃安装 | ✓ | `iotQueryPort.hasActiveInstallationByLivestock(id)` | ✅ |
| Livestock 有 `deletedAt` 软删除 | ✓ | JPA Entity 有，`deleteById` 设 `deletedAt` | ✅ |
| Installation 有 `removedAt` | ✓ | Domain entity 有 `remove()` / `isActive()` | ✅ |
| `DeviceStatus` 枚举值 | INVENTORY/ACTIVE/OFFLINE/DECOMMISSIONED | 完全一致 | ✅ |
| `IoTCommandPort` 不存在 | ✓ | 代码库无此接口 | ✅ |
| `InstallationRepository.findActiveByLivestockId` | 存在 | 返回 `Optional<Installation>`（单数） | ⚠️ 签名不足 |

### 前端关键文件验证

| 检查项 | 规格声称 | 实际代码 | 匹配 |
|--------|---------|---------|------|
| 模型字段名 `earTag` | ✓ | `core_models.dart` 多处 `earTag` | ✅ |
| 详情页返回 fallback 到 twin | ✓ | `context.go(AppRoute.twin.path)` | ✅ |
| 路由参数取 `pathSegments.last` 命名为 `earTag` | ✓ | `app_router.dart:267` | ✅ |
| 列表页无设备 badge | ✓ | 仅 `ListTile` 显示 earTag + breed | ✅ |
| `_BindDeviceSheet` 仅过滤已安装设备 | ⚠️ "加载所有设备，过滤已安装" | 实际：过滤已安装到**当前牲畜**的设备，未过滤已安装到其他牲畜的、未按状态过滤 | ⚠️ 不完全 |
| 轨迹按钮跳转围栏页 | ✓ | `context.go(AppRoute.fence.path)` | ✅ |
| `livestock_api_repository` 有 `?? m['earTag']` fallback | ✓ | `m['livestockCode'] ?? m['earTag']` | ✅ |
| `trajectory_sheet.dart` 不存在 | ✓ | 不存在 | ✅ |
| `.earTag` 引用文件数 ~18 | 声称 18 个 | 实际 18 个包含 `earTag` 的 Dart 文件，但清单组成有误 | ⚠️ 数量巧合 |

### 改进项 6 实际需要修改的文件（基于 grep 精确结果）

1. `core/models/core_models.dart` — `LivestockInfo.earTag`, `LivestockDetail.earTag`, `AlertItem.earTag`, `DeviceItem.boundEarTag`
2. `core/l10n/enum_labels.dart` — `DeviceType.earTag` label 映射
3. `app/app_router.dart` — route 参数 `earTag` → `livestockId`
4. `features/livestock/domain/livestock_repository.dart` — `LivestockSummary.earTag`
5. `features/livestock/data/livestock_api_repository.dart` — 解析 `m['earTag']` fallback
6. `features/livestock/data/map_api_repository.dart` — `earTag` 字段
7. `features/livestock/presentation/widgets/livestock_form_sheet.dart` — `existing?.earTag`
8. `features/alerts/domain/alerts_repository.dart` — `AlertItem.earTag`
9. `features/alerts/data/alerts_api_repository.dart` — `earTag: livestockId ?? '-'`
10. `features/devices/data/devices_api_repository.dart` — `DeviceType.earTag` 枚举映射
11. `features/devices/presentation/widgets/device_form_sheet.dart` — 设备表单
12. `features/devices/presentation/widgets/device_health_card.dart` — 设备健康卡片
13. `features/highfi/widgets/highfi_device_tile.dart` — 设备 tile
14. `features/fence/presentation/fence_controller.dart` — `earTag: m['livestockCode']`
15. `features/pages/livestock_list_page.dart` — 列表渲染
16. `features/pages/livestock_detail_page.dart` — 详情页 + `_BindDeviceSheet`
17. `features/pages/devices_page.dart` — 设备页 `boundEarTag`
18. `features/pages/fence_page.dart` — 围栏页

**删除（不在实际影响范围内）**:
- ~~`features/livestock/presentation/livestock_controller.dart`~~ — 无 earTag 引用
- ~~`features/ranch/presentation/widgets/livestock_detail_sheet.dart`~~ — 已使用 `livestockCode`
- ~~`features/ranch/presentation/widgets/livestock_map_marker.dart`~~ — 已使用 `livestockCode`
