# 设备软删除历史遗留治理方案终评（spec v3.2 / plan v2.2）

终评日期：2026-07-21
被评审文档：
- spec `docs/superpowers/specs/2026-07-21-device-soft-delete-design.md`（v3.2，新增 §8 历史遗留数据治理）
- plan `docs/superpowers/plans/2026-07-21-device-soft-delete-plan.md`（v2.2，Task 1 迁移×2、Task 6 注册门放宽）
背景：上一轮评估判定"DECOMMISSIONED+null 设备卡 DEVICE_PENDING"为可见可恢复的中间态、非 bug、可不修复；用户提出两层闭环治理（存量迁移 + 增量放宽门），本评审核实该方案。

## 终评结论

**通过，治理方案成立，可进入实施。**

两层闭环设计完整且自洽：存量迁移消除既有隐患、增量注册门放宽防止再现。spec v3.2 与 plan v2.2 完全对齐（§8 ↔ Task 1 第二支迁移 + Task 6 放宽门 + Task 11/13 验证）。经源码核实，`activateOnPlatform` 与状态机 `activate()` 独立，"只绑定不激活"方案技术可行；治理 SQL 经全迁移核查在种子库命中 0 行（纯防御/前瞻性迁移），无数据风险。

实施时需注意 1 个 P1（注册门放宽的代码结构改造，非 spec/plan 错误，是落地时的易错点）。

## 两层闭环核实

### 存量治理（Flyway 迁移）— 成立

```sql
UPDATE devices SET status = 'INVENTORY', updated_at = NOW()
WHERE status = 'DECOMMISSIONED' AND platform_device_id IS NULL AND deleted_at IS NULL;
```

- **命中行数核实**：扫描全部 Flyway 迁移，**无任何 `DECOMMISSIONED` 状态的设备数据**（仅 V3 check 约束定义、V20260715121000 移除 OFFLINE）。V10 seed 45 台设备均为 ACTIVE/OFFLINE，device 1/2 后被 V20260709130000 补了 platform_device_id，无任何迁移执行过 `status='DECOMMISSIONED'`。故该 SQL 在 dev/test 种子库**命中 0 行**——Task 13 验证"count(*) 为 0"必然成立。
- **性质**：纯防御/前瞻性迁移。真值在于：dev/test 环境运行时经 UI 退役过设备后、未来线上环境可能有此状态时，能自动收敛。
- **安全性**：`status` 重置不影响 FK 关联（gps_logs/遥测/质检单均按 device_id 关联），INVENTORY 语义对"从未真正接入平台"的设备更准确。无副作用。

### 增量闭环（注册门放宽）— 成立

spec §4 第 3 条 / plan Task 6：`findOrCreateByEui` 注册尝试条件由 `status == INVENTORY` 放宽为 `platformDeviceId == null`，`activate()` 仍仅 INVENTORY 执行。

- **技术可行性已核实**：`activateOnPlatform(Device)`（`DeviceApplicationService.java:208-235`）只做 EUI 反查/注册、设 `platformDeviceId`，**完全独立于状态机 `activate()`**（后者才做 INVENTORY→ACTIVE 转换）。故对 ACTIVE/DECOMMISSIONED 设备调 `activateOnPlatform` 绑定、不调 `activate()` 不抛 `STATE_CONFLICT`，方案成立。
- **闭环验证**：ACTIVE/DECOMMISSIONED + null 设备经 EUI 命中 → 尝试绑定 → 成功则 `platformDeviceId` 设值，`importFromExcel`（:172-174）`platformDeviceId != null` 置 `READY`，不再卡 `DEVICE_PENDING`。

## 不治理部分的合理性

`ACTIVE + platform_device_id IS NULL` 存量（V10 种子假设备）不重置——**合理**。

- 这些设备承担 datagen 仿真（`DeviceQueryPortImpl.findActiveInstallations` 选 `status==ACTIVE`）与安装演示，重置为 INVENTORY 会中断 datagen 和绑定展示；
- 其导入质检单本就有双修复路径：v3.2 注册门放宽（导入时自动绑定）+ `retryRegistration`（:251-298 手动补绑定）。即使重置也会破坏 datagen，不重置风险更低。

## P1 实施细节风险（非 spec/plan 错误，是落地易错点）

### P1-A 注册门放宽的代码结构改造，非"增量 if"微调

现有 `findOrCreateByEui`（:108-117）结构：
```java
if (device.getStatus() == DeviceStatus.INVENTORY) {
    try {
        activateOnPlatform(device);   // 绑定
        device.activate();            // 激活（INVENTORY→ACTIVE）
        device = deviceRepository.save(device);
    } catch (Exception ex) { ... }
}
```
`activateOnPlatform` 与 `activate()` 在**同一个 if 块**内。放宽门后，对 ACTIVE/DECOMMISSIONED 设备要调 `activateOnPlatform` 但**不能调 `activate()`**（会抛 `STATE_CONFLICT`）。

这意味着代码结构要从"if INVENTORY { 绑定+激活 }"拆成两段独立逻辑：
```java
// 绑定门：platformDeviceId 为空即尝试（任意 status）
if (device.getPlatformDeviceId() == null) {
    try { activateOnPlatform(device); } catch (Exception ex) { ... }
}
// 激活门：仅 INVENTORY（保留原状态机约束）
if (device.getStatus() == DeviceStatus.INVENTORY) {
    device.activate();
    device = deviceRepository.save(device);
}
```

spec/plan 描述（"放宽绑定门、activate() 仅 INVENTORY"）正确，但**文字描述正确 ≠ 实施者会照此拆分**。若实施者误以为是"把 `status == INVENTORY` 改成 `platformDeviceId == null`"的一处替换，会连带 `activate()` 也对非 INVENTORY 设备调用 → 抛 `STATE_CONFLICT` → 落 catch → 行为退回"不绑定不激活"，治理失效。

**建议**：plan Task 6 显式标注"这是代码结构拆分，非 if 条件替换"，并给出上述两段式伪代码。Task 11 单测已覆盖"命中 ACTIVE/DECOMMISSIONED+null → 调 activateOnPlatform、status 不变"，能兜住该风险，但 plan 文字提示可降低实施返工。

## P2 spec 严谨性

### P2-A §8 隐患的"唯一可达路径"描述与治理 SQL目标对象不完全自洽

spec §8 隐患描述："唯一可达路径 = V10 种子 ACTIVE 无绑定老设备 → `updateDevice` 补录 EUI → 退役"。

核实：V10 seed 中**仅 device 1、2** 有 dev_eui（经 V20260709130000 补录），其余 43 台 dev_eui 为 NULL。而隐患触发需 `findOrCreateByEui` 命中（按 devEui 查）——**dev_eui 为 NULL 的设备根本不会被命中**。故"V10 种子老设备补 EUI 后退役"的可达路径，实际仅对 device 1、2（已有 platform_device_id，退役后 platform_device_id 非空，不满足治理条件）成立，对其余 43 台不成立。

这使治理 SQL 的目标对象（`DECOMMISSIONED + platform_device_id IS NULL`）在真实种子数据中**目前为空集**，与隐患描述的"可达路径"不完全对应。非错误（治理是前瞻性防御，且 §8 也承认"正常业务流程不可达"），但描述可更精确：隐患的真正来源是"运行时经 UI 退役的、早期创建的无平台绑定设备"，而非特定于 V10 seed。

**建议**（可选）：§8 隐患描述弱化对"V10 种子"的具体绑定，改为"早期/运行时创建的无平台绑定设备经退役后构成该状态"，与治理 SQL 的前瞻性定位一致。不影响实施。

## 总结

spec v3.2 + plan v2.2 的历史遗留治理是**完整且自洽的两层闭环**：存量迁移（命中 0 行，纯防御）+ 增量注册门放宽（技术可行，`activateOnPlatform` 与 `activate()` 独立）。不治理部分（ACTIVE+null 假设备）有充分理由与双修复路径。上一轮评估的"非 bug、可恢复"结论仍成立，但本治理方案进一步消除了该中间态、提升了系统整洁度，属于有价值的收尾。

建议实施时落实 P1-A 的代码结构拆分提示；P2-A 描述精确化为可选。两项均不阻断实施。
