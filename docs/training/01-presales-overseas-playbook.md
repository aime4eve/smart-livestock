# 海外解决方案售前实战手册

> 版本：v0.5（2026-08-26）
> 适用对象：海外售前/商务人员，以及参与客户澄清的售后支持人员
> 前置阅读：《智慧畜牧解决方案赋能手册》《智慧畜牧软件平台培训手册》，并浏览 GAT-100 与 RBC-100 设备分册
> 目标：把软件平台、IoT 设备、网络、实施和服务的询盘、回访、需求引导、技术澄清和报价流程变成可复制方法。

## 1. 售前目标

海外售前不是“讲完产品”，而是完成四个判断：

1. 客户是否有真实问题：牲畜丢失、健康风险、人工效率、数据割裂、集团管控。
2. 我们是否有匹配方案：功能、设备、订阅、集成、实施。
3. 客户是否具备落地条件：网络、设备、人员、预算、数据、合规。
4. 下一步是否明确：demo、技术澄清、POC、报价或暂缓。

每次客户接触后，必须能回答：

- 客户角色和决策链是什么？
- 客户最想解决的三个问题是什么？
- 牲畜类型、规模、现有设备和网络条件是什么？
- 我们能确认什么，不能确认什么？
- 下一步动作、负责人和时间是什么？

### 一分钟产品讲稿

```text
Smart Livestock is an IoT-based platform for farms that need better visibility
and faster response. It connects GPS trackers and health sensors, shows animals
on a map, applies geofences and alert workflows, and turns telemetry into
operational data for farm teams.

For a farm owner, it brings livestock, devices, alerts, health analysis, and
subscription control into one workspace. For workers, it keeps the daily
experience simple: map, alerts, and acknowledgment. For an enterprise team, it
provides tenant isolation, farm-level data scope, role-based access, and Open
API integration.

The next step is a short discovery call to confirm your animal types, farm
scale, current devices, network coverage, and the problem you want to improve
first. We can then demonstrate the relevant workflow and assess whether a
technical pilot is needed.
```

### 30 秒电梯版

> We help farms turn GPS and health sensor data into faster action: animals are visible on a map, geofence breaches create alerts, workers acknowledge them, and owners close the loop. The platform also supports multi-farm access control, subscription tiers, and API integration for enterprise systems.

## 2. 询盘分级

| 级别 | 判断特征 | 首次响应重点 | 下一步 |
|---|---|---|---|
| A：高意向 | 有明确规模、时间表、预算或痛点 | 当日响应，确认关键需求 | 技术澄清 + demo |
| B：潜在有效 | 有兴趣但需求模糊 | 价值介绍 + 需求问卷 | 电话/视频会议 |
| C：调研比价 | 主要问价格、功能清单、竞品对比 | 给能力框架，不承诺定制 | 长期跟进 |
| D：无效或不匹配 | 无牲畜管理场景或需求超出边界 | 礼貌说明适合场景 | 记录原因后关闭 |
| E：合作伙伴 | 渠道、集成商、设备商合作 | 明确合作类型和能力边界 | 转商务/产品负责人 |

> 首次响应时限待业务确认。确认前建议内部按“重要询盘当日响应，普通询盘 1 个工作日内响应”执行。

## 3. 首次响应模板

```text
Subject: Smart Livestock Platform - Next Steps for Your Requirements

Dear [Name],

Thank you for your interest in the Smart Livestock platform.

To make our response accurate, could you share more about:
1. Your farm scale, animal types, and current management process.
2. The devices and connectivity already available on-site.
3. The main problem you want to improve first: animal loss, health monitoring,
   daily inspection efficiency, or system integration.

We can then arrange a short online session to demonstrate the relevant
workflows and confirm whether a technical assessment is needed.

Best regards,
[Your name]
```

使用规则：

1. 首次回复不发送长篇功能清单。
2. 客户预算和规模未明确前，不主动报价。
3. 不承诺设备兼容性、SLA、数据驻留或 AI 精度。
4. 每封邮件必须有一个明确下一步。

## 4. 需求引导问卷

### 业务概况

1. How many farms and animals are involved?
2. What animal types and production models do you manage?
3. Who will use the platform daily: farm owner, workers, or a central team?
4. What is your current process when an animal is missing or sick?
5. Which problem do you want to improve first?

### 设备与网络

1. Do you already use GPS trackers, rumen capsules, or other sensors?
2. What are the device models and vendors?
3. How do these devices upload data today?
4. What is network coverage like across the farm?
5. Will you purchase new devices or integrate existing devices?
6. Which GAT-100 reporting interval matches your operation: 30 minutes by default, shorter for more responsiveness, or longer for battery life?
7. Do you need RBC-100 for rumen temperature and motility, and who will perform bolus administration?
8. Which regional LoRaWAN frequency band is required, and has gateway coverage been surveyed?

### 工作流与告警

1. Who should receive alerts?
2. What response time do you expect after a geofence breach or health alert?
3. How should workers confirm and handle alerts?
4. Do you need historical evidence for insurance, audits, or internal review?

### 集成与数据

1. Do you need API integration with an existing system?
2. Which data objects and update frequency are required?
3. Do you need data export, reporting, or BI integration?
4. Do you have data residency or privacy requirements?

### 商务与实施

1. What is your expected go-live timeline?
2. Who will install and maintain the devices?
3. What is your budget range and procurement process?
4. Which subscription and support level are you expecting?

## 5. 需求到价值翻译

| 客户问题 | 不够好的回答 | 推荐英文回答 |
|---|---|---|
| Animals are hard to find | We have GPS | GPS tracking and geofence alerts help you identify animals outside the expected area and dispatch workers more quickly. |
| Patrol takes too much labor | You can use a map | The map and alert workspace help your team prioritize inspections instead of doing routine patrols blindly. |
| Health issues are found too late | We have a health score | With compatible sensors, the platform analyzes individual telemetry and raises alerts to support earlier review and treatment decisions. |
| We manage multiple farms | We support farms | The platform separates farms, roles, and data access, so a central team can manage multiple farms while workers only see what they need. |
| We need integration | We have APIs | Open API access can be enabled for approved data scopes. We need to review your integration requirements, frequency, and security policy. |
| The price is too high | Discount | Let us align on farm scale, sensors, subscription tier, and support scope, then propose a phased option. |

### 需求到功能匹配表

| 客户说 | 优先演示 | 演示结束时要确认 |
|---|---|---|
| I do not know where my animals are | 地图概览、牲畜位置、设备状态 | 现场网络和设备上传频率 |
| Animals leave the allowed area | 围栏、越界告警、告警状态流 | 谁接收告警、谁确认、谁处理 |
| Inspection takes too long | 地图、历史轨迹、Dashboard | 现有巡查人数、耗时、目标改善 |
| We find illness too late | 发热、消化、发情、疫病或异常检测 | 畜种、传感器、兽医流程 |
| We have many farms and workers | 租户、牧场、角色、权限 | 组织结构和数据隔离要求 |
| We need our own system to receive data | Open API、API Key、调用统计 | 数据对象、频率、安全策略 |
| We want to start small | 订阅层级、Feature Gate、试点方案 | 试点范围、成功标准、扩展节奏 |

### 客户价值量化提问

不要直接问“你愿意花多少钱”，先把业务损失和人工成本问清楚：

1. How many animals were lost, injured, or treated too late in the last 12 months?
2. What was the financial value of each incident?
3. How many hours do workers spend on patrol and searching?
4. How long does it take from discovering an issue to acting on it today?
5. What does a missed estrus or delayed treatment cost in your operation?
6. How much time is spent consolidating reports from farms or systems?

得到数字后，用解决方案赋能手册中的价值公式做初步量化。客户没有数据时，可建议 POC 采集基线，不编造行业平均值。

### 解决方案组合配置

| 方案包 | 硬件组合 | 平台能力 | 适用客户 | 售前必确认 |
|---|---|---|---|---|
| 定位防丢版 | GAT-100 + 网关 | 地图、轨迹、围栏、越界告警 | 放牧牛羊、大范围牧场、走失风险高 | 频段、覆盖、上报周期、电池寿命、防拆是否定制 |
| 健康监测版 | RBC-100 + 网关 | 温度、胃动力、健康趋势、异常提示 | 疾病早发现、兽医服务、科研场景 | 投服能力、协议版本、现场覆盖、数据量 |
| 定位健康完整版 | GAT-100 + RBC-100 + 网关 | 体表 + 体内数据形成个体档案 | 中高价值牛群、繁殖和健康管理 | 设备与牲畜绑定、佩戴/投服流程、试点范围 |
| 繁殖管理版 | RBC-100 + GAT-100 | 发情和活动趋势辅助、个体档案 | 想降低空怀天数、提高配种时机判断 | 畜种适配、人工确认流程、繁殖指标 |
| 保险监管版 | RBC-100 + 平台 API | 个体身份、健康与在线状态数据 | 活体抵押、保险监管 | 数据披露范围、责任边界、接口频率 |
| 企业集成版 | 按牧场选择设备 | Open API、统计、多牧场权限 | 集团、政府/产业平台、集成商 | scope、限流、数据驻留、安全审查 |

方案包只是销售配置框架，不是固定折扣或固定价格。报价前必须完成现场覆盖、畜种、设备数量、实施责任和支持范围评估。

### 硬件售前前检查清单

1. GAT-100：目的国频段、网关覆盖、上报周期、项圈佩戴责任、防拆/温湿度是否需要定制固件。
2. RBC-100：投服团队、投服工具、冷链存储、胶囊编号与牛耳号登记、固件帧格式、不可回收和不可换电池口径。
3. 网络与实施：网关数量、安装位置、供电和回传、现场 RSSI/SNR 摸底、运维责任。
4. 平台：设备注册、License、牲畜档案、围栏、告警通知、订阅层级和数据保留。
5. POC：试点动物数、对照组、时间窗、成功指标、设备回收/清理和退出条件。

### 商业模式匹配

| 客户信号 | 优先模式 | 销售动作 | 不适合的做法 |
|---|---|---|---|
| 单一牧场、owner 决策、想先试用 | direct SaaS 订阅 | 从小规模或标准层级切入，明确设备依赖和升级路径 | 不先看规模就报企业版 |
| 中大型牧场、有设备采购预算 | 设备买断/租赁 + 订阅 | 分别确认设备数量、安装责任、保修和平台服务范围 | 把硬件和订阅混成一句总价 |
| 经销商或渠道带来多客户 | revenue_share | 转商务负责人确认客户归属、服务边界、分润比例和结算周期 | 口头承诺渠道政策 |
| 集团客户要私有化、数据驻留或定制集成 | licensed / enterprise | 先做技术评估，再确认部署、集成、支持和运维责任 | 承诺私有化交付时间 |
| 集成商只要数据接口 | api_usage 或 enterprise 打包 | 确认数据 scope、调用量、频率、限流、SLA 和安全审查 | 直接承诺 API 单价和免费额度 |
| 已有 GPS 或传感器设备 | 平台服务 + 集成评估 | 收集设备型号、厂商、数据格式和可获取权限 | 假设所有设备都能接入 |

### 收费模式销售话术

#### SaaS 订阅

> The subscription defines the feature scope, data retention, quotas, and support level. Device requirements are assessed separately, so you can start with a manageable pilot and expand as coverage proves its value.

#### 设备加订阅

> We can separate the commercial discussion into devices, platform subscription, installation, and support. This makes the pilot scope and long-term cost easier to review.

#### 渠道分润

> For partner-led models, we need to define customer ownership, services delivered by the partner, revenue-share basis, settlement cycle, and contract responsibilities before commercial terms can be confirmed.

#### Licensed / Enterprise

> For private or enterprise deployment, we first confirm hosting, data residency, integration scope, device scale, support model, and upgrade responsibility. License scope and pricing are then defined commercially.

#### API 服务

> Open API access is controlled by API Key scope and rate limits. For a commercial API service, we need to define data objects, call volume, frequency, service level, and security review before pricing.

### 报价前检查清单

1. 客户角色和决策链。
2. 牧场数量、牲畜数量、畜种和扩群计划。
3. 现有设备型号、厂商、数量、通信方式和数据获取权限。
4. 需要新购、租赁还是复用设备。
5. 目标功能、数据保留和 API 需求。
6. 部署方式、数据驻留和合规要求。
7. 实施安装、培训和运维责任。
8. 支持等级、响应时间和值班窗口。
9. 币种、税费、付款周期、折扣审批和发票要求。
10. POC 范围、成功标准、退出条件和后续转化条件。

报价输出建议拆成六栏：设备、平台订阅、实施培训、集成开发、支持服务、税费或其他费用。没有确认的费用不要写“included”，先写“to be confirmed after technical assessment”。

## 6. 竞品对比话术

### 通用竞争定位

```text
Many solutions start with a tracker or a map. We approach the farm as an
operating workflow: device data, livestock records, geofences, alert handling,
health analysis, multi-farm permissions, subscriptions, and API integration
are connected in one platform.

The right comparison is not only feature count. It is whether the solution fits
your animals, connectivity, devices, workflow, and expansion plan.
```

### 竞品 Battlecard

| 竞品 | 客户常见判断 | 我方切入问题 | 我方差异化表达 | 不要说 |
|---|---|---|---|---|
| Halter | 虚拟围栏和牧场数字化认知较强 | Which parts of your team's workflow are not covered by your current tools? | We can connect alert handling, livestock records, devices, multi-farm access, and API integration in one operating workflow. | Halter 能力差 |
| Vence | 北美规模化牧场场景经验 | How do you manage data access across farms and enterprise systems? | Our tenant, farm, role, and API model is designed for centralized operations and integration. | Vence 不专业 |
| Nofence | 小型反刍动物和欧洲市场认知 | Which animal types and fence workflows do you need to support? | We can assess your animal types, sensors, geofence workflow, and health-analysis requirements together. | 我们一定更适合山羊/绵羊 |
| Digitanimal | LoRaWAN 与活动监测经验 | Beyond location and activity, what health and workflow outcomes do you need? | Our platform extends device data into alert closure, health context, subscription control, and enterprise integration. | 对方只是简单追踪 |

### 竞品问题回答框架

1. **确认客户关心点**：price, coverage, animal type, health, integration, local support。
2. **承认合理强项**：竞品在区域案例、品牌或特定场景可能成熟。
3. **转向现场条件**：网络、畜种、设备、组织流程、集成目标。
4. **给出我方差异**：平台闭环、多源数据、权限、API、分阶段方案。
5. **定义验证方式**：demo、技术评估、小规模 POC、客户真实数据指标。

### 竞品对比红线

1. 不使用未复核的竞品价格、电池寿命、精度、案例和覆盖范围。
2. 不贬低竞品或暗示对方产品不可靠。
3. 不把历史研究快照当作当前市场事实。
4. 不在没有实测报告的情况下承诺找回率、准确率、误报率或投资回报率。
5. 竞品材料如要发给客户，必须先由产品、法和商务负责人审批。

## 7. 常见技术问题商务版回答

### 部署方式

> The platform runs as an online service in supported deployments. Deployment options, hosting region, and data residency requirements need to be confirmed during technical and commercial review.

不要直接承诺私有化、专属云、本地部署或指定区域，除非产品和研发已有书面方案。

### 数据安全

> The platform uses tenant-based isolation, role-based access control, JWT authentication for app users, and API Key scope control for external integrations.

客户追问审计、加密细节、合规证书、数据驻留时，转合规/安全负责人。

### 设备接入

> Device compatibility depends on device type, data protocol, vendor platform, and connectivity model. Please share the device list and vendor information for assessment.

需收集厂商、型号、数量、通信制式、数据格式、账号权限和是否可提供测试设备。

### 定位与告警

> Location and alert timeliness depend on device status, network coverage, and the data upload frequency of the selected device plan.

不承诺固定秒级延迟。客户有明确 KPI 时，记录后转技术评估。

### 地图与离线

> The mobile app supports map display and offline tile management. Available regions, offline package size, and update method should be confirmed for your deployment.

不说“完全没有网络也能看所有数据”。

### API 能力

> Open API provides controlled access to approved data scopes with API Key authentication, scope control, and rate limiting.

接口文档、sandbox、调用量、错误码和兼容策略必须走技术资料审批。

### AI 能力

> The platform includes AI-assisted anomaly detection to support farm decisions. It does not replace veterinary diagnosis.

客户询问准确率、召回率、误报率时转研发，并说明需用客户真实数据评估。

## 8. 异议处理

| 客户异议 | 处理思路 |
|---|---|
| We already have GPS devices | 先确认型号和数据可获取性；平台价值在于设备数据、牧场业务、告警和工作流整合 |
| Workers may not use it | 强调 worker 界面聚焦地图、告警和确认动作；培训可按角色拆分 |
| Network coverage is weak | 记录弱网区域和比例；网络与设备方案需技术评估 |
| We want the cheapest option | 用小规模试点设计，但明确设备、功能门控和数据保留边界 |
| Competitors are cheaper | 回到丢失成本、人工成本、健康损失和集成价值，避免单纯比价 |
| You have no overseas case | 不虚构案例；说明当前可提供的 demo、验证流程和支持方式 |
| Can you guarantee results | 可承诺交付和验证流程，不承诺未经真实数据评估的业务结果 |

## 9. 技术问题升级

必须升级的场景：

1. 设备型号、协议、供应商平台兼容性。
2. API scope、限流、集成架构、安全审查。
3. 部署区域、私有化、数据驻留和合规。
4. 网络覆盖、设备规模、并发和延迟 KPI。
5. 历史数据迁移和第三方系统对接。
6. AI 指标、模型效果和 POC 评估方法。
7. API 用量计费、增值服务包、设备租赁和折扣规则。
8. 超出当前订阅层级或合同模板的承诺。

升级模板：

```text
Customer / Opportunity:
Region:
Sales owner:
Customer contact:
Customer goal:

Questions raised:
1. ...
2. ...

Known facts:
- Farm scale:
- Animal types:
- Existing devices:
- Network conditions:
- Timeline:
- Budget range:
- Compliance requirements:

Requested answer:
- Technical feasibility:
- Required devices:
- Deployment/integration impact:
- POC or assessment needed:
- Commercial constraints:

Deadline and reason:
```

升级原则：

1. 售前负责跟进节奏，技术负责人负责技术结论。
2. 技术结论必须书面化。
3. 客户收到结论前，售前先检查是否与产品边界一致。

## 10. 回访节奏

| 阶段 | 建议动作 | 目标 |
|---|---|---|
| 首次沟通后 1-2 个工作日 | 发送会议纪要和待确认清单 | 确认理解一致 |
| Demo 后 1 个工作日 | 发送场景材料和技术问题清单 | 推进技术澄清 |
| 技术澄清后 2 个工作日 | 发送方案范围、POC 或报价前置条件 | 进入商务阶段 |
| 报价后 3-5 个工作日 | 跟进审批、竞品和预算 | 处理阻塞 |
| 长期线索每月一次 | 发送行业内容或产品更新 | 保持有效触达 |

具体频率结合客户时区和商机阶段调整，重要节点以客户承诺日期为准。

## 11. Demo 讲解结构

### 10 分钟解决方案版

1. 客户目标复述：1 分钟。
2. 牲畜数字档案与地图概览：2 分钟。
3. GAT-100 轨迹、围栏与告警处理流程：2 分钟。
4. RBC-100 温度、胃动力与健康趋势，或 Open API 集成，按客户关注点二选一：2 分钟。
5. 设备、网关、实施和平台订阅组合：1 分钟。
6. 现场勘测、POC 和下一步：2 分钟。

讲解原则：

1. 先讲客户场景，再点功能名称。
2. 每个界面说明“谁在什么情况下用它”。
3. 告警必须讲清 pending、acknowledged、handled、archived 的业务含义。
4. 演示 GAT-100/RBC-100 时必须说明数据前置条件和现场勘测要求。
5. Demo 数据只用于演示，不说成客户现场效果。
6. 超出边界的问题当场记录，并说明需要技术确认。

## 12. CRM 最低记录要求

1. 客户公司、国家/地区、时区、联系人角色。
2. 牲畜类型、数量、牧场数量。
3. 现有设备、网络和系统。
4. GAT-100/RBC-100 需求量、上报周期、频段、网关和投服/佩戴责任。
5. 核心痛点排序。
6. 预算和时间表。
7. 适合的商业模型：直订、设备组合、渠道分润、License、API 或 Enterprise 打包。
8. 客户正在比较的竞品和客户认可的对价点。
9. 已承诺事项。
10. 待技术或商务确认事项。
11. 下一步动作、负责人、截止日期。

## 13. 售前红线

1. 不虚构案例、认证、指标或生产效果。
2. 不向客户发送内部账号、环境地址、数据库信息或未审批接口文档。
3. 不用仿真数据证明真实业务效果。
4. 不承诺未确认的设备兼容性、网络效果和延迟。
5. 不承诺 AI 替代兽医或人工决策。
6. 不绕过合同承诺数据所有权、违约责任、赔偿和合规义务。
7. 不模糊订阅配额、数据保留和支持边界。

## 14. 培训练习

1. 给 5 封询盘邮件分级，并分别写首复。
2. 把客户目标匹配到主要功能域，每个目标选择最多 3 个演示点。
3. 把牲畜丢失、巡查慢、健康发现晚、系统割裂翻译成各 3 句英文价值表达。
4. 用客户提供的数字完成一次价值量化，并列出缺失数据和 POC 采集方案。
5. 回答私有化、AI 准确率、设备兼容、离线地图和 SLA 问题，并判断哪些必须升级。
6. 给定 5 个客户画像，分别判断适合的商业模式并列出报价前缺失信息。
7. 针对 Halter、Vence、Nofence、Digitanimal 各写一段不贬低竞品的差异化回答。
8. 用 10 分钟完成场景化 demo，必须包含客户目标、主要功能、角色、告警状态和下一步。

## 15. 待确认清单

### 行业与竞品售前公开基准

> 检索时间：2026-08-25 UTC。以下为内部参考快照，不是可直接对客户引用的审计结论；对外使用前需复核原文、区域页面和资料日期。

| 竞品/来源 | 公开售前口径 | 对我们的启发 | 使用限制 |
|---|---|---|---|
| Halter ROI 页 | 官网发布 AgFirst / Transform Agri 对 10 个新西兰奶牛场的独立研究，宣传平均 pasture eaten +9%、milk solids/ha +9.5%、profit before tax +13%，并强调技术必须与牧场管理改变结合 | 售前论证不应只讲功能；用客户现场数据建立 before/after 基线，把技术、流程和管理改变一起纳入 POC | 新西兰奶牛场样本，不能外推到其他畜种、区域或牧场管理水平 |
| Halter 区域化官网 | 提供 Rest of world、NZ、AU、US、CA、AR、UY 等区域入口；主要页面聚焦 Dairy、Beef、ROI、Technology、Farmers、Articles、Contact | 海外售前需要按区域组织价格、案例、合规、支持和本地代表；不同区域的价值叙事可能不同 | 区域页面内容可能不同，需逐区复核 |
| Halter 技术页 | 宣传太阳能项圈、直连卫星、无塔站覆盖、90 秒响应、实时位置/健康/发情、每项圈每分钟 6000+ 数据点、累计 70 亿小时行为数据 | 竞品把覆盖、数据密度、实时性、AI 数据资产作为前排卖点；我们的技术资料包需逐项准备证据和边界 | 这些均为 Halter 宣传口径，未经我们实测，不能作为我方能力表述 |
| Halter 联系流程 | 未公开标准价格，采用 Chat with us / local rep 流程，并说明主要支持 NZ/AU/US；公开 Help Centre、Learning hub 和支持邮箱 | 高价值方案可用 contact sales + 需求筛选；首次响应不必直接报价，可先确认规模、设备、网络和目标 | 无公开价格，不能推断报价或 SLA |
| Digitanimal 商城 | GPS tracker、太阳能 tracker、virtual fencing 公开设备价并标注 VAT excluded：EVO 约 €179.95 起、ECO 约 €189.95 起、Virtual Fencing 约 €339.94 起；公开 12 个月服务、renewal plans、14 天退款、2 年质保 | 硬件 + 12 个月服务 + 到期续费是清晰线上销售模式；公开税费、质保、退款和续费可降低询盘摩擦 | 起价随变体/套餐变化；区域税费、物流、售后和法规需另算，不能照抄 |
| Digitanimal 支持入口 | 支持页分为系统介绍、FAQ、GPS/App 支持、订单续费咨询，并提供 WhatsApp | 售前资料应与订单/续费/支持入口联动；客户自助了解后，销售再进入技术评估和报价 | 响应时限未见公开，不能推断服务等级 |
| Vence Contact 表单 | 收集姓名、邮箱、手机号、公司、城市/州/邮编、Operation Type、Average Herd Size，并提示补充放牧面积和国家 | 大牧场询盘应先用运营类型、畜群规模、放牧面积、国家和覆盖条件筛选，不直接凭邮件判断可行性 | 这是销售联系表单，不等同于需求调研或技术评估全量 |
| Nofence 搜索索引 | 搜索结果显示官网定位 cattle/sheep/goats virtual fencing，并强调 remote livestock management、减少体力劳动；当前网络访问官网页面返回 404 | 多畜种场景需要单独的价值话术和资质/案例，不可只按奶牛或肉牛设计 | 未能验证官网页面、价格和支持渠道，禁止引用为可确认事实 |

行业经验总结：

1. **先筛现场条件，再谈价格**。Vence 表单收集规模、面积和国家，Halter 通过 local rep 沟通；海外询盘应先确认畜种、规模、网络、设备、合规和目标。
2. **价值论证要有管理改变**。Halter 的 ROI 不是“设备自动产生收益”，而是技术与牧场管理流程共同作用；我们的 POC 应定义操作流程和客户配合度。
3. **公开价适合低摩擦设备，复杂方案适合 contact sales**。Digitanimal 公开设备起价和服务/续费口径；Halter、Vence 不公开标准价。我们需要区分线上可售与销售主导方案。
4. **税费和售后边界必须显性化**。VAT excluded、质保、退款、服务包含期和 renewal plan 都是报价前必须解释的内容。
5. **区域化内容影响转化**。语言、案例、本地代表、支持范围和合规资料应按市场配置，而非只用一个全球页面。
6. **竞品指标需要证据链**。ROI 数字、覆盖范围、响应时间和数据量都必须标来源、样本和适用条件，不能在对比表中裸用。

### 待确认

| 项目 | 行业/竞品基准 | 内部待确认内容 | 负责人 | 影响 |
|---|---|---|---|---|
| 首响 SLA | Halter/Vence 走 contact sales；Digitanimal 提供线上支持入口 | 不同级别询盘首响、local rep 跟进、技术澄清和报价时限 | 销售/商务 | 团队考核 |
| 区域策略 | Halter 提供多区域站点；Vence 表单采集国家和州 | 目标市场优先级、区域话术、语言、本地代表、案例和合规差异 | 市场/销售 | 转化率 |
| 报价模板 | Digitanimal 公开 VAT excluded 设备价；Halter/Vence contact sales | 币种、税费、设备、订阅、实施、支持、物流、质保和退款拆分；哪些可线上公开、哪些必须销售报价 | 商务/财务 | 商务推进 |
| Demo 环境 | 竞品使用 App 截屏、技术页、案例和研究建立信任 | 海外可访问地址、语言、数据场景、权限、版本、竞品对比演示路径和录制材料 | 产品/运维 | 演示效果 |
| 案例口径 | Halter 公开独立研究和农场案例；Digitanimal 有客户与项目内容 | 可公开客户、区域、畜种、指标、截图、数据周期和引用格式 | 市场/产品 | 信任建立 |
| 技术资料包 | Halter 强调覆盖、数据密度和实时性；Digitanimal 公开通信和电池规格 | 可对外架构图、覆盖评估表、设备规格、API 文档、安全问答、数据表和边界声明 | 产品/研发 | 技术澄清 |
| POC 模板 | Halter ROI 与管理改变绑定；Vence 采集规模和放牧面积 | 范围、设备、时间窗、客户配合、基线指标、成功标准、退出条件、数据清理和转化条件 | 产品/销售 | 商务闭环 |
| 竞品复核表 | 本节外部快照可作为初稿 | 逐项复核竞品价格、功能、案例、认证、区域页面、资料日期和反证来源 | 市场/产品 | 竞争话术 |
| 价值计算器 | Halter 用独立研究展示产出、利润和劳动变化 | 输入项、公式、默认值、客户基线采集表、免责声明和输出口径 | 产品/财务 | 商务论证 |
| 商务模式清单 | Digitanimal 设备 + 12 个月服务 + renewal；Halter/Vence contact sales | API 计费、增值包、设备租赁、服务包含期、断缴、分润、License 和 enterprise 打包规则 | 产品/商务/财务 | 报价口径 |
| 询盘表单 | Vence 采集 Operation Type、Herd Size、面积和国家 | 最低询盘字段、表单语言、自动分级规则、CRM 必填项和去重规则 | 市场/销售 | 商机质量 |
| 质保退款口径 | Digitanimal 公开 14 天退款和 2 年质保 | 退款窗口、质保范围、人为损坏、物流责任、备件、退换和区域消费者权利 | 法务/供应链 | 商务争议 |

### 外部来源

- [Halter ROI](https://www.halterhq.com/roi)
- [Halter technology](https://www.halterhq.com/our-technology)
- [Halter contact/support](https://www.halterhq.com/contact)
- [Digitanimal shop](https://digitanimal.com/shop/?lang=en)
- [Digitanimal EVO tracker](https://digitanimal.com/producto/dispositivo-gps-para-ganado/)
- [Digitanimal ECO solar tracker](https://digitanimal.com/producto/collar-gps-ganado-panel-solar/)
- [Digitanimal virtual fencing](https://digitanimal.com/producto/dispositivo-de-vallado-virtual-vacas/)
- [Digitanimal customer support](https://digitanimal.com/soporte-clientes/)
- [Vence contact form](https://www.merck-animal-health-usa.com/hub/vence/contact/)
