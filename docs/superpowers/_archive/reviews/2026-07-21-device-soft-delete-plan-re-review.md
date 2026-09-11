# 设备软删除实施计划复审（plan v2）

复审日期：2026-07-21
被评审文档：`docs/superpowers/plans/2026-07-21-device-soft-delete-plan.md`（v2）
前置评审：`docs/superpowers/reviews/2026-07-21-device-soft-delete-plan-review.md`
复审方式：逐条核对修订是否落地 + 核实 spec/plan 一致性 + 核实修订引入的新依赖（deviceEuiDuplicate key、循环依赖、解绑链路）

## 复审结论

**通过，可进入实施，无阻断问题。**

上一轮评审 P0-1 / P1-A / P1-B / P2-A / P2-B / P2-C 全部正确落地；待确认事项 1 的 `error.deviceEuiDuplicate` key 决策已回写 spec v3.1（§4:141、§7:165、行为速查:176 三处一致）；plan v2 与 spec v3.1 完全对齐。本次复审新核实的三处代码现状（messages 文件数、循环依赖、解绑过滤）全部成立，未发现新阻断问题。

## 上一轮意见落实核查

| 项 | v2 处置 | 核实 |
|---|---|---|
| P0-1 复活分支状态矩阵 | Task 6/7 补全"软删除→复活 / 活跃(任意status)→原逻辑或报错 / 未命中→新建"；DECOMMISSIONED 既有缺陷注明不扩展 | ✅ |
| P1-A 复活对象流五步 | Task 6 写明 deleted 来源 → deviceCode 判重 → restore() → restoreById → save()，并注明内存/DB 双写顺序不影响正确性、restore 必须在 save 前 | ✅ |
| P1-B deleteDevice 单测 mock | Task 11 明确新增 `@Mock InstallationApplicationService`，`getActiveInstallation` 返回 present/empty 两态 | ✅ |
| P2-A 循环依赖 | Task 5 注明注入 `InstallationApplicationService` 无循环依赖（后者只依赖 DeviceRepository/InstallationRepository） | ✅ |
| P2-B 约束名核对时机 | Task 1 前置核对 + Task 13 步骤 3 显式列为部署前手动检查 | ✅ |
| P2-C 无绑定删除用例 | Task 13 补"删除无 active 绑定设备不抛错" | ✅ |
| 待确认 1 deviceEuiDuplicate | 新增 key（三份 properties 同步），回写 spec v3.1 | ✅ |

## 新核实点（修订引入）

**1. `error.deviceEuiDuplicate` key 与实际 properties 文件**：spec v3.1 §7 与 plan Task 7 均称"`messages.properties` / `messages_zh.properties` / `messages_en.properties` 三份同步"。核实 `src/main/resources/` 确实存在这三份文件，数量一致。plan 的"三份同步"表述准确，符合 i18n 规范。

**2. Task 5 循环依赖声明**：plan 称"`InstallationApplicationService` 仅依赖 `DeviceRepository` / `InstallationRepository`，不反向依赖 `DeviceApplicationService`"。核实 `InstallationApplicationService.java:22-24` 构造参数确为两者，无反向依赖，循环依赖风险消除，声明成立。

**3. deleteDevice 第 2 步解绑链路**：plan 写"`getActiveInstallation(id).isPresent()` 时调 `remove`，`remove` 对无活跃绑定会抛异常，必须先判存在"。核实：
- `InstallationApplicationService.getActiveInstallation` → `InstallationRepository.findActiveByDeviceId` → `findByDeviceIdAndRemovedAtIsNull`（派生方法，过滤 `removed_at`，`JpaInstallationRepositoryImpl.java:30-33`），正确返回活跃绑定；
- `InstallationApplicationService.remove`（`InstallationApplicationService.java:54-58`，前序已核实）在 `findActiveByDeviceId` 为空时抛 `RESOURCE_NOT_FOUND`。plan 先判 `isPresent()` 再调 `remove` 的写法正确，避免了该异常。

## 小提示（P2，不阻断实施）

### P2-1 Task 5 第 2 步可简化

plan 先 `getActiveInstallation(id).isPresent()` 判存在，再调 `remove(id, operatorId)`，而 `remove` 内部又会再查一次 `findActiveByDeviceId`。即同一事务内 `findActiveByDeviceId` 被执行两次。功能正确，仅一次冗余查询。若在意可在实施时封装一个"幂等解绑"方法（存在则解绑、不存在则 no-op），但非必须，保持现状也可。

### P2-2 Task 11 mock 的 operatorId 传递

deleteDevice 单测用 `InOrder` 验证 `remove(id, operatorId)` 调用。`operatorId` 来自 Controller 的 `getCurrentUserId()`（Task 10），单测是 Service 层、直接传值，无需 mock SecurityContext。建议 Task 11 注明 operatorId 在单测中作为固定参数传入（如 `1L`），避免实施者误以为要在 Service 单测里搭 SecurityContextHolder。属测试可读性细节。

## 建议

plan v2 已成熟，spec/plan 一致性、代码现状引用、边界处理、测试分层均到位。**建议直接进入实施阶段**。两个 P2 小提示在编码时顺手处理即可。
