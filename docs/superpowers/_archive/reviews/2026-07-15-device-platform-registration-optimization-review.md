# 评审：设备平台注册流程优化

**文档**: `docs/superpowers/specs/2026-07-15-device-platform-registration-optimization.md`
**评审日期**: 2026-07-15
**评审人**: Codex

---

## 总体评价

Spec 方向正确——将 `platformDeviceId` 获取与设备激活状态绑定是合理的。当前代码的问题（平台注册失败静默吞异常、`activateDevice()` 纯本地无平台交互）确实需要修复。

但 spec 在**概念映射、状态机变更、数据迁移**三方面存在关键缺陷，直接按当前设计实现会导致回归和数据不一致。

---

## P0 — 阻塞性问题

### P0-1：`deviceCode` ≠ SN — 概念混淆

Spec 第二章把 `deviceCode`（SN）和 `devEui`（EUI）并列，暗示 `deviceCode` 就是设备的序列号。**这不是事实。**

- `deviceCode` 是 smart-livestock 应用层分配的编号（如 `TST-17`、`DEV-GPS-001`），由用户或种子数据任意指定
- blade 平台的 SN（serial number）是设备出厂编号，通常与 EUI 相关（PoC 数据中 EUI `00956906000285d8` 对应的平台 `deviceSn` 是另一格式）
- blade 的 `getLicenseStatusBySn()` 接口期望的是**真实的设备序列号**，不是 app 自分配的 `deviceCode`

**影响**：`resolveSn()` 返回 `deviceCode`（如 `TST-17`），传给 blade 的 license 查询 → 查不到 → license 校验跳过 → 用错误的 `deviceIdentifier` 注册 → 注册失败或创建无效设备。

**建议**：明确区分三个概念：
1. `deviceCode` — 应用层编号（展示用，不变）
2. `serialNo` — 设备出厂序列号（blade license 查询用）—— 需要在 Device 模型新增此字段
3. `devEui` — LoRaWAN EUI（blade 注册标识符用）

或者简化：如果实际场景中 SN 和 EUI 总是相同的（PoC 数据暗示如此），则统一只用 `devEui`，不要引入 SN 回退逻辑。但需要在 spec 中**明确记录这个假设**。

### P0-2：`activateDevice()` 重写破坏 OFFLINE → ACTIVE 语义

Spec 4.2 把 `PUT /devices/{id}/activate` 从纯本地状态变更改为"平台注册 + 激活"。

当前状态机允许 `OFFLINE → ACTIVE`（`Device.activate()` 允许从 INVENTORY 或 OFFLINE 转入）。一个已注册的 ACTIVE 设备掉线后恢复在线，调用 `activate()` 是正常操作。

**但新实现会让这个操作变成：**
- 检查 `platformDeviceId != null` → 已有则跳过平台注册 → 直接 activate → ✅ 没问题
- 如果 `platformDeviceId == null`（异常状态）→ 尝试平台注册 → 可能因平台暂时不可达而失败 → 设备卡在 OFFLINE

**核心问题**：OFFLINE→ACTIVE 这个高频恢复操作，不应依赖外部平台可用性。

**建议**：
- 新增一个独立的 `PUT /devices/{id}/register-with-platform` 端点专门做平台注册
- `activate()` 保持纯本地语义（仅状态流转）
- 或者：activate 时仅在 `platformDeviceId == null` 时才触发平台注册，已有 platformDeviceId 的设备 activate 纯本地

### P0-3：现有 ACTIVE 无 platformDeviceId 设备的数据迁移缺失

当前数据库有大量 ACTIVE 设备但 `platformDeviceId = NULL`（V10 种子的 100 台设备，以及 test 环境的 TST-17/21/22）。

Spec 声明"INVENTORY → ACTIVE 的唯一途径是成功获取 blade deviceId"，但不处理这些存量数据。

**影响**：
- 这些设备在 `InstallationApplicationService.install()` 中仍可通过 `status == ACTIVE` 检查（已有校验），但 `platformDeviceId` 为 NULL → 遥测采集跳过
- 如果实现 P0-2 的修复（activate 时按 platformDeviceId 分流），这些设备的 OFFLINE→ACTIVE 恢复会被阻断

**建议**：新增 Flyway 迁移，对 test 环境的 TST-17/21/22 写入正确的 `platform_device_id`（PoC 数据中已有映射）。对 dev 环境的种子设备，提供批量注册脚本或接受它们保持 INVENTORY 状态。

---

## P1 — 应修复

### P1-1：`resolveSn()`/`resolveEui()` 互相回退是语义错误

```
resolveSn(device):   deviceCode → devEui fallback
resolveEui(device):  devEui → deviceCode fallback
```

EUI 是 16 字符 hex（如 `00956906000285d8`），deviceCode 是任意字符串（如 `TST-17`）。用 `TST-17` 作为 EUI 去调用 blade `registerDevice` 的 `deviceIdentifier` 字段是无效的。

**建议**：去掉互相回退。EUI 为空时不尝试 blade 注册（返回 INVENTORY），不要用 deviceCode 冒充 EUI。

### P1-2：Controller 校验硬编码中文

```java
ApiResponse.error(ErrorCode.VALIDATION_ERROR, "deviceCode 和 devEui 至少需要提供一个")
```

违反项目 i18n 规范。应使用 `messageResolver` 或 i18n key：

```java
ApiResponse.error(ErrorCode.VALIDATION_ERROR, "error.deviceSnOrEuiRequired")
```

并在 `messages_zh.properties` / `messages_en.properties` 同步新增。

同时 `OpenDeviceRegisterController` 中已有的硬编码中文 `"serialNo 不能为空"` 也应一并修复。

### P1-3：OAuth2 配置遗漏

`application.yml` 中 `agentic-platform.oauth2.enabled` 默认为 `false`。这意味着 Feign client 到 blade 的调用**不带认证**。

Spec 第六章只提到 `AGENTIC_PLATFORM_DEVICE_BASE_URL` 和 `AGENTIC_PLATFORM_LICENSE_BASE_URL`，完全没提 OAuth2 相关变量。

**建议**：
- 明确 OAuth2 是否必须开启
- 如必须，docker-compose 中需传递 `AGENTIC_PLATFORM_OAUTH2_ENABLED=true` 等变量
- 如当前 blade Feign 接口不需要认证（内网直连），在 spec 中记录这个前提

---

## P2 — 建议改进

### P2-1：`DevicePageReq` 新增 `keyword` 影响面

`DevicePageReq` 是 blade Feign 接口的请求 DTO，可能被 `TelemetryIngestionService` 等其他调用方使用。新增 `keyword` 字段不会破坏现有调用（JSON 序列化会忽略 null），但应在 spec 中确认。

### P2-2：验证方式缺少边界用例

第九章的验证场景缺少：
- blade 平台不可达时 `registerDevice` 的行为（应返回 INVENTORY，不阻塞创建）
- OAuth2 认证失败的错误提示
- `devEui` 格式错误（非 16 字符 hex）的校验
- 重复注册同一 EUI 的幂等处理

### P2-3：前端"手动激活"UX 细节缺失

第八章提到激活操作但未描述：
- 激活过程中的 loading 状态
- 激活失败后的错误 toast 显示（NIX-16 修复的 `ApiException.toString()` 正好支撑这里）
- 是否需要"重试"按钮 vs 直接调 activate

### P2-4：`registerWithPlatform()` 与 `activateDevice()` 职责重叠

Spec 同时修改了两个方法（4.2 的 activate 和 5.1 的 registerWithPlatform），它们的逻辑高度相似（都是"获取 platformDeviceId → activate"）。应明确：
- 用户面对的是哪个端点？
- 是否合并为一个，废弃另一个？
- Open API 的 `register-with-platform` 和 App API 的 `activate` 是否应统一语义？

---

## 实现前需调整的清单

| # | 调整项 | 优先级 |
|---|--------|--------|
| 1 | 明确 `deviceCode` vs `serialNo` vs `devEui` 三者关系，决定是否新增 `sn` 字段或统一用 `devEui` | P0 |
| 2 | activate 端点分两种路径：已有 platformDeviceId → 纯本地状态流转；无 platformDeviceId → 平台注册 | P0 |
| 3 | 新增 Flyway 迁移，修复 test 环境 TST-17/21/22 的 `platform_device_id` | P0 |
| 4 | 去掉 `resolveSn()`/`resolveEui()` 的互相回退逻辑 | P1 |
| 5 | 所有新增/修改的 Controller 校验消息走 i18n key | P1 |
| 6 | docker-compose 中补充 OAuth2 相关环境变量（如需要） | P1 |
| 7 | 明确 `registerWithPlatform()` 与 `activateDevice()` 的职责边界 | P2 |
| 8 | 补充边界测试用例 | P2 |
