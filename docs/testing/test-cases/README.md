# 测试用例规格（docs/testing/test-cases）

> 由 tools/generate-test-cases.mjs 从后端 240 个测试类与 Mobile 118 个测试文件批量解析生成初稿（2026-11-21 基线）。
> 用例编号：TC-<域>-NNN，域对齐 SRS REQ 体系（RCH/IOT/HLT/IDT/CMC/PLT/JRY=旅程集成）。
> 状态：脚本初稿——优先级为规则推断，REQ 为关键词自动映射，步骤为单测载体模板，均需人工校对。

## 统计

- 测试文件：357
- 文档化用例：2604（P0 399 / P1 2063 / P2 142）

## 分册索引

| 分册 | 域 | 用例数 |
|---|---|---|
| [tc-app-admin-tools.md](tc-app-admin-tools.md) | PLT | 16 |
| [tc-app-alerts.md](tc-app-alerts.md) | RCH | 48 |
| [tc-app-auth-tenant.md](tc-app-auth-tenant.md) | IDT | 41 |
| [tc-app-core-infra.md](tc-app-core-infra.md) | PLT | 139 |
| [tc-app-devices.md](tc-app-devices.md) | IOT | 44 |
| [tc-app-drinking.md](tc-app-drinking.md) | HLT | 29 |
| [tc-app-fence.md](tc-app-fence.md) | RCH | 178 |
| [tc-app-gps-quality.md](tc-app-gps-quality.md) | IOT | 34 |
| [tc-app-livestock-health.md](tc-app-livestock-health.md) | RCH | 51 |
| [tc-app-subscription-license.md](tc-app-subscription-license.md) | CMC | 83 |
| [tc-server-commerce.md](tc-server-commerce.md) | CMC | 258 |
| [tc-server-datagen.md](tc-server-datagen.md) | PLT | 117 |
| [tc-server-gps-telemetry.md](tc-server-gps-telemetry.md) | IOT | 152 |
| [tc-server-health.md](tc-server-health.md) | HLT | 424 |
| [tc-server-identity.md](tc-server-identity.md) | IDT | 87 |
| [tc-server-integration.md](tc-server-integration.md) | JRY | 265 |
| [tc-server-iot-device.md](tc-server-iot-device.md) | IOT | 142 |
| [tc-server-licensing.md](tc-server-licensing.md) | CMC | 171 |
| [tc-server-platform-shared.md](tc-server-platform-shared.md) | PLT | 31 |
| [tc-server-ranch-alert.md](tc-server-ranch-alert.md) | RCH | 66 |
| [tc-server-ranch-fence.md](tc-server-ranch-fence.md) | RCH | 93 |
| [tc-server-ranch-livestock-overview.md](tc-server-ranch-livestock-overview.md) | RCH | 135 |

## 未解析文件（1）

- smart-livestock-server/src/test/java/com/smartlivestock/integration/AbstractJourneyTest.java
