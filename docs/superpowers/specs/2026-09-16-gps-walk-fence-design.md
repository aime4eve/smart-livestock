# 围栏轨迹采集与 GPX 导入设计：走一圈生成围栏初始范围

- **工单**：[NIX-213](https://linear.app/nix-agentic/issue/NIX-213)（High）
- **日期**：2026-09-16
- **状态**：设计待用户批准（按 2026-09-05 硬性规则，批准前不编码）
- **关联**：NIX-189（向导画图 GCJ 存库偏差，同族坐标系问题）、NIX-190（离线瓦片 fallback）；2026-09-04 删除的「轨迹缓冲区」模板（338a90f2）是本特性的"演示假数据版"，本设计是其真实数据版
- **复杂度分级**：feature（新功能，移动端 + 可选后端防御），按 AGENTS.md §3 feature 工作流：本设计批准后出 plan → 编码 → 部署 dev → 用户集成测试 → PR → 关单

---

## 1. 需求

当前围栏创建靠地图画矩形/圆形 + 顶点编辑/平移修正，真实牧场圈地效率低。本特性新增两条"轨迹成栏"路径：

1. **走一圈生成**：手机 App（Android/iOS）调用系统 GPS 实时采点，用户沿围栏边界走一圈，轨迹经算法处理后生成围栏初始范围，进入现有顶点编辑修正后保存。
2. **GPX 导入**：外部 GPS 工具（RTK 手簿、奥维互动地图、两步路等）导出的 GPX 轨迹文件导入，经同一管线生成初始范围。

**已确认的关键决策**（用户批准计划时采纳推荐项）：

| 决策 | 结论 | 说明 |
|---|---|---|
| 轨迹形态 | 沿边界走一圈，**轨迹即边界** | 算法做去噪/抽稀/闭合；不做凹包（P3 备选） |
| 导入格式 | 仅 GPX | 主流 GPS 工具均支持导出 GPX |
| 解析位置 | 客户端（Flutter）解析 GPX | 围栏 API 本来就收 vertices，无后端新端点 |

---

## 2. 现状调研结论（2026-09-16 双端探查）

### 2.1 移动端（Mobile/mobile_app/）

| 事项 | 现状 | 对本特性的含义 |
|---|---|---|
| 定位能力 | **无任何定位插件**（无 geolocator/location）；AndroidManifest 仅 `INTERNET`+`CAMERA`，Info.plist 仅 `NSCameraUsageDescription` | 需新增 geolocator 依赖 + 双平台权限声明 + 运行时权限请求 |
| 文件选取 | Web 有手写 `web_file_utils`（dart:html conditional import），**移动端直接 throw UnsupportedError**（`lib/features/admin/gps_quality/presentation/track_line_import_dialog.dart` 用例） | GPX 导入移动端需引入 `file_picker`；Web 复用现有通道 |
| 轨迹简化库 | 无（无 polyline/几何简化包） | 自实现 Douglas-Peucker（~50 行，便于单测，免新依赖） |
| 编辑会话 | `FenceEditSession`/`FenceEditOperations` 接受任意 `List<LatLng>`，顶点编辑/插点/删点/平移/undo/redo 全套在 `fence_page.dart` 编辑器 | 管线产出的顶点列表**零改动**进入现有修正与保存链路 |
| 新建围栏 | `fence_form_page.dart`（模板矩形/圆/多边形点按/手动录入），保存 `farmPost('/fences')`，payload `{name, vertices:[{lat,lng}]}`（GCJ→WGS 转回后输出） | 轨迹/GPX 产出的顶点加载进表单预览即可走现有保存；"手动录入" TextButton 行（L886-890）是"导入 GPX"按钮的自然位置 |
| 校验 | `FenceController.validateDraftGeometry`（fence_controller.dart L367-384）：<3 点/重复点/零面积/自相交 | 管线末段直接复用 |
| 坐标系 | 存储一律 WGS-84；渲染按瓦片源经 `SmartTileProvider.shouldTransformCoordinates()` 转 GCJ-02（高德）；转换工具 `lib/core/map/coord_transform.dart` 齐备（wgs84ToGcj02/gcj02ToWgs84 批量版都有） | GPS 原生输出即 WGS-84，**直存不转换**；显示时走现有机制，规避 NIX-189 类画图点存库偏差 |
| i18n | 模板是 `app_zh.arb`（注意不是 en），中英双写 + `flutter gen-l10n` | 新文案按 §10 key 清单双语言同步 |
| 测试先例 | fence 领域层纯函数单测模式成熟（`test/features/fence/` 7 个）；GPX 解析可用 fixture（`test/fixtures/` 模式） | 管线与 GPX 解析按同模式写单测 |

### 2.2 后端（smart-livestock-server/）

- 围栏是**纯多边形顶点模型**（`fences.vertices` JSONB，无半径/无 Circle 类型耦合），`POST /fences` 接受任意长度 vertices，**无顶点数校验**——几百顶点直存无障碍。
- **风险**：保存时服务端用 JTS 对多边形做 `buffer(50m)` 预计算 `buffer_polygon`（`FenceApplicationService.computeBufferPolygon`）。原始 GPS 轨迹直连的环**极易自相交**，JTS buffer 对 invalid polygon 可能抛 `TopologyException` → 创建围栏 500。
- 运行时围栏判定（`GpsLogEventConsumer`）是 O(顶点数) BigDecimal 射线法/每 GPS 点/每围栏，无空间索引——顶点数应控制在几十~一百量级（本设计顶点上限 100 即由此来）。
- 无任何 GPX/KML 解析先例；既有导入特性均为"multipart parse→import 两阶段"模式（admin 端），本特性客户端解析后走普通 POST，**不引入后端端点**。
- 坐标系：数据库与 API 一律 WGS-84（PRD v2.3 §坐标系 1245-1261 行）。
- `source=MANUAL_IMPORT` 的 GPS 点跳过围栏检测（V20260729120000 一族）——手机轨迹**不写** `gps_logs`（该表挂 device_id，手机无对应设备），不存在污染遥测数据的问题。

---

## 3. 总体架构

```
┌─────────────────────┐     ┌──────────────────────┐
│ 采集模式（走一圈）    │     │  GPX 文件导入         │
│ TrackCollectPage    │     │  GpxTrackImporter    │
│ geolocator 流式采点  │     │  file_picker/Web通道  │
└──────────┬──────────┘     └──────────┬───────────┘
           │  List<TrackPoint>          │  List<TrackPoint>
           ▼                            ▼
┌─────────────────────────────────────────────────┐
│  轨迹→闭合多边形管线（纯函数，可单测）              │
│  TrackToPolygonConverter                         │
│  精度过滤 → 停留去重 → 速度离群剔除 → DP 抽稀      │
│  → 顶点上限迭代 → 首尾闭合 → 几何校验             │
└──────────────────────┬──────────────────────────┘
                       │  List<LatLng>（WGS-84）+ 结果标志
                       ▼
┌─────────────────────────────────────────────────┐
│  FenceFormPage 载入顶点预览（现有能力）            │
│  → 用户填写名称 → 保存 POST /fences（现有链路）    │
│  → 提示进入全屏编辑器顶点修正（现有入口）          │
└─────────────────────────────────────────────────┘
```

- **后端零新端点**；P1 可选项含后端防御性校验（§9）。
- 移动端（Android/iOS）支持采集 + 导入；Web 端仅导入（浏览器定位精度差，且围栏编辑以手机为主场景），采集入口在 Web 构建下隐藏（`kIsWeb` 判定）。

---

## 4. 轨迹→闭合多边形算法设计（核心）

新建 `lib/features/fence/domain/track_to_polygon_converter.dart`，纯函数、无 Flutter 依赖，输入输出：

```dart
class TrackPoint {
  final double lat, lng;
  final double accuracyMeters; // GPS 水平精度
  final DateTime timestamp;
}

class TrackToPolygonResult {
  final List<LatLng> vertices;   // 闭合多边形顶点（不含重复首尾点）
  final bool closedLoop;         // 首尾是否自然闭合（false=直连闭合）
  final bool selfIntersecting;   // 是否自相交（提示用户修正）
  final int rawCount;            // 原始点数
  final int vertexCount;         // 抽稀后顶点数
}

TrackToPolygonResult convertTrackToPolygon(
  List<TrackPoint> raw, {
  double accuracyThresholdM = 20,   // P1 固定值，不做设置项
  double simplifyEpsilonM = 2,
  int maxVertices = 100,
  double closeThresholdM = 10,
})
```

### 4.1 各阶段

1. **精度过滤**：`accuracy > 20m` 的点丢弃；全被丢弃 → 返回失败（`TOO_FEW_POINTS`）。
2. **停留去重**：相邻点位移 < 1m 视为同一位置，保留精度最好的一点（人原地站着 GPS 漂移会堆几百个点）。
3. **速度离群剔除**：相邻两点隐含速度 = 距离/时间差，> 10 m/s（≈36 km/h，步行/骑行画栏的上界）判定为跳点，丢弃后一点。逐点单向扫描即可，不做全局拟合。
4. **下限检查**：剩余 < 3 点 → 失败（`TOO_FEW_POINTS`）。
5. **Douglas-Peucker 抽稀**：容差 2m。地理坐标下垂直距离用等距圆柱近似（以线段中点纬度做 cos(lat) 缩放），牧场尺度（< 数 km）误差可忽略；距离量算复用 `latlong2` 的 haversine（`LatLng.distance`）。
6. **顶点上限迭代**：抽稀后仍 > 100 顶点 → 容差 ×1.5 重跑（从原始点重新开始，避免累积误差），直到 ≤100 或容差 > 50m（此时接受现状，宁可顶点多也不进一步失真——后端无硬上限）。
7. **首尾闭合**：首末点距离 < 10m → 合并为一点（取均值），`closedLoop=true`；否则直线连接首末，`closedLoop=false`（UI 提示"轨迹未闭合，已自动连接，请修正"）。
8. **几何校验**：复用 `validateDraftGeometry` 同款规则（≥3 个互异点、非零面积、无自相交）。自相交时先用更大容差重抽一次；仍自相交则照常返回结果但 `selfIntersecting=true`——**不阻断**，交给用户顶点编辑修正（轨迹交叉多发生在走位重叠处，自动拆解易误判）。存库前如果后端防御校验在位（§9），仍会被拦下并提示。

### 4.2 为什么不需要凹包（concave hull）

沿边界走一圈时轨迹本身即边界序列，只需"抽稀 + 闭合"，边界贴合度 = 人走的位置。凹包只适用于"区域内自由走动、点集散布"场景，边界贴合度低且 Dart 侧实现复杂（k 记忆化凹包/alpha shape 均无现成包）。**已与用户确认采用轨迹即边界**；凹包列入 P3 备选。

---

## 5. 采集模式 UI 与交互

### 5.1 入口

`FenceFormPage` 绘制类型下拉（现：矩形/圆/多边形）新增第四项 **「轨迹采集」**。选中后表单地图区域替换为「开始采集」大按钮（Web 构建下该项隐藏）。

### 5.2 采集页 `TrackCollectPage`（新文件，全屏）

- **地图**：复用 `SmartTileProvider`（瓦片源/GCJ 转换自动）；初始中心 = 当前定位；实时元素：
  - 当前位置标记（圆点 + 精度圈）；
  - 已采轨迹 Polyline（**显示坐标 = WGS-84 → GCJ-02 转换后**，与围栏渲染同机制；存储始终 WGS-84 原始值）。
- **状态条**（顶部悬浮卡）：精度 ±Xm（>20m 显示黄色警示）、已采点数、采集时长。
- **操作**：开始 → 暂停/继续 → 完成（触发管线 → 结果确认对话框：顶点数/是否闭合/是否自相交 → 确认后 `pop` 返回表单页并回传顶点）/ 放弃。
- **采集中**：地图平移缩放自由（flutter_map 8 手势经验：不在采集态禁 drag）；置 `wakelock_plus` 保持亮屏（iOS WhenInUse 熄屏即停采，依赖极小、收益明确，列入 P1）。
- **权限/服务前置检查**：进入页面即请求 WhenInUse 权限；拒绝 → 引导页（说明 + 重新请求按钮 + 打开系统设置）；定位服务关闭 → 明确提示。

### 5.3 采集参数

| 参数 | 值 | 理由 |
|---|---|---|
| 插件 | `geolocator`（新依赖） | 事实标准，双平台一致 API |
| 模式 | WhenInUse | 不申请后台定位（商店审核复杂度↑，走一圈必亮屏，无必要） |
| 采点策略 | `distanceFilter: 2m` | 步速 ~1.4m/s 下约 1.4s 一点，兼顾密度与功耗 |
| 内存上限 | 环形缓冲 5000 点 | 走 10km 边界 @2m = 5000 点封顶，防极端场景内存膨胀；到顶后按 1/2 抽稀腾空间 |

---

## 6. GPX 导入设计

### 6.1 解析

新建 `lib/features/fence/domain/gpx_track_parser.dart`：

- 依赖 `xml` 包（^6.x，纯 Dart，三端可用）解析。
- 支持：`<trk><trkseg><trkpt lat lon>`（多段合并）、`<rte><rtept>`；`<wpt>` 单点集不构成轨迹，忽略。命名空间前缀不敏感（剥 `gpx:` 等前缀后匹配 local name）。
- `<ele>`/`<time>` 读取（time 用于速度离群剔除；无 time 则跳过该步）。
- 输出 `List<TrackPoint>` 进同一管线。
- fixture 测试样本：真实 RTK 手簿导出 + 手写最小样例 + 命名空间变体。

### 6.2 文件选取

- 抽象 `pickTrackFileBytes()`：移动端/桌面用 `file_picker`（新依赖，`type: custom, extensions: [gpx, xml]`）；Web 用现有 `web_file_utils`（`pickFileBytesWithName(['gpx','xml'])`，conditional import 模式与 `track_line_import_dialog.dart` 一致）。
- 入口：`FenceFormPage` "手动录入坐标"旁新增 **「导入 GPX」** TextButton（L886-890 处）。
- 失败提示：解析失败/无轨迹数据/点不足，Snackbar 中英文（§10）。

---

## 7. 坐标系处理（防 NIX-189 复发）

| 环节 | 坐标系 | 处理 |
|---|---|---|
| GPS 采集 | WGS-84（系统原生） | **直存管线与表单 state，任何环节不得转 GCJ** |
| GPX 文件 | 按业界惯例 WGS-84 | 直存 |
| 显示（采集页/表单预览） | 高德瓦片 = GCJ-02 | 按 `shouldTransformCoordinates()` 转 GCJ 后落屏 |
| 保存 | WGS-84 | 直接提交 vertices，**不做任何转换** |

与 NIX-189（向导画图点是屏幕 GCJ 坐标、未经逆变换直存 → 偏差 ~500m）方向相反：本特性数据源天生 WGS-84，风险在"显示端忘了转 GCJ"（表现为轨迹画在瓦片旁边 ~500m，肉眼即可发现），单测覆盖转换接线。

---

## 8. 权限与平台声明

| 平台 | 改动 |
|---|---|
| Android | `AndroidManifest.xml` 增 `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION`（不申请 `ACCESS_BACKGROUND_LOCATION`） |
| iOS | `Info.plist` 增 `NSLocationWhenInUseUsageDescription`（中英双语一句话："沿围栏边界行走时记录您的位置以生成围栏 / Records your location while you walk the fence boundary to create it"） |
| 运行时 | geolocator `requestPermission()` 前置检查 + 拒绝后引导（§5.2）；沿用项目现有"权限被拒不崩溃只提示"约定 |

---

## 9. 后端影响与防御性校验（P1 可选项，待批准）

主体**零后端改动**。建议随 P1 增加两处小防御（各 ~10 行，含测试）：

1. `FenceApplicationService` create/update：`vertices.size() < 3` → 400 `VALIDATION_ERROR`，MessageSource 新 key `error.fenceTooFewVertices`（中英 properties 同步）。
2. `computeBufferPolygon` 包 try/catch `TopologyException` → 400 `error.fenceInvalidGeometry`（而非 500）。

不加也不阻塞 P1（客户端管线已拦绝大多数），但轨迹场景把"自相交围栏"从不可能变为常见，服务端兜底值得。

---

## 10. 边界情况与 i18n key 清单

| 场景 | 行为 | l10n key（zh / en） |
|---|---|---|
| 定位权限拒绝 | 引导页：说明 + 重试 + 系统设置 | `fenceTrackPermissionDenied` 需要定位权限才能采集轨迹 / Location permission required to record a track |
| 定位服务关闭 | 提示 + 打开系统设置入口 | `fenceTrackServiceDisabled` 请先开启系统定位服务 / Please enable location services |
| 有效点不足 | Snackbar，留在采集页 | `fenceTrackTooFewPoints` 有效定位点不足，无法生成围栏 / Not enough valid points to build a fence |
| 轨迹未闭合 | 结果确认框黄色提示 | `fenceTrackNotClosed` 轨迹未闭合，已自动直线连接，请用顶点编辑修正 / Track not closed; auto-connected, please adjust vertices |
| 轨迹自相交 | 结果确认框黄色提示 | `fenceTrackSelfIntersecting` 轨迹存在交叉，建议手动修正顶点 / The track crosses itself; please adjust vertices |
| 熄屏提示 | 采集开始 Snackbar | `fenceTrackKeepScreenOn` 采集中请保持屏幕常亮 / Keep the screen on while recording |
| GPX 解析失败 | Snackbar | `fenceImportGpxFailed` GPX 解析失败：{error} / Failed to parse GPX: {error} |
| GPX 无轨迹 | Snackbar | `fenceImportNoTrack` GPX 文件中未找到轨迹数据 / No track found in GPX file |
| 采集页固定文案 | 按钮/状态条 | `fenceTrackMode/Start/Pause/Resume/Finish/Discard`、`fenceTrackPointCount` 已采 {count} 点、`fenceTrackAccuracy` 精度 ±{meters}m |

流程：`app_zh.arb`（模板）+ `app_en.arb` 双写 → `flutter gen-l10n`。

---

## 11. 测试计划

| 层 | 用例 |
|---|---|
| 管线纯函数单测 | 精度过滤阈值、停留去重、速度离群、DP 抽稀正确性（构造规则形状轨迹→顶点数/形状断言）、顶点上限迭代、<10m 闭合与未闭合标志、自相交标志、全点被过滤/点不足失败 |
| GPX 解析单测 | trk 多段、rte、命名空间前缀、无 time 字段容错、坏 XML 抛可读错误 |
| 坐标转换接线 | 采集点显示转换调用断言（高德源 WGS→GCJ、OSM 源直通） |
| 表单集成 | 轨迹结果回传后表单顶点预览/保存 payload 断言（fake repository 模式，同 `fence_controller_save_guard_test`） |
| 权限 | 真机冒烟（授权/拒绝/关服务三态，集成测试阶段人工执行） |
| 回归基线 | `flutter analyze` 无新增；`flutter test` CI 口径（排除 test/e2e）不扩大既有失败（当前 516 过/1 挂为基线）；若做后端防御：目标模块测试 + 全新库 Flyway 不涉及（无迁移） |

---

## 12. 分期与改动面估算

| 期 | 内容 | 改动面 |
|---|---|---|
| **P1** | 采集模式 + 管线 + 表单衔接 + 权限 + i18n + 测试 | 新增：TrackCollectPage、TrackToPolygonConverter、权限引导；依赖：geolocator、wakelock_plus；修改：fence_form_page（类型项+回传）、AndroidManifest、Info.plist、arb ×2、（可选）后端 2 处防御 + properties ×2 |
| **P2** | GPX 导入 | 新增：GpxTrackParser、pickTrackFileBytes（conditional import）；依赖：xml、file_picker；修改：fence_form_page（按钮）+ arb ×2 |
| **P3** | 备选 | 凹包包络、CSV/KML、熄屏/后台采集、采集结果直达全屏编辑器草稿会话（`createDraftSession`） |

P1 完成 → 部署 dev → 用户真机集成测试（重点：实际走一圈 + 高德瓦片下位置正确性）→ P2。

---

## 13. 待用户确认的决策清单

1. **设计整体批准？**（轨迹即边界 + GPX 仅此格式 + 客户端解析）
2. **后端两处防御性校验**是否随 P1 一起做（推荐做，防轨迹场景 500）？
3. **入口形态**：类型下拉加「轨迹采集」项（现方案）vs 围栏页独立入口按钮——现方案改动最小、与现有画法并列，如希望更醒目可改独立按钮。
4. P3 备选项是否有想提前的（如 CSV 导入）。
