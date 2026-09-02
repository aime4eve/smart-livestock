# docs/diagrams — 架构图表

本目录存放由 archify（ZCode `archify` skill，v2.16.0-dev.0）生成的**可交互独立 HTML 架构图**（内联 SVG，无外部 JS 依赖，可直接在浏览器打开或托管到任意静态站点）。

## 文件清单

| 文件 | 说明 |
| --- | --- |
| `telemetry-data-flow.html` | **主图表**：智慧畜牧 · 设备遥测数据流（可交互，双主题） |
| `telemetry-data-flow.visual-check.html` | 主图表的视觉检查报告页，汇总 4 张不同视口/主题的渲染截图 |
| `telemetry-data-flow.visual-check.*.png` | 视觉检查截图（1440×900 / 2048×1320 × light/dark） |
| `telemetry-data-flow.archify.json` | 主图表的 archify 源定义（声明式节点/连线，重新生成的输入） |

两个 HTML 文件均通过标签配平校验，可直接用浏览器打开。

## 主图表：设备遥测数据流

`telemetry-data-flow.html` 描述遥测数据从设备采集到结果应用的完整链路，按 5 个阶段组织：

1. **数据采集** — 智能项圈/耳标（CAPSULE · TRACKER）经 MQTT 上报 ThingsBoard；设备也可直连 Agentic 中台（report-record 分页拉取，5min 轮询）
2. **统一摄取** — `TelemetryIngestionService` 幂等去重汇入，TB 游标轮询防双源重复
3. **存储 · 事件流** — 原始遥测落 `device_telemetry_logs`（按月分区）；GPS 走 outbox 异步落 `gps_logs`；`telemetry-received` / `gps-log-updated` 事件进 RocketMQ
4. **数据分析** — 事件驱动的健康规则分析（发热/消化/发情/疫病 · 围栏）+ ai-platform 的 STL/CUSUM 融合评分（读 24h 特征窗口，主链路暂禁用）
5. **结果应用** — 告警中心聚合 RULE/AI 告警；移动端（Flutter）拉取与已读回写；开放 API（API Key）供第三方消费

图表内置"关键结论"注释卡片，与 `docs/reference/project-overview.md` 的架构描述保持一致。

### 交互功能

- **主题**：深色/浅色切换（默认跟随系统），工具栏按钮或快捷键 `T`
- **视觉风格**：`S` 循环切换 经典 / 信号流 / 蓝图 三种预设
- **聚焦阶段**：`F` 切换阶段聚焦视图
- **导出**：`E` 打开导出面板
- **探索工具**：节点查找器（搜索定位）、语义透镜、语义雷达、引导故事/路径旅程、动效暂停、复制聚焦节点链接

### URL 参数

| 参数 | 作用 |
| --- | --- |
| `?theme=light\|dark` | 指定初始主题（优先于 localStorage 记忆） |
| `?embed=1` | 嵌入模式（隐藏外框 UI，适合 iframe） |
| `?present=1` | 演示模式 |
| `?focus=<node>` | 打开即聚焦指定节点 |
| `?lens=<...>` | 打开即应用语义透镜 |

## 视觉检查页

`telemetry-data-flow.visual-check.html` 是 archify 自动化检查（containment pass）的产物，将主图表在 1440×900 与 2048×1320 两种视口、light/dark 两主题下的截图并排展示，供人工复核布局是否溢出。它依赖同目录下的 4 张 PNG，需整目录一起拷贝。

## 维护约定

- **修改图表**：编辑 `telemetry-data-flow.archify.json` 后用 archify 重新生成 HTML，不要手改主图 HTML（其为生成产物）。
- **重新生成后**：重跑视觉检查并同步更新报告页与 PNG。
- 图表内容与代码/迁移不一致时，以代码与 Flyway 迁移为准，并回过头更新本图表。
