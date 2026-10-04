# 规格卡 · PhysiologyEntrySheet（屏 2："＋ 记录"录入 bottom sheet）

> 来源：`docs/prototypes/physiology-events-p1-prototype.html` v1.2。
> 关键语义：录"发病"**无结束日期字段**——康复日后补录"康复"事件闭合窗口（spec §8 A1 裁决，append-only 单一事实源）。
> 日期语义（B3）：默认今天，按 Asia/Shanghai 当日零点转 UTC 存储；未来日期拒绝。

## 组件树

```
detail page (dim-overlay: rgba(38,49,38,.35), r 24 24 0 0)
└── sheet (自底部弹出, z2)
    ├── grip (36×4 r2 bg --border, mb10 居中)
    ├── t「新增生理记录」(fs13 fw700 mb10)
    ├── type-grid: ×6 chip（单选）
    │   ├── idle: bg --surface + border --border + secondary
    │   └── sel: bg --primary #fff（品牌绿选中态，B5）
    ├── date-row: lab「发生日期」(fs10 secondary) + v「2026-10-04」(fs12 fw700 ml-auto)
    ├── note-box: placeholder「备注（选填，≤500 字）…」(fs11 secondary, min-h52)
    └── save-btn「保存」(bg --primary #fff fs12 fw700 r8 padding 10 0)
```

## 数值表（原型 CSS 逐条提取）

| 元素 | 属性 | 值 |
|---|---|---|
| .dim-overlay | 遮罩 | absolute inset0、bg rgba(38,49,38,.35)、r 24 24 0 0、z1（C7：真遮罩） |
| .sheet | 容器 | bg `--surface-alt`、r 14 14 0 0、padding 14 14 18、shadow `--shadow-sheet`(0 -4px 24px rgba(38,49,38,.15))、relative z2 |
| .grip | 把手 | 36×4、r2、bg `--border`、居中、mb10 |
| .sheet .t | 标题 | fs13 fw700、mb10 |
| .type-grid | 类型组 | flex wrap gap6、mb12 |
| .type-grid .chip | 类型 chip | fs10 fw600、r999、padding 6×11 |
| .chip.sel | 选中 | bg `--primary`(#2F6B3B)、#fff |
| .chip.idle | 未选 | bg `--surface`、`--text-secondary`、border 1px `--border` |
| .date-row | 日期行 | flex center gap8、border 1px `--border`、r8、padding 8 10、mb10 |
| .date-row .lab | 标签 | fs10、`--text-secondary` |
| .date-row .v | 值 | fs12 fw700、ml-auto |
| .note-box | 备注框 | border 1px `--border`、r8、padding 8 10、fs11、`--text-secondary`、min-height 52、mb12 |
| .save-btn | 保存 | bg `--primary` #fff、center、fs12 fw700、r8、padding 10 0 |

## 交互与校验（A2 CRUD 全量）

- 类型六 chip 单选：🐮 产犊 / ❤️ 配种 / 🤰 妊娠检查 / ⏸️ 干奶 / 💊 发病 / ✅ 康复。
- 日期选择默认今天；**未来日期拒绝**（`error.physiology.futureDate`）。
- 备注 ≤500 字（`error.physiology.noteTooLong`）。
- 保存：POST 创建；服务端先查 partial unique（livestock+type+date, source=MANUAL）防重，双击幂等返回已有行。
- 编辑/删除（卡片行入口或长按，P1 从列表行操作）：仅 MANUAL 来源；非 MANUAL 返回 409（`error.physiology.readOnlySource`）。
- 写权限三角色：OWNER / B2B_ADMIN / WORKER（对齐 AlertController 日常处置惯例，B2）。

## 后端错误文案（messages_zh/en，B1）

| key | 中文 | English |
|---|---|---|
| error.physiology.livestockRequired | 请指定牲畜 | Livestock is required |
| error.physiology.livestockNotFound | 牲畜不存在或不属于当前牧场 | Livestock not found in this farm |
| error.physiology.eventNotFound | 生理记录不存在 | Physiology record not found |
| error.physiology.readOnlySource | 手工事件才可编辑或删除 | Only manual records can be edited or deleted |
| error.physiology.futureDate | 发生日期不能晚于今天 | Date occurred cannot be in the future |
| error.physiology.noteTooLong | 备注不能超过 500 字 | Note must not exceed 500 characters |

## 文案表（ZH/EN，spec §5）

| key | 中文 | English |
|---|---|---|
| health.physiology.sheetTitle | 新增生理记录 | New physiology record |
| health.physiology.occurredDate | 发生日期 | Date occurred |
| health.physiology.noteHint | 备注（选填，≤500 字）… | Note (optional, ≤500 chars)… |

## 元素清单（DOM 一一对应，可勾）

- [ ] 压暗遮罩（rgba(38,49,38,.35)，sheet 弹出时）
- [ ] sheet：grip 把手 + 标题"新增生理记录"
- [ ] 六类型 chip（单选，品牌绿选中态；示例默认选"妊娠检查"）
- [ ] 日期行（发生日期标签 + 右侧日期值，边框 r8）
- [ ] 备注框（min-h52，placeholder ≤500 字）
- [ ] 保存按钮（品牌绿主按钮 r8 padding 10 0）
- [ ] 底部说明（录"发病"无结束日期字段语义提示）
