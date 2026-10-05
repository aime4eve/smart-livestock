# 规格卡 · DrinkingCard（屏 1：牲畜详情页 · 健康 Tab）

> 来源：`docs/prototypes/drinking-event-detection-prototype.html` v1.3（UI 唯一事实源，已冻结）
> 令牌：`docs/design-tokens.md`（34 枚）。硬规则：数值一律以本卡与令牌表为准，不得猜值。
> 挂载点：牲畜详情页健康 Tab，与体温/瘤胃蠕动/发情三张趋势卡同级追加（主入口，2 击可达）。

## 组件树

```
DrinkingCard (card)
├── drinking-card-head
│   ├── title: dot(8×8 --drinking) + "饮水行为" (fs12 fw700)
│   └── chip.drinking "今日 7 次"
├── bignum-row (baseline, gap6)
│   ├── bignum "7" (fs30 fw800 --drinking lh1)
│   ├── bignum-unit "次 / 今日" (fs11 secondary)
│   └── last-drink (ml-auto, 右对齐)
│       ├── label "上次饮水" (subtle fs11)
│       └── v "35 分钟前" (fs12 fw700 text-primary)
├── mini-bars (h44, mt10, gap6, padding 0 2px)
│   └── ×7 bar-wrap (flex1, col, center, gap3)
│       ├── val "8" (fs8 fw700 secondary)
│       ├── bar (h=值映射, r 4/4/2/2, bg --drinking opacity .85; low→bg --fever opacity .55)
│       └── day "一" (fs8 secondary)
├── 副标 (subtle, mt8) "同类成母牛均值 7.3 次/日 · 本牛近 30 日基线 7.6 次/日"
└── context-note (mt10) 发热上下文条
    ├── ic 🌡️ (fs11 lh1.3)
    └── tx (fs9.5 --fever lh1.45)
```

## 数值表（原型 CSS 逐条提取）

| 元素 | 属性 | 值 |
|---|---|---|
| .card | 容器 | bg `--surface-alt`(#FFFFFF)、r `--radius-md`(12)、shadow `--shadow-card`、padding 12 |
| .drinking-card-head | 布局 | flex space-between、margin-bottom 10 |
| .title | 文字 | fs12 fw700、gap6（含 8×8 圆点） |
| .chip.drinking | chip | bg `--drinking-soft`(#E2EDF4)、color `--drinking`(#3D7FA8)、fs10 fw600、r999、padding 3×8、gap4 |
| .bignum | 大数字 | fs30 fw800、color `--drinking`、line-height 1 |
| .bignum-unit | 单位 | fs11、color `--text-secondary` |
| .last-drink .v | 值 | fs12 fw700、color `--text-primary` |
| .mini-bars | 容器 | flex align-end、gap6、height 44、margin-top 10、padding 0 2px |
| .bar | 柱 | width 100%、border-radius 4 4 2 2、bg `--drinking` opacity .85 |
| .bar.low | 发热日柱 | bg `--fever`(#D97B29) opacity .55 |
| .val / .day | 轴标 | fs8；val fw700；均 `--text-secondary` |
| 副标 .subtle | 文字 | fs11、`--text-secondary`、lh1.45、margin-top 8 |
| .context-note | 容器 | bg rgba(217,123,41,.08)、r8、padding 7×8、margin-top 10、gap6 |
| .context-note .tx | 文字 | fs9.5、`--fever`、lh1.45 |

柱高映射（原型示例）：8→32px、7→28px、9→38px、6→24px、3→12px、8→32px、7→28px（约 4px/次线性）。

## 数据溯源（UI 数字 → 端点 → 字段，原型 3c）

| UI 元素 | 端点 | 字段/规则 |
|---|---|---|
| 今日 7 次 | `GET .../drinking-summary?date=&days=1` | `daily.count` |
| 上次饮水 35 分钟前 | drinking-summary | `daily.events` 最后一条 `event_end_at`（前端算相对时间） |
| 近 7 日柱值 8/7/9/6/3/8/7 | `drinking-summary?days=7` | 按牛日（Asia/Shanghai）分日计数；发热日低值照实 + 染橙 |
| 本牛近 30 日基线 7.6 | `drinking-summary?days=30` | `rolling30dBaseline.avgPerDay`（剔除发热覆盖 ≥50% 的日）+ `sampleDays` |
| 同类成母牛均值 7.3 | `GET .../drinking-peer-comparison`（Premium） | `peerAvgPerDay` + 分组元数据 |

## 文案表（ZH/EN）

| key | 中文 | English |
|---|---|---|
| health.drinking.title | 饮水行为 | Drinking Behavior |
| health.drinking.todayCount | {n} 次 / 今日 | {n} today |
| health.drinking.lastDrink | 上次饮水 | Last drink |
| health.drinking.minutesAgo | {n} 分钟前 | {n} min ago |
| health.drinking.weekBars | 近 7 日 | Last 7 days |
| health.drinking.peerBaseline | 同类{stage}均值 {n} 次/日 · 本牛基线 {m} 次/日 | {stage} peer avg {n}/day · own baseline {m}/day |
| health.drinking.feverContext | {date} {n} 次：当日 {range} 处于发热期，发热期间饮水减少属常见现象；发热期数据不参与异常判定与基线计算 | {date}: {n} visits during fever episode ({range}) — reduced drinking is expected during fever; fever data excluded from anomaly detection and baselines |
| health.drinking.state.noData | 暂无饮水数据 | No drinking data yet |
| health.drinking.state.building | 基线建立中 | Building baseline |
| health.drinking.state.backfill | 数据补传中 | Backfilling |
| health.drinking.state.error | 饮水数据暂时不可用 | Temporarily unavailable |

> 注：feverContext 以原型 DOM v1.3 文案为准（F4 精确句式"发热期数据不参与异常判定与基线计算"），说明面板 3b 旧句"未计入异常"已被四轮评审替换。UI 不含学术引用（F3）。

## 元素清单（DOM 一一对应，可勾）

- [ ] 卡片容器（card：白底 r12 shadow-card padding12）
- [ ] 头行：8×8 水蓝圆点 + 标题 fs12 fw700 + 右侧水蓝 chip"今日 N 次"
- [ ] 大数字行：30px/800 水蓝数字 + 单位 11px + 右对齐"上次饮水"标签/值
- [ ] 迷你柱状：7 列 gap6 h44，柱 r4/4/2/2，正常水蓝 .85 / 发热日橙 .55，列值+星期 8px
- [ ] 双参照副标（同类均值 · 本牛基线，11px secondary）
- [ ] 发热上下文条（橙 .08 底 r8，🌡️ + 9.5px 橙字）——仅当日/近 7 日含发热日时出现
