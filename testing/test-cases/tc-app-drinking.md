# 测试用例规格：App·饮水监测

> 用例域：HLT ｜ 用例数：29
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-HLT-001 | boundary: en long copy renders without overflow | P2 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_boundary_golden_test.dart::boundary: en long copy renders without overflow` |
| TC-HLT-002 | boundary: textScale 1.3 renders without overflow | P2 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_boundary_golden_test.dart::boundary: textScale 1.3 renders without overflow` |
| TC-HLT-003 | build merges days=7 and days=30 calls | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::build merges days=7 and days=30 calls` |
| TC-HLT-004 | farm switch triggers rebuild | P1 | REQ-HLT-007、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::farm switch triggers rebuild` |
| TC-HLT-005 | loading while the summary is in flight | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::loading while the summary is in flight` |
| TC-HLT-006 | error on 5xx/timeout | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::error on 5xx/timeout` |
| TC-HLT-007 | noData when no rumen capsule is bound | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::noData when no rumen capsule is bound` |
| TC-HLT-008 | building below the 3-day baseline minimum | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::building below the 3-day baseline minimum` |
| TC-HLT-009 | building threshold follows the server-delivered baselineMinDays | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::building threshold follows the server-delivered baselineMinDays` |
| TC-HLT-010 | ready once ≥3 sample days exist | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::ready once ≥3 sample days exist` |
| TC-HLT-011 | premium 403 lands in AsyncError as ForbiddenException | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::premium 403 lands in AsyncError as ForbiddenException` |
| TC-HLT-012 | INSUFFICIENT_PEERS returns data with the degraded reason | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::INSUFFICIENT_PEERS returns data with the degraded reason` |
| TC-HLT-013 | markLabel patches then refreshes rows and summaries | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::markLabel patches then refreshes rows and summaries` |
| TC-HLT-014 | addManual posts the wall-clock string then refreshes | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::addManual posts the wall-clock string then refreshes` |
| TC-HLT-015 | 48h chart draws one fever shadow band per server window | P2 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_detail_section_test.dart::48h chart draws one fever shadow band per server window` |
| TC-HLT-016 | a window before the visible 48h span is not drawn | P2 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_detail_section_test.dart::a window before the visible 48h span is not drawn` |
| TC-HLT-017 | empty state keeps the manual back-fill entry for writers | P2 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_event_list_empty_test.dart::empty state keeps the manual back-fill entry for writers` |
| TC-HLT-018 | empty state hides the entry for non-write roles | P2 | REQ-HLT-007、REQ-IDT-004 | `Mobile/mobile_app/test/features/drinking/drinking_event_list_empty_test.dart::empty state hides the entry for non-write roles` |
| TC-HLT-019 | days=7 payload parses daily, weekly and 7 dayCounts | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::days=7 payload parses daily, weekly and 7 dayCounts` |
| TC-HLT-020 | days=30 payload parses rolling baseline | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::days=30 payload parses rolling baseline` |
| TC-HLT-021 | weekBars sorts ascending and trims to 7 | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::weekBars sorts ascending and trims to 7` |
| TC-HLT-022 | missing baseline block yields 0 sample days | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing baseline block yields 0 sample days` |
| TC-HLT-023 | baselineMinDays is exposed from the days=30 layer | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::baselineMinDays is exposed from the days=30 layer` |
| TC-HLT-024 | parses candidate rows and marking-loop helpers | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::parses candidate rows and marking-loop helpers` |
| TC-HLT-025 | missing lowConfidence defaults to false | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing lowConfidence defaults to false` |
| TC-HLT-026 | normal payload | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::normal payload` |
| TC-HLT-027 | INSUFFICIENT_PEERS keeps the degraded copy path | P1 | REQ-HLT-007 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::INSUFFICIENT_PEERS keeps the degraded copy path` |
| TC-HLT-028 | parses events plus clipped fever windows | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::parses events plus clipped fever windows` |
| TC-HLT-029 | missing feverWindows degrades to an empty band list | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing feverWindows degrades to an empty band list` |

## 用例明细（初稿模板）

### TC-HLT-001 boundary: en long copy renders without overflow

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_boundary_golden_test.dart::boundary: en long copy renders without overflow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-002 boundary: textScale 1.3 renders without overflow

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_boundary_golden_test.dart::boundary: textScale 1.3 renders without overflow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-003 build merges days=7 and days=30 calls

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingSummaryController
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::build merges days=7 and days=30 calls`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-004 farm switch triggers rebuild

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::farm switch triggers rebuild`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-IDT-001、REQ-IDT-003

### TC-HLT-005 loading while the summary is in flight

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：resolveDrinkingCardUiState (five-state convention)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::loading while the summary is in flight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-006 error on 5xx/timeout

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::error on 5xx/timeout`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-007 noData when no rumen capsule is bound

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::noData when no rumen capsule is bound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-008 building below the 3-day baseline minimum

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::building below the 3-day baseline minimum`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-009 building threshold follows the server-delivered baselineMinDays

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::building threshold follows the server-delivered baselineMinDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-010 ready once ≥3 sample days exist

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::ready once ≥3 sample days exist`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-011 premium 403 lands in AsyncError as ForbiddenException

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingPeerController
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::premium 403 lands in AsyncError as ForbiddenException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-012 INSUFFICIENT_PEERS returns data with the degraded reason

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::INSUFFICIENT_PEERS returns data with the degraded reason`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-013 markLabel patches then refreshes rows and summaries

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingEventsController marking loop
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::markLabel patches then refreshes rows and summaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-014 addManual posts the wall-clock string then refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_controller_test.dart::addManual posts the wall-clock string then refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-015 48h chart draws one fever shadow band per server window

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_detail_section_test.dart::48h chart draws one fever shadow band per server window`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-016 a window before the visible 48h span is not drawn

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_detail_section_test.dart::a window before the visible 48h span is not drawn`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-017 empty state keeps the manual back-fill entry for writers

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_event_list_empty_test.dart::empty state keeps the manual back-fill entry for writers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-018 empty state hides the entry for non-write roles

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_event_list_empty_test.dart::empty state hides the entry for non-write roles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-IDT-004

### TC-HLT-019 days=7 payload parses daily, weekly and 7 dayCounts

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingSummary.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::days=7 payload parses daily, weekly and 7 dayCounts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-020 days=30 payload parses rolling baseline

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::days=30 payload parses rolling baseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-021 weekBars sorts ascending and trims to 7

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingSummaryBundle
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::weekBars sorts ascending and trims to 7`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-022 missing baseline block yields 0 sample days

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing baseline block yields 0 sample days`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-023 baselineMinDays is exposed from the days=30 layer

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::baselineMinDays is exposed from the days=30 layer`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-024 parses candidate rows and marking-loop helpers

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingEvent.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::parses candidate rows and marking-loop helpers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-025 missing lowConfidence defaults to false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing lowConfidence defaults to false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-026 normal payload

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingPeerComparison.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::normal payload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-027 INSUFFICIENT_PEERS keeps the degraded copy path

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::INSUFFICIENT_PEERS keeps the degraded copy path`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007

### TC-HLT-028 parses events plus clipped fever windows

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DrinkingEventsPage.fromJson (NIX-259 m-q)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::parses events plus clipped fever windows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-029 missing feverWindows degrades to an empty band list

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/drinking/drinking_models_test.dart::missing feverWindows degrades to an empty band list`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

