# NIX-60 功能门控管理 UI/UX 重设计 实施计划

> **REQUIRED SKILL:** `prototype-to-flutter-fidelity` — 每个编码 Task 完成后必须通过视觉保真验证（Phase 3）。

**Goal:** 重写功能门控管理页面，修复 tier 大小写 bug，加中文友好名+分组，卡片风格对齐订阅管理。实现必须与高保真原型（方案 B）像素级一致。

**Architecture:** 前端纯 Flutter 改动，后端无需改动。复用现有 FeatureGateApiRepository / FeatureGateController / HighfiCard。

**Spec:** `docs/superpowers/specs/2026-07-26-nix-60-feature-gate-redesign.md`
**原型:** `docs/marketing/nix-60-feature-gate-redesign-prototype.html`（方案 B：按 tier 分 Tab）

---

## Task 0: 视觉保真准备（prototype-to-flutter-fidelity Phase 1+2）

**目标**：提取设计令牌，截取原型基准截图

- [ ] 0.1 运行 `python3 ~/.codex/skills/prototype-to-flutter-fidelity/scripts/extract_design_tokens.py docs/marketing/nix-60-feature-gate-redesign-prototype.html --out docs/design-tokens-nix60.md`
- [ ] 0.2 对照令牌表检查现有 `app_colors.dart` / `app_spacing.dart`，确认所有令牌已存在（本页令牌与订阅管理同源，预期无需新增）
- [ ] 0.3 用 Playwright 截取原型方案 B 的基准截图，存入 `/private/tmp/nix60-baselines/`：
  - `planB-basic.png`（基础版 tab，含 lock 锁定项）
  - `planB-standard.png`（标准版 tab）
  - `planB-premium.png`（高级版 tab）
  - `planB-enterprise.png`（企业版 tab，全 none/全开）
- [ ] 0.4 记录每个基准截图对应的 Flutter Task 编号

**验证**：令牌表完整，基准截图 4 张齐全

---

## Task 1: i18n key 新增（中英文同步）

- [ ] 1.1 app_zh.arb 新增 29 个 key（tier 中文名 4 + 分类 2 + 单位 4 + gate 状态 5 + feature 中文名 12 + 编辑/取消 2）
- [ ] 1.2 app_en.arb 同步新增对应英文 key
- [ ] 1.3 运行 `flutter gen-l10n` 确认无缺失 key
- [ ] 1.4 `flutter analyze` 通过

**验证**：gen-l10n 无报错，analyze 无新增 warning（本 Task 无 UI，跳过视觉对比）

---

## Task 2: Feature 中文映射 + 分组逻辑

- [ ] 2.1 在 feature_gate_models.dart 新增 `FeatureMeta` 类：`featureKey → {中文名, 分类, 单位}` 静态映射表
- [ ] 2.2 新增 `FeatureGateEntry` 扩展方法：`displayName`（中文友好名）、`category`（平台功能/健康模块）、`unit`（头/个/人/天）
- [ ] 2.3 `flutter analyze` 通过

**验证**：单元逻辑正确（本 Task 无 UI，跳过视觉对比）

---

## Task 3: 页面重写 — Tier TabBar + 功能列表卡片

- [ ] 3.1 重写 `feature_gate_page.dart`：TabBar 用中文名（基础版/标准版/高级版/企业版），修复 tier 大小写（`g.tier == tabKey`，统一小写比较）
- [ ] 3.2 新增 `feature_gate_card.dart`：HighfiCard 风格的功能卡片
  - 左侧：中文名（12px/600）+ raw key（9px/monospace）+ gate 状态 chip
  - 中间：配额值（LIMIT→primary / FILTER→info）+ 单位（仅 LIMIT/FILTER 显示）
  - 右侧：Switch（即时切换 isEnabled）+ 编辑按钮（✎）
- [ ] 3.3 新增 gate 状态 chip 组件（none/limit/lock/lockOpen/filter 五态）
- [ ] 3.4 功能按 category 分组（平台功能 7 项 + 健康模块 5 项），section header 带计数
- [ ] 3.5 tab 切换内容区，无 loading（数据全量加载）
- [ ] 3.6 **视觉保真验证**：flutter build web → Playwright 截图 → 对比基准 `planB-basic.png`（至少 5 维度通过）

---

## Task 4: 行内编辑模式

- [ ] 4.1 新增 `feature_gate_edit_row.dart`：点击 ✎ 展开的编辑区
  - LIMIT 类型：input「限额」+ Switch「启用」
  - FILTER 类型：input「保留天数」+ Switch「启用」
  - LOCK 类型：仅 Switch「启用」
  - NONE 类型：无编辑区
  - 保存/取消按钮，虚线分隔
- [ ] 4.2 编辑中卡片高亮（`--shadow-elev`）
- [ ] 4.3 保存调用 `controller.updateGate(id, ...)`，成功 SnackBar，失败回滚
- [ ] 4.4 **视觉保真验证**：对比基准 `planB-basic.png` 编辑态（原型方案 A 第一张卡片的编辑区样式作为参考）

---

## Task 5: 编译 + 部署 + 端到端验证

- [ ] 5.1 `flutter analyze` 全项目无新增 warning
- [ ] 5.2 `flutter gen-l10n` 无缺失 key
- [ ] 5.3 `./build_web.sh` 编译通过
- [ ] 5.4 部署 dev 环境（`./scripts/deploy.sh dev`）
- [ ] 5.5 浏览器验证：platform_admin 登录 → 功能门控管理 → 4 个 tab 都有 12 条数据 → 编辑一个配额保存
- [ ] 5.6 **全 tab 视觉保真验证**：对比基准 4 张截图（basic/standard/premium/enterprise）

---

## Task 6: 提交 + PR + 工单

- [ ] 6.1 git commit + push 分支 `codex/nix-60-feature-gate-redesign`
- [ ] 6.2 创建 PR
- [ ] 6.3 更新 NIX-60 工单状态
