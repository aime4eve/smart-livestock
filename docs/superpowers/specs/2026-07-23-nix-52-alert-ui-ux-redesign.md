# NIX-52：告警中心 UI/UX 重设计

**Date**: 2026-07-23
**Status**: Spec 待评审
**关联工单**: [NIX-52](https://linear.app/nix-agentic/issue/NIX-52)
**高保真原型**: `docs/marketing/nix-52-alert-ui-redesign-prototype.html`

---

## 1. 背景与痛点

### 1.1 现有问题

| # | 痛点 | 具体表现 | 根因 |
|---|------|---------|------|
| 1 | 操作体验杂乱 | 状态/类型 chips 是装饰性组件，不可点击；操作按钮只作用于 `firstItem`（第一条告警） | `alerts_page.dart` 的 chips 是 `HighfiStatusChip` 静态展示，无 `onTap`；操作按钮 `onPressed` 调用 `controller.acknowledge(firstItem.id)` |
| 2 | 浏览不丝滑 | 无搜索、无分组、无分页、无已读/未读视觉区分 | 页面用 `SingleChildScrollView` 平铺所有卡片，无分组逻辑；`AlertItem` 无 `read` 字段 |
| 3 | 看不到细节 | 卡片只显示标题和通用描述文字（硬编码 P0 假数据），无时间、牲畜编号、设备信息、严重程度可视化 | `_buildP0AlertRows` 硬编码 3 行假数据；`AlertItem` 只有 title/subtitle/priority/type/stage，无 detail 字段 |

### 1.2 设计目标

- **真实数据驱动**：移除所有硬编码假数据，全部来自 `/alerts` API
- **功能性筛选**：状态分段控件 + 类型横向滑动 chips 均可点击过滤
- **富信息展示**：卡片展示完整元数据，详情面板展示全部字段 + 处置时间线
- **流畅浏览**：按日期分组、已读/未读区分、摘要快速跳转
- **与牧场页联动**：从牧场页横幅/看板卡片自然进入告警中心，详情面板可跳转回地图定位

---

## 2. 数据模型

### 2.1 后端现有 DTO（无需修改）

```java
// AlertDto.java — 已有字段，无需新增
public record AlertDto(
    Long id,
    Long farmId,
    Long livestockId,
    Long fenceId,
    String type,          // FENCE_BREACH | FENCE_APPROACH | ZONE_APPROACH |
                          // TEMPERATURE_ABNORMAL | DIGESTIVE_ABNORMAL |
                          // ESTRUS | EPIDEMIC | AI_ANOMALY |
                          // DEVICE_TAMPER | DEVICE_LOW_BATTERY
    String status,        // ACTIVE | DISMISSED | AUTO_RESOLVED
    String severity,      // INFO | WARNING | CRITICAL
    String message,
    boolean read,         // 已读状态（per-user, alert_read_status 表）
    String resolvedType,  // AUTO | MANUAL_DISMISS
    Instant resolvedAt,
    Long acknowledgedBy,
    Instant acknowledgedAt,
    Long handledBy,
    Instant handledAt,
    String source         // RULE | AI
) {}
```

**结论**：后端 AlertDto 字段已足够支撑重设计所需的所有信息，**后端无需改动**。

### 2.2 前端数据模型变更

```dart
// 新增字段到 AlertItem（对齐 AlertDto）
class AlertItem {
  final String id;
  final String title;
  final String subtitle;
  final String priority;
  final String type;
  final String stage;
  final String livestockCode;
  final String? livestockId;
  final String source;

  // ── 新增字段 ──
  final String severity;        // INFO | WARNING | CRITICAL
  final bool read;              // 已读状态
  final String? occurredAt;     // ISO 时间戳
  final String? resolvedAt;     // ISO 时间戳
  final String? fenceName;      // 围栏名称（需后端 join 或前端缓存）
  final String? resolvedType;   // AUTO | MANUAL_DISMISS
}
```

### 2.3 前端新增类型映射

```dart
// 告警类型元数据（图标、颜色、标签）
enum AlertTypeMeta {
  fenceBreach('FENCE_BREACH', '围栏越界', Icons.fence, AlertColor.critical),
  fenceApproach('FENCE_APPROACH', '接近围栏', Icons.warning, AlertColor.warning),
  zoneApproach('ZONE_APPROACH', '区域接近', Icons.location_on, AlertColor.info),
  temperatureAbnormal('TEMPERATURE_ABNORMAL', '体温异常', Icons.thermostat, AlertColor.critical),
  digestiveAbnormal('DIGESTIVE_ABNORMAL', '消化异常', Icons.pets, AlertColor.warning),
  estrus('ESTRUS', '发情检测', Icons.favorite, AlertColor.estrus),
  epidemic('EPIDEMIC', '疫病预警', Icons.shield, AlertColor.critical),
  aiAnomaly('AI_ANOMALY', 'AI异常', Icons.psychology, AlertColor.ai),
  deviceTamper('DEVICE_TAMPER', '设备拆卸', Icons.sensors, AlertColor.warning),
  deviceLowBattery('DEVICE_LOW_BATTERY', '低电量', Icons.battery_alert, AlertColor.warning);
}
```

---

## 3. 页面架构

### 3.1 页面树（与现有 app 路由的关系）

```
RanchPage (地图, /ranch)
├── 告警横幅（严重告警 > 0 时显示，点击 → AlertsPage）
├── 地图标记（告警牲畜用对应严重度颜色标记）
└── 底部看板卡片（围栏/健康/设备分类计数，点击 → AlertsPage）
    └── AlertsPage (告警中心, /alerts)  ← 本次重设计范围
        ├── 摘要条（严重/警告/待处理计数，可点击筛选）
        ├── 状态分段控件（全部 / 活跃 / 已处理）
        ├── 类型横向滑动 chips（全部类型 + 10 种告警类型）
        ├── 告警列表（按日期分组）
        │   └── AlertCard（单条告警）
        │       ├── 点击 → AlertDetailSheet（底部面板）
        │       │   ├── 完整元数据网格
        │       │   ├── 处置时间线
       │       │   └── 操作按钮（标记已读 / 忽略 / 地图定位）
        │       │   └── 操作按钮（标记已读 / 忽略 / 地图定位 / 查看轨迹）
        │       └── 长按 → 批量模式
        │           └── BatchBottomBar（批量已读 / 批量忽略）
        └── 空状态（无告警时友好引导）
```

### 3.2 文件变更清单

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `lib/features/pages/alerts_page.dart` | **重写** | 完全重写，移除硬编码假数据和装饰性 chips |
| `lib/features/alerts/domain/alerts_repository.dart` | **修改** | `AlertItem` 新增 severity/read/occurredAt/fenceName 字段；`AlertsListData` 新增摘要计数 |
| `lib/features/alerts/data/alerts_api_repository.dart` | **修改** | 解析 AlertDto 新字段；`loadDetail` 返回完整详情 |
| `lib/features/alerts/presentation/alerts_controller.dart` | **修改** | 新增筛选状态管理（status/severity/type）；新增 batchSelect 状态 |
| `lib/features/alerts/presentation/widgets/alert_card.dart` | **新增** | 富信息告警卡片组件 |
| `lib/features/alerts/presentation/widgets/alert_detail_sheet.dart` | **新增** | 底部详情面板组件 |
| `lib/features/alerts/presentation/widgets/alert_summary_strip.dart` | **新增** | 顶部摘要条组件 |
| `lib/features/alerts/presentation/widgets/alert_filter_bar.dart` | **新增** | 筛选栏组件（分段控件 + 类型 chips） |
| `lib/features/alerts/presentation/widgets/alert_batch_bar.dart` | **新增** | 批量操作底栏组件 |
| `lib/features/alerts/presentation/widgets/alert_empty_state.dart` | **新增** | 空状态组件 |
| `lib/l10n/app_zh.arb` / `app_en.arb` | **修改** | 新增告警类型标签、摘要文案等 i18n key |

---

## 4. 组件设计

### 4.1 AlertsPage（页面主体）

布局（CustomScrollView + Slivers）：

```
┌─────────────────────────┐
│ Appbar（标题 + 全部已读） │
├─────────────────────────┤
│ SummaryStrip（sliver）   │  ← 严重/警告/待处理 计数，可点击
├─────────────────────────┤
│ FilterBar（pinned sliver）│  ← 分段控件 + 类型 chips，滚动时固定
├─────────────────────────┤
│ DateGroup: 今天 (5 条)   │
│   AlertCard × N         │
│ DateGroup: 昨天 (2 条)   │
│   AlertCard × N         │
│ DateGroup: 更早 (3 条)   │
│   AlertCard × N         │
├─────────────────────────┤
│ BottomNav（牧场 / 我的）  │
└─────────────────────────┘
```

### 4.2 AlertCard（富信息卡片）

每张卡片包含：

| 区域 | 内容 | 视觉 |
|------|------|------|
| 左侧色条 | severity 颜色 | 3px 宽，critical=红/warning=橙/info=蓝 |
| 类型图标 | 10 种类型对应图标 | 36px 圆角方形，浅色背景 |
| 标题 | message（截断） | 14px 加粗，未读更深色 |
| 未读圆点 | read=false | 8px 绿色圆点 |
| 元信息行 | 牲畜编号 · 围栏 · 时间 | 11px 灰色 |
| 标签行 | 类型标签 + 状态标签 + 来源标签 | 10px 彩色小标签 |

**交互**：
- 单击 → 打开 `AlertDetailSheet`
- 长按 → 进入批量模式，当前卡片自动选中

### 4.3 AlertDetailSheet（详情面板）

从底部滑出的 modal bottom sheet：

```
┌─────────────────────────┐
│ ─── drag handle ─── ✕   │
│       [大图标]           │  ← 类型图标 56px
│   牲畜 #LS-028 越出...   │  ← 完整标题
│  [围栏越界][严重][活跃]   │  ← 标签组
├─────────────────────────┤
│ 💡 告警描述...           │  ← 详细说明
├─────────────────────────┤
│ 发生时间   牲畜编号      │
│ 牲畜类型   所在围栏      │  ← 元数据网格 2×3
│ 严重程度   告警来源      │
├─────────────────────────┤
│ 📋 处置时间线            │
│ ● 09:39 规则引擎触发告警 │
│ ○ 等待处理...            │
├─────────────────────────┤
│ [📍定位][📈轨迹][✓已读][忽略] │  ← 操作按钮
└─────────────────────────┘
```

**操作按钮逻辑**（根据 status 和角色权限动态显示）：

| 条件 | 显示按钮 |
|------|---------|
| ACTIVE + owner/b2b_admin | 地图定位 + 查看轨迹 + 标记已读 + 忽略 |
| ACTIVE + worker | 地图定位 + 查看轨迹 + 标记已读 |
| DISMISSED | 地图定位 + 查看轨迹 + （已忽略，不可操作） |
| AUTO_RESOLVED | 地图定位 + 查看轨迹 + （自动恢复，不可操作） |

### 4.4 批量模式

**进入方式**：长按任意告警卡片

**UI 变化**：
- Appbar 标题变为「批量管理 (N)」，右侧显示「取消」「全选」
- 每张卡片左侧出现 checkbox
- 底部出现 `BatchBottomBar`（批量已读 + 批量忽略）

**操作完成后**：退出批量模式，刷新列表

### 4.5 摘要条（SummaryStrip）

顶部三个统计项，点击切换 severity 筛选：

| 统计项 | 数据来源 | 点击行为 |
|--------|---------|---------|
| 严重 | `severity == CRITICAL && status == ACTIVE` | 筛选 CRITICAL |
| 警告 | `severity == WARNING && status == ACTIVE` | 筛选 WARNING |
| 待处理 | `status == ACTIVE` | 筛选 ACTIVE |

### 4.6 筛选栏（FilterBar）

**状态分段控件**（SegmentedButton）：
- 全部：所有告警
- 活跃：status == ACTIVE（带未读 badge）
- 已处理：status != ACTIVE（DISMISSED + AUTO_RESOLVED）

**类型横向滑动 chips**：
- 从当前数据中动态提取出现的告警类型
- 「全部类型」+ 每种类型一个 chip
- 点击切换 type 筛选

---

## 5. 国际化（i18n）

### 新增 ARB key

**中文 (`app_zh.arb`)**：

| Key | 值 |
|-----|---|
| `alertSeverityCritical` | "严重" |
| `alertSeverityWarning` | "警告" |
| `alertSeverityInfo` | "提示" |
| `alertSummaryPending` | "待处理" |
| `alertDetailTitle` | "告警详情" |
| `alertDetailOccurredAt` | "发生时间" |
| `alertDetailLivestockCode` | "牲畜编号" |
| `alertDetailLivestockType` | "牲畜类型" |
| `alertDetailFence` | "所在围栏" |
| `alertDetailSeverity` | "严重程度" |
| `alertDetailSource` | "告警来源" |
| `alertDetailDistance` | "偏离距离" |
| `alertDetailTimeline` | "处置时间线" |
| `alertActionMarkRead` | "标记已读" |
| `alertActionDismiss` | "忽略" |
| `alertActionLocate` | "地图定位" |
| `alertActionTrajectory` | "查看轨迹" |
| `alertActionMarkAllRead` | "全部已读" |
| `alertBatchTitle` | "批量管理" |
| `alertBatchSelected` | "已选 {count} 条" |
| `alertBatchSelectAll` | "全选" |
| `alertBatchCancel` | "取消" |
| `alertBatchRead` | "批量已读" |
| `alertBatchDismiss` | "批量忽略" |
| `alertEmptyTitle` | "暂无告警" |
| `alertEmptyDesc` | "所有牲畜状态正常，围栏和设备运行良好" |
| `alertTypeFenceBreach` | "围栏越界" |
| `alertTypeFenceApproach` | "接近围栏" |
| `alertTypeZoneApproach` | "区域接近" |
| `alertTypeTemperatureAbnormal` | "体温异常" |
| `alertTypeDigestiveAbnormal` | "消化异常" |
| `alertTypeEstrus` | "发情检测" |
| `alertTypeEpidemic` | "疫病预警" |
| `alertTypeAiAnomaly` | "AI异常" |
| `alertTypeDeviceTamper` | "设备拆卸" |
| `alertTypeDeviceLowBattery` | "低电量" |
| `alertSourceRule` | "规则触发" |
| `alertSourceAi` | "AI检测" |

**英文 (`app_en.arb`)**：同步翻译所有 key。

---

## 6. API 调用

### 6.1 现有端点（无需新增）

| 方法 | 路径 | 用途 |
|------|------|------|
| GET | `/farms/{farmId}/alerts?page=&pageSize=&status=&severity=` | 告警列表（已支持 status 和 severity 参数） |
| GET | `/farms/{farmId}/alerts/{alertId}` | 告警详情 |
| POST | `/farms/{farmId}/alerts/{alertId}/read` | 标记已读 |
| POST | `/farms/{farmId}/alerts/{alertId}/dismiss` | 忽略告警 |
| POST | `/farms/{farmId}/alerts/batch-read` | 批量已读 |

### 6.2 前端 Repository 变更

修改：传递 severity 参数到 API，解析 read / severity / occurredAt 字段。

### 6.3 fenceName 获取

AlertDto 当前不含 fenceName。两个方案：

1. **后端方案**（推荐）：AlertController join fence 表返回 fenceName
2. **前端方案**：加载告警后用 fenceId 批量查询围栏名称缓存

Spec 评审时确定方案。

---

## 7. 与牧场页的联动

### 7.1 告警横幅

在 `RanchPage` 地图上方，当存在 CRITICAL 活跃告警时显示横幅，点击跳转到 `/alerts`。

### 7.2 看板卡片增强

现有 `StatusDashboardCard` 按类别（围栏/健康/设备）展示告警数，增加 `onTap` 跳转到告警中心并预筛选对应类型。

### 7.3 地图标记

现有地图标记已根据告警状态着色（`fenceStatusMap`），本次不改变标记逻辑，仅确保告警详情面板的「地图定位」按钮能跳转回牧场页并定位到对应牲畜。

### 7.4 轨迹联动

告警详情面板的「查看轨迹」按钮复用现有 showTrajectorySheet()（lib/features/livestock/presentation/widgets/trajectory_sheet.dart），直接以 livestockId 调用，展示该牲畜的 GPS 运动轨迹。围栏越界告警场景下，用户可直观看到牲畜如何越界。

---

## 8. 约束与边界

### 8.1 不改动范围

- **后端 AlertController / AlertDto / Alert domain model**：字段已足够，不改
- **牧场页地图逻辑**：标记和围栏渲染逻辑不改，仅增加横幅
- **角色权限**：保持现有 `RolePermission` 体系，worker 只能标记已读，owner/b2b_admin 可忽略

### 8.2 性能考虑

- 告警列表默认 pageSize=20，支持分页加载（未来迭代）
- 当前种子数据量约 10 条，性能不是瓶颈
- 摘要计数在前端从列表数据计算，无需额外 API

### 8.3 向后兼容

- 保留 legacy API 端点（acknowledge/handle/archive）和 legacy controller 方法
- 新 UI 调用新端点（read/dismiss/batch-read），但 controller 方法名保持兼容

---

## 9. 验收标准

| # | 验收项 | 验证方式 |
|---|--------|---------|
| 1 | 告警列表全部来自 API，无硬编码假数据 | grep 代码确认无 `_buildP0AlertRows` |
| 2 | 状态分段控件点击后列表实时过滤 | 手动测试：点击「活跃」只显示 ACTIVE |
| 3 | 类型 chips 点击后列表实时过滤 | 手动测试 |
| 4 | 摘要条点击跳转对应筛选 | 手动测试 |
| 5 | 告警卡片展示牲畜编号、围栏、时间、来源 | 视觉确认 |
| 6 | 已读/未读视觉区分（色条 + 圆点） | 视觉确认 |
| 7 | 点击卡片弹出详情面板 | 手动测试 |
| 8 | 详情面板展示完整元数据 + 时间线 | 视觉确认 |
| 9 | 详情面板操作按钮按角色和状态正确显示 | owner vs worker 测试 |
| 10 | 长按进入批量模式 | 手动测试 |
| 11 | 批量已读/批量忽略功能正常 | 手动测试 |
| 12 | 已处理视图显示 DISMISSED + AUTO_RESOLVED | 手动测试 |
| 13 | 空状态显示友好引导 | 无告警时确认 |
| 14 | i18n 双语同步 | `flutter gen-l10n` 无缺失 key |
| 15 | 牧场切换后告警列表刷新 | FarmScopedNotifier 验证 |
| 16 | 「地图定位」跳转回牧场页 | 手动测试 |
| 17 | 「查看轨迹」打开牲畜轨迹面板 | 手动测试 |

---

## 10. 风险与依赖

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| AlertDto 不含 fenceName | 围栏名称显示为空 | 方案 1：后端 join fence 表（推荐）；方案 2：前端缓存 |
| 前端 AlertItem 新增字段可能影响其他引用 | 编译错误 | 全局搜索 AlertItem 使用处，同步更新 |
| 时间线数据（acknowledgedAt/handledAt）可能为 null | 时间线不完整 | null 安全处理，仅展示有值的节点 |

---

## 11. 围栏管理统一设计（扩展范围）

### 11.1 现状问题

围栏 CRUD 操作散落在牧场页地图上的 4 个不同位置：

| 操作 | 当前位置 | 问题 |
|------|---------|------|
| 围栏列表 | 左侧滑出面板（FAB 菜单按钮切换） | 发现性差，用户不知道点左侧空白按钮 |
| 新增围栏 | 地图右下角 FAB(+) | 和编辑 FAB 互斥显示，困惑 |
| 编辑围栏 | 选中围栏后右下角出现 FAB | onEdit 跳转 `/fence` 而非 `/fence/form?fenceId=xxx`，疑似 bug |
| 删除围栏 | 滑出面板内卡片删除按钮 | 入口太深 |

地图上同时存在 3 个 FAB（面板切换、新增、编辑），操作入口分散。

### 11.2 方案：底部 sheet 分段 Tab

将牧场页底部 sheet 改为分段 Tab 结构：

| Tab | 内容 |
|-----|------|
| 概览 | 看板卡片（围栏/健康/设备告警数 + 牲畜总数） |
| 围栏 | 围栏列表 + 新增按钮 + 每项含编辑/删除/查看告警 |
| 告警 | 告警列表（本次重设计核心），带未读 badge |

### 11.3 围栏 Tab 设计

**围栏列表**（sheet-tab-content 区域）：

- 顶部：标题「围栏列表 (N)」+ 右侧「＋ 新增围栏」按钮
- 每项：围栏颜色点 + 名称 + 元信息（面积/牲畜数/类型）+ 编辑/删除图标按钮
- 点击围栏项 → 地图高亮对应围栏 + 展开围栏详情卡片

**围栏详情卡片**（点击围栏项后展开）：

| 信息 | 来源 |
|------|------|
| 面积 | `FenceItem.areaHectares` |
| 围栏类型 | `FenceItem.type`（多边形/矩形/圆形） |
| 围栏内牲畜数 | `FenceItem.livestockCount` |
| 活跃告警数 | 从 `overview.alerts` 按 fenceId 过滤 |

操作按钮：
- 编辑边界 → `context.push('/fence/form?fenceId=${fence.id}')`
- 查看告警 → 切换到告警 Tab，预筛选该围栏
- 删除 → 弹出确认对话框

### 11.4 移除项

- 左侧滑出面板（`AnimatedPositioned` + `_fencePanelOpen`）
- 围栏面板切换 FAB（`ranch-fence-panel-toggle`）
- 地图右下角新增围栏 FAB（`ranch-add-fence-btn`）
- 地图右下角编辑围栏 FAB（`ranch-edit-fence-btn`）

### 11.5 Bug 修复

现有 `onEdit: () => context.go(AppRoute.fence.path)` 跳转到 `/fence` 而非 `/fence/form?fenceId=xxx`，修改为：
```dart
onEdit: () => context.push('${AppRoute.fenceForm.path}?fenceId=${fence.id}')
```

### 11.6 文件变更（围栏部分）

| 文件 | 变更 |
|------|------|
| `lib/features/pages/ranch_page.dart` | 移除滑出面板和散落 FAB；底部 sheet 改为分段 Tab；新增围栏 Tab 内容 |
| `lib/features/ranch/presentation/widgets/ranch_fence_tab.dart` | **新增**：围栏 Tab 内容组件（列表 + 详情卡片） |

### 11.7 牲畜快捷面板增强

现有 `LivestockDetailSheet` 信息过薄（只有编号 + 坐标 + 简单告警列表），增强为：

| 区域 | 内容 |
|------|------|
| 头部 | 健康圆点 + 牲畜编号 + 品种标签 + 「详情页」入口 |
| 活跃告警横幅 | 有告警时显示，点击跳转告警详情 |
| 关键指标 2x2 | 体温 / 设备电量 / 最后定位 / 围栏状态 |
| 快捷操作 | 查看轨迹 / 地图定位 / 告警详情 |
| 关联告警列表 | 该牲畜的所有活跃告警 |

**文件变更**：重写 `lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart`

---

## 12. 验收标准（追加）

| # | 验收项 | 验证方式 |
|---|--------|---------|
| 18 | 底部 sheet 显示分段 Tab（概览/围栏/告警） | 视觉确认 |
| 19 | 概览 Tab 看板卡片点击可切换到对应 Tab | 手动测试 |
| 20 | 围栏 Tab 显示围栏列表 + 新增按钮 | 视觉确认 |
| 21 | 点击围栏项高亮地图并展开详情卡片 | 手动测试 |
| 22 | 围栏详情编辑边界正确跳转 /fence/form?fenceId=xxx | 手动测试 |
| 23 | 围栏详情查看告警切换到告警 Tab 并预筛选 | 手动测试 |
| 24 | 删除围栏弹出确认对话框 | 手动测试 |
| 25 | 地图上不再有散落的 FAB | grep 确认无 ranch-fence-panel-toggle / ranch-add-fence-btn / ranch-edit-fence-btn |
| 26 | 点击地图牲畜标记弹出增强后的快捷面板 | 手动测试 |
| 27 | 牲畜快捷面板显示体温/电量/定位/围栏状态 | 视觉确认 |
| 28 | 牲畜快捷面板轨迹按钮打开 showTrajectorySheet | 手动测试 |
