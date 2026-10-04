# 规格卡 · DrinkingDetailSection（屏 2：健康详情图表页 · 第四分节）

> 来源：`docs/prototypes/drinking-event-detection-prototype.html` v1.3。
> 挂载点：健康详情图表页，与"发热监测/消化健康/发情检测"三分节并列的第四分节（3 击可达）。
> 图表实现钉死（plan T5.3）：体温叠加 fl_chart `LineChart`（谷点 `FlDotCirclePainter` 白描边、发热区 `HorizontalRangeAnnotation`）；时刻分布与 mini-bars 自绘（对齐项目 contact-tracing 自绘图惯例）。

## 组件树

```
DrinkingDetailSection
├── chart-card A「今日饮水时刻分布」
│   ├── chart-title: "📊 今日饮水时刻分布" + right "共 7 次"
│   ├── chart-area: SVG 340×96
│   │   ├── ×3 峰值参考区 rect (#DCE8D5 opacity .55 rx3) + 区内标注 fs7.5 #4C7A52
│   │   ├── 时间轴 line (#D7D2C6) + 轴标 0/8/16/24时 (fs7.5 #617061)
│   │   └── ×N 饮水事件菱形 (fill #3D7FA8, path l5,6 -5,6 -5,-6)
│   ├── legend-row: 菱形 swatch(8×8 rotate45 #3D7FA8)+文案 / 绿块 swatch(10×10 r3 #DCE8D5)+文案
│   └── 副标 subtle "75% 饮水集中在饲喂/挤奶后…"
├── chart-card B「48h 温度×饮水」
│   ├── chart-title: "🌡️ 48h 温度×饮水" + seg 分段切换（本牛 on / 同类）
│   ├── chart-area: SVG 340×120
│   │   ├── 发热区 rect (#D97B29 opacity .12 rx4) + 标注 "发热期·已排除" (fs7.5 #D97B29)
│   │   ├── 基线 dashline (#617061 dasharray 4,4 opacity .35) + 标注 "基线 38.5" (fs8)
│   │   ├── 温度曲线 path (stroke #D97B29 w2)
│   │   └── ×N 谷点 circle (r4 fill #2C6486 stroke #fff 1.5) + 降幅标签 (fs7.5 fw700 #2C6486)
│   └── legend-row 三项: 瘤胃温度 / 饮水谷(圆点) / 发热期+6h 缓冲
└── note-box 诚实口径（常驻）
    ├── icon ℹ️ (fs13 --drinking)
    └── text (fs9.5 --drinking lh1.5)
```

## 数值表（原型 CSS 逐条提取）

| 元素 | 属性 | 值 |
|---|---|---|
| .chart-card | 容器 | bg `--surface-alt`、r `--radius-md`(12)、shadow `--shadow-card`、padding 12 |
| .chart-title | 标题行 | fs11 fw700、flex space-between、mb8 |
| .chart-title .right | 右注 | fs9 fw600、`--text-secondary` |
| .chart-area | 图区 | bg `--surface`(#F8F6F0)、r8、padding 8 |
| svg.chart | 画布 | width 100% height auto；分布图 viewBox 340×96、叠加图 340×120 |
| 峰值参考区 | rect | fill `--map-green`(#DCE8D5)、opacity .55、rx3、y8 h70 |
| 区内标注 | text | fs7.5、#4C7A52 |
| 时间轴 | line | stroke `--border`(#D7D2C6) w1；轴标 fs7.5 `--text-secondary` |
| 事件菱形 | path | fill `--drinking`(#3D7FA8)、10×10（l5,6） |
| .legend-row | 图例行 | gap10 wrap、mt7 |
| .legend-row .lg | 图例项 | fs8.5、gap4、`--text-secondary` |
| .legend-row .swatch | 色块 | 10×10 r3；菱形图例 8×8 rotate45；圆点图例圆形 |
| .seg | 分段容器 | r999、padding 2、bg `--surface`、border 1px `--border` |
| .seg .opt | 选项 | fs9 fw600、r999、padding 3×7、`--text-secondary` |
| .seg .opt.on | 选中 | bg `--drinking`、#fff |
| 发热区 | rect | fill `--fever`(#D97B29) opacity .12、rx4 |
| 基线 | line | #617061、dasharray 4,4、opacity .35；标注 fs8 |
| 温度曲线 | path | stroke `--fever`、stroke-width 2 |
| 谷点 | circle | r4、fill `--drinking-event`(#2C6486)、stroke #fff 1.5 |
| 降幅标签 | text | fs7.5 fw700、#2C6486 |
| .note-box | 容器 | bg rgba(61,127,168,.07)、r8、padding 9×10、gap7 |
| .note-box .icon | 图标 | fs13、`--drinking`、lh1.2 |
| .note-box .text | 文字 | fs9.5、`--drinking`、lh1.5 |
| 副标 .subtle | 文字 | fs11、`--text-secondary`、mt7 |

## 数据溯源（UI 数字 → 端点 → 字段）

| UI 元素 | 端点 | 字段/规则 |
|---|---|---|
| 共 7 次（分布图右注） | drinking-summary?days=1 | `daily.count` |
| 事件菱形位置（今日各时刻） | `GET .../drinking-events?from=&to=` | `event_start_at`（谷底≈饮水结束时刻定位） |
| 降幅标签 −1.7°C / −1.4°C | drinking-events | `temp_drop` |
| 48h 温度曲线 | 既有温度查询 | `temperature_logs` 点列（复用体温分节数据源） |
| 发热区阴影 | 排除窗口 | PhysiologyQueryPort.activeWindows ∪ TEMPERATURE_ABNORMAL 告警窗口（+6h 缓冲） |
| 分段"本牛/同类" | 同类= peer-comparison | Premium 权益（服务端校验） |

## 文案表（ZH/EN）

| key | 中文 | English |
|---|---|---|
| health.drinking.detail.title | 饮水行为详情 | Drinking Behavior Detail |
| health.drinking.timeDistribution | 今日饮水时刻分布 | Today's drinking timeline |
| health.drinking.tempOverlay | 48h 温度×饮水 | 48h temp × drinking |
| health.drinking.honestyNote | 数据为瘤胃温度自动检测，更新延迟约 30 分钟；夏季水温接近体温时部分饮水可能未被识别（检出的均可靠）。发热期数据不参与异常判定与基线计算。 | Auto-detected from rumen temperature with ~30 min delay. Some drinks may be missed in summer when water is near body temperature (detected events are reliable). Fever data is excluded from anomaly detection and baselines. |

> honestyNote 以原型 DOM v1.3 文案为准（3b 旧句"发热期时段不参与统计"已被 F4 精确句式替换）。

## 元素清单（DOM 一一对应，可勾）

- [ ] 分布图 chart-card：标题行+右注"共 N 次"、峰值参考区×3（饲喂后/挤奶后/傍晚高峰）、时间轴 0/8/16/24、菱形事件标记×N
- [ ] 分布图图例行两项（菱形=饮水事件、绿块=饲喂/挤奶时段）+ 副标（集中度说明）
- [ ] 叠加图 chart-card：标题+seg 分段（本牛/同类）、发热阴影区+标注、基线虚线+标注、温度曲线、谷点+降幅标签×N
- [ ] 叠加图图例三项（瘤胃温度/饮水谷/发热期+6h 缓冲）
- [ ] 诚实口径 note-box（常驻，ℹ️ + 水蓝 9.5px 文字）
