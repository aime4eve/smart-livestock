# 设备软删除设计终评（v2 修订版）

终评日期：2026-07-21
被评审文档：`docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`（状态：已修订 v2）
前置评审：初评 `2026-07-21-device-soft-delete-design-review.md`、复审 `2026-07-21-device-soft-delete-design-re-review.md`

## 终评结论

**通过，可进入实施。**

v2 修订按需求澄清将"停止数据链路"重构为**真设备停 blade / 假设备停 datagen 仿真**的分流模型，并采纳复审全部 P1/P2。经源码核实，分流判定的锚点（`platform_device_id` 非空 = 真设备）与实现一致，两条停止机制均成立。本设计已具备实施条件。

## 勘误：复审"datagen 适用范围注明 test 生效"意见作废

复审中"datagen 停止仅适用于 `DATAGEN_ENABLED=true` 环境"的意见**作废**，该意见源于对 datagen 的狭义误解。

| 复审（错误）理解 | 正确理解（v2 澄清） |
|---|---|
| datagen = `SynthesisService` 仿真，受 `DATAGEN_ENABLED` 开关控制 | "设备数据来源"总称，分两路 |
| 假纠结 dev/test 开关、纠结生产有无此链路 | 应按真/假设备分别确保两路停止 |
| 把"停止仿真"当成 datagen 的全部 | 仿真只是假设备那一路；真设备那一路是 blade 采集 |

正确的视角是 v2 现在的写法。判定锚点经核实与代码一致：

- `Device.platformDeviceId` 为 `Long` 包装类型，`new Device()` 默认 `null`（假设备）；
- 仅 `activateOnPlatform()` 成功（EUI 反查命中 `DeviceApplicationService.java:222` 或注册成功 `:309`）才 `bindPlatformDeviceId` 设值（真设备）；
- blade 调度 `findActivePlatformDeviceIds` SQL `WHERE status='ACTIVE' AND platformDeviceId IS NOT NULL`（`SpringDataDeviceRepository.java:35`）恰好等价于"只同步真设备"。

因此 spec v2 的分流模型是正确的，复审那条意见不成立。

## 真/假设备分流停止机制核实

**真设备（platformDeviceId 非空）→ blade 同步**：
- 删除后 `@SQLRestriction("deleted_at IS NULL")` 作用于 `findActivePlatformDeviceIds` → 调度不再返回该 id → blade 同步停止。
- 并发安全：删除前已入 MQ 的在途同步任务，Worker 消费时 `syncDevice` 内 `findById` 返回 null（全局过滤），`:49` 处 `device == null → return`，不会对已删设备写数据。天然安全，无需额外处理。

**假设备（platformDeviceId 为空）→ datagen 仿真**：
- 删除时自动解绑（`InstallationApplicationService.remove` 置 `removed_at`）→ 该设备脱离 `findAllActive()`；
- 全局过滤使 `DeviceQueryPortImpl.findActiveInstallations()` 内 `findById` 返回 null → 双重保障停止仿真。
- 注：`DeviceQueryPortImpl.java:29` 的 `status != ACTIVE` 检查主要兜底"退役未删"场景，软删除路径上由前两重先命中（P2-B 表述已采纳）。

## 遗留项状态汇总

| 项 | 初评/复审 | v2 处置 | 核实 |
|---|---|---|---|
| P0-1/P0-2 状态机冲突 | 初评 | 删除三步、不改 status | ✅ |
| P1-1 租户校验 | 初评 | deleteDevice 加租户断言 | ✅ |
| P1-2 全局过滤 | 初评 | @SQLRestriction + native 例外 | ✅ |
| P1-3 Mapper 双向映射 | 初评 | toJpaEntity/toDomain 补 deletedAt | ✅ |
| P1-4 复活状态语义 | 初评 | 行为速查补"回 INVENTORY" | ✅ |
| P2-1 deviceCode 判重（registerDevice） | 初评 | 复活前 findByDeviceCode 活跃判重 | ✅ |
| P2-2 迁移 IF EXISTS | 初评 | 三个 DROP 全部 IF EXISTS | ✅ |
| P2-3 alerts | 初评 | 核实不成立，移除 | ✅ |
| P2-4 i18n key | 初评 | 不新增后端 key | ✅ |
| P2-5 预检并发 | 初评 | 文档注明 best-effort | ✅ |
| P1-A 复活持久化 merge 陷阱 | 复审 | native UPDATE 先行再 save() | ✅ 方案完整 |
| P2-A findOrCreateByEui 判重 | 复审 | 传值非空且不同才更新+判重 | ✅ |
| P2-B 三重保障表述 | 复审 | 标注主/兜底 | ✅ |
| P2-C 质检历史 LEFT JOIN | 复审 | 接受为已知限制 + 去重顺序修正 | ✅ |
| datagen 适用范围 | 复审 | **意见作废**（狭义误解） | — |

**额外亮点**：v2 自行挖出复审未涉及的"批量导入去重顺序"问题——`existsByEuiAndTimeRange`（INNER JOIN devices，`:146`）在设备软删除时 JOIN 失效导致去重漏判，并提出"把复活移到去重之前"的修正。比复审原意见更深入，方案正确。

## 实施层小提示（不阻断，P2）

1. **native UPDATE 的 JPA 持久化上下文**：`UPDATE devices SET deleted_at=NULL, status='INVENTORY' WHERE id=?` 是 `@Modifying` 查询，执行后同一事务内的持久化上下文可能持有过期的一级缓存实体。建议加 `@Modifying(clearAutomatically = true, flushAutomically = true)`，确保后续 `save()`（merge）从库重新加载到 `deleted_at=NULL` 的行。属实现细节，非设计缺陷。

2. **restore() 与 native UPDATE 双写状态**：领域模型 `restore()` 设 `INVENTORY`，native UPDATE 也设 `INVENTORY`，两处需保持语义一致。若将来 `restore()` 改逻辑，native UPDATE 须同步，建议代码注释互引。

## 建议

spec 已成熟，建议进入实施阶段。实施时落实任务清单 13 项，其中第 4 条（复活持久化）按 v2 的 native UPDATE 先行方案执行；其余 P2 小提示在编码时顺带处理。
