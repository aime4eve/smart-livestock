# 复审：AI-Platform Phase A 实施计划（修复后）

> 评审对象：`docs/superpowers/plans/2026-06-20-ai-platform-phase-a.md`（commit `73baddb2`「应用 Plan 1 评审修复（12 条）+ self-review 核出的 2 个额外硬伤」）
> 复审日期：2026-06-20
> 基线：`docs/superpowers/reviews/2026-06-20-ai-platform-phase-a-plan-review.md`（首轮 12 条意见）

## 复审结论

**修复全部落实，可进入执行。** 首轮 12 条意见 + self-review 核出的 2 个额外硬伤都已正确处理。逐条核验结果如下。

### ✅ 已正确修复（13 项）

| # | 首轮意见 | 核验结果 |
|---|---------|---------|
| 1 (high) | `analyze_single` body 缺 `livestock_ids` 致 422 | ✅ `PredictRequest.livestock_ids` 改 `Field(default_factory=list)`（line 366）；批量端点补 `if not req.livestock_ids: return 400`（line 1888）。单头端点 body 可省字段，硬伤消除。 |
| 2 | ai-platform 目录/docker context 偏离 tile-worker | ✅ File Structure 下方补说明段（line 63）：阐明 ai-platform 是一等微服务、独立 build context 只打包 `ai-platform/` 避免把整个 `smart-livestock-server/` 当上下文，理由成立。 |
| 3 | fixture naive 索引与 db tz-aware 混用 | ✅ `make_triplet_series` 与 `make_df_with_missing` 都加 `tz="UTC"`（line 196/464）。 |
| 4 | Mahalanobis 历史矩阵含当前窗口致异常自稀释 | ✅ 引入 `history_df = slots_df.iloc[:-win]`（line 1420），Mahalanobis 历史矩阵与当前特征向量分开构造（line 1442/1449）。 |
| 5 | SQL 字符串拼 interval 脆弱 | ✅ 三条查询全改 `make_interval(hours => %s)`（line 1672-1680）。 |
| 6 | `test_cusum_flat` 容差 `abs=0.5` 过宽 | ✅ 改为 `== 0.0` 精确断言（line 787）。 |
| 7 | CUSUM `history_max` 用当前值×2 致维度退化 | ✅ 改用历史段滚动 CUSUM 最大值（line 1429-1435），Self-Review 同步更新措辞。 |
| 8 | `_predict_one` 兜底用裸 dict | ✅ 两处兜底改 `Contributions(stl=0.0,...)`（line 1866/1874），并补 import。 |
| 9 | 缺 route 纯阈值 vs 迟滞交叉对照 | ✅ 新增 `test_route_pure_threshold_vs_hysteresis_diverge`（line 1173），锁定 N_eff=180 在无 state→mahalanobis、有 iforest state→保持 的分叉，与 router 纯阈值分支实现一致。 |
| 10 | `app depends_on ai-platform` 不属 Plan 1 | ✅ 改为注释「移至 Plan 2」（line 1999），Plan 1 仅 ai-platform 自身 depends_on postgres。 |
| 12 | 测试计数约 45 不准 | ✅ 改「约 54（单文件累加口径）」(line 2029)。 |
| 额外-a | `test_l1_cold_start` 传 tail(144) 落 mahalanobis 却 assert rules | ✅ 改 `tail(20)` 使 n_eff=20<30 落 rules 档（line 1347），注释说明。 |
| 额外-b | route 对 n_eff≥200 返回 iforest 但 Phase A 未实现 | ✅ `predict_series` 里 `if algo == "iforest": algo = "mahalanobis"` 自动降级（line 1403），Self-Review 措辞同步。 |

> 评审 #11（版本兼容核验）首轮即判定「不改」，维持。

### 🟢 复审新发现的小瑕疵（不阻塞执行）

**N1. `test_cusum_flat_series_low` 的内联 Series 索引仍是 naive（未跟 #3 统一）**
line 786 `pd.Series(np.zeros(96), index=pd.date_range("2026-06-01", periods=96, freq="30min"))` 没加 `tz="UTC"`。`cusum_score` 只做数值运算不碰时区，不会报错，但与 #3「统一 tz-aware」精神不一致（同文件 `test_cusum_detects_step_change` line 790 同样遗漏）。建议顺手补 `tz="UTC"` 保持一致，非必须。

**N2. `history_df` 在短序列时退化回含当前窗口**
line 1420 `history_df = slots_df.iloc[:-win] if len(slots_df) > win else slots_df`——当 `len(slots_df) <= win`（冷启动/短序列）时 `history_df = slots_df`，又含当前窗口，退化回 #4 想避免的问题。实际影响有限：短序列 n_eff 低、走 rules 档、Mahalanobis 被跳过，不触发自稀释。但逻辑上是边缘缺口，建议注释标明「短序列走 rules 档，此处退化无害」即可。

**N3. router 迟滞测试 `test_route_pure_threshold_vs_hysteresis_diverge` 缺「已是 mahalanobis state」这一档对照**
现测了 `state=None` 和 `state={iforest}`，但没测 `state={current:"mahalanobis"}` 在 N_eff=180（迟滞带内）应保持 mahalanobis——这是迟滞最核心的场景（避免在临界带抖动）。原 `test_neff_hysteresis_avoids_jitter` 覆盖了 mahalanobis→iforest 的升降，但纯阈值 vs 迟滞对照里少了 mahalanobis state 这一档。建议补一行 `assert route_by_neff(180, state={"current":"mahalanobis"}) == "mahalanobis"` 让对照完整。

---

## 总体评价

修复质量高：① high 级硬伤（422 契约）用 schema 默认值 + 批量端点业务校验的组合方案，比单纯改测试 body 更干净；② self-review 主动核出 2 个首轮漏掉的硬伤（cold_start tail、iforest 降级），说明作者理解了算法路由逻辑而非机械套意见；③ 每条修复都在 Self-Review 段落同步更新措辞，commit message 逐条对应，可追溯。

3 个新发现的小瑕疵（N1-N3）均为一致性/完整性问题，不影响执行正确性，可在实现时顺手处理或忽略。

**建议：直接进入执行（subagent-driven 或 inline）。** 首轮评审的所有阻塞项已清除。

## 🔧 可选的小补丁清单（优先级 low）

| 优先级 | 修改项 | 位置 |
|--------|--------|------|
| low | `test_cusum_flat` / `test_cusum_detects_step_change` 索引补 `tz="UTC"` 与 #3 统一 | Task 6 (line 786/790) |
| low | `history_df` 短序列退化加注释「走 rules 档无害」 | Task 10 (line 1420) |
| low | route 交叉对照补 `state={mahalanobis}` 在 N_eff=180 保持的断言 | Task 9 (line 1173) |
