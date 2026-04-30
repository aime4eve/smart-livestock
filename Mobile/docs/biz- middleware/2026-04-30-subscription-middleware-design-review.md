# 订阅管理中台详细设计 — 评审报告

> **评审基准**: `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` v1.3
> **评审对象**: `docs/biz-middleware/订阅管理中台详细设计文档.md` v1.0
> **评审日期**: 2026-04-30
> **评审修订**: v2（基于"中台面向多业务系统"背景重新分类问题）
> **评审结论**: **有条件通过 — 需补齐 6 项中台层缺陷 + 明确 4 项职责边界**

---

## 零、评审视角与职责边界

本次评审基于一个关键背景：**订阅管理中台是面向智慧畜牧、智慧停车、智慧公寓等多种业务场景的通用能力中心**，而非智慧畜牧专属模块。

这意味着评审需要区分三个层次的职责：

| 层次 | 职责范围 | 示例 |
|---|---|---|
| **中台（本设计）** | 提供通用的订阅交易模型、生命周期管理、计费抽象、权限框架 | 订单/支付/激活/续费/取消的通用流程，SKU 管理的通用数据结构 |
| **业务系统适配层** | 各业务系统基于中台能力实现的领域适配 | 智慧畜牧的"牛数×设备月费"、智慧停车的"车位×月费"、智慧公寓的"房间×月费" |
| **业务前端** | 业务系统专属的 UI/交互逻辑 | LockedOverlay、设备缺失提示、牧场管理后台 |

### 职责判定原则

评审中使用以下原则判定某个需求属于哪一层：

| 判定规则 | 属于中台 | 属于业务系统 |
|---|---|---|
| 多个业务系统是否共用？ | 是 → 中台 | 否 → 业务系统 |
| 是否涉及领域实体（牛、车位、房间）？ | 否 → 中台 | 是 → 业务系统 |
| 变更时是否影响所有接入方？ | 是 → 中台 | 否 → 业务系统 |
| 是否是通用订阅语义？ | 是 → 中台 | 否 → 业务系统 |

基于此视角，原评审中的部分 P0 问题需要降级或重新定位。

---

## 一、总体评价

详细设计文档在 DDD 分层、聚合划分、支付回调幂等、定时补偿等方面工程基础扎实。作为通用订阅中台，其核心交易模型（订单→支付→激活）和 SKU 管理的设计方向正确。

**主要问题不在"设计质量"，而在"中台抽象层的完整性"**：
1. 部分本应由中台提供的通用能力缺失（状态机不完整、续费/取消流程缺失、数据模型不完整）
2. 中台与业务系统的职责边界未明确声明，导致接入方（如智慧畜牧）无法判断哪些需自行实现
3. 缺少对多业务隔离和可扩展性的考虑（business_system_code 仅作为标签使用，未形成隔离机制）

**结论调整**：原报告将 10 项标记为 P0，其中 4 项（设备依赖、角色体系、Feature Flag 清单、智慧畜牧专属 tenant 类型）属于业务系统职责，降级为"中台需提供扩展点但不必实现具体逻辑"。修正后中台层 P0 为 6 项。

---

## 二、P0 级问题（中台层缺陷，必须修复）

### P0-1. 订阅生命周期状态机不完整

**性质**：中台通用能力

**设计现状**：订阅聚合根仅有 `activate()`、`enterGracePeriod()`、`close()` 三个方法。

**缺失状态与方法**：
- `cancel()` — 取消订阅（当前周期结束后降级，这是 SaaS 订阅的标准操作）
- `renew()` — 续费（重置周期起止时间）
- `expire()` — 过期（宽限期结束后自动触发）
- `upgrade()` / `downgrade()` — 升降级（改变 SKU/tier，这是中台通用语义）
- 状态 `trial` → `active` → `grace_period` → `expired`，以及 `active` → `cancelled` → `expired`

**影响**：任何接入的业务系统都需要续费和取消能力。这不是畜牧特有需求——智慧停车的车位月租续费、智慧公寓的房间租赁续费，逻辑完全相同。

**建议**：
1. 定义通用状态枚举：`trial` | `active` | `cancelled` | `grace_period` | `expired`
2. 绘制状态转换图，标注每个转换的触发条件、前置校验
3. 补充聚合根方法签名和业务规则表
4. grace period 时长通过 SKU 配置（不同业务可有不同策略）

### P0-2. 缺少续费、升降级、取消流程

**性质**：中台通用能力

**设计现状**：仅覆盖新购流程（创建订单→支付→激活）。

**缺失流程**：

| 流程 | 通用性说明 |
|---|---|
| 续费（renew） | 所有按周期计费的业务都需要。中台需处理：周期接续计算、金额重算（订阅对象数可能变化）、生成新应收单 |
| 取消（cancel） | 标准 SaaS 操作。中台需处理：当前周期是否继续、到期后状态转换、通知触发 |
| 升级（upgrade） | 套餐变更的通用场景。中台需处理：差价按天折算、立即生效 vs 下周期生效策略 |
| 降级（downgrade） | 通常下周期生效。中台需处理：到期前仍保持当前权益 |

**影响**：没有这些流程，中台只能支持"首次购买"这一个场景，无法支撑任何业务系统的持续运营。

**建议**：为每个流程补充接口定义、流程图、输入输出表、状态转换规则。金额计算策略（如差价折算）应抽象为可配置的计费策略，由 SKU 定义或业务系统传入。

### P0-3. 数据模型不完整

**性质**：中台通用能力

**设计现状**：仅定义了 `payment_transaction_log` 表。缺少 `subscription`、`subscription_order`、`sku`、`notification_record` 等核心表的 DDL。

**缺失内容**：
1. `subscription` 表：subscription_id、tenant_id（通用归属维度）、sku_code、status、current_period_start/end、trial_ends_at、grace_period_ends_at、billing_cycle、price_snapshot（金额快照）
2. `subscription_order` 表：order_id、tenant_id、sku_code、subscription_id（关联）、targets（订阅对象 ID 列表，JSON）、amount_snapshot、order_status
3. `sku` 表：sku_code、sku_name、sku_type（subscription/api）、billing_cycles（支持月/季/年）、pricing_tiers（JSON，多档价格）、trial_config（JSON，试用策略）、quota_config（JSON，API 类 SKU 配额）、status
4. `notification_record` 表：已有方法定义，需补充表结构
5. 金额字段统一为 `DECIMAL(19,2)`，明确单位为"元"

**注意**：中台的 subscription 表存储的是通用金额快照，不包含业务领域字段（如牛数、设备类型）。具体的计费维度（牛数×设备月费、车位×月费）由计费中心或业务适配层计算，中台只存结果。

**建议**：补充所有核心表完整 DDL + 索引设计。

### P0-4. 外部服务接口定义不完整

**性质**：中台通用能力

**设计现状**（Section 4.7）：计费中心、支付中心、消息中心的接口路径已列出，但请求参数和响应结果全部留空。

**建议**：补充以下关键接口的完整 request/response schema：

| 接口 | 需补充的要点 |
|---|---|
| `POST /internal/billing/price/calculate` | 请求：sku_code、targets（订阅对象列表）、billing_cycle、tenant_id；响应：total_amount、price_breakdown（计费明细） |
| `POST /internal/billing/receivable/create` | 请求：order_id、amount、amount_breakdown；响应：receivable_id |
| `GET /internal/billing/payment/status/{orderId}` | 响应：payment_status、payment_transaction_id、payment_time、payment_method |
| `POST /api/v1/payment/create` | 请求：order_id、amount；响应：payment_link、payment_id |
| 消息中心 `sendNotification` | 请求：event_code、subscription_id、user_id、payload |

**关键原则**：中台的外部接口不传领域实体（牛、车位、房间），只传通用维度（sku_code、target 列表、金额）。

### P0-5. 缺少多业务系统隔离机制

**性质**：中台通用能力

**设计现状**：`business_system_code` 作为创建订单的入参存在，但未在数据隔离、权限控制、SKU 可见性等层面发挥作用。所有业务系统的订阅数据混在一起查询。

**影响**：智慧畜牧的订阅订单可能被智慧停车的运营人员看到；SKU 无业务系统归属，A 系统可购买 B 系统的 SKU。

**建议**：
1. 所有核心表增加 `business_system_code` 字段并建立索引
2. 查询接口默认按 `business_system_code` 过滤（从请求上下文/Token 中提取）
3. SKU 增加 `applicable_system_codes` 字段（控制哪些业务系统可见）
4. 中台管理后台（如有）支持按业务系统切换视图

### P0-6. 试用转付费流程未展开

**性质**：中台通用能力（DD-TRIAL-003 已列出但仅一行方法名）

**设计现状**：`convertTrialToPaid` 在功能模块清单中出现，但缺少输入输出定义、流程图、业务规则。

**建议**：
1. 定义接口：`POST /api/v1/subscription/{id}/convert-trial`
2. 输入：sku_code（转付费的 SKU）、targets（可选，调整订阅对象）、billing_cycle
3. 业务规则：试用期数据保留、转付费后周期从转付费时间起算、生成新订单走支付流程
4. 输出：order_id（需支付）、新周期起止时间

---

## 三、P1 级问题（中台需提供扩展点，具体实现由业务系统负责）

### P1-1. 缺少 tenant 层级与 tier 继承的通用模型

**规格要求**（Section 2.1–2.3）：智慧畜牧有 partner/farm/api 三种 tenant 类型，farm 继承 partner 的 tier。

**评审判断**：partner/farm/api 是畜牧领域概念，不应硬编码到中台。但中台需提供通用的 tenant 层级机制，让业务系统可以自定义类型和继承规则。

**建议**：
1. 中台的 subscription 实体以 `tenant_id` 为归属维度（替代 `user_id`），但中台不定义 tenant 类型
2. 中台提供"查询 tenant 当前有效 tier"的接口，tier 的计算逻辑（含继承）由业务系统的适配层实现
3. 若中台需要自行判断 tier（如 Shaping 场景），可通过回调/扩展点由业务系统提供

### P1-2. 缺少 Feature Flag / Shaping 的通用框架

**规格要求**（Section 4.1–4.1.1）：20 个 Feature Flag，双门控（tier + 设备）。

**评审判断**：具体的 Flag 清单（fence、temperature_monitor 等）是畜牧专属的。但"基于订阅等级控制功能可见性"是中台通用能力——智慧停车也需要按套餐控制"车位监控""月租续费""电子发票"等功能的可见性。

**建议**：
1. 中台 SKU 定义中增加 `feature_flags: JSON` 字段，存储"该 SKU 包含哪些功能 key"
2. 中台提供"查询某订阅的 feature 可用性"接口：输入 subscription_id，输出 `{ feature_key: boolean }[]`
3. 具体的 feature key 定义、门控规则（tier 门控 + 设备门控）由业务系统在 SKU 配置中声明
4. 中台不实现 Shaping 中间件——这是业务系统的前端逻辑（不同业务的 UI 展示逻辑不同）

### P1-3. 角色体系

**规格要求**（Section 3.1–3.5）：5 个角色，权限矩阵。

**评审判断**：platform_admin/owner/worker/b2b_admin/api_consumer 是畜牧专属角色。但中台需要通用的"操作者身份 + 权限级别"抽象。

**建议**：
1. 中台接口鉴权层定义通用角色：`admin`（中台运营）、`subscriber`（订阅者）、`viewer`（只读）
2. 业务系统通过适配层将自身角色映射到中台角色（如畜牧的 owner → subscriber，platform_admin → admin）
3. 中台的权限模型关注"谁能操作哪些订阅"，不关注"谁能操作哪些牛/车位/房间"

### P1-4. 设备依赖检查

**规格要求**（Section 4.1.1）：device_gate 规则表。

**评审判断**：设备依赖是畜牧领域概念。智慧停车没有"牛戴设备"的概念，它的门控可能是"车位是否安装了地磁传感器"。中台不应内置 device_gate。

**建议**：
1. 中台在 SKU 的 feature_flags 中支持 `required_conditions: JSON` 字段，业务系统可自定义前置条件
2. 中台的"查询 feature 可用性"接口只做 tier 级别的判断，输出 `{ locked: boolean, upgradeTier: string | null }`
3. 业务系统在拿到中台的 tier 门控结果后，叠加自身的领域门控（如畜牧的 device_gate、停车的 sensor_gate），输出 `{ deviceLocked: boolean, deviceMessage: string | null }`

### P1-5. 三层计费模型的通用化

**规格要求**（Section 4.2）：设备月费 + Tier 月费 + API 增值三层计费。

**评审判断**：具体的计费公式（牛数×设备单价）是畜牧专属的。但"订阅费用由多个计费维度组成"是通用需求——智慧停车可能按"车位数×单价 + 套餐月费"，逻辑结构类似。

**建议**：
1. 中台的 subscription 和 order 存储通用金额快照：`total_amount` + `price_breakdown: JSON`（结构由计费中心定义）
2. 计费中心负责具体的计费公式，中台不内置任何计费逻辑
3. 中台的创建订单接口接收 `amount` + `amount_breakdown`（可选，透传计费中心的拆分结果），不强制三层结构

### P1-6. 领域事件缺少消费方定义

事件清单（附录 A）列出了 9 个事件，但未定义消费方和 payload 结构。建议补充：
1. 每个事件的 payload JSON schema
2. 至少标注 1 个典型 consumer（如 `SubscriptionActivatedEvent` → 通知服务 + 业务系统适配层）
3. 明确事件发布方式（RocketMQ Topic 命名规则，是否区分业务系统）

### P1-7. 定时任务缺少关键配置

5 个定时任务缺少：分布式锁机制、超时策略、执行记录表设计、失败告警通道。

### P1-8. 缺少灰度/降级策略

设计文档未提及分阶段交付范围。建议新增"Phase 范围"小节，明确哪些功能在哪个阶段交付。

---

## 四、设计亮点（值得保留）

| 方面 | 说明 |
|---|---|
| DDD 聚合划分 | 订单/订阅/SKU/API账户 四个聚合边界清晰，符合"一个事务只修改一个聚合"原则 |
| 支付回调幂等 | 支付流水号幂等键 + 事务内原子操作 + 定时任务兜底，三层保障完善 |
| 通知补偿机制 | 通知失败进入补偿队列 + 最大重试次数 + 告警，确保关键消息送达 |
| 防腐层设计 | BillingCenterGateway / PaymentCenterGateway / MessageCenterGateway 隔离外部系统依赖 |
| 程序结构设计总表 | DD-ID + SD-ID + 类名 + 方法名 + 输入输出 + 代码路径，可追溯性好 |
| 通用 SKU 模型 | SKU 支持订阅类和 API 类，可配置计费周期、价格档位、试用策略，具备跨业务复用能力 |

---

## 五、差距汇总表（修订版）

> **分类标准**：P0 = 中台层缺失的通用能力，必须修复；P1 = 中台需提供扩展点，具体逻辑由业务系统实现

| # | 级别 | 差距项 | 性质 | 修复方 |
|---|---|---|---|---|
| 1 | P0 | 订阅生命周期状态机不完整 | 中台通用 | 中台 |
| 2 | P0 | 缺少续费/升降级/取消流程 | 中台通用 | 中台 |
| 3 | P0 | 数据模型不完整（缺核心表 DDL） | 中台通用 | 中台 |
| 4 | P0 | 外部服务接口 schema 留空 | 中台通用 | 中台 |
| 5 | P0 | 缺少多业务系统隔离机制 | 中台通用 | 中台 |
| 6 | P0 | 试用转付费流程未展开 | 中台通用 | 中台 |
| 7 | P1 | tenant 层级与 tier 继承模型 | 中台提供扩展点 | 中台 + 业务适配层 |
| 8 | P1 | Feature Flag / Shaping 通用框架 | 中台提供扩展点 | 中台 + 业务适配层 |
| 9 | P1 | 角色体系通用化 | 中台提供扩展点 | 中台 + 业务适配层 |
| 10 | P1 | 设备/传感器依赖检查 | 业务系统专属 | 业务适配层 |
| 11 | P1 | 多维度计费模型通用化 | 中台提供扩展点 | 中台 + 计费中心 |
| 12 | P1 | 领域事件消费方定义 | 中台通用 | 中台 |
| 13 | P1 | 定时任务配置 | 中台通用 | 中台 |
| 14 | P1 | 灰度/降级策略 | 中台通用 | 中台 |

---

## 六、修复优先级建议

四批修复按依赖关系排序：前一批的产出是后一批的输入。每批内部的项目可并行推进。

---

### 第一批：核心数据模型与状态机（基础设施层）

> **目标**：补齐中台最底层数据基础——没有完整的数据模型和状态机，后续所有流程都无法设计。
> **通用性说明**：状态机和数据表是所有业务系统（畜牧/停车/公寓）的共享基础设施。

| 修复项 | 具体工作 | 产出物 |
|---|---|---|
| **P0-1 状态机** | 1. 定义通用状态枚举：`trial` → `active` → `cancelled` → `grace_period` → `expired`<br>2. 绘制状态转换图，标注触发条件、前置校验、副作用<br>3. 补充聚合根方法：`cancel()`、`renew()`、`expire()`、`enterGracePeriod()`、`exitGracePeriod()`、`upgrade()`、`downgrade()`<br>4. grace period 时长通过 SKU 的 `trial_config` 或 `billing_config` 配置（不同 SKU 可有不同策略） | 状态机转换图 + 方法签名 + 业务规则表 |
| **P0-3 数据模型** | 1. 补充 `subscription` 表 DDL：subscription_id、tenant_id、sku_code、status、current_period_start/end、trial_ends_at、grace_period_ends_at、billing_cycle、price_snapshot（DECIMAL）、price_breakdown（JSONB）、business_system_code<br>2. 补充 `subscription_order` 表 DDL：order_id、tenant_id、sku_code、subscription_id、targets（JSONB，通用订阅对象 ID 列表）、amount_snapshot、price_breakdown（JSONB）、order_status、expired_at、business_system_code<br>3. 补充 `sku` 表 DDL：sku_code、sku_name、sku_type、billing_cycles（JSONB）、pricing_tiers（JSONB）、trial_config（JSONB）、quota_config（JSONB）、feature_flags（JSONB）、applicable_system_codes（JSONB）、status、business_system_code<br>4. 补充 `notification_record` 表 DDL<br>5. 金额字段 DECIMAL(19,2)，单位"元" | 5 张核心表完整 DDL + 索引设计 |
| **P0-5 多业务隔离** | 1. 所有核心表增加 `business_system_code` 字段 + 索引<br>2. 定义隔离策略：查询接口默认按 business_system_code 过滤（从请求头/Token 中提取）<br>3. SKU 增加 `applicable_system_codes` 字段控制可见性<br>4. 编写隔离规则说明文档（什么场景下需要跨系统查询，如 platform_admin） | 隔离策略文档 + 表结构变更 |

**第一批完成标志**：设计文档中有完整的通用状态机（5 种状态 + 7 个转换方法）、5 张核心表 DDL（含 business_system_code 隔离字段）、多业务隔离规则说明。

---

### 第二批：完整业务流程（应用层）

> **目标**：补齐"新购→续费→升降级→取消→试用转付费"完整生命周期，让中台能支撑任何按周期计费的业务。
> **前置依赖**：第一批的状态机（P0-1）和数据模型（P0-3）已就绪。
> **通用性说明**：续费/取消/升降级是所有 SaaS 订阅的标准操作——车位月租续费和牧场套餐续费，在中台层面逻辑完全相同。

| 修复项 | 具体工作 | 产出物 |
|---|---|---|
| **P0-2 续费/升降级/取消** | **续费（renew）**：<br>1. 定义 `POST /api/v1/subscription/{id}/renew` 接口<br>2. 入参：targets（可选，调整订阅对象）、billing_cycle<br>3. 逻辑：调用计费中心重新计算金额 → 生成新订单 → 支付成功后重置周期<br>4. 续费金额计算由计费中心负责（中台不内置公式）<br><br>**取消（cancel）**：<br>1. 定义 `POST /api/v1/subscription/{id}/cancel` 接口<br>2. 策略参数：`immediate`（立即生效）或 `end_of_period`（当前周期结束后生效），策略由 SKU 配置决定<br>3. 逻辑：更新状态为 cancelled → 到期后自动转 expired → 触发通知<br><br>**升降级（upgrade/downgrade）**：<br>1. 定义 `POST /api/v1/subscription/{id}/change-sku` 接口<br>2. 入参：new_sku_code、effective_time（immediate / next_cycle）<br>3. 逻辑：差价按天折算 → 生成补差订单或下周期生效 → 触发通知<br>4. 每个流程需包含：流程图、输入输出表、状态转换、异常处理 | 3 个接口定义 + 3 张流程图 + 状态转换规则 |
| **P0-6 试用转付费** | 1. 定义 `POST /api/v1/subscription/{id}/convert-trial` 接口<br>2. 入参：sku_code、targets（可选）、billing_cycle<br>3. 逻辑：校验当前状态为 trial → 生成付费订单 → 支付成功后更新状态为 active，周期从转付费时间起算<br>4. 试用期数据保留规则 | 接口定义 + 流程图 + 业务规则 |

**第二批完成标志**：设计文档覆盖完整的订阅生命周期（试用→新购→续费→升级→降级→取消→试用转付费），每个流程有接口定义、流程图、状态转换规则。

---

### 第三批：外部接口与可扩展性（集成层）

> **目标**：补齐中台与外部系统的集成契约，以及中台对业务系统的扩展点定义。
> **前置依赖**：第一批的数据模型（P0-3）已就绪。
> **通用性说明**：计费/支付/消息中心是中台的标准外部依赖；扩展点是多业务接入的前提。

| 修复项 | 具体工作 | 产出物 |
|---|---|---|
| **P0-4 外部服务接口** | 补充 5 个接口的完整 request/response schema：<br>1. `calculatePrice`：请求含 sku_code + targets + billing_cycle；响应含 total_amount + price_breakdown（JSONB，结构由计费中心定义）<br>2. `createReceivable`：请求含 order_id + amount + amount_breakdown<br>3. `queryPaymentStatus`：响应含 payment_status + transaction_id + payment_time<br>4. `createPayment`：请求含 order_id + amount；响应含 payment_link<br>5. `sendNotification`：请求含 event_code + subscription_id + user_id + payload | 5 个接口完整 schema |
| **P1-1 tenant 层级扩展点** | 1. 中台以 `tenant_id` 为订阅归属维度（取代 `user_id`），不定义 tenant 类型<br>2. 提供 `GET /api/v1/subscription/{id}/effective-tier` 接口：由业务适配层实现 tier 解析逻辑（含继承链），中台透传结果<br>3. 或定义 SPI/回调：中台需要判断 tier 时，通过扩展点调用业务系统的 tier 解析服务 | tenant 扩展点设计 + SPI 定义 |
| **P1-2 Feature Flag 框架** | 1. SKU 的 `feature_flags`（JSONB）存储该 SKU 包含的功能 key 列表<br>2. 中台提供 `GET /api/v1/subscription/{id}/features` 接口：返回当前订阅可用的 feature key 列表<br>3. 具体的门控逻辑（tier 门控 + 领域门控）由业务系统实现 | Feature Flag 数据结构 + 查询接口定义 |
| **P1-3 角色通用化** | 1. 中台定义通用角色：`admin`（中台运营全量）、`subscriber`（订阅者，操作自有订阅）、`viewer`（只读）<br>2. 业务系统通过适配层映射自身角色 | 通用角色模型 + 映射规则 |
| **P1-5 计费模型通用化** | 1. subscription/order 存储 `price_breakdown`（JSONB），结构由计费中心定义<br>2. 中台不内置任何计费公式，全部委托计费中心<br>3. 创建订单时接收计费中心返回的 breakdown 并透传存储 | 计费抽象层设计 |

**第三批完成标志**：5 个外部接口 schema 不留空；中台为业务系统定义了 tenant/tier 继承、Feature Flag、角色、计费四个扩展点；业务系统接入方清楚知道"中台提供什么、我需要实现什么"。

---

### 第四批：质量提升（非阻塞）

> **前置依赖**：无硬依赖，可与第一至三批并行。

| 修复项 | 具体工作 | 预估工作量 |
|---|---|---|
| **P1-4 设备/传感器依赖** | 明确写入文档："设备依赖检查由业务系统在适配层实现，中台不内置" | 小（约 0.5 天） |
| **P1-6 领域事件消费方** | 为 9 个事件定义 payload JSON schema 和典型 consumer；明确 RocketMQ Topic 命名规则 | 小（约 0.5 天） |
| **P1-7 定时任务配置** | 补充分布式锁策略、task_execution_log 表 DDL、超时阈值、失败告警通道 | 小（约 0.5 天） |
| **P1-8 灰度/降级策略** | 新增"Phase 范围"小节，明确分阶段交付内容和降级方案 | 小（约 0.5 天） |

---

### 修复批次依赖关系

```
第一批（基础）  ──→  第二批（流程）  ──→  第三批（集成）
   │                    │
   │  状态机             │  续费/取消/升降级
   │  数据模型           │  试用转付费
   │  多业务隔离         │
   │                    │
   └────────────────────┘
                        │
                   第四批（质量）← 可与任意批次并行
```

---

### 中台 vs 业务系统：修复职责矩阵

| 修复内容 | 中台负责 | 智慧畜牧适配层负责 | 智慧停车适配层负责 |
|---|---|---|---|
| 订阅状态机 | 定义 5 种状态和转换规则 | 使用 | 使用 |
| 续费/取消/升降级接口 | 实现通用流程 | 调用 | 调用 |
| 数据模型（DDL） | 设计和实现通用表 | 无 | 无 |
| 多业务隔离 | business_system_code 过滤 | 无 | 无 |
| 外部接口 schema | 定义和实现 | 无 | 无 |
| tenant 层级 | 提供扩展点/SPI | 实现 partner/farm/api 三类型 + tier 继承 | 实现 group/parking_lot 两类型 |
| Feature Flag | SKU.feature_flags 存储 + 查询接口 | 定义 20 个畜牧 Flag + tier 门控 | 定义停车 Flag + 套餐门控 |
| 角色映射 | admin/subscriber/viewer 三角色 | owner→subscriber, worker→viewer | 物业经理→subscriber, 租户→viewer |
| 设备依赖检查 | 不实现（声明职责边界） | 实现 device_gate（牛→GPS/胶囊） | 实现 sensor_gate（车位→地磁） |
| 计费公式 | price_breakdown 存储 | 计费中心实现"牛数×设备月费" | 计费中心实现"车位×月费" |

---

## 七、结论

**修订后评审结论：有条件通过。**

设计文档的 DDD 工程基础扎实，SKU 模型的通用设计方向正确。6 项 P0 问题属于中台必须具备的通用能力（状态机、续费/取消、数据模型、外部接口、多业务隔离、试用转付费），不涉及任何业务领域耦合，建议优先修复。

4 项 P1 问题（tenant 继承、Feature Flag、角色、计费模型）的核心修复策略是：**中台提供扩展点/SPI，业务系统在适配层实现具体逻辑**。这确保中台保持通用性的同时，智慧畜牧的规格需求也能得到满足。

**建议下一步**：
1. 按第一批→第二批→第三批顺序修复 P0，每批完成后做一轮轻量评审
2. P1 的扩展点设计建议与第一批并行推进（扩展点影响数据模型，需尽早确定）
3. 修复完成后，智慧畜牧团队基于中台扩展点编写"畜牧业务适配层设计"文档
