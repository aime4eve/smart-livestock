# 设备平台注册流程优化 — 复审意见

复审对象：`docs/superpowers/specs/2026-07-15-device-platform-registration-optimization.md`（用户修改后版本）

---

## 总体评价

用户修改后的 spec 在初版基础上做了三项重要改进：**区分 deviceCode / serialNo / devEui 三个独立字段**、**去掉 OFFLINE 状态统一用 runtimeStatus 表达在线/离线**、**明确 blade onlineStatus 的权威来源**。整体方向正确，但存在以下问题。

---

## P0 — 必须修复

### 1. Section 八 "不涉及的文件" 与 Section 5.2a 自相矛盾

**位置**：spec 第 555 行

```
- `DeviceStatus.java` — 枚举不变
```

Section 5.2a 明确删除 OFFLINE 枚举值，此处却说"枚举不变"，**明显矛盾**。应改为：

```
- `DeviceStatus.java` — 删除 OFFLINE，见 section 5.2a
```

同时该段落重复了 `messages_*.properties`（第 549 和 551 行），应合并。

---

### 2. `activateDevice()` 缺少 ACTIVE 状态前置检查

**位置**：spec Section 5.1 `activateDevice()` 代码

```java
// 无 platformDeviceId → 先注册到 blade 平台
if (device.getPlatformDeviceId() == null) {
    activateOnPlatform(device);
}
// 从 INVENTORY 转为 ACTIVE
device.activate();  // ← 如果已是 ACTIVE，这里会抛 STATE_CONFLICT
```

新 `activate()` 方法只允许 `INVENTORY → ACTIVE`。如果前端误调用，或者设备已在 ACTIVE 状态（有 platformDeviceId 且已激活），`device.activate()` 会抛 `STATE_CONFLICT`。

**建议**：方法开头加状态检查：

```java
// 已激活则直接返回
if (device.getStatus() == DeviceStatus.ACTIVE) {
    return DeviceDto.from(device);
}
// 非 INVENTORY 不可激活
if (device.getStatus() != DeviceStatus.INVENTORY) {
    throw new ApiException(ErrorCode.STATE_CONFLICT, "error.deviceActivateWrongStatus");
}
```

同理，DECOMMISSIONED 的设备和已 ACTIVE 的设备都不应走到 `activate()`。

---

### 3. `registerWithPlatform()` 仍引用已删除的 OFFLINE

**位置**：spec Section 5.1 `registerWithPlatform()` 代码

```java
if (device.getStatus() == DeviceStatus.INVENTORY || device.getStatus() == DeviceStatus.OFFLINE) {
    device.activate();
}
```

`DeviceStatus.OFFLINE` 已在 Section 5.2a 中删除，此引用编译不过。应改为：

```java
if (device.getStatus() == DeviceStatus.INVENTORY) {
    device.activate();
}
```

---

## P1 — 建议修复

### 4. 验证项 6 已过时

**位置**：spec Section 十 验证方式第 6 条

```
6. OFFLINE 设备恢复：已有 platformDeviceId 的 OFFLINE 设备 → activate → 跳过平台注册 → 本地 activate → ACTIVE
```

Flyway 迁移 `V20260715121000` 已将全部 OFFLINE 设备 UPDATE 为 ACTIVE，迁移完成后数据库中不存在 OFFLINE 状态的设备。此验证项不再适用，应删除或改为：

```
6. 已注册设备重复激活：已有 platformDeviceId 且 status=ACTIVE 的设备 → activate → 直接返回（幂等）
```

---

### 5. 影响范围清单遗漏了多个文件的 OFFLINE 相关变更

**位置**：spec Section 八

以下文件也需要修改，但影响范围清单未列出：

| 遗漏文件 | 变更 |
|----------|------|
| `DeviceMapper.java` | `toJpaEntity()` 和 `toDomain()` 新增 `serialNo` / `runtimeStatus` 字段映射（详见 finding #6） |
| `DeviceTest.java` | 删除 `markOffline` 测试用例；更新 `activate` 约束测试（不再允许 OFFLINE→ACTIVE）；更新 `decommission` 约束测试（不再允许 OFFLINE→DECOMMISSIONED） |
| `DeviceApplicationServiceTest.java` | 删除 `markOffline` 相关测试；更新 mock 行为适配新增的 `activateOnPlatform()` 平台调用 |
| `JpaDeviceRepositoryImpl.java` | 新增 `serialNo` 字段在查询/更新中的处理（如有手动 SQL） |

特别关注 `DeviceMapper.java` — 当前 `toJpaEntity()` / `toDomain()` 均未映射 `runtimeStatus` 字段（域对象有此字段但 mapper 未传递），这次改动应一并修复。

---

### 6. DeviceMapper 缺少 serialNo 和 runtimeStatus 映射

**当前代码**：`DeviceMapper.java` 的 `toJpaEntity()` 和 `toDomain()` 中均无 `serialNo` 和 `runtimeStatus` 的映射。

**spec 要求**：新增 `serialNo` 字段，`runtimeStatus` 由 blade 同步。spec 提到 `DeviceJpaEntity` 需加 `serial_no` 列映射，但未提 `DeviceMapper` 同步更新。

**建议**：Section 八影响范围补充 `DeviceMapper.java`。

---

### 7. Flyway CHECK 约束名可能不一致

**位置**：spec Section 6.2

```sql
ALTER TABLE devices DROP CONSTRAINT IF EXISTS chk_devices_status;
ALTER TABLE devices ADD CONSTRAINT chk_devices_status
    CHECK (status IN ('INVENTORY', 'ACTIVE', 'DECOMMISSIONED'));
```

`chk_devices_status` 是人工命名的约束名。如果现有数据库的 CHECK 约束是由 Hibernate/JPA 自动生成的（名称格式如 `devices_status_check`），或者根本没有命名约束，`DROP CONSTRAINT IF EXISTS chk_devices_status` 会静默跳过，然后 `ADD CONSTRAINT` 会创建一个新的约束，导致旧约束和新约束同时存在。

**建议**：
- 在迁移中显式查询并删除所有相关约束：

```sql
DO $$
DECLARE
    con_name text;
BEGIN
    FOR con_name IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'devices'::regclass AND contype = 'c'
    LOOP
        EXECUTE 'ALTER TABLE devices DROP CONSTRAINT IF EXISTS ' || con_name;
    END LOOP;
END $$;
ALTER TABLE devices ADD CONSTRAINT chk_devices_status
    CHECK (status IN ('INVENTORY', 'ACTIVE', 'DECOMMISSIONED'));
```

或者部署前先 `\d devices` 确认实际约束名。

---

### 8. `activateOnPlatform()` 方式一成功后 runtimeStatus 未初始化

**位置**：spec Section 5.1 `activateOnPlatform()` 代码

EUI 反查命中时同步了 `runtimeStatus`（从 `record.getOnlineStatus()`），但走方式一（`doPlatformRegistration`）成功后，`registerDevice` 响应 **不包含 `onlineStatus`**（只有 `deviceId`/`deviceIdentifier`/`deviceTypeId`/`status`/`createTime`），此时 `runtimeStatus` 保持旧值（可能是 null）。

**建议**：`doPlatformRegistration()` 成功后，将 `runtimeStatus` 初始化为默认值 `"offline"`（刚注册的设备通常尚未上线），等遥测同步服务下一次轮询时更新为实际值。或者 `doPlatformRegistration` 成功后额外调一次 `pageDevices` 获取 `onlineStatus`。

---

## P2 — 可选优化

### 9. `updateInfo()` 未支持 serialNo 更新

当前 `Device.updateInfo(deviceCode, devEui)` 签名不变。用户录入错误的 serialNo 后无法修正。建议 `UpdateDeviceCommand` 新增 `serialNo` 参数，`updateInfo()` 同步支持。

---

### 10. `TelemetryIngestionService.computeRuntimeStatus()` 与 blade onlineStatus 的职责边界模糊

**当前状态**：
- `TelemetryIngestionService.computeRuntimeStatus()` 根据遥测数据本地计算（antiDisassembly → offline; battery<10 → low_battery; else → online）
- spec 说 runtimeStatus 以 blade `onlineStatus` 为准

**问题**：两套逻辑如何协调？TelemetryIngestionService 处理的是**实时遥测数据**（report-record），而 blade 的 `onlineStatus` 来自 `pageDevices` 分页查询。如果遥测同步服务已用 blade onlineStatus 覆盖了 runtimeStatus，那 `computeRuntimeStatus()` 的本地计算是否还保留？

**建议**：spec 中明确说明：
- 遥测同步服务（定时轮询 `pageDevices`）→ 写 `runtimeStatus`（权威来源）
- `TelemetryIngestionService.ingest()` → 只写遥测指标字段（rssi/snr/battery 等），**不再计算 runtimeStatus**
- `computeRuntimeStatus()` 标记为 deprecated 或删除

---

### 11. Flyway seed 迁移注释不精确

**位置**：spec Section 6.3

```sql
-- 仅针对 dev 环境，test 环境不执行此迁移
```

Flyway 会无条件执行此迁移。准确描述应为：

```sql
-- 仅在 dev 环境中 dev_eui 匹配的设备的 platform_device_id 为空时 UPDATE 生效
-- test 环境中 dev_eui 值不同，UPDATE 不会命中任何行，实际为 no-op
```

---

### 12. `DeviceRepository` 层需确认 COUNT 查询

`countActiveByTenant()` 当前查询 `WHERE status = 'ACTIVE'`。OFFLINE 设备迁移为 ACTIVE 后，COUNT 会变大（以前 OFFLINE 的不算，现在全算 ACTIVE）。如果前端用这个数字做 dashboard 展示，会突然变多。需确认这是预期行为。

---

## 总结

| 级别 | 数量 | 关键问题 |
|------|------|----------|
| P0 | 3 | 自相矛盾、状态检查缺失、编译错误 |
| P1 | 5 | 过期验证项、影响范围遗漏、DB 风险、runtimeStatus 未初始化 |
| P2 | 4 | updateInfo 扩展、职责边界模糊、注释准确性、COUNT 语义 |

建议优先修复 P0 的三个问题后再实施。
