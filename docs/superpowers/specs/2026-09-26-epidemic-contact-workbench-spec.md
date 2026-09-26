# 接触追踪三视图工作台 Spec

> 状态：三视图原型已确认（2026-09-26）；spec/plan 待用户批准后编码。
> 视觉与交互蓝本：`docs/prototypes/contact-tracing-unified-experience.html`（唯一实现真源）。
> 场景存档：`contact-tracing-a-risk-stream.html`、`contact-tracing-b-priority-view.html`、`contact-tracing-c-network-investigation.html` 仅作为 A/B/C 场景说明，不作为独立页面实现目标。
> 保真要求：Flutter 实现与统一原型按高保真 1:1 对照；布局、层级、颜色、字号、状态、动作和文案不允许自由发挥。

## 1. 目标与边界

把现有疫病防控页和疫情接触追踪详情升级为一个接触追踪工作台，让应急处置人员按“先处理哪头牛”行动，而不是在平铺接触记录里自行推断风险。

范围内：

- 疫病防控页升级为“处置 / 记录 / 链路”三视图工作台。
- 接触事件、牛只聚合、传播链三层后端聚合接口。
- 四级处置重要性模型、建议动作和时限。
- 牛只处置状态记录与标记观察能力。
- 高保真视觉、空态、加载态、错误态、订阅锁定态和中英文 i18n。

范围外：

- 不改变全局底部导航和牧场切换机制。
- 不重做健康模块其他场景页。
- 不把 AI 仿真结果作为真实防疫效果；AI 分值仅作为已有健康信号参与分级。
- 不在前端硬算风险分数、处置等级或传播链。
- 不新增真实传感器；仍消费现有 GPS 接触与健康快照数据。

## 2. 信息架构

### 2.1 页面结构

保留 `/twin/epidemic` 路由，升级为工作台外壳：

1. 主AppBar：返回、标题“疫病防控”、风险模型窗口和同步时间、全局筛选。
2. 三视图Tab：`处置`、`记录`、`链路`；默认进入“处置”。
3. 共享应急概览：疑似源头、病种、标记时间、接触牛只数、一级处置数、最近接触。
4. 当前视图内容。
5. 底部主操作按视图切换：应急报告 / 接触记录导出 / 调查报告。

深链参数：

| 参数 | 取值 | 说明 |
|---|---|---|
| `view` | `disposition`、`records`、`network` | 默认 `disposition` |
| `sourceLivestockId` | 可选 | 未传时由后端选择最新标记源 |
| `window` | `24h`、`48h`、`72h`、`all` | 默认 `72h` |

旧路由 `/twin/epidemic/contacts/:livestockId` 必须兼容，重定向到：

```text
/twin/epidemic?view=network&sourceLivestockId=:livestockId
```

### 2.2 视图定位

| 视图 | 用户问题 | 主内容 | 主操作 |
|---|---|---|---|
| 处置 | 先处理哪头牛、什么时候处理 | 四级处置汇总 + 牛只处置队列 | 立即隔离 / 立即检查 / 标记观察 / 传播链 |
| 记录 | 为什么风险高、证据是什么 | 风险数量 + 按风险排序的接触事件 | 查看牛只、按牛只处置、导出记录 |
| 链路 | 接触如何扩散 | 源头、节点边、高风险路径、证据 | 展开二层 / 打开处置队列 / 调查报告 |

三个视图共用同一接口、同一时间窗、同一风险模型和同一处置等级。禁止视图之间出现数字不一致。

## 3. 处置重要性模型

### 3.1 基本原则

处置等级不是感染确诊结论，而是“操作紧迫度”。它由四类输入共同决定：

1. **接触风险**：现有三维评分，时间 40 + 距离 35 + 持续时长 25。
2. **传播路径**：是否直接接触源头，以及最短路径深度。
3. **健康信号**：体温、瘤胃蠕动、活跃健康告警、已有 AI 异常信号。
4. **时间窗**：默认 72 小时；24h / 48h / 72h / all 只改变证据范围，不改变评分公式。

所有分级必须由后端计算并下发。前端只渲染 `dispositionTier`、`recommendedAction`、`dueAt` 和理由。

### 3.2 四级定义

| 等级 | Key | 用户文案 | 判定优先级 | 建议动作 | 时限 |
|---|---|---|---|---|---|
| 一级 | `CRITICAL` | 立即隔离 / 立即检查 | 最高 | 有健康异常：隔离并通知兽医；无健康异常但风险极高：立即兽医检查 | 2-4 小时 |
| 二级 | `OBSERVATION` | 重点观察 | 高 | 24 小时健康复核 | 24 小时 |
| 三级 | `TRACKING` | 常规追踪 | 中 | 继续追踪并核对新增接触 | 72 小时 |
| 四级 | `ARCHIVE` | 归档备查 | 低 | 暂无即时动作，保留证据 | 不设时限 |

### 3.3 分级算法

对窗口内每头非源头牛只计算：

```text
directSource = 存在 source -> livestock 的一阶接触
age          = now - 该牛最近一条直接源头接触的 lastContactAt
maxRiskScore = 该牛所有相关事件的最大风险分
minDepth     = 从源头到该牛的最短路径深度；一阶 = 1，二阶 = 2
healthSignal = tempStatus ∈ {FEVER, CRITICAL}
               OR motilityStatus = ABNORMAL
               OR 存在 ACTIVE 的健康/疫病相关告警
```

按顺序命中第一条规则：

1. `directSource && age <= 24h && riskScore >= 70 && healthSignal`
   → `CRITICAL`，动作 `ISOLATE_NOTIFY_VET`，时限 `now + 2h`。
2. `directSource && age <= 24h && riskScore >= 80`
   → `CRITICAL`，动作 `IMMEDIATE_VET_CHECK`，时限 `now + 4h`。
3. `directSource && age <= 48h && riskScore >= 40` 或 `minDepth <= 2 && maxRiskScore >= 70`
   → `OBSERVATION`，动作 `HEALTH_RECHECK`，时限 `now + 24h`。
4. `maxRiskScore >= 40`
   → `TRACKING`，动作 `CONTINUE_TRACING`，时限 `now + 72h`。
5. 其余
   → `ARCHIVE`，动作 `ARCHIVE_ONLY`，无时限。

阈值 V1 先按上述默认值实现，并放入后端可配置项。上线前仍需兽医/业务方确认；确认后冻结为业务规则并补测试。

### 3.4 排序与并列

处置队列排序固定为：

1. 处置等级升序：一级 → 四级。
2. 最大相关风险分降序。
3. 最近接触时间升序，越近越靠前。
4. 牛号编码升序，保证结果稳定。

### 3.5 动作状态

| 状态 | 含义 |
|---|---|
| `PENDING` | 待处置，卡片显示建议动作和剩余时间 |
| `IN_PROGRESS` | 已有人认领或开始处理 |
| `COMPLETED` | 动作完成，保留完成人和完成时间 |
| `CANCELLED` | 用户或业务规则取消，保留原因 |

同一 `farmId + livestockId` 只允许存在一条 `PENDING / IN_PROGRESS` 处置任务。源牛取消标记时，系统不物理删除历史任务，只取消未完成任务并保留审计记录。

## 4. 三视图规格

### 4.1 共享应急概览

内容固定为：

1. 疑似源头牛号、状态、病种、标记时间。
2. 三个摘要值：接触牛只、一级处置、最近接触。
3. 风险模型窗口和同步时间。
4. 多源规则：默认选择 `markedAt` 最新的源头；用户可通过深链切换。若存在多个活跃源头，概览提供“多源头”状态入口，V1 只展示最新源头详情。

### 4.2 处置视图

页面顺序：

1. 四级处置汇总卡：2×2 网格。
2. 处置队列，按等级分组。
3. 每张牛只卡展示：牛号、等级、围栏/位置、最近接触、接触牛数、最高风险、体温/健康信号、建议动作、时限、可展开接触证据。
4. 卡片底部固定两个动作：`传播链` 和等级主动作。

等级主动作：

| 等级 | 主动作 |
|---|---|
| `CRITICAL` | 立即隔离 / 立即检查 |
| `OBSERVATION` | 标记观察 |
| `TRACKING` | 继续追踪 |
| `ARCHIVE` | 查看证据 |

已完成后卡片降为收敛展示：等级、完成时间、完成人、结果摘要；不显示误导性主操作。

### 4.3 记录视图

页面顺序：

1. 风险数量：高风险、中风险、低风险。
2. 时间窗 chips：24h / 48h / 72h / 全部。
3. 接触事件列表，默认全窗口、按风险分降序。
4. 每条事件展示：`fromCode ↔ toCode`、风险分、距离、持续时长、最近时间、成因标签。
5. 事件底部提供“按牛只处置”，跳到涉事牛的处置卡。

成因枚举由后端下发，前端只做 i18n：

| Key | 条件 |
|---|---|
| `FRESH` | `age <= 24h` |
| `RECENT` | `age <= 48h` |
| `NEAR` | `distance < 5m` |
| `MODERATE_DISTANCE` | `5m <= distance < 15m` |
| `LONG_DURATION` | `duration > 30min` |
| `MEDIUM_DURATION` | `15min < duration <= 30min` |

### 4.4 链路视图

页面顺序：

1. 源头状态卡。
2. 一阶接触图。
3. 高风险路径列表。
4. 调查结论摘要。
5. 时间倒序证据列表。

规则：

- V1 图谱默认展示源头 + 两跳路径；后端接口 `maxDepth` 默认 2，最大 3。
- 节点显示牛号和处置等级；源头节点显示“疑似源头”。
- 边宽表示接触强度，边详情来自对应接触事件。
- 点击节点打开牛只处置上下文；点击边打开事件证据。
- 路径累计风险 = 路径上事件风险分之和；后端下发，不由前端累加展示数据反推。

### 4.5 通用状态

| 状态 | 规则 |
|---|---|
| 加载 | 三视图首次加载显示骨架屏；Tab 切换时已有数据不重置滚动 |
| 刷新 | 下拉刷新；刷新失败保留旧数据并显示轻量错误条 |
| 空态 | 按视图区分“无接触”“窗口内无记录”“无高风险路径” |
| 错误 | 明确“加载失败”和重试，不裸抛异常 |
| 权限 | 无权限动作隐藏，不显示置灰误导 |
| 订阅 | 继承现有 `epidemic_alert` Premium+ 门控；锁定页保留升级入口 |
| 牧场切换 | Controller 必须继承 `FarmScopedAsyncNotifier` 并调用 `watchActiveFarmId()` |

## 5. Design Tokens

以下令牌以统一原型 390×844 画布为真源，确认后锁定。

### 5.1 颜色

| Token | 值 | 用途 |
|---|---|---|
| `color.primary` | `#2F6B3B` | AppBar、主按钮、选中态 |
| `color.primaryDark` | `#244F2D` | 主按钮文字强调、选中 Tab 文本 |
| `color.primarySoft` | `#E3F0E4` | 头像、正向标签 |
| `color.surface` | `#F8F6F0` | 页面底色 |
| `color.surfaceAlt` | `#FFFFFF` | 卡片、Tab 选中底 |
| `color.surfaceMuted` | `#F2F0EA` | 指标块、次级标签 |
| `color.border` | `#D7D2C6` | 卡片边框、分隔线 |
| `color.textPrimary` | `#263126` | 主文本 |
| `color.textSecondary` | `#617061` | 次文本、说明 |
| `color.danger` / `dangerStrong` / `dangerSoft` | `#C2564B` / `#B3352C` / `#FBE8E6` | 一级、高风险、源头 |
| `color.warning` / `warningStrong` / `warningSoft` | `#D28A2D` / `#B36A16` / `#FFF2DE` | 二级、中风险、关注 |
| `color.info` / `infoSoft` | `#4A7F9D` / `#EAF2F6` | 三级、路径辅助 |
| `color.success` / `successSoft` | `#4C9A5F` / `#E4F3E8` | 四级、低风险、完成 |

### 5.2 字号 / 字重 / 行高

| Token | 值 | 用途 |
|---|---|---|
| `font.caption` | 11 / 500-600 | 元数据、说明、chips |
| `font.body` | 13 / 500-600 | 普通正文、按钮 |
| `font.title` | 15 / 700 | 页面标题、卡片主标题 |
| `font.metric` | 18-21 / 700 | 摘要数字 |
| `line.tight` | 1.2 | 标题 |
| `line.normal` | 1.45 | 说明与结论 |

### 5.3 间距 / 圆角 / 尺寸

| Token | 值 |
|---|---|
| `spacing` | 4 / 8 / 12 / 16 / 20 |
| `radius.small` | 6 |
| `radius.medium` | 10 |
| `radius.large` | 14 |
| `radius.pill` | 999 |
| `touch.target` | 44 |
| `app.width` | 390 |
| `app.height` | 844 |
| `graph.height` | 250 |
| `shadow.card` | `0 1px 2px rgba(38,49,38,0.06)` |
| `shadow.app` | `0 18px 50px rgba(38,49,38,0.16)` |

## 6. 组件规格

### 6.1 模式 Tab

- 三等分网格，外层 padding 4，间隙 4。
- 非选中：透明底、次文本、16px 图标 + 13/600 文本。
- Active：白底、10 圆角、主深绿文本、卡片阴影。
- Tab 切换不重新进入 loading，已有缓存数据立即渲染。

### 6.2 共享应急概览

- 外层 14 圆角，红色 14% → 4% 水平渐变，边框 `rgba(194,86,75,0.18)`。
- 图标容器 40×40，圆角 10，红 14% 底。
- 标题 15/700，`dangerStrong`。
- 三个摘要值横向等分；标签 10，值 18/700。

### 6.3 处置等级卡

- 2×2 网格，间隙 8。
- 卡片最小高 74，圆角 10，左侧色脊 4。
- 等级名 13/700；数量 11/700；动作说明 10。
- 色脊：一级 danger、二级 warning、三级 info、四级 success。

### 6.4 牛只处置卡

- 圆角 14，白底，左侧色脊 4。
- 头像 46×46，圆角 10。
- 等级胶囊：10/700，soft 底色。
- 三个指标块等分：接触牛、最高风险、体温/健康信号。
- 健康信号条高约 34，圆角 10。
- 证据区可折叠；展开按钮高 42。
- 底部双按钮高 40，等分。

### 6.5 记录事件卡

- 圆角 14，白底，左侧风险色脊 4。
- 事件头左侧牛号对 15/700，右侧风险分 soft 胶囊。
- 三个指标块等分，标签带 12px 图标。
- 成因 chips 换行，激活项使用风险 soft 色。

### 6.6 链路图

- 画布高度 250，白底卡片圆角 14。
- 源头节点半径 30，一阶节点半径 24。
- 一级节点 danger，二级节点 warning，四级/低风险节点 success。
- 高风险边宽 5，中风险边宽 4，二级观察边宽 3，跨层关系虚线 2。
- 边标签白底 6 圆角、细边框，文本 10/700。
- 图例固定在图下方。

### 6.7 底部操作栏

- 固定底部，半透明页面底色 + 16px blur。
- 双按钮等分，高 44，圆角 10。
- 左侧 quiet：筛选或展开；右侧 primary：报告/导出动作。

## 7. API 契约

### 7.1 工作台聚合

```http
GET /api/v1/farms/{farmId}/health/epidemic/workbench
```

| 参数 | 必填 | 默认 | 说明 |
|---|---|---|---|
| `sourceLivestockId` | 否 | 最新标记源 | 指定疑似源头 |
| `windowHours` | 否 | `72` | `24` / `48` / `72`；`0` 表示全部 |
| `maxDepth` | 否 | `2` | 传播链最大深度，最大 3 |
| `tier` | 否 | 全部 | CSV：`CRITICAL,OBSERVATION,TRACKING,ARCHIVE` |

响应核心结构：

```json
{
  "context": {
    "source": {
      "livestockId": "48",
      "livestockCode": "SL-2024-048",
      "diseaseType": "口蹄疫疑似",
      "markedAt": "2026-09-26T01:00:00Z",
      "status": "SUSPECTED"
    },
    "windowHours": 72,
    "generatedAt": "2026-09-26T03:00:00Z",
    "syncedAt": "2026-09-26T03:00:08Z",
    "herdMetrics": {
      "avgTemperature": 38.6,
      "abnormalRate": 0.03,
      "totalLivestock": 120,
      "abnormalCount": 4,
      "riskLevel": "关注"
    },
    "lastContactAgeMinutes": 4
  },
  "tiers": [
    {"key": "CRITICAL", "rank": 1, "count": 2},
    {"key": "OBSERVATION", "rank": 2, "count": 1},
    {"key": "TRACKING", "rank": 3, "count": 3},
    {"key": "ARCHIVE", "rank": 4, "count": 2}
  ],
  "livestock": [
    {
      "livestockId": "12",
      "livestockCode": "SL-2024-012",
      "fenceName": "围栏 A-03",
      "dispositionTier": "CRITICAL",
      "rank": 1,
      "recommendedAction": "ISOLATE_NOTIFY_VET",
      "actionStatus": "PENDING",
      "dueAt": "2026-09-26T05:00:00Z",
      "directSourceContact": true,
      "shortestDepth": 1,
      "directContactCount": 3,
      "maxRiskScore": 82,
      "maxRiskLevel": "HIGH",
      "lastContactAt": "2026-09-26T02:56:00Z",
      "lastContactAgeMinutes": 4,
      "health": {
        "currentTemp": 39.8,
        "tempStatus": "FEVER",
        "motilityStatus": "NORMAL",
        "hasActiveHealthAlert": true,
        "aiAnomalyScore": null
      },
      "reasonCodes": ["DIRECT_SOURCE", "NEAR", "LONG_DURATION", "HEALTH_ABNORMAL"],
      "eventIds": [1001, 1002],
      "pathIds": ["P-48-12-4"]
    }
  ],
  "events": [
    {
      "eventId": 1001,
      "from": {"livestockId": "48", "livestockCode": "SL-2024-048"},
      "to": {"livestockId": "12", "livestockCode": "SL-2024-012"},
      "proximityMeters": 3.7,
      "durationMinutes": 22,
      "lastContactAt": "2026-09-26T02:56:00Z",
      "hoursAgo": 4,
      "timeScore": 40,
      "distanceScore": 35,
      "durationScore": 18,
      "riskScore": 93,
      "riskLevel": "HIGH",
      "factorCodes": ["FRESH", "NEAR", "MEDIUM_DURATION"]
    }
  ],
  "network": {
    "sourceLivestockId": "48",
    "maxDepth": 2,
    "nodes": [
      {"livestockId": "48", "livestockCode": "SL-2024-048", "kind": "SOURCE", "dispositionTier": null},
      {"livestockId": "12", "livestockCode": "SL-2024-012", "kind": "CONTACT", "dispositionTier": "CRITICAL"}
    ],
    "edges": [
      {"edgeId": "1001", "fromLivestockId": "48", "toLivestockId": "12", "eventId": 1001, "depth": 1, "riskScore": 93, "riskLevel": "HIGH"}
    ],
    "paths": [
      {"pathId": "P-48-12-4", "livestockIds": ["48", "12", "4"], "edgeIds": ["1001", "1003"], "depth": 2, "riskScore": 143, "riskLevel": "HIGH"}
    ]
  }
}
```

约束：

- `riskScore / riskLevel / factorCodes / path.riskScore` 全部由后端计算。
- `events` 不得沿用现有 20 条截断；接口必须返回窗口内全量或分页全量数据。V1 单牧场数据量可控，先返回全量，后续如超过 500 条再补服务端分页。
- `livestock.fenceName` 当前后端端口缺失时返回 `null`，前端隐藏围栏行，不允许显示 `?`。

### 7.2 处置任务

```http
POST /api/v1/farms/{farmId}/health/epidemic/dispositions
```

```json
{
  "livestockId": 12,
  "sourceLivestockId": 48,
  "actionCode": "ISOLATE_NOTIFY_VET",
  "eventId": 1001
}
```

后端按当前工作台等级校验并创建/更新 `PENDING` 或 `IN_PROGRESS` 任务；如果已有活跃任务则幂等返回现有任务，不重复建单。

```http
POST /api/v1/farms/{farmId}/health/epidemic/dispositions/{dispositionId}/complete
POST /api/v1/farms/{farmId}/health/epidemic/dispositions/{dispositionId}/cancel
```

完成/取消必须记录操作者和时间。取消必须携带原因码。

### 7.3 旧接口兼容

- `GET /health/epidemic` 保留一个过渡版本，内部可委托新聚合服务，避免第三方或旧版本 App 断链。
- `GET /health/epidemic/contacts/{livestockId}` 保留；新前端不再使用。
- `POST /health/epidemic/mark` 与 `DELETE /health/epidemic/mark/{livestockId}` 保留。取消源头标记时同步取消相关 `PENDING / IN_PROGRESS` 处置任务。

## 8. 数据模型

现有 `contact_traces` 已具备 `proximity_meters`、`contact_duration_minutes`、`last_contact_at`、`disease_type`、`marked_at`、`risk_score`、`risk_level`，本期不改其结构。

新增 `epidemic_dispositions`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | BIGSERIAL PK | |
| `farm_id` | BIGINT NOT NULL | FK `farms(id)` |
| `livestock_id` | BIGINT NOT NULL | FK `livestock(id)` |
| `source_livestock_id` | BIGINT | FK `livestock(id)`，可为空 |
| `source_event_id` | BIGINT | FK `contact_traces(id)`，可为空 |
| `tier` | VARCHAR(20) NOT NULL | `CRITICAL / OBSERVATION / TRACKING / ARCHIVE` |
| `action_code` | VARCHAR(40) NOT NULL | 建议动作 |
| `status` | VARCHAR(20) NOT NULL | `PENDING / IN_PROGRESS / COMPLETED / CANCELLED` |
| `reason_codes` | TEXT[] NOT NULL DEFAULT '{}' | 分级理由 |
| `due_at` | TIMESTAMP | 一至三级必填，四级为空 |
| `completed_at` | TIMESTAMP | |
| `completed_by` | BIGINT | FK users，可按现有用户端口调整 |
| `cancel_reason_code` | VARCHAR(40) | |
| `created_at` / `updated_at` | TIMESTAMP NOT NULL | |

索引与约束：

- CHECK 约束限定 tier、action、status 枚举。
- 部分唯一索引：`farm_id + livestock_id` 上仅允许一条 `PENDING / IN_PROGRESS`。
- 索引：`(farm_id, status, due_at)`、`(farm_id, livestock_id)`、`(source_livestock_id)`。

### 8.1 种子数据

新增 Flyway 迁移必须随迁移写入可验证种子，基于现有 farm 1 与 `SL-2024-048` 源头：

| 牛号 | 等级 | 动作 | 状态 |
|---|---|---|---|
| `SL-2024-012` | `CRITICAL` | `ISOLATE_NOTIFY_VET` | `PENDING` |
| `SL-2024-049` | `CRITICAL` | `IMMEDIATE_VET_CHECK` | `PENDING` |
| `SL-2024-050` | `OBSERVATION` | `HEALTH_RECHECK` | `PENDING` |
| `SL-2024-004` | `TRACKING` | `CONTINUE_TRACING` | `PENDING` |
| `SL-2024-008` | `ARCHIVE` | `ARCHIVE_ONLY` | `PENDING` |

种子必须幂等，不覆盖已有用户处理状态。部署后通过新接口 curl 验证五级/五类任务字段非空。

## 9. i18n

所有用户可见文案进入 `app_zh.arb` / `app_en.arb`，后端服务端消息进入 `messages_zh.properties` / `messages_en.properties`。禁止硬编码。

必须覆盖：

| 分类 | 示例 |
|---|---|
| 标题与Tab | 疫病防控、处置、记录、链路 |
| 源头 | 疑似源头、已确认染病、未标记、标记时间、多源头 |
| 处置等级 | 一级立即隔离、二级重点观察、三级常规追踪、四级归档备查 |
| 动作 | 隔离并通知兽医、立即检查、健康复核、继续追踪、归档备查、标记观察、完成、取消 |
| 时间 | 2 小时内、4 小时内、24 小时内、72 小时内、剩余时间、已逾期 |
| 记录 | 高风险、中风险、低风险、距离、持续、时间、成因 |
| 链路 | 第一层接触、二层路径、高风险路径、累计风险、调查结论 |
| 状态 | 加载中、暂无接触、窗口内无记录、无高风险路径、加载失败、重试 |
| 导出 | 应急报告、接触记录导出、调查报告 |

中英 placeholder 类型和数量必须一致；`flutter gen-l10n` 无缺失。

## 10. 观测与审计

- 新接口记录结构化日志：`farmId`、`sourceLivestockId`、`windowHours`、耗时、事件数、路径数；不打印牛群全量数据。
- 处置创建、完成、取消记录操作者、时间、来源事件和等级。
- 分级阈值使用配置项，修改配置应有审计或发布记录。

## 11. 验收标准

1. 视觉：三视图、四级处置卡、记录卡、链路图与统一原型 1:1；颜色、字号、圆角、阴影和状态无自由发挥。
2. 交互：处置 ↔ 记录 ↔ 链路跳转不丢上下文；Tab 切换不重置数据和时间窗。
3. 数据：同一时间窗内概览、记录、链路和处置数量一致；风险分数全部来自后端。
4. 分级：Spec §3.3 每条规则都有单测；healthSignal、深度、旧接触、无事件边界均有覆盖。
5. 兼容：旧接触详情路由可跳转新工作台；旧 epidemic API 不删除。
6. i18n：中英同步，长英文不溢出；`flutter gen-l10n` 和 `flutter analyze` 通过。
7. 状态：加载、空态、错误、Premium 锁定、已完成处置均可用。
8. 迁移：全新库执行通过；种子任务 curl 验证非空。
9. 部署：dev 环境 `main.dart.js` hash 一致，种子账号登录 200，新接口业务字段非空。
10. 收口：浏览器走查三视图主旅程并截图留证。

## 12. 待业务确认

以下采用默认值实现，不影响结构与交互；业务方确认后只改配置或阈值：

1. 一级判定中的风险 70/80、时间 24h、时限 2/4 小时是否需要按病种调整。
2. `tempStatus = ELEVATED` 是否算健康信号。V1 不算。
3. AI 异常分数是否可单独触发升级。V1 仅作为展示信号，不单独升级等级。
4. WORKER 是否允许完成一级隔离。V1 默认 WORKER 可标记观察和上传完成，一级隔离必须 OWNER / B2B_ADMIN 确认。
