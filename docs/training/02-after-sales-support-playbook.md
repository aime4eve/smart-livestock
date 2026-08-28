# 解决方案售后支持实战手册

> 版本：v0.4（2026-08-26）
> 适用对象：售后支持人员、参与客户问题定位的测试和研发人员
> 前置阅读：《智慧畜牧解决方案赋能手册》《智慧畜牧软件平台培训手册》，以及 GAT-100 与 RBC-100 设备分册
> 目标：把硬件、网络、平台、数据、商业配置和客户沟通的问题受理、定位、测试、研发升级和结果反馈做成闭环。

## 1. 关闭标准

一个问题只有满足以下条件才能关闭：

1. 客户原始诉求被完整记录。
2. 影响范围和严重程度被判断。
3. 问题被定位到硬件、网络、环境、部署、数据或代码层。
4. 已完成必要测试或证据收集。
5. 需要研发处理时，升级单可复现、可验证、可追踪。
6. 客户收到明确结论、处理结果和后续建议。

“我回复了客户”不等于“问题已关闭”。

## 2. 问题受理

### 最低信息清单

| 分类 | 必填信息 |
|---|---|
| 客户 | 客户名称、联系人、角色、时区、联系方式 |
| 环境 | 生产/POC/demo、区域、客户端类型、App 版本或浏览器 |
| 业务对象 | farm ID、livestock ID、device ID、alert ID、API Key 名称，按问题选择 |
| 时间 | 问题发生时间、客户本地时间、UTC 时间、是否持续复现 |
| 现象 | 期望结果、实际结果、错误提示、截图或录屏 |
| 操作 | 复现步骤、入口页面、用户角色、最近变更 |
| 硬件 | GAT-100/RBC-100 编号、固件版本、电量、佩戴/投服登记、设备与牲畜绑定 |
| 网络 | 网关编号、频段、RSSI/SNR、网络服务器、最后转发时间 |
| 影响 | 受影响动物/设备数量、业务阻塞、临时绕过方案 |
| 安全 | 是否涉及账号异常、数据泄露、密钥泄露、越权访问 |

### 受理回复模板

```text
Dear [Name],

Thank you for reporting the issue.

We have recorded the following details:
- Affected user/role:
- Farm/device/alert:
- Time window:
- Expected result:
- Actual result:

To speed up investigation, could you also provide:
1. A screenshot or screen recording of the error.
2. The approximate time when it last happened.
3. Whether the same issue appears for another user or device.

We will keep you updated as soon as we complete the initial assessment.

Best regards,
[Your name]
```

信息不足时，先做基础确认，不要直接升级研发：

1. 用户角色和权限是否正确。
2. 是否为账号、租户或订阅状态问题。
3. 是否为客户操作理解偏差。
4. 是否有明确错误提示。
5. 影响单个对象还是批量对象。
6. 是否已有其他客户报告同类问题。

## 3. 严重程度建议

| 级别 | 判断标准 | 建议动作 |
|---|---|---|
| S1 | 全站不可用、数据安全风险、核心业务大面积中断 | 立即升级值班负责人，启动应急沟通 |
| S2 | 关键功能不可用，如登录、告警、设备数据批量缺失 | 当日定位，必要时升级研发 |
| S3 | 单个对象或少数用户异常，有绕过方案 | 常规工单处理 |
| S4 | 使用咨询、配置调整、非阻塞缺陷 | 排期处理并告知预期 |

> 正式响应和解决时限待支持负责人确认。海外客户必须同时记录客户时区和跟进窗口。

## 4. 六层定位树

### 4.1 硬件层

先确认设备本身是否具备上报条件。

检查点：

1. 设备型号、编号、固件版本和可选功能宏。
2. 电量、电池电压趋势和低电告警。
3. GAT-100 开机、入网蜂鸣、按键反馈、佩戴和防拆配置。
4. RBC-100 投服前验活、投服登记、温度是否进入 38-40℃ 牛体温区间。
5. 设备是否与正确牲畜绑定，安装关系是否有效。
6. RBC-100 payload 帧格式是否确认：`68 6B 74`、`F2/F5` 或 `C1`。

| 症状 | 定位方向 |
|---|---|
| 单个设备无数据 | 电量、设备状态、绑定关系、佩戴/投服状态 |
| RBC-100 解码失败 | 固件版本、帧头、解码器是否匹配 |
| GAT-100 无位置 | GPS 未定位、遮挡、上报周期、佩戴姿态 |
| 温度不在牛体温区间 | 未入胃、换算错误、传感器异常 |

### 4.2 网络层

确认设备数据是否能够到达网络服务器和平台。

检查点：

1. 目的国频段与设备、网关是否一致。
2. 网关在线状态、供电和回传网络。
3. 网关覆盖、安装位置和牧场地形。
4. 现场牛体高度或活动区域的 RSSI/SNR。
5. 网络服务器是否收到 frame 和 uplink。

| 症状 | 定位方向 |
|---|---|
| 单个区域设备无数据 | 网关盲区、天线位置、障碍物、牛群活动范围 |
| 批量设备无数据 | 网关离线、网络服务器异常、平台接入异常 |
| RBC-100 覆盖差 | 穿牛体衰减、牛舍结构、网关密度不足 |
| 偶发离线 | 信号边界、重发/重入网机制、上报周期 |

### 4.3 环境层

先排除系统和代码之外的因素。

检查点：

1. 客户网络是否可访问服务。
2. 手机或浏览器版本是否受支持。
3. 客户使用的是 demo、POC、dev、test 还是生产入口。
4. 设备网络、电量、安装状态是否正常。
5. 客户是否误用不同环境的账号或地址。

| 现象 | 可能原因 |
|---|---|
| 单个客户打不开 | 本地网络、DNS、防火墙、客户端缓存 |
| 所有客户打不开 | 转部署层 |
| 单台设备无数据 | 先转硬件层和网络层，再查安装关系 |
| 批量设备无数据 | 先查网络层，再查部署层或数据层 |

### 4.4 部署层

确认客户使用的版本和服务状态。

检查点：

1. API 健康状态。
2. 后端服务日志。
3. 前端发布版本是否包含目标功能。
4. Docker 服务状态。
5. nginx 入口和路由。
6. 配置是否指向正确环境。

| 症状 | 定位方向 |
|---|---|
| API 正常但前端无变化 | 前端未重新构建或部署 |
| 功能入口缺失 | 前端版本、角色权限或功能门控 |
| 服务 5xx 或超时 | 后端日志、容器状态、依赖服务 |
| 某环境正常另一环境异常 | 配置、版本或数据差异 |

支持人员不得直接操作 test 环境部署。test 环境部署和相关集成测试必须遵守公司通知与审批流程。

### 4.5 数据层

确认数据是否存在、是否在正确范围、来源是否合法。

检查点：

1. farm 归属和租户隔离。
2. active farm / farm scope 是否正确。
3. 时间窗和时区。
4. 设备与牲畜安装关系。
5. License、订阅、Feature Gate。
6. 数据保留策略。
7. 数据来源 `source` 是否符合预期。
8. GPS ingestion task 是否失败或积压。

| 现象 | 误区 | 正确检查 |
|---|---|---|
| 轨迹为空 | 直接判断缺陷 | 先查设备、active installation、时间范围、时间格式 |
| 功能不可见 | 只查角色 | 同时查角色、订阅层级、Feature Gate |
| 数据不一致 | 只看页面 | 核对来源、时间窗、幂等键 |
| 测试数据混入 | 忽略 source | 确认是否为 DATAGEN 或 MANUAL_IMPORT |
| RBC-100 数据解析失败 | 直接判平台缺陷 | 先确认固件版本、帧头和解码器 |
| GAT-100 轨迹漂移 | 直接判设备损坏 | 查卫星数、HDOP、遮挡和运动场景 |

### 4.6 代码层

只有硬件、网络、环境、部署、数据被排除，或已有明确复现证据时，才升级代码缺陷。

代码层升级必须包含：

1. 复现步骤。
2. 用户角色和数据对象。
3. 期望结果与实际结果。
4. API 请求/响应中的 `requestId`。
5. 后端日志片段或错误栈。
6. 环境、版本和时间窗。
7. 是否可稳定复现。
8. 已排除项，至少说明硬件、网络、环境、部署、数据层的检查结论。

## 5. 常见问题定位

### 5.1 登录或权限

1. 确认登录入口和环境。
2. 确认账号状态和租户状态。
3. 确认用户角色。
4. 对照权限矩阵确认预期可见范围。
5. 如返回 401 或 403，记录业务错误码和 `requestId`。

| 错误 | 客户侧含义 |
|---|---|
| `AUTH_TOKEN_EXPIRED` | 登录态过期，需重新认证 |
| `AUTH_INVALID_TOKEN` | 凭证无效 |
| `AUTH_FORBIDDEN` | 角色或 scope 权限不足 |
| `TENANT_DISABLED` | 租户被禁用 |

### 5.2 地图或轨迹为空

排查顺序：

1. 客户是否选择了正确牧场。
2. 牲畜是否有有效设备安装关系。
3. 设备是否在线并有遥测数据。
4. 查询时间窗是否覆盖数据时间。
5. 时间和坐标格式是否符合接口约定。
6. GPS ingestion task 是否失败或积压。
7. 地图瓦片服务或离线包是否异常。

客户沟通时避免直接说“系统没有数据”，先说明正在确认设备上传、数据范围和地图链路。

### 5.3 告警未触发或状态异常

1. 确认围栏配置和生效版本。
2. 确认牲畜与设备关系。
3. 确认相关时间窗内是否有有效位置数据。
4. 确认告警当前状态。
5. 确认操作角色是否允许该状态流转。

```text
pending -> acknowledged -> handled -> archived
```

worker 可确认告警；处理和归档由 owner 执行。非法跳转会返回状态冲突，不应绕过状态机直接改数据。

### 5.4 健康数据或预警异常

1. 确认订阅层级是否开放该功能。
2. 确认牲畜是否配备所需传感器。
3. 确认温度、蠕动、活动等原始数据是否存在。
4. 确认时间窗和数据来源。
5. 确认客户是否把辅助预警理解为确定性诊断。

客户质疑模型效果时，由研发评估真实数据样本；不得用仿真数据回答生产效果问题。

### 5.5 API 调用失败

必须记录 API Key 名称，不记录完整密钥，另加请求 URL、方法、时间、HTTP 状态、业务错误码、`requestId`、调用频率和数据量。

| 错误 | 定位 |
|---|---|
| `AUTH_API_KEY_INVALID` | Key 不存在、撤销或填写错误 |
| `AUTH_API_KEY_EXPIRED` | Key 过期 |
| `AUTH_FORBIDDEN` | scope 不足 |
| `RATE_LIMIT_EXCEEDED` | 超出限流 |
| `FARM_SCOPE_CONFLICT` | farm scope 来源冲突 |
| `RESOURCE_NOT_FOUND` | 资源不存在或不属于当前租户 |

### 5.6 订阅、License 与配额

客户反馈“已付费但功能不可用”“设备不能添加”“API 不能调用”时，先确认商业状态，再判断代码问题：

1. 订阅状态：trial、active、free、renewal failed、expired、suspended 或 cancelled。
2. 当前有效层级：basic、standard、premium、enterprise；试用期内按高级能力体验的策略需与产品口径一致。
3. Feature Gate：功能是被 LOCK 锁定、LIMIT 超量，还是 FILTER 裁剪历史数据。
4. 设备 License：设备类型、配额、有效期和安装关系。
5. 独立部署 License：服务状态、有效期、设备配额和激活记录。
6. API Key：状态、scope、限流、日用量和调用日志。

常见判断：

| 现象 | 优先确认 |
|---|---|
| 功能入口有升级提示 | 订阅层级、FeatureGate、客户合同 |
| 创建资源返回配额不足 | 当前用量、层级上限、是否需要商务升配 |
| 设备无法启用 | 设备 License、设备类型、剩余配额、设备状态 |
| API 返回限流 | 调用日志、限流配置、客户调用量和合同范围 |
| License 服务不可用 | 激活状态、到期时间、部署环境和续费记录 |

如果确认是商务续费、升配或合同范围问题，转商务负责人；只有配置正确但系统行为错误时才升级研发。

## 6. 测试与验证

### 测试前确认

1. 明确客户问题或研发假设。
2. 明确测试环境和数据来源。
3. 明确时间窗、设备或牧场范围。
4. 明确成功标准。
5. 明确测试数据清理方案。

不允许“随手造一点数据看看”。

### 测试数据规则

1. 使用明确时间窗，避免与真实数据混淆。
2. 压测或验证数据使用 `MANUAL_IMPORT` source。
3. 仿真数据必须标记为 DATAGEN，不得与真实来源混淆。
4. 测试后清理数据并恢复设备快照。
5. 不在生产客户环境保留演示或压测数据。

### 证据记录

每次测试记录：

1. 测试时间。
2. 环境。
3. 版本或提交。
4. 测试账号角色。
5. 操作步骤。
6. 输入数据。
7. 期望结果。
8. 实际结果。
9. 截图、日志、API 响应。
10. 结论。

### 验证通过标准

1. 原复现步骤不再出现错误。
2. 关联业务流程可用。
3. API 响应符合契约。
4. 无新增回归。
5. 测试数据已清理。
6. 客户确认结果，或客户无法参与时留有可回放证据。

## 7. 研发升级单

```text
Ticket ID:
Customer:
Severity:
Support owner:
R&D owner:
Customer timezone:

Summary:
- One-sentence description:

Impact:
- Affected users/roles:
- Affected farms/devices/alerts:
- Business impact:
- Workaround:

Reproduction:
- Environment:
- Version:
- Time window:
- Steps:
- Expected:
- Actual:

Evidence:
- requestId:
- API response:
- Raw payload / frame format:
- Gateway RSSI/SNR:
- Screenshot/recording:
- Backend log:
- Database check result:

Investigation:
- Hardware layer:
- Network layer:
- Environment layer:
- Deployment layer:
- Data layer:
- Code layer:

Request:
- Suspected component:
- Required analysis:
- Suggested fix or test:

Verification:
- Acceptance criteria:
- Regression scope:
- Test data cleanup:

Communication:
- Last customer update:
- Next update time:
```

研发接收标准：

1. 问题可复现或有足够证据。
2. 影响范围明确。
3. 已排除非代码因素。
4. 环境与版本明确。
5. 验收标准明确。

## 8. 客户沟通话术

### 已受理

> We have received your report and recorded the affected farm, device, time window, and expected behavior. Our team is doing an initial assessment, and we will update you by [time/date, customer timezone].

### 需要补料

> To confirm whether this is related to the device, data scope, or platform service, could you provide [specific evidence]? This will help us avoid unnecessary back-and-forth.

### 正在定位

> We are checking the data flow and service logs for the reported time window. We do not yet have a final conclusion, but the next update will be provided by [time/date].

### 已定位非缺陷

> Based on our review, the behavior is caused by [configuration/data/permission/device condition]. Here is the correction: [action]. We suggest [preventive action].

### 确认缺陷

> We have confirmed a platform issue affecting [scope]. Our engineering team is working on a fix. The current workaround is [workaround or none]. We will confirm the release and validation plan by [time/date].

### 修复后验证

> The fix has been deployed. We have verified [scope]. Could you confirm whether the original issue is resolved in your environment? If not, please share the new time and screenshot.

## 9. 跨时区协作

1. 客户时间同时记录本地时间和 UTC。
2. 承诺更新时间写清时区。
3. 重要结论写进工单，不依赖会议记忆。
4. 交接包含当前结论、已排除项、下一步和阻塞。
5. 超过承诺时间前主动更新进展，即使没有最终结论。

## 10. 安全事件

以下情况立即升级安全/研发负责人：

1. 疑似账号被盗或异常登录。
2. API Key 或密码泄露。
3. 客户看到非自身租户数据。
4. 系统入侵迹象。
5. 大规模数据异常删除或篡改。

初步动作：

1. 不删除证据。
2. 记录时间、账号、requestId、截图和日志。
3. 按负责人指令暂停或重置凭证。
4. 结论确认前，不向客户猜测原因和影响范围。

## 11. 售后红线

1. 不向客户展示完整 API Key、token、数据库连接或内部地址。
2. 不直接修改生产数据绕过业务状态机。
3. 不把 DATAGEN 数据当作真实设备数据解释。
4. 不在未通知的情况下操作 test 环境。
5. 不为关闭工单承诺未确认的修复时间。
6. 不把“无法复现”说成“不是问题”，应说明已排查范围和所需补充证据。
7. 不让客户自行执行破坏性 SQL 或危险操作。

## 12. 培训练习

1. 给定“地图看不到牛”的客户邮件，补全受理表单并列出 3 个必问问题。
2. 给定“设备有数据但页面轨迹为空”，按六层写出排查顺序。
3. 把一个告警状态 409 问题整理成研发升级单，必须包含 requestId、时间窗、角色、步骤和已排除项。
4. 写一封英文更新邮件：问题尚未定位，但已确认不是账号权限问题，并承诺下次更新时间。
5. 给定“客户已付费但健康功能不可用”的案例，区分订阅层级、FeatureGate、设备依赖和代码缺陷。

## 13. 待确认清单

### 行业与竞品售后公开基准

> 检索时间：2026-08-25 UTC。以下为内部参考快照，不是可直接对客户承诺的 SLA；对外使用前需复核原文、区域页面和资料日期。

| 竞品/来源 | 公开售后与支持口径 | 对我们的启发 | 使用限制 |
|---|---|---|---|
| Halter Help Center | 提供搜索型帮助中心，公开分类包括 Collars and Towers、Virtual Fencing、Troubleshooting、Animal Welfare Charter；支持 EN/ES 双语；文章覆盖登录 FAQ、Collaring Guide、System Overview、Virtual Fencing Background、Training Animals 等 | 知识库按“设备/网络、核心业务、故障排查、动物福利”分层；售后自助内容应覆盖登录、系统概览、佩戴/安装、训练/启用、业务规则 | 具体文章内容以官网为准；Halter 的流程未必等同于我们的设备与业务模型 |
| Halter 工单门户前端文案 | 公开工单词表使用 Submitted、In progress、Waiting on you、Resolved，并呈现 Ticket ID、Title、Description、Created by、Created at、Assignee、State 等字段 | 客户可见状态要少而清楚；“等待客户补充”必须成为显式状态，避免内部忙等和客户误解 | 前端词表不等于完整 SLA；不能推断其响应时限 |
| Digitanimal 支持页 | 公开支持入口分为 Introducción al sistema、Preguntas frecuentes、GPS y aplicación clientes、Pedidos renovaciones y consultas；页面提供 WhatsApp 联系入口 | 支持入口按“入门、FAQ、设备/App、订单续费咨询”分流；订单、续费和账单不应混入技术缺陷单 | 具体支持响应时间未见公开；联系方式可能随区域变化 |
| Digitanimal 商品质保与退款 | 设备页公开 2 年质保、14 天退款保证、12 个月服务包含和 renewal plans | 售后必须提前定义质保、退款、服务包含期、续费后服务边界和断缴处理 | 不同国家消费者权利、运费、损耗和人为损坏规则需法务确认 |
| Vence Contact 表单 | 表单收集姓名、邮箱、手机号、公司、城市/州/邮编、Operation Type、Average Herd Size，并提示补充放牧面积和国家 | 售前/售后受理都应采集运营类型、畜群规模、放牧面积和国家/区域，便于判断影响范围和覆盖问题 | 这是销售联系表单，不等同于售后工单结构 |
| Nofence 搜索索引 | 搜索结果显示官网强调 dedicated team 和选购支持，但当前网络访问官网页面返回 404 | 多畜种和远程牧场支持需要本地化联系方式与销售/支持分工 | 未能验证页面与支持渠道，禁止引用为可确认事实 |

行业经验总结：

1. **先自助分流，再人工受理**。公开帮助中心、FAQ、搜索和类别导航可以减少低价值工单；复杂问题再进入工单或消息通道。
2. **工单状态要面向客户解释**。Submitted、In progress、Waiting on you、Resolved 这类状态比内部技术状态更适合客户门户。
3. **订单、续费、账单与技术缺陷分轨**。Digitanimal 将订单/续费/咨询与 GPS/App 支持分开，售后应避免把商业问题误判成产品缺陷。
4. **环境上下文是受理质量的关键**。Vence 表单采集运营类型、规模、位置、面积，说明覆盖和影响范围必须在首次沟通时收集。
5. **动物福利需要专门内容**。Halter 将 Animal Welfare Charter 独立为帮助中心分类；涉及项圈、胶囊、声音或电刺激时不能只放在技术 FAQ。
6. **质保、退款、续费边界必须书面化**。设备故障、人为损坏、物流、服务到期和续费争议应各有判定规则。

### 待确认

| 项目 | 行业/竞品基准 | 内部待确认内容 | 负责人 | 影响 |
|---|---|---|---|---|
| 支持 SLA | Halter/Digitanimal 未公开响应时限；仅公开支持入口 | S1-S4 响应时限、解决时限、更新频率、值班窗口、节假日和时区规则 | 支持负责人 | 客户承诺 |
| 支持渠道 | Halter Help Centre + 工单门户；Digitanimal 支持页 + WhatsApp | 是否提供 Help Centre、邮箱、工单门户、WhatsApp/电话/IM，渠道优先级和语言 | 支持负责人 | 客户入口 |
| 工单系统 | Ticket ID、Title、Description、Created by、Assignee、State、Waiting on customer | 客户可见字段、内部字段、状态流、权限、通知规则、SLA 计时和暂停规则 | 产品/支持 | 流程落地 |
| 受理表单 | Vence 采集 Operation Type、Herd Size、位置、面积 | 最低受理字段是否增加畜种、运营类型、牧场规模、放牧面积、国家/地区和设备覆盖比例 | 支持负责人 | 定位效率 |
| 知识库 | Halter 按设备/业务/排障/动物福利分层，EN/ES 双语 | 首批文章清单、搜索、多语言、版本维护、产品版本标记和审核流程 | 产品/支持 | 自助支持 |
| 质保退款 | Digitanimal 公开 2 年质保、14 天退款、12 个月服务和续费 | 质保范围、人为损坏、物流、退款窗口、服务到期、续费和断缴边界 | 法务/商务/供应链 | 商务争议 |
| 日志权限 | 竞品未公开内部权限 | 支持人员可查询哪些日志、数据库、设备平台数据和客户信息；审批与审计方式 | 研发/安全 | 定位效率与数据安全 |
| 客户环境 | Vence 强调 acres grazed 和 country | 生产/POC/demo 环境编号、入口、版本、部署区域、网络和设备来源 | 运维/支持 | 排查准确性 |
| 应急预案 | 竞品公开资料未暴露内部流程 | S1 通知链、值班机制、升级路径、回滚、数据恢复和客户公告模板 | 研发/运维 | 重大故障 |
| 升级与复盘 | Halter/Intercom 状态含 Waiting/Resolved，但无内部升级细节 | 研发接收标准、升级人、根因分析、RCA 报告和回归验证要求 | 研发负责人 | 缺陷闭环 |

### 外部来源

- [Halter Help Center](https://intercom.help.halter.io/en/)
- [Halter Help Center sitemap](https://intercom.help.halter.io/sitemap.xml)
- [Halter contact/support](https://www.halterhq.com/contact)
- [Digitanimal customer support](https://digitanimal.com/soporte-clientes/)
- [Digitanimal FAQ](https://digitanimal.com/ayuda/preguntas-frecuentes/)
- [Digitanimal GPS and client app support](https://digitanimal.com/ayuda/gps-y-aplicacion-clientes/)
- [Digitanimal orders, renewals and inquiries](https://digitanimal.com/ayuda/pedidos-renovaciones-y-consultas/)
- [Digitanimal EVO tracker warranty/refund page](https://digitanimal.com/producto/dispositivo-gps-para-ganado/)
- [Vence contact form](https://www.merck-animal-health-usa.com/hub/vence/contact/)
