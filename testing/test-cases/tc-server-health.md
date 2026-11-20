# 测试用例规格：后端·健康监测与 AI 分析（health）

> 用例域：HLT ｜ 用例数：424
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-HLT-030 | dispatchesEachActiveLivestock | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::dispatchesEachActiveLivestock` |
| TC-HLT-031 | oneFailingDispatchDoesNotStopTheBatch | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::oneFailingDispatchDoesNotStopTheBatch` |
| TC-HLT-032 | noActiveLivestock_dispatchesNothing | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::noActiveLivestock_dispatchesNothing` |
| TC-HLT-033 | disabledFlag_skipsQueryAndDispatch | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::disabledFlag_skipsQueryAndDispatch` |
| TC-HLT-034 | yesterdayWindowUsesShanghaiMidnights | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::yesterdayWindowUsesShanghaiMidnights` |
| TC-HLT-035 | yesterdayWindowFlipsExactlyAtShanghaiMidnight | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::yesterdayWindowFlipsExactlyAtShanghaiMidnight` |
| TC-HLT-036 | schedulerBeanExistsByDefaultAndWhenExplicitlyEnabled | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerBeanExistsByDefaultAndWhenExplicitlyEnabled` |
| TC-HLT-037 | schedulerBeanAbsentWhenDrinkingDisabled | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerBeanAbsentWhenDrinkingDisabled` |
| TC-HLT-038 | schedulerCarriesConditionalAndScheduledAnnotations | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerCarriesConditionalAndScheduledAnnotations` |
| TC-HLT-039 | runDelegatesYesterdaysWindowToTheSweep | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::runDelegatesYesterdaysWindowToTheSweep` |
| TC-HLT-040 | dispatchesEachActiveLivestockWithItsOwnSource | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::dispatchesEachActiveLivestockWithItsOwnSource` |
| TC-HLT-041 | oneFailingLivestockDoesNotStopTheBatch | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::oneFailingLivestockDoesNotStopTheBatch` |
| TC-HLT-042 | noActiveLivestock_dispatchesNothing | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::noActiveLivestock_dispatchesNothing` |
| TC-HLT-043 | disabledFlag_skipsQueryAndDispatch | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::disabledFlag_skipsQueryAndDispatch` |
| TC-HLT-044 | missingSnapshotThrowsResourceNotFound | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::missingSnapshotThrowsResourceNotFound` |
| TC-HLT-045 | evaluationComparesDefaultAndLearnedOnIdenticalInput | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::evaluationComparesDefaultAndLearnedOnIdenticalInput` |
| TC-HLT-046 | episodeCountMergesConsecutiveHighScoresWithin24h | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::episodeCountMergesConsecutiveHighScoresWithin24h` |
| TC-HLT-047 | windowOverrideClampsToSevenAndFourteenDays | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::windowOverrideClampsToSevenAndFourteenDays` |
| TC-HLT-048 | insufficientLearnedCandidateLeavesLearnedSideNull | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::insufficientLearnedCandidateLeavesLearnedSideNull` |
| TC-HLT-049 | gate_tenantResolutionFails_zeroQueriesZeroWrites | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gate_tenantResolutionFails_zeroQueriesZeroWrites` |
| TC-HLT-050 | gate_featureLocked_zeroQueriesAfterGate | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gate_featureLocked_zeroQueriesAfterGate` |
| TC-HLT-051 | firstAssessment_landsScoreWithoutTicket | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::firstAssessment_landsScoreWithoutTicket` |
| TC-HLT-052 | secondAssessment_raisesTicketInOrder_withDatagenSourceAndWindow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::secondAssessment_raisesTicketInOrder_withDatagenSourceAndWindow` |
| TC-HLT-053 | persistenceOne_firstCrossing_raisesImmediately | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::persistenceOne_firstCrossing_raisesImmediately` |
| TC-HLT-054 | holdBand_activeTicket_keepsTicketAndTracksScore | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::holdBand_activeTicket_keepsTicketAndTracksScore` |
| TC-HLT-055 | release_resolvesTicketAndClearsColumn | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::release_resolvesTicketAndClearsColumn` |
| TC-HLT-056 | subPersistScore_resetsStaleColumnAndWritesNoRow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::subPersistScore_resetsStaleColumnAndWritesNoRow` |
| TC-HLT-057 | steadySameValue_skipsColumnUpdateButWritesRow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::steadySameValue_skipsColumnUpdateButWritesRow` |
| TC-HLT-058 | quietHead_belowPersist_neverTouchesTicketLookup | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::quietHead_belowPersist_neverTouchesTicketLookup` |
| TC-HLT-059 | baselineAudit_learnedStampedWhenConsumed | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_learnedStampedWhenConsumed` |
| TC-HLT-060 | baselineAudit_forcedDefaultWhenApplyLearnedOff | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_forcedDefaultWhenApplyLearnedOff` |
| TC-HLT-061 | baselineAudit_learnedSnapshotWithoutValue_fallsBackToDefault | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_learnedSnapshotWithoutValue_fallsBackToDefault` |
| TC-HLT-062 | activityRatio_clampedToColumnUpperBound | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::activityRatio_clampedToColumnUpperBound` |
| TC-HLT-063 | clampToColumn_saturatesBothEndsAndKeepsNull | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::clampToColumn_saturatesBothEndsAndKeepsNull` |
| TC-HLT-064 | priorConflict_alertTextWithoutWindow | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::priorConflict_alertTextWithoutWindow` |
| TC-HLT-065 | priorNormal_windowDisplayed_withPriorWithWindowEvidence | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::priorNormal_windowDisplayed_withPriorWithWindowEvidence` |
| TC-HLT-066 | activityMissing_evidenceShowsDashForGap | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::activityMissing_evidenceShowsDashForGap` |
| TC-HLT-067 | gestation_latestMilestoneCalving_orOverdueOrFuture_priorUnavailable | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gestation_latestMilestoneCalving_orOverdueOrFuture_priorUnavailable` |
| TC-HLT-068 | drinkingExclusion_bufferedWindowsOnTemperatureOnly | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::drinkingExclusion_bufferedWindowsOnTemperatureOnly` |
| TC-HLT-069 | drinkingExclusion_troughBeforeStart_usesStartAsEnd | P1 | REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::drinkingExclusion_troughBeforeStart_usesStartAsEnd` |
| TC-HLT-070 | alertSource_syntheticActivityMarksTicketDatagen | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::alertSource_syntheticActivityMarksTicketDatagen` |
| TC-HLT-071 | physiologicalGate_detachedSamplesNeverEnterTemperatureChannel | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::physiologicalGate_detachedSamplesNeverEnterTemperatureChannel` |
| TC-HLT-072 | evaluateHead_swallowsRepositoryFailure | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::evaluateHead_swallowsRepositoryFailure` |
| TC-HLT-073 | locked calving_warning gate rejects with 403 and never queries data | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::gateLocked_rejected` |
| TC-HLT-074 | lists the latest row per livestock with codes, clamped limit and risk-desc order | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::list_sourcingAndOrdering` |
| TC-HLT-075 | snapshot score floor: >=50 listed, <50 and snapshot-less heads dropped | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::list_snapshotScoreFloor` |
| TC-HLT-076 | oracle_handComputedGridScores_episodeAndAvailability | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::oracle_handComputedGridScores_episodeAndAvailability` |
| TC-HLT-077 | drinkingExclusion_invertedRowClippedToStart | P1 | REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::drinkingExclusion_invertedRowClippedToStart` |
| TC-HLT-078 | replayCadence_pollGridRefusesWhatSamplePacingFabricates | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::replayCadence_pollGridRefusesWhatSamplePacingFabricates` |
| TC-HLT-079 | episode_raiseAndReleasePairedThroughSharedState | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::episode_raiseAndReleasePairedThroughSharedState` |
| TC-HLT-080 | noLookAhead_samplesAfterNowIgnored | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::noLookAhead_samplesAfterNowIgnored` |
| TC-HLT-081 | drinkingWindowOrder_shuffledInputReplaysIdentical | P1 | REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::drinkingWindowOrder_shuffledInputReplaysIdentical` |
| TC-HLT-082 | physiologicalGate_detachedSamplesNeverEnterTemperatureChannel | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::physiologicalGate_detachedSamplesNeverEnterTemperatureChannel` |
| TC-HLT-083 | emptySeries_replaysToEmptyResult | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::emptySeries_replaysToEmptyResult` |
| TC-HLT-084 | breedingPrior_perGridPointGestationDays_normalSuppressedAndNeutral | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::breedingPrior_perGridPointGestationDays_normalSuppressedAndNeutral` |
| TC-HLT-085 | analyzesEveryFarmWithWholeHerdScope | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::analyzesEveryFarmWithWholeHerdScope` |
| TC-HLT-086 | usesConfiguredRollingWindowAsCutoff | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::usesConfiguredRollingWindowAsCutoff` |
| TC-HLT-087 | singleFarmFailureDoesNotBlockRemainingFarms | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::singleFarmFailureDoesNotBlockRemainingFarms` |
| TC-HLT-088 | scheduledRunDelegatesToFarmsWhenEnabled | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::scheduledRunDelegatesToFarmsWhenEnabled` |
| TC-HLT-089 | disabledSwitchSkipsScheduledRun | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::disabledSwitchSkipsScheduledRun` |
| TC-HLT-090 | 两牛交错轨迹产生接触行，距离/时长/评分字段合理 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::interleavedTrajectoriesProduceContactRow` |
| TC-HLT-091 | 距离阈值边界：29m 计接触，31m 不计 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::distanceThresholdBoundary` |
| TC-HLT-092 | 时长阈值边界：累计 4min 不计，6min 计 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::durationThresholdBoundary` |
| TC-HLT-093 | 已标记行（marked_at 非空）不被分析覆盖 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::markedRowsAreNotOverwritten` |
| TC-HLT-094 | 重复分析幂等：不产生重复行，迟到轨迹数值刷新 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::reAnalysisIsIdempotentAndRefreshes` |
| TC-HLT-095 | 指定 livestockId 时只分析该牛参与的牛对 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::targetedAnalysisOnlyCoversTargetPairs` |
| TC-HLT-096 | 两牛交错轨迹产生接触行，距离/时长/评分字段合理 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::interleavedTrajectoriesProduceContactRow` |
| TC-HLT-097 | 距离阈值边界：29m 计接触，31m 不计 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::distanceThresholdBoundary` |
| TC-HLT-098 | 时长阈值边界：累计 4min 不计，6min 计 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::durationThresholdBoundary` |
| TC-HLT-099 | 已标记行（markedAt 非空）不被分析覆盖 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::markedRowsAreNotOverwritten` |
| TC-HLT-100 | 重复分析幂等：不产生重复行，迟到轨迹数值刷新 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::reAnalysisIsIdempotentAndRefreshes` |
| TC-HLT-101 | 指定 livestockId 时只分析该牛参与的牛对 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::targetedAnalysisOnlyCoversTargetPairs` |
| TC-HLT-102 | markDiseased 翻转后的已标记行：重分析不重复插入且疫情语义保留 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::flippedMarkedRowIsNotDuplicatedByReAnalysis` |
| TC-HLT-103 | 未标记的翻转行：重分析复用同一行并归一回 min(id)=from 方向 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::unmarkedFlippedRowIsReusedAndRenormalized` |
| TC-HLT-104 | getSeries_queriesDeviceWindowsAndMapsReadings | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DeviceHealthSeriesApplicationServiceTest.java::getSeries_queriesDeviceWindowsAndMapsReadings` |
| TC-HLT-105 | vShapedValleyDetected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::vShapedValleyDetected` |
| TC-HLT-106 | slopeOnlyValleyNotDetected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::slopeOnlyValleyNotDetected` |
| TC-HLT-107 | valleyWithoutRecoveryNotDetected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleyWithoutRecoveryNotDetected` |
| TC-HLT-108 | valleysTenMinutesApartMergeIntoOne | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysTenMinutesApartMergeIntoOne` |
| TC-HLT-109 | valleysFortyMinutesApartStaySeparate | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysFortyMinutesApartStaySeparate` |
| TC-HLT-110 | valleysInsideFeverWindowAndBufferDropped | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysInsideFeverWindowAndBufferDropped` |
| TC-HLT-111 | outOfBodyPointsSkipped | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::outOfBodyPointsSkipped` |
| TC-HLT-112 | eventCarriesSourceOfItsStartPoint | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::eventCarriesSourceOfItsStartPoint` |
| TC-HLT-113 | depthJustMissingBecomesCandidate | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::depthJustMissingBecomesCandidate` |
| TC-HLT-114 | slowDescentValleyBecomesSingleCandidate | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::slowDescentValleyBecomesSingleCandidate` |
| TC-HLT-115 | deeperValleyScoresHigherConfidence | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::deeperValleyScoresHigherConfidence` |
| TC-HLT-116 | longDescentMergesIntoSingleEvent | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::longDescentMergesIntoSingleEvent` |
| TC-HLT-117 | mergeEventsRollingAnchorKeepsGenuineSeparateBouts | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::mergeEventsRollingAnchorKeepsGenuineSeparateBouts` |
| TC-HLT-118 | midnightCrossingValleyAttributedToStartLocalDay | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::midnightCrossingValleyAttributedToStartLocalDay` |
| TC-HLT-119 | extendWindowsAddsBufferAndKeepsOpenWindowsOpen | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::extendWindowsAddsBufferAndKeepsOpenWindowsOpen` |
| TC-HLT-120 | recalcLowerEdgeStartExactlyAtFromMinusOneHourIsIncluded | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcLowerEdgeStartExactlyAtFromMinusOneHourIsIncluded` |
| TC-HLT-121 | recalcUpperEdgeStartExactlyAtToPlusOneHourIsExcluded | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcUpperEdgeStartExactlyAtToPlusOneHourIsExcluded` |
| TC-HLT-122 | recalcStartBeforeFromMinusOneHourIsExcluded | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcStartBeforeFromMinusOneHourIsExcluded` |
| TC-HLT-123 | detectedUnlabeledRowCounts | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::detectedUnlabeledRowCounts` |
| TC-HLT-124 | rejectedRowNeverCounts | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::rejectedRowNeverCounts` |
| TC-HLT-125 | candidateCountsOnlyAfterConfirmation | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::candidateCountsOnlyAfterConfirmation` |
| TC-HLT-126 | manualBackFillCounts | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::manualBackFillCounts` |
| TC-HLT-127 | listEventsFlagsRowsBelowLowConfidenceThreshold | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsFlagsRowsBelowLowConfidenceThreshold` |
| TC-HLT-128 | listEventsDefaultsToTheRecentSevenShanghaiDays | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsDefaultsToTheRecentSevenShanghaiDays` |
| TC-HLT-129 | listEventsParsesExplicitClosedRange | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsParsesExplicitClosedRange` |
| TC-HLT-130 | listEventsRejectsBadRangeAndFuture | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsRejectsBadRangeAndFuture` |
| TC-HLT-131 | listEventsCarriesClippedFeverWindows | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsCarriesClippedFeverWindows` |
| TC-HLT-132 | listEventsQueriesFeverWindowsOverTheSameRangeAsRows | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsQueriesFeverWindowsOverTheSameRangeAsRows` |
| TC-HLT-133 | patchLabelAcceptsOnlyConfirmedAndRejected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::patchLabelAcceptsOnlyConfirmedAndRejected` |
| TC-HLT-134 | patchLabelRejectsUnlabeledAndGarbage | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::patchLabelRejectsUnlabeledAndGarbage` |
| TC-HLT-135 | manualPostReturnsExistingRowOnRepeat | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::manualPostReturnsExistingRowOnRepeat` |
| TC-HLT-136 | exportBuildsCsvWithBomHeaderEscapingTimesAndFarmJoin | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportBuildsCsvWithBomHeaderEscapingTimesAndFarmJoin` |
| TC-HLT-137 | exportUsesClosedShanghaiWindowPassedToRepository | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportUsesClosedShanghaiWindowPassedToRepository` |
| TC-HLT-138 | exportSkipsTheLivestockLookupWhenNoRowIsBound | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportSkipsTheLivestockLookupWhenNoRowIsBound` |
| TC-HLT-139 | exportRejectsMissingMalformedInvertedAndFutureRanges | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportRejectsMissingMalformedInvertedAndFutureRanges` |
| TC-HLT-140 | farmUniverseDeduplicatesBindingsIntoSortedFarmSet | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::farmUniverseDeduplicatesBindingsIntoSortedFarmSet` |
| TC-HLT-141 | softDeletedLivestockResolveToNoFarm | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::softDeletedLivestockResolveToNoFarm` |
| TC-HLT-142 | emptyBindingUniverseSkipsTheRanchLookup | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::emptyBindingUniverseSkipsTheRanchLookup` |
| TC-HLT-143 | oneFarmFailureDoesNotStopTheSweepAndIsCounted | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::oneFarmFailureDoesNotStopTheSweepAndIsCounted` |
| TC-HLT-144 | sweepAggregatesDevicesAndEventsAcrossFarms | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::sweepAggregatesDevicesAndEventsAcrossFarms` |
| TC-HLT-145 | deviceModeRecalculatesOneDeviceAfterExistenceCheck | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::deviceModeRecalculatesOneDeviceAfterExistenceCheck` |
| TC-HLT-146 | deviceModeRejectsUnknownDeviceWith404 | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::deviceModeRejectsUnknownDeviceWith404` |
| TC-HLT-147 | farmModeSweepsEveryFarmAndReportsScope | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::farmModeSweepsEveryFarmAndReportsScope` |
| TC-HLT-148 | windowIsClosedDateRangeAtShanghaiMidnights | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::windowIsClosedDateRangeAtShanghaiMidnights` |
| TC-HLT-149 | singleDayRangeSpansExactlyOneCowDay | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::singleDayRangeSpansExactlyOneCowDay` |
| TC-HLT-150 | todayAsToIsAllowedButTomorrowIsRejected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::todayAsToIsAllowedButTomorrowIsRejected` |
| TC-HLT-151 | missingMalformedOrInvertedRangesAreRejected | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::missingMalformedOrInvertedRangesAreRejected` |
| TC-HLT-152 | dailyCountsIsCountedRowsOnlyAndPinsLastDrinkEndAt | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::dailyCountsIsCountedRowsOnlyAndPinsLastDrinkEndAt` |
| TC-HLT-153 | weeklyDirectlySumsSevenDaysIncludingFeverLows | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::weeklyDirectlySumsSevenDaysIncludingFeverLows` |
| TC-HLT-154 | rollingBaselineExcludesFeverCoveredAndLowPointDays | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::rollingBaselineExcludesFeverCoveredAndLowPointDays` |
| TC-HLT-155 | baselineWithoutSampleDaysReturnsNullAverage | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::baselineWithoutSampleDaysReturnsNullAverage` |
| TC-HLT-156 | sampleDayRulePinsBoundaries | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::sampleDayRulePinsBoundaries` |
| TC-HLT-157 | feverCoverageMergesOverlapsAndClampsAtDayBounds | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::feverCoverageMergesOverlapsAndClampsAtDayBounds` |
| TC-HLT-158 | cowDayBoundarySplitsAtUtcSixteen | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::cowDayBoundarySplitsAtUtcSixteen` |
| TC-HLT-159 | summaryValidatesDaysAndDate | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::summaryValidatesDaysAndDate` |
| TC-HLT-160 | summaryRejectsLivestockOfAnotherFarm | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::summaryRejectsLivestockOfAnotherFarm` |
| TC-HLT-161 | peerComparisonChecksPremiumBeforeAnythingElse | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonChecksPremiumBeforeAnythingElse` |
| TC-HLT-162 | peerComparisonWithoutOtherGroupMembersDegradesToInsufficientPeers | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonWithoutOtherGroupMembersDegradesToInsufficientPeers` |
| TC-HLT-163 | peerComparisonAveragesQualifiedPeersAndExcludesTarget | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonAveragesQualifiedPeersAndExcludesTarget` |
| TC-HLT-164 | peerComparisonDegradesWhenNoPeerReachesMinSampleDays | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonDegradesWhenNoPeerReachesMinSampleDays` |
| TC-HLT-165 | opensFarmWarningAboveTenPercent_andDeduplicates | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::opensFarmWarningAboveTenPercent_andDeduplicates` |
| TC-HLT-166 | doesNotDuplicateWhenFarmWarningAlreadyActive | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::doesNotDuplicateWhenFarmWarningAlreadyActive` |
| TC-HLT-167 | resolvesBelowFivePercent | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::resolvesBelowFivePercent` |
| TC-HLT-168 | hysteresisBand_keepsWarningBetweenFiveAndTenPercent | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::hysteresisBand_keepsWarningBetweenFiveAndTenPercent` |
| TC-HLT-169 | disabledSkipsScheduledRun | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::disabledSkipsScheduledRun` |
| TC-HLT-170 | learnedBaseline_consumedByScoring_andAudited | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::learnedBaseline_consumedByScoring_andAudited` |
| TC-HLT-171 | applyLearnedFalse_rollsBackToDefaultBaseline_everywhere | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::applyLearnedFalse_rollsBackToDefaultBaseline_everywhere` |
| TC-HLT-172 | defaultColdStart_scoresWithFixedBaseline_andStampsDefault | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::defaultColdStart_scoresWithFixedBaseline_andStampsDefault` |
| TC-HLT-173 | feverDurationChart_judgesEachRowByItsOwnDelta | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::feverDurationChart_judgesEachRowByItsOwnDelta` |
| TC-HLT-174 | feverDurationChart_allDefaultRows_matchLegacyFixedThreshold | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::feverDurationChart_allDefaultRows_matchLegacyFixedThreshold` |
| TC-HLT-175 | ingest_withSwitchOff_newLogsCarryDefaultBaseline | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::ingest_withSwitchOff_newLogsCarryDefaultBaseline` |
| TC-HLT-176 | confirmWritesEpisodeBackedLabelAndAuditEvent | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::confirmWritesEpisodeBackedLabelAndAuditEvent` |
| TC-HLT-177 | restoreFailureFallsBackToAlertPointWindow | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::restoreFailureFallsBackToAlertPointWindow` |
| TC-HLT-178 | sameVerdictRepeatIsIdempotentWithZeroWrites | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::sameVerdictRepeatIsIdempotentWithZeroWrites` |
| TC-HLT-179 | flippedVerdictSupersedesOldRowAndInsertsNewOne | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::flippedVerdictSupersedesOldRowAndInsertsNewOne` |
| TC-HLT-180 | rejectedRepeatIsAlsoIdempotentWithZeroWrites | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::rejectedRepeatIsAlsoIdempotentWithZeroWrites` |
| TC-HLT-181 | reconfirmAfterRejectSupersedesRejectedRow | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::reconfirmAfterRejectSupersedesRejectedRow` |
| TC-HLT-182 | unknownAlertThrows404 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::unknownAlertThrows404` |
| TC-HLT-183 | nonEstrusAlertThrows400 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::nonEstrusAlertThrows400` |
| TC-HLT-184 | crossFarmAlertThrows403 | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::crossFarmAlertThrows403` |
| TC-HLT-185 | physiologyEventUniqueRaceRereadsExistingRow | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::physiologyEventUniqueRaceRereadsExistingRow` |
| TC-HLT-186 | breedingWindowDerivesLabelsWithoutVerdict | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingWindowDerivesLabelsWithoutVerdict` |
| TC-HLT-187 | breedingLinkingSkipsAlertsWithHumanVerdict | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingLinkingSkipsAlertsWithHumanVerdict` |
| TC-HLT-188 | breedingLinkingContinuesPastSingleFailure | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingLinkingContinuesPastSingleFailure` |
| TC-HLT-189 | estrusConfirmIsNotAStageType | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::estrusConfirmIsNotAStageType` |
| TC-HLT-190 | legacyMode_producesPreNormalizationRow_unchanged | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::legacyMode_producesPreNormalizationRow_unchanged` |
| TC-HLT-191 | normalized_crossingNotifiesAlertBridge_snapshotInstanceCarriesFlip | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_crossingNotifiesAlertBridge_snapshotInstanceCarriesFlip` |
| TC-HLT-192 | normalized_dayBoundaryStraddle_meanMeanKeepsCleanCowQuiet | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_dayBoundaryStraddle_meanMeanKeepsCleanCowQuiet` |
| TC-HLT-193 | normalized_ratioOne_lowScore_columnsCarryIncreaseAndMeterDelta | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioOne_lowScore_columnsCarryIncreaseAndMeterDelta` |
| TC-HLT-194 | normalized_ratioThree_crossesHighThreshold_stepIncreaseColumn200 | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioThree_crossesHighThreshold_stepIncreaseColumn200` |
| TC-HLT-195 | normalized_crossingWithDistance_persistsFeatureVersionAndConstructedRatio | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_crossingWithDistance_persistsFeatureVersionAndConstructedRatio` |
| TC-HLT-196 | normalized_distanceRatioBeyondColumn_clampedToDecimal6_3Bound | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_distanceRatioBeyondColumn_clampedToDecimal6_3Bound` |
| TC-HLT-197 | normalized_distanceRatioJustBelowRung_flooredNotRoundedOntoRung | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_distanceRatioJustBelowRung_flooredNotRoundedOntoRung` |
| TC-HLT-198 | normalized_ratioBelowOne_negativeIncreaseAndNegativeMeterDelta | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioBelowOne_negativeIncreaseAndNegativeMeterDelta` |
| TC-HLT-199 | normalized_capsuleOnly_activityIndexScored_distanceColumnNull | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_capsuleOnly_activityIndexScored_distanceColumnNull` |
| TC-HLT-200 | normalized_earTagFallback_stepCountChannelUsed | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_earTagFallback_stepCountChannelUsed` |
| TC-HLT-201 | guard_currentWindowSamplesBelowMin_noRowWritten | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_currentWindowSamplesBelowMin_noRowWritten` |
| TC-HLT-202 | guard_tooFewTemperatureSamples_noRowWritten | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_tooFewTemperatureSamples_noRowWritten` |
| TC-HLT-203 | guard_baselineWindowsAllUnqualified_noRowWritten | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_baselineWindowsAllUnqualified_noRowWritten` |
| TC-HLT-204 | guard_noTemperatureAnchor_noRowWritten | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_noTemperatureAnchor_noRowWritten` |
| TC-HLT-205 | normalized_snapshotEstrusScoreUpdated | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_snapshotEstrusScoreUpdated` |
| TC-HLT-206 | keepsNewestLimitRowsAndDropsOldest | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::keepsNewestLimitRowsAndDropsOldest` |
| TC-HLT-207 | limitLargerThanWindowReturnsAllRows | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::limitLargerThanWindowReturnsAllRows` |
| TC-HLT-208 | legacy_knownRow_breakdownAndWeightedSumRecompute | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::legacy_knownRow_breakdownAndWeightedSumRecompute` |
| TC-HLT-209 | legacy_nullTempAndDistance_componentsZeroWeightsKept | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::legacy_nullTempAndDistance_componentsZeroWeightsKept` |
| TC-HLT-210 | normalized_negativeTempClamped_distanceAbsent_weightsRenormalized | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::normalized_negativeTempClamped_distanceAbsent_weightsRenormalized` |
| TC-HLT-211 | normalized_allComponentsPresent_fullWeights | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::normalized_allComponentsPresent_fullWeights` |
| TC-HLT-212 | nullFeatureVersion_returnsNull | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::nullFeatureVersion_returnsNull` |
| TC-HLT-213 | legacyReplayMatchesHandComputedOracle | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::legacyReplayMatchesHandComputedOracle` |
| TC-HLT-214 | normalizedCrossingScoresAndProducesEpisode | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedCrossingScoresAndProducesEpisode` |
| TC-HLT-215 | normalizedQuietSequenceProducesNoEpisode | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedQuietSequenceProducesNoEpisode` |
| TC-HLT-216 | normalizedExcludesAnchorTimestampedActivityFrame | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedExcludesAnchorTimestampedActivityFrame` |
| TC-HLT-217 | normalizedSparseBaselineWindowsSkipPosition | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedSparseBaselineWindowsSkipPosition` |
| TC-HLT-218 | normalizedSidesShareActivityFactorAndDifferByBaseline | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedSidesShareActivityFactorAndDifferByBaseline` |
| TC-HLT-219 | modeDispatchSelectsExactlyOneKernel | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::modeDispatchSelectsExactlyOneKernel` |
| TC-HLT-220 | tempCritical_noActiveAlert_createsCriticalTemperatureTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempCritical_noActiveAlert_createsCriticalTemperatureTicket` |
| TC-HLT-221 | tempElevated_createsWarningTemperatureTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempElevated_createsWarningTemperatureTicket` |
| TC-HLT-222 | tempAlarming_activeAlertExists_skipsDuplicateCreation | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempAlarming_activeAlertExists_skipsDuplicateCreation` |
| TC-HLT-223 | tempBackToNormal_resolvesTemperatureTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempBackToNormal_resolvesTemperatureTicket` |
| TC-HLT-224 | motilityAbnormal_createsDigestiveTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::motilityAbnormal_createsDigestiveTicket` |
| TC-HLT-225 | motilityLow_doesNotCreateDigestiveTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::motilityLow_doesNotCreateDigestiveTicket` |
| TC-HLT-226 | estrusAtThreshold_createsEstrusTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::estrusAtThreshold_createsEstrusTicket` |
| TC-HLT-227 | estrusBelowThreshold_resolvesEstrusTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::estrusBelowThreshold_resolvesEstrusTicket` |
| TC-HLT-228 | hasStateChanged_noTransition_returnsFalse | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_noTransition_returnsFalse` |
| TC-HLT-229 | hasStateChanged_motilityTransition_returnsTrue | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_motilityTransition_returnsTrue` |
| TC-HLT-230 | hasStateChanged_nullPreviousStates_firstAssessmentCountsAsChange | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_nullPreviousStates_firstAssessmentCountsAsChange` |
| TC-HLT-231 | hasStateChanged_estrusCrossesThreshold_returnsTrue | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_estrusCrossesThreshold_returnsTrue` |
| TC-HLT-232 | hasStateChanged_estrusFluctuatesBelowThreshold_returnsFalse | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_estrusFluctuatesBelowThreshold_returnsFalse` |
| TC-HLT-233 | multipleAlarmingDimensions_createOneTicketPerType | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::multipleAlarmingDimensions_createOneTicketPerType` |
| TC-HLT-234 | calvingRaise_withPriorWithWindow_createsEvidenceTicketKeepingDatagenSource | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_withPriorWithWindow_createsEvidenceTicketKeepingDatagenSource` |
| TC-HLT-235 | calvingRaise_withPriorNoWindow_createsEvidenceTicketAsRuleSource | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_withPriorNoWindow_createsEvidenceTicketAsRuleSource` |
| TC-HLT-236 | calvingRaise_noPriorWithWindow_createsEvidenceTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_noPriorWithWindow_createsEvidenceTicket` |
| TC-HLT-237 | calvingRaise_noPriorNoWindow_missingFeaturesRenderDash | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_noPriorNoWindow_missingFeaturesRenderDash` |
| TC-HLT-238 | calvingRaise_activeTicketExists_skipsDuplicateCreation | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_activeTicketExists_skipsDuplicateCreation` |
| TC-HLT-239 | calvingBelowAlertThreshold_resolvesTicket | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingBelowAlertThreshold_resolvesTicket` |
| TC-HLT-240 | calvingAlarming_followsConfiguredAlertThreshold | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingAlarming_followsConfiguredAlertThreshold` |
| TC-HLT-241 | calvingWindowInstants_formattedInFarmZone | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_formattedInFarmZone` |
| TC-HLT-242 | calvingWindowInstants_missingBound_dropsWindowFromText | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_missingBound_dropsWindowFromText` |
| TC-HLT-243 | calvingWindowInstants_emptyOrInvertedWindow_dropsWindowFromText | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_emptyOrInvertedWindow_dropsWindowFromText` |
| TC-HLT-244 | highScore_writesScore_updatesSnapshot_raisesAiAlertOnce | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::highScore_writesScore_updatesSnapshot_raisesAiAlertOnce` |
| TC-HLT-245 | activeAlertAlreadyExists_doesNotCreateDuplicate | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::activeAlertAlreadyExists_doesNotCreateDuplicate` |
| TC-HLT-246 | scoreBelowHysteresis_resolvesOnlyAiAlerts | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::scoreBelowHysteresis_resolvesOnlyAiAlerts` |
| TC-HLT-247 | nearZeroScore_skipsRowButStillSyncsSnapshotAndDedup | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::nearZeroScore_skipsRowButStillSyncsSnapshotAndDedup` |
| TC-HLT-248 | aiPlatformUnavailable_degradesSilently | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::aiPlatformUnavailable_degradesSilently` |
| TC-HLT-249 | dedupHit_skipsEverything | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::dedupHit_skipsEverything` |
| TC-HLT-250 | abruptChangeMapsToTemperatureAbnormal | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::abruptChangeMapsToTemperatureAbnormal` |
| TC-HLT-251 | midZoneBetweenAlertAndResolveThresholds_neitherCreatesNorResolves | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::midZoneBetweenAlertAndResolveThresholds_neitherCreatesNorResolves` |
| TC-HLT-252 | target id 较大：参与行翻转成 from=target 后标记，工作台解析出 target 为源头 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::targetWithLargerIdIsFlippedAndResolvedAsSource` |
| TC-HLT-253 | target id 较小（对称场景）：行方向不变原地标记，工作台解析出 target | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::targetWithSmallerIdIsMarkedInPlace` |
| TC-HLT-254 | 所有参与行（from/to=target）都标记，无关行不动，contactsGenerated 透传 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::allParticipatingRowsAreMarkedAndUnrelatedRowsUntouched` |
| TC-HLT-255 | windowHours 钳制：null/0→默认 72h，800→720h，5→透传 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::windowHoursClamping` |
| TC-HLT-256 | 重复标记=重算再标记：markedAt 刷新、病种更新、分析被再次调用 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::reMarkRerunsAnalysisAndRefreshesMarkedAt` |
| TC-HLT-257 | 窗口内无 GPS：contactsGenerated=0，标记仍成功且不产生行 | P1 | REQ-IOT-005、REQ-IOT-006、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::noGpsWindowReturnsZeroAndMarksNothing` |
| TC-HLT-258 | unmarkDiseased 行为不变：清空 from=target 行的病种/标记时间 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::unmarkClearsMarkingOnFromRows` |
| TC-HLT-259 | contactsGenerated=0 时响应附 error.epidemicNoGpsWindow 提示码，>0 时无提示 | P1 | REQ-IOT-005、REQ-IOT-006、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::controllerAttachesNoGpsWarningOnlyOnZeroContacts` |
| TC-HLT-260 | processTelemetry_capsule_withTemperatures_expandsTo7Logs | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_withTemperatures_expandsTo7Logs` |
| TC-HLT-261 | processTelemetry_capsule_skipsAlreadyIngestedTemperaturePoint | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_skipsAlreadyIngestedTemperaturePoint` |
| TC-HLT-262 | processTelemetry_capsule_gastricMotilityDividedBy100000 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_gastricMotilityDividedBy100000` |
| TC-HLT-263 | processTelemetry_realCapsule_firstCounterReport_storesCounterWithoutFrequency | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_realCapsule_firstCounterReport_storesCounterWithoutFrequency` |
| TC-HLT-264 | processTelemetry_realCapsule_secondReport_derivesPerMinuteFrequency | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_realCapsule_secondReport_derivesPerMinuteFrequency` |
| TC-HLT-265 | processTelemetry_counterReset_negativeDelta_noFrequencyNoAssessment | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_counterReset_negativeDelta_noFrequencyNoAssessment` |
| TC-HLT-266 | processTelemetry_counterWindow_tooLong_noFrequency | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_counterWindow_tooLong_noFrequency` |
| TC-HLT-267 | processTelemetry_capsuleWithoutLivestock_persistsDeviceSeriesWithoutSnapshot | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsuleWithoutLivestock_persistsDeviceSeriesWithoutSnapshot` |
| TC-HLT-268 | processTelemetry_tracker_ingestActivityOnly | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_tracker_ingestActivityOnly` |
| TC-HLT-269 | processTelemetry_earTag_ingestGpsDerivedActivity | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_earTag_ingestGpsDerivedActivity` |
| TC-HLT-270 | processTelemetry_capsule_noTemperatures_skipsTempLog | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_noTemperatures_skipsTempLog` |
| TC-HLT-271 | processTelemetry_createsNewSnapshotWhenNotExists | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_createsNewSnapshotWhenNotExists` |
| TC-HLT-272 | processTelemetry_capsule_singleTemperature_fallback | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_singleTemperature_fallback` |
| TC-HLT-273 | processTelemetry_tracker_noActivityData_skipsActivityLog | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_tracker_noActivityData_skipsActivityLog` |
| TC-HLT-274 | processTelemetry_implausibleTemperature_excludedFromAssessment | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_implausibleTemperature_excludedFromAssessment` |
| TC-HLT-275 | processTelemetry_allTemperaturesImplausible_statusAndValueKept | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_allTemperaturesImplausible_statusAndValueKept` |
| TC-HLT-276 | processTelemetry_missingSource_normalizesToUnknown | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_missingSource_normalizesToUnknown` |
| TC-HLT-277 | processTelemetry_thingsBoardSource_isPreserved | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_thingsBoardSource_isPreserved` |
| TC-HLT-278 | processTelemetry_motilityTransition_invokesAlertBridge | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_motilityTransition_invokesAlertBridge` |
| TC-HLT-279 | processTelemetry_steadyState_skipsAlertBridge | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_steadyState_skipsAlertBridge` |
| TC-HLT-280 | feverBoard_groupsAndReconciles | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::feverBoard_groupsAndReconciles` |
| TC-HLT-281 | estrusBoard_highScoreIsAbnormal | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::estrusBoard_highScoreIsAbnormal` |
| TC-HLT-282 | feverTrendUpFromRecentReadings | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::feverTrendUpFromRecentReadings` |
| TC-HLT-283 | aiBandMappedOnRows | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::aiBandMappedOnRows` |
| TC-HLT-284 | healthyRateNeverExceedsOne_andWatchStatesCountUnhealthy | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::healthyRateNeverExceedsOne_andWatchStatesCountUnhealthy` |
| TC-HLT-285 | feverAbnormalIncludesElevatedAndCarriesTicketCount | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::feverAbnormalIncludesElevatedAndCarriesTicketCount` |
| TC-HLT-286 | epidemicHasMarkedSourceReflectsMarkedTraceExistence | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::epidemicHasMarkedSourceReflectsMarkedTraceExistence` |
| TC-HLT-287 | nullTypesQueriesAllSeries | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::nullTypesQueriesAllSeries` |
| TC-HLT-288 | temperatureOnlySkipsMotilityAndActivityRepositories | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::temperatureOnlySkipsMotilityAndActivityRepositories` |
| TC-HLT-289 | unknownTypeYieldsAllEmptySeries | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::unknownTypeYieldsAllEmptySeries` |
| TC-HLT-290 | deviceQuerySupportsBothSeries | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::deviceQuerySupportsBothSeries` |
| TC-HLT-291 | activityReadingsMapDomainFields | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::activityReadingsMapDomainFields` |
| TC-HLT-292 | updateKeepsStoredNoteWhenKeyAbsentOrNull | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateKeepsStoredNoteWhenKeyAbsentOrNull` |
| TC-HLT-293 | updateClearsNoteOnPresentBlankString | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateClearsNoteOnPresentBlankString` |
| TC-HLT-294 | updateReplacesNoteOnNonBlankValue | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateReplacesNoteOnNonBlankValue` |
| TC-HLT-295 | updateStillRejectsNoteOver500Characters | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateStillRejectsNoteOver500Characters` |
| TC-HLT-296 | updateMapsUniqueIndexRaceToStateConflict | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateMapsUniqueIndexRaceToStateConflict` |
| TC-HLT-297 | breedingEventLinksEstrusAlertsInlineWithoutTransactionSync | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::breedingEventLinksEstrusAlertsInlineWithoutTransactionSync` |
| TC-HLT-298 | breedingEventDefersLinkingUntilAfterCommit | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::breedingEventDefersLinkingUntilAfterCommit` |
| TC-HLT-299 | nonBreedingEventDoesNotLinkEstrusAlerts | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::nonBreedingEventDoesNotLinkEstrusAlerts` |
| TC-HLT-300 | listEventsExcludesEstrusConfirmAuditRows | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::listEventsExcludesEstrusConfirmAuditRows` |
| TC-HLT-301 | singleIllnessWithoutRecoveryStaysOpen | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::singleIllnessWithoutRecoveryStaysOpen` |
| TC-HLT-302 | illnessThenRecoveryCloses | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::illnessThenRecoveryCloses` |
| TC-HLT-303 | twoNestedPairsCloseInnerFirst | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::twoNestedPairsCloseInnerFirst` |
| TC-HLT-304 | recoveryBeforeIllnessIsIgnoredAndInputOrderDoesNotMatter | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::recoveryBeforeIllnessIsIgnoredAndInputOrderDoesNotMatter` |
| TC-HLT-305 | surplusRecoveryDoesNotFormAWindow | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::surplusRecoveryDoesNotFormAWindow` |
| TC-HLT-306 | nonIllnessLaneEventsAreIgnored | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::nonIllnessLaneEventsAreIgnored` |
| TC-HLT-307 | emptyInputYieldsNoWindows | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::emptyInputYieldsNoWindows` |
| TC-HLT-308 | inProgressDispositionProjectsAsOpenIllnessWindow | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::inProgressDispositionProjectsAsOpenIllnessWindow` |
| TC-HLT-309 | farmBatchWindowsAreIsolatedPerLivestock | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::farmBatchWindowsAreIsolatedPerLivestock` |
| TC-HLT-310 | alertConfirmMilestoneDoesNotDriveStage | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::alertConfirmMilestoneDoesNotDriveStage` |
| TC-HLT-311 | recentManualCalvingYieldsLactatingStage | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::recentManualCalvingYieldsLactatingStage` |
| TC-HLT-312 | resolvesTicketWhenStateRecovered | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::resolvesTicketWhenStateRecovered` |
| TC-HLT-313 | keepsTicketWhenStillAbnormalAndSkipsMissingSnapshot | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::keepsTicketWhenStillAbnormalAndSkipsMissingSnapshot` |
| TC-HLT-314 | estrusTicketResolvedWhenScoreDropped | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::estrusTicketResolvedWhenScoreDropped` |
| TC-HLT-315 | calvingTicket_resolvedWhenScoreClearedOrBelowRelease_keptInHoldBand | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::calvingTicket_resolvedWhenScoreClearedOrBelowRelease_keptInHoldBand` |
| TC-HLT-316 | healthTypes_includeCalvingWarning | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::healthTypes_includeCalvingWarning` |
| TC-HLT-317 | learnsElevatedIndividualFromDefaultColdStart | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::learnsElevatedIndividualFromDefaultColdStart` |
| TC-HLT-318 | feverAlertWindowExcludesSampleWhenPreviousSourceIsLearned | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::feverAlertWindowExcludesSampleWhenPreviousSourceIsLearned` |
| TC-HLT-319 | defaultColdStartDoesNotVetoHighSampleAsFeverAlert | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::defaultColdStartDoesNotVetoHighSampleAsFeverAlert` |
| TC-HLT-320 | slowFeverRampIsRobustOutlierAndDoesNotRaiseBaseline | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::slowFeverRampIsRobustOutlierAndDoesNotRaiseBaseline` |
| TC-HLT-321 | drinkingWindowExcludesTroughVicinityButKeepsRecoveredSamples | P1 | REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::drinkingWindowExcludesTroughVicinityButKeepsRecoveredSamples` |
| TC-HLT-322 | offBodyReadingIsRejectedAsImplausible | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::offBodyReadingIsRejectedAsImplausible` |
| TC-HLT-323 | datagenAndUnknownSourcesAreNeverAdmitted | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::datagenAndUnknownSourcesAreNeverAdmitted` |
| TC-HLT-324 | duplicateFramesCountExactlyOnce | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::duplicateFramesCountExactlyOnce` |
| TC-HLT-325 | activityModeClassifiesHighLowAndMissingActivity | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::activityModeClassifiesHighLowAndMissingActivity` |
| TC-HLT-326 | withoutAnyActivityNightSamplesAreKeptAndDaySamplesDropped | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::withoutAnyActivityNightSamplesAreKeptAndDaySamplesDropped` |
| TC-HLT-327 | windowBoundariesAreHalfOpen | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::windowBoundariesAreHalfOpen` |
| TC-HLT-328 | insufficientQualifiedDaysKeepPreviousSourceAndBaseline | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::insufficientQualifiedDaysKeepPreviousSourceAndBaseline` |
| TC-HLT-329 | shuffledInputProducesIdenticalOutcome | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::shuffledInputProducesIdenticalOutcome` |
| TC-HLT-330 | zeroMadFallsBackToMadFloorAndKeepsIdenticalSamples | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::zeroMadFallsBackToMadFloorAndKeepsIdenticalSamples` |
| TC-HLT-331 | denseBackfillDayDoesNotDominateBaseline | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::denseBackfillDayDoesNotDominateBaseline` |
| TC-HLT-332 | bandStrictlySurroundsBaselineAtFixedScale | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::bandStrictlySurroundsBaselineAtFixedScale` |
| TC-HLT-333 | relearnUnderLearnedSourceUpdatesValuesWithoutFlip | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::relearnUnderLearnedSourceUpdatesValuesWithoutFlip` |
| TC-HLT-334 | tempDropScore_mapsFourRungsAtExactBoundaries | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::tempDropScore_mapsFourRungsAtExactBoundaries` |
| TC-HLT-335 | tempDropScore_negativeDropFromReboundClampsToZero | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::tempDropScore_negativeDropFromReboundClampsToZero` |
| TC-HLT-336 | score_nullTempDropIsUnavailable_whileNegativeTempDropKeepsItsWeight | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_nullTempDropIsUnavailable_whileNegativeTempDropKeepsItsWeight` |
| TC-HLT-337 | computeTempDrop_samePhaseWindowsCountWithEqualWeight | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_samePhaseWindowsCountWithEqualWeight` |
| TC-HLT-338 | computeTempDrop_roundsHalfUpToTwoDecimals | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_roundsHalfUpToTwoDecimals` |
| TC-HLT-339 | computeTempDrop_underSampledReferenceWindowIsSkipped | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_underSampledReferenceWindowIsSkipped` |
| TC-HLT-340 | computeTempDrop_allReferenceWindowsUnderSampled_isUnavailable | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_allReferenceWindowsUnderSampled_isUnavailable` |
| TC-HLT-341 | computeTempDrop_currentWindowGuardIsEightSamples | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_currentWindowGuardIsEightSamples` |
| TC-HLT-342 | computeTempDrop_staleWindowSelectsNewestCleanWindowWithAnchoredReferences | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_staleWindowSelectsNewestCleanWindowWithAnchoredReferences` |
| TC-HLT-343 | computeTempDrop_referenceAnchoredToObservationWindow_circadianCancels | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_referenceAnchoredToObservationWindow_circadianCancels` |
| TC-HLT-344 | computeTempDrop_staleLagBoundary_inclusiveAtLimitNullBeyond | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_staleLagBoundary_inclusiveAtLimitNullBeyond` |
| TC-HLT-345 | computeActivityRatio_samePhaseWindowsCountWithEqualWeight | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_samePhaseWindowsCountWithEqualWeight` |
| TC-HLT-346 | computeActivityRatio_nullActivityIndexSamplesAreSkipped | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_nullActivityIndexSamplesAreSkipped` |
| TC-HLT-347 | computeActivityRatio_insufficientOrZeroReference_isUnavailable | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_insufficientOrZeroReference_isUnavailable` |
| TC-HLT-348 | activityRatioScore_mapsThreeRungsAtExactBoundaries | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::activityRatioScore_mapsThreeRungsAtExactBoundaries` |
| TC-HLT-349 | score_nullActivityRatioIsUnavailable | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_nullActivityRatioIsUnavailable` |
| TC-HLT-350 | classifyPrior_bandBoundaries | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::classifyPrior_bandBoundaries` |
| TC-HLT-351 | score_priorNormal_handComputedFullWeightOracle | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorNormal_handComputedFullWeightOracle` |
| TC-HLT-352 | score_priorSuppressed_scoresZeroAndHalvesTheComposite | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorSuppressed_scoresZeroAndHalvesTheComposite` |
| TC-HLT-353 | score_priorNeutral_renormalizesTempAndActivityWeights | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorNeutral_renormalizesTempAndActivityWeights` |
| TC-HLT-354 | score_priorSwitchedOff_ignoresGestationEntirely | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorSwitchedOff_ignoresGestationEntirely` |
| TC-HLT-355 | score_noTemperature_activityOnlyIsCappedAtPromptLevel | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_noTemperature_activityOnlyIsCappedAtPromptLevel` |
| TC-HLT-356 | score_temperatureAvailable_twoChannelScoresAreNotCapped | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_temperatureAvailable_twoChannelScoresAreNotCapped` |
| TC-HLT-357 | score_noTemperatureWithSuppressedPrior_suppressionThenCap | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_noTemperatureWithSuppressedPrior_suppressionThenCap` |
| TC-HLT-358 | score_reboundAddsFixedBonusOnlyWhileTheSwitchIsOn | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_reboundAddsFixedBonusOnlyWhileTheSwitchIsOn` |
| TC-HLT-359 | score_allChannelsMaxedPlusRebound_clampsAt100 | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_allChannelsMaxedPlusRebound_clampsAt100` |
| TC-HLT-360 | score_allChannelsZero_isZero | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_allChannelsZero_isZero` |
| TC-HLT-361 | isReboundDetected_dropThenRiseAcrossBlocks_detected | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_dropThenRiseAcrossBlocks_detected` |
| TC-HLT-362 | isReboundDetected_switchOff_alwaysFalse | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_switchOff_alwaysFalse` |
| TC-HLT-363 | isReboundDetected_riseBelowThreshold_false | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_riseBelowThreshold_false` |
| TC-HLT-364 | isReboundDetected_insufficientSamples_false | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_insufficientSamples_false` |
| TC-HLT-365 | excludeWindows_removesSamplesInsideHalfOpenWindow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_removesSamplesInsideHalfOpenWindow` |
| TC-HLT-366 | excludeWindows_nullOrEmptyWindows_returnInputUnchanged | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_nullOrEmptyWindows_returnInputUnchanged` |
| TC-HLT-367 | excludeWindows_unorderedAndOverlappingWindows_allApplied | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_unorderedAndOverlappingWindows_allApplied` |
| TC-HLT-368 | filterPlausible_boundsInclusive_outsideAndNullRemoved | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_boundsInclusive_outsideAndNullRemoved` |
| TC-HLT-369 | filterPlausible_boundsComeFromTheConfiguredBand | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_boundsComeFromTheConfiguredBand` |
| TC-HLT-370 | filterPlausible_emptyAndNullInput | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_emptyAndNullInput` |
| TC-HLT-371 | detectOnset_gradualDecline_triggersWhenTrailingLevelCrossesThreshold | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_gradualDecline_triggersWhenTrailingLevelCrossesThreshold` |
| TC-HLT-372 | detectOnset_drinkingValley_noTriggerOnceTheDrinkingWindowIsExcluded | P1 | REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_drinkingValley_noTriggerOnceTheDrinkingWindowIsExcluded` |
| TC-HLT-373 | detectOnset_levelLowForFewerThanTwoEvaluationPoints_doesNotTrigger | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_levelLowForFewerThanTwoEvaluationPoints_doesNotTrigger` |
| TC-HLT-374 | detectOnset_noiseAroundFlatLevel_doesNotTrigger | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_noiseAroundFlatLevel_doesNotTrigger` |
| TC-HLT-375 | detectOnset_duplicateTimestampsFormOneEvaluationPoint | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_duplicateTimestampsFormOneEvaluationPoint` |
| TC-HLT-376 | detectOnset_ignoresSamplesAtOrAfterNow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_ignoresSamplesAtOrAfterNow` |
| TC-HLT-377 | detectOnset_underSampledPointsAreSkipped_runCarriesOverAGap | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_underSampledPointsAreSkipped_runCarriesOverAGap` |
| TC-HLT-378 | detectOnset_circadianOnly_noFalseOnsetWithPerPointReference | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_circadianOnly_noFalseOnsetWithPerPointReference` |
| TC-HLT-379 | detectOnset_referenceUnavailableOrNoInput_returnsEmpty | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_referenceUnavailableOrNoInput_returnsEmpty` |
| TC-HLT-380 | estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity` |
| TC-HLT-381 | estimateWindow_defaultOnsetWindowCoversCalvingOfSimulatedDecline | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_defaultOnsetWindowCoversCalvingOfSimulatedDecline` |
| TC-HLT-382 | estimateWindow_activityPath_whenNoOnset | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_activityPath_whenNoOnset` |
| TC-HLT-383 | estimateWindow_noOnsetNoActivity_returnsEmptyWindow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_noOnsetNoActivity_returnsEmptyWindow` |
| TC-HLT-384 | estimateWindow_priorWindowIntersectsSignsWindow | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowIntersectsSignsWindow` |
| TC-HLT-385 | estimateWindow_priorWindowBeforeSigns_keepsSignsWindowAndFlagsConflict | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowBeforeSigns_keepsSignsWindowAndFlagsConflict` |
| TC-HLT-386 | estimateWindow_priorWindowEntirelyLaterThanSigns_keepsSignsWindowAndFlagsConflict | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowEntirelyLaterThanSigns_keepsSignsWindowAndFlagsConflict` |
| TC-HLT-387 | estimateWindow_withoutGestationOrWithPriorOff_returnsSignsWindowUnclipped | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_withoutGestationOrWithPriorOff_returnsSignsWindowUnclipped` |
| TC-HLT-388 | transition_exhaustiveCombinationTable_matchesDocumentedSemantics | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::transition_exhaustiveCombinationTable_matchesDocumentedSemantics` |
| TC-HLT-389 | transition_persistenceOne_singleCrossingRaisesWithoutPrev | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::transition_persistenceOne_singleCrossingRaisesWithoutPrev` |
| TC-HLT-390 | storeColumn_writeOnlyWhenValueActuallyChanges | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::storeColumn_writeOnlyWhenValueActuallyChanges` |
| TC-HLT-391 | crossedAlert_persistenceRuleDecisionBoundary | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::crossedAlert_persistenceRuleDecisionBoundary` |
| TC-HLT-392 | clinicalFloor_guardrail_preventsFalseAbnormalOnSlowButHealthyCattle | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-004、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::clinicalFloor_guardrail_preventsFalseAbnormalOnSlowButHealthyCattle` |
| TC-HLT-393 | highBaseline_abnormalLineCappedAtClinicalFloor | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::highBaseline_abnormalLineCappedAtClinicalFloor` |
| TC-HLT-394 | lowBaseline_relativeRuleStillWinsBelowFloor | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::lowBaseline_relativeRuleStillWinsBelowFloor` |
| TC-HLT-395 | defaultBaseline_twoContractionBand | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::defaultBaseline_twoContractionBand` |
| TC-HLT-396 | normalBand_unchanged | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::normalBand_unchanged` |
| TC-HLT-397 | nullFrequency_normal | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::nullFrequency_normal` |
| TC-HLT-398 | directRecentHighRiskWithHealthSignalIsolatesWithinTwoHours | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directRecentHighRiskWithHealthSignalIsolatesWithinTwoHours` |
| TC-HLT-399 | directRecentVeryHighRiskWithoutHealthSignalRequiresImmediateCheck | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directRecentVeryHighRiskWithoutHealthSignalRequiresImmediateCheck` |
| TC-HLT-400 | directMediumRiskOrIndirectHighRiskIsObserved | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directMediumRiskOrIndirectHighRiskIsObserved` |
| TC-HLT-401 | olderMediumRiskIsTracked | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::olderMediumRiskIsTracked` |
| TC-HLT-402 | olderOrLowerRiskIsArchived | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::olderOrLowerRiskIsArchived` |
| TC-HLT-403 | remoteLowRiskIsArchived | P1 | REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::remoteLowRiskIsArchived` |
| TC-HLT-404 | ladderScore_mapsDefaultLadderBoundaries | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::ladderScore_mapsDefaultLadderBoundaries` |
| TC-HLT-405 | ladderScore_honorsCustomLadder | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::ladderScore_honorsCustomLadder` |
| TC-HLT-406 | normalized_activityPlusTemp_weightsNormalizeOverAvailableComponents | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_activityPlusTemp_weightsNormalizeOverAvailableComponents` |
| TC-HLT-407 | normalized_activityPlusDistance_weightsNormalizeOverAvailableComponents | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_activityPlusDistance_weightsNormalizeOverAvailableComponents` |
| TC-HLT-408 | normalized_allThreeComponents_fullWeightSum | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_allThreeComponents_fullWeightSum` |
| TC-HLT-409 | normalized_negativeTempDelta_floorsAtZero_notNegativeEvidence | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_negativeTempDelta_floorsAtZero_notNegativeEvidence` |
| TC-HLT-410 | normalized_capsuleOnly_activityPlusTempKnownCase | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_capsuleOnly_activityPlusTempKnownCase` |
| TC-HLT-411 | normalized_allNull_returnsZero | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_allNull_returnsZero` |
| TC-HLT-412 | normalized_nullLadderFallsBackToDefault | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_nullLadderFallsBackToDefault` |
| TC-HLT-413 | normalized_defaultLadderVersusCustomLadder_sameInputsDifferentScores | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_defaultLadderVersusCustomLadder_sameInputsDifferentScores` |
| TC-HLT-414 | legacy_calculateScore_knownCompositeCase | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_knownCompositeCase` |
| TC-HLT-415 | legacy_calculateScore_zeroAndNullInputs | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_zeroAndNullInputs` |
| TC-HLT-416 | legacy_calculateScore_stepOnlyTopBand | P1 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_stepOnlyTopBand` |
| TC-HLT-417 | persistedDelta_critical | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::persistedDelta_critical` |
| TC-HLT-418 | missingDelta_derivedFromTemperatureMinusBaseline_sameTransactionInsert | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_derivedFromTemperatureMinusBaseline_sameTransactionInsert` |
| TC-HLT-419 | missingDelta_elevatedWhenNotSustained | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_elevatedWhenNotSustained` |
| TC-HLT-420 | missingDelta_feverWhenSustained | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_feverWhenSustained` |
| TC-HLT-421 | sustainedDetection_isOrderAgnostic | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::sustainedDetection_isOrderAgnostic` |
| TC-HLT-422 | missingDeltaAndMissingBaseline_returnsNormal | P1 | REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDeltaAndMissingBaseline_returnsNormal` |
| TC-HLT-423 | normalTemperature_returnsNormal | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::normalTemperature_returnsNormal` |
| TC-HLT-424 | absoluteHighTemperature_criticalRegardlessOfDelta | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::absoluteHighTemperature_criticalRegardlessOfDelta` |
| TC-HLT-425 | premiumTenant_openGate_allowed | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::premiumTenant_openGate_allowed` |
| TC-HLT-426 | lockedGate_deniedEvenWhenEnabled | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::lockedGate_deniedEvenWhenEnabled` |
| TC-HLT-427 | disabledGate_denied | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::disabledGate_denied` |
| TC-HLT-428 | missingGate_denied | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::missingGate_denied` |
| TC-HLT-429 | nullTenantOrMissingSubscription_fallsBackToBasicGate | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::nullTenantOrMissingSubscription_fallsBackToBasicGate` |
| TC-HLT-430 | hasFeatureForTenant_neverReadsTenantContext | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::hasFeatureForTenant_neverReadsTenantContext` |
| TC-HLT-431 | hasFeature_stillResolvesThroughTenantContext | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::hasFeature_stillResolvesThroughTenantContext` |
| TC-HLT-432 | farmFound_returnsTenantId | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmFound_returnsTenantId` |
| TC-HLT-433 | farmMissing_empty | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmMissing_empty` |
| TC-HLT-434 | farmWithoutTenant_empty | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmWithoutTenant_empty` |
| TC-HLT-435 | nullFarmId_empty | P1 | REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::nullFarmId_empty` |
| TC-HLT-436 | defaults_matchPlan7dWorkingPointAndPassValidation | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::defaults_matchPlan7dWorkingPointAndPassValidation` |
| TC-HLT-437 | validate_rejectsNonMonotonicLadders | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsNonMonotonicLadders` |
| TC-HLT-438 | validate_rejectsNegativeWeight | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsNegativeWeight` |
| TC-HLT-439 | validate_rejectsBadStaleLagBufferAndPersistence | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsBadStaleLagBufferAndPersistence` |
| TC-HLT-440 | validate_alertPersistencePointsLimitedToOneOrTwo | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_alertPersistencePointsLimitedToOneOrTwo` |
| TC-HLT-441 | validate_rejectsEmptyOrInvertedPlausibilityBand | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsEmptyOrInvertedPlausibilityBand` |
| TC-HLT-442 | validate_rejectsSingleChannelCapAtOrAboveAlertThreshold | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsSingleChannelCapAtOrAboveAlertThreshold` |
| TC-HLT-443 | validate_rejectsReleaseThresholdNotBelowAlertThreshold | P1 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReleaseThresholdNotBelowAlertThreshold` |
| TC-HLT-444 | validate_rejectsInvertedOnsetAndActivityWindows | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsInvertedOnsetAndActivityWindows` |
| TC-HLT-445 | validate_rejectsReferenceOffsetsBreakingSamePhase | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReferenceOffsetsBreakingSamePhase` |
| TC-HLT-446 | validate_rejectsReboundLookbackWithoutThreeWholeBlocks | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReboundLookbackWithoutThreeWholeBlocks` |
| TC-HLT-447 | validate_rejectsPriorBandsOutOfOrder | P1 | REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsPriorBandsOutOfOrder` |
| TC-HLT-448 | submitReturnsFeedbackResultFields | P0 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::submitReturnsFeedbackResultFields` |
| TC-HLT-449 | unknownAlertPassesThroughAs404 | P0 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::unknownAlertPassesThroughAs404` |
| TC-HLT-450 | nonEstrusAlertPassesThroughAs400 | P0 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::nonEstrusAlertPassesThroughAs400` |
| TC-HLT-451 | crossFarmAlertPassesThroughAs403 | P0 | REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::crossFarmAlertPassesThroughAs403` |
| TC-HLT-452 | missingConfirmedFieldIsRejectedAs400 | P0 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::missingConfirmedFieldIsRejectedAs400` |
| TC-HLT-453 | unauthenticatedRequestIsRejectedAs401 | P0 | REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::unauthenticatedRequestIsRejectedAs401` |

## 用例明细（初稿模板）

### TC-HLT-030 dispatchesEachActiveLivestock

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::dispatchesEachActiveLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-031 oneFailingDispatchDoesNotStopTheBatch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::oneFailingDispatchDoesNotStopTheBatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-032 noActiveLivestock_dispatchesNothing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::noActiveLivestock_dispatchesNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-033 disabledFlag_skipsQueryAndDispatch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/CalvingPredictionSchedulerTest.java::disabledFlag_skipsQueryAndDispatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-034 yesterdayWindowUsesShanghaiMidnights

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::yesterdayWindowUsesShanghaiMidnights`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-035 yesterdayWindowFlipsExactlyAtShanghaiMidnight

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::yesterdayWindowFlipsExactlyAtShanghaiMidnight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-036 schedulerBeanExistsByDefaultAndWhenExplicitlyEnabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerBeanExistsByDefaultAndWhenExplicitlyEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-037 schedulerBeanAbsentWhenDrinkingDisabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerBeanAbsentWhenDrinkingDisabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-038 schedulerCarriesConditionalAndScheduledAnnotations

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::schedulerCarriesConditionalAndScheduledAnnotations`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-039 runDelegatesYesterdaysWindowToTheSweep

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/DrinkingEventSchedulerTest.java::runDelegatesYesterdaysWindowToTheSweep`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-040 dispatchesEachActiveLivestockWithItsOwnSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::dispatchesEachActiveLivestockWithItsOwnSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-041 oneFailingLivestockDoesNotStopTheBatch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::oneFailingLivestockDoesNotStopTheBatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-042 noActiveLivestock_dispatchesNothing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::noActiveLivestock_dispatchesNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-043 disabledFlag_skipsQueryAndDispatch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/HealthAnomalySchedulerTest.java::disabledFlag_skipsQueryAndDispatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-044 missingSnapshotThrowsResourceNotFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::missingSnapshotThrowsResourceNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-045 evaluationComparesDefaultAndLearnedOnIdenticalInput

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::evaluationComparesDefaultAndLearnedOnIdenticalInput`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-046 episodeCountMergesConsecutiveHighScoresWithin24h

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::episodeCountMergesConsecutiveHighScoresWithin24h`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-047 windowOverrideClampsToSevenAndFourteenDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::windowOverrideClampsToSevenAndFourteenDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-048 insufficientLearnedCandidateLeavesLearnedSideNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/BaselineEvaluationServiceTest.java::insufficientLearnedCandidateLeavesLearnedSideNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-049 gate_tenantResolutionFails_zeroQueriesZeroWrites

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gate_tenantResolutionFails_zeroQueriesZeroWrites`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-050 gate_featureLocked_zeroQueriesAfterGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gate_featureLocked_zeroQueriesAfterGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-051 firstAssessment_landsScoreWithoutTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::firstAssessment_landsScoreWithoutTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-052 secondAssessment_raisesTicketInOrder_withDatagenSourceAndWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::secondAssessment_raisesTicketInOrder_withDatagenSourceAndWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-053 persistenceOne_firstCrossing_raisesImmediately

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::persistenceOne_firstCrossing_raisesImmediately`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-054 holdBand_activeTicket_keepsTicketAndTracksScore

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::holdBand_activeTicket_keepsTicketAndTracksScore`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-055 release_resolvesTicketAndClearsColumn

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::release_resolvesTicketAndClearsColumn`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-056 subPersistScore_resetsStaleColumnAndWritesNoRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::subPersistScore_resetsStaleColumnAndWritesNoRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-057 steadySameValue_skipsColumnUpdateButWritesRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::steadySameValue_skipsColumnUpdateButWritesRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-058 quietHead_belowPersist_neverTouchesTicketLookup

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::quietHead_belowPersist_neverTouchesTicketLookup`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-059 baselineAudit_learnedStampedWhenConsumed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_learnedStampedWhenConsumed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-060 baselineAudit_forcedDefaultWhenApplyLearnedOff

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_forcedDefaultWhenApplyLearnedOff`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-061 baselineAudit_learnedSnapshotWithoutValue_fallsBackToDefault

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::baselineAudit_learnedSnapshotWithoutValue_fallsBackToDefault`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-062 activityRatio_clampedToColumnUpperBound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::activityRatio_clampedToColumnUpperBound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-063 clampToColumn_saturatesBothEndsAndKeepsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::clampToColumn_saturatesBothEndsAndKeepsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-064 priorConflict_alertTextWithoutWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::priorConflict_alertTextWithoutWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-065 priorNormal_windowDisplayed_withPriorWithWindowEvidence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::priorNormal_windowDisplayed_withPriorWithWindowEvidence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-066 activityMissing_evidenceShowsDashForGap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::activityMissing_evidenceShowsDashForGap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-067 gestation_latestMilestoneCalving_orOverdueOrFuture_priorUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::gestation_latestMilestoneCalving_orOverdueOrFuture_priorUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-068 drinkingExclusion_bufferedWindowsOnTemperatureOnly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::drinkingExclusion_bufferedWindowsOnTemperatureOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IOT-001

### TC-HLT-069 drinkingExclusion_troughBeforeStart_usesStartAsEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::drinkingExclusion_troughBeforeStart_usesStartAsEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-070 alertSource_syntheticActivityMarksTicketDatagen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::alertSource_syntheticActivityMarksTicketDatagen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-071 physiologicalGate_detachedSamplesNeverEnterTemperatureChannel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::physiologicalGate_detachedSamplesNeverEnterTemperatureChannel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-072 evaluateHead_swallowsRepositoryFailure

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionApplicationServiceTest.java::evaluateHead_swallowsRepositoryFailure`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-073 locked calving_warning gate rejects with 403 and never queries data

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::gateLocked_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-074 lists the latest row per livestock with codes, clamped limit and risk-desc order

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::list_sourcingAndOrdering`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-075 snapshot score floor: >=50 listed, <50 and snapshot-less heads dropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingPredictionQueryServiceTest.java::list_snapshotScoreFloor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-076 oracle_handComputedGridScores_episodeAndAvailability

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::oracle_handComputedGridScores_episodeAndAvailability`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-077 drinkingExclusion_invertedRowClippedToStart

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::drinkingExclusion_invertedRowClippedToStart`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-078 replayCadence_pollGridRefusesWhatSamplePacingFabricates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::replayCadence_pollGridRefusesWhatSamplePacingFabricates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-079 episode_raiseAndReleasePairedThroughSharedState

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::episode_raiseAndReleasePairedThroughSharedState`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-080 noLookAhead_samplesAfterNowIgnored

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::noLookAhead_samplesAfterNowIgnored`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-081 drinkingWindowOrder_shuffledInputReplaysIdentical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::drinkingWindowOrder_shuffledInputReplaysIdentical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-082 physiologicalGate_detachedSamplesNeverEnterTemperatureChannel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::physiologicalGate_detachedSamplesNeverEnterTemperatureChannel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-083 emptySeries_replaysToEmptyResult

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::emptySeries_replaysToEmptyResult`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-084 breedingPrior_perGridPointGestationDays_normalSuppressedAndNeutral

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/CalvingSeriesReplayerTest.java::breedingPrior_perGridPointGestationDays_normalSuppressedAndNeutral`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-085 analyzesEveryFarmWithWholeHerdScope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::analyzesEveryFarmWithWholeHerdScope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-086 usesConfiguredRollingWindowAsCutoff

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::usesConfiguredRollingWindowAsCutoff`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-087 singleFarmFailureDoesNotBlockRemainingFarms

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::singleFarmFailureDoesNotBlockRemainingFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-088 scheduledRunDelegatesToFarmsWhenEnabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::scheduledRunDelegatesToFarmsWhenEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-089 disabledSwitchSkipsScheduledRun

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisSchedulerTest.java::disabledSwitchSkipsScheduledRun`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-090 两牛交错轨迹产生接触行，距离/时长/评分字段合理

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::interleavedTrajectoriesProduceContactRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-091 距离阈值边界：29m 计接触，31m 不计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::distanceThresholdBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-092 时长阈值边界：累计 4min 不计，6min 计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::durationThresholdBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-093 已标记行（marked_at 非空）不被分析覆盖

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::markedRowsAreNotOverwritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-094 重复分析幂等：不产生重复行，迟到轨迹数值刷新

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::reAnalysisIsIdempotentAndRefreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-095 指定 livestockId 时只分析该牛参与的牛对

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceIntegrationTest.java::targetedAnalysisOnlyCoversTargetPairs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-096 两牛交错轨迹产生接触行，距离/时长/评分字段合理

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::interleavedTrajectoriesProduceContactRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-097 距离阈值边界：29m 计接触，31m 不计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::distanceThresholdBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-098 时长阈值边界：累计 4min 不计，6min 计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::durationThresholdBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-099 已标记行（markedAt 非空）不被分析覆盖

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::markedRowsAreNotOverwritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-100 重复分析幂等：不产生重复行，迟到轨迹数值刷新

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::reAnalysisIsIdempotentAndRefreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-101 指定 livestockId 时只分析该牛参与的牛对

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::targetedAnalysisOnlyCoversTargetPairs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-102 markDiseased 翻转后的已标记行：重分析不重复插入且疫情语义保留

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::flippedMarkedRowIsNotDuplicatedByReAnalysis`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-103 未标记的翻转行：重分析复用同一行并归一回 min(id)=from 方向

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/ContactAnalysisServiceTest.java::unmarkedFlippedRowIsReusedAndRenormalized`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-104 getSeries_queriesDeviceWindowsAndMapsReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DeviceHealthSeriesApplicationServiceTest.java::getSeries_queriesDeviceWindowsAndMapsReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-105 vShapedValleyDetected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::vShapedValleyDetected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-106 slopeOnlyValleyNotDetected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::slopeOnlyValleyNotDetected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-107 valleyWithoutRecoveryNotDetected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleyWithoutRecoveryNotDetected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-108 valleysTenMinutesApartMergeIntoOne

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysTenMinutesApartMergeIntoOne`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-109 valleysFortyMinutesApartStaySeparate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysFortyMinutesApartStaySeparate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-110 valleysInsideFeverWindowAndBufferDropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::valleysInsideFeverWindowAndBufferDropped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-007

### TC-HLT-111 outOfBodyPointsSkipped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::outOfBodyPointsSkipped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-112 eventCarriesSourceOfItsStartPoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::eventCarriesSourceOfItsStartPoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-113 depthJustMissingBecomesCandidate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::depthJustMissingBecomesCandidate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-114 slowDescentValleyBecomesSingleCandidate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::slowDescentValleyBecomesSingleCandidate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-115 deeperValleyScoresHigherConfidence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::deeperValleyScoresHigherConfidence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-116 longDescentMergesIntoSingleEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::longDescentMergesIntoSingleEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-117 mergeEventsRollingAnchorKeepsGenuineSeparateBouts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::mergeEventsRollingAnchorKeepsGenuineSeparateBouts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-118 midnightCrossingValleyAttributedToStartLocalDay

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::midnightCrossingValleyAttributedToStartLocalDay`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-119 extendWindowsAddsBufferAndKeepsOpenWindowsOpen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::extendWindowsAddsBufferAndKeepsOpenWindowsOpen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-007

### TC-HLT-120 recalcLowerEdgeStartExactlyAtFromMinusOneHourIsIncluded

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcLowerEdgeStartExactlyAtFromMinusOneHourIsIncluded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-121 recalcUpperEdgeStartExactlyAtToPlusOneHourIsExcluded

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcUpperEdgeStartExactlyAtToPlusOneHourIsExcluded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-122 recalcStartBeforeFromMinusOneHourIsExcluded

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventDetectionServiceTest.java::recalcStartBeforeFromMinusOneHourIsExcluded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-123 detectedUnlabeledRowCounts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::detectedUnlabeledRowCounts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-124 rejectedRowNeverCounts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::rejectedRowNeverCounts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-125 candidateCountsOnlyAfterConfirmation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::candidateCountsOnlyAfterConfirmation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-126 manualBackFillCounts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::manualBackFillCounts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-127 listEventsFlagsRowsBelowLowConfidenceThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsFlagsRowsBelowLowConfidenceThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-128 listEventsDefaultsToTheRecentSevenShanghaiDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsDefaultsToTheRecentSevenShanghaiDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-129 listEventsParsesExplicitClosedRange

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsParsesExplicitClosedRange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-130 listEventsRejectsBadRangeAndFuture

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsRejectsBadRangeAndFuture`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-131 listEventsCarriesClippedFeverWindows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsCarriesClippedFeverWindows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-132 listEventsQueriesFeverWindowsOverTheSameRangeAsRows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::listEventsQueriesFeverWindowsOverTheSameRangeAsRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-133 patchLabelAcceptsOnlyConfirmedAndRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::patchLabelAcceptsOnlyConfirmedAndRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-134 patchLabelRejectsUnlabeledAndGarbage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::patchLabelRejectsUnlabeledAndGarbage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-135 manualPostReturnsExistingRowOnRepeat

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingEventServiceTest.java::manualPostReturnsExistingRowOnRepeat`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-136 exportBuildsCsvWithBomHeaderEscapingTimesAndFarmJoin

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportBuildsCsvWithBomHeaderEscapingTimesAndFarmJoin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-137 exportUsesClosedShanghaiWindowPassedToRepository

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportUsesClosedShanghaiWindowPassedToRepository`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-138 exportSkipsTheLivestockLookupWhenNoRowIsBound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportSkipsTheLivestockLookupWhenNoRowIsBound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-139 exportRejectsMissingMalformedInvertedAndFutureRanges

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingLabelExportServiceTest.java::exportRejectsMissingMalformedInvertedAndFutureRanges`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-140 farmUniverseDeduplicatesBindingsIntoSortedFarmSet

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::farmUniverseDeduplicatesBindingsIntoSortedFarmSet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-141 softDeletedLivestockResolveToNoFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::softDeletedLivestockResolveToNoFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-142 emptyBindingUniverseSkipsTheRanchLookup

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::emptyBindingUniverseSkipsTheRanchLookup`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-143 oneFarmFailureDoesNotStopTheSweepAndIsCounted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::oneFarmFailureDoesNotStopTheSweepAndIsCounted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-144 sweepAggregatesDevicesAndEventsAcrossFarms

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::sweepAggregatesDevicesAndEventsAcrossFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-145 deviceModeRecalculatesOneDeviceAfterExistenceCheck

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::deviceModeRecalculatesOneDeviceAfterExistenceCheck`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-146 deviceModeRejectsUnknownDeviceWith404

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::deviceModeRejectsUnknownDeviceWith404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-147 farmModeSweepsEveryFarmAndReportsScope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::farmModeSweepsEveryFarmAndReportsScope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-148 windowIsClosedDateRangeAtShanghaiMidnights

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::windowIsClosedDateRangeAtShanghaiMidnights`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-149 singleDayRangeSpansExactlyOneCowDay

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::singleDayRangeSpansExactlyOneCowDay`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-150 todayAsToIsAllowedButTomorrowIsRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::todayAsToIsAllowedButTomorrowIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-151 missingMalformedOrInvertedRangesAreRejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingRecalculationServiceTest.java::missingMalformedOrInvertedRangesAreRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-152 dailyCountsIsCountedRowsOnlyAndPinsLastDrinkEndAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::dailyCountsIsCountedRowsOnlyAndPinsLastDrinkEndAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-153 weeklyDirectlySumsSevenDaysIncludingFeverLows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::weeklyDirectlySumsSevenDaysIncludingFeverLows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-154 rollingBaselineExcludesFeverCoveredAndLowPointDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::rollingBaselineExcludesFeverCoveredAndLowPointDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-155 baselineWithoutSampleDaysReturnsNullAverage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::baselineWithoutSampleDaysReturnsNullAverage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-156 sampleDayRulePinsBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::sampleDayRulePinsBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-157 feverCoverageMergesOverlapsAndClampsAtDayBounds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::feverCoverageMergesOverlapsAndClampsAtDayBounds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-158 cowDayBoundarySplitsAtUtcSixteen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::cowDayBoundarySplitsAtUtcSixteen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-159 summaryValidatesDaysAndDate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::summaryValidatesDaysAndDate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-160 summaryRejectsLivestockOfAnotherFarm

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::summaryRejectsLivestockOfAnotherFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-IDT-001

### TC-HLT-161 peerComparisonChecksPremiumBeforeAnythingElse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonChecksPremiumBeforeAnythingElse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-162 peerComparisonWithoutOtherGroupMembersDegradesToInsufficientPeers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonWithoutOtherGroupMembersDegradesToInsufficientPeers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-163 peerComparisonAveragesQualifiedPeersAndExcludesTarget

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonAveragesQualifiedPeersAndExcludesTarget`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-164 peerComparisonDegradesWhenNoPeerReachesMinSampleDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/DrinkingSummaryServiceTest.java::peerComparisonDegradesWhenNoPeerReachesMinSampleDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-165 opensFarmWarningAboveTenPercent_andDeduplicates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::opensFarmWarningAboveTenPercent_andDeduplicates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-166 doesNotDuplicateWhenFarmWarningAlreadyActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::doesNotDuplicateWhenFarmWarningAlreadyActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-167 resolvesBelowFivePercent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::resolvesBelowFivePercent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-168 hysteresisBand_keepsWarningBetweenFiveAndTenPercent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::hysteresisBand_keepsWarningBetweenFiveAndTenPercent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-169 disabledSkipsScheduledRun

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EpidemicAlertServiceTest.java::disabledSkipsScheduledRun`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-170 learnedBaseline_consumedByScoring_andAudited

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::learnedBaseline_consumedByScoring_andAudited`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-171 applyLearnedFalse_rollsBackToDefaultBaseline_everywhere

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::applyLearnedFalse_rollsBackToDefaultBaseline_everywhere`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-172 defaultColdStart_scoresWithFixedBaseline_andStampsDefault

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::defaultColdStart_scoresWithFixedBaseline_andStampsDefault`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-173 feverDurationChart_judgesEachRowByItsOwnDelta

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::feverDurationChart_judgesEachRowByItsOwnDelta`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-174 feverDurationChart_allDefaultRows_matchLegacyFixedThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::feverDurationChart_allDefaultRows_matchLegacyFixedThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-175 ingest_withSwitchOff_newLogsCarryDefaultBaseline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusBaselineConsumptionTest.java::ingest_withSwitchOff_newLogsCarryDefaultBaseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-176 confirmWritesEpisodeBackedLabelAndAuditEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::confirmWritesEpisodeBackedLabelAndAuditEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-177 restoreFailureFallsBackToAlertPointWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::restoreFailureFallsBackToAlertPointWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-178 sameVerdictRepeatIsIdempotentWithZeroWrites

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::sameVerdictRepeatIsIdempotentWithZeroWrites`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-179 flippedVerdictSupersedesOldRowAndInsertsNewOne

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::flippedVerdictSupersedesOldRowAndInsertsNewOne`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-180 rejectedRepeatIsAlsoIdempotentWithZeroWrites

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::rejectedRepeatIsAlsoIdempotentWithZeroWrites`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-181 reconfirmAfterRejectSupersedesRejectedRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::reconfirmAfterRejectSupersedesRejectedRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-182 unknownAlertThrows404

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::unknownAlertThrows404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-183 nonEstrusAlertThrows400

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::nonEstrusAlertThrows400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-184 crossFarmAlertThrows403

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::crossFarmAlertThrows403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-185 physiologyEventUniqueRaceRereadsExistingRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::physiologyEventUniqueRaceRereadsExistingRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-186 breedingWindowDerivesLabelsWithoutVerdict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingWindowDerivesLabelsWithoutVerdict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-187 breedingLinkingSkipsAlertsWithHumanVerdict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingLinkingSkipsAlertsWithHumanVerdict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-188 breedingLinkingContinuesPastSingleFailure

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::breedingLinkingContinuesPastSingleFailure`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-189 estrusConfirmIsNotAStageType

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusFeedbackServiceTest.java::estrusConfirmIsNotAStageType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-190 legacyMode_producesPreNormalizationRow_unchanged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::legacyMode_producesPreNormalizationRow_unchanged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-191 normalized_crossingNotifiesAlertBridge_snapshotInstanceCarriesFlip

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_crossingNotifiesAlertBridge_snapshotInstanceCarriesFlip`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-192 normalized_dayBoundaryStraddle_meanMeanKeepsCleanCowQuiet

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_dayBoundaryStraddle_meanMeanKeepsCleanCowQuiet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-193 normalized_ratioOne_lowScore_columnsCarryIncreaseAndMeterDelta

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioOne_lowScore_columnsCarryIncreaseAndMeterDelta`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-194 normalized_ratioThree_crossesHighThreshold_stepIncreaseColumn200

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioThree_crossesHighThreshold_stepIncreaseColumn200`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-195 normalized_crossingWithDistance_persistsFeatureVersionAndConstructedRatio

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_crossingWithDistance_persistsFeatureVersionAndConstructedRatio`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-196 normalized_distanceRatioBeyondColumn_clampedToDecimal6_3Bound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_distanceRatioBeyondColumn_clampedToDecimal6_3Bound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-197 normalized_distanceRatioJustBelowRung_flooredNotRoundedOntoRung

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_distanceRatioJustBelowRung_flooredNotRoundedOntoRung`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-198 normalized_ratioBelowOne_negativeIncreaseAndNegativeMeterDelta

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_ratioBelowOne_negativeIncreaseAndNegativeMeterDelta`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-199 normalized_capsuleOnly_activityIndexScored_distanceColumnNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_capsuleOnly_activityIndexScored_distanceColumnNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-200 normalized_earTagFallback_stepCountChannelUsed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_earTagFallback_stepCountChannelUsed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-201 guard_currentWindowSamplesBelowMin_noRowWritten

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_currentWindowSamplesBelowMin_noRowWritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004

### TC-HLT-202 guard_tooFewTemperatureSamples_noRowWritten

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_tooFewTemperatureSamples_noRowWritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-203 guard_baselineWindowsAllUnqualified_noRowWritten

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_baselineWindowsAllUnqualified_noRowWritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004

### TC-HLT-204 guard_noTemperatureAnchor_noRowWritten

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::guard_noTemperatureAnchor_noRowWritten`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-205 normalized_snapshotEstrusScoreUpdated

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::normalized_snapshotEstrusScoreUpdated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-206 keepsNewestLimitRowsAndDropsOldest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::keepsNewestLimitRowsAndDropsOldest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-207 limitLargerThanWindowReturnsAllRows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusNormalizedScoringTest.java::limitLargerThanWindowReturnsAllRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-208 legacy_knownRow_breakdownAndWeightedSumRecompute

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::legacy_knownRow_breakdownAndWeightedSumRecompute`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-209 legacy_nullTempAndDistance_componentsZeroWeightsKept

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::legacy_nullTempAndDistance_componentsZeroWeightsKept`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-210 normalized_negativeTempClamped_distanceAbsent_weightsRenormalized

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::normalized_negativeTempClamped_distanceAbsent_weightsRenormalized`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-211 normalized_allComponentsPresent_fullWeights

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::normalized_allComponentsPresent_fullWeights`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-212 nullFeatureVersion_returnsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusScoreExplainerTest.java::nullFeatureVersion_returnsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-213 legacyReplayMatchesHandComputedOracle

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::legacyReplayMatchesHandComputedOracle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-214 normalizedCrossingScoresAndProducesEpisode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedCrossingScoresAndProducesEpisode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-215 normalizedQuietSequenceProducesNoEpisode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedQuietSequenceProducesNoEpisode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-216 normalizedExcludesAnchorTimestampedActivityFrame

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedExcludesAnchorTimestampedActivityFrame`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-217 normalizedSparseBaselineWindowsSkipPosition

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedSparseBaselineWindowsSkipPosition`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-218 normalizedSidesShareActivityFactorAndDifferByBaseline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::normalizedSidesShareActivityFactorAndDifferByBaseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-219 modeDispatchSelectsExactlyOneKernel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/EstrusSeriesReplayerNormalizedTest.java::modeDispatchSelectsExactlyOneKernel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-220 tempCritical_noActiveAlert_createsCriticalTemperatureTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempCritical_noActiveAlert_createsCriticalTemperatureTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-221 tempElevated_createsWarningTemperatureTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempElevated_createsWarningTemperatureTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-222 tempAlarming_activeAlertExists_skipsDuplicateCreation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempAlarming_activeAlertExists_skipsDuplicateCreation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-223 tempBackToNormal_resolvesTemperatureTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::tempBackToNormal_resolvesTemperatureTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-224 motilityAbnormal_createsDigestiveTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::motilityAbnormal_createsDigestiveTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-225 motilityLow_doesNotCreateDigestiveTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::motilityLow_doesNotCreateDigestiveTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-226 estrusAtThreshold_createsEstrusTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::estrusAtThreshold_createsEstrusTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-227 estrusBelowThreshold_resolvesEstrusTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::estrusBelowThreshold_resolvesEstrusTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-228 hasStateChanged_noTransition_returnsFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_noTransition_returnsFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-229 hasStateChanged_motilityTransition_returnsTrue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_motilityTransition_returnsTrue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-230 hasStateChanged_nullPreviousStates_firstAssessmentCountsAsChange

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_nullPreviousStates_firstAssessmentCountsAsChange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-231 hasStateChanged_estrusCrossesThreshold_returnsTrue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_estrusCrossesThreshold_returnsTrue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-232 hasStateChanged_estrusFluctuatesBelowThreshold_returnsFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::hasStateChanged_estrusFluctuatesBelowThreshold_returnsFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-233 multipleAlarmingDimensions_createOneTicketPerType

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::multipleAlarmingDimensions_createOneTicketPerType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-234 calvingRaise_withPriorWithWindow_createsEvidenceTicketKeepingDatagenSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_withPriorWithWindow_createsEvidenceTicketKeepingDatagenSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-235 calvingRaise_withPriorNoWindow_createsEvidenceTicketAsRuleSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_withPriorNoWindow_createsEvidenceTicketAsRuleSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-236 calvingRaise_noPriorWithWindow_createsEvidenceTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_noPriorWithWindow_createsEvidenceTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-237 calvingRaise_noPriorNoWindow_missingFeaturesRenderDash

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_noPriorNoWindow_missingFeaturesRenderDash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-238 calvingRaise_activeTicketExists_skipsDuplicateCreation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingRaise_activeTicketExists_skipsDuplicateCreation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-239 calvingBelowAlertThreshold_resolvesTicket

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingBelowAlertThreshold_resolvesTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-240 calvingAlarming_followsConfiguredAlertThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingAlarming_followsConfiguredAlertThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-241 calvingWindowInstants_formattedInFarmZone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_formattedInFarmZone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-242 calvingWindowInstants_missingBound_dropsWindowFromText

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_missingBound_dropsWindowFromText`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-243 calvingWindowInstants_emptyOrInvertedWindow_dropsWindowFromText

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAlertBridgeServiceTest.java::calvingWindowInstants_emptyOrInvertedWindow_dropsWindowFromText`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-244 highScore_writesScore_updatesSnapshot_raisesAiAlertOnce

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::highScore_writesScore_updatesSnapshot_raisesAiAlertOnce`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-245 activeAlertAlreadyExists_doesNotCreateDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::activeAlertAlreadyExists_doesNotCreateDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-246 scoreBelowHysteresis_resolvesOnlyAiAlerts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::scoreBelowHysteresis_resolvesOnlyAiAlerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-247 nearZeroScore_skipsRowButStillSyncsSnapshotAndDedup

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::nearZeroScore_skipsRowButStillSyncsSnapshotAndDedup`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-248 aiPlatformUnavailable_degradesSilently

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::aiPlatformUnavailable_degradesSilently`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-249 dedupHit_skipsEverything

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::dedupHit_skipsEverything`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-250 abruptChangeMapsToTemperatureAbnormal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::abruptChangeMapsToTemperatureAbnormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-251 midZoneBetweenAlertAndResolveThresholds_neitherCreatesNorResolves

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthAnomalyServiceTest.java::midZoneBetweenAlertAndResolveThresholds_neitherCreatesNorResolves`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-252 target id 较大：参与行翻转成 from=target 后标记，工作台解析出 target 为源头

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::targetWithLargerIdIsFlippedAndResolvedAsSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-253 target id 较小（对称场景）：行方向不变原地标记，工作台解析出 target

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::targetWithSmallerIdIsMarkedInPlace`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-254 所有参与行（from/to=target）都标记，无关行不动，contactsGenerated 透传

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::allParticipatingRowsAreMarkedAndUnrelatedRowsUntouched`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-255 windowHours 钳制：null/0→默认 72h，800→720h，5→透传

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::windowHoursClamping`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-256 重复标记=重算再标记：markedAt 刷新、病种更新、分析被再次调用

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::reMarkRerunsAnalysisAndRefreshesMarkedAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-257 窗口内无 GPS：contactsGenerated=0，标记仍成功且不产生行

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::noGpsWindowReturnsZeroAndMarksNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-HLT-003、REQ-HLT-005

### TC-HLT-258 unmarkDiseased 行为不变：清空 from=target 行的病种/标记时间

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::unmarkClearsMarkingOnFromRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-259 contactsGenerated=0 时响应附 error.epidemicNoGpsWindow 提示码，>0 时无提示

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceMarkDiseasedTest.java::controllerAttachesNoGpsWarningOnlyOnZeroContacts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-HLT-003、REQ-HLT-005

### TC-HLT-260 processTelemetry_capsule_withTemperatures_expandsTo7Logs

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_withTemperatures_expandsTo7Logs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-261 processTelemetry_capsule_skipsAlreadyIngestedTemperaturePoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_skipsAlreadyIngestedTemperaturePoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-262 processTelemetry_capsule_gastricMotilityDividedBy100000

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_gastricMotilityDividedBy100000`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-263 processTelemetry_realCapsule_firstCounterReport_storesCounterWithoutFrequency

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_realCapsule_firstCounterReport_storesCounterWithoutFrequency`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-264 processTelemetry_realCapsule_secondReport_derivesPerMinuteFrequency

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_realCapsule_secondReport_derivesPerMinuteFrequency`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-265 processTelemetry_counterReset_negativeDelta_noFrequencyNoAssessment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_counterReset_negativeDelta_noFrequencyNoAssessment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-266 processTelemetry_counterWindow_tooLong_noFrequency

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_counterWindow_tooLong_noFrequency`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-267 processTelemetry_capsuleWithoutLivestock_persistsDeviceSeriesWithoutSnapshot

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsuleWithoutLivestock_persistsDeviceSeriesWithoutSnapshot`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-268 processTelemetry_tracker_ingestActivityOnly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_tracker_ingestActivityOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-269 processTelemetry_earTag_ingestGpsDerivedActivity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_earTag_ingestGpsDerivedActivity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-HLT-270 processTelemetry_capsule_noTemperatures_skipsTempLog

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_noTemperatures_skipsTempLog`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-271 processTelemetry_createsNewSnapshotWhenNotExists

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_createsNewSnapshotWhenNotExists`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-272 processTelemetry_capsule_singleTemperature_fallback

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_capsule_singleTemperature_fallback`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-273 processTelemetry_tracker_noActivityData_skipsActivityLog

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_tracker_noActivityData_skipsActivityLog`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-274 processTelemetry_implausibleTemperature_excludedFromAssessment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_implausibleTemperature_excludedFromAssessment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-275 processTelemetry_allTemperaturesImplausible_statusAndValueKept

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_allTemperaturesImplausible_statusAndValueKept`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-276 processTelemetry_missingSource_normalizesToUnknown

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_missingSource_normalizesToUnknown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-277 processTelemetry_thingsBoardSource_isPreserved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_thingsBoardSource_isPreserved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-278 processTelemetry_motilityTransition_invokesAlertBridge

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_motilityTransition_invokesAlertBridge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-279 processTelemetry_steadyState_skipsAlertBridge

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthApplicationServiceTelemetryTest.java::processTelemetry_steadyState_skipsAlertBridge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-HLT-280 feverBoard_groupsAndReconciles

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::feverBoard_groupsAndReconciles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-281 estrusBoard_highScoreIsAbnormal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::estrusBoard_highScoreIsAbnormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-282 feverTrendUpFromRecentReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::feverTrendUpFromRecentReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-283 aiBandMappedOnRows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthEpisodeServiceTest.java::aiBandMappedOnRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-284 healthyRateNeverExceedsOne_andWatchStatesCountUnhealthy

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::healthyRateNeverExceedsOne_andWatchStatesCountUnhealthy`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-285 feverAbnormalIncludesElevatedAndCarriesTicketCount

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::feverAbnormalIncludesElevatedAndCarriesTicketCount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-286 epidemicHasMarkedSourceReflectsMarkedTraceExistence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/HealthOverviewFixesTest.java::epidemicHasMarkedSourceReflectsMarkedTraceExistence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-287 nullTypesQueriesAllSeries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::nullTypesQueriesAllSeries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-288 temperatureOnlySkipsMotilityAndActivityRepositories

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::temperatureOnlySkipsMotilityAndActivityRepositories`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-289 unknownTypeYieldsAllEmptySeries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::unknownTypeYieldsAllEmptySeries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-290 deviceQuerySupportsBothSeries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::deviceQuerySupportsBothSeries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-291 activityReadingsMapDomainFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/OpenTelemetryQueryServiceTest.java::activityReadingsMapDomainFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-292 updateKeepsStoredNoteWhenKeyAbsentOrNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateKeepsStoredNoteWhenKeyAbsentOrNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-293 updateClearsNoteOnPresentBlankString

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateClearsNoteOnPresentBlankString`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-294 updateReplacesNoteOnNonBlankValue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateReplacesNoteOnNonBlankValue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-295 updateStillRejectsNoteOver500Characters

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateStillRejectsNoteOver500Characters`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-296 updateMapsUniqueIndexRaceToStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::updateMapsUniqueIndexRaceToStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-297 breedingEventLinksEstrusAlertsInlineWithoutTransactionSync

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::breedingEventLinksEstrusAlertsInlineWithoutTransactionSync`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-298 breedingEventDefersLinkingUntilAfterCommit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::breedingEventDefersLinkingUntilAfterCommit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-299 nonBreedingEventDoesNotLinkEstrusAlerts

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::nonBreedingEventDoesNotLinkEstrusAlerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-300 listEventsExcludesEstrusConfirmAuditRows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyEventServiceTest.java::listEventsExcludesEstrusConfirmAuditRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-301 singleIllnessWithoutRecoveryStaysOpen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::singleIllnessWithoutRecoveryStaysOpen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-302 illnessThenRecoveryCloses

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::illnessThenRecoveryCloses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-303 twoNestedPairsCloseInnerFirst

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::twoNestedPairsCloseInnerFirst`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-304 recoveryBeforeIllnessIsIgnoredAndInputOrderDoesNotMatter

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::recoveryBeforeIllnessIsIgnoredAndInputOrderDoesNotMatter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-305 surplusRecoveryDoesNotFormAWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::surplusRecoveryDoesNotFormAWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-306 nonIllnessLaneEventsAreIgnored

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::nonIllnessLaneEventsAreIgnored`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-307 emptyInputYieldsNoWindows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyPairingTest.java::emptyInputYieldsNoWindows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-308 inProgressDispositionProjectsAsOpenIllnessWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::inProgressDispositionProjectsAsOpenIllnessWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-309 farmBatchWindowsAreIsolatedPerLivestock

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::farmBatchWindowsAreIsolatedPerLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-310 alertConfirmMilestoneDoesNotDriveStage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::alertConfirmMilestoneDoesNotDriveStage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-311 recentManualCalvingYieldsLactatingStage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/PhysiologyQueryServiceTest.java::recentManualCalvingYieldsLactatingStage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-312 resolvesTicketWhenStateRecovered

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::resolvesTicketWhenStateRecovered`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-313 keepsTicketWhenStillAbnormalAndSkipsMissingSnapshot

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::keepsTicketWhenStillAbnormalAndSkipsMissingSnapshot`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-314 estrusTicketResolvedWhenScoreDropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::estrusTicketResolvedWhenScoreDropped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-315 calvingTicket_resolvedWhenScoreClearedOrBelowRelease_keptInHoldBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::calvingTicket_resolvedWhenScoreClearedOrBelowRelease_keptInHoldBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-316 healthTypes_includeCalvingWarning

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/application/service/StaleHealthAlertReconcilerTest.java::healthTypes_includeCalvingWarning`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-317 learnsElevatedIndividualFromDefaultColdStart

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::learnsElevatedIndividualFromDefaultColdStart`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-318 feverAlertWindowExcludesSampleWhenPreviousSourceIsLearned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::feverAlertWindowExcludesSampleWhenPreviousSourceIsLearned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-319 defaultColdStartDoesNotVetoHighSampleAsFeverAlert

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::defaultColdStartDoesNotVetoHighSampleAsFeverAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-320 slowFeverRampIsRobustOutlierAndDoesNotRaiseBaseline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::slowFeverRampIsRobustOutlierAndDoesNotRaiseBaseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-321 drinkingWindowExcludesTroughVicinityButKeepsRecoveredSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::drinkingWindowExcludesTroughVicinityButKeepsRecoveredSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-007、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-322 offBodyReadingIsRejectedAsImplausible

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::offBodyReadingIsRejectedAsImplausible`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-323 datagenAndUnknownSourcesAreNeverAdmitted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::datagenAndUnknownSourcesAreNeverAdmitted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-324 duplicateFramesCountExactlyOnce

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::duplicateFramesCountExactlyOnce`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-325 activityModeClassifiesHighLowAndMissingActivity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::activityModeClassifiesHighLowAndMissingActivity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-326 withoutAnyActivityNightSamplesAreKeptAndDaySamplesDropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::withoutAnyActivityNightSamplesAreKeptAndDaySamplesDropped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-327 windowBoundariesAreHalfOpen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::windowBoundariesAreHalfOpen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-328 insufficientQualifiedDaysKeepPreviousSourceAndBaseline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::insufficientQualifiedDaysKeepPreviousSourceAndBaseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-329 shuffledInputProducesIdenticalOutcome

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::shuffledInputProducesIdenticalOutcome`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-330 zeroMadFallsBackToMadFloorAndKeepsIdenticalSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::zeroMadFallsBackToMadFloorAndKeepsIdenticalSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-331 denseBackfillDayDoesNotDominateBaseline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::denseBackfillDayDoesNotDominateBaseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-332 bandStrictlySurroundsBaselineAtFixedScale

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::bandStrictlySurroundsBaselineAtFixedScale`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-333 relearnUnderLearnedSourceUpdatesValuesWithoutFlip

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/BaselineLearningCalculatorTest.java::relearnUnderLearnedSourceUpdatesValuesWithoutFlip`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-334 tempDropScore_mapsFourRungsAtExactBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::tempDropScore_mapsFourRungsAtExactBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-335 tempDropScore_negativeDropFromReboundClampsToZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::tempDropScore_negativeDropFromReboundClampsToZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-336 score_nullTempDropIsUnavailable_whileNegativeTempDropKeepsItsWeight

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_nullTempDropIsUnavailable_whileNegativeTempDropKeepsItsWeight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-337 computeTempDrop_samePhaseWindowsCountWithEqualWeight

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_samePhaseWindowsCountWithEqualWeight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-338 computeTempDrop_roundsHalfUpToTwoDecimals

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_roundsHalfUpToTwoDecimals`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-339 computeTempDrop_underSampledReferenceWindowIsSkipped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_underSampledReferenceWindowIsSkipped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-340 computeTempDrop_allReferenceWindowsUnderSampled_isUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_allReferenceWindowsUnderSampled_isUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-341 computeTempDrop_currentWindowGuardIsEightSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_currentWindowGuardIsEightSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-IDT-004

### TC-HLT-342 computeTempDrop_staleWindowSelectsNewestCleanWindowWithAnchoredReferences

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_staleWindowSelectsNewestCleanWindowWithAnchoredReferences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-343 computeTempDrop_referenceAnchoredToObservationWindow_circadianCancels

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_referenceAnchoredToObservationWindow_circadianCancels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-344 computeTempDrop_staleLagBoundary_inclusiveAtLimitNullBeyond

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeTempDrop_staleLagBoundary_inclusiveAtLimitNullBeyond`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-345 computeActivityRatio_samePhaseWindowsCountWithEqualWeight

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_samePhaseWindowsCountWithEqualWeight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-346 computeActivityRatio_nullActivityIndexSamplesAreSkipped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_nullActivityIndexSamplesAreSkipped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-347 computeActivityRatio_insufficientOrZeroReference_isUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::computeActivityRatio_insufficientOrZeroReference_isUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-348 activityRatioScore_mapsThreeRungsAtExactBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::activityRatioScore_mapsThreeRungsAtExactBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-349 score_nullActivityRatioIsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_nullActivityRatioIsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-350 classifyPrior_bandBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::classifyPrior_bandBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-351 score_priorNormal_handComputedFullWeightOracle

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorNormal_handComputedFullWeightOracle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-352 score_priorSuppressed_scoresZeroAndHalvesTheComposite

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorSuppressed_scoresZeroAndHalvesTheComposite`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-353 score_priorNeutral_renormalizesTempAndActivityWeights

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorNeutral_renormalizesTempAndActivityWeights`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-354 score_priorSwitchedOff_ignoresGestationEntirely

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_priorSwitchedOff_ignoresGestationEntirely`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-355 score_noTemperature_activityOnlyIsCappedAtPromptLevel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_noTemperature_activityOnlyIsCappedAtPromptLevel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-356 score_temperatureAvailable_twoChannelScoresAreNotCapped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_temperatureAvailable_twoChannelScoresAreNotCapped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-357 score_noTemperatureWithSuppressedPrior_suppressionThenCap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_noTemperatureWithSuppressedPrior_suppressionThenCap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-358 score_reboundAddsFixedBonusOnlyWhileTheSwitchIsOn

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_reboundAddsFixedBonusOnlyWhileTheSwitchIsOn`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-359 score_allChannelsMaxedPlusRebound_clampsAt100

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_allChannelsMaxedPlusRebound_clampsAt100`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-360 score_allChannelsZero_isZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::score_allChannelsZero_isZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-361 isReboundDetected_dropThenRiseAcrossBlocks_detected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_dropThenRiseAcrossBlocks_detected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-362 isReboundDetected_switchOff_alwaysFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_switchOff_alwaysFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-363 isReboundDetected_riseBelowThreshold_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_riseBelowThreshold_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-364 isReboundDetected_insufficientSamples_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::isReboundDetected_insufficientSamples_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-365 excludeWindows_removesSamplesInsideHalfOpenWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_removesSamplesInsideHalfOpenWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-366 excludeWindows_nullOrEmptyWindows_returnInputUnchanged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_nullOrEmptyWindows_returnInputUnchanged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-367 excludeWindows_unorderedAndOverlappingWindows_allApplied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::excludeWindows_unorderedAndOverlappingWindows_allApplied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-368 filterPlausible_boundsInclusive_outsideAndNullRemoved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_boundsInclusive_outsideAndNullRemoved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-369 filterPlausible_boundsComeFromTheConfiguredBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_boundsComeFromTheConfiguredBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-370 filterPlausible_emptyAndNullInput

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::filterPlausible_emptyAndNullInput`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-371 detectOnset_gradualDecline_triggersWhenTrailingLevelCrossesThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_gradualDecline_triggersWhenTrailingLevelCrossesThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-372 detectOnset_drinkingValley_noTriggerOnceTheDrinkingWindowIsExcluded

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_drinkingValley_noTriggerOnceTheDrinkingWindowIsExcluded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-007、REQ-HLT-003、REQ-HLT-005

### TC-HLT-373 detectOnset_levelLowForFewerThanTwoEvaluationPoints_doesNotTrigger

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_levelLowForFewerThanTwoEvaluationPoints_doesNotTrigger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-374 detectOnset_noiseAroundFlatLevel_doesNotTrigger

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_noiseAroundFlatLevel_doesNotTrigger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-375 detectOnset_duplicateTimestampsFormOneEvaluationPoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_duplicateTimestampsFormOneEvaluationPoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-376 detectOnset_ignoresSamplesAtOrAfterNow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_ignoresSamplesAtOrAfterNow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-377 detectOnset_underSampledPointsAreSkipped_runCarriesOverAGap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_underSampledPointsAreSkipped_runCarriesOverAGap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-378 detectOnset_circadianOnly_noFalseOnsetWithPerPointReference

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_circadianOnly_noFalseOnsetWithPerPointReference`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-379 detectOnset_referenceUnavailableOrNoInput_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::detectOnset_referenceUnavailableOrNoInput_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-380 estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_onsetPath_offsetsFromOnsetAndWinsOverActivity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-381 estimateWindow_defaultOnsetWindowCoversCalvingOfSimulatedDecline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_defaultOnsetWindowCoversCalvingOfSimulatedDecline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-382 estimateWindow_activityPath_whenNoOnset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_activityPath_whenNoOnset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-383 estimateWindow_noOnsetNoActivity_returnsEmptyWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_noOnsetNoActivity_returnsEmptyWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-384 estimateWindow_priorWindowIntersectsSignsWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowIntersectsSignsWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-385 estimateWindow_priorWindowBeforeSigns_keepsSignsWindowAndFlagsConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowBeforeSigns_keepsSignsWindowAndFlagsConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-386 estimateWindow_priorWindowEntirelyLaterThanSigns_keepsSignsWindowAndFlagsConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_priorWindowEntirelyLaterThanSigns_keepsSignsWindowAndFlagsConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-387 estimateWindow_withoutGestationOrWithPriorOff_returnsSignsWindowUnclipped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionServiceTest.java::estimateWindow_withoutGestationOrWithPriorOff_returnsSignsWindowUnclipped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-388 transition_exhaustiveCombinationTable_matchesDocumentedSemantics

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::transition_exhaustiveCombinationTable_matchesDocumentedSemantics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-389 transition_persistenceOne_singleCrossingRaisesWithoutPrev

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::transition_persistenceOne_singleCrossingRaisesWithoutPrev`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-390 storeColumn_writeOnlyWhenValueActuallyChanges

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::storeColumn_writeOnlyWhenValueActuallyChanges`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-391 crossedAlert_persistenceRuleDecisionBoundary

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/CalvingPredictionStateTransitionTest.java::crossedAlert_persistenceRuleDecisionBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-392 clinicalFloor_guardrail_preventsFalseAbnormalOnSlowButHealthyCattle

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::clinicalFloor_guardrail_preventsFalseAbnormalOnSlowButHealthyCattle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-004、REQ-PLT-001

### TC-HLT-393 highBaseline_abnormalLineCappedAtClinicalFloor

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::highBaseline_abnormalLineCappedAtClinicalFloor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-394 lowBaseline_relativeRuleStillWinsBelowFloor

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::lowBaseline_relativeRuleStillWinsBelowFloor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-395 defaultBaseline_twoContractionBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::defaultBaseline_twoContractionBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005

### TC-HLT-396 normalBand_unchanged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::normalBand_unchanged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-397 nullFrequency_normal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/DigestiveAnalysisServiceTest.java::nullFrequency_normal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-398 directRecentHighRiskWithHealthSignalIsolatesWithinTwoHours

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directRecentHighRiskWithHealthSignalIsolatesWithinTwoHours`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-399 directRecentVeryHighRiskWithoutHealthSignalRequiresImmediateCheck

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directRecentVeryHighRiskWithoutHealthSignalRequiresImmediateCheck`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-400 directMediumRiskOrIndirectHighRiskIsObserved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::directMediumRiskOrIndirectHighRiskIsObserved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-401 olderMediumRiskIsTracked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::olderMediumRiskIsTracked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-402 olderOrLowerRiskIsArchived

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::olderOrLowerRiskIsArchived`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-403 remoteLowRiskIsArchived

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EpidemicDispositionRulesTest.java::remoteLowRiskIsArchived`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-RCH-001、REQ-RCH-002

### TC-HLT-404 ladderScore_mapsDefaultLadderBoundaries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::ladderScore_mapsDefaultLadderBoundaries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-405 ladderScore_honorsCustomLadder

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::ladderScore_honorsCustomLadder`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-406 normalized_activityPlusTemp_weightsNormalizeOverAvailableComponents

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_activityPlusTemp_weightsNormalizeOverAvailableComponents`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-407 normalized_activityPlusDistance_weightsNormalizeOverAvailableComponents

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_activityPlusDistance_weightsNormalizeOverAvailableComponents`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-408 normalized_allThreeComponents_fullWeightSum

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_allThreeComponents_fullWeightSum`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-409 normalized_negativeTempDelta_floorsAtZero_notNegativeEvidence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_negativeTempDelta_floorsAtZero_notNegativeEvidence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-410 normalized_capsuleOnly_activityPlusTempKnownCase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_capsuleOnly_activityPlusTempKnownCase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-411 normalized_allNull_returnsZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_allNull_returnsZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-412 normalized_nullLadderFallsBackToDefault

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_nullLadderFallsBackToDefault`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-413 normalized_defaultLadderVersusCustomLadder_sameInputsDifferentScores

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::normalized_defaultLadderVersusCustomLadder_sameInputsDifferentScores`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-414 legacy_calculateScore_knownCompositeCase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_knownCompositeCase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-415 legacy_calculateScore_zeroAndNullInputs

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_zeroAndNullInputs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-416 legacy_calculateScore_stepOnlyTopBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/EstrusAnalysisServiceTest.java::legacy_calculateScore_stepOnlyTopBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-PLT-001

### TC-HLT-417 persistedDelta_critical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::persistedDelta_critical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-418 missingDelta_derivedFromTemperatureMinusBaseline_sameTransactionInsert

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_derivedFromTemperatureMinusBaseline_sameTransactionInsert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-419 missingDelta_elevatedWhenNotSustained

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_elevatedWhenNotSustained`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-420 missingDelta_feverWhenSustained

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDelta_feverWhenSustained`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-421 sustainedDetection_isOrderAgnostic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::sustainedDetection_isOrderAgnostic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-422 missingDeltaAndMissingBaseline_returnsNormal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::missingDeltaAndMissingBaseline_returnsNormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-PLT-001、REQ-PLT-002

### TC-HLT-423 normalTemperature_returnsNormal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::normalTemperature_returnsNormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-424 absoluteHighTemperature_criticalRegardlessOfDelta

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/domain/service/FeverAnalysisServiceTest.java::absoluteHighTemperature_criticalRegardlessOfDelta`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-HLT-425 premiumTenant_openGate_allowed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::premiumTenant_openGate_allowed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-426 lockedGate_deniedEvenWhenEnabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::lockedGate_deniedEvenWhenEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-427 disabledGate_denied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::disabledGate_denied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-428 missingGate_denied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::missingGate_denied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-429 nullTenantOrMissingSubscription_fallsBackToBasicGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::nullTenantOrMissingSubscription_fallsBackToBasicGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-430 hasFeatureForTenant_neverReadsTenantContext

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::hasFeatureForTenant_neverReadsTenantContext`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-431 hasFeature_stillResolvesThroughTenantContext

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/HealthSubscriptionPortImplTest.java::hasFeature_stillResolvesThroughTenantContext`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-HLT-432 farmFound_returnsTenantId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmFound_returnsTenantId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-433 farmMissing_empty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmMissing_empty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-434 farmWithoutTenant_empty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::farmWithoutTenant_empty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-435 nullFarmId_empty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/acl/RanchQueryPortImplTest.java::nullFarmId_empty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-IDT-001、REQ-IDT-003

### TC-HLT-436 defaults_matchPlan7dWorkingPointAndPassValidation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::defaults_matchPlan7dWorkingPointAndPassValidation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-CMC-001

### TC-HLT-437 validate_rejectsNonMonotonicLadders

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsNonMonotonicLadders`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-438 validate_rejectsNegativeWeight

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsNegativeWeight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-439 validate_rejectsBadStaleLagBufferAndPersistence

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsBadStaleLagBufferAndPersistence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-HLT-004

### TC-HLT-440 validate_alertPersistencePointsLimitedToOneOrTwo

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_alertPersistencePointsLimitedToOneOrTwo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-441 validate_rejectsEmptyOrInvertedPlausibilityBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsEmptyOrInvertedPlausibilityBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-442 validate_rejectsSingleChannelCapAtOrAboveAlertThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsSingleChannelCapAtOrAboveAlertThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-443 validate_rejectsReleaseThresholdNotBelowAlertThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReleaseThresholdNotBelowAlertThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-004、REQ-HLT-003

### TC-HLT-444 validate_rejectsInvertedOnsetAndActivityWindows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsInvertedOnsetAndActivityWindows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-445 validate_rejectsReferenceOffsetsBreakingSamePhase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReferenceOffsetsBreakingSamePhase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-446 validate_rejectsReboundLookbackWithoutThreeWholeBlocks

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsReboundLookbackWithoutThreeWholeBlocks`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-447 validate_rejectsPriorBandsOutOfOrder

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/infrastructure/config/CalvingPredictionPropertiesTest.java::validate_rejectsPriorBandsOutOfOrder`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-448 submitReturnsFeedbackResultFields

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::submitReturnsFeedbackResultFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-449 unknownAlertPassesThroughAs404

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::unknownAlertPassesThroughAs404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-450 nonEstrusAlertPassesThroughAs400

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::nonEstrusAlertPassesThroughAs400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-451 crossFarmAlertPassesThroughAs403

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::crossFarmAlertPassesThroughAs403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-HLT-006、REQ-HLT-003

### TC-HLT-452 missingConfirmedFieldIsRejectedAs400

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::missingConfirmedFieldIsRejectedAs400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-RCH-001

### TC-HLT-453 unauthenticatedRequestIsRejectedAs401

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/health/interfaces/app/EstrusFeedbackControllerTest.java::unauthenticatedRequestIsRejectedAs401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-006、REQ-HLT-003、REQ-HLT-005、REQ-IDT-002

