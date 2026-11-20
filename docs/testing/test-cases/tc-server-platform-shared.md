# 测试用例规格：后端·平台与共享设施

> 用例域：PLT ｜ 用例数：31
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-PLT-158 | startEditing 成功时记录 fence_edit_enter 且 payload 正确 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::startEditing 成功时记录 fence_edit_enter 且 payload 正确` |
| TC-PLT-159 | startEditing 无效 fenceId 时不记录 fence_edit_enter | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::startEditing 无效 fenceId 时不记录 fence_edit_enter` |
| TC-PLT-160 | saveEditing 时记录 fence_edit_save | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::saveEditing 时记录 fence_edit_save` |
| TC-PLT-161 | cancelEditing 时记录 fence_edit_cancel | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::cancelEditing 时记录 fence_edit_cancel` |
| TC-PLT-162 | saveEditing 无 session 时不记录事件 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::saveEditing 无 session 时不记录事件` |
| TC-PLT-163 | cancelEditing 无 session 时不记录事件 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::cancelEditing 无 session 时不记录事件` |
| TC-PLT-169 | classLevel_requiresPlatformAdminOnly | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/AnalyticsAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly` |
| TC-PLT-170 | endpoints_haveNoPerMethodOverride | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/AnalyticsAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride` |
| TC-PLT-171 | classLevel_requiresPlatformAdminOnly | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/PortalAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly` |
| TC-PLT-172 | endpoints_haveNoPerMethodOverride | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/PortalAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride` |
| TC-PLT-283 | ensureCurrentAndFuturePartitions_coversAllTablesAndMonitorsDefault | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-HLT-006 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/application/PartitionMaintenanceServiceTest.java::ensureCurrentAndFuturePartitions_coversAllTablesAndMonitorsDefault` |
| TC-PLT-284 | dispatchSendsToEnabledUsersTokensInServerEnvironment | P1 | REQ-IDT-002、REQ-IDT-006、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::dispatchSendsToEnabledUsersTokensInServerEnvironment` |
| TC-PLT-285 | payloadCarriesAlertIdentityForDeepLink | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::payloadCarriesAlertIdentityForDeepLink` |
| TC-PLT-286 | disabledSwitchSkipsEverything | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::disabledSwitchSkipsEverything` |
| TC-PLT-287 | userToggleOffFiltersRecipients | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::userToggleOffFiltersRecipients` |
| TC-PLT-288 | invalidTokenReportedByApnsIsReaped | P1 | REQ-IDT-002、REQ-IDT-006、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::invalidTokenReportedByApnsIsReaped` |
| TC-PLT-289 | vanishedAlertSkipsDispatch | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::vanishedAlertSkipsDispatch` |
| TC-PLT-290 | passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::passesThrough` |
| TC-PLT-291 | passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::passesThrough` |
| TC-PLT-292 | noTenantId_passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::noTenantId_passesThrough` |
| TC-PLT-293 | noFarmId_passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::noFarmId_passesThrough` |
| TC-PLT-294 | quotaAllowed_passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaAllowed_passesThrough` |
| TC-PLT-295 | quotaAllowedWithRetention_passesThrough | P0 | REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaAllowedWithRetention_passesThrough` |
| TC-PLT-296 | quotaDenied_throwsApiException | P0 | REQ-CMC-003、REQ-CMC-009、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaDenied_throwsApiException` |
| TC-PLT-297 | farmIdFromPath_whenAttributeMissing | P0 | REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::farmIdFromPath_whenAttributeMissing` |
| TC-PLT-298 | unknownFeatureKey_usesZeroUsage | P0 | REQ-CMC-003、REQ-CMC-009、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::unknownFeatureKey_usesZeroUsage` |
| TC-PLT-299 | resolvesChineseMessage | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::resolvesChineseMessage` |
| TC-PLT-300 | resolvesEnglishMessage | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::resolvesEnglishMessage` |
| TC-PLT-301 | fallsBackToKeyWhenNotFound | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::fallsBackToKeyWhenNotFound` |
| TC-PLT-302 | accessDeniedTranslatesByLocale | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::accessDeniedTranslatesByLocale` |
| TC-PLT-303 | numericArgsRenderVerbatimWithoutLocaleGrouping | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::numericArgsRenderVerbatimWithoutLocaleGrouping` |

## 用例明细（初稿模板）

### TC-PLT-158 startEditing 成功时记录 fence_edit_enter 且 payload 正确

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::startEditing 成功时记录 fence_edit_enter 且 payload 正确`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-159 startEditing 无效 fenceId 时不记录 fence_edit_enter

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::startEditing 无效 fenceId 时不记录 fence_edit_enter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-160 saveEditing 时记录 fence_edit_save

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::saveEditing 时记录 fence_edit_save`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-161 cancelEditing 时记录 fence_edit_cancel

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::cancelEditing 时记录 fence_edit_cancel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-162 saveEditing 无 session 时不记录事件

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::saveEditing 无 session 时不记录事件`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-163 cancelEditing 无 session 时不记录事件

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_analytics_event_test.dart::cancelEditing 无 session 时不记录事件`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-PLT-169 classLevel_requiresPlatformAdminOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/AnalyticsAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-170 endpoints_haveNoPerMethodOverride

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/AnalyticsAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-171 classLevel_requiresPlatformAdminOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/PortalAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-172 endpoints_haveNoPerMethodOverride

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/analytics/interfaces/admin/PortalAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-283 ensureCurrentAndFuturePartitions_coversAllTablesAndMonitorsDefault

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/application/PartitionMaintenanceServiceTest.java::ensureCurrentAndFuturePartitions_coversAllTablesAndMonitorsDefault`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-HLT-006

### TC-PLT-284 dispatchSendsToEnabledUsersTokensInServerEnvironment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::dispatchSendsToEnabledUsersTokensInServerEnvironment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-PLT-001、REQ-PLT-002

### TC-PLT-285 payloadCarriesAlertIdentityForDeepLink

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::payloadCarriesAlertIdentityForDeepLink`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-PLT-286 disabledSwitchSkipsEverything

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::disabledSwitchSkipsEverything`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-287 userToggleOffFiltersRecipients

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::userToggleOffFiltersRecipients`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-288 invalidTokenReportedByApnsIsReaped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::invalidTokenReportedByApnsIsReaped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-PLT-001、REQ-PLT-002

### TC-PLT-289 vanishedAlertSkipsDispatch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/messaging/push/PushDispatchServiceTest.java::vanishedAlertSkipsDispatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-PLT-290 passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002

### TC-PLT-291 passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002

### TC-PLT-292 noTenantId_passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::noTenantId_passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003

### TC-PLT-293 noFarmId_passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::noFarmId_passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003

### TC-PLT-294 quotaAllowed_passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaAllowed_passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002

### TC-PLT-295 quotaAllowedWithRetention_passesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaAllowedWithRetention_passesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-PLT-001、REQ-PLT-002

### TC-PLT-296 quotaDenied_throwsApiException

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::quotaDenied_throwsApiException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-RCH-001、REQ-RCH-002

### TC-PLT-297 farmIdFromPath_whenAttributeMissing

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::farmIdFromPath_whenAttributeMissing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-IDT-001、REQ-IDT-003

### TC-PLT-298 unknownFeatureKey_usesZeroUsage

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/platform/web/QuotaInterceptorTest.java::unknownFeatureKey_usesZeroUsage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-RCH-001、REQ-RCH-002

### TC-PLT-299 resolvesChineseMessage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::resolvesChineseMessage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-300 resolvesEnglishMessage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::resolvesEnglishMessage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-301 fallsBackToKeyWhenNotFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::fallsBackToKeyWhenNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-302 accessDeniedTranslatesByLocale

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::accessDeniedTranslatesByLocale`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-PLT-303 numericArgsRenderVerbatimWithoutLocaleGrouping

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/MessageResolverTest.java::numericArgsRenderVerbatimWithoutLocaleGrouping`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

