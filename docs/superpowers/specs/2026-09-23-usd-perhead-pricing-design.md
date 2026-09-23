# USD 按头/月订阅定价改造设计（NIX-245）

> 日期：2026-09-23 ｜ 分支 `nix/usd-perhead-pricing` ｜ Linear：NIX-245
> 状态：已批准实施（用户批准定价方案与影响面评估后执行）

## 1. 背景与决策链

1. 丹麦客户询问订阅费 → 欧洲竞品定价调研（Obsidian `10-Projects/02-smart-livestock/2026-09-23-欧洲竞品订阅定价调研-丹麦客户报价参考.md`）：SenseHub GO ≈$3.80/头/月全包（硬件含、5 年合同）为行业标杆；我方旧示例价折算仅 €1-4/头/年，低一个数量级。
2. 用户裁决：**统一美元报价；硬件客户自购 $65/台；订阅价 = 竞品 5 年 TCO 的 85%**。
3. 85% 作用在 **5 年总拥有成本**而非月费名义价：硬件 $65 + 订阅 × 48 个月（首年免费）= 85% × 竞品 5 年全包 $228/头 → 订阅 **$2.65/头/月**（100-499 档）。
4. 默认裁决（推荐执行）：取消付费档头数硬上限（仅 BASIC ≤50）；删除固定折扣表（billingCycle 字段保留）；跳过 HTML 原型（布局不变仅内容）。

## 2. 定价事实（唯一价格真源）

- **币种**：USD 全球统一、不含 VAT
- **硬件**：一次性客户自购 $65/台（项圈/耳标/胶囊统一；设备归客户所有）；LoRaWAN 网关按牧场另报
- **软件订阅**（$/头/月，存栏规模分档）：

| 档位 | ＜100 头 | 100–499 头 | ≥500 头 | 数据保留 |
|---|---|---|---|---|
| BASIC | 免费（≤50 头硬上限） | — | — | 7 天 |
| STANDARD | $2.60 | $2.15 | $1.40 | 30 天 |
| PREMIUM | $3.20 | $2.65 | $1.75 | 90 天 |
| ENTERPRISE | 定制（买断 ≈36 个月订阅价 + 20%/年维保） | | | 3 年 |

- 计费公式：`月费 = 存栏头数 × 所在规模档单价`（美分整数运算）
- 首年免费 = 既有 365 天试点授权（`CloudPilotLicenseService`，不改动）；14 天自助试用不变；正式订阅以 5 年期人工合同为主

## 3. 后端设计

- `SubscriptionTier` 枚举：内嵌 `record PriceBand(minHead, maxHead=-1 无上界, unitPriceUsdCents)`；`calculateMonthlyFee(headcount) = bandOf(headcount).unitPrice × headcount`；ENTERPRISE 空带保持 `ENTERPRISE_CUSTOM_PRICING`；`livestockCap` 字段（BASIC=50，其余 -1）仅作配额镜像展示。
- `bandFor` 对低于最低档的头数（含 0）回落第一档——0 头自然算 $0。
- `SubscriptionAssembler` 费用计算统一调用 `calculateMonthlyFee`（消除原第二处独立实现）。
- API 契约（app-api.md §6 已同步）：
  - `/subscription/plans` → `{tier, currency:"USD", billingUnit:"per_head_month", customPricing, livestockCap, priceBands[]}`
  - `/subscription`、`/subscription/usage` → 增 `livestockCount/currency/livestockCap/applicableBand/unitPriceUsdCents/monthlyFeeUsdCents`；删 `calculatedTierFee/calculatedDeviceFee/calculatedTotal` 与 `monthlyPriceCents/includedLivestock/overagePriceCents`
- Flyway `V20260923120000`：`feature_gates.livestock_management` standard/premium 从 `limit 200/1000` 改 `none`（无限额与 enterprise 同语义；LIMIT 分支无 -1 无上限语义，故必须改 gate_type 而非 limit_value）。
- billingCycle（monthly/yearly）字段与 DB CHECK 保留，语义降为合同登记。

## 4. 前端设计

- 修复存量断裂：ApiClient 将 List 响应包成 `{'value': [...]}`，旧仓库解析 `data['items']` 永远为空 → 前端一直显示本地写死价（且与后端不一致）。新仓库解析 `value`，删除本地价格表与 fallback。
- 模型：`SubscriptionTierInfo` 只留 features 展示配置；新增 `PlanInfo`/`PriceBand`（与后端同构的带计算）；`SubscriptionStatus` 换新费用字段。
- UI：tier 卡主价为 100-499 档单价 + 副行展示全部分档；结账页算价唯一走 `PlanInfo.monthlyFeeFor`（消除第四处重复实现）；状态卡显示档位单价 + 月费。
- 币种：`currency_formatter` ¥→$（订阅与 B2B 分账展示统一）。
- l10n：新增 `subPerHeadMonth/subFreeTier/subHeadCapBounded/subHerdBandEntry/subUnitPriceLabel/subMonthlyFeeRow`，删除 9 个人民币旧 key，中英同步。

## 5. 文档与上市材料

事实源链：PRD v2.3 §3（全章重写）→ app-api.md → 上市材料四件套（solution-introduction v1.4 / solution-brochure 三副本 / market-development-kit v1.2 / technical-support-guide v1.2）→ 矛盾收敛（customer-journey §6.1、subscription-guide §3+§六：清除 ¥3/¥2/¥1 超额与设备月费 ¥15/¥30 旧口径，分润基数改订阅费）→ superpowers/培训/售前手册同步。

**对外话术红线**：只宣传"5 年总拥有成本比主流竞品低约 15%，且设备归客户所有"；禁止拿我方订阅月费直接对竞品全包月费比价。

## 6. 验证基线

- 后端：commerce + licensing 单测全绿；`SubscriptionTierTest` 断言按头×档（260×265=68900 等四组）
- 前端：analyze 0 issue；CI 口径 556 测试全绿；契约 fixture 更新为新响应形状（部署 dev 后重录覆盖）
- 集成：dev 部署后 curl /plans、/usage 新契约冒烟 + 浏览器走查套餐/结账/我的页

## 7. 风险与前提

1. **设备 5 年在栏寿命**是定价成立硬前提：若实际 3 年（5 年两台 $130/头），保持 85% TCO 需订阅降至 ≈$2.03/头/月（100-499 PREMIUM）——电池寿命是定价变量，需固件侧确认口径。
2. 锚价 $3.80（SenseHub 丹麦代表价）为推断，正式锁价前建议本地经销询价校准。
3. 老客户（旧口径接触过）次年起的价格沟通需提前一季度铺垫。
4. 系统计费金额与人工合同金额的对账：系统月费为标准价计算，合同折扣以 license/合同登记为准（现状机制不变）。
