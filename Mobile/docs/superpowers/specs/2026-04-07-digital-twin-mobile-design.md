# 数智孪生移动端扩展设计

> 日期: 2026-04-07
> 状态: 已批准
> 范围: Flutter 移动端 + Mock Server 扩展

## 一、背景与目标

在现有智慧畜牧 App（Flutter + Riverpod）基础上，新增 4 个数智孪生场景功能模块，将 App 从基础 GPS 围栏管理升级为覆盖牲畜全生命周期的智能管理平台。

**本次实现 4 个场景**：
1. 发热预警（瘤胃温度 → 基线偏离预警）
2. 消化管理（蠕动传感器 → 消化健康评分）
3. 发情识别（多传感器融合 → AI 评分 + 配种提醒）
4. 疫病防控（群体趋势分析 + 接触链路）

**数据策略**：Mock 数据先行，接口设计兼容后续替换真实 IoT 数据源。

**版本路线图说明**：CLAUDE.md 版本路线图将"瘤胃温度/蠕动监测"置于 V1.5、"步态分析+发情检测"置于 V2.0。本次将发热预警和消化管理提前实现（Mock 阶段验证 UI 流程），发情识别和疫病防控同步以 Mock 形式落地。实施完成后需更新 CLAUDE.md 版本路线图。

## 二、架构决策

### 2.1 模块结构

采用方案 A：每个场景作为独立 feature 模块，与现有模块平行并列，共享部分放 core 层。

```
lib/
├── core/
│   ├── models/
│   │   └── twin_models.dart          # 新增：4 个场景的共享数据模型
│   └── data/
│       └── twin_seed.dart            # 新增：场景 Mock 数据
├── features/
│   ├── pages/
│   │   ├── twin_overview_page.dart   # 替换 dashboard_page.dart
│   │   ├── widgets/
│   │   │   └── twin_scene_card.dart  # 场景入口卡片组件
│   │   ├── fever_warning_page.dart
│   │   ├── digestive_page.dart
│   │   ├── estrus_page.dart
│   │   └── epidemic_page.dart
│   ├── twin_overview/
│   │   ├── domain/twin_overview_repository.dart
│   │   ├── data/mock_twin_overview_repository.dart
│   │   ├── data/live_twin_overview_repository.dart
│   │   └── presentation/twin_overview_controller.dart
│   ├── fever_warning/
│   │   ├── domain/fever_repository.dart
│   │   ├── data/mock_fever_repository.dart
│   │   ├── data/live_fever_repository.dart
│   │   └── presentation/fever_controller.dart
│   │   └── presentation/widgets/temperature_chart.dart
│   ├── digestive/
│   │   ├── domain/digestive_repository.dart
│   │   ├── data/mock_digestive_repository.dart
│   │   ├── data/live_digestive_repository.dart
│   │   └── presentation/digestive_controller.dart
│   │   └── presentation/widgets/motility_chart.dart
│   ├── estrus/
│   │   ├── domain/estrus_repository.dart
│   │   ├── data/mock_estrus_repository.dart
│   │   ├── data/live_estrus_repository.dart
│   │   └── presentation/estrus_controller.dart
│   │   └── presentation/widgets/estrus_trend_chart.dart
│   └── epidemic/
│       ├── domain/epidemic_repository.dart
│       ├── data/mock_epidemic_repository.dart
│       ├── data/live_epidemic_repository.dart
│       └── presentation/epidemic_controller.dart
```

### 2.2 导航变更

**owner 角色**底部导航从：

```
看板 | 地图 | 告警 | 我的 | 围栏
```

替换为：

```
孪生 | 地图 | 告警 | 我的 | 围栏
```

**worker 角色**底部导航同样将"看板"替换为"孪生"，可见导航变为：

```
孪生 | 地图 | 告警 | 我的 | 围栏
```

worker 在孪生场景中仅可查看数据，不可执行操作（如处理告警、标记配种等）。

**ops 角色**不变，仅可见租户管理后台。

### 2.3 路由定义

```
/twin                       → TwinOverviewPage（总览：统计卡 + 4 个场景入口卡片）
/twin/fever                 → FeverWarningPage（发热预警列表）
/twin/fever/:livestockId    → FeverDetailPage（个体体温详情）
/twin/digestive             → DigestivePage（消化管理列表）
/twin/digestive/:livestockId → DigestiveDetailPage（个体消化详情）
/twin/estrus                → EstrusPage（发情识别列表）
/twin/estrus/:livestockId   → EstrusDetailPage（个体发情详情）
/twin/epidemic              → EpidemicPage（疫病防控概览）
```

`/dashboard` 路由替换为 `/twin`，`AppRoute` 枚举更新。列表页中点击个体跳转到对应的 `:livestockId` 详情页。

### 2.4 权限定义

| 权限码 | owner | worker | ops |
|--------|-------|--------|-----|
| `twin:view` | ✅ | ✅ | ❌ |
| `twin:fever` | ✅ | ✅（只读） | ❌ |
| `twin:digestive` | ✅ | ✅（只读） | ❌ |
| `twin:estrus` | ✅ | ✅（只读） | ❌ |
| `twin:epidemic` | ✅ | ✅（只读） | ❌ |

Mock Server 中间件使用 `requirePermission('twin:view')` 保护所有 `/api/twin/*` 端点。

## 三、共享数据模型

文件：`core/models/twin_models.dart`

所有模型类使用 `const` 构造函数。每个场景的 Repository 返回包装了 `ViewState` 的 `ViewData` 对象，与现有模式一致。

### 3.1 ViewData 包装器

所有 ViewData 遵循现有模式（参照 `DashboardViewData`、`AlertsViewData`），使用 `const` 构造函数，包含 `ViewState` 和 `message` 字段。

```dart
// 总览页 ViewData
class TwinOverviewViewData {
  final ViewState viewState;
  final TwinOverviewStats? stats;
  final TwinSceneSummary? sceneSummary;
  final String? message;
  const TwinOverviewViewData({required this.viewState, this.stats, this.sceneSummary, this.message});
}

class TwinOverviewStats {
  final int totalLivestock;
  final double healthyRate;
  final int alertCount;
  final int criticalCount;
  final double deviceOnlineRate;
  const TwinOverviewStats({...});
}

class TwinSceneSummary {
  final SceneSummaryFever fever;
  final SceneSummaryDigestive digestive;
  final SceneSummaryEstrus estrus;
  final SceneSummaryEpidemic epidemic;
  const TwinSceneSummary({...});
}

class SceneSummaryFever {
  final int abnormalCount;
  final int criticalCount;
  const SceneSummaryFever({required this.abnormalCount, required this.criticalCount});
}

class SceneSummaryDigestive {
  final int abnormalCount;
  final int watchCount;
  const SceneSummaryDigestive({required this.abnormalCount, required this.watchCount});
}

class SceneSummaryEstrus {
  final int highScoreCount;
  final bool breedingAdvice;
  const SceneSummaryEstrus({required this.highScoreCount, required this.breedingAdvice});
}

class SceneSummaryEpidemic {
  final String status;  // normal / warning
  final double abnormalRate;
  const SceneSummaryEpidemic({required this.status, required this.abnormalRate});
}

// 发热预警 ViewData
class FeverViewData {
  final ViewState viewState;
  final List<TemperatureBaseline> items;
  final String? message;
  const FeverViewData({required this.viewState, this.items = const [], this.message});
}

// 消化管理 ViewData
class DigestiveViewData {
  final ViewState viewState;
  final List<DigestiveHealth> items;
  final String? message;
  const DigestiveViewData({required this.viewState, this.items = const [], this.message});
}

// 发情识别 ViewData
class EstrusViewData {
  final ViewState viewState;
  final List<EstrusScore> items;
  final String? message;
  const EstrusViewData({required this.viewState, this.items = const [], this.message});
}

// 疫病防控 ViewData
class EpidemicViewData {
  final ViewState viewState;
  final HerdHealthMetrics? metrics;
  final List<ContactTrace> contacts;
  final String? message;
  const EpidemicViewData({required this.viewState, this.metrics, this.contacts = const [], this.message});
}
```

### 3.2 体温数据

```dart
class TemperatureRecord {
  final String livestockId;
  final double temperature;   // °C
  final DateTime timestamp;
  const TemperatureRecord({required this.livestockId, required this.temperature, required this.timestamp});
}

class TemperatureBaseline {
  final String livestockId;
  final double baselineTemp;     // 基线温度（7 天均值）
  final double threshold;        // 预警阈值（基线 + 0.5°C）
  final List<TemperatureRecord> recent72h;
  final String status;           // normal / warning / critical
  final String? conclusion;      // AI 判断结论
  const TemperatureBaseline({...});
}
```

### 3.3 蠕动数据

```dart
class MotilityRecord {
  final String livestockId;
  final double frequency;    // 次/分钟
  final double intensity;    // 强度 0-1
  final DateTime timestamp;
  const MotilityRecord({required this.livestockId, required this.frequency, required this.intensity, required this.timestamp});
}

class DigestiveHealth {
  final String livestockId;
  final double motilityBaseline;
  final String status;            // normal / warning / critical
  final String? advice;
  final List<MotilityRecord> recent24h;
  const DigestiveHealth({...});
}
```

### 3.4 发情评分

```dart
class EstrusScore {
  final String livestockId;
  final int score;                // 0-100
  final int stepIncreasePercent;
  final double tempDelta;
  final double distanceDelta;
  final DateTime timestamp;
  final String? advice;
  const EstrusScore({...});
}
```

### 3.5 疫病防控

```dart
class HerdHealthMetrics {
  final double avgTemperature;
  final double avgActivity;
  final double abnormalRate;
  final int totalLivestock;
  final int abnormalCount;
  final List<ContactTrace> contactTraces;
  const HerdHealthMetrics({...});
}

class ContactTrace {
  final String fromId;
  final String toId;
  final DateTime lastContact;
  final double proximity;  // 接近距离（米）
  const ContactTrace({...});
}
```

### 3.6 Mock 数据策略

`core/data/twin_seed.dart` 包含：
- ~20 头牲畜的体温记录（7 天，每 30 分钟一条，含 2-3 头异常）
- ~20 头牲畜的蠕动记录（24 小时，含 1 头蠕动停止）
- ~15 头可繁殖母牛的发情评分（含 2 头高分）
- 群体健康指标 + 3 条接触链路

## 四、Repository 接口

每个场景的 Repository 接口遵循同步加载模式（与现有 `DashboardRepository` 一致），Controller 遵循 `DashboardController` 模式（`appModeProvider` 切换 mock/live，`setViewState` 方法）。

### 4.0 TwinOverviewRepository

```dart
abstract class TwinOverviewRepository {
  TwinOverviewViewData load([ViewState desiredState = ViewState.normal]);
}
```

Controller 遵循 `DashboardController` 模式：

```dart
final twinOverviewRepositoryProvider = Provider<TwinOverviewRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock: return const MockTwinOverviewRepository();
    case AppMode.live: return const LiveTwinOverviewRepository();
  }
});

class TwinOverviewController extends Notifier<TwinOverviewViewData> {
  @override
  TwinOverviewViewData build() {
    return ref.watch(twinOverviewRepositoryProvider).load(ViewState.normal);
  }
  void setViewState(ViewState viewState) {
    state = ref.read(twinOverviewRepositoryProvider).load(viewState);
  }
}
```

### 4.1 FeverRepository

```dart
abstract class FeverRepository {
  FeverViewData load([ViewState desiredState = ViewState.normal]);
  TemperatureBaseline? loadDetail(String livestockId);
}
```

- `load()` — 返回所有/异常个体的列表，`desiredState` 用于 StateSwitchBar 演示
- `loadDetail(livestockId)` — 返回指定个体的 72h 体温详情

### 4.2 DigestiveRepository

```dart
abstract class DigestiveRepository {
  DigestiveViewData load([ViewState desiredState = ViewState.normal]);
  DigestiveHealth? loadDetail(String livestockId);
}
```

### 4.3 EstrusRepository

```dart
abstract class EstrusRepository {
  EstrusViewData load([ViewState desiredState = ViewState.normal]);
  EstrusScore? loadDetail(String livestockId);
}
```

### 4.4 EpidemicRepository

```dart
abstract class EpidemicRepository {
  EpidemicViewData load([ViewState desiredState = ViewState.normal]);
}
```

### 4.5 Live Repository 与 ApiCache 扩展

Live 模式下，每个模块的 `Live*Repository` 从 `ApiCache` 同步读取预加载的数据。

**ApiCache 新增字段**：

```dart
// api_cache.dart 新增
Map<String, dynamic>? twinOverview;
List<dynamic>? feverList;
List<dynamic>? digestiveList;
List<dynamic>? estrusList;
Map<String, dynamic>? epidemicSummary;
List<dynamic>? epidemicContacts;
```

**ApiCache.init() 扩展**：

在现有 6 个预加载请求基础上，并发新增 6 个 GET 请求：

```dart
// 并发预加载 twin 端点
final twinFutures = [
  _fetch('/api/twin/overview'),
  _fetch('/api/twin/fever/list'),
  _fetch('/api/twin/digestive/list'),
  _fetch('/api/twin/estrus/list'),
  _fetch('/api/twin/epidemic/summary'),
  _fetch('/api/twin/epidemic/contacts'),
];
```

Live*Repository 的 fallback 策略：若 ApiCache 未初始化或缓存为空，fallback 到对应的 MockXxxRepository（与现有 LiveDashboardRepository 模式一致）。

## 五、总览页（TwinOverviewPage）— UI 详细规格

### 5.1 整体布局

页面使用 `SingleChildScrollView`，内边距 `EdgeInsets.all(16)`。纵向排列三个区域：

```
┌─────────────────────────────────┐
│ ① 牧场头部卡片                    │  height: auto
├─────────────────────────────────┤
│ ② 统计卡片区 (2×2 网格)           │  height: auto
├─────────────────────────────────┤
│ ③ 场景入口卡片区 (纵向列表)        │  height: auto
│   ├─ 发热预警卡片                  │
│   ├─ 消化管理卡片                  │
│   ├─ 发情识别卡片                  │
│   └─ 疫病防控卡片                  │
└─────────────────────────────────┘
```

### 5.2 ① 牧场头部卡片

复用现有 `_DashboardFarmHeader` 组件模式，使用 `HighfiCard` 包裹。

| 属性 | 规格 |
|------|------|
| 容器 | `HighfiCard` → `Card` + `Padding(all: 16)` |
| 牧场名称 | `Theme.of(context).textTheme.titleLarge`，颜色 `AppColors.textPrimary` |
| 副标题 | `Theme.of(context).textTheme.bodySmall`，颜色 `AppColors.textSecondary`，内容："晴 18°C · 最近同步 2 分钟前" |
| 状态标签 | 复用 `HighfiStatusChip`，标签文字改为"数智孪生已同步" |

**Widget 树**：
```
HighfiCard
  └─ Column(crossAxisAlignment: start)
       ├─ Text("阿尔卑斯北麓牧场", style: titleLarge)
       ├─ SizedBox(height: 8)
       ├─ Text("晴 18°C · 最近同步 2 分钟前", style: bodySmall, color: textSecondary)
       ├─ SizedBox(height: 12)
       └─ Wrap(spacing: 8)
            ├─ HighfiStatusChip("数智孪生已同步", color: info, icon: cloud_done)
            └─ HighfiStatusChip.fromViewState(normal)
```

### 5.3 ② 统计卡片区

2×2 网格布局，使用 `GridView.count(crossAxisCount: 2)` 或 `Wrap` 实现。数据来自 `GET /api/twin/overview` 的 `stats` 字段。

**间距规格**：
- 网格间距：`mainAxisSpacing: 12, crossAxisSpacing: 12`（对应 `AppSpacing.md`）
- 卡片宽高比：约 1.1（宽度 100%，高度约 100-110）
- 区域上边距：`SizedBox(height: 16)` 与头部卡片分隔

**四张统计卡片**，复用 `HighfiStatTile` 组件：

| 卡片 | title | value | trend | caption | onTap |
|------|-------|-------|-------|---------|-------|
| 牲畜总数 | "牲畜总数" | "3,847" | "+12 本周新增" | "牛 2,156 / 羊 1,691" | `context.go('/twin/epidemic')` |
| 健康率 | "健康率" | "99.1%" | "+0.3%" | "健康个体 3,812" | null |
| 预警数量 | "预警数量" | "35" | null | "紧急 3 / 一般 32" | `context.go('/alerts')` |
| 设备在线 | "设备在线" | "97.8%" | null | "传感器 1,247 在线" | null |

**预警卡片特殊处理**：当 `alertCount > 0` 时，value 文字颜色使用 `AppColors.warning`；当 `criticalCount > 0` 时，value 文字颜色使用 `AppColors.danger`。

**Widget 树**：
```
Column
  └─ SizedBox(height: 16)  // 与头部卡片间距
  └─ GridView.count(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1, shrinkWrap: true, physics: NeverScrollableScrollPhysics())
       ├─ HighfiStatTile(title="牲畜总数", value="3,847", ...)
       ├─ HighfiStatTile(title="健康率", value="99.1%", ...)
       ├─ HighfiStatTile(title="预警数量", value="35", ...)  // 条件颜色
       └─ HighfiStatTile(title="设备在线", value="97.8%", ...)
```

### 5.4 ③ 场景入口卡片区

纵向列表，每张卡片是一个独立的可点击区域。数据来自 `GET /api/twin/overview` 的 `sceneSummary` 字段。

**区域间距**：与统计卡片区之间 `SizedBox(height: 16)`。
**卡片之间间距**：`SizedBox(height: 12)`（对应 `AppSpacing.md`）。

#### 场景卡片组件（TwinSceneCard）

新建 Widget `TwinSceneCard`，位于 `features/pages/widgets/twin_scene_card.dart`。

**布局规格**：

```
┌─────────────────────────────────────┐
│ ┌─┐                                 │  ← 左侧指示条（4dp 宽，圆角 2dp）
│ │ │  [icon]  场景名称          →     │  ← icon 24x24, 场景名 bodyLarge
│ │ │         关键指标 · 状态描述       │  ← bodySmall, textSecondary
│ └─┘                                 │
└─────────────────────────────────────┘
```

**组件属性**：

| 属性 | 类型 | 说明 |
|------|------|------|
| `icon` | `IconData` | 场景图标 |
| `title` | `String` | 场景名称 |
| `summary` | `String` | 关键指标摘要（如"3 头异常 · 2 紧急"） |
| `alertLevel` | `String?` | "critical" / "warning" / null |
| `onTap` | `VoidCallback` | 导航到详情页 |

**样式规格**：

| 元素 | 规格 |
|------|------|
| 卡片容器 | `HighfiCard` → `Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: 16))` |
| 内边距 | `Padding(all: 16)` |
| 左侧指示条 | `Container(width: 4, height: 全高, borderRadius: 2)` |
| 指示条颜色 | critical → `AppColors.danger`，warning → `AppColors.warning`，null → `AppColors.primarySoft` |
| 图标 | `Icon(icon, size: 24, color: AppColors.textSecondary)` |
| 场景名称 | `Theme.of(context).textTheme.bodyLarge`，颜色 `AppColors.textPrimary` |
| 指标摘要 | `Theme.of(context).textTheme.bodySmall`，颜色 `AppColors.textSecondary` |
| 右侧箭头 | `Icon(Icons.chevron_right, color: AppColors.textSecondary)` |

**Widget 树**：
```
HighfiCard(padding: zero)
  └─ Material(transparent)
       └─ InkWell(borderRadius: 16, onTap: onTap)
            └─ Padding(all: 16)
                 └─ Row(crossAxisAlignment: center)
                      ├─ _AlertIndicator(level: alertLevel)  // 左侧指示条 4dp
                      ├─ SizedBox(width: 12)
                      ├─ Icon(icon, size: 24)                // 场景图标
                      ├─ SizedBox(width: 12)
                      ├─ Expanded
                      │    └─ Column(crossAxisAlignment: start)
                      │         ├─ Text(title, style: bodyLarge)
                      │         ├─ SizedBox(height: 4)
                      │         └─ Text(summary, style: bodySmall, color: textSecondary)
                      └─ Icon(Icons.chevron_right, color: textSecondary)
```

#### 四张场景卡片数据

| 场景 | icon | title | summary | alertLevel | onTap 路由 |
|------|------|-------|---------|------------|-----------|
| 发热预警 | `Icons.thermostat_outlined` | "发热预警" | "3 头异常 · 2 紧急" | critical（当 criticalCount > 0） | `/twin/fever` |
| 消化管理 | `Icons.monitor_heart_outlined` | "消化管理" | "1 头蠕动停止 · 5 关注" | critical | `/twin/digestive` |
| 发情识别 | `Icons.favorite_outline` | "发情识别" | "2 头高分 · 建议配种" | warning | `/twin/estrus` |
| 疫病防控 | `Icons.shield_outlined` | "疫病防控" | "群体正常 · 异常率 0.9%" | null | `/twin/epidemic` |

#### 左侧指示条组件（_AlertIndicator）

私有 Widget，内嵌在 `TwinSceneCard` 中：

```dart
class _AlertIndicator extends StatelessWidget {
  final String? level;  // "critical" | "warning" | null
  // 高度由父 Row 撑满
  // 宽度: 4, borderRadius: 2
  // 颜色映射:
  //   critical → AppColors.danger
  //   warning  → AppColors.warning
  //   null     → AppColors.primarySoft
}
```

### 5.5 空状态与错误处理

复用现有 `HighfiEmptyErrorState` 组件，与 `DashboardPage` 的 ViewState 分支一致：

| ViewState | 标题 | 描述 | 图标 |
|-----------|------|------|------|
| loading | — | `CircularProgressIndicator` | — |
| empty | "暂无孪生数据" | "演示空状态：可去地图或告警页查看。" | `inbox_outlined` |
| error | "孪生数据加载失败" | "当前使用演示数据源，可稍后重试。" | `wifi_tethering_error_rounded` |
| forbidden | "暂无查看权限" | "当前角色仅可查看授权范围内的孪生信息。" | `lock_outline_rounded` |
| offline | "当前为离线快照" | "已展示最近一次同步的牧场概览数据。" | `cloud_off_rounded` |

### 5.6 数据流

```
TwinOverviewPage (ConsumerWidget)
  → ref.watch(twinOverviewControllerProvider)   // 新增 Riverpod controller
    → TwinOverviewRepository.load(viewState)
      → Mock: 读取 twin_seed.dart 汇总数据
      → Live: 读取 ApiCache.twinOverview
  → 根据 ViewState 分支渲染 UI
```

**新增 Controller**：`twin_overview_controller.dart` 位于 `features/twin_overview/presentation/`，遵循现有 `DashboardController` 的模式（`setViewState` 方法 + `load` 数据）。

## 六、场景详情页 — UI 详细规格

### 6.0 通用模式

所有 4 个场景详情页共享以下通用模式：

**筛选机制**：客户端过滤。Repository.load() 返回全量数据，Controller 提供 `setFilter(String? status)` 方法，由 UI 层根据 filter 对 `items` 做客户端过滤。不增加 API 参数复杂度。

**StateSwitchBar 集成**：每个场景页面顶部集成 `StateSwitchBar`（与现有 Dashboard 一致），支持切换 normal/loading/empty/error/forbidden/offline 状态。`setViewState` 方法已在 Repository 接口中定义。

**页面结构**：每个场景页分为列表页（`XxxPage`）和详情页（`XxxDetailPage`）。列表页展示个体列表，点击跳转到详情子路由。详情页接收 `livestockId` 路由参数，调用 Repository.loadDetail() 获取数据。

**列表项组件**：每个场景定义自己的列表项 Widget（如 `_FeverListItem`），内嵌在各场景目录下。

**通用列表项布局**（所有场景复用的行结构）：

```
┌─────────────────────────────────────┐
│ [状态点]  牲畜ID          [指标值]   │  ← Row, 主行
│           状态描述文字        [时间]   │  ← Row, 副行
└─────────────────────────────────────┘
```

### 6.1 发热预警

#### 列表页（FeverWarningPage）

**页面结构**：

```
SingleChildScrollView(padding: all(16))
  └─ Column
       ├─ HighfiCard  (标题区)
       │    ├─ Text("发热预警", style: titleLarge)
       │    ├─ SizedBox(height: 8)
       │    ├─ Text("瘤胃温度基线偏离检测，实时监控个体体温异常。", style: bodySmall)
       │    ├─ SizedBox(height: 12)
       │    └─ StateSwitchBar(onChanged: controller.setViewState)
       ├─ SizedBox(height: 12)
       ├─ _FilterChips(filter: currentFilter, onChanged: controller.setFilter)
       │    ├─ ChoiceChip("全部", selected: filter == null)
       │    ├─ ChoiceChip("异常", selected: filter == "abnormal")
       │    └─ ChoiceChip("紧急", selected: filter == "critical")
       ├─ SizedBox(height: 12)
       └─ filteredItems.map((item) => _FeverListItem(item, onTap: () => context.go('/twin/fever/${item.livestockId}')))
            └─ SizedBox(height: 8) // 列表项间距
```

**列表项 `_FeverListItem`**：

```
HighfiCard(padding: zero)
  └─ InkWell(borderRadius: 16, onTap: onTap)
       └─ Padding(all: 16)
            └─ Row(crossAxisAlignment: center)
                 ├─ Container(  // 状态点 12x12
                 │    width: 12, height: 12, borderRadius: 6,
                 │    color: critical → danger, warning → warning, normal → success
                 │  )
                 ├─ SizedBox(width: 12)
                 ├─ Expanded
                 │    └─ Column(crossAxisAlignment: start)
                 │         ├─ Row(children: [
                 │         │    Text("牛#${item.livestockId}", style: bodyLarge, color: textPrimary),
                 │         │    Spacer(),
                 │         │    Text("${item.currentTemp}°C", style: titleMedium, color: conditionalColor),
                 │         │  ])
                 │         ├─ SizedBox(height: 4)
                 │         └─ Row(children: [
                 │              Expanded(child: Text(item.conclusion, style: bodySmall, color: textSecondary)),
                 │              Text("↑${item.delta}°C", style: labelSmall, color: warning),
                 │            ])
                 └─ Icon(Icons.chevron_right, color: textSecondary)
```

**条件颜色**：当 `status == "critical"` 时，温度值用 `AppColors.danger`；`warning` 时用 `AppColors.warning`。

#### 详情页（FeverDetailPage）

接收路由参数 `livestockId`，调用 `feverRepositoryProvider.loadDetail(livestockId)` 获取 `TemperatureBaseline`。

**页面结构**：

```
Scaffold(appBar: AppBar(title: "牛#${baseline.livestockId} 体温详情"))
  └─ SingleChildScrollView(padding: all(16))
       └─ Column
            ├─ HighfiCard  (状态摘要)
            │    └─ Row
            │         ├─ Column
            │         │    ├─ Text("当前状态", style: bodySmall, color: textSecondary)
            │         │    ├─ Text(statusLabel, style: titleLarge, color: statusColor)
            │         │    └─ Text(baseline.conclusion, style: bodySmall)
            │         └─ Column
            │              ├─ Text("基线温度", style: labelSmall, color: textSecondary)
            │              └─ Text("${baseline.baselineTemp}°C", style: titleMedium)
            ├─ SizedBox(height: 16)
            ├─ HighfiCard  (温度曲线图)
            │    ├─ Text("72小时体温曲线", style: titleSmall)
            │    ├─ SizedBox(height: 12)
            │    └─ TemperatureChart(records: baseline.recent72h,
            │         baselineTemp: baseline.baselineTemp,
            │         threshold: baseline.threshold)
            ├─ SizedBox(height: 16)
            └─ HighfiCard  (AI 判断)
                 ├─ Row(children: [
                 │    Icon(Icons.psychology_outlined, color: info),
                 │    SizedBox(width: 8),
                 │    Text("AI 判断", style: titleSmall),
                 │  ])
                 ├─ SizedBox(height: 8)
                 └─ Text(baseline.conclusion, style: bodyMedium)
```

**TemperatureChart** 组件规格（`fever_warning/presentation/widgets/temperature_chart.dart`）：
- 高度：200
- 使用 `fl_chart` `LineChart`
- Y 轴范围：baselineTemp - 1.0 到 baselineTemp + 2.0
- 基线标线：`baselineTemp` 虚线，颜色 `AppColors.success`
- 预警阈值标线：`threshold` 虚线，颜色 `AppColors.warning`
- 数据线：颜色 `AppColors.info`
- 超过阈值的点：红色圆点 + `AppColors.danger`
- 正常范围的点：蓝色圆点 + `AppColors.info`

### 6.2 消化管理

#### 列表页（DigestivePage）

结构与 FeverWarningPage 一致，替换为消化管理的标题和筛选。

```
SingleChildScrollView(padding: all(16))
  └─ Column
       ├─ HighfiCard(标题: "消化管理", 副标题: "瘤胃蠕动频率监测，消化系统健康预警。")
       │    └─ StateSwitchBar
       ├─ _FilterChips(全部 | 异常 | 关注)
       └─ _DigestiveListItem 列表
```

**列表项 `_DigestiveListItem`**：

```
HighfiCard → InkWell → Padding(all: 16) → Row
  ├─ 状态点 (12x12, critical→danger, warning→warning, normal→success)
  ├─ SizedBox(width: 12)
  ├─ Expanded → Column
  │    ├─ Row: [Text("牛#${id}"), Spacer(), Text(motilityStatus)]
  │    └─ Row: [Expanded(Text(advice)), Text(frequency + "次/分")]
  └─ Icon(chevron_right)
```

`motilityStatus` 显示：critical → "蠕动停止"，warning → "蠕动下降"，normal → "正常"。

#### 详情页（DigestiveDetailPage）

```
Scaffold(appBar: "牛#${id} 消化详情")
  └─ SingleChildScrollView(padding: all(16))
       └─ Column
            ├─ HighfiCard(状态摘要: 当前状态 + 蠕动基线)
            ├─ HighfiCard(24h蠕动趋势图)
            │    └─ MotilityChart(records: recent24h, baseline: motilityBaseline)
            └─ HighfiCard(建议操作: advice 文本)
```

**MotilityChart** 组件规格（`digestive/presentation/widgets/motility_chart.dart`）：
- 高度：200
- `LineChart`，Y 轴范围：0 到 baseline * 1.5
- 基线标线：虚线，颜色 `AppColors.success`
- 数据线：颜色 `AppColors.accent`
- frequency == 0 的区间：红色背景填充

### 6.3 发情识别

#### 列表页（EstrusPage）

```
SingleChildScrollView(padding: all(16))
  └─ Column
       ├─ HighfiCard(标题: "发情识别", 副标题: "多传感器融合评分，精准配种时机提醒。")
       │    └─ StateSwitchBar
       ├─ _FilterChips(高分优先 | 全部)
       └─ _EstrusListItem 列表（按 score 降序排列）
```

"高分优先"筛选：score >= 70 的个体。"全部"：显示所有可繁殖母牛。

**列表项 `_EstrusListItem`**：

```
HighfiCard → InkWell → Padding(all: 16) → Row
  ├─ Container(  // 评分圆形徽章 48x48
  │    borderRadius: 24,
  │    color: score >= 80 ? danger.withOpacity(0.1) : warning.withOpacity(0.1),
  │    child: Center(Text("${score}", style: titleMedium, color: conditionalColor))
  │  )
  ├─ SizedBox(width: 12)
  ├─ Expanded → Column
  │    ├─ Row: [Text("牛#${id}"), Spacer(), Text("评分 ${score}/100")]
  │    └─ Row: [Text("步数+${stepIncreasePercent}%", style: labelSmall, color: textSecondary), SizedBox(width: 8), Text(advice, style: labelSmall, color: warning)]
  └─ Icon(chevron_right)
```

评分颜色：score >= 80 → `AppColors.danger`，score >= 50 → `AppColors.warning`，其他 → `AppColors.textSecondary`。

#### 详情页（EstrusDetailPage）

```
Scaffold(appBar: "牛#${id} 发情详情")
  └─ SingleChildScrollView(padding: all(16))
       └─ Column
            ├─ HighfiCard(评分摘要: 当前评分 + 配种建议)
            │    └─ Row
            │         ├─ Column(评分环形进度 + 数字)
            │         └─ Column(多指标列表)
            │              ├─ _MetricRow("步数增长", "+${stepIncreasePercent}%")
            │              ├─ _MetricRow("体温变化", "+${tempDelta}°C")
            │              └─ _MetricRow("距离变化", "+${distanceDelta}km")
            ├─ HighfiCard(7天发情指数趋势)
            │    └─ EstrusTrendChart(trend7d: data.trend7d)
            └─ HighfiCard(配种建议: advice 文本 + 时间窗口)
```

**EstrusTrendChart**（`estrus/presentation/widgets/estrus_trend_chart.dart`）：
- 高度：180
- `LineChart`，Y 轴：0-100
- 阈值线 70 分虚线，颜色 `AppColors.warning`
- 数据线颜色：score >= 70 用 `AppColors.danger`，否则 `AppColors.info`
- 高分区间填充红色渐变背景

### 6.4 疫病防控

#### 列表页（EpidemicPage）

疫病防控页没有个体列表，只有一个整体概览页，不跳转详情子路由。

```
SingleChildScrollView(padding: all(16))
  └─ Column
       ├─ HighfiCard(标题: "疫病防控", 副标题: "群体健康趋势监控，接触链路追踪。")
       │    └─ StateSwitchBar
       ├─ SizedBox(height: 16)
       ├─ Row(children: [  // 指标卡片行
       │    Expanded(child: HighfiCard(child: Column([
       │      Text("平均体温", style: bodySmall, color: textSecondary),
       │      Text("${avgTemperature}°C", style: titleMedium),
       │    ]))),
       │    SizedBox(width: 12),
       │    Expanded(child: HighfiCard(child: Column([
       │      Text("异常率", style: bodySmall, color: textSecondary),
       │      Text("${abnormalRate}%", style: titleMedium, color: abnormalRate > 2 ? danger : success),
       │    ]))),
       │ ])
       ├─ SizedBox(height: 12)
       ├─ Row(children: [
       │    Expanded(child: HighfiCard(child: Column([
       │      Text("异常个体", style: bodySmall, color: textSecondary),
       │      Text("${abnormalCount}", style: titleMedium),
       │    ]))),
       │    SizedBox(width: 12),
       │    Expanded(child: HighfiCard(child: Column([
       │      Text("活动量指数", style: bodySmall, color: textSecondary),
       │      Text("${avgActivity}", style: titleMedium),
       │    ]))),
       │ ])
       ├─ SizedBox(height: 16)
       └─ HighfiCard  (接触链路)
            ├─ Row(children: [
            │    Icon(Icons.share_outlined, color: info),
            │    SizedBox(width: 8),
            │    Text("接触链路追踪", style: titleSmall),
            │  ])
            ├─ SizedBox(height: 12)
            └─ Column(children: contacts.map(_ContactTraceItem))
```

#### 接触链路可视化

采用**简化列表形式**（非网络图），每条接触记录一个列表项：

**`_ContactTraceItem` 布局**：

```
Padding(vertical: 8) → Row
  ├─ Icon(Icons.cattle, size: 20, color: danger)  // 源个体（异常）
  ├─ SizedBox(width: 4)
  ├─ Text("牛#${fromId}", style: bodySmall, color: danger)
  ├─ SizedBox(width: 8)
  ├─ Icon(Icons.arrow_forward, size: 16, color: textSecondary)
  ├─ SizedBox(width: 8)
  ├─ Text("牛#${toId}", style: bodySmall, color: warning)  // 接触个体（标黄）
  ├─ Spacer()
  └─ Column(crossAxisAlignment: end)
       ├─ Text("${proximity}m", style: labelSmall, color: textSecondary)
       └─ Text(timeAgo, style: labelSmall, color: textSecondary)
```

选择列表而非网络图的理由：移动端屏幕空间有限，网络图需要缩放/拖拽交互，实现复杂度高且不如列表直观。后续 MVP 阶段可升级为地图叠加或网络图。

## 七、图表组件策略

### 7.1 依赖

使用 `fl_chart` 包绘制所有图表。

### 7.2 组件划分

图表 Widget 放在各场景模块的 `presentation/widgets/` 子目录中，不做全局共享（当前各场景图表类型不同，过早抽象收益低）：

```
fever_warning/presentation/widgets/temperature_chart.dart   # 72h 体温曲线
digestive/presentation/widgets/motility_chart.dart          # 24h 蠕动频率趋势
estrus/presentation/widgets/estrus_trend_chart.dart         # 7天发情指数趋势
```

### 7.3 数据转换

每个图表 Widget 接收领域模型（如 `List<TemperatureRecord>`），内部转换为 `fl_chart` 的 `FlSpot`：

```dart
// temperature_chart.dart 内部
List<FlSpot> _toSpots(List<TemperatureRecord> records) {
  return records.map((r) {
    final x = r.timestamp.millisecondsSinceEpoch.toDouble();
    final y = r.temperature;
    return FlSpot(x, y);
  }).toList();
}
```

## 八、Mock Server 扩展

### 8.1 新增端点与响应 Schema

#### GET /api/twin/overview

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-twin-overview",
  "data": {
    "stats": {
      "totalLivestock": 3847,
      "healthyRate": 99.1,
      "alertCount": 35,
      "deviceOnlineRate": 97.8
    },
    "sceneSummary": {
      "fever": { "abnormalCount": 3, "criticalCount": 2 },
      "digestive": { "abnormalCount": 1, "watchCount": 5 },
      "estrus": { "highScoreCount": 2, "breedingAdvice": true },
      "epidemic": { "status": "normal", "abnormalRate": 0.9 }
    }
  }
}
```

#### GET /api/twin/fever/list?status=abnormal

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-fever-list",
  "data": {
    "items": [
      {
        "livestockId": "3872",
        "currentTemp": 39.8,
        "baselineTemp": 38.6,
        "delta": 1.2,
        "status": "critical",
        "conclusion": "疑似早期感染",
        "updatedAt": "2026-04-07T10:30:00Z"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 3
  }
}
```

#### GET /api/twin/fever/:id

`:id` 为 `livestockId`。

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-fever-detail",
  "data": {
    "livestockId": "3872",
    "baselineTemp": 38.6,
    "threshold": 39.1,
    "status": "critical",
    "conclusion": "温度升高+活动量下降，高概率感染，建议隔离检查",
    "recent72h": [
      { "temperature": 38.5, "timestamp": "2026-04-04T08:00:00Z" },
      { "temperature": 38.7, "timestamp": "2026-04-04T08:30:00Z" }
    ]
  }
}
```

#### GET /api/twin/digestive/list

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "items": [
      {
        "livestockId": "1205",
        "currentFrequency": 0.0,
        "baselineFrequency": 1.5,
        "status": "critical",
        "advice": "蠕动完全停止，疑似瘤胃臌气，需立即处理",
        "updatedAt": "2026-04-07T10:22:00Z"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1
  }
}
```

#### GET /api/twin/digestive/:id

`:id` 为 `livestockId`。

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "livestockId": "1205",
    "motilityBaseline": 1.5,
    "status": "critical",
    "advice": "蠕动完全停止，疑似瘤胃臌气，需立即处理",
    "recent24h": [
      { "frequency": 1.4, "intensity": 0.8, "timestamp": "2026-04-06T12:00:00Z" }
    ]
  }
}
```

#### GET /api/twin/estrus/list

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "items": [
      {
        "livestockId": "2158",
        "score": 92,
        "stepIncreasePercent": 320,
        "tempDelta": 0.4,
        "distanceDelta": 3.5,
        "timestamp": "2026-04-07T09:58:00Z",
        "advice": "步数增加320%，建议6小时内配种"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 2
  }
}
```

#### GET /api/twin/estrus/:id

`:id` 为 `livestockId`。

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "livestockId": "2158",
    "score": 92,
    "stepIncreasePercent": 320,
    "tempDelta": 0.4,
    "distanceDelta": 3.5,
    "timestamp": "2026-04-07T09:58:00Z",
    "advice": "建议6小时内配种",
    "trend7d": [
      { "score": 12, "timestamp": "2026-04-01T10:00:00Z" },
      { "score": 15, "timestamp": "2026-04-02T10:00:00Z" }
    ]
  }
}
```

#### GET /api/twin/epidemic/summary

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "avgTemperature": 38.7,
    "avgActivity": 72.5,
    "abnormalRate": 0.9,
    "totalLivestock": 3847,
    "abnormalCount": 35
  }
}
```

#### GET /api/twin/epidemic/contacts

```json
{
  "code": "OK",
  "message": "success",
  "data": {
    "items": [
      {
        "fromId": "3872",
        "toId": "3901",
        "lastContact": "2026-04-07T08:30:00Z",
        "proximity": 5.2
      }
    ],
    "page": 1,
    "pageSize": 50,
    "total": 3
  }
}
```

### 8.2 新增文件

- `backend/routes/twin.js` — 路由处理器
- `backend/data/twin_seed.js` — Mock 数据（与前端 `twin_seed.dart` 对齐）

### 8.3 告警集成

现有告警数据模型扩展 `type` 字段：

```js
// seed.js 中告警条目新增 type 字段
{
  id: 'alert-007',
  type: 'fever_warning',     // 新增字段
  title: '牛#3872 温度异常 — 当前39.8°C，基线38.6°C',
  level: 'critical',
  stage: 'pending',
  occurredAt: '2026-04-07T10:30:00Z'
}
```

前端 `demo_models.dart` 中的 `Alert` 类新增 `type` 字段，告警列表页支持按 `type` 分组筛选。

新增告警种子条目（在 `demo_seed.dart` 和 `seed.js` 中各增加 4-6 条）：

| type | level | title 示例 |
|------|-------|-----------|
| `fever_warning` | critical | 牛#3872 温度异常 — 当前39.8°C |
| `motility_stop` | critical | 牛#1205 蠕动停止 |
| `estrus_high` | warning | 牛#2158 发情指数 92 |
| `herd_abnormal` | warning | A区群体体温偏高 |
| `fever_warning` | warning | 牛#5621 温度轻微升高 |

现有 `level` 字段（critical/warning/info）完全复用，无需修改。

## 九、与现有系统的集成点

| 现有模块 | 变更说明 |
|---------|---------|
| `AppRoute` 枚举 | 新增 twin/fever/feverDetail/digestive/digestiveDetail/estrus/estrusDetail/epidemic 路由，移除 dashboard |
| `app_router.dart` | `/dashboard` → `/twin`，新增子路由 + 3 个详情页 `:livestockId` 路由，路由守卫重定向目标更新 |
| `DemoShell` | 底部导航 owner/worker 第一个 Tab 从"看板"改为"孪生" |
| `dashboard_page.dart` | 替换为 `twin_overview_page.dart`（原文件可保留不删除） |
| `alerts_page.dart` | 支持 `type` 字段筛选，新增 4 种告警类型 |
| `demo_seed.dart` | 告警种子数据中增加新类型条目 |
| `demo_models.dart` | `Alert` 类新增 `type` 字段 |
| `ApiCache` | 新增 6 个 twin 相关缓存字段 + init() 扩展 |
| `RolePermission` | 新增 twin:view 等权限码 |
| `CLAUDE.md` | 更新版本路线图，反映功能范围变化 |

### 迁移影响清单

以下文件需要更新以适配路由变更：

1. **`app_router.dart`** — `redirect` 回调中所有 `/dashboard` 引用改为 `/twin`
2. **`app_route.dart`** — `AppRoute` 枚举更新
3. **`demo_shell.dart`** — 底部导航构建逻辑
4. **测试文件**：
   - `role_visibility_test.dart` — "看板"Tab 相关断言改为"孪生"
   - `flow_smoke_test.dart` — 路由跳转路径更新
   - `widget_smoke_test.dart` — dashboard 相关 key 更新
5. **`CLAUDE.md`** — 目录结构、导航描述、版本路线图

## 十、依赖

- `fl_chart ^0.69.0` — 温度曲线、蠕动趋势、发情指数等图表绘制
- 现有 `flutter_riverpod`、`go_router`、`http` 不变

## 十一、不包含的内容（YAGNI）

以下内容明确不在本次范围：
- 精准灌溉场景（草场管理，不涉及牲畜个体）
- 真实 IoT 传感器数据对接
- AI 模型实现（Mock 阶段用固定文本）
- Web 管理大屏
- FastAPI 后端替换
- 自动控制闭环（饲喂/隔离/灌溉自动执行）
