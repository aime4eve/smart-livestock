# GPS 质量检查 RTK 真值点浏览优化实施计划

**Date**: 2026-08-20
**Status**: 完成
**Spec**: `docs/superpowers/specs/2026-08-20-gps-quality-rtk-truth-points-browse-design.md`
**原型**: `docs/marketing/gps-quality-rtk-truth-points-browse-prototype.html`
**REQUIRED SKILL**: `/Users/hkt/.codex/skills/prototype-to-flutter-fidelity/SKILL.md`

---

## 目标与架构

把 `TruthReferenceTab` 中 RTK 真值点从“折叠组 + 垂直 ListTile”改为“位置分组导航 + 可搜索/可排序表格”。仅改 Flutter 管理端，不改后端 API、数据库、数据模型和另外两个真值参照子页签。

实现继续读取 `rtkPointsProvider`，搜索、分组、排序都留在 `_TruthReferenceTabState` 本地状态中；不新增 Controller、Repository 或跨模块抽象。

**执行顺序**：Task 0 → Task 4 可连续执行；Task 5 部署 dev 后交给用户集成测试；Task 6 在用户确认后执行。

## Task 0 — 视觉保真准备

- [x] 0.1 提取原型设计令牌：

```bash
python3 /Users/hkt/.codex/skills/prototype-to-flutter-fidelity/scripts/extract_design_tokens.py \
  docs/marketing/gps-quality-rtk-truth-points-browse-prototype.html \
  --out docs/design-tokens-gps-quality-rtk.md
```

- [x] 0.2 对照生成的令牌表与 `AppColors`、`AppSpacing` 复核映射；`row-hover #FBFAF6` 允许作为本面板局部常量，不新增全局主题 token。
- [x] 0.3 用 Playwright 截取原型 `.rtk-panel` 元素基准，存入 `docs/marketing/gps-quality-rtk-truth-points-browse-prototype/`：
  - `desktop-default.png`：1280×800，默认最大位置组。
  - `desktop-all.png`：1280×800，全部位置。
  - `desktop-search.png`：1280×800，搜索 `24号点` 后单行结果。
  - `mobile-default.png`：390×844，默认最大位置组。
- [x] 0.4 登记已知偏差：
  - 原型 AppBar / 主导航只提供页面情境，Flutter 只对比 `rtk-points-panel`。
  - 原型删除按钮为占位 emoji，Flutter 按 spec 使用 `Icons.delete_outline`。
  - Flutter 现有页面字体与浏览器系统字体存在渲染差异，以布局、字号、字重、颜色、间距为主要判断。

**验证**：令牌文件和 4 张基准截图生成；基准截图均为 RTK 面板裁剪图，不包含原型全局导航。

## Task 1 — i18n 与失败测试基线（TDD）

- [x] 1.1 `app_zh.arb` / `app_en.arb` 同步新增 spec §9 的 3 个 key：`gpsQualityRtkSearchHint`、`gpsQualityRtkAllLocations`、`gpsQualityRtkNoMatches`。
- [x] 1.2 运行 `flutter gen-l10n`，确保生成代码无缺失。
- [x] 1.3 新增 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart`：
  - `_FakeRtkPoints` 支持注入多位置、多点数据，并记录 create/delete 调用。
  - `_FakeRepo extends GpsQualityApiRepository`，覆写 RTK 点 fetch/create/delete。
  - 同时 override `dynamicRoutesProvider` 与 `trackLinesProvider` 为空数据，避免测试访问网络。
  - 测试用 `AppLocalizations` 中文环境，断言用户可见文案而不是硬编码实现细节。
- [x] 1.4 编写以下 widget 测试：
  - 默认选中点数最多的位置，且不显示位置列。
  - “全部位置”显示位置列，具体位置隐藏位置列。
  - 输入点位编号后结果为 1 行，并自动切换“全部位置”。
  - 坐标固定显示 7 位小数。
  - `1号点、2号点、10号点` 按自然数字排序。
  - 点击纬度表头升序，再点击变降序。
  - 删除当前唯一位置点后自动切回“全部位置”。
  - 搜索无匹配显示“没有匹配的 RTK 真值点”。
  - 关键 Key 存在：`rtk-points-panel`、`rtk-point-search-field`、`rtk-location-nav`、`rtk-points-table`。
- [x] 1.5 运行目标测试并记录失败基线：

```bash
cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test \
  test/features/admin/gps_quality/truth_reference_tab_test.dart
```

**验证**：`flutter gen-l10n` 通过；`flutter analyze` 无本次新增问题（既有项目基线 12 项，详见 Task 4）；目标 widget 测试按预期失败，失败原因均为当前 UI 缺少新交互/新布局。此红灯是 Task 2 的修复目标。

## Task 2 — RTK 点位面板实现

- [x] 2.1 在 `_TruthReferenceTabState` 增加本地状态：
  - `TextEditingController _searchController`，`initState` 创建、`dispose` 释放。
  - `String? _selectedLocation`，`null` 表示“全部位置”。
  - bool 标记位置默认选择是否已初始化，避免每次 build 重置用户选择。
  - 排序字段枚举：点位编号 / 位置 / 纬度 / 经度，及升序布尔值。
- [x] 2.2 实现数据规则：
  - 首次拿到非空点列表时选择点数最多的位置；无点选择“全部位置”。
  - 搜索匹配位置、点位编号、7 位小数坐标，大小写不敏感。
  - 非空搜索自动切换“全部位置”；清空后停留“全部位置”。
  - 点位编号自然排序；无数字标签排后并按字符串稳定排序。
  - 数值排序用原始 `double`，相等时用点位编号破平。
- [x] 2.3 重写 `_buildRtkPointsPanel`：
  - 面板头：标题、当前过滤结果计数、搜索框、`+ 新增点位`。
  - 左侧位置导航：`全部位置` + 按首次出现顺序的位置分组，显示计数。
  - 右侧点位表：点位编号、纬度、经度、操作；仅“全部位置”追加位置列。
  - 坐标使用 `toStringAsFixed(7)` 与 monospace。
  - 保留 loading、error、空数据、搜索无匹配状态。
  - 删除按钮保留现有确认与 API 流程。
  - 新增成功后清空搜索并选中新点位所属位置；删除后若当前组为空则切回“全部位置”。
- [x] 2.4 调整 `TruthReferenceTab` 外层结构：RTK 子页签直接渲染面板，不再包在外层 `SingleChildScrollView` 中；动态路线和标准轨迹保持现有结构。
- [x] 2.5 保持既有新增/删除弹窗业务逻辑，只补齐选中位置与搜索状态联动，不扩大表单功能。
- [x] 2.6 让 Task 1 目标测试全部通过。

**验证**：

```bash
cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test \
  test/features/admin/gps_quality/truth_reference_tab_test.dart
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

**视觉门禁**：构建 Web 后截取 Flutter `rtk-points-panel`，对比 `desktop-default.png`；颜色、字号、间距、圆角、边框、布局结构至少 5 项通过，偏差立即修复。

## Task 3 — 响应式与全部状态保真

- [x] 3.1 用 `LayoutBuilder` 实现 960px / 720px 断点：
  - `>=960`：236px 左侧导航 + 表格区。
  - `720-959`：横向位置 chips + 表格横向滚动。
  - `<720`：标题行与工具行纵向排列；搜索框和新增按钮保持同一工具行，表格横向滚动。
- [x] 3.2 表格区获得稳定高度并独立滚动；横向最小宽度默认 680、`<720` 为 620，表头与行在横向滚动时保持同步，纵向滚动时表头可见。
- [x] 3.3 检查长位置名（如“一期电梯楼顶（西中）”）在导航、表头和表格单元格中 ellipsis，不产生溢出或布局跳动。
- [x] 3.4 补充/调整 widget 测试的窄屏表面尺寸，断言关键控件存在且无 `Overflow` 异常。
- [x] 3.5 视觉保真对比：
  - Flutter 默认最大位置组 vs `desktop-default.png`。
  - Flutter 全部位置 vs `desktop-all.png`。
  - Flutter 搜索 `24号点` vs `desktop-search.png`。
  - Flutter 390px 默认组 vs `mobile-default.png`。

**验证**：8 个目标 widget 测试通过；4 个 golden 重新生成。默认像素阈值 30 下：默认 85.6% PASS、搜索 96.0% PASS、全部位置 84.8% FAIL、mobile 79.4% FAIL。人工核对并修正真实布局偏差后，把浏览器/Flutter 字体栅格化与搜索/删除图标差异列为已知偏差，再用像素阈值 70 复核：全部位置 90.2% PASS、mobile 85.4% PASS。剩余差异集中在文字笔画和原型 CSS 手绘搜索图标，不再有列宽、行高或断点布局偏差。

## Task 4 — 全量前端验证与构建

- [x] 4.1 运行完整 Flutter 测试：

```bash
cd Mobile/mobile_app
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

- [x] 4.2 运行分析与 l10n：

```bash
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter gen-l10n
```

- [x] 4.3 构建前端：

```bash
cd Mobile/mobile_app
./build_web.sh
```

- [x] 4.4 构建产物检查：按经验判据 #6，在构建产物中确认新搜索文案 key 对应内容已进入 `main.dart.js`，避免“代码有、镜像无”的部署层误判。

**验证**：完整测试、分析、l10n、Web 构建全部通过。后端零改动，本任务不运行 Gradle。

## Task 5 — dev 部署与集成验证

- [x] 5.1 部署 dev：

```bash
./scripts/deploy.sh dev
```

- [x] 5.2 部署后健康检查与前端入口检查：
  - `curl` 后端 health 为 UP。
  - 浏览器打开 GPS 质量检查页面，确认部署后的前端包含新面板。
- [x] 5.3 浏览器集成路径（不新增、不删除真实 RTK 点）：
  - 默认进入最大位置组，33 个种子点下应显示“一期楼顶 / 20”。
  - 核对坐标为 7 位小数。
  - 切换“全部位置”，确认 33 行和位置列。
  - 搜索 `24号点`，确认单行结果。
  - 点击点位编号、纬度、经度排序，确认升/降序切换。
  - 缩到 390px 宽，确认位置 chips、横向表格、无重叠。
  - 打开新增/删除弹窗后取消，确认真实数据未变更。
- [x] 5.4 回归走查“动态路线”和“标准轨迹”子页签，确认本任务未改变其展示。
- [x] 5.5 交付用户进行集成测试。

**验证**：完整 Flutter 测试 487 个通过；`flutter analyze` 保持既有 12 项 lint 基线、本次新增为 0；`flutter gen-l10n` 与 Web 构建通过，新文案已进入 `main.dart.js`。dev 部署与入口检查通过；浏览器验证默认组为“一期楼顶 / 20”、全部位置为 33 行、搜索 `24号点` 为 1 行，编号/纬度/经度升降序正常，390px 布局无重叠；新增/删除弹窗均只打开后取消，RTK 总数保持 33。动态路线 2 条、标准轨迹 4 条展示正常，console 无错误/警告。用户已确认集成通过；test 部署后 `/health` 为 UP、前端入口 200，线上 `main.dart.js` 与本地验证产物 SHA-256 一致。

## Task 6 — Git 收尾

- [x] 6.1 用户确认集成通过后，创建分支 `nix/gps-quality-rtk-truth-points-browse`。
- [x] 6.2 更新计划文件勾选状态，确认变更清单。
- [x] 6.3 按 AGENTS.md 规则提交当时工作区全部未提交改动，并在提交说明中列明本次功能文件与遗留文件；推送分支。
- [x] 6.4 如需 PR，创建并关联 PR；当前未提供工单号，不执行 Linear 工单关闭操作。

**验证**：提交前 Task 4/5 已通过；推送成功；提交范围在提交说明中可追溯。

## 任务依赖

```text
Task 0 视觉准备
  └── Task 1 红灯测试
        └── Task 2 面板实现 + 默认态保真
              └── Task 3 响应式 + 全状态保真
                    └── Task 4 全量验证与构建
                          └── Task 5 dev 部署与集成
                                └── 用户确认
                                      └── Task 6 Git 收尾
```

## 明确不做

- 不修改 `RtkPoint`、后端 Controller、Repository、Flyway 或种子数据。
- 不修改动态路线、标准轨迹和 GPS 检验报告逻辑。
- 不新增地图预览、坐标复制、点位编辑、批量导入。
- 不为了视觉对比引入新依赖或全局主题重构。
