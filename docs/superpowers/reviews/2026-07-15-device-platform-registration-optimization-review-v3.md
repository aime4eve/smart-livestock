# 设备平台注册流程优化 — 最终复查（v3）

**复查对象**：`docs/superpowers/specs/2026-07-15-device-platform-registration-optimization.md`（v3，含复审 v2 反馈）
**复查日期**：2026-07-15
**复查范围**：全代码库影响面排查（后端 + 前端 + 数据库 + API 文档 + 定时任务）
**复查人**：Codex

---

## 复查方法

对 spec 中每一项变更，在代码库中逐一追踪其影响面：
- `markOffline()` / `DeviceStatus.OFFLINE` 的所有调用方和引用点
- `TelemetryIngestionService` 和遥测同步链路对设备状态的依赖
- 前端 `status` / `runtimeStatus` 解析逻辑
- Open API 契约文档
- 定时任务（`@Scheduled`）
- 种子数据中的 OFFLINE 状态

---

## P0 — 阻塞性问题

### P0-1：`activateDevice()` 返回类型变更未同步到 Controller

**现状**：`DeviceApplicationService.activateDevice()` 当前返回 `void`，Controller 中先调用 activate 再单独调 `getDevice()` 获取 DTO：

```java
// DeviceController.java:113-116 (现状)
deviceApplicationService.activateDevice(deviceId);
DeviceDto device = deviceApplicationService.getDevice(deviceId);
return ResponseEntity.ok(ApiResponse.ok(device));
```

**Spec 要求**：`activateDevice()` 改为返回 `DeviceDto`。

**风险**：如果 service 改返回值但 Controller 仍按旧的 void + getDevice 模式调用，要么编译错误（void 不能赋给变量），要么多一次不必要的 getDevice 查询。

**建议**：spec 第八章影响范围表中明确 `DeviceController.java` 的 activate 端点需同步适配——删除 `getDevice()` 调用，直接用 service 返回的 DTO。

### P0-2：Open API 文档声明 status 含 OFFLINE，去掉后是 breaking change

**现状**：`docs/api-contracts/app-api.md` 第 651 行：

```
- `status`: 生命周期状态（`inventory` / `active` / `offline` / `decommissioned`）
```

**风险**：去掉 OFFLINE 后，如果有外部 API consumer 解析 `status` 字段并依赖 `"offline"` 值，会收到未知值。

**建议**：
1. spec 影响范围新增 `docs/api-contracts/app-api.md`、`admin-api.md`、`open-api.md`，更新 status 枚举值描述
2. 在 API 文档中标注 OFFLINE 已废弃，迁移到 `runtimeStatus` 字段
3. 检查是否有外部 consumer（当前无，但预留 changelog 记录）

---

## P1 — 应修复

### P1-1：`DeviceDto.from()` 的 runtimeStatus fallback 逻辑与新持久化修复冲突

**现状**：`DeviceDto.from()` 在 `runtimeStatus == null` 时根据 `lastOnlineAt` 推算在线状态（2小时内=online）：

```java
if (runtimeStatus == null) {
    if (lastOnlineAt != null && Duration.between(lastOnlineAt, Instant.now()).toHours() < 2) {
        runtimeStatus = "online";
    } else {
        runtimeStatus = "offline";
    }
}
```

**问题**：spec 修复了 runtimeStatus 持久化（既有 bug），之后 runtimeStatus 不再为 null（除非旧数据）。但这段 fallback 逻辑会掩盖"从未收到遥测"的设备（runtimeStatus 真正为 null）的状态。对于 V10 种子中 8 台原 OFFLINE 设备（迁移后变为 ACTIVE），它们的 `runtimeStatus` 历史上从未持久化过（mapper bug），重启后为 null，fallback 逻辑会根据 `lastOnlineAt`（V10 种子中是旧时间）推算为 offline——**结果是合理的，但靠巧合而非设计**。

**建议**：spec 中明确记录这个 fallback 逻辑的存废：
- 选项 A：保留 fallback 作为兼容层，在 runtimeStatus 持久化修复后的首次遥测同步前生效
- 选项 B：移除 fallback，runtimeStatus 为 null 时 DTO 直接返回 null，前端自行处理

推荐选项 A（渐进式），在 fallback 逻辑上加注释说明"临时兼容，未来可移除"。

### P1-2：V10 种子数据中的 OFFLINE 状态会在新部署时写入

**现状**：V10 种子迁移（已执行过，不会重跑）中有 8 条 `status='OFFLINE'` 的 INSERT。如果全新环境部署（数据库从零初始化），V10 会插入 OFFLINE 设备，然后 V20260715121000 会把它们 UPDATE 为 ACTIVE。

**风险**：V10 的 INSERT 与 V20260715121000 的 UPDATE 之间的窗口期（如果迁移中途失败），会有 OFFLINE 状态的设备存在。虽然 Flyway 事务保证原子性，但更干净的做法是直接修改 V10 种子数据。

**建议**：由于 V10 已执行过不可修改（Flyway checksum），spec 中已有 V20260715121000 迁移处理。在 spec 中明确记录"V10 的 OFFLINE 不修改，由后续迁移统一处理"。

### P1-3：`TelemetryIngestionService.ingest()` 的 `status == ACTIVE` 守卫行为变化

**现状**：`TelemetryIngestionService.ingest()` 第 76 行：

```java
if (device.getStatus() != DeviceStatus.ACTIVE) {
    return; // skip non-active devices
}
```

**影响**：OFFLINE→ACTIVE 迁移后，原 OFFLINE 设备（如 DEV-GPS-043~046）现在变为 ACTIVE，遥测采集会开始处理它们。但这些设备没有 `platformDeviceId`（dev 环境），`AgenticPlatformTelemetrySyncJob.syncDevice()` 开头检查 `platformDeviceId == null → return`，所以实际不会处理。**没有风险**，但 spec 应记录这个逻辑链确保安全。

**建议**：spec 影响范围说明 TelemetryIngestionService 的 `ingest()` 守卫不变，且 `AgenticPlatformTelemetrySyncJob` 的 `platformDeviceId == null → return` 守卫保证了无平台注册的设备不会被遥测处理。

---

## P2 — 信息记录

### P2-1：前端 `_parseDeviceItem` 无需改动（已确认安全）

前端解析逻辑：`m['runtimeStatus'] ?? m['status']`，映射时 `'ACTIVE' => online`，`_ => offline`。去掉后端 OFFLINE 后：
- `status = INVENTORY` → fallback 走 `_ => offline`（合理，未注册设备显示离线）
- `status = ACTIVE` → 映射为 `online`
- `status = DECOMMISSIONED` → fallback 走 `_ => offline`（合理）

前端 `lifecycleStatus` 字段单独存储原始 status，`isActivated` getter 检查 `== 'ACTIVE'`，不受影响。

**结论**：前端零改动，spec 第九章描述准确。

### P2-2：`markOffline()` 删除安全（无运行时调用方）

排查结果：
- `TelemetryIngestionService.ingest()` → 不调用 markOffline，只调 `setRuntimeStatus()`
- `AgenticPlatformTelemetrySyncJob.syncDevice()` → 不调用 markOffline
- Controller → 无 offline 端点（只有 activate 和 decommission）
- 定时任务 → 无 `@Scheduled` 调用 markOffline

`markOffline()` 仅在测试代码中被调用。删除安全。

### P2-3：`computeRuntimeStatus()` 废弃后的遥测指标写入

spec 说 `computeRuntimeStatus()` 标记 deprecated，`ingest()` 不再调它。但 `updateDeviceRuntimeStatus()` 除了 runtimeStatus 外还更新 rssi/snr/battery/gateway 等遥测指标。确保只移除 `setRuntimeStatus(computeRuntimeStatus(...))` 这一行，其余遥测指标更新保留。

**建议**：spec 5.8 节已明确"删除 `device.setRuntimeStatus(computeRuntimeStatus(...))` 行"，但应额外注明"`updateDeviceRuntimeStatus()` 中的其他字段更新（rssi/snr/battery 等）保留不动"。

### P2-4：`DeviceApplicationService.markOffline()` 删除后需确认无反射调用

`markOffline(Long id)` 是 public 方法。需确认没有通过反射（如 Spring SpEL、@PreAuthorize 表达式等）调用它。排查结果：无此类调用。

---

## 总结

| 级别 | 数量 | 关键问题 |
|------|------|----------|
| P0 | 2 | Controller 适配遗漏、API 文档 breaking change 未记录 |
| P1 | 3 | DTO fallback 逻辑存废、V10 种子窗口期、遥测守卫行为变化 |
| P2 | 4 | 前端确认安全、markOffline 删除安全、computeRuntimeStatus 精确范围、反射调用确认 |

### 与 v2 复审的对比

v2 复审的 P0×3 + P1×5 已在 spec v3 中全部修复。本次 v3 复审新发现的 P0-2（API 文档 breaking change）是之前未覆盖的维度。

### P2-5：前端存在既有 bug（与本次改动无关，但建议同步修复）

前端调查发现两套设备状态判断逻辑并行存在，方式 B 有死代码 bug：

**方式 A（正确，使用已解析的 DeviceStatus 枚举）**：
- `devices_page.dart:585-589` 概览统计卡片
- `highfi_device_tile.dart:135-146` 设备磁贴
- `livestock_detail_page.dart:237-239` 牲畜详情设备图标

**方式 B（有 bug，直接用原始字符串比较）**：
- `devices_page.dart:809`：`d.status == 'ACTIVE'` — 枚举 vs 字符串，永假
- `devices_page.dart:850`：`d.status.name.toLowerCase() == 'active'` — 枚举名不含 active，永假
- `device_health_card.dart:95,134,163,175`：`devices_page.dart` 的复制副本，同样 bug

**实际影响**：设备健康弹窗（方式 B）中，只要 `runtimeStatus` 原始字符串不是 `"online"`，一律显示红色"离线"——即使 `status` 枚举已是 `online`。

**与本次改动的关系**：这些是既有 bug，不是本次改动引入的。但本次修改 `runtimeStatus` 持久化和 `computeRuntimeStatus()` 废弃后，`runtimeStatus` 从"本地推算"变为"blade 同步"，行为会变化。建议本次同步修复方式 B，统一用方式 A（信任已解析的 `DeviceStatus` 枚举）。

**另外**：`highfi_device_tile.dart:144-146` 有硬编码中文（"在线"/"离线"/"低电"），违反 i18n 规范，应改用已有的 `DeviceStatusL10n.localizedLabel(l10n)` 扩展。

---

## 风险评估

**整体风险：中低**。核心风险点是 OFFLINE 状态去掉的连锁影响，但经过全代码库排查：

1. **`markOffline()` 删除安全** — 无运行时调用方（仅测试代码引用）
2. **前端零改动** — `_parseDeviceItem` 解析逻辑天然兼容（`runtimeStatus ?? status` → `ACTIVE→online, default→offline`）
3. **遥测同步安全** — `AgenticPlatformTelemetrySyncJob` 有双重守卫（`platformDeviceId != null` + `status == ACTIVE`），原 OFFLINE 设备迁移为 ACTIVE 后因无 platformDeviceId 仍不会被处理
4. **定时任务安全** — 无 `@Scheduled` 调用 markOffline

**最大风险**：API 文档 breaking change（P0-2）和 activateDevice 返回值适配（P0-1），两者都是文档/接口层面的遗漏，修复成本低。

建议修复 P0 两项后即可进入 plan 阶段。前端既有 bug（P2-5）可视优先级决定是否纳入本次改动。
