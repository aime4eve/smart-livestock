# 围栏轨迹采集与 GPX 导入设计：走动包络生成围栏初始范围

- **工单**：[NIX-213](https://linear.app/nix-agentic/issue/NIX-213)（High）
- **日期**：2026-09-16（r2）
- **修订记录**：
  - r1（2026-09-16）：初版，算法为"轨迹即边界"（去噪→抽稀→首尾闭合），GPX 客户端解析。
  - **r2（2026-09-16，用户裁决两项）**：① 算法改为**最外包络**——无论怎么走，取所有采点的最外点形成围栏最外沿（凹包为主、凸包兜底），不再依赖走线顺序与闭合回路；② GPX 导入**借鉴本项目 GPS 质量检验的轨迹导入功能**（三步向导 + 后端解析端点），不再做客户端 GPX 解析。
- **状态**：设计待用户批准（按 2026-09-05 硬性规则，批准前不编码）
- **关联**：NIX-189（向导画图 GCJ 存库偏差，同族坐标系问题）、NIX-190（离线瓦片 fallback）；2026-09-04 删除的「轨迹缓冲区」模板（338a90f2）是本特性的"演示假数据版"，本设计是其真实数据版
- **复杂度分级**：feature（新功能，移动端 + 后端解析端点 + 可选后端防御），按 AGENTS.md §3 feature 工作流：本设计批准后出 plan → 编码 → 部署 dev → 用户集成测试 → PR → 关单

---

## 1. 需求

当前围栏创建靠地图画矩形/圆形 + 顶点编辑/平移修正，真实牧场圈地效率低。本特性新增两条"轨迹成栏"路径：

1. **走动采集生成**：手机 App（Android/iOS）调用系统 GPS 实时采点，用户沿场地边缘走动（顺序无关、不要求闭合），算法取所有采点的**最外包络**生成围栏初始范围，进入现有顶点编辑修正后保存。
2. **GPX 导入**：外部 GPS 工具（RTK 手簿、奥维互动地图、两步路等）导出的 GPX 轨迹文件导入，经同一包络管线生成初始范围。导入交互**借鉴本项目 GPS 质量检验的轨迹导入**（`TrackLineImportDialog` 三步向导 + parse 端点模式）。

**已确认的关键决策**：

| 决策 | 结论 | 说明 |
|---|---|---|
| 轨迹形态 | **自由走动 + 最外包络**（用户裁决 2026-09-16） | 取所有点最外点形成外沿；凹包为主、凸包兜底；不做"轨迹即边界" |
| GPX 导入模式 | **借鉴 GPS 质量轨迹导入**（用户裁决 2026-09-16） | 三步向导 UX + 后端 parse 端点解析 GPX；只借 parse 不借 import 落库（§6） |
| 解析位置 | **GPX 解析在后端**（r2 变更），包络在客户端 | 客户端零 GPX 格式知识；包络单实现避免 Dart/Java 双份漂移 |

---

## 2. 现状调研结论（2026-09-16 双端探查）

### 2.1 移动端（Mobile/mobile_app/）

| 事项 | 现状 | 对本特性的含义 |
|---|---|---|
| 定位能力 | **无任何定位插件**（无 geolocator/location）；AndroidManifest 仅 `INTERNET`+`CAMERA`，Info.plist 仅 `NSCameraUsageDescription` | 需新增 geolocator 依赖 + 双平台权限声明 + 运行时权限请求 |
| 文件选取 | Web 有手写 `web_file_utils`（dart:html conditional export），**移动端 stub 直接 throw UnsupportedError**（GPS 质量的三个导入向导因此实为 Web-only） | 围栏 GPX 导入要上手机：扩展 `pickFileBytesWithName` 增加 IO 实现（`file_picker` 包），Web 复用现有实现 |
| 几何算法库 | 无轨迹简化/三角剖分/凹包库。**pub `delaunay` 包可用**（Mapbox Delaunator 的纯 Dart 移植，v3.0.0，BSD-3，全平台，已核实）；pub 无现成凹包/alpha shape 包 | Delaunay 用 `delaunay` 包；α-shape 边界提取与凸包手写（~100 + ~40 行），Douglas-Peucker 手写（~50 行），均可纯函数单测 |
| 编辑会话 | `FenceEditSession`/`FenceEditOperations` 接受任意 `List<LatLng>`，顶点编辑/插点/删点/平移/undo/redo 全套在 `fence_page.dart` 编辑器 | 包络产出的顶点列表**零改动**进入现有修正与保存链路 |
| 新建围栏 | `fence_form_page.dart`（模板矩形/圆/多边形点按/手动录入），保存 `farmPost('/fences')`，payload `{name, vertices:[{lat,lng}]}` | 包络顶点加载进表单预览即可走现有保存；"手动录入" TextButton 行（L886-890）是"导入 GPX"按钮的自然位置 |
| 校验 | `FenceController.validateDraftGeometry`（fence_controller.dart L367-384）：<3 点/重复点/零面积/自相交 | 管线末段直接复用 |
| 大响应基建 | `ApiClient` 对 ≥64KB 响应已在 `compute` 后台解码（2026-09-12 GPS 质量报告教训的产物） | track-parse 返回 ≤5000 点 JSON（~250KB）可直接复用该通道 |
| 坐标系 | 存储一律 WGS-84；渲染按瓦片源经 `SmartTileProvider.shouldTransformCoordinates()` 转 GCJ-02（高德）；转换工具 `lib/core/map/coord_transform.dart` 齐备 | GPS 原生输出即 WGS-84，**直存不转换**；显示时走现有机制，规避 NIX-189 类画图点存库偏差 |
| i18n | 模板是 `app_zh.arb`（注意不是 en），中英双写 + `flutter gen-l10n` | 新文案按 §10 key 清单双语言同步 |
| 测试先例 | fence 领域层纯函数单测模式成熟（`test/features/fence/` 7 个）；GPS 质量 `batch_import_preview_test` 是三向导中唯一 widget 测试（`debugFileBytes` 钩子模式） | 包络管线按纯函数模式、导入向导按 `debugFileBytes` + fake repo 模式写测试 |

### 2.2 后端（smart-livestock-server/）

- 围栏是**纯多边形顶点模型**（`fences.vertices` JSONB），`POST /fences` 接受任意长度 vertices，无顶点数校验——几百顶点直存无障碍；保存时 JTS `buffer(50m)` 预计算对自相交多边形可能抛 `TopologyException` → 500。**包络输出天然是简单多边形（无自相交）**，该风险大头在算法侧消解，后端防御仅剩兜底意义（§9）。
- 运行时围栏判定（`GpsLogEventConsumer`）是 O(顶点数) BigDecimal 射线法/每 GPS 点/每围栏——顶点上限 100 由此来。
- 坐标系：数据库与 API 一律 WGS-84（PRD v2.3 §1245-1261）。
- 手机轨迹**不写** `gps_logs`（该表挂 device_id），无遥测污染问题。

### 2.3 借鉴对象：GPS 质量轨迹导入链路（2026-09-16 专项探查）

- **前端** `track_line_import_dialog.dart`（637 行）：三步向导（`_step` 0/1/2），`_fileBytes/_fileName` 跨步复用（parse 与 import 用同一份内存 bytes，后端不存状态）；Step1 预览统计条（rawPointCount/pointCount/removedDuplicates/lengthMeters/起终点）+ 警告条（metadataWarning/invalidPoints）+ 前 8 点 DataTable + 名称输入框（默认值来自文件）；导入按钮 disabled 条件 `pointCount < 2`；错误处理 catch 后 Snackbar 显示后端 `message`；`debugFileBytes` `@visibleForTesting` 测试钩子 + 全流程 Key 规范。
- **后端** `GpsQualityAdminController`（`@PreAuthorize PLATFORM_ADMIN`）+ `StandardTrackLineService`：`/track-lines/parse|import` multipart 两阶段**无状态衔接**（import 重新解析同一上传文件，无 token 无临时存储）；清洗 = 仅去连续重复点 + 非法坐标范围校验 + `MAX_POINTS=20000` 上限（**不做抽稀**）；`ApiResponse` envelope + `ApiException(ErrorCode)`。
- **债务提示**：batch/trajectory/track-lines 三个向导是**三份复制粘贴**（无共用壳 widget）；track-lines 服务无服务级测试（仅域逻辑测试）。
- **不可复用**：POI/XLSX/RTK 8 列格式解析；`StandardTrackLine` 域语义（LINE 检查空间匹配、CANDIDATE 生命周期）与围栏（闭合多边形、面积、启停用）完全错位。

---

## 3. 总体架构

```
┌─────────────────────┐     ┌───────────────────────────────────┐
│ 走动采集（自由走动）  │     │  GPX 文件导入（借鉴 GPS 质量导入）   │
│ TrackCollectPage    │     │  FenceTrackImportDialog 三步向导    │
│ geolocator 流式采点  │     │  ② POST /fences/track-parse       │
└──────────┬──────────┘     │    （后端解析 GPX→清洗→统计+点集）   │
           │ 原始采点        └──────────────┬────────────────────┘
           │                               │ 清洗后轨迹点（JSON）
           ▼                               ▼
┌─────────────────────────────────────────────────┐
│  轨迹→外包络管线（客户端 Dart，纯函数，两路共用）    │
│  TrackToEnvelopeConverter                        │
│  预处理 → 统计离群清洗 → 凹包 α-shape → 凸包兜底   │
│  → DP 抽稀 → 顶点上限 → 几何校验                  │
└──────────────────────┬──────────────────────────┘
                       │  List<LatLng>（WGS-84）+ 结果标志
                       ▼
┌─────────────────────────────────────────────────┐
│  FenceFormPage 载入顶点预览（现有能力）            │
│  → 用户填写名称 → 保存 POST /fences（现有链路，    │
│    唯一写路径：配额/乐观锁不旁路）                 │
│  → 提示进入全屏编辑器顶点修正（现有入口）          │
└─────────────────────────────────────────────────┘
```

- **后端新增 1 个无状态解析端点，无新写路径、无数据库迁移**；P1 可选项含后端防御性校验（§9）。
- 移动端（Android/iOS）支持采集 + 导入；Web 端仅导入（浏览器定位精度差），采集入口在 Web 构建下隐藏（`kIsWeb` 判定）。

---

## 4. 轨迹→外包络算法设计（核心，r2）

新建 `lib/features/fence/domain/track_to_envelope_converter.dart`，纯函数、无 Flutter 依赖：

```dart
class TrackPoint {
  final double lat, lng;
  final double accuracyMeters; // GPS 水平精度；GPX 来源无此值时用 0（视为可信）
  final DateTime? timestamp;   // GPX 无 <time> 时为 null → 跳过速度剔除
}

class TrackToEnvelopeResult {
  final List<LatLng> vertices;   // 外包络顶点（简单多边形，WGS-84）
  final HullMethod method;       // concave / convex（是否走了兜底）
  final int ringsDropped;        // 丢弃的内部环（洞）与碎片环数量
  final int outliersDropped;     // 统计清洗剔除的点数
  final int rawCount;
  final int vertexCount;
}

TrackToEnvelopeResult convertTrackToEnvelope(
  List<TrackPoint> raw, {
  double accuracyThresholdM = 20,
  double simplifyEpsilonM = 2,
  int maxVertices = 100,
})
```

### 4.1 各阶段（9 步）

1. **精度过滤**：`accuracy > 20m` 丢弃（GPX 来源 accuracy=0 全保留）；全被丢弃 → 失败（`TOO_FEW_POINTS`）。
2. **停留去重**：相邻点位移 < 1m 合并，保留精度最好的一点（原地漂移堆点）。
3. **速度离群剔除**：相邻点隐含速度 > 10 m/s（≈36 km/h）判定跳点丢弃（有 timestamp 才做）。
4. **统计离群清洗（r2 新增，包络法的关键防线）**：包络对"向外的坏点"最敏感——一个漂移 50m 的定位点会直接变成围栏凸起。以点集中心（经纬度中位数）为参照，剔除距中心 > 中位数 + 5×MAD 的点，记录 `outliersDropped`。
5. **退化检查**：剩余 < 3 点或近似共线（凸包面积 < 25㎡）→ 失败（`TOO_FEW_POINTS` / `DEGENERATE`）。
6. **凹包 α-shape（主路径）**：
   - Delaunay 三角剖分：pub `delaunay` 包，输入投影到以点集中心为原点的局部平面坐标（米）后剖分（O(n log n)），规避经度收敛问题；
   - 三角形过滤：最长边 ≤ **L_max**（初始 `max(25m, 3×精度中位数)`，物理意义=边界单元最大边长）；
   - 边界提取：恰被 1 个存活三角形使用的边 = 边界边 → 链成闭合环；
   - 环处理：取**面积最大环**为围栏，其余环（洞/碎片）计入 `ringsDropped`；**洞 v1 不支持**（P3）；
   - 碎片化退化：多个面积可比的环（走位稀疏）→ L_max ×1.6 重试 ≤3 次，仍碎片化 → 兜底。
7. **凸包兜底**：Andrew monotone chain（~40 行），`method=convex`（UI 提示建议顶点修正）。凸包永远有解，保证管线不失败。
8. **Douglas-Peucker 抽稀**：容差 2m（等距圆柱近似垂直距离，latlong2 haversine 量距）；仍 > 100 顶点 → 容差 ×1.5 重跑，直到 ≤100 或容差 > 50m。
9. **几何校验**：包络天然闭合且无自相交（α-shape/凸包数学性质，保留断言）；复用 `validateDraftGeometry` 同款规则（≥3 互异点、非零面积）。

### 4.2 鲁棒性论述（包络法的物理边界，需向用户明示）

| 性质 | 说明 |
|---|---|
| ✅ 走线顺序无关 | 先走哪边、顺逆时针、走回头路均不影响 |
| ✅ 内部绕路无影响 | 场地内部点不参与外包络；横穿场地安全 |
| ⚠️ **最外沿 = 走到的最远点** | 拐角和边线附近务必走到，没走到的边被直线连接（宁可直连后顶点修正） |
| ⚠️ 向外漂移点撑包络 | 阶段 4 统计清洗压掉大漂移；残余小凸起属预期，交顶点编辑修平（正是"初始范围+人工修正"的产品定位） |
| ❌ 不支持洞 | 场中池塘/林地需镂空的围栏 v1 不支持（P3） |

### 4.3 方案取舍

- **纯凸包做主路径**：凹角（L/U 形场地）被直线切过多圈地；仅作兜底。
- **kNN 凹包（Moreira-Santos）**：~200 行自带失败重启；α-shape 有 `delaunay` 包垫底、L_max 参数直观，选后者。
- **服务端包络（JTS）**：否决——走动采集必须客户端即时包络，服务端再做一套即 Dart/Java 双实现漂移、双份调参；且 JTS ConcaveHull 版本可用性存疑。
- **r1"轨迹即边界"**：对走线质量要求高（必须沿边闭合）；被包络法取代，作为"贴边走"的特例自然成立。

---

## 5. 采集模式 UI 与交互

### 5.1 入口

`FenceFormPage` 绘制类型下拉（现：矩形/圆/多边形）新增第四项 **「轨迹采集」**；选中后表单地图区域替换为「开始采集」大按钮（Web 构建下该项隐藏）。

### 5.2 采集页 `TrackCollectPage`（新文件，全屏）

- **地图**：复用 `SmartTileProvider`（瓦片源/GCJ 转换自动）；初始中心 = 当前定位；实时元素：当前位置标记（圆点+精度圈）、已采轨迹 Polyline（**显示坐标 = WGS-84 → GCJ-02 转换后**；存储始终 WGS-84 原始值）。
- **引导语**（r2）：「沿场地边缘走一圈，拐角和边线附近务必走到；中途走进场地内部无妨」。
- **状态条**：精度 ±Xm（>20m 黄色警示）、已采点数、采集时长。
- **操作**：开始 → 暂停/继续 → 完成（包络管线 → 结果确认框：顶点数/凹凸/清洗数 → 确认后 pop 回表单页并回传顶点）/ 放弃。
- **采集中**：地图平移缩放自由（flutter_map 8 手势经验：采集态不禁 drag）；`wakelock_plus` 保持亮屏（iOS WhenInUse 熄屏停采）。
- **权限/服务前置检查**：进页即请求 WhenInUse 权限；拒绝 → 引导页（说明+重试+系统设置）；定位服务关闭 → 明确提示。

### 5.3 采集参数

| 参数 | 值 | 理由 |
|---|---|---|
| 插件 | `geolocator`（新依赖） | 事实标准，双平台一致 API |
| 模式 | WhenInUse | 不申请后台定位（审核复杂度↑，走一圈必亮屏） |
| 采点策略 | `distanceFilter: 2m` | 步速 ~1.4m/s 下约 1.4s 一点；包络法对密度要求低于"轨迹即边界" |
| 内存上限 | 环形缓冲 5000 点 | 10km 边界 @2m 封顶；到顶按 1/2 抽稀腾空间 |

---

## 6. GPX 导入设计（r2：借鉴 GPS 质量轨迹导入）

### 6.1 借鉴映射

| GPS 质量轨迹导入（track-lines） | 本特性围栏 GPX 导入 | 异同 |
|---|---|---|
| 三步向导：上传→解析预览→导入结果 | 三步向导：上传→**解析预览**→**包络结果** | Step2 语义不同：不落库，生成围栏初始范围载入表单 |
| `POST /admin/gps-quality/track-lines/parse`（multipart） | `POST /api/v1/farms/{farmId}/fences/track-parse`（multipart `file`） | farm-scoped 业务端点而非 admin 端点 |
| parse→import 两阶段（import 重新解析落库 StandardTrackLine） | **只借 parse**；终点 = 客户端包络 → 表单预览 → 现有 `POST /fences` 保存 | 唯一写路径不旁路（配额/乐观锁保持单点） |
| 预览 DTO：defaultName/rawPointCount/pointCount/removedDuplicates/invalidPoints/lengthMeters/起终点/metadataWarning/previewPoints(前8) | 同语义 + **trackPoints**（清洗后全量点集，供客户端包络） | 新增 trackPoints 字段 |
| 清洗：去连续重复 + 坐标范围校验 + MAX 20000 | 同规则 + 高程忽略（GPX `<ele>` 不用） | 一致 |
| `ApiResponse` envelope + `ApiException(ErrorCode)` + MessageSource 中文校验文案 | 同模式 | 一致 |
| Web-only 文件选取（stub 抛 UnsupportedError） | conditional export 补 IO 实现（`file_picker`） | 修复移动端缺口 |

### 6.2 后端端点契约草案

```
POST /api/v1/farms/{farmId}/fences/track-parse
Content-Type: multipart/form-data; file=.gpx
权限：OWNER / B2B_ADMIN（镜像 FenceController create）；无 @QuotaCheck（不落库）
```

响应 `data`：

```json
{
  "defaultName": "北围栏",                    // GPX <name> 或文件名去扩展名
  "rawPointCount": 3200,
  "pointCount": 2980,                        // 清洗后
  "removedDuplicates": 220,
  "invalidPoints": 0,
  "lengthMeters": 4820.5,                    // 轨迹全长（等距圆柱近似）
  "startLat": 28.24012, "startLng": 112.85031,
  "endLat": 28.24050, "endLng": 112.85010,
  "metadataWarning": null,                   // 多段合并/无时间戳等提示
  "previewPoints": [ {"sequenceNo":1,"lat":28.24012,"lng":112.85031} ],  // 前 8 个
  "trackPoints": [ {"lat":28.24012,"lng":112.85031} ]  // 清洗后全量（见 6.3 上限）
}
```

实现要点：
- 新 `FenceTrackParseService`（ranch/application）：JDK 内置 XML 解析（`DocumentBuilderFactory`，**XXE 防护：`disallow-doctype-decl=true` + 禁外部实体**），支持 `<trk><trkseg><trkpt>` 多段合并与 `<rte><rtept>`，命名空间前缀不敏感；`<wpt>` 忽略。
- 清洗：非法坐标（lat∉[-90,90]/lng∉[-180,180]）剔除计数、连续重复点合并、点数上限 **20000**（超限 `VALIDATION_ERROR error.gpxTooManyPoints`，同 track-lines 口径）、`pointCount < 2` 报 `error.gpxNoTrack` 同族错误。
- **传输抽稀**：清洗后 >5000 点时均匀步进抽至 5000（包络质量不受影响：L_max ≥25m，2m 级采样密度富余），防大响应。
- `@Transactional` 不加（无状态纯解析，参考 TrajectoryImportService 先例）。
- MessageSource 新 key：`error.gpxParseFailed` / `error.gpxNoTrack` / `error.gpxTooManyPoints`（中英 properties 同步）。
- 契约文档：`docs/api-contracts/app-api.md` §3.2 追加为围栏第 6 端点。

### 6.3 前端向导 `FenceTrackImportDialog`（三步）

- **共享壳 `ImportWizardShell`**（新 widget，lightweight）：步骤指示器 + 三步布局骨架 + Key 规范 + `debugFileBytes` 钩子。旧三个 GPS 质量向导**不动**，仅新向导使用，避免第四份裸拷贝；旧向导迁移留待后续（不在本工单范围）。
- **Step 0 上传**：`pickTrackFileBytes(['gpx','xml'])`（conditional export：Web 用现有 `web_file_utils`，IO 平台新增 `file_picker` 实现）；格式说明条（GPX 轨迹 `<trkpt>/<rtept>`，WGS-84）。
- **Step 1 解析预览**：`repo.parseFenceTrack(bytes, name)` → `ApiClient.uploadFile` → 统计条（原始/清洗点数、去重数、轨迹全长、起终点）+ 警告条 + 前 8 点表 + 「生成围栏范围」按钮（disabled 条件 `pointCount < 3`，围栏需多边形）。
- **Step 2 包络结果**：客户端对 `trackPoints` 跑 `TrackToEnvelopeConverter` → 展示顶点数/凹凸方式/剔除漂移点数/是否碎片多环 → 「载入围栏」→ pop 回 `FenceFormPage`，顶点 + `defaultName` 回填预览 → 用户走正常保存链路（后续顶点修正走现有全屏编辑器）。
- 大响应：trackPoints JSON 走 `ApiClient` 既有 ≥64KB `compute` 后台解码。

---

## 7. 坐标系处理（防 NIX-189 复发）

| 环节 | 坐标系 | 处理 |
|---|---|---|
| GPS 采集 | WGS-84（系统原生） | **直存管线与表单 state，任何环节不得转 GCJ** |
| GPX 文件/track-parse 响应 | WGS-84 | 直存 |
| 包络计算 | 局部平面坐标（米） | 仅管线内部以点集中心为原点等距投影，结果转回 WGS-84 |
| 显示（采集页/表单预览） | 高德瓦片 = GCJ-02 | 按 `shouldTransformCoordinates()` 转 GCJ 后落屏 |
| 保存 | WGS-84 | 直接提交 vertices，**不做任何转换** |

与 NIX-189（画图点 GCJ 直存偏差 ~500m）方向相反：本特性数据源天生 WGS-84，风险在"显示端忘了转 GCJ"（表现为轨迹画偏 ~500m，肉眼可发现），单测覆盖转换接线。

---

## 8. 权限与平台声明

| 平台 | 改动 |
|---|---|
| Android | `AndroidManifest.xml` 增 `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION`（不申请 `ACCESS_BACKGROUND_LOCATION`） |
| iOS | `Info.plist` 增 `NSLocationWhenInUseUsageDescription`（"沿围栏边界行走时记录您的位置以生成围栏 / Records your location while you walk the fence boundary to create it"） |
| 运行时 | geolocator `requestPermission()` 前置检查 + 拒绝后引导（§5.2）；沿用"权限被拒不崩溃只提示"约定 |

---

## 9. 后端影响与防御性校验（P1 可选项，待批准）

主体零改动（track-parse 为无状态解析端点）。r2 后包络输出无自相交，JTS 500 风险大头已消解，防御降为兜底（各 ~10 行）：

1. `FenceApplicationService` create/update：`vertices.size() < 3` → 400 `VALIDATION_ERROR`，key `error.fenceTooFewVertices`。
2. `computeBufferPolygon` 包 try/catch `TopologyException` → 400 `error.fenceInvalidGeometry`。

仍推荐随手加上（手动录入路径仍可能造出自相交多边形）。

---

## 10. 边界情况与 i18n key 清单

| 场景 | 行为 | l10n key（zh / en） |
|---|---|---|
| 定位权限拒绝 | 引导页：说明+重试+系统设置 | `fenceTrackPermissionDenied` 需要定位权限才能采集轨迹 / Location permission required to record a track |
| 定位服务关闭 | 提示+系统设置入口 | `fenceTrackServiceDisabled` 请先开启系统定位服务 / Please enable location services |
| 有效点不足 | Snackbar，留在采集页/向导 | `fenceTrackTooFewPoints` 有效定位点不足，无法生成围栏 / Not enough valid points to build a fence |
| 点位退化（近似共线） | Snackbar | `fenceTrackDegenerate` 定位点几乎在一条直线上，无法生成围栏范围 / Points are nearly collinear; cannot build a fence area |
| 多片区域/碎片 | 取最大环并提示 | `fenceTrackMultiArea` 检测到多片区域，已取最大一片 / Multiple areas detected; the largest one was kept |
| 凸包兜底 | 结果框提示建议修正 | `fenceTrackConvexFallback` 边缘点位较稀疏，已按最简外沿生成，建议修正顶点 / Sparse boundary points; simplified envelope created, please adjust vertices |
| 清洗提示 | 结果框显示 | `fenceTrackOutliersRemoved` 已剔除 {count} 个漂移点 / Removed {count} drifting points |
| 熄屏提示 | 采集开始 Snackbar | `fenceTrackKeepScreenOn` 采集中请保持屏幕常亮 / Keep the screen on while recording |
| GPX 解析失败 | Snackbar（后端 message） | `fenceImportGpxFailed` GPX 解析失败：{error} / Failed to parse GPX: {error} |
| GPX 无轨迹/点超限 | Snackbar（后端 message，error.gpx* 族） | 后端 MessageSource key |
| 向导固定文案 | 步骤/按钮/格式说明 | `fenceImportStepUpload/Preview/Result`、`fenceImportPickFile/Generate/Apply/Cancel`、`fenceImportGpxTitle` 导入 GPX 轨迹、格式说明条文案 |
| 采集页固定文案 | 按钮/状态条/引导语 | `fenceTrackMode/Start/Pause/Resume/Finish/Discard/Guide`、`fenceTrackPointCount` 已采 {count} 点、`fenceTrackAccuracy` 精度 ±{meters}m |

流程：`app_zh.arb`（模板）+ `app_en.arb` 双写 → `flutter gen-l10n`。

---

## 11. 测试计划

| 层 | 用例 |
|---|---|
| 包络管线单测 | 已知 L 形场地走位（含内部杂点+漂移尖刺）→ 凹角保持、尖刺被清洗、内部点无影响；**顺序打乱（洗牌）结果不变**；碎片化 → L_max 重试 → 凸包兜底标志；多环取最大环；共线/点不足失败；DP 抽稀与顶点上限迭代；局部投影往返误差 <1m |
| 凸包单测 | monotone chain 基准形状（凸/凹/共线退化） |
| 后端 FenceTrackParseService 测试 | 最小 GPX 样例、多段 trkseg 合并、rte、命名空间前缀、`<wpt>` 忽略、无轨迹报错、>20000 报错、非法坐标计数、坏 XML 报错、**XXE 载荷拒绝**、defaultName 取值优先级、>5000 传输抽稀 |
| 前端向导 widget 测试 | `debugFileBytes` 预置 GPX + fake repo：三步流转、预览统计渲染、`pointCount<3` 禁用、Step2 结果与回传表单断言（模板：`batch_import_preview_test`） |
| 坐标转换接线 | 高德源 WGS→GCJ、OSM 源直通断言 |
| 表单集成 | 包络/向导结果回传后表单顶点预览/保存 payload 断言（fake repository，同 `fence_controller_save_guard_test`） |
| 权限/真机 | 授权/拒绝/关服务三态冒烟；真机走一圈 + 高德瓦片位置正确性 + L_max/MAD 参数真实走位调优（集成测试阶段人工） |
| 回归基线 | `flutter analyze` 无新增；`flutter test` CI 口径不扩大既有失败（516 过/1 挂基线）；后端目标模块测试 + 全新库 Flyway 不涉及（无迁移）；track-lines 等既有导入回归不受影响（旧向导不动） |

---

## 12. 分期与改动面估算

| 期 | 内容 | 改动面 |
|---|---|---|
| **P1** | 走动采集 + 包络管线 + 表单衔接 + 权限 + i18n + 测试 | 新增：TrackCollectPage、TrackToEnvelopeConverter（α-shape/凸包/DP）、权限引导；依赖：geolocator、wakelock_plus、delaunay；修改：fence_form_page（类型项+回传）、AndroidManifest、Info.plist、arb ×2、（可选）后端 2 处防御 + properties ×2 |
| **P2** | GPX 导入（借鉴模式） | 后端：FenceTrackParseService + track-parse 端点 + DTO + MessageSource + 契约文档 + 服务测试；前端：FenceTrackImportDialog + ImportWizardShell + `pickFileBytesWithName` IO 实现 + repo 两方法（parseFenceTrack 等）+ arb ×2；依赖：file_picker |
| **P3** | 备选 | 带洞围栏（多环 GeoJSON，需后端判定链路同步，改动面大）、CSV/KML、熄屏/后台采集、采集结果直达全屏编辑器草稿会话（`createDraftSession`）、旧三个 GPS 质量向导迁移到 ImportWizardShell |

P1 完成 → 部署 dev → 用户真机集成测试 → P2 → 再部署 dev → 用户集成测试 → PR → 关单。实现进展持续更新 NIX-213。

---

## 13. 待用户确认的决策清单

1. ~~轨迹形态~~ **已裁决（r2）：自由走动 + 最外包络（凹包为主、凸包兜底）**。
2. ~~GPX 导入模式~~ **已裁决（r2）：借鉴 GPS 质量轨迹导入（三步向导 + 后端 parse 端点）**。
3. **设计整体批准？**（本 r2 文档）
4. **后端两处防御性校验**是否随 P1 做——r2 后风险大头已消解，仍推荐作为手动录入路径兜底。
5. **入口形态**：类型下拉加「轨迹采集」项（现方案，改动最小）vs 围栏页独立入口按钮。
6. P3 备选项是否有想提前的（带洞围栏不建议提前）。
