# 畜牧管理前端体验优化

> 版本: 1.1 | 日期: 2026-07-10 | 状态: 评审已通过，待实施  
> 高保真原型: [docs/features/livestock-management-ux-v2.html](../features/livestock-management-ux-v2.html)  
> 评审报告: [docs/superpowers/reviews/2026-07-10-livestock-management-ux-improvement-review.md](../reviews/2026-07-10-livestock-management-ux-improvement-review.md)  
> 变更: v1.1 修正评审发现的 9 项问题（IoTCommandPort 路径、InstallationRepository 签名、文件清单纠正、boundEarTag、AlertItem 语义 bug 等）

## 1. 概述

畜牧管理是牧场主日常使用频率最高的模块之一。当前实现基本可用，但在信息密度、操作完整性、业务逻辑闭环上存在改进空间。本文档定义 6 个改进项的设计方案，覆盖前端 UI、后端 API 调整和业务逻辑补全。

### 改进项总览

| # | 改进项 | 层级 | 复杂度 |
|---|--------|------|--------|
| 1 | 列表页卡片展示已绑定设备编号 | 后端 DTO + 前端 | 中 |
| 2 | 删除畜牧级联逻辑（先解绑设备再软删除） | 后端 + 前端 | 中 |
| 3 | 详情页返回正确回到列表页 | 前端 | 低 |
| 4 | 绑定设备校验规则完善 | 前端为主 | 中 |
| 5 | 查看完整轨迹（轨迹地图 sheet） | 前端为主 | 中 |
| 6 | "耳标号"统一改为"编号" | 前端模型重命名 | 中（影响面广） |

### 设计原则

- **不引入新表**：所有改进复用现有 `livestock`、`installations`、`devices`、`gps_logs` 表结构
- **API 向后兼容**：新增字段为可选，不破坏现有消费方
- **历史数据只读归档**：删除牲畜时不删除已产生的健康/告警/GPS 数据，保证审计可追溯
- **前端模型语义对齐**：`earTag` → `livestockCode`，与后端字段名统一
- **Port 接口归调用方**：跨上下文命令/查询端口定义在调用方限界上下文的 `domain/port/` 中，遵循 DDD 防腐层"谁调用谁定义"原则

### 跨上下文数据流

```
Livestock (Ranch)
  ├── installations (IoT) → devices.dev_eui, devices.device_code
  ├── alerts (Ranch) → 引用 livestock_id
  ├── temperature_logs / rumen_motility_logs (Health) → 引用 livestock_id
  └── gps_logs (IoT) → installations.device_id → gps_logs
```

---

## 2. 改进项 1：列表页展示设备编号

### 现状

`GET /api/v1/farms/{farmId}/livestock` 返回 `LivestockDto`，只含牲畜自身字段（编号、品种、性别等），不含设备信息。前端列表卡片也未展示设备。

### 方案

#### 后端

`LivestockDto` 新增可选字段：

```java
public record DeviceBrief(
    Long deviceId,
    String deviceCode,
    String devEui,
    String deviceType   // GPS / CAPSULE / EAR_TAG
) {}
```

`LivestockDto` 增加 `List<DeviceBrief> devices` 字段。因 `LivestockDto` 是 Java record，通过 compact canonical constructor 设置默认值：

```java
public LivestockDto(
    Long id, Long farmId, String livestockCode, /* ...existing fields... */
    List<DeviceBrief> devices
) {
    // ...existing assignments...
    this.devices = devices == null ? List.of() : devices;
}
```

现有 `LivestockDto.from(Livestock)` 工厂方法保持不变（`devices` 传 `List.of()`），`listByFarm` 填充设备后重新构建 DTO。

`LivestockApplicationService.listByFarm()` 在返回结果时批量查询设备：
1. 取出当前页所有 `livestockId`
2. 调用 `InstallationApplicationService.findByLivestockIds(ids)` 一次批量查活跃安装
3. 按 `deviceId` 批量查 `Device` 获取 `deviceCode` / `devEui` / `deviceType`
4. 组装到各 `LivestockDto.devices`

为避免 N+1 查询，`IoTQueryPort` 新增方法：

```java
/**
 * Batch query active devices for multiple livestock.
 * @param livestockIds 要查询的牲畜 ID 列表（允许空列表）
 * @return Map: livestockId -> List<DeviceBrief>；
 *         输入为空列表时返回空 Map；
 *         无设备的牲畜 key 不出现在 Map 中（调用方按空列表兜底）
 */
Map<Long, List<DeviceBrief>> findActiveDevicesByLivestockIds(List<Long> livestockIds);
```

#### 前端

`LivestockSummary` 增加 `List<String> deviceCodes` 字段。

列表卡片在品种/月龄/体重行下方，渲染设备 badge：

- 有设备：蓝色标签显示 `deviceCode`（如 `SN-TRK-00001`），多个设备横向排列
- 无设备：灰色斜体文字"未绑定设备"

### 不做的

- 不在列表页展示 DevEUI（太长，留给详情页）
- 不做实时设备在线状态刷新（列表页关注牲畜，不关注设备心跳）

---

## 3. 改进项 2：删除畜牧级联逻辑

### 现状

`LivestockApplicationService.deleteLivestock()` 在检测到活跃安装时直接抛 `STATE_CONFLICT` 拒绝删除。前端无删除入口。

### 方案

#### 业务流程

```
用户点击删除
  ↓
前端 GET /livestock/{id} → 检查是否有绑定的设备
  ↓
├── 无设备 → 简单确认弹窗 → DELETE /livestock/{id}
│
└── 有设备 → 详细确认弹窗，列出级联影响：
      • 设备 SN-TRK-00002 将自动解绑（变为待安装状态）
      • 瘤胃胶囊 RC-00231 将自动解绑
      • 历史健康数据/告警记录将保留（只读归档）
      • GPS 轨迹历史将保留（只读归档）
    → DELETE /livestock/{id}（后端事务内先解绑再删除）
```

#### 后端改动

`LivestockApplicationService.deleteLivestock()` 改为：

```java
@Transactional
public void deleteLivestock(Long id) {
    Livestock livestock = livestockRepository.findById(id)
        .orElseThrow(() -> ...);
    // 级联解绑：将所有活跃 installation 设 removedAt
    cascadeUninstallByLivestock(id);
    // 软删除牲畜
    livestockRepository.deleteById(id);
}

private void cascadeUninstallByLivestock(Long livestockId) {
    // 调用 IoT 上下文批量解绑（通过 Ranch 上下文的命令端口）
    iotCommandPort.removeAllActiveInstallations(livestockId);
}
```

**命令端口定义在调用方（Ranch）上下文**，遵循 DDD 防腐层原则：

```
ranch/domain/port/IoTCommandPort.java         ← Ranch 上下文定义命令端口
ranch/infrastructure/acl/IoTCommandPortImpl.java  ← Ranch 上下文的 ACL 实现，注入 IoT 的 InstallationRepository
```

```java
// ranch/domain/port/IoTCommandPort.java
public interface IoTCommandPort {
    /**
     * Remove all active installations for a livestock.
     * Used during livestock deletion cascade.
     */
    void removeAllActiveInstallations(Long livestockId);
}
```

> **依赖方向说明**：Port 接口和 Impl 都在 `ranch` 包下。Impl 通过 Spring 注入 `iot.domain.repository.InstallationRepository`，将防腐层的依赖反转集中在 Impl 类中，Ranch 的 domain/application 层只依赖自己上下文的 Port 接口。

#### InstallationRepository 签名补充

现有 `InstallationRepository.findActiveByLivestockId(Long)` 返回 `Optional<Installation>`（单数），无法满足级联解绑"找到全部活跃安装"的需求。新增方法：

```java
// InstallationRepository.java
List<Installation> findAllActiveByLivestockId(Long livestockId);
```

```java
// SpringDataInstallationRepository.java
@Query("SELECT i FROM InstallationJpaEntity i WHERE i.livestockId = :livestockId AND i.removedAt IS NULL")
List<InstallationJpaEntity> findAllActiveByLivestockId(@Param("livestockId") Long livestockId);
```

`IoTCommandPortImpl.removeAllActiveInstallations()` 使用此方法获取全部活跃安装记录，逐条调用 `installation.remove()`。

#### 数据保留策略

删除牲畜后，以下数据**保留不动**（通过 `livestock_id` 仍可查询，但牲畜记录已 `deleted_at`）：

| 数据表 | 保留原因 |
|--------|---------|
| `temperature_logs` | 健康历史归档，可用于群体疫病分析 |
| `rumen_motility_logs` | 同上 |
| `activity_logs` | 同上 |
| `alerts` | 告警审计记录 |
| `gps_logs` | 轨迹历史 |
| `estrus_scores` | 发情记录归档 |

前端在查看已删除牲畜的历史数据时，显示"该牲畜已移除"标记。

#### 前端改动

详情页 AppBar 新增删除按钮（红色垃圾桶图标），点击后：

1. 先检查 `detail.devices` 是否为空
2. 无设备 → 简单确认弹窗
3. 有设备 → 详细确认弹窗，逐条列出将解绑的设备 + 数据归档说明
4. 确认后调 `DELETE`，成功后 `context.go('/livestock')` 返回列表并刷新

---

## 4. 改进项 3：详情页返回列表页

### 现状

```dart
// livestock_detail_page.dart
leading: IconButton(
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoute.twin.path);  // ← 不合理 fallback
    }
  },
```

当详情页是深层入口（如从告警跳转）时，`canPop()` 为 false，fallback 到了数智孪生页而非列表页。

路由参数命名也有问题：`app_router.dart` 中 `final earTag = state.uri.pathSegments.last` 取的是 URL path segment，实际值是 `livestockId`（数字 ID），但变量名叫 `earTag`。

### 方案

将 fallback 改为 `AppRoute.livestockList.path`：

```dart
onPressed: () {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoute.livestockList.path);
  }
},
```

路由参数名改为 `livestockId`（配合改进项 6 一并修正）：

```dart
// app_router.dart
builder: (context, state) {
  final livestockId = state.uri.pathSegments.last;
  return LivestockDetailPage(livestockId: livestockId);
},
```

---

## 5. 改进项 4：绑定设备校验规则完善

### 现状

`_BindDeviceSheet._loadDevices()` 的过滤逻辑为：

```dart
final installedDeviceIds = installed
    .where((i) => i.livestockId == widget.livestockId && i.installedAt.isNotEmpty)
    .map((i) => i.deviceId)
    .toSet();
_devices = data.items.where((d) => !installedDeviceIds.contains(d.id)).toList();
```

只过滤了安装到**当前牲畜**的设备，未过滤安装到其他牲畜的设备，也未按设备状态过滤。

### 方案

#### 设备筛选规则

绑定设备 sheet 中，设备列表按以下规则展示：

| 条件 | 展示 | 可选 |
|------|------|------|
| `status = ACTIVE` 且未被任何牲畜绑定 | 正常显示 | 可选 |
| `status = ACTIVE` 但同类型已绑定到当前牲畜 | 灰色 + 黄色警告"同类型已绑定" | 不可选 |
| `status = INVENTORY` | 灰色 + "未激活（需先在设备管理激活）" | 不可选 |
| `status = OFFLINE / DECOMMISSIONED` | 不显示 | — |
| 已被其他牲畜绑定 | 不显示 | — |

#### 后端配合

后端 `InstallationApplicationService.install()` 已有完整校验链：
1. 设备必须 `ACTIVE` 状态
2. 设备未被其他牲畜安装（`findActiveByDeviceId`）
3. 同一头牲畜不能安装同类型设备（`findActiveByLivestockIdAndDeviceType`）

前端提前做规则 2 和 3 的预判（灰色禁用），后端做最终防线。

> **注意**：后端 `install()` 不校验 livestock 是否存在。如果前端传入不存在的 `livestockId`，安装会成功创建孤儿记录。此问题非本次范围，单独提 issue 跟踪。

#### 前端改动

`_BindDeviceSheet` 改为：

1. 加载设备时同时加载所有安装记录（而非只过滤当前牲畜的）
2. 已被任何牲畜安装的设备直接排除
3. 对剩余设备判断：是否与当前牲畜已绑设备类型冲突
4. 展示 `deviceCode` + `devEui` + 设备类型标签 + 状态点
5. 选中高亮，底部"确认绑定"按钮

---

## 6. 改进项 5：查看完整轨迹

### 现状

"查看完整轨迹"按钮直接跳转到围栏管理页面（`AppRoute.fence.path`），与该牲畜的轨迹无关。

### 方案

#### API（已存在，无需改动）

```
GET /api/v1/farms/{farmId}/livestock/{livestockId}/gps-logs
  ?startTime=2026-07-09T00:00:00Z
  &endTime=2026-07-10T00:00:00Z
  &page=1&pageSize=500
```

返回 `{ items: [{ latitude, longitude, recorded_at, ... }], total }`。

#### 前端改动

点击"查看完整轨迹"弹出 bottom sheet（而非跳转页面）：

**轨迹 sheet 布局**：

```
┌─────────────────────────────────┐
│  SL-2024-002 移动轨迹           │
│                                 │
│  [24小时] [7天] [30天]          │  ← 时间范围切换
│                                 │
│  ┌─────────────────────────┐    │
│  │                         │    │
│  │   flutter_map 地图       │    │  ← 围栏边界（虚线）+ 轨迹折线
│  │   • 起点 → ••• → 当前位置│    │     起点标记 + 当前位置脉冲
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  轨迹点数: 142  距离: 3.2km     │  ← 统计摘要
│  活动范围: 0.8 km²              │
│                                 │
│  [关闭]                         │
└─────────────────────────────────┘
```

**实现要点**：

- 时间范围切换默认 24 小时，切换后重新请求 API
- `Polyline` 绘制轨迹路径，颜色用 `AppColors.primary`
- 叠加该牲畜所在围栏的 `Polygon`（虚线边界）；牲畜无围栏（`fenceId` 为空）时仅展示轨迹，不画围栏边界
- 起点（绿色圆点）+ 当前位置（主题色脉冲圆点）
- `pageSize=500` 避免频繁分页；如果超过 500 点用均匀采样（每 N 个取 1 个）降采样到 500 点以内
- 无 GPS 数据时显示空状态"暂无轨迹数据"
- 无活跃设备绑定时按钮置灰（`disabled`），tooltip 提示"请先绑定 GPS 设备"

#### 距离计算

当前 `pubspec.yaml` 中无 `geolocator` 依赖。不新增依赖，自行实现 Haversine 公式：

```dart
// core/utils/geo_utils.dart (新建)
import 'dart:math';

/// Haversine distance between two coordinates in meters.
double haversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0; // Earth radius in meters
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * pi / 180;

/// Total distance of a GPS path in meters.
double totalPathDistance(List<({double lat, double lng})> points) {
  double dist = 0;
  for (int i = 1; i < points.length; i++) {
    dist += haversineDistance(
      points[i - 1].lat, points[i - 1].lng,
      points[i].lat, points[i].lng,
    );
  }
  return dist;
}
```

---

## 7. 改进项 6："耳标号" → "编号" 统一

### 现状

- `app_zh.arb` 中 `livestockFormFieldCode` 已是 `"编号"`，`livestockSearchHint` 已是 `"搜索编号或品种"` — i18n 层已正确
- 但 Dart 代码中模型字段名仍叫 `earTag`，与后端字段名 `livestockCode` 不一致

### 方案

#### 模型层重命名

`core_models.dart`：

```dart
// Before
class LivestockSummary {
  final String earTag;
}
class LivestockDetail {
  final String earTag;
}

// After
class LivestockSummary {
  final String livestockCode;
}
class LivestockDetail {
  final String livestockCode;
}
```

同时处理 `DeviceItem.boundEarTag`（字段语义为"绑定的牲畜编号"）：

```dart
// Before
class DeviceItem {
  final String boundEarTag;
}

// After
class DeviceItem {
  final String boundLivestockCode;
}
```

#### 已有语义 bug 修正

`AlertItem.earTag`（`alerts_repository.dart:43`）当前被赋值为 `livestockId`（数字 ID），而非牲畜编号字符串：

```dart
// alerts_api_repository.dart:88 — Before
earTag: livestockId ?? '-',

// After — 字段重命名为 livestockCode，从正确的 API 字段取值
livestockCode: item['livestockCode'] as String? ?? '-',
```

需确认告警 API 返回的 JSON 中是否包含 `livestockCode` 字段。如果不包含，需要后端在告警 DTO 中补充。

#### 影响文件清单（基于 grep 精确验证，18 个文件）

> 以下清单基于 `rg "earTag" Mobile/mobile_app/lib/ -t dart -l` 的精确结果，排除 `DeviceType.earTag` 枚举值（不改名）。

**模型层**：
1. `core/models/core_models.dart` — `LivestockSummary.earTag` → `livestockCode`；`LivestockDetail.earTag` → `livestockCode`；`AlertItem.earTag` → `livestockCode`；`DeviceItem.boundEarTag` → `boundLivestockCode`

**Domain 层**：
2. `features/livestock/domain/livestock_repository.dart` — `LivestockSummary.earTag` 字段声明
3. `features/alerts/domain/alerts_repository.dart` — `AlertItem.earTag` 字段声明

**Repository 层**：
4. `features/livestock/data/livestock_api_repository.dart` — 解析逻辑统一为 `m['livestockCode']`，移除 `?? m['earTag']` fallback
5. `features/livestock/data/map_api_repository.dart` — `earTag` 字段解析
6. `features/devices/data/devices_api_repository.dart` — `boundEarTag` JSON key 解析（确认后端返回的 key 是否需同步调整）
7. `features/alerts/data/alerts_api_repository.dart` — `earTag: livestockId ?? '-'` 修正为正确的赋值源

**Presentation 层**：
8. `features/pages/livestock_list_page.dart` — `item.earTag` → `item.livestockCode`
9. `features/pages/livestock_detail_page.dart` — `detail.earTag` → `detail.livestockCode`；`LivestockDetailPage.earTag` 参数名 → `livestockId`
10. `features/livestock/presentation/widgets/livestock_form_sheet.dart` — `widget.existing?.earTag` → `widget.existing?.livestockCode`
11. `features/devices/presentation/widgets/device_form_sheet.dart` — `DeviceType.earTag` 引用（不改名，但需确认 `l10n.deviceTypeEarTag` 文案不变）
12. `features/devices/presentation/widgets/device_health_card.dart` — 同上
13. `features/highfi/widgets/highfi_device_tile.dart` — `device.boundEarTag` → `device.boundLivestockCode`
14. `features/pages/devices_page.dart` — `device.copyWith(boundEarTag: ...)` → `boundLivestockCode`
15. `features/pages/fence_page.dart` — `earTag` 引用
16. `features/fence/presentation/fence_controller.dart` — `earTag: m['livestockCode']` → `livestockCode: m['livestockCode']`

**路由层**：
17. `app/app_router.dart` — `livestockDetail` 路由参数名 `earTag` → `livestockId`

**i18n 层**：
18. `core/l10n/enum_labels.dart` — `DeviceType.earTag` case 分支（枚举值不改，label 映射不变）

> **注意**：`DeviceType.earTag` 是设备类型枚举值（耳标式设备），与牲畜编号无关，**不改名**。涉及该枚举值的文件（`device_form_sheet.dart`、`device_health_card.dart`、`enum_labels.dart`）仅需确认无混淆，不需要修改。

#### 重命名策略

使用全局搜索替换：
- `\.earTag` → `\.livestockCode`（LivestockSummary / LivestockDetail / AlertItem 场景）
- `\.boundEarTag` → `\.boundLivestockCode`（DeviceItem 场景）
- `earTag:` → `livestockCode:`（命名参数/JSON key 场景）

然后逐文件检查上下文，排除 `DeviceType.earTag` 枚举值引用。

---

## 8. 实施计划

### 8.1 后端改动

| 文件 | 改动 |
|------|------|
| `ranch/domain/port/dto/DeviceBrief.java` | 新建 DTO record |
| `ranch/domain/port/IoTQueryPort.java` | 新增 `findActiveDevicesByLivestockIds` |
| `ranch/domain/port/IoTCommandPort.java` | 新建命令端口接口（Ranch 上下文定义） |
| `ranch/infrastructure/acl/IoTQueryPortImpl.java` | 实现批量查询 |
| `ranch/infrastructure/acl/IoTCommandPortImpl.java` | 实现 `removeAllActiveInstallations`（注入 IoT 的 InstallationRepository） |
| `ranch/application/dto/LivestockDto.java` | 增加 `devices` 字段 + compact constructor 默认值 |
| `ranch/application/LivestockApplicationService.java` | `listByFarm` 填充 devices；`deleteLivestock` 改为级联解绑 |
| `iot/domain/repository/InstallationRepository.java` | 新增 `findAllActiveByLivestockId` |
| `iot/infrastructure/persistence/SpringDataInstallationRepository.java` | 新增对应 JPQL 查询 |
| `iot/infrastructure/persistence/JpaInstallationRepositoryImpl.java` | 实现 `findAllActiveByLivestockId` |

### 8.2 前端改动

| 文件 | 改动 |
|------|------|
| `core/models/core_models.dart` | `earTag` → `livestockCode`；`boundEarTag` → `boundLivestockCode`；新增 `deviceCodes` |
| `core/utils/geo_utils.dart` | 新建 Haversine 距离计算工具 |
| `features/livestock/data/livestock_api_repository.dart` | 解析 devices 字段 + 字段名对齐 |
| `features/livestock/domain/livestock_repository.dart` | 字段名对齐 |
| `features/pages/livestock_list_page.dart` | 卡片展示设备 badge + 删除入口 |
| `features/pages/livestock_detail_page.dart` | 返回修正 + 编辑/删除按钮 + 轨迹 sheet + `_BindDeviceSheet` 过滤完善 |
| `features/livestock/presentation/widgets/livestock_form_sheet.dart` | 字段名对齐 |
| `features/livestock/presentation/widgets/trajectory_sheet.dart` | 新建轨迹组件 |
| `features/alerts/data/alerts_api_repository.dart` | `earTag` → `livestockCode` + 赋值源修正 |
| `features/alerts/domain/alerts_repository.dart` | 字段名对齐 |
| `features/devices/data/devices_api_repository.dart` | `boundEarTag` → `boundLivestockCode` |
| `features/devices/presentation/widgets/device_form_sheet.dart` | 确认无需修改（仅 DeviceType.earTag） |
| `features/devices/presentation/widgets/device_health_card.dart` | 确认无需修改（仅 DeviceType.earTag） |
| `features/highfi/widgets/highfi_device_tile.dart` | `boundEarTag` → `boundLivestockCode` |
| `features/pages/devices_page.dart` | `boundEarTag` → `boundLivestockCode` |
| `features/pages/fence_page.dart` | 字段名对齐 |
| `features/fence/presentation/fence_controller.dart` | 字段名对齐 |
| `features/livestock/data/map_api_repository.dart` | 字段名对齐 |
| `app/app_router.dart` | 路由参数名 `earTag` → `livestockId` |
| `core/l10n/enum_labels.dart` | 确认无需修改（DeviceType.earTag label 不变） |
| `l10n/app_en.arb` | 确认英文翻译一致 |

### 8.3 实施顺序

```
Step 1: 后端 — DeviceBrief + IoTQueryPort 批量查询 + LivestockDto (改进 1)
  → 验证: ./gradlew compileJava
  → 测试: ./gradlew test --tests "*.ranch.*"

Step 2: 后端 — InstallationRepository.findAllActiveByLivestockId + IoTCommandPort + 删除级联 (改进 2)
  → 验证: ./gradlew compileJava
  → 测试: ./gradlew test --tests "*.ranch.*" --tests "*.iot.*"

Step 3: 前端 — earTag → livestockCode / boundEarTag → boundLivestockCode 全局重命名 (改进 6)
  → 验证: flutter analyze
  → 测试: flutter test

Step 4: 前端 — 列表页设备 badge 展示 (改进 1)
  → 验证: flutter analyze

Step 5: 前端 — 详情页返回修正 + 编辑/删除按钮 (改进 3)
  → 验证: flutter analyze

Step 6: 前端 — 删除确认弹窗 + 级联提示 (改进 2)
  → 验证: flutter analyze

Step 7: 前端 — 绑定设备校验完善 (改进 4)
  → 验证: flutter analyze

Step 8: 前端 — 轨迹 sheet + geo_utils (改进 5)
  → 验证: flutter analyze + 手动验证
```

---

## 9. 验收标准

| # | 验收项 | 验证方式 |
|---|--------|---------|
| 1.1 | 列表页卡片底部展示已绑定设备的 deviceCode | 部署后 curl + 前端查看 |
| 1.2 | 无设备的牲畜显示"未绑定设备" | 前端查看 |
| 1.3 | API 返回的 `devices` 字段为空列表而非 null | curl 验证 |
| 2.1 | 删除有设备的牲畜时弹出级联确认弹窗 | 前端操作 |
| 2.2 | 确认删除后所有活跃 installation 的 removedAt 被设置 | 数据库验证 |
| 2.3 | 删除后历史数据（health/alert/gps）仍存在 | 数据库验证 |
| 3.1 | 详情页返回箭头回到列表页 | 前端操作 |
| 4.1 | 绑定设备列表只显示 ACTIVE 且未被任何牲畜绑定的设备 | 前端操作 |
| 4.2 | 同类型已绑定时灰色不可选 | 前端操作 |
| 5.1 | 轨迹 sheet 展示路径 + 围栏（有围栏时）+ 统计 | 前端操作 |
| 5.2 | 无 GPS 设备时按钮置灰 | 前端操作 |
| 5.3 | 无围栏的牲畜仅展示轨迹，不报错 | 前端操作 |
| 5.4 | 超过 500 点时降采样不卡顿 | 前端操作 |
| 6.1 | 代码中无 `.earTag` 和 `.boundEarTag` 引用（`DeviceType.earTag` 除外）| grep 验证 |
| 6.2 | 表单标签显示"编号"而非"耳标号" | 前端查看 |
| 6.3 | 告警列表显示牲畜编号（非 livestockId）| 前端查看 |
| 7.1 | `IoTCommandPort` 定义在 `ranch/domain/port/` 下 | 代码检查 |
| 7.2 | `findAllActiveByLivestockId` 返回 `List` | 编译通过 |
| 7.3 | 每步实施后测试通过无回归 | `./gradlew test` + `flutter test` |
