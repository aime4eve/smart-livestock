# 设备删除功能（软删除 + 复活机制）— 实施计划

> 日期：2026-07-21
> Spec：`docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`（v3.1）
> 修订：v2（2026-07-21）按评审 `docs/superpowers/reviews/2026-07-21-device-soft-delete-plan-review.md` 修订——P0-1 复活分支状态矩阵补全、P1-A 复活对象流明确、P1-B deleteDevice 单测 mock 依赖、P2-A/B/C 实施细节；EUI 命中活跃设备的处理决策已回写 spec v3.1。v2.1 补两条 P2 提示（不阻断）：Task 5 解绑双查询冗余注明、Task 11 operatorId 直传免 mock SecurityContext。v2.2 历史遗留数据治理（spec v3.2）：Task 1 增第二支迁移、Task 6 注册门放宽闭环、Task 11/13 补治理验证。v2.3 按治理终评落实 P1-A：Task 6 显式标注"结构拆分非条件替换"并给两段式伪代码（含"绑定成功即落库"修正——评审伪代码仅在 INVENTORY 门内 save，ACTIVE/DECOMMISSIONED 绑定会丢失）。v2.4 按 E2E 实测修正：restoreById 同语句写最终 device_code（定夺记录 4）+ serialNo 仅非空覆盖（Task 7）
> 顺序：Flyway 迁移 → 实体/领域 → Mapper → Repository → Service（删除 + 复活）→ Controller → 后端测试 → 前端 → 编译/静态检查 → 部署 dev → E2E 验证
> 关键代码现状（已核对）：
> - `DeviceJpaEntity` 已映射 `deleted_at`（`DeviceJpaEntity.java:81-82`），但 `Device` 领域模型与 `DeviceMapper` 均未携带该字段
> - `DeviceApplicationService` 现有 `registerDevice()`(:48)、`findOrCreateByEui()`(:83)、`updateDevice()`(:313)、`decommissionDevice()`(:371)
> - `SpringDataDeviceRepository.java:35` 的 `findActivePlatformDeviceIds` 依赖全局过滤停同步
> - `GpsQualityBatchImportService.importFromExcel()` 历史去重 :146 在设备解析 :155 之前，需调换
> - 前端 `devices_page.dart` 有 `_showUnbindDialog`(:271) 可仿写；`HighfiDeviceTile` 按钮排 :95-110；`ApiClient.farmDelete` 已存在（`api_client.dart:94`）

## Task 1 — Flyway 迁移 ×2：唯一约束部分索引化 + 历史遗留治理

**文件**：
- 新建 `smart-livestock-server/src/main/resources/db/migration/V20260721100000__device_soft_delete_unique_indexes.sql`
- 新建 `smart-livestock-server/src/main/resources/db/migration/V20260721101000__legacy_decommissioned_no_platform_reset.sql`

**改动**：迁移一按 spec 第 3 节原样落 SQL：

```sql
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_device_code_key;
CREATE UNIQUE INDEX uq_devices_code_active ON devices(device_code) WHERE deleted_at IS NULL;

DROP INDEX IF EXISTS uq_devices_eui_tenant;
CREATE UNIQUE INDEX uq_devices_eui_tenant ON devices(dev_eui, tenant_id)
    WHERE dev_eui IS NOT NULL AND deleted_at IS NULL;

DROP INDEX IF EXISTS idx_devices_platform_device_id;
CREATE UNIQUE INDEX idx_devices_platform_device_id ON devices(platform_device_id)
    WHERE platform_device_id IS NOT NULL AND deleted_at IS NULL;
```

迁移二按 spec 第 8 节落历史遗留治理（v3.2）：

```sql
-- DECOMMISSIONED 且从未完成平台注册的设备重置回 INVENTORY（从未真正接入平台，INVENTORY 语义更准确）；
-- 历史 gps_logs / 遥测 / 质检单均按 device_id 关联，不受 status 重置影响
UPDATE devices SET status = 'INVENTORY', updated_at = NOW()
WHERE status = 'DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL;
```

**前置核对**（评审 P2-B：作为部署前手动前置检查，显式纳入 Task 13 步骤）：部署前在 dev / test 两套库执行，确认列级约束名一致（PG 默认 `devices_device_code_key`，若漂移则先调整迁移 DROP 语句再部署）：

```sql
SELECT conname FROM pg_constraint WHERE conrelid = 'devices'::regclass AND contype = 'u';
```

**验证**：迁移提交 git（经验教训 #12：迁移必须提交，防 checksum 分歧）；部署 dev 后 `\d devices` 确认三个部分索引存在、列级约束已消失；`SELECT count(*) FROM devices WHERE status='DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL` 为 0。

## Task 2 — 实体全局过滤 + 领域模型 deletedAt/restore()

**文件**：
- `iot/infrastructure/persistence/entity/DeviceJpaEntity.java`
- `iot/domain/model/Device.java`

**改动**：
- `DeviceJpaEntity` 类级加 `@org.hibernate.annotations.SQLRestriction("deleted_at IS NULL")`（Hibernate 6，Spring Boot 3.3 满足）。效果：JPQL、派生方法、`findById`、`findAllById` 全部自动过滤软删除行，覆盖 `findActivePlatformDeviceIds`、`findByDeviceTypeOrderById`、`findAllByIdIn` 等全部查询。
- `Device` 加 `private Instant deletedAt` + getter/setter；加 `restore()`：清 `deletedAt`、`status` 重置 `INVENTORY`。
- `restore()` 的 javadoc 注明"与 `SpringDataDeviceRepository.restoreById` 的 native UPDATE 语义一致（均复位 INVENTORY），改动需同步"（终评提示 2，两处注释互引）。
- 不动 `decommission()` / `activate()` 状态机；删除不改 status。

**验证**：`./gradlew compileJava` 通过。

## Task 3 — DeviceMapper 补 deletedAt 双向映射

**文件**：`iot/infrastructure/persistence/mapper/DeviceMapper.java`

**改动**：
- `toJpaEntity` 加 `jpa.setDeletedAt(device.getDeletedAt())`；
- `toDomain` 加 `device.setDeletedAt(jpa.getDeletedAt())`。

缺此映射则 `JpaDeviceRepositoryImpl.save()` 每次全新重建实体会把 `deletedAt` 写回 null，软删除静默丢失（评审 P1-3）。

**验证**：编译通过；单测覆盖（见 Task 11）。

## Task 4 — Repository 层：含删除查询 + 复活 native UPDATE

**文件**：
- `iot/domain/repository/DeviceRepository.java`
- `iot/infrastructure/persistence/SpringDataDeviceRepository.java`
- `iot/infrastructure/persistence/JpaDeviceRepositoryImpl.java`

**改动**：
- `SpringDataDeviceRepository` 新增两个方法：
  - `findAllByDevEuiAndTenantIdIncludeDeleted`：**native query**（`SELECT * FROM devices WHERE dev_eui = :devEui AND tenant_id = :tenantId`），native 绕过 `@SQLRestriction`（复活判定例外一）；
  - `restoreById`：**native UPDATE** `UPDATE devices SET deleted_at = NULL, status = 'INVENTORY', device_code = :deviceCode WHERE id = :id`，标注 `@Modifying(clearAutomatically = true, flushAutomatically = true)`——同事务内清持久化上下文一级缓存，保证后续 `save()`（merge 内 SELECT）从库重新加载（复审 P1-A + 终评提示 1）。**`device_code` 同语句写最终值**（调用方先对活跃集合判重）：软删除行旧 code 可能已被活跃设备占用，仅清 `deleted_at` 会撞 `uq_devices_code_active` 变 500（E2E 实测发现，见定夺记录 4）。
- `DeviceRepository` 接口加对应两个方法；`JpaDeviceRepositoryImpl` 实现委托 springDataRepo（IncludeDeleted 结果照常走 `DeviceMapper.toDomain`）。

**验证**：编译通过。

## Task 5 — DeviceApplicationService.deleteDevice()

**文件**：`iot/application/DeviceApplicationService.java`

**改动**：
- 注入 `InstallationApplicationService`（构造器新增 final 字段，Lombok `@RequiredArgsConstructor` 自动处理）。**无循环依赖**（评审 P2-A）：`InstallationApplicationService` 仅依赖 `DeviceRepository` / `InstallationRepository`（`InstallationApplicationService.java:22-24`），不反向依赖 `DeviceApplicationService`。
- 新增 `@Transactional public void deleteDevice(Long id, Long operatorId)`，单事务三步：
  1. `findById` 不存在 → `RESOURCE_NOT_FOUND`（`error.deviceNotFound`）；`!device.getTenantId().equals(TenantContext.getCurrentTenant())` → 同样抛 `RESOURCE_NOT_FOUND`（不暴露存在性，评审 P1-1）；
  2. `installationApplicationService.getActiveInstallation(id).isPresent()` 时调 `installationApplicationService.remove(id, operatorId)`（注意：`remove` 对无活跃绑定会抛异常，必须先判存在）；此步是 datagen 链路停止的主机制。**已知冗余**（评审 P2-1，不阻断）：`isPresent()` 与 `remove()` 内部的 `findActiveByDeviceId` 在同事务执行两次，功能无误；如需消除可后续在 `InstallationApplicationService` 封装幂等解绑（存在则解、不存在则 no-op），本次不做；
  3. `device.setDeletedAt(Instant.now())` + `deviceRepository.save(device)`。**不改 status**，`deviceCode`/`serialNo`/`devEui`/`platformDeviceId` 原值保留。

**验证**：编译通过；单测覆盖三步与租户拒绝（Task 11）。

## Task 6 — findOrCreateByEui() 复活分支

**文件**：`iot/application/DeviceApplicationService.java`（:83 起）

**改动**：
- :95 查找改调 `findAllByDevEuiAndTenantIdIncludeDeleted`；
- 命中后按**状态矩阵**分流（评审 P0-1，本计划定死：复活只处理软删除记录，任何 status 的非软删除记录走原逻辑）：
  - **软删除**（`deletedAt != null`）→ 复活，严格按以下**对象流**（评审 P1-A）：
    1. `deleted` = `findAllByDevEuiAndTenantIdIncludeDeleted` 返回的领域对象（此时 `deletedAt` 非空、status 任意）；
    2. deviceCode 判重：传入值非空且 ≠ `deleted.getDeviceCode()` → `findByDeviceCode(传入值)`（全局过滤后只查活跃集合）判重，撞活跃设备抛 `DUPLICATE_RESOURCE`（`error.deviceCodeDuplicate`，复审 P2-A）；传入为空或与原值相同 → 保留原值不动；
    3. `deleted.restore()`（**内存对象**复位：`deletedAt=null`、`status=INVENTORY`）+ 判重通过时 `deleted.setDeviceCode(传入值)`；
    4. `deviceRepository.restoreById(deleted.getId())`（**DB 行**复位：native UPDATE 使行脱离软删除状态，为后续 merge 的内部 SELECT 清障——必须在 `save()` 之前执行；步骤 3/4 一个改内存一个改 DB，相互顺序不影响正确性）；
    5. `deviceRepository.save(deleted)`（merge：DB 行已 `deleted_at=NULL`，SELECT 正常加载，`JpaDeviceRepositoryImpl.save()` 的 createdAt 回退逻辑恢复）；
    6. 走既有流程：`platformDeviceId` 非空直接复用返回；为空（复活后 status 恰为 INVENTORY）→ 落入现有 :108-117 尝试平台注册。
  - **活跃**（`deletedAt == null`，任意 status：INVENTORY/ACTIVE/DECOMMISSIONED）→ 不复活、不报错；`platformDeviceId` 非空直接复用，为空则尝试平台绑定（v3.2：:108 注册尝试条件由 `status == INVENTORY` 放宽为 `platformDeviceId == null`，`activate()` 仍仅 INVENTORY 执行；ACTIVE/DECOMMISSIONED 命中只绑定不改状态，绑定失败落 catch 走原返回）；
  - 未命中 → 新建（现有逻辑不变）。
- **落地结构警告**（终评 P1-A）：注册门放宽是**代码结构拆分**，不是把 :108 的 `status == INVENTORY` 一处替换成 `platformDeviceId == null`——现有 :108-117 把 `activateOnPlatform` 与 `activate()` 放在同一 if 块，一处替换会连带对非 INVENTORY 设备调 `activate()` 抛 `STATE_CONFLICT`、落 catch 后治理失效。必须拆成绑定/激活两个独立条件，且**绑定成功即落库**（否则 ACTIVE/DECOMMISSIONED 设备的 platformDeviceId 只留在内存，DB 仍 null，下次导入重复绑定、blade 同步调度也读不到）：

  ```java
  // 绑定门：platformDeviceId 为空即尝试（任意 status）
  if (device.getPlatformDeviceId() == null) {
      try {
          activateOnPlatform(device);              // 只绑定，与状态机无关
          if (device.getStatus() == DeviceStatus.INVENTORY) {
              device.activate();                   // 激活门：仅 INVENTORY
          }
          device = deviceRepository.save(device);  // 绑定/激活结果落库（任意 status）
      } catch (Exception ex) {
          log.warn("Platform registration retry failed for device {} EUI {}: {}",
                  device.getId(), eui, ex.getMessage());
      }
  }
  ```
- **遗留边界已治理**（v3.2，评审 P0-1 关闭）：DECOMMISSIONED+null 存量由 Task 1 第二支迁移重置为 INVENTORY；增量经注册门放宽闭环——即使再现（legacy ACTIVE+null 设备补 EUI 后退役），导入时也会自动尝试绑定，检测单不再卡 `DEVICE_PENDING`。

影响面：GPS 质检手工添加 3 处（`GpsQualityAdminController`:155/:203/:298）、批量导入、`OpenDeviceRegisterController` 注册全部自动获得复活能力，无需改动调用方。

**验证**：编译通过；单测覆盖复活分支、对象流调用顺序与 deviceCode 撞单（Task 11）。

## Task 7 — registerDevice() 复活分支

**文件**：`iot/application/DeviceApplicationService.java`（:48 起）

**改动**：
- 在现有 deviceCode 判重（:49）**之前**插入 EUI 分支：`command.devEui()` 非空 → `findAllByDevEuiAndTenantIdIncludeDeleted` 查找，按**状态矩阵**分流（评审 P0-1 + 待确认事项定夺，已回写 spec v3.1）：
  - 命中**软删除**记录 → 复活（对象流同 Task 6 五步）：先 `findByDeviceCode(command.deviceCode())` 活跃判重（撞活跃设备抛 `DUPLICATE_RESOURCE`，评审 P2-1）→ `restore()` + 表单值覆盖 `deviceCode`/`deviceType`，`serialNo` **仅非空时覆盖**（Controller 允许只传 devEui，避免 null 抹掉保留的 SN）→ `restoreById` → `save()` → 走既有 `activateOnPlatform` + `activate()` 注册流程（复用 :63-69）；
  - 命中**非软删除**记录（INVENTORY/ACTIVE/DECOMMISSIONED **一律**，不做状态细分）→ 抛 `DUPLICATE_RESOURCE`（**`error.deviceEuiDuplicate`**，参数 devEui），不复活、不新建；
  - 未命中 → 落入现有 deviceCode 判重 → 新建。deviceCode 撞软删除记录时不复活、直接新建（部分索引放行）。
- 未填 devEui → 现有逻辑不变。
- **message key 决策**（评审批复"spec 不新增 key 与 plan 传 devEui 冲突"的定夺）：**新增 `error.deviceEuiDuplicate`**，`messages.properties` / `messages_zh.properties` / `messages_en.properties` 三份同步（文案"设备 EUI 已存在： {0}" / "Device EUI already exists: {0}"）。理由：EUI 命中活跃设备是 spec 未定义的新场景，复用 `error.deviceCodeDuplicate` 传 EUI 文案误导（"设备编号已存在： A84041…"）；已回写 spec v3.1 §7。

**验证**：编译通过；单测覆盖（Task 11）。

## Task 8 — importFromExcel 步骤顺序修正

**文件**：`iot/application/GpsQualityBatchImportService.java`

**改动**：将"Step 3: Resolve device"（:154-155 `findOrCreateByEui`）移到"Step 2: Historical dedup"（:145-152 `existsByEuiAndTimeRange`）**之前**，步骤号注释同步更新。理由（复审 P2-C）：历史去重 SQL 为 INNER JOIN devices，设备仍处软删除时 JOIN 被全局过滤 → 去重失效；复活先执行则 JOIN 正常。安全性：重复行必然已有检测单 → 设备必然已存在（复活而非新建），不会产生"行被 SKIPPED 却新建了设备"的副作用。

**验证**：编译通过；E2E 验证去重顺序场景（Task 13）。

## Task 9 — precheckRow() 软删除命中提示

**文件**：`iot/application/GpsQualityBatchImportService.java`（:406 起）

**改动**：
- :406 查找改调 `findAllByDevEuiAndTenantIdIncludeDeleted`（不改则软删除设备落入"Device not found"误导性 WARN）；
- 命中且 `deletedAt != null` → 返回 WARN，消息沿用文件内硬编码英文风格：`"Device was deleted; it will be restored on import"`（不阻断导入；best-effort，不保证与正式导入一致，评审 P2-5）；
- 命中活跃设备逻辑不变。

**验证**：编译通过。

## Task 10 — DeviceController DELETE 端点

**文件**：`iot/interfaces/DeviceController.java`

**改动**：
- 新增：

```java
@DeleteMapping("/{deviceId}")
@PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
public ResponseEntity<ApiResponse<Void>> deleteDevice(
        @PathVariable Long farmId, @PathVariable Long deviceId) {
    deviceApplicationService.deleteDevice(deviceId, getCurrentUserId());
    return ResponseEntity.ok(ApiResponse.ok(null));
}
```

- `getCurrentUserId()` 仿 `InstallationController.java:99-105`（SecurityContextHolder principal 强转 Long，未认证抛 `AUTH_INVALID_TOKEN`），作为 private 方法加在 DeviceController 内。

**验证**：编译通过；E2E curl 验证（Task 13）。

## Task 11 — 后端测试

**文件**：
- `src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java`（追加）
- `src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java`（追加，此版本已含 platform client mock，适合注册/复活路径）
- 新建 `src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java`（继承 `AbstractJourneyTest`，Testcontainers + 真实 PG，覆盖 `@SQLRestriction`/merge 等单测无法验证的行为）

**改动**：
- 领域单测：`restore()` 清 deletedAt + 复位 INVENTORY；
- Service 单测（Mockito）：
  - **mock 依赖**（评审 P1-B）：测试类新增 `@Mock InstallationApplicationService`（`deleteDevice` 经 Task 5 新增该依赖，不加则 `@InjectMocks` 注入 null）；
  - `deleteDevice`：mock `getActiveInstallation(id)` 分别返回 `Optional.of(...)` / `Optional.empty()` 两态，`InOrder` 验证三步调用顺序、`remove(id, operatorId)` **仅在有活跃绑定时调用一次**、deletedAt 置位且 status 不变、租户不匹配抛 `RESOURCE_NOT_FOUND`。注意（评审 P2-2）：`operatorId` 是 `deleteDevice(id, operatorId)` 的入参，单测直接传固定值即可，**无需 mock SecurityContext / SecurityContextHolder**（那是 Controller 层 `getCurrentUserId()` 的事）；
  - `findOrCreateByEui` 复活：`InOrder` 验证 `restoreById` 先于 `save` 调用（评审 P1-A 对象流）、deviceCode 撞活跃设备抛 `DUPLICATE_RESOURCE`、传入空 code 保留原值、命中活跃 DECOMMISSIONED 记录不复活不报错（评审 P0-1 状态矩阵）；**注册门放宽**（v3.2）：命中 ACTIVE/DECOMMISSIONED 且 `platformDeviceId` 为空 → 调 `activateOnPlatform` 尝试绑定、status 不变、结果 `save` 落库；
  - `registerDevice` 复活：同上判重 + 字段覆盖；EUI 命中活跃记录（INVENTORY/ACTIVE/DECOMMISSIONED 各一例）抛 `DUPLICATE_RESOURCE`（`error.deviceEuiDuplicate`）；
- 集成测试（复活 merge 路径，复审 P1-A）：owner 登录 → POST 建设备（带 EUI）→ DELETE → `GET /{id}` 返回 404（全局过滤生效）→ 同 EUI 重新 POST → 断言**返回原 id**（无新增重复行）、`status=INVENTORY`。真实 Hibernate + PG 环境直接验证"native UPDATE 先行 + merge 正常加载"。

**验证**：`./gradlew test --tests "*Device*"` 及新集成测试通过。

## Task 12 — 前端：repository + 删除按钮 + 确认弹窗 + arb

**文件**：
- `Mobile/mobile_app/lib/features/devices/domain/devices_repository.dart`
- `Mobile/mobile_app/lib/features/devices/data/devices_api_repository.dart`
- `Mobile/mobile_app/lib/features/highfi/widgets/highfi_device_tile.dart`
- `Mobile/mobile_app/lib/features/pages/devices_page.dart`
- `Mobile/mobile_app/lib/l10n/app_zh.arb` / `app_en.arb`

**改动**：
- `DevicesRepository` 加 `Future<void> delete(String id)`；`DevicesApiRepository` 实现 `ApiClient.instance.farmDelete('/devices/$id')`；
- `HighfiDeviceTile` 加 `final VoidCallback? onDelete` 参数 + danger 色删除按钮（与现有激活/安装/解绑按钮同排，:95-110 区域，仿其条件渲染模式）；
- `devices_page.dart` 仿 `_showUnbindDialog`(:271-310) 新增 `_showDeleteDialog`：确认弹窗 key `device-delete-confirm`，标题/内容用新 arb key，按钮复用 `commonDelete`/`commonCancel`；确认后调 `repository.delete` → 成功 SnackBar（`deviceDeleteSuccess`）+ `_loadInstallations()` + `ref.invalidate(devicesControllerProvider)`，失败 SnackBar（`deviceDeleteFailed(e)`）；`HighfiDeviceTile(` 调用处（:198-206 与 :564 附近）无条件传 `onDelete`（任意状态可删）；
- arb 中英同步新增 4 key：`deviceDeleteConfirmTitle` / `deviceDeleteConfirmContent` / `deviceDeleteSuccess` / `deviceDeleteFailed`；
- 沿用模块现有 `AppLocalizations.of(context)!` 用法，不引入 `context.l10n`。

**验证**：`flutter gen-l10n` 无缺失 key；`flutter analyze` 通过。

## Task 13 — 编译 + 部署 dev + E2E 验证

**步骤**：
1. `./gradlew compileJava` + `./gradlew test`（后端全量）；
2. `flutter gen-l10n` + `flutter analyze`；
3. **部署前手动前置检查**（评审 P2-B）：dev / test 两套库分别执行 Task 1 的约束名核对 SQL（`SELECT conname FROM pg_constraint WHERE conrelid = 'devices'::regclass AND contype = 'u';`），确认 `devices_device_code_key` 存在；若库内约束名漂移，先调整迁移 DROP 语句再部署，避免迁移到部署时才暴露失败；
4. `./scripts/deploy.sh dev` 部署；
5. curl E2E（对齐 spec「验证」第 3 条清单）：
   - **正向**：删除有绑定设备 → `installations.removed_at` 已置、设备列表不出现、`gps_logs` 历史仍在；同 deviceCode 重新 POST → 成功（新 id）；同 EUI 批量导入 → 复活原 device_id，检测单关联正确；
   - **无绑定删除**（评审 P2-C）：删除无 active 绑定的设备 → 不抛错、返回 200、设备列表消失（防止实施时把"无 active installation"误处理成错误）；
   - **状态机（P0-1）**：`INVENTORY` / `DECOMMISSIONED` 设备直接删除成功；
   - **租户隔离（P1-1）**：A 租户 token 删 B 租户 deviceId → 404；
   - **全局过滤（P1-2）**：已删设备 `GET /{id}`、`PUT /{id}/activate`、`GET /{id}/health` 均 404；GPS 质检后台 `findAllTrackers` 不含已删设备；
   - **复活持久化（P1-A）**：复活后 DB 仍原行原 id，`created_at` 保持原值；
   - **复活语义（P1-4）**：复活后 `status=INVENTORY`；重新激活后 blade 同步恢复，重新安装后 datagen 恢复；
   - **复活判重（P2-1/P2-A）**：两条路径复活时 deviceCode 撞活跃设备均返回业务错误（非 500）；
   - **EUI 撞活跃（v3.1）**：registerDevice 填已存在活跃设备的 devEui → 返回 `DUPLICATE_RESOURCE`（`error.deviceEuiDuplicate`，非 500）；
   - **真设备停同步**：删除后 blade 同步日志不再出现其 platformDeviceId；
   - **假设备停仿真**：删除后 `gps_logs` 无该设备新增合成数据；
   - **去重顺序（P2-C）**：已删设备再次批量导入同 EUI+时间+类型 → 重复行 SKIPPED，不产生重复检测单；
   - **遗留治理（v3.2）**：`SELECT count(*) FROM devices WHERE status='DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL` 结果为 0；构造 legacy 场景（ACTIVE+null 设备补 EUI 后退役）导入同 EUI → 设备自动尝试绑定平台、检测单不卡 `DEVICE_PENDING`。

**验证**：上述逐项通过。

## 不做的事（沿用 spec）

- blade 远端注销、回收站 UI、Open API 删除端点、其余写端点租户校验回填、alerts 关联处理、GPS 质检后台按 EUI 搜已删设备历史单的 UX 限制修复；
- `ACTIVE + platform_device_id IS NULL` 存量设备不重置（V10 种子假设备承担 datagen/安装演示，且 v3.2 后导入时自动绑定 + `retryRegistration` 双路径可修复）。

## 评审定夺记录

1. **registerDevice 的 devEui 命中活跃设备**（INVENTORY/ACTIVE/DECOMMISSIONED 一律）→ 抛 `DUPLICATE_RESOURCE`，**新增 `error.deviceEuiDuplicate` key**（三份 properties 同步）。评审批复：复用 `error.deviceCodeDuplicate` 传 EUI 文案误导，新增一个 key 更准确；已回写 spec v3.1（§4 registerDevice、§7 i18n、行为速查表）。
2. **复活范围定死**（评审 P0-1）：本次复活只处理软删除记录；任何 status 的非软删除记录在 `findOrCreateByEui` 走原逻辑、在 `registerDevice` 报错，均不做状态细分的特殊处理。
3. **历史遗留治理**（v3.2，解除评审 P0-1 隐患）：两层——存量 Flyway 迁移重置 `DECOMMISSIONED + platform_device_id IS NULL` 为 `INVENTORY`（Task 1 第二支迁移）；增量 `findOrCreateByEui` 注册尝试条件放宽为 `platformDeviceId == null`，`activate()` 仍仅 INVENTORY（Task 6）。`ACTIVE + null` 存量不重置（datagen/演示影响面 + 双修复路径）。
4. **复活撞码修正**（v3.4，E2E 实测发现）：`restoreById` 的 native UPDATE 必须同语句写入**最终 device_code**（`deleted_at = NULL, status = 'INVENTORY', device_code = :deviceCode`）。场景：软删除行旧 code 被另一活跃设备占用时，仅清 `deleted_at` 会立即撞 `uq_devices_code_active` 唯一索引（23505 → 500），`save()` 来不及改 code。两条复活路径均先对最终 code 做活跃判重，索引安全。
