# 测试用例规格：后端·身份认证与多租户

> 用例域：IDT ｜ 用例数：87
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IDT-042 | createApiKey_returnsSkLivePrefix | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::createApiKey_returnsSkLivePrefix` |
| TC-IDT-043 | validateApiKey_succeedsWithCorrectKey | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::validateApiKey_succeedsWithCorrectKey` |
| TC-IDT-044 | revokeApiKey_setsRevoked | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::revokeApiKey_setsRevoked` |
| TC-IDT-045 | deleteApiKey_rejectsActiveKey | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::deleteApiKey_rejectsActiveKey` |
| TC-IDT-046 | switch_nonSuperAdminCaller_forbidden | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_nonSuperAdminCaller_forbidden` |
| TC-IDT-047 | switch_passwordChangeLock_cannotBeBypassed | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_passwordChangeLock_cannotBeBypassed` |
| TC-IDT-048 | switch_nonSelectableRoles_rejected | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_nonSelectableRoles_rejected` |
| TC-IDT-049 | switch_tenantScopedRoleWithoutTenant_rejected | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_tenantScopedRoleWithoutTenant_rejected` |
| TC-IDT-050 | switch_missingOrDeletedTenant_notFound | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_missingOrDeletedTenant_notFound` |
| TC-IDT-051 | switch_trialExpiredTenant_rejected | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_trialExpiredTenant_rejected` |
| TC-IDT-052 | switch_disabledTenant_isEnterable_withAudit | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_disabledTenant_isEnterable_withAudit` |
| TC-IDT-053 | switch_platformAdmin_tenantlessToken | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_platformAdmin_tenantlessToken` |
| TC-IDT-054 | refresh_contextToken_returnsEffectiveIdentity | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::refresh_contextToken_returnsEffectiveIdentity` |
| TC-IDT-055 | refresh_plainToken_returnsStoredIdentity | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::refresh_plainToken_returnsStoredIdentity` |
| TC-IDT-056 | createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/FarmCreationTileTest.java::createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles` |
| TC-IDT-057 | createFarm_withoutBoundaryVertices_skipsTileDetection | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/FarmCreationTileTest.java::createFarm_withoutBoundaryVertices_skipsTileDetection` |
| TC-IDT-058 | classify_routesByShape | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::classify_routesByShape` |
| TC-IDT-059 | normalizePhone_addsPlusAndStripsSeparators | P1 | REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::normalizePhone_addsPlusAndStripsSeparators` |
| TC-IDT-060 | normalizeEmail_lowercases | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::normalizeEmail_lowercases` |
| TC-IDT-061 | phoneCandidates_coverLegacyAndE164Forms | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::phoneCandidates_coverLegacyAndE164Forms` |
| TC-IDT-062 | validators_rejectBadShapes | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::validators_rejectBadShapes` |
| TC-IDT-063 | activeWithPastExpiresAtIsEligibleAnchoredAtExpiry | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::activeWithPastExpiresAtIsEligibleAnchoredAtExpiry` |
| TC-IDT-064 | expiredStatusIsEligibleAnchoredAtExpiresAt | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::expiredStatusIsEligibleAnchoredAtExpiresAt` |
| TC-IDT-065 | lastDayOfWindowIsStillOpen | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::lastDayOfWindowIsStillOpen` |
| TC-IDT-066 | activeWithoutPastExpiryIsNotTerminated | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::activeWithoutPastExpiryIsNotTerminated` |
| TC-IDT-067 | closedWindowIsDenied | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::closedWindowIsDenied` |
| TC-IDT-068 | missingSubscriptionIsDenied | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::missingSubscriptionIsDenied` |
| TC-IDT-069 | suspendedAndRenewalFailedGetNoChannel | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::suspendedAndRenewalFailedGetNoChannel` |
| TC-IDT-070 | freeIsALabelForLapsedTrialAndKeepsTheChannel | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::freeIsALabelForLapsedTrialAndKeepsTheChannel` |
| TC-IDT-071 | activeSubscriptionKeepsItsTier | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::activeSubscriptionKeepsItsTier` |
| TC-IDT-072 | activeTrialResolvesToPremium | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::activeTrialResolvesToPremium` |
| TC-IDT-073 | expiredSubscriptionDegradesToBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::expiredSubscriptionDegradesToBasic` |
| TC-IDT-074 | freeSubscriptionDegradesToBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::freeSubscriptionDegradesToBasic` |
| TC-IDT-075 | missingSubscriptionIsNoneAndBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::missingSubscriptionIsNoneAndBasic` |
| TC-IDT-076 | nullTenantIsNoneAndBasic | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::nullTenantIsNoneAndBasic` |
| TC-IDT-077 | secondResolveWithinTtlHitsCache | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::secondResolveWithinTtlHitsCache` |
| TC-IDT-078 | evictForcesFreshLookup | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::evictForcesFreshLookup` |
| TC-IDT-079 | 正常登录成功，返回 JWT token 和用户信息 | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldLoginSuccessfully` |
| TC-IDT-080 | 密码错误时，拒绝登录 | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectWrongPassword` |
| TC-IDT-081 | 已停用的用户，拒绝登录 | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectInactiveUser` |
| TC-IDT-082 | 手机号不存在时，拒绝登录 | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectNonExistentPhone` |
| TC-IDT-083 | shouldCreateFarmAndAutoAssignOwner | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldCreateFarmAndAutoAssignOwner` |
| TC-IDT-084 | shouldRejectCreateForNonexistentTenant | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldRejectCreateForNonexistentTenant` |
| TC-IDT-085 | shouldNotAutoAssignWorker | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldNotAutoAssignWorker` |
| TC-IDT-086 | shouldNotAutoAssignOwnerFromDifferentTenant | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldNotAutoAssignOwnerFromDifferentTenant` |
| TC-IDT-087 | shouldCreateUserWithRequiredFields | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldCreateUserWithRequiredFields` |
| TC-IDT-088 | shouldNotActivateInactiveUser | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldNotActivateInactiveUser` |
| TC-IDT-089 | shouldDeactivateActiveUser | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldDeactivateActiveUser` |
| TC-IDT-090 | shouldNotDeactivateInactiveUser | P1 | REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldNotDeactivateInactiveUser` |
| TC-IDT-091 | shouldRecordLastLogin | P1 | REQ-IDT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldRecordLastLogin` |
| TC-IDT-092 | shouldCheckRole | P1 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldCheckRole` |
| TC-IDT-093 | shouldHavePlatformAdminWithNullTenant | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldHavePlatformAdminWithNullTenant` |
| TC-IDT-094 | ownerContextToken_passesWithoutUserRowLoad | P0 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::ownerContextToken_passesWithoutUserRowLoad` |
| TC-IDT-095 | workerContextToken_refused | P0 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::workerContextToken_refused` |
| TC-IDT-096 | rootSuperAdminToken_refused_outsideAnyContext | P0 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::rootSuperAdminToken_refused_outsideAnyContext` |
| TC-IDT-097 | classLevel_requiresPlatformAdminOnly | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/admin/DataExportAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly` |
| TC-IDT-098 | endpoints_haveNoPerMethodOverride | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/admin/DataExportAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride` |
| TC-IDT-099 | strongPassword_passes | P1 | REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/PasswordPolicyTest.java::strongPassword_passes` |
| TC-IDT-100 | sevenCharsWithAllClasses_stillViolates | P1 | REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/PasswordPolicyTest.java::sevenCharsWithAllClasses_stillViolates` |
| TC-IDT-101 | shouldResolveWriteScopeFromPath | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveWriteScopeFromPath` |
| TC-IDT-102 | shouldRejectWriteScopeWithOnlyHeader | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectWriteScopeWithOnlyHeader` |
| TC-IDT-103 | shouldRejectWriteScopeWithBothSources | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectWriteScopeWithBothSources` |
| TC-IDT-104 | shouldResolveReadScopeFromPath | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveReadScopeFromPath` |
| TC-IDT-105 | shouldResolveReadScopeFromHeaderOnly | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveReadScopeFromHeaderOnly` |
| TC-IDT-106 | shouldRejectReadScopeWithBothSources | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectReadScopeWithBothSources` |
| TC-IDT-107 | shouldReturnNullForNoScope | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldReturnNullForNoScope` |
| TC-IDT-108 | everyAdminController_hasDeclarativeGuard | P0 | REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/AdminControllerPreAuthorizeCoverageTest.java::everyAdminController_hasDeclarativeGuard` |
| TC-IDT-109 | contextToken_carriesActClaim | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::contextToken_carriesActClaim` |
| TC-IDT-110 | refresh_preservesActClaim | P1 | REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::refresh_preservesActClaim` |
| TC-IDT-111 | plainToken_hasNoActClaim_beforeAndAfterRefresh | P1 | REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::plainToken_hasNoActClaim_beforeAndAfterRefresh` |
| TC-IDT-112 | hostedModePassesEvenWhenRuntimeStateWouldBlock | P0 | REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::hostedModePassesEvenWhenRuntimeStateWouldBlock` |
| TC-IDT-113 | missingTenantContextPassesThrough | P0 | REQ-CMC-008、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::missingTenantContextPassesThrough` |
| TC-IDT-114 | pendingActivationBlocksBusinessApiWithLicenseRequiredJson | P0 | REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::pendingActivationBlocksBusinessApiWithLicenseRequiredJson` |
| TC-IDT-115 | suspendedBlocksBusinessApiIncludingOpenPaths | P0 | REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::suspendedBlocksBusinessApiIncludingOpenPaths` |
| TC-IDT-116 | validRuntimePasses | P0 | REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::validRuntimePasses` |
| TC-IDT-117 | expiredRuntimePasses | P0 | REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::expiredRuntimePasses` |
| TC-IDT-118 | missingStateRowBlocksAsPendingActivation | P0 | REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::missingStateRowBlocksAsPendingActivation` |
| TC-IDT-119 | nullRuntimeStatusBlocksAsPendingActivation | P0 | REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::nullRuntimeStatusBlocksAsPendingActivation` |
| TC-IDT-120 | licenseGateIsRegisteredFirstWithDesignMatrixPaths | P0 | REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::licenseGateIsRegisteredFirstWithDesignMatrixPaths` |
| TC-IDT-121 | apiKeyRequest_passesEvenWhenPrincipalCollidesWithLockedUser | P0 | REQ-IDT-002、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/PasswordChangeRequiredInterceptorTest.java::apiKeyRequest_passesEvenWhenPrincipalCollidesWithLockedUser` |
| TC-IDT-122 | jwtUserWithMustChangePassword_stillLocked | P0 | REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/PasswordChangeRequiredInterceptorTest.java::jwtUserWithMustChangePassword_stillLocked` |
| TC-IDT-123 | standardFarmPath | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::standardFarmPath` |
| TC-IDT-124 | openApiFarmPath | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::openApiFarmPath` |
| TC-IDT-125 | adminNestedFarmPath | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::adminNestedFarmPath` |
| TC-IDT-126 | noFarmSegment_returnsNull | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::noFarmSegment_returnsNull` |
| TC-IDT-127 | farmSegmentNotNumber_returnsNull | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::farmSegmentNotNumber_returnsNull` |
| TC-IDT-128 | farmAtEndOfPath_returnsNull | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::farmAtEndOfPath_returnsNull` |

## 用例明细（初稿模板）

### TC-IDT-042 createApiKey_returnsSkLivePrefix

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::createApiKey_returnsSkLivePrefix`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-043 validateApiKey_succeedsWithCorrectKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::validateApiKey_succeedsWithCorrectKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-044 revokeApiKey_setsRevoked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::revokeApiKey_setsRevoked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-045 deleteApiKey_rejectsActiveKey

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/ApiKeyApplicationServiceTest.java::deleteApiKey_rejectsActiveKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-046 switch_nonSuperAdminCaller_forbidden

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_nonSuperAdminCaller_forbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-047 switch_passwordChangeLock_cannotBeBypassed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_passwordChangeLock_cannotBeBypassed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-PLT-001

### TC-IDT-048 switch_nonSelectableRoles_rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_nonSelectableRoles_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004

### TC-IDT-049 switch_tenantScopedRoleWithoutTenant_rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_tenantScopedRoleWithoutTenant_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004

### TC-IDT-050 switch_missingOrDeletedTenant_notFound

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_missingOrDeletedTenant_notFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-051 switch_trialExpiredTenant_rejected

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_trialExpiredTenant_rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-052 switch_disabledTenant_isEnterable_withAudit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_disabledTenant_isEnterable_withAudit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-053 switch_platformAdmin_tenantlessToken

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::switch_platformAdmin_tenantlessToken`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-054 refresh_contextToken_returnsEffectiveIdentity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::refresh_contextToken_returnsEffectiveIdentity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-055 refresh_plainToken_returnsStoredIdentity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/AuthApplicationServiceSwitchContextTest.java::refresh_plainToken_returnsStoredIdentity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-056 createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/FarmCreationTileTest.java::createFarm_withBoundaryVertices_createsBoundaryFenceAndDetectsTiles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-IDT-057 createFarm_withoutBoundaryVertices_skipsTileDetection

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/FarmCreationTileTest.java::createFarm_withoutBoundaryVertices_skipsTileDetection`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-058 classify_routesByShape

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::classify_routesByShape`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-059 normalizePhone_addsPlusAndStripsSeparators

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::normalizePhone_addsPlusAndStripsSeparators`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-IDT-060 normalizeEmail_lowercases

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::normalizeEmail_lowercases`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-061 phoneCandidates_coverLegacyAndE164Forms

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::phoneCandidates_coverLegacyAndE164Forms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-062 validators_rejectBadShapes

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/LoginIdentifiersTest.java::validators_rejectBadShapes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-063 activeWithPastExpiresAtIsEligibleAnchoredAtExpiry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::activeWithPastExpiresAtIsEligibleAnchoredAtExpiry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-064 expiredStatusIsEligibleAnchoredAtExpiresAt

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::expiredStatusIsEligibleAnchoredAtExpiresAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-065 lastDayOfWindowIsStillOpen

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::lastDayOfWindowIsStillOpen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-066 activeWithoutPastExpiryIsNotTerminated

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::activeWithoutPastExpiryIsNotTerminated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-067 closedWindowIsDenied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::closedWindowIsDenied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-068 missingSubscriptionIsDenied

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::missingSubscriptionIsDenied`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-069 suspendedAndRenewalFailedGetNoChannel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::suspendedAndRenewalFailedGetNoChannel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-070 freeIsALabelForLapsedTrialAndKeepsTheChannel

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/SubscriptionExportPolicyTest.java::freeIsALabelForLapsedTrialAndKeepsTheChannel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-071 activeSubscriptionKeepsItsTier

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::activeSubscriptionKeepsItsTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-072 activeTrialResolvesToPremium

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::activeTrialResolvesToPremium`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-073 expiredSubscriptionDegradesToBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::expiredSubscriptionDegradesToBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-074 freeSubscriptionDegradesToBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::freeSubscriptionDegradesToBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-075 missingSubscriptionIsNoneAndBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::missingSubscriptionIsNoneAndBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-076 nullTenantIsNoneAndBasic

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::nullTenantIsNoneAndBasic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-077 secondResolveWithinTtlHitsCache

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::secondResolveWithinTtlHitsCache`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-078 evictForcesFreshLookup

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/TenantSubscriptionResolverTest.java::evictForcesFreshLookup`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

### TC-IDT-079 正常登录成功，返回 JWT token 和用户信息

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldLoginSuccessfully`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-080 密码错误时，拒绝登录

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectWrongPassword`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-081 已停用的用户，拒绝登录

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectInactiveUser`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-082 手机号不存在时，拒绝登录

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/AuthApplicationServiceTest.java::shouldRejectNonExistentPhone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-083 shouldCreateFarmAndAutoAssignOwner

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldCreateFarmAndAutoAssignOwner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-084 shouldRejectCreateForNonexistentTenant

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldRejectCreateForNonexistentTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-085 shouldNotAutoAssignWorker

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldNotAutoAssignWorker`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-086 shouldNotAutoAssignOwnerFromDifferentTenant

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/application/service/FarmApplicationServiceTest.java::shouldNotAutoAssignOwnerFromDifferentTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-087 shouldCreateUserWithRequiredFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldCreateUserWithRequiredFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IDT-088 shouldNotActivateInactiveUser

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldNotActivateInactiveUser`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IDT-089 shouldDeactivateActiveUser

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldDeactivateActiveUser`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IDT-090 shouldNotDeactivateInactiveUser

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldNotDeactivateInactiveUser`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-IDT-091 shouldRecordLastLogin

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldRecordLastLogin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-RCH-001、REQ-RCH-002

### TC-IDT-092 shouldCheckRole

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldCheckRole`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-093 shouldHavePlatformAdminWithNullTenant

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/domain/model/UserTest.java::shouldHavePlatformAdminWithNullTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-094 ownerContextToken_passesWithoutUserRowLoad

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::ownerContextToken_passesWithoutUserRowLoad`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-PLT-001

### TC-IDT-095 workerContextToken_refused

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::workerContextToken_refused`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-096 rootSuperAdminToken_refused_outsideAnyContext

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/FarmControllerCreateFarmTest.java::rootSuperAdminToken_refused_outsideAnyContext`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-RCH-001

### TC-IDT-097 classLevel_requiresPlatformAdminOnly

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/admin/DataExportAdminControllerSecurityTest.java::classLevel_requiresPlatformAdminOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-098 endpoints_haveNoPerMethodOverride

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/identity/interfaces/admin/DataExportAdminControllerSecurityTest.java::endpoints_haveNoPerMethodOverride`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-099 strongPassword_passes

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/PasswordPolicyTest.java::strongPassword_passes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-IDT-100 sevenCharsWithAllClasses_stillViolates

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/common/PasswordPolicyTest.java::sevenCharsWithAllClasses_stillViolates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-IDT-101 shouldResolveWriteScopeFromPath

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveWriteScopeFromPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-102 shouldRejectWriteScopeWithOnlyHeader

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectWriteScopeWithOnlyHeader`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-103 shouldRejectWriteScopeWithBothSources

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectWriteScopeWithBothSources`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-104 shouldResolveReadScopeFromPath

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveReadScopeFromPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-105 shouldResolveReadScopeFromHeaderOnly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldResolveReadScopeFromHeaderOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-106 shouldRejectReadScopeWithBothSources

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldRejectReadScopeWithBothSources`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-107 shouldReturnNullForNoScope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java::shouldReturnNullForNoScope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-108 everyAdminController_hasDeclarativeGuard

- 优先级：P0
- 前置条件：已认证测试用户与目标角色上下文
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/AdminControllerPreAuthorizeCoverageTest.java::everyAdminController_hasDeclarativeGuard`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-109 contextToken_carriesActClaim

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::contextToken_carriesActClaim`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004

### TC-IDT-110 refresh_preservesActClaim

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::refresh_preservesActClaim`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-111 plainToken_hasNoActClaim_beforeAndAfterRefresh

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/JwtTokenProviderTest.java::plainToken_hasNoActClaim_beforeAndAfterRefresh`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-112 hostedModePassesEvenWhenRuntimeStateWouldBlock

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::hostedModePassesEvenWhenRuntimeStateWouldBlock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002

### TC-IDT-113 missingTenantContextPassesThrough

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::missingTenantContextPassesThrough`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-001、REQ-IDT-003、REQ-IDT-004

### TC-IDT-114 pendingActivationBlocksBusinessApiWithLicenseRequiredJson

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::pendingActivationBlocksBusinessApiWithLicenseRequiredJson`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-115 suspendedBlocksBusinessApiIncludingOpenPaths

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::suspendedBlocksBusinessApiIncludingOpenPaths`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-116 validRuntimePasses

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::validRuntimePasses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002

### TC-IDT-117 expiredRuntimePasses

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::expiredRuntimePasses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002

### TC-IDT-118 missingStateRowBlocksAsPendingActivation

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::missingStateRowBlocksAsPendingActivation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-119 nullRuntimeStatusBlocksAsPendingActivation

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::nullRuntimeStatusBlocksAsPendingActivation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-120 licenseGateIsRegisteredFirstWithDesignMatrixPaths

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/LicenseEnforcementInterceptorTest.java::licenseGateIsRegisteredFirstWithDesignMatrixPaths`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-121 apiKeyRequest_passesEvenWhenPrincipalCollidesWithLockedUser

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/PasswordChangeRequiredInterceptorTest.java::apiKeyRequest_passesEvenWhenPrincipalCollidesWithLockedUser`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-004、REQ-PLT-001、REQ-PLT-002

### TC-IDT-122 jwtUserWithMustChangePassword_stillLocked

- 优先级：P0
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/security/PasswordChangeRequiredInterceptorTest.java::jwtUserWithMustChangePassword_stillLocked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-004、REQ-RCH-001、REQ-RCH-002

### TC-IDT-123 standardFarmPath

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::standardFarmPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-124 openApiFarmPath

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::openApiFarmPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-125 adminNestedFarmPath

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::adminNestedFarmPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-126 noFarmSegment_returnsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::noFarmSegment_returnsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-127 farmSegmentNotNumber_returnsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::farmSegmentNotNumber_returnsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IDT-128 farmAtEndOfPath_returnsNull

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/shared/web/FarmIdPathParserTest.java::farmAtEndOfPath_returnsNull`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

