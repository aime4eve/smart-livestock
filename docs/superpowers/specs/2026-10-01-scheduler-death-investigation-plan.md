# 共享调度池静默死亡——触发点排查方案

- 日期：2026-10-01
- 状态：方案待批准（按硬性规则，批准后执行）
- 关联：`10-Projects/02-smart-livestock/2026-09-30-test仿真数据流断续诊断与看门狗止血.md`（知识库）
- 已落地的止血/缓解：datagen tick、GPS 消费、TB 轮询三链路已迁独立调度器（c6cd5350 / 22136330），共享池扩容 8 线程（22136330），看门狗兜底（activity 8 分钟窗）

---

## 1. 问题定义

Spring 共享调度池（`@EnableScheduling` 默认单线程 `ThreadPoolTaskScheduler`）在容器生命周期内的某个时刻**静默停止调度一切任务**：无错误日志、无 shutdown 痕迹、应用 HTTP/MQ/DB 全部正常。受影响的 19 个 `@Scheduled` 任务里，仿真/GPS/TB 三链路已迁出，剩余任务（信号 outbox 分发 1s、SSE 心跳 20s、离线对账 10min、AI 评估 5min、疫病检查每小时、分区维护等）仍在共享池上，死亡即静默停摆。

**待回答的唯一核心问题**：共享调度池停止派发的确切机制——哪个任务、哪行代码、什么条件。

## 2. 证据台账（截至 2026-10-01）

| # | 证据 | 含义 |
|---|---|---|
| E1 | 每容器恰好 1 轮 datagen 全量写入（多容器复现），之后 tick 静默 | 死亡发生在启动后秒级~分钟级，非长期退化 |
| E2 | 14.5h 内零 ERROR 日志（含 DelegatingErrorHandlingRunnable 的标准错误输出） | 异常未走标准错误处理路径，或根本无异常 |
| E3 | 死态 dump（17:28，17:15 容器）：scheduling-1 卡在 `SignalOutboxDispatcher.dispatchScheduled → findDispatchableIds → PgStatement.executeQuery` | 死亡瞬间调度线程在执行信号 outbox 查询 |
| E4 | 两次独立 dump 均命中该查询执行中（按毫秒级查询/1s 轮询，单次命中概率 <1%） | 统计上强烈指向"该调用长时间不返回"（非慢 SQL，见 E7） |
| E5 | 更晚 dump（17:59 容器死态）：**完全没有 scheduling 线程**（92 线程） | worker 消失 = `getTask()` 返回 null = executor 被 shutdown（JDK 语义下 worker 不会自行退出）——**但此 dump 可能被 tail 截断，需重抓验证** |
| E6 | `SIGNAL_OUTBOX_POLL_MS=30000` 试验无效（仍一轮死） | 单纯降低 outbox 轮询频率不能避免死亡 |
| E7 | 手动 EXPLAIN ANALYZE 该查询（test，10-01）：**0.5ms**，Seq Scan 118 行 | SQL 本身不慢；E3/E4 的"卡在 executeQuery"指向 **JDBC/网络/会话层阻塞**或 dump 时刻的锁环境与现在不同 |
| E8 | 死态时 HTTP（Tomcat 线程）、MQ 消费者（20 线程 waiting）全部正常 | 只有共享调度池受害 |
| E9 | 时间线：09-26 信号同步 Phase 3 上线 → 09-28 dev/test 数据断崖；09-27（无信号异常的一天）正常 | 头号嫌疑 = 信号 outbox/SSE 链路（09-26 上线） |
| E10 | `dispatchScheduled → dispatchDueBatch` 为**同类自调用**，`dispatchDueBatch` 的 `@Transactional` **不生效**（无代理）→ 查询以 autocommit 执行 | `FOR UPDATE` 行锁本应即取即释；但事务边界与设计意图不符本身就是隐患 |

**当前头号嫌疑（按优先级）**：
1. `SignalStreamHub` 的 SSE 推送路径在 `publish()` 内被同步调用（E3 的查询只是运气不好的采样点，真正卡点在其后/其前的 SSE emitter 发送——**到已断开客户端的 emitter.send() 可无限阻塞**）；
2. 共享池被某段代码生命周期逻辑 shutdown（E5）；
3. micrometer Observation 边界（`ScheduledMethodRunnable.run` 的 observe 包装）在特定条件下抛错且不打日志。

## 3. 排查计划（三阶段，先廉价后昂贵）

### 阶段 0：观测固化（0.5 天）

- **池心跳探针**：新增一个每 30s 的 `@Scheduled` 探针任务（INFO 一行：时间戳 + 池内任务计数），死亡时刻从日志**精确到秒**；
- **池状态指标**：`Micrometer` gauge 暴露共享池 active/poolSize/queued（`ScheduledThreadPoolExecutor` 的 getActiveCount/getQueue().size()），或等价定期日志；
- **完整 dump 采集脚本**：kill -3 后取 `docker logs` 全量（去掉 tail 截断），存 `/data/agentic/sched_dumps/<ts>.txt`（修正 E5 的截断疑点）；
- 部署 test，等待死亡复现（历史规律：数分钟~小时级），拿到**死亡时刻的精确日志切片 + 完整 dump**。

**判定**：探针停摆时刻 ± dump → 死亡瞬间调度线程的状态（阻塞点/消失）→ 直接进入阶段 3 修复。

### 阶段 1：代码审计（1 天，与阶段 0 并行）

聚焦"能在调度线程上永久阻塞或杀死线程"的代码模式，逐条读并记录结论：

1. `SignalStreamHub`：SSE emitter 的 send 是否有超时？死连接的清理机制（heartbeat 20s 能清吗）？`publish()` 是否可能在持有共享池线程时同步 send？
2. `SignalOutboxDispatcher`：事务边界（E10 的自调用失效）与 `upsertPending` 调用方（遥测 ingest 路径）的锁交互；`eventPublisher.publish(event)` 的完整下游；
3. `AgenticPlatformSyncDispatcher`（blade 同步，含自有 executor 与 shutdown 逻辑）与共享池的交互；
4. `health-telemetry` RocketMQ 消费者（20 线程）：消费逻辑里是否有对共享池 bean 的同步调用；
5. 全局 grep：`shutdown()`、`Thread.interrupt`、可被外部触发的池操作。

**产物**：审计清单（每条嫌疑：代码位置、阻塞可能性、验证方式）。

### 阶段 2：受控复现（1 天）

在 dev（低峰）按阶段 1 的头号嫌疑构造条件：

- 复现变量矩阵：SSE 订阅客户端数（0/1/N 个无头浏览器 tab）、遥测写入速率（datagen 全量/减半）、outbox 积压量、TB 拉取；
- 复现成功标志：**池心跳探针停摆**（阶段 0 埋点）；
- 复现时抓：完整 dump ×2（间隔 5s）+ JFR（`-XX:StartFlightRecording` 已随重启可加，ThreadStart/ThreadEnd/Monitor Blocked 事件可精确定位线程死亡时刻）。

**判定**：稳定复现（3 次以上）→ 定谳触发器；无法复现 → 回到阶段 1 扩大审计面（含 Spring/micrometer 框架层 issue 检索）。

### 阶段 3：修复 + 回归（1-2 天）

按定谳结果实施，候选（按嫌疑预置）：

- **A. SSE/信号链路修复**：emitter send 加超时与异常隔离（send 移出调度线程/异步化）、死连接及时清理、`dispatchDueBatch` 事务边界修正（自调用失效改代理调用或移除事务依赖）；
- **B. 兜底自愈**：池心跳探针检测自身停摆 N 次后**重建共享调度池**或触发容器重启（升级现有看门狗为应用内自愈）；
- **C. 隔离加固**：把剩余高价值任务（信号 outbox 分发、SSE 心跳）迁独立池（同前三链路模式）。

回归：dev 24h 数据连续性（activity/gps/TB/信号心跳四探针）→ test → 用户验收。

## 4. 工作量与交付

| 阶段 | 工作量 |
|---|---|
| 阶段 0 观测固化 | 0.5 天 |
| 阶段 1 代码审计 | 1 天 |
| 阶段 2 受控复现 | 1 天 |
| 阶段 3 修复+回归 | 1-2 天 |
| 合计 | 3.5-4.5 天 |

交付物：定谳结论 + 修复 + 四探针长跑报告（24h 数据连续性）。

## 5. 风险与备注

- 死亡复现窗口不稳定（秒级~小时级），阶段 0 的探针是全部后续工作的前提；
- dev 每天多次部署会不断"复活"调度池、污染复现——复现期 dev 冻结部署；
- 看门狗维持运行（误杀已修正），不影响诊断（重启会打断复现——**诊断期间看门狗需暂停**，阶段 0 部署时一并停用 crontab）；
- 三链路已独立，诊断期内 test 的牛只数据不受影响（用户可见功能不回归）。
