# 告警工作台专项重设计 Spec（方案 A × 统一详情 V2）

> 状态：原型已确认（2026-09-25）；spec/plan 待用户批准后编码。
> 视觉与交互蓝本：`docs/prototypes/alert-workbench-redesign-interactive-prototype.html`
> 方案对照存档：`docs/prototypes/alert-workbench-redesign-prototype.html`
> 保真要求：Flutter 实现与已确认原型按高保真 1:1 对照；布局、状态、色彩、字号、层级、动作和跳转不允许自由发挥。

## 1. 目标与边界

把牧场页“告警”Tab 与 `/alerts` 告警中心统一为跨资产告警工作台。界面第一层回答“牧场接下来要做什么”，第二层锚定到牲畜、牛群、围栏、设备资产。

范围内：

- 牧场页告警 Tab 重构。
- `/alerts` 告警中心重构。
- 统一告警详情面板。
- 后端告警工作台聚合接口。
- `DEVICE_OFFLINE` 告警类型、调度、种子与 i18n。
- 健康告警内嵌 AI 结论与 AI 排行。

范围外：

- 不重做已确认的概览视觉。
- 不重做已确认的围栏视觉与编辑能力。
- 不改变全局底部导航；仍为“牧场 / 我的”。
- 不把告警重新拆成围栏、健康、设备三个独立信息孤岛。
- 不直接调用 AI 推理接口；只消费已有 AI band / finding。

## 2. 信息架构

### 2.1 导航关系

| 层级 | 内容 |
|---|---|
| 全局底部导航 | `牧场`、`我的`；告警未读角标挂在“牧场”上 |
| 牧场页内部页签 | `概览`、`围栏`、`告警` |
| 概览 | 牧场现状入口，展示围栏 / 健康 / 设备数量与主要矛盾 |
| 围栏 | 空间资产详情，展示围栏形状、位置、在养数量、临近状态 |
| 告警 | 跨资产处置队列，按管理动作四桶组织 |

### 2.2 四桶口径

| 桶 | 判定 | 说明 |
|---|---|---|
| `immediate` 立即处置 | 严重告警、围栏越界、疫病、设备拆卸、AI alarm 且已开单 | 最高优先级 |
| `field` 现场巡检 | 围栏/区域接近、健康一般异常、低电、设备离线 | 可结合现场路线处理 |
| `observe` 持续观察 | AI watch、快照异常但暂无活跃告警、恢复中个体 | 不强制开单 |
| `resolved` 今日已处理 | 当日 `DISMISSED` / `AUTO_RESOLVED` | 可进入完整历史 |

桶内排序固定为：严重级降序 → 未读优先 → 发生时间升序。数字必须由后端工作台接口统一下发，禁止前端用不同数据源重复计算。

### 2.3 资产锚定

| 资产 | 聚合规则 |
|---|---|
| 牲畜 `livestock` | 健康相关告警按 `livestockId` 聚合 |
| 牛群 `herd` | 全场级疫病风险聚合 |
| 围栏 `fence` | 按 `fenceId` 聚合，受影响牲畜去重 |
| 设备 `device` | 按 `deviceId` 聚合，无设备 id 时保留 farm 级兜底卡 |

## 3. Design Tokens

所有颜色优先复用 `AppColors`；新增渐变只在告警工作台局部使用。

| Token | 值 | 用途 |
|---|---|---|
| primary | `#2F6B3B` | 主色、选中态、推荐动作渐变 |
| primary-dark | `#244F2D` | 推荐动作渐变深端 |
| primary-soft | `#E3F0E4` | 选中 chip、工具按钮 |
| surface | `#F8F6F0` | 页面底色 |
| surface-alt | `#FFFFFF` | 卡片、面板 |
| border | `#D7D2C6` | 卡片边框 |
| text-primary / secondary | `#263126` / `#617061` | 主/次文本 |
| danger / warning / info / success | `#C2564B` / `#D28A2D` / `#4A7F9D` / `#4C9A5F` | 四桶与状态 |
| tile red gradient | `#B3453B → #C9664F` | 立即处置 |
| tile orange gradient | `#C07A22 → #DB9C40` | 现场巡检 |
| verdict gradient | `#244F2D → #2F6B3B` | 下一步建议 |

尺寸与字号以已确认交互原型 410×760 画布为真源：

- 页面主标题 13/w800；区块标题 13/w850；卡片标题 11/w850。
- 主要数字：概览小瓷砖 20/w900，告警四桶 22/w900，详情指标 13/w900。
- 元信息 8px；证据 9px；标签 7.5–8px/w800。
- 卡片圆角 12；面板圆角 12；底部动作按钮高 32；未读胶囊最小 14×14。
- 卡片阴影：`0 1px 3px rgba(38,49,38,.06), 0 1px 2px rgba(38,49,38,.04)`。

## 4. 牧场页告警 Tab

页面结构固定为：

1. 三签导航：概览 / 围栏 / 告警。
2. 上下文条：显示“概览 / 围栏 / 告警”的当前入口关系；从概览或围栏跳入时高亮来源。
3. 四桶瓷砖：立即处置、现场巡检、持续观察、今日已处理。
4. 资产 chips：全部资产、牲畜、牛群、围栏、设备。
5. 每桶最多 3 条资产卡。
6. AI 摘要入口：“谁最需要关注”。

行为：

- 点击四桶进入 `/alerts` 并保留 bucket 上下文。
- 点击资产卡直接打开统一详情。
- 标记已读、处理、定位、轨迹等动作就地生效。
- 刷新周期 30 秒；弹层打开或批量操作时暂停；静默刷新不重置滚动。
- 牧场切换由 `FarmScopedAsyncNotifier.watchActiveFarmId()` 自动触发重建。

## 5. `/alerts` 告警中心

`/alerts` 路由保留，页面升级为完整工作台：

1. 四桶汇总瓷砖。
2. 四桶筛选 chips。
3. 资产筛选 chips。
4. 全量分页列表。
5. AI 排行入口。
6. 批量已读 / 处理入口。

旧入口兼容：

| 旧参数 | 新语义 |
|---|---|
| `category=fence` | `asset=fence` |
| `category=health` | `asset=livestock,herd` |
| `category=device` | `asset=device` |
| `fenceId=...` | 继续作为围栏上下文过滤 |

新增深链参数：`bucket`、`asset`、`fenceId`、`page`、`pageSize`。

## 6. 统一详情面板 V2

详情面板固定五层，不允许按告警类型重新发明结构：

1. **风险头**：资产、风险标题、四桶、严重级、未读、当前影响。
2. **下一步建议**：用绿色渐变主卡回答“先做什么”和“为什么”。
3. **关键指标**：最多三个关键值；不同资产只替换内容，不改变结构。
4. **证据**：短句证据列表；健康类可含 AI 证据；技术证据折叠。
5. **生命周期**：触发、AI 评估、当前待办、处理 / 恢复。

底部动作区固定：

- 主操作按资产和状态变化：处理、联动地图、设备、牛详情。
- 工具操作：轨迹、牲畜、标记已读。
- 已处理详情不显示处理动作，只显示结果、证据、生命周期。
- WORKER 可处理 ACTIVE 告警；无权限动作隐藏，不置灰误导。

必须覆盖的状态：围栏越界、健康 AI 观察、设备离线、设备拆卸、健康已恢复、手动处理。

## 7. AI 呈现

- 卡片只展示“平稳 / 留意 / 警惕”和一句发现。
- 详情技术证据折叠；评分、样本数、模型名不作为主文案。
- AI 排行按档位降序：警惕 > 留意 > 平稳。
- 排行数据复用健康 episodes 聚合；NIX-243 未就绪时展示空态“AI 观察暂未开启，恢复后自动展示”。
- 禁止用合成结果冒充真实效果。

## 8. API 契约

### 8.1 工作台聚合

```http
GET /api/v1/farms/{farmId}/alerts/workbench
```

| 参数 | 取值 |
|---|---|
| `bucket` | `all`, `immediate`, `field`, `observe`, `resolved` |
| `asset` | CSV：`all`, `livestock`, `herd`, `fence`, `device`；健康入口映射为 `livestock,herd` |
| `fenceId` | 可选围栏上下文 |
| `page` | 默认 1 |
| `pageSize` | 默认 50，上限 200 |

响应：

```json
{
  "summary": {
    "buckets": [
      {"key": "immediate", "total": 5, "unread": 3},
      {"key": "field", "total": 7, "unread": 2},
      {"key": "observe", "total": 5, "unread": 0},
      {"key": "resolved", "total": 12, "unread": 0}
    ],
    "assets": [
      {"key": "livestock", "total": 3, "unread": 2},
      {"key": "herd", "total": 1, "unread": 1},
      {"key": "fence", "total": 2, "unread": 1},
      {"key": "device", "total": 4, "unread": 1}
    ]
  },
  "items": [
    {
      "id": "fence-01",
      "bucket": "immediate",
      "asset": {"kind": "fence", "id": "1", "name": "北区放牧区", "subtitle": "46 头在养"},
      "title": "3 头越界",
      "subtitle": "北区放牧区",
      "severity": "CRITICAL",
      "unread": true,
      "occurredAt": "2026-09-25T01:41:00Z",
      "resolvedAt": null,
      "resolvedType": null,
      "reasons": [
        {
          "alertId": "101",
          "type": "FENCE_BREACH",
          "severity": "CRITICAL",
          "message": "SL-07 已越出围栏",
          "occurredAt": "2026-09-25T01:41:00Z",
          "read": false
        }
      ],
      "ai": {
        "band": "alarm",
        "findingCode": "temp_spike",
        "score": 0.86,
        "assessedAt": "2026-09-25T01:20:00Z"
      },
      "actions": ["VIEW_FENCE", "LOCATE", "TRAJECTORY", "MARK_READ", "DISMISS"],
      "targetRoute": "/alerts?asset=fence&fenceId=1"
    }
  ],
  "page": 1,
  "pageSize": 50,
  "total": 17
}
```

`actions` 只表示该工作台项支持的能力：`LOCATE`, `TRAJECTORY`, `VIEW_LIVESTOCK`, `VIEW_FENCE`, `VIEW_DEVICE`, `VIEW_AI`, `MARK_READ`, `DISMISS`。最终按钮是否可见仍由前端角色权限决定。

### 8.2 设备离线

新增 `DEVICE_OFFLINE`：

- 判定对象：当前有 active installation 的 ACTIVE 设备。
- 阈值：最新信号时间早于当前时间 2 小时；最新信号取 `lastOnlineAt`、`lastTelemetrySyncedAt`、最新 telemetry `reportTime` 的最大值。
- 开单幂等键：`(farmId, deviceId, DEVICE_OFFLINE, ACTIVE)`。
- 调度：默认 10 分钟，可配置。
- 恢复：设备重新上报且信号时间回到阈值内后自动 `AUTO_RESOLVED`。
- 告警消息 key：`alert.device.offline`。

## 9. 权限与状态

- `POST /alerts/{alertId}/dismiss` 从 `OWNER / B2B_ADMIN` 扩展到 `WORKER`。
- `batch-handle` 同步扩展到 `WORKER`。
- `markRead` 仍为当前用户维度，不改变告警状态。
- `dismiss` 表示处理完成：`ACTIVE -> DISMISSED`，记录操作者。
- `AUTO_RESOLVED` 只能由系统恢复路径写入。

## 10. i18n

所有用户可见文案必须进入 `app_zh.arb` / `app_en.arb`，后端服务端消息进入 `messages_zh.properties` / `messages_en.properties`。

不得硬编码：

- 四桶名称与描述。
- 资产类型。
- AI 档位与 finding。
- 上下文条、筛选、空态、加载更多、处理结果提示。
- 设备离线告警消息。

`flutter gen-l10n` 必须无缺失 key，中英 placeholder 类型一致。

## 11. 验收标准

1. 高保真：牧场告警 Tab、告警中心、四桶、资产筛选、AI 排行、统一详情 V2 与交互原型逐屏对齐。
2. 数字一致：概览入口、牧场告警 Tab、告警中心、详情未读来自同一聚合口径。
3. 闭环：标记已读、处理、自动恢复、历史进入、深链过滤、牧场切换全部可用。
4. 权限：OWNER / B2B_ADMIN / WORKER 看到相同风险，但只显示各自可用动作。
5. 兼容：旧 `/alerts?category=...`、`fenceId=...` 不断链。
6. 后端：编译、目标测试、迁移全新库执行通过；设备离线开单与恢复有测试。
7. 前端：`flutter gen-l10n` 无缺失，`flutter analyze` 零新增，目标 widget 测试通过。
8. 部署：dev 部署后 curl 新接口业务字段非空，浏览器全链路走查，容器内 `main.dart.js` hash 一致，种子账号登录 200。
