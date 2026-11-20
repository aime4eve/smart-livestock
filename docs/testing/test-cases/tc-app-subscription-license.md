# 测试用例规格：App·订阅门控与许可

> 用例域：CMC ｜ 用例数：83
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-CMC-001 | enum has 4 values | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::enum has 4 values` |
| TC-CMC-002 | all map contains 4 tiers | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::all map contains 4 tiers` |
| TC-CMC-003 | tier metadata keeps name and features only (pricing lives in PlanInfo) | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::tier metadata keeps name and features only (pricing lives in PlanInfo)` |
| TC-CMC-004 | fromJson parses tier, currency and bands | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson parses tier, currency and bands` |
| TC-CMC-005 | band boundaries are inclusive | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::band boundaries are inclusive` |
| TC-CMC-006 | monthly fee = head count × band unit price | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::monthly fee = head count × band unit price` |
| TC-CMC-007 | custom pricing tiers return null fee | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::custom pricing tiers return null fee` |
| TC-CMC-008 | rangeLabel renders locale-neutral band ranges | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::rangeLabel renders locale-neutral band ranges` |
| TC-CMC-009 | fromJson parses all fields correctly | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson parses all fields correctly` |
| TC-CMC-010 | fromJson handles missing pricing fields (enterprise) | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson handles missing pricing fields (enterprise)` |
| TC-CMC-011 | all map contains 20 feature keys | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::all map contains 20 feature keys` |
| TC-CMC-012 | all 20 string constants are unique | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::all 20 string constants are unique` |
| TC-CMC-013 | fence has limit shape for lowest tier | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::fence has limit shape for lowest tier` |
| TC-CMC-014 | health_score has lock shape and dual device requirement | P1 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::health_score has lock shape and dual device requirement` |
| TC-CMC-015 | gps_location has none shape | P1 | REQ-IOT-005、REQ-IOT-006、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::gps_location has none shape` |
| TC-CMC-016 | data_retention_days has filter shape | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::data_retention_days has filter shape` |
| TC-CMC-017 | enterprise-exclusive features are lock shaped | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::enterprise-exclusive features are lock shaped` |
| TC-CMC-018 | basic tier can access gps_location | P1 | REQ-IOT-005、REQ-IOT-006、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier can access gps_location` |
| TC-CMC-019 | basic tier cannot access health_score (lock) | P1 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier cannot access health_score (lock)` |
| TC-CMC-020 | premium tier can access health_score | P1 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::premium tier can access health_score` |
| TC-CMC-021 | standard tier can access alert_history | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-CMC-001 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::standard tier can access alert_history` |
| TC-CMC-022 | basic tier cannot access alert_history | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-CMC-001 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier cannot access alert_history` |
| TC-CMC-023 | enterprise can access all locked features | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::enterprise can access all locked features` |
| TC-CMC-024 | unknown feature key returns false | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::unknown feature key returns false` |
| TC-CMC-025 | data_retention_days uses Map tiers config | P1 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/core/subscription_tier_test.dart::data_retention_days uses Map tiers config` |
| TC-CMC-026 | ONPREM: loads mode + tenants and preselects first tenant | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::ONPREM: loads mode + tenants and preselects first tenant` |
| TC-CMC-027 | HOSTED: loads mode but no tenant detail | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::HOSTED: loads mode but no tenant detail` |
| TC-CMC-028 | reloads enrollment + current for the picked tenant | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::reloads enrollment + current for the picked tenant` |
| TC-CMC-029 | calls the repository with the selected tenant + picked file and refreshes | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::calls the repository with the selected tenant + picked file and refreshes` |
| TC-CMC-030 | shows hosted notice card, hides onprem sections | P2 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::shows hosted notice card, hides onprem sections` |
| TC-CMC-031 | renders tenant dropdown and enrollment info | P2 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::renders tenant dropdown and enrollment info` |
| TC-CMC-032 | renders the four runtime status chips | P2 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::renders the four runtime status chips` |
| TC-CMC-033 | expired / suspended show renewal guidance | P2 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::expired / suspended show renewal guidance` |
| TC-CMC-034 | valid license shows no renewal guidance and renders countdown | P2 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::valid license shows no renewal guidance and renders countdown` |
| TC-CMC-035 | platform_admin can open /admin/deployment-license | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::platform_admin can open /admin/deployment-license` |
| TC-CMC-036 | owner navigating to /admin/deployment-license is redirected to ranch | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::owner navigating to /admin/deployment-license is redirected to ranch` |
| TC-CMC-037 | worker navigating to /admin/deployment-license is redirected to ranch | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::worker navigating to /admin/deployment-license is redirected to ranch` |
| TC-CMC-038 | grantPilotLicense delegates to the repository and refreshes | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::grantPilotLicense delegates to the repository and refreshes` |
| TC-CMC-039 | grantPilotLicense rethrows STATE_CONFLICT conflict branch | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::grantPilotLicense rethrows STATE_CONFLICT conflict branch` |
| TC-CMC-040 | button visible in HOSTED mode with pilot enabled | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button visible in HOSTED mode with pilot enabled` |
| TC-CMC-041 | button hidden in ONPREM mode | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button hidden in ONPREM mode` |
| TC-CMC-042 | button hidden in HOSTED mode when pilot switch disabled | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button hidden in HOSTED mode when pilot switch disabled` |
| TC-CMC-043 | confirm flow grants the pilot license and shows trialEndsAt | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::confirm flow grants the pilot license and shows trialEndsAt` |
| TC-CMC-044 | STATE_CONFLICT renders the dedicated conflict message | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007 | `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::STATE_CONFLICT renders the dedicated conflict message` |
| TC-CMC-045 | D5: eight filter chips + search box; backend gets size=100 | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D5: eight filter chips + search box; backend gets size=100` |
| TC-CMC-046 | D4: legend footer four colour dots + total note | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D4: legend footer four colour dots + total note` |
| TC-CMC-047 | D6: zh pill labels per health status | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D6: zh pill labels per health status` |
| TC-CMC-048 | chip tap and keyword submit re-query with params | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::chip tap and keyword submit re-query with params` |
| TC-CMC-049 | NIX-334: ops column renders per health status | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: ops column renders per health status` |
| TC-CMC-050 | NIX-334: assist repayment confirm dialog issues PUT ACTIVE  | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: assist repayment confirm dialog issues PUT ACTIVE ` |
| TC-CMC-051 | NIX-334: cancelling the dialog issues no write | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: cancelling the dialog issues no write` |
| TC-CMC-052 | settings card renders loaded thresholds and PUTs on save | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::settings card renders loaded thresholds and PUTs on save` |
| TC-CMC-053 | frontend order validation blocks an invalid save without PUT | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::frontend order validation blocks an invalid save without PUT` |
| TC-CMC-054 | editing any tier field clears the stale order error | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::editing any tier field clears the stale order error` |
| TC-CMC-055 | HOSTED mode shows the cloud-hosted chip without banner | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::HOSTED mode shows the cloud-hosted chip without banner` |
| TC-CMC-056 | ONPREM PENDING_ACTIVATION shows the activation banner | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM PENDING_ACTIVATION shows the activation banner` |
| TC-CMC-057 | ONPREM fresh install (null runtime) shows pending banner and copy button | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM fresh install (null runtime) shows pending banner and copy button` |
| TC-CMC-058 | ONPREM EXPIRED shows the expired banner | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM EXPIRED shows the expired banner` |
| TC-CMC-059 | deployment-info failure hides the badge and keeps the form | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002 | `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::deployment-info failure hides the badge and keeps the form` |
| TC-CMC-060 | export card paints a dashed stroke, not a solid border | P2 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/export_entitlement_card_dashed_border_test.dart::export card paints a dashed stroke, not a solid border` |
| TC-CMC-061 | shows child when locked is false | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows child when locked is false` |
| TC-CMC-062 | shows overlay when locked is true | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows overlay when locked is true` |
| TC-CMC-063 | shows upgrade button when onUpgrade provided and not device locked | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows upgrade button when onUpgrade provided and not device locked` |
| TC-CMC-064 | shows device icon when deviceLocked is true | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows device icon when deviceLocked is true` |
| TC-CMC-065 | device locked shows default message when deviceMessage is null | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::device locked shows default message when deviceMessage is null` |
| TC-CMC-066 | device locked does NOT show upgrade button | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::device locked does NOT show upgrade button` |
| TC-CMC-067 | shows correct label for enterprise upgrade tier | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows correct label for enterprise upgrade tier` |
| TC-CMC-068 | child is rendered with reduced opacity when locked | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::child is rendered with reduced opacity when locked` |
| TC-CMC-069 | spec §2 severity matrix colours (backend-decided severity) | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::spec §2 severity matrix colours (backend-decided severity)` |
| TC-CMC-070 | missing severity falls back to info (safe direction when  | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::missing severity falls back to info (safe direction when ` |
| TC-CMC-071 | healthy renders no banner | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::healthy renders no banner` |
| TC-CMC-072 | suspended has no primary CTA; expired has renew CTA | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::suspended has no primary CTA; expired has renew CTA` |
| TC-CMC-073 | fromJson parses severity (nullable, default null) | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::fromJson parses severity (nullable, default null)` |
| TC-CMC-074 | NIX-334 snooze gating is backend-decided via snoozeAllowed:  | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::NIX-334 snooze gating is backend-decided via snoozeAllowed: ` |
| TC-CMC-075 | fromJson parses snoozeAllowed (nullable, default null) | P2 | REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::fromJson parses snoozeAllowed (nullable, default null)` |
| TC-CMC-076 | TRIAL converts to premium regardless of row tier | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::TRIAL converts to premium regardless of row tier` |
| TC-CMC-077 | RENEWAL_FAILED renews the row tier, not basic (D1 regression) | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::RENEWAL_FAILED renews the row tier, not basic (D1 regression)` |
| TC-CMC-078 | EXPIRED keeps row tier | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::EXPIRED keeps row tier` |
| TC-CMC-079 | basic row renewing stays basic | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::basic row renewing stays basic` |
| TC-CMC-080 | record round-trips through its encoded form | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::record round-trips through its encoded form` |
| TC-CMC-081 | suppresses only the same level AND period end | P1 | REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002 | `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::suppresses only the same level AND period end` |
| TC-CMC-082 | snooze persists across a fresh provider/container (app restart) | P1 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::snooze persists across a fresh provider/container (app restart)` |
| TC-CMC-083 | snoozes are keyed per tenant | P1 | REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::snoozes are keyed per tenant` |

## 用例明细（初稿模板）

### TC-CMC-001 enum has 4 values

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：SubscriptionTier
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::enum has 4 values`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-002 all map contains 4 tiers

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：SubscriptionTierInfo
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::all map contains 4 tiers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006

### TC-CMC-003 tier metadata keeps name and features only (pricing lives in PlanInfo)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::tier metadata keeps name and features only (pricing lives in PlanInfo)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-004 fromJson parses tier, currency and bands

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson parses tier, currency and bands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-005 band boundaries are inclusive

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::band boundaries are inclusive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-006 monthly fee = head count × band unit price

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::monthly fee = head count × band unit price`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-007 custom pricing tiers return null fee

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::custom pricing tiers return null fee`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-008 rangeLabel renders locale-neutral band ranges

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::rangeLabel renders locale-neutral band ranges`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-009 fromJson parses all fields correctly

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：SubscriptionStatus
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson parses all fields correctly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-010 fromJson handles missing pricing fields (enterprise)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::fromJson handles missing pricing fields (enterprise)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-011 all map contains 20 feature keys

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FeatureFlags
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::all map contains 20 feature keys`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006

### TC-CMC-012 all 20 string constants are unique

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::all 20 string constants are unique`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-013 fence has limit shape for lowest tier

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::fence has limit shape for lowest tier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-CMC-014 health_score has lock shape and dual device requirement

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::health_score has lock shape and dual device requirement`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-015 gps_location has none shape

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::gps_location has none shape`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-CMC-001、REQ-CMC-002

### TC-CMC-016 data_retention_days has filter shape

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::data_retention_days has filter shape`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-017 enterprise-exclusive features are lock shaped

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::enterprise-exclusive features are lock shaped`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-018 basic tier can access gps_location

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：checkTierAccess
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier can access gps_location`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-CMC-001、REQ-CMC-002

### TC-CMC-019 basic tier cannot access health_score (lock)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier cannot access health_score (lock)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-020 premium tier can access health_score

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::premium tier can access health_score`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-021 standard tier can access alert_history

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::standard tier can access alert_history`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-CMC-001

### TC-CMC-022 basic tier cannot access alert_history

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::basic tier cannot access alert_history`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-CMC-001

### TC-CMC-023 enterprise can access all locked features

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::enterprise can access all locked features`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-024 unknown feature key returns false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::unknown feature key returns false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-025 data_retention_days uses Map tiers config

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/subscription_tier_test.dart::data_retention_days uses Map tiers config`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-002、REQ-RCH-006

### TC-CMC-026 ONPREM: loads mode + tenants and preselects first tenant

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DeploymentLicenseController — build
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::ONPREM: loads mode + tenants and preselects first tenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-027 HOSTED: loads mode but no tenant detail

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::HOSTED: loads mode but no tenant detail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-028 reloads enrollment + current for the picked tenant

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DeploymentLicenseController — selectTenant
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::reloads enrollment + current for the picked tenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-029 calls the repository with the selected tenant + picked file and refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DeploymentLicenseController — importLicense
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_controller_test.dart::calls the repository with the selected tenant + picked file and refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-030 shows hosted notice card, hides onprem sections

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：DeploymentLicensePage — HOSTED mode
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::shows hosted notice card, hides onprem sections`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-031 renders tenant dropdown and enrollment info

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：DeploymentLicensePage — ONPREM mode
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::renders tenant dropdown and enrollment info`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-001

### TC-CMC-032 renders the four runtime status chips

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::renders the four runtime status chips`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-033 expired / suspended show renewal guidance

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::expired / suspended show renewal guidance`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-034 valid license shows no renewal guidance and renders countdown

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_page_test.dart::valid license shows no renewal guidance and renders countdown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-035 platform_admin can open /admin/deployment-license

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::platform_admin can open /admin/deployment-license`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-036 owner navigating to /admin/deployment-license is redirected to ranch

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::owner navigating to /admin/deployment-license is redirected to ranch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-037 worker navigating to /admin/deployment-license is redirected to ranch

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/deployment_license_route_test.dart::worker navigating to /admin/deployment-license is redirected to ranch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-038 grantPilotLicense delegates to the repository and refreshes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：pilot license — controller
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::grantPilotLicense delegates to the repository and refreshes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-039 grantPilotLicense rethrows STATE_CONFLICT conflict branch

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::grantPilotLicense rethrows STATE_CONFLICT conflict branch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-CMC-040 button visible in HOSTED mode with pilot enabled

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：pilot license — SubscriptionsPage entry
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button visible in HOSTED mode with pilot enabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-CMC-041 button hidden in ONPREM mode

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button hidden in ONPREM mode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-042 button hidden in HOSTED mode when pilot switch disabled

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::button hidden in HOSTED mode when pilot switch disabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-043 confirm flow grants the pilot license and shows trialEndsAt

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::confirm flow grants the pilot license and shows trialEndsAt`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-044 STATE_CONFLICT renders the dedicated conflict message

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/license/pilot_license_test.dart::STATE_CONFLICT renders the dedicated conflict message`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007

### TC-CMC-045 D5: eight filter chips + search box; backend gets size=100

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D5: eight filter chips + search box; backend gets size=100`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-046 D4: legend footer four colour dots + total note

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D4: legend footer four colour dots + total note`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-047 D6: zh pill labels per health status

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::D6: zh pill labels per health status`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-048 chip tap and keyword submit re-query with params

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::chip tap and keyword submit re-query with params`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-049 NIX-334: ops column renders per health status

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: ops column renders per health status`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-050 NIX-334: assist repayment confirm dialog issues PUT ACTIVE 

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: assist repayment confirm dialog issues PUT ACTIVE `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-051 NIX-334: cancelling the dialog issues no write

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::NIX-334: cancelling the dialog issues no write`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-052 settings card renders loaded thresholds and PUTs on save

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::settings card renders loaded thresholds and PUTs on save`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-053 frontend order validation blocks an invalid save without PUT

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::frontend order validation blocks an invalid save without PUT`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-054 editing any tier field clears the stale order error

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/subscription_health_page_test.dart::editing any tier field clears the stale order error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-055 HOSTED mode shows the cloud-hosted chip without banner

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::HOSTED mode shows the cloud-hosted chip without banner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-056 ONPREM PENDING_ACTIVATION shows the activation banner

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM PENDING_ACTIVATION shows the activation banner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-057 ONPREM fresh install (null runtime) shows pending banner and copy button

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM fresh install (null runtime) shows pending banner and copy button`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-058 ONPREM EXPIRED shows the expired banner

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::ONPREM EXPIRED shows the expired banner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-059 deployment-info failure hides the badge and keeps the form

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/login_license_mode_test.dart::deployment-info failure hides the badge and keeps the form`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IDT-002

### TC-CMC-060 export card paints a dashed stroke, not a solid border

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/export_entitlement_card_dashed_border_test.dart::export card paints a dashed stroke, not a solid border`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-061 shows child when locked is false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：LockedOverlay
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows child when locked is false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-062 shows overlay when locked is true

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows overlay when locked is true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-063 shows upgrade button when onUpgrade provided and not device locked

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows upgrade button when onUpgrade provided and not device locked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002

### TC-CMC-064 shows device icon when deviceLocked is true

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows device icon when deviceLocked is true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002

### TC-CMC-065 device locked shows default message when deviceMessage is null

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::device locked shows default message when deviceMessage is null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002

### TC-CMC-066 device locked does NOT show upgrade button

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::device locked does NOT show upgrade button`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IOT-001、REQ-IOT-002

### TC-CMC-067 shows correct label for enterprise upgrade tier

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::shows correct label for enterprise upgrade tier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-068 child is rendered with reduced opacity when locked

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/locked_overlay_test.dart::child is rendered with reduced opacity when locked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-069 spec §2 severity matrix colours (backend-decided severity)

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::spec §2 severity matrix colours (backend-decided severity)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-070 missing severity falls back to info (safe direction when 

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::missing severity falls back to info (safe direction when `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-071 healthy renders no banner

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::healthy renders no banner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-072 suspended has no primary CTA; expired has renew CTA

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::suspended has no primary CTA; expired has renew CTA`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-073 fromJson parses severity (nullable, default null)

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::fromJson parses severity (nullable, default null)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-074 NIX-334 snooze gating is backend-decided via snoozeAllowed: 

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::NIX-334 snooze gating is backend-decided via snoozeAllowed: `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-075 fromJson parses snoozeAllowed (nullable, default null)

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_health_banner_severity_test.dart::fromJson parses snoozeAllowed (nullable, default null)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-CMC-001、REQ-CMC-002

### TC-CMC-076 TRIAL converts to premium regardless of row tier

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::TRIAL converts to premium regardless of row tier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-077 RENEWAL_FAILED renews the row tier, not basic (D1 regression)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::RENEWAL_FAILED renews the row tier, not basic (D1 regression)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-078 EXPIRED keeps row tier

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::EXPIRED keeps row tier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-079 basic row renewing stays basic

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_plan_page_cta_target_test.dart::basic row renewing stays basic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-080 record round-trips through its encoded form

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::record round-trips through its encoded form`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-081 suppresses only the same level AND period end

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::suppresses only the same level AND period end`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-PLT-001、REQ-PLT-002

### TC-CMC-082 snooze persists across a fresh provider/container (app restart)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::snooze persists across a fresh provider/container (app restart)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-CMC-083 snoozes are keyed per tenant

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/subscription/subscription_snooze_record_test.dart::snoozes are keyed per tenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-IDT-001、REQ-IDT-003

