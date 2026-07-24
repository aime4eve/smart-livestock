# NIX-52 告警中心 + 围栏管理 UI/UX 重设计 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **REQUIRED SKILL:** `prototype-to-flutter-fidelity` — 每个编码 Task 完成后必须通过视觉保真验证（Phase 3）。

**Goal:** 重写告警中心页面，统一围栏管理入口，增强牲畜快捷面板。实现必须与高保真原型像素级一致。

**Architecture:** 前端纯 Flutter 改动，后端无需改动。复用现有 showTrajectorySheet()、FarmScopedAsyncNotifier、RolePermission。

**Spec:** `docs/superpowers/specs/2026-07-23-nix-52-alert-ui-ux-redesign.md`
**原型:** `docs/marketing/nix-52-alert-ui-redesign-prototype.html`

---

## Task 0: 视觉保真准备（prototype-to-flutter-fidelity Phase 1+2）

**目标**：提取设计令牌，截取原型基准截图

- [x] 0.1 运行 `extract_design_tokens.py` 提取原型 CSS 令牌到 `docs/design-tokens.md`
- [x] 0.2 对照令牌表检查现有 `app_colors.dart` / `app_spacing.dart`，补充缺失值
- [x] 0.3 用 Playwright 截取原型 9 个屏幕的基准截图，存入 `/private/tmp/nix52-baselines/`
- [x] 0.4 记录每个基准截图对应的 Flutter Task 编号

**验证**：令牌表完整，基准截图 9 张齐全

---

## Task 1: 数据模型 + i18n 基础

- [x] 1.1 AlertItem 新增 severity / read / occurredAt / resolvedAt / fenceName / resolvedType
- [x] 1.2 alerts_api_repository.dart 解析新字段；loadAlerts 增加 severity 参数
- [x] 1.3 alerts_controller.dart 新增筛选状态（filterStatus / filterSeverity / filterType）
- [x] 1.4 app_zh.arb / app_en.arb 新增 48 个 key（双语同步）
- [x] 1.5 `flutter gen-l10n` + `flutter analyze` 通过

**验证**：编译通过，无 analyze 错误（本 Task 无 UI，跳过视觉对比）

---

## Task 2: 告警列表页面重写

- [x] 2.1 新增 alert_summary_strip.dart（摘要条）
- [x] 2.2 新增 alert_filter_bar.dart（分段控件 + 类型 chips）
- [x] 2.3 新增 alert_card.dart（富信息卡片）
- [x] 2.4 新增 alert_empty_state.dart
- [x] 2.5 重写 alerts_page.dart（CustomScrollView + Slivers + 日期分组）
- [x] 2.6 移除所有硬编码 P0 假数据
- [x] 2.7 **视觉保真验证**：flutter build web → Playwright 截图 → 对比基准 Screen 2（告警列表）

---

## Task 3: 告警详情面板

- [x] 3.1 新增 alert_detail_sheet.dart（大图标 + 标题 + 元数据网格 + 时间线 + 操作按钮）
- [x] 3.2 操作按钮按角色和状态动态显示（定位 / 轨迹 / 已读 / 忽略）
- [x] 3.3 「查看轨迹」调用 showTrajectorySheet(context, livestockId)
- [x] 3.4 **视觉保真验证**：对比基准 Screen 3（告警详情）

---

## Task 4: 批量管理模式

- [x] 4.1 新增 alert_batch_bar.dart
- [x] 4.2 AlertsPage 新增 batchMode + selectedIds
- [x] 4.3 AlertCard 在 batchMode 下显示 checkbox
- [x] 4.4 长按触发批量模式
- [x] 4.5 **视觉保真验证**：对比基准 Screen 4（批量管理）

---

## Task 5: 围栏管理统一入口

- [x] 5.1 新增 ranch_fence_tab.dart（围栏列表 + 新增 + 编辑/删除）
- [x] 5.2 围栏项点击高亮地图 + 展开详情卡片
- [x] 5.3 修复编辑跳转 /fence/form?fenceId=xxx
- [x] 5.4 修改 ranch_page.dart 底部 sheet 分段 Tab（概览/围栏/告警）
- [x] 5.5 移除左侧滑出面板和 3 个散落 FAB
- [x] 5.6 **视觉保真验证**：对比基准 Screen 1（概览 Tab）+ Screen 8（围栏 Tab）+ Screen 9（围栏详情）

---

## Task 6: 牲畜快捷面板增强

- [x] 6.1 重写 livestock_detail_sheet.dart
- [x] 6.2 健康圆点 + 编号 + 品种 + 活跃告警横幅 + 关键指标 2x2 + 快捷操作
- [x] 6.3 **视觉保真验证**：对比基准 Screen 7（牲畜快捷面板）

---

## Task 7: 编译验证 + 部署

- [x] 7.1 flutter analyze 零错误
- [x] 7.2 flutter build web 通过
- [x] 7.3 ./build_web.sh 构建
- [x] 7.4 部署 dev 环境
- [ ] 7.5 用户集成测试（28 条验收标准）

---

## 视觉保真验证流程（每个编码 Task 必须执行）

1. `flutter build web` 构建当前代码
2. Playwright 打开 Flutter web，导航到对应页面
3. 截取 Flutter 渲染截图
4. 打开 `/private/tmp/nix52-baselines/` 中的原型基准截图
5. 并排对比，检查 10 个维度：背景色 / 文字层级 / 间距 / 颜色令牌 / 圆角 / 阴影 / 图标 / 布局结构 / 标签样式 / 响应式
6. 至少 5 个维度通过才标记 Task 完成
7. 发现差异立即修正，不推迟

---

## 验收标准摘要（28 条）

| 范围 | 验收项 | 数量 |
|------|--------|------|
| 告警列表重设计 | #1-#14 | 14 |
| 牲畜 + 轨迹联动 | #15-#17 | 3 |
| 围栏管理统一 | #18-#25 | 8 |
| 牲畜快捷面板 | #26-#28 | 3 |
