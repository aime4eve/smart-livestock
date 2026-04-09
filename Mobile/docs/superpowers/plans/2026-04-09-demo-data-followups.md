# Demo 数据增强 — 后续任务（与 GitHub Issues 同步）

**关联设计**: `specs/2026-04-09-demo-data-enhancement-design.md`（§下一步开发任务、§实现偏差）  
**前置计划（已落地）**: `plans/2026-04-09-demo-data-enhancement.md`  
**仓库**: https://github.com/aime4eve/smart-livestock

**真相来源**: Issue 的 **open/closed** 以 GitHub 为准；本文件记录范围说明、依赖与 **关闭后** 的归档信息。

---

## 如何完成 Issue 并与本文件同步

1. **认领**: 在对应 Issue 下留言或 assign 自己；按上文「执行顺序建议」下一项优先 **#3**（#2 已完成）。
2. **分支**: 从 `master` 拉分支，命名示例 `fix/2-gps-trajectory-cache`、`feat/3-chart-downsample`（含 issue 编号便于追溯）。
3. **开发**: 仅改 `Mobile/`（遵守 `AGENTS.md`）；完成后本地 `flutter analyze`、`flutter test`（及相关目录命令）。
4. **PR**: 标题写清意图；正文用 **`Closes #2`**（或 `Fixes #2`）关联 Issue，合并进默认分支后 **GitHub 会自动关闭** 该 Issue。
5. **同步本文档**（合并 PR 的同一提交或跟投小 PR）:
   - 在下方 **完成记录** 表增加一行：完成日期、PR 链接、对应 Issue 号；
   - 若验收标准或涉及路径有变化，顺改本文件中该 Issue 的小节。
6. **核对**: `gh issue view 2 --json state` 或网页确认已 closed；本地 `git pull` 后文档与仓库一致。

本地快速查看未关闭 Issue：`gh issue list --repo aime4eve/smart-livestock --state open`。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | [#2](https://github.com/aime4eve/smart-livestock/issues/2) | GPS 轨迹缓存键纳入时间区间 |
| P1 | [#3](https://github.com/aime4eve/smart-livestock/issues/3) | 孪生体温/蠕动图表降采样 |
| P1 | [#4](https://github.com/aime4eve/smart-livestock/issues/4) | GPS 轨迹行为逼真度（可选） |
| P2 | [#5](https://github.com/aime4eve/smart-livestock/issues/5) | Live 孪生时序与 Mock 对齐策略 |
| P2 | [#6](https://github.com/aime4eve/smart-livestock/issues/6) | 后端设备种子与 demo_seed 对齐 |
| P2 | [#7](https://github.com/aime4eve/smart-livestock/issues/7) | 孪生概览「当前牧区」上下文（UI） |
| P3 | [#8](https://github.com/aime4eve/smart-livestock/issues/8) | TimeSeriesGenerator 抽象（可选重构） |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-04-09 | [#2](https://github.com/aime4eve/smart-livestock/issues/2) | [#9](https://github.com/aime4eve/smart-livestock/pull/9) | 缓存键含 earTag、围栏指纹、start/end；`generator_test` 覆盖 24h vs 7d |

---

## #2 — P0：GPS 轨迹缓存键（已完成）

**目标**: `GpsTrajectoryGenerator` 缓存键包含时间范围（或等价于 `TrajectoryRange`），避免换区间仍命中旧缓存。

**主要涉及**: `Mobile/mobile_app/lib/core/data/generators/gps_trajectory_generator.dart`（`mock_map_repository` 无需改调用签名）

**验收**: Issue #2 已关闭；实现见 PR [#9](https://github.com/aime4eve/smart-livestock/pull/9)；`flutter analyze`、`flutter test` 通过。

---

## #3 — P1：图表降采样

**目标**: 孪生体温/蠕动图表绑定前对序列降采样或聚合，对齐设计文档性能假设。

**主要涉及**: 孪生场景下图表组件、 fever/digestive 相关 presentation 或数据映射层

**验收**: 见 Issue #3。

---

## #4 — P1（可选）：GPS 行为逼真度

**目标**: Mock 路径下可选增强锚点、休息区、边界接近等（固定种子可复现）。

**主要涉及**: `gps_trajectory_generator.dart`、`demo_seed.dart` 围栏元数据引用方式

**验收**: 见 Issue #4。

---

## #5 — P2：Live 孪生时序对齐

**目标**: 产品选定「扩 API」或「简化曲线 + UI 说明」之一并落地。

**主要涉及**: `Mobile/backend/data/twin_seed.js`、twin 路由、`live_*_twin*` 或 ApiCache

**验收**: 见 Issue #5。

---

## #6 — P2：后端设备种子

**目标**: Live 模式设备数据与 `demo_seed` 100 台一致（或文档明确排除）。

**主要涉及**: `Mobile/backend/data/seed.js`、设备相关路由（若已有）

**验收**: 见 Issue #6。

---

## #7 — P2：孪生概览 UI

**目标**: 企业级汇总旁增加当前 Demo 牧区（50 头）说明。

**主要涉及**: `twin_overview_page` 或等价 highfi 组件、`AppColors`/`AppSpacing`/`AppTypography`

**验收**: 见 Issue #7；交互控件带 `Key`。

---

## #8 — P3：TimeSeriesGenerator 抽象

**目标**: 可选统一生成器接口与缓存策略。

**主要涉及**: `lib/core/data/generators/` 下各文件

**验收**: 见 Issue #8；行为与现有测试一致。

---

## 执行顺序建议

1. 合并 **#2**（P0）后可并行 **#3**、**#4**（#4 可选）。  
2. **#5**、**#6** 依赖产品与后端范围，可与 **#7** 并行（不同子系统）。  
3. **#8** 在技术债窗口或 #2～#4 稳定后再做。
