# 地图牛只状态标记设计

> 日期: 2026-06-12
> 状态: 已确认

## 背景

牧场地图上需要同时展示牛只的健康状态和围栏状态，两个维度独立可读，互不干扰。当前 `HealthMarker` 和 `AlertMarker` 两套 widget 将健康/围栏/告警三个概念压缩成一个颜色通道，信息丢失。

## 设计原则

**两个独立视觉通道：**

| 维度 | 视觉通道 | 编码方式 |
|------|---------|---------|
| 健康状态 | 填充色 | 颜色=异常类型 |
| 围栏状态 | 边框样式 | 线型+粗细=围栏级别 |

## 健康状态 → 填充色

`RanchLivestockMarker.healthStatus`（严重程度）+ `primaryAlert`（类型）联合决定：

| 条件 | 填充色 | 色值 |
|------|-------|------|
| `healthStatus == NORMAL` | 绿色 | `AppColors.success #4C9A5F` |
| `healthStatus != NORMAL` + `primaryAlert == FEVER` | 红色 | `AppColors.danger #C2564B` |
| `healthStatus != NORMAL` + `primaryAlert == DIGESTIVE` | 橙色 | `AppColors.warning #D28A2D` |
| `healthStatus != NORMAL` + `primaryAlert == ESTRUS` | 粉色 | `AppColors.estrus #C25689` |
| `healthStatus != NORMAL` + `primaryAlert == EPIDEMIC` | 青蓝色 | `AppColors.info #4A7F9D` |
| 其他异常（无具体类型） | 红色 | `AppColors.danger #C2564B` |

## 围栏状态 → 边框样式

`RanchLivestockMarker.fenceStatus` 决定：

| fenceStatus | 边框 | 动画 |
|------------|------|------|
| `SAFE` | 无边框 | 无 |
| `APPROACH` | 深灰 `AppColors.fenceApproach #454F45` 虚线 `2px` | 无 |
| `BREACH` | 黑色 `AppColors.fenceBreach #1A1F1A` 实线 `3px` + 外发光阴影 | 脉冲闪烁（透明度 0.6↔1.0 周期变化） |

只有 BREACH 有动画，其他状态纯静态。

## 统一 Widget：LivestockMapMarker

替换现有 `HealthMarker` + `AlertMarker`，合并为一个 widget。

**接口：**

```dart
class LivestockMapMarker extends StatefulWidget {
  const LivestockMapMarker({
    super.key,
    required this.livestockCode,
    required this.healthStatus,
    required this.primaryAlert,
    required this.fenceStatus,
    this.onTap,
  });

  final String livestockCode;
  final String healthStatus;   // NORMAL / WARNING / CRITICAL
  final String primaryAlert;   // FEVER / DIGESTIVE / ESTRUS / EPIDEMIC / '' / ...
  final String fenceStatus;    // SAFE / APPROACH / BREACH
  final VoidCallback? onTap;
}
```

**渲染逻辑：**
- 填充色 = `_healthColor()`（基于 healthStatus + primaryAlert）
- 边框 = `_fenceBorder()`（基于 fenceStatus）
- 动画 = `fenceStatus == 'BREACH'` 时启用 `AnimationController`，周期 1200ms，reverse repeat，边框透明度 0.6↔1.0
- 非 BREACH 状态不启动动画 controller
- 尺寸统一 32px
- 圆心显示 livestockCode 缩写

## ranch_page.dart 渲染简化

**之前**：两条互斥路径（非告警→HealthMarker，告警→AlertMarker 脉冲）

**之后**：一条路径

```dart
for (final m in overview.livestockMarkers)
  Marker(
    point: m.toLatLng(),
    width: 32,
    height: 32,
    child: LivestockMapMarker(
      key: Key('livestock-${m.livestockId}'),
      livestockCode: m.livestockCode,
      healthStatus: m.healthStatus,
      primaryAlert: m.primaryAlert,
      fenceStatus: m.fenceStatus,
      onTap: () => _showLivestockDetail(context, m, overview),
    ),
  ),
```

移除 `alertLivestockIds` 集合、`_alertSeverityForLivestock()` 方法。

## 文件变更清单

| 文件 | 变更 |
|------|------|
| `features/ranch/presentation/widgets/health_marker.dart` | 替换为 `livestock_map_marker.dart` |
| `features/ranch/presentation/widgets/alert_marker.dart` | 删除 |
| `features/pages/ranch_page.dart` | 简化 MarkerLayer，移除 alertLivestockIds 和 _alertSeverityForLivestock，import 更新 |
| `core/theme/app_colors.dart` | 新增 `estrus: #C25689`、`fenceApproach: #454F45`、`fenceBreach: #1A1F1A` |
| `features/ranch/domain/ranch_models.dart` | 无变更 |

## 不在范围内

- 后端 API 变更（`RanchLivestockMarker` 数据结构不变）
- `LivestockDetailSheet`（点击后弹出的详情面板）的改造
- 围栏 Polygon 和 FenceBufferLayer 的渲染逻辑
