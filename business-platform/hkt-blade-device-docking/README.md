# 设备数据采集对接验证：blade / ThingsBoard / NS

本目录最初是 Phase C 的 blade 对接 PoC，方案 B（Feign + url 直连），不引入 Nacos /
Spring Cloud Alibaba，用 Feign `url` 模式消费 blade 已有的 `/feign/v1/*` 端点。
blade 不可改代码，本工程只作为消费方。

**已通过真实 blade平台 test 环境（172.22.4.17）和dev 环境（172.21.2.41）全链路验证（单元测试 18/18 + 真实联通性 13/13 全绿）。**

2026-08-29 起，本文同时记录 smart-livestock 真实设备数据采集的完整经验：NS 平台配置、
ThingsBoard 直连、blade 轮询，以及三条链路的取舍。datagen 仿真数据用于市场演示和算法
预训练，不计入真实设备采集通道。

阅读顺序：

1. `数据采集途径总览`回答“选哪条通道”。
2. `Blade 对接`、`ThingsBoard 对接`、`NS 平台配置`分别说明各层的数据路径、接口和配置事实。
3. `统一接入语义与项目级流程`沉淀跨通道的身份、时间、幂等、接入 Checklist 和验收分级。
4. `数据采集优化审视`在此基础上给出后续工程化和治理方向。
5. 附录保留原 Phase C PoC 的完整验证记录，供追溯历史结论。

## 数据采集途径总览

真实设备数据当前有三类入口、四个可实现途径：

| # | 类别 | 途径 | 当前状态 | 适用场景 | 主要限制 |
|---|------|------|----------|----------|----------|
| 1 | blade | REST 轮询 `/device/report-record/page` | 主线已实现，dev/test 已部署验证 | 兼容既有通道；按 blade `deviceId` 拉历史 | 最长 5 分钟轮询延迟；依赖 blade 可用性和字段转发完整性 |
| 2 | ThingsBoard | REST 轮询 timeseries | NIX-179 Phase 1 已在 dev/test 验证 | 直连遥测源头，回补历史、避开 blade 轮询延迟 | 仍是轮询；设备需存在 TB timeseries；本地需绑定关系 |
| 3 | ThingsBoard | WebSocket 订阅 | Phase 2 规划 | 实时推送，延迟可到秒级或百毫秒级 | 需处理重连、订阅恢复、REST 兜底和游标一致性 |
| 4 | NS | MQTT 订阅或转发配置 | 已作为 TB Gateway 接入配置验证；应用直连未上线 | 平台侧打通 NS→TB；诊断 NS 原始上行 | 应用直连会引入第四套数据协议和幂等语义，默认不建议 |

选择原则：

1. 生产主通道继续保留 blade 轮询，不因新增 TB 通道而删除或停用。
2. 需要更低延迟或历史回补时优先使用 TB：Phase 1 REST，Phase 2 WebSocket 加 REST 兜底。
3. NS MQTT 用于打通和诊断上游链路；除非 TB 和 blade 都不可用，不建议 smart-livestock 直接消费 NS。
4. datagen 只生成 `source=DATAGEN` 仿真数据，禁止与真实采集混淆。

## Blade 对接

### 数据路径

```text
smart-livestock AgenticPlatformSyncDispatcher
  → AgenticPlatformTelemetrySyncJob
  → blade GET /device/report-record/page
  → AgenticPlatformReportData.toReadings()
  → TelemetryIngestionService.ingest(..., AGENTIC_PLATFORM)
```

当前主线代码按设备并行拉取，调度周期默认 5 分钟。每个本地设备依赖
`devices.platform_device_id` 映射 blade 数字 `deviceId`，并使用
`devices.last_telemetry_synced_at` 作为增量游标。

### 关键接口与认证

1. OAuth2 换票：`POST /oauth2/token`
   - `grant_type=openapi`
   - `userId={serviceUserId}`
   - Basic Auth 使用 openapi client
   - 请求带 `Tenant-Id`
2. 设备查询：`POST /feign/v1/device/lifecycle/pageDevices`
3. 设备详情：`POST /feign/v1/device/lifecycle/getDeviceDetail`
4. 最新遥测：`POST /feign/v1/device/telemetry/history/latest`
5. 上行历史：`GET /device/report-record/page?deviceId={deviceId}&current={page}&size={size}`

blade Feign 请求头是裸 `token`，不是 `Authorization: Bearer`。

### 使用建议

- `report-record/page` 是 blade 时序数据的首选接口：包含原始 `hexData`、`decodeData`、RSSI、SNR 和网关信息。
- `history/latest` 适合快照和联通性检查，不适合完整历史采集。
- blade `deviceId` 必须来自平台，不能本地生成；EUI 反查是当前 PoC 的稳定方式。
- 若设备只有 NS 上行而没有进入 blade，先解决上游 TB/blade 转发，继续加大轮询频率没有意义。

### 已验证结论

- tracker 历史采集可用，PoC 真实联通性检查 13 项通过。
- blade 平台 test/dev 均完成 OAuth2 换票和 Feign url 直连验证。
- blade 是 TB 下游：字段和可用性受 TB→Kafka→blade 链路影响；NS 在线不等于 blade 有 `report-record`。

## ThingsBoard 对接

### 数据路径

```text
NS MQTT topic
  → TB IoT Gateway / OC connector
  → TB device timeseries: data / body / result / dataHex / rssi / snr ...
  → smart-livestock TbTelemetryChannel
  → TelemetryIngestionService.ingest(..., THINGSBOARD)
```

NIX-179 Phase 1 已实现 TB REST 增量轮询：

- 登录：`POST /api/auth/login`
- 响应 token 字段：`token`
- 后续请求头：`X-Authorization: Bearer {token}`
- 遥测查询：`GET /api/plugins/telemetry/DEVICE/{tbDeviceId}/values/timeseries`
- 常用 keys：`result,dataHex,rssi,snr,downLinkGateway`
- 本地绑定表：`tb_device_bindings`
- 本地游标：`telemetry_cursor_ms`

### 解析规则

1. `result.decodeStatus=true` 且能映射出非空 readings 时，`result` 是 authoritative。
2. 同一物理帧的 `dataHex` 不重复入库；仅在 result 缺失或不可解析时作为 capsule TLV fallback。
3. tracker 暂无 TLV fallback；坏 result 按失败帧处理，游标不得越过。
4. TB `ts` 是 epoch milliseconds，按 UTC Instant 入库，不做墙时区换算。
5. DTL 和 GPS 依赖数据库唯一键吸收 at-least-once 重放。

### 需要同时满足的绑定条件

| 层 | 条件 |
|----|------|
| TB | 设备存在，Device Profile 正确，且 OC connector 已订阅该设备所属 NS 项目的 MQTT topic |
| smart-livestock | `devices` 中存在本地设备；`tb_device_bindings` 有 `RESOLVED` 绑定和 TB deviceId |
| 业务 | 设备为 ACTIVE；若要温度/胃动力进入 health 表，还必须有 active installation 绑定到牲畜 |

### 2026-08-29 真实复验

以 `001a0103ff000262` 验证项目 89：

1. NS 在 `2026-08-29 01:31` 收到真实上行。
2. TB 同帧收到并生成 `result`、`dataHex`、`temperatureGroup`、`gastricMotility`、三轴加速度、RSSI 和 SNR。
3. smart-livestock test 入库 1 条 `source=THINGSBOARD` DTL。
4. TB binding 游标推进到 `1787938283391`。
5. `001a0103ff00024e` 已创建 TB 设备和本地 `RESOLVED` 绑定，等待下一帧真实上行。

注意：手工给 TB 设备补 `connectorType/connectorName/devEui/app/project` 属性并不会让数据流入；
这些属性更多是 connector 接管后的结果或映射信息。真正决定收数的是 gateway connector 的
NS project topic subscription。

### 当前边界

- REST 轮询默认 5 分钟，不是实时通道。
- Phase 2 应实现 TB WebSocket 实时订阅，并保留 REST 游标兜底。
- `blade-exclusion=true` 是源路由选择，不提供 TB 故障时自动回退 blade。
- 262/24E 当时没有 active installation，因此 DTL 可入库，但 health 消费者会因 `livestockId=null` 跳过温度/胃动力表写入。

## NS 平台配置

### 平台与项目

- NS UI：`http://172.17.201.15`
- 生产测试项目：`26.1.26 60台胶囊生产测试`，project id `89`
- 对照项目：`AI智能体硬件设备验证`，project id `111`
- 项目 89 的 EU868 胶囊使用 LoRaWAN App `18 / EU868_ABP`

项目名称只用于展示，不作为设备数量或接入范围的事实源。该项目名称虽然包含“60台”，
但 2026-08-29 查询到的实际设备清单为 30 台。接入、对账和授权必须以 NS 设备列表 API
或数据库查询结果为准。

### 关键根因

NS 显示设备在线只代表 NS 收到了上行，不代表数据已经进入 TB 或 blade。2026-08-29 排查确认：

```text
NS project 89 device online
  ≠ TB gateway subscribed project 89 topic
  ≠ TB device/timeseries exists
  ≠ blade report-record exists
```

当时 TB `通用接入网关` 的 `OC` connector 已订阅项目 111：

```text
org/1/project/111/device/+/dat/up
```

但没有订阅项目 89，因此项目 89 的 30 台胶囊即使在线，也不会进入 TB。

这次定位最快的方法是“正常/异常对照”：

| 对照项 | 正常样本 | 异常样本 | 结论 |
|--------|----------|----------|------|
| 设备 | `001a0103ff00027f` | `001a0103ff000262` | 两者同为 EU868 胶囊、App 18 |
| NS 项目 | 111 | 89 | 正常设备属于项目 111 |
| TB connector | 已订阅 project 111 topic | 未订阅 project 89 topic | 根因是项目级 MQTT mapping |

对照排除了设备型号、TB tenant、Device Profile、credentials 类型和本地 smart-livestock 代码，
把差异收敛到 NS project topic subscription，避免继续猜测设备物理层或调大轮询频率。

### 成功配置

在 TB gateway 的 `OC` connector `SHARED_SCOPE` 配置中，复制项目 111 的 JSON converter 映射，
并将 topic 改为：

```text
org/1/project/89/device/+/dat/up
```

映射要点：

- device name：`${devEUI}`
- device type：`瘤胃胶囊-OC-配置-v2`
- attributes：`project`、`app`、`devEui`
- timeseries：`data`、`body`
- broker：NS `172.17.201.15:1883`
- MQTT 凭据：使用 NS `MQ客户端` 中预建的 `ThingsBoard-868` 凭据；不要把密码写入代码或文档

注意：NS 页面中的 `MQTT转发` 列表为空，并不代表数据不会进入 TB。TB Gateway 是一个 MQTT
客户端，它使用 NS `MQ客户端` 凭据主动订阅 NS broker；这和 NS 平台内配置的“MQTT转发”
是两种不同接入方式。

操作顺序：

1. 备份 TB Gateway `OC` shared attribute 全量 JSON。
2. 从项目 111 复制已验证的 converter mapping，只替换 project topic 和必要的 device type。
3. 先用单台设备验证上行、TB 解码和本地入库；本项目使用 `001a0103ff000262`。
4. 验证通过后再改成项目级通配 topic。
5. 受控停用并恢复 `OC` connector，让 gateway 重新加载 mapping。
6. 等待下一帧真实设备上行确认；配置保存成功不等于运行态已生效。

本次重载后，直接 MQTT 只读探测确认：

```text
org/1/project/89/device/001a0103ff000262/dat/up
```

有真实上行，且 `ThingsBoard-868` 凭据对该 topic 有订阅权限。

### 排查顺序

1. NS 项目设备是否在线，历史数据是否有原始 TLV。
2. NS MQTT topic 是否真实发布：`org/1/{orgId}/project/{projectId}/device/{devEui}/dat/up`。
3. TB gateway connector 是否 active，是否订阅该项目 topic。
4. TB 是否存在同名设备、正确 profile 和 timeseries。
5. blade `report-record/page` 是否已有记录。
6. smart-livestock 本地 device、binding、installation 是否满足入库条件。

### 配置纪律

- 修改 TB gateway shared attribute 前必须完整备份原 JSON。
- 不在 README、脚本或仓库中保存 NS MQTT 密码。
- 项目级 topic mapping 必须使用显式项目 ID，不盲目订阅全组织通配，避免误接入不可控设备。
- 每次新增 NS 项目时，核对 NS 设备清单、TB 设备清单、smart-livestock 本地绑定清单三方差集。

## 统一接入语义与项目级流程

### 设备身份纪律

- smart-livestock 内部 `devices.dev_eui` 统一小写；业务比较必须按规范化小写执行。
- TB 设备名大小写敏感，不能用模糊搜索结果直接绑定；必须按原样、大写、小写三种精确匹配。
- 多个大小写变体指向不同 TB 设备时应判定歧义并人工处理，不能随机选择。
- `tb_device_bindings.external_device_id` 必须保存确认后的 TB deviceId，不能只依赖设备名。
- 本地 EUI 与 TB deviceId 的绑定要有审计记录，避免设备重建后沿用失效 UUID。

### 时间与游标纪律

| 通道 | 源时间 | 本地游标 | 禁止事项 |
|------|--------|----------|----------|
| TB REST | epoch milliseconds，UTC | `tb_device_bindings.telemetry_cursor_ms` | 不得与 blade 游标混用 |
| blade REST | `reportTime` 墙钟字符串 | `devices.last_telemetry_synced_at` | 不得按本地时区二次换算 |

每个通道只推进自己的游标。游标代表“连续成功处理前缀”，不是简单取本轮最大时间；失败帧
不能被越过。进程在入库与游标保存之间崩溃时允许重放，由数据库唯一键和幂等归类吸收。

### 幂等与来源路由

- `device_telemetry_logs` 的 `(device_id, report_time)` 唯一键不区分 source；TB 和 blade
  对同一设备同一时间帧只能有一个主路由。
- `gps_logs` 与 GPS outbox 同样依赖 `(device_id, recorded_at)` 防重。
- TB 通道遇到已存在的 DTL 时间帧时，应归类为幂等成功并允许游标推进，而不是当成采集失败。
- TB 和 blade 双源并存时，必须先定义每台设备的 source routing；如确需同时入库，应引入
  canonical 去重策略，不能依赖“默认不开启”长期规避。

### 项目级接入 Checklist

1. 以 NS project id 查询设备清单；项目名称和口头数量只作参考。
2. 与正常项目做对照，确认 LoRaWAN App、project topic、converter mapping 和 device profile。
3. 在 TB Gateway 增加显式 project topic mapping，先单台试点，再项目级通配。
4. 确认 TB 设备存在、profile 正确、deviceId 唯一，并处理大小写同名歧义。
5. 在 smart-livestock 创建本地设备与 `RESOLVED` TB binding。
6. 若要温度、胃动力等 health 数据生效，创建 active installation，将设备绑定到牲畜。
7. 输出 NS/TB/本地三方清单差集和绑定审计记录。

### 分层验收标准

| 层级 | 验收问题 | 证据 |
|------|----------|------|
| L1 | 设备是否发射 | NS 历史数据中有原始 TLV 上行 |
| L2 | NS 是否发布 | MQTT topic 收到真实 payload |
| L3 | TB 是否接收并解码 | TB timeseries 出现 `data/body/result/dataHex` |
| L4 | smart-livestock 是否采集 | DTL 出现 `source=THINGSBOARD`，binding 游标推进 |
| L5 | 业务是否闭环 | temperature/rumen_motility 等 health 表有对应记录 |

只达到 L4 时，说明采集通道已打通；L5 还依赖 active installation。验收时必须写明达到的层级，
不能用 L1 或 L3 代替 L4/L5。

## 数据采集优化审视

### 1. 通道分层已经清楚，应保持加法而非替换

blade 轮询、TB REST、未来 TB WebSocket 分别承担兼容、历史回补和实时性。不要删除 blade 通道；
也不要让 datagen 参与真实采集验收。

### 2. Phase 2 应完成 TB WebSocket 实时化

REST 轮询适合兜底和历史回补，但生产实时体验应使用 TB WebSocket：

- fresh login 后重建订阅
- 30 秒 ping
- 指数退避重连
- 断线期间游标不推进
- 恢复后先 REST 回补，再回到 WebSocket

### 3. 设备接入应从手工绑定走向项目化同步

本次项目 89 暴露的问题不是单台设备，而是 NS 项目设备清单没有同步到 TB 和本地。上一节的
项目级 Checklist 是人工执行标准；后续应把它工具化为运维流程：

1. 以 NS project id 为输入拉取设备清单。
2. 校验 TB device profile、TB deviceId 和同名大小写歧义。
3. 生成 smart-livestock `devices` 和 `tb_device_bindings` 导入清单。
4. 人工确认后批量导入。
5. 输出三方差集报告：NS 有 TB 无、TB 有本地无、本地绑定但无最近遥测。

工具必须输出 dry-run 预览和实际导入结果，禁止在未处理大小写同名歧义时自动提交。

### 4. Active installation 是健康数据入库的必要条件

仅创建设备和 TB binding 只能保证 DTL、GPS 等采集链路。瘤胃温度和胃动力要进入 health 表，
设备必须 active installation 到牲畜。设备入库和牲畜绑定应作为胶囊接入 checklist 的两步。

### 5. 幂等和源路由需要持续守住

- DTL/GPS 唯一键是 at-least-once 重放的安全底线，不能移除；且 DTL 唯一键跨 source 生效。
- TB 和 blade 双通道并存时，必须明确每台设备当前路由，避免同一帧双写。
- `blade-exclusion` 打开前要有 TB 可用性告警，或明确接受 TB 故障期间的采集延迟。
- 后续如确需双源并存，应引入 canonical 去重策略，而不是依赖默认不开启。

### 6. 监控应面向最后一公里

建议指标和告警：

- NS project device online count
- TB connector active/inactive
- TB per-project 最新收到消息时间
- TB per-device 最新 telemetry ts
- smart-livestock per-binding cursor lag
- blade report-record latest time
- 入库 DTL/GPS/health 各自成功数与失败数
- `livestockId=null` 导致 health 跳过的数量

监控阈值必须以“最近一帧”为核心，而不是只看服务进程存活。例如同一项目内 connector active
但 per-project 最新消息时间停更，应触发项目级路由告警。只有同时看上游和本地入库，才能快速
区分设备没发、TB 没收、blade 没转、本地没绑、业务没安装。

### 7. 配置和凭据需要版本化治理

TB gateway 的 project mapping 是远程 shared attribute 配置，变更不能依赖个人记忆：

- 变更前后 JSON 备份；`/tmp` 只能作为操作现场临时备份，最终必须归档到受控配置库
- 记录变更原因、项目 id、topic、验证设备、操作者和回滚方案
- 凭据只放 secret manager 或环境变量
- TB/NS 密码定期轮换
- 为 project mapping 建立评审清单，避免无关项目被误接入

### 8. 不建议默认直连 NS MQTT

直连 NS 会绕过 TB 的设备管理、解码规则和审计面，还要自行处理 MQTT QoS、重连、幂等和密钥。
除非 TB 和 blade 均不可用且业务接受降级，否则 NS MQTT 只作为平台侧接通和诊断手段。

## 附录：原 Phase C PoC 详细记录

### Nacos 注册中心

172.22.3.16:8848，namespace `c47123d9-9d2b-4fdf-a61a-8d5daa9c89ac

### blade 平台 dev 环境

| 服务             | 地址             | 用途                              |
| ---------------- | ---------------- | --------------------------------- |
| hkt-blade-auth   | 172.21.2.41:8108 | OAuth2 换票 `/oauth2/token`       |
| hkt-blade-device | 172.21.2.41:8100 | 设备 + 遥测 `/feign/v1/device/*`  |
| hkt-blade-system | 172.21.2.41:8106 | 用户管理 `/feign/v1/system/sdk/*` |

### blade 平台 test 环境

| 服务 | 地址 | 用途 |
|------|------|------|
| hkt-blade-auth | 172.22.4.17:8108 | OAuth2 换票 `/oauth2/token` |
| hkt-blade-device | 172.22.4.17:8100 | 设备 + 遥测 `/feign/v1/device/*` |
| hkt-blade-system | 172.22.4.17:8106 | 用户管理 `/feign/v1/system/sdk/*` |

### 换票记录

|本项目| blade 平台|service-user-id|换票|
|------|------|------|------|
| dev（19080）|dev 172.21.2.41|207938296942293811| ✅ | 
| test（18080） |test 172.22.4.17|2074385063398711296 | ✅ |        

### 单元测试（18/18 全绿）

#### 对接测试（MockWebServer，6/6）

| # | 用例 | 覆盖点 |
|---|------|--------|
| 1 | `oauthTokenExchangeWorks` | `/oauth2/token` + `grant_type=openapi` + Basic Auth + `Tenant-Id` |
| 2 | `tokenHeaderInjected` | `token` 头 + `Tenant-Id` 头注入（blade 约定，无 Bearer） |
| 3 | `envelopeParsing` | `InternalResponse` 包络 + `DevicePageResp` 解析 |
| 4 | `deviceDetailWithTelemetry` | 设备详情 + 遥测属性 |
| 5 | `telemetryLatestQuery` | 遥测最新值（`deviceIds` 数组 + `deviceTypeCode`） |
| 6 | `errorDecoderOn500` | blade HTTP 500 → `BladeServiceException` |

#### 加速度计换算测试（AccelerometerConverterTest，12/12）

| # | 用例 | 覆盖点 |
|---|------|--------|
| 7 | `positiveValue` | 正值 uint16 → g（+0.612g） |
| 8 | `negativeValue` | 负值补码 uint16 → g（-0.612g） |
| 9 | `zeroValue` | 零值 = 0g |
| 10 | `maxPositive` | 量程边界（512 → +2.048g） |
| 11 | `maxNegative` | 负边界（65485 → -0.204g） |
| 12 | `magnitudeStationary` | 静止合矢量 ≈ 1g |
| 13 | `magnitudeFlatHorizontal` | 水平放置 Z=1g |
| 14 | `motionIntensityZero` | 纯重力时运动强度 = 0 |
| 15 | `activityClassification` | rest/light/active/intense 阈值 |
| 16 | `realBladeComparison` | 真实 blade 样本：活动 > 静止 |
| 17 | `toMs2Conversion` | g → m/s²（1g = 9.80665） |
| 18 | `firmwareThreshold` | 固件动作阈值 512 raw ≈ 32mg |

### 真实联通性验证脚本（13 项检查）

```bash
cd business-platform/hkt-blade-device-docking
./scripts/verify-blade-docking.sh
```

检查链路：服务健康 → OAuth2 换票 → 设备详情（运维数据） → 设备+遥测快照 → 最新遥测 →
上行历史摘要（g 值 + 活动分类） → GPS+步数+加速度全量历史表（g 值 + roll/pitch 倾角 + 活动分类 + 静止/活动统计） → 物模型定义。

### 运行

```bash
# 单元测试（不依赖真实 blade）
cd business-platform/hkt-blade-device-docking
smart-livestock-server/gradlew test

# 真实联通性验证
./scripts/verify-blade-docking.sh
```

### OAuth2 换票流程

1. blade auth `POST /oauth2/token`，Basic Auth = `hkt_openapi:secret`
2. form params: `grant_type=openapi&userId={serviceUserId}`
3. header: `Tenant-Id: 000000`
4. 返回 `{"code":200,"data":{"accessToken":"...","expiresIn":43200}}`

**serviceUserId 获取方式**（blade 无现成 API 用户时的自建流程）：
```
# 1. 获取 RSA 公钥
curl http://172.22.4.17:8108/code/public-key

# 2. RSA 加密密码（PKCS1Padding）

# 3. 创建用户（feign 端点不需要 token）
curl -X POST http://172.22.4.17:8106/feign/v1/system/sdk/user/create \
  -H "Tenant-Id: 000000" -H "Content-Type: application/json" \
  -d '{"account":"sl_service","password":"{RSA-encrypted}","name":"SL Service"}'

# 4. 启用用户
curl -X PUT http://172.22.4.17:8106/feign/v1/system/sdk/user/{userId}/enable \
  -H "Tenant-Id: 000000"

# 5. 用 userId 换票（grant_type=openapi）
```

### 已验证的真实 API 端点

| 端点 | 方法 | 用途 | 状态 |
|------|------|------|------|
| `/oauth2/token` | POST | OAuth2 换票 | ✅ 12h token |
| `/feign/v1/system/sdk/user/create` | POST | 创建用户（无需 token） | ✅ |
| `/feign/v1/system/sdk/user/{id}/enable` | PUT | 启用用户（无需 token） | ✅ |
| `/feign/v1/device/lifecycle/pageDevices` | POST | 设备列表（120 台） | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetail` | POST | 设备详情 | ✅ |
| `/feign/v1/device/lifecycle/getDeviceDetailWithTelemetry` | GET | **设备+遥测快照** | ✅ |
| `/feign/v1/device/lifecycle/registerDevice` | POST | 设备注册 | ✅ |
| `/feign/v1/device/lifecycle/batchRegisterDevices` | POST | 批量注册 | ✅ |
| `/feign/v1/device/lifecycle/removeDevice` | POST | 删除（软删除） | ✅ |
| `/feign/v1/device/lifecycle/updateDeviceInfo` | POST | 更新设备 | ✅ |
| `/feign/v1/device/telemetry/history/latest` | POST | **最新遥测** | ✅ |
| `/device/report-record/page` | GET | **上行历史（推荐时序数据源，含 decodeData）** | ✅ 324+ 条 |
| `/feign/v1/device/type/findById` | GET | 设备物模型（19 属性） | ✅ |
| `/feign/v1/device-license/control/by-sn` | GET | License 查询 | 服务未注册 |

### CATTLE_TRACKER 物模型（19 属性）

| 属性 | 类型 | 说明 |
|------|------|------|
| `latitude` | float | GPS 纬度 |
| `longitude` | float | GPS 经度 |
| `stepNumber` | int | 步数（活动量） |
| `battery` | int | 电量 (%) |
| `antiDisassemblyStatus` | int | 防拆卸状态 |
| `workMode` | select | 工作模式（固定/分段周期） |
| `xAxisDirectionAccelerationValue` | int | **X 轴加速度（LIS3DH，需换算）** |
| `yAxisDirectionAccelerationValue` | int | **Y 轴加速度** |
| `zAxisDirectionAccelerationValue` | int | **Z 轴加速度** |
| 其余 10 个 | - | 分段周期配置、软硬件版本、上报间隔 |

### 加速度计换算（LIS3DH，固件源码 + 规格书 + 实测三方确认）

**传感器**: ST LIS3DH 三轴 MEMS 加速度计

**固件配置**（源码分析确认）:

| 配置项 | 值 |
|--------|-----|
| 量程 | ±2g |
| 分辨率模式 | Low Power（8-bit，~16mg 分辨率） |
| 数据上报 | 原始整数（`lis3dh_get_raw_data`） |
| 动作阈值 | 512 raw ≈ 32mg（小于此值当噪声忽略） |
| 高通滤波 | 未启用（数据含重力，静止合矢量 ≈ 1g） |

**换算公式**:
```python
def blade_accel_to_g(raw: int) -> float:
    signed = raw - 65536 if raw > 32767 else raw
    return signed * 0.004  # ~3.57mg/digit (实测), 4mg/digit (规格书)
```

**倾角计算**（数据含重力，可直接算姿态）:
```python
import math
roll  = math.degrees(math.atan2(ay, az))
pitch = math.degrees(math.atan2(-ax, math.sqrt(ay**2 + az**2)))
```

**活动分类**:

| 合矢量 | 分类 | 业务含义 |
|--------|------|---------|
| < 1.15g | rest | 静止/休息 |
| 1.15-1.5g | light | 轻微活动（吃草） |
| 1.5-2.5g | active | 活跃行走 |
| > 2.5g | intense | 剧烈运动/冲击 |


**精度限制**: LP 8-bit 模式最小可分辨 ~16mg。反刍咀嚼等细微动作可能检测不到。固件有 `lis3dh_high_res`（~1mg）备选，建议长期切换以支持健康监测。

**代码**: `AccelerometerConverter.java`（`toG` / `toMs2` / `magnitudeG` / `motionIntensity` / `rollDegrees` / `pitchDegrees` / `classifyActivity` / `isAboveFirmwareThreshold`）

### 技术栈

- Spring Boot 3.3.0 + Spring Cloud 2023.0.4 + OpenFeign（无 Nacos）
- Cloud 2023.0.x 匹配 Boot 3.2/3.3（Cloud 2024.0.x 需要 Boot 3.4.x）
- 加速度计换算工具类 + 10 个单元测试

### 与 smart-livestock-server 主项目的关系

本工程是独立 PoC。验证通过后，同一套 Feign Client / OAuth2 / DTO / 加速度计换算直接迁移到
`smart-livestock-server/.../iot/infrastructure/client/feign/`。
