# 从设备轨迹生成围栏草图 · 令牌映射与组件-原型对照清单（Task 0 产物）

> 依据：plan Task 0（`docs/superpowers/plans/2026-11-11-fence-from-device-track-plan.md`，2026-11-12 复核后基线）
> 视觉真源：原型 `docs/prototypes/2026-11-11-fence-from-device-track-prototype.html`（`:root` 第 8–31 行 + 6 屏）
> 规格锚点：spec §2 设计令牌表 / §3 组件视觉规格（`docs/superpowers/specs/2026-11-11-fence-from-device-track-spec.md`）
> Flutter 落点核实对象：`Mobile/mobile_app/lib/core/theme/`（app_colors.dart / app_spacing.dart / app_typography.dart / app_theme.dart）
> 用途：Task 4/5 人工视觉保真核对基线（本会话 `prototype-to-flutter-fidelity` skill 不可用）；本文件为独立产物，不回写 spec/plan/原型。
> 版本注记：2026-11-12 复核重写——补齐「原型 vs spec §2 逐条比对」列、组件级数值清单、逐组件验收要点列、覆盖清单与待裁决节；替换 11-11 初版。
> 比例约定：沿 NIX-52 先例（`docs/prototypes/design-tokens.md`），原型 px 值 1:1 映射 Flutter 逻辑像素；280px 手机框与 1120px 桌面框为展示脚手架，不参与保真核对。

---

## 第一部分：令牌映射表

### 1.1 新增令牌逐条映射（原型 `:root` 9 条声明 ↔ spec §2.1 7 个令牌，逐条比对）

> 原型 `:root`「本功能新增令牌」块共 9 条声明（第 22–30 行）；spec §2.1 记 7 个令牌（`--track-dot-opacity` 并入 track.dot 行、`--envelope-stroke-dash` 即 envelope.dash 行、`--step-indicator-inactive` 归入 §2.2 继承令牌注记）。**计数口径差异不构成值冲突**，逐条比对如下。

| # | 原型令牌 | 原型实测值（原型行号） | spec §2 结论 | 比对 | Flutter 落点（grep 核实证据） |
|---|---|---|---|---|---|
| 1 | `--track-dot` | `#4A7F9D`（:22） | `#4A7F9D`，映射 `AppColors.info` | ✅ 与 spec §2 一致 | `AppColors.info = Color(0xFF4A7F9D)`（app_colors.dart:32） |
| 2 | `--track-dot-opacity` | `.35`（:23） | 并入 track.dot 行 `@35%` | ✅ 与 spec §2 一致 | 数值常量：`AppColors.info.withValues(alpha: .35)` |
| 3 | `--envelope-fill` | `rgba(76,154,95,.14)`（:24） | `rgba(76,154,95,.14)`，映射 `AppColors.success` | ✅ 与 spec §2 一致（rgba(76,154,95)=#4C9A5F 逐位同值） | `AppColors.success = Color(0xFF4C9A5F)`（app_colors.dart:23）+ 数值常量 `.withValues(alpha: .14)` |
| 4 | `--envelope-stroke` | `#2F6B3B`（:25） | `#2F6B3B`，映射 `AppColors.primary` | ✅ 与 spec §2 一致 | `AppColors.primary = Color(0xFF2F6B3B)`（app_colors.dart:6） |
| 5 | `--envelope-stroke-dash` | CSS 令牌默认 `none`（:26）；实际虚线值在 SVG 内联：屏 4 `stroke-dasharray="5,3"`（:313）、屏 6 `"8,4"`（:422），确认载入后实线 | `[5,3]` 移动 / `[8,4]` Web | ✅ 与 spec §2 一致（spec 数值与 SVG 实测吻合；注意 CSS 令牌本身不携带 [5,3]/[8,4]，值内联在 SVG） | 数值常量：CustomPaint dash 参数 `[5,3]` / `[8,4]`（实现已落：track_draft_preview.dart:180 `isDesktop ? [8,4] : [5,3]`） |
| 6 | `--chip-selected-bg` | `#2F6B3B`（:27） | `#2F6B3B`，映射 `AppColors.primary` | ✅ 与 spec §2 一致 | `AppColors.primary`（app_colors.dart:6）；语义先例：app_theme.dart:79 `chipTheme.selectedColor: AppColors.primary` |
| 7 | `--stat-strip-bg` | `#263126`（:28） | `#263126`，映射 `AppColors.textPrimary`（同值复用，不新建色） | ✅ 与 spec §2 一致 | `AppColors.textPrimary = Color(0xFF263126)`（app_colors.dart:20），逐位同值 |
| 8 | `--step-indicator-inactive` | `#D7D2C6`（:29） | spec §2.1 未列，§2.2 继承注记 `= --border` | ✅ 与 spec §2.2 一致（分类：继承而非新增） | `AppColors.border = Color(0xFFD7D2C6)`（app_colors.dart:14），逐位同值 |
| 9 | `--wizard-panel-width` | `360px`（:30） | `360px`，`LayoutBuilder` ≥900px 启用宽屏 | ✅ 与 spec §2 一致 | 数值常量 `360.0`；断点 900 为另一数值常量（spec §5.3；实现已落：track_draft_desktop_panel.dart:26 `desktopBreakpoint = 900`） |

**逐条比对小结**：9 条声明全部与 spec §2 结论一致，**无不一致项**；spec「全部映射既有 AppColors」经逐条核实成立——6 条颜色令牌（#1/3/4/6/7/8）全部命中既有常量，其余 3 条为纯数值常量（透明度、dash 参数、面板宽；透明度实为 .35/.14 两处）。spec §2.2「映射检查结论：不新增颜色常量」**验证成立**（唯一越界值为组件级 `#F2C879`，见 ⚠ 待裁决 #1）。

### 1.2 继承令牌（NIX-246 基线）→ Flutter 常量清单（全部 grep 核实）

| 原型令牌（:root 行号） | 原型值 | Flutter 常量（出处） | 核实 |
|---|---|---|---|
| `--primary`（:10） | `#2F6B3B` | `AppColors.primary`（app_colors.dart:6） | ✅ |
| `--primary-dark`（:10） | `#244F2D` | `AppColors.primaryDark`（:7） | ✅ |
| `--primary-soft`（:10） | `#E3F0E4` | `AppColors.primarySoft`（:8） | ✅ |
| `--accent`（:10） | `#8BA95A` | `AppColors.accent`（:9） | ✅ |
| `--surface`（:11） | `#F8F6F0` | `AppColors.surface`（:11） | ✅ |
| `--surface-alt`（:11） | `#FFFFFF` | `AppColors.surfaceAlt`（:12） | ✅ |
| `--border`（:11） | `#D7D2C6` | `AppColors.border`（:14） | ✅ |
| `--text-primary`（:12） | `#263126` | `AppColors.textPrimary`（:20） | ✅ |
| `--text-secondary`（:12） | `#617061` | `AppColors.textSecondary`（:21） | ✅ |
| `--success`（:13） | `#4C9A5F` | `AppColors.success`（:23） | ✅ |
| `--warning`（:13） | `#D28A2D` | `AppColors.warning`（:26） | ✅ |
| `--danger`（:13） | `#C2564B` | `AppColors.danger`（:29） | ✅ |
| `--info`（:13） | `#4A7F9D` | `AppColors.info`（:32） | ✅ |
| `--xs/--sm/--md/--lg/--xl`（:14） | `4/8/12/16/24px` | `AppSpacing.xs/sm/md/lg/xl`（app_spacing.dart:4–8，值 4/8/12/16/24） | ✅ 逐位一致（AppSpacing.xxl=32 为 app 侧超集，原型未用，无冲突） |
| `--radius-sm/md/lg`（:15） | `8/12/16px` | **无 `AppRadius` 令牌类**；theme 内联值：card 16（app_theme.dart:43）、input/button 14（:54/:58/:62/:73）、chip 12（:83） | ⚠️ 见 §1.4 偏差 1 |
| `--shadow-card/elev/sheet`（:16–18） | rgba(38,49,38) 三档 | **无阴影令牌类**；cardTheme 仅 `elevation: 0.8 + shadowColor black@.08`（app_theme.dart:41–42）近似 `--shadow-card` | ⚠️ 见 §1.4 偏差 2（`--shadow-sheet` 6 屏未使用，无需映射） |
| `--hero-g1/g2/g3`（:19） | `#1C3F25/#2F6B3B/#3E7F4C` | 6 屏均未引用（声明未用）；g2==`AppColors.primary` | ✅ 无需处理 |
| 地图底色（非令牌，`.mapbox/.map-area` 内联） | `#DCE8D5` | `AppColors.mapGreen`（app_colors.dart:54，NIX-256 引入） | ✅ 既有常量命中 |

**AppTypography 核对**：`app_typography.dart` 仅有 `static TextTheme build()`（:7），**无任何静态数值常量**——原型字号/字重均为组件级值（见 §1.3），不经 AppTypography 落地，零冲突成立。

### 1.3 组件级数值清单（spec §2 未列、原型 CSS 实测，Task 4/5 编码直接引用）

**字号/字重（px / FontWeight）**

| 组件·部位 | 原型 class | 值 |
|---|---|---|
| 入口卡标题 | `.entry-card .tt` | 11.5 / 800 |
| 入口卡副标 | `.entry-card .dd` | 9 / 400 `textSecondary`，行高 1.4，`margin-top:2px` |
| 入口卡 NEW 标签 | `.entry-card .new-tag` | 8 / 800，白字 primary 底，padding 1×5，radius 4，`margin-left:5px` |
| 入口卡 chevron | `.entry-card .chev` | 13 `textSecondary` |
| 设备行名称 | `.device-row .nm` | 10.5 / 700 |
| 设备行副标 | `.device-row .sub` | 8.5 `textSecondary`，`margin-top:1px` |
| 设备行点数数字 | `.device-row .pts b` | 11 / 700 `primaryDark` |
| 设备行点数标签 | `.device-row .pts span` | 8 `textSecondary` |
| 步骤圆点数字 | `.step-dot .c` | 9 / 800 白字 |
| 步骤标签 | `.step-dot` | 9.5 / 700（未选 `textSecondary`；当前 `primaryDark`） |
| chips | `.chip` | 10 / 700（未选 `textSecondary`，选中白字） |
| 日期框标签/值 | `.date-box .lbl/.val` | 8.5 `textSecondary` / 11 / 700，`margin-top:2px` |
| 屏 3 分节标签（内联） | 「快捷选择」「自定义范围」 | 10 / 700 |
| 统计条数值 | `.stat-cell .v` | 13 / 800 白，行高 1.2；`.v.warn`=`#F2C879` |
| 统计条标签 | `.stat-cell .k` | 8，白 @.65，`margin-top:1px` |
| 已选摘要 pill | `.selected-pill` | 9.5 `textSecondary`，数字 `primaryDark` 加粗，`padding-top:6px` |
| 按钮 | `.btn` | 11 / 800，padding 10×0，radius 8（=radius-sm） |
| 空态标题/原因 | `.e-tt/.e-dd` | 12.5 / 800 / 9.5 `textSecondary` 行高 1.6，`margin-top:5px` |
| 建议列表 | `.empty-sugg` | 9 `textSecondary` 行高 1.7，「建议：」加粗 `textPrimary` |
| 来源卡标题/行 | `.mc-tt/.mc-row` | 9 / 700 `textSecondary`（letter-spacing .3px）/ 9.5，行 v 加粗 600；k 列宽 56px |
| Web 面板小节头 | `.sec-head .t` | 11.5 / 800；`.sub` 9.5 `textSecondary`（数字 `primaryDark`） |
| Web 顶栏面包屑 | `.desktop-topbar .crumb` | 12 / 700（当前节点 `primaryDark`） |
| Web 按钮 | `.web-btn` | 12 / 800，padding 8×16，radius 8，`shadow-elev` |
| Web 图例（内联覆盖） | `.legend` | 10（gap 14）；移动端 `.legend` 基准 9 / gap 12 |

**尺寸/间距/圆角**

| 组件 | 值（原型 CSS 实测） |
|---|---|
| 入口卡 | padding 11×12，gap 10，radius 12（radius-md），边 1.5px；图标 34×34 radius 10 `primarySoft` 底 `primaryDark` 图标 17px |
| 设备行 | padding 9×10，gap 8，radius 12，边 1.5px，`margin-bottom:7px`；checkbox 18×18 radius 6 边 1.5px，选中填 `chip-selected-bg` 白 ✓ 10px |
| 步骤指示器 | 圆点 18×18（50% 圆），gap 6，连线高 2 radius 1，容器 padding `10px 14px 2px`；未激活点/线=`#D7D2C6`(border)，当前点=primary，完成点/线=success |
| chips | padding 8×0，radius 999（胶囊），边 1.5px，`chip-row` gap 6 `margin-bottom:10px` |
| 日期框 | padding 8×10，radius 8（radius-sm），边 1.5px；`date-pair` gap 8 |
| 提示条 | padding 7×9，radius 8，边 1px，字号 9，`margin-top:10px`（Web 屏 6 内联覆盖字号 9.5） |
| 统计条 | radius 12，padding 8×4，`shadow-elev`；cell `padding:0 4px`，右分隔 1px 白@.12（末格无） |
| 空态 | `.empty-box` padding 26×18；图标 52×52 radius 16 warning@.1 底 warning 字 24px，`margin-bottom:10px`；建议卡 padding 8×10 radius 8 `margin-top:12px` |
| 来源卡 | padding 9×11，radius 12，边 1px，`shadow-card` |
| 操作条 | padding `10px 14px 14px`，gap 8，顶边 1px `border`，`surfaceAlt` 底；屏 2 取消钮定宽 76px、屏 4/5 返回钮定宽 96px |
| Web 面板 | 宽 360（`--wizard-panel-width`），`wp-scroll` padding 14×16；`wp-sec margin-bottom:16px`；小节头：竖条 3×11 radius 2 primary，gap 5，`margin-bottom:8px`；顶栏高 44 |
| Web 悬浮层 | `.stat-float` left/bottom/right 14，gap 10；`.web-action` top 12 right 14 gap 8；图例卡 `surfaceAlt` 底 radius 12 padding 8×12 `shadow-elev` |
| Web 面板操作条（内联覆盖） | padding `12px 16px 14px`，按钮字号 12 |

**透明度与混色（数值常量）**

| 用途 | 原型出处 | 值 → Flutter |
|---|---|---|
| 轨迹点叠加 | 屏 4 :304 / 屏 6 :415 `<g fill="#4A7F9D" opacity=".35">`；点 r2（移动）/r3（Web） | `AppColors.info.withValues(alpha:.35)` |
| 包络填充 | `rgba(76,154,95,.14)` | `AppColors.success.withValues(alpha:.14)` |
| 包络描边宽 | 屏 4 2px / 屏 6 2.5px；虚线 [5,3]/[8,4]；顶点 r3（移动）/r5（Web） | primary + 组件常量 |
| 漫游剔除点 | `<g fill="#D28A2D" opacity=".8">`；r2.5（移动）/r4（Web） | `AppColors.warning.withValues(alpha:.8)` |
| 图例轨迹点圆 | `.legend i` 内联 `opacity:.5`（**与地图 .35 不同**，8×8 圆） | `info.withValues(alpha:.5)` |
| 图例色块 | `.sw-poly` 14×9，边 1.5px primary，底 `envelope-fill`，radius 2 | — |
| 统计条琥珀亮值 | `.stat-cell .v.warn` | `#F2C879` → ⚠ 待裁决 #1（实现已落 `track_draft_preview.dart:39 _trimmedAmber`） |
| 统计条 cell 分隔 | `border-right:1px solid rgba(255,255,255,.12)` | `Colors.white.withValues(alpha:.12)` |
| 统计条标签色 | `.stat-cell .k` `rgba(255,255,255,.65)` | `Colors.white.withValues(alpha:.65)` |
| 提示条 info 态 | 底 `rgba(74,127,157,.08)` / 边 `rgba(74,127,157,.25)` / 字 `--info` | `info.withValues(alpha:.08/.25)` + `AppColors.info` |
| 提示条 warn 态 | 底 `rgba(210,138,45,.08)` / 边 `rgba(210,138,45,.3)` / 字 `--warning` | `warning.withValues(alpha:.08/.3)` + `AppColors.warning` |
| 空态图标底 | `.e-ico` `rgba(210,138,45,.1)` | `warning.withValues(alpha:.1)` |
| stale 设备行 | 内联 `opacity:.65`（整行）；`.stale` 文字 warning / 700 | `Opacity(.65)` + `AppColors.warning` |
| 地图署名 | `.map-attrib` 7.5px `rgba(38,49,38,.5)` | `textPrimary.withValues(alpha:.5)` |
| 返回键底（脚手架） | `.app-bar .back` `rgba(97,112,97,.08)` | `textSecondary.withValues(alpha:.08)`（既有壳已有，仅备查） |

### 1.4 与 spec/原型的结构性偏差记录（非颜色冲突，实现时留意）

1. **圆角无令牌类**：Flutter 侧无 `AppRadius`；`app_theme.dart` 的 input/button 圆角为 **14**（:54/:58/:62/:73，≠ 原型 radius-md 12），chip 12（:83）与 card 16（:43）命中。本功能组件（entry-card/device-row/meta-card/stat-strip=12；date-box/btn/limit-hint/empty-sugg=8；空态图标=16）应按原型值 `BorderRadius.circular(8/12/16)` 组件内书写，**不得复用 inputDecorationTheme 的 14**。
2. **阴影无令牌类**：`--shadow-card`（`0 1px 3px rgba(38,49,38,.06),0 1px 2px rgba(38,49,38,.04)`）与 `--shadow-elev`（`0 4px 16px rgba(38,49,38,.12)`）需组件内 `BoxShadow` 按原型值实现；cardTheme 的 `elevation:0.8`（app_theme.dart:41）只是近似。entry-card/device-row/meta-card 用 shadow-card，stat-strip/web-btn/图例卡用 shadow-elev。
3. **date-box 超限态原型无 CSS 规格**：屏 3 仅文字描述「开始/结束红框」（:274），无对应 class；spec §3.3 已定「起止框 `danger` 边」——按 spec 用 `AppColors.danger` 实现，非遗漏。
4. **文案勘误不改原型**：统计条第二格原型显示「剔除漫游 5%」（:325/:432），已被 plan 附录 A #12 用户裁决勘误为「剔除漫游」（无百分数）；「面积(亩)」按 plan 附录 A #14 locale 分支（中文亩 1 位小数 / 英文 ha 2 位小数，<0.1 亩 / <0.01 ha 降级 `fenceTrackDraftAreaSqmFallback`）。**保真核对以 plan 附录 A 文案为准，不照抄原型含 "5%" 的标签**。

---

## ⚠ 待主智能体裁决（实质性矛盾，不自行裁定）

> **以下 3 项已由主智能体裁决（2026-11-12，随 Task 0 评审落账；用户可在最终报告中推翻）：**

1. **统计条琥珀亮值 `#F2C879` 与「不新增颜色常量」结论的边界**：原型 `.stat-cell .v.warn{color:#F2C879}`（:102）是暗底（#263126）上的可读性亮琥珀，**`AppColors` 无对应常量**（warning=#D28A2D 过深，warningSoft=#FFF2DE 过浅，均不可替代——暗底上对比度不同）。spec §2 对 7 个令牌的「不新增颜色常量」结论本身成立（#F2C879 不在令牌表内），但组件实现必然要持有该色：现状实现已用局部常量 `static const _trimmedAmber = Color(0xFFF2C879)`（track_draft_preview.dart:39，未提交）。**裁决：保留组件局部常量**——spec §2 的「不新增颜色常量」约束的是设计令牌表范围（不扩 AppColors 色表）；组件级局部常量仅一处使用、出处明确（原型 .v.warn），不污染全局色表；将来若有第二个暗底组件复用再提升为正式常量。保真核对按 #F2C879 核。
2. **步骤指示器：原型语言 vs 既有 `ImportWizardShell` 实现不一致**：spec §5.1/设计裁决表要求「复用 ImportWizardShell 外壳与步骤指示器语言」，但两者视觉不同——原型（`.step-dot`）：圆点 **18×18 实底**、未激活填 `--step-indicator-inactive`(#D7D2C6)、完成态 `success` 绿底 ✓、当前步标签 `primaryDark`；既有 shell（import_wizard_shell.dart:74–106）：圆点 **26×26 描边式**、未激活透明底+`textSecondary` 边、无独立完成态（`i<=step` 全部 primary 实底）、连线 done 用 primary（原型 done 用 success）。**裁决：沿用 ImportWizardShell 原样，步骤指示器保真豁免**——shell 是 NIX-213 既有向导（GPX/实地采集）共用骨架，spec §5.1 明文复用；为单功能改造共享壳会波及既有向导（回归面扩大，违反「不做无关重构」）。保真核对记录须注明此豁免。
3. **入口卡 primary 描边语义**：原型 `.entry-card` 基类边框即 1.5px `primary`（:60），第 5 入口卡未覆盖该值（:194）——即**常驻高亮**；既有「实地采集」卡内联覆盖 `border-color:var(--border)`（:188）回到灰边。spec §3.1 表述为「**选中边框** 1.5px primary（与原型一致）」。两种解读对 Task 5 行为不同：常驻高亮（新卡永远绿边）vs 选中态（默认灰边、选中变绿）。**裁决：按原型=常驻 1.5px primary 描边**——spec 头部「原型已确认」为最高视觉依据，NEW 强调意图明确（原型作者对既有采集卡显式覆盖灰边，反证新卡绿边是有意为之）；spec §3.1「选中边框」属行文不精确（原型单帧无法表达选中交互）。

---

## 第二部分：组件-原型对照清单（人工保真核对基线，Task 4/5 逐屏截图比对用）

> 核对方法：Flutter 实现（Web 截图 / 移动端截图）与原型对应屏并排，逐行核对「关键视觉要素」列；「验收要点」为实现后人工必查项。屏号对应原型 `screen-label` 编号 1–6。

### 1. 统计条 stat-strip（屏 4 / 屏 5 / 屏 6 地图底部悬浮）

- **关键视觉要素**（CSS 实测）：暗底 `--stat-strip-bg`=#263126（=AppColors.textPrimary）、radius 12、padding 8×4、`shadow-elev`；cell 白字右分隔 1px 白@.12（末格无）；数值 13/800 白、行高 1.2；剔除类数值 `.v.warn`=#F2C879；标签 8px 白@.65 `margin-top:1px`。屏 4 四格：有效点 / 剔除漫游 / 包络顶点 / 面积；屏 6 加第 5 格「凹包·生成方式」；屏 5 为清洗明细四格（原始点白字 + 精度超限/漫游剔除/剩余有效三格琥珀）。
- **验收要点**：① 底色用 `AppColors.textPrimary`（非纯黑/非灰）；② 琥珀值格核对为 `#F2C879` 亮琥珀（裁决 #1 落地方式）；③ cell 分隔线白@.12 且末格无；④ 移动端 4 格 / Web 5 格（第 5 格生成方式）；⑤ 标签文案按 plan 附录 A（第二格「剔除漫游」**无 "5%"**，面积格 locale 分支亩/ha）；⑥ Key `track-draft-stat-strip` 可命中。

### 2. 步骤指示器（屏 2/3/4/5 顶部）

- **关键视觉要素**：三步「1 选设备 — 2 选时间 — 3 预览」；圆点 18×18、白字 9/800；未激活点/连线=#D7D2C6、当前步点=primary+标签 9.5/700 `primaryDark`、完成步点/连线=success 绿 + ✓；连线高 2 radius 1，gap 6，容器 padding `10px 14px 2px`。**注意与既有 ImportWizardShell（26px 描边点）不一致 → 待裁决 #2**。
- **验收要点**：① 三态区分（未选/当前/完成）与原型色一致（若裁决沿用 shell，则按 shell 现状核对并在核对记录注明豁免）；② 完成态为 success 绿（原型）而非 primary（shell）；③ 屏 3/4/5 起始步为「✓ 完成态」呈现。

### 3. 设备行 device-row（屏 2 / 屏 6 面板①）

- **关键视觉要素**：白底（surfaceAlt）radius 12、边 1.5px `border`、padding 9×10、gap 8、`margin-bottom:7px`、`shadow-card`；选中态=底 `primarySoft` + 边 `primary`；checkbox 18×18 radius 6 边 1.5px，选中填 `chip-selected-bg`(=primary) 白 ✓ 10px；名称 10.5/700；副标 8.5 `textSecondary`（耳标 · 相对定位时间）；右侧点数块右对齐：数字 11/700 `primaryDark` + 标签 8px `textSecondary`（屏 2「30 天点数」/ 屏 6「30 天点」）；stale 行整行 opacity .65 + 副标内 `⚠ {n} 天前定位` warning 加粗（仍可选）。
- **验收要点**：① 选中/未选中两态的底色与边色切换（primarySoft/primary vs surfaceAlt/border）；② checkbox 选中态绿底白勾、尺寸 18 radius 6；③ stale 行降透明且警示文字为 warning 色加粗、行仍可点选；④ 点数列千分位（7,986）右对齐两行式；⑤ Key `track-draft-device-row-{deviceId}`。

### 4. 日期框 date-box（屏 3 / 屏 6 面板②，含快捷档 chips）

- **关键视觉要素**：两框并排 `date-pair` gap 8；框=白底、边 1.5px `border`、radius 8、padding 8×10；标签 8.5 `textSecondary`（开始/结束）、值 11/700（`10-29 00:00 📅`）。快捷档 chips：三等分胶囊 radius 999、边 1.5px、10/700，选中实底 `chip-selected-bg` 白字；`chip-row` gap 6。信息提示条=info@.08 底 / info@.25 边 / info 字 9px radius 8；超限替换为 warn 态（warning@.08 底 / @.3 边）+ 起止框 danger 边 + 主按钮禁用（`.btn.disabled` 底 #D7D2C6 白字）。
- **验收要点**：① chips 选中实底绿/未选白底灰边；② 超限三联反馈同时出现（红框+琥珀条+按钮禁用）；③ 提示条常态/超限为两条不同文案（`fenceTrackDraftRangeHint` / `fenceTrackDraftRangeTooLong`）；④ Key `track-draft-range-chip-{7|14|30}`、`track-draft-range-start/end`、`track-draft-generate`。

### 5. 空态/失败态（屏 5）

- **关键视觉要素**：`.empty-box` padding 26×18 居中；图标 52×52 radius 16、warning@.1 底、warning 色 24px 🐾；标题 12.5/800 `textPrimary`；原因 9.5 `textSecondary` 行高 1.6（关键数字加粗）；建议卡=白底 1px `border` 边 radius 8 padding 8×10、9px `textSecondary` 行高 1.7 左对齐、「建议：」加粗 `textPrimary`、三条编号建议；下方清洗明细统计条（见组件 1）；底部唯一全宽主按钮「‹ 返回调整条件」。
- **验收要点**：① 三类失败（无数据/点不足/退化）共用此版式，仅文案不同（`fenceTrackDraftFailNoData/TooFew/Degenerate` + `FailSuggests`）；② 建议列表三条齐全可操作；③ 唯一回边按钮全宽 primary、无第二出口；④ 保留诊断统计条（失败可诊断）。

### 6. 入口卡 entry-card（屏 1）

- **关键视觉要素**：白底 radius 12、边 **1.5px `primary`**（原型常驻；语义待裁决 #3）、padding 11×12、gap 10、`shadow-card`；图标 34×34 radius 10 `primarySoft` 底 `primaryDark` 🐄 17px；标题 11.5/800 + NEW 胶囊（primary 底白字 8/800 radius 4 `margin-left:5px`）；副标 9 `textSecondary` 行高 1.4 两行内（`fenceTrackDraftEntryDesc`）；右端 chevron › 13px `textSecondary`；位于「实地采集」卡之下。离线态：置灰 + `fenceTrackDraftOffline` 提示（spec §8，原型未画）。
- **验收要点**：① 卡片描边颜色核对裁决 #3 结论（常驻 primary vs 选中态）；② 图标块 34×34/r10/primarySoft；③ NEW 标签尺寸与位置；④ 与既有 4 入口卡风格一致（同 radius/阴影/间距语言）；⑤ `canManage=false` 隐藏、离线置灰；⑥ Key `fence-form-track-draft-entry`；⑦ 双端（含 Web）可见。

### 7. 图例行（屏 4 地图下方 / 屏 6 地图右下图例卡）

- **关键视觉要素**：三项——草图色块 `.sw-poly`（14×9、1.5px primary 边、`envelope-fill` 底、radius 2）/ 轨迹点圆 8×8（`info`@**.5**，注意与地图 .35 不同）/ 剔除点圆 8×8 warning 实色；文字 9px `textSecondary`（屏 6 内联覆盖 10px、gap 14）；gap 12；屏 6 图例置于白卡内（radius 12 padding 8×12 `shadow-elev`）。
- **验收要点**：① 三个图例元素形状/颜色/透明度逐项核对（易错点：图例点 .5 ≠ 地图点 .35）；② 文案 `fenceTrackDraftLegendEnvelope/TrackDots/Trimmed`，第三项带 ×{n} 计数；③ 移动端在地图下独立一行、Web 在右下白色胶囊卡内。

### 8. Web 桌面面板布局（屏 6，≥900px）

- **关键视觉要素**：左面板定宽 **360px**、`surfaceAlt` 底、右边线 1px `border`，内部滚动 padding 14×16；小节头=3×11 primary 竖条 + 11.5/800 标题 + 右侧 9.5 计数（数字 `primaryDark`）；① 设备清单（复用组件 3 行样式，标签为「30 天点」）② chips+日期框+提示条（字号 9.5 覆盖）③ 生成来源卡；面板底部操作条 padding `12px 16px 14px` 全宽「⟳ 生成预览」按钮（12/800）。右侧地图区占满余宽（底 mapGreen），右上悬浮 `web-action` 两钮（soft=白底 `primaryDark` 字 1px border 边 / primary=绿底白字，12/800 radius 8 `shadow-elev`），左下悬浮统计条+右下图例卡（`stat-float` 14px 内边距 gap 10）。顶栏 44px 高白底 `border` 下边线、面包屑 12/700。断点：`LayoutBuilder` ≥900px 本布局，<900px 三步向导。
- **验收要点**：① 面板宽恰 360、地图随窗口伸缩；② 参数改动不自动重算，地图区出现「条件已变更，请重新生成」stale 角标（`fenceTrackDraftStaleNotice`），手动「生成预览」才刷新；③ 悬浮统计条 5 格 + 图例卡同屏共存；④ <900px 正确降级为移动向导且共享同一 controller 状态；⑤ 面包屑路径与牧场/用户占位正确。

### 补充组件（Task 4/5 亦需核对）

| 组件 | 屏号 | 关键视觉要素 | 验收要点 |
|---|---|---|---|
| 预览地图三层叠加 | 屏 4 / 屏 6 | 顺序：轨迹点（info@.35，r2/r3）→ 剔除点（warning@.8，r2.5/r4）→ 包络（success@.14 填充 + primary 描边 2/2.5px 虚线 [5,3]/[8,4] + 顶点 primary 实点 r3/r5）；地图底 mapGreen、1px border 边、radius 12、右下署名 7.5px textPrimary@.5 | 三层叠放次序（包络在最上）；虚线参数随断点切换；载入表单后草图变**实线**；Key `track-draft-preview-map` |
| 生成来源卡 meta-card | 屏 3 / 屏 4 / 屏 6 面板 | 白底 radius 12、1px border、padding 9×11、`shadow-card`；标题 9/700 `textSecondary` letter-spacing .3px；行 9.5、k 列 56px `textSecondary`、v 600 | 标题文案「生成来源（将随围栏保存）」（`fenceTrackDraftSourceCardTitle`）；行内容设备+时间段；详情页两挂载点（fence_page `_FenceCard` / ranch_fence_tab `_FenceDetailCard`）同款且 `generationMetadata==null` 时隐藏 |
| 底部操作条与按钮 | 屏 2/3/4/5 | `surfaceAlt` 底、顶边 1px border、padding `10px 14px 14px`、gap 8；btn radius 8、11/800、padding 10×0；primary 绿底白字 / soft `primarySoft` 底 `primaryDark` 字 / disabled #D7D2C6 底白字；屏 2 pill「已选 2 台 · 预估合并 16,088 点」9.5/数字 primaryDark | 按钮三态色核对；取消/上一步定宽 76、调整条件定宽 96；Key `track-draft-device-next`、`track-draft-confirm` |

---

## 验证记录（实际执行的命令与输出摘要）

### 验证 1：映射表覆盖原型全部新增视觉元素（覆盖清单）

对照原型 `<style>` 全部 40+ 选择器与 6 屏 markup 逐个核对，覆盖情况：

- **`:root` 9 条新增声明**（:22–30）→ §1.1 全覆盖（9/9）。
- **继承令牌**（:10–19 全局块 + :29）→ §1.2 全覆盖（13 色 + 间距 5 + 圆角 3 + 阴影 3 + hero 3 + 地图底色）。
- **组件 class**（全部落附录/§1.3）：`.steps/.step-dot(.on/.done)/.step-line(.done)` → 组件 2；`.entry-card` 及 5 个子元素 → 组件 6；`.device-row(.on)` 及 `.chk/.ico/.nm/.sub/.stale/.pts` → 组件 3；`.chip-row/.chip(.on)` → 组件 4；`.date-pair/.date-box(.lbl/.val)` → 组件 4；`.limit-hint(.warn)` → 组件 4；`.stat-strip/.stat-cell(.v.warn/.k)` → 组件 1；`.action-bar/.btn(.primary/.soft/.disabled)/.selected-pill` → 补充表；`.empty-box(.e-ico/.e-tt/.e-dd)/.empty-sugg` → 组件 5；`.meta-card(.mc-tt/.mc-row)` → 补充表；`.mapbox/.map-attrib` → 补充表；`.legend(.sw-poly/i)` → 组件 7；`.desktop-topbar(.crumb)/.wizard-panel(.wp-scroll)/.wp-sec(.sec-head .dot/.t/.sub)/.map-area(.stat-float)/.web-action/.web-btn(.primary/.soft)` → 组件 8。
- **SVG 内联视觉值**（dasharray 5,3 / 8,4；r2/r3、r2.5/r4、r3/r5；stroke-width 2/2.5；opacity .35/.8）→ §1.3 透明度表 + 补充表。
- **脚手架（明确排除，不参与保真）**：`.phone/.phone-status/.app-bar/.back`（手机框）、`.desktop/.desktop-body` 外框（桌面框）、`.screen-label/.screen-sublabel/.flow-grid/.page-head/.decision-table`（版式外框）、`.map-overlay-top`（原型定义未使用）、`--hero-g1/g2/g3`（声明未引用）、屏 1 的既有页面元素（快速开始 chips/围栏信息输入框，属既有新增围栏页）。
- **结论**：原型新增视觉元素全覆盖，无遗漏项。

### 验证 2：与 `AppColors`/`AppSpacing`/`AppTypography` 零冲突（grep 实录）

实际执行（工作目录 `Mobile/mobile_app`）：

```
grep -n "static const Color" lib/core/theme/app_colors.dart
grep -n "static const double" lib/core/theme/app_spacing.dart
grep -n "static" lib/core/theme/app_typography.dart
grep -n "BorderRadius.circular\|elevation\|shadowColor\|selectedColor" lib/core/theme/app_theme.dart
grep -rn "F2C879" lib --include="*.dart"
```

关键输出：`primary`(:6)=0xFF2F6B3B、`primaryDark`(:7)=0xFF244F2D、`primarySoft`(:8)=0xFFE3F0E4、`accent`(:9)=0xFF8BA95A、`surface`(:11)=0xFFF8F6F0、`surfaceAlt`(:12)=0xFFFFFFFF、`border`(:14)=0xFFD7D2C6、`textPrimary`(:20)=0xFF263126、`textSecondary`(:21)=0xFF617061、`success`(:23)=0xFF4C9A5F、`warning`(:26)=0xFFD28A2D、`danger`(:29)=0xFFC2564B、`info`(:32)=0xFF4A7F9D、`mapGreen`(:54)=0xFFDCE8D5；`AppSpacing.xs..xl`(:4–8)=4/8/12/16/24；`app_typography.dart` 无静态数值常量（仅 `build()` :7）。映射表引用的全部 Flutter 落点均存在且与原型值逐位一致。

**结论：「不新增颜色常量」成立**——6 条新增颜色令牌全部复用既有 `AppColors`。唯一边界项：组件级琥珀亮值 `#F2C879`（非令牌表成员，`AppColors` 无对应；grep 显示全 lib 仅 track_draft_preview.dart:39 一处，为已落实现局部常量）→ 已列入 ⚠ 待裁决 #1，不在本文件内裁定。

### 验证 3：原型 CSS 值与 spec §2 结论逐条比对

见 §1.1 表「比对」列（9/9 逐条标注）：**8 条与 spec §2.1/§2.2 完全一致**（含计数口径差异说明）；**无不一致项**；1 条结构注记（`--envelope-stroke-dash` CSS 令牌默认 `none`，[5,3]/[8,4] 内联于 SVG，spec 结论与 SVG 实测吻合）。spec §2.2「全部新令牌可映射到现有 AppColors，不新增颜色常量；新增仅虚线参数、透明度、面板宽三处数值常量」——逐条验证**属实**（透明度实为 .35/.14 两处，plan 表述「透明度 0.35/0.14」与此一致）。

---

## 现状备注（供主智能体评审 Task 4/5 时参考）

工作区（未提交）已存在 Task 3/4/5 实现文件：`track_draft_preview.dart`（:39 `_trimmedAmber`、:180 dash 分段）、`track_draft_desktop_panel.dart`（:26 `desktopBreakpoint=900`）、`track_draft_area.dart`（:6 `sqmPerMu=2000/3`）、`roaming_trim.dart`、`track_draft_params.dart`、`track_draft_controller.dart`、`track_draft_wizard_page.dart`、`track_draft_repository.dart`、`fence_generation_source_card.dart`、`track_draft_device_picker.dart`、`track_draft_range_picker.dart` 等。本文件按 Task 0 职责独立产出（基线核对，不改动任何代码）；上述实现与本清单的逐项一致性由 Task 4/5 保真核对闭环。
