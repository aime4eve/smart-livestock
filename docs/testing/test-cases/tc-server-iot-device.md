# 测试用例规格：后端·设备与安装

> 用例域：IOT ｜ 用例数：142
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IOT-079 | toReadings_capsule_decodesRawRumenTlvFrameAndMergesMetadata | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformReportDataTest.java::toReadings_capsule_decodesRawRumenTlvFrameAndMergesMetadata` |
| TC-IOT-080 | dispatch_shouldSkipTenantBoundDeviceWhenExclusionEnabled | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldSkipTenantBoundDeviceWhenExclusionEnabled` |
| TC-IOT-081 | dispatch_shouldNotQueryBindingsWhenExclusionDisabled | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldNotQueryBindingsWhenExclusionDisabled` |
| TC-IOT-082 | dispatch_shouldFallBackToBladeWhenTbCursorIsStale | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldFallBackToBladeWhenTbCursorIsStale` |
| TC-IOT-083 | healthyCoverage_returnsNone | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::healthyCoverage_returnsNone` |
| TC-IOT-084 | clusteredWeakArea_triggersAddGateway | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::clusteredWeakArea_triggersAddGateway` |
| TC-IOT-085 | dominantWeakDirection_triggersMoveAntenna | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::dominantWeakDirection_triggersMoveAntenna` |
| TC-IOT-086 | edgeBelowTrigger_withNoDirection_isNone | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::edgeBelowTrigger_withNoDirection_isNone` |
| TC-IOT-087 | noGatewaysRegistered_isNone | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::noGatewaysRegistered_isNone` |
| TC-IOT-088 | shouldRegisterDeviceWithDevEui | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRegisterDeviceWithDevEui` |
| TC-IOT-089 | shouldRejectDuplicateDeviceCode | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRejectDuplicateDeviceCode` |
| TC-IOT-090 | shouldUpdateDeviceCodeAndDevEui | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldUpdateDeviceCodeAndDevEui` |
| TC-IOT-091 | shouldLowercaseEuiOnFindOrCreate | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldLowercaseEuiOnFindOrCreate` |
| TC-IOT-092 | shouldRejectUpdateWithDuplicateCode | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRejectUpdateWithDuplicateCode` |
| TC-IOT-093 | resolveActiveTypeMapShouldSkipDisabledAndBlankEntries | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::resolveActiveTypeMapShouldSkipDisabledAndBlankEntries` |
| TC-IOT-094 | createShouldNormalizeNameAndRejectDuplicate | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::createShouldNormalizeNameAndRejectDuplicate` |
| TC-IOT-095 | createShouldSaveTrimmedRuleAndAudit | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::createShouldSaveTrimmedRuleAndAudit` |
| TC-IOT-096 | updateShouldRequireExistingRule | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::updateShouldRequireExistingRule` |
| TC-IOT-097 | updateShouldRejectMissingDeviceType | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::updateShouldRejectMissingDeviceType` |
| TC-IOT-098 | deleteShouldRequireExistingRule | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::deleteShouldRequireExistingRule` |
| TC-IOT-099 | holdout_tierAgreement_and_p90Coverage_onSyntheticField | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::holdout_tierAgreement_and_p90Coverage_onSyntheticField` |
| TC-IOT-100 | quantile_interpolates_likePercentileCont | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::quantile_interpolates_likePercentileCont` |
| TC-IOT-101 | smallBuckets_areDropped | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::smallBuckets_areDropped` |
| TC-IOT-114 | shouldRejectInstallOnNonActiveDevice | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallOnNonActiveDevice` |
| TC-IOT-115 | shouldRejectInstallAlreadyInstalledDevice | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallAlreadyInstalledDevice` |
| TC-IOT-116 | shouldRejectInstallDuplicateDeviceType | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallDuplicateDeviceType` |
| TC-IOT-117 | shouldAllowInstallDifferentDeviceTypes | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldAllowInstallDifferentDeviceTypes` |
| TC-IOT-118 | shouldResolveTrackerForLivestockGpsWhenCapsuleIsAlsoInstalled | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldResolveTrackerForLivestockGpsWhenCapsuleIsAlsoInstalled` |
| TC-IOT-119 | shouldResolveEarTagForLivestockGpsWhenTrackerIsNotInstalled | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldResolveEarTagForLivestockGpsWhenTrackerIsNotInstalled` |
| TC-IOT-120 | compactHerd_withoutStraggler_flagsNothing | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::compactHerd_withoutStraggler_flagsNothing` |
| TC-IOT-121 | straggler_beyondBaselineAndFloor_isFlagged | P1 | REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::straggler_beyondBaselineAndFloor_isFlagged` |
| TC-IOT-122 | farButCompactHerd_isNotFlagged | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::farButCompactHerd_isNotFlagged` |
| TC-IOT-123 | nearButOutsideBaseline_isNotFlagged | P1 | REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::nearButOutsideBaseline_isNotFlagged` |
| TC-IOT-124 | zeroMad_allIdentical_stillFlagsTrueStraggler | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::zeroMad_allIdentical_stillFlagsTrueStraggler` |
| TC-IOT-125 | normalizeEuiShouldLowercaseAndTrim | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::normalizeEuiShouldLowercaseAndTrim` |
| TC-IOT-126 | invalidEuiShouldFailBeforeExternalCalls | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::invalidEuiShouldFailBeforeExternalCalls` |
| TC-IOT-127 | reconcileShouldBeReadOnlyAndReportMissingLocalLayers | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::reconcileShouldBeReadOnlyAndReportMissingLocalLayers` |
| TC-IOT-128 | reconcileShouldRejectCaseTwins | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::reconcileShouldRejectCaseTwins` |
| TC-IOT-129 | repeatedImportShouldReuseLocalDeviceAndBinding | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::repeatedImportShouldReuseLocalDeviceAndBinding` |
| TC-IOT-130 | provisionShouldRejectMovingInstalledDeviceToAnotherLivestock | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::provisionShouldRejectMovingInstalledDeviceToAnotherLivestock` |
| TC-IOT-194 | 注册新设备（无 SN/EUI → 平台注册跳过，保持 INVENTORY） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRegisterNewDevice` |
| TC-IOT-195 | 激活库存设备（平台注册成功 → ACTIVE） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldActivateInventoryDevice` |
| TC-IOT-196 | 已激活设备重复激活（幂等，直接返回） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldActivateActiveDeviceIdempotently` |
| TC-IOT-197 | 拒绝激活 DECOMMISSIONED 状态的设备 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectActivateDecommissionedDevice` |
| TC-IOT-198 | 停用活跃设备 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldDecommissionActiveDevice` |
| TC-IOT-199 | 设备不存在时，抛出 RESOURCE_NOT_FOUND | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldThrowResourceNotFoundForMissingDevice` |
| TC-IOT-200 | 删除有活跃绑定的设备（自动解绑 → 软删除，status 不变） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldSoftDeleteDeviceWithActiveInstallation` |
| TC-IOT-201 | 删除无活跃绑定的设备（直接软删除，不调用解绑） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldSoftDeleteDeviceWithoutInstallation` |
| TC-IOT-202 | 跨租户删除设备（抛 RESOURCE_NOT_FOUND，不暴露存在性） | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectDeleteForOtherTenant` |
| TC-IOT-203 | findOrCreateByEui 命中软删除设备 → 复活（restoreById 先于 save，platformDeviceId 复用） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReviveSoftDeletedDeviceOnFindOrCreateByEui` |
| TC-IOT-204 | findOrCreateByEui 复活时传入空 code → 保留原 deviceCode | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldKeepOriginalDeviceCodeWhenBlankOnRevive` |
| TC-IOT-205 | findOrCreateByEui 复活时 deviceCode 撞活跃设备 → DUPLICATE_RESOURCE | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectReviveWhenDeviceCodeConflicts` |
| TC-IOT-206 | findOrCreateByEui 命中活跃 DECOMMISSIONED 记录（platformDeviceId 非空）→ 不复活不报错 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReuseActiveDecommissionedDeviceAsIs` |
| TC-IOT-207 | findOrCreateByEui 命中 ACTIVE 未绑定设备 → 尝试绑定平台（注册门放宽），status 不变且落库 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldTryBindingForActiveDeviceWithoutPlatformId` |
| TC-IOT-208 | registerDevice 的 EUI 命中软删除设备 → 复活并覆盖表单值 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReviveSoftDeletedDeviceOnRegister` |
| TC-IOT-209 | registerDevice 的 EUI 复活时 serialNo 为空 → 保留原 serialNo（不被 null 覆盖） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldKeepOriginalSerialNoWhenBlankOnRegisterRevive` |
| TC-IOT-210 | registerDevice 的 EUI 命中活跃设备 → DUPLICATE_RESOURCE（error.deviceEuiDuplicate） | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectRegisterWhenEuiHitsActiveDevice` |
| TC-IOT-211 | 移交查询：EUI 在其他租户 → found=true + 当前租户名 + 无活跃安装 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldLookupDeviceForTransfer` |
| TC-IOT-212 | 移交成功：租户 1 → 2，写审计 | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldTransferDeviceToTargetTenant` |
| TC-IOT-213 | 移交拒绝：EUI 不存在 → RESOURCE_NOT_FOUND | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenDeviceMissing` |
| TC-IOT-214 | 移交拒绝：已归属目标租户 → STATE_CONFLICT | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenAlreadyInTargetTenant` |
| TC-IOT-215 | 移交拒绝：原租户有活跃安装 → STATE_CONFLICT 且不落库不审计 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenActiveInstallationExists` |
| TC-IOT-216 | longitudeBeyond180_isFlagged | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::longitudeBeyond180_isFlagged` |
| TC-IOT-217 | validCoordinates_pass | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::validCoordinates_pass` |
| TC-IOT-218 | zeroZero_isNoFix | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::zeroZero_isNoFix` |
| TC-IOT-219 | missingGateway_isFlagged_butDatagenSkipped | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::missingGateway_isFlagged_butDatagenSkipped` |
| TC-IOT-220 | framesWithoutGpsKeys_passQuietly | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::framesWithoutGpsKeys_passQuietly` |
| TC-IOT-221 | shouldCreateActiveLicense | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldCreateActiveLicense` |
| TC-IOT-222 | shouldBeValidWhenNotExpired | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldBeValidWhenNotExpired` |
| TC-IOT-223 | shouldBeExpiredWhenPastExpiry | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldBeExpiredWhenPastExpiry` |
| TC-IOT-224 | shouldRevokeActiveLicense | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldRevokeActiveLicense` |
| TC-IOT-225 | shouldRejectRevokeAlreadyRevoked | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldRejectRevokeAlreadyRevoked` |
| TC-IOT-226 | shouldDetectExpiredStatusOnCheck | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldDetectExpiredStatusOnCheck` |
| TC-IOT-227 | shouldCreateDeviceWithInventoryStatus | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldCreateDeviceWithInventoryStatus` |
| TC-IOT-228 | shouldTransitionInventoryToActive | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldTransitionInventoryToActive` |
| TC-IOT-229 | shouldTransitionActiveToDecommissioned | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldTransitionActiveToDecommissioned` |
| TC-IOT-230 | shouldRejectActivateWhenAlreadyActive | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectActivateWhenAlreadyActive` |
| TC-IOT-231 | shouldRejectActivateFromDecommissioned | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectActivateFromDecommissioned` |
| TC-IOT-232 | shouldRejectDecommissionFromInventory | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectDecommissionFromInventory` |
| TC-IOT-233 | shouldRejectDecommissionWhenAlreadyDecommissioned | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectDecommissionWhenAlreadyDecommissioned` |
| TC-IOT-234 | shouldUpdateRuntimeStatus | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldUpdateRuntimeStatus` |
| TC-IOT-235 | shouldRestoreSoftDeletedDeviceToInventory | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRestoreSoftDeletedDeviceToInventory` |
| TC-IOT-238 | shouldInstallToDeviceAndLivestock | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldInstallToDeviceAndLivestock` |
| TC-IOT-239 | shouldRemoveInstallation | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldRemoveInstallation` |
| TC-IOT-240 | shouldRejectRemoveAlreadyRemoved | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldRejectRemoveAlreadyRemoved` |
| TC-IOT-241 | healthyWhenCursorFreshAndFailuresBelowThreshold | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::healthyWhenCursorFreshAndFailuresBelowThreshold` |
| TC-IOT-242 | unhealthyWhenCursorFrozenBeyondStaleWindow | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::unhealthyWhenCursorFrozenBeyondStaleWindow` |
| TC-IOT-243 | unhealthyWhenFailuresReachThreshold | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::unhealthyWhenFailuresReachThreshold` |
| TC-IOT-244 | fallsBackToLastPollBaselineWhenNeverPulled | P1 | REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::fallsBackToLastPollBaselineWhenNeverPulled` |
| TC-IOT-245 | benefitOfTheDoubtBeforeFirstPoll | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::benefitOfTheDoubtBeforeFirstPoll` |
| TC-IOT-246 | threePoints_onRoute_fullCoverage_inOrder | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::threePoints_onRoute_fullCoverage_inOrder` |
| TC-IOT-247 | thirdGpsDriftsBeyondThreshold_oneMissed | P1 | REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::thirdGpsDriftsBeyondThreshold_oneMissed` |
| TC-IOT-248 | adjacentRoutePointsShareGpsReport_ambiguous | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::adjacentRoutePointsShareGpsReport_ambiguous` |
| TC-IOT-249 | reversedTimestamps_inOrderFalse | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::reversedTimestamps_inOrderFalse` |
| TC-IOT-250 | equalTimestampsAmbiguity_inOrderTrue | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::equalTimestampsAmbiguity_inOrderTrue` |
| TC-IOT-251 | emptyRoute_coverageZero_allGpsTransit | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::emptyRoute_coverageZero_allGpsTransit` |
| TC-IOT-252 | emptyGps_allRouteMissed | P1 | REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::emptyGps_allRouteMissed` |
| TC-IOT-253 | fiveMatched_meanP50P95 | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::fiveMatched_meanP50P95` |
| TC-IOT-277 | decode_nsUplink_extractsCapsuleReadings | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_nsUplink_extractsCapsuleReadings` |
| TC-IOT-278 | decode_temperatureGroup_convertsPositiveAndNegativeValues | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_temperatureGroup_convertsPositiveAndNegativeValues` |
| TC-IOT-279 | decode_legacyTemperatureGroupType_extractsCapsuleReadings | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_legacyTemperatureGroupType_extractsCapsuleReadings` |
| TC-IOT-280 | decode_legacyGastricMotilityType_extractsCapsuleReadings | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_legacyGastricMotilityType_extractsCapsuleReadings` |
| TC-IOT-281 | decode_timestampTlv_isConsumedForFramingOnly | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_timestampTlv_isConsumedForFramingOnly` |
| TC-IOT-282 | decode_truncatedOrUnknownTlv_returnsEmpty | P1 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_truncatedOrUnknownTlv_returnsEmpty` |
| TC-IOT-334 | Positive raw value converts correctly | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::positiveValue` |
| TC-IOT-335 | Negative raw value (stored as uint16 complement) converts correctly | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::negativeValue` |
| TC-IOT-336 | Zero raw value = 0g | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::zeroValue` |
| TC-IOT-337 | toMs2: 1g = 9.80665 m/s² | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::toMs2Conversion` |
| TC-IOT-338 | Magnitude: stationary device ~1g gravity | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::magnitudeStationary` |
| TC-IOT-339 | Magnitude of flat horizontal device: Z=1g, X=Y=0g | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::magnitudeFlatHorizontal` |
| TC-IOT-340 | Motion intensity: zero when gravity only (flat) | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::motionIntensityZero` |
| TC-IOT-341 | Roll angle: flat device = 0°, tilted 45° on Y-Z plane | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::rollAngle` |
| TC-IOT-342 | Pitch angle: flat device = 0°, nose up 45° | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::pitchAngle` |
| TC-IOT-343 | Activity classification thresholds | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::activityClassification` |
| TC-IOT-344 | Firmware threshold: 512 raw ≈ 32mg | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::firmwareThreshold` |
| TC-IOT-345 | Real blade sample: active device (steps>0) has higher magnitude than rest | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::realBladeComparison` |
| TC-IOT-346 | shouldPageDevicesAndUseXToken | P1 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldPageDevicesAndUseXToken` |
| TC-IOT-347 | shouldQuerySingleDeviceByEui | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldQuerySingleDeviceByEui` |
| TC-IOT-348 | shouldRejectNonSuccessEnvelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldRejectNonSuccessEnvelope` |
| TC-IOT-349 | shouldRequireEnabledFlag | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldRequireEnabledFlag` |
| TC-IOT-350 | enabledClientShouldRequireCredentials | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::enabledClientShouldRequireCredentials` |
| TC-IOT-351 | shouldCacheLoginTokenAcrossCalls | P1 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldCacheLoginTokenAcrossCalls` |
| TC-IOT-352 | shouldReloginAndReplayOn401 | P1 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReloginAndReplayOn401` |
| TC-IOT-353 | shouldResolveByExactNameThroughFuzzySearch | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldResolveByExactNameThroughFuzzySearch` |
| TC-IOT-354 | shouldRejectAmbiguousCaseTwins | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldRejectAmbiguousCaseTwins` |
| TC-IOT-355 | variantsShouldDedupeSameCase | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::variantsShouldDedupeSameCase` |
| TC-IOT-356 | shouldReturnExactDeviceViewsForReconciliation | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReturnExactDeviceViewsForReconciliation` |
| TC-IOT-357 | shouldPageDeviceProfiles | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldPageDeviceProfiles` |
| TC-IOT-358 | shouldReadLatestTelemetryTimestamp | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReadLatestTelemetryTimestamp` |
| TC-IOT-359 | enabledClientShouldRequireCredentials | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::enabledClientShouldRequireCredentials` |
| TC-IOT-360 | shouldMapResultFrameAndIngestWithTransportMetadata | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldMapResultFrameAndIngestWithTransportMetadata` |
| TC-IOT-361 | shouldFallbackToDataHexDecodeForCapsule | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldFallbackToDataHexDecodeForCapsule` |
| TC-IOT-362 | shouldDropUndecodableFrameWithoutBlocking | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropUndecodableFrameWithoutBlocking` |
| TC-IOT-363 | shouldDropUnknownDeviceWithoutBlocking | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropUnknownDeviceWithoutBlocking` |
| TC-IOT-364 | shouldResolveBindingByDevEuiWhenTbDeviceIdUnknown | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldResolveBindingByDevEuiWhenTbDeviceIdUnknown` |
| TC-IOT-365 | shouldSkipFrameAlreadyIngested | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldSkipFrameAlreadyIngested` |
| TC-IOT-366 | shouldSwallowUniqueConflictAsConcurrentIngest | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldSwallowUniqueConflictAsConcurrentIngest` |
| TC-IOT-367 | shouldRethrowUniqueConflictWhenRowAbsent | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldRethrowUniqueConflictWhenRowAbsent` |
| TC-IOT-368 | shouldPropagateTransientIngestFailureForRetry | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldPropagateTransientIngestFailureForRetry` |
| TC-IOT-369 | shouldDropMalformedJson | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropMalformedJson` |
| TC-IOT-370 | shouldDropFrameWithMissingContractFields | P1 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropFrameWithMissingContractFields` |
| TC-IOT-371 | shouldClampOutOfRangeGpsBeforeIngest | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldClampOutOfRangeGpsBeforeIngest` |

## 用例明细（初稿模板）

### TC-IOT-079 toReadings_capsule_decodesRawRumenTlvFrameAndMergesMetadata

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformReportDataTest.java::toReadings_capsule_decodesRawRumenTlvFrameAndMergesMetadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-080 dispatch_shouldSkipTenantBoundDeviceWhenExclusionEnabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldSkipTenantBoundDeviceWhenExclusionEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IOT-081 dispatch_shouldNotQueryBindingsWhenExclusionDisabled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldNotQueryBindingsWhenExclusionDisabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-082 dispatch_shouldFallBackToBladeWhenTbCursorIsStale

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/AgenticPlatformSyncDispatcherTest.java::dispatch_shouldFallBackToBladeWhenTbCursorIsStale`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-083 healthyCoverage_returnsNone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::healthyCoverage_returnsNone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-IOT-084 clusteredWeakArea_triggersAddGateway

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::clusteredWeakArea_triggersAddGateway`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-085 dominantWeakDirection_triggersMoveAntenna

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::dominantWeakDirection_triggersMoveAntenna`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-086 edgeBelowTrigger_withNoDirection_isNone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::edgeBelowTrigger_withNoDirection_isNone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-087 noGatewaysRegistered_isNone

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/CoverageDiagnosticServiceTest.java::noGatewaysRegistered_isNone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-088 shouldRegisterDeviceWithDevEui

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRegisterDeviceWithDevEui`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-089 shouldRejectDuplicateDeviceCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRejectDuplicateDeviceCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-090 shouldUpdateDeviceCodeAndDevEui

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldUpdateDeviceCodeAndDevEui`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-091 shouldLowercaseEuiOnFindOrCreate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldLowercaseEuiOnFindOrCreate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-092 shouldRejectUpdateWithDuplicateCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceApplicationServiceTest.java::shouldRejectUpdateWithDuplicateCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-093 resolveActiveTypeMapShouldSkipDisabledAndBlankEntries

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::resolveActiveTypeMapShouldSkipDisabledAndBlankEntries`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-IOT-094 createShouldNormalizeNameAndRejectDuplicate

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::createShouldNormalizeNameAndRejectDuplicate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-095 createShouldSaveTrimmedRuleAndAudit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::createShouldSaveTrimmedRuleAndAudit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-096 updateShouldRequireExistingRule

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::updateShouldRequireExistingRule`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-097 updateShouldRejectMissingDeviceType

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::updateShouldRejectMissingDeviceType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-098 deleteShouldRequireExistingRule

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceProfileRuleServiceTest.java::deleteShouldRequireExistingRule`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-099 holdout_tierAgreement_and_p90Coverage_onSyntheticField

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::holdout_tierAgreement_and_p90Coverage_onSyntheticField`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-100 quantile_interpolates_likePercentileCont

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::quantile_interpolates_likePercentileCont`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-IOT-101 smallBuckets_areDropped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/GatewayDistanceProfileServiceTest.java::smallBuckets_areDropped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-114 shouldRejectInstallOnNonActiveDevice

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallOnNonActiveDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-115 shouldRejectInstallAlreadyInstalledDevice

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallAlreadyInstalledDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-116 shouldRejectInstallDuplicateDeviceType

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldRejectInstallDuplicateDeviceType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-117 shouldAllowInstallDifferentDeviceTypes

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldAllowInstallDifferentDeviceTypes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-118 shouldResolveTrackerForLivestockGpsWhenCapsuleIsAlsoInstalled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldResolveTrackerForLivestockGpsWhenCapsuleIsAlsoInstalled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-119 shouldResolveEarTagForLivestockGpsWhenTrackerIsNotInstalled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/InstallationApplicationServiceTest.java::shouldResolveEarTagForLivestockGpsWhenTrackerIsNotInstalled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-120 compactHerd_withoutStraggler_flagsNothing

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::compactHerd_withoutStraggler_flagsNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-121 straggler_beyondBaselineAndFloor_isFlagged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::straggler_beyondBaselineAndFloor_isFlagged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-122 farButCompactHerd_isNotFlagged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::farButCompactHerd_isNotFlagged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-123 nearButOutsideBaseline_isNotFlagged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::nearButOutsideBaseline_isNotFlagged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-124 zeroMad_allIdentical_stillFlagsTrueStraggler

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/LivestockPresenceServiceTest.java::zeroMad_allIdentical_stillFlagsTrueStraggler`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-125 normalizeEuiShouldLowercaseAndTrim

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::normalizeEuiShouldLowercaseAndTrim`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-126 invalidEuiShouldFailBeforeExternalCalls

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::invalidEuiShouldFailBeforeExternalCalls`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-127 reconcileShouldBeReadOnlyAndReportMissingLocalLayers

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::reconcileShouldBeReadOnlyAndReportMissingLocalLayers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-128 reconcileShouldRejectCaseTwins

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::reconcileShouldRejectCaseTwins`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-129 repeatedImportShouldReuseLocalDeviceAndBinding

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::repeatedImportShouldReuseLocalDeviceAndBinding`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-130 provisionShouldRejectMovingInstalledDeviceToAnotherLivestock

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/TbDeviceProvisioningServiceTest.java::provisionShouldRejectMovingInstalledDeviceToAnotherLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-194 注册新设备（无 SN/EUI → 平台注册跳过，保持 INVENTORY）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRegisterNewDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-195 激活库存设备（平台注册成功 → ACTIVE）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldActivateInventoryDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-196 已激活设备重复激活（幂等，直接返回）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldActivateActiveDeviceIdempotently`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-197 拒绝激活 DECOMMISSIONED 状态的设备

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectActivateDecommissionedDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-198 停用活跃设备

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldDecommissionActiveDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-199 设备不存在时，抛出 RESOURCE_NOT_FOUND

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldThrowResourceNotFoundForMissingDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-200 删除有活跃绑定的设备（自动解绑 → 软删除，status 不变）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldSoftDeleteDeviceWithActiveInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-201 删除无活跃绑定的设备（直接软删除，不调用解绑）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldSoftDeleteDeviceWithoutInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-202 跨租户删除设备（抛 RESOURCE_NOT_FOUND，不暴露存在性）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectDeleteForOtherTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IOT-203 findOrCreateByEui 命中软删除设备 → 复活（restoreById 先于 save，platformDeviceId 复用）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReviveSoftDeletedDeviceOnFindOrCreateByEui`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-204 findOrCreateByEui 复活时传入空 code → 保留原 deviceCode

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldKeepOriginalDeviceCodeWhenBlankOnRevive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-205 findOrCreateByEui 复活时 deviceCode 撞活跃设备 → DUPLICATE_RESOURCE

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectReviveWhenDeviceCodeConflicts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-206 findOrCreateByEui 命中活跃 DECOMMISSIONED 记录（platformDeviceId 非空）→ 不复活不报错

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReuseActiveDecommissionedDeviceAsIs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-207 findOrCreateByEui 命中 ACTIVE 未绑定设备 → 尝试绑定平台（注册门放宽），status 不变且落库

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldTryBindingForActiveDeviceWithoutPlatformId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-208 registerDevice 的 EUI 命中软删除设备 → 复活并覆盖表单值

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldReviveSoftDeletedDeviceOnRegister`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-209 registerDevice 的 EUI 复活时 serialNo 为空 → 保留原 serialNo（不被 null 覆盖）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldKeepOriginalSerialNoWhenBlankOnRegisterRevive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-210 registerDevice 的 EUI 命中活跃设备 → DUPLICATE_RESOURCE（error.deviceEuiDuplicate）

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectRegisterWhenEuiHitsActiveDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-211 移交查询：EUI 在其他租户 → found=true + 当前租户名 + 无活跃安装

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldLookupDeviceForTransfer`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-212 移交成功：租户 1 → 2，写审计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldTransferDeviceToTargetTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IOT-213 移交拒绝：EUI 不存在 → RESOURCE_NOT_FOUND

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenDeviceMissing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-214 移交拒绝：已归属目标租户 → STATE_CONFLICT

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenAlreadyInTargetTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-IOT-215 移交拒绝：原租户有活跃安装 → STATE_CONFLICT 且不落库不审计

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/service/DeviceApplicationServiceTest.java::shouldRejectTransferWhenActiveInstallationExists`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-216 longitudeBeyond180_isFlagged

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::longitudeBeyond180_isFlagged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-217 validCoordinates_pass

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::validCoordinates_pass`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-IOT-218 zeroZero_isNoFix

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::zeroZero_isNoFix`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-219 missingGateway_isFlagged_butDatagenSkipped

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::missingGateway_isFlagged_butDatagenSkipped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-220 framesWithoutGpsKeys_passQuietly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/governance/GovernanceRulesTest.java::framesWithoutGpsKeys_passQuietly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-221 shouldCreateActiveLicense

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldCreateActiveLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-222 shouldBeValidWhenNotExpired

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldBeValidWhenNotExpired`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-223 shouldBeExpiredWhenPastExpiry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldBeExpiredWhenPastExpiry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-224 shouldRevokeActiveLicense

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldRevokeActiveLicense`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-225 shouldRejectRevokeAlreadyRevoked

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldRejectRevokeAlreadyRevoked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-226 shouldDetectExpiredStatusOnCheck

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java::shouldDetectExpiredStatusOnCheck`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-IOT-227 shouldCreateDeviceWithInventoryStatus

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldCreateDeviceWithInventoryStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-228 shouldTransitionInventoryToActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldTransitionInventoryToActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-229 shouldTransitionActiveToDecommissioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldTransitionActiveToDecommissioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-230 shouldRejectActivateWhenAlreadyActive

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectActivateWhenAlreadyActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-231 shouldRejectActivateFromDecommissioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectActivateFromDecommissioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-232 shouldRejectDecommissionFromInventory

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectDecommissionFromInventory`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-233 shouldRejectDecommissionWhenAlreadyDecommissioned

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRejectDecommissionWhenAlreadyDecommissioned`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-234 shouldUpdateRuntimeStatus

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldUpdateRuntimeStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-235 shouldRestoreSoftDeletedDeviceToInventory

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java::shouldRestoreSoftDeletedDeviceToInventory`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-238 shouldInstallToDeviceAndLivestock

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldInstallToDeviceAndLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-239 shouldRemoveInstallation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldRemoveInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-240 shouldRejectRemoveAlreadyRemoved

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java::shouldRejectRemoveAlreadyRemoved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-241 healthyWhenCursorFreshAndFailuresBelowThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::healthyWhenCursorFreshAndFailuresBelowThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-IOT-242 unhealthyWhenCursorFrozenBeyondStaleWindow

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::unhealthyWhenCursorFrozenBeyondStaleWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-IOT-243 unhealthyWhenFailuresReachThreshold

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::unhealthyWhenFailuresReachThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-IOT-244 fallsBackToLastPollBaselineWhenNeverPulled

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::fallsBackToLastPollBaselineWhenNeverPulled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-245 benefitOfTheDoubtBeforeFirstPoll

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/model/TbDeviceBindingTest.java::benefitOfTheDoubtBeforeFirstPoll`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-246 threePoints_onRoute_fullCoverage_inOrder

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::threePoints_onRoute_fullCoverage_inOrder`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-247 thirdGpsDriftsBeyondThreshold_oneMissed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::thirdGpsDriftsBeyondThreshold_oneMissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002

### TC-IOT-248 adjacentRoutePointsShareGpsReport_ambiguous

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::adjacentRoutePointsShareGpsReport_ambiguous`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-249 reversedTimestamps_inOrderFalse

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::reversedTimestamps_inOrderFalse`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-250 equalTimestampsAmbiguity_inOrderTrue

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::equalTimestampsAmbiguity_inOrderTrue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-251 emptyRoute_coverageZero_allGpsTransit

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::emptyRoute_coverageZero_allGpsTransit`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-252 emptyGps_allRouteMissed

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::emptyGps_allRouteMissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002

### TC-IOT-253 fiveMatched_meanP50P95

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/DynamicQualityCalculatorTest.java::fiveMatched_meanP50P95`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-277 decode_nsUplink_extractsCapsuleReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_nsUplink_extractsCapsuleReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-278 decode_temperatureGroup_convertsPositiveAndNegativeValues

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_temperatureGroup_convertsPositiveAndNegativeValues`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-279 decode_legacyTemperatureGroupType_extractsCapsuleReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_legacyTemperatureGroupType_extractsCapsuleReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-280 decode_legacyGastricMotilityType_extractsCapsuleReadings

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_legacyGastricMotilityType_extractsCapsuleReadings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-281 decode_timestampTlv_isConsumedForFramingOnly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_timestampTlv_isConsumedForFramingOnly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-282 decode_truncatedOrUnknownTlv_returnsEmpty

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/domain/service/RumenPayloadDecoderTest.java::decode_truncatedOrUnknownTlv_returnsEmpty`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-334 Positive raw value converts correctly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::positiveValue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-335 Negative raw value (stored as uint16 complement) converts correctly

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::negativeValue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-336 Zero raw value = 0g

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::zeroValue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-337 toMs2: 1g = 9.80665 m/s²

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::toMs2Conversion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-338 Magnitude: stationary device ~1g gravity

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::magnitudeStationary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-339 Magnitude of flat horizontal device: Z=1g, X=Y=0g

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::magnitudeFlatHorizontal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-340 Motion intensity: zero when gravity only (flat)

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::motionIntensityZero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-341 Roll angle: flat device = 0°, tilted 45° on Y-Z plane

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::rollAngle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-IOT-342 Pitch angle: flat device = 0°, nose up 45°

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::pitchAngle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-343 Activity classification thresholds

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::activityClassification`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-344 Firmware threshold: 512 raw ≈ 32mg

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::firmwareThreshold`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-345 Real blade sample: active device (steps>0) has higher magnitude than rest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java::realBladeComparison`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-346 shouldPageDevicesAndUseXToken

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldPageDevicesAndUseXToken`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-347 shouldQuerySingleDeviceByEui

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldQuerySingleDeviceByEui`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-348 shouldRejectNonSuccessEnvelope

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldRejectNonSuccessEnvelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-IOT-349 shouldRequireEnabledFlag

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::shouldRequireEnabledFlag`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-350 enabledClientShouldRequireCredentials

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/ns/NsClientTest.java::enabledClientShouldRequireCredentials`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-351 shouldCacheLoginTokenAcrossCalls

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldCacheLoginTokenAcrossCalls`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-352 shouldReloginAndReplayOn401

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReloginAndReplayOn401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-IOT-353 shouldResolveByExactNameThroughFuzzySearch

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldResolveByExactNameThroughFuzzySearch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-354 shouldRejectAmbiguousCaseTwins

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldRejectAmbiguousCaseTwins`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-355 variantsShouldDedupeSameCase

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::variantsShouldDedupeSameCase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-IOT-356 shouldReturnExactDeviceViewsForReconciliation

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReturnExactDeviceViewsForReconciliation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-357 shouldPageDeviceProfiles

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldPageDeviceProfiles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-358 shouldReadLatestTelemetryTimestamp

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::shouldReadLatestTelemetryTimestamp`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-IOT-359 enabledClientShouldRequireCredentials

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/thingsboard/TbClientTest.java::enabledClientShouldRequireCredentials`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-360 shouldMapResultFrameAndIngestWithTransportMetadata

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldMapResultFrameAndIngestWithTransportMetadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-IOT-361 shouldFallbackToDataHexDecodeForCapsule

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldFallbackToDataHexDecodeForCapsule`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-362 shouldDropUndecodableFrameWithoutBlocking

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropUndecodableFrameWithoutBlocking`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-363 shouldDropUnknownDeviceWithoutBlocking

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropUnknownDeviceWithoutBlocking`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-364 shouldResolveBindingByDevEuiWhenTbDeviceIdUnknown

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldResolveBindingByDevEuiWhenTbDeviceIdUnknown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-365 shouldSkipFrameAlreadyIngested

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldSkipFrameAlreadyIngested`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-366 shouldSwallowUniqueConflictAsConcurrentIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldSwallowUniqueConflictAsConcurrentIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-367 shouldRethrowUniqueConflictWhenRowAbsent

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldRethrowUniqueConflictWhenRowAbsent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-368 shouldPropagateTransientIngestFailureForRetry

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldPropagateTransientIngestFailureForRetry`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-369 shouldDropMalformedJson

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropMalformedJson`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-IOT-370 shouldDropFrameWithMissingContractFields

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldDropFrameWithMissingContractFields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-IOT-371 shouldClampOutOfRangeGpsBeforeIngest

- 优先级：P1
- 前置条件：测试夹具按测试类 @BeforeEach 构造
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/mq/DeviceHubChannelConsumerTest.java::shouldClampOutOfRangeGpsBeforeIngest`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

