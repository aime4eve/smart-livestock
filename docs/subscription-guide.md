一、两个维度：Phase（租户阶段）× Tier（订阅级别）

租户生命周期：

  注册 ──→ SAMPLE（试用期）──→ BATCH（正式期）
           │                    │
           ├ 自动获得 Premium   ├ 须选择 Tier
           ├ 14 天免费          ├ basic / standard / premium / enterprise
           └ 到期自动降 basic   └ 可升级/降级
Phase 是时间维度：租户处于生命周期的哪个阶段
Tier 是功能维度：当前配额和功能范围
试用期 Tier 固定为 Premium；进入 BATCH 后 Tier 由付费决定
二、四种计费模式（billingModel）
billingModel	谁付费	谁收钱	典型场景
direct	牧场主	平台	中小牧场主自助订阅
revenue_share	最终牧场主	Partner 收，按比例分给平台	代理商/集成商代理销售
licensed	B端客户	平台，年费一口价	大集团独立部署
api_usage	第三方开发者	平台，按调用量	数据集成/API 消费
每种 billingModel 对应一种 tenant.type：farm（direct）、partner（revenue_share）、api（api_usage）。licensed 是 partner 的子类型（通过 deploymentType 区分）。

三、Tier 定价与配额
3.1 B2C 订阅定价（direct 模式）
Tier	月费	含牲畜数	超出费用	围栏上限	数据保留	SLA
basic	¥0	50 头	¥3/头/月	3	7 天	99.5%
standard	¥299	200 头	¥2/头/月	5	30 天	99.5%
premium	¥699	1000 头	¥1/头/月	10	90 天	99.9%
enterprise	定制	无限	—	无限	3 年	99.99%
月费计算：基础 Tier 月费 + 超出牲畜数 × 超出单价

3.2 设备月费（独立于 Tier）
GPS 追踪器：¥15/头/月
瘤胃胶囊：¥30/头/月
牧场总设备月费 = ∑(每头牛 × 配置设备 × 单价)
3.3 API 开放平台定价（api_usage 模式）
API Tier	月费	含调用量	超出费用
free	¥0	1000 次/月	—
growth	¥500	10000 次	¥0.01/次
scale	¥2000	100000 次	¥0.005/次
四、核心实体关系

Tenant (1)
 ├── phase: SAMPLE | BATCH
 ├── type: farm | partner | api
 ├── billingModel: direct | revenue_share | licensed | api_usage
 ├── parentTenantId → Tenant  (farm 归属 partner 时非空)
 │
 ├── Subscription (1)
 │    ├── tier: basic | standard | premium | enterprise
 │    ├── status: trial | active | suspended | cancelled | expired
 │    ├── billingCycle: monthly | yearly
 │    ├── startedAt, expiresAt
 │    └── trialEndsAt
 │
 ├── Contract (0..1, B2B 专用)
 │    ├── effectiveTier: standard | premium | enterprise
 │    ├── revenueShareRatio: DECIMAL(5,4)  (分润比例)
 │    ├── status: draft | active | suspended | expired | terminated
 │    └── signedBy, signedAt, startedAt, expiresAt
 │
 ├── SubscriptionService (0..1, licensed 专用)
 │    ├── serviceKey: "SL-SUB-XXXX-XXXX"
 │    ├── status: active | grace_period | degraded | revoked | expired
 │    ├── lastHeartbeatAt
 │    └── gracePeriodDays: 15
 │
 ├── ApiKey (0..*, api 专用)
 │    ├── apiTier: free | growth | scale
 │    ├── key: "sl_apikey_<uuid>"
 │    ├── status: active | suspended | revoked
 │    ├── callQuota, callsUsed
 │    └── rateLimit: 10 calls/min
 │
 └── ApiAuthorization (0..*, api 数据访问授权)
      ├── farmTenantId → Tenant
      ├── requestedScopes: string[]
      └── status: pending | approved | rejected | revoked
五、配额引擎（Tier 门控）
Feature Flag 四种策略：

策略	行为	示例
none	所有 Tier 可用	GPS 定位
lock	指定 Tier 以上才显示	发情检测 ≥ premium
limit	数量按 Tier 上限	围栏数 basic=3, standard=5
filter	数据按 Tier 过滤	告警历史 basic=7天, premium=90天
后端执行位置：在 Service 层或 Interceptor 中检查当前租户的 Tier，超出配额返回 QUOTA_EXCEEDED（已有 ErrorCode）。

六、分润结算流程（B2B 模式）

每月结算周期：
  1. 系统自动计算：每 farm 的牲畜数 × 设备配置单价 = 设备月费
  2. 分润金额 = 设备月费 × revenueShareRatio
  3. 生成 RevenuePeriod 记录，status = pending
  4. 双方确认：platform 确认 → confirmed，partner 确认 → settled
  5. settled 后触发实际打款（线下或系统内）
七、前端已完成 vs 后端待实现
模块	Flutter 前端	Spring Boot 后端
Tier 枚举 + Feature Flag	✅ 4 Tier + 23 Flag	❌ 零实现
订阅 UI（套餐选择/支付确认）	✅ Mock 支付流程	❌ 无端点
B2B 后台（合同查看/用量看板）	✅ 只读展示	❌ 无端点
配额门控 UI（LockedOverlay）	✅ 已实现	❌ 无门控逻辑
牧工管理	✅ 本地操作	⚠️ 端点存在但返回 stub
分润对账	✅ Mock 数据展示	❌ 零实现
API Key 管理	❌ 未实现	⚠️ 端点存在但返回 stub
订阅服务（serviceKey）	❌ 未实现	❌ 零实现
以上是我的完整理解。请看看哪些地方不对、需要调整、或者有遗漏。