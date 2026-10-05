# 饮水行为检测 + 生理事件流 P1 — 合并设计 Spec v1.1

- 日期：2026-10-04（同日评审修订 ×3：第一轮设计级 A1–A3/B1–B5/C1/C2/C6；第二轮代码级 N1–N4/DDL 惯例/路径；第三轮 plan 评审联动——原型壳宽 280→390 对齐保真对照惯例，全部落实）
- 状态：**spec 待用户确认**（设计令牌已随饮水原型冻结；原型双份 v1.2 冻结；四项裁决按推荐默认执行并记录于原型）
- 关联：
  - 技术方案：`docs/research/2026-10-04-瘤胃温度检测饮水事件-技术实现方案.md`（算法/验证阶梯/配套盘点）
  - 高保真原型：`docs/prototypes/drinking-event-detection-prototype.html` v1.2（**UI 唯一事实源**）
  - 生理记录卡小原型：`docs/prototypes/physiology-events-p1-prototype.html` v1.2
  - 设计令牌：`docs/design-tokens.md`（skill `extract_design_tokens.py` 从原型提取）
  - 知识库：`10-Projects/02-smart-livestock/2026-10-04-基于瘤胃温度谷检测饮水事件可行性评估.md`
  - 工单：Linear NIX-256

---

# 上篇：饮水行为检测（UI + 服务）

## 1. 目标与范围

基于瘤胃温度谷自动检测饮水事件，提供每日饮水频次与时刻分布。**只承诺频次/时刻，不承诺饮水量**（文献负结果）；**离线批分析，不做实时告警**（帧批量上报 ≤30min 延迟）；二期才做骤减告警。

**不做**：饮水量估算、实时告警、概览页入口、独立 Tab、手动回算页面（运维 API）。

## 2. 设计令牌

完整令牌见 `docs/design-tokens.md`（34 枚，skill 脚本提取）。基线 = NIX-246 方案 D 全套；**本 feature 新增 3 枚**：

| Token | 值 | Flutter 映射 | 用途 |
|---|---|---|---|
| `--drinking` | `#3D7FA8` | `AppColors.drinking = Color(0xFF3D7FA8)` | 语义主色：大数字/柱状/chip/菱形标记 |
| `--drinking-soft` | `#E2EDF4` | `AppColors.drinkingSoft` | chip 浅底 |
| `--drinking-event` | `#2C6486` | `AppColors.drinkingEvent` | 温度曲线事件点（白描边） |

复用令牌：`--fever`（发热上下文）、`--map-green`（峰值参考区）、`--border/--surface/--surface-alt`、间距/圆角/阴影全套。**硬规则：编码中任何颜色/间距/圆角/字号不得猜值，一律查令牌表；表中没有的先从原型 CSS 提取再入表。**

## 3. 组件视觉规格（数值从原型 CSS 逐条提取）

### 3.1 DrinkingCard（牲畜详情页健康 Tab，主入口）

| 部分 | 规格 |
|---|---|
| 容器 | 白底 `--surface-alt`，`--radius-md:12`，`--shadow-card`，padding 12 |
| 头行 | 标题 12px/700 + 色点 8×8 `--drinking` + 右侧 chip：bg `--drinking-soft` 文字 `--drinking` 10px/600 padding 3×8 r999 |
| 大数字 | 30px/800 `--drinking` + 单位 11px `--text-secondary`；右侧"上次饮水"标签 11px + 值 12px/700 |
| 迷你柱状 | 高 44px，7 列 gap 6，柱顶 r4 柱底 r2，正常 `--drinking` opacity .85，发热日 `--fever` opacity .55；列值/星期 8px secondary |
| 副标 | 11px secondary："同类成母牛均值 7.3 次/日 · 本牛近 30 日基线 7.6 次/日" |
| 发热上下文条 | bg `rgba(217,123,41,.08)` r8 padding 7×8；图标 11px + 文字 9.5px `--fever` 行高 1.45 |

### 3.2 DrinkingDetailSection（健康详情图表页第四分节）

**时刻分布图**：`chart-area` bg `--surface` r8 padding8；SVG 340×96；饲喂/挤奶峰值区 `#DCE8D5` opacity .55；事件菱形 10×10 `--drinking`；时间轴 `--border`；轴标 7.5px secondary；图例行 8.5px（swatch 10px r3）。副标 11px（Cardot 基准对照）。

**48h 温度叠加图**：SVG 340×120；基线虚线 dasharray 4,4 opacity .35 + 标注 8px；温度线 `--fever` 2px；发热期+6h 缓冲区 `rgba(217,123,41,.12)` r4 + 区内标注 7.5px；饮水谷点 r4 `--drinking-event` 白描边 1.5 + 降幅标签 7.5px/700；图例三项。头部右侧分段切换 `.seg`：容器 border `--border` r999 padding 2，opt 9px/600 padding 3×7，选中白字蓝底。

**诚实口径 note-box**：bg `rgba(61,127,168,.07)` r8 padding 9×10；icon 13px + 文字 9.5px `--drinking` 行高 1.5，常驻。

### 3.3 状态与异常态（卡片与详情共用，5 态全覆盖）

| 态 | 视觉 |
|---|---|
| 暂无数据 | 居中 icon 26px + 标题 12/700 + 描述 10px secondary + chip muted"未绑定 RBC 胶囊" |
| 基线建立中 | 同布局 + chip drinking"2 / 3 天"进度 |
| 数据补传中 | 同布局 + chip muted"离线 04:12–08:15"（黄色中性语义） |
| 加载骨架 | skeleton-line 高 10 r5 渐变动画 1.2s（大数字 56×26 + 三行渐缩） |
| 服务异常 | 红色错误卡：标题 12/700 `--danger` + 描述 10px + retry 按钮 bg `--danger` 白字 10/700 r6 padding 5×14；仅接口 5xx/超时 |

### 3.4 周边配套组件

- **体温曲线图层 chips**：9px/700 border `--border` r999 padding 3×8，选中态 border `--drinking`；三项：发热标记✓/饮水事件✓/基线（off 示范）。
- **同类对比锁定卡**（Premium）：内容 `.dim` opacity .28 + blur(1px)；居中 lock-msg（🔒 22px + 文案 10px + 升级按钮 bg `--primary` 白字 10/700 r6 padding 5×14）；右上 tier-badge 8.5/700 bg `--primary-soft`。
- **二期告警行**（预埋）：图标容器 34×34 r10 bg `--drinking-soft` + emoji 16px；标题 11/700 + "二期"chip；描述 9.5px secondary；时间 8.5px。

## 4. 数据与接口契约（摘要，详约见技术方案 §6.1–6.2）

- 新表 `drinking_events`：DDL 对齐仓库惯例（`TIMESTAMP` 非 TIMESTAMPTZ、`REFERENCES` 外键、`temp_drop NUMERIC(10,2)`——#13 教训；完整 DDL 在技术方案 §6.1）；UNIQUE(device_id, event_start_at, algorithm_version)，索引 (livestock_id, event_start_at DESC)；普通表不分区（量级论证见方案）。
- API（farm-scoped，路径钉死；**四轮评审 F1：UI 每个数字必须有端点字段来源，见原型数据溯源表**）：
  - `GET /api/v1/farms/{farmId}/livestock/{livestockId}/drinking-events?from=&to=`——事件明细。
  - `GET /api/v1/farms/{farmId}/livestock/{livestockId}/drinking-summary?date=&days=1|7|30`——**一个端点三层口径**：`daily`（当日次数 + 事件时刻列表）、`weekly`（days=7 时：周合计/日均）、`rolling30dBaseline`（30 日日均 + 有效样本天数 `sampleDays`）。
  - `GET /api/v1/farms/{farmId}/livestock/{livestockId}/drinking-peer-comparison`——同类均值对比；**Premium 端点：服务端校验订阅档位**（对齐项目既有订阅校验机制——T5 实施前核实具体复用点，不依赖客户端 `subscription_tier` 判断）；分组定义（P1 口径）：同牧场 + 同品种（`livestock.breed`）+ 同生理阶段（`currentStage`）+ 近 30 日有效样本 ≥5 天；返回 `peerAvgPerDay` + 分组元数据（样本头数/口径说明）。
- **聚合口径（F4 裁决，两层分开定义防对不上账）**：
  - 日柱/周合计 = 各日**检出事件数直接求和**（含发热日低值——那是真实生理反应，由 context-note 解释；"未计入异常"精确化为"**发热期数据不参与异常判定与基线计算**"）；
  - 30 日基线与同类均值 = **剔除发热窗口覆盖 ≥50% 的日**后计算（发热期检出数被排除机制压低，不具统计代表性），`sampleDays` 记录有效样本天数。
- **牛日边界（F5）**：检测器的 μ/σ 按"日"切——**牛日 = Asia/Shanghai 日历日**（与 B3 手动录入时区一致），夜间跨午夜饮水按本地日归属，不按 UTC 劈日。
- **重算删除语义（F6）**：日批重跑与手动回算 = 先 `DELETE WHERE device_id=? AND event_start_at >= from−1h AND event_start_at < to+1h` 再插入（1h 漂移余量，配置 `health.drinking.recalc-overlap-hours:1`）——防补传 recordedAt 漂移绕过 UNIQUE 键产生重复行。
- 检测器与统计参数**全部配置化**（`health.drinking.*`，F3：魔法数不入 UI 当权威）：`baseline-min-days:3`（基线最少有效天数，默认 3，标定复核）、`recalc-overlap-hours:1`、`recovery-window-min:120`、`merge-gap-min:15`、`k-sigma:0.5`、`fall-threshold:0.06`（°C/min，Δt 归一）、`recovery-ratio:0.7`；两判据组合（FallST 斜率 ∧ 逐牛逐日 μ−kσ）+ 回升确认 + 15min 合并；参数定值见 §14（Aubé 开放数据集 L1 标定，2026-10-05）。
- 排除窗口：发热 episode/退热 6h 缓冲——由 `PhysiologyQueryPort.activeWindows` 读时合并产出（处置单侧）∪ `TEMPERATURE_ABNORMAL` 告警窗口拼装（`AlertBrief` 已自带 `createdAt/resolvedAt`，RanchQueryPort:41，**零 DTO 改动**）。
- **source 语义（用户裁决 2026-10-05：基于仿真数据实现功能）**：检测处理全部 source 的温度点（含 DATAGEN），事件**保留温度点 source 标记**——仿真事件可演示、可统计展示，但按 source 可区分、永不与真实数据混算对外效果口径（AGENTS 红线"仿真不得冒充效果验收"不变，禁的是冒充、不是使用）。原"DATAGEN 不入库"条款废止，替换为本条。
- 调度：`DrinkingEventScheduler` cron 默认 `0 40 3 * * *` + enabled 开关，**走共享调度池**（`SchedulerPoolConfig` 全局唯一显式 taskScheduler 8 线程 + 心跳探针兜底；不新建 scheduler bean——多 bean 混杂正是 09-30 静默死亡根因注释点名的模式，且 `@Scheduled` 无法路由第二个 bean）。

## 5. i18n

首批 12 组 key（ZH/EN 全表见原型说明面板 3b）：`health.drinking.title/todayCount/lastDrink/minutesAgo/weekBars/peerBaseline/feverContext/detail.title/timeDistribution/tempOverlay/honestyNote/state.*`。ARB 双语同步，`flutter gen-l10n` 零缺失。

**生理记录侧（B1，首批 14 组）**：

| key | 中文 | English |
|---|---|---|
| `health.physiology.title` | 生理记录 | Physiology Records |
| `health.physiology.stageLactating` | 泌乳期 · 第 {n} 天 | Lactating · day {n} |
| `health.physiology.stageDry` | 干奶期 | Dry off |
| `health.physiology.event.calving` | 产犊 | Calving |
| `health.physiology.event.breeding` | 配种 | Breeding |
| `health.physiology.event.pregnancyCheck` | 妊娠检查 | Pregnancy check |
| `health.physiology.event.dryOff` | 干奶 | Dry-off |
| `health.physiology.event.illness` | 发病 | Illness onset |
| `health.physiology.event.recovery` | 康复 | Recovery |
| `health.physiology.addRecord` | ＋ 记录 | + Add record |
| `health.physiology.sheetTitle` | 新增生理记录 | New physiology record |
| `health.physiology.occurredDate` | 发生日期 | Date occurred |
| `health.physiology.noteHint` | 备注（选填，≤500 字）… | Note (optional, ≤500 chars)… |
| `health.physiology.empty` | 尚无生理记录，点"＋ 记录"开始建档 | No records yet — tap "+ Add record" to start |

来源 chip 复用既有文案（手工录入/处置单 #n）；错误态文案复用饮水侧 `state.error` 句式。

**后端 messages（B1 加重项，第二轮评审坐实；惯例 = `ApiException(VALIDATION_ERROR, "key")` + `messages_zh/en.properties` 双语，范本 error.epidemic\*）**：

| key | 中文（messages_zh） | English（messages_en） |
|---|---|---|
| `error.physiology.livestockRequired` | 请指定牲畜 | Livestock is required |
| `error.physiology.livestockNotFound` | 牲畜不存在或不属于当前牧场 | Livestock not found in this farm |
| `error.physiology.eventNotFound` | 生理记录不存在 | Physiology record not found |
| `error.physiology.readOnlySource` | 手工事件才可编辑或删除 | Only manual records can be edited or deleted |
| `error.physiology.futureDate` | 发生日期不能晚于今天 | Date occurred cannot be in the future |
| `error.physiology.noteTooLong` | 备注不能超过 500 字 | Note must not exceed 500 characters |

## 6. 验收标准（上篇）

1. **1:1 保真**：每屏 Flutter Web 截图 vs 原型同尺寸基准图，`compare_screenshots.py` 相似度 ≥85%（区域报告无 worst-region FAIL）；人工抽查组件树/文案/数值与规格卡一致。
2. **状态覆盖**：§3.3 五态 + Premium 锁定态逐一切换验证。
3. **i18n**：`flutter gen-l10n` 无缺失、`flutter analyze` 通过、ZH/EN 切换走查。
4. **可达性**（#25）：列表→卡片 2 击、详情分节 3 击；无隐藏入口。
5. **数据口径**：DATAGEN 事件带 source 标记入库（§4 source 语义，演示可用）；发热窗口不产事件（构造含发烧序列的集成测试）；新端点 curl 真实数据冒烟（#25）。
6. **编译/测试**：后端编译 + 目标测试全绿（对比既有失败基线不扩大）。

---

# 下篇：生理事件流 P1（数据模型 + 统一端口 + 录入 UI）

## 7. 目标

建立项目统一的生理状态载体：**生理事件流 + 投影查询**，一次覆盖生病窗口（联动处置单）、发情历史、分娩窗口、泌乳分层四个下游需求。否决项：livestock 散点字段（一致性无人管）；完整状态机引擎（过重）。

## 8. 数据模型（Flyway 迁移）

```sql
CREATE TABLE physiology_events (
    id          BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    event_type  VARCHAR(24) NOT NULL CHECK (event_type IN ('CALVING','BREEDING','PREGNANCY_CHECK','DRY_OFF','ILLNESS','RECOVERY')),
    occurred_at TIMESTAMP NOT NULL,      -- 手工日历日期按 Asia/Shanghai 当日零点转 UTC 存（B3；Instant 由应用层写，与 #17 同向）
    source      VARCHAR(24) NOT NULL CHECK (source IN ('MANUAL','ALERT_CONFIRM')),  -- 读时合并后无处置单来源行（N3）
    ref_id      BIGINT,                  -- ALERT_CONFIRM 时 = 告警 id
    note        VARCHAR(500),
    created_by  BIGINT REFERENCES users(id),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_by  BIGINT REFERENCES users(id),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_physiology_events_livestock ON physiology_events (livestock_id, occurred_at DESC);
-- ILLNESS/RECOVERY 语义（A1 裁决）：手动生病窗口的结束权威 = 配对 RECOVERY（栈式），无 ended_at 列，append-only 单一事实源。
-- 处置单侧不落本表——读时合并（§9，N3），无投影行故无投影幂等索引。
-- 防重（A2）：手工来源按 livestock+type+date 幂等（partial unique，仓库惯例范本 uq_epidemic_disposition_active_livestock）
CREATE UNIQUE INDEX uq_physiology_manual_dup ON physiology_events (livestock_id, event_type, occurred_at, source) WHERE source = 'MANUAL';
```

**ILLNESS/RECOVERY 语义（A1 裁决）**：生病窗口的结束**只有一种权威表示——配对的 RECOVERY 事件**，不存在第二机制。`activeWindows` 推导规则：一条 ILLNESS 的窗口结束 = 其后（occurred_at ≥ 发病时刻、同牲畜）**最近的 RECOVERY** 的 occurred_at；无配对 RECOVERY → 窗口持续到查询上界 to。RECOVERY 自身不构成窗口。配对按 occurred_at 排序栈式匹配（先发病后康复；乱序录入按时间排序归位）。录入 UI 相应简化：录"发病"时**没有**结束日期字段（自然消解 A1 连带问题），康复日后补录"康复"事件即可。

种子：demo 牧场 2 头成母牛各 1 条 CALVING 事件（source=MANUAL）。

## 9. 领域端口（下游唯一入口）

```java
public interface PhysiologyQueryPort {
    /** 牲畜在 [from, to) 内的生理窗口（配对推导规则见 §8 ILLNESS/RECOVERY 裁决） */
    List<PhysiologyWindow> activeWindows(Long livestockId, Instant from, Instant to);
    /** farm 级批量（B4，供 T4 每日批避免逐头 N+1）：全群生理窗口，按 livestock 分组 */
    Map<Long, List<PhysiologyWindow>> activeWindowsForFarm(Long farmId, Instant from, Instant to);
    /** 当前生理阶段投影：泌乳期/干奶期（由最近 CALVING/DRY_OFF 推导），供分层口径 */
    Optional<PhysiologyStage> currentStage(Long livestockId);
}

/** 窗口 DTO（C2）——sourceType 区分窗口出处（非表枚举） */
public record PhysiologyWindow(
        PhysiologyEventType eventType,   // 本端口只产出 ILLNESS 窗口（P1 范围）
        Instant occurredAt,              // 窗口起点
        Instant endedAt,                 // null=持续到查询上界
        String sourceType,               // MANUAL（配对 RECOVERY）| DISPOSITION（读时合并）
        Long refId                       // DISPOSITION 时 = epidemic_dispositions.id
) {}

/** 阶段投影 DTO（C2） */
public record PhysiologyStage(PhysiologyStageType type, Instant since) {}
public enum PhysiologyStageType { LACTATING, DRY }   // P1 只推导这两态；妊娠/空怀进 P2
// 泌乳期长度 305 天为配置 health.physiology.lactation-length-days:305（F7：行业标准值非常数真理，可调）
```

**读时合并实现（N3 架构裁决，化解 N1/N2）**：`activeWindows` 实现 = 两路 UNION——
1. **手动路**：`physiology_events` 中 source='MANUAL' 的 ILLNESS，按 §8 规则配对 RECOVERY 推导窗口；
2. **处置单路**：JOIN `epidemic_dispositions` WHERE `status IN ('PENDING','IN_PROGRESS')`（活动窗口，起点=created_at）；COMPLETED → 以 completed_at 为止的历史窗口；CANCELLED（含 `cancelActiveBySource` 的 SOURCE_UNMARKED 软删）→ **无窗口**，天然一致。

处置单自身已有完整生命周期（4 个状态转移口、幂等创建、软删），**不在 physiology_events 双写**——零钩子、零同步点、处置单未来新增状态转移自动被覆盖；"唯一载体"弱化为"统一端口"（下游只见端口，符合本意）。窗口 sourceType 标记出处，便于下游标注/审计。
- healthStatus 死字段处置：P1 标记 `@deprecated`（javadoc 注明"以 PhysiologyQueryPort/告警为准"），不做数据迁移。

## 10. 录入 UI（牲畜详情页"生理记录"卡，小原型 `physiology-events-p1-prototype.html` v1.1）

- 卡片：最近 3 条事件行（类型图标+名称+日期+来源 chip）+ "＋ 记录"按钮；视觉语言复用方案 D 卡片规格（白卡 r12 shadow-card padding12，行间发丝线）。**语义色裁决（B5）：生理记录走品牌绿（色点/选中 chip 用 `--primary`、图标底用 `--primary-soft`），不走水蓝**——与饮水卡（水蓝）在详情页并存时语义分明；"窗口中"chip 沿用 `--fever` 橙（生病语义）。
- 录入 bottom sheet：事件类型 6 chips（单选，品牌绿选中态）+ 日期选择（默认今天，**按 Asia/Shanghai 当日零点转 UTC 存储**，B3）+ 备注框（≤500 字）+ 保存按钮（`--primary` 主按钮）。录"发病"**无结束日期字段**——康复日后录"康复"事件（A1 语义，见 §8）。
- **CRUD 全量（A2）**：
  - `POST` 创建（服务端先查 partial unique 同约束防重，双击保存幂等返回已有行）；
  - `PUT /{id}` 编辑——**仅 MANUAL 来源**可编辑（occurred_at/note）；投影来源（EPIDEMIC_DISPOSITION）由处置单驱动，不开放手编，返回 409；
  - `DELETE /{id}`——仅 MANUAL 来源可删；投影来源返回 409（由处置单 cancel 驱动）；
  - `GET` 列表（卡片最近 3 条）+ 端口查询（§9）。
- **状态覆盖（A3，对齐饮水侧 5 态口径）**：①正常态；②空态（新牲畜零事件：居中 icon+文案"尚无生理记录"+引导）；③加载骨架（同饮水侧样式）；④错误态（接口 5xx/超时，红色+重试）；⑤权限降级形态（角色无写权限时隐藏"＋ 记录"按钮，列表仍可读）。
- **权限（B2，已核实代码后修正措辞）**：OWNER / B2B_ADMIN / WORKER 三角色**均可写**——对齐 `AlertController` 日常处置端点惯例（dismiss/handle 为三角色，仅 archive 收紧两角色）；VIEWER 类只读角色走权限降级形态。

## 11. 验收标准（下篇 P1）

1. 迁移在全新库跑通（含 seed）；CRUD 全走 farm-scoped 校验（POST/PUT/DELETE/GET，投影来源写操作返回 409）。
2. `activeWindows` 集成测试（**读时合并**四场景）：手动 ILLNESS 持续中（无 RECOVERY）/手动配对结束/**处置单 PENDING·IN_PROGRESS→活动窗口、COMPLETED→completed_at 止**/CANCELLED（含 SOURCE_UNMARKED）→无窗口。
3. 防重集成测试：MANUAL 同牲畜同类型同日期二次保存幂等返回已有行（partial unique 兜底）。
4. 录入 sheet ZH/EN 走查、日期边界（未来日期拒绝；时区 Asia/Shanghai 零点语义用跨日单测锁定）。
5. 生理卡五态 + 权限降级形态逐一切换验证（对齐饮水侧状态覆盖口径）。
6. 饮水检测排除窗口的切换点以接口签名为准（P1 未上线前饮水检测用告警窗口，不互相阻塞）。

---

## 12. 实施拆分（串行；批准后执行）

| Task | 内容 | 验证 |
|---|---|---|
| T1 | 生理事件流 P1：迁移+领域模型+端口+录入 UI（下篇先行——它是排除窗口的地基） | 全新库迁移 + 端口集成测试 |
| T2 | L1 标定（Aubé 开放数据集，Python 独立脚本） | F ≥ 0.90，参数定值回填本 spec 附录 |
| T3 | drinking_events 迁移 + 检测服务 + 排除窗口（接 PhysiologyQueryPort） | 编译 + 真库集成测试（含发烧序列假阳性用例） |
| T4 | 调度器 + 手动回算 API | dev 部署真实回放冒烟（curl #25） |
| T5 | API + Flutter 组件（规格卡→组件库克隆→截图对照）+ i18n | compare_screenshots ≥85% + gen-l10n/analyze |
| T6 | L2 回放报告（真实通道，频次量级对照） | 报告落 docs/research |
| T7 | 部署 dev → 用户集成测试 → L3 试点方案 | 用户验收 |

## 13. Linear 工单

合并单：**NIX-256**（https://linear.app/nix-agentic/issue/NIX-256 ，priority High，Backlog）——范围/约束/文档索引见工单描述；spec 确认后进 plan。

## 14. 参数定值（T2 L1 标定回填，2026-10-05）

数据集：Aubé et al. 2025（DOI 10.57745/H2SPNR，Etalab 2.0 许可，28 牛 × 96h × **5-min** 采样 + 730 视频标注）。三方法复现 |ΔF| ≤ 1pp 贴住论文后完成网格标定。报告：`docs/research/2026-10-05-drinking-l1-calibration-report.md`。

| 配置键 | 定值 | 依据（5-min，N=730） |
|---|---|---|
| `fall-threshold` | **0.06** °C/min（Δt 归一：`fall/Δt_min ≥ 0.06`；等效步降幅 5-min 0.30°C / 6-min 0.36°C / 10-min 0.60°C） | 网格下限最优 F=0.9400；Δt 归一后 6/10-min 迁移损失 0.10pp/1.30pp |
| `k-sigma` | **0.5** | k 轴单调下降（0.5→0.9400、1→0.9346、2→0.9010、3→0.8317）；原"k=10（Vázquez 2019）"为活动判定语境值，已废弃；k>2 告警 |
| `recovery-ratio` | **0.7** | L1 近乎不敏感（0.5~0.8 差 ≤0.15pp），防御性默认；L2 发烧/离体"降而不回"形态主防线 |
| `recovery-window-min` | **120** | Cantor 最冷组恢复 103min |
| `merge-gap-min` | **15**（原 30 改定） | 敏感性扫描 gap={0,10,15,20,25,30}→F={82.45,93.76,**94.00**,93.90,93.27,92.65}；原 30 系对 Aubé"30 min apart"（分辨下限）的误读，压 Se 于 86.7% 天花板；gap=0 FP 洪水（211）证明合并必须存在 |
| `baseline-min-days` | **3** | 维持原值，标定复核通过 |
| `recalc-overlap-hours` | **1** | 维持原值（F6） |

组合检测器（FallST ∧ μ−kσ + 回升确认 + 15min 合并）：**5-min F=0.9400**（TP 650/FP 3，Se 89.0%/PPV 99.5%）、6-min 0.9390、10-min 0.9270——门禁 F≥0.90 达成。数据勘误：饮水信号在 `ruminal_temperature` 列（corrected 列已被平滑）；我们平台 `temperature_logs` 存原始通道温度，同口径无此问题。

### §14.1 生产口径转正（评审 B1/M1/M3 收口，2026-10-05）

L1 标定口径（上表）与生产内核（Java）存在三处实现差异：①深度判据——标定为"低于 μ−kσ 即过（任意裕度）"，内核为"谷底低于 μ−kσ **再低 ≥1.0°C**"（rDepth≥1）；②内核带 35–43°C 离体门卫（Aubé 深谷 4.47% 点 <35°C，谷底被截断）；③斜率取下降段内最大速率而非触发对速率。**生产口径全网格重跑**（`calibrate.py --merge-gap 15 --in-body-gate --depth-margin 1.0`，结果 `output/drinking-l1/results-production/`）：

| 间隔 | 生产口径 F | 门禁 |
|---|---|---|
| 5-min | **0.928**（TP 632/FP 0/FN 98，Se 86.6%/PPV 100%） | ✓ |
| 6-min | **0.9209** | ✓（平台有效分辨率档） |
| 10-min | 0.8756 | ✗（低于门禁；平台无此粗档，如实记录） |

**裁决：内核判据保留**（5/6-min 平台运行档门禁通过）；1.0°C 深度门槛与离体门卫自此为正典判据的一部分；Se 由 89.0% 降至 86.6%（裕度+门卫的量化代价）。复现命令入库可重跑（M3 一并收口：`grid_results_gap15.csv` 的内联生成器已被 `--merge-gap` 参数取代）。R_th 在生产口径下 0.5 略优（0.928 vs 0.9153@0.7），维持 0.7 不变（邻域内差异 1.3pp，防御性中心档）。

> **合并锚定勘误（T6 回放发现，2026-10-05）**：`mergeEvents` 的 javadoc 自述 "consecutive starts"，实现却把间距比较锚在**合并链首 start** 上——长缓降谷（下跌段 >merge-gap）会被按 merge-gap 整数倍机械切成幻影次事件（+15min、共享谷底、drop 显著小）。已改为**滚动锚定**（比较上一成员自身 start，Java 与 Python 检测器双侧同修）；Aubé 数据全网格重跑逐数一致（陡降单谷对此语义不敏感，故 B1 平价未曾暴露），30 天仿真回放（docs/research/2026-10-05-drinking-l2pre-replay-report.md）中该缺陷曾致 PPV 0.795 → 修复后见报告。

## 15. 反馈标定闭环（用户裁决 2026-10-05：仿真实现 + 标记修正参数）

三原则：①功能基于仿真数据即可跑通演示（§4 source 语义）；②系统具备"标记 → 修参数"的闭环能力；③标记来源双通道——系统自动发现 + 牧场主手动。

### 15.1 数据模型（并入 drinking_events，T3 一并建表）

| 列 | 语义 |
|---|---|
| `source` | 事件来源温度点的 source 透传（DATAGEN/THINGSBOARD/AGENTIC_PLATFORM/MANUAL_IMPORT…）+ 两个新枚举值：`MANUAL`（牧场主补录的漏报）、`ALGORITHM_CANDIDATE`（系统自动发现的疑似漏报候选，见 15.2） |
| `label` | `UNLABELED` / `CONFIRMED`（确认真饮水）/ `REJECTED`（判误报）；默认 UNLABELED |
| `confidence` | 事件置信度 0~1（纯函数：降幅、斜率、回升比对各自阈值的裕度归一合成，检测时写入） |

### 15.2 标记通道

**牧场主手动（写 API + T5 UI 行级操作）**：
- `PATCH /api/v1/farms/{farmId}/livestock/{livestockId}/drinking-events/{id}/label` body `{label: CONFIRMED|REJECTED}`；
- `POST .../drinking-events/manual` body `{eventStartAt, note?}`——补录漏报（source=MANUAL、label=CONFIRMED）；
- 权限同生理事件（OWNER/B2B_ADMIN/WORKER 可写）。

**系统自动发现（检测批产出，零人工）**：
- 每事件写 confidence；低于 `health.drinking.low-confidence:0.5` 呈现为"待核实"（UI 低置信标记）；
- **borderline 候选**：未过判据但各判据达阈值 50% 裕度内（配置 `health.drinking.candidate-tolerance:0.5`）的温度谷落 `source=ALGORITHM_CANDIDATE` 行——不计入统计、不算事件数，进"待标记"队列；牧场主确认后 label=CONFIRMED 转正参与统计，忽略则重算窗口清理。

### 15.3 统计口径（F4 聚合规则细化）

- 日柱/周合计/30 日基线：`label != REJECTED && (source != ALGORITHM_CANDIDATE || label == CONFIRMED)` 参与计数（检出默认计、误报剔除、补录计入、未确认候选不进、**确认候选转正计入**——与 §15.2 转正语义一致，修订于 T3 评审）；
- 参数评估口径（离线）：全部 label 参与——CONFIRMED=TP 真值、REJECTED=FP 真值、MANUAL 补录=FN 真值、CANDIDATE 经裁决后归位。

### 15.4 参数修正闭环（离线工具，P1 不做自动改参）

- 标签导出：`GET /api/v1/admin/drinking-labels/export?from=&to=`（CSV：事件字段+label+confidence+检测上下文），管理员权限；
- `calibrate.py --labels <export.csv>` 新模式：在标签集上重算参数网格的 Se/PPV/F，输出**建议参数**报告——运维据此改 `health.drinking.*` 配置；
- 采信门槛：单牧场 CONFIRMED+REJECTED 合计 ≥100 条方出建议，报告注明样本量；自动调参列 P2（需护栏设计）。
- **与 AI 平台的关系（用户裁决 2026-10-05）**：P1 刻意用确定性统计（网格搜索）而非 AI 平台——参数仅 3~4 标量、可解释是硬需求、频率季度级。P1 同时铺好三个衔接点：标签数据集（未来 ML 的训练/评估集）、导出端点（平台取数口）、`health.drinking.*` 配置面（平台建议参数的生效通道）；标签量达数千级且全群单组参数表达不了异质性时，`--labels` 逻辑平移为平台任务（仿 `AnomalyScoreClient` HTTP 端口 + 降级模式），P1 资产零返工。
- **标签跨重算保留**：日批/手动重算的删除范围 = `source NOT IN ('MANUAL') AND label 语义可重建`——具体为：只删算法产物行（透传 source 的检出与 ALGORITHM_CANDIDATE），**MANUAL 行永不删**；重插后按 `(device_id, event_start_at)` 匹配回填删除前的 label（CONFIRMED/REJECTED 不因重算丢失）。

### 15.5 与验证阶梯的关系

本节闭环在仿真数据上先行跑通（功能+标记+导出+重标定全链路演示）；真实设备数据接入后**同一套机制无缝切换**（标记 UI 与导出与 source 无关）；L3 试点（水表/摄像头）= 最高质量标记来源。对外效果口径仅采用真实 source 事件的标签统计——AGENTS 红线不变。
