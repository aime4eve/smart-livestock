# 评审：AI-Platform Phase A 实施计划

> 评审对象：`docs/superpowers/plans/2026-06-20-ai-platform-phase-a.md`（14 Task TDD 计划，2050 行）
> 评审日期：2026-06-20
> 评审方式：plan 内容与 design doc 修订版、代码库惯例（docker-compose、tile-worker）、pandas/psycopg API 静态核对

## 总体评价

这是一份**完成度很高、可直接执行**的 TDD 计划。14 个 Task 从骨架 → schemas → 特征 → 检测器 → 融合 → 路由 → capability → engine → db → FastAPI → docker，依赖顺序正确，每个 Task 都是"写失败测试 → 实现 → 跑通 → commit"闭环。职责分层（`l1/` 纯算法无 IO、`capability/` 门面、`db.py` 隔离 PG）清晰且利于单测。

值得肯定的是，plan 明确承接了 design doc 上一轮评审的全部补强（Self-Review 表逐条标注 design 章节 → Task 映射），并清晰划定了 **Plan 1/Plan 2 边界**（只读 DB 账号、Java 接入、Flutter 双轨都留给后续 plan），没有越界。

但发现 **1 个会导致测试与实现直接对不上的硬伤**（API 契约）、**1 处与项目惯例不一致**、以及若干实现/隐患问题。按严重程度分级。

---

## 🔴 重大问题（执行前必须改）

### 1. `analyze_single` 端点 body 缺 `livestock_ids`，Pydantic 校验会 422，测试却期望 200

**事实**：
- Task 2 `PredictRequest` 定义 `livestock_ids: list[int]`（必填，无默认值，schemas.py line ~362）。
- Task 13 `analyze_single` 的测试 body 是 `{"tenant_id":1,"farm_id":2,"window_hours":24}`——**不含 `livestock_ids`**（test_main.py line ~1764/1792）。
- Task 13 实现里 `analyze_single` 先 `req.livestock_ids = [livestock_id]` 覆盖（line ~1870）。

**问题**：FastAPI 在请求进入函数体**之前**就用 `PredictRequest` 解析 body 并校验。body 缺 `livestock_ids` → Pydantic `ValidationError` → FastAPI 自动返回 **422**，根本到不了 `req.livestock_ids = [livestock_id]` 那一行。测试 `test_analyze_single` / `test_analyze_single_handles_missing_data` 期望 `status_code == 200`，**会直接失败**。

**修复（二选一）**：
- 方案 A（推荐）：`PredictRequest` 里 `livestock_ids: list[int] = Field(default_factory=list)`，单头端点 body 不传该字段合法；实现 `analyze_single` 覆盖逻辑保留。批量端点仍要求非空（在 `analyze_batch` 里加业务校验）。
- 方案 B：单头端点测试 body 补 `"livestock_ids": []`，实现里用路径参数覆盖。但这让 body 与 path 语义重复，不如方案 A 干净。

> 这是最该在执行前修的一条，否则 Task 13 的 4 个测试里有 2 个必然红。

### 2. ai-platform 目录与 docker context 与项目惯例不一致

**事实**：项目已有 Python 服务 `tile-worker`，其惯例是：
- 代码放 `infrastructure/tile-worker/`；
- docker-compose `build.context: .`（仓库根），`dockerfile: infrastructure/tile-worker/Dockerfile`。

plan 把 ai-platform 放在 `smart-livestock-server/ai-platform/`（仓库根下独立顶层目录），`build.context: ./ai-platform`。

**问题**：两种 Python 服务放法不统一，增加维护认知成本；`ai-platform/` 作为顶层目录也脱离了 `infrastructure/` 的基础设施归集约定。

**建议**：评估是否移到 `infrastructure/ai-platform/`，与 tile-worker 对齐。若坚持独立目录（理由：ai-platform 是一等微服务而非纯 worker，体量更大），应在 README 或 plan 顶部**显式说明为何偏离 tile-worker 惯例**，避免后续维护者困惑。这条不阻塞执行，但属于架构一致性决策，值得现在定。

---

## 🟡 中等问题（建议改）

### 3. 合成 fixture（naive 索引）与 db 真实路径（tz-aware 索引）混用隐患

**事实**：
- `conftest.make_triplet_series` 用 `pd.date_range("2026-06-01", ..., freq="30min")` 生成 **naive（无时区）** 索引。
- `db.fetch_window` 用 `pd.to_datetime(..., utc=True)` 生成 **UTC tz-aware** 索引。
- `resample_to_slots` 对两种索引都工作，但一旦某处做**索引对齐/拼接**（如未来把 cohort baseline 多牛拼接、或 main 里把多条 series 合并），naive 与 tz-aware 混合会抛 `TypeError: Cannot join tz-naive and tz-aware`。

**现状**：当前 plan 的测试路径里 naive（test_health_l1 直传 normal_series）和 tz-aware（test_main mock 的 normal_series 也是 naive，db 测试 mock 了 fetchall）是**分开走**的，暂不触发。但这是埋着的雷。

**建议**：统一一种。推荐 `conftest` 也用 tz-aware（`pd.date_range(..., tz="UTC")`），与 db 路径一致；或在 `resample_to_slots` 入口对 naive 索引 `.tz_localize("UTC")` 归一化。至少在 plan 加一条"索引时区约定"注释。

### 4. Task 10 `health_l1.predict_series` 里 Mahalanobis 历史矩阵构造用同一份 `slots_df` 自滑窗，本质是"用待检测窗口自身估分布"

**事实**：Task 10 实现里构造 Mahalanobis 历史特征矩阵的方式是（line ~1430）：
```python
for start in range(0, max(1, len(slots_df) - win), 12):
    window = slots_df.iloc[start:start + win]
    v, _ = build_feature_vector(window, baselines)
    feats.append(v)
```
即**用同一头牛自己的 14 天 slots_df 滑窗**造历史样本，再算当前点相对该分布的 Mahalanobis 距离。

**问题**：design §4.3 的 Mahalanobis 语义是"per-individual 历史正常分布"。但这里如果最近 24h 已注入异常，**异常点也参与了历史矩阵的协方差估计**，会"自我稀释"异常距离——异常越剧烈，协方差被撑得越大，Mahalanobis 反而越小。这与"检测当前窗口偏离历史正常"的初衷相悖。

**建议**：明确历史矩阵应**排除最近检测窗口**（用 `slots_df.iloc[:-detect_n]` 的历史段造特征，只对最后 `detect_n` 槽算当前特征向量）。plan Task 10 应把"历史段 vs 当前段"拆开。当前写法会让合成注入测试的区分度被削弱（Task 14 `test_synthetic_anomaly_scores_higher_than_normal` 可能勉强过但信号被压缩）。

### 5. Task 12 SQL 用 `(%s || ' hours')::interval` 字符串拼 interval，脆弱

**事实**：`WHERE recorded_at >= NOW() - (%s || ' hours')::interval`，参数传 `(livestock_id, str(window_hours))`。

**问题**：字符串拼接 interval 依赖隐式转换，且 `window_hours` 若被传成非数字（配置错误）会在 DB 端报语法错而非 Python 端早失败。PostgreSQL 更地道的写法是 `make_interval(hours => %s)` 或直接 `NOW() - %s * interval '1 hour'`。

**建议**：改 `recorded_at >= NOW() - make_interval(hours => %s)`，参数只传 `window_hours`（int），更安全且意图清晰。`fetch_window` 签名已是 `window_hours: int`，天然适配。

### 6. Task 6 CUSUM `cusum_score` 对扁平序列返回 0 的测试用 `abs=0.5` 容差过宽

**事实**：`test_cusum_flat_series_low` 断言 `cusum_score(flat) == approx(0.0, abs=0.5)`，但全零序列 `std==0`，实现直接 `return 0.0`，精确为 0。

**问题**：`abs=0.5` 容差下，即便实现有 bug（如忘了除零保护返回了 0.4）也测不出来。这是 TDD"测试必须有区分度"的典型反例。

**建议**：收紧为 `== approx(0.0, abs=1e-9)`，或断言精确 `0.0`。这条是测试质量问题，不影响功能。

### 7. Task 8 `normalize_cusum` 的 `history_max` 在 health_l1 里被简化为 `cusum_raw * 2.0`

**事实**：Task 10 health_l1 里 `history_max = max(cusum_raw * 2.0, 1.0)`（line ~1418），即用**当前值自身的 2 倍**当"历史最大"。

**问题**：这使 `normalize_cusum` 恒等于 `clip(0.5, 0, 1) = 0.5`（当前值非零时），CUSUM 维度几乎失去变化能力——任何非零 CUSUM 都被归一化到 0.5，融合后 CUSUM 贡献基本固定。Self-Review 虽然承认这是"简化估计"，但**这个简化让 CUSUM 维度退化为常数**，实质削弱了 L1b 突变检测的价值。

**建议**：至少用该牛**历史窗口**（非当前检测窗）的 CUSUM 滚动最大值做 `history_max`，与 Task 4 同一思路（历史段 vs 当前段）。否则 Phase A 的 CUSUM 层基本是摆设。

---

## 🟢 小问题

### 8. `PredictResponse.contributions` 在 main.py `_predict_one` 兜底分支里传了 `dict` 而非 `Contributions` 对象
main.py line ~1840 的 no_data/no_capability 兜底写 `contributions={"stl":0.0,...}`（裸 dict），而 schema 字段类型是 `Contributions`。Pydantic v2 会自动 coerce，所以不报错，但与正常分支（传 `Contributions(...)` 对象）风格不一致。统一用 `Contributions(stl=0.0,...)`。

### 9. Task 9 `route_by_neff` 迟滞测试覆盖了升/降档，但缺"无 state 纯阈值"与"有 state"交叉验证
`test_neff_route_small_uses_rules/medium/large` 三个测的是无 state 纯阈值路径，`test_neff_hysteresis_avoids_jitter` 测有 state。但没有测试"同一 N_eff 在有无 state 下给出不同结果"的场景，迟滞与纯阈值的分叉点（如 N_eff=180 在纯阈值下应升 iforest，在 mahalanobis state 下保持）没被显式锁定。建议补一个对照断言。

### 10. Task 14 docker-compose 让 `app depends_on ai-platform`，但 Plan 1 不含 Java 调用
Task 14 Step 3 让 `app:` 依赖 `ai-platform: service_started`。但按 plan 边界，Plan 1 只建 Python 服务，Java 端调用（`AnomalyScoreClient`）在 Plan 2。Plan 1 阶段 app 不调 ai-platform，加这个依赖只会拖慢 app 启动。建议：`app depends_on ai-platform` 这条改动**移到 Plan 2**，Plan 1 只加 ai-platform 服务本身 + depends_on postgres。

### 11. 缺 `requirements.txt` 版本锁定与 Python 3.11 的兼容核验
`numpy==2.2.1` / `pandas==2.2.3` 等都较新，但 plan 未说明是否在目标部署环境（docker `python:3.11-slim`）实测过 `pip install`。`psycopg[binary]==3.2.3` 在 slim 镜像通常 OK，但建议 Task 1 Step 9 的"安装依赖跑冒烟测试"作为首个验证关卡，失败则先修版本。这是流程提醒，非缺陷。

### 12. Self-Review 称"约 45 个测试"，但未逐 Task 核对计数
各 Task 给的 `Expected: N passed` 累加（2+5+3+4+5+5+3+6+6+5+2+2+4+2 = 54）与"约 45"不符。建议核对，或去掉具体数字避免执行时困惑。

---

## ✅ 做得好的地方

- **承接 design 评审闭环**：Self-Review 表明确把 design §3/§4.2/§4.3/§4.4/§5/§6/§8/§9/§10 逐节映射到 Task，且标注了边界（baseline_temp 不回写、V38 归 Plan 2、数据访问方案 A）。这是高质量 plan 的标志。
- **TDD 节奏严格**：每个 Task 都是红→绿→commit，且测试断言有具体数值（如 `vec[0] > 5.0`、`anomaly_score > normal`），不是空壳。
- **职责分层利于测**：`l1/` 不 import db/main，可纯算法单测；`predict_series`（传 DataFrame）与 `predict`（HTTP 取数）分离，测试友好。
- **实现纪律落实**：conftest 注释、Task 14 Step 2 备注"不得在检测代码针对合成数据加分支"，与 roadmap 决策 #2 一致。
- **明确 Plan 1/2/3 边界**：只读账号、Java 接入、Flutter 双轨都不揽，避免单 plan 过载。

---

## 🔧 建议修改清单（优先级排序）

| 优先级 | 修改项 | 位置 |
|--------|--------|------|
| **high** | `PredictRequest.livestock_ids` 加默认值，修 `analyze_single` body 422 问题 | Task 2 / Task 13 |
| **medium** | ai-platform 目录/docker context 是否对齐 tile-worker 惯例（或显式说明偏离理由） | File Structure / Task 14 |
| **medium** | 统一 fixture 与 db 路径的索引时区（naive vs tz-aware） | conftest / Task 12 |
| **medium** | Mahalanobis 历史矩阵排除当前检测窗口（防异常自稀释） | Task 10 |
| **medium** | `history_max` 用历史段 CUSUM 最大值，避免 CUSUM 维度退化为常数 | Task 10 / Task 8 |
| **medium** | SQL 改 `make_interval(hours => %s)` | Task 12 |
| **low** | 收紧 `test_cusum_flat_series_low` 容差 | Task 6 |
| **low** | `_predict_one` 兜底用 `Contributions(...)` 而非裸 dict | Task 13 |
| **low** | `app depends_on ai-platform` 移到 Plan 2 | Task 14 |
| **low** | 补 route_by_neff 纯阈值 vs 迟滞交叉对照测试 | Task 9 |
| **low** | 核对测试总数（约 45 vs 实际 54） | Self-Review |
