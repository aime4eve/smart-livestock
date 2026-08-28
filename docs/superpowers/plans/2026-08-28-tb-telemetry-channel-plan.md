# ThingsBoard 遥测直连通道实施计划（NIX-179 Phase 1）

> Date: 2026-08-28\
> Spec: `docs/superpowers/specs/2026-08-28-tb-telemetry-channel-design.md`\
> Issue: NIX-179（Parent: NIX-142）\
> 策略: 实现对齐版。Phase 1 代码已在分支落地，本计划用于记录缺口整改与验证收尾；全部完成后部署 dev 做端到端验证，test 部署等待用户通知。完整评审锚点：`docs/reviews/2026-08-28-tb-telemetry-channel-spec-plan-review.md`

---

## Task 1：数据模型与来源枚举

**当前状态**：已整改。tenant-scoped 查询、binding_status CHECK、种子环境说明已补齐。

1. `TelemetrySource` 新增 `THINGSBOARD`。
2. Flyway 迁移 `V20260828110000__tb_device_bindings.sql`：`tb_device_bindings` 表 + 索引 + 两个已验证种子（tracker `00956906000285cf`、capsule `001a0103ff00027f`，TB UUID 由实现时 API 查询后写入）。
3. `TbDeviceBinding` 实体 + `TbDeviceBindingRepository`（`findByTenantIdAndStatus`、`findByDeviceIdAndProvider`）。Phase 1 单接入范围可由显式配置提供 tenant；Phase 3 前禁止无租户边界的全局绑定扫描。

**验证**：`./gradlew compileJava compileTestJava` 通过；迁移 SQL 语法走 psql 本地/远端冒烟（部署时 Flyway 验证）。

## Task 2：TbClient

**当前状态**：已整改。401 与三变体目标测试通过。

1. `TbProperties`（`smartlivestock.tb.*`，enabled 默认 false）。
2. `TbClient`：`login()`（POST /api/auth/login）、401 重新登录一次重放、`resolveDeviceId(eui)` 三变体精确匹配（多变体命中不同设备抛 INVALID）、`fetchTimeseries(deviceId, keys, startTs, endTs, limit)`。
3. 单元测试（MockWebServer 或接口桩）：登录头、401 自愈、三变体解析、timeseries 查询参数。limit 截断续拉由 `TbTelemetryChannel` 测试覆盖。

**验证**：目标测试全绿。

## Task 3：TbTelemetryChannel

**当前状态**：已整改。decodeStatus/坏 result 边界、连续成功游标、DTL 幂等冲突归类均有单测覆盖。

1. `@Scheduled(poll-interval-ms)`，`enabled=false` 时不注册调度（`@ConditionalOnProperty`）。
2. 每绑定设备：`startTs = cursor==null ? now-lookback-days : cursor+1`；拉取 → 逐帧解析 → `ingest(deviceId, readings, ts, THINGSBOARD)`。
3. 解析：仅 `result.decodeStatus=true` 且 `decodeData.properties` 可解析出非空 readings 时，才用 result 并跳过同帧 `dataHex`；`decodeStatus=false`、result 缺失/坏 JSON/空映射必须走 `dataHex` TLV fallback。
4. 游标：只推进到连续成功处理前缀的最大 ts。任一帧 ingest 失败后立即停止该设备本轮后续帧，游标不得越过失败帧；其他设备继续处理。
5. 异常 fail-open：单设备失败不影响其他设备、blade Dispatcher 或 API 服务，warn 日志。
6. 单元测试：同帧单次入库、`decodeStatus=false`/坏 result fallback、失败帧阻断后续帧且游标不越过失败帧、GPS clamp、设备非 ACTIVE 时 ingest 抛 STATE_CONFLICT 的容错。

**验证**：目标测试全绿。

## Task 4：blade 通道排除开关

**当前状态**：已整改。tenant 范围与 exclusion 单测已补齐。

`AgenticPlatformSyncDispatcher` 派发前查绑定表，`smartlivestock.tb.blade-exclusion=true` 时跳过已绑设备。默认 false，不改存量行为。文档与实现必须明确：该开关是数据源路由，不提供 TB 故障时的 blade 回退；Phase 3 批量启用前补充可用性告警或回退策略。

**验证**：Dispatcher 现有测试回归 + 新增排除逻辑单测（开启时跳过绑定设备、关闭时不查绑定表、绑定查询失败不阻断未绑定设备）。

## Task 5：编译与目标测试

**当前状态**：已完成。`compileJava`、`compileTestJava` 与 NIX-179 目标测试通过。

`./gradlew compileJava compileTestJava` + 新增测试类全部通过 + 既有 `DeviceApplicationServiceTest` 等目标回归。必须覆盖：limit 达到 batch-size 后缩小窗口续拉且无丢帧、失败帧阻断游标、坏 result 走 fallback、blade exclusion。

## Task 6：dev 部署与端到端验证

**当前状态**：已完成复验。V20260828140000 迁移成功；游标回拨重放后 DTL/GPS 行数不变且游标恢复最大值。

1. `./scripts/deploy.sh dev`（迁移自动执行）。
2. 远程 `.env.dev` 追加 `SMARTLIVESTOCK_TB_ENABLED=true` 与凭据（env 注入，不入 git），重建 dev app。
3. 验证：`tb_device_bindings` 中 tracker `00956906000285cf` 种子在库；capsule `001a0103ff00027f` 是 guarded seed，仅在其本地设备存在的环境出现在库；等待/手动触发一轮轮询后 psql 查 `device_telemetry_logs WHERE source='THINGSBOARD'` 出现 tracker 记录；`telemetry_cursor_ms` 前进；重启 app 后游标不回退，重放窗口不产生重复 telemetry/GPS 记录。
4. blade 回归：未绑定设备同步日志行为不变；`blade-exclusion=false` 时绑定设备不改变 blade 行为。

## Task 7：评审整改与提交

1. 按 `docs/reviews/2026-08-28-tb-telemetry-channel-spec-plan-review.md` 的 F1-F8 逐项关闭，并在该文档回填关闭状态。
2. 更新 Linear NIX-179 评论，附 spec/plan 修订说明、目标测试结果和 dev 验证证据。
3. 提交分支 `nix/tb-telemetry-channel` 并推送；test 环境部署等待用户通知。
