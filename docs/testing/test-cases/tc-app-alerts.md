# 测试用例规格：App·告警工作台

> 用例域：RCH ｜ 用例数：48
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-001 | active ESTRUS alert shows confirm/reject actions | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::active ESTRUS alert shows confirm/reject actions` |
| TC-RCH-002 | non-ESTRUS alert shows no confirm/reject actions | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::non-ESTRUS alert shows no confirm/reject actions` |
| TC-RCH-003 | confirm flow posts to the estrus-feedback endpoint and shows success | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::confirm flow posts to the estrus-feedback endpoint and shows success` |
| TC-RCH-004 | renders four buckets, unread state, and asset card | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::renders four buckets, unread state, and asset card` |
| TC-RCH-005 | parses workbench payload and reconciles unread total | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::parses workbench payload and reconciles unread total` |
| TC-RCH-006 | ESTRUS item shows confirm/reject actions wired to the underlying alertId | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::ESTRUS item shows confirm/reject actions wired to the underlying alertId` |
| TC-RCH-007 | non-ESTRUS item shows no estrus confirm/reject actions | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::non-ESTRUS item shows no estrus confirm/reject actions` |
| TC-RCH-008 | CRITICAL severity maps to P0 priority | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::CRITICAL severity maps to P0 priority` |
| TC-RCH-009 | WARNING severity maps to P1 priority | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::WARNING severity maps to P1 priority` |
| TC-RCH-010 | LOW severity maps to P2 priority | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::LOW severity maps to P2 priority` |
| TC-RCH-011 | null severity defaults to WARNING/P1 | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null severity defaults to WARNING/P1` |
| TC-RCH-012 | lowercase severity still maps correctly | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::lowercase severity still maps correctly` |
| TC-RCH-013 | status DISMISSED maps to dismissed stage | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::status DISMISSED maps to dismissed stage` |
| TC-RCH-014 | status AUTO_RESOLVED maps to auto_resolved wire stage | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::status AUTO_RESOLVED maps to auto_resolved wire stage` |
| TC-RCH-015 | legacy status PENDING maps to active | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status PENDING maps to active` |
| TC-RCH-016 | legacy status ACKNOWLEDGED maps to active | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status ACKNOWLEDGED maps to active` |
| TC-RCH-017 | legacy status HANDLED maps to dismissed | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status HANDLED maps to dismissed` |
| TC-RCH-018 | legacy status ARCHIVED maps to auto_resolved | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status ARCHIVED maps to auto_resolved` |
| TC-RCH-019 | unknown status defaults to active | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::unknown status defaults to active` |
| TC-RCH-020 | null status defaults to active | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null status defaults to active` |
| TC-RCH-021 | null type defaults to unknown | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null type defaults to unknown` |
| TC-RCH-022 | int id converted to string | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::int id converted to string` |
| TC-RCH-023 | int livestockId converted to string | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::int livestockId converted to string` |
| TC-RCH-024 | null livestockId defaults earTag to dash | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null livestockId defaults earTag to dash` |
| TC-RCH-025 | custom source overrides default RULE | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::custom source overrides default RULE` |
| TC-RCH-026 | null message produces empty title | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null message produces empty title` |
| TC-RCH-027 | occurredAt extracted from response | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::occurredAt extracted from response` |
| TC-RCH-028 | resolvedAt used as fallback when occurredAt absent | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::resolvedAt used as fallback when occurredAt absent` |
| TC-RCH-029 | null occurredAt and resolvedAt yields null | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null occurredAt and resolvedAt yields null` |
| TC-RCH-030 | build loads alerts | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::build loads alerts` |
| TC-RCH-031 | setFilterStatus passes status to repo | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::setFilterStatus passes status to repo` |
| TC-RCH-032 | setFilterSeverity passes severity to repo | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::setFilterSeverity passes severity to repo` |
| TC-RCH-033 | markRead delegates to repo and refreshes | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::markRead delegates to repo and refreshes` |
| TC-RCH-034 | dismiss delegates to repo and refreshes | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::dismiss delegates to repo and refreshes` |
| TC-RCH-035 | batchRead delegates list and refreshes | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::batchRead delegates list and refreshes` |
| TC-RCH-036 | legacy acknowledge delegates to markRead | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy acknowledge delegates to markRead` |
| TC-RCH-037 | legacy handle delegates to dismiss | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy handle delegates to dismiss` |
| TC-RCH-038 | legacy batchHandle delegates to batchRead | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy batchHandle delegates to batchRead` |
| TC-RCH-039 | legacy archive is a no-op (no repo call) | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy archive is a no-op (no repo call)` |
| TC-RCH-040 | farm switch triggers rebuild | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001 | `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::farm switch triggers rebuild` |
| TC-RCH-041 | renders confirm and reject buttons for ESTRUS alert | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::renders confirm and reject buttons for ESTRUS alert` |
| TC-RCH-042 | confirm flow: dialog → API path/body correct via real repository →  | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::confirm flow: dialog → API path/body correct via real repository → ` |
| TC-RCH-043 | reject flow: dialog → API body {"confirmed": false} → reject snackbar | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::reject flow: dialog → API body {"confirmed": false} → reject snackbar` |
| TC-RCH-044 | server error surfaces the backend message, buttons stay | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::server error surfaces the backend message, buttons stay` |
| TC-RCH-045 | non-API failure shows generic copy without leaking raw error | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::non-API failure shows generic copy without leaking raw error` |
| TC-RCH-046 | idempotent repeat shows the duplicate verdict copy | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::idempotent repeat shows the duplicate verdict copy` |
| TC-RCH-047 | buttons show spinner and ignore taps while submitting | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::buttons show spinner and ignore taps while submitting` |
| TC-RCH-048 | enabled=false buttons never trigger a submission | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022 | `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::enabled=false buttons never trigger a submission` |

## 用例明细（初稿模板）

### TC-RCH-001 active ESTRUS alert shows confirm/reject actions

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::active ESTRUS alert shows confirm/reject actions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-002 non-ESTRUS alert shows no confirm/reject actions

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::non-ESTRUS alert shows no confirm/reject actions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-003 confirm flow posts to the estrus-feedback endpoint and shows success

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_detail_sheet_estrus_test.dart::confirm flow posts to the estrus-feedback endpoint and shows success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-004 renders four buckets, unread state, and asset card

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::renders four buckets, unread state, and asset card`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-RCH-005 parses workbench payload and reconciles unread total

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::parses workbench payload and reconciles unread total`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-006 ESTRUS item shows confirm/reject actions wired to the underlying alertId

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::ESTRUS item shows confirm/reject actions wired to the underlying alertId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-007 non-ESTRUS item shows no estrus confirm/reject actions

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alert_workbench_test.dart::non-ESTRUS item shows no estrus confirm/reject actions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-008 CRITICAL severity maps to P0 priority

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：AlertsApiRepository._alertItemFromMap
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::CRITICAL severity maps to P0 priority`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-009 WARNING severity maps to P1 priority

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::WARNING severity maps to P1 priority`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-010 LOW severity maps to P2 priority

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::LOW severity maps to P2 priority`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-011 null severity defaults to WARNING/P1

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null severity defaults to WARNING/P1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-012 lowercase severity still maps correctly

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::lowercase severity still maps correctly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-013 status DISMISSED maps to dismissed stage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::status DISMISSED maps to dismissed stage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-RCH-014 status AUTO_RESOLVED maps to auto_resolved wire stage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::status AUTO_RESOLVED maps to auto_resolved wire stage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-015 legacy status PENDING maps to active

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status PENDING maps to active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-016 legacy status ACKNOWLEDGED maps to active

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status ACKNOWLEDGED maps to active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-017 legacy status HANDLED maps to dismissed

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status HANDLED maps to dismissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-RCH-018 legacy status ARCHIVED maps to auto_resolved

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::legacy status ARCHIVED maps to auto_resolved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-019 unknown status defaults to active

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::unknown status defaults to active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-020 null status defaults to active

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null status defaults to active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-021 null type defaults to unknown

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null type defaults to unknown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-022 int id converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::int id converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-023 int livestockId converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::int livestockId converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-024 null livestockId defaults earTag to dash

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null livestockId defaults earTag to dash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-025 custom source overrides default RULE

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::custom source overrides default RULE`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-026 null message produces empty title

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null message produces empty title`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-027 occurredAt extracted from response

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：AlertsApiRepository._alertDetailFromMap
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::occurredAt extracted from response`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-028 resolvedAt used as fallback when occurredAt absent

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::resolvedAt used as fallback when occurredAt absent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-029 null occurredAt and resolvedAt yields null

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_api_repository_test.dart::null occurredAt and resolvedAt yields null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-030 build loads alerts

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::build loads alerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-031 setFilterStatus passes status to repo

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::setFilterStatus passes status to repo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-RCH-032 setFilterSeverity passes severity to repo

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::setFilterSeverity passes severity to repo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-RCH-033 markRead delegates to repo and refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::markRead delegates to repo and refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-034 dismiss delegates to repo and refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::dismiss delegates to repo and refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-035 batchRead delegates list and refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::batchRead delegates list and refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-036 legacy acknowledge delegates to markRead

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy acknowledge delegates to markRead`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-037 legacy handle delegates to dismiss

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy handle delegates to dismiss`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-038 legacy batchHandle delegates to batchRead

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy batchHandle delegates to batchRead`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-039 legacy archive is a no-op (no repo call)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::legacy archive is a no-op (no repo call)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010

### TC-RCH-040 farm switch triggers rebuild

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/alerts_controller_test.dart::farm switch triggers rebuild`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001

### TC-RCH-041 renders confirm and reject buttons for ESTRUS alert

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::renders confirm and reject buttons for ESTRUS alert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-042 confirm flow: dialog → API path/body correct via real repository → 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::confirm flow: dialog → API path/body correct via real repository → `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-043 reject flow: dialog → API body {"confirmed": false} → reject snackbar

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::reject flow: dialog → API body {"confirmed": false} → reject snackbar`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-044 server error surfaces the backend message, buttons stay

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::server error surfaces the backend message, buttons stay`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-045 non-API failure shows generic copy without leaking raw error

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::non-API failure shows generic copy without leaking raw error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-046 idempotent repeat shows the duplicate verdict copy

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::idempotent repeat shows the duplicate verdict copy`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-047 buttons show spinner and ignore taps while submitting

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::buttons show spinner and ignore taps while submitting`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

### TC-RCH-048 enabled=false buttons never trigger a submission

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/alerts/estrus_feedback_actions_test.dart::enabled=false buttons never trigger a submission`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-022

