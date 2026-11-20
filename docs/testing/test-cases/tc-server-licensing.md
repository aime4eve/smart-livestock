# 测试用例规格：后端·许可证（licensing）

> 用例域：CMC ｜ 用例数：171
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-CMC-342 | noSubscription_createsTrial365Days_andAuditsGrant | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::noSubscription_createsTrial365Days_andAuditsGrant` |
| TC-CMC-343 | activeTrialEndingEarlier_extendsToPilotEnd | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::activeTrialEndingEarlier_extendsToPilotEnd` |
| TC-CMC-344 | activeTrialEndingLater_rollingMode_keepsLongerCurrentEnd | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::activeTrialEndingLater_rollingMode_keepsLongerCurrentEnd` |
| TC-CMC-345 | fixedDeadline_configured_noSubscription_createsTrialAtDeadline | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_configured_noSubscription_createsTrialAtDeadline` |
| TC-CMC-346 | fixedDeadline_configured_laterCurrentTrial_convergesBackToDeadline | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_configured_laterCurrentTrial_convergesBackToDeadline` |
| TC-CMC-347 | fixedDeadline_unparseableValue_failsFast | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_unparseableValue_failsFast` |
| TC-CMC-348 | requestedDeadline_noSubscription_createsTrialAtRequestedEnd | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_noSubscription_createsTrialAtRequestedEnd` |
| TC-CMC-349 | requestedDeadline_laterCurrentTrial_convergesToRequestedEnd | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_laterCurrentTrial_convergesToRequestedEnd` |
| TC-CMC-350 | requestedDeadline_inPast_rejectedAsValidationError | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_inPast_rejectedAsValidationError` |
| TC-CMC-351 | configuredDeadline_auditRecordsConfiguredSource | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::configuredDeadline_auditRecordsConfiguredSource` |
| TC-CMC-352 | expiredTrial_canBeReEnrolled | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::expiredTrial_canBeReEnrolled` |
| TC-CMC-353 | onPremMode_forbidden | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::onPremMode_forbidden` |
| TC-CMC-354 | disabledPilot_forbidden | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::disabledPilot_forbidden` |
| TC-CMC-355 | modeIsCaseInsensitive | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::modeIsCaseInsensitive` |
| TC-CMC-356 | missingAuthentication_rejected | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::missingAuthentication_rejected` |
| TC-CMC-357 | mapsSnapshotFields | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::mapsSnapshotFields` |
| TC-CMC-358 | emptyWhenNoSubscription | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::emptyWhenNoSubscription` |
| TC-CMC-359 | noSubscription_createsTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::noSubscription_createsTrial` |
| TC-CMC-360 | existingTrial_extendsTrialEnd | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::existingTrial_extendsTrialEnd` |
| TC-CMC-361 | existingActive_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::existingActive_throwsStateConflict` |
| TC-CMC-362 | fromTrial_activatesWithTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_activatesWithTier` |
| TC-CMC-363 | fromFree_transitionsToActive | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromFree_transitionsToActive` |
| TC-CMC-364 | active_updatesTierAndStaysActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::active_updatesTierAndStaysActive` |
| TC-CMC-365 | suspended_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::suspended_throwsStateConflict` |
| TC-CMC-366 | lowercaseTierName_isAccepted | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::lowercaseTierName_isAccepted` |
| TC-CMC-367 | unknownTier_throwsValidationError | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::unknownTier_throwsValidationError` |
| TC-CMC-368 | missingSubscription_throwsNotFound | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::missingSubscription_throwsNotFound` |
| TC-CMC-369 | fromTrial_downgradesToFreeBasic | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_downgradesToFreeBasic` |
| TC-CMC-370 | fromRenewalFailed_downgradesToFreeBasic | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromRenewalFailed_downgradesToFreeBasic` |
| TC-CMC-371 | fromFree_isIdempotent | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromFree_isIdempotent` |
| TC-CMC-372 | fromActive_downgradesToFreeBasic | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromActive_downgradesToFreeBasic` |
| TC-CMC-373 | fromSuspended_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromSuspended_throwsStateConflict` |
| TC-CMC-374 | fromActive_suspends | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromActive_suspends` |
| TC-CMC-375 | fromSuspended_isIdempotent | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromSuspended_isIdempotent` |
| TC-CMC-376 | fromTrial_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_throwsStateConflict` |
| TC-CMC-377 | missingSubscription_throwsNotFound | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::missingSubscription_throwsNotFound` |
| TC-CMC-378 | firstEnroll_createsInstallationWithGeneratedId | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::firstEnroll_createsInstallationWithGeneratedId` |
| TC-CMC-379 | reEnroll_keepsInstallationIdStable | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::reEnroll_keepsInstallationIdStable` |
| TC-CMC-380 | notConfirmed_rejectsWithValidationError | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::notConfirmed_rejectsWithValidationError` |
| TC-CMC-381 | notEnrolled_rejectsWithValidationError | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::notEnrolled_rejectsWithValidationError` |
| TC-CMC-382 | unreadableEnvelope_writesRejectedEventAndThrowsInvalid | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::unreadableEnvelope_writesRejectedEventAndThrowsInvalid` |
| TC-CMC-383 | trialImportWithoutSubscription_appliesTrialAndStoresCurrentLicense | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportWithoutSubscription_appliesTrialAndStoresCurrentLicense` |
| TC-CMC-384 | trialImportOverActiveTrial_extendsTrial | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportOverActiveTrial_extendsTrial` |
| TC-CMC-385 | activeImportFromFreeSubscription_activatesWithTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::activeImportFromFreeSubscription_activatesWithTier` |
| TC-CMC-386 | importReplacesPreviousLicense_oldRecordMarkedReplaced | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::importReplacesPreviousLicense_oldRecordMarkedReplaced` |
| TC-CMC-387 | bindingMismatch_persistsRejectedRecordAndThrows | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::bindingMismatch_persistsRejectedRecordAndThrows` |
| TC-CMC-388 | quotaExceeded_rejectsImportWithoutTouchingSubscription | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-003、REQ-CMC-009 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::quotaExceeded_rejectsImportWithoutTouchingSubscription` |
| TC-CMC-389 | quotaKeyAbsentFromPayload_skipsThatPrecheck | P1 | REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::quotaKeyAbsentFromPayload_skipsThatPrecheck` |
| TC-CMC-390 | trialImportAfterTrialDegradedToFree_rejects | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportAfterTrialDegradedToFree_rejects` |
| TC-CMC-391 | trialImportOverExpiredTrial_rejects | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportOverExpiredTrial_rejects` |
| TC-CMC-392 | expiredLicenseImport_rejectedAsExpired | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::expiredLicenseImport_rejectedAsExpired` |
| TC-CMC-393 | windowImport_requiresAdminBootstrap | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::windowImport_requiresAdminBootstrap` |
| TC-CMC-394 | windowImportWithAdminBootstrap_createsAdminAccount | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::windowImportWithAdminBootstrap_createsAdminAccount` |
| TC-CMC-395 | renewalWithoutAdminFields_keepsExistingAdminUntouched | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::renewalWithoutAdminFields_keepsExistingAdminUntouched` |
| TC-CMC-396 | halfAdminPair_isInvalidPayload | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::halfAdminPair_isInvalidPayload` |
| TC-CMC-397 | replayedCertificate_rejected | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::replayedCertificate_rejected` |
| TC-CMC-398 | reportsInstallationLicenseStateAndSubscription | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::reportsInstallationLicenseStateAndSubscription` |
| TC-CMC-399 | beforeEnroll_reportsPendingActivation | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::beforeEnroll_reportsPendingActivation` |
| TC-CMC-400 | hostedMode_isNoOp | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::hostedMode_isNoOp` |
| TC-CMC-401 | validatesEveryTenantWithInstallation | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::validatesEveryTenantWithInstallation` |
| TC-CMC-402 | tenantFailureDoesNotBlockOthers | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::tenantFailureDoesNotBlockOthers` |
| TC-CMC-403 | noInstallations_noValidation | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::noInstallations_noValidation` |
| TC-CMC-404 | onPremModeIsDetectedCaseInsensitively | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::onPremModeIsDetectedCaseInsensitively` |
| TC-CMC-405 | requireOnPremPassesOnlyInOnPremMode | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::requireOnPremPassesOnlyInOnPremMode` |
| TC-CMC-406 | requireSelfServiceAllowedPassesOnlyInHostedMode | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::requireSelfServiceAllowedPassesOnlyInHostedMode` |
| TC-CMC-407 | noInstallation_returnsEmptyAndWritesNothing | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::noInstallation_returnsEmptyAndWritesNothing` |
| TC-CMC-408 | firstValidationWithValidLicense_marksValidAndAdvancesAnchor | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::firstValidationWithValidLicense_marksValidAndAdvancesAnchor` |
| TC-CMC-409 | recoveryFromSuspension_revalidatesRawLicenseAndRemapsSubscription | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::recoveryFromSuspension_revalidatesRawLicenseAndRemapsSubscription` |
| TC-CMC-410 | trialLicenseRecoveryOverFreeSubscription_keepsRuntimeValidSkipsRemap | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::trialLicenseRecoveryOverFreeSubscription_keepsRuntimeValidSkipsRemap` |
| TC-CMC-411 | expiredLicense_marksExpiredAndDowngradesSubscription | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::expiredLicense_marksExpiredAndDowngradesSubscription` |
| TC-CMC-412 | downgradeConflict_stillMarksRuntimeExpired | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::downgradeConflict_stillMarksRuntimeExpired` |
| TC-CMC-413 | rollbackBeyondTolerance_suspendsAndKeepsAnchorMonotonic | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::rollbackBeyondTolerance_suspendsAndKeepsAnchorMonotonic` |
| TC-CMC-414 | rollbackWithinTolerance_staysValid | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::rollbackWithinTolerance_staysValid` |
| TC-CMC-415 | suspendConflict_stillMarksRuntimeSuspended | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::suspendConflict_stillMarksRuntimeSuspended` |
| TC-CMC-416 | currentLicenseRecordDeleted_fallsBackToPendingActivation | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::currentLicenseRecordDeleted_fallsBackToPendingActivation` |
| TC-CMC-417 | tamperedRawLicense_suspendsWithInvalidProtection | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::tamperedRawLicense_suspendsWithInvalidProtection` |
| TC-CMC-418 | replacedChainWithoutCurrent_fallsBackToPendingActivation | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::replacedChainWithoutCurrent_fallsBackToPendingActivation` |
| TC-CMC-419 | accepts 64-char hex and normalizes to lowercase | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::acceptsAndNormalizesHex` |
| TC-CMC-420 | strips surrounding whitespace before validation | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::stripsWhitespace` |
| TC-CMC-421 | rejects non-hex or wrong-length digests with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::rejectsMalformedDigests` |
| TC-CMC-422 | matches compares normalized digests | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::matchesNormalized` |
| TC-CMC-423 | parsesWellFormedEnvelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::parsesWellFormedEnvelope` |
| TC-CMC-424 | decodesPayloadAndSignatureBytes | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::decodesPayloadAndSignatureBytes` |
| TC-CMC-425 | rejectsBlankInput | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsBlankInput` |
| TC-CMC-426 | rejectsNonJsonInput | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsNonJsonInput` |
| TC-CMC-427 | rejectsUnsupportedFormat | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsUnsupportedFormat` |
| TC-CMC-428 | rejectsMissingSignature | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsMissingSignature` |
| TC-CMC-429 | rejectsPayloadSha256ThatIsNotHex64 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsPayloadSha256ThatIsNotHex64` |
| TC-CMC-430 | rejectsPayloadThatIsNotBase64Url | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsPayloadThatIsNotBase64Url` |
| TC-CMC-431 | normalizesPayloadSha256ToLowerCase | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::normalizesPayloadSha256ToLowerCase` |
| TC-CMC-432 | parsesAllFields | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesAllFields` |
| TC-CMC-433 | parsesOptionalReplacesLicenseId | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesOptionalReplacesLicenseId` |
| TC-CMC-434 | parsesAdminBootstrapPair | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesAdminBootstrapPair` |
| TC-CMC-435 | omitsAdminFieldsWhenAbsent_keepingCanonicalFormStable | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::omitsAdminFieldsWhenAbsent_keepingCanonicalFormStable` |
| TC-CMC-436 | rejectsHalfAdminPair | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsHalfAdminPair` |
| TC-CMC-437 | rejectsNonBcryptAdminPasswordHash | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonBcryptAdminPasswordHash` |
| TC-CMC-438 | toMapRoundTripsThroughFromMap | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::toMapRoundTripsThroughFromMap` |
| TC-CMC-439 | rejectsUnsupportedPayloadVersion | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsUnsupportedPayloadVersion` |
| TC-CMC-440 | rejectsUnknownLicenseType | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsUnknownLicenseType` |
| TC-CMC-441 | rejectsMissingRequiredField | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsMissingRequiredField` |
| TC-CMC-442 | rejectsNonUuidLicenseId | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonUuidLicenseId` |
| TC-CMC-443 | rejectsNonHexFingerprintHash | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonHexFingerprintHash` |
| TC-CMC-444 | rejectsExpiresAtBeforeIssuedAt | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsExpiresAtBeforeIssuedAt` |
| TC-CMC-445 | rejectsNonIntegerQuotaValues | P1 | REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonIntegerQuotaValues` |
| TC-CMC-446 | rejectsQuotasThatAreNotAnObject | P1 | REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsQuotasThatAreNotAnObject` |
| TC-CMC-447 | shared vectors: Java canonical form matches expectedCanonical | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::sharedVectorsAreReproduced` |
| TC-CMC-448 | keys sorted lexicographically at every level | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::sortsNestedKeys` |
| TC-CMC-449 | instants rendered as UTC seconds form; integral doubles lose the decimal point | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::formatsInstantsAndIntegers` |
| TC-CMC-450 | strings escape mandatory JSON characters, non-ASCII stays raw | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::escapesStrings` |
| TC-CMC-451 | serialize/parse round trip preserves structure | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::roundTripsThroughParse` |
| TC-CMC-452 | loads the committed production key list from main resources | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsProductionKeyList` |
| TC-CMC-453 | loads the test key list via classpath resource | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsTestClasspathKeyList` |
| TC-CMC-454 | accepts an explicit stream (tests / custom provisioning) | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsFromStream` |
| TC-CMC-455 | missing resource fails fast | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::missingResourceFailsFast` |
| TC-CMC-456 | unknown keyId is rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::unknownKeyId` |
| TC-CMC-457 | rejectsInvalidJson | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsInvalidJson` |
| TC-CMC-458 | rejectsEmptyKeysArray | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsEmptyKeysArray` |
| TC-CMC-459 | rejectsWrongRawKeyLength | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsWrongRawKeyLength` |
| TC-CMC-460 | rejectsUnsupportedStatus | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsUnsupportedStatus` |
| TC-CMC-461 | rejectsDuplicateKeyId | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsDuplicateKeyId` |
| TC-CMC-462 | sign/verify round trip accepts a well-formed license | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::roundTrip` |
| TC-CMC-463 | tampered signature is rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tamperedSignature` |
| TC-CMC-464 | tampered payload is rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tamperedPayload` |
| TC-CMC-465 | payloadSha256 mismatch is rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::payloadShaMismatch` |
| TC-CMC-466 | unsupported keyId is rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::unsupportedKeyId` |
| TC-CMC-467 | payload signed correctly but carrying a different keyId than the envelope is rejected | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::keyIdMismatchBetweenEnvelopeAndPayload` |
| TC-CMC-468 | matching binding and valid window succeeds | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::success` |
| TC-CMC-469 | tenant mismatch reports LICENSE_BINDING_MISMATCH | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tenantMismatch` |
| TC-CMC-470 | installation mismatch reports LICENSE_BINDING_MISMATCH | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::installationMismatch` |
| TC-CMC-471 | fingerprint mismatch reports LICENSE_BINDING_MISMATCH | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::fingerprintMismatch` |
| TC-CMC-472 | expired license reports LICENSE_EXPIRED | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::expiredLicense` |
| TC-CMC-473 | issuedAt in the future beyond tolerance reports LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::notYetValid` |
| TC-CMC-474 | issuedAt slightly in the future within tolerance is accepted | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::toleranceAbsorbsClockSkew` |
| TC-CMC-475 | crypto failures surface as LICENSE_INVALID results, not exceptions | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::cryptoFailureBecomesResult` |
| TC-CMC-476 | hashes the stripped machine-id content | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::hashesStrippedContent` |
| TC-CMC-477 | same host id yields a stable, equal fingerprint | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::stableAndEqual` |
| TC-CMC-478 | missing source file fails with the path in the message | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::missingFile` |
| TC-CMC-479 | blank source file fails | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::blankFile` |
| TC-CMC-480 | shared canonical vectors: Python expected bytes reproduce in Java | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::canonicalVectorsMatchByteForByte` |
| TC-CMC-481 | issuer roundtrip: canonical bytes identical and envelope verifies | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::roundtripEnvelopeVerifies` |
| TC-CMC-482 | issuer roundtrip: tampered payload rejected with LICENSE_INVALID | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::tamperedRoundtripPayloadRejected` |
| TC-CMC-483 | livestockUsage_countedFromLivestockJoin | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::livestockUsage_countedFromLivestockJoin` |
| TC-CMC-484 | deviceUsage_countedFromDevices | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::deviceUsage_countedFromDevices` |
| TC-CMC-485 | workerUsage_countedFromAssignments | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::workerUsage_countedFromAssignments` |
| TC-CMC-486 | fenceUsage_countedFromFenceJoin | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::fenceUsage_countedFromFenceJoin` |
| TC-CMC-487 | unknownKey_countsAsZeroWithoutQuerying | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::unknownKey_countsAsZeroWithoutQuerying` |
| TC-CMC-488 | onPremDeploymentRejectsPilotGrantEvenWhenFlagEnabled | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::onPremDeploymentRejectsPilotGrantEvenWhenFlagEnabled` |
| TC-CMC-489 | hostedDeploymentWithFlagGrantsPilotLicense | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::hostedDeploymentWithFlagGrantsPilotLicense` |
| TC-CMC-490 | requestedDeadlineForwardedToService | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::requestedDeadlineForwardedToService` |
| TC-CMC-491 | unparseableDeadlineRejectedBeforeService | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::unparseableDeadlineRejectedBeforeService` |
| TC-CMC-492 | nonPlatformAdminIsRejected | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::nonPlatformAdminIsRejected` |
| TC-CMC-493 | hostedModeReportsNullRuntimeStatus | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::hostedModeReportsNullRuntimeStatus` |
| TC-CMC-494 | onpremModeReportsLatestRuntimeStatus | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::onpremModeReportsLatestRuntimeStatus` |
| TC-CMC-495 | onpremModeWithoutStateReportsNullRuntimeStatus | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::onpremModeWithoutStateReportsNullRuntimeStatus` |
| TC-CMC-496 | nonPlatformAdminIsRejectedOnEveryEndpoint | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::nonPlatformAdminIsRejectedOnEveryEndpoint` |
| TC-CMC-497 | unauthenticatedIsRejected | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::unauthenticatedIsRejected` |
| TC-CMC-498 | enrollmentIsOnPremOnly | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::enrollmentIsOnPremOnly` |
| TC-CMC-499 | currentIsOnPremOnly | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::currentIsOnPremOnly` |
| TC-CMC-500 | importIsOnPremOnly | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::importIsOnPremOnly` |
| TC-CMC-501 | modeEndpointIsUsableInEveryMode | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::modeEndpointIsUsableInEveryMode` |
| TC-CMC-502 | enrollmentReturnsAssembledDto | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::enrollmentReturnsAssembledDto` |
| TC-CMC-503 | currentReturnsStatusDto | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::currentReturnsStatusDto` |
| TC-CMC-504 | modeReportsOnPremAndDisabledPilot | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::modeReportsOnPremAndDisabledPilot` |
| TC-CMC-505 | multipartImportWithFileAndConfirmSucceeds | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithFileAndConfirmSucceeds` |
| TC-CMC-506 | multipartImportWithoutConfirmPropagatesFalseAndIsRefused | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithoutConfirmPropagatesFalseAndIsRefused` |
| TC-CMC-507 | multipartImportWithoutFileIsValidationErrorBeforeService | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithoutFileIsValidationErrorBeforeService` |
| TC-CMC-508 | oversizedFileIsRejectedBeforeService | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::oversizedFileIsRejectedBeforeService` |
| TC-CMC-509 | malformedEnvelopeSurfacesLicenseInvalidFromService | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::malformedEnvelopeSurfacesLicenseInvalidFromService` |
| TC-CMC-510 | anonymousEnrollmentAllowedWhileWindowOpen_usesSeededTenant | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousEnrollmentAllowedWhileWindowOpen_usesSeededTenant` |
| TC-CMC-511 | anonymousImportRejectedWhenCertificateCarriesNoAdminBootstrap | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousImportRejectedWhenCertificateCarriesNoAdminBootstrap` |
| TC-CMC-512 | anonymousImportStillBlockedWhenWindowClosed | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousImportStillBlockedWhenWindowClosed` |

## 用例明细（初稿模板）

### TC-CMC-342 noSubscription_createsTrial365Days_andAuditsGrant

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::noSubscription_createsTrial365Days_andAuditsGrant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-343 activeTrialEndingEarlier_extendsToPilotEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::activeTrialEndingEarlier_extendsToPilotEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-344 activeTrialEndingLater_rollingMode_keepsLongerCurrentEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::activeTrialEndingLater_rollingMode_keepsLongerCurrentEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-345 fixedDeadline_configured_noSubscription_createsTrialAtDeadline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_configured_noSubscription_createsTrialAtDeadline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-346 fixedDeadline_configured_laterCurrentTrial_convergesBackToDeadline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_configured_laterCurrentTrial_convergesBackToDeadline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-347 fixedDeadline_unparseableValue_failsFast

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::fixedDeadline_unparseableValue_failsFast`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-348 requestedDeadline_noSubscription_createsTrialAtRequestedEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_noSubscription_createsTrialAtRequestedEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-349 requestedDeadline_laterCurrentTrial_convergesToRequestedEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_laterCurrentTrial_convergesToRequestedEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-350 requestedDeadline_inPast_rejectedAsValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::requestedDeadline_inPast_rejectedAsValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-351 configuredDeadline_auditRecordsConfiguredSource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::configuredDeadline_auditRecordsConfiguredSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-352 expiredTrial_canBeReEnrolled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::expiredTrial_canBeReEnrolled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-353 onPremMode_forbidden

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::onPremMode_forbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-354 disabledPilot_forbidden

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::disabledPilot_forbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-355 modeIsCaseInsensitive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::modeIsCaseInsensitive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-356 missingAuthentication_rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CloudPilotLicenseServiceTest.java::missingAuthentication_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-357 mapsSnapshotFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::mapsSnapshotFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-002

### TC-CMC-358 emptyWhenNoSubscription

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::emptyWhenNoSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-359 noSubscription_createsTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::noSubscription_createsTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-360 existingTrial_extendsTrialEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::existingTrial_extendsTrialEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-361 existingActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::existingActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-362 fromTrial_activatesWithTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_activatesWithTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-363 fromFree_transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromFree_transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-364 active_updatesTierAndStaysActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::active_updatesTierAndStaysActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-365 suspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::suspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-366 lowercaseTierName_isAccepted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::lowercaseTierName_isAccepted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-367 unknownTier_throwsValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::unknownTier_throwsValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-368 missingSubscription_throwsNotFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::missingSubscription_throwsNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-369 fromTrial_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-370 fromRenewalFailed_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromRenewalFailed_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-371 fromFree_isIdempotent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromFree_isIdempotent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-372 fromActive_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromActive_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-373 fromSuspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromSuspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-374 fromActive_suspends

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromActive_suspends`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-375 fromSuspended_isIdempotent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromSuspended_isIdempotent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-376 fromTrial_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::fromTrial_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-377 missingSubscription_throwsNotFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/CommerceLicenseAdapterTest.java::missingSubscription_throwsNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-378 firstEnroll_createsInstallationWithGeneratedId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::firstEnroll_createsInstallationWithGeneratedId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-379 reEnroll_keepsInstallationIdStable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::reEnroll_keepsInstallationIdStable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-380 notConfirmed_rejectsWithValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::notConfirmed_rejectsWithValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-381 notEnrolled_rejectsWithValidationError

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::notEnrolled_rejectsWithValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-382 unreadableEnvelope_writesRejectedEventAndThrowsInvalid

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::unreadableEnvelope_writesRejectedEventAndThrowsInvalid`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-383 trialImportWithoutSubscription_appliesTrialAndStoresCurrentLicense

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportWithoutSubscription_appliesTrialAndStoresCurrentLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-384 trialImportOverActiveTrial_extendsTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportOverActiveTrial_extendsTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-385 activeImportFromFreeSubscription_activatesWithTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::activeImportFromFreeSubscription_activatesWithTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-386 importReplacesPreviousLicense_oldRecordMarkedReplaced

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::importReplacesPreviousLicense_oldRecordMarkedReplaced`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-387 bindingMismatch_persistsRejectedRecordAndThrows

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::bindingMismatch_persistsRejectedRecordAndThrows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-388 quotaExceeded_rejectsImportWithoutTouchingSubscription

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::quotaExceeded_rejectsImportWithoutTouchingSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-003、REQ-CMC-009

### TC-CMC-389 quotaKeyAbsentFromPayload_skipsThatPrecheck

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::quotaKeyAbsentFromPayload_skipsThatPrecheck`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006

### TC-CMC-390 trialImportAfterTrialDegradedToFree_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportAfterTrialDegradedToFree_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-391 trialImportOverExpiredTrial_rejects

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::trialImportOverExpiredTrial_rejects`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-392 expiredLicenseImport_rejectedAsExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::expiredLicenseImport_rejectedAsExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-393 windowImport_requiresAdminBootstrap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::windowImport_requiresAdminBootstrap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-394 windowImportWithAdminBootstrap_createsAdminAccount

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::windowImportWithAdminBootstrap_createsAdminAccount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-395 renewalWithoutAdminFields_keepsExistingAdminUntouched

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::renewalWithoutAdminFields_keepsExistingAdminUntouched`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-396 halfAdminPair_isInvalidPayload

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::halfAdminPair_isInvalidPayload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-397 replayedCertificate_rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::replayedCertificate_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-398 reportsInstallationLicenseStateAndSubscription

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::reportsInstallationLicenseStateAndSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-399 beforeEnroll_reportsPendingActivation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseApplicationServiceTest.java::beforeEnroll_reportsPendingActivation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-400 hostedMode_isNoOp

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::hostedMode_isNoOp`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-401 validatesEveryTenantWithInstallation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::validatesEveryTenantWithInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-402 tenantFailureDoesNotBlockOthers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::tenantFailureDoesNotBlockOthers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-403 noInstallations_noValidation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/DeploymentLicenseSchedulerTest.java::noInstallations_noValidation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-404 onPremModeIsDetectedCaseInsensitively

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::onPremModeIsDetectedCaseInsensitively`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-405 requireOnPremPassesOnlyInOnPremMode

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::requireOnPremPassesOnlyInOnPremMode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-406 requireSelfServiceAllowedPassesOnlyInHostedMode

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseModeGuardTest.java::requireSelfServiceAllowedPassesOnlyInHostedMode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-407 noInstallation_returnsEmptyAndWritesNothing

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::noInstallation_returnsEmptyAndWritesNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-408 firstValidationWithValidLicense_marksValidAndAdvancesAnchor

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::firstValidationWithValidLicense_marksValidAndAdvancesAnchor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-409 recoveryFromSuspension_revalidatesRawLicenseAndRemapsSubscription

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::recoveryFromSuspension_revalidatesRawLicenseAndRemapsSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-410 trialLicenseRecoveryOverFreeSubscription_keepsRuntimeValidSkipsRemap

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::trialLicenseRecoveryOverFreeSubscription_keepsRuntimeValidSkipsRemap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-411 expiredLicense_marksExpiredAndDowngradesSubscription

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::expiredLicense_marksExpiredAndDowngradesSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-412 downgradeConflict_stillMarksRuntimeExpired

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::downgradeConflict_stillMarksRuntimeExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-413 rollbackBeyondTolerance_suspendsAndKeepsAnchorMonotonic

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::rollbackBeyondTolerance_suspendsAndKeepsAnchorMonotonic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-414 rollbackWithinTolerance_staysValid

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::rollbackWithinTolerance_staysValid`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-415 suspendConflict_stillMarksRuntimeSuspended

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::suspendConflict_stillMarksRuntimeSuspended`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-416 currentLicenseRecordDeleted_fallsBackToPendingActivation

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::currentLicenseRecordDeleted_fallsBackToPendingActivation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-417 tamperedRawLicense_suspendsWithInvalidProtection

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::tamperedRawLicense_suspendsWithInvalidProtection`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-418 replacedChainWithoutCurrent_fallsBackToPendingActivation

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/application/LicenseTimeGuardServiceTest.java::replacedChainWithoutCurrent_fallsBackToPendingActivation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-004

### TC-CMC-419 accepts 64-char hex and normalizes to lowercase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::acceptsAndNormalizesHex`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-420 strips surrounding whitespace before validation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::stripsWhitespace`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-421 rejects non-hex or wrong-length digests with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::rejectsMalformedDigests`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-422 matches compares normalized digests

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/HostFingerprintTest.java::matchesNormalized`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-423 parsesWellFormedEnvelope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::parsesWellFormedEnvelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-424 decodesPayloadAndSignatureBytes

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::decodesPayloadAndSignatureBytes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-425 rejectsBlankInput

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsBlankInput`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-426 rejectsNonJsonInput

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsNonJsonInput`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-427 rejectsUnsupportedFormat

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsUnsupportedFormat`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-428 rejectsMissingSignature

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsMissingSignature`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-429 rejectsPayloadSha256ThatIsNotHex64

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsPayloadSha256ThatIsNotHex64`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-430 rejectsPayloadThatIsNotBase64Url

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::rejectsPayloadThatIsNotBase64Url`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-431 normalizesPayloadSha256ToLowerCase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicenseEnvelopeTest.java::normalizesPayloadSha256ToLowerCase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-432 parsesAllFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesAllFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-433 parsesOptionalReplacesLicenseId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesOptionalReplacesLicenseId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-434 parsesAdminBootstrapPair

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::parsesAdminBootstrapPair`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-435 omitsAdminFieldsWhenAbsent_keepingCanonicalFormStable

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::omitsAdminFieldsWhenAbsent_keepingCanonicalFormStable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-436 rejectsHalfAdminPair

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsHalfAdminPair`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-437 rejectsNonBcryptAdminPasswordHash

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonBcryptAdminPasswordHash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-438 toMapRoundTripsThroughFromMap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::toMapRoundTripsThroughFromMap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-002

### TC-CMC-439 rejectsUnsupportedPayloadVersion

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsUnsupportedPayloadVersion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-440 rejectsUnknownLicenseType

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsUnknownLicenseType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-441 rejectsMissingRequiredField

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsMissingRequiredField`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-442 rejectsNonUuidLicenseId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonUuidLicenseId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-443 rejectsNonHexFingerprintHash

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonHexFingerprintHash`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-444 rejectsExpiresAtBeforeIssuedAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsExpiresAtBeforeIssuedAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-445 rejectsNonIntegerQuotaValues

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsNonIntegerQuotaValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006

### TC-CMC-446 rejectsQuotasThatAreNotAnObject

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/domain/LicensePayloadTest.java::rejectsQuotasThatAreNotAnObject`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009、REQ-CMC-004、REQ-CMC-006

### TC-CMC-447 shared vectors: Java canonical form matches expectedCanonical

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::sharedVectorsAreReproduced`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-448 keys sorted lexicographically at every level

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::sortsNestedKeys`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-449 instants rendered as UTC seconds form; integral doubles lose the decimal point

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::formatsInstantsAndIntegers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-450 strings escape mandatory JSON characters, non-ASCII stays raw

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::escapesStrings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-451 serialize/parse round trip preserves structure

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/CanonicalJsonSerializerTest.java::roundTripsThroughParse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-452 loads the committed production key list from main resources

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsProductionKeyList`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-453 loads the test key list via classpath resource

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsTestClasspathKeyList`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-454 accepts an explicit stream (tests / custom provisioning)

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::loadsFromStream`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-PLT-001

### TC-CMC-455 missing resource fails fast

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::missingResourceFailsFast`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-456 unknown keyId is rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::unknownKeyId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-457 rejectsInvalidJson

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsInvalidJson`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-458 rejectsEmptyKeysArray

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsEmptyKeysArray`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-459 rejectsWrongRawKeyLength

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsWrongRawKeyLength`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-460 rejectsUnsupportedStatus

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsUnsupportedStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-461 rejectsDuplicateKeyId

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/ClasspathLicensePublicKeyRegistryTest.java::rejectsDuplicateKeyId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-462 sign/verify round trip accepts a well-formed license

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::roundTrip`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-463 tampered signature is rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tamperedSignature`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-464 tampered payload is rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tamperedPayload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-465 payloadSha256 mismatch is rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::payloadShaMismatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-466 unsupported keyId is rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::unsupportedKeyId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-467 payload signed correctly but carrying a different keyId than the envelope is rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::keyIdMismatchBetweenEnvelopeAndPayload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-468 matching binding and valid window succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-469 tenant mismatch reports LICENSE_BINDING_MISMATCH

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::tenantMismatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-470 installation mismatch reports LICENSE_BINDING_MISMATCH

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::installationMismatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-471 fingerprint mismatch reports LICENSE_BINDING_MISMATCH

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::fingerprintMismatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-472 expired license reports LICENSE_EXPIRED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::expiredLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-473 issuedAt in the future beyond tolerance reports LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::notYetValid`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-474 issuedAt slightly in the future within tolerance is accepted

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::toleranceAbsorbsClockSkew`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-475 crypto failures surface as LICENSE_INVALID results, not exceptions

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/Ed25519LicenseVerifierTest.java::cryptoFailureBecomesResult`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-476 hashes the stripped machine-id content

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::hashesStrippedContent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-477 same host id yields a stable, equal fingerprint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::stableAndEqual`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-478 missing source file fails with the path in the message

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::missingFile`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-479 blank source file fails

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/HostFingerprintReaderTest.java::blankFile`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-480 shared canonical vectors: Python expected bytes reproduce in Java

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::canonicalVectorsMatchByteForByte`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-481 issuer roundtrip: canonical bytes identical and envelope verifies

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::roundtripEnvelopeVerifies`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-482 issuer roundtrip: tampered payload rejected with LICENSE_INVALID

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/IssuerRoundtripVectorTest.java::tamperedRoundtripPayloadRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-483 livestockUsage_countedFromLivestockJoin

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::livestockUsage_countedFromLivestockJoin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-484 deviceUsage_countedFromDevices

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::deviceUsage_countedFromDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-485 workerUsage_countedFromAssignments

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::workerUsage_countedFromAssignments`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-486 fenceUsage_countedFromFenceJoin

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::fenceUsage_countedFromFenceJoin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-487 unknownKey_countsAsZeroWithoutQuerying

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/infrastructure/LicenseUsageQueryAdapterTest.java::unknownKey_countsAsZeroWithoutQuerying`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-488 onPremDeploymentRejectsPilotGrantEvenWhenFlagEnabled

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::onPremDeploymentRejectsPilotGrantEvenWhenFlagEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-489 hostedDeploymentWithFlagGrantsPilotLicense

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::hostedDeploymentWithFlagGrantsPilotLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-490 requestedDeadlineForwardedToService

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::requestedDeadlineForwardedToService`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-491 unparseableDeadlineRejectedBeforeService

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::unparseableDeadlineRejectedBeforeService`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-492 nonPlatformAdminIsRejected

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/CloudPilotLicenseControllerTest.java::nonPlatformAdminIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-493 hostedModeReportsNullRuntimeStatus

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::hostedModeReportsNullRuntimeStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-CMC-494 onpremModeReportsLatestRuntimeStatus

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::onpremModeReportsLatestRuntimeStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-495 onpremModeWithoutStateReportsNullRuntimeStatus

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentInfoControllerTest.java::onpremModeWithoutStateReportsNullRuntimeStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-496 nonPlatformAdminIsRejectedOnEveryEndpoint

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::nonPlatformAdminIsRejectedOnEveryEndpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-497 unauthenticatedIsRejected

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::unauthenticatedIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-498 enrollmentIsOnPremOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::enrollmentIsOnPremOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-499 currentIsOnPremOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::currentIsOnPremOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-500 importIsOnPremOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::importIsOnPremOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-501 modeEndpointIsUsableInEveryMode

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::modeEndpointIsUsableInEveryMode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-502 enrollmentReturnsAssembledDto

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::enrollmentReturnsAssembledDto`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-PLT-001

### TC-CMC-503 currentReturnsStatusDto

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::currentReturnsStatusDto`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-504 modeReportsOnPremAndDisabledPilot

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::modeReportsOnPremAndDisabledPilot`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-505 multipartImportWithFileAndConfirmSucceeds

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithFileAndConfirmSucceeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-506 multipartImportWithoutConfirmPropagatesFalseAndIsRefused

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithoutConfirmPropagatesFalseAndIsRefused`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-507 multipartImportWithoutFileIsValidationErrorBeforeService

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::multipartImportWithoutFileIsValidationErrorBeforeService`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-508 oversizedFileIsRejectedBeforeService

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::oversizedFileIsRejectedBeforeService`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-509 malformedEnvelopeSurfacesLicenseInvalidFromService

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::malformedEnvelopeSurfacesLicenseInvalidFromService`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-510 anonymousEnrollmentAllowedWhileWindowOpen_usesSeededTenant

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousEnrollmentAllowedWhileWindowOpen_usesSeededTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-511 anonymousImportRejectedWhenCertificateCarriesNoAdminBootstrap

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousImportRejectedWhenCertificateCarriesNoAdminBootstrap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-512 anonymousImportStillBlockedWhenWindowClosed

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/licensing/interfaces/DeploymentLicenseAdminControllerTest.java::anonymousImportStillBlockedWhenWindowClosed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

