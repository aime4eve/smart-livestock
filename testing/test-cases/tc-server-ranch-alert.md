# 测试用例规格：后端·告警与信号流（ranch alert/signal）

> 用例域：RCH ｜ 用例数：66
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-313 | renders message text | P2 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::renders message text` |
| TC-RCH-314 | shows dismiss button when showDismiss is true and status is ACTIVE | P2 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::shows dismiss button when showDismiss is true and status is ACTIVE` |
| TC-RCH-315 | does not show dismiss when status is not ACTIVE | P2 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::does not show dismiss when status is not ACTIVE` |
| TC-RCH-316 | calls onTap when tapped | P2 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::calls onTap when tapped` |
| TC-RCH-317 | shows status badge for AUTO_RESOLVED | P2 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::shows status badge for AUTO_RESOLVED` |
| TC-RCH-424 | 创建新告警 — 默认 ACTIVE | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldCreateAlert` |
| TC-RCH-425 | 忽略 ACTIVE 告警 → DISMISSED | P1 | REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldDismissActiveAlert` |
| TC-RCH-426 | 自动解除 ACTIVE 告警 → AUTO_RESOLVED | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldAutoResolveActiveAlert` |
| TC-RCH-427 | markRead 调用 readStatusRepository | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldMarkRead` |
| TC-RCH-428 | 拒绝忽略已解除的告警 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldRejectDismissOnDismissedAlert` |
| TC-RCH-429 | 告警不存在时，抛出 RESOURCE_NOT_FOUND | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldThrowResourceNotFoundForMissingAlert` |
| TC-RCH-430 | localize_parsesArgsAndUsesRequestLocale | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_parsesArgsAndUsesRequestLocale` |
| TC-RCH-431 | localize_withoutKeyKeepsLegacyMessage | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_withoutKeyKeepsLegacyMessage` |
| TC-RCH-432 | localize_invalidArgsFallsBackToNoArguments | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_invalidArgsFallsBackToNoArguments` |
| TC-RCH-433 | markRead — 首次标记，写入 read_status，返回 read=true | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::markRead_firstTime_writesStatus` |
| TC-RCH-434 | markRead — 重复标记幂等（ON CONFLICT DO NOTHING），仍返回 read=true | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::markRead_idempotent` |
| TC-RCH-435 | batchRead — 批量标记已读，返回正确计数 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::batchRead_multipleAlerts` |
| TC-RCH-436 | batchRead — 跳过不存在的 alertId | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::batchRead_skipsMissing` |
| TC-RCH-437 | listByFarmPaged — 正确填充 read 字段（多用户隔离） | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::listWithReadStatus_multiUserIsolation` |
| TC-RCH-438 | getAlertWithReadStatus — 单条查询正确返回 read 状态 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::getWithReadStatus` |
| TC-RCH-439 | getAlertWithReadStatus — 未读返回 false | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::getWithReadStatus_unread` |
| TC-RCH-440 | listByFarmPaged — 空列表直接返回空 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::listWithReadStatus_emptyFarm` |
| TC-RCH-441 | 分组计数映射正确，且 严重+警告+提示 ≡ 活跃总数 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::summaryMapping_andReconciliation` |
| TC-RCH-442 | 空牧场：全 0 且加总恒等式成立 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::emptyFarm_allZero` |
| TC-RCH-443 | 结果写入 10s 缓存 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::cachesResult` |
| TC-RCH-444 | markRead 后失效该用户的 summary 缓存 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::markRead_evictsSummaryCache` |
| TC-RCH-445 | criticalFenceBreachIsImmediateAndFenceAnchored | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::criticalFenceBreachIsImmediateAndFenceAnchored` |
| TC-RCH-446 | lowBatteryIsFieldAndDeviceAnchored | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::lowBatteryIsFieldAndDeviceAnchored` |
| TC-RCH-447 | aiWatchWithoutTicketIsObserve | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::aiWatchWithoutTicketIsObserve` |
| TC-RCH-448 | opensOnlyOneActiveTicketWhenSilentOverThreshold | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::opensOnlyOneActiveTicketWhenSilentOverThreshold` |
| TC-RCH-449 | resolvesActiveTicketWhenDeviceReportsAgain | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::resolvesActiveTicketWhenDeviceReportsAgain` |
| TC-RCH-450 | doesNotDuplicateActiveTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::doesNotDuplicateActiveTicket` |
| TC-RCH-469 | recordsOnlyFarmAndEntityChangeHint | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::recordsOnlyFarmAndEntityChangeHint` |
| TC-RCH-470 | rejectsIncompleteChangeHints | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::rejectsIncompleteChangeHints` |
| TC-RCH-471 | eventTypesContainPhaseTwoContract | P1 | REQ-CMC-004、REQ-CMC-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::eventTypesContainPhaseTwoContract` |
| TC-RCH-472 | acceptsNewerFixAndProjectsRevision | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::acceptsNewerFixAndProjectsRevision` |
| TC-RCH-473 | ignoresOlderFix | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::ignoresOlderFix` |
| TC-RCH-474 | rejectsInvalidSourceOrCoordinate | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::rejectsInvalidSourceOrCoordinate` |
| TC-RCH-475 | successfulDispatchMarksEvent | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::successfulDispatchMarksEvent` |
| TC-RCH-476 | failedDispatchIncrementsRetryAndSchedulesBackoff | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::failedDispatchIncrementsRetryAndSchedulesBackoff` |
| TC-RCH-477 | maxRetriesMarksEventFailed | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::maxRetriesMarksEventFailed` |
| TC-RCH-478 | claimContractUsesSkipLocked | P1 | REQ-CMC-004、REQ-CMC-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::claimContractUsesSkipLocked` |
| TC-RCH-479 | rejectsUserWithoutActiveFarmAssignment | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::rejectsUserWithoutActiveFarmAssignment` |
| TC-RCH-480 | cursorZeroPerformsInitialFullSyncWithNestedMetrics | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::cursorZeroPerformsInitialFullSyncWithNestedMetrics` |
| TC-RCH-481 | returnHomeStaysOutOfHealthAndBecomesPresenceSignal | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::returnHomeStaysOutOfHealthAndBecomesPresenceSignal` |
| TC-RCH-482 | unchangedCursorDoesNotBuildMapPayload | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::unchangedCursorDoesNotBuildMapPayload` |
| TC-RCH-483 | aheadCursorUsesDedicatedErrorCode | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::aheadCursorUsesDedicatedErrorCode` |
| TC-RCH-484 | bumpStatusUsesAtomicReturningUpdate | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::bumpStatusUsesAtomicReturningUpdate` |
| TC-RCH-485 | statusAndGeometryBumpsRecordEntityChangeHints | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::statusAndGeometryBumpsRecordEntityChangeHints` |
| TC-RCH-486 | rejectsAheadCursorWithDedicatedException | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::rejectsAheadCursorWithDedicatedException` |
| TC-RCH-487 | rejectsStaleCursorWithDedicatedException | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::rejectsStaleCursorWithDedicatedException` |
| TC-RCH-488 | allZeroMapCursorIsAlwaysInitialFullSync | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::allZeroMapCursorIsAlwaysInitialFullSync` |
| TC-RCH-489 | connectsValidTicketAndEnforcesUserFarmLimit | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamHubTest.java::connectsValidTicketAndEnforcesUserFarmLimit` |
| TC-RCH-490 | highFrequencyFarmEventsMergeIntoOneNotification | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamNotificationServiceTest.java::highFrequencyFarmEventsMergeIntoOneNotification` |
| TC-RCH-491 | noSubscribersDoesNotReadRevisionsOrScheduleWork | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamNotificationServiceTest.java::noSubscribersDoesNotReadRevisionsOrScheduleWork` |
| TC-RCH-492 | validTicketConsumesOnceAndBindsUserTenantFarm | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::validTicketConsumesOnceAndBindsUserTenantFarm` |
| TC-RCH-493 | crossFarmReplayIsRejected | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::crossFarmReplayIsRejected` |
| TC-RCH-494 | expiredTicketIsRejected | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::expiredTicketIsRejected` |
| TC-RCH-495 | browserReconnectUsesCookieWithoutReusingConsumedTicket | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::browserReconnectUsesCookieWithoutReusingConsumedTicket` |
| TC-RCH-496 | shouldCreateActiveAlert | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldCreateActiveAlert` |
| TC-RCH-497 | shouldTransitionActiveToDismissed | P1 | REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldTransitionActiveToDismissed` |
| TC-RCH-498 | shouldTransitionActiveToAutoResolved | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldTransitionActiveToAutoResolved` |
| TC-RCH-499 | shouldAutoResolveBeIdempotent | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldAutoResolveBeIdempotent` |
| TC-RCH-500 | shouldRejectDismissOnDismissed | P1 | REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldRejectDismissOnDismissed` |
| TC-RCH-501 | shouldRejectDismissOnAutoResolved | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldRejectDismissOnAutoResolved` |
| TC-RCH-546 | saveWritesGeneratedIdBackToCallerOwnedAggregate | P1 | REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/JpaAlertRepositoryImplTest.java::saveWritesGeneratedIdBackToCallerOwnedAggregate` |

## 用例明细（初稿模板）

### TC-RCH-313 renders message text

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：AlertCard
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::renders message text`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-314 shows dismiss button when showDismiss is true and status is ACTIVE

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::shows dismiss button when showDismiss is true and status is ACTIVE`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-315 does not show dismiss when status is not ACTIVE

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::does not show dismiss when status is not ACTIVE`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-316 calls onTap when tapped

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::calls onTap when tapped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-317 shows status badge for AUTO_RESOLVED

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/alert_card_test.dart::shows status badge for AUTO_RESOLVED`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-424 创建新告警 — 默认 ACTIVE

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldCreateAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-425 忽略 ACTIVE 告警 → DISMISSED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldDismissActiveAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002

### TC-RCH-426 自动解除 ACTIVE 告警 → AUTO_RESOLVED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldAutoResolveActiveAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-427 markRead 调用 readStatusRepository

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldMarkRead`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-428 拒绝忽略已解除的告警

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldRejectDismissOnDismissedAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002

### TC-RCH-429 告警不存在时，抛出 RESOURCE_NOT_FOUND

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertApplicationServiceTest.java::shouldThrowResourceNotFoundForMissingAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-430 localize_parsesArgsAndUsesRequestLocale

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_parsesArgsAndUsesRequestLocale`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-431 localize_withoutKeyKeepsLegacyMessage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_withoutKeyKeepsLegacyMessage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-432 localize_invalidArgsFallsBackToNoArguments

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertMessageLocalizerTest.java::localize_invalidArgsFallsBackToNoArguments`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-433 markRead — 首次标记，写入 read_status，返回 read=true

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::markRead_firstTime_writesStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-434 markRead — 重复标记幂等（ON CONFLICT DO NOTHING），仍返回 read=true

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::markRead_idempotent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-435 batchRead — 批量标记已读，返回正确计数

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::batchRead_multipleAlerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-436 batchRead — 跳过不存在的 alertId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::batchRead_skipsMissing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-437 listByFarmPaged — 正确填充 read 字段（多用户隔离）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::listWithReadStatus_multiUserIsolation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003

### TC-RCH-438 getAlertWithReadStatus — 单条查询正确返回 read 状态

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::getWithReadStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-439 getAlertWithReadStatus — 未读返回 false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::getWithReadStatus_unread`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-440 listByFarmPaged — 空列表直接返回空

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertReadStatusTest.java::listWithReadStatus_emptyFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003

### TC-RCH-441 分组计数映射正确，且 严重+警告+提示 ≡ 活跃总数

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::summaryMapping_andReconciliation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-442 空牧场：全 0 且加总恒等式成立

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::emptyFarm_allZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003

### TC-RCH-443 结果写入 10s 缓存

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::cachesResult`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-444 markRead 后失效该用户的 summary 缓存

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertSummaryTest.java::markRead_evictsSummaryCache`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-445 criticalFenceBreachIsImmediateAndFenceAnchored

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::criticalFenceBreachIsImmediateAndFenceAnchored`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-446 lowBatteryIsFieldAndDeviceAnchored

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::lowBatteryIsFieldAndDeviceAnchored`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-447 aiWatchWithoutTicketIsObserve

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/AlertWorkbenchServiceTest.java::aiWatchWithoutTicketIsObserve`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-448 opensOnlyOneActiveTicketWhenSilentOverThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::opensOnlyOneActiveTicketWhenSilentOverThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-449 resolvesActiveTicketWhenDeviceReportsAgain

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::resolvesActiveTicketWhenDeviceReportsAgain`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-450 doesNotDuplicateActiveTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/DeviceOfflineAlertSchedulerTest.java::doesNotDuplicateActiveTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-469 recordsOnlyFarmAndEntityChangeHint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::recordsOnlyFarmAndEntityChangeHint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-470 rejectsIncompleteChangeHints

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::rejectsIncompleteChangeHints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-471 eventTypesContainPhaseTwoContract

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalEventOutboxServiceTest.java::eventTypesContainPhaseTwoContract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-PLT-001、REQ-PLT-002

### TC-RCH-472 acceptsNewerFixAndProjectsRevision

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::acceptsNewerFixAndProjectsRevision`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-473 ignoresOlderFix

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::ignoresOlderFix`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-474 rejectsInvalidSourceOrCoordinate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalLocationProjectionServiceTest.java::rejectsInvalidSourceOrCoordinate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-475 successfulDispatchMarksEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::successfulDispatchMarksEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-476 failedDispatchIncrementsRetryAndSchedulesBackoff

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::failedDispatchIncrementsRetryAndSchedulesBackoff`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-477 maxRetriesMarksEventFailed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::maxRetriesMarksEventFailed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-478 claimContractUsesSkipLocked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalOutboxDispatcherTest.java::claimContractUsesSkipLocked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-PLT-001、REQ-PLT-002

### TC-RCH-479 rejectsUserWithoutActiveFarmAssignment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::rejectsUserWithoutActiveFarmAssignment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-480 cursorZeroPerformsInitialFullSyncWithNestedMetrics

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::cursorZeroPerformsInitialFullSyncWithNestedMetrics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-481 returnHomeStaysOutOfHealthAndBecomesPresenceSignal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::returnHomeStaysOutOfHealthAndBecomesPresenceSignal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-RCH-482 unchangedCursorDoesNotBuildMapPayload

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::unchangedCursorDoesNotBuildMapPayload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-483 aheadCursorUsesDedicatedErrorCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalQueryServiceTest.java::aheadCursorUsesDedicatedErrorCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-484 bumpStatusUsesAtomicReturningUpdate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::bumpStatusUsesAtomicReturningUpdate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-485 statusAndGeometryBumpsRecordEntityChangeHints

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::statusAndGeometryBumpsRecordEntityChangeHints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-486 rejectsAheadCursorWithDedicatedException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::rejectsAheadCursorWithDedicatedException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-487 rejectsStaleCursorWithDedicatedException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::rejectsStaleCursorWithDedicatedException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-488 allZeroMapCursorIsAlwaysInitialFullSync

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalRevisionServiceTest.java::allZeroMapCursorIsAlwaysInitialFullSync`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-489 connectsValidTicketAndEnforcesUserFarmLimit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamHubTest.java::connectsValidTicketAndEnforcesUserFarmLimit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-490 highFrequencyFarmEventsMergeIntoOneNotification

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamNotificationServiceTest.java::highFrequencyFarmEventsMergeIntoOneNotification`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-491 noSubscribersDoesNotReadRevisionsOrScheduleWork

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamNotificationServiceTest.java::noSubscribersDoesNotReadRevisionsOrScheduleWork`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-492 validTicketConsumesOnceAndBindsUserTenantFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::validTicketConsumesOnceAndBindsUserTenantFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-493 crossFarmReplayIsRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::crossFarmReplayIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-RCH-494 expiredTicketIsRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::expiredTicketIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-495 browserReconnectUsesCookieWithoutReusingConsumedTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/signal/SignalStreamTicketServiceTest.java::browserReconnectUsesCookieWithoutReusingConsumedTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-496 shouldCreateActiveAlert

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldCreateActiveAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-497 shouldTransitionActiveToDismissed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldTransitionActiveToDismissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002

### TC-RCH-498 shouldTransitionActiveToAutoResolved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldTransitionActiveToAutoResolved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-499 shouldAutoResolveBeIdempotent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldAutoResolveBeIdempotent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-500 shouldRejectDismissOnDismissed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldRejectDismissOnDismissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-PLT-001、REQ-PLT-002

### TC-RCH-501 shouldRejectDismissOnAutoResolved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java::shouldRejectDismissOnAutoResolved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

### TC-RCH-546 saveWritesGeneratedIdBackToCallerOwnedAggregate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/JpaAlertRepositoryImplTest.java::saveWritesGeneratedIdBackToCallerOwnedAggregate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-RCH-001、REQ-RCH-002

