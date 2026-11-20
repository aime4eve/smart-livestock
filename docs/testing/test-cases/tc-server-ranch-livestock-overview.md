# 测试用例规格：后端·牲畜档案与牧场总览

> 用例域：RCH ｜ 用例数：135
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-261 | tap cycles peek → half → full → half → peek | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::tap cycles peek → half → full → half → peek` |
| TC-RCH-262 | drag down from full → half → peek | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag down from full → half → peek` |
| TC-RCH-263 | drag up from peek → half → full | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag up from peek → half → full` |
| TC-RCH-264 | drag direction syncs with subsequent taps | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag direction syncs with subsequent taps` |
| TC-RCH-265 | OPEN tiles render the data cards (fever pill + calving foot) | P1 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-003、REQ-HLT-005 | `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::OPEN tiles render the data cards (fever pill + calving foot)` |
| TC-RCH-266 | LOCKED tiles render the lock pill + upgrade foot with the name kept | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::LOCKED tiles render the lock pill + upgrade foot with the name kept` |
| TC-RCH-267 | HIDDEN tiles are dropped entirely (no empty slot) | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::HIDDEN tiles are dropped entirely (no empty slot)` |
| TC-RCH-268 | OPEN calving tile navigates to the calving predictions page | P1 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::OPEN calving tile navigates to the calving predictions page` |
| TC-RCH-269 | LOCKED tile navigates to the scene-locked page with scene key | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::LOCKED tile navigates to the scene-locked page with scene key` |
| TC-RCH-270 | NORMAL returns success green | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::NORMAL returns success green` |
| TC-RCH-271 | WARNING + FEVER returns danger red | P2 | REQ-HLT-003、REQ-RCH-002、REQ-RCH-006、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + FEVER returns danger red` |
| TC-RCH-272 | CRITICAL + FEVER returns danger red | P2 | REQ-HLT-003、REQ-RCH-002、REQ-RCH-006、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::CRITICAL + FEVER returns danger red` |
| TC-RCH-273 | WARNING + DIGESTIVE returns warning orange | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + DIGESTIVE returns warning orange` |
| TC-RCH-274 | CRITICAL + DIGESTIVE returns warning orange | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::CRITICAL + DIGESTIVE returns warning orange` |
| TC-RCH-275 | WARNING + ESTRUS returns estrus pink | P2 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + ESTRUS returns estrus pink` |
| TC-RCH-276 | WATCH + CALVING_WARNING returns warning orange, not danger | P2 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WATCH + CALVING_WARNING returns warning orange, not danger` |
| TC-RCH-277 | WARNING + EPIDEMIC returns info blue | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + EPIDEMIC returns info blue` |
| TC-RCH-278 | abnormal with unknown alert type returns danger | P2 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::abnormal with unknown alert type returns danger` |
| TC-RCH-279 | abnormal with empty alert returns danger | P2 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::abnormal with empty alert returns danger` |
| TC-RCH-280 | return home does not turn a normal marker red | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::return home does not turn a normal marker red` |
| TC-RCH-281 | position freshness controls marker opacity | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::position freshness controls marker opacity` |
| TC-RCH-282 | renders livestock code label | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::renders livestock code label` |
| TC-RCH-283 | handles empty code gracefully | P2 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::handles empty code gracefully` |
| TC-RCH-284 | fromJson 正确解析完整响应 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::fromJson 正确解析完整响应` |
| TC-RCH-285 | livestockMarkers healthStatus 映射 NORMAL/WARNING/CRITICAL | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::livestockMarkers healthStatus 映射 NORMAL/WARNING/CRITICAL` |
| TC-RCH-286 | RanchFenceData 颜色解析支持多种格式 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchFenceData 颜色解析支持多种格式` |
| TC-RCH-287 | 空列表安全 — fences/markers/alerts 为空不抛异常 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::空列表安全 — fences/markers/alerts 为空不抛异常` |
| TC-RCH-288 | null 字段兜底为默认值 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::null 字段兜底为默认值` |
| TC-RCH-289 | RanchAlertData 类型解析 | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchAlertData 类型解析` |
| TC-RCH-290 | RanchPendingTask 完整性 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchPendingTask 完整性` |
| TC-RCH-291 | parses inFenceRate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses inFenceRate` |
| TC-RCH-292 | inFenceRate is null when missing | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::inFenceRate is null when missing` |
| TC-RCH-293 | parses read field | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses read field` |
| TC-RCH-294 | read defaults to false | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::read defaults to false` |
| TC-RCH-295 | parses resolvedType and resolvedAt | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses resolvedType and resolvedAt` |
| TC-RCH-296 | copyWith works | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::copyWith works` |
| TC-RCH-297 | parses fence and health summaries | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses fence and health summaries` |
| TC-RCH-298 | summaries default to empty map | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::summaries default to empty map` |
| TC-RCH-299 | parses from JSON | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses from JSON` |
| TC-RCH-300 | updates alerts list | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::updates alerts list` |
| TC-RCH-301 | parses calving counts and three-state gating | P1 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses calving counts and three-state gating` |
| TC-RCH-302 | unknown gating value falls back to locked (fail closed) | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::unknown gating value falls back to locked (fail closed)` |
| TC-RCH-303 | missing gating object means all open (legacy payload) | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing gating object means all open (legacy payload)` |
| TC-RCH-304 | missing gating field inside the object locks that scene | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing gating field inside the object locks that scene` |
| TC-RCH-305 | parses backend bufferPolygon and bufferDistance | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses backend bufferPolygon and bufferDistance` |
| TC-RCH-306 | missing bufferPolygon degrades to empty, distance defaults to 50 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing bufferPolygon degrades to empty, distance defaults to 50` |
| TC-RCH-318 | shows collapsed by default with count | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::shows collapsed by default with count` |
| TC-RCH-319 | expands on tap to show items | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::expands on tap to show items` |
| TC-RCH-320 | renders nothing when alerts empty | P2 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::renders nothing when alerts empty` |
| TC-RCH-327 | renders title and count when alertCount > 0 | P2 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::renders title and count when alertCount > 0` |
| TC-RCH-328 | does not show count badge when alertCount is 0 | P2 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::does not show count badge when alertCount is 0` |
| TC-RCH-329 | calls onTap when tapped | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::calls onTap when tapped` |
| TC-RCH-390 | shouldCreateLivestockWithAllFields | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldCreateLivestockWithAllFields` |
| TC-RCH-391 | shouldNormalizeLowercaseBreedAndGender | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldNormalizeLowercaseBreedAndGender` |
| TC-RCH-392 | shouldDefaultBlankBreedToOther | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldDefaultBlankBreedToOther` |
| TC-RCH-393 | shouldRejectUnknownBreedWithValidationError | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectUnknownBreedWithValidationError` |
| TC-RCH-394 | shouldRejectInvalidGenderWithValidationError | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectInvalidGenderWithValidationError` |
| TC-RCH-395 | shouldRejectDuplicateLivestockCode | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectDuplicateLivestockCode` |
| TC-RCH-396 | shouldUpdateLivestockFields | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldUpdateLivestockFields` |
| TC-RCH-397 | shouldRejectUpdateWithDuplicateCode | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectUpdateWithDuplicateCode` |
| TC-RCH-398 | shouldCascadeUninstallDevicesOnDelete | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldCascadeUninstallDevicesOnDelete` |
| TC-RCH-399 | detailCarriesMarkedSourceWhenLivestockIsMarked | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailCarriesMarkedSourceWhenLivestockIsMarked` |
| TC-RCH-400 | detailLeavesMarkedSourceNullWhenUnmarked | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailLeavesMarkedSourceNullWhenUnmarked` |
| TC-RCH-401 | listByFarmDerivesHealthFromSnapshotsInsteadOfStaticColumn | P1 | REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::listByFarmDerivesHealthFromSnapshotsInsteadOfStaticColumn` |
| TC-RCH-402 | detailDerivesHealthStatusFromSnapshot | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailDerivesHealthStatusFromSnapshot` |
| TC-RCH-403 | explicitOtherIsAccepted | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::explicitOtherIsAccepted` |
| TC-RCH-404 | chineseOtherAliasesAreAccepted | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::chineseOtherAliasesAreAccepted` |
| TC-RCH-405 | blankMapsToOther | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::blankMapsToOther` |
| TC-RCH-406 | knownAliasesStillResolve | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::knownAliasesStillResolve` |
| TC-RCH-407 | unknownBreedIsRejected | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::unknownBreedIsRejected` |
| TC-RCH-408 | handleFarmTileDetection_matchingRegion_createsReadyTask | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_matchingRegion_createsReadyTask` |
| TC-RCH-409 | handleFarmTileDetection_noCoverage_createsGenerationTask | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_noCoverage_createsGenerationTask` |
| TC-RCH-410 | handleFarmTileDetection_lowCoverage_createsCustomRegion | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_lowCoverage_createsCustomRegion` |
| TC-RCH-411 | getFarmTileSources_returnsReadySources | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::getFarmTileSources_returnsReadySources` |
| TC-RCH-412 | requestFarmTileGeneration_withReadyRegion_linksFarmTileTask | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_withReadyRegion_linksFarmTileTask` |
| TC-RCH-413 | requestFarmTileGeneration_noCoverage_createsTaskOnce | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_noCoverage_createsTaskOnce` |
| TC-RCH-414 | requestFarmTileGeneration_inflightTask_doesNotDuplicate | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_inflightTask_doesNotDuplicate` |
| TC-RCH-415 | fullFlow_farmCreation_detectsTiles_getsSources | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_farmCreation_detectsTiles_getsSources` |
| TC-RCH-416 | fullFlow_noCoverage_createsGenerationTask | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_noCoverage_createsGenerationTask` |
| TC-RCH-417 | fullFlow_lowCoverage_createsCustomRegionWithWarning | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_lowCoverage_createsCustomRegionWithWarning` |
| TC-RCH-418 | upsertRegion_createsNewRegion | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::upsertRegion_createsNewRegion` |
| TC-RCH-419 | upsertRegion_updatesExistingRegion | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::upsertRegion_updatesExistingRegion` |
| TC-RCH-420 | updateTaskStatus_done_advancesFarmTileTasks | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::updateTaskStatus_done_advancesFarmTileTasks` |
| TC-RCH-451 | should return empty overview when farm has no data | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::emptyFarm` |
| TC-RCH-452 | should return fences from repository | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fencesLoaded` |
| TC-RCH-453 | should echo generationMetadata on FenceData when present, null otherwise | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fenceGenerationMetadataEcho` |
| TC-RCH-454 | should count livestock whose current GPS position is inside each fence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fenceLivestockCount` |
| TC-RCH-455 | should return livestock markers with WARNING health status for FEVER | P1 | REQ-HLT-003、REQ-HLT-005、REQ-HLT-033、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::livestockWithWarningHealth` |
| TC-RCH-456 | should derive CRITICAL status for CRITICAL temp | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::criticalHealthStatus` |
| TC-RCH-457 | should filter out archived alerts from response | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::filterArchivedAlerts` |
| TC-RCH-458 | should skip livestock without GPS position | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::skipLivestockWithoutGps` |
| TC-RCH-459 | calving risk at the alert threshold turns the marker WARNING with a calving task | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingRiskAtThreshold_markerWarning` |
| TC-RCH-460 | null or below-threshold calving risk leaves the marker NORMAL | P1 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingRiskNullOrBelowThreshold_markerNormal` |
| TC-RCH-461 | estrus keeps precedence over a concurrent calving risk | P1 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::estrusAndCalving_estrusTakesPrecedence` |
| TC-RCH-462 | an ACTIVE CALVING_WARNING ticket lights the health-ticket red dot | P1 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTicket_setsHealthTicketDot` |
| TC-RCH-463 | calving tile counts: >=70 high risk, 50-69 watch, null/absent snapshot not counted | P1 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTileCount_bands` |
| TC-RCH-464 | calving tile watch band is inclusive at 50 and exclusive below 70 | P1 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTileCount_bandEdges` |
| TC-RCH-465 | unlocked gate ships OPEN even when the platform policy would hide locked tiles | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_gateOpen_OPEN` |
| TC-RCH-466 | locked gate + SHOW_LOCKED policy ships LOCKED | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_lockedGateShowLocked_LOCKED` |
| TC-RCH-467 | locked gate + HIDE policy ships HIDDEN | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_lockedGateHide_HIDDEN` |
| TC-RCH-468 | all six tiles walk the gate keys to their own state field | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_allSixScenes_keyMapping` |
| TC-RCH-509 | shouldCreateLivestockWithDefaults | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldCreateLivestockWithDefaults` |
| TC-RCH-510 | shouldUpdatePosition | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldUpdatePosition` |
| TC-RCH-511 | shouldTransitionHealthStatus | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldTransitionHealthStatus` |
| TC-RCH-512 | containsPoint_inside | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::containsPoint_inside` |
| TC-RCH-513 | containsPoint_outside | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::containsPoint_outside` |
| TC-RCH-514 | intersectsBbox_overlap | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::intersectsBbox_overlap` |
| TC-RCH-515 | intersectsBbox_noOverlap | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::intersectsBbox_noOverlap` |
| TC-RCH-530 | nullSnapshotIsNeverAlarming | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::nullSnapshotIsNeverAlarming` |
| TC-RCH-531 | criticalTemperatureWinsOverEverything | P1 | REQ-HLT-001、REQ-HLT-002、REQ-HLT-005、REQ-HLT-033 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::criticalTemperatureWinsOverEverything` |
| TC-RCH-532 | feverAndElevatedAndAbnormalMotilityAreWarnings | P1 | REQ-HLT-003、REQ-HLT-005、REQ-HLT-033、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::feverAndElevatedAndAbnormalMotilityAreWarnings` |
| TC-RCH-533 | estrusScoreAtOrAbove70IsWarning | P1 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::estrusScoreAtOrAbove70IsWarning` |
| TC-RCH-534 | calvingRiskAtOrAboveThresholdIsWarning | P1 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::calvingRiskAtOrAboveThresholdIsWarning` |
| TC-RCH-535 | allClearIsNormalWithNoPrimaryAlert | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::allClearIsNormalWithNoPrimaryAlert` |
| TC-RCH-536 | calvingThresholdConstantIsShared | P1 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::calvingThresholdConstantIsShared` |
| TC-RCH-537 | bbox_squareVertices | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::bbox_squareVertices` |
| TC-RCH-538 | coverageRatio_squarePolygon_isHigh | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_squarePolygon_isHigh` |
| TC-RCH-539 | coverageRatio_narrowStrip_isLow | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_narrowStrip_isLow` |
| TC-RCH-540 | coverageRatio_triangle_isModerate | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_triangle_isModerate` |
| TC-RCH-541 | onMessage_manualImport_earlyReturn_noFenceDetectionNoPositionUpdate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_manualImport_earlyReturn_noFenceDetectionNoPositionUpdate` |
| TC-RCH-542 | onMessage_agenticPlatform_processesNormally | P1 | REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_agenticPlatform_processesNormally` |
| TC-RCH-543 | onMessage_missingSource_treatedAsAgenticPlatform | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_missingSource_treatedAsAgenticPlatform` |
| TC-RCH-544 | onMessage_manualImport_doesNotTouchLivestockEvenWhenInstalled | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_manualImport_doesNotTouchLivestockEvenWhenInstalled` |
| TC-RCH-545 | onMessage_approachAlert_staysActiveUntilLivestockReturnsOrEscalates | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_approachAlert_staysActiveUntilLivestockReturnsOrEscalates` |
| TC-RCH-561 | sameFarm_returnsEntity | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity` |
| TC-RCH-562 | crossFarm_is404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404` |
| TC-RCH-563 | unknownId_is404 | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404` |
| TC-RCH-564 | sameFarm_returnsEntity | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity` |
| TC-RCH-565 | crossFarm_is404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404` |
| TC-RCH-566 | unknownId_is404 | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404` |
| TC-RCH-567 | sameFarm_returnsEntity | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity` |
| TC-RCH-568 | crossFarm_is404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404` |
| TC-RCH-569 | unknownId_is404 | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404` |
| TC-RCH-570 | livestockIdsOf_collectsFarmIds | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::livestockIdsOf_collectsFarmIds` |
| TC-RCH-571 | livestockIdsOf_emptyFarm | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::livestockIdsOf_emptyFarm` |

## 用例明细（初稿模板）

### TC-RCH-261 tap cycles peek → half → full → half → peek

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::tap cycles peek → half → full → half → peek`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-262 drag down from full → half → peek

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag down from full → half → peek`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-263 drag up from peek → half → full

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag up from peek → half → full`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-264 drag direction syncs with subsequent taps

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_bottom_sheet_snap_test.dart::drag direction syncs with subsequent taps`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-265 OPEN tiles render the data cards (fever pill + calving foot)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::OPEN tiles render the data cards (fever pill + calving foot)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-003、REQ-HLT-005

### TC-RCH-266 LOCKED tiles render the lock pill + upgrade foot with the name kept

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::LOCKED tiles render the lock pill + upgrade foot with the name kept`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-267 HIDDEN tiles are dropped entirely (no empty slot)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::HIDDEN tiles are dropped entirely (no empty slot)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-268 OPEN calving tile navigates to the calving predictions page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::OPEN calving tile navigates to the calving predictions page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033

### TC-RCH-269 LOCKED tile navigates to the scene-locked page with scene key

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/health_tiles_gating_test.dart::LOCKED tile navigates to the scene-locked page with scene key`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-270 NORMAL returns success green

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：livestockHealthColor
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::NORMAL returns success green`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-271 WARNING + FEVER returns danger red

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + FEVER returns danger red`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-RCH-002、REQ-RCH-006、REQ-RCH-001

### TC-RCH-272 CRITICAL + FEVER returns danger red

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::CRITICAL + FEVER returns danger red`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-RCH-002、REQ-RCH-006、REQ-RCH-001

### TC-RCH-273 WARNING + DIGESTIVE returns warning orange

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + DIGESTIVE returns warning orange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-274 CRITICAL + DIGESTIVE returns warning orange

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::CRITICAL + DIGESTIVE returns warning orange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-275 WARNING + ESTRUS returns estrus pink

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + ESTRUS returns estrus pink`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-002

### TC-RCH-276 WATCH + CALVING_WARNING returns warning orange, not danger

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WATCH + CALVING_WARNING returns warning orange, not danger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006

### TC-RCH-277 WARNING + EPIDEMIC returns info blue

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::WARNING + EPIDEMIC returns info blue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-278 abnormal with unknown alert type returns danger

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::abnormal with unknown alert type returns danger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-279 abnormal with empty alert returns danger

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::abnormal with empty alert returns danger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-002

### TC-RCH-280 return home does not turn a normal marker red

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::return home does not turn a normal marker red`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-281 position freshness controls marker opacity

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：LivestockMapMarker widget
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::position freshness controls marker opacity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-282 renders livestock code label

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::renders livestock code label`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-283 handles empty code gracefully

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/livestock_map_marker_test.dart::handles empty code gracefully`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-284 fromJson 正确解析完整响应

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchOverview
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::fromJson 正确解析完整响应`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-285 livestockMarkers healthStatus 映射 NORMAL/WARNING/CRITICAL

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::livestockMarkers healthStatus 映射 NORMAL/WARNING/CRITICAL`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-286 RanchFenceData 颜色解析支持多种格式

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchFenceData 颜色解析支持多种格式`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-287 空列表安全 — fences/markers/alerts 为空不抛异常

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::空列表安全 — fences/markers/alerts 为空不抛异常`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-288 null 字段兜底为默认值

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::null 字段兜底为默认值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-289 RanchAlertData 类型解析

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchAlertData 类型解析`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-290 RanchPendingTask 完整性

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_controller_test.dart::RanchPendingTask 完整性`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-291 parses inFenceRate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchOverviewStats
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses inFenceRate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-292 inFenceRate is null when missing

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::inFenceRate is null when missing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-293 parses read field

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchAlertData
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses read field`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-294 read defaults to false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::read defaults to false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-295 parses resolvedType and resolvedAt

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses resolvedType and resolvedAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-296 copyWith works

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::copyWith works`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-297 parses fence and health summaries

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchOverview
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses fence and health summaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-298 summaries default to empty map

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::summaries default to empty map`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-299 parses from JSON

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceZoneData
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses from JSON`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-300 updates alerts list

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchOverview copyWith
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::updates alerts list`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-301 parses calving counts and three-state gating

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchSceneSummary calving/gating (NIX-389)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses calving counts and three-state gating`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-RCH-302 unknown gating value falls back to locked (fail closed)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::unknown gating value falls back to locked (fail closed)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-303 missing gating object means all open (legacy payload)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing gating object means all open (legacy payload)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-304 missing gating field inside the object locks that scene

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing gating field inside the object locks that scene`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-305 parses backend bufferPolygon and bufferDistance

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchFenceData buffer geometry (NIX-412)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::parses backend bufferPolygon and bufferDistance`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-306 missing bufferPolygon degrades to empty, distance defaults to 50

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/ranch_models_test.dart::missing bufferPolygon degrades to empty, distance defaults to 50`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-318 shows collapsed by default with count

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：AutoResolvedSection
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::shows collapsed by default with count`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-319 expands on tap to show items

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::expands on tap to show items`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-320 renders nothing when alerts empty

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/auto_resolved_section_test.dart::renders nothing when alerts empty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-327 renders title and count when alertCount > 0

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：StatusDashboardCard
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::renders title and count when alertCount > 0`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-328 does not show count badge when alertCount is 0

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::does not show count badge when alertCount is 0`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-329 calls onTap when tapped

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/ranch/widgets/status_dashboard_card_test.dart::calls onTap when tapped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-390 shouldCreateLivestockWithAllFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldCreateLivestockWithAllFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-391 shouldNormalizeLowercaseBreedAndGender

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldNormalizeLowercaseBreedAndGender`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-392 shouldDefaultBlankBreedToOther

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldDefaultBlankBreedToOther`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-393 shouldRejectUnknownBreedWithValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectUnknownBreedWithValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-394 shouldRejectInvalidGenderWithValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectInvalidGenderWithValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-395 shouldRejectDuplicateLivestockCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectDuplicateLivestockCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-396 shouldUpdateLivestockFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldUpdateLivestockFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-397 shouldRejectUpdateWithDuplicateCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldRejectUpdateWithDuplicateCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-398 shouldCascadeUninstallDevicesOnDelete

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::shouldCascadeUninstallDevicesOnDelete`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-RCH-399 detailCarriesMarkedSourceWhenLivestockIsMarked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailCarriesMarkedSourceWhenLivestockIsMarked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-400 detailLeavesMarkedSourceNullWhenUnmarked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailLeavesMarkedSourceNullWhenUnmarked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-401 listByFarmDerivesHealthFromSnapshotsInsteadOfStaticColumn

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::listByFarmDerivesHealthFromSnapshotsInsteadOfStaticColumn`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003

### TC-RCH-402 detailDerivesHealthStatusFromSnapshot

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockApplicationServiceTest.java::detailDerivesHealthStatusFromSnapshot`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-403 explicitOtherIsAccepted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::explicitOtherIsAccepted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-404 chineseOtherAliasesAreAccepted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::chineseOtherAliasesAreAccepted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-405 blankMapsToOther

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::blankMapsToOther`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-406 knownAliasesStillResolve

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::knownAliasesStillResolve`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-407 unknownBreedIsRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/LivestockAttributesTest.java::unknownBreedIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-408 handleFarmTileDetection_matchingRegion_createsReadyTask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_matchingRegion_createsReadyTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-409 handleFarmTileDetection_noCoverage_createsGenerationTask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_noCoverage_createsGenerationTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-410 handleFarmTileDetection_lowCoverage_createsCustomRegion

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::handleFarmTileDetection_lowCoverage_createsCustomRegion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-411 getFarmTileSources_returnsReadySources

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::getFarmTileSources_returnsReadySources`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-412 requestFarmTileGeneration_withReadyRegion_linksFarmTileTask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_withReadyRegion_linksFarmTileTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-413 requestFarmTileGeneration_noCoverage_createsTaskOnce

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_noCoverage_createsTaskOnce`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-414 requestFarmTileGeneration_inflightTask_doesNotDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileAdminServiceTest.java::requestFarmTileGeneration_inflightTask_doesNotDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-415 fullFlow_farmCreation_detectsTiles_getsSources

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_farmCreation_detectsTiles_getsSources`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-416 fullFlow_noCoverage_createsGenerationTask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_noCoverage_createsGenerationTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-417 fullFlow_lowCoverage_createsCustomRegionWithWarning

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::fullFlow_lowCoverage_createsCustomRegionWithWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-418 upsertRegion_createsNewRegion

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::upsertRegion_createsNewRegion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-419 upsertRegion_updatesExistingRegion

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::upsertRegion_updatesExistingRegion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-420 updateTaskStatus_done_advancesFarmTileTasks

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/TileIntegrationTest.java::updateTaskStatus_done_advancesFarmTileTasks`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-RCH-451 should return empty overview when farm has no data

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::emptyFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-RCH-452 should return fences from repository

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fencesLoaded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-453 should echo generationMetadata on FenceData when present, null otherwise

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fenceGenerationMetadataEcho`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-454 should count livestock whose current GPS position is inside each fence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::fenceLivestockCount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-455 should return livestock markers with WARNING health status for FEVER

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::livestockWithWarningHealth`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-HLT-033、REQ-RCH-001

### TC-RCH-456 should derive CRITICAL status for CRITICAL temp

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::criticalHealthStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-457 should filter out archived alerts from response

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::filterArchivedAlerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-RCH-458 should skip livestock without GPS position

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::skipLivestockWithoutGps`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-RCH-459 calving risk at the alert threshold turns the marker WARNING with a calving task

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingRiskAtThreshold_markerWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-004

### TC-RCH-460 null or below-threshold calving risk leaves the marker NORMAL

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingRiskNullOrBelowThreshold_markerNormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-RCH-461 estrus keeps precedence over a concurrent calving risk

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::estrusAndCalving_estrusTakesPrecedence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-004

### TC-RCH-462 an ACTIVE CALVING_WARNING ticket lights the health-ticket red dot

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTicket_setsHealthTicketDot`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033

### TC-RCH-463 calving tile counts: >=70 high risk, 50-69 watch, null/absent snapshot not counted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTileCount_bands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006

### TC-RCH-464 calving tile watch band is inclusive at 50 and exclusive below 70

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::calvingTileCount_bandEdges`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-002、REQ-RCH-006

### TC-RCH-465 unlocked gate ships OPEN even when the platform policy would hide locked tiles

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_gateOpen_OPEN`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-466 locked gate + SHOW_LOCKED policy ships LOCKED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_lockedGateShowLocked_LOCKED`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-467 locked gate + HIDE policy ships HIDDEN

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_lockedGateHide_HIDDEN`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-468 all six tiles walk the gate keys to their own state field

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/application/service/RanchOverviewApplicationServiceTest.java::gating_allSixScenes_keyMapping`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-509 shouldCreateLivestockWithDefaults

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldCreateLivestockWithDefaults`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-510 shouldUpdatePosition

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldUpdatePosition`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-511 shouldTransitionHealthStatus

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/LivestockTest.java::shouldTransitionHealthStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-512 containsPoint_inside

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::containsPoint_inside`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-513 containsPoint_outside

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::containsPoint_outside`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-514 intersectsBbox_overlap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::intersectsBbox_overlap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-515 intersectsBbox_noOverlap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/model/TileRegionTest.java::intersectsBbox_noOverlap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-530 nullSnapshotIsNeverAlarming

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::nullSnapshotIsNeverAlarming`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005

### TC-RCH-531 criticalTemperatureWinsOverEverything

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::criticalTemperatureWinsOverEverything`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-HLT-005、REQ-HLT-033

### TC-RCH-532 feverAndElevatedAndAbnormalMotilityAreWarnings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::feverAndElevatedAndAbnormalMotilityAreWarnings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-HLT-033、REQ-RCH-001

### TC-RCH-533 estrusScoreAtOrAbove70IsWarning

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::estrusScoreAtOrAbove70IsWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-005

### TC-RCH-534 calvingRiskAtOrAboveThresholdIsWarning

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::calvingRiskAtOrAboveThresholdIsWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033

### TC-RCH-535 allClearIsNormalWithNoPrimaryAlert

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::allClearIsNormalWithNoPrimaryAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005

### TC-RCH-536 calvingThresholdConstantIsShared

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/HealthStatusDeriverTest.java::calvingThresholdConstantIsShared`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033

### TC-RCH-537 bbox_squareVertices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::bbox_squareVertices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-538 coverageRatio_squarePolygon_isHigh

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_squarePolygon_isHigh`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-539 coverageRatio_narrowStrip_isLow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_narrowStrip_isLow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-540 coverageRatio_triangle_isModerate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/TileCoverageCalculatorTest.java::coverageRatio_triangle_isModerate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-541 onMessage_manualImport_earlyReturn_noFenceDetectionNoPositionUpdate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_manualImport_earlyReturn_noFenceDetectionNoPositionUpdate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-542 onMessage_agenticPlatform_processesNormally

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_agenticPlatform_processesNormally`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002

### TC-RCH-543 onMessage_missingSource_treatedAsAgenticPlatform

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_missingSource_treatedAsAgenticPlatform`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-RCH-544 onMessage_manualImport_doesNotTouchLivestockEvenWhenInstalled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_manualImport_doesNotTouchLivestockEvenWhenInstalled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-RCH-545 onMessage_approachAlert_staysActiveUntilLivestockReturnsOrEscalates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumerTest.java::onMessage_approachAlert_staysActiveUntilLivestockReturnsOrEscalates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005

### TC-RCH-561 sameFarm_returnsEntity

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-562 crossFarm_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-563 unknownId_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-564 sameFarm_returnsEntity

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-565 crossFarm_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-566 unknownId_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-567 sameFarm_returnsEntity

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::sameFarm_returnsEntity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-568 crossFarm_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::crossFarm_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-569 unknownId_is404

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::unknownId_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-570 livestockIdsOf_collectsFarmIds

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::livestockIdsOf_collectsFarmIds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

### TC-RCH-571 livestockIdsOf_emptyFarm

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/ranch/interfaces/open/support/OpenOwnershipGuardTest.java::livestockIdsOf_emptyFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-004、REQ-RCH-001

