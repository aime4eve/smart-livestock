# 围栏命中检测两级优先设计

> 日期: 2026-04-17
> 状态: Approved
> 范围: Mobile/mobile_app — fence_hit_detection + fence_page
> Issue: #26

## 背景

上一个 spec（2026-04-16-fence-map-ux-overhaul）引入了 40px 屏幕空间边界容差，解决了射线法零容差导致的"点击边界附近无法选中"问题。但在默认 zoom 14 下，围栏屏幕尺寸极小（最大 16×40px，最小 4×8px），40px 容差使所有围栏的有效点击区域膨胀 3-21 倍，导致**所有 6 对围栏的容差区域互相重叠**。

当前 `detectFenceHits` 将"点在围栏内部"（射线法命中）和"点在边界附近"（容差命中）视为同等优先级混合排序。当用户点击放牧B区内部时，附近围栏的容差区域也会命中，触发 BottomSheet 而非直接选中。

## 设计目标

- 点击围栏内部时直接选中，不受附近围栏容差区域干扰
- 点击边界附近时按物理距离选最近的围栏，减少 BottomSheet 弹出频率
- 距离相近时保留 BottomSheet 让用户选择
- 改动范围最小化，仅涉及命中检测逻辑

## 设计

### FenceHitResult 数据模型

扩展 `FenceHitResult`，携带命中层级和距离信息：

```dart
class FenceHitResult {
  const FenceHitResult({
    required this.fenceId,
    required this.areaHectares,
    required this.isInside,
    required this.boundaryDistance,
  });

  final String fenceId;
  final double areaHectares;
  final bool isInside;          // Tier 1: 射线法内部命中
  final double boundaryDistance; // Tier 2: 到最近边的像素距离（内部命中为 0）
}
```

两个新字段均为 `required`，无默认值。

### 检测与排序

`detectFenceHits` 遍历所有围栏，分离两种命中：

1. **Tier 1（内部命中）**：`fencePolygonContainsLatLng(tapLatLng, fence.points)` 返回 `true` → `isInside = true, boundaryDistance = 0`
2. **Tier 2（边界命中）**：将围栏顶点投影到屏幕坐标，计算点击位置到每条边的最短距离 → `isInside = false, boundaryDistance = minDistance`

排序规则：
1. Tier 1 排在 Tier 2 前面
2. 同为 Tier 1 → 按面积升序（小围栏优先，嵌套场景选内层）
3. 同为 Tier 2 → 按 `boundaryDistance` 升序（近的优先）

### 选择逻辑

`_handleMapTap` 接收排序后的命中列表，按以下规则决定：

```
if hits 为空 → select(null), return

if hits[0].isInside == true:
  select(hits[0].fenceId)   // 最小的内部命中，直接选中
  return

// 以下全部是 Tier 2
if hits.length == 1:
  select(hits[0].fenceId)   // 唯一边界命中，直接选中
  return

if hits.length >= 2:
  if hits[0].boundaryDistance < 1.0:
    select(hits[0].fenceId) // 几乎贴在边界上，毫无疑问
    return
  ratio = hits[1].boundaryDistance / hits[0].boundaryDistance
  if ratio >= 1.5:
    select(hits[0].fenceId) // 最近者明显更近，直接选中
    return
  else:
    BottomSheet             // 距离相近，让用户选择
```

距离比值 1.5 的含义：第二近围栏的距离必须是最近围栏距离的 1.5 倍以上，才认为最近围栏"明显更近"。例如最近 5px、第二近 7px → 7/5=1.4 < 1.5 → 弹窗；最近 5px、第二近 12px → 12/5=2.4 ≥ 1.5 → 直接选中。

### 边界距离计算

将 `isPointNearPolygonBoundary` 改为返回最近距离，阈值判断上移到 `detectFenceHits`：

```dart
double nearestDistanceToPolygonBoundary(
  Offset point,
  List<Offset> polygonScreenPoints,
)
```

遍历所有边，调用 `distanceToSegment` 计算每条边的距离，返回最小值。`distanceToSegment` 保持不变。

## 场景验证

以隔离区（4×8px）和放牧B区（16×40px）为例，两者最近边距 17px：

| 点击位置 | Tier 1 | Tier 2 距离 | 结果 |
|----------|--------|------------|------|
| 隔离区内部 | 隔离区 | — | 直接选中隔离区 |
| 放牧B区内部 | 放牧B区 | — | 直接选中放牧B区 |
| 隔离区边界外 2px | 无 | 隔离区 2px, 放牧B区 19px | ratio=9.5 → 直接选中隔离区 |
| 两者中间（各 8.5px） | 无 | 隔离区 8.5px, 放牧B区 8.5px | ratio=1.0 → BottomSheet |

## 文件变更

### 修改

| 文件 | 变更 |
|------|------|
| `lib/features/fence/presentation/fence_hit_detection.dart` | `FenceHitResult` 增加 `isInside` + `boundaryDistance`；`isPointNearPolygonBoundary` → `nearestDistanceToPolygonBoundary` 返回距离；`detectFenceHits` 分离 Tier 1/Tier 2 并按新规则排序 |
| `lib/features/pages/fence_page.dart` | `_handleMapTap` 实现两级优先 + 距离比值判定 |
| `test/features/fence/fence_hit_detection_test.dart` | 新增 Tier 1 优先、Tier 2 距离排序、距离比值阈值用例 |

### 不变

- `fence_controller.dart` — `select()` 接口不变
- `fence_polygon_contains.dart` — 射线法不变
- `fence_candidate_sheet.dart` — BottomSheet UI 不变
- 所有编辑态代码不变
- 所有 domain/data 层不变

## 验收标准

1. 点击围栏内部可直接选中，不弹出 BottomSheet
2. 点击围栏边界附近（40px 内）时，按距离选中最近的围栏
3. 距离相近的两个围栏之间点击时弹出 BottomSheet 候选列表
4. 点击空白区域取消选中
5. `flutter test` 全部通过
6. `flutter analyze` 无新增警告
