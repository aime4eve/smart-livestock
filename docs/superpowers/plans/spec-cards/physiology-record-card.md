# 规格卡 · PhysiologyRecordCard（屏 1：牲畜详情页 · 生理记录卡）

> 来源：`docs/prototypes/physiology-events-p1-prototype.html` v1.2。
> 语义色裁决（B5）：生理记录走**品牌绿**（`--primary`/`--primary-soft`），与饮水卡水蓝并存时语义分明；"窗口中"chip 沿用 `--fever` 橙（生病语义）。
> 挂载点：牲畜详情页（与饮水卡同页并存）。

## 组件树

```
PhysiologyRecordCard (card)
├── sec 头行: dot(8×8 --primary) + "生理记录"(fs12 fw700)
│   └── chip idle「泌乳期 · 第 128 天」(ml-auto)
├── ×3 ev-row (最近 3 条事件)
│   ├── ic (30×30 r9 bg --primary-soft, fs14 emoji)
│   ├── b: n 事件名 (fs11 fw700) + d 来源/备注 (fs9 secondary)
│   └── when 日期 (fs9 secondary nowrap) | chip disp「窗口中」
└── add-btn「＋ 记录」(mt9)
```

事件图标（C1 裁决）：🐮 产犊 / ❤️ 配种 / 🤰 妊娠检查 / ⏸️ 干奶 / 💊 发病 / ✅ 康复。

## 数值表（原型 CSS 逐条提取）

| 元素 | 属性 | 值 |
|---|---|---|
| .card | 容器 | bg `--surface-alt`、r `--radius-md`(12)、shadow `--shadow-card`、padding 12 |
| .sec | 头行 | fs12 fw700、gap6、mb8 |
| .dot | 圆点 | 8×8、r50%、bg `--primary`(#2F6B3B) |
| .chip.idle | 阶段 chip | bg `--surface`、color `--text-secondary`、border 1px `--border`、fs9 fw600、r999、padding 2×7 |
| .ev-row | 事件行 | flex center、gap9、padding 8 0、border-bottom 1px `--border`（末行无） |
| .ev-row .ic | 图标容器 | 30×30、r9、bg `--primary-soft`(#E3F0E4)、center、fs14 |
| .ev-row .n | 事件名 | fs11 fw700 |
| .ev-row .d | 来源/备注 | fs9、`--text-secondary`、mt1 |
| .ev-row .when | 日期 | fs9、`--text-secondary`、nowrap |
| .chip.manual | 手工来源 chip | bg `--primary-soft`、color `--primary` |
| .chip.disp | 窗口中 chip | bg rgba(217,123,41,.12)、color `--fever`(#D97B29) |
| .add-btn | 记录按钮 | bg `--primary` #fff、fs11 fw700、r8、padding 8 0、center、gap5、mt9 |

## 状态覆盖（A3：六形态）

| 形态 | 视觉 |
|---|---|
| ①正常态 | 三行事件 + ＋记录 |
| ②空态 | state-empty（dashed border r8 padding 14×8）：📋 fs22 +「尚无生理记录」fs11 fw700 +「点"＋ 记录"开始建档」fs9.5 secondary |
| ③加载骨架 | 三行 skeleton-line 100% / 82% / 60%（h10 r5 渐变） |
| ④错误态 | err-head「⚠️ 生理记录暂时不可用」fs11 fw700 `--danger` + err-d fs9.5 lh1.55 + retry（fs9 fw700 r6 padding 4×12 bg `--danger`） |
| ⑤权限降级 | 无写权限角色隐藏"＋ 记录"按钮，列表仍可读（OWNER/B2B_ADMIN/WORKER 三角色可写，B2） |
| ⑥窗口中 chip | 处置单活动窗口行尾 chip.disp「窗口中」 |

## 数据溯源

| UI 元素 | 来源 | 字段/规则 |
|---|---|---|
| 泌乳期 · 第 128 天 | `PhysiologyQueryPort.currentStage` | LACTATING.since 推导（泌乳长度配置 305d，`health.physiology.lactation-length-days` F7） |
| 事件行（最近 3 条） | `GET .../physiology-events` | occurred_at DESC 取 3；来源=MANUAL（手工录入）/处置单（读时合并投影） |
| 窗口中 chip | `PhysiologyQueryPort.activeWindows` | 活动窗口（手动 ILLNESS 无配对 RECOVERY ∪ 处置单 PENDING/IN_PROGRESS） |

## 文案表（ZH/EN，spec §5 14 组）

| key | 中文 | English |
|---|---|---|
| health.physiology.title | 生理记录 | Physiology Records |
| health.physiology.stageLactating | 泌乳期 · 第 {n} 天 | Lactating · day {n} |
| health.physiology.stageDry | 干奶期 | Dry off |
| health.physiology.event.calving | 产犊 | Calving |
| health.physiology.event.breeding | 配种 | Breeding |
| health.physiology.event.pregnancyCheck | 妊娠检查 | Pregnancy check |
| health.physiology.event.dryOff | 干奶 | Dry-off |
| health.physiology.event.illness | 发病 | Illness onset |
| health.physiology.event.recovery | 康复 | Recovery |
| health.physiology.addRecord | ＋ 记录 | + Add record |
| health.physiology.empty | 尚无生理记录，点"＋ 记录"开始建档 | No records yet — tap "+ Add record" to start |

来源 chip 复用既有文案（手工录入/处置单 #n）；错误态复用饮水侧 state.error 句式。

## 元素清单（DOM 一一对应，可勾）

- [ ] 卡片容器（白卡 r12 shadow-card padding12）
- [ ] 头行：品牌绿圆点 + "生理记录" + 右侧阶段 chip（idle 态）
- [ ] 事件行 ×3：30×30 绿底 emoji 图标 + 名称/来源描述 + 日期（窗口中行尾为橙色 chip）
- [ ] ＋记录按钮（品牌绿主按钮 r8）
- [ ] 状态覆盖卡：空态（dashed 框 📋）/骨架三行/错误态（红标题+retry）/权限降级说明
