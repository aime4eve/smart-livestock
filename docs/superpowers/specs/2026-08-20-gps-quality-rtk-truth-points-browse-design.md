# GPS 质量检查：RTK 真值点浏览优化设计

**Date**: 2026-08-20
**Status**: 已确认
**高保真原型**: `docs/marketing/gps-quality-rtk-truth-points-browse-prototype.html`
**影响范围**: Flutter 管理端 GPS 质量检查 → 真值参照 → RTK 真值点

---

## 1. 背景

当前实现在 `truth_reference_tab.dart` 中按位置使用 `ExpansionTile` 折叠，每个 RTK 点再用 `ListTile` 垂直堆叠：

- 33 个种子点形成长列表，位置、点位、坐标不能按列扫视和比较。
- 坐标使用 `toStringAsFixed(5)`，而数据库为 `DECIMAL(10,7)`，界面损失了约米级精度。
- 无搜索、无排序，定位一个点只能靠肉眼和折叠组。
- `subtitle` 中硬编码 `'{n} 个点位'`，违反项目 i18n 规则。

本设计将 RTK 点浏览改为“位置分组导航 + 点位表格”，保留现有新增、删除、API 与数据模型。

## 2. 范围

### 2.1 本期做

- 重构 RTK 真值点子面板的浏览布局。
- 增加本地搜索、自然数字排序、经纬度排序。
- 坐标固定展示 7 位小数。
- 增加全部位置视图和当前位置视图。
- 修复该面板内的硬编码中文。
- 补充中英文 i18n 与 widget 测试。

### 2.2 本期不做

- 不修改后端 API、数据库、Flyway、`RtkPoint` 模型。
- 不修改“动态路线”“标准轨迹”子页签。
- 不新增地图预览、批量导入、编辑点位、复制坐标等功能。
- 不改变新增/删除的业务校验和错误处理。

## 3. 信息架构

桌面端结构：

```text
RTK 真值点 [20]            [搜索位置、点位或坐标] [+ 新增点位]
┌──────────────┬──────────────────────────────────────────────────┐
│ 全部位置 33  │ 点位编号   纬度             经度             操作 │
│ 宿舍楼顶 4   │ 11号点    28.2465940     112.8516104      删除  │
│ 西南门 2     │ 12号点    28.2465306     112.8515918      删除  │
│ ...          │ ...                                                       │
│ 一期楼顶 20  │                                                            │
└──────────────┴──────────────────────────────────────────────────┘
```

规则：

- 默认选中点数最多的位置；当前 33 个种子点下即“一期楼顶”。无点位时选中“全部位置”。
- “全部位置”额外显示“位置”列；具体位置视图隐藏该列。
- 搜索、排序、分组切换均为本地状态，不发起额外 API 请求。
- 位置分组顺序按该组首个点在 API 返回中的出现顺序；组内默认按点位编号自然升序。

## 4. 交互规格

### 4.1 搜索

- 输入即过滤，不要求回车。
- 匹配字段：位置名、点位编号、`latitude.toStringAsFixed(7)`、`longitude.toStringAsFixed(7)`。
- 匹配规则：大小写不敏感的 substring。
- 在具体位置下输入非空搜索词时，自动切换到“全部位置”，避免匹配点被当前位置过滤隐藏。
- 清空搜索后停留在“全部位置”，由用户重新选择位置；这是可预期且减少状态跳变的做法。
- 无匹配时表格区域显示空态，不显示错误。

### 4.2 排序

- 默认：点位编号自然升序，`1号点、2号点、10号点`，不是字典序。
- 点位编号无数字时排在有数字点之后，再按字符串稳定排序。
- 可排序列：点位编号、位置（仅全部位置视图）、纬度、经度。
- 点击同一列头在升序/降序间切换；切换列时重置为升序。
- 数值排序以原始 `double` 比较；相等时按点位编号自然排序稳定破平。

### 4.3 新增

- 保留现有新增点位弹窗和 `rtkPointsProvider.notifier.createPoint()` 流程。
- 创建成功后清空搜索词，并选中新点位所属位置，让用户立即看到结果。
- 创建失败沿用现有 SnackBar 错误提示。

### 4.4 删除

- 保留现有确认弹窗、`deletePoint()` 流程和失败提示。
- 删除成功后刷新分组计数；如果当前选中位置已无点位，自动切回“全部位置”。

### 4.5 加载与异常

- Loading：表格区域保持最小高度 120，居中显示进度圈。
- Error：沿用现有错误文本展示，文字为 danger 色。
- 空数据：显示现有“暂无数据”空态。
- 搜索无匹配：显示专用“没有匹配的 RTK 真值点”空态。

## 5. 设计令牌表

以下令牌从原型 `:root` 提取并锁定。Flutter 落地时优先映射 `AppColors` / `AppSpacing`；本项目没有全局 radius/shadow token 的值按本表局部使用。

### 5.1 颜色

| 令牌 | 值 | Flutter 映射 / 用途 |
|---|---:|---|
| `--color-primary` | `#2F6B3B` | `AppColors.primary`，主按钮、激活排序、选中位置强调 |
| `--color-primary-dark` | `#244F2D` | `AppColors.primaryDark`，选中位置文字 |
| `--color-primary-soft` | `#E3F0E4` | `AppColors.primarySoft`，选中位置、计数徽章 |
| `--color-surface` | `#F8F6F0` | `AppColors.surface`，页面背景 |
| `--color-surface-alt` | `#FFFFFF` | `AppColors.surfaceAlt`，面板、表头、输入框 |
| `--color-surface-muted` | `#F2F0EA` | `AppColors.surfaceMuted`，hover 背景 |
| `--color-border` | `#D7D2C6` | `AppColors.border`，描边和分隔线 |
| `--color-text` | `#263126` | `AppColors.textPrimary`，主文字 |
| `--color-text-secondary` | `#617061` | `AppColors.textSecondary`，次文字 |
| `--color-danger` | `#C2564B` | `AppColors.danger`，删除 hover 文字 |
| `--color-danger-soft` | `#FBE8E6` | `AppColors.dangerSoft`，删除 hover 背景 |
| `--color-row-hover` | `#FBFAF6` | 表格行 hover 背景，局部常量 |

### 5.2 间距 / 圆角 / 阴影

| 令牌 | 值 | 用途 |
|---|---:|---|
| `--space-xs` | `4px` | `AppSpacing.xs`，紧凑间距 |
| `--space-sm` | `8px` | `AppSpacing.sm`，控件间距 |
| `--space-md` | `12px` | `AppSpacing.md`，面板头/表单内边距 |
| `--space-lg` | `16px` | `AppSpacing.lg`，子页签下间距、表格单元左右间距 |
| `--space-xl` | `24px` | `AppSpacing.xl`，页面和原型内容外边距 |
| `--radius-sm` | `4px` | 计数徽章 |
| `--radius-md` | `6px` | 输入框、按钮、位置项 |
| `--radius-lg` | `8px` | 外层面板 |
| `--shadow-card` | `0 1px 2px rgba(38,49,38,0.08)` | 外层面板阴影 |

### 5.3 字体

| 用途 | 规格 |
|---|---|
| 面板标题 | 15px / 600 / 主文字色 |
| 位置名、表格正文、按钮 | 13px / 400-600 |
| 计数、表头、坐标 | 12px |
| 表头 | 12px / 600 / 次文字色 |
| 坐标 | 12px / monospace / tabular figures |
| 正文行高 | 1.45 |

## 6. 组件视觉规格

### 6.1 RTK 面板

- 白色背景、1px border、8px 圆角、卡片阴影。
- 桌面最小高度按可用视口高度填充；表格区域独立纵向滚动，表头保持可见。
- 面板头高约 58px：上下 12px padding，内容高 34px。
- 面板头左侧为标题和结果计数；右侧为搜索框与新增按钮。

### 6.2 结果计数

- 形状：胶囊，最小宽度 38px。
- 背景 `primarySoft`，文字 `primary`，12px / 600。
- 数值含义为当前过滤后的行数，不是全部点数；总点数继续显示在子页签上。

### 6.3 搜索框

- 高度 34px，圆角 6px，白底，1px border。
- 宽度桌面最大 320px；窄屏与新增按钮同处一行，并占据按钮之外的可用宽度。
- 左侧搜索图标 16px。
- Focus：border 变 primary，外圈 3px `primarySoft`。
- 文案：`搜索位置、点位或坐标` / `Search location, point, or coordinates`。

### 6.4 新增按钮

- 高度 34px，primary 实底，白字，圆角 6px。
- 图标 `Icons.add`，间距 5px。
- 桌面与 720px 以下均为内容宽度；720px 以下与搜索框同处一行。

### 6.5 位置导航

桌面：

- 固定宽 236px，右侧 1px 分隔线，纵向滚动。
- “全部位置”始终第一项，其后按位置首次出现顺序。
- 每项最小高 36px，左右 padding 10px，圆角 6px，间距 2px。
- 名称超长 ellipsis，右侧显示计数。
- Hover：`surfaceMuted`。
- Selected：`primarySoft` 背景，文字 `primaryDark` / 600。

窄屏：

- 变为横向 chips，横向滚动，高度与桌面项一致。
- 项与项间距 8px，自身有 1px border。

### 6.6 点位表

- 表头高 40px；数据行高 40px；最后一行无底边线。
- 表头白底、底部 1px border、12px / 600 / 次文字色。
- 数据行底部 1px border；Hover 背景 `row-hover`。
- 横向最小宽度 680px，不足时表格横向滚动。
- 单元格左右 padding：桌面 16px，720px 以下 10px。
- 列宽：操作 56px；其余列以确认原型的 HTML auto table 分配为基准，在最小宽度之上按比例吸收剩余宽度（无位置列时点位/纬度/经度约为 27.91%/36.045%/36.045%；有位置列时点位/位置/纬度/经度约为 18.97%/32.01%/24.51%/24.51%）。位置名 ellipsis。
- 点位编号 13px / 600；位置名次文字色；坐标 12px monospace 并固定 7 位小数。
- 操作列为 28px 方形删除 icon button，右对齐；默认次文字色，hover 为 dangerSoft + danger。
- 排序表头使用 `Icons.arrow_upward` / `Icons.arrow_downward`，尺寸 12-14px；未激活列不显示箭头。

### 6.7 空态

- 搜索无匹配：居中显示“没有匹配的 RTK 真值点”，次文字色 13px，上下 padding 24px。
- 全量无数据沿用现有“暂无数据”。

## 7. 响应式规格

断点按 Flutter logical width 判断。

| 宽度 | 行为 |
|---:|---|
| `>= 960` | 左侧位置导航 236px + 右侧表格；表格区域独立纵向滚动 |
| `720 - 959` | 位置导航变横向 chips；面板头保持一行；表格横向滚动 |
| `< 720` | 面板头标题与工具行纵向排列；搜索框和新增按钮保持同一工具行；表格单元 padding 降为 10px、最小宽 620px，仍横向滚动 |

原型中的 AppBar、主导航、主导航 Tab 只用于页面情境，Flutter 实现不重复构建；只替换当前 `TruthReferenceTab` 内 RTK 点位面板。

## 8. 实现影响

预计只修改：

- `Mobile/mobile_app/lib/features/admin/gps_quality/presentation/truth_reference_tab.dart`
- `Mobile/mobile_app/lib/l10n/app_zh.arb`
- `Mobile/mobile_app/lib/l10n/app_en.arb`
- `Mobile/mobile_app/lib/l10n/gen/*`（由 `flutter gen-l10n` 生成）
- `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart`（新增）

新增本地状态：

- `TextEditingController` 搜索词，`dispose()` 释放。
- 当前选中位置标识。
- 当前排序字段与方向。

数据仍来自 `rtkPointsProvider`；不新增 Controller 或 Repository。

## 9. i18n

中英文同步新增：

| Key | 中文 | 英文 |
|---|---|---|
| `gpsQualityRtkSearchHint` | 搜索位置、点位或坐标 | Search location, point, or coordinates |
| `gpsQualityRtkAllLocations` | 全部位置 | All locations |
| `gpsQualityRtkNoMatches` | 没有匹配的 RTK 真值点 | No matching RTK points |

可复用既有 key：

- `gpsQualityLocationName`：位置
- `gpsQualityPointLabel`：点位编号
- `gpsQualityLatitude` / `gpsQualityLongitude`
- `gpsQualityActions`：操作
- `gpsQualityPointsUnit`：位置计数单位
- `gpsQualityAddRtkPoint` / `gpsQualityDelete` / `gpsQualityNoData`

计数展示使用 `'$count ${l10n.gpsQualityPointsUnit}'` 或等价格式化方法；禁止新增硬编码中英文。

## 10. 测试与验收

### 10.1 Widget 测试

新增 `truth_reference_tab_test.dart`：

- 伪造多位置 RTK 点，断言默认选中点数最多的位置。
- 断言“全部位置”出现位置列，具体位置隐藏位置列。
- 输入点位编号后结果为 1 行且自动切换“全部位置”。
- 断言坐标显示 7 位小数。
- 断言 `1号点、2号点、10号点` 自然排序。
- 点击纬度表头后按数值升序，再点击变降序。
- 删除当前唯一位置点后自动切回“全部位置”。
- 断言关键节点 Key：`rtk-points-panel`、`rtk-point-search-field`、`rtk-location-nav`、`rtk-points-table`。

### 10.2 编译与静态验证

- `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n`
- `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze`
- `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test`
- `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter build web --release`

### 10.3 视觉验收

使用 prototype-to-flutter-fidelity 流程对比以下状态：

- 1280px：默认最大位置组。
- 1280px：全部位置。
- 1280px：搜索 `24号点` 后单行结果。
- 390px：默认最大位置组，位置 chips 与横向表格。

容差按项目既有视觉保真流程；重点检查表头、行高、位置选中态、坐标等宽字体和窄屏无重叠。

## 11. 关键提醒

- `DECIMAL(10,7)` 的展示必须保留 7 位小数，不能继续用 5 位。
- 位置默认选择不能硬编码“一期楼顶”；应按最大组动态计算，当前种子数据自然落在“一期楼顶”。
- 搜索输入控制器必须释放，避免页面内 Tab 切换后泄漏。
- 表格行数是过滤结果，子页签计数是总点数，两者语义不能混用。
- 本期是前端展示层优化，不因 UI 需要改后端契约。
