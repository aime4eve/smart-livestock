# Demo 数据增强 — 后续任务（与 GitHub Issues 同步）

**关联设计**: `specs/2026-04-09-demo-data-enhancement-design.md`（§下一步开发任务、§实现偏差）  
**前置计划（已落地）**: `plans/2026-04-09-demo-data-enhancement.md`  
**仓库**: https://github.com/aime4eve/smart-livestock

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

---

## #2 — P0：GPS 轨迹缓存键

**目标**: `GpsTrajectoryGenerator` 缓存键包含时间范围（或等价于 `TrajectoryRange`），避免换区间仍命中旧缓存。

**主要涉及**: `Mobile/mobile_app/lib/core/data/generators/gps_trajectory_generator.dart`、`mock_map_repository.dart`（调用方式若需调整）

**验收**: 见 Issue #2；`flutter analyze`、`flutter test` 通过。

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
