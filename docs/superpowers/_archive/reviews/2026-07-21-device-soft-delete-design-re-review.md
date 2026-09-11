# 设备软删除设计复审（修订版）

复审日期：2026-07-21
被复审文档：`docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`（状态：已修订）
前置评审：`docs/superpowers/reviews/2026-07-21-device-soft-delete-design-review.md`
复审方式：逐条核对修订是否落地 + 核实修订版新增论断（datagen 链路 / save() createdAt 陷阱 / findAllByIdIn）的真实性

## 总体结论

**修订质量高，可进入实施，但实施前需确定第 1 点（复活保存的 native UPDATE 路径）。**

上一轮 P0/P1（共 6 项）全部正确采纳并落实到位；P2 中 P2-3（alerts）经核实前提不成立已合理移除、P2-4（i18n）改"不新增后端 key"的处理合理。修订版还**主动补入 3 处前置评审遗漏的点**（datagen 链路分析、`save()` createdAt 交互陷阱、`findAllByIdIn` 全局过滤覆盖），经源码核实方向正确。

本次复审新发现 **1 个 P1**（复活保存方案不完整）+ **3 个 P2**。

| 项 | 状态 |
|---|---|
| P0-1/P0-2 状态机冲突 | ✅ 已解决（删除三步、不改 status） |
| P1-1 租户校验 | ✅ 已解决 |
| P1-2 全局过滤 | ✅ 已解决（@SQLRestriction） |
| P1-3 Mapper 双向映射 | ✅ 已解决 |
| P1-4 复活状态语义 | ✅ 已解决（行为速查补行） |
| P2-1 deviceCode 判重 | ⚠️ 部分覆盖（见 P2-A） |
| P2-2 IF EXISTS | ✅ 已解决 |
| P2-3 alerts 移除 | ✅ 核实成立（`alerts.device_id` 标量列、告警查询无 JOIN devices） |
| P2-4 i18n key | ✅ 改"不新增后端 key"，合理 |
| P2-5 预检并发 | ✅ 已解决 |
| datagen 链路（新增） | ✅ 机制成立（见 P2-B 表述建议） |

---

## ✅ 已核实成立的修订点

**P0-1/P0-2**：删除流程收敛为"校验 → 解绑 → 软删除"三步，不改 status。与源码一致——`Device.decommission()` 仅允许 `ACTIVE`→`DECOMMISSIONED`（`Device.java:77-83`），`AgenticPlatformTelemetrySyncJob.syncDevice()` 内部不检查 status，停同步确由 `findActivePlatformDeviceIds` 的全局过滤实现。结论正确。

**P1-2 全局过滤覆盖面**：核实 `findAllByIdIn`（`JpaDeviceRepositoryImpl.java:93`）确实封装 `springDataRepo.findAllById(ids)`，属 JpaRepository 默认方法，受 `@SQLRestriction` 覆盖。`findByDeviceTypeOrderById`（`findAllTrackers`）、`findActivePlatformDeviceIds`（blade 调度）同理。复活专用 `findAllByDevEuiAndTenantIdIncludeDeleted` 用 native query 绕过，方向正确（Hibernate 实体级过滤不附加到 native query）。

**P1-3 Mapper 现状**：核实 `DeviceMapper.toJpaEntity/toDomain` 确实完全不处理 `deletedAt`（JpaEntity 有字段、Mapper 无映射），补双向映射的必要性成立。

**datagen 链路三重保障**：核实 `DeviceQueryPortImpl.findActiveInstallations()`（`DeviceQueryPortImpl.java:22-33`）确实存在三重机制——`findAllActive`（过滤 `removed_at`）+ `findById`（全局过滤后返回 null）+ `device.getStatus() != ACTIVE` 检查。`SynthesisService.generate()` 仅对返回的 `ActiveInstallationInfo` 生成数据，故删除后该设备不再被选中。机制成立。

---

## ⚠️ 新发现的问题

### P1-A 复活保存的 `@SQLRestriction` × `save()` 交互：仅补 createdAt 不够

修订版第 2 节识别了这个陷阱：`save()` 用 `findById` 取原 `createdAt`（`JpaDeviceRepositoryImpl.java:23-24`），全局过滤后查不到软删除实体，故建议"回退路径改用 native 查询取 createdAt"。

**核实发现方案不完整**。`save()` 对已存在 id 的实体走 JPA `merge`（`SimpleJpaRepository.save` → `isNew=false` → merge）。`@SQLRestriction` 是 Hibernate 6 的实体级过滤，附加到**所有从数据库加载该实体的 SQL**，包括 `merge` 内部为加载现有状态而执行的 SELECT。因此：

- 复活的设备（id 存在、`deleted_at` 非空）经 `toJpaEntity` 重建后调 `springDataRepo.save()` → merge 内部 SELECT 因 `deleted_at IS NULL` 过滤**查不到该行** → merge 视为"新对象" → flush 时要么 INSERT 主键冲突、要么抛 "entity not found"、要么乐观锁异常。
- 即使按修订版用 native 查询补上了 `createdAt`，`save()` 本身（merge 路径）仍无法更新仍处于软删除状态的行。

**建议**：复活的持久化改为 **native UPDATE 先行**——先执行一条 native `UPDATE devices SET deleted_at = NULL, status = 'INVENTORY' WHERE id = ?`（可同时复位 `last_telemetry_synced_at` 等），使该行脱离软删除状态，再用常规 `save()`（此时 `findById` 能查到、createdAt 回退逻辑恢复、merge 正常）。这样彻底绕开 `@SQLRestriction` × merge 的不可靠交互。仅补 `createdAt` 不够。

> 注：Hibernate 6 对 `@SQLRestriction` 与 `merge` 的具体异常形态建议实测确认，但风险方向明确，按"最坏情况"设计（native UPDATE 先行）最稳妥。

### P2-A `findOrCreateByEui` 复活分支缺 deviceCode 活跃判重（P2-1 未完全覆盖）

修订版第 4 节：`registerDevice()` 复活分支明确"更新 deviceCode 前先 `findByDeviceCode` 判重"（P2-1），但 `findOrCreateByEui()` 复活分支只说"用本次传入的 deviceCode 更新标签"，未提判重。

`findOrCreateByEui` 的 deviceCode 可由调用方显式传入（GPS 质检手工添加 / 批量导入表单列）。若传入值撞另一条**活跃**设备的 deviceCode，部分索引 `uq_devices_code_active WHERE deleted_at IS NULL` 阻止，直接抛数据库唯一约束异常（500），而非 `DUPLICATE_RESOURCE`。

**建议**：`findOrCreateByEui` 复活更新 deviceCode 前同样判重；或复活时**优先保留原 deviceCode 不覆盖**（仅当传入值非空且与原值不同时才更新并判重）。

### P2-B datagen 三重保障的因果表述可精确化

软删除场景下真正生效的是前两重（解绑 + 全局过滤）；`device.getStatus() != ACTIVE`（`DeviceQueryPortImpl.java:29`）这一重主要兜底"退役未删"场景——软删除后 `findById` 已返回 null，执行不到 status 检查。非错误，建议行为速查表述为"解绑（主）+ 全局过滤（兜底）+ status 检查（兜底退役场景）"，避免读者误以为三重在软删除路径上都会触发。

### P2-C 已删除设备的 GPS 质检历史在后台按 EUI 筛选搜不到

核实 `SpringDataGpsQualityTestRepository.findByFilters` / `countByFilters` 用 `LEFT JOIN DeviceJpaEntity`（`SpringDataGpsQualityTestRepository.java:43-58`）。加 `@SQLRestriction` 后右表 device 行被过滤：

- LEFT JOIN 保留左表 → 已删除设备的质检单**仍出现在列表**（设备信息列为空）。
- 但按 eui 筛选（`d.devEui LIKE`）时，已删除设备行 `d.devEui` 为 null 不匹配 → **筛不掉/搜不到**。

属 UX 边界，非数据丢失（底层 FK 数据完整）。与行为速查"历史检测记录保留"不冲突（保留指的是不物理删除），但建议在"历史数据保留"表述里注明此例外，或接受为已知限制。`existsByEuiAndTimeRange`（INNER JOIN）因复活时设备已脱离软删除状态，不受影响。

---

## 小遗漏

**datagen 适用范围**：行为速查"datagen 停止生成该设备数据"未注明 datagen 由 `@ConditionalOnProperty(datagen.enabled)` + `@Scheduled` 驱动（`SynthesisRunner.java:19-30`），仅在启用了 datagen 的环境生效，生产环境无此链路。建议行为速查/验证节注明 datagen 停止仅适用于 dev/test。

---

## 修改优先级

1. **P1-A（必须）**：复活持久化改 native UPDATE 先行，使 `save()` 脱离软删除状态后再执行；仅补 createdAt 不够。建议在实施任务清单第 4 条明确这一方案。
2. **P2-A**：`findOrCreateByEui` 复活补 deviceCode 判重（或保留原值）。
3. **P2-B / P2-C / datagen 适用范围**：文档表述精确化，不阻断实施。
