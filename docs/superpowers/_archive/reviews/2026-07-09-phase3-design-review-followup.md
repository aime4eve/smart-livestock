# Phase 3 实施设计 — 复审报告

**被评审文档**: `docs/superpowers/specs/2026-07-08-phase3-blade-integration-device-health-spec.md`（评审修正后版本）
**前置评审**: `docs/superpowers/reviews/2026-07-09-phase3-design-review.md`
**复审日期**: 2026-07-09

---

## 一、复审结论：✅ 可以进入实施

上一轮评审的 3 个阻塞问题全部解决，4 个中等问题中 3 个已解决。仅剩 **2 个轻微不一致** 需要在实施前微调，不阻塞实施。

---

## 二、已解决问题对照

| 原问题 | 严重程度 | 状态 | 修正位置 |
|--------|---------|------|---------|
| 透传架构 + 数据流不一致 | 🔴 | ✅ 已解决 | §5.1 方案 B 数据流图 + D1-D7 配套设计要求 |
| 防拆卸告警无去重 | 🔴 | ✅ 已解决 | §3.3 内联创建 + 去重，§6.3 `detectDeviceAlerts()` / `createDeviceAlertIfNotExists()` |
| SyncJob 设计缺失 | 🔴 | ✅ 已解决 | §5.5 消息驱动同步（Dispatcher + Worker），含游标/分页/重试/并发/容量估算 |
| Feign Client 迁移策略 | 🟡 | ✅ 已解决 | A1 + D6 明确迁移到 smart-livestock-server |
| 字段名映射混乱 | 🟡 | ✅ 已解决 | §6.2 标准 readings key 规范表（17 个 key），删除 batteryLevel 兼容 |
| decodeData 字段不全 | 🟡 | ✅ 已解决 | §6.2 区分 decodeData 内字段 vs report-record 顶层字段 |
| 任务分解遗漏 | 🟢 | ✅ 已解决 | A5 拆为 4 子任务（A5a-d），新增 C2a / AccelerometerConverter / JPA Entity / Mapper / DTO |
| health_score 命名冲突 | 🟢 | ✅ 已解决 | §3.1 顶部注明 `device_health_score` |

---

## 三、轻微不一致（实施前微调即可）

### 🟡 1. alerts 表加 `device_id` 列未纳入 §2 表结构扩展

**现状**：§3.3 和 §8.1 均指出 `alerts` 表需要新增 `device_id BIGINT` 列（现有表无此列），A3 任务描述也包含此变更。但 §2"设备模型扩展"只列了 `devices` 的 ALTER 和 `device_telemetry_logs` 的 CREATE，遗漏了 `alerts` 的 ALTER。

**建议修正**：在 §2 末尾增加 alerts 表扩展：

```sql
ALTER TABLE alerts
    ADD COLUMN IF NOT EXISTS device_id BIGINT;
```

### 🟡 2. `snr` 在 readings Map 中的类型需加注原因

**现状**：§6.2 标准 key 表写 `snr` 类型为 `String`，但 §2.1 devices 表和 §2.2 device_telemetry_logs 中 `snr` 定义为 `NUMERIC(4,1)`。§6.3 `updateDeviceRuntimeStatus` 用 `toBigDecimal(snr)` 做转换。逻辑一致但缺少说明。

**建议修正**：在 §6.2 snr 行的"说明"列加注：

> blade report-record 顶层 snr 为 String 类型（如 "12.5"），ingest 内 `toBigDecimal()` 转换后写入 DB `NUMERIC(4,1)`。

---

## 四、新增设计的质量确认

### §5.5 消息驱动同步（Dispatcher + Worker）

文档新增了 RocketMQ 分发架构，比简单定时轮询更完整。评审确认：

| 维度 | 评估 | 说明 |
|------|------|------|
| 容量估算 | ✅ 合理 | 10000 台 / 15-25s，DB QPS 660 无压力 |
| 容错策略 | ✅ 完整 | 死信队列 + 游标去重 + 事务回滚 + rebalance |
| 数据流 | ✅ 一致 | 直接复用方案 B 的 ingest() 入口，无新分支 |
| 可扩展性 | ✅ 良好 | 增加实例即增加吞吐 |

**实施提醒**：Dispatcher 查询 `WHERE platform_device_id IS NOT NULL AND status = 'ACTIVE'` 需要 `DeviceRepository` 提供对应查询方法（`findActivePlatformDeviceIds`），当前 Repository 接口无此方法，实施时需补充。

### §5.6 加速度计换算

从 PoC `AccelerometerConverter` 迁移，换算逻辑经过固件源码 + 规格书 + 92 个实测样本三方验证。换算在 SyncWorker 组装 readings 时完成（数据入口边界），下游统一消费换算值，设计合理。

### §6.3 TelemetryIngestionService 升级

新增 `TelemetrySource` 枚举 + 7 步分流逻辑（验证→状态→时序→GPS→告警→透传→游标），保持透传 `TelemetryReceivedEvent` 给 Health 上下文。告警逻辑仅在 `source=AGENTIC_PLATFORM` 时触发，datagen 不产生真实告警。设计清晰。

---

## 五、命名一致性确认

文档中将之前的 "blade" 全面替换为 "中台（agentic-middle-platform）"，代码层面映射：

| 概念 | 文档用词 | DB 字段 | Java 字段 |
|------|---------|---------|----------|
| 中台设备 ID | 中台 deviceId | `platform_device_id` | `agenticPlatformDeviceId` |
| Feign Client 路径 | — | — | `iot/infrastructure/client/agenticplatform/` |
| 同步 Job | AgenticPlatformTelemetrySyncJob | — | — |
| TelemetrySource 枚举 | AGENTIC_PLATFORM | — | — |

Java 侧使用 `agenticPlatform*` 前缀，DB 侧使用 `platform_*` 前缀，属合理差异（Java 偏重语义，DB 偏重简洁）。

---

## 六、总结

**阻塞项：0**
**轻微不一致：2（建议实施前修正，不阻塞）**

文档从初版的"方向正确但细节不足"升级为"方向正确且细节充分"，可以进入实施阶段。
