# 租户管理 Phase 3（可视化与体验）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为租户详情页增加 30 天趋势图表（复用现有降采样策略）、骨架屏加载态、细化空状态视觉，并补齐 Phase 2 未覆盖的测试。

**Architecture:** 新增趋势 Controller + chart widget 复用 `TwinSeriesDownsample` 降采样策略；详情页各卡片从"无 loading 态/隐藏空数据"升级为骨架屏脉冲动画 + 独立空状态占位；Stats 卡片从 Row 布局升级为 GridView 双列布局对齐 twin_overview_page 模式。

**Tech Stack:** Flutter 3.x, flutter_riverpod, fl_chart, go_router, Node.js + Express 5

**被实施规格:** `docs/superpowers/specs/2026-04-20-tenant-management-design.md` Phase 3（§ 图表降采样策略完善、§ 细化骨架屏与空状态视觉、§ 性能与测试覆盖优化）

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P2 | 待创建 | 租户管理 Phase 3：趋势图表 + 骨架屏 + 测试补齐 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-04-27 | 待创建 | feat/tenant-phase3 | Phase 3 可视化与体验 — 8 commits, +19 tests |

---

## 范围界定（Scope）

**本计划覆盖（Phase 3）:**
- 后端：新增 `GET /api/tenants/:id/trends` 趋势端点（30 天每日统计假数据）
- 前端：趋势图表组件（fl_chart 折线图 + 降采样到 7-10 点）
- 前端：详情页骨架屏加载态（脉冲动画占位，不引入新依赖）
- 前端：详情页各卡片独立空状态（替代当前隐藏策略）
- 前端：Stats 卡片从 Row 双行布局改为 GridView 双列布局
- 测试：补齐 Phase 2 三个 Controller（devices/logs/stats）单元测试
- 测试：详情页卡片级 Widget 测试（stats/devices/logs 卡片）
- 测试：后端趋势端点测试

**本计划不覆盖：**
- 新的 npm/flutter 依赖包（骨架屏用手写动画，不引入 shimmer 包）
- 后端真实时间序列存储（仍用 Mock 假数据生成）
- 图表交互（缩放/拖拽/Tooltip）
- 列表页改造（列表页已有 loading 分支，本次仅优化详情页）

---

## 文件结构

### 后端 — 新建

| 文件 | 职责 |
|------|------|
| `backend/test/tenantTrends.test.js` | 趋势端点单元测试 |

### 后端 — 修改

| 文件 | 变更 |
|------|------|
| `backend/routes/tenants.js` | 新增 `GET /:id/trends` 端点 + 导出 `generateTrends` |
| `backend/server.js` | `ROUTE_DEFINITIONS` 注册新路由 |
| `backend/routes/registerApiRoutes.js` | 适配 `{ router, generateTrends }` 解构导入 |

### 前端 — 新建

| 文件 | 职责 |
|------|------|
| `lib/features/tenant/presentation/tenant_trends_controller.dart` | 趋势数据 Notifier.family |
| `lib/features/tenant/presentation/widgets/tenant_trend_chart.dart` | 30 天趋势折线图 widget |
| `lib/features/tenant/presentation/widgets/tenant_skeleton.dart` | 骨架屏脉冲动画 widget |
| `test/features/tenant/tenant_devices_controller_test.dart` | Devices Controller 测试 |
| `test/features/tenant/tenant_logs_controller_test.dart` | Logs Controller 测试 |
| `test/features/tenant/tenant_stats_controller_test.dart` | Stats Controller 测试 |
| `test/features/tenant/tenant_trends_controller_test.dart` | Trends Controller 测试 |
| `test/features/tenant/tenant_detail_cards_test.dart` | 详情页卡片 Widget 测试 |

### 前端 — 修改

| 文件 | 变更 |
|------|------|
| `lib/features/tenant/domain/tenant_view_data.dart` | 新增 `TenantTrendsViewData`、`DailyStatPoint` |
| `lib/features/tenant/domain/tenant_repository.dart` | 新增 `loadTrends(String id)` 方法 |
| `lib/features/tenant/data/mock_tenant_repository.dart` | 实现 `loadTrends`（30 天趋势假数据） |
| `lib/features/tenant/data/live_tenant_repository.dart` | 实现 `loadTrends`（从 ApiCache 读取 + 回退 Mock） |
| `lib/features/tenant/presentation/pages/tenant_detail_page.dart` | 骨架屏加载态、各卡片空状态、趋势图集成、Stats GridView 布局 |
| `lib/core/api/api_cache.dart` | 新增 `_trends` 缓存字段 + `fetchTenantTrends` 方法 |

---

## 前置条件与约定

1. **降采样策略**: 复用 `lib/core/data/twin_series_downsample.dart` 的均匀截断思路。30 天原始数据 → 按天聚合 → 若超过 10 点则均匀采样到 7-10 点。
2. **图表风格**: 对齐 `temperature_chart.dart` / `motility_chart.dart` 的 fl_chart LineChart 模式（无曲线平滑、点阈值着色、固定高度 150px）。
3. **骨架屏**: 不引入 `shimmer` 等新依赖。手写 `AnimationController` 驱动的脉冲透明度动画（0.3 ↔ 0.7 opacity，1.2s 周期）。
4. **空状态**: 各卡片数据为空时显示专属空状态文案和图标，不再 `SizedBox.shrink()` 隐藏。
5. **Stats 布局**: 从当前两个 Row 改为一组 `GridView.count(crossAxisCount: 2)`，每个统计指标使用内联 `_statMiniTile` 方法（避免 `HighfiStatTile` 自带 `HighfiCard` 造成双重卡片包裹），外层统一由 `HighfiCard` 包裹标题和网格。
6. **趋势数据类型**: `DailyStatPoint` 包含 `date`、`alerts`、`deviceOnlineRate`、`healthRate`。首版仅展示告警趋势折线图。
7. **测试模式**: 每个 Controller 测试使用 `ProviderContainer` 隔离，不依赖真实后端。
8. **提交频次**: 每个 Task 结束必须 `git commit`，遵循 existing conventional commits 风格。
9. **趋势数据加载**: Live 模式下，趋势数据通过 `ApiCache.refreshTenantTrends(role, id)` 按需获取。首次访问某个租户详情页时，缓存未命中会自动回退 Mock 数据（Live 仓库的 `loadTrends` 中检查 `cache.tenantTrends` 是否为空）。这是预期行为，与 Phase 2 的 devices/logs/stats 回退策略一致。

---

## Task 1：后端趋势端点（TDD）

**Files:**
- Create: `backend/test/tenantTrends.test.js`
- Modify: `backend/routes/tenants.js`
- Modify: `backend/server.js`

### 📋 目标

新增 `GET /api/tenants/:id/trends` 端点，返回 30 天每日统计假数据，用于前端趋势图表。

### 🔧 实施步骤

- [ ] **Step 1: 写趋势端点测试 `tenantTrends.test.js`**

```javascript
const assert = require('node:assert/strict');
const { test } = require('node:test');

test('tenantTrends: 生成 30 天趋势数据', () => {
  const trends = generateTrends('tenant_001');
  assert.equal(trends.dailyStats.length, 30);
  const first = trends.dailyStats[0];
  assert.ok(typeof first.date === 'string');
  assert.ok(typeof first.alerts === 'number');
  assert.ok(typeof first.deviceOnlineRate === 'number');
  assert.ok(typeof first.healthRate === 'number');
  assert.ok(first.deviceOnlineRate >= 0 && first.deviceOnlineRate <= 100);
  assert.ok(first.healthRate >= 60 && first.healthRate <= 100);
});

test('tenantTrends: 日期倒序排列（最新在前）', () => {
  const trends = generateTrends('tenant_001');
  const dates = trends.dailyStats.map(s => s.date);
  for (let i = 0; i < dates.length - 1; i++) {
    assert.ok(dates[i] >= dates[i + 1]);
  }
});

test('tenantTrends: 不同租户数据有差异', () => {
  const a = generateTrends('tenant_001');
  const b = generateTrends('tenant_002');
  const aSum = a.dailyStats.reduce((s, p) => s + p.alerts, 0);
  const bSum = b.dailyStats.reduce((s, p) => s + p.alerts, 0);
  assert.notEqual(aSum, bSum);
});
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/backend && node --test test/tenantTrends.test.js
```

Expected: FAIL（`generateTrends` 未定义）。

- [ ] **Step 3: 在 `backend/routes/tenants.js` 中实现趋势端点**

在文件末尾 `module.exports = router;` 之前添加：

```javascript
function generateTrends(tenantId) {
  const now = new Date();
  const dailyStats = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const date = d.toISOString().substring(0, 10);
    const base = Math.abs(hashCode(tenantId + date));
    dailyStats.push({
      date,
      alerts: Math.max(0, Math.round((base % 8) + (Math.sin(i * 0.3) * 3))),
      deviceOnlineRate: Math.min(100, 80 + (base % 20)),
      healthRate: Math.min(100, 75 + (base % 25)),
    });
  }
  return { dailyStats };
}

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash + str.charCodeAt(i)) | 0;
  }
  return Math.abs(hash);
}

router.get(
  '/:id/trends',
  authMiddleware,
  requirePermission('tenant:view'),
  (req, res) => {
    const tenant = store.findById(req.params.id);
    if (!tenant) {
      return res.fail(404, 'RESOURCE_NOT_FOUND', '租户不存在');
    }
    res.ok(generateTrends(req.params.id));
  }
);
```

- [ ] **Step 4: 暴露生成函数供测试使用**

在 `module.exports` 中添加 `generateTrends` 导出。

在 `backend/routes/tenants.js` 底部修改 module.exports：

```javascript
module.exports = { router, generateTrends };
```

同时修改 `backend/routes/registerApiRoutes.js` 中对 tenants 路由的引用：

```javascript
// 当前: const tenantsRoutes = require('./tenants');
// 改为:
const { router: tenantsRoutes } = require('./tenants');
```

确保路由挂载不变。

- [ ] **Step 5: 更新 `backend/server.js` 的 `ROUTE_DEFINITIONS`**

在 `ROUTE_DEFINITIONS` 数组中 `['GET', '/tenants/:id/stats']` 之后添加：

```javascript
['GET',    '/api/tenants/:id/trends'],
```

- [ ] **Step 6: 更新测试引用方式**

修改 `backend/test/tenantTrends.test.js`，使用新的导出路径：

```javascript
const { generateTrends } = require('../routes/tenants');
```

- [ ] **Step 7: 运行测试确认通过**

```bash
cd Mobile/backend && node --test test/tenantTrends.test.js
```

Expected: 3 个 case 全部 PASS。

- [ ] **Step 8: 确认已有后端测试不破坏**

```bash
cd Mobile/backend && npm test
```

Expected: 所有已有测试（tenantStore 15 个 + apiVersionRoutes 等）全部通过。

- [ ] **Step 9: curl 烟雾测试**

```bash
cd Mobile/backend && node server.js &
sleep 1
curl -sS 'http://localhost:3001/api/tenants/tenant_001/trends' \
  -H 'Authorization: Bearer mock-token-ops' | jq '.data.dailyStats | length'
# Expected: 30
kill %1
```

- [ ] **Step 10: Commit**

```bash
cd Mobile
git add backend/routes/tenants.js backend/server.js backend/test/tenantTrends.test.js
git commit -m "feat(backend): add GET /api/tenants/:id/trends endpoint with 30-day mock data"
```

---

## Task 2：趋势数据模型 + Repository 扩展 + ApiCache

**Files:**
- Modify: `lib/features/tenant/domain/tenant_view_data.dart`
- Modify: `lib/features/tenant/domain/tenant_repository.dart`
- Modify: `lib/features/tenant/data/mock_tenant_repository.dart`
- Modify: `lib/features/tenant/data/live_tenant_repository.dart`
- Modify: `lib/core/api/api_cache.dart`

### 📋 目标

添加趋势数据的领域模型、Repository 方法和 ApiCache 读取支持。

### 🔧 实施步骤

- [ ] **Step 1: 在 `tenant_view_data.dart` 中添加趋势模型**

在文件末尾追加：

```dart
class DailyStatPoint {
  const DailyStatPoint({
    required this.date,
    required this.alerts,
    required this.deviceOnlineRate,
    required this.healthRate,
  });

  final String date;
  final int alerts;
  final double deviceOnlineRate;
  final double healthRate;
}

class TenantTrendsViewData {
  const TenantTrendsViewData({
    required this.viewState,
    required this.dailyStats,
    this.message,
  });

  final ViewState viewState;
  final List<DailyStatPoint> dailyStats;
  final String? message;
}
```

- [ ] **Step 2: 在 `tenant_repository.dart` 中添加 `loadTrends` 方法**

在抽象方法列表末尾追加：

```dart
TenantTrendsViewData loadTrends(String id);
```

同时添加 import：

```dart
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
```

- [ ] **Step 3: 在 `mock_tenant_repository.dart` 中实现 `loadTrends`**

```dart
@override
TenantTrendsViewData loadTrends(String id) {
  final tenant = _seed.where((t) => t.id == id).toList();
  if (tenant.isEmpty) {
    return const TenantTrendsViewData(
      viewState: ViewState.empty,
      dailyStats: [],
      message: '租户不存在',
    );
  }
  final now = DateTime.now();
  final stats = <DailyStatPoint>[];
  final baseHash = id.hashCode.abs();
  for (var i = 29; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    stats.add(DailyStatPoint(
      date: date,
      final sinVal = sin(d.month * d.day * 0.3);
    alerts: ((baseHash + i * 7) % 8 + (sinVal * 3).round()).abs(),
      deviceOnlineRate: (80 + (baseHash + i * 3) % 20).toDouble(),
      healthRate: (75 + (baseHash + i * 5) % 25).toDouble(),
    ));
  }
  return TenantTrendsViewData(
    viewState: ViewState.normal,
    dailyStats: stats,
  );
}
```

需要添加 `import 'dart:math';`。

- [ ] **Step 4: 在 `live_tenant_repository.dart` 中实现 `loadTrends`**

```dart
@override
TenantTrendsViewData loadTrends(String id) {
  final cache = ApiCache.instance;
  if (!cache.initialized) return _fallback.loadTrends(id);
  final trendsCache = cache.tenantTrends;
  if (trendsCache == null || trendsCache.isEmpty) return _fallback.loadTrends(id);
  final map = trendsCache[id];
  if (map == null) return _fallback.loadTrends(id);
  final dailyStats = (map['dailyStats'] as List<dynamic>?)
      ?.map((e) => DailyStatPoint(
            date: e['date'] as String,
            alerts: e['alerts'] as int,
            deviceOnlineRate: (e['deviceOnlineRate'] as num).toDouble(),
            healthRate: (e['healthRate'] as num).toDouble(),
          ))
      .toList();
  if (dailyStats == null || dailyStats.isEmpty) {
    return _fallback.loadTrends(id);
  }
  return TenantTrendsViewData(
    viewState: ViewState.normal,
    dailyStats: dailyStats,
  );
}
```

- [ ] **Step 5: 在 `api_cache.dart` 中添加趋势缓存**

在 `ApiCache` 类中添加字段：

```dart
Map<String, Map<String, dynamic>>? _tenantTrends;
```

添加 getter：

```dart
Map<String, Map<String, dynamic>>? get tenantTrends => _tenantTrends;
```

添加预加载方法（在 `refreshTenants` 附近）：

```dart
Future<void> refreshTenantTrends(String role, String tenantId) async {
  final data = await _get('/tenants/$tenantId/trends', _headers(role));
  if (data != null) {
    _tenantTrends ??= {};
    _tenantTrends![tenantId] = data;
  }
}
```

在 `debugReset` 中清理：

```dart
_tenantTrends = null;
```

- [ ] **Step 6: 静态分析**

```bash
cd Mobile/mobile_app && flutter analyze
```

Expected: No issues found.

- [ ] **Step 7: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/domain/tenant_view_data.dart \
        mobile_app/lib/features/tenant/domain/tenant_repository.dart \
        mobile_app/lib/features/tenant/data/mock_tenant_repository.dart \
        mobile_app/lib/features/tenant/data/live_tenant_repository.dart \
        mobile_app/lib/core/api/api_cache.dart
git commit -m "feat(tenant): add trend data models, repository methods, and ApiCache support"
```

---

## Task 3：趋势 Controller

**Files:**
- Create: `lib/features/tenant/presentation/tenant_trends_controller.dart`
- Create: `test/features/tenant/tenant_trends_controller_test.dart`

### 📋 目标

创建 `TenantTrendsController`，遵循现有同步 Controller + ViewData 模式。

### 🔧 实施步骤

- [ ] **Step 1: 写测试 `tenant_trends_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_trends_controller.dart';

void main() {
  test('Trends Controller 为已知租户返回 ViewState.normal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.dailyStats.length, 30);
  });

  test('Trends Controller 日期降序排列', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    final dates = data.dailyStats.map((s) => s.date).toList();
    for (var i = 0; i < dates.length - 1; i++) {
      expect(dates[i].compareTo(dates[i + 1]), greaterThanOrEqualTo(0));
    }
  });

  test('Trends Controller 刷新保持相同租户', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantTrendsControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    expect(data.dailyStats.length, 30);
  });

  test('Trends Controller 对不存在的租户返回 ViewState.empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_unknown'));
    expect(data.viewState, ViewState.empty);
    expect(data.dailyStats, isEmpty);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/mobile_app && flutter test test/features/tenant/tenant_trends_controller_test.dart
```

Expected: FAIL。

- [ ] **Step 3: 实现 `tenant_trends_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantTrendsController extends Notifier<TenantTrendsViewData> {
  TenantTrendsController(this.id);

  final String id;

  @override
  TenantTrendsViewData build() {
    return ref.watch(tenantRepositoryProvider).loadTrends(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadTrends(id);
  }
}

final tenantTrendsControllerProvider = NotifierProvider.family<
    TenantTrendsController, TenantTrendsViewData, String>(
  TenantTrendsController.new,
);
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/mobile_app && flutter test test/features/tenant/tenant_trends_controller_test.dart
```

Expected: 4 个 case PASS。

- [ ] **Step 5: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/tenant_trends_controller.dart \
        mobile_app/test/features/tenant/tenant_trends_controller_test.dart
git commit -m "feat(tenant): add TenantTrendsController with NotifierProvider.family"
```

---

## Task 4：趋势图表 Widget

**Files:**
- Create: `lib/features/tenant/presentation/widgets/tenant_trend_chart.dart`

### 📋 目标

创建 30 天告警趋势折线图，复用 `TwinSeriesDownsample` 降采样策略，对齐现有图表风格。

### 🔧 实施步骤

- [ ] **Step 1: 查看现有降采样工具签名**

```bash
grep -n "class TwinSeriesDownsample" Mobile/mobile_app/lib/core/data/twin_series_downsample.dart
```

确认：`TwinSeriesDownsample` 是静态工具类，有两个公共方法 `hourlyMeanTemperature` 和 `hourlyMeanMotility`。对于租户趋势，每日数据已经是天粒度的，需写一个通用的 `uniformSample` 辅助方法。

- [ ] **Step 2: 实现 `tenant_trend_chart.dart`**

```dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class TenantTrendChart extends StatelessWidget {
  const TenantTrendChart({
    super.key,
    required this.dailyStats,
    this.maxDisplayPoints = 10,
    this.height = 150,
  });

  final List<DailyStatPoint> dailyStats;
  final int maxDisplayPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return SizedBox(height: height);
    }

    final sorted = List<DailyStatPoint>.from(dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    final sampled = _uniformSample(sorted, maxDisplayPoints);

    final spots = <FlSpot>[];
    for (var i = 0; i < sampled.length; i++) {
      spots.add(FlSpot(i.toDouble(), sampled[i].alerts.toDouble()));
    }

    final maxY = spots.isEmpty
        ? 10.0
        : spots.map((s) => s.y).reduce(max).clamp(5.0, 50.0) * 1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 20 ? 5 : 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textSecondary.withAlpha(30),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: sampled.length > 5
                    ? (sampled.length / 4).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sampled.length) {
                    return const SizedBox.shrink();
                  }
                  final d = sampled[idx].date;
                  return Text(
                    d.substring(5), // MM-DD
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.warning,
              barWidth: 2,
              dotData: FlDotData(
                show: sampled.length <= 10,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 2.5,
                  color: AppColors.warning,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.warning.withAlpha(25),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<DailyStatPoint> _uniformSample(List<DailyStatPoint> source, int maxPoints) {
    if (source.length <= maxPoints) return source;
    final result = <DailyStatPoint>[];
    final step = (source.length - 1) / (maxPoints - 1);
    for (var i = 0; i < maxPoints; i++) {
      final idx = (i * step).round().clamp(0, source.length - 1);
      result.add(source[idx]);
    }
    return result;
  }
}
```

- [ ] **Step 3: 静态分析**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/tenant/presentation/widgets/tenant_trend_chart.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/widgets/tenant_trend_chart.dart
git commit -m "feat(tenant): add 30-day alert trend chart with downsampling"
```

---

## Task 5：骨架屏 + 空状态 Widget

**Files:**
- Create: `lib/features/tenant/presentation/widgets/tenant_skeleton.dart`

### 📋 目标

创建轻量级骨架屏加载 widget（脉冲动画，不引入新依赖），以及各卡片专属空状态 widget。

### 🔧 实施步骤

- [ ] **Step 1: 实现 `tenant_skeleton.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class TenantSkeleton extends StatefulWidget {
  const TenantSkeleton({super.key});

  @override
  State<TenantSkeleton> createState() => _TenantSkeletonState();
}

class _TenantSkeletonState extends State<TenantSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.3 + (_controller.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 160, height: 18),
                const SizedBox(height: AppSpacing.md),
                _bar(width: 240, height: 12),
                const SizedBox(height: AppSpacing.xs),
                _bar(width: double.infinity, height: 6),
                const SizedBox(height: AppSpacing.sm),
                _bar(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          HighfiCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _bar(width: 72, height: 32),
                _bar(width: 72, height: 32),
                _bar(width: 96, height: 32),
                _bar(width: 64, height: 32),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
          const SizedBox(height: AppSpacing.md),
          _skeletonCard(),
        ],
      ),
    );
  }

  Widget _skeletonCard() {
    return HighfiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 100, height: 14),
          const SizedBox(height: AppSpacing.sm),
          _bar(width: double.infinity, height: 36),
        ],
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class TenantEmptyCard extends StatelessWidget {
  const TenantEmptyCard({
    super.key,
    required this.title,
    required this.icon,
    this.description,
  });

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary.withAlpha(100)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 静态分析**

```bash
cd Mobile/mobile_app && flutter analyze lib/features/tenant/presentation/widgets/tenant_skeleton.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/widgets/tenant_skeleton.dart
git commit -m "feat(tenant): add skeleton loading and per-card empty state widgets"
```

---

## Task 6：详情页 UX 重构（骨架屏 + 空状态 + 趋势图 + GridView）

**Files:**
- Modify: `lib/features/tenant/presentation/pages/tenant_detail_page.dart`

### 📋 目标

重构详情页，加入：
1. 骨架屏加载态（`ViewState.loading` 时显示 `TenantSkeleton`）
2. 各卡片独立空状态（替代当前 `SizedBox.shrink()` 隐藏）
3. 趋势图表卡片（统计概览下方）
4. Stats 卡片从 Row 布局改为 GridView 双列布局

### 🔧 实施步骤

- [ ] **Step 1: 阅读并定位需要修改的代码段**

关键行号（基于当前文件）：
- `_buildBody`: 39-65（主切分支）
- `_buildStatsCard`: 194-239（需重构为 GridView 双列布局）
- `_buildDevicesCard`: 258-292（需加空状态分支）
- `_buildLogsCard`: 351-367（需加空状态分支）

- [ ] **Step 2: 修改 `_buildBody` — 增加 loading 分支**

将当前代码（第 39-46 行）：

```dart
Widget _buildBody(BuildContext context, WidgetRef ref, TenantDetailViewData data) {
  if (data.viewState != ViewState.normal || data.tenant == null) {
    return HighfiEmptyErrorState(
      title: '无法加载',
      description: data.message ?? '租户不存在',
      icon: Icons.error_outline,
    );
  }
```

替换为：

```dart
Widget _buildBody(BuildContext context, WidgetRef ref, TenantDetailViewData data) {
  if (data.viewState == ViewState.loading) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: TenantSkeleton(),
    );
  }
  if (data.viewState != ViewState.normal || data.tenant == null) {
    return HighfiEmptyErrorState(
      title: '无法加载',
      description: data.message ?? '租户不存在',
      icon: Icons.error_outline,
    );
  }
```

- [ ] **Step 3: 在主卡片列表中加入趋势图**

在第 57 行 `_buildStatsCard` 之后插入趋势图卡片：

```dart
const SizedBox(height: AppSpacing.md),
_buildTrendCard(context, ref),
```

- [ ] **Step 4: 重构 `_buildStatsCard` — GridView 双列布局**

用以下代码替换当前 `_buildStatsCard` 方法（第 194-239 行）：

```dart
Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
  final data = ref.watch(tenantStatsControllerProvider(id));
  if (data.viewState == ViewState.loading) {
    return const SizedBox.shrink(); // 骨架屏已覆盖
  }
  if (data.viewState != ViewState.normal) {
    return const TenantEmptyCard(
      title: '暂无统计数据',
      icon: Icons.bar_chart_outlined,
    );
  }
  return HighfiCard(
    key: const Key('tenant-detail-card-stats'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('统计概览', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statMiniTile('牲畜总数', '${data.livestockTotal}', '头'),
            _statMiniTile('在线设备', '${data.deviceOnline}/${data.deviceTotal}',
                '在线率 ${data.deviceOnlineRate}%'),
            _statMiniTile('健康率', '${data.healthRate}%', null),
            _statMiniTile('今日告警', '${data.alertCount}',
                data.lastSync != null ? '同步 $data.lastSync' : null),
          ],
        ),
      ],
    ),
  );
}

Widget _statMiniTile(String label, String value, String? caption) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      if (caption != null)
        Text(
          caption,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
    ],
  );
}
```

注意：上述代码**无需** import `HighfiStatTile`，统计项使用内联 `_statMiniTile` 方法避免外层 `HighfiCard` 与 `HighfiStatTile` 内层 `HighfiCard` 双重包裹。

- [ ] **Step 5: 重构 `_buildDevicesCard` — 增加空状态分支**

在方法开头添加空状态检查：

```dart
Widget _buildDevicesCard(BuildContext context, WidgetRef ref) {
  final data = ref.watch(tenantDevicesControllerProvider(id));
  if (data.viewState == ViewState.loading) {
    return const SizedBox.shrink(); // 骨架屏已覆盖
  }
  if (data.viewState != ViewState.normal) {
    return const TenantEmptyCard(
      title: '暂无设备数据',
      icon: Icons.devices_outlined,
      description: '该租户下暂未绑定设备',
    );
  }
  // ... 已有代码保持不变
```

- [ ] **Step 6: 重构 `_buildLogsCard` — 增加空状态分支**

同样在方法开头添加：

```dart
Widget _buildLogsCard(BuildContext context, WidgetRef ref) {
  final data = ref.watch(tenantLogsControllerProvider(id));
  if (data.viewState == ViewState.loading) {
    return const SizedBox.shrink(); // 骨架屏已覆盖
  }
  if (data.viewState != ViewState.normal) {
    return const TenantEmptyCard(
      title: '暂无操作日志',
      icon: Icons.history_outlined,
    );
  }
  // ... 已有代码保持不变
```

- [ ] **Step 7: 新增 `_buildTrendCard` 方法**

在 `_buildLogsCard` 方法之后添加：

```dart
Widget _buildTrendCard(BuildContext context, WidgetRef ref) {
  final data = ref.watch(tenantTrendsControllerProvider(id));
  if (data.viewState == ViewState.loading) {
    return const SizedBox.shrink();
  }
  if (data.viewState != ViewState.normal || data.dailyStats.isEmpty) {
    return const SizedBox.shrink(); // 趋势图为可选卡片，无数据时静默隐藏
  }
  return HighfiCard(
    key: const Key('tenant-detail-card-trends'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('30 天告警趋势', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TenantTrendChart(dailyStats: data.dailyStats),
      ],
    ),
  );
}
```

- [ ] **Step 8: 添加缺失的 import**

在文件顶部添加：

```dart
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_trends_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_skeleton.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_trend_chart.dart';
```

- [ ] **Step 9: 静态分析 + 运行已有测试**

```bash
cd Mobile/mobile_app && flutter analyze && flutter test
```

Expected: analyze 无错误；全部已有测试通过。

- [ ] **Step 10: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/tenant/presentation/pages/tenant_detail_page.dart
git commit -m "feat(tenant): refactor detail page with skeleton loading, empty states, trend chart, and grid stats"
```

---

## Task 7：Phase 2 Controller 测试补齐

**Files:**
- Create: `test/features/tenant/tenant_devices_controller_test.dart`
- Create: `test/features/tenant/tenant_logs_controller_test.dart`
- Create: `test/features/tenant/tenant_stats_controller_test.dart`

### 📋 目标

为 Phase 2 新增的三个 Controller 编写单元测试，补齐测试覆盖。

### 🔧 实施步骤

- [ ] **Step 1: 写 `tenant_devices_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_devices_controller.dart';

void main() {
  test('Devices Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantDevicesControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.devices.isNotEmpty, isTrue);
    expect(data.total, greaterThanOrEqualTo(data.devices.length));
  });

  test('Devices Controller 刷新保持数据', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantDevicesControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantDevicesControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.devices.isNotEmpty, isTrue);
  });
}
```

- [ ] **Step 2: 写 `tenant_logs_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_logs_controller.dart';

void main() {
  test('Logs Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantLogsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.logs.isNotEmpty, isTrue);
    expect(data.total, greaterThanOrEqualTo(data.logs.length));
  });

  test('Logs Controller 日志条目有非空字段', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantLogsControllerProvider('tenant_001'));
    for (final log in data.logs) {
      expect(log.id.isNotEmpty, isTrue);
      expect(log.action.isNotEmpty, isTrue);
      expect(log.operator.isNotEmpty, isTrue);
    }
  });
}
```

- [ ] **Step 3: 写 `tenant_stats_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_stats_controller.dart';

void main() {
  test('Stats Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.livestockTotal, greaterThan(0));
    expect(data.deviceTotal, greaterThan(0));
    expect(data.healthRate, greaterThanOrEqualTo(0));
    expect(data.alertCount, greaterThanOrEqualTo(0));
  });

  test('Stats Controller 在线率在有效范围内', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.deviceOnlineRate, inInclusiveRange(0, 100));
    expect(data.healthRate, inInclusiveRange(0, 100));
  });

  test('Stats Controller 刷新保持数据', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantStatsControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.livestockTotal, greaterThan(0));
  });
}
```

- [ ] **Step 4: 运行测试**

```bash
cd Mobile/mobile_app && flutter test test/features/tenant/tenant_devices_controller_test.dart \
                                 test/features/tenant/tenant_logs_controller_test.dart \
                                 test/features/tenant/tenant_stats_controller_test.dart
```

Expected: 7 个 case 全部 PASS。

- [ ] **Step 5: Commit**

```bash
cd Mobile
git add mobile_app/test/features/tenant/tenant_devices_controller_test.dart \
        mobile_app/test/features/tenant/tenant_logs_controller_test.dart \
        mobile_app/test/features/tenant/tenant_stats_controller_test.dart
git commit -m "test(tenant): add unit tests for Phase 2 devices/logs/stats controllers"
```

---

## Task 8：详情页卡片 Widget 测试

**Files:**
- Create: `test/features/tenant/tenant_detail_cards_test.dart`

### 📋 目标

为详情页的 Stats/Devices/Logs 卡片编写 Widget 测试，验证各卡片在 normal 和 empty 状态下的渲染。

### 🔧 实施步骤

- [ ] **Step 1: 写 `tenant_detail_cards_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_devices_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_logs_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_stats_controller.dart';

void main() {
  testWidgets('Stats 卡片显示四个统计指标', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-stats')), findsOneWidget);
    expect(find.text('统计概览'), findsOneWidget);
  });

  testWidgets('Devices 卡片显示设备列表', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-devices')), findsOneWidget);
  });

  testWidgets('Logs 卡片显示操作日志', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-logs')), findsOneWidget);
  });

  testWidgets('trends 卡片在 mock 模式下显示', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TenantDetailPage(id: 'tenant_001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-detail-card-trends')), findsOneWidget);
    expect(find.text('30 天告警趋势'), findsOneWidget);
  });

  testWidgets('不存在的租户显示错误态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const TenantDetailPage(id: 'tenant_unknown'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('无法加载'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试**

```bash
cd Mobile/mobile_app && flutter test test/features/tenant/tenant_detail_cards_test.dart
```

Expected: 5 个 case 全部 PASS。

- [ ] **Step 3: Commit**

```bash
cd Mobile
git add mobile_app/test/features/tenant/tenant_detail_cards_test.dart
git commit -m "test(tenant): add widget tests for detail page cards"
```

---

## Task 9：全量回归验证

**Files:**（无代码改动）

### 📋 目标

确认所有改动在 Mock 和 Live 模式下均可正常工作，已有测试无回归。

### 🔧 实施步骤

- [ ] **Step 1: 运行全量 Flutter 测试**

```bash
cd Mobile/mobile_app && flutter analyze && flutter test
```

Expected: analyze 无错误；全部测试通过（已有 190+ 个 + 本次新增约 15 个）。

- [ ] **Step 2: 运行后端全量测试**

```bash
cd Mobile/backend && npm test
```

Expected: 全部测试通过（已有 tenantStore 15 + apiVersionRoutes 等 + 本次新增 tenantTrends 3）。

- [ ] **Step 3: Live 模式手工验证**

```bash
# 终端 1: 启动 Mock Server
cd Mobile/backend && node server.js

# 终端 2: 启动 Flutter（Live 模式）
cd Mobile/mobile_app && flutter run -d chrome --dart-define=APP_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

手工验证清单：
1. 以 `ops` 登录 → 进入租户列表
2. 点击任意租户进入详情页
3. 确认首次加载时看到骨架屏脉冲动画（若网络够快可能一闪而过）
4. 确认 Stats 卡片以 2x2 网格展示四个指标
5. 确认"30 天告警趋势"折线图正常渲染
6. 确认设备列表卡片内容正常
7. 确认操作日志卡片显示时间线样式

- [ ] **Step 4: Mock 模式手工验证**

```bash
cd Mobile/mobile_app && flutter run -d chrome
```

重复 Step 3 的验证清单。Mock 模式下数据即时加载，骨架屏可能不可见（预期行为）。

- [ ] **Step 5: 更新完成记录**

在 `docs/superpowers/todolist-2026-04-27.md` 的"已完成概览"表中增加一行（若文件不存在则跳过此步骤）：

```markdown
| 18 | 租户管理 Phase 3（可视化与体验） | 2026-04-20-tenant-management-design Phase 3 | 已完成 |
```

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add docs/superpowers/todolist-2026-04-27.md docs/superpowers/plans/2026-04-27-tenant-management-phase3.md
git commit -m "docs(tenant): record Phase 3 visualization and test completion"
```

---

## 验收清单（Definition of Done）

**图表与降采样**
- [ ] 趋势端点 `GET /api/tenants/:id/trends` 返回 30 天每日统计数据
- [ ] `TenantTrendChart` widget 渲染 fl_chart LineChart，30 天数据降采样到 ≤10 显示点
- [ ] 趋势图在 Mock 和 Live 模式均可正常渲染

**骨架屏与空状态**
- [ ] 详情页 `ViewState.loading` 时显示 `TenantSkeleton` 脉冲动画（不引入新依赖）
- [ ] Stats 卡片数据为空时显示"暂无统计数据"空状态（不再隐藏）
- [ ] Devices 卡片数据为空时显示"暂无设备数据"空状态
- [ ] Logs 卡片数据为空时显示"暂无操作日志"空状态

**Stats 布局**
- [ ] Stats 卡片从 Row 双行布局改为 GridView 2x2 双列布局
- [ ] 每个指标使用内联 `_statMiniTile` 方法，由外层 `HighfiCard` 统一包裹

**测试覆盖**
- [ ] `tenantTrends.test.js` 3 个 case 通过
- [ ] `tenant_devices_controller_test.dart` 2 个 case 通过
- [ ] `tenant_logs_controller_test.dart` 2 个 case 通过
- [ ] `tenant_stats_controller_test.dart` 3 个 case 通过
- [ ] `tenant_trends_controller_test.dart` 4 个 case 通过
- [ ] `tenant_detail_cards_test.dart` 5 个 case 通过
- [ ] 全量 `flutter analyze && flutter test` 通过
- [ ] 全量 `npm test` 后端测试通过

**回归**
- [ ] 详情页基本信息卡片、操作按钮卡片功能不变
- [ ] Mock 和 Live 双模式均可正常运行
- [ ] 列表页分页、搜索、筛选功能不变

---

**计划版本**: v1.0
**创建日期**: 2026-04-27
**状态**: 待评审
