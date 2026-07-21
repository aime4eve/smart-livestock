# 设备删除功能设计（软删除 + 复活机制）

日期：2026-07-21
状态：已修订 v3.1，终评通过、可进入实施（2026-07-21。v1 根据初评 `2026-07-21-device-soft-delete-design-review.md` 修订；v2 根据复审 `2026-07-21-device-soft-delete-design-re-review.md` 采纳 P1-A/P2-A/P2-B/P2-C，并按需求澄清将"停止数据链路"按真/假设备分流：真设备停 blade 同步、假设备停 datagen 仿真；v3 根据终评 `2026-07-21-device-soft-delete-design-final-review.md` 落入两条实施提示：native UPDATE 的 `@Modifying` 清上下文、`restore()` 与 native UPDATE 状态双写一致性；v3.1 根据 plan 评审 `../reviews/2026-07-21-device-soft-delete-plan-review.md` 补充：registerDevice 的 devEui 命中活跃设备统一抛 DUPLICATE_RESOURCE，新增 `error.deviceEuiDuplicate` key；v3.2 补充历史遗留数据治理（第 8 节）：存量迁移重置 DECOMMISSIONED+null 设备为 INVENTORY，`findOrCreateByEui` 注册尝试条件放宽为 `platformDeviceId == null`，彻底解除"退役未注册设备卡 DEVICE_PENDING"隐患；v3.3 按治理终评 `../reviews/2026-07-21-device-soft-delete-legacy-governance-review.md` 精确化 §8 隐患可达路径描述（P2-A，治理为前瞻性防御）；v3.4 按 E2E 实测修正：复活 native UPDATE 同语句写最终 device_code，防旧 code 撞 `uq_devices_code_active`）

## 背景与目标

设备管理目前只有"退役"（decommission，状态机终态）没有"删除"。需要在 App 端设备管理中增加删除设备功能，并保证数据一致性：

- 至少 7 张表 FK 引用 `devices(id)`（`device_licenses`、`installations`、`gps_logs`、`device_telemetry_logs`、`alerts`、`gps_quality_tests`、RTK/动态测试表），均无级联，**物理删除不可行**；
- `devices` 表 V3 建表时已预留 `deleted_at` 列（注释 "soft delete via deleted_at"），`DeviceJpaEntity` 已映射，但领域模型与全部查询未启用；
- 软删除后必须解决重新添加同 code / 同 EUI 设备的问题（三条添加路径，见下）。

**目标**：

1. App 端设备管理支持删除设备（软删除），数据一致性有保障：
   - **真设备**（`platform_device_id` 非空，即通过 devEui 在 blade 平台成功获得 deviceId 的设备）→ 停止从 blade 平台同步该设备数据；
   - **假设备**（仿真设备，无 blade 平台绑定）→ 停止后台自动生成该设备的仿真数据（datagen）；
   - 绑定关系正确解除、历史数据保留；
2. 已删除设备可被重新添加：同 EUI 复活原记录（历史延续），同 deviceCode 允许新建（不阻挡）。

## 术语辨析：deviceCode / devEui / dev_eui / serialNo / 真设备

| 字段/术语 | 层 | 语义 | 唯一性 | 可变性 |
|---|---|---|---|---|
| `devEui`（Java/Dart）= `dev_eui`（DB 列） | 同一事物两种命名：camelCase 是代码字段名，snake_case 是数据库列名 | LoRaWAN DevEUI，64-bit 硬件标识，**物理设备身份** | `(dev_eui, tenant_id)` 唯一（`uq_devices_eui_tenant`） | 不可变（厂商烧录） |
| `deviceCode` / `device_code` | 业务编号、人读标签 | 用户可自定义（如 `GPS-001`），批量导入缺省为 `"GPS-" + eui` | 全表 UNIQUE（V3 列级约束，本次改为部分索引） | 可编辑 |
| `serialNo` / `serial_no` | 设备 SN | 用于 blade 平台 license 查询（`getLicenseStatusBySn`） | 无唯一约束 | 录入后基本不变 |
| **真设备** | 业务判定 | `platform_device_id` 非空：通过 devEui 在 blade 平台成功获得 deviceId（EUI 反查或注册成功），数据来自 blade 平台采集 | — | — |
| **假设备** | 业务判定 | 无 blade 平台绑定（`platform_device_id` 为空），数据由 datagen 仿真生成 | — | — |

**判定规则：同 devEui = 同一块硬件 → 复活；仅同 deviceCode ≠ 同一设备 → 允许新建。**

## 现状

### 删除相关

- `DeviceController`（`/api/v1/farms/{farmId}/devices`）无 DELETE 端点；最接近的语义是 `PUT /{deviceId}/decommission`（状态机 ACTIVE → DECOMMISSIONED）。
- `Device.decommission()` 仅允许 ACTIVE → DECOMMISSIONED，其他状态抛 `STATE_CONFLICT`（`Device.java:77-83`）——**删除流程不能复用该方法**（评审 P0-1）。
- 软删除先例：`JpaLivestockRepositoryImpl.deleteById()` / `JpaFarmRepositoryImpl.deleteById()` = 置 `deletedAt`；Livestock 唯一约束用部分索引 `uq_livestock_farm_code_active ... WHERE deleted_at IS NULL`（V2）。注意 Livestock 先例的查询过滤是逐个 `@Query` 手补，其派生方法（`findByLivestockCode`）与 `findById` 均未过滤——**本设计不继承该缺陷**，改用全局过滤（见第 2 节，评审 P1-2）。
- `LivestockApplicationService.deleteLivestock()` 删除前先解绑 active installation，设备删除镜像此模式。
- blade 平台侧：Feign client（`AgenticPlatformDeviceClient`）无注销/删除接口，**只做本地删除**。

### 三条添加路径（与软删除的冲突点）

| 路径 | 入口 | 判重逻辑 |
|---|---|---|
| 设备管理手工添加 | `DeviceController POST` → `DeviceApplicationService.registerDevice()` | 只按 `deviceCode` 判重（`findByDeviceCode`） |
| GPS 质量检测手工添加 | `GpsQualityAdminController`（155/203/298 行 3 处）→ `findOrCreateByEui()` | 按 `(devEui, tenantId)` 查找，有则复用、无则新建 |
| GPS 质量检测批量导入 | `GpsQualityBatchImportService.importFromExcel()` → 同一 `findOrCreateByEui()`；预检 `parseExcel()`/`precheckRow()` 只查不建 | 同上 |

devices 表现有三个唯一约束，**均不含 `deleted_at` 过滤**：

- `device_code UNIQUE`（V3 列级约束，全表，PG 默认约束名 `devices_device_code_key`）；
- `uq_devices_eui_tenant ON (dev_eui, tenant_id) WHERE dev_eui IS NOT NULL`（V20260719100000）；
- `idx_devices_platform_device_id ON (platform_device_id) WHERE platform_device_id IS NOT NULL`（V20260709120000）。

若只给查询加 `deletedAt IS NULL` 而不动约束，重新添加同 code / 同 EUI 设备会直接撞唯一索引报 500（批量导入中表现为整行 FAILED）。

### 两条数据链路（删除后按真/假设备分别停止）

1. **真设备 → blade 遥测同步链路**：`AgenticPlatformSyncDispatcher`（:38，定时调度）→ MQ → `AgenticPlatformSyncWorker` → `AgenticPlatformTelemetrySyncJob.syncDevice()`。调度入口 `findActivePlatformDeviceIds` 的 SQL 为 `WHERE d.status = 'ACTIVE' AND d.platformDeviceId IS NOT NULL`（`SpringDataDeviceRepository.java:35`）；`syncDevice()` 内部只做 `findById` + `platformDeviceId` 非空判断，**不检查 status**——因此"改状态停同步"的因果链不成立，**真正机制是给调度查询过滤 `deletedAt`**（评审 P0-2）。
2. **假设备 → datagen 仿真数据链路**：`SynthesisRunner`（每 10s tick，`SynthesisRunner.java:27`）→ `SynthesisService.java:38` → `DeviceQueryPortImpl.findActiveInstallations()`。取数逻辑：先取 `installationRepository.findAllActive()` 活跃绑定，再对每台设备 `findById`，`device == null || status != ACTIVE` 跳过（`DeviceQueryPortImpl.java:27`）。`EvaluationService.java:31` 走同一 port。停止机制：**解绑（主，设备不再出现在活跃绑定中）+ 全局过滤（兜底，`findById` 返回 null）+ port status 检查（兜底"退役未删"场景）**（复审 P2-B）。

## 设计

### 1. 删除端点与流程（三步，不动状态机）

`DeviceController` 新增：

```
DELETE /api/v1/farms/{farmId}/devices/{deviceId}
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
```

`DeviceApplicationService.deleteDevice(id, operatorId)` 单事务内三步：

1. **校验**：设备存在、未删除，且 `device.getTenantId().equals(TenantContext.getCurrentTenant())`；租户不匹配抛 `RESOURCE_NOT_FOUND`（不暴露存在性，评审 P1-1）。设备写操作普遍缺租户校验是既有问题，DELETE 破坏性最强必须带上，其余写端点的回填另行处理。
2. **自动解绑**：存在 active installation 则调 `InstallationApplicationService.remove(deviceId, operatorId)`（软解绑，`removed_at` 保留历史）。此步同时是 datagen 链路停止的主机制。
3. **软删除**：置 `deletedAt = now()`。**不改 status**（评审 P0-1/P0-2：`decommission()` 对 INVENTORY/DECOMMISSIONED 会抛 `STATE_CONFLICT`，且停同步不依赖状态字段）。

任意状态（INVENTORY / ACTIVE / DECOMMISSIONED）均允许删除。`deviceCode` / `serialNo` / `devEui` / `platformDeviceId` **原值保留不改写**（审计性 + 复活无需还原）。

删除后两条数据链路的停止效果：

- **真设备**：`findActivePlatformDeviceIds` 经全局过滤不再返回该设备 → blade 平台数据同步停止；
- **假设备**：解绑使其脱离 `findAllActive()`，全局过滤使 `findById` 返回 null → datagen 停止生成该设备仿真数据。

### 2. 软删除落地：全局过滤策略（`@SQLRestriction`）

Livestock 先例"逐个 `@Query` 手补 `deletedAt IS NULL`"对派生方法和 `findById` 无效，本设计改用 Hibernate 6 的实体级全局过滤：

- `DeviceJpaEntity` 加 `@org.hibernate.annotations.SQLRestriction("deleted_at IS NULL")`——JPQL、派生方法、`findById`、`findAllById` 全部自动覆盖，包括 `findActivePlatformDeviceIds`（blade 调度）、`findByDeviceTypeOrderById`（`findAllTrackers`，GPS 质检后台）、`findAllByIdIn`（评审遗漏项）等。
- **例外一（复活判定）**：`findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId)` 用 **native query** 编写以绕过全局过滤。
- **例外二（复活持久化，复审 P1-A）**：`save()` 对已存在 id 的实体走 JPA `merge`，merge 内部为加载现有状态而发的 SELECT 同样被 `@SQLRestriction` 过滤 → 查不到软删除行 → merge 按新对象处理（IDENTITY 策略下可能生成新 id 插入重复设备——软删除行已被部分索引排除、唯一约束拦不住——或抛异常）。因此**复活必须先执行 native `UPDATE devices SET deleted_at = NULL, status = 'INVENTORY', device_code = :deviceCode WHERE id = :id`**，使行脱离软删除状态，再走常规 `save()`（此时 merge 的 SELECT 正常、createdAt 回退逻辑也恢复正常）。该方案同时覆盖 v1 识别的 createdAt 丢失问题，无需单独补 createdAt。实施细节：① 该 UPDATE 以 `@Modifying(clearAutomatically = true, flushAutomatically = true)` 执行，避免同一事务内持久化上下文持有过期一级缓存实体，确保后续 `save()` 从库重新加载到 `deleted_at = NULL` 的行（终评提示 1）；② `device_code` 必须同语句写入**最终值**（调用方已对活跃集合判重）——软删除行的旧 code 可能已被另一活跃设备占用，仅清 `deleted_at` 会在 `uq_devices_code_active` 上撞唯一索引变 500（E2E 实测发现，v3.4 修正）。
- 删除流程自身的 `save()` 不受影响：merge 时 DB 行 `deleted_at` 仍为 NULL，能正常查到并更新。
- `Device` 领域模型加 `deletedAt` 字段 + `restore()` 方法（清 `deletedAt`、状态重置 `INVENTORY`）。`restore()` 与上述 native UPDATE 均复位 `INVENTORY`，两处语义必须保持一致，代码注释互引，防止将来改一处漏另一处（终评提示 2）。
- **`DeviceMapper` 必须补 `deletedAt` 双向映射**（评审 P1-3）：`toJpaEntity` 加 `jpa.setDeletedAt(device.getDeletedAt())`，`toDomain` 加 `device.setDeletedAt(jpa.getDeletedAt())`。`JpaDeviceRepositoryImpl.save()` 每次经 `toJpaEntity` 全新重建实体，缺此映射则任何一次 save（含遥测同步）都会把 `deletedAt` 写回 null，软删除静默丢失。

### 3. 唯一约束部分索引化（新 Flyway 迁移）

沿用 livestock V2 先例，唯一性只约束活跃设备：

```sql
-- device_code：列级约束改部分索引（约束名 devices_device_code_key，
-- 部署前核对 dev/test 两套库实际约束名一致）
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_device_code_key;
CREATE UNIQUE INDEX uq_devices_code_active ON devices(device_code) WHERE deleted_at IS NULL;

-- dev_eui + tenant：重建加 deleted_at 过滤
DROP INDEX IF EXISTS uq_devices_eui_tenant;
CREATE UNIQUE INDEX uq_devices_eui_tenant ON devices(dev_eui, tenant_id)
    WHERE dev_eui IS NOT NULL AND deleted_at IS NULL;

-- platform_device_id：重建加 deleted_at 过滤
DROP INDEX IF EXISTS idx_devices_platform_device_id;
CREATE UNIQUE INDEX idx_devices_platform_device_id ON devices(platform_device_id)
    WHERE platform_device_id IS NOT NULL AND deleted_at IS NULL;
```

迁移命名用时间戳版本号（`V20260721xxxxxx__device_soft_delete_unique_indexes.sql`），全部 `IF EXISTS` 防两套库约束名漂移（评审 P2-2）。

### 4. 重新添加：复活机制

**`findOrCreateByEui()`**（覆盖 GPS 质量检测手工添加 3 处 + 批量导入 + Open API 注册）：

1. 查找改用 `findAllByDevEuiAndTenantIdIncludeDeleted`；
2. 命中**软删除**记录 → 复活：
   - 先执行 native UPDATE 清 `deleted_at`、复位 `INVENTORY`（见第 2 节例外二），再走常规 `save()`；
   - deviceCode 处理：仅当传入值非空且与原值不同时才更新；更新前 `findByDeviceCode`（活跃集合）判重，撞活跃设备抛 `DUPLICATE_RESOURCE` 业务错误，避免部分索引违例变 500（复审 P2-A）；
   - 然后走既有流程：`platformDeviceId` 非空直接复用（blade 侧设备从未注销，绑定依然有效），为空则尝试注册；
3. 命中**活跃**记录 → `platformDeviceId` 非空直接复用；为空则尝试平台绑定（v3.2：注册尝试条件由 `status == INVENTORY` 放宽为 `platformDeviceId == null`，`activate()` 仍仅 INVENTORY 执行；ACTIVE/DECOMMISSIONED 命中只绑定不改状态）——关闭历史遗留 DECOMMISSIONED+null 设备导入卡 `DEVICE_PENDING` 的增量路径（见第 8 节）；
4. 未命中 → 新建（现有逻辑不变）。

效果：同一台物理设备删除后再次导入/添加，历史 `gps_logs`、遥测、`gps_quality_tests`（均按 `device_id` 关联）自然延续。

**`registerDevice()`**（设备管理手工添加）：

1. 若填了 devEui：先按 EUI 查（含软删除）：
   - 命中**软删除**记录 → 复活（native UPDATE 先行，同上），用表单值更新 deviceCode / deviceType，serialNo **仅非空时覆盖**（Controller 允许只传 devEui，避免 null 抹掉保留的 SN，与 findOrCreateByEui 的 deviceCode 保护一致）；**更新 deviceCode 前先 `findByDeviceCode`（活跃集合）判重，撞活跃设备抛 `DUPLICATE_RESOURCE`**（评审 P2-1）；再走既有平台注册流程；
   - 命中**活跃**记录（INVENTORY/ACTIVE/DECOMMISSIONED 一律，不做状态细分）→ 抛 `DUPLICATE_RESOURCE`（`error.deviceEuiDuplicate`，v3.1 新增），不复活、不新建（避免唯一索引 500）；
2. 未命中 → 现有 deviceCode 判重（全局过滤后只查活跃设备）→ 新建。deviceCode 撞软删除记录时**不复活、直接新建**（旧设备报废后新设备沿用编号是合法场景，部分索引放行）。

**批量导入去重顺序修正**（复审 P2-C 补充）：`importFromExcel` 当前先做历史去重（`existsByEuiAndTimeRange`，INNER JOIN devices，:146）再解析设备（`findOrCreateByEui`，:155，复活发生处）。设备仍处软删除状态时 INNER JOIN 被全局过滤 → 去重检查返回 false → 已删设备的历史检测单挡不住重复导入。**实施时把"解析/复活设备"步骤移到"历史去重"之前**，使去重检查时设备已复活、JOIN 正常。

**批量导入预检 `precheckRow()`**：命中软删除设备时提示改为"设备已删除，导入时将自动恢复"（WARN 级，不阻断导入）。预检为只读尽力而为（best-effort），与正式导入之间存在并发窗口，不保证结果一致（评审 P2-5）。

**已知限制（复审 P2-C）**：GPS 质检后台 `findByFilters`/`countByFilters` 为 `LEFT JOIN DeviceJpaEntity` + `d.devEui LIKE`（`SpringDataGpsQualityTestRepository.java:36-56`）。全局过滤附加到 JOIN 条件后：已删设备的历史质检单**仍出现在列表**（设备信息列为空），但**按 EUI 筛选搜不到**（JOIN 后 `devEui` 为 null）。底层数据完整（FK 无损），属 UX 边界，接受为已知限制。

### 5. blade 平台侧

不注销远端设备（client 无此接口）。删除后本地软删除即停止真设备同步（第 2 节全局过滤作用于调度查询）；复活时 EUI 反查 / 原 platformDeviceId 直接恢复绑定。在运维文档注明 blade 侧残留设备属预期。

### 6. 前端改动（Mobile/mobile_app）

- `DevicesRepository` 加 `delete(String id)` → `ApiClient.farmDelete('/devices/$id')`；
- `HighfiDeviceTile` 加 `onDelete` 删除按钮（danger 色，与现有激活/绑定/解绑按钮同排）；
- `devices_page.dart` 仿 `_showUnbindDialog` / 围栏 `_showDeleteDialog` 加确认弹窗（key `device-delete-confirm`），成功后 `ref.invalidate(devicesControllerProvider)` + `_loadInstallations()` + 失败 SnackBar；
- 复活对 UI 透明，无需标识；
- 风格沿用该模块现有 `AppLocalizations.of(context)!` 用法，不引入 `context.l10n`。

### 7. i18n

- 前端 arb（中英同步）新增 4 个 key：`deviceDeleteConfirmTitle` / `deviceDeleteConfirmContent` / `deviceDeleteSuccess` / `deviceDeleteFailed`；`commonDelete` / `commonCancel` 等现有 key 复用。
- 后端 messages：**新增 1 个 key** `error.deviceEuiDuplicate`（v3.1：registerDevice 填已存在活跃设备的 devEui 时的报错，`messages.properties` / `messages_zh.properties` / `messages_en.properties` 三份同步）；其余复用——`error.deviceNotFound`、`error.deviceCodeDuplicate`（`DUPLICATE_RESOURCE`）；复活对 UI 透明无独立提示；批量预检 WARN 消息沿用 `GpsQualityBatchImportService` 现有硬编码英文 RowResult 消息风格（该文件全部行级消息均为硬编码、不接入 MessageSource，保持文件内一致）。

### 8. 历史遗留数据治理（v3.2）

**隐患**：`DECOMMISSIONED + platform_device_id IS NULL` 的设备被 EUI 导入/添加命中时，`findOrCreateByEui` 跳过注册直接返回，检测单停留 `DEVICE_PENDING`。正常业务流程不可达（激活必经平台绑定 ⇒ `ACTIVE ⟹ platformDeviceId ≠ null`，退役仅允许 ACTIVE→DECOMMISSIONED）；可达路径为"早期/运行时创建的无平台绑定设备补录 EUI 后经退役"构成（终评 P2-A 精确化：不绑定特定种子批次——V10 种子设备仅 id 1/2 经 V20260709130000 补录 EUI 且已绑定平台，dev_eui 为空的设备不会被 EUI 查询命中，故当前种子库中该状态为空集，治理属前瞻性防御）。

**存量治理（Flyway 迁移）**：

```sql
-- DECOMMISSIONED 且从未完成平台注册的设备重置回 INVENTORY（从未真正接入平台，INVENTORY 语义更准确）；
-- 历史 gps_logs / 遥测 / 质检单均按 device_id 关联，不受 status 重置影响
UPDATE devices SET status = 'INVENTORY', updated_at = NOW()
WHERE status = 'DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL;
```

**增量闭环**：`findOrCreateByEui` 注册尝试条件放宽（见第 4 节第 3 条），任何未绑定平台的设备被 EUI 命中时都尝试绑定，该状态即使再现也不会卡单。

**不治理的部分**：`ACTIVE + platform_device_id IS NULL` 存量（V10 种子假设备，承担 datagen 仿真与安装演示）不重置——重置会中断 datagen 与绑定展示，且其导入质检单本就有"导入时自动绑定（v3.2）+ `retryRegistration`"双修复路径。

## 行为速查

| 场景 | 结果 |
|---|---|
| 删除无绑定设备（任意状态） | 软删除，历史 gps/遥测/检测记录保留 |
| 删除有 active 绑定的设备 | 事务内自动软解绑 → 软删除；牲畜侧不再显示该设备 |
| 删除**真设备**（platformDeviceId 非空） | blade 平台数据同步停止（调度查询全局过滤）；blade 侧设备残留属预期 |
| 删除**假设备**（无 platformDeviceId） | datagen 停止生成该设备仿真数据（解绑为主、全局过滤兜底、port status 检查兜底退役场景） |
| 设备管理添加，EUI 命中已删设备 | 复活原记录，表单值覆盖标签信息，platformDeviceId 复用 |
| 设备管理添加，EUI 命中活跃设备（任意 status，v3.1） | 返回 `DUPLICATE_RESOURCE` 业务错误（`error.deviceEuiDuplicate`，非 500），不复活不新建 |
| 历史遗留 DECOMMISSIONED 无平台绑定设备（v3.2） | 迁移重置为 `INVENTORY`；同 EUI 再导入/添加走正常注册流程，不再卡 `DEVICE_PENDING` |
| 设备管理添加，仅 deviceCode 命中已删设备 | 新建记录（部分索引放行） |
| GPS 质检手工/批量添加，EUI 命中已删设备 | 复活，历史检测数据延续，新检测单关联原 device_id |
| 复活后设备状态 | 回 `INVENTORY`：历史数据延续，但需手动重新激活（恢复 blade 同步）并重新安装到牲畜（恢复 datagen/定位）；blade 侧 platformDeviceId 绑定仍有效（评审 P1-4） |
| 复活时 deviceCode 撞另一条活跃设备 | 返回 `DUPLICATE_RESOURCE` 业务错误（非 500），`registerDevice` 与 `findOrCreateByEui` 两路一致 |
| 已删设备重复批量导入（同 EUI+时间+类型） | 复活先于历史去重执行，重复行被 SKIPPED，不产生重复检测单（复审 P2-C 补充） |
| 批量导入预检，EUI 命中已删设备 | WARN："设备已删除，导入时将自动恢复"（best-effort，不保证与导入时一致） |
| 已删设备的历史质检单 | 列表仍显示（设备信息列为空）；按 EUI 筛选搜不到（已知 UX 限制，数据完整） |

## 实施任务清单

1. Flyway 迁移 ×2：三个唯一约束部分索引化（`IF EXISTS`，核对两套库约束名）+ 历史遗留 DECOMMISSIONED+null 设备重置 `INVENTORY`（v3.2，第 8 节）；
2. `DeviceJpaEntity` 加 `@SQLRestriction("deleted_at IS NULL")`；`Device` 领域模型加 `deletedAt` + `restore()`；
3. `DeviceMapper` 补 `deletedAt` 双向映射；
4. 复活持久化：native `UPDATE devices SET deleted_at = NULL, status = 'INVENTORY' WHERE id = ?` 先行（`@Modifying(clearAutomatically = true, flushAutomatically = true)`），再走常规 `save()`（复审 P1-A + 终评提示 1，替代 v1 的 createdAt 兜底方案）；
5. `DeviceRepository` / `SpringDataDeviceRepository` 新增 `findAllByDevEuiAndTenantIdIncludeDeleted`（native query）；
6. `DeviceApplicationService.deleteDevice()`：租户断言 + 自动解绑 + 软删除；
7. `findOrCreateByEui()` 复活分支（含 deviceCode 判重/保留原值，复审 P2-A）+ 注册尝试条件放宽为 `platformDeviceId == null`（v3.2 增量闭环）；
8. `registerDevice()` 复活分支（含 deviceCode 活跃判重，评审 P2-1）；
9. `importFromExcel` 步骤顺序：设备解析/复活移到历史去重之前（复审 P2-C 补充）；
10. `precheckRow()` 软删除命中提示语；
11. `DeviceController` DELETE 端点（`@PreAuthorize OWNER/B2B_ADMIN`）；
12. 前端：repository `delete` + 删除按钮 + 确认弹窗 + arb 中英 key；
13. 测试：后端单测（删除三步、复活、租户拒绝、复活 merge 路径）+ 前端 analyze/gen-l10n。

## 验证

1. `./gradlew compileJava` + 后端相关单测（Device 状态机 / 复活逻辑 / 复活持久化路径）；
2. `flutter analyze` + `flutter gen-l10n` 无缺失 key；
3. 部署 dev 后端到端验证（curl + App）：
   - **正向**：删除有绑定设备 → installations 表 `removed_at` 已置、设备列表不显示、gps_logs 历史仍在；同 deviceCode 重新添加 → 成功（新纪录）；同 EUI 批量导入 → 复活原 device_id（不新建重复行），检测单关联正确；
   - **状态机（P0-1）**：`INVENTORY` / `DECOMMISSIONED` 状态设备可直接删除成功，无需先 activate；
   - **租户隔离（P1-1）**：用 A 租户 token 删 B 租户 deviceId 返回 404/403；
   - **全局过滤（P1-2）**：已删除设备 `GET /{deviceId}`、`PUT /{deviceId}/activate`、`GET /{deviceId}/health` 均返回 404；GPS 质检后台 `findAllTrackers` 不含已删除设备；
   - **复活持久化（复审 P1-A）**：复活后 DB 中仍为原行原 id（无新增重复设备），`created_at` 保持原值；
   - **复活语义（P1-3/P1-4）**：复活后 `status = INVENTORY`，历史 `gps_logs` / `gps_quality_tests` 按 `device_id` 关联可查；重新激活后 blade 遥测同步恢复，重新安装后 datagen 恢复；
   - **复活判重（P2-1/P2-A）**：两条添加路径复活时 deviceCode 撞活跃设备均返回业务错误（非 500）；
   - **真设备停同步**：删除真设备后 blade 同步日志不再出现其 platformDeviceId 的拉取；
   - **假设备停仿真**：删除假设备后 `gps_logs` 无该设备新增合成数据，`SynthesisService` 日志无该 deviceId；
   - **去重顺序（复审 P2-C）**：已删设备再次批量导入同 EUI+时间+类型 → 复活后去重生效，重复行 SKIPPED，不产生重复检测单。
   - **遗留治理（v3.2）**：迁移后 `SELECT count(*) FROM devices WHERE status='DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL` 为 0；构造 legacy 场景（ACTIVE+null 设备补 EUI 后退役）导入同 EUI → 自动尝试绑定平台，检测单不卡 `DEVICE_PENDING`。

## 不做的事（Out of Scope）

- blade 平台远端设备注销（client 无接口，仅文档注明）；
- 已删除设备的列表展示 / 回收站 UI；
- `DeviceHealthDialog` 内历史硬编码中文的 i18n 清理（历史遗留，另行处理）；
- Open API 侧新增删除端点（`OpenDeviceRegisterController` 的注册走 `findOrCreateByEui`，自动获得复活能力，无需改动）；
- 其余设备写端点（update/activate/decommission 等）的租户校验回填（既有问题，另行处理）；
- alerts 关联处理：经核实 `alerts.device_id` 为标量列、告警查询无 JOIN devices，软删除不影响告警展示（评审 P2-3 前提不成立，无需处理）；
- GPS 质检后台按 EUI 搜已删设备历史单的 UX 限制修复（复审 P2-C，接受为已知限制）。
