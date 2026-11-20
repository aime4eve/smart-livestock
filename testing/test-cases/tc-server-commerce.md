# 测试用例规格：后端·订阅与商业（commerce）

> 用例域：CMC ｜ 用例数：258
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-CMC-084 | createsDraftContract | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::createsDraftContract` |
| TC-CMC-085 | invalidRevenueShareRatio_throws | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::invalidRevenueShareRatio_throws` |
| TC-CMC-086 | draftContract_signsSuccessfully | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::draftContract_signsSuccessfully` |
| TC-CMC-087 | contractNotFound_throws | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::contractNotFound_throws` |
| TC-CMC-088 | activeContract_suspends | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::activeContract_suspends` |
| TC-CMC-089 | suspendedContract_reactivates | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::suspendedContract_reactivates` |
| TC-CMC-090 | activeContract_terminates | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::activeContract_terminates` |
| TC-CMC-091 | contractNotFound_doesNotPublish | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::contractNotFound_doesNotPublish` |
| TC-CMC-092 | missing settings row falls back to SHOW_LOCKED | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::missingRow_fallsBackToShowLocked` |
| TC-CMC-093 | repository failure falls back to SHOW_LOCKED | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::repositoryFailure_fallsBackToShowLocked` |
| TC-CMC-094 | persisted HIDE policy is returned | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::persistedHide_isReturned` |
| TC-CMC-095 | cache hit within TTL does not re-read the repository | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::cacheHit_skipsRepository` |
| TC-CMC-096 | getLockedTilePolicy delegates to the provider (fallback included) | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::get_delegatesToProvider` |
| TC-CMC-097 | update persists the policy, records an audit entry and invalidates the cache | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::update_persistsAuditsAndInvalidates` |
| TC-CMC-098 | update with a null policy is rejected with VALIDATION_ERROR | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::update_nullPolicy_rejected` |
| TC-CMC-099 | parsePolicy accepts case-insensitive values from the domain | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::parsePolicy_acceptsKnownValues` |
| TC-CMC-100 | parsePolicy rejects anything outside the value domain | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::parsePolicy_rejectsUnknownValues` |
| TC-CMC-101 | subscriptionNotFound_throwsDomainException | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::subscriptionNotFound_throwsDomainException` |
| TC-CMC-102 | suspendedSubscription_deniedRegardlessOfGate | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::suspendedSubscription_deniedRegardlessOfGate` |
| TC-CMC-103 | cancelledSubscription_denied | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::cancelledSubscription_denied` |
| TC-CMC-104 | expiredSubscription_denied | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::expiredSubscription_denied` |
| TC-CMC-105 | renewalFailedSubscription_denied | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::renewalFailedSubscription_denied` |
| TC-CMC-106 | allowsAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::allowsAccess` |
| TC-CMC-107 | missingGate_treatedAsNone | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::missingGate_treatedAsNone` |
| TC-CMC-108 | enabledLock_allowsAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::enabledLock_allowsAccess` |
| TC-CMC-109 | disabledLock_deniesAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::disabledLock_deniesAccess` |
| TC-CMC-110 | underLimit_allowsAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::underLimit_allowsAccess` |
| TC-CMC-111 | atLimit_deniesAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::atLimit_deniesAccess` |
| TC-CMC-112 | overLimit_deniesAccess | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::overLimit_deniesAccess` |
| TC-CMC-113 | allowedWithRetentionDays | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::allowedWithRetentionDays` |
| TC-CMC-114 | trialUsesEffectiveTierPremium | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::trialUsesEffectiveTierPremium` |
| TC-CMC-115 | licenseQuotaPresent_overridesFeatureGate | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaPresent_overridesFeatureGate` |
| TC-CMC-116 | licenseQuotaBoundaryUsageInclusive_allowed | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaBoundaryUsageInclusive_allowed` |
| TC-CMC-117 | licenseQuotaExceeded_deniesWithLocalizedMessage | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaExceeded_deniesWithLocalizedMessage` |
| TC-CMC-118 | licenseQuotaEmpty_fallsBackToFeatureGateLimit | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaEmpty_fallsBackToFeatureGateLimit` |
| TC-CMC-119 | calculatesPeriodForActiveContract | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::calculatesPeriodForActiveContract` |
| TC-CMC-120 | inactiveContract_throws | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::inactiveContract_throws` |
| TC-CMC-121 | pendingPeriod_confirmedByPlatform | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::pendingPeriod_confirmedByPlatform` |
| TC-CMC-122 | platformConfirmedPeriod_confirmedByPartner | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::platformConfirmedPeriod_confirmedByPartner` |
| TC-CMC-123 | partnerConfirmedPeriod_settles | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::partnerConfirmedPeriod_settles` |
| TC-CMC-124 | updatesExistingPeriod_inPlace | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::updatesExistingPeriod_inPlace` |
| TC-CMC-125 | settledPeriod_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::settledPeriod_throwsStateConflict` |
| TC-CMC-126 | existingSubscription_returnsExisting | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::existingSubscription_returnsExisting` |
| TC-CMC-127 | noExistingSubscription_createsTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noExistingSubscription_createsTrial` |
| TC-CMC-128 | noExistingSubscription_fixedDeadlineConfigured_createsTrialAtDeadline | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noExistingSubscription_fixedDeadlineConfigured_createsTrialAtDeadline` |
| TC-CMC-129 | fromTrialToActive_succeeds | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::fromTrialToActive_succeeds` |
| TC-CMC-130 | fromActiveTierChange_succeeds | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::fromActiveTierChange_succeeds` |
| TC-CMC-131 | nullBillingCycle_reusesCurrentCycle | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::nullBillingCycle_reusesCurrentCycle` |
| TC-CMC-132 | nullBillingCycle_andNoCurrentCycle_defaultsToMonthly | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::nullBillingCycle_andNoCurrentCycle_defaultsToMonthly` |
| TC-CMC-133 | subscriptionNotFound_throws | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::subscriptionNotFound_throws` |
| TC-CMC-134 | trialSubscription_expiresToFree | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::trialSubscription_expiresToFree` |
| TC-CMC-135 | activeSubscription_succeeds | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::activeSubscription_succeeds` |
| TC-CMC-136 | suspendedSubscription_reactivates | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::suspendedSubscription_reactivates` |
| TC-CMC-137 | activeSubscription_cancels | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::activeSubscription_cancels` |
| TC-CMC-138 | trialSubscription_cancels | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::trialSubscription_cancels` |
| TC-CMC-139 | publishesAndClearsDomainEvents | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::publishesAndClearsDomainEvents` |
| TC-CMC-140 | noSubscriptionFound_doesNotPublish | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noSubscriptionFound_doesNotPublish` |
| TC-CMC-141 | regrantAfterPremiumDropsTierToBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::regrantAfterPremiumDropsTierToBasic` |
| TC-CMC-142 | lapsedRegrantedTrialResolvesToBasicNotStalePremium | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::lapsedRegrantedTrialResolvesToBasicNotStalePremium` |
| TC-CMC-143 | lapsedPeriod_restartsOneCycleFromNow | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::lapsedPeriod_restartsOneCycleFromNow` |
| TC-CMC-144 | periodStillRunning_extendsFromPreviousExpiry | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::periodStillRunning_extendsFromPreviousExpiry` |
| TC-CMC-145 | yearlyCycle_extendsOneYear | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::yearlyCycle_extendsOneYear` |
| TC-CMC-146 | notRenewalFailed_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::notRenewalFailed_throwsStateConflict` |
| TC-CMC-147 | everySampleLandsOnItsMatrixState | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::everySampleLandsOnItsMatrixState` |
| TC-CMC-148 | trialLapsedDoesNotShowAsTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::trialLapsedDoesNotShowAsTrial` |
| TC-CMC-149 | expiringSoonLevels | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::expiringSoonLevels` |
| TC-CMC-150 | defaultTiersKeepSnoozeGateOn14And7Only | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::defaultTiersKeepSnoozeGateOn14And7Only` |
| TC-CMC-151 | defaultTiersMapSeverity14Info7Warn3Danger | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::defaultTiersMapSeverity14Info7Warn3Danger` |
| TC-CMC-152 | trialBannerEscalatesSeverityByLevelWithoutSnooze | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::trialBannerEscalatesSeverityByLevelWithoutSnooze` |
| TC-CMC-153 | severityNonNullWhereverLevelPresentSnoozeOnlyInExpiringSoon | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::severityNonNullWhereverLevelPresentSnoozeOnlyInExpiringSoon` |
| TC-CMC-154 | customTiersDriveWindowLevelAndSnoozeGate | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::customTiersDriveWindowLevelAndSnoozeGate` |
| TC-CMC-155 | degradedAndExportEligibilityAgreeOnEverySample | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::degradedAndExportEligibilityAgreeOnEverySample` |
| TC-CMC-156 | setsDraftStatusAndFields | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::setsDraftStatusAndFields` |
| TC-CMC-157 | registersContractCreatedEvent | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::registersContractCreatedEvent` |
| TC-CMC-158 | revenueShareModel_requiresRatio | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::revenueShareModel_requiresRatio` |
| TC-CMC-159 | nonRevenueShareModel_allowsNullRatio | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::nonRevenueShareModel_allowsNullRatio` |
| TC-CMC-160 | ratioMustBeGreaterThanZero | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::ratioMustBeGreaterThanZero` |
| TC-CMC-161 | ratioMustBeLessThanOne | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::ratioMustBeLessThanOne` |
| TC-CMC-162 | transitionsToActive | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToActive` |
| TC-CMC-163 | registersContractSignedEvent | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::registersContractSignedEvent` |
| TC-CMC-164 | suspend_transitionsToSuspended | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::suspend_transitionsToSuspended` |
| TC-CMC-165 | reactivate_transitionsToActive | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::reactivate_transitionsToActive` |
| TC-CMC-166 | transitionsToTerminated | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToTerminated` |
| TC-CMC-167 | transitionsToExpired | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToExpired` |
| TC-CMC-168 | calculatesSharesFromRatio | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::calculatesSharesFromRatio` |
| TC-CMC-169 | differentRatio | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::differentRatio` |
| TC-CMC-170 | zeroGrossAmount | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::zeroGrossAmount` |
| TC-CMC-171 | rejectsNegativeGrossAmount | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::rejectsNegativeGrossAmount` |
| TC-CMC-172 | signFromActive_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::signFromActive_throwsStateConflict` |
| TC-CMC-173 | suspendFromDraft_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::suspendFromDraft_throwsStateConflict` |
| TC-CMC-174 | reactivateFromActive_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::reactivateFromActive_throwsStateConflict` |
| TC-CMC-175 | terminateFromSuspended_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::terminateFromSuspended_throwsStateConflict` |
| TC-CMC-176 | markExpiredFromSuspended_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::markExpiredFromSuspended_throwsStateConflict` |
| TC-CMC-177 | terminateFromDraft_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::terminateFromDraft_throwsStateConflict` |
| TC-CMC-178 | markExpiredFromDraft_throwsStateConflict | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::markExpiredFromDraft_throwsStateConflict` |
| TC-CMC-179 | unrestricted_allowsAccess | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::unrestricted_allowsAccess` |
| TC-CMC-180 | isLockedWhenEnabled | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLockedWhenEnabled` |
| TC-CMC-181 | isLockedWhenDisabled | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLockedWhenDisabled` |
| TC-CMC-182 | isLimitedWithLimitValue | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLimitedWithLimitValue` |
| TC-CMC-183 | isLimitedWithNullRetentionDays | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLimitedWithNullRetentionDays` |
| TC-CMC-184 | isFilteredWithRetentionDays | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isFilteredWithRetentionDays` |
| TC-CMC-185 | createsNoneGate | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::createsNoneGate` |
| TC-CMC-186 | setsPendingStatusAndFields | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::setsPendingStatusAndFields` |
| TC-CMC-187 | registersRevenuePeriodCreatedEvent | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::registersRevenuePeriodCreatedEvent` |
| TC-CMC-188 | allowsRatioEqualToZero_forDirectModel | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::allowsRatioEqualToZero_forDirectModel` |
| TC-CMC-189 | rejectsRatioEqualToOne | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsRatioEqualToOne` |
| TC-CMC-190 | rejectsSharesNotSummingToGross | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsSharesNotSummingToGross` |
| TC-CMC-191 | rejectsPeriodEndBeforeStart | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsPeriodEndBeforeStart` |
| TC-CMC-192 | transitionsToPlatformConfirmed | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToPlatformConfirmed` |
| TC-CMC-193 | rejectsFromNonPending | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromNonPending` |
| TC-CMC-194 | rejectsFromSettled | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromSettled` |
| TC-CMC-195 | transitionsToPartnerConfirmed | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToPartnerConfirmed` |
| TC-CMC-196 | rejectsFromPending | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPending` |
| TC-CMC-197 | rejectsFromPartnerConfirmed | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPartnerConfirmed` |
| TC-CMC-198 | transitionsToSettled | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToSettled` |
| TC-CMC-199 | rejectsFromPending | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPending` |
| TC-CMC-200 | rejectsFromPlatformConfirmed | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPlatformConfirmed` |
| TC-CMC-201 | rejectsFromSettled | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromSettled` |
| TC-CMC-202 | setsProvisionedStatusAndFields | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::setsProvisionedStatusAndFields` |
| TC-CMC-203 | hashesServiceKeyAndExtractsPrefix | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::hashesServiceKeyAndExtractsPrefix` |
| TC-CMC-204 | registersServiceProvisionedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::registersServiceProvisionedEvent` |
| TC-CMC-205 | transitionsToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsToActive` |
| TC-CMC-206 | registersServiceActivatedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::registersServiceActivatedEvent` |
| TC-CMC-207 | rejectsFromNonProvisioned | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromNonProvisioned` |
| TC-CMC-208 | updatesLastHeartbeatAt | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::updatesLastHeartbeatAt` |
| TC-CMC-209 | fromGracePeriod_transitionsBackToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::fromGracePeriod_transitionsBackToActive` |
| TC-CMC-210 | rejectsFromProvisioned | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned` |
| TC-CMC-211 | rejectsFromExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired` |
| TC-CMC-212 | whenHeartbeatOverdue_transitionsToGracePeriod | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::whenHeartbeatOverdue_transitionsToGracePeriod` |
| TC-CMC-213 | whenHeartbeatRecent_staysActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::whenHeartbeatRecent_staysActive` |
| TC-CMC-214 | rejectsFromProvisioned | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned` |
| TC-CMC-215 | rejectsFromExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired` |
| TC-CMC-216 | transitionsFromGracePeriodToDegraded | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromGracePeriodToDegraded` |
| TC-CMC-217 | rejectsFromActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromActive` |
| TC-CMC-218 | transitionsFromActiveToExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromActiveToExpired` |
| TC-CMC-219 | transitionsFromProvisionedToExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromProvisionedToExpired` |
| TC-CMC-220 | transitionsFromGracePeriodToExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromGracePeriodToExpired` |
| TC-CMC-221 | rejectsFromExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired` |
| TC-CMC-222 | transitionsFromActiveToExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromActiveToExpired` |
| TC-CMC-223 | rejectsFromProvisioned | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned` |
| TC-CMC-224 | rejectsFromExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired` |
| TC-CMC-225 | updatesQuotaAndRegistersEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::updatesQuotaAndRegistersEvent` |
| TC-CMC-226 | rejectsFromProvisioned | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned` |
| TC-CMC-227 | rejectsFromExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired` |
| TC-CMC-228 | acceptsCorrectKey | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::acceptsCorrectKey` |
| TC-CMC-229 | rejectsWrongKey | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsWrongKey` |
| TC-CMC-230 | rejectsNullKey | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsNullKey` |
| TC-CMC-231 | rejectsEmptyKey | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsEmptyKey` |
| TC-CMC-232 | setsTrialStatusAndFields | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::setsTrialStatusAndFields` |
| TC-CMC-233 | registersSubscriptionCreatedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersSubscriptionCreatedEvent` |
| TC-CMC-234 | activatesFromTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activatesFromTrial` |
| TC-CMC-235 | registersSubscriptionCreatedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersSubscriptionCreatedEvent` |
| TC-CMC-236 | transitionsToFreeWithBasicTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::transitionsToFreeWithBasicTier` |
| TC-CMC-237 | registersTierChangedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEvent` |
| TC-CMC-238 | rejectsFromNonTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsFromNonTrial` |
| TC-CMC-239 | extendsTrialEndFromTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::extendsTrialEndFromTrial` |
| TC-CMC-240 | rejectsFromNonTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsFromNonTrial` |
| TC-CMC-241 | rejectsShorteningCurrentTrialEnd | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsShorteningCurrentTrialEnd` |
| TC-CMC-242 | sameTimestampAllowed | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::sameTimestampAllowed` |
| TC-CMC-243 | setsTrialEndWhenCurrentIsNull | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::setsTrialEndWhenCurrentIsNull` |
| TC-CMC-244 | trialActive_returnsPremium | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::trialActive_returnsPremium` |
| TC-CMC-245 | trialExpired_returnsActualTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::trialExpired_returnsActualTier` |
| TC-CMC-246 | activeSubscription_returnsActualTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activeSubscription_returnsActualTier` |
| TC-CMC-247 | isActiveOrTrial_active | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_active` |
| TC-CMC-248 | isActiveOrTrial_trial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_trial` |
| TC-CMC-249 | isActiveOrTrial_free | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_free` |
| TC-CMC-250 | isActiveOrTrial_suspended_false | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_suspended_false` |
| TC-CMC-251 | isActiveOrTrial_cancelled_false | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_cancelled_false` |
| TC-CMC-252 | isActiveOrTrial_renewalFailed_false | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_renewalFailed_false` |
| TC-CMC-253 | isActiveOrTrial_expired_false | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_expired_false` |
| TC-CMC-254 | isTrialActive_nullTrialEndsAt_returnsFalse | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isTrialActive_nullTrialEndsAt_returnsFalse` |
| TC-CMC-255 | fromFreeToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromFreeToActive` |
| TC-CMC-256 | registersTierChangedEvent | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEvent` |
| TC-CMC-257 | fromTrial_transitionsToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromTrial_transitionsToActive` |
| TC-CMC-258 | fromRenewalFailed_repaysToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_repaysToActive` |
| TC-CMC-259 | fromRenewalFailed_sameTier_renewsInPlace | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_sameTier_renewsInPlace` |
| TC-CMC-260 | suspend_transitionsToSuspended | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspend_transitionsToSuspended` |
| TC-CMC-261 | reactivate_transitionsToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::reactivate_transitionsToActive` |
| TC-CMC-262 | suspendRequiresActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspendRequiresActive` |
| TC-CMC-263 | markRenewalFailed_transitionsToRenewalFailed | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markRenewalFailed_transitionsToRenewalFailed` |
| TC-CMC-264 | recoverFromRenewalFailure_transitionsToActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailure_transitionsToActive` |
| TC-CMC-265 | recoverFromRenewalFailureWithNewExpiry_restartsPeriod | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailureWithNewExpiry_restartsPeriod` |
| TC-CMC-266 | downgradeAfterRenewalFailure_transitionsToFree | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::downgradeAfterRenewalFailure_transitionsToFree` |
| TC-CMC-267 | cancelFromActive_setsCancelledAt | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromActive_setsCancelledAt` |
| TC-CMC-268 | cancelFromTrial | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromTrial` |
| TC-CMC-269 | transitionsToExpired | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::transitionsToExpired` |
| TC-CMC-270 | activateFromActive_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activateFromActive_throwsStateConflict` |
| TC-CMC-271 | reactivateFromActive_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::reactivateFromActive_throwsStateConflict` |
| TC-CMC-272 | cancelFromCancelled_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromCancelled_throwsStateConflict` |
| TC-CMC-273 | suspendFromSuspended_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspendFromSuspended_throwsStateConflict` |
| TC-CMC-274 | markRenewalFailedFromTrial_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markRenewalFailedFromTrial_throwsStateConflict` |
| TC-CMC-275 | recoverFromRenewalFailureWhenActive_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailureWhenActive_throwsStateConflict` |
| TC-CMC-276 | downgradeFromActive_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::downgradeFromActive_throwsStateConflict` |
| TC-CMC-277 | markExpiredFromCancelled_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markExpiredFromCancelled_throwsStateConflict` |
| TC-CMC-278 | fromActive_downgradesToFreeBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromActive_downgradesToFreeBasic` |
| TC-CMC-279 | fromTrial_downgradesToFreeBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromTrial_downgradesToFreeBasic` |
| TC-CMC-280 | fromRenewalFailed_downgradesToFreeBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_downgradesToFreeBasic` |
| TC-CMC-281 | fromFree_isIdempotentNoOp | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromFree_isIdempotentNoOp` |
| TC-CMC-282 | registersTierChangedEventFromActive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEventFromActive` |
| TC-CMC-283 | fromSuspended_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromSuspended_throwsStateConflict` |
| TC-CMC-284 | fromCancelled_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromCancelled_throwsStateConflict` |
| TC-CMC-285 | fromExpired_throwsStateConflict | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromExpired_throwsStateConflict` |
| TC-CMC-286 | basicIsFreeWithCap | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::basicIsFreeWithCap` |
| TC-CMC-287 | standardBands | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::standardBands` |
| TC-CMC-288 | premiumBands | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::premiumBands` |
| TC-CMC-289 | enterpriseHasNoBands | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::enterpriseHasNoBands` |
| TC-CMC-290 | bandBoundariesAreInclusive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::bandBoundariesAreInclusive` |
| TC-CMC-291 | headCountBelowLowestBandFallsBackToFirstBand | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::headCountBelowLowestBandFallsBackToFirstBand` |
| TC-CMC-292 | zeroHeadsCostsNothing | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::zeroHeadsCostsNothing` |
| TC-CMC-293 | smallHerd | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::smallHerd` |
| TC-CMC-294 | danishMainstreamHerd | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::danishMainstreamHerd` |
| TC-CMC-295 | largeHerd | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::largeHerd` |
| TC-CMC-296 | basicIsAlwaysFree | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::basicIsAlwaysFree` |
| TC-CMC-297 | enterpriseThrowsDomainException | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::enterpriseThrowsDomainException` |
| TC-CMC-298 | returnsEmptyRegardlessOfLicense | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::returnsEmptyRegardlessOfLicense` |
| TC-CMC-299 | validLicenseWithKey_returnsQuota | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::validLicenseWithKey_returnsQuota` |
| TC-CMC-300 | validLicenseWithoutKey_returnsEmpty | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::validLicenseWithoutKey_returnsEmpty` |
| TC-CMC-301 | expiredRuntime_returnsEmpty | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::expiredRuntime_returnsEmpty` |
| TC-CMC-302 | suspendedRuntime_returnsEmpty | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::suspendedRuntime_returnsEmpty` |
| TC-CMC-303 | noCurrentLicense_returnsEmpty | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::noCurrentLicense_returnsEmpty` |
| TC-CMC-304 | modeMatchIsCaseInsensitive | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::modeMatchIsCaseInsensitive` |
| TC-CMC-305 | resolvesLimitFromFeatureGateLimitRow | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::resolvesLimitFromFeatureGateLimitRow` |
| TC-CMC-306 | licenseQuotaWinsOverFeatureGate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::licenseQuotaWinsOverFeatureGate` |
| TC-CMC-307 | enterpriseNoneGateResolvesToNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::enterpriseNoneGateResolvesToNull` |
| TC-CMC-308 | missingGateRowResolvesToNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::missingGateRowResolvesToNull` |
| TC-CMC-309 | inactiveSubscriptionResolvesToNull | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::inactiveSubscriptionResolvesToNull` |
| TC-CMC-310 | noTenantContextResolvesToNullWithoutTouchingStores | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::noTenantContextResolvesToNullWithoutTouchingStores` |
| TC-CMC-311 | seedRowMatchesPreChangeHardcodedTiers | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::seedRowMatchesPreChangeHardcodedTiers` |
| TC-CMC-312 | unorderedTiersViolateTheCheckConstraint | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::unorderedTiersViolateTheCheckConstraint` |
| TC-CMC-313 | providerInvalidationReloadsPersistedTiers | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::providerInvalidationReloadsPersistedTiers` |
| TC-CMC-314 | allFieldsPreservedViaToJpaEntityAndBack | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack` |
| TC-CMC-315 | activeSubscriptionWithAllFieldsFilledRoundTrips | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::activeSubscriptionWithAllFieldsFilledRoundTrips` |
| TC-CMC-316 | updateEntityPreservesMutableFields | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::updateEntityPreservesMutableFields` |
| TC-CMC-317 | allFieldsPreservedViaToJpaEntityAndBack | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack` |
| TC-CMC-318 | draftContractRoundTrips | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::draftContractRoundTrips` |
| TC-CMC-319 | allFieldsPreservedViaToJpaEntityAndBack | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack` |
| TC-CMC-320 | settledPeriodRoundTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::settledPeriodRoundTrips` |
| TC-CMC-321 | allFieldsPreservedViaToJpaEntityAndBack | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack` |
| TC-CMC-322 | activatedServiceRoundTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::activatedServiceRoundTrips` |
| TC-CMC-323 | nullHeartbeatDefaultsPreserved | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::nullHeartbeatDefaultsPreserved` |
| TC-CMC-324 | limitGateRoundTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::limitGateRoundTrips` |
| TC-CMC-325 | filterGateRoundTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::filterGateRoundTrips` |
| TC-CMC-326 | disabledGateRoundTrips | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::disabledGateRoundTrips` |
| TC-CMC-327 | nullIsEnabledDefaultsToTrue | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::nullIsEnabledDefaultsToTrue` |
| TC-CMC-328 | onPremCheckoutIsRejectedWithLicenseRequired | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremCheckoutIsRejectedWithLicenseRequired` |
| TC-CMC-329 | onPremTierChangeIsRejectedWithLicenseRequired | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremTierChangeIsRejectedWithLicenseRequired` |
| TC-CMC-330 | onPremCancelIsRejectedWithLicenseRequired | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremCancelIsRejectedWithLicenseRequired` |
| TC-CMC-331 | hostedCheckoutKeepsWorking | P0 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::hostedCheckoutKeepsWorking` |
| TC-CMC-332 | onPremManualStatusChangeIsRejectedWithLicenseRequired | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremManualStatusChangeIsRejectedWithLicenseRequired` |
| TC-CMC-333 | hostedManualStatusChangeReachesBusinessLogic | P0 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::hostedManualStatusChangeReachesBusinessLogic` |
| TC-CMC-334 | onPremReadEndpointsStayUsable | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremReadEndpointsStayUsable` |
| TC-CMC-335 | classLevel_requiresPlatformAdminOnly | P0 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/AdminSubscriptionOverviewControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly` |
| TC-CMC-336 | endpoints_haveNoPerMethodOverride | P0 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/AdminSubscriptionOverviewControllerSecurityTest.java::endpoints_haveNoPerMethodOverride` |
| TC-CMC-337 | nonPlatformAdminIsRejectedOnEveryEndpoint | P0 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::nonPlatformAdminIsRejectedOnEveryEndpoint` |
| TC-CMC-338 | platformAdminGetsCurrentTiers | P0 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::platformAdminGetsCurrentTiers` |
| TC-CMC-339 | validTiersRoundTrip | P0 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::validTiersRoundTrip` |
| TC-CMC-340 | nonOrderedTiersReturnValidationError | P0 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::nonOrderedTiersReturnValidationError` |
| TC-CMC-341 | missingFieldReturnsValidationError | P0 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::missingFieldReturnsValidationError` |

## 用例明细（初稿模板）

### TC-CMC-084 createsDraftContract

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::createsDraftContract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-085 invalidRevenueShareRatio_throws

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::invalidRevenueShareRatio_throws`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-086 draftContract_signsSuccessfully

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::draftContract_signsSuccessfully`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-087 contractNotFound_throws

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::contractNotFound_throws`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-088 activeContract_suspends

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::activeContract_suspends`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-089 suspendedContract_reactivates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::suspendedContract_reactivates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-090 activeContract_terminates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::activeContract_terminates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-091 contractNotFound_doesNotPublish

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/ContractApplicationServiceTest.java::contractNotFound_doesNotPublish`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-092 missing settings row falls back to SHOW_LOCKED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::missingRow_fallsBackToShowLocked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-093 repository failure falls back to SHOW_LOCKED

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::repositoryFailure_fallsBackToShowLocked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-094 persisted HIDE policy is returned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::persistedHide_isReturned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-095 cache hit within TTL does not re-read the repository

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsProviderTest.java::cacheHit_skipsRepository`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-096 getLockedTilePolicy delegates to the provider (fallback included)

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::get_delegatesToProvider`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-CMC-097 update persists the policy, records an audit entry and invalidates the cache

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::update_persistsAuditsAndInvalidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-CMC-098 update with a null policy is rejected with VALIDATION_ERROR

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::update_nullPolicy_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-CMC-099 parsePolicy accepts case-insensitive values from the domain

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::parsePolicy_acceptsKnownValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-CMC-100 parsePolicy rejects anything outside the value domain

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/PlatformDisplaySettingsServiceTest.java::parsePolicy_rejectsUnknownValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-CMC-101 subscriptionNotFound_throwsDomainException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::subscriptionNotFound_throwsDomainException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-102 suspendedSubscription_deniedRegardlessOfGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::suspendedSubscription_deniedRegardlessOfGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-103 cancelledSubscription_denied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::cancelledSubscription_denied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-104 expiredSubscription_denied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::expiredSubscription_denied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-105 renewalFailedSubscription_denied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::renewalFailedSubscription_denied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-106 allowsAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::allowsAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-107 missingGate_treatedAsNone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::missingGate_treatedAsNone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-108 enabledLock_allowsAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::enabledLock_allowsAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-109 disabledLock_deniesAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::disabledLock_deniesAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-110 underLimit_allowsAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::underLimit_allowsAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-111 atLimit_deniesAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::atLimit_deniesAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-112 overLimit_deniesAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::overLimit_deniesAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-113 allowedWithRetentionDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::allowedWithRetentionDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-114 trialUsesEffectiveTierPremium

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::trialUsesEffectiveTierPremium`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-115 licenseQuotaPresent_overridesFeatureGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaPresent_overridesFeatureGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-116 licenseQuotaBoundaryUsageInclusive_allowed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaBoundaryUsageInclusive_allowed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-117 licenseQuotaExceeded_deniesWithLocalizedMessage

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaExceeded_deniesWithLocalizedMessage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-118 licenseQuotaEmpty_fallsBackToFeatureGateLimit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java::licenseQuotaEmpty_fallsBackToFeatureGateLimit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-119 calculatesPeriodForActiveContract

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::calculatesPeriodForActiveContract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-120 inactiveContract_throws

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::inactiveContract_throws`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-121 pendingPeriod_confirmedByPlatform

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::pendingPeriod_confirmedByPlatform`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-122 platformConfirmedPeriod_confirmedByPartner

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::platformConfirmedPeriod_confirmedByPartner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-123 partnerConfirmedPeriod_settles

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::partnerConfirmedPeriod_settles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-124 updatesExistingPeriod_inPlace

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::updatesExistingPeriod_inPlace`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-125 settledPeriod_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/RevenueApplicationServiceTest.java::settledPeriod_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-126 existingSubscription_returnsExisting

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::existingSubscription_returnsExisting`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-127 noExistingSubscription_createsTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noExistingSubscription_createsTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-128 noExistingSubscription_fixedDeadlineConfigured_createsTrialAtDeadline

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noExistingSubscription_fixedDeadlineConfigured_createsTrialAtDeadline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-129 fromTrialToActive_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::fromTrialToActive_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-130 fromActiveTierChange_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::fromActiveTierChange_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-131 nullBillingCycle_reusesCurrentCycle

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::nullBillingCycle_reusesCurrentCycle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-132 nullBillingCycle_andNoCurrentCycle_defaultsToMonthly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::nullBillingCycle_andNoCurrentCycle_defaultsToMonthly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-133 subscriptionNotFound_throws

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::subscriptionNotFound_throws`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-134 trialSubscription_expiresToFree

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::trialSubscription_expiresToFree`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-135 activeSubscription_succeeds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::activeSubscription_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-136 suspendedSubscription_reactivates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::suspendedSubscription_reactivates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-137 activeSubscription_cancels

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::activeSubscription_cancels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-138 trialSubscription_cancels

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::trialSubscription_cancels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-139 publishesAndClearsDomainEvents

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::publishesAndClearsDomainEvents`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-140 noSubscriptionFound_doesNotPublish

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::noSubscriptionFound_doesNotPublish`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-141 regrantAfterPremiumDropsTierToBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::regrantAfterPremiumDropsTierToBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-142 lapsedRegrantedTrialResolvesToBasicNotStalePremium

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::lapsedRegrantedTrialResolvesToBasicNotStalePremium`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-143 lapsedPeriod_restartsOneCycleFromNow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::lapsedPeriod_restartsOneCycleFromNow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-144 periodStillRunning_extendsFromPreviousExpiry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::periodStillRunning_extendsFromPreviousExpiry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-145 yearlyCycle_extendsOneYear

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::yearlyCycle_extendsOneYear`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-146 notRenewalFailed_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java::notRenewalFailed_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-147 everySampleLandsOnItsMatrixState

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::everySampleLandsOnItsMatrixState`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-148 trialLapsedDoesNotShowAsTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::trialLapsedDoesNotShowAsTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-149 expiringSoonLevels

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::expiringSoonLevels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-150 defaultTiersKeepSnoozeGateOn14And7Only

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::defaultTiersKeepSnoozeGateOn14And7Only`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-151 defaultTiersMapSeverity14Info7Warn3Danger

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::defaultTiersMapSeverity14Info7Warn3Danger`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-152 trialBannerEscalatesSeverityByLevelWithoutSnooze

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::trialBannerEscalatesSeverityByLevelWithoutSnooze`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-153 severityNonNullWhereverLevelPresentSnoozeOnlyInExpiringSoon

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::severityNonNullWhereverLevelPresentSnoozeOnlyInExpiringSoon`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-154 customTiersDriveWindowLevelAndSnoozeGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::customTiersDriveWindowLevelAndSnoozeGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-155 degradedAndExportEligibilityAgreeOnEverySample

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionSemanticsCrossCheckTest.java::degradedAndExportEligibilityAgreeOnEverySample`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-156 setsDraftStatusAndFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::setsDraftStatusAndFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-157 registersContractCreatedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::registersContractCreatedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-158 revenueShareModel_requiresRatio

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::revenueShareModel_requiresRatio`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-159 nonRevenueShareModel_allowsNullRatio

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::nonRevenueShareModel_allowsNullRatio`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-160 ratioMustBeGreaterThanZero

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::ratioMustBeGreaterThanZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-161 ratioMustBeLessThanOne

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::ratioMustBeLessThanOne`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-162 transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-163 registersContractSignedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::registersContractSignedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-164 suspend_transitionsToSuspended

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::suspend_transitionsToSuspended`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-165 reactivate_transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::reactivate_transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-166 transitionsToTerminated

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToTerminated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-167 transitionsToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::transitionsToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-168 calculatesSharesFromRatio

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::calculatesSharesFromRatio`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-169 differentRatio

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::differentRatio`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-170 zeroGrossAmount

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::zeroGrossAmount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-171 rejectsNegativeGrossAmount

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::rejectsNegativeGrossAmount`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-172 signFromActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::signFromActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-173 suspendFromDraft_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::suspendFromDraft_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-174 reactivateFromActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::reactivateFromActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-175 terminateFromSuspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::terminateFromSuspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-176 markExpiredFromSuspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::markExpiredFromSuspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-177 terminateFromDraft_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::terminateFromDraft_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-178 markExpiredFromDraft_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java::markExpiredFromDraft_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-179 unrestricted_allowsAccess

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::unrestricted_allowsAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-180 isLockedWhenEnabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLockedWhenEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-181 isLockedWhenDisabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLockedWhenDisabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-182 isLimitedWithLimitValue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLimitedWithLimitValue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-183 isLimitedWithNullRetentionDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isLimitedWithNullRetentionDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-184 isFilteredWithRetentionDays

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::isFilteredWithRetentionDays`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-185 createsNoneGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/FeatureGateTest.java::createsNoneGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-186 setsPendingStatusAndFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::setsPendingStatusAndFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-187 registersRevenuePeriodCreatedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::registersRevenuePeriodCreatedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-188 allowsRatioEqualToZero_forDirectModel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::allowsRatioEqualToZero_forDirectModel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-189 rejectsRatioEqualToOne

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsRatioEqualToOne`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-190 rejectsSharesNotSummingToGross

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsSharesNotSummingToGross`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-191 rejectsPeriodEndBeforeStart

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsPeriodEndBeforeStart`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-192 transitionsToPlatformConfirmed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToPlatformConfirmed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-193 rejectsFromNonPending

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromNonPending`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-194 rejectsFromSettled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromSettled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-195 transitionsToPartnerConfirmed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToPartnerConfirmed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-196 rejectsFromPending

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPending`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-197 rejectsFromPartnerConfirmed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPartnerConfirmed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-198 transitionsToSettled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::transitionsToSettled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-199 rejectsFromPending

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPending`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-200 rejectsFromPlatformConfirmed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromPlatformConfirmed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-201 rejectsFromSettled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java::rejectsFromSettled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-202 setsProvisionedStatusAndFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::setsProvisionedStatusAndFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-203 hashesServiceKeyAndExtractsPrefix

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::hashesServiceKeyAndExtractsPrefix`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-204 registersServiceProvisionedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::registersServiceProvisionedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-205 transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-206 registersServiceActivatedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::registersServiceActivatedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-207 rejectsFromNonProvisioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromNonProvisioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-208 updatesLastHeartbeatAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::updatesLastHeartbeatAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-209 fromGracePeriod_transitionsBackToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::fromGracePeriod_transitionsBackToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-210 rejectsFromProvisioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-211 rejectsFromExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-212 whenHeartbeatOverdue_transitionsToGracePeriod

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::whenHeartbeatOverdue_transitionsToGracePeriod`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-213 whenHeartbeatRecent_staysActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::whenHeartbeatRecent_staysActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-214 rejectsFromProvisioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-215 rejectsFromExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-216 transitionsFromGracePeriodToDegraded

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromGracePeriodToDegraded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-217 rejectsFromActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-218 transitionsFromActiveToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromActiveToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-219 transitionsFromProvisionedToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromProvisionedToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-220 transitionsFromGracePeriodToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromGracePeriodToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-221 rejectsFromExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-222 transitionsFromActiveToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::transitionsFromActiveToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-223 rejectsFromProvisioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-224 rejectsFromExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-225 updatesQuotaAndRegistersEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::updatesQuotaAndRegistersEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-226 rejectsFromProvisioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromProvisioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-227 rejectsFromExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsFromExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-228 acceptsCorrectKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::acceptsCorrectKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-229 rejectsWrongKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsWrongKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-230 rejectsNullKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsNullKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-231 rejectsEmptyKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java::rejectsEmptyKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-232 setsTrialStatusAndFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::setsTrialStatusAndFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-233 registersSubscriptionCreatedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersSubscriptionCreatedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-234 activatesFromTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activatesFromTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-235 registersSubscriptionCreatedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersSubscriptionCreatedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-236 transitionsToFreeWithBasicTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::transitionsToFreeWithBasicTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-237 registersTierChangedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-238 rejectsFromNonTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsFromNonTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-239 extendsTrialEndFromTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::extendsTrialEndFromTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-240 rejectsFromNonTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsFromNonTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-241 rejectsShorteningCurrentTrialEnd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::rejectsShorteningCurrentTrialEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-242 sameTimestampAllowed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::sameTimestampAllowed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-243 setsTrialEndWhenCurrentIsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::setsTrialEndWhenCurrentIsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-244 trialActive_returnsPremium

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::trialActive_returnsPremium`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-245 trialExpired_returnsActualTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::trialExpired_returnsActualTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-246 activeSubscription_returnsActualTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activeSubscription_returnsActualTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-247 isActiveOrTrial_active

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-248 isActiveOrTrial_trial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_trial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-249 isActiveOrTrial_free

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_free`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-250 isActiveOrTrial_suspended_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_suspended_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-251 isActiveOrTrial_cancelled_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_cancelled_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-252 isActiveOrTrial_renewalFailed_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_renewalFailed_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-253 isActiveOrTrial_expired_false

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isActiveOrTrial_expired_false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-254 isTrialActive_nullTrialEndsAt_returnsFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::isTrialActive_nullTrialEndsAt_returnsFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-255 fromFreeToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromFreeToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-256 registersTierChangedEvent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-257 fromTrial_transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromTrial_transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-258 fromRenewalFailed_repaysToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_repaysToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-259 fromRenewalFailed_sameTier_renewsInPlace

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_sameTier_renewsInPlace`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-260 suspend_transitionsToSuspended

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspend_transitionsToSuspended`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-261 reactivate_transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::reactivate_transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-262 suspendRequiresActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspendRequiresActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-263 markRenewalFailed_transitionsToRenewalFailed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markRenewalFailed_transitionsToRenewalFailed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-264 recoverFromRenewalFailure_transitionsToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailure_transitionsToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-265 recoverFromRenewalFailureWithNewExpiry_restartsPeriod

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailureWithNewExpiry_restartsPeriod`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-266 downgradeAfterRenewalFailure_transitionsToFree

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::downgradeAfterRenewalFailure_transitionsToFree`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-267 cancelFromActive_setsCancelledAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromActive_setsCancelledAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-268 cancelFromTrial

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromTrial`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-269 transitionsToExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::transitionsToExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-270 activateFromActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::activateFromActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-271 reactivateFromActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::reactivateFromActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-272 cancelFromCancelled_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::cancelFromCancelled_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-273 suspendFromSuspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::suspendFromSuspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-274 markRenewalFailedFromTrial_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markRenewalFailedFromTrial_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-275 recoverFromRenewalFailureWhenActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::recoverFromRenewalFailureWhenActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-276 downgradeFromActive_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::downgradeFromActive_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-277 markExpiredFromCancelled_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::markExpiredFromCancelled_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-278 fromActive_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromActive_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-279 fromTrial_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromTrial_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-280 fromRenewalFailed_downgradesToFreeBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromRenewalFailed_downgradesToFreeBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-281 fromFree_isIdempotentNoOp

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromFree_isIdempotentNoOp`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-282 registersTierChangedEventFromActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::registersTierChangedEventFromActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-283 fromSuspended_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromSuspended_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-284 fromCancelled_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromCancelled_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-285 fromExpired_throwsStateConflict

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java::fromExpired_throwsStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-286 basicIsFreeWithCap

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::basicIsFreeWithCap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-287 standardBands

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::standardBands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-288 premiumBands

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::premiumBands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-289 enterpriseHasNoBands

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::enterpriseHasNoBands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-290 bandBoundariesAreInclusive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::bandBoundariesAreInclusive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-291 headCountBelowLowestBandFallsBackToFirstBand

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::headCountBelowLowestBandFallsBackToFirstBand`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-292 zeroHeadsCostsNothing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::zeroHeadsCostsNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-293 smallHerd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::smallHerd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-294 danishMainstreamHerd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::danishMainstreamHerd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-295 largeHerd

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::largeHerd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-296 basicIsAlwaysFree

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::basicIsAlwaysFree`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-297 enterpriseThrowsDomainException

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java::enterpriseThrowsDomainException`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-298 returnsEmptyRegardlessOfLicense

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::returnsEmptyRegardlessOfLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-299 validLicenseWithKey_returnsQuota

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::validLicenseWithKey_returnsQuota`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-300 validLicenseWithoutKey_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::validLicenseWithoutKey_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-301 expiredRuntime_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::expiredRuntime_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-302 suspendedRuntime_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::suspendedRuntime_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-303 noCurrentLicense_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::noCurrentLicense_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-304 modeMatchIsCaseInsensitive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/CommerceQuotaLicenseAdapterTest.java::modeMatchIsCaseInsensitive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-RCH-001

### TC-CMC-305 resolvesLimitFromFeatureGateLimitRow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::resolvesLimitFromFeatureGateLimitRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-306 licenseQuotaWinsOverFeatureGate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::licenseQuotaWinsOverFeatureGate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-307 enterpriseNoneGateResolvesToNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::enterpriseNoneGateResolvesToNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-308 missingGateRowResolvesToNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::missingGateRowResolvesToNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-309 inactiveSubscriptionResolvesToNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::inactiveSubscriptionResolvesToNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-310 noTenantContextResolvesToNullWithoutTouchingStores

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/acl/FenceQuotaPortImplTest.java::noTenantContextResolvesToNullWithoutTouchingStores`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-001

### TC-CMC-311 seedRowMatchesPreChangeHardcodedTiers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::seedRowMatchesPreChangeHardcodedTiers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-312 unorderedTiersViolateTheCheckConstraint

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::unorderedTiersViolateTheCheckConstraint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-313 providerInvalidationReloadsPersistedTiers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/SubscriptionHealthSettingsRepositoryIntegrationTest.java::providerInvalidationReloadsPersistedTiers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-314 allFieldsPreservedViaToJpaEntityAndBack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-315 activeSubscriptionWithAllFieldsFilledRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::activeSubscriptionWithAllFieldsFilledRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-CMC-316 updateEntityPreservesMutableFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::updateEntityPreservesMutableFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-317 allFieldsPreservedViaToJpaEntityAndBack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-318 draftContractRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::draftContractRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-CMC-319 allFieldsPreservedViaToJpaEntityAndBack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-320 settledPeriodRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::settledPeriodRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-321 allFieldsPreservedViaToJpaEntityAndBack

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::allFieldsPreservedViaToJpaEntityAndBack`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-322 activatedServiceRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::activatedServiceRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-323 nullHeartbeatDefaultsPreserved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::nullHeartbeatDefaultsPreserved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-324 limitGateRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::limitGateRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-325 filterGateRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::filterGateRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-326 disabledGateRoundTrips

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::disabledGateRoundTrips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-327 nullIsEnabledDefaultsToTrue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/infrastructure/persistence/mapper/MapperRoundTripTest.java::nullIsEnabledDefaultsToTrue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-CMC-328 onPremCheckoutIsRejectedWithLicenseRequired

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremCheckoutIsRejectedWithLicenseRequired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004

### TC-CMC-329 onPremTierChangeIsRejectedWithLicenseRequired

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremTierChangeIsRejectedWithLicenseRequired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004

### TC-CMC-330 onPremCancelIsRejectedWithLicenseRequired

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremCancelIsRejectedWithLicenseRequired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004

### TC-CMC-331 hostedCheckoutKeepsWorking

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::hostedCheckoutKeepsWorking`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001

### TC-CMC-332 onPremManualStatusChangeIsRejectedWithLicenseRequired

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremManualStatusChangeIsRejectedWithLicenseRequired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004

### TC-CMC-333 hostedManualStatusChangeReachesBusinessLogic

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::hostedManualStatusChangeReachesBusinessLogic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001

### TC-CMC-334 onPremReadEndpointsStayUsable

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/SubscriptionSelfServiceGuardTest.java::onPremReadEndpointsStayUsable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-008、REQ-IDT-004

### TC-CMC-335 classLevel_requiresPlatformAdminOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/AdminSubscriptionOverviewControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001

### TC-CMC-336 endpoints_haveNoPerMethodOverride

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/AdminSubscriptionOverviewControllerSecurityTest.java::endpoints_haveNoPerMethodOverride`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-004、REQ-RCH-001

### TC-CMC-337 nonPlatformAdminIsRejectedOnEveryEndpoint

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::nonPlatformAdminIsRejectedOnEveryEndpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-338 platformAdminGetsCurrentTiers

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::platformAdminGetsCurrentTiers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-339 validTiersRoundTrip

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::validTiersRoundTrip`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-340 nonOrderedTiersReturnValidationError

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::nonOrderedTiersReturnValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

### TC-CMC-341 missingFieldReturnsValidationError

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/commerce/interfaces/admin/SubscriptionHealthSettingsAdminControllerTest.java::missingFieldReturnsValidationError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-001、REQ-CMC-002

