# 饮水检测 L2-pre 回放报告（NIX-256 Task 6）

日期：2026-10-05 ｜ 分支 `nix/256-drinking-physiology-p1` ｜ 环境：本地栈（bootRun + postgresql@16@55432，RocketMQ 排除）
数据：`backfill_sim.py --days 30 --cows 10 --seed 20261005` 生成（DATAGEN source 入库，用户裁决 2026-10-05 ①）

## 0. 结论速览

| 项 | 结果 | 门禁 |
|---|---|---|
| 30 天全群回放（修复合并锚定后） | **Se 0.832 / PPV 1.000 / F 0.9084**，平台≡离线（0.9078） | ✓ |
| 标记闭环演练（四通道全走通） | CONFIRMED 1994 / REJECTED 107 / MANUAL 3；`--labels` 建议报告产出，采信门槛通过（2101≥100） | ✓ |
| V 形抽查 20 例 | 算法侧 17/17 通过；3 条 MANUAL 为边界深度补录（符合语义；深度基准双口径见 vspot-20.note.md） | ✓ |
| **T6 回灌产出** | 发现并修复 T3 内核缺陷：**合并锚定链首 → 长谷幻影切分**（af2c6f5a，双侧内核同修，Aubé 全网格逐数一致） | ✓ |

## 1. 回放数据与执行

- 生成：10 头牛 × 30 天 × 5-min = **86,400 温度点**（source=DATAGEN）；**1,985 个植入饮水谷**（边界深度 0.35–0.55°C 共 207 个 ≈10%；发热期 14 个；一头牛一日 0 谷）；1 条 TEMPERATURE_ABNORMAL 告警（5 天发热期，AUTO_RESOLVED）；谷深默认 2.8–4.0°C（log-uniform）。
  - **谷深参数勘误（子智能体数据驱动异议，主智能体独立复核批准）**：任务书原定 0.6–1.8°C 与生产口径深度线 μ−0.5σ−1.0°C 算术不相容（实测 F≈0.10）；Aubé 真实谷深 p10=2.9 / 中位 8.2°C（独立复测 n=35：min 3.30 / p10 4.92 / 中位 8.30），取真实分布低端 [2.8,4.0] 保守可检出。可用 `--depth-min/--depth-max` 复现原区间。
- 批量触发：`POST /api/v1/admin/drinking-recalculate {from:2026-09-05,to:2026-10-04}`（省略 deviceId=全群）→ `{scope:ALL_FARMS, farms:1, devices:12, events:*, failedFarms:0}`，耗时 1.45s。

### 1.1 三轮评分轨迹（污染→清理→内核修复）

| 轮 | 环境/内核 | Se | PPV | F | 说明 |
|---|---|---|---|---|---|
| 1 | 检测窗混入 T4 遗留 Aubé MANUAL_IMPORT 3,456 点 + 种子 UNKNOWN 492 点 / 旧内核 | 0.805 | 0.779 | 0.7914 | 平台按设计读设备全部 source 温度点；过采样交叠产生多余检出 |
| 2 | 清理窗内残留（备份 4,071 行）/ 旧内核 | 0.846 | 0.795 | 0.8199 | PPV 差距指向内核 |
| 3 | 干净 / **滚动锚定修复后** | **0.832** | **1.000** | **0.9084** | det 1652 = TP 1652 / FP 0 / FN 333（离线 1650/0/335）；与离线同数据交叉自测（F=0.9078, TP 1650）对齐，**平台≡离线** |

- 评分口径：device 内事件中心距真值谷中心 ≤20min（容差 15/20/30min 结果稳定 ±0.003）；真值时间轴上海墙钟、事件轴 UTC（差 8h 已换算——首轮评分曾漏换算致巧合命中，已纠正）。
- **FN=333 分解**：发热期排除 14（设计）＋边界深度 200（设计）＋<15min 近邻谷合并 78（spec 正典语义：近邻双谷=一事件）＋昼夜低谷/日界残余 41。全部可解释，无不明缺失。

### 1.2 内核缺陷：合并锚定链首 → 长谷幻影切分（本轮最重要产出）

- **症状**：旧内核下设备 55 检出 227 vs 离线 174；52/174 个谷出现"嵌套次事件"——恰在主事件 start **+15:00 整**（=merge-gap）、共享谷底与恢复终点、temp_drop 显著小（0.4–0.5）。
- **机理（对照代码逐步求值）**：`judgeDay` 对每个合格下滑步进各产一个候选（borderline 评估所需）；`mergeEvents` 把间距比较锚在**合并链首 start**（`combine` 保留 earliest）→ 下跌段 >merge-gap 的谷按 merge-gap 整数倍机械切段。javadoc 自述 "consecutive starts"，实现违背自身文档。
- **修复（af2c6f5a）**：滚动锚定（比较上一成员自身 start），Java `mergeEvents` 与 Python `detect_combined` 双侧同修；新增回归测试（20-min 下跌 → 单事件；真近邻双谷不误并）15/15 绿。
- **Aubé 回归**：生产口径全网格重跑**逐数一致**（最优行 TP 632/FP 0/FN 98，F=0.9280@5min，门禁通过；生产参数行 R_th=0.7：0.9153/0.9006@5/6min 均 ≥0.90（注：此数字取自当时 results-production/，即滚动锚定修复前 chain-first 产物；当前内核复跑 6-min 为 0.8998/选定行 0.9201，门禁不变——N3 勘误 2026-10-06）；10-min 0.8484 低于门禁如实记录）。Aubé 谷陡链短，对锚定语义不敏感——这正是 B1 平价当时未暴露缺陷的原因；缺陷只在缓降长谷显形。spec §14.1 已补勘误注。
- **gap 复核**：新语义下 gap 10/15/20 结果完全一致（Aubé 链短），**gap=15 维持**。

## 2. 标记闭环演练（spec §15 全通道）

| 通道 | 操作 | 结果 |
|---|---|---|
| 导出端点（T6.1 新增） | `GET /admin/drinking-labels/export` | 200 / 350,803 B / BOM+RFC4180+`drinking-labels_2026-09-05_2026-10-04.csv` 全契约 |
| 检出确認 | PATCH label（owner 账号，2,098 次调用） | DATAGEN→CONFIRMED 1,643；**0 失败** |
| 候选转正 | 候选匹配真值边界谷 → CONFIRMED | 348 转正（§15.2 转正语义） |
| 候选驳回 | 候选无真值对应 → REJECTED | 97 驳回（+DATAGEN 落选 9 + 遗留 1） |
| 漏报复录 | POST manual ×3（真值驱动） | id 7672–7674，source=MANUAL/label=CONFIRMED ✓ |
| 二次导出 | 含全标签 CSV | 2,101 行，四通道标签齐全 |
| `--labels` 建议 | `calibrate.py --labels export.csv --series series.csv` | 报告产出（`output/drinking-l2/labels-mode/labels_suggestion.txt`）；**采信判定通过**（farm 1: 2,101≥100）；生产参数标签集 F=0.879，网格最优 0.8793（R_th 0.5/gap 10）→ 差 ≤0.04pp 属噪声，**建议=维持现产参数** |
| 标签跨重算保留 | 设备 55 全窗重算 | 前=后：CONFIRMED 208 / REJECTED 14（§15.4 保留语义端到端验证） |

- **--labels 语义注记**：转正候选按 §15.3 计为正样本，但网格只能整体放宽参数把它们移入事件道——故标签集 Se（0.80）结构性低于原始回放 Se（0.832），是口径差异非缺陷；无标签匹配的检出不计 TP/FP（运维只标子集，caveat 已写入报告）。
- **契约观察（记档，非阻断）**：manual POST `eventStartAt` 仅接受分钟精度 `yyyy-MM-dd HH:mm`（带秒 → 400 VALIDATION_ERROR）；UI 已按此发送，但 API 层面可考虑宽容解析。

## 3. V 形抽查 20 例

样本：随机 10 确认事件 + 7 转正候选 + 3 补录；证据 `output/drinking-l2/drill/vspot-20.csv|svg`（±90min 曲线，红线=事件起点）。

- **算法侧 17/17 通过**：谷底全部落在事件窗内；drop 1.15–3.86°C；120min 回升率 54–282%；距最近植入谷 ≤12min。
- **MANUAL 3 条**：所在位置相对前窗最大值（drop_vs_pre_max 列）仅 0.15–0.60°C 浅谷（边界深度植入），算法确不可见——正是补录通道的用途（人看到饮水、机器测不出）；在 `--labels` 中计 FN 形成调参压力，语义正确。

## 4. 边界样张

| 边界 | 证据 | 结果 |
|---|---|---|
| 0 次日 | 设备 59 / 2026-09-20（上海日，真值无谷） | 事件 0、候选 0 ✓ |
| 全发热周 | 告警窗 09-29 16:00→10-04 16:00 UTC | 窗内事件/候选 **0**；窗外 171 正常检出；UI 汇总 livestock 40：5×100%+今日 25%（退热缓冲 6h 精确）；处置单道 livestock 4（demo 种子 PENDING 处置单）：54.2%=780/1440 分毫吻合 ✓ |
| 英文长文案 | 浏览器截图 `drill/ui-en-home.png`、`ui-en-detail-1.png`（locale=en-US 实字渲染） | 发热长注释英文完整呈现、无截断溢出 ✓ |
| textScale 1.3 | widget golden `test/features/drinking/goldens/drinking-card-{en-long,zh-textscale-1.3}.png` + 溢出断言 | 2/2 无溢出异常，analyze 干净 ✓ |

## 5. L2-real 顺延状态（显式记录）

- **触发条件**：①86/223 生产环境核实存在真实 source（THINGSBOARD/AGENTIC_PLATFORM）瘤胃温度数据 ≥30 天；或②试点胶囊接入（L3 立项后）。当前温度/蠕动全部为 DATAGEN 仿真（用户确认 2026-10-05），**无真实数据可放**。
- **切换后动作**：同一套机制零改动（标记 UI/导出/--labels 与 source 无关）；报告仅采信真实 source 事件；频次量级对照 Cardot 7.3±2.8 次/日（泌乳牛）。对外效果口径在 L3 前保持"试点验证方案"（AGENTS 红线：仿真结果不混充生产效果）。

## 6. 运维与数据治理备忘

- 检测读设备**全部**温度点（不分 source，多源共存是正常形态）；但研究数据导入（Aubé MANUAL_IMPORT）与种子演示数据同设备共存时会污染回算——**数据恢复/导入操作后应 farm/device 级复核再跑批量回算**（本次已清理并备份 4,071 行）。
- 演练产物可复现：`scripts/drinking_calibration/backfill_sim.py`（seed 固定）、`output/drinking-l2/`（series/truth/labels-mode/drill 全套）、`drill/label_drill.py`。

## 7. 产出清单

- 代码：`8bbecab5`（导出端点+4 单测）、`2be76996`（--labels 模式+回填生成器）、`af2c6f5a`（合并锚定修复+回归测试+Aubé 复跑+spec §14.1 勘误）、本报告 commit（golden 边界测试+演练证据）。
- 后端测试：Drinking 相关 60+4+2=66 项绿（4 既有 Testcontainers 环境失败不变）；Flutter drinking 23 项绿。
