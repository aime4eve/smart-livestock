# ThingsBoard 遥测直连通道实施计划（NIX-179 Phase 1）

> Date: 2026-08-28\
> Spec: `docs/superpowers/specs/2026-08-28-tb-telemetry-channel-design.md`\
> Issue: NIX-179（Parent: NIX-142）\
> 策略: 每个任务编译验证；全部完成后部署 dev 做端到端验证；通道默认关闭，dev 用 env 开启验证

---

## Task 1：数据模型与来源枚举

1. `TelemetrySource` 新增 `THINGSBOARD`。
2. Flyway 迁移 `V20260828110000__tb_device_bindings.sql`：`tb_device_bindings` 表 + 索引 + 种子（`001a0103ff00027f` → RESOLVED，TB UUID 由实现时 API 查询后写入）。
3. `TbDeviceBinding` 实体 + `TbDeviceBindingRepository`（`findResolvedByTenant`、`findByDeviceIdAndProvider`）。

**验证**：`./gradlew compileJava compileTestJava` 通过；迁移 SQL 语法走 psql 本地/远端冒烟（部署时 Flyway 验证）。

## Task 2：TbClient

1. `TbProperties`（`smartlivestock.tb.*`，enabled 默认 false）。
2. `TbClient`：`login()`（POST /api/auth/login）、401 重新登录一次重放、`resolveDeviceId(eui)` 三变体精确匹配（多变体命中不同设备抛 INVALID）、`fetchTimeseries(deviceId, keys, startTs, endTs, limit)`、limit 截断时收窄窗口续拉。
3. 单元测试（MockWebServer 或接口桩）：登录头、401 自愈、三变体解析、截断续拉。

**验证**：目标测试全绿。

## Task 3：TbTelemetryChannel

1. `@Scheduled(poll-interval-ms)`，`enabled=false` 时不注册调度（`@ConditionalOnProperty`）。
2. 每绑定设备：`startTs = cursor==null ? now-lookback-days : cursor+1`；拉取 → 逐帧解析 → `ingest(deviceId, readings, ts, THINGSBOARD)` → 游标=本批最大 ts。
3. 解析：`result.decodeStatus=true` 时用 `result.decodeData.properties`（复用 `AgenticPlatformReportData` 属性映射 + tracker 加速度换算 + GPS clamp），跳过 `dataHex`；result 缺失/不可解时才走 `dataHex` TLV fallback。
4. 异常 fail-open：单设备失败不影响其他设备与其他通道，warn 日志。
5. 单元测试：同帧单次入库、游标推进、GPS clamp、设备非 ACTIVE 时 ingest 抛 STATE_CONFLICT 的容错。

**验证**：目标测试全绿。

## Task 4：blade 通道排除开关

`AgenticPlatformSyncDispatcher` 派发前查绑定表，`smartlivestock.tb.blade-exclusion=true` 时跳过已绑设备。默认 false，不改存量行为。

**验证**：Dispatcher 现有测试回归 + 新增排除逻辑单测。

## Task 5：编译与目标测试

`./gradlew compileJava compileTestJava` + 新增测试类全部通过 + 既有 `DeviceApplicationServiceTest` 等目标回归。

## Task 6：dev 部署与端到端验证

1. `./scripts/deploy.sh dev`（迁移自动执行）。
2. 远程 `.env.dev` 追加 `SMARTLIVESTOCK_TB_ENABLED=true` 与凭据（env 注入，不入 git），重启 dev app。
3. 验证：`tb_device_bindings` 种子在库；等待/手动触发一轮轮询后 psql 查 `device_telemetry_logs WHERE source='THINGSBOARD'` 出现 `001a0103ff00027f` 记录；`telemetry_cursor_ms` 前进；重启 app 后游标不回退、无重复窗口拉取。
4. blade 回归：未绑定设备（如 tracker 178/179）同步日志行为不变。

## Task 7：提交

分支 `nix/tb-telemetry-channel`（前缀规范），提交信息引用 NIX-179；推送；test 环境部署等用户通知。
