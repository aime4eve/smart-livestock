# 测试用例规格：后端·数据仿真（datagen）

> 用例域：PLT ｜ 用例数：117
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-PLT-135 | renders datagen console with localized values | P2 | — | `Mobile/mobile_app/test/features/admin/datagen/datagen_console_page_test.dart::renders datagen console with localized values` |
| TC-PLT-136 | loads farms and initializes selected devices | P1 | REQ-IDT-001、REQ-IDT-003、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::loads farms and initializes selected devices` |
| TC-PLT-137 | starting with no selected device defaults to eligible devices | P1 | REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::starting with no selected device defaults to eligible devices` |
| TC-PLT-138 | saving devices updates control request and console | P1 | REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::saving devices updates control request and console` |
| TC-PLT-139 | saving rules updates the console without changing devices | P1 | REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::saving rules updates the console without changing devices` |
| TC-PLT-140 | parses console response and nullable fields defensively | P1 | — | `Mobile/mobile_app/test/features/admin/datagen/datagen_models_test.dart::parses console response and nullable fields defensively` |
| TC-PLT-141 | clear result computes total deleted | P1 | — | `Mobile/mobile_app/test/features/admin/datagen/datagen_models_test.dart::clear result computes total deleted` |
| TC-PLT-173 | assembleReport_detectionLeadMissAndEpisodeCaliberFalseAlarms | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_detectionLeadMissAndEpisodeCaliberFalseAlarms` |
| TC-PLT-174 | assembleReport_windowBoundaries_inclusiveStartAndEnd | P1 | REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_windowBoundaries_inclusiveStartAndEnd` |
| TC-PLT-175 | assembleReport_leadDistributionOddMedian | P1 | REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_leadDistributionOddMedian` |
| TC-PLT-176 | assembleReport_channelAvailabilityGroupedByHerdClassAndReboundRate | P1 | REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_channelAvailabilityGroupedByHerdClassAndReboundRate` |
| TC-PLT-177 | syntheticBreedingAt_backwardFromTruthOnlyInRecordScenario | P1 | REQ-HLT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::syntheticBreedingAt_backwardFromTruthOnlyInRecordScenario` |
| TC-PLT-178 | purgeOldData_dropsAllTimeSeriesPartitionsAndDeletesLegacyRows | P1 | REQ-RCH-001、REQ-RCH-002、REQ-NFR-001、REQ-NFR-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DataRetentionServiceTest.java::purgeOldData_dropsAllTimeSeriesPartitionsAndDeletesLegacyRows` |
| TC-PLT-179 | clear_runningFarm_rejectsWithoutDeleting | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_runningFarm_rejectsWithoutDeleting` |
| TC-PLT-180 | clear_wrongConfirmText_rejectsBeforeLocking | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_wrongConfirmText_rejectsBeforeLocking` |
| TC-PLT-181 | clear_stoppedFarm_clearsAndWritesAudit | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_stoppedFarm_clearsAndWritesAudit` |
| TC-PLT-182 | clear_invalidCustomRange_rejects | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_invalidCustomRange_rejects` |
| TC-PLT-183 | updateRules_savesRulesClearsSchedulesAndWritesAudit | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceRulesTest.java::updateRules_savesRulesClearsSchedulesAndWritesAudit` |
| TC-PLT-184 | updateRules_invalidRange_rejects | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceRulesTest.java::updateRules_invalidRange_rejects` |
| TC-PLT-185 | stop_deactivatesActiveAssignmentsWithoutValidatingStaleDevices | P1 | REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::stop_deactivatesActiveAssignmentsWithoutValidatingStaleDevices` |
| TC-PLT-186 | stop_emptyRequestDeactivatesAllActiveAssignments | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::stop_emptyRequestDeactivatesAllActiveAssignments` |
| TC-PLT-187 | enable_stillValidatesRequestedDevices | P1 | REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::enable_stillValidatesRequestedDevices` |
| TC-PLT-188 | start_addsAssignmentForNewEligibleDevice | P1 | REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::start_addsAssignmentForNewEligibleDevice` |
| TC-PLT-189 | clear_executesDeleteStatements | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenDataQueryServiceTest.java::clear_executesDeleteStatements` |
| TC-PLT-190 | requireAccessibleFarm_platformAdmin_canAccessAnyFarm | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_platformAdmin_canAccessAnyFarm` |
| TC-PLT-191 | requireAccessibleFarm_b2bAdmin_canAccessOwnTenantFarm | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_b2bAdmin_canAccessOwnTenantFarm` |
| TC-PLT-192 | requireAccessibleFarm_b2bAdmin_cannotAccessOtherTenantFarm | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_b2bAdmin_cannotAccessOtherTenantFarm` |
| TC-PLT-193 | requireAccessibleFarm_missingFarm_returnsNotFound | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_missingFarm_returnsNotFound` |
| TC-PLT-194 | resolve_platformAdminWithoutTenant_succeeds | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_platformAdminWithoutTenant_succeeds` |
| TC-PLT-195 | resolve_b2bAdminWithoutTenant_rejects | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_b2bAdminWithoutTenant_rejects` |
| TC-PLT-196 | resolve_b2bAdminWithTenant_succeeds | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_b2bAdminWithTenant_succeeds` |
| TC-PLT-197 | resolve_nonAdmin_rejects | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_nonAdmin_rejects` |
| TC-PLT-198 | onlyConfirmedAndVerdictlessLabelsSurviveTheVerdictFilter | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::onlyConfirmedAndVerdictlessLabelsSurviveTheVerdictFilter` |
| TC-PLT-199 | rejectedAndSupersededLabelsDoNotMarkLivestockAbnormal | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::rejectedAndSupersededLabelsDoNotMarkLivestockAbnormal` |
| TC-PLT-200 | confirmedLabelWithHighScoreCountsAsTruePositive | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::confirmedLabelWithHighScoreCountsAsTruePositive` |
| TC-PLT-201 | deviceIntervals_useFarmRules | P1 | REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::deviceIntervals_useFarmRules` |
| TC-PLT-202 | generate_trackerOutsideFirstFence_resetsInsideFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_trackerOutsideFirstFence_resetsInsideFence` |
| TC-PLT-203 | generate_capsule_generatesHealthReadings | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsule_generatesHealthReadings` |
| TC-PLT-204 | generate_boundedExcursion_returnsContinuously | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_boundedExcursion_returnsContinuously` |
| TC-PLT-205 | generate_capsuleCurves_areDeterministicAndSmooth | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsuleCurves_areDeterministicAndSmooth` |
| TC-PLT-206 | generate_capsuleCreatesSharedStateBeforeTracker_trackerStillInitializesInFence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsuleCreatesSharedStateBeforeTracker_trackerStillInitializesInFence` |
| TC-PLT-207 | clearDeviceSchedules_removesOnlyRequestedDevices | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::clearDeviceSchedules_removesOnlyRequestedDevices` |
| TC-PLT-208 | analyzeL1PersistsValidatedPrediction | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::analyzeL1PersistsValidatedPrediction` |
| TC-PLT-209 | repeatedAnalysisUpdatesExistingModelRow | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::repeatedAnalysisUpdatesExistingModelRow` |
| TC-PLT-210 | analyzeRejectsL2WithoutModelIdentity | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::analyzeRejectsL2WithoutModelIdentity` |
| TC-PLT-211 | trainRequiresSyntheticDatasetAndL2Request | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::trainRequiresSyntheticDatasetAndL2Request` |
| TC-PLT-212 | trainDelegatesValidSyntheticDataset | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::trainDelegatesValidSyntheticDataset` |
| TC-PLT-213 | exportsCanonicalDatasetAndScenarioDigest | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetExportServiceTest.java::exportsCanonicalDatasetAndScenarioDigest` |
| TC-PLT-214 | rejectsDatasetFromAnotherScenario | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetExportServiceTest.java::rejectsDatasetFromAnotherScenario` |
| TC-PLT-215 | generatesAndPersistsSyntheticDatasetWithGovernedSplits | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::generatesAndPersistsSyntheticDatasetWithGovernedSplits` |
| TC-PLT-216 | sameCanonicalDefinitionIsIdempotent | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::sameCanonicalDefinitionIsIdempotent` |
| TC-PLT-217 | rejectsTooManyWindows | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::rejectsTooManyWindows` |
| TC-PLT-218 | validatesSubjectScopeBeforeGeneratingDataset | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::validatesSubjectScopeBeforeGeneratingDataset` |
| TC-PLT-219 | rejectsNullInitialWeightWithoutInternalServerError | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::rejectsNullInitialWeightWithoutInternalServerError` |
| TC-PLT-220 | completeReportContainsDominantFacetBoundaryAndEventMetrics | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::completeReportContainsDominantFacetBoundaryAndEventMetrics` |
| TC-PLT-221 | predictionFreeDatasetReturnsExplicitNoPredictionsState | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::predictionFreeDatasetReturnsExplicitNoPredictionsState` |
| TC-PLT-222 | partialPredictionsAreExplicitlyReported | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::partialPredictionsAreExplicitlyReported` |
| TC-PLT-223 | mixedSourcesRequireExplicitDebugMode | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::mixedSourcesRequireExplicitDebugMode` |
| TC-PLT-224 | rejectsEmptyDatasetSelection | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::rejectsEmptyDatasetSelection` |
| TC-PLT-225 | overlaps_contained_range | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::overlaps_contained_range` |
| TC-PLT-226 | overlaps_boundary_touching | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::overlaps_boundary_touching` |
| TC-PLT-227 | no_overlap_completely_before | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::no_overlap_completely_before` |
| TC-PLT-228 | start_from_draft_succeeds | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_draft_succeeds` |
| TC-PLT-229 | start_from_stopped_succeeds | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_stopped_succeeds` |
| TC-PLT-230 | start_from_running_fails | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_running_fails` |
| TC-PLT-231 | isActiveAt_within_window_true | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_within_window_true` |
| TC-PLT-232 | isActiveAt_exclusive_end | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_exclusive_end` |
| TC-PLT-233 | isActiveAt_stopped_scenario_false | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_stopped_scenario_false` |
| TC-PLT-234 | baseline_always_zero | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::baseline_always_zero` |
| TC-PLT-235 | gradual_rise_plateau_at_midpoint | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_rise_plateau_at_midpoint` |
| TC-PLT-236 | gradual_rise_starts_low_ends_low | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_rise_starts_low_ends_low` |
| TC-PLT-237 | abrupt_spike_ramp_up_then_plateau | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::abrupt_spike_ramp_up_then_plateau` |
| TC-PLT-238 | activity_surge_stays_high_until_tail | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::activity_surge_stays_high_until_tail` |
| TC-PLT-239 | gradual_and_abrupt_shapes_start_near_zero | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_and_abrupt_shapes_start_near_zero` |
| TC-PLT-240 | activity_shapes_start_at_full_strength | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::activity_shapes_start_at_full_strength` |
| TC-PLT-241 | all_non_baseline_shapes_end_near_zero | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::all_non_baseline_shapes_end_near_zero` |
| TC-PLT-242 | v1ContractHashIsStable | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeatureContractTest.java::v1ContractHashIsStable` |
| TC-PLT-243 | structuralChangesChangeSchemaHash | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeatureContractTest.java::structuralChangesChangeSchemaHash` |
| TC-PLT-244 | sameCanonicalScenarioProducesIdenticalDataset | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::sameCanonicalScenarioProducesIdenticalDataset` |
| TC-PLT-245 | changingSeedChangesDataset | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::changingSeedChangesDataset` |
| TC-PLT-246 | changingSubjectDefinitionChangesDatasetIdentity | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::changingSubjectDefinitionChangesDatasetIdentity` |
| TC-PLT-247 | twentyFourHourDatasetHasStableWindowsAndEpisodeBoundaries | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::twentyFourHourDatasetHasStableWindowsAndEpisodeBoundaries` |
| TC-PLT-248 | canonicalScenarioIsDeterministic | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::canonicalScenarioIsDeterministic` |
| TC-PLT-249 | fullFeatureSetValidates | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::fullFeatureSetValidates` |
| TC-PLT-250 | fullInputCannotDeclareMissingFields | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::fullInputCannotDeclareMissingFields` |
| TC-PLT-251 | partialInputMayOmitFieldsOnlyThroughMask | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::partialInputMayOmitFieldsOnlyThroughMask` |
| TC-PLT-252 | rejectsMissingOutOfRangeAndNonIntegerValues | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::rejectsMissingOutOfRangeAndNonIntegerValues` |
| TC-PLT-253 | rejectsIncompatibleVersionOrHash | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::rejectsIncompatibleVersionOrHash` |
| TC-PLT-254 | coarseSnapshotCannotCarryOralLabels | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::coarseSnapshotCannotCarryOralLabels` |
| TC-PLT-255 | activityCountsCannotExceedSampleCount | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::activityCountsCannotExceedSampleCount` |
| TC-PLT-256 | ruminationAndFeedingHaveDistinctProtocolFeatures | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::ruminationAndFeedingHaveDistinctProtocolFeatures` |
| TC-PLT-257 | walkingIsDistinctFromLying | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::walkingIsDistinctFromLying` |
| TC-PLT-258 | missingWindowUsesUnknownQualityAndCompleteMask | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::missingWindowUsesUnknownQualityAndCompleteMask` |
| TC-PLT-259 | 同 seed 同参数两次生成，逐点逐字段相等 | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::compositionIsDeterministic` |
| TC-PLT-260 | 30 头 μᵢ 全部落在截断区间 [38.6,39.5]，均值接近 39.0±0.2 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::individualBaselinesAreTruncatedAndCentered` |
| TC-PLT-261 | PREPARTUM 头产犊前 6h 段较其事件外基线低 0.15–0.45℃（群体均值），末 8h 活动×1.3–1.7 | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::prepartumShowsRrtDropAndActivityRise` |
| TC-PLT-262 | ESTRUS 头标签窗内/窗外活动均值比（ herd 中位）≈2.2–3.8，RRT 升幅 ≈0.35–0.75 | P1 | REQ-HLT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::estrusShowsActivitySurgeAndRrtRise` |
| TC-PLT-263 | 温谷深度 ∈[2.0,5.2]，谷后 2h 在 P2/P3 噪声包络内回升到基线水平 | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::waterValleysAreDeepAndRecover` |
| TC-PLT-264 | DETACHED 头全天温度 ∈[25,35]（环境反推）且无任何活动行 | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::detachedDayHasEnvironmentalReadingsAndNoActivity` |
| TC-PLT-265 | CLEAN 头 23:00–02:00 段均值 > 09:00–12:00 段均值 + 0.2（峰相深夜） | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::nightPeakExceedsMorningByCircadianAmplitude` |
| TC-PLT-266 | ESTRUS 标签窗起点 1h 内出现 ≥2×同时段基线的活动点（按可检测头集合断言） | P1 | REQ-HLT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::estrusLabelStartAlignsWithActivityOnset` |
| TC-PLT-267 | 默认参数 30 头：各类头数 = ratio×30 取整 | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::eventQuotasMatchHeadRatios` |
| TC-PLT-268 | farmZoneId=Asia/Shanghai：本地 23:00–02:00 均值 > 本地 09:00–12:00 均值 + 0.2（深夜峰锚本地钟） | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::nightPeakAnchorsToFarmLocalClock` |
| TC-PLT-269 | 同 seed 换 farmZoneId 生成结果不同（日相时区敏感性回归） | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::sameSeedDifferentZoneYieldsDifferentSeries` |
| TC-PLT-270 | 校验：头数>200 / days>30 / granularity∉{10,15,30} / 列表不等长均抛 ApiException | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::generationServiceValidatesRanges` |
| TC-PLT-271 | acceptsConsistentActiveSubjectScope | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::acceptsConsistentActiveSubjectScope` |
| TC-PLT-272 | rejectsTenantMismatchBeforeQueryingSubjectScope | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsTenantMismatchBeforeQueryingSubjectScope` |
| TC-PLT-273 | rejectsMissingLivestockWithValidationError | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsMissingLivestockWithValidationError` |
| TC-PLT-274 | rejectsLivestockFromAnotherFarmOrDeletedLivestock | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsLivestockFromAnotherFarmOrDeletedLivestock` |
| TC-PLT-275 | rejectsMissingRemovedMismatchedOrInactiveInstallation | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsMissingRemovedMismatchedOrInactiveInstallation` |
| TC-PLT-276 | ensureByFarmId_repointsLegacyControlToDefaultScenario | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaDatagenFarmControlRepositoryImplTest.java::ensureByFarmId_repointsLegacyControlToDefaultScenario` |
| TC-PLT-277 | ensureByFarmId_keepsCurrentScenario | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaDatagenFarmControlRepositoryImplTest.java::ensureByFarmId_keepsCurrentScenario` |
| TC-PLT-278 | save_existingScenario_preservesCreatedAt | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaSynthesisScenarioRepositoryImplTest.java::save_existingScenario_preservesCreatedAt` |
| TC-PLT-279 | legacyGlobalEndpoints_requirePlatformAdminOnly | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::legacyGlobalEndpoints_requirePlatformAdminOnly` |
| TC-PLT-280 | consoleController_allowsPlatformAndB2bAdmin | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::consoleController_allowsPlatformAndB2bAdmin` |
| TC-PLT-281 | behaviorController_allowsPlatformAndB2bAdmin | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::behaviorController_allowsPlatformAndB2bAdmin` |
| TC-PLT-282 | ensureByFarmIdRepointsLegacyControlToDefaultScenario | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DatagenFarmControlRepositoryIntegrationTest.java::ensureByFarmIdRepointsLegacyControlToDefaultScenario` |

## 用例明细（初稿模板）

### TC-PLT-135 renders datagen console with localized values

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_console_page_test.dart::renders datagen console with localized values`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-136 loads farms and initializes selected devices

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::loads farms and initializes selected devices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IOT-003、REQ-IOT-004

### TC-PLT-137 starting with no selected device defaults to eligible devices

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::starting with no selected device defaults to eligible devices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-003、REQ-IOT-004

### TC-PLT-138 saving devices updates control request and console

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::saving devices updates control request and console`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-003、REQ-IOT-004

### TC-PLT-139 saving rules updates the console without changing devices

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_controller_test.dart::saving rules updates the console without changing devices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-003、REQ-IOT-004

### TC-PLT-140 parses console response and nullable fields defensively

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_models_test.dart::parses console response and nullable fields defensively`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-141 clear result computes total deleted

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/datagen/datagen_models_test.dart::clear result computes total deleted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-173 assembleReport_detectionLeadMissAndEpisodeCaliberFalseAlarms

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_detectionLeadMissAndEpisodeCaliberFalseAlarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-PLT-174 assembleReport_windowBoundaries_inclusiveStartAndEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_windowBoundaries_inclusiveStartAndEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-175 assembleReport_leadDistributionOddMedian

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_leadDistributionOddMedian`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-176 assembleReport_channelAvailabilityGroupedByHerdClassAndReboundRate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::assembleReport_channelAvailabilityGroupedByHerdClassAndReboundRate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-177 syntheticBreedingAt_backwardFromTruthOnlyInRecordScenario

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/CalvingSimulationEvaluationServiceTest.java::syntheticBreedingAt_backwardFromTruthOnlyInRecordScenario`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-RCH-001、REQ-RCH-002

### TC-PLT-178 purgeOldData_dropsAllTimeSeriesPartitionsAndDeletesLegacyRows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DataRetentionServiceTest.java::purgeOldData_dropsAllTimeSeriesPartitionsAndDeletesLegacyRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-NFR-001、REQ-NFR-002

### TC-PLT-179 clear_runningFarm_rejectsWithoutDeleting

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_runningFarm_rejectsWithoutDeleting`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-180 clear_wrongConfirmText_rejectsBeforeLocking

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_wrongConfirmText_rejectsBeforeLocking`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-181 clear_stoppedFarm_clearsAndWritesAudit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_stoppedFarm_clearsAndWritesAudit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-182 clear_invalidCustomRange_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenClearServiceTest.java::clear_invalidCustomRange_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-183 updateRules_savesRulesClearsSchedulesAndWritesAudit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceRulesTest.java::updateRules_savesRulesClearsSchedulesAndWritesAudit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-184 updateRules_invalidRange_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceRulesTest.java::updateRules_invalidRange_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-185 stop_deactivatesActiveAssignmentsWithoutValidatingStaleDevices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::stop_deactivatesActiveAssignmentsWithoutValidatingStaleDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-186 stop_emptyRequestDeactivatesAllActiveAssignments

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::stop_emptyRequestDeactivatesAllActiveAssignments`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-187 enable_stillValidatesRequestedDevices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::enable_stillValidatesRequestedDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-188 start_addsAssignmentForNewEligibleDevice

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenControlServiceStopTest.java::start_addsAssignmentForNewEligibleDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-189 clear_executesDeleteStatements

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenDataQueryServiceTest.java::clear_executesDeleteStatements`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-190 requireAccessibleFarm_platformAdmin_canAccessAnyFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_platformAdmin_canAccessAnyFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-PLT-191 requireAccessibleFarm_b2bAdmin_canAccessOwnTenantFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_b2bAdmin_canAccessOwnTenantFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-PLT-192 requireAccessibleFarm_b2bAdmin_cannotAccessOtherTenantFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_b2bAdmin_cannotAccessOtherTenantFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-PLT-193 requireAccessibleFarm_missingFarm_returnsNotFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenFarmAccessServiceTest.java::requireAccessibleFarm_missingFarm_returnsNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-PLT-194 resolve_platformAdminWithoutTenant_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_platformAdminWithoutTenant_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-195 resolve_b2bAdminWithoutTenant_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_b2bAdminWithoutTenant_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-196 resolve_b2bAdminWithTenant_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_b2bAdminWithTenant_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-197 resolve_nonAdmin_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/DatagenOperatorContextResolverTest.java::resolve_nonAdmin_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-198 onlyConfirmedAndVerdictlessLabelsSurviveTheVerdictFilter

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::onlyConfirmedAndVerdictlessLabelsSurviveTheVerdictFilter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-199 rejectedAndSupersededLabelsDoNotMarkLivestockAbnormal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::rejectedAndSupersededLabelsDoNotMarkLivestockAbnormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-200 confirmedLabelWithHighScoreCountsAsTruePositive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/EvaluationServiceTest.java::confirmedLabelWithHighScoreCountsAsTruePositive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-201 deviceIntervals_useFarmRules

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::deviceIntervals_useFarmRules`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-PLT-001、REQ-PLT-002

### TC-PLT-202 generate_trackerOutsideFirstFence_resetsInsideFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_trackerOutsideFirstFence_resetsInsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001

### TC-PLT-203 generate_capsule_generatesHealthReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsule_generatesHealthReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-PLT-204 generate_boundedExcursion_returnsContinuously

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_boundedExcursion_returnsContinuously`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-205 generate_capsuleCurves_areDeterministicAndSmooth

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsuleCurves_areDeterministicAndSmooth`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-206 generate_capsuleCreatesSharedStateBeforeTracker_trackerStillInitializesInFence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::generate_capsuleCreatesSharedStateBeforeTracker_trackerStillInitializesInFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-PLT-001

### TC-PLT-207 clearDeviceSchedules_removesOnlyRequestedDevices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/SynthesisServiceTest.java::clearDeviceSchedules_removesOnlyRequestedDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-208 analyzeL1PersistsValidatedPrediction

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::analyzeL1PersistsValidatedPrediction`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-209 repeatedAnalysisUpdatesExistingModelRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::repeatedAnalysisUpdatesExistingModelRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-210 analyzeRejectsL2WithoutModelIdentity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::analyzeRejectsL2WithoutModelIdentity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-211 trainRequiresSyntheticDatasetAndL2Request

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::trainRequiresSyntheticDatasetAndL2Request`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-212 trainDelegatesValidSyntheticDataset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorAnalysisOrchestrationServiceTest.java::trainDelegatesValidSyntheticDataset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-213 exportsCanonicalDatasetAndScenarioDigest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetExportServiceTest.java::exportsCanonicalDatasetAndScenarioDigest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-214 rejectsDatasetFromAnotherScenario

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetExportServiceTest.java::rejectsDatasetFromAnotherScenario`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-215 generatesAndPersistsSyntheticDatasetWithGovernedSplits

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::generatesAndPersistsSyntheticDatasetWithGovernedSplits`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-216 sameCanonicalDefinitionIsIdempotent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::sameCanonicalDefinitionIsIdempotent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-217 rejectsTooManyWindows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::rejectsTooManyWindows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-218 validatesSubjectScopeBeforeGeneratingDataset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::validatesSubjectScopeBeforeGeneratingDataset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-219 rejectsNullInitialWeightWithoutInternalServerError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorDatasetPersistenceServiceTest.java::rejectsNullInitialWeightWithoutInternalServerError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-220 completeReportContainsDominantFacetBoundaryAndEventMetrics

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::completeReportContainsDominantFacetBoundaryAndEventMetrics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-221 predictionFreeDatasetReturnsExplicitNoPredictionsState

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::predictionFreeDatasetReturnsExplicitNoPredictionsState`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-222 partialPredictionsAreExplicitlyReported

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::partialPredictionsAreExplicitlyReported`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-223 mixedSourcesRequireExplicitDebugMode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::mixedSourcesRequireExplicitDebugMode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-224 rejectsEmptyDatasetSelection

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/application/behavior/BehaviorEvaluationServiceTest.java::rejectsEmptyDatasetSelection`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-225 overlaps_contained_range

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::overlaps_contained_range`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-226 overlaps_boundary_touching

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::overlaps_boundary_touching`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-227 no_overlap_completely_before

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/GroundTruthLabelTest.java::no_overlap_completely_before`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-228 start_from_draft_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_draft_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-229 start_from_stopped_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_stopped_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-230 start_from_running_fails

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::start_from_running_fails`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-231 isActiveAt_within_window_true

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_within_window_true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-232 isActiveAt_exclusive_end

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_exclusive_end`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-233 isActiveAt_stopped_scenario_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java::isActiveAt_stopped_scenario_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-234 baseline_always_zero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::baseline_always_zero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-235 gradual_rise_plateau_at_midpoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_rise_plateau_at_midpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-236 gradual_rise_starts_low_ends_low

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_rise_starts_low_ends_low`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-237 abrupt_spike_ramp_up_then_plateau

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::abrupt_spike_ramp_up_then_plateau`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-238 activity_surge_stays_high_until_tail

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::activity_surge_stays_high_until_tail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-239 gradual_and_abrupt_shapes_start_near_zero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::gradual_and_abrupt_shapes_start_near_zero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-240 activity_shapes_start_at_full_strength

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::activity_shapes_start_at_full_strength`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-241 all_non_baseline_shapes_end_near_zero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java::all_non_baseline_shapes_end_near_zero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-242 v1ContractHashIsStable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeatureContractTest.java::v1ContractHashIsStable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-243 structuralChangesChangeSchemaHash

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/model/behavior/BehaviorFeatureContractTest.java::structuralChangesChangeSchemaHash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-244 sameCanonicalScenarioProducesIdenticalDataset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::sameCanonicalScenarioProducesIdenticalDataset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-245 changingSeedChangesDataset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::changingSeedChangesDataset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-246 changingSubjectDefinitionChangesDatasetIdentity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::changingSubjectDefinitionChangesDatasetIdentity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-247 twentyFourHourDatasetHasStableWindowsAndEpisodeBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::twentyFourHourDatasetHasStableWindowsAndEpisodeBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-248 canonicalScenarioIsDeterministic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorDatasetGeneratorTest.java::canonicalScenarioIsDeterministic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-249 fullFeatureSetValidates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::fullFeatureSetValidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-250 fullInputCannotDeclareMissingFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::fullInputCannotDeclareMissingFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-251 partialInputMayOmitFieldsOnlyThroughMask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::partialInputMayOmitFieldsOnlyThroughMask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-252 rejectsMissingOutOfRangeAndNonIntegerValues

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::rejectsMissingOutOfRangeAndNonIntegerValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-253 rejectsIncompatibleVersionOrHash

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::rejectsIncompatibleVersionOrHash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-254 coarseSnapshotCannotCarryOralLabels

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::coarseSnapshotCannotCarryOralLabels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-255 activityCountsCannotExceedSampleCount

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorFeatureValidatorTest.java::activityCountsCannotExceedSampleCount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-256 ruminationAndFeedingHaveDistinctProtocolFeatures

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::ruminationAndFeedingHaveDistinctProtocolFeatures`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-257 walkingIsDistinctFromLying

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::walkingIsDistinctFromLying`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-258 missingWindowUsesUnknownQualityAndCompleteMask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/BehaviorWaveformGeneratorTest.java::missingWindowUsesUnknownQualityAndCompleteMask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-PLT-259 同 seed 同参数两次生成，逐点逐字段相等

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::compositionIsDeterministic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-260 30 头 μᵢ 全部落在截断区间 [38.6,39.5]，均值接近 39.0±0.2

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::individualBaselinesAreTruncatedAndCentered`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-261 PREPARTUM 头产犊前 6h 段较其事件外基线低 0.15–0.45℃（群体均值），末 8h 活动×1.3–1.7

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::prepartumShowsRrtDropAndActivityRise`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-262 ESTRUS 头标签窗内/窗外活动均值比（ herd 中位）≈2.2–3.8，RRT 升幅 ≈0.35–0.75

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::estrusShowsActivitySurgeAndRrtRise`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-RCH-001、REQ-RCH-002

### TC-PLT-263 温谷深度 ∈[2.0,5.2]，谷后 2h 在 P2/P3 噪声包络内回升到基线水平

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::waterValleysAreDeepAndRecover`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-264 DETACHED 头全天温度 ∈[25,35]（环境反推）且无任何活动行

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::detachedDayHasEnvironmentalReadingsAndNoActivity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-265 CLEAN 头 23:00–02:00 段均值 > 09:00–12:00 段均值 + 0.2（峰相深夜）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::nightPeakExceedsMorningByCircadianAmplitude`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-266 ESTRUS 标签窗起点 1h 内出现 ≥2×同时段基线的活动点（按可检测头集合断言）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::estrusLabelStartAlignsWithActivityOnset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-RCH-001、REQ-RCH-002

### TC-PLT-267 默认参数 30 头：各类头数 = ratio×30 取整

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::eventQuotasMatchHeadRatios`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-PLT-268 farmZoneId=Asia/Shanghai：本地 23:00–02:00 均值 > 本地 09:00–12:00 均值 + 0.2（深夜峰锚本地钟）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::nightPeakAnchorsToFarmLocalClock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-269 同 seed 换 farmZoneId 生成结果不同（日相时区敏感性回归）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::sameSeedDifferentZoneYieldsDifferentSeries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-270 校验：头数>200 / days>30 / granularity∉{10,15,30} / 列表不等长均抛 ApiException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/domain/service/SimulationHerdComposerTest.java::generationServiceValidatesRanges`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-271 acceptsConsistentActiveSubjectScope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::acceptsConsistentActiveSubjectScope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-272 rejectsTenantMismatchBeforeQueryingSubjectScope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsTenantMismatchBeforeQueryingSubjectScope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-273 rejectsMissingLivestockWithValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsMissingLivestockWithValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-274 rejectsLivestockFromAnotherFarmOrDeletedLivestock

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsLivestockFromAnotherFarmOrDeletedLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-275 rejectsMissingRemovedMismatchedOrInactiveInstallation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/acl/BehaviorSubjectScopePortImplTest.java::rejectsMissingRemovedMismatchedOrInactiveInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-276 ensureByFarmId_repointsLegacyControlToDefaultScenario

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaDatagenFarmControlRepositoryImplTest.java::ensureByFarmId_repointsLegacyControlToDefaultScenario`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-277 ensureByFarmId_keepsCurrentScenario

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaDatagenFarmControlRepositoryImplTest.java::ensureByFarmId_keepsCurrentScenario`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-278 save_existingScenario_preservesCreatedAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/infrastructure/persistence/JpaSynthesisScenarioRepositoryImplTest.java::save_existingScenario_preservesCreatedAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-279 legacyGlobalEndpoints_requirePlatformAdminOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::legacyGlobalEndpoints_requirePlatformAdminOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-PLT-280 consoleController_allowsPlatformAndB2bAdmin

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::consoleController_allowsPlatformAndB2bAdmin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-PLT-281 behaviorController_allowsPlatformAndB2bAdmin

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/datagen/interfaces/admin/DataGenControllerSecurityTest.java::behaviorController_allowsPlatformAndB2bAdmin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-PLT-282 ensureByFarmIdRepointsLegacyControlToDefaultScenario

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DatagenFarmControlRepositoryIntegrationTest.java::ensureByFarmIdRepointsLegacyControlToDefaultScenario`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

