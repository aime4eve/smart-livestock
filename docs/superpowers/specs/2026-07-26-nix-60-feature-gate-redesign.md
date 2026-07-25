# NIX-60：功能门控管理 UI/UX 重设计

**Date**: 2026-07-26
**Status**: Spec 待评审
**关联工单**: [NIX-60](https://linear.app/nix-agentic/issue/NIX-60)
**高保真原型**: `docs/marketing/nix-60-feature-gate-redesign-prototype.html`
**选定方案**: 方案 B — 按 tier 分 Tab + 功能列表卡片

---

## 1. 背景与痛点

### 1.1 现有问题

| # | 痛点 | 具体表现 | 根因 |
|---|------|---------|------|
| 1 | 看不到有效内容 | 所有 Tab 都显示"该等级暂无功能门控" | `feature_gate_page.dart:18` 用大写 `_tiers = ['BASIC',...]`，后端返回小写 `tier: 'basic'`，`grouped[tier]` 永远 miss |
| 2 | 功能不可读 | feature_key 是英文 raw key（如 `livestock_management`），无中文友好名 | 前端无 feature_key → 中文名映射，直接展示 raw key |
| 3 | 无分组 | 12 个 feature 平铺，无业务分类 | 缺少平台功能/健康模块的分类逻辑 |
| 4 | 编辑体验差 | limit/retention/switch/save 横向挤在一行，input 宽 80px，移动端难操作 | `_GateTile` 用 Row 平铺所有控件，无分组编辑模式 |

### 1.2 设计目标

- **数据可见**：修复 tier 大小写，48 条数据正确按档位展示
- **中文友好名**：12 个 feature_key 全部映射中文展示名 + i18n
- **业务分组**：分"平台功能"（7 项）和"健康模块"（5 项）两组
- **卡片式展示**：与订阅管理页 HighfiCard 风格一致
- **行内编辑**：配额值/保留天数/启用开关，保存即时生效

---

## 2. 数据模型

### 2.1 后端现有 DTO（无需修改）

后端 `/api/v1/admin/feature-gates` 已返回完整数据（48 条，4 tier × 12 feature），**后端无需改动**。

```json
{
  "id": 1,
  "tier": "basic",
  "featureKey": "livestock_management",
  "gateType": "LIMIT",
  "limitValue": 50,
  "retentionDays": null,
  "isEnabled": true
}
```

`gateType` 取值：`NONE`（无限制）、`LOCK`（布尔门控）、`LIMIT`（数值配额）、`FILTER`（数据范围，配 retentionDays）。

### 2.2 前端数据模型（无结构变更）

```dart
// feature_gate_models.dart — 现有模型保持不变
class FeatureGateEntry {
  final int id;
  final String tier;          // 'basic' | 'standard' | 'premium' | 'enterprise'
  final String featureKey;    // 'livestock_management' 等
  final String? gateType;     // 'NONE' | 'LOCK' | 'LIMIT' | 'FILTER'
  final int limitValue;
  final int retentionDays;
  final bool isEnabled;
}
```

### 2.3 Feature 中文映射（新增 i18n）

12 个 feature_key 的中文友好名，中英文 arb 同步新增：

| featureKey | 中文 | 英文 | 分类 |
|---|---|---|---|
| livestock_management | 牲畜管理 | Livestock Management | 平台功能 |
| fence_management | 围栏管理 | Fence Management | 平台功能 |
| alert_management | 告警管理 | Alert Management | 平台功能 |
| worker_management | 牧工管理 | Worker Management | 平台功能 |
| advanced_analytics | 高级分析 | Advanced Analytics | 平台功能 |
| api_access | API 访问 | API Access | 平台功能 |
| health_monitoring | 健康监控 | Health Monitoring | 平台功能 |
| temperature_monitor | 温度监控 | Temperature Monitor | 健康模块 |
| peristaltic_monitor | 蠕动监控 | Peristaltic Monitor | 健康模块 |
| health_score | 健康评分 | Health Score | 健康模块 |
| estrus_detect | 发情检测 | Estrus Detection | 健康模块 |
| epidemic_alert | 疫情预警 | Epidemic Alert | 健康模块 |

---

## 3. 设计令牌表（从原型提取，锁定）

### 3.1 颜色

| 令牌 | Hex | 用途 |
|---|---|---|
| `--primary` | `#2F6B3B` | 主题色（appbar、激活态、limit 配额值） |
| `--primary-dark` | `#244F2D` | 激活文字 |
| `--primary-soft` | `#E3F0E4` | 激活态背景 |
| `--accent` | `#8BA95A` | 辅助强调 |
| `--surface` | `#F8F6F0` | 页面背景、单元格背景 |
| `--surface-alt` | `#FFFFFF` | 卡片背景、tab 背景 |
| `--border` | `#D7D2C6` | 分隔线、卡片边框、未激活开关 |
| `--text-primary` | `#263126` | 主文字 |
| `--text-secondary` | `#617061` | 次要文字、标签 |
| `--success` | `#4C9A5F` | 开关 on、none 状态、解锁 |
| `--danger` | `#C2564B` | lock 状态、锁定值 |
| `--info` | `#4A7F9D` | filter 状态、范围值 |

### 3.2 间距

| 令牌 | 值 | 用途 |
|---|---|---|
| `--xs` | `4px` | 紧凑间距（chip 内 dot、单元格内间隙） |
| `--sm` | `8px` | 卡片间距、label 内边距 |
| `--md` | `12px` | 卡片内边距、section 间距 |
| `--lg` | `16px` | 列表外边距 |
| `--xl` | `24px` | 页面外边距 |

### 3.3 圆角 / 阴影 / 字号

| 令牌 | 值 | 用途 |
|---|---|---|
| `--radius-sm` | `8px` | tier 单元格、input |
| `--radius-md` | `12px` | 卡片（HighfiCard） |
| `--shadow-card` | `0 1px 3px rgba(38,49,38,.06), 0 1px 2px rgba(38,49,38,.04)` | 卡片阴影 |
| 字号 - section header | `11px / 700 / uppercase / letter-spacing .5px` | 分组标题 |
| 字号 - feature name | `12px / 600` | 卡片功能名 |
| 字号 - feature key | `9px / monospace` | raw key（次要展示） |
| 字号 - tier tab | `11px / 600`（激活）/ `500`（未激活） | tab 标签 |

---

## 4. 组件视觉规格

### 4.1 Tier TabBar（顶部）

- 高度：tab-item padding `10px 4px`，整体含底部 2px 指示线
- 4 个 tab 等宽：基础版 / 标准版 / 高级版 / 企业版
- 激活态：文字 `--primary`、底部线 `--primary`
- 未激活态：文字 `--text-secondary`、无线
- tab 下方小字：`{N} 项`（`8px`，当前 tab 着色）

### 4.2 FeatureCard（列表项卡片）

- 容器：`HighfiCard`（`--surface-alt` + `--radius-md` + `--shadow-card`）
- 内边距：`10px 12px`
- 布局：横向 Row —— 左侧功能信息，中间配额值（LIMIT/FILTER 时），右侧开关 + 编辑按钮

**左侧信息区**
- feature 中文名：`12px / 600`
- 第二行：raw key（`9px / monospace / --text-secondary`）+ gate 状态 chip

**Gate 状态 Chip**
- `none`：`--success` 背景 12%，边框 28%，"无限制"
- `limit`：`--primary` 背景 12%，"配额"
- `lock`（is_enabled=false）：`--danger` 背景 12%，"锁定"
- `lock`（is_enabled=true）：`--success` 背景 12%，"已解锁"
- `filter`：`--info` 背景 12%，"范围"

**中间配额值（仅 LIMIT/FILTER 显示）**
- 数值：`15px / 700`
  - LIMIT → `--primary`
  - FILTER → `--info`
- 单位：`8px / --text-secondary`（头/个/人/天，按 featureKey 映射）

**右侧开关 + 编辑**
- Switch：宽 36 高 20，on=`--success`，off=`--border`
- 编辑按钮：26×26 透明 icon button，`✎` 图标

### 4.3 行内编辑模式

点击编辑按钮后，卡片下方展开编辑区：
- 顶部虚线分隔（`1px dashed --border`）
- LIMIT 类型：input「限额」+ Switch「启用」+ Save/Cancel
- FILTER 类型：input「保留天数」+ Switch「启用」+ Save/Cancel
- LOCK 类型：仅 Switch「启用」+ Save/Cancel
- NONE 类型：无编辑区（无配置项）

### 4.4 Section 分组标题

- padding：`0 12px 6px`
- 文字：`11px / 700 / --text-secondary / uppercase / letter-spacing .5px`
- 右侧计数：`10px`，`--surface-alt` 背景圆角胶囊

### 4.5 空状态

- 理论上不会出现（每个 tier 都有 12 条），保留兜底
- 复用现有 `featureGateNoData` i18n key

---

## 5. 交互规格

### 5.1 Tab 切换

- 点击 tab 即时切换内容区，无 loading（数据已全量加载）
- 切换动画：Material TabBar 默认滑动指示器动画

### 5.2 编辑保存

- 点击 `✎` → 卡片底部展开编辑区，卡片获得 `--shadow-elev` 高亮
- 修改 input 或 switch → 显示 `保存`（激活）/`取消` 按钮
- 点击保存 → 调用 `controller.updateGate(id, ...)` → 成功后 SnackBar 提示，编辑区收起
- 点击取消 → 编辑区收起，不保存

### 5.3 开关即时切换

- 直接点击卡片右侧 Switch → 立即调用 `updateGate(id, isEnabled: newValue)`（无需进入编辑模式）
- 失败时回滚 switch 状态 + SnackBar 报错

---

## 6. i18n 新增 Key

中英文 arb 同步新增以下 key：

```
featureGateTierBasic       基础版    Basic
featureGateTierStandard    标准版    Standard
featureGateTierPremium     高级版    Premium
featureGateTierEnterprise  企业版    Enterprise

featureGateCatPlatform     平台功能  Platform Features
featureGateCatHealth       健康模块  Health Modules

featureGateUnitHead        头        head(s)
featureGateUnitCount       个        fence(s)
featureGateUnitPerson      人        worker(s)
featureGateUnitDay         天        day(s)

gateTypeNone               无限制    Unlimited
gateTypeLimit              配额      Quota
gateTypeLock               锁定      Locked
gateTypeLockOpen           已解锁    Unlocked
gateTypeFilter             范围      Range

featLivestockManagement    牲畜管理  Livestock Management
featFenceManagement        围栏管理  Fence Management
featAlertManagement        告警管理  Alert Management
featWorkerManagement       牧工管理  Worker Management
featAdvancedAnalytics      高级分析  Advanced Analytics
featApiAccess              API访问   API Access
featHealthMonitoring       健康监控  Health Monitoring
featTemperatureMonitor     温度监控  Temperature Monitor
featPeristalticMonitor     蠕动监控  Peristaltic Monitor
featHealthScore            健康评分  Health Score
featEstrusDetect           发情检测  Estrus Detection
featEpidemicAlert          疫情预警  Epidemic Alert
```

---

## 7. 后端改动

**无后端改动**。后端 API 和数据已完整，tier 返回小写是设计意图（前端统一 toUpperCase 比较）。

---

## 8. 验收标准

- [ ] 4 个 tab 都能显示 12 条 feature 数据（修复大小写 bug）
- [ ] 每个 feature 显示中文名 + raw key
- [ ] feature 按平台功能/健康模块分组
- [ ] LIMIT/FILTER 类型的卡片显示配额值和单位
- [ ] LOCK 类型显示开关，NONE 类型显示"无限制"
- [ ] 编辑按钮可展开行内编辑区
- [ ] 保存成功后 SnackBar 提示
- [ ] tab 可切换，切换后正确显示对应档位数据
- [ ] flutter analyze 无新增 warning
- [ ] flutter gen-l10n 无缺失 key
