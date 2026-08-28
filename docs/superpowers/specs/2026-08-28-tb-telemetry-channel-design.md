# ThingsBoard 遥测直连通道设计（Phase 1 REST）

> Date: 2026-08-28\
> Status: 评审修订，待整改验证\
> Issue: NIX-179（Parent: NIX-142）\
> 参照: smart-parking NIX-80 决策文档（`04-smart-parking/docs/research/2026-07-30-blade数据采集通道设计决策.md`）与 NIX-122 正式通道 spec（`04-smart-parking/docs/features/tb-telemetry-channel/spec.md`）\
> Plan: `docs/superpowers/plans/2026-08-28-tb-telemetry-channel-plan.md`

---

## 1. 背景与实测事实

2026-08-28 通过 TB REST API、blade API 与双环境数据库实测确认真实拓扑：

```
传感器 → LoRaWAN → 网关 → NS → ThingsBoard（遥测源头）
                                     │ Kafka
                                     ▼
                                   blade（下游设备中台，不可改代码）
                                     │ report-record/page
                                     ▼
                    smart-livestock 现有轮询通道（5 分钟）
```

关键事实：

1. blade 是 TB 的下游中台。现有通道存在 5 分钟轮询延迟、字段经 TB→blade 裁剪、blade 单点依赖三重硬伤。
2. TB test：`http://172.22.3.105`（TB 3.8.0），REST 登录 `POST /api/auth/login`，后续请求头 `X-Authorization: Bearer <jwt>`（非标准 Authorization 头）。
3. 瘤胃胶囊 profile `瘤胃胶囊-OC-配置-v2` 16 台中 5 台有 30 天内数据；追踪器 profile `牛羊追踪器-OC-配置-v2` 245 台，已知活跃设备有历史数据（最新 2026-07-22）。耳标类型在 TB 租户上不存在。
4. TB `result`（`{"decodeStatus":true,"decodeData":{"properties":{...}}}`）与 blade `decodeData.properties` 同构；`dataHex` 为原始帧，仅作 fallback。同一次到达中 `result` 与 `dataHex` 是同一物理帧，必须单次入库。
5. TB `ts` 为 epoch ms（UTC），比 blade `reportTime`（Asia/Shanghai 墙钟无时区）更规范，两源时间不得混用为同一幂等键。

## 2. 目标与非目标

**目标（本工单 = Phase 1 REST）**

1. 新增 TB REST 直连通道，作为与 blade 轮询平行的第三条采集通道（source=`THINGSBOARD`）。
2. 解析后统一进入 `TelemetryIngestionService.ingest()`，入库下游（快照、时序表、告警、GPS 异步）零改动。
3. 绑定表 + per-device 游标，按 parking NIX-80 D11/D12 规范建模（裁剪版）。
4. 已绑定 TB 的设备可配置从 blade 同步排除，防止同帧双写；开关默认关闭，存量设备行为完全不变。

**非目标（后续工单）**

- Phase 2：TB WebSocket 实时通道（30s ping、指数退避重连、重连 fresh login + 重建订阅）。
- Phase 3：追踪器批量接入与 90 天历史回补。
- 耳标：TB 无设备，通道类型预留但不承诺。
- 跨通道 canonical 去重（parking D13 全套）：按设备路由规避后，确有双源并存需求再上。
- 替换或修改现有 blade 轮询通道、datagen 仿真链路。

### 评审修订结论

1. 游标采用 at-least-once 语义：只允许推进到连续成功处理的前缀边界；单帧失败不得被游标越过。
2. `result` 只有在 `decodeStatus=true` 且能解析出有效 `decodeData.properties` 时才是 authoritative；坏 result 不得抑制 `dataHex` fallback。
3. `blade-exclusion=true` 是明确的源路由选择，不是故障回退机制；开启后绑定设备的采集连续性依赖 TB 通道可用性。
4. Phase 1 种子包含 tracker 与 capsule 两个已验证绑定；多租户批量接入前必须补 tenant-scoped 绑定查询。

## 3. 现有架构基线

通道层（怎么拉）：

```
AgenticPlatformSyncDispatcher（@Scheduled 5min，扫 devices.platform_device_id）
  → 内部 RocketMQ → AgenticPlatformSyncWorker（消费者）
  → AgenticPlatformTelemetrySyncJob.syncDevice(deviceId)
      游标 devices.last_telemetry_synced_at + lastActiveTime 预检
      → GET blade /device/report-record/page 分页
      → AgenticPlatformReportData.toReadings(record, deviceType)
```

入库层（拉到之后）：

```
TelemetryIngestionService.ingest(deviceId, readings, recordedAt, source)
  单事务：设备快照 + 时序表（temperature/rumen_motility/activity/device_telemetry/anomaly_scores）
  + 告警评估 + 游标推进；GPS 特例写 gps_ingestion_tasks → GpsIngestionTaskScheduler 异步落 gps_logs
```

`TelemetrySource` 现有枚举：`AGENTIC_PLATFORM / DATAGEN / HTTP / MANUAL_IMPORT`，本次新增 `THINGSBOARD`。

## 4. 架构设计

### 4.1 组件

| 组件 | 位置 | 职责 |
|------|------|------|
| `TbProperties` | `iot/infrastructure/client/thingsboard/` | `smartlivestock.tb.*` 配置：enabled（默认 false）、base-url、username、password、poll-interval-ms、lookback-days、blade-exclusion |
| `TbClient` | 同上 | JWT 登录（POST /api/auth/login）、`X-Authorization` 注入、401 重新登录一次、设备三变体名解析、timeseries 窗口查询、limit 截断续拉 |
| `TbDeviceBinding` + Repository | `iot/domain/model` + `iot/infrastructure/persistence` | 绑定实体与查询（按 tenant + device、按 tenant + status 列表） |
| `TbTelemetryChannel` | `iot/application/` | @Scheduled 增量轮询绑定设备 → `result.decodeData.properties` → `readings` → `ingest()` → 连续成功前缀游标推进 |
| Dispatcher 排除 | `AgenticPlatformSyncDispatcher` | 查询绑定表排除已绑 TB 的设备（仅当 `smartlivestock.tb.blade-exclusion=true`） |

### 4.2 数据流

```
TbTelemetryChannel（@Scheduled，默认 300s，enabled=false 时整个通道不装配）
  1. 读绑定表：当前接入范围内 status=RESOLVED 的绑定
  2. 每设备：GET /api/plugins/telemetry/DEVICE/{tbDeviceId}/values/timeseries
       ?keys=<按设备类型>&startTs=cursor+1&endTs=now&orderBy=ASC&limit=<batch>
  3. limit 截断：以本批最大 ts 收窄窗口续拉，禁止推进游标丢尾部帧
  4. 每帧：仅有效 result（decodeStatus=true 且映射出非空业务 readings）
       才作为 authoritative；无效 result 走 dataHex fallback。当前 TLV fallback
       覆盖 capsule；tracker 若 result 无效且 dataHex 不可解码，按失败帧处理
  5. readings（键与 blade 通道一致）→ ingest(deviceId, readings, ts, THINGSBOARD)
  6. 游标 = 本批连续成功处理前缀的最大 ts；遇到失败帧立即停止该设备后续帧，
       但不影响其他绑定设备。若崩溃发生在 ingest 与游标保存之间，重启后允许重放，
       由 (device_id, report_time) / (device_id, recorded_at) 唯一约束吸收重复
```

### 4.3 数据模型：`tb_device_bindings`

| 列 | 类型 | 语义 |
|----|------|------|
| id | BIGSERIAL PK | |
| tenant_id | BIGINT NOT NULL | 租户 |
| device_id | BIGINT NOT NULL | 本地 devices.id |
| provider | VARCHAR(20) NOT NULL | 固定 `THINGSBOARD`（预留 BLADE） |
| device_eui | VARCHAR(32) NOT NULL | 规范化小写 EUI（业务关联键） |
| external_device_id | VARCHAR(64) NOT NULL | TB deviceId（UUID） |
| external_device_name | VARCHAR(100) | TB 原始设备名，保留大小写 |
| binding_status | VARCHAR(20) NOT NULL | `PENDING / RESOLVED / INVALID` |
| telemetry_cursor_ms | BIGINT | per-device 已完整处理边界（epoch ms，单调前进） |
| last_event_at / last_verified_at | TIMESTAMP | 最近事件 / 最近绑定校验 |
| created_at / updated_at | TIMESTAMP | |

约束：`unique(provider, external_device_id)`、`unique(device_id, provider)`。种子数据（迁移内）登记两个已验证绑定：tracker `00956906000285cf` 与 capsule `001a0103ff00027f`（均 RESOLVED）。tracker 用于有历史数据的端到端验证，capsule 作为后续验证绑定保留；其余设备由运维后续插入，不自动全量绑定。

## 5. 关键规则

1. **三变体解析**：TB 设备名大小写敏感，按 `原样 → 大写 → 小写` 依次精确匹配 DevEUI；多变体同时命中不同设备时标 INVALID 并告警日志，不随机绑定。
2. **同帧单次入库**：仅当 `result.decodeStatus=true` 且 `decodeData.properties` 可解析出非空 readings 时，`result` 才是 authoritative 并抑制同帧 `dataHex`；`decodeStatus=false`、result 缺失、JSON 损坏或映射后为空时必须走 `dataHex` TLV fallback。
3. **游标语义**：游标 = 连续成功处理前缀的最大源时间；REST 拉取 `startTs=cursor+1ms`。单帧 ingest 失败时禁止推进到该帧之后，必须停止该设备本轮后续帧并保留失败边界供下轮重试。断连、进程崩溃或游标保存前重启按 at-least-once 处理，允许重放，重复帧由数据库唯一约束和同事务回滚吸收。
4. **limit 截断**：本批达到 limit 时收窄 endTs 续拉，直到不足一批，最后才推进游标。
5. **时间**：TB `ts` 直接 epoch ms → Instant（UTC），不做墙钟换算（教训 #17）。
6. **401 自愈**：任何 TB 调用收到 401 → 重新登录一次并重放该请求，再失败才抛错；登录失败计数告警日志。
7. **fail-open 隔离**：TB 通道异常不得阻断 blade Dispatcher、其他绑定设备或 API 服务（异常捕获 + warn 日志 + 下轮重试）。注意这不等于为已路由到 TB 的设备提供 blade 故障回退。
8. **双写防护与路由语义**：`blade-exclusion=true` 时 Dispatcher 排除已绑设备，表示该设备的数据源路由到 TB；TB 故障期间这些设备会出现采集延迟，直到 TB 恢复。该开关默认 false。Phase 3 批量启用前必须补充 TB 不可用告警，或实现明确的 blade 回退策略。
9. **凭据**：`SMARTLIVESTOCK_TB_USERNAME / SMARTLIVESTOCK_TB_PASSWORD` env 注入，不落库不硬编码；当前密码已曾在会话中暴露，上线前应轮换。

## 6. 解析映射（result.decodeData.properties → readings）

properties 键与 blade `decodeData.properties` 同构，复用 `AgenticPlatformReportData` 的属性映射逻辑：

| TB properties 键 | readings 键 | 适用设备 |
|------------------|-------------|---------|
| `temperatureGroup` | `temperatureGroup` | 胶囊 |
| `gastricMotility` | `gastricMotility` | 胶囊 |
| `batteryVoltage` | `batteryVoltage` | 胶囊/追踪器 |
| `software` / `hardware` | `softwareVersion` / `hardwareVersion` | 通用 |
| `dataSyncCycle` | `dataSyncCycle` | 通用 |
| `xAxisAccelerationValue` 等 | `accelXRaw` 等 → 换算 `accelXG/activityClass/rollDegrees/pitchDegrees` | 追踪器 |
| `latitude` / `longitude`（DECIMAL）| `latitude` / `longitude` | 追踪器 |
| `stepNumber` | `stepNumber`（ingest 内已有累计→增量换算） | 追踪器 |
| `rssi` / `snr` / `downLinkGateway` | `rssi` / `snr` / `gatewayId` | 通用 |

Tracker 帧走 `applyAccelerometerConversion`；GPS 越界值沿用现有 clamp 保护。

## 7. 配置项

| 配置 | 默认 | 说明 |
|------|------|------|
| `smartlivestock.tb.enabled` | `false` | 通道总开关，false 时不装配 |
| `smartlivestock.tb.base-url` | `http://172.22.3.105` | TB 地址 |
| `smartlivestock.tb.username` / `password` | env | 凭据 |
| `smartlivestock.tb.poll-interval-ms` | `300000` | REST 轮询周期 |
| `smartlivestock.tb.lookback-days` | `7` | 首次绑定（cursor=null）回看窗口 |
| `smartlivestock.tb.batch-size` | `200` | 单设备单次 limit |
| `smartlivestock.tb.blade-exclusion` | `false` | Dispatcher 排除已绑设备开关 |
| `smartlivestock.tb.tenant-id` | 空 | Phase 1 单接入范围租户；启用 tenant-scoped 绑定查询时必填 |

Phase 1 允许单接入范围读取绑定；Phase 3 多租户/批量接入前必须改为显式 tenant-scoped 查询，禁止跨租户调度绑定设备。

## 8. 验收标准

- [ ] 绑定表迁移 + 种子部署 dev 成功；`00956906000285cf` 与 `001a0103ff00027f` 均绑定 RESOLVED
- [ ] TB 通道轮询后 `device_telemetry_logs` 出现 `source=THINGSBOARD` 记录，设备快照更新正常（告警评估按现有设计仅对 AGENTIC_PLATFORM 来源触发，TB 来源暂不触发告警，如需放开另行决策）
- [ ] 游标单调推进；失败帧之后的帧不被处理，游标不越过失败帧；崩溃后重放不产生重复 telemetry/GPS 记录
- [ ] 未绑定设备 blade 通道行为与现状一致（回归：目标测试 + dev 巡检日志）
- [ ] `enabled=false`（默认）时零行为变化（不装配、不建 HTTP 连接）
- [ ] 单元测试：properties→readings 映射、同帧单次、`decodeStatus=false`/坏 result 走 fallback、失败帧阻断游标、limit 截断续拉、401 自愈、三变体解析、blade exclusion、GPS clamp、非 ACTIVE 容错
- [ ] `./gradlew compileJava` + 目标测试全绿；dev 部署健康检查通过

## 9. 风险与开放问题

1. 胶囊 `001a0103ff000262` 物理层未上线（lastActivity=never），通道不解决设备本体问题，需另行排查 NS/密钥/网关覆盖。
2. TB 密码已在排查会话中明文暴露，上线前轮换。
3. `blade-exclusion=true` 当前不提供 blade 故障回退；Phase 3 批量启用前需要补充可用性告警或回退策略。
4. 追踪器双源（blade + TB）并存时的 canonical 去重留待 Phase 3 决策。
5. 多租户批量接入前必须补 tenant-scoped 绑定查询与测试。
6. TB 生产环境地址与凭据分发方式待平台团队提供（当前仅 test）。
