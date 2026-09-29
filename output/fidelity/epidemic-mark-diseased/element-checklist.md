# 疫病·标记患病入口 — 原型元素清单（保真基线）

> 来源：`docs/prototypes/2026-09-29-epidemic-mark-diseased-prototype.html`（唯一视觉真源，7 屏 390×844）
> 基线截图：`output/fidelity/epidemic-mark-diseased/prototype/p1.png … p7.png`（820×1728，DPR 2）
> Spec：`docs/superpowers/specs/2026-09-29-epidemic-mark-diseased-entry-spec.md`

## 0. 设计令牌（原型 `:root`，`prototype-to-flutter-fidelity` 解析源）

| 令牌 | 值 | 备注 |
|---|---|---|
| `--color-primary` | `#2F6B3B` | appbar 底、P4 主按钮底 |
| `--color-primary-dark` | `#244F2D` | P6 「了解 Premium」按钮底、价格/标题字色 |
| `--color-primary-soft` | `#E3F0E4` | 默认头像底 |
| `--color-danger` | `#C2564B` | danger 语义：标记按钮底、chip 选中描边、疫病卡描边 |
| `--color-danger-soft` | `#F6E4E2` | chip 选中底、P3 信息条底、P3 头像底 |
| `--color-warning` / `-soft` | `#D28A2D` / `#F7ECDC` | 「留意」pill、异常徽标 |
| `--color-success` / `-soft` | `#4C9A5F` / `#E3F0E4` | 「平稳」pill |
| `--color-info` / `-soft` | `#4A7F9D` / `#E2EDF3` | 弹层 hint 条 |
| `--color-surface` / `-alt` / `-muted` | `#F8F6F0` / `#FFFFFF` / `#F2F0EA` | 页面底 / 卡片·弹层底 / 未选 chip·neutral 按钮底 |
| `--color-text-primary` / `-secondary` | `#263126` / `#617061` | 主文 / 辅文 |
| `--color-border` | `#D7D2C6` | 卡片描边、输入框描边、grab |
| `--mark-chip-active-bg` | `#F6E4E2` | 本原型新增：病种选中底 = danger-soft |
| `--mark-chip-active-bd` | `#C2564B` | 本原型新增：病种选中描边 = danger |
| 间距 | xs 4 / sm 8 / md 16 / lg 24 / xl 32 | |
| 圆角 | lg 16 / md 12 / sm 8 / pill 999 | |
| 阴影 | card `0 2px 10px rgba(38,49,38,.08)`；sheet `0 -4px 24px rgba(38,49,38,.14)` | |
| 字体 | title `700 15px/1.3`；body `400 12px/1.5`；cap `400 10px/1.4` | PingFang SC |

## 通用手机框架结构（每屏一致）

- `.phone` 390×844，surface 底，radius 28，10px 深色边框 `#263126`。
- 状态栏 34px：左 `9:41`，右 `●●● 🔋`。
- appbar：primary 底白字，padding `10px 16px 12px`；左返回 `‹`（18px）、标题 15px/700、右侧辅文 11px（每屏不同，见下）。

---

## P1 · 主入口 — 牲畜详情页 + 标记弹层（`p1.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| appbar | 标题「牛只详情」，右侧「牧场」 | 返回 ‹ |
| 牛只身份卡 | avatar 42×42（primary-soft 底 / primary-dark 字）内容 `63`；编号 `SL-2024-0063`（14px/700）；meta `母牛 · 3 号围栏 · 佩戴 TB 胶囊`（10px secondary）；pill warn「留意」（warning-soft 底 / warning 字） | 静态展示 |
| 分节标题 | 竖条 bar（3×10 primary）+「健康信息」 | — |
| 健康信息卡 | 一行三列 11px secondary：`体温 39.6℃ ↑`｜`反刍 正常`｜`活动 偏低` | — |
| 动作行（未标记态，新增） | `🦠 标记疑似患病`：btn primary = danger 底白字，高 36，radius-sm，12px/700，占满整行 | OWNER/B2B_ADMIN 可见；点击呼起标记弹层 |
| 弹层 scrim | `rgba(38,49,38,.45)` 全屏遮罩 | 点击弹层外关闭 |
| 标记弹层 sheet | surface-alt 底，顶部圆角 radius-lg，padding `18px 16px 26px`，shadow-sheet | 底部弹出 |
| ├ grab | 36×4 border 色，radius 2，居中，下距 14 | 拖拽把手（视觉） |
| ├ 标题 | `标记疑似患病源头`（font-title 15px/700，居中） | — |
| ├ who | `SL-2024-0063 · 母牛 · 3 号围栏`（11px secondary，居中） | — |
| ├ 病种组标题 | `病种（单选）`（11px/700） | — |
| ├ 病种 chips | 5 枚 pill：`口蹄疫疑似`（on 态）`牛结核疑似` `布病疑似` `腹泻类疾病` `其他`；默认 surface-muted 底 / transparent 描边 1.5 / 600；选中态 = `--mark-chip-active-bg`（danger-soft）底 / danger 字 / danger 描边 / 700；padding `7px 14px`，gap 8 | 单选切换；默认全不选 |
| ├ hint 信息条 | info-soft 底 / info 字，radius-sm，padding `10px 12px`，10px/1.6；图标 `ⓘ`；文案 `标记后将立即分析该牛近 72 小时的接触轨迹，生成接触追踪与处置建议。` | 静态说明 |
| └ 双按钮 | `取消`（neutral：surface-muted 底 / secondary 字）+ `确认标记`（primary：danger 底白字）；高 42，13px/700，gap 10 | 未选病种时确认置灰（`btn:disabled` opacity .45）；确认提交标记 |

## P2 · 弹层变体 — 「其他」输入 + 成功 toast（`p2.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| 页面背景 | 同 P1 详情页（健康卡简化为空卡 min-height 120） | — |
| 病种 chips | `其他` 为 on 态（danger-soft/danger），其余默认 | 选中「其他」展开下方输入框 |
| 其他病种输入框 | 高 36，radius-sm，border 描边，padding `0 12px`，12px，surface 底；placeholder `请输入病种名称（必填）`；示例值 `牛病毒性腹泻` | 「其他」选中时必填 |
| hint / 双按钮 | 同 P1 | 同 P1 |
| toast 成功 | 居中悬浮 bottom 132，`rgba(38,49,38,.92)` 底白字 pill 圆角，padding `10px 16px`，11px；对勾 `✓` 色 `#9FD8AC`/800；文案 `已标记，接触分析完成（12 次接触）` | 提交成功后展示（12 来自后端 contactsGenerated），随后自动跳 `/twin/epidemic?sourceLivestockId=…`；contactsGenerated=0 时文案换为 `已标记，但近 72 小时无定位轨迹，接触网络为空` |

## P3 · 已标记态 — 源头徽标 + 取消确认（`p3.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| 牛只身份卡（已标记态） | avatar 转 danger-soft 底 / danger 字；pill src「疑似源头」= **danger 实底白字**（非 soft） | 静态 |
| 源头信息条 | danger-soft 底，radius-sm，padding `8px 10px`，位于身份卡内部底端；行 1 `🦠 口蹄疫疑似 · 已标记 2 小时`（10px danger/700）；行 2 `接触 12 头 · 一级处置 1 · 见「疫病防控」工作台`（9px secondary） | 数据来自牲畜维度查询（病种/标记时间/接触数） |
| 动作行（已标记态） | `查看疫病工作台`（neutral）+ `取消染病标记`（ghost：透明底 / danger 字 / danger 描边）；均高 36 | 查看跳工作台；取消呼起二次确认弹层 |
| 取消确认弹层 | grab + 标题 `取消染病标记？`；who（line-height 1.7，两行）`将同时取消 SL-2024-0063 作为源头的` `<br>` `全部未完成处置单（共 3 张）。`；按钮 `保留标记`（neutral）+ `确认取消`（danger 底白字） | 确认 → `DELETE /epidemic/mark/{id}`（后端 cancelActiveBySource 连带取消未完成处置单）后刷新 |

## P4 · 疫病工作台空态 — 「去选择病牛」（`p4.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| appbar | 标题「疫病防控」，右侧「72h 窗口」 | — |
| 空态（全屏居中，padding 0 36） | 图标 `🐾` 40px secondary opacity .55；标题 `暂无标记的疑似源头`（13px/700）；正文三行（10px secondary / 1.7）：`当前牧场还没有确认染病的牲畜。` `<br>` `从围栏页选择牛只，在详情页即可标记疑似患病，` `<br>` `系统将自动生成接触追踪与处置建议。` | — |
| 主按钮 | `去选择病牛`：**primary（#2F6B3B）底白字**（注意非 danger），自适应宽度 padding `0 22px` | 跳转围栏页牛只列表；免费用户点击走 P6 升级引导 |
| 次按钮 | `重试`：neutral，高 32，11px | 网络异常场景重试 |

## P5 · 疫病类告警 — 「标记为源头」快捷动作（`p5.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| appbar | 标题「告警中心」，右侧「健康 4」 | — |
| 疫病告警卡（EPIDEMIC） | 卡片 `border-left: 3px solid danger`；级别行 `疫病风险 · 严重`（10px danger/800）；标题 `SL-2024-0063 体温持续升高`（12px/700 text-primary）；meta `体温 39.6℃ 持续 9 小时 · 3 号围栏`（10px secondary） | — |
| ├ 告警动作区 | `查看牛只`（neutral small：高 30，11px，padding `0 12px`）+ `标记为源头`（danger 底白字 small）；margin-top 12 | 仅 EPIDEMIC 类型显示；标记为源头 → 呼起标记弹层（牛只已预填） |
| 非疫病告警卡 | opacity .55 置灰；`发热 · 警告`（warning 色/800）；`SL-2024-0071 低热`；`38.9℃ · 2 号围栏`；**无动作区** | 非 EPIDEMIC 类不显示「标记为源头」 |
| 标记弹层（来自告警） | 同 P1 共享弹层；差异点：who 为 `SL-2024-0063 · 母牛 · 3 号围栏（来自告警）`（尾部标注来源）；chips 默认 `口蹄疫疑似` on | 预填牛只，只选病种即提交；与告警「处理=已读」语义并存（标记是更强动作，不替代已读） |

## P6 · 免费用户 — 点击标记 → 升级引导（`p6.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| 牛只身份卡 | avatar `71`（primary-soft 默认态）；`SL-2024-0071`；meta `母牛 · 2 号围栏`；pill ok「平稳」（success-soft 底 / success 字） | — |
| 健康卡占位 | 卡内文案 `免费版 · 疫病防控为 Premium 功能`（10px secondary），卡 min-height 150 | — |
| 升级弹层 sheet | grab + 居中大图标 `🔒`（34px）；标题 `疫病防控需要 Premium`（16px/800 primary-dark）；说明两行（11px secondary / 1.7）`标记疑似患病、接触追踪与四级处置` `<br>` `属于 Premium 功能（epidemic_alert）。`；价格行 `$2.65`（22px/800 primary-dark）+ ` / 头 / 月`（10px secondary） | 免费用户点击标记按钮时弹出（按钮可见不隐藏，保留功能感知） |
| └ 双按钮 | `暂不升级`（neutral）+ `了解 Premium`（**primary-dark** 底白字）；高 42 | 入口挂 subscriptionController tier 判定 + checkTierAccess(FeatureFlags.epidemicAlert) |

## P7 · 概览疫病卡 — 副文两段式衔接（`p7.png`）

| 区块 | 关键元素 | 交互行为 |
|---|---|---|
| appbar | 标题「牧场」，右侧 `HKT Main Ranch ⌄` | 牧场切换 |
| 分节标题 | bar +「健康管理」 | — |
| 场景卡网格 2×2 | scene 卡：surface-alt 底 / border 描边 / radius-md / padding 10；卡间距横向 7px、行距 8px；标题行 11px/700 + 右侧 pill（9px/700 pill 圆角）；副文 `.ft` 9px secondary | 点击疫病卡进工作台（P4 空态引导） |
| ├ 发热管理卡 | `🌡️ 发热管理` + pill warn「1 只异常」；副文 `1 只发烧 · 0 只低热` | — |
| ├ 消化管理卡 | `🌾 消化管理` + pill warn「2 只异常」；副文 `2 只反刍偏低` | — |
| ├ 发情管理卡 | `💗 发情管理` + pill ok「平稳」；副文 `暂无高分个体，适合巡查` | — |
| └ 疫病防控卡（目标态） | `🛡️ 疫病防控` + pill danger「27.3%」；卡片描边 danger；**副文两段式**：`7 日异常率 27.3%` + 分隔点 `·`（border 色 `.sep`）+ `未标记源头`（**danger 色 / 700 红字**） | 判定：异常率超警戒（epiOver）且无标记源头（hasMarkedSource=false）时追加红字段；有源头时维持现有副文不动 |

---

## 保真对照挂载点盘点（收口用）

- 详情页动作行两态：P1（未标记）/ P3（已标记），同一位置两种渲染。
- 标记弹层挂载 3 处：P1 详情页入口、P5 告警卡动作（列表）、告警详情（Task 7 要求两处都挂，对照 #25）。
- toast 两态：contactsGenerated>0 / =0（P2 caption）。
- 免费引导挂载 3 处：详情页标记按钮（P6）、工作台空态主按钮（P4 caption）、告警标记动作（Task 7）。
- 概览副文两态：有/无标记源头（P7）。
