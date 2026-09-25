# NIX-246 围栏页方案 D 实施计划（1:1 高保真，无遗漏）

> Spec：`docs/superpowers/specs/2026-09-25-fence-tab-redesign-spec.md`（已确认：坐标读数保留、脉冲动画启用）
> 原型基线：`docs/prototypes/nix-246-fence-tab-redesign-prototype.html` 方案 D（两态；基线三张：列表/选中/滚动底）
> 保真标准：下文「元素清单」逐项实现并有验证归属；最终以部署后截图与原型并排比对收口。

## 0. 元素清单（原型 D 全量盘点，实现与验收一一对应）

### 屏 1 · 列表态

| # | 元素 | 关键规格 | Task |
|---|---|---|---|
| 1-01 | sec-head「围栏状态」 | 3px 绿条 + 11/700 + 右侧 `5 个围栏 · 46 头在养` | T3 |
| 1-02 | 瓷砖·围栏 | green.grad，big=5，sub=4 个启用 | T3 |
| 1-03 | 瓷砖·在养 | 白卡，big=46，sub=含 3 头无GPS | T3 |
| 1-04 | 瓷砖·告警 | red.grad + 白底红字角标 12，sub=2 个围栏涉及 | T3 |
| 1-05 | sec-head「围栏列表」 | 红条 + 右侧 hint + 新建按钮（info 底） | T3 |
| 1-06 | dcard·色脊 | 3px 围栏本色 | T3 |
| 1-07 | dcard·mini 沙盘 | 92×56 地形渐变底 + 虚线多边形 + 点阵 + 告警点脉冲 | T2/T3/T5 |
| 1-08 | dcard·info 行 1 | 名称 11/700 ellipsis + 类型标签 +（停用标签） | T3 |
| 1-09 | dcard·info 行 2 | `{n} 头 · {area} 公顷` 9px + 告警胶囊（红/绿两态） | T3 |
| 1-10 | 停用卡整体 | 60% 透明（opacity .6，无额外处理） | T6 |
| 1-11 | 对账行 | 琥珀胶囊（继承现版文案） | T3（回归） |
| 1-12 | 瓷砖 0 态 | 告警=0 → 白卡绿字「无告警」 | T6 |

### 屏 2 · 选中详情态

| # | 元素 | 关键规格 | Task |
|---|---|---|---|
| 2-01 | sec-head 选中标题 + `收起 ✕` | 复用现版收起交互 | T4 |
| 2-02 | 暗盘画布 | 108 高、#14251A、16px 网格 | T4 |
| 2-03 | 暗盘多边形 | fill 30% + stroke 2 虚线[6,4] + 顶点 #8FD694 | T4 |
| 2-04 | 暗盘点阵 | 同列表规则，告警点 2.6 脉冲 | T4/T5 |
| 2-05 | 扫描线 | 2px 渐变横条，3.8s 循环 | T4/T5 |
| 2-06 | 坐标读数 | 包围盒中心 `112.938°E 28.229°N` | T4 |
| 2-07 | 徽章 | `8 起告警 · 1 头临近边界` | T4 |
| 2-08 | light 区 head | 色点 + 名称 + 类型标签 | T4 |
| 2-09 | 2×2 元数据 | 面积/类型/在养/活跃告警（红字） | T4 |
| 2-10 | 三操作位 | 编辑边界 info / 围栏告警 soft / 删除 danger | T4 |
| 2-11 | 其余卡片 dim | 50% 透明 | T4 |

### 全局

| # | 元素 | Task |
|---|---|---|
| G-1 | 牧工视角：隐藏新建/编辑/删除，详情无操作位 | T6 |
| G-2 | 边界态：points<3 占位、无点位沙盘、0 告警 | T6 |
| G-3 | 新增 7 个 l10n 键中英同步 | T2 |
| G-4 | 保真截图基线与比对 | T0/T7 |

## 1. Task 0 · 视觉保真准备

1. 用 Playwright 以 2x 截取原型 D 屏（隐藏 `rec-mark/redo-mark/new-mark/keep-mark` 注释伪元素与页面级注释表，仅手机屏），存 `screen1.png`（列表态）、`screen2.png`（选中态）、`screen3.png`（列表滚动到底：完整停用卡 + 对账行）作为基线。
2. 从原型 CSS 提取的令牌已在 Spec §2 固化为表，本任务不重复；实现以 Spec §2 为唯一真源。
3. 生成元素清单核对表（本文 §0）打印进 PR 描述。

**验证**：基线图存在且可辨（人工）；清单覆盖原型全部节点（对照原型 DOM 逐个数）。

## 2. Task 1 · 沙盘绘制核心

新文件 `Mobile/mobile_app/lib/features/ranch/presentation/widgets/fence_sandbox_painter.dart`：

- `FenceSandboxData`：ring（归一化前 points）、dots（livestockId→Offset+status）、mode(list/detail)、progress（动画 0-1）。画布尺寸以调用方为准（列表 92×56，详情 280×108 比例）。
- 归一化：bbox + 12% margin + 短边占比 clamp ≥20%；detail 模式加顶点点。
- 绘制顺序：地形渐变由容器负责；painter 画 fill→stroke（dash）→dots→（detail）vertex→外部扫描线由 Stack 实现（不做进 painter，方便对齐 CSS）。
  - 修正：扫描线为 Stack 内 AnimatedBuilder 定位条，painter 不含。
- 单测 `test/fence_sandbox_painter_test.dart`：归一化比例、clamp 触发、点映射、空 points。

**保真验证**：写一个临时 golden（painter 直出 92×56 与 280×108 两尺寸 PNG），与原型截取的多边形区域并排比对后删除临时 golden，保留单测。

## 3. Task 2 · 数据透传 + i18n

- `RanchFenceTab` 新增参数：`totalLivestock`、`fenceUnread`、`fenceStatusMap`；`RanchPage` 三处透传（概览调用点同步）。
- l10n：Spec §7 的 7 键写入 `app_zh.arb` / `app_en.arb`，`flutter gen-l10n`。

**验证**：`flutter analyze` 0 issue；`gen-l10n` 通过；既有 fence 相关页面行为不变（手动冒烟：列表/编辑/删除入口）。

## 4. Task 3 · 列表态重建（清单 1-01 ~ 1-11）

- 抽共享组件 `ranch_summary_tile.dart`（从 ranch_page 私有 tile 闭包提炼，概览页改用之，保证两页 1:1 同源）。
- `ranch_fence_tab.dart` 重建：瓷砖三格 → dcard 列表（spine + CustomPaint terrain + info 两行）→ 对账行。
- 告警胶囊/停用标签/未读角标按 Spec；`fenceStatusMap` 缺省 SAFE。

**保真验证**：Flutter Web 390×844 截图 vs `screen1.png` 核对 1-01~1-10、vs `screen3.png` 核对 1-10/1-11，逐项打勾；重点色值取色比对（瓷砖渐变、胶囊红绿、地形底）。

## 5. Task 4 · 选中详情态（清单 2-01 ~ 2-11）

- 详情卡：dark 画布 108（网格底 + detail 模式 painter + 坐标读数 + 徽章）+ light 区（现版 head/meta/actions 重排为 Spec 结构）。
- 非选中卡 50% 透明；选中联动地图聚焦（现逻辑）。

**保真验证**：截图 vs `screen2.png` 核对 2-01~2-11；暗盘网格间距 16、扫描线 2px、顶点色 #8FD694 取色核对。

## 6. Task 5 · 动画（清单 1-07/2-04/2-05 的动态部分）

- Tab State 单 `AnimationController`（repeat，22.8s 公倍周期），派生整数相位：扫描线 6 圈、watch 脉冲 12 圈、alert 脉冲 19 圈（防 wrap 跳变）。
- 贴片外滚动/后台不暂停不做优化（sheet 切 tab 即不 paint，天然节能）。

**保真验证**：录屏 3s，确认扫描线循环、告警点闪烁节奏与原型 CSS 动画一致（人工比对）；`--profile` 下列表滚动无可感卡顿。

## 7. Task 6 · 权限与边界态（清单 1-10/1-12/G-1/G-2）

- 牧工视角：无新建/编辑/删除；详情无操作位（点击仍可看仪表盘）。
- 边界：points<3 灰占位轮廓；无点位只画形状；停用卡 opacity .6；0 告警白卡。

**保真验证**：切换牧工账号走查；构造/挑选对应数据逐态截图核对。

## 8. Task 7 · 全量验证 + 部署 + 收口

1. `flutter analyze` → `flutter build web` → `deploy.sh dev`。
2. `main.dart.js` 哈希一致 + 种子账号登录 200。
3. 浏览器走查 §0 全清单（三张基线覆盖的列表态/选中态/滚动底态 + 权限 + 边界），截图与原型基线并排存 `output/fidelity/fence-d/final-*.png`。
4. 提交 + push（分支 `nix/245-health-integration`），PR 描述附清单勾选与对比图。
5. 用户集成测试通过后合单（feature 流程第 6-7 步）。

**验证**：AGENTS 收口清单（#25）全部满足；无清单外新交互。

## 9. 风险与回退

| 风险 | 缓解 |
|---|---|
| 概览 tile 提炼引发概览回归 | 提炼为纯移动（同参数同 UI），概览截图前后比对 |
| 极扁多边形变形 | clamp 已入 Task1 单测 |
| 透传参数遗漏调用点 | analyze + 编译兜底；参数全部 required |
| 保真争议 | 以 Spec §2 令牌表 + 元素清单为仲裁依据，不以印象争论 |
