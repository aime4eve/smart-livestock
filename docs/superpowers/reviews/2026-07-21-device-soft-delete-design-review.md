# 设备软删除设计评审（2026-07-21-device-soft-delete-design.md）

评审日期：2026-07-21
被评审文档：`docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`
评审范围：设计正确性 + 与现有代码契合度
评审方式：通读 spec + 交叉验证源码（Device 领域模型/状态机、Repository、同步链路、Flyway 迁移、Livestock 先例、Mapper、前端）

## 总体结论

设计方向正确：**软删除 + 部分唯一索引 + EUI 复活**，术语辨析（deviceCode/devEui/serialNo）清晰，三条添加路径与冲突点梳理完整，blade 平台"只做本地删除"的处理务实。但在与现有代码衔接处存在 **2 个 P0 阻断问题**（会导致删除功能直接不可用或语义错误）和 **4 个 P1 重要问题**（安全/正确性），建议修改后再进入实施阶段。

| 级别 | 数量 | 含义 |
|---|---|---|
| P0 | 2 | 阻断，不修则功能不可用 |
| P1 | 4 | 影响安全/正确性，实施前必须明确 |
| P2 | 5 | 改进建议 |

---

## P0 阻断问题

### P0-1 删除流程的状态机冲突：INVENTORY/DECOMMISSIONED 设备无法删除

**设计自相矛盾**：第 1 节声称"任意状态（INVENTORY / ACTIVE / DECOMMISSIONED）均允许删除"，同时第 3 步要求"状态置 `DECOMMISSIONED`"。但现有状态机不允许这样做。

**证据**（`smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/model/Device.java`）：

```java
public void decommission() {
    if (status != DeviceStatus.ACTIVE) {
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "Device must be in ACTIVE status to decommission, current: " + status);
    }
    this.status = DeviceStatus.DECOMMISSIONED;
}
```

- 删除一台 `INVENTORY` 设备（最常见的新设备误录）→ 第 3 步 `decommission()` 直接抛 `STATE_CONFLICT`，整个事务回滚，删除失败。
- 删除已是 `DECOMMISSIONED` 的设备 → 同样抛异常。
- 只有恰好 `ACTIVE` 的设备能走通删除流程，与"任意状态可删"矛盾。

**建议**：去掉"状态置 DECOMMISSIONED"这一步（见 P0-2，该步本身冗余），软删除（`deletedAt = now()`）+ 查询补 `deletedAt IS NULL` 已足以让设备从所有视图和同步队列中消失，无需改动状态机。若一定要保留终态语义，应新增 `Device.softDelete()` 方法用 `setStatus()` 绕过状态机，而不是复用 `decommission()`。

---

### P0-2 "停同步"步骤冗余，且对同步链路的描述有误

**设计描述**：第 3 步"状态置 `DECOMMISSIONED`，`AgenticPlatformTelemetrySyncJob`（按 ACTIVE + platformDeviceId 筛选）不再向 blade 拉遥测"。

**实际链路**（`AgenticPlatformSyncDispatcher.java:38` → MQ → `AgenticPlatformSyncWorker.java:43` → `AgenticPlatformTelemetrySyncJob.syncDevice`）：

- 调度入口 `findActivePlatformDeviceIds` 的 SQL 本就是 `WHERE d.status = 'ACTIVE' AND d.platformDeviceId IS NOT NULL`（`SpringDataDeviceRepository.java:33`）。
- 设计第 2 节**已经**要求给 `findActivePlatformDeviceIds` 补 `deletedAt IS NULL`。补上后，已删除设备的 id 根本不会进入同步队列。
- `syncDevice()` 内部是 `findById(deviceId)` + 取 `platformDeviceId` 拉数据，**并不检查 `status`**——所以"改状态=停同步"这个因果链不成立。

**结论**：`deletedAt IS NULL` 过滤才是停同步的真正机制；"状态置 DECOMMISSIONED 停同步"是冗余且理由错误的描述。去掉该步即可同时消除 P0-1 的状态机冲突，并简化设计。

**建议**：删除流程收敛为三步——① 校验存在且未删除（含租户校验，见 P1-1）；② 自动软解绑 active installation；③ 置 `deletedAt = now()`。状态字段保持原值不动。

---

## P1 重要问题

### P1-1 删除端点缺少租户校验（越权风险）

**证据**（`DeviceController.java`）：所有端点都接收 `@PathVariable Long farmId`，但 `farmId` 在方法体内**完全未使用**，`listDevices` 注释明确写着 *"currently by tenant, farm filtering TBD"*。

- `devices` 表没有 `farm_id` 列，只有 `tenant_id`，"农场级隔离"对设备根本不成立。
- `deleteDevice(id, operatorId)` 只按 id 查找（`findById`），不校验设备是否属于当前租户。
- `DeviceRepository.findById`（`JpaDeviceRepositoryImpl.java:29`）不带 `tenant_id` 过滤——理论上知道 `deviceId` 即可跨租户访问/删除。

**这是既有问题**（现有 get/update/activate/decommission 都有），但 DELETE 是破坏性操作，越权后果显著更严重。

**建议**：`deleteDevice` 内删除前断言 `device.getTenantId().equals(TenantContext.getCurrentTenant())`，不匹配抛 `RESOURCE_NOT_FOUND`（不暴露存在性）。此校验也建议回填到其它写操作端点，但至少 DELETE 必须有。

---

### P1-2 `findById` 与派生方法的 `deletedAt` 过滤遗漏

**设计描述**（第 2 节）："`SpringDataDeviceRepository` **全部 JPQL 查询**补 `deletedAt IS NULL`，包括 `findActivePlatformDeviceIds` 与 `findByDeviceCode`。"

**问题**：`DeviceRepository` 多数查询是 Spring Data **派生方法**，不是 `@Query` JPQL，"JPQL 查询补条件"的措辞会让实施者漏掉它们：

| 方法 | 类型 | 设计是否点名 |
|---|---|---|
| `findById`（JpaRepository 默认） | 默认方法 | ❌ 完全未提 |
| `findByDeviceCode` | 派生方法 | ✅ 点名 |
| `findAllByDevEuiAndTenantId` | 派生方法 | ❌ |
| `findByTenantId` | 派生方法 | ❌ |
| `countByTenantIdAndStatus` | 派生方法 | ❌ |
| `findByDeviceTypeOrderById`（`findAllTrackers` 用） | 派生方法 | ❌ |
| `findActivePlatformDeviceIds` / `findByTenantIdPaged` 等 | `@Query` JPQL | ✅ |

**核对 Livestock 先例**：`SpringDataLivestockRepository` 同样没有 `@Where`/`@SQLRestriction`，靠逐个 `@Query` 补 `deletedAt IS NULL`；其 `findByLivestockCode`（派生方法，line 22）和 `findById`（line 36-37）**也都没过滤**——这是先例本身就带的小缺陷（靠部分唯一索引兜底判重，影响有限）。设计说"完全沿用这套模式"，会**继承同样的缺陷**，但对破坏性的 DELETE 来说代价更高。

**漏掉的后果**：
- 已删除设备仍可通过 `GET /{id}`、`activate`、`update`、`decommission`、`health`、`registerWithPlatform` 访问/操作（它们都走 `findById`）。
- `findAllTrackers()`（GPS 质检管理后台设备列表）会显示已删除设备。
- `deleteDevice` 第 1 步"校验未删除"若依赖 `findById`，必须显式判 `deletedAt != null`，否则可被重复删除。

**建议**：在 `DeviceJpaEntity` 上加 `@org.hibernate.annotations.SQLRestriction("deleted_at IS NULL")`（Hibernate 6 推荐注解，Spring Boot 3 可用）做全局过滤——这比先例更严谨，是**改进而非偏离**；仅为复活专用的 `findAllByDevEuiAndTenantIdIncludeDeleted` 写一个绕过全局过滤的 native query。若坚持沿用逐个补条件，则必须把 `findById` 和上述所有派生方法一并纳入，并在任务清单逐条列明。

---

### P1-3 `DeviceMapper` 必须新增 `deletedAt` 双向映射

**设计描述**（第 2 节）："`DeviceMapper` 双向映射。"

**现状**（`DeviceMapper.java`）：`toJpaEntity` / `toDomain` **都不处理 `deletedAt`**（JpaEntity 有 `deletedAt` 字段，但 Mapper 没映射）。

**后果**：软删除置 `deletedAt = now()` 后，若 Mapper 不映射，下一次 `save` 会把 `deletedAt` 写回 `null`——软删除静默丢失，复活逻辑也无从判断"命中软删除记录"。设计提到了这点，但实施极易遗漏。

**建议**：在任务清单显式列出"`toJpaEntity` 加 `jpa.setDeletedAt(device.getDeletedAt())`、`toDomain` 加 `device.setDeletedAt(jpa.getDeletedAt())`"。

---

### P1-4 复活后状态语义未在"行为速查"中明确

**设计描述**：`restore()` 清 `deletedAt`、状态重置 `INVENTORY`；第 4 节又说"复活对 UI 透明，无需标识"。

**问题**：若设备删除前是 `ACTIVE`（已安装在牲畜上），删除时第 2 步已自动软解绑 installation。复活后回到 `INVENTORY`——设备虽然"复活"、历史数据延续，但**不再工作**（`findActivePlatformDeviceIds` 只选 `ACTIVE`，INVENTORY 设备不参与同步；且 installation 已解绑）。

用户预期很可能是"复活 = 恢复原状"，实际是"复活 = 待激活/待安装"，"行为速查"表里没有任何一行说明这一点，易导致 QA/用户困惑。

**建议**：在"行为速查"增加一行"同 EUI 复活 → 历史数据延续，但设备状态回 `INVENTORY`，需手动重新激活并重新安装到牲畜"。同时说明：blade 侧 `platformDeviceId` 虽保留（绑定仍有效），但本地需重走激活流程才会恢复遥测同步。

---

## P2 改进建议

### P2-1 复活时 `deviceCode` 唯一性预检缺失

`registerDevice` 复活分支"用表单值更新 deviceCode / serialNo / deviceType"。若用户填入的新 `deviceCode` 恰好撞另一条**活跃**设备的 code，部分索引 `uq_devices_code_active WHERE deleted_at IS NULL` 会阻止，直接抛数据库唯一约束异常（500），而非业务错误。

**建议**：复活更新 `deviceCode` 前先 `findByDeviceCode`（活跃集合）判重，命中则抛 `DUPLICATE_RESOURCE`。

### P2-2 迁移脚本的防御性与不可逆性

第 3 节迁移 `DROP CONSTRAINT devices_device_code_key` / `DROP INDEX uq_devices_eui_tenant` / `DROP INDEX idx_devices_platform_device_id` 不可逆。建议：

- 全部加 `IF EXISTS`，避免约束/索引名在 dev/test 两套库不一致（历史迁移若改过名）时迁移失败。
- 核对两套库（test 18080 / dev 19080）实际约束名与设计假设一致（V3 列级 `UNIQUE` 默认命名 `devices_device_code_key` 通常正确，但需确认）。

### P2-3 `alerts` 关联已删除设备的显示

`alerts.device_id REFERENCES devices(id)`（V20260709120000）。设备软删除后，其产生的告警仍在。若告警列表查询 JOIN `devices` 且全局过滤 `deletedAt IS NULL`，已删设备的告警会丢失设备名/信息。需确认告警列表查询是否 JOIN `devices`，必要时改 `LEFT JOIN` 并容忍空设备信息。

### P2-4 i18n key 未给出具体名称

设计第 7 节新增了后端"复活提示语""批量预检新提示"的 key，但未给具体名称。建议明确，例如 `iot.deviceRestored`（复活成功）、`iot.deviceDeletedWillRestore`（批量预检 WARN）。前端 key（`deviceDeleteConfirmTitle/Content/Success/Failed`）与现有 `commonDelete/commonCancel` 风格一致，OK。

### P2-5 批量预检与实际复活的并发

`precheckRow()` 是只读预检，`importFromExcel()` 才真正复活。并发场景下预检时设备未删、导入时已删（或反之），预检结果与实际不一致。属正常并发，建议文档注明预检为"尽力而为（best-effort）"，不保证与最终导入结果一致。

---

## 做得好的地方

- **术语辨析表**（deviceCode / devEui / serialNo）清晰，"同 EUI = 复活、同 code = 新建"的判定规则合理且与硬件语义吻合。
- **三条添加路径**的判重逻辑与冲突点梳理完整，复活机制覆盖全部入口（含 `OpenDeviceRegisterController` 自动获益）。
- **部分唯一索引化**方案正确沿用 `uq_livestock_farm_code_active ... WHERE deleted_at IS NULL`（V2）先例。
- **blade 平台不注销**的处理务实（client 无接口），并注明运维侧残留属预期。
- **Out of Scope** 边界清晰（不做回收站 UI、不动历史遗留 i18n）。

---

## 验证章节建议补充

现有验证清单偏"正向路径"，建议补齐 P0/P1 相关的反向/边界用例：

- **P0-1**：`INVENTORY` / `DECOMMISSIONED` 设备可直接删除成功（修复后无需先 activate）。
- **P1-1**：跨租户删除（用 A 租户 token 删 B 租户 deviceId）应返回 `404`/`403`。
- **P1-2**：已删除设备通过 `GET /{deviceId}`、`PUT /{deviceId}/activate`、`GET /{deviceId}/health` 应返回 `404`；`findAllTrackers`（GPS 质检后台）不包含已删除设备。
- **P1-3/P1-4**：复活后 `status = INVENTORY`，历史 `gps_logs` / `gps_quality_tests` 仍按 `device_id` 关联可查；重新激活后遥测同步恢复。
- **P2-1**：复活时 deviceCode 撞活跃设备应返回业务错误（非 500）。

---

## 修改优先级（供实施前修订 spec）

1. **P0-1 + P0-2 合并处理**：删除流程去掉"状态置 DECOMMISSIONED"，收敛为"校验 → 解绑 → 软删除"三步（同时明确不动状态机）。
2. **P1-1**：`deleteDevice` 增加租户断言。
3. **P1-2**：明确 deletedAt 过滤策略（推荐 `@SQLRestriction` 全局过滤，并列出复活专用绕过查询）。
4. **P1-3**：任务清单显式列出 Mapper 双向映射 deletedAt。
5. **P1-4**：行为速查补充复活后状态语义。
6. P2 项作为实施细节纳入。
