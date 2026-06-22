# AI Platform Phase A — 全量代码评审

- **分支**: `feat/ai-platform-phase-a`
- **评审范围**: `smart-livestock-server/ai-platform/` 全部 26 个文件（+1568 行），`docker-compose.yml` ai-platform 服务块
- **基线**: master（V37），本分支 25 commits，14 Task 全部落地
- **评审方式**: 静态全量阅读（源码 + 测试 + 契约）+ 与后端 V20 表结构 / 迁移历史交叉核验
- **测试运行**: ⚠️ 本地系统 Python 无 fastapi/pandas/sklearn 等依赖，沙箱禁止联网 pip install；按 AGENTS.md §5，依赖安装与 pytest 运行属部署阶段（用户在 172.22.1.123 执行）。本评审基于代码静态分析，测试断言已逐条人工核验。

---

## 总体评价

**🟢 实现质量高，架构清晰，TDD 纪律严格。** 三层 capability 契约（L1 实跑 / L2·L3 占位）、engine 透传、registry 门面分层干净；L1 内部 STL+CUSUM+Mahalanobis 三路融合 + 经验排名归一化 + LOOCV d2_hist + self-leak 防护，算法严谨度远超一般 Phase A 占位。测试覆盖 13 个文件、~60 用例，含多 seed 参数化、边界、退化、hysteresis 分叉点锁定，可解释性强。

**与 design/spec 的一致性**: 字段契约（`temperature_logs.temperature` / `rumen_motility_logs.frequency` / `activity_logs.activity_index`）与 V20 `CREATE TABLE` 完全吻合 ✅。`recorded_at` 索引、`livestock_id` 过滤均对齐。

**主要风险集中在生产化运维层**（连接池、迟滞失效、时区、安全），非算法正确性问题。下面按优先级列出。

---

## 🔴 High（合并前建议处理）

### H1 — 批量端点无连接池，每头一次 TCP+auth 握手

**位置**: `app/db.py:41-42` `_connect()` → `fetch_window()` → `conn.close()`；`app/main.py:23-26` `_predict_one` 对每个 `livestock_id` 调一次 `_fetch`。

**问题**: `PredictRequest.livestock_ids` `max_length=100`，批量 100 头 = 100 次 `psycopg.connect()`（每次 TCP 三次握手 + PG auth + TLS 协商）。在高频检测场景（design §3 Java 端定时拉取）下：
- 连接建立开销 >> 查询本身（3 条 SELECT 各走索引）；
- 短时大量连接可能触发 PG `max_connections`（默认 100）或连接风暴；
- `finally: conn.close()` 在异常路径下若 `_connect()` 本身抛错（PG 不可达），`conn` 未定义会 `NameError` 掩盖真实错误。

**建议**:
- 用 `psycopg_pool.ConnectionPool`（psycopg3 原生池，已在 `psycopg[binary]` 依赖树外需加 `psycopg-pool`）或模块级单连接 + `@contextmanager`；
- 或至少把 `_connect()` 移到 `fetch_window` 外层，批量共享一个连接（事务只读，无竞争）；
- `conn = None; try: conn = _connect(); ... finally: if conn: conn.close()` 防异常掩盖。

**严重度**: 生产稳定性。Phase A 单头验证不触发，Plan 2 接入 Java 定时批量后立即暴露。

---

### H2 — design §4.3 要求的 per-individual 跨次迟滞未实现，router 迟滞分支为端到端死代码

**设计要求**（`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md:112`）：
> 路由切换迟滞（评审补强 #4）：分档切换带 ±20% hysteresis 防临界抖动——升档需 N_eff **持续** ≥200（非单次碰线），降档需持续 <160。否则**同一头牛**在临界值会因个别缺失槽位导致算法来回切换。

该要求隐含三个实现前提（缺一不可）：
- **跨次**："持续"要求系统记住前次检测的 N_eff 或当前档位，单次调用无法表达；
- **per-individual**："同一头牛"要求状态按 `livestock_id`（或 `tenant_id+livestock_id`）分键，非全局；
- **状态机**：`current` 档位是被 N_eff 驱动迁移的状态，升档/降档阈值不对称。

**代码现状**（`app/capability/health_l1.py:38-39`）：
```python
router_state: dict = {}                  # 局部变量，函数返回即销毁
algo = route_by_neff(n_eff, state=router_state)
```
- `router_state` 是 `predict_series` 的局部变量，**每次调用新建空 dict**；
- 空 dict 无 `current` 键 → `route_by_neff` 恒走纯阈值分支（`router.py:43-47`）；
- 迟滞分支（`router.py:49-65`，22 行）**端到端永不执行**。

**结论**：design §4.3 第 112 行的迟滞要求**零落实**。三个前提（跨次 / per-individual / 状态化）一条都不满足。`router.py` 的迟滞实现本身逻辑正确，`test_router.py::test_neff_hysteresis_avoids_jitter` 也覆盖了函数级行为，但**调用方从未把状态接进来**——属于"零件造对了、没装到机器上"，且测试制造了"迟滞已工作"的假象。

**真实影响**（代入 health_l1 实际消费方式逐步求值，非从阈值数字联想）：
- 纯阈值分支在 N_eff=29/30 边界抖动时，`algo` 在 rules↔mahalanobis 间横跳 → `health_l1.py:79` 的 `if algo != "rules"` 分支时开时关 → joint（Mahalanobis 距离）时而计算、时而为 0 → 融合分数 `w_joint=0.4` 项跳变 0.4 幅度 → 同一头牛相邻两次检测分数可能差 0.4，正是 design 第 112 行"算法来回切换"要防的病症；
- N_eff=199/200 边界（iforest↔mahalanobis）在 Phase A 被 `health_l1.py:42` `if algo=="iforest": algo="mahalanobis"` 抹平，**零影响**——所以 iforest 迟滞带 `[160,200)` 在当前代码里连"失效"都谈不上，是双重死代码（迟滞不接线 + 档位被强降）。

**修复方向**（二选一，需 design/Plan 2 决策）：

1. **落实设计**（推荐，若 §4.3 第 112 行仍是要的）：
   - 把 router 状态提升为按 `livestock_id` 分键的持久态。Phase A 无 DB 写权限，最小实现是进程内 `dict[livestock_id] -> current_algo`（单实例够用；多实例需 Redis 或 PG，属 Plan 2）；
   - `health_l1` 改为 `algo = route_by_neff(n_eff, state=self._states.setdefault(lid, {}))`；
   - 补端到端测试：同一头牛 N_eff 在 28↔31 间连续 3 次检测，断言 `model_meta["router"]` 不来回切换（现有 `test_neff_hysteresis` 只测函数，必须补"跨次"测试）。

2. **修订设计**（若 Phase A 判定迟滞非必需）：
   - 删除 router.py 迟滞分支 + `test_neff_hysteresis_avoids_jitter`，避免"有测试覆盖但运行时死代码"的误导；
   - 在 design §4.3 第 112 行标注"Phase A 不实现，Plan 2 状态化时补"，并在 health_l1 注释明确"纯阈值，无跨次记忆"；
   - 评估无迟滞的后果：临界 N_eff 的牛分数抖动是否可接受（若 Java 端有告警去抖/时间窗聚合，可吸收；若直接按分数告警，则会误报）。

**当前状态最差**：代码存在、单测通过、给人已落实的印象，但 design 要求零落地。无论选 1 还是 2，都必须打破这个假象——**留着不动是最坏选项**。

---

## 🟡 Medium

### M1 — `recorded_at` 时区契约隐式假设未文档化

**位置**: `app/db.py:37` `pd.to_datetime([r[2] for r in rows], utc=True)`。

**事实**: V20 `temperature_logs.recorded_at TIMESTAMP NOT NULL`（**无时区**）。`pd.to_datetime(..., utc=True)` 对 naive 时间戳会**当作 UTC 赋值**，不转换。

**问题**:
- 若 PG 服务器 / 容器时区非 UTC（如 `docker-compose` 默认 UTC，但部署机 `172.22.1.123` 的 PG `timezone` GUC 未确认），写入时的"本地时间"会被 ai-platform 当 UTC 解释 → 时间错位；
- conftest 用 `tz="UTC"` 生成测试数据，掩盖了真实 DB 的 naive 时间戳路径；
- `make_interval(hours => %s)` 与 `NOW()` 的比较依赖 PG 会话时区，与 Python 侧的 utc 赋值若不一致，窗口边界会偏移。

**建议**:
- 在 db.py docstring 明确"假设 PG `timezone='UTC'`，否则需 `AT TIME ZONE` 转换"；
- 或查询改为 `recorded_at AT TIME ZONE 'UTC' AS recorded_at` 显式锚定；
- Plan 2 联调时用 `curl` 验证一次真实数据的窗口边界（取一头有数据的家畜，对比 PG `SELECT` 与 API 返回的 n_eff）。

### M2 — 分区表仅覆盖到 2026-08，跨分区查询需验证

**位置**: V20 `temperature_logs_2026_03` ... `temperature_logs_2026_08` + `_default`。

**事实**: ai-platform `fetch_window` 的 `WHERE recorded_at >= NOW() - make_interval(hours => %s)` 会落到具体分区。当前（2026-06）落在 `_2026_06` 正常；但：
- 若 `window_hours=720`（schemas 允许上限 30 天）跨越 06/07 分区边界，PG 需扫描多分区（有 default 兜底，不报错）；
- 2026-09 之后的数据进 `_default` 分区，查询性能退化（无针对性索引）；
- 这是**后端既有问题**（V20 设计），非本分支引入，但 ai-platform 是首个跨分区大窗口查询的消费者，应在 Plan 2 联调时确认 `EXPLAIN` 走索引。

**建议**: 在 db.py 或 design §9.1 备注"窗口 > 单月时跨分区扫描，Plan 2 需 EXPLAIN 验证"。非阻塞。

### M3 — `analyze_single` body 与 path 参数语义重叠，且未校验一致性

**位置**: `app/main.py:67-69`
```python
@app.post("/ai/health/analyze/{livestock_id}")
def analyze_single(livestock_id: int, req: PredictRequest):
    results = [_predict_one(req, livestock_id)]
```

**问题**: body 仍可携带 `livestock_ids`（schemas 默认 `[]`，但也允许传 `[999]`）。若客户端同时传 path `livestock_id=10` 和 body `livestock_ids=[999]`，`_predict_one` 用 path 的 10，但 health_l1 内部 `req.livestock_ids[0]` 用 999（虽被覆盖，但 `model_meta` 不含此值，且语义混乱）。

**建议**:
- 单头端点要么不接受 body 的 `livestock_ids`（用独立 `SinglePredictRequest` 不含该字段），要么显式校验 `req.livestock_ids` 为空或与 path 一致；
- 当前靠"覆盖"兜底，能跑通但契约不清，Plan 2 Java 端封装时易踩坑。

### M4 — 每次请求重算 STL 分解 + Mahalanobis LOOCV，无缓存

**位置**: `health_l1.py:48` `stl_layer_score(slots_df[d])`（对 3 维各跑一次 `STL(robust=True).fit()`，672 点 × 3）；`detectors.py:73-78` LOOCV 对 n≈48 样本各拟合一次 OAS。

**问题**: 单次请求 CPU 可接受（672 点 STL ~50ms，LOOCV 48×OAS ~20ms），但：
- Java 端定时批量（design §3）每 N 分钟对全牧场数百头跑一次 → CPU 峰值；
- STL 的 `period=48` 分解对同一头家畜的历史段是稳定的，可缓存 residual；
- LOOCV 的历史特征矩阵在同一检测窗口内不变。

**建议**: Phase A 可不做（单头够快），但 design/Plan 2 应记录"批量场景需缓存 STL residual + 历史特征矩阵 + OAS 模型，key=(livestock_id, window_hash)"。非阻塞，标 TODO 即可。

### M5 — `compute_neff` 与 engine 传入的 `n_eff=0` 不一致，契约混淆

**位置**: `engine.py:18-19` `predict_series(..., n_eff: int = 0)` → `CapabilityContext(n_eff=n_eff)`；`health_l1.py:37` 又 `n_eff = compute_neff(slots_df)` 重新算。

**问题**: engine 透传的 `n_eff=0` 进入 `CapabilityContext`，但 L1 的 `is_available(ctx)` 不读 ctx.n_eff（永远 `return True`），health_l1 内部用自己算的 n_eff。**两套 n_eff 并存**，CapabilityContext.n_eff 在 Phase A 完全未被任何 capability 读取——是预留字段，但当前是"有参数无消费者"。

**建议**: 要么 engine 不传 n_eff（透传层不该假设数据特征），要么文档明确"CapabilityContext.n_eff 预留给 L2/L3 路由，L1 自行重算"。避免后续维护者误以为 ctx.n_eff 驱动 L1 路由。

### M6 — `PredictResponse.anomaly_type` 是自由 `str`，未用枚举约束

**位置**: `schemas.py:45` `anomaly_type: str  # circadian_disruption / abrupt_change / multivariate / normal`。

**问题**: 注释列了 4 个合法值，但类型是 `str`，`decide_anomaly_type` 返回值靠实现保证。若未来某分支拼错（如 `"abrubt_change"`），schema 不拦截，Java 端按字符串匹配会漏判。`capability_used` 同理（`"health_l1"` / `"none"` / `"no_data"` reason 散落）。

**建议**: 定义 `AnomalyType(str, Enum)` 和 `CapabilityUsed(str, Enum)`，与 `CapabilityLevel` 风格一致。低优先级但提升类型安全。

---

## 🟢 Low / Nit

### L1 — `__post_init__` 校验在模块导入时触发，环境变量错误导致启动失败而非配置报错
`config.py` `settings = Settings()` 模块级实例化，若 `AI_W_STL` 等设错，整个服务 import 即崩（FastAPI worker 起不来）。这是合理的 fail-fast，但错误信息建议在 Dockerfile/README 提示"启动失败先查 AI_* 环境变量"。Nit。

### L2 — `requirements.txt` 未 pin 传递依赖，`psycopg[binary]` 拉入的 libpq 版本浮动
Phase A 可接受，Plan 2 生产化时建议 `pip-compile` 生成 lock。Nit。

### L3 — `test_e2e_synthetic.py::test_score_distribution_self_consistent` 阈值 `< 0.5` 是经验值，且注释承认"边缘通过"
```python
# range(10) normal 均值 ≈0.491，边缘通过 < 0.5
assert sum(scores) / len(scores) < 0.5
```
这是 **flaky 风险**——若 numpy 版本/scipy 更新导致 STL 行为微变，0.491 → 0.501 即破测。建议要么放宽到 `< 0.55` 并注释"实测 0.49，容差 0.06"，要么改用相对断言（normal 均值 < anomaly 均值 × 0.8）。当前已用固定 seed，确定性 OK，但绝对阈值脆弱。

### L4 — `health_l1.py:26` `if req.livestock_ids else 0` 的 fallback `0` 是隐式魔法值
单头端点 body 无 `livestock_ids` 时 livestock_id=0，虽被 main 覆盖，但 `0` 作为"未知"哨兵易与真实 id=0 混淆。建议用 `Optional[int]` 或直接要求 `_predict_one` 在调用前设置 `req.livestock_ids = [livestock_id]`。Nit。

### L5 — `fusion.normalize_cusum` / `normalize_mahalanobis` 在 health_l1 中未被调用（被经验排名替代）
`health_l1.py` 用 `np.searchsorted` 做经验排名归一化，`fusion.py` 的 `normalize_cusum`/`normalize_mahalanobis` 仅被各自单测覆盖，生产路径未用。注释（`health_l1.py:78-80`）解释了"保留为通用工具"，但若 Phase B 不回归，这俩函数会成 dead code。建议标 `# Phase B 预留` 或删除。Nit。

### L6 — Dockerfile 未固定 python:3.11-slim 的 digest，且未做 `.dockerignore`
`context: ./ai-platform` 会把 `tests/`、`.pytest_cache/`、未来 `.venv/` 全打进镜像。建议加 `.dockerignore`（`tests/`、`__pycache__/`、`.venv/`、`.pytest_cache/`）。`COPY app/ ./app/` 已排除 tests，但 build context 上传仍含。Nit。

### L7 — `docker-compose.yml` ai-platform 无 healthcheck，Java 端 `depends_on` 仅 `service_started`
`postgres` 用了 `condition: service_healthy`，但 ai-platform 自身无 healthcheck，未来 Java `depends_on: ai-platform: condition: service_healthy` 会立即通过（service_started）。Plan 2 加 Java 联调前需补：
```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/ai/health/live')"]
  interval: 10s
  timeout: 3s
  retries: 5
```
当前 Plan 2 未实施，非阻塞。

---

## 修改清单（按优先级）

| # | 优先级 | 文件 | 动作 | 工作量 |
|---|--------|------|------|--------|
| H1 | 🔴 | `app/db.py` | 引入连接池或批量共享连接 + `conn=None` 防异常掩盖 | 中 |
| H2 | 🔴 | `app/capability/health_l1.py` + `router.py` | 决策：迟滞状态化 or 删除迟滞分支+测试 | 中 |
| M1 | 🟡 | `app/db.py` | 时区假设文档化或 `AT TIME ZONE 'UTC'` | 小 |
| M3 | 🟡 | `app/main.py` + `schemas.py` | 单头端点 body 契约清理 | 小 |
| M5 | 🟡 | `app/engine.py` 注释 | 文档化 n_eff 双轨语义 | 极小 |
| M6 | 🟡 | `app/schemas.py` | `AnomalyType` / `CapabilityUsed` 枚举 | 小 |
| L3 | 🟢 | `tests/test_e2e_synthetic.py` | 放宽或改相对断言 | 极小 |
| L6 | 🟢 | `ai-platform/.dockerignore` | 新增 | 极小 |
| L7 | 🟢 | `docker-compose.yml` | ai-platform healthcheck | 极小 |

**建议合并策略**: H1/H2 建议本分支处理（生产稳定性 + 避免误导性测试）；M 系列可记入 Plan 2 TODO；L 系列随下次清理。

---

## 做得好的地方

- **算法严谨**: LOOCV 消除 in-sample 偏差、经验排名替代 chi2.cdf（病态协方差鲁棒）、self-leak 防护延伸到基线层、CUSUM 同尺度预处理——每一步都有对应的 commit + 注释解释"为什么"，可追溯性强。
- **TDD 纪律**: 每个 Task 都是 test→impl→fix 循环，commit message 清晰记录"评审 #N"对应关系，历史可读性极佳。
- **退化路径覆盖**: 常量序列（epsilon-floor guard）、空数据兜底、短序列 STL 退化、协方差奇异（OAS + 去常量列）、N_eff 不足降级——边界处理完整，无 panic 路径。
- **design 对齐**: 字段契约、capability 三层、N_eff 分档阈值（30/200）、融合权重（0.3/0.3/0.4）均与 spec 一致，且偏离处（如经验排名替代 chi2）有充分论证。
- **注释质量**: 大量"为什么这样做"的注释（而非"做了什么"），对后续维护者极友好。

---

## 结论

**Phase A 作为算法验证 + 架构骨架是成功的**，算法正确性和测试覆盖达到生产级水准。**主要缺口在生产化运维层**（连接池 H1、迟滞失效 H2），这两项不影响 Phase A 单头 demo，但会在 Plan 2（Java 定时批量联调）时立即暴露，建议合并前处理。其余为契约清理和文档化，可在 Plan 2 一起收。

**推荐动作**: 处理 H1 + H2 后合并；M/L 记入 Plan 2 checklist。
