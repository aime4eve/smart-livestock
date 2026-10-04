# 规格卡 · 状态态 + 图层 chips + 锁定卡 + 告警行（屏 3–6）

> 来源：`docs/prototypes/drinking-event-detection-prototype.html` v1.3。
> 覆盖：5 状态态（卡片与详情分节共用）、体温曲线图层 chips（屏 4）、同类对比锁定卡（屏 5，Premium）、二期告警行（屏 6 预埋）。

## 一、状态与异常态（5 态，§3.3）

```
state-card (card, col center, padding 18×12, gap8)
├── big-ic (fs26 emoji)
├── t (fs12 fw700)
├── d (fs10 secondary lh1.5)
└── chip（muted / drinking）
```

| 态 | big-ic | t | d | chip |
|---|---|---|---|---|
| 暂无数据 | 📭 | 暂无饮水数据 | 该牲畜尚未绑定瘤胃胶囊，绑定后约 24 小时内建立基线并开始统计 | muted「未绑定 RBC 胶囊」 |
| 基线建立中 | 🧮 | 基线建立中 | 已积累 2 天数据，检测算法需 ≥3 天有效数据才能可靠区分饮水谷与体温波动 | drinking「2 / 3 天」 |
| 数据补传中 | 📡 | 数据补传中 | 网关离线 4 小时，设备本地缓存将自动补传，期间统计可能有延迟 | muted「离线 04:12–08:15」 |
| 加载骨架 | — | — | — | — |
| 服务异常 | — | （err-card 见下） | — | — |

**加载骨架**（card 内）：大数字区 `skeleton-line` 56×26 + 单位 48×10；三行渐缩 100% / 88% / 64%（h10 r5）；渐变 `linear-gradient(90deg, var(--surface) 25%, #ECE9E1 50%, var(--surface) 75%)` background-size 200%、动画 1.2s infinite。

**服务异常 err-card**（红色，仅接口 5xx/超时）：head「⚠️ 饮水数据暂时不可用」fs12 fw700 `--danger`；d fs10 secondary lh1.55；retry 按钮 bg `--danger` #fff r6 fs10 fw700 padding 5×14。与"数据补传中"（黄色中性态）严格区分。

**切换条件**：未绑定胶囊→noData；绑定后 <3 有效天→building（chip 显示 n/3，3=配置 `health.drinking.baseline-min-days`，F3 非魔法数）；网关离线补传→backfill；5xx/超时→error。

## 二、体温曲线图层 chips（屏 4）

挂载点：既有体温趋势卡（fl_chart LineChart）以图层模式叠加饮水谷标记，与发热标记同层级；双向联动（谷点↔详情分节同时段）。

```
layer-chips (flex gap6 mt8 wrap)
└── ×3 layer-chip: sw(7×7 圆点) + 文案
    ├── on: color text-primary、border-color --drinking
    └── off: color --text-secondary、border --border
```

| 元素 | 属性 | 值 |
|---|---|---|
| .layer-chip | chip | fs9 fw700、r999、padding 3×8、gap4、bg `--surface-alt`、border 1px `--border` |
| .layer-chip .sw | 色点 | 7×7、r50%；发热 #D97B29 / 饮水 #2C6486 / 基线 #617061 |
| .layer-chip.on | 选中态 | color `--text-primary`、border-color `--drinking` |

三项默认全 on（F2：三图层默认全开）：发热标记 ✓ / 饮水事件 ✓ / 基线 ✓。

## 三、同类对比锁定卡（屏 5，Premium）

```
chart-card.locked-overlay
├── tier-badge「Premium+」(absolute top8 right8)
├── .dim (opacity .28 + blur 1px)
│   ├── chart-title「📊 同类成母牛均值对比」
│   └── chart-area (h80) 灰绿柱状 (#8BA95A)
└── .lock-msg (absolute inset0, col center, gap6)
    ├── lock-ic 🔒 (fs22)
    ├── lock-tx (fs10 secondary center padding 0 16 lh1.5)
    └── upgrade-btn「升级解锁」
```

| 元素 | 属性 | 值 |
|---|---|---|
| .dim | 淡化 | opacity .28、filter blur(1px) |
| .lock-msg | 居中层 | absolute inset0、col center、gap6 |
| .lock-ic | 图标 | fs22 |
| .lock-tx | 文案 | fs10、`--text-secondary`、居中、padding 0 16、lh1.5 |
| .upgrade-btn | 按钮 | bg `--primary` #fff、r6、fs10 fw700、padding 5×14 |
| .tier-badge | 角标 | fs8.5 fw700、bg `--primary-soft`、color `--primary`、r999、padding 2×7、absolute top8 right8 |

上方"本牛近 7 日"卡（全订阅可用）：7 柱 #3D7FA8（发热日 #D28A2D opacity .55）、副标「周合计 48 次 · 日均 6.9 次 · 较本牛基线 −9%」（周合计/日均=weekly.count/avgPerDay；−9%=前端计算 weekly.avgPerDay vs rolling30dBaseline.avgPerDay）。

## 四、二期告警行（屏 6 预埋，DRINKING_ABNORMAL）

```
card > al-row (flex start gap9)
├── ic 💧 (34×34 r10 bg --drinking-soft center fs16)
├── body (flex1 min-w0)
│   ├── t「饮水骤减 + chip drinking『二期』(padding 1×6 fs8)」(fs11 fw700)
│   └── d (fs9.5 secondary lh1.5 mt2)
└── time (fs8.5 secondary nowrap)
```

本期仅预埋形态（屏 3 premium-strip 同文案），不触发、不入 AlertType（依赖 L3 准确率数据，AGENTS 红线：无验证不上告警）。

## 文案表（ZH/EN，状态与预埋）

| key | 中文 | English |
|---|---|---|
| health.drinking.state.noData | 暂无饮水数据 | No drinking data yet |
| health.drinking.state.building | 基线建立中 | Building baseline |
| health.drinking.state.backfill | 数据补传中 | Backfilling |
| health.drinking.state.error | 饮水数据暂时不可用 | Temporarily unavailable |

预埋/说明性文案（二期告警行、锁定卡升级、图层 chips 文案）在 T5 入 ARB 时按原型 DOM 原文补齐 key。

## 元素清单（DOM 一一对应，可勾）

- [ ] 5 状态态：noData/building/backfill（state-card 四件套：big-ic+标题+描述+chip）+ 骨架（56×26+三行渐缩 1.2s 动画）+ err-card（红标题+描述+retry）
- [ ] 二期预埋条（premium-strip：虚线橙边框渐变底+⚠️ 文案+"二期"chip）
- [ ] 图层 chips ×3（发热标记✓/饮水事件✓/基线✓，默认全 on，可开关）
- [ ] 谷点双向联动说明 note-box（🔗）
- [ ] 锁定卡：tier-badge 角标 + dim 内容（标题+灰绿柱状）+ 居中锁形+文案+升级按钮
- [ ] 本牛 7 日柱状卡（全订阅可用右注 + 周合计/日均/对比副标）
- [ ] 告警行：34×34 水蓝底 💧 图标容器 + 标题（含"二期"chip）+ 描述 + 时间
- [ ] 入口可达性卡（flow-step ×4：列表→详情卡 2 击→详情分节 3 击→告警二期）
