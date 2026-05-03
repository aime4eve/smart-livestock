# b2b_admin UX 优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重写 b2b_admin 4 个页面（概览/对账/合同/牧工管理），提升信息密度、交互深度和视觉一致性。

**Architecture:** 数据层先行（扩展现有 model + repository），共用组件其次，页面最后。新增 2 个详情页路由（对账详情/牧工详情）。全部页面使用 Material Icons Outlined + 低饱和灰蓝主色 + 统一二次确认/SnackBar 反馈。

**Tech Stack:** Flutter / flutter_riverpod / go_router / Material Icons Outlined

**被实施规格:** `docs/superpowers/specs/2026-05-03-b2b-admin-ux-optimization-design.md`

---

## 文件结构

### 新建文件

| 文件 | 职责 |
|------|------|
| `lib/features/b2b_admin/presentation/widgets/confirm_dialog.dart` | 共用二次确认 Dialog |
| `lib/features/b2b_admin/presentation/widgets/alert_bottom_sheet.dart` | 概览页告警摘要 BottomSheet |
| `lib/features/b2b_admin/presentation/b2b_revenue_detail_page.dart` | 对账周期详情页 |
| `lib/features/b2b_admin/presentation/b2b_worker_detail_page.dart` | 牧场工人详情页 |

### 修改文件

| 文件 | 变更 |
|------|------|
| `lib/features/b2b_admin/data/b2b_repository.dart` | `B2bFarmSummary` 新增 `deviceCount`/`workerCount`；`B2bDashboardData` 新增 `monthlyRevenue`/`deviceOnlineRate`/`partnerName`/`billingModel`；`B2bContractData` 新增 `billingModel`/`deploymentType`/`serviceStatus`/`lastHeartbeatAt`/`deviceQuota`/`serviceExpiresAt`/`effectiveTier`(service)/`partnerName`/`contractId`/`partnerTenantId` |
| `lib/features/revenue/domain/revenue_repository.dart` | 新增 `RevenuePeriodDetail`/`RevenueFarmDetail` 类型；`RevenueDetailViewData.details` 类型从 `List<Map>` 改为 `List<RevenueFarmDetail>`；新增 `totalDeviceFee`/`revenueShareRatio`/`platformConfirmed`/`partnerConfirmed`/`calculatedAt` 字段 |
| `lib/features/revenue/data/mock_revenue_repository.dart` | 实现 `getPeriodDetail` 返回结构化 `RevenueDetailViewData` |
| `lib/features/revenue/data/live_revenue_repository.dart` | 同上 |
| `lib/features/b2b_admin/domain/b2b_worker_management_repository.dart` | `B2bSubFarmWorker` 新增 `id`/`assignedAt`；`B2bSubFarm` 新增 `deviceCount`；`B2bWorkerManagementViewData` 新增 `totalWorkers`/`offlineWorkerCount`；接口新增 `assignWorker`/`removeWorker`/`getAvailableWorkers` |
| `lib/features/b2b_admin/data/mock_b2b_worker_management_repository.dart` | 实现分配/移除/获取可用牧工 |
| `lib/features/b2b_admin/data/live_b2b_worker_management_repository.dart` | 同上 |
| `lib/features/b2b_admin/presentation/b2b_controller.dart` | `B2bDashboardController` 扩展加载 revenue 数据；`B2bContractController` 扩展加载订阅服务数据 |
| `lib/features/b2b_admin/presentation/b2b_dashboard_page.dart` | 完全重写：经营概览主卡片 + 告警提醒条 + 快捷入口 + 牧场列表 |
| `lib/features/b2b_admin/presentation/b2b_revenue_page.dart` | 完全重写：汇总指标 + 筛选标签 + 周期卡片列表 |
| `lib/features/b2b_admin/presentation/b2b_contract_page.dart` | 完全重写：主信息卡片 + 到期提醒 + 条款区 + 订阅服务状态 + 快捷操作 |
| `lib/features/b2b_admin/presentation/worker_management_page.dart` | 完全重写：汇总指标 + 批量入口 + 牧场卡片列表 |
| `lib/features/b2b_admin/presentation/b2b_worker_management_controller.dart` | 新增 `assignWorker`/`removeWorker`/`getAvailableWorkers`/`offlineWorkerCount` |
| `lib/app/app_route.dart` | 新增 `b2bAdminRevenueDetail`/`b2bWorkerDetail` 枚举 |
| `lib/app/app_router.dart` | 注册 2 个新路由（作为现有 b2b 路由的子路由） |

---

## 实施任务

### Task 1: 数据模型扩展（b2b_repository.dart）

**Files:**
- Modify: `lib/features/b2b_admin/data/b2b_repository.dart`

- [ ] **Step 1: 扩展 B2bFarmSummary**

在 `B2bFarmSummary` 类中新增 `deviceCount` 和 `workerCount` 字段：

```dart
class B2bFarmSummary {
  const B2bFarmSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.livestockCount,
    required this.region,
    this.deviceCount = 0,
    this.workerCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final int livestockCount;
  final String region;
  final int deviceCount;
  final int workerCount;
  final String? createdAt;
}
```

- [ ] **Step 2: 扩展 B2bDashboardData**

新增 `monthlyRevenue`/`deviceOnlineRate`/`partnerName`/`billingModel` 字段：

```dart
class B2bDashboardData {
  const B2bDashboardData({
    required this.viewState,
    this.totalFarms = 0,
    this.totalLivestock = 0,
    this.totalDevices = 0,
    this.pendingAlerts = 0,
    this.monthlyRevenue = 0.0,
    this.deviceOnlineRate = 0.0,
    this.partnerName,
    this.billingModel,
    this.farms = const [],
    this.contractStatus,
    this.contractExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final int totalFarms;
  final int totalLivestock;
  final int totalDevices;
  final int pendingAlerts;
  final double monthlyRevenue;
  final double deviceOnlineRate;
  final String? partnerName;
  final String? billingModel;
  final List<B2bFarmSummary> farms;
  final String? contractStatus;
  final String? contractExpiresAt;
  final String? message;
}
```

- [ ] **Step 3: 扩展 B2bContractData**

新增订阅服务和合作方相关字段：

```dart
class B2bContractData {
  const B2bContractData({
    required this.viewState,
    this.id,
    this.status,
    this.effectiveTier,
    this.revenueShareRatio,
    this.startedAt,
    this.expiresAt,
    this.signedBy,
    this.partnerName,
    this.partnerTenantId,
    this.contractId,
    this.billingModel,
    this.deploymentType,
    this.serviceStatus,
    this.serviceTier,
    this.lastHeartbeatAt,
    this.deviceQuota,
    this.serviceExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final String? id;
  final String? status;
  final String? effectiveTier;
  final double? revenueShareRatio;
  final String? startedAt;
  final String? expiresAt;
  final String? signedBy;
  final String? partnerName;
  final String? partnerTenantId;
  final String? contractId;
  final String? billingModel;
  final String? deploymentType;
  final String? serviceStatus;
  final String? serviceTier;
  final String? lastHeartbeatAt;
  final int? deviceQuota;
  final String? serviceExpiresAt;
  final String? message;
}
```

- [ ] **Step 4: 更新 mock 数据填充新字段**

在 `B2bRepository.loadDashboard()` 的 mock 分支中填充新字段（deviceCount/workerCount 用合理占位值，monthlyRevenue 用 revenue mock 数据计算，deviceOnlineRate 用 0.65 占位）。在 `_loadDashboardFromCache()` 中解析新字段。

在 `loadContract()` 的 mock 分支中填充 `partnerName`/`billingModel`/`serviceStatus` 等（mock 环境按 `billingModel = 'revenue_share'` 返回，subscription 相关字段为 null）。

在 `_loadContractFromCache()` 中解析新字段。

- [ ] **Step 5: 运行 flutter analyze 确保无编译错误**

```bash
cd Mobile/mobile_app && flutter analyze
```

Expected: 无新增 error

- [ ] **Step 6: Commit**

```bash
git add lib/features/b2b_admin/data/b2b_repository.dart
git commit -m "feat(b2b-ux): expand B2b data models with revenue/subscription/worker fields"
```

---

### Task 2: 数据模型扩展（revenue_repository.dart）

**Files:**
- Modify: `lib/features/revenue/domain/revenue_repository.dart`

- [ ] **Step 1: 新增 RevenuePeriodDetail 和 RevenueFarmDetail 类型**

在 `revenue_repository.dart` 中新增：

```dart
class RevenueFarmDetail {
  const RevenueFarmDetail({
    required this.farmName,
    required this.livestockCount,
    required this.deviceUnitPrice,
    required this.deviceFee,
    required this.shareAmount,
  });

  final String farmName;
  final int livestockCount;
  final double deviceUnitPrice;
  final double deviceFee;
  final double shareAmount;
}
```

扩展 `RevenueDetailViewData`：

```dart
class RevenueDetailViewData {
  const RevenueDetailViewData({
    this.viewState = ViewState.normal,
    this.period,
    this.totalDeviceFee = 0.0,
    this.revenueShareRatio = 0.0,
    this.platformConfirmed = false,
    this.partnerConfirmed = false,
    this.calculatedAt,
    this.farmDetails = const [],
    this.message,
  });

  final ViewState viewState;
  final RevenuePeriod? period;
  final double totalDeviceFee;
  final double revenueShareRatio;
  final bool platformConfirmed;
  final bool partnerConfirmed;
  final String? calculatedAt;
  final List<RevenueFarmDetail> farmDetails;
  final String? message;
}
```

- [ ] **Step 2: 更新 mock/live repository 实现**

在 `mock_revenue_repository.dart` 的 `getPeriodDetail()` 中返回结构化 `RevenueDetailViewData`（含 `totalDeviceFee`/`revenueShareRatio`/`platformConfirmed`/`partnerConfirmed`/`farmDetails`）。

在 `live_revenue_repository.dart` 中同步更新。

- [ ] **Step 3: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/revenue/domain/revenue_repository.dart \
        lib/features/revenue/data/mock_revenue_repository.dart \
        lib/features/revenue/data/live_revenue_repository.dart
git commit -m "feat(b2b-ux): add typed RevenuePeriodDetail/RevenueFarmDetail models"
```

---

### Task 3: 数据模型扩展（b2b_worker_management_repository.dart）

**Files:**
- Modify: `lib/features/b2b_admin/domain/b2b_worker_management_repository.dart`
- Modify: `lib/features/b2b_admin/data/mock_b2b_worker_management_repository.dart`
- Modify: `lib/features/b2b_admin/data/live_b2b_worker_management_repository.dart`

- [ ] **Step 1: 扩展 B2bSubFarmWorker / B2bSubFarm / ViewData**

```dart
class B2bSubFarmWorker {
  const B2bSubFarmWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.assignedAt,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String? assignedAt;
}

class B2bSubFarm {
  const B2bSubFarm({
    required this.id,
    required this.name,
    required this.workerCount,
    required this.livestockCount,
    this.deviceCount = 0,
  });

  final String id;
  final String name;
  final int workerCount;
  final int livestockCount;
  final int deviceCount;
}

class B2bWorkerManagementViewData {
  const B2bWorkerManagementViewData({
    this.viewState = ViewState.normal,
    this.subFarms = const [],
    this.totalWorkers = 0,
    this.offlineWorkerCount = 0,
    this.message,
  });

  final ViewState viewState;
  final List<B2bSubFarm> subFarms;
  final int totalWorkers;
  final int offlineWorkerCount;
  final String? message;
}
```

- [ ] **Step 2: 扩展 repository 接口**

```dart
abstract class B2bWorkerManagementRepository {
  B2bWorkerManagementViewData getSubFarms();
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId);
  Future<bool> assignWorker(String farmId, String workerId);
  Future<bool> removeWorker(String farmId, String workerId);
  List<B2bSubFarmWorker> getAvailableWorkers();
}
```

- [ ] **Step 3: 在 mock 和 live 实现中实现新方法**

Mock: 内存操作（从固定列表中分配/移除）。Live: HTTP 调用 `POST /api/v1/farms/:farmId/workers` / `DELETE /api/v1/farms/:farmId/workers/:workerId`。

- [ ] **Step 4: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/b2b_admin/domain/b2b_worker_management_repository.dart \
        lib/features/b2b_admin/data/mock_b2b_worker_management_repository.dart \
        lib/features/b2b_admin/data/live_b2b_worker_management_repository.dart
git commit -m "feat(b2b-ux): expand worker repository with assign/remove and typed fields"
```

---

### Task 4: 共用组件（ConfirmDialog + AlertBottomSheet）

**Files:**
- Create: `lib/features/b2b_admin/presentation/widgets/confirm_dialog.dart`
- Create: `lib/features/b2b_admin/presentation/widgets/alert_bottom_sheet.dart`

- [ ] **Step 1: 实现 ConfirmDialog**

```dart
class B2bConfirmDialog extends StatelessWidget {
  const B2bConfirmDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmLabel = '确认',
    this.isDestructive = false,
  });

  final String title;
  final String? subtitle;
  final String confirmLabel;
  final bool isDestructive;

  static Future<bool?> show(BuildContext context, {...}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => B2bConfirmDialog(...),
    );
  }
}
```

- [ ] **Step 2: 实现 AlertBottomSheet**

```dart
class B2bAlertBottomSheet extends StatelessWidget {
  const B2bAlertBottomSheet({super.key, required this.alerts, required this.totalCount});

  final List<Map<String, dynamic>> alerts;
  final int totalCount;

  static void show(BuildContext context, List<Map<String, dynamic>> alerts, int total) {
    showModalBottomSheet(
      context: context,
      builder: (_) => B2bAlertBottomSheet(alerts: alerts, totalCount: total),
    );
  }
}
```

- [ ] **Step 3: 运行 flutter analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/features/b2b_admin/presentation/widgets/
git commit -m "feat(b2b-ux): add shared B2bConfirmDialog and AlertBottomSheet"
```

---

### Task 5: 新增路由 + 注册

**Files:**
- Modify: `lib/app/app_route.dart`
- Modify: `lib/app/app_router.dart`

- [ ] **Step 1: 在 AppRoute 枚举新增 2 个路由**

```dart
b2bAdminRevenueDetail('/b2b/admin/revenue/:id', 'b2b-admin-revenue-detail', '对账详情'),
b2bWorkerDetail('/b2b/admin/workers/:farmId', 'b2b-worker-detail', '牧工详情'),
```

- [ ] **Step 2: 在 app_router.dart 注册子路由**

在 `b2bAdmin` GoRoute 的 `routes` 数组中，为 `revenue` 和 `workers` 子路由各增加一个子路由：

```dart
GoRoute(
  path: 'revenue',
  name: AppRoute.b2bAdminRevenue.routeName,
  builder: (context, state) => const B2bRevenuePage(),
  routes: [
    GoRoute(
      path: ':id',
      name: AppRoute.b2bAdminRevenueDetail.routeName,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return B2bRevenueDetailPage(periodId: id);
      },
    ),
  ],
),
GoRoute(
  path: 'workers',
  name: AppRoute.b2bWorkerManagement.routeName,
  builder: (context, state) => const B2bWorkerManagementPage(),
  routes: [
    GoRoute(
      path: ':farmId',
      name: AppRoute.b2bWorkerDetail.routeName,
      builder: (context, state) {
        final farmId = state.pathParameters['farmId']!;
        return B2bWorkerDetailPage(farmId: farmId);
      },
    ),
  ],
),
```

同时添加新的 import。

- [ ] **Step 3: 运行 flutter analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/app/app_route.dart lib/app/app_router.dart
git commit -m "feat(b2b-ux): add revenue detail and worker detail routes"
```

---

### Task 6: 概览页重写

**Files:**
- Modify: `lib/features/b2b_admin/presentation/b2b_controller.dart`
- Modify: `lib/features/b2b_admin/presentation/b2b_dashboard_page.dart`

- [ ] **Step 1: 扩展 B2bDashboardController**

在 `build()` 中额外加载 revenue 本月数据，填充 `monthlyRevenue`/`deviceOnlineRate`。

- [ ] **Step 2: 重写 B2bDashboardPage**

页面结构：
1. 页头："B端控制台" + `partnerName` + 合同状态
2. 经营概览主卡片（灰蓝渐变 `#37474f → #546e7a`）：月分润收入 / 总牲畜 / 待处理告警 + 设备在线率进度条
3. 告警提醒条（`#fff3e0` 背景）：仅 `pendingAlerts > 0` 时显示，点击弹出 `B2bAlertBottomSheet`
4. 快捷入口网格（4 列）：对账/合同/牧场/牧工（Material Icons: `bar_chart`/`description`/`agriculture`/`engineering`）
5. 牧场列表：每张卡片含 `agriculture` icon + 名称 + `groups`/`pets`/`sensors` 统计 + 状态标签

- [ ] **Step 3: 运行 flutter analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/features/b2b_admin/presentation/b2b_controller.dart \
        lib/features/b2b_admin/presentation/b2b_dashboard_page.dart
git commit -m "feat(b2b-ux): rewrite B2b dashboard with hero card, alerts, quick links"
```

---

### Task 7: 对账页重写 + 详情页

**Files:**
- Modify: `lib/features/b2b_admin/presentation/b2b_revenue_page.dart`
- Create: `lib/features/b2b_admin/presentation/b2b_revenue_detail_page.dart`

- [ ] **Step 1: 重写 B2bRevenuePage（列表页）**

页面结构：
1. 页头："对账"
2. 汇总指标（3 列）：累计分润（`#e8f5e9`）/ 待确认数（`#fff3e0`）/ 已结算数（`#e3f2fd`）
3. 筛选标签（Pill 样式：全部/待确认/已结算）
4. 周期卡片列表：左侧竖线颜色按状态 + 金额格式化 `¥x,xxx.xx` + 周期标签 `2026年5月` + "点击查看明细"

点击卡片 → `context.go('/b2b/admin/revenue/$periodId')`。

- [ ] **Step 2: 实现 B2bRevenueDetailPage（详情页）**

页面结构：
1. 面包屑："‹ 返回 对账 > 2026年5月 对账明细"
2. 周期汇总灰蓝卡片：总设备费 + 分润金额 + 分润比 + 结算时间
3. 确认状态条（`#fff3e0`）：双方确认状态 + "确认对账"按钮
4. 牧场明细表：白底圆角表格，每行含 farmName/livestockCount/deviceUnitPrice/deviceFee/shareAmount

确认流程：`B2bConfirmDialog.show()` → Loading → `controller.confirmPeriod()` → SnackBar。

- [ ] **Step 3: 运行 flutter analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/features/b2b_admin/presentation/b2b_revenue_page.dart \
        lib/features/b2b_admin/presentation/b2b_revenue_detail_page.dart
git commit -m "feat(b2b-ux): rewrite B2b revenue list and add detail page with drill-down"
```

---

### Task 8: 合同详情页重写

**Files:**
- Modify: `lib/features/b2b_admin/presentation/b2b_contract_page.dart`

- [ ] **Step 1: 重写 B2bContractPage**

页面结构：
1. 页头：返回 + "合同信息"
2. 主信息卡片（灰蓝渐变）：合作方名称 + `verified` 状态标签 + 分割线 + 编号/签约人/计费模式
3. 到期提醒条（蓝色渐变 `#e3f2fd → #bbdefb`）：`event` icon + 到期日 + 剩余天数 + "联系续签"按钮（颜色按天数：>90蓝/31-90橙/≤30红）
4. 合同条款区：`description` icon 标题 + 2×2 白底小卡片网格（`workspace_premium`/`percent`/`play_arrow`/`schedule` icons）
5. 订阅服务状态区块：仅 `billingModel === 'licensed'` 时显示。`vpn_key` icon 标题 + 绿/黄/红圆点 + 状态文字 + `cloud`/`devices`/`favorite`/`timer` 4格信息
6. 快捷操作：`phone` 联系平台 + `download` 下载合同（占位 Dialog）

- [ ] **Step 2: 运行 flutter analyze**

- [ ] **Step 3: Commit**

```bash
git add lib/features/b2b_admin/presentation/b2b_contract_page.dart
git commit -m "feat(b2b-ux): rewrite B2b contract page with expiry countdown and subscription status"
```

---

### Task 9: 牧工管理重写 + 详情页

**Files:**
- Modify: `lib/features/b2b_admin/presentation/b2b_worker_management_controller.dart`
- Modify: `lib/features/b2b_admin/presentation/worker_management_page.dart`
- Create: `lib/features/b2b_admin/presentation/b2b_worker_detail_page.dart`

- [ ] **Step 1: 扩展 B2bWorkerManagementController**

新增方法：
```dart
Future<bool> assignWorker(String farmId, String workerId);
Future<bool> removeWorker(String farmId, String workerId);
List<B2bSubFarmWorker> getAvailableWorkers();
```

- [ ] **Step 2: 重写 B2bWorkerManagementPage（牧场列表页）**

页面结构：
1. 页头："牧工管理"
2. 汇总指标（3 列）：牧场数/总牧工/离岗
3. 批量分配入口卡片（`person_add` icon + "批量分配牧工"）
4. 牧场卡片列表：`agriculture` icon 方块 + 名称 + `groups`/`pets` 统计 + 状态标签（全部在岗绿/有离岗橙）+ `chevron_right`

点击卡片 → `context.go('/b2b/admin/workers/$farmId')`。

- [ ] **Step 3: 实现 B2bWorkerDetailPage（工人详情页）**

页面结构：
1. 面包屑："‹ 牧工管理 > 西南合作牧场"
2. 牧场信息条：`groups`/`pets`/`sensors` 统计 + "分配牧工"按钮
3. 工人列表：`person` avatar 圆圈 + 姓名/入职日 + 在岗/离岗标签 + 移除按钮

分配流程：点击"分配牧工" → Dialog 多选可用工人 → 确认 → SnackBar。
移除流程：点击"移除" → `B2bConfirmDialog` → SnackBar。

- [ ] **Step 4: 运行 flutter analyze**

- [ ] **Step 5: Commit**

```bash
git add lib/features/b2b_admin/presentation/b2b_worker_management_controller.dart \
        lib/features/b2b_admin/presentation/worker_management_page.dart \
        lib/features/b2b_admin/presentation/b2b_worker_detail_page.dart
git commit -m "feat(b2b-ux): rewrite B2b worker management with farm drill-down and assign/remove"
```

---

### Task 10: 全量测试 + 回归

- [ ] **Step 1: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

Expected: 无新增 issue

- [ ] **Step 2: 运行 flutter test**

```bash
cd Mobile/mobile_app && flutter test
```

Expected: 全部 PASS

- [ ] **Step 3: 手动验证 b2b_admin 登录**

以 `mock-token-b2b-admin` 登录，验证：
- 概览页：主卡片数据、告警条、快捷入口可点击、牧场列表带统计
- 对账：汇总指标、筛选、点击进入详情页、确认流程弹窗
- 合同：到期天数、条款区、非 licensed 模式无订阅区块
- 牧工：汇总、点击进入工人详情、分配/移除 Dialog

- [ ] **Step 4: 最终 Commit**

```bash
git add -A
git commit -m "feat(b2b-ux): complete b2b_admin UX optimization — dashboard, revenue, contract, worker management"
```

---

## 测试策略

| Task | 测试 |
|------|------|
| Task 1 | `flutter analyze` 通过（编译期类型检查） |
| Task 2 | `flutter analyze` + 现有 revenue 测试不回归 |
| Task 3 | `flutter analyze` + 现有 worker 测试不回归 |
| Task 4 | `flutter analyze` |
| Task 5 | `flutter analyze` + 路由导航冒烟测试 |
| Task 6-9 | `flutter analyze` + `flutter test` 全量 |
| Task 10 | `flutter analyze` + `flutter test` + 手动端到端 |

---

## 执行波次

| 波次 | Tasks | 策略 |
|------|-------|------|
| 第一波 | 1, 2, 3 | 串行 — 数据层是所有页面的基础 |
| 第二波 | 4, 5 | 可并行 — 共用组件 + 路由互不依赖 |
| 第三波 | 6, 7, 8, 9 | 可并行 — 4 个页面相互独立 |
| 第四波 | 10 | 串行 — 全量回归 |
