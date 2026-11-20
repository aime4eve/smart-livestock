# 测试用例规格：后端·电子围栏（ranch fence）

> 用例域：RCH ｜ 用例数：93
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-307 | signal fence with matching overview metadata renders the source card | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::signal fence with matching overview metadata renders the source card` |
| TC-RCH-308 | signal fence without matching overview fence hides the source card | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::signal fence without matching overview fence hides the source card` |
| TC-RCH-309 | buffer layer shows while a fence is selected (pumpRanchPage  | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::buffer layer shows while a fence is selected (pumpRanchPage ` |
| TC-RCH-310 | buffer layer hides after deselecting the fence | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::buffer layer hides after deselecting the fence` |
| TC-RCH-311 | selected fence renders the band from the overview-merged  | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::selected fence renders the band from the overview-merged ` |
| TC-RCH-312 | overview fence without a buffer ring skips the band entirely | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::overview fence without a buffer ring skips the band entirely` |
| TC-RCH-321 | renders breach and approach counts when alerts exist | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::renders breach and approach counts when alerts exist` |
| TC-RCH-322 | renders nothing when both counts are zero | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::renders nothing when both counts are zero` |
| TC-RCH-323 | calls onTap when tapped | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::calls onTap when tapped` |
| TC-RCH-324 | renders band from backend buffer ring with fence hole | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::renders band from backend buffer ring with fence hole` |
| TC-RCH-325 | skips band when backend buffer polygon is absent | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::skips band when backend buffer polygon is absent` |
| TC-RCH-326 | skips inactive fences | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::skips inactive fences` |
| TC-RCH-347 | tapping a fence card reports selection | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `Mobile/mobile_app/test/ranch_fence_tab_select_test.dart::tapping a fence card reports selection` |
| TC-RCH-348 | deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence` |
| TC-RCH-349 | deleteFence_keepAlerts_detachesReferencesInsteadOfDeleting | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_keepAlerts_detachesReferencesInsteadOfDeleting` |
| TC-RCH-350 | deleteFence_missingFence_throwsNotFoundWithoutSideEffects | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_missingFence_throwsNotFoundWithoutSideEffects` |
| TC-RCH-351 | createFence_withGenerationMetadata_serializesJsonOntoFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withGenerationMetadata_serializesJsonOntoFence` |
| TC-RCH-352 | createFence_withoutGenerationMetadata_staysNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withoutGenerationMetadata_staysNull` |
| TC-RCH-353 | createFence_withShape_persistsShapeAndEchoesItBack | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withShape_persistsShapeAndEchoesItBack` |
| TC-RCH-354 | createFence_withoutShape_defaultsToPolygon | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withoutShape_defaultsToPolygon` |
| TC-RCH-355 | createFence_withUnknownShape_throwsValidation | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withUnknownShape_throwsValidation` |
| TC-RCH-356 | createFence_withUnknownFenceRole_throwsValidation | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withUnknownFenceRole_throwsValidation` |
| TC-RCH-357 | createFence_withBoundaryRole_persistsRole | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withBoundaryRole_persistsRole` |
| TC-RCH-358 | updateFence_withShape_updatesStoredShape | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withShape_updatesStoredShape` |
| TC-RCH-359 | updateFence_withoutShape_keepsStoredShape | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withoutShape_keepsStoredShape` |
| TC-RCH-360 | updateFence_withUnknownShape_throwsValidation | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withUnknownShape_throwsValidation` |
| TC-RCH-361 | source_rejectsEmptyAndTooManyDevices | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsEmptyAndTooManyDevices` |
| TC-RCH-362 | source_rejectsNullDeviceIds | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsNullDeviceIds` |
| TC-RCH-363 | source_rejectsDeviceNotOwnedByFarm | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsDeviceNotOwnedByFarm` |
| TC-RCH-364 | source_rejectsNonTrackerDevice | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsNonTrackerDevice` |
| TC-RCH-365 | source_rejectsInvertedAndOverlongRange | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsInvertedAndOverlongRange` |
| TC-RCH-366 | source_acceptsExactlyThirtyDays | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_acceptsExactlyThirtyDays` |
| TC-RCH-367 | source_strideCeilsAtFiveThousand | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_strideCeilsAtFiveThousand` |
| TC-RCH-368 | source_exactlyFiveThousandKeepsStrideOne | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_exactlyFiveThousandKeepsStrideOne` |
| TC-RCH-369 | source_zeroRawPointsSkipsSampling | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_zeroRawPointsSkipsSampling` |
| TC-RCH-370 | source_countsAllDevicesBeforeSamplingSerially | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_countsAllDevicesBeforeSamplingSerially` |
| TC-RCH-371 | source_mergesDevicePointsAscendingByRecordedAt | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_mergesDevicePointsAscendingByRecordedAt` |
| TC-RCH-372 | source_keepsNullAccuracyAsNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_keepsNullAccuracyAsNull` |
| TC-RCH-373 | candidates_assemblesDevicesAndQuotaFromPorts | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_assemblesDevicesAndQuotaFromPorts` |
| TC-RCH-374 | candidates_unlimitedTierPassesNullLimitThrough | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_unlimitedTierPassesNullLimitThrough` |
| TC-RCH-375 | candidates_fullQuotaStillReportsBothNumbers | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_fullQuotaStillReportsBothNumbers` |
| TC-RCH-376 | parsesTrackWithCleaningCountersAndDefaults | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesTrackWithCleaningCountersAndDefaults` |
| TC-RCH-377 | fallsBackToFileNameWhenNoNameElement | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::fallsBackToFileNameWhenNoNameElement` |
| TC-RCH-378 | mergesMultipleSegmentsWithWarning | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::mergesMultipleSegmentsWithWarning` |
| TC-RCH-379 | parsesNamespacedGpx | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesNamespacedGpx` |
| TC-RCH-380 | parsesRoutePoints | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesRoutePoints` |
| TC-RCH-381 | rejectsWaypointsOnlyFile | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsWaypointsOnlyFile` |
| TC-RCH-382 | rejectsOversizedTrack | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsOversizedTrack` |
| TC-RCH-383 | rejectsMalformedXml | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsMalformedXml` |
| TC-RCH-384 | rejectsXxePayload | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsXxePayload` |
| TC-RCH-385 | decimatesTrackPointsForTransport | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::decimatesTrackPointsForTransport` |
| TC-RCH-386 | parsesRtkXlsxTrackWithCleaningCounters | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesRtkXlsxTrackWithCleaningCounters` |
| TC-RCH-387 | xlsxMultipleDataRowsWarnsAndTakesFirst | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxMultipleDataRowsWarnsAndTakesFirst` |
| TC-RCH-388 | xlsxWithoutCoordinatesRejected | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxWithoutCoordinatesRejected` |
| TC-RCH-389 | xlsxCorruptFileRejected | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxCorruptFileRejected` |
| TC-RCH-421 | from_nullMetadata_echoesNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_nullMetadata_echoesNull` |
| TC-RCH-422 | from_validMetadataJson_echoesAsMap | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_validMetadataJson_echoesAsMap` |
| TC-RCH-423 | from_malformedMetadataJson_degradesToNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_malformedMetadataJson_degradesToNull` |
| TC-RCH-502 | shouldContainPointInsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldContainPointInsideFence` |
| TC-RCH-503 | shouldNotContainPointOutsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldNotContainPointOutsideFence` |
| TC-RCH-504 | shouldContainPointOnEdge | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldContainPointOnEdge` |
| TC-RCH-505 | shouldDisableAndEnableFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldDisableAndEnableFence` |
| TC-RCH-506 | updateFence_keepsVersion_whenExpectedMatches | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_keepsVersion_whenExpectedMatches` |
| TC-RCH-507 | updateFence_rejectsStaleVersion | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_rejectsStaleVersion` |
| TC-RCH-508 | updateFence_skipsCheck_whenExpectedVersionNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_skipsCheck_whenExpectedVersionNull` |
| TC-RCH-516 | rectangleTemplateAreaMatchesPlanarExpectation | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::rectangleTemplateAreaMatchesPlanarExpectation` |
| TC-RCH-517 | windingDirectionDoesNotChangeTheArea | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::windingDirectionDoesNotChangeTheArea` |
| TC-RCH-518 | degenerateRingsYieldZero | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::degenerateRingsYieldZero` |
| TC-RCH-519 | shouldDetectBreachWhenOutsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectBreachWhenOutsideFence` |
| TC-RCH-520 | shouldNotDetectBreachWhenInsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectBreachWhenInsideFence` |
| TC-RCH-521 | shouldFindBreachedFenceFromMultiple | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldFindBreachedFenceFromMultiple` |
| TC-RCH-522 | shouldSkipInactiveFencesWhenFindingBreached | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldSkipInactiveFencesWhenFindingBreached` |
| TC-RCH-523 | shouldDetectApproachWhenInBufferButOutsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectApproachWhenInBufferButOutsideFence` |
| TC-RCH-524 | shouldNotDetectApproachWhenInsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenInsideFence` |
| TC-RCH-525 | shouldNotDetectApproachWhenBufferNotSet | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenBufferNotSet` |
| TC-RCH-526 | shouldNotDetectApproachWhenFarOutsideBuffer | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenFarOutsideBuffer` |
| TC-RCH-527 | shouldDetectReturnToSafeZone | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectReturnToSafeZone` |
| TC-RCH-528 | shouldNotDetectReturnWhenStillOutside | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectReturnWhenStillOutside` |
| TC-RCH-529 | shouldFindApproachingFencesFromMultiple | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldFindApproachingFencesFromMultiple` |
| TC-RCH-547 | toJpaEntity_withGenerationMetadata_jsonRoundTripsThroughDomain | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::toJpaEntity_withGenerationMetadata_jsonRoundTripsThroughDomain` |
| TC-RCH-548 | toJpaEntity_withoutGenerationMetadata_staysNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::toJpaEntity_withoutGenerationMetadata_staysNull` |
| TC-RCH-549 | updateEntity_preservesGenerationMetadata | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::updateEntity_preservesGenerationMetadata` |
| TC-RCH-550 | updateEntity_preservesNullGenerationMetadata | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::updateEntity_preservesNullGenerationMetadata` |
| TC-RCH-551 | ownerListsTrackDraftCandidates | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerListsTrackDraftCandidates` |
| TC-RCH-552 | ownerLoadsTrackDraftSource | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerLoadsTrackDraftSource` |
| TC-RCH-553 | ownerCreatesFenceWithGenerationMetadata | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerCreatesFenceWithGenerationMetadata` |
| TC-RCH-554 | workerIsDeniedTrackDraftCandidates | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedTrackDraftCandidates` |
| TC-RCH-555 | workerIsDeniedTrackDraftSource | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedTrackDraftSource` |
| TC-RCH-556 | workerIsDeniedFenceCreation | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedFenceCreation` |
| TC-RCH-557 | unknownFarmYieldsNotFound | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::unknownFarmYieldsNotFound` |
| TC-RCH-558 | crossTenantFarmYieldsForbidden | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::crossTenantFarmYieldsForbidden` |
| TC-RCH-559 | candidatesDaysOutOfRangeIsRejectedAs400 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::candidatesDaysOutOfRangeIsRejectedAs400` |
| TC-RCH-560 | trackDraftSourceWithoutDeviceIdsIsRejectedAs400 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::trackDraftSourceWithoutDeviceIdsIsRejectedAs400` |

## 用例明细（初稿模板）

### TC-RCH-307 signal fence with matching overview metadata renders the source card

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::signal fence with matching overview metadata renders the source card`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001

### TC-RCH-308 signal fence without matching overview fence hides the source card

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::signal fence without matching overview fence hides the source card`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001

### TC-RCH-309 buffer layer shows while a fence is selected (pumpRanchPage 

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::buffer layer shows while a fence is selected (pumpRanchPage `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-310 buffer layer hides after deselecting the fence

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::buffer layer hides after deselecting the fence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-311 selected fence renders the band from the overview-merged 

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::selected fence renders the band from the overview-merged `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-312 overview fence without a buffer ring skips the band entirely

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_page_fence_source_card_test.dart::overview fence without a buffer ring skips the band entirely`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-321 renders breach and approach counts when alerts exist

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：FenceBreachBanner
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::renders breach and approach counts when alerts exist`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-322 renders nothing when both counts are zero

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::renders nothing when both counts are zero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-323 calls onTap when tapped

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_breach_banner_test.dart::calls onTap when tapped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-324 renders band from backend buffer ring with fence hole

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::renders band from backend buffer ring with fence hole`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-325 skips band when backend buffer polygon is absent

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::skips band when backend buffer polygon is absent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-326 skips inactive fences

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/fence_buffer_layer_test.dart::skips inactive fences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-347 tapping a fence card reports selection

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/ranch_fence_tab_select_test.dart::tapping a fence card reports selection`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-348 deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_withAlerts_deletesReadStatusAlertsZonesAndFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-349 deleteFence_keepAlerts_detachesReferencesInsteadOfDeleting

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_keepAlerts_detachesReferencesInsteadOfDeleting`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-350 deleteFence_missingFence_throwsNotFoundWithoutSideEffects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::deleteFence_missingFence_throwsNotFoundWithoutSideEffects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-351 createFence_withGenerationMetadata_serializesJsonOntoFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withGenerationMetadata_serializesJsonOntoFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-352 createFence_withoutGenerationMetadata_staysNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withoutGenerationMetadata_staysNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-353 createFence_withShape_persistsShapeAndEchoesItBack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withShape_persistsShapeAndEchoesItBack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-354 createFence_withoutShape_defaultsToPolygon

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withoutShape_defaultsToPolygon`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-355 createFence_withUnknownShape_throwsValidation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withUnknownShape_throwsValidation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-356 createFence_withUnknownFenceRole_throwsValidation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withUnknownFenceRole_throwsValidation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004

### TC-RCH-357 createFence_withBoundaryRole_persistsRole

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::createFence_withBoundaryRole_persistsRole`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004

### TC-RCH-358 updateFence_withShape_updatesStoredShape

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withShape_updatesStoredShape`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-359 updateFence_withoutShape_keepsStoredShape

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withoutShape_keepsStoredShape`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-360 updateFence_withUnknownShape_throwsValidation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceApplicationServiceTest.java::updateFence_withUnknownShape_throwsValidation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-361 source_rejectsEmptyAndTooManyDevices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsEmptyAndTooManyDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-362 source_rejectsNullDeviceIds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsNullDeviceIds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-363 source_rejectsDeviceNotOwnedByFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsDeviceNotOwnedByFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-RCH-364 source_rejectsNonTrackerDevice

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsNonTrackerDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-365 source_rejectsInvertedAndOverlongRange

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_rejectsInvertedAndOverlongRange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-366 source_acceptsExactlyThirtyDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_acceptsExactlyThirtyDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-367 source_strideCeilsAtFiveThousand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_strideCeilsAtFiveThousand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-368 source_exactlyFiveThousandKeepsStrideOne

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_exactlyFiveThousandKeepsStrideOne`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-369 source_zeroRawPointsSkipsSampling

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_zeroRawPointsSkipsSampling`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-370 source_countsAllDevicesBeforeSamplingSerially

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_countsAllDevicesBeforeSamplingSerially`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-371 source_mergesDevicePointsAscendingByRecordedAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_mergesDevicePointsAscendingByRecordedAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-372 source_keepsNullAccuracyAsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::source_keepsNullAccuracyAsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-373 candidates_assemblesDevicesAndQuotaFromPorts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_assemblesDevicesAndQuotaFromPorts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-RCH-374 candidates_unlimitedTierPassesNullLimitThrough

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_unlimitedTierPassesNullLimitThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-RCH-375 candidates_fullQuotaStillReportsBothNumbers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackDraftServiceTest.java::candidates_fullQuotaStillReportsBothNumbers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-RCH-376 parsesTrackWithCleaningCountersAndDefaults

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesTrackWithCleaningCountersAndDefaults`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-377 fallsBackToFileNameWhenNoNameElement

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::fallsBackToFileNameWhenNoNameElement`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-378 mergesMultipleSegmentsWithWarning

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::mergesMultipleSegmentsWithWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-379 parsesNamespacedGpx

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesNamespacedGpx`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-380 parsesRoutePoints

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesRoutePoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-381 rejectsWaypointsOnlyFile

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsWaypointsOnlyFile`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-382 rejectsOversizedTrack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsOversizedTrack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-383 rejectsMalformedXml

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsMalformedXml`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-384 rejectsXxePayload

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::rejectsXxePayload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-385 decimatesTrackPointsForTransport

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::decimatesTrackPointsForTransport`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-386 parsesRtkXlsxTrackWithCleaningCounters

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::parsesRtkXlsxTrackWithCleaningCounters`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-387 xlsxMultipleDataRowsWarnsAndTakesFirst

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxMultipleDataRowsWarnsAndTakesFirst`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-388 xlsxWithoutCoordinatesRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxWithoutCoordinatesRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-389 xlsxCorruptFileRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/FenceTrackParseServiceTest.java::xlsxCorruptFileRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-421 from_nullMetadata_echoesNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_nullMetadata_echoesNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-422 from_validMetadataJson_echoesAsMap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_validMetadataJson_echoesAsMap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-423 from_malformedMetadataJson_degradesToNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/dto/FenceDtoTest.java::from_malformedMetadataJson_degradesToNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-502 shouldContainPointInsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldContainPointInsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-503 shouldNotContainPointOutsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldNotContainPointOutsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-504 shouldContainPointOnEdge

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldContainPointOnEdge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-505 shouldDisableAndEnableFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java::shouldDisableAndEnableFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-506 updateFence_keepsVersion_whenExpectedMatches

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_keepsVersion_whenExpectedMatches`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-507 updateFence_rejectsStaleVersion

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_rejectsStaleVersion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-508 updateFence_skipsCheck_whenExpectedVersionNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/FenceVersionTest.java::updateFence_skipsCheck_whenExpectedVersionNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-516 rectangleTemplateAreaMatchesPlanarExpectation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::rectangleTemplateAreaMatchesPlanarExpectation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-RCH-517 windingDirectionDoesNotChangeTheArea

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::windingDirectionDoesNotChangeTheArea`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-518 degenerateRingsYieldZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceAreaCalculatorTest.java::degenerateRingsYieldZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-519 shouldDetectBreachWhenOutsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectBreachWhenOutsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-520 shouldNotDetectBreachWhenInsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectBreachWhenInsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-521 shouldFindBreachedFenceFromMultiple

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldFindBreachedFenceFromMultiple`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-522 shouldSkipInactiveFencesWhenFindingBreached

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldSkipInactiveFencesWhenFindingBreached`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-523 shouldDetectApproachWhenInBufferButOutsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectApproachWhenInBufferButOutsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-524 shouldNotDetectApproachWhenInsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenInsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-525 shouldNotDetectApproachWhenBufferNotSet

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenBufferNotSet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-526 shouldNotDetectApproachWhenFarOutsideBuffer

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectApproachWhenFarOutsideBuffer`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-527 shouldDetectReturnToSafeZone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldDetectReturnToSafeZone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-528 shouldNotDetectReturnWhenStillOutside

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldNotDetectReturnWhenStillOutside`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-529 shouldFindApproachingFencesFromMultiple

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java::shouldFindApproachingFencesFromMultiple`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-547 toJpaEntity_withGenerationMetadata_jsonRoundTripsThroughDomain

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::toJpaEntity_withGenerationMetadata_jsonRoundTripsThroughDomain`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-548 toJpaEntity_withoutGenerationMetadata_staysNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::toJpaEntity_withoutGenerationMetadata_staysNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-549 updateEntity_preservesGenerationMetadata

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::updateEntity_preservesGenerationMetadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-550 updateEntity_preservesNullGenerationMetadata

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapperTest.java::updateEntity_preservesNullGenerationMetadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-551 ownerListsTrackDraftCandidates

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerListsTrackDraftCandidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-552 ownerLoadsTrackDraftSource

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerLoadsTrackDraftSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-553 ownerCreatesFenceWithGenerationMetadata

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::ownerCreatesFenceWithGenerationMetadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-554 workerIsDeniedTrackDraftCandidates

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedTrackDraftCandidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-555 workerIsDeniedTrackDraftSource

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedTrackDraftSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-556 workerIsDeniedFenceCreation

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::workerIsDeniedFenceCreation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-557 unknownFarmYieldsNotFound

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::unknownFarmYieldsNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-RCH-558 crossTenantFarmYieldsForbidden

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::crossTenantFarmYieldsForbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-RCH-559 candidatesDaysOutOfRangeIsRejectedAs400

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::candidatesDaysOutOfRangeIsRejectedAs400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

### TC-RCH-560 trackDraftSourceWithoutDeviceIdsIsRejectedAs400

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/FenceControllerTest.java::trackDraftSourceWithoutDeviceIdsIsRejectedAs400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-001

