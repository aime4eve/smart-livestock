# 测试用例规格：后端·GPS 与遥测采集

> 用例域：IOT ｜ 用例数：152
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IOT-102 | processTask_writesGpsAndRemovesCompletedTask | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_writesGpsAndRemovesCompletedTask` |
| TC-IOT-103 | processTask_notReady_skipsGpsWrite | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_notReady_skipsGpsWrite` |
| TC-IOT-104 | processTask_failedStatus_skipsGpsWrite | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_failedStatus_skipsGpsWrite` |
| TC-IOT-105 | processTask_gpsWriteFailure_propagatesForSchedulerRetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_gpsWriteFailure_propagatesForSchedulerRetry` |
| TC-IOT-106 | recordFailure_updatesTaskForRetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::recordFailure_updatesTaskForRetry` |
| TC-IOT-107 | processReadyTasks_continuesAfterFailureAndRecordsRetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskSchedulerTest.java::processReadyTasks_continuesAfterFailureAndRecordsRetry` |
| TC-IOT-108 | supportsDashFormatWithoutSeconds | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsDashFormatWithoutSeconds` |
| TC-IOT-109 | supportsSlashFormatsWithAndWithoutSeconds | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsSlashFormatsWithAndWithoutSeconds` |
| TC-IOT-110 | supportsUnpaddedMonthDayHour | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsUnpaddedMonthDayHour` |
| TC-IOT-111 | supportsExcelDateFormattedNumericCell | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsExcelDateFormattedNumericCell` |
| TC-IOT-112 | keepsSupportingFullAndIsoFormats | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::keepsSupportingFullAndIsoFormats` |
| TC-IOT-113 | invalidFormatReportsErrorRow | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::invalidFormatReportsErrorRow` |
| TC-IOT-131 | shouldPollBindingsAcrossTenants | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldPollBindingsAcrossTenants` |
| TC-IOT-132 | shouldIngestFramesAndAdvanceCursor | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldIngestFramesAndAdvanceCursor` |
| TC-IOT-133 | shouldCarryBindingIdentityAndFingerprintIntoArbitration | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldCarryBindingIdentityAndFingerprintIntoArbitration` |
| TC-IOT-134 | shouldTreatExistingDtlFrameAsIdempotentSuccess | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldTreatExistingDtlFrameAsIdempotentSuccess` |
| TC-IOT-135 | shouldStopAtFailedFrameAndKeepSuccessfulPrefixCursor | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldStopAtFailedFrameAndKeepSuccessfulPrefixCursor` |
| TC-IOT-136 | shouldNotWedgeCursorWhenDuplicateObservationStopsIngest | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldNotWedgeCursorWhenDuplicateObservationStopsIngest` |
| TC-IOT-137 | shouldContinueWhenBatchReachesLimit | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldContinueWhenBatchReachesLimit` |
| TC-IOT-138 | shouldClampOutOfRangeGpsBeforeIngest | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldClampOutOfRangeGpsBeforeIngest` |
| TC-IOT-139 | shouldSkipNonActiveDeviceWithoutFetch | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldSkipNonActiveDeviceWithoutFetch` |
| TC-IOT-140 | shouldSkipUndecodableFramesAndAdvanceCursorPastThem | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldSkipUndecodableFramesAndAdvanceCursorPastThem` |
| TC-IOT-141 | shouldCountConsecutiveFailuresOnPageError | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldCountConsecutiveFailuresOnPageError` |
| TC-IOT-142 | shouldResetFailuresOnCleanCycleWithoutFrames | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldResetFailuresOnCleanCycleWithoutFrames` |
| TC-IOT-143 | shouldParseCapsuleResultFrameWithOcConverterKeys | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldParseCapsuleResultFrameWithOcConverterKeys` |
| TC-IOT-144 | shouldSkipDataHexThatDuplicatesResultFrame | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldSkipDataHexThatDuplicatesResultFrame` |
| TC-IOT-145 | shouldFallbackToTlvDecodeForDistantDataHexOnly | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvDecodeForDistantDataHexOnly` |
| TC-IOT-146 | shouldFallbackToTlvWhenDecodeStatusIsFalse | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvWhenDecodeStatusIsFalse` |
| TC-IOT-147 | shouldFallbackToTlvWhenResultIsMalformedJson | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvWhenResultIsMalformedJson` |
| TC-IOT-148 | shouldFallbackToLegacyTlvWhenConverterReportsLegacyUnknownTypes | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToLegacyTlvWhenConverterReportsLegacyUnknownTypes` |
| TC-IOT-149 | shouldSkipInvalidTrackerResultWithoutFallback | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldSkipInvalidTrackerResultWithoutFallback` |
| TC-IOT-150 | shouldMapTrackerPropertiesAndSortByTs | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldMapTrackerPropertiesAndSortByTs` |
| TC-IOT-151 | firstObservationBecomesCanonical | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::firstObservationBecomesCanonical` |
| TC-IOT-152 | sameSourceObservationIsSourceDuplicate | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::sameSourceObservationIsSourceDuplicate` |
| TC-IOT-153 | nearNeighborWithSameFingerprintMergesAsDuplicate | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::nearNeighborWithSameFingerprintMergesAsDuplicate` |
| TC-IOT-154 | neighborBeyondMatchWindowIsIndependentCanonical | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::neighborBeyondMatchWindowIsIndependentCanonical` |
| TC-IOT-155 | neighborWithDifferentFingerprintIsIndependentCanonical | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::neighborWithDifferentFingerprintIsIndependentCanonical` |
| TC-IOT-156 | twoFingerprintMatchingNeighborsAreAmbiguous | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::twoFingerprintMatchingNeighborsAreAmbiguous` |
| TC-IOT-157 | sameCanonicalKeyFingerprintDriftFallsBackToDuplicate | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::sameCanonicalKeyFingerprintDriftFallsBackToDuplicate` |
| TC-IOT-158 | arbitrationLocksAcquiredPerObservation | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::arbitrationLocksAcquiredPerObservation` |
| TC-IOT-159 | fingerprintIsStableAndOrderIndependent | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::fingerprintIsStableAndOrderIndependent` |
| TC-IOT-160 | fingerprintExcludesWirelessParams | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::fingerprintExcludesWirelessParams` |
| TC-IOT-161 | parse_classificationMatrix_coversAllStatuses | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_classificationMatrix_coversAllStatuses` |
| TC-IOT-162 | parse_matchedDeviceWithInstallation_resolvesLivestockAndFarmNames | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_matchedDeviceWithInstallation_resolvesLivestockAndFarmNames` |
| TC-IOT-163 | parse_deviceNotRegistered_matchedFalseWithKey | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_deviceNotRegistered_matchedFalseWithKey` |
| TC-IOT-164 | parse_deviceNotActive_matchedFalseWithKey | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_deviceNotActive_matchedFalseWithKey` |
| TC-IOT-165 | parse_nonTrackerDevice_matchedFalseWithKey | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_nonTrackerDevice_matchedFalseWithKey` |
| TC-IOT-166 | import_deviceNotRegistered_throwsBeforeIngest | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_deviceNotRegistered_throwsBeforeIngest` |
| TC-IOT-167 | parse_badFileName_throws | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_badFileName_throws` |
| TC-IOT-168 | parse_microsecondTime_parsedAtFaceValueUtc | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_microsecondTime_parsedAtFaceValueUtc` |
| TC-IOT-169 | import_success_ingestsImportableRowsAscendingWithManualImportSource | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_success_ingestsImportableRowsAscendingWithManualImportSource` |
| TC-IOT-170 | import_idempotentReplay_allRowsDuplicate_nothingIngested | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_idempotentReplay_allRowsDuplicate_nothingIngested` |
| TC-IOT-171 | import_singleRowFailure_countedAndContinues | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_singleRowFailure_countedAndContinues` |
| TC-IOT-172 | parse_numericCells_wholeNumbersRenderWithoutDecimalPoint | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_numericCells_wholeNumbersRenderWithoutDecimalPoint` |
| TC-IOT-173 | canonicalObservationProceedsToIngest | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceDedupGateTest.java::canonicalObservationProceedsToIngest` |
| TC-IOT-174 | duplicateClassesNeverReachIngest | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceDedupGateTest.java::duplicateClassesNeverReachIngest` |
| TC-IOT-175 | ingest_capsule_publishesGenericTelemetryEvent | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_capsule_publishesGenericTelemetryEvent` |
| TC-IOT-176 | ingest_realCapsule_computesGastricCounterDeltaAndStoresRawCounter | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_realCapsule_computesGastricCounterDeltaAndStoresRawCounter` |
| TC-IOT-177 | ingest_realCapsule_ignoresGastricCounterReset | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_realCapsule_ignoresGastricCounterReset` |
| TC-IOT-178 | ingest_tracker_enqueuesGpsAndPublishesEvent | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_tracker_enqueuesGpsAndPublishesEvent` |
| TC-IOT-179 | ingest_capsule_doesNotExtractGps | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_capsule_doesNotExtractGps` |
| TC-IOT-180 | ingest_earTag_enqueuesGps | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_earTag_enqueuesGps` |
| TC-IOT-181 | ingest_gpsCapableDevice_derivesDistanceFromPreviousCoordinate | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_gpsCapableDevice_derivesDistanceFromPreviousCoordinate` |
| TC-IOT-182 | ingest_deviceNotFound_throwsException | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_deviceNotFound_throwsException` |
| TC-IOT-183 | ingest_deviceNotActive_throwsException | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_deviceNotActive_throwsException` |
| TC-IOT-184 | ingest_noActiveInstallation_succeedsWithoutLivestockId | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_noActiveInstallation_succeedsWithoutLivestockId` |
| TC-IOT-185 | ingest_invalidGpsFix_skipsOutboxAndStillPublishesTelemetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_invalidGpsFix_skipsOutboxAndStillPublishesTelemetry` |
| TC-IOT-186 | ingest_outOfRangeGps_skipsOutboxAndStillIngestsTelemetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_outOfRangeGps_skipsOutboxAndStillIngestsTelemetry` |
| TC-IOT-187 | ingest_usesCurrentTimeWhenRecordedAtIsNull | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_usesCurrentTimeWhenRecordedAtIsNull` |
| TC-IOT-188 | ingest_manualImport_skipsRuntimeSnapshot_logsHistoricalValues | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_manualImport_skipsRuntimeSnapshot_logsHistoricalValues` |
| TC-IOT-189 | ingest_platformDeviceFault_persistsLocalizedMessageKey | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_platformDeviceFault_persistsLocalizedMessageKey` |
| TC-IOT-190 | ingest_duplicateDeviceAndTime_skipsAllProcessing | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_duplicateDeviceAndTime_skipsAllProcessing` |
| TC-IOT-191 | ingest_thingsBoardDeviceFault_triggersDeviceAlert | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_thingsBoardDeviceFault_triggersDeviceAlert` |
| TC-IOT-192 | ingest_unassignedDeviceFault_skipsAlertInsteadOfFailing | P1 | REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_unassignedDeviceFault_skipsAlertInsteadOfFailing` |
| TC-IOT-193 | ingest_agenticPlatform_updatesSnapshotAndWritesSource | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_agenticPlatform_updatesSnapshotAndWritesSource` |
| TC-IOT-236 | markFailed_underMaxAttempts_schedulesRetry | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/GpsIngestionTaskTest.java::markFailed_underMaxAttempts_schedulesRetry` |
| TC-IOT-237 | markFailed_atMaxAttempts_marksFailed | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/GpsIngestionTaskTest.java::markFailed_atMaxAttempts_marksFailed` |
| TC-IOT-254 | deriveDistanceMeters_returnsHaversineDistanceForValidSegment | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_returnsHaversineDistanceForValidSegment` |
| TC-IOT-255 | deriveDistanceMeters_treatsSmallMovementAsJitter | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_treatsSmallMovementAsJitter` |
| TC-IOT-256 | deriveDistanceMeters_rejectsImplausibleSpeedAsGpsJump | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_rejectsImplausibleSpeedAsGpsJump` |
| TC-IOT-257 | deriveDistanceMeters_ignoresStaleOrReversedPoint | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_ignoresStaleOrReversedPoint` |
| TC-IOT-258 | noPoints_returnsUnavailable | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::noPoints_returnsUnavailable` |
| TC-IOT-259 | n5_p99IsNull_p95DegradesToMax | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n5_p99IsNull_p95DegradesToMax` |
| TC-IOT-260 | n5_varyingDistances | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n5_varyingDistances` |
| TC-IOT-261 | p95_14_9_excellent | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_14_9_excellent` |
| TC-IOT-262 | p95_15_0_excellentBoundary | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_15_0_excellentBoundary` |
| TC-IOT-263 | p95_15_1_usable | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_15_1_usable` |
| TC-IOT-264 | p95_25_0_usableBoundary | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_25_0_usableBoundary` |
| TC-IOT-265 | p95_25_1_marginal | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_25_1_marginal` |
| TC-IOT-266 | p95_40_0_marginalBoundary | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_40_0_marginalBoundary` |
| TC-IOT-267 | p95_40_1_unavailable | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_40_1_unavailable` |
| TC-IOT-268 | n10_lowCount_degradesGrade | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n10_lowCount_degradesGrade` |
| TC-IOT-269 | n48_allMetricsComputed | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n48_allMetricsComputed` |
| TC-IOT-270 | excludeSuspect_removesMovingPoints | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::excludeSuspect_removesMovingPoints` |
| TC-IOT-271 | stepNumberNull_isNotSuspect | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::stepNumberNull_isNotSuspect` |
| TC-IOT-272 | stepNumberZero_isNotSuspect | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::stepNumberZero_isNotSuspect` |
| TC-IOT-273 | n100_withExtremeOutlier | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n100_withExtremeOutlier` |
| TC-IOT-274 | n110_noOutliers | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n110_noOutliers` |
| TC-IOT-275 | twoPoints_maxPairwiseDistance | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::twoPoints_maxPairwiseDistance` |
| TC-IOT-276 | singlePoint_zeroJitter | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::singlePoint_zeroJitter` |
| TC-IOT-283 | perpendicularFootInsideSegment | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::perpendicularFootInsideSegment` |
| TC-IOT-284 | footBeyondSegmentEndFallsBackToEndpoint | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::footBeyondSegmentEndFallsBackToEndpoint` |
| TC-IOT-285 | degenerateSegmentUsesEndpointDistance | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::degenerateSegmentUsesEndpointDistance` |
| TC-IOT-286 | cornerProjectionPicksNearestSegment | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::cornerProjectionPicksNearestSegment` |
| TC-IOT-287 | equalDistanceTieKeepsFirstSegment | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::equalDistanceTieKeepsFirstSegment` |
| TC-IOT-288 | rejectsLineWithFewerThanTwoPoints | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::rejectsLineWithFewerThanTwoPoints` |
| TC-IOT-289 | emptyDeviationsYieldZeroStats | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::emptyDeviationsYieldZeroStats` |
| TC-IOT-290 | degeneratePercentilesFallBackToMax | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::degeneratePercentilesFallBackToMax` |
| TC-IOT-291 | percentilesUseLinearInterpolation | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::percentilesUseLinearInterpolation` |
| TC-IOT-292 | p95Exactly15With10SamplesIsExcellent | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Exactly15With10SamplesIsExcellent` |
| TC-IOT-293 | p95JustAbove15DropsToUsable | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95JustAbove15DropsToUsable` |
| TC-IOT-294 | nineSamplesCannotBeExcellent | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::nineSamplesCannotBeExcellent` |
| TC-IOT-295 | p95Exactly40With4SamplesIsMarginal | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Exactly40With4SamplesIsMarginal` |
| TC-IOT-296 | fewerThan4SamplesIsUnavailable | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::fewerThan4SamplesIsUnavailable` |
| TC-IOT-297 | p95Above40IsUnavailable | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Above40IsUnavailable` |
| TC-IOT-298 | corridorBoundaryIncludes99m | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::corridorBoundaryIncludes99m` |
| TC-IOT-299 | corridorBoundaryExcludes101m | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::corridorBoundaryExcludes101m` |
| TC-IOT-300 | gapOver300sSplitsIntoTwoTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::gapOver300sSplitsIntoTwoTrips` |
| TC-IOT-301 | gapExactly300sStaysInOneTrip | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::gapExactly300sStaysInOneTrip` |
| TC-IOT-302 | segmentWithFewerThan4PointsIsDropped | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::segmentWithFewerThan4PointsIsDropped` |
| TC-IOT-303 | outsideCorridorPointCutsTheSegment | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::outsideCorridorPointCutsTheSegment` |
| TC-IOT-304 | multipleTripsMergeIntoOneStatistic | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::multipleTripsMergeIntoOneStatistic` |
| TC-IOT-305 | noValidSegmentYieldsZeroSamplesAndUnavailable | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::noValidSegmentYieldsZeroSamplesAndUnavailable` |
| TC-IOT-306 | matchedPointsCarryDeviationAndSegment | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::matchedPointsCarryDeviationAndSegment` |
| TC-IOT-307 | polylineLengthSumsHaversineSegments | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::polylineLengthSumsHaversineSegments` |
| TC-IOT-308 | decode_realPeriodicFrame_extractsAllFields | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_realPeriodicFrame_extractsAllFields` |
| TC-IOT-309 | toReadings_realPeriodicFrame_matchesPlatformKeyConventions | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::toReadings_realPeriodicFrame_matchesPlatformKeyConventions` |
| TC-IOT-310 | decode_unknownType30_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_unknownType30_returnsEmpty` |
| TC-IOT-311 | decode_nonSyncHead_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_nonSyncHead_returnsEmpty` |
| TC-IOT-312 | decode_unknownType8A_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_unknownType8A_returnsEmpty` |
| TC-IOT-313 | decode_nullOrEmpty_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_nullOrEmpty_returnsEmpty` |
| TC-IOT-314 | decode_shorterThanHeader_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_shorterThanHeader_returnsEmpty` |
| TC-IOT-315 | decode_truncatedTlvValue_returnsEmpty | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_truncatedTlvValue_returnsEmpty` |
| TC-IOT-316 | decode_zeroZeroCoordinate_decodesToZero | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_zeroZeroCoordinate_decodesToZero` |
| TC-IOT-317 | decode_negativeCoordinate_bit31Set | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_negativeCoordinate_bit31Set` |
| TC-IOT-318 | decode_antiDisassemblyAndSkippedTypes_consumedWithoutMapping | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_antiDisassemblyAndSkippedTypes_consumedWithoutMapping` |
| TC-IOT-319 | fileCoordinatesShortCircuitWithoutCandidates | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::fileCoordinatesShortCircuitWithoutCandidates` |
| TC-IOT-320 | pairsNearestLogWithinTolerance | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::pairsNearestLogWithinTolerance` |
| TC-IOT-321 | equidistantTieGoesToEarlierReport | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::equidistantTieGoesToEarlierReport` |
| TC-IOT-322 | beyondToleranceIsUnpaired | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::beyondToleranceIsUnpaired` |
| TC-IOT-323 | emptyCandidatesIsUnpaired | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::emptyCandidatesIsUnpaired` |
| TC-IOT-324 | emptyListYieldsZeros | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::emptyListYieldsZeros` |
| TC-IOT-325 | unpairedExcludedFromErrorStatistics | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::unpairedExcludedFromErrorStatistics` |
| TC-IOT-326 | percentilesDegradeToMaxOnSmallSamples | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::percentilesDegradeToMaxOnSmallSamples` |
| TC-IOT-327 | p95ComputedWhenEnoughSamples | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::p95ComputedWhenEnoughSamples` |
| TC-IOT-328 | prototypeExampleIsExcellent | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::prototypeExampleIsExcellent` |
| TC-IOT-329 | excellentRequiresTenPairedSamples | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::excellentRequiresTenPairedSamples` |
| TC-IOT-330 | excellentRequiresPairRateAboveEighty | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::excellentRequiresPairRateAboveEighty` |
| TC-IOT-331 | usableRequiresPairRateAboveSixty | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::usableRequiresPairRateAboveSixty` |
| TC-IOT-332 | fewerThanFourPairedIsUnavailable | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::fewerThanFourPairedIsUnavailable` |
| TC-IOT-333 | p95AboveFortyIsUnavailable | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::p95AboveFortyIsUnavailable` |
| TC-IOT-372 | getDeviceGpsHistory_rejectsCapsule | P0 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/interfaces/GpsLogControllerTest.java::getDeviceGpsHistory_rejectsCapsule` |

## 用例明细（初稿模板）

### TC-IOT-102 processTask_writesGpsAndRemovesCompletedTask

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_writesGpsAndRemovesCompletedTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-103 processTask_notReady_skipsGpsWrite

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_notReady_skipsGpsWrite`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-104 processTask_failedStatus_skipsGpsWrite

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_failedStatus_skipsGpsWrite`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-105 processTask_gpsWriteFailure_propagatesForSchedulerRetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::processTask_gpsWriteFailure_propagatesForSchedulerRetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-106 recordFailure_updatesTaskForRetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskProcessorTest.java::recordFailure_updatesTaskForRetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-107 processReadyTasks_continuesAfterFailureAndRecordsRetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsIngestionTaskSchedulerTest.java::processReadyTasks_continuesAfterFailureAndRecordsRetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-108 supportsDashFormatWithoutSeconds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsDashFormatWithoutSeconds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-109 supportsSlashFormatsWithAndWithoutSeconds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsSlashFormatsWithAndWithoutSeconds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-110 supportsUnpaddedMonthDayHour

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsUnpaddedMonthDayHour`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-111 supportsExcelDateFormattedNumericCell

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::supportsExcelDateFormattedNumericCell`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-112 keepsSupportingFullAndIsoFormats

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::keepsSupportingFullAndIsoFormats`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-113 invalidFormatReportsErrorRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GpsQualityBatchImportServiceTest.java::invalidFormatReportsErrorRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-131 shouldPollBindingsAcrossTenants

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldPollBindingsAcrossTenants`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-132 shouldIngestFramesAndAdvanceCursor

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldIngestFramesAndAdvanceCursor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-133 shouldCarryBindingIdentityAndFingerprintIntoArbitration

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldCarryBindingIdentityAndFingerprintIntoArbitration`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-134 shouldTreatExistingDtlFrameAsIdempotentSuccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldTreatExistingDtlFrameAsIdempotentSuccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-135 shouldStopAtFailedFrameAndKeepSuccessfulPrefixCursor

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldStopAtFailedFrameAndKeepSuccessfulPrefixCursor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-136 shouldNotWedgeCursorWhenDuplicateObservationStopsIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldNotWedgeCursorWhenDuplicateObservationStopsIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-137 shouldContinueWhenBatchReachesLimit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldContinueWhenBatchReachesLimit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-138 shouldClampOutOfRangeGpsBeforeIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldClampOutOfRangeGpsBeforeIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-139 shouldSkipNonActiveDeviceWithoutFetch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldSkipNonActiveDeviceWithoutFetch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-140 shouldSkipUndecodableFramesAndAdvanceCursorPastThem

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldSkipUndecodableFramesAndAdvanceCursorPastThem`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-141 shouldCountConsecutiveFailuresOnPageError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldCountConsecutiveFailuresOnPageError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-142 shouldResetFailuresOnCleanCycleWithoutFrames

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryChannelTest.java::shouldResetFailuresOnCleanCycleWithoutFrames`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-143 shouldParseCapsuleResultFrameWithOcConverterKeys

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldParseCapsuleResultFrameWithOcConverterKeys`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-144 shouldSkipDataHexThatDuplicatesResultFrame

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldSkipDataHexThatDuplicatesResultFrame`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-145 shouldFallbackToTlvDecodeForDistantDataHexOnly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvDecodeForDistantDataHexOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-146 shouldFallbackToTlvWhenDecodeStatusIsFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvWhenDecodeStatusIsFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-147 shouldFallbackToTlvWhenResultIsMalformedJson

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToTlvWhenResultIsMalformedJson`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-148 shouldFallbackToLegacyTlvWhenConverterReportsLegacyUnknownTypes

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldFallbackToLegacyTlvWhenConverterReportsLegacyUnknownTypes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-149 shouldSkipInvalidTrackerResultWithoutFallback

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldSkipInvalidTrackerResultWithoutFallback`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-150 shouldMapTrackerPropertiesAndSortByTs

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbTelemetryFrameParserTest.java::shouldMapTrackerPropertiesAndSortByTs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-151 firstObservationBecomesCanonical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::firstObservationBecomesCanonical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-152 sameSourceObservationIsSourceDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::sameSourceObservationIsSourceDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-153 nearNeighborWithSameFingerprintMergesAsDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::nearNeighborWithSameFingerprintMergesAsDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-154 neighborBeyondMatchWindowIsIndependentCanonical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::neighborBeyondMatchWindowIsIndependentCanonical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-155 neighborWithDifferentFingerprintIsIndependentCanonical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::neighborWithDifferentFingerprintIsIndependentCanonical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-156 twoFingerprintMatchingNeighborsAreAmbiguous

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::twoFingerprintMatchingNeighborsAreAmbiguous`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-157 sameCanonicalKeyFingerprintDriftFallsBackToDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::sameCanonicalKeyFingerprintDriftFallsBackToDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-158 arbitrationLocksAcquiredPerObservation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::arbitrationLocksAcquiredPerObservation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-159 fingerprintIsStableAndOrderIndependent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::fingerprintIsStableAndOrderIndependent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-160 fingerprintExcludesWirelessParams

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryDedupApplicationServiceTest.java::fingerprintExcludesWirelessParams`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-161 parse_classificationMatrix_coversAllStatuses

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_classificationMatrix_coversAllStatuses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-162 parse_matchedDeviceWithInstallation_resolvesLivestockAndFarmNames

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_matchedDeviceWithInstallation_resolvesLivestockAndFarmNames`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-163 parse_deviceNotRegistered_matchedFalseWithKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_deviceNotRegistered_matchedFalseWithKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-164 parse_deviceNotActive_matchedFalseWithKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_deviceNotActive_matchedFalseWithKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-165 parse_nonTrackerDevice_matchedFalseWithKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_nonTrackerDevice_matchedFalseWithKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-166 import_deviceNotRegistered_throwsBeforeIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_deviceNotRegistered_throwsBeforeIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-167 parse_badFileName_throws

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_badFileName_throws`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-168 parse_microsecondTime_parsedAtFaceValueUtc

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_microsecondTime_parsedAtFaceValueUtc`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-169 import_success_ingestsImportableRowsAscendingWithManualImportSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_success_ingestsImportableRowsAscendingWithManualImportSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-170 import_idempotentReplay_allRowsDuplicate_nothingIngested

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_idempotentReplay_allRowsDuplicate_nothingIngested`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-171 import_singleRowFailure_countedAndContinues

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::import_singleRowFailure_countedAndContinues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-172 parse_numericCells_wholeNumbersRenderWithoutDecimalPoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryImportServiceTest.java::parse_numericCells_wholeNumbersRenderWithoutDecimalPoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-173 canonicalObservationProceedsToIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceDedupGateTest.java::canonicalObservationProceedsToIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-174 duplicateClassesNeverReachIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceDedupGateTest.java::duplicateClassesNeverReachIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-175 ingest_capsule_publishesGenericTelemetryEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_capsule_publishesGenericTelemetryEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-176 ingest_realCapsule_computesGastricCounterDeltaAndStoresRawCounter

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_realCapsule_computesGastricCounterDeltaAndStoresRawCounter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-177 ingest_realCapsule_ignoresGastricCounterReset

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_realCapsule_ignoresGastricCounterReset`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-178 ingest_tracker_enqueuesGpsAndPublishesEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_tracker_enqueuesGpsAndPublishesEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-179 ingest_capsule_doesNotExtractGps

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_capsule_doesNotExtractGps`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-180 ingest_earTag_enqueuesGps

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_earTag_enqueuesGps`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-181 ingest_gpsCapableDevice_derivesDistanceFromPreviousCoordinate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_gpsCapableDevice_derivesDistanceFromPreviousCoordinate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-182 ingest_deviceNotFound_throwsException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_deviceNotFound_throwsException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-183 ingest_deviceNotActive_throwsException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_deviceNotActive_throwsException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-184 ingest_noActiveInstallation_succeedsWithoutLivestockId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_noActiveInstallation_succeedsWithoutLivestockId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-185 ingest_invalidGpsFix_skipsOutboxAndStillPublishesTelemetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_invalidGpsFix_skipsOutboxAndStillPublishesTelemetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-186 ingest_outOfRangeGps_skipsOutboxAndStillIngestsTelemetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_outOfRangeGps_skipsOutboxAndStillIngestsTelemetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-187 ingest_usesCurrentTimeWhenRecordedAtIsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_usesCurrentTimeWhenRecordedAtIsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-188 ingest_manualImport_skipsRuntimeSnapshot_logsHistoricalValues

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_manualImport_skipsRuntimeSnapshot_logsHistoricalValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-189 ingest_platformDeviceFault_persistsLocalizedMessageKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_platformDeviceFault_persistsLocalizedMessageKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-190 ingest_duplicateDeviceAndTime_skipsAllProcessing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_duplicateDeviceAndTime_skipsAllProcessing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-191 ingest_thingsBoardDeviceFault_triggersDeviceAlert

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_thingsBoardDeviceFault_triggersDeviceAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-IOT-192 ingest_unassignedDeviceFault_skipsAlertInsteadOfFailing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_unassignedDeviceFault_skipsAlertInsteadOfFailing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IOT-001、REQ-IOT-002

### TC-IOT-193 ingest_agenticPlatform_updatesSnapshotAndWritesSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TelemetryIngestionServiceTest.java::ingest_agenticPlatform_updatesSnapshotAndWritesSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-IOT-236 markFailed_underMaxAttempts_schedulesRetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/GpsIngestionTaskTest.java::markFailed_underMaxAttempts_schedulesRetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-237 markFailed_atMaxAttempts_marksFailed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/GpsIngestionTaskTest.java::markFailed_atMaxAttempts_marksFailed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-254 deriveDistanceMeters_returnsHaversineDistanceForValidSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_returnsHaversineDistanceForValidSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-255 deriveDistanceMeters_treatsSmallMovementAsJitter

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_treatsSmallMovementAsJitter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-256 deriveDistanceMeters_rejectsImplausibleSpeedAsGpsJump

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_rejectsImplausibleSpeedAsGpsJump`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-257 deriveDistanceMeters_ignoresStaleOrReversedPoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsDistanceDerivationServiceTest.java::deriveDistanceMeters_ignoresStaleOrReversedPoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-258 noPoints_returnsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::noPoints_returnsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-259 n5_p99IsNull_p95DegradesToMax

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n5_p99IsNull_p95DegradesToMax`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-260 n5_varyingDistances

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n5_varyingDistances`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-261 p95_14_9_excellent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_14_9_excellent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-262 p95_15_0_excellentBoundary

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_15_0_excellentBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-263 p95_15_1_usable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_15_1_usable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-264 p95_25_0_usableBoundary

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_25_0_usableBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-265 p95_25_1_marginal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_25_1_marginal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-266 p95_40_0_marginalBoundary

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_40_0_marginalBoundary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-267 p95_40_1_unavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::p95_40_1_unavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-268 n10_lowCount_degradesGrade

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n10_lowCount_degradesGrade`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-269 n48_allMetricsComputed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n48_allMetricsComputed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-270 excludeSuspect_removesMovingPoints

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::excludeSuspect_removesMovingPoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-271 stepNumberNull_isNotSuspect

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::stepNumberNull_isNotSuspect`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-272 stepNumberZero_isNotSuspect

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::stepNumberZero_isNotSuspect`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-273 n100_withExtremeOutlier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n100_withExtremeOutlier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-274 n110_noOutliers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::n110_noOutliers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-275 twoPoints_maxPairwiseDistance

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::twoPoints_maxPairwiseDistance`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-276 singlePoint_zeroJitter

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/GpsQualityCalculatorTest.java::singlePoint_zeroJitter`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-283 perpendicularFootInsideSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::perpendicularFootInsideSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-284 footBeyondSegmentEndFallsBackToEndpoint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::footBeyondSegmentEndFallsBackToEndpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-285 degenerateSegmentUsesEndpointDistance

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::degenerateSegmentUsesEndpointDistance`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-286 cornerProjectionPicksNearestSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::cornerProjectionPicksNearestSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-287 equalDistanceTieKeepsFirstSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::equalDistanceTieKeepsFirstSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-288 rejectsLineWithFewerThanTwoPoints

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::rejectsLineWithFewerThanTwoPoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-289 emptyDeviationsYieldZeroStats

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::emptyDeviationsYieldZeroStats`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-290 degeneratePercentilesFallBackToMax

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::degeneratePercentilesFallBackToMax`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-291 percentilesUseLinearInterpolation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::percentilesUseLinearInterpolation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-292 p95Exactly15With10SamplesIsExcellent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Exactly15With10SamplesIsExcellent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-293 p95JustAbove15DropsToUsable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95JustAbove15DropsToUsable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-294 nineSamplesCannotBeExcellent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::nineSamplesCannotBeExcellent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-295 p95Exactly40With4SamplesIsMarginal

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Exactly40With4SamplesIsMarginal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-296 fewerThan4SamplesIsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::fewerThan4SamplesIsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-297 p95Above40IsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::p95Above40IsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-298 corridorBoundaryIncludes99m

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::corridorBoundaryIncludes99m`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-299 corridorBoundaryExcludes101m

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::corridorBoundaryExcludes101m`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-300 gapOver300sSplitsIntoTwoTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::gapOver300sSplitsIntoTwoTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-301 gapExactly300sStaysInOneTrip

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::gapExactly300sStaysInOneTrip`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-302 segmentWithFewerThan4PointsIsDropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::segmentWithFewerThan4PointsIsDropped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-303 outsideCorridorPointCutsTheSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::outsideCorridorPointCutsTheSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-304 multipleTripsMergeIntoOneStatistic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::multipleTripsMergeIntoOneStatistic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-305 noValidSegmentYieldsZeroSamplesAndUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::noValidSegmentYieldsZeroSamplesAndUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-306 matchedPointsCarryDeviationAndSegment

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::matchedPointsCarryDeviationAndSegment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-307 polylineLengthSumsHaversineSegments

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackLineCalculatorTest.java::polylineLengthSumsHaversineSegments`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-308 decode_realPeriodicFrame_extractsAllFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_realPeriodicFrame_extractsAllFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-309 toReadings_realPeriodicFrame_matchesPlatformKeyConventions

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::toReadings_realPeriodicFrame_matchesPlatformKeyConventions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-310 decode_unknownType30_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_unknownType30_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-311 decode_nonSyncHead_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_nonSyncHead_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-312 decode_unknownType8A_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_unknownType8A_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-313 decode_nullOrEmpty_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_nullOrEmpty_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-314 decode_shorterThanHeader_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_shorterThanHeader_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-315 decode_truncatedTlvValue_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_truncatedTlvValue_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-316 decode_zeroZeroCoordinate_decodesToZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_zeroZeroCoordinate_decodesToZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-317 decode_negativeCoordinate_bit31Set

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_negativeCoordinate_bit31Set`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IOT-318 decode_antiDisassemblyAndSkippedTypes_consumedWithoutMapping

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrackerPayloadDecoderTest.java::decode_antiDisassemblyAndSkippedTypes_consumedWithoutMapping`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-IOT-319 fileCoordinatesShortCircuitWithoutCandidates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::fileCoordinatesShortCircuitWithoutCandidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-320 pairsNearestLogWithinTolerance

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::pairsNearestLogWithinTolerance`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-321 equidistantTieGoesToEarlierReport

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::equidistantTieGoesToEarlierReport`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-322 beyondToleranceIsUnpaired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::beyondToleranceIsUnpaired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-323 emptyCandidatesIsUnpaired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::emptyCandidatesIsUnpaired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-324 emptyListYieldsZeros

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::emptyListYieldsZeros`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-325 unpairedExcludedFromErrorStatistics

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::unpairedExcludedFromErrorStatistics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-326 percentilesDegradeToMaxOnSmallSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::percentilesDegradeToMaxOnSmallSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-327 p95ComputedWhenEnoughSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::p95ComputedWhenEnoughSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-328 prototypeExampleIsExcellent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::prototypeExampleIsExcellent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-329 excellentRequiresTenPairedSamples

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::excellentRequiresTenPairedSamples`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-330 excellentRequiresPairRateAboveEighty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::excellentRequiresPairRateAboveEighty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-331 usableRequiresPairRateAboveSixty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::usableRequiresPairRateAboveSixty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-332 fewerThanFourPairedIsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::fewerThanFourPairedIsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-333 p95AboveFortyIsUnavailable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/TrajectoryPairingServiceTest.java::p95AboveFortyIsUnavailable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-372 getDeviceGpsHistory_rejectsCapsule

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/interfaces/GpsLogControllerTest.java::getDeviceGpsHistory_rejectsCapsule`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

