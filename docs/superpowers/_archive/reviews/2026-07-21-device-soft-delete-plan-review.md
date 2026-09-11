# 设备软删除实施计划评审

评审日期：2026-07-21
被评审文档：`docs/superpowers/plans/2026-07-21-device-soft-delete-plan.md`
对照 spec：`docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`（v3 终评通过）
评审方式：13 个 Task 逐项对照 spec + 核实 plan 引用的代码现状（行号、类是否存在、mock 配置、merge 路径）

## 总体结论

**通过（带 1 个 P0 修正），可进入实施。** Plan 与 spec 终稿对齐良好，13 个 Task 覆盖 spec 全部要求（包括容易遗漏的 Task 8 去重顺序、Task 9 预检提示）。代码现状引用（`ApiClient.farmDelete:94`、`AbstractJourneyTest`、`InstallationController.getCurrentUserId:99`、带 platform client mock 的 `DeviceApplicationServiceTest`）**逐条核实准确**。测试分层合理（领域单测 + Mockito + Testcontainers 集成测试，尤其复活 merge 路径用真实 PG 验证是亮点）。

主要问题集中在 Task 6/7 复活分支的**边界与顺序语义**。

| 级别 | 数量 | 含义 |
|---|---|---|
| P0 | 1 | 设计缺口，不补则复活逻辑有缺陷 |
| P1 | 2 | 影响正确性/可测性，实施前需明确 |
| P2 | 3 | 改进建议 |

---

## ✅ 核实准确的引用

- `ApiClient.farmDelete` 存在于 `lib/core/api/api_client.dart:94`（Task 12）；
- `_showUnbindDialog` 在 `devices_page.dart:271`、`HighfiDeviceTile(` 调用 :564、按钮排 `highfi_device_tile.dart:95-110`（Task 12）；
- `AbstractJourneyTest` 存在 `src/test/java/com/smartlivestock/integration/AbstractJourneyTest.java`（Task 11）；
- `InstallationController.getCurrentUserId` 在 `:99-105`（Task 10）；
- 存在两个 `DeviceApplicationServiceTest`：`application/`（旧，无 platform mock）与 `application/service/`（新，含 `@Mock AgenticPlatformDeviceClient`）。Plan 正确选用后者（Task 11），但需注意 deleteDevice 测试需补 mock 依赖（见 P1-B）；
- `SpringDataDeviceRepository.findActivePlatformDeviceIds:35`（Task 5 停同步）；
- `GpsQualityBatchImportService` 历史去重 `:146` / 设备解析 `:155`（Task 8 调换）。

---

## P0 阻断问题

### P0-1 Task 6/7 复活分支漏处理"命中活跃记录但 status 非 INVENTORY"的设备

**问题**：Task 6 复活后"走既有流程：`platformDeviceId` 非空直接复用返回；为空且 INVENTORY → 尝试平台注册"。Task 7 类似。但都只考虑了三种结果（软删除→复活 / 活跃→不变或报错 / 未命中→新建），**忽略了已存在的活跃记录 status 为 ACTIVE 或 DECOMMISSIONED 的情况**。

具体场景：设备 A（devEui=E，status=ACTIVE，已安装在某牲畜上）还在正常使用，用户通过 GPS 质检批量导入同一 EUI=E 的数据。此时：

- Task 6 现状描述"命中活跃记录 → 现有逻辑不变"——现有 `findOrCreateByEui` 命中 ACTIVE 且 platformDeviceId 非空时直接 return（:104-106），**不会**触发任何错误。质检单正常挂在已激活的设备上。这条本身 OK。
- 但 Task 7 的 `registerDevice` 复活分支，命中**活跃**记录时 plan 选择抛 `DUPLICATE_RESOURCE`（待确认事项 1）。这里有个隐患：如果该活跃记录是 **DECOMMISSIONED**（退役未删），plan 让它落入"命中活跃→抛错"，而用户语义上 DECOMMISSIONED 设备可能本就该被"重新激活复用"。spec 终稿对此未定义，plan 的抛错决策合理，但**应在 Task 7 明确：命中任何非软删除记录（INVENTORY/ACTIVE/DECOMMISSIONED）一律抛 `DUPLICATE_RESOURCE`**，避免实施者只判"软删除 vs 其他"时漏掉状态细分，或在 DECOMMISSIONED 上误用复活路径。

**更关键的缺口**：Task 6 命中活跃记录的复活路径里，"为空且 INVENTORY → 尝试注册"这一步——如果命中的活跃记录是 **DECOMMISSIONED**，现有 `findOrCreateByEui` 代码（:108 `if status == INVENTORY`）会跳过注册，直接返回一个 DECOMMISSIONED 设备，质检单挂上后设备其实不工作。这不是软删除引入的（是既有 bug），但 plan 没有指出，建议在 Task 6 注明"复活/复用语义对 DECOMMISSIONED 设备不完整，属既有问题，本次不扩展"，避免被误以为是新功能覆盖。

**建议**：
- Task 6/7 复活判定明确状态矩阵：软删除→复活；活跃(INVENTORY/ACTIVE)→现有逻辑/报错；活跃(DECOMMISSIONED)→不在本次复活范围，行为同现有逻辑（不复活、不报错地复用，或明确报错，二选一并与 spec 对齐）。
- 这一项需要回到 spec 确认 DECOMMISSIONED 边界，或直接在 plan 里定死"本次复活只处理软删除记录，任何 status 的非软删除记录走原逻辑"。

---

## P1 重要问题

### P1-A Task 4 `restoreById` 与领域 `restore()` 双写的语义/顺序

**问题**：Task 4 描述复活 = `restoreById`（native UPDATE 改 DB）+ Task 2 的 `restore()`（改领域模型内存对象）。Task 6/7 的复活步骤写成"restoreById native UPDATE → 表单值覆盖 → restore() → save()"。

这里 `restore()` 和 `restoreById` **都在复位 INVENTORY**，存在重复语义，且顺序有讲究：
- `restoreById`（native UPDATE）直接改 DB 行 `deleted_at=NULL, status=INVENTORY`；
- 随后领域对象的 `status` 已被 `restore()` 设为 INVENTORY，`deletedAt=null`；
- `save()` → `toJpaEntity` 重建 → merge。

顺序上 native UPDATE 在前是对的（让行脱离软删除，merge 的内部 SELECT 才能查到，这是复审 P1-A 的核心）。但 plan 没有说清：**`restoreById` 之后，领域对象的内存状态从哪来？** 复活流程通常是 `findAllByDevEuiAndTenantIdIncludeDeleted` 返回的 Device（此时 `deletedAt` 非空、status 可能任意），对其调 `restore()` 得到内存态，再 `restoreById` 改 DB，再 `save` 内存态。需要明确这个对象的生命周期，否则实施者可能对 DB 对象和内存对象搞混。

**建议**：Task 6/7 把复活步骤写成明确的对象流：
1. `Optional<Device> deleted = findAllByDevEuiAndTenantIdIncludeDeleted(...)` → 取得含 deletedAt 的领域对象；
2. deviceCode 判重（用 deleted.deviceCode 与表单值比较 + findByDeviceCode 活跃集判重）；
3. `deleted.restore()` → 内存对象复位（deletedAt=null, status=INVENTORY）；同时按表单值覆盖 deviceCode/serialNo/deviceType；
4. `restoreById(deleted.getId())` → DB 行复位（脱离软删除，为 merge 清障）；
5. `save(deleted)` → merge 持久化（此时 DB 行 deleted_at=NULL，merge 的 SELECT 能查到，createdAt 回退正常）。

注意步骤 3/4 顺序：领域 `restore()` 改内存、`restoreById` 改 DB，两者改的是不同层，顺序上 native UPDATE 先（步骤 4）还是领域 restore 先（步骤 3）不影响正确性（只要 save 前 DB 行已复位），但**领域 restore 必须在 save 之前**。plan 现写的顺序（UPDATE → 覆盖 → restore → save）成立，但对象来源没交代，建议补全。

### P1-B Task 11 deleteDevice 单测需补 mock 依赖

**问题**：plan 说在 `application/service/DeviceApplicationServiceTest.java` 追加 deleteDevice 测试。但该测试现有 `@Mock` 只有 `DeviceRepository` + `AgenticPlatformDeviceClient` + `AgenticPlatformLicenseClient`（核实确认），而 `deleteDevice` 依赖 `InstallationApplicationService`（用于自动解绑）。

- `DeviceApplicationService` 当前并未注入 `InstallationApplicationService`（Task 5 要新增构造参数）。单测要验证"有活跃绑定才调 remove"，必须 mock `InstallationApplicationService`（或它依赖的 `InstallationRepository`）。
- plan Task 11 列了"三步调用顺序（解绑仅在有活跃绑定时调用）"，但没提到需新增 mock 字段，实施者容易漏。

**建议**：Task 11 明确 deleteDevice 单测需 `@Mock InstallationApplicationService`（或 `InstallationRepository`），并 mock `getActiveInstallation` 返回 present/empty 两种情况。若为避免循环依赖（`InstallationApplicationService` 也注入 `DeviceRepository`），plan 应说明 `deleteDevice` 如何拿到 installation 查询能力——见 P2-A。

---

## P2 改进建议

### P2-A Task 5 deleteDevice 的解绑依赖注入方式

Task 5 `deleteDevice` 调 `InstallationApplicationService.remove(deviceId, operatorId)`，但 `DeviceApplicationService` 当前只注入 `DeviceRepository / platformDeviceClient / platformLicenseClient`。新增 `InstallationApplicationService` 依赖时注意**循环依赖**：`InstallationApplicationService` 已注入 `DeviceRepository`（`InstallationApplicationService.java:22`）。Service 之间互相依赖不是必然循环（只要 `DeviceApplicationService` 不被 `InstallationApplicationService` 依赖即可，当前后者只依赖 repo 不依赖前者），但建议 plan Task 5 注明"注入 `InstallationApplicationService`，确认无循环依赖"，并考虑是否更轻量地直接注入 `InstallationRepository` + 复用解绑逻辑（减少跨 Service 调用）。

### P2-B Task 1 迁移的 dev/test 两套库一致性核对时机

Task 1 写"部署前在 dev/test 两套库执行核对约束名"。实际流程是 `deploy.sh dev` / `test` 分别 rsync+compose，Flyway 在容器启动时跑迁移。建议把"核对约束名"作为**部署前的手动前置检查**显式列入 Task 13 步骤，否则迁移在 test 库失败（约束名漂移）会到部署时才暴露。

### P2-C Task 13 E2E 缺"解绑"断言的明确性

正向用例"删除有绑定设备 → installations.removed_at 已置"对，但建议补一条：删除**无绑定**设备时 `deleteDevice` 不抛错（plan Task 11 单测覆盖了，E2E 也应显式列一条，防止实施时把"无 active installation"误处理成错误）。

---

## 待确认事项回应

Plan 末尾「待确认事项 1」：`registerDevice` 的 devEui 命中**活跃**记录时抛 `DUPLICATE_RESOURCE`。

**回应**：决策合理（业务错误优于唯一索引 500）。但需对齐 spec——spec 第 4 节 `registerDevice` 只定义了"命中软删除→复活""未命中→新建"，确实未定义命中活跃。建议：
- 此决策应**回写进 spec**（哪怕一句话），保持 spec/plan 一致，避免后续以 spec 为准的人困惑；
- 参数传 devEui 时，复用的 message key `error.deviceCodeDuplicate` 语义上其实是"deviceCode 重复"，传 devEui 作参数文案会读起来别扭（"deviceCode 重复：EUIxxx"）。建议要么新增 `error.deviceEuiDuplicate` key（但 spec 说"不新增后端 key"），要么沿用 key 但确认参数语义可接受。**这是一个 spec（不新增 key）与 plan（传 devEui）的小冲突，需定夺**。

---

## 修改优先级

1. **P0-1**：Task 6/7 复活分支补全状态矩阵（软删除 / INVENTORY / ACTIVE / DECOMMISSIONED 各自行为），并回到 spec 对齐 DECOMMISSIONED 边界或在 plan 定死"只复活软删除"。
2. **P1-A**：Task 6/7 补全复活对象流（领域对象来源 + restore/restoreById/save 顺序）。
3. **P1-B**：Task 11 deleteDevice 单测明确需新增 `InstallationApplicationService` mock。
4. P2-A 注入方式、P2-B 核对时机、P2-C 无绑定用例、待确认事项回写 spec，作为实施细节纳入。

总体而言，这是一份高质量、引用扎实的 plan，主要待补的是复活分支的状态边界细节。
