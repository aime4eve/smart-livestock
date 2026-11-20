# 测试用例规格：后端·端到端旅程集成测试

> 用例域：JRY ｜ 用例数：265
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-JRY-001 | ACTIVE → dismiss → DISMISSED | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::active_to_dismissed` |
| TC-JRY-002 | ACTIVE → archive (auto-resolve) → AUTO_RESOLVED | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::active_to_autoResolved` |
| TC-JRY-003 | markRead 端点可用 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::markRead_endpoint` |
| TC-JRY-004 | batch-read 端点可用 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::batchRead_endpoint` |
| TC-JRY-005 | worker 可以 markRead | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanMarkRead` |
| TC-JRY-006 | worker 可以 dismiss 告警 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanDismiss` |
| TC-JRY-007 | worker 批量 dismiss 端点可用（NIX-351） | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanBatchDismiss` |
| TC-JRY-008 | batch-dismiss 跳过非 ACTIVE 项（NIX-351） | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::batchDismiss_skipsNonActive` |
| TC-JRY-009 | dismiss 已解除的告警返回 409 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::dismiss_dismissedAlert_returns409` |
| TC-JRY-010 | dismiss 已自动解除的告警返回 409 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::dismiss_autoResolvedAlert_returns409` |
| TC-JRY-011 | 旧 /acknowledge 端点仍可调用 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::legacy_acknowledge` |
| TC-JRY-012 | 旧 /handle 端点重定向到 dismiss | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::legacy_handle` |
| TC-JRY-013 | platform_admin 登录成功返回 token | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::platformAdminLogin` |
| TC-JRY-014 | b2b_admin 登录成功返回 token | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::b2bAdminLogin` |
| TC-JRY-015 | owner 登录成功返回 token | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::ownerLogin` |
| TC-JRY-016 | worker 登录成功返回 token | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::workerLogin` |
| TC-JRY-017 | 登录响应包含用户信息 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::loginResponseContainsUserInfo` |
| TC-JRY-018 | 错误密码返回 401 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::wrongPassword_returns401` |
| TC-JRY-019 | 不存在的手机号返回 401 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::nonexistentPhone_returns401` |
| TC-JRY-020 | 空密码返回 401 或 400 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::emptyPassword_returnsError` |
| TC-JRY-021 | 无 token 访问受保护端点返回 401 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::noToken_returns401` |
| TC-JRY-022 | 有效 token 访问受保护端点返回 200 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::validToken_succeeds` |
| TC-JRY-023 | 伪造 token 访问受保护端点返回 401 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::invalidToken_returns401` |
| TC-JRY-024 | b2b_admin 查看牧场列表（≥2 个牧场） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFarms_atLeast2` |
| TC-JRY-025 | b2b_admin 查看牧场详情 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_getFarmDetail` |
| TC-JRY-026 | b2b_admin 查看牧场 1 的成员列表 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFarmMembers` |
| TC-JRY-027 | b2b_admin 查看 Dashboard 汇总数据 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_dashboardSummary` |
| TC-JRY-028 | b2b_admin 查看地图概览 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_mapOverview` |
| TC-JRY-029 | b2b_admin 不能访问 Admin 合同列表（返回 403） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listContracts_returns403` |
| TC-JRY-030 | b2b_admin 不能访问 Admin 分润期间列表（返回 403） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listRevenuePeriods_returns403` |
| TC-JRY-031 | b2b_admin 查看 App 端合同（/contracts/me） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_viewMyContracts` |
| TC-JRY-032 | b2b_admin 查看 App 端分润期间 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_viewRevenuePeriods` |
| TC-JRY-033 | b2b_admin 查看 Admin 订阅列表 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listSubscriptions` |
| TC-JRY-034 | b2b_admin 查看 Admin 功能门控列表 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFeatureGates` |
| TC-JRY-035 | b2b_admin 查看 Admin 订阅服务列表 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listSubscriptionServices` |
| TC-JRY-036 | b2b_admin 不能创建其他租户的用户 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_cannotCreateUserForOtherTenant` |
| TC-JRY-037 | b2b_admin 不能访问 platform_admin 独占端点 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_cannotAccessPlatformAdminEndpoints` |
| TC-JRY-038 | b2b_admin 可以创建牧场（owner 或 b2b_admin 均可） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_canCreateFarm` |
| TC-JRY-039 | highRiskHead_detectedThroughRealScheduler | P0 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::highRiskHead_detectedThroughRealScheduler` |
| TC-JRY-040 | repeatedEvaluation_deduplicatesTicket | P0 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::repeatedEvaluation_deduplicatesTicket` |
| TC-JRY-041 | riskFall_releasesTicketAndClearsColumn | P0 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::riskFall_releasesTicketAndClearsColumn` |
| TC-JRY-042 | lowRiskHead_writesNothing | P0 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::lowRiskHead_writesNothing` |
| TC-JRY-043 | lockedGate_skipsEvaluation | P0 | REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::lockedGate_skipsEvaluation` |
| TC-JRY-044 | ticketSource_followsTelemetrySource | P0 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::ticketSource_followsTelemetrySource` |
| TC-JRY-045 | owner 查看当前订阅（premium） | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewSubscription` |
| TC-JRY-046 | owner 查看套餐列表 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewPlans` |
| TC-JRY-047 | owner 查看用量 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewUsage` |
| TC-JRY-048 | owner 查看合同（/contracts/me） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewMyContracts` |
| TC-JRY-049 | owner 查看分润期间（/revenue/periods） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewRevenuePeriods` |
| TC-JRY-050 | owner checkout 升级订阅 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_checkoutUpgrade` |
| TC-JRY-051 | owner checkout 不带 billingCycle 也能成功（App 端无周期概念） | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_checkoutWithoutBillingCycle` |
| TC-JRY-052 | owner PUT /subscription/tier 降级订阅 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_downgradeTier` |
| TC-JRY-053 | owner POST /subscription/cancel 取消订阅 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cancelSubscription` |
| TC-JRY-054 | platform_admin 创建合同成功 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_createContract` |
| TC-JRY-055 | platform_admin 查看合同列表 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listContracts` |
| TC-JRY-056 | platform_admin 更新合同状态 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_updateContractStatus` |
| TC-JRY-057 | platform_admin 查看分润期间列表（≥3 条） | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listRevenuePeriods` |
| TC-JRY-058 | platform_admin 查看分润期间详情 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_getRevenuePeriodDetail` |
| TC-JRY-059 | platform_admin 触发分润计算 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_calculateRevenue` |
| TC-JRY-060 | platform_admin 查看订阅服务列表 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listSubscriptionServices` |
| TC-JRY-061 | platform_admin 查看功能门控列表 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listFeatureGates` |
| TC-JRY-062 | platform_admin 查看订阅详情 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_getSubscriptionDetail` |
| TC-JRY-063 | owner 不能访问 Admin 合同端点 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminContracts` |
| TC-JRY-064 | owner 不能访问 Admin 分润端点 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminRevenue` |
| TC-JRY-065 | owner 不能访问 Admin 订阅服务管理 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminSubscriptionServices` |
| TC-JRY-066 | worker 可以查看订阅信息（无角色限制） | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::worker_canViewSubscription` |
| TC-JRY-067 | GET /me 返回当前用户信息 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::getMe_returnsUserInfo` |
| TC-JRY-068 | PUT /me 更新用户信息 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::putMe_updatesProfile` |
| TC-JRY-069 | GET /tenants/me 返回当前租户信息 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::getTenantsMe_returnsTenantInfo` |
| TC-JRY-070 | platform_admin GET /tenants/me 无租户归属返回 404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::platformAdmin_tenantsMe_noTenant` |
| TC-JRY-071 | owner 查看 Farm 1 Dashboard 汇总 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_dashboardSummary_farm1` |
| TC-JRY-072 | owner 查看 Farm 2 Dashboard 汇总 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_dashboardSummary_farm2` |
| TC-JRY-073 | Dashboard 数据与牧场关联正确 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::dashboardData_matchesFarm` |
| TC-JRY-074 | owner 查看 Farm 1 地图概览 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_mapOverview_farm1` |
| TC-JRY-075 | owner 查看 Farm 2 地图概览 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_mapOverview_farm2` |
| TC-JRY-076 | Farm 1 牲畜 50 头，Farm 2 牲畜 10 头 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::livestockCount_diffBetweenFarms` |
| TC-JRY-077 | Farm 1 围栏 ≥4 个，Farm 2 围栏 =2 个 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::fenceCount_diffBetweenFarms` |
| TC-JRY-078 | Farm 1 告警 ≥18 条，Farm 2 告警 =5 条 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::alertCount_diffBetweenFarms` |
| TC-JRY-079 | 不存在的农场返回 404/403 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::nonexistentFarm_returnsError` |
| TC-JRY-080 | 种子迁移：两条现行白名单存在且启用（行为不变迁移） | P0 | REQ-IDT-005、REQ-IDT-007、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::seedRulesShouldExistAndBeEnabled` |
| TC-JRY-081 | CRUD：创建/重名 409/停用/更新忽略改名/删除/删除不存在 404 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::crudShouldWork` |
| TC-JRY-082 | 权限：OWNER/WORKER 403，B2B_ADMIN 可读写 | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::roleGateShouldBlockNonPlatformAdmins` |
| TC-JRY-083 | 审计：写操作落 audit_logs | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::auditTrailShouldBeRecorded` |
| TC-JRY-084 | preflight 联动：停用/删除规则 → PENDING_TB_DEVICE，恢复 → READY_TO_INGEST | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::preflightShouldRespectRuleLifecycle` |
| TC-JRY-085 | 删除设备 → 全局过滤 404 → 同 EUI 重新添加复活原记录（同 id、status=INVENTORY） | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldSoftDeleteAndReviveByEui` |
| TC-JRY-086 | 同 deviceCode 重新添加已删设备 → 新建记录（部分索引放行，新 id） | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldCreateNewRecordForSameDeviceCode` |
| TC-JRY-087 | EUI 撞活跃设备 → DUPLICATE_RESOURCE（非 500） | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldRejectDuplicateEuiOnActiveDevice` |
| TC-JRY-088 | 跨租户删除设备 → 404（不暴露存在性） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldReturn404ForCrossTenantDelete` |
| TC-JRY-089 | datagenPointsProduceSourceTaggedEvents | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::datagenPointsProduceSourceTaggedEvents` |
| TC-JRY-090 | patchLabelFlipsWhitelistAndValidates | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::patchLabelFlipsWhitelistAndValidates` |
| TC-JRY-091 | manualPostCreatesConfirmedRowAndRejectsFutureAndNoDevice | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::manualPostCreatesConfirmedRowAndRejectsFutureAndNoDevice` |
| TC-JRY-092 | recalcPreservesManualRowsLabelsAndRestoresLabeledRows | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::recalcPreservesManualRowsLabelsAndRestoresLabeledRows` |
| TC-JRY-093 | candidateRowsFollowCountingDataContract | P0 | REQ-HLT-010、REQ-HLT-011、REQ-CMC-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::candidateRowsFollowCountingDataContract` |
| TC-JRY-094 | feverAlertActiveExcludesDetection | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-010 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::feverAlertActiveExcludesDetection` |
| TC-JRY-095 | defervescenceBufferExtendsExclusion | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::defervescenceBufferExtendsExclusion` |
| TC-JRY-096 | platformAdminRecalculatesSingleDevice | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::platformAdminRecalculatesSingleDevice` |
| TC-JRY-097 | platformAdminRecalculatesAllFarms | P0 | REQ-HLT-010、REQ-HLT-011、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::platformAdminRecalculatesAllFarms` |
| TC-JRY-098 | b2bAdminRecalculatesSingleDevice | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::b2bAdminRecalculatesSingleDevice` |
| TC-JRY-099 | ownerAndWorkerAreForbidden | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::ownerAndWorkerAreForbidden` |
| TC-JRY-100 | invertedMissingAndMalformedRangesAreRejected | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::invertedMissingAndMalformedRangesAreRejected` |
| TC-JRY-101 | futureToIsRejected | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::futureToIsRejected` |
| TC-JRY-102 | unknownDeviceIsRejectedWith404 | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::unknownDeviceIsRejectedWith404` |
| TC-JRY-103 | summaryEndpointsServeTracingTableShapes | P0 | REQ-HLT-010、REQ-HLT-011、REQ-PLT-001、REQ-PLT-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::summaryEndpointsServeTracingTableShapes` |
| TC-JRY-104 | eventsListHonorsClosedRangeAndOrdersNewestFirst | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::eventsListHonorsClosedRangeAndOrdersNewestFirst` |
| TC-JRY-105 | eventsListServesDerivedLowConfidenceFlag | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::eventsListServesDerivedLowConfidenceFlag` |
| TC-JRY-106 | peerComparisonReturns403ForNonPremiumTier | P0 | REQ-HLT-010、REQ-HLT-011、REQ-CMC-001、REQ-CMC-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::peerComparisonReturns403ForNonPremiumTier` |
| TC-JRY-107 | peerComparisonDegradesToInsufficientPeersWithoutQualifiedGroup | P0 | REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::peerComparisonDegradesToInsufficientPeersWithoutQualifiedGroup` |
| TC-JRY-108 | endpointsRejectLivestockOfAnotherFarmOrUnknown | P0 | REQ-HLT-010、REQ-HLT-011、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::endpointsRejectLivestockOfAnotherFarmOrUnknown` |
| TC-JRY-109 | migrationBackfillsLegacyVersion | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::migrationBackfillsLegacyVersion` |
| TC-JRY-110 | normalizedRowExplainedEndToEnd | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::normalizedRowExplainedEndToEnd` |
| TC-JRY-111 | capsuleRowDistanceNotParticipated | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::capsuleRowDistanceNotParticipated` |
| TC-JRY-112 | noScoreRow_degradesGracefully | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::noScoreRow_degradesGracefully` |
| TC-JRY-113 | confirmWritesEventAndLabel | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::confirmWritesEventAndLabel` |
| TC-JRY-114 | rejectionWritesRejectedLabel | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::rejectionWritesRejectedLabel` |
| TC-JRY-115 | flipSupersedesAndKeepsHistory | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::flipSupersedesAndKeepsHistory` |
| TC-JRY-116 | idempotentRepeatNoNewRows | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::idempotentRepeatNoNewRows` |
| TC-JRY-117 | breedingLinksDerivedLabels | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::breedingLinksDerivedLabels` |
| TC-JRY-118 | evaluationSkipsRejected | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::evaluationSkipsRejected` |
| TC-JRY-119 | normalizedScoringLandsRow | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::normalizedScoringLandsRow` |
| TC-JRY-120 | capsuleOnlyScoringDropsDistanceWeight | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::capsuleOnlyScoringDropsDistanceWeight` |
| TC-JRY-121 | starvedCurrentWindowWritesNothing | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::starvedCurrentWindowWritesNothing` |
| TC-JRY-122 | legacyModeRollsBackToShortWindowFormula | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::legacyModeRollsBackToShortWindowFormula` |
| TC-JRY-123 | readClampKeepsScoringOnClippedWindow | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::readClampKeepsScoringOnClippedWindow` |
| TC-JRY-124 | snapshotMirrorsFreshScore | P0 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::snapshotMirrorsFreshScore` |
| TC-JRY-125 | owner 查看自己的牧场列表 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarms_success` |
| TC-JRY-126 | owner 查看牧场 1 牲畜 total=50 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarm1Livestock` |
| TC-JRY-127 | owner 查看牧场 2 牲畜 total=10 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarm2Livestock` |
| TC-JRY-128 | owner 查看牧场围栏 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFences_forFarm` |
| TC-JRY-129 | owner 创建围栏成功 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFence_success` |
| TC-JRY-130 | owner 删除围栏成功 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_deleteFence_success` |
| TC-JRY-131 | owner 更新围栏名称和颜色 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_updateFence_success` |
| TC-JRY-132 | worker 不能创建围栏 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::worker_cannotCreateFence_returnsForbidden` |
| TC-JRY-133 | owner 创建新牧场成功 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFarm_success` |
| TC-JRY-134 | owner 创建重复名称牧场失败 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFarm_duplicateName_returnsError` |
| TC-JRY-135 | b2b_admin 查看牧场列表成功 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::b2bAdmin_listFarms_success` |
| TC-JRY-136 | owner 查看牧场成员列表（种子数据已分配 owner + worker） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarmMembers_returnsSeedMembers` |
| TC-JRY-137 | owner 添加牧场成员成功 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_addMember_returnsCreated` |
| TC-JRY-138 | owner 重复添加成员返回 409 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_addMember_duplicate_returns409` |
| TC-JRY-139 | owner 移除牧场成员成功 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_removeMember_returnsOk` |
| TC-JRY-140 | owner 列出围栏区域（可为空） | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::ownerListZones` |
| TC-JRY-141 | 无 token 返回 401 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::noAuthReturns401` |
| TC-JRY-142 | owner 创建围栏区域成功 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::ownerCreateZone` |
| TC-JRY-143 | worker 不能创建围栏区域 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::workerCannotCreate` |
| TC-JRY-144 | 当牲畜在围栏外时，应创建告警 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldCreateAlertWhenLivestockOutsideFence` |
| TC-JRY-145 | 当牲畜在围栏内时，不应创建告警 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldNotCreateAlertWhenLivestockInsideFence` |
| TC-JRY-146 | 越出多个围栏时，应为每个围栏创建告警 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldCreateMultipleAlertsWhenBreachingMultipleFences` |
| TC-JRY-147 | 告警应包含正确的围栏ID | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldIncludeCorrectFenceIdInAlert` |
| TC-JRY-148 | 已禁用的围栏不应触发告警 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldNotAlertForDisabledFence` |
| TC-JRY-149 | 设备无安装记录时，应静默跳过 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenNoActiveInstallation` |
| TC-JRY-150 | 牲畜不存在时，应静默跳过 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenLivestockNotFound` |
| TC-JRY-151 | 牧场无围栏时，应静默跳过 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenFarmHasNoFences` |
| TC-JRY-152 | FenceBreachDetector 正确检测围栏外的点 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::detectorShouldFindBreachedFences` |
| TC-JRY-153 | FenceBreachDetector 正确确认围栏内的点 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::detectorShouldConfirmInsideFences` |
| TC-JRY-154 | pilotFirstYearFree_expiryDowngrade_renewalRestoreJourney | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/HostedFirstYearFreeJourneyTest.java::pilotFirstYearFree_expiryDowngrade_renewalRestoreJourney` |
| TC-JRY-155 | individualBaselineLearningJourney | P0 | REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/IndividualBaselineLearningJourneyTest.java::individualBaselineLearningJourney` |
| TC-JRY-156 | 完整客户旅程 — 4 角色登录 + 数据验证 + 权限边界 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/JourneyIntegrationTest.java::fullCustomerJourney` |
| TC-JRY-157 | offlineLicense_hostBinding_expiry_renewalJourney | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OnPremLicenseJourneyTest.java::offlineLicense_hostBinding_expiry_renewalJourney` |
| TC-JRY-158 | livestock/{id}：本牧场 200，跨牧场 404（两方向） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::livestockDetail_crossFarmIs404` |
| TC-JRY-159 | livestock/{id}/gps-logs：本牧场 200，跨牧场 404 | P0 | REQ-IOT-005、REQ-IOT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::gpsHistory_crossFarmIs404` |
| TC-JRY-160 | gps-logs/latest：只返回本牧场牲畜的位置，不再泄漏其它牧场/租户 | P0 | REQ-IOT-005、REQ-IOT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::latestGps_isScopedToFarm` |
| TC-JRY-161 | fences/{id}：本牧场 200，跨牧场 404 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::fenceDetail_crossFarmIs404` |
| TC-JRY-162 | alerts/{id}：本牧场 200，跨牧场 404 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::alertDetail_crossFarmIs404` |
| TC-JRY-163 | devices/{id}：本租户 200，他租户设备 403，不存在 404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::deviceDetail_crossTenantIs403` |
| TC-JRY-164 | 不存在的牧场路径：牧场门先行 404，不触及资源校验 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::unknownFarm_is404` |
| TC-JRY-165 | owner 查看牧场 1 牲畜列表 total=50 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listLivestock_farm1` |
| TC-JRY-166 | owner 查看牧场 2 牲畜列表 total=10 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listLivestock_farm2` |
| TC-JRY-167 | owner 查看牲畜详情 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_getLivestockDetail` |
| TC-JRY-168 | owner 创建牲畜成功 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_createLivestock_success` |
| TC-JRY-169 | owner 更新牲畜信息成功 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_updateLivestock_success` |
| TC-JRY-170 | owner 牲畜列表返回完整数据 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_livestockListAll` |
| TC-JRY-171 | owner 查看牧场设备列表 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listDevices` |
| TC-JRY-172 | owner 查看设备详情 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_getDeviceDetail` |
| TC-JRY-173 | owner 注册新设备 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_registerDevice` |
| TC-JRY-174 | owner 查看安装记录列表 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listInstallations` |
| TC-JRY-175 | owner 查看设备 License 列表 | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listDeviceLicenses` |
| TC-JRY-176 | owner 查看最新 GPS 日志 | P0 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_latestGpsLogs` |
| TC-JRY-177 | owner 查看指定牲畜 GPS 日志 | P0 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_livestockGpsLogs` |
| TC-JRY-178 | crudHappyPath | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::crudHappyPath` |
| TC-JRY-179 | postIsIdempotentOnSameTriple | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::postIsIdempotentOnSameTriple` |
| TC-JRY-180 | futureDateRejectedWithEnglishMessage | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::futureDateRejectedWithEnglishMessage` |
| TC-JRY-181 | noteLongerThan500Rejected | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::noteLongerThan500Rejected` |
| TC-JRY-182 | livestockFromAnotherFarmRejected | P0 | REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::livestockFromAnotherFarmRejected` |
| TC-JRY-183 | alertConfirmRowsCannotBeEditedOrDeleted | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::alertConfirmRowsCannotBeEditedOrDeleted` |
| TC-JRY-184 | manualIllnessWithoutRecoveryStaysOpen | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::manualIllnessWithoutRecoveryStaysOpen` |
| TC-JRY-185 | manualIllnessWithRecoveryClosesAndFiltersByRange | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::manualIllnessWithRecoveryClosesAndFiltersByRange` |
| TC-JRY-186 | dispositionWindowsMergeByStatus | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::dispositionWindowsMergeByStatus` |
| TC-JRY-187 | entryDateIsShanghaiMidnightInUtc | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::entryDateIsShanghaiMidnightInUtc` |
| TC-JRY-188 | listMergesActiveDispositionRowAndProjectsStage | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::listMergesActiveDispositionRowAndProjectsStage` |
| TC-JRY-189 | currentStageFollowsSeededCalvingThenDryOff | P0 | REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::currentStageFollowsSeededCalvingThenDryOff` |
| TC-JRY-190 | grantCreatesTrialSubscriptionPersistedInDatabase | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::grantCreatesTrialSubscriptionPersistedInDatabase` |
| TC-JRY-191 | regrantAlignsToSharedCampaignDeadline | P0 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::regrantAlignsToSharedCampaignDeadline` |
| TC-JRY-192 | activeSubscriptionTenantIsRejectedWithStateConflict | P0 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::activeSubscriptionTenantIsRejectedWithStateConflict` |
| TC-JRY-193 | owner 获取 ranch-overview 成功，包含六个顶层字段 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::ownerGetsRanchOverview` |
| TC-JRY-194 | overallStats 字段完整且类型正确 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::overallStatsFieldsCorrect` |
| TC-JRY-195 | fences 列表非空且格式正确 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::fencesFormatCorrect` |
| TC-JRY-196 | livestockMarkers 包含位置和健康状态 | P0 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::livestockMarkersHavePositionAndHealth` |
| TC-JRY-197 | alerts 不含 AUTO_RESOLVED 状态 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::alertsExcludesArchived` |
| TC-JRY-198 | pendingTasks 的 severity 合法 | P0 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::pendingTasksSeverityValid` |
| TC-JRY-199 | worker 也能访问 ranch-overview | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::workerCanAccess` |
| TC-JRY-200 | 无 token 返回 401 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::noTokenReturns401` |
| TC-JRY-201 | 跨租户 farmId 返回 403 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::crossTenantFarmReturns403` |
| TC-JRY-202 | ranch-overview 包含 fenceZones 字段 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::overviewContainsFenceZones` |
| TC-JRY-203 | fenceAlertSummary 和 healthAlertSummary 字段存在 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::alertSummariesPresent` |
| TC-JRY-204 | alert change persists an outbox hint in the business transaction | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::successfulBusinessChangeWritesOutbox` |
| TC-JRY-205 | rolling back the business transaction also removes its outbox hint | P0 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::businessRollbackRemovesOutboxHint` |
| TC-JRY-206 | repeated entity changes merge into one pending final notification | P0 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::pendingEntityEventsCoalesce` |
| TC-JRY-207 | locked pending rows are skipped by another dispatcher | P0 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::concurrentDispatchersDoNotConsumeTheSameRow` |
| TC-JRY-208 | simulationEvaluationJourney | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/SimulationEvaluationJourneyTest.java::simulationEvaluationJourney` |
| TC-JRY-209 | viewCollapsesDualSourceAndExcludesDatagen | P0 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::viewCollapsesDualSourceAndExcludesDatagen` |
| TC-JRY-210 | viewSurvivorPrefersAgenticPlatform | P0 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::viewSurvivorPrefersAgenticPlatform` |
| TC-JRY-211 | linkDiagnosticsStillReadsRawTable | P0 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::linkDiagnosticsStillReadsRawTable` |
| TC-JRY-212 | platform_admin → 创建租户 → 创建用户 → 新用户登录 → 查询验证 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::fullOnboardingChain` |
| TC-JRY-213 | 创建租户缺少 name 返回 400 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createTenant_missingName_returns400` |
| TC-JRY-214 | 更新租户成功 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenant_success` |
| TC-JRY-215 | 更新租户 phase 为 batch | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantPhase_toBatch` |
| TC-JRY-216 | 查询不存在的租户返回 404 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::getNonexistentTenant_returns404` |
| TC-JRY-217 | 查询租户下的牧场列表 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::listTenantFarms_success` |
| TC-JRY-218 | 创建用户重复手机号返回 409 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createUser_duplicatePhone_returns409` |
| TC-JRY-219 | 创建用户无效 role 返回 400 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createUser_invalidRole_returns400` |
| TC-JRY-220 | 重置用户密码后可用新密码登录 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::resetPassword_thenLoginWithNew` |
| TC-JRY-221 | b2b_admin 不能创建租户返回 403 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::b2bAdmin_cannotCreateTenant_returns403` |
| TC-JRY-222 | owner 不能创建用户返回 403 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotCreateUser_returns403` |
| TC-JRY-223 | worker 不能创建用户返回 403 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::worker_cannotCreateUser_returns403` |
| TC-JRY-224 | platform_admin 查看 API Key 列表 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_listApiKeys` |
| TC-JRY-225 | platform_admin 创建 API Key | P0 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_createApiKey` |
| TC-JRY-226 | platform_admin 更新 API Key 状态（禁用） | P0 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_disableApiKey` |
| TC-JRY-227 | owner 不能访问 API Key 管理端点 | P0 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotAccessApiKeyAdmin` |
| TC-JRY-228 | platform_admin 更新租户状态（stub: active → disabled） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantStatus_disabled` |
| TC-JRY-229 | 更新租户状态无效值返回 400 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantStatus_invalidStatus_returns400` |
| TC-JRY-230 | owner 不能更新租户状态 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotUpdateTenantStatus` |
| TC-JRY-231 | owner 查看牧场瓦片状态 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileStatus` |
| TC-JRY-232 | owner 查看瓦片源（返回 List） | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileSource` |
| TC-JRY-233 | owner 查看离线地图（Testcontainers 无 mbtiles 文件，返回 404） | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_offlineMap_returns404` |
| TC-JRY-234 | owner 记录瓦片下载日志 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileDownloadLog` |
| TC-JRY-235 | platform_admin 查看瓦片管理状态（TileController 返回裸 List） | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_tileStatus` |
| TC-JRY-236 | platform_admin 查看瓦片区域列表（返回 List） | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listRegions` |
| TC-JRY-237 | platform_admin 查看瓦片生成任务（返回 List） | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listTasks` |
| TC-JRY-238 | platform_admin 查看牧场瓦片状态汇总（farm-tasks） | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listFarmTasks` |
| TC-JRY-239 | platform_admin 创建瓦片区域 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_createRegion` |
| TC-JRY-240 | platform_admin 创建瓦片生成任务 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_createTask` |
| TC-JRY-241 | worker 不能访问 Admin 瓦片端点 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::worker_cannotAccessAdminTiles` |
| TC-JRY-242 | owner 不能访问 Admin 瓦片端点 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_cannotAccessAdminTiles` |
| TC-JRY-243 | b2b_admin 可以访问 Admin 瓦片端点（@PreAuthorize 包含 B2B_ADMIN） | P0 | REQ-IDT-002、REQ-IDT-006、REQ-RCH-002、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::b2bAdmin_canAccessAdminTiles` |
| TC-JRY-244 | worker 查看牧场列表 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listFarms` |
| TC-JRY-245 | worker 查看牧场 1 牲畜列表 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listLivestock` |
| TC-JRY-246 | worker 查看围栏列表（只读） | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listFences` |
| TC-JRY-247 | worker 查看告警列表 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listAlerts` |
| TC-JRY-248 | worker 查看告警详情 | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_getAlertDetail` |
| TC-JRY-249 | worker 查看 Dashboard | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_viewDashboard` |
| TC-JRY-250 | worker 查看地图概览 | P0 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_viewMapOverview` |
| TC-JRY-251 | worker GET /me 返回正确角色信息 | P0 | REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_getMe_returnsWorkerRole` |
| TC-JRY-252 | worker PUT /me 更新名称成功 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_updateMe_success` |
| TC-JRY-253 | worker 可以 markRead ACTIVE 告警 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_canAcknowledge` |
| TC-JRY-254 | worker 不能创建牲畜 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateLivestock` |
| TC-JRY-255 | worker 不能创建围栏 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateFence` |
| TC-JRY-256 | worker 不能删除围栏 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotDeleteFence` |
| TC-JRY-257 | worker 可以处理告警（handle） | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_canHandleAlert` |
| TC-JRY-258 | worker 不能归档告警（archive） | P0 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotArchiveAlert` |
| TC-JRY-259 | worker 不能注册设备 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotRegisterDevice` |
| TC-JRY-260 | worker 不能访问 Admin 端点 | P0 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessAdmin` |
| TC-JRY-261 | worker 不能管理租户 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessTenant` |
| TC-JRY-262 | worker 不能查看 Admin 合同 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessContracts` |
| TC-JRY-263 | worker 不能查看 Admin 分润 | P0 | REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessRevenue` |
| TC-JRY-264 | worker 不能查看 Admin 订阅 | P0 | REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessSubscriptions` |
| TC-JRY-265 | worker 不能创建牧场 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateFarm` |

## 用例明细（初稿模板）

### TC-JRY-001 ACTIVE → dismiss → DISMISSED

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::active_to_dismissed`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-JRY-002 ACTIVE → archive (auto-resolve) → AUTO_RESOLVED

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::active_to_autoResolved`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-003 markRead 端点可用

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::markRead_endpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-004 batch-read 端点可用

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::batchRead_endpoint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-005 worker 可以 markRead

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanMarkRead`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-006 worker 可以 dismiss 告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanDismiss`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-007 worker 批量 dismiss 端点可用（NIX-351）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::workerCanBatchDismiss`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-008 batch-dismiss 跳过非 ACTIVE 项（NIX-351）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::batchDismiss_skipsNonActive`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-009 dismiss 已解除的告警返回 409

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::dismiss_dismissedAlert_returns409`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-JRY-010 dismiss 已自动解除的告警返回 409

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::dismiss_autoResolvedAlert_returns409`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-011 旧 /acknowledge 端点仍可调用

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::legacy_acknowledge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-012 旧 /handle 端点重定向到 dismiss

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AlertStateMachineJourneyTest.java::legacy_handle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-013 platform_admin 登录成功返回 token

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::platformAdminLogin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-014 b2b_admin 登录成功返回 token

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::b2bAdminLogin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-015 owner 登录成功返回 token

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::ownerLogin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-016 worker 登录成功返回 token

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::workerLogin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-017 登录响应包含用户信息

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::loginResponseContainsUserInfo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-018 错误密码返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::wrongPassword_returns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-019 不存在的手机号返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::nonexistentPhone_returns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-020 空密码返回 401 或 400

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::emptyPassword_returnsError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-021 无 token 访问受保护端点返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::noToken_returns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-022 有效 token 访问受保护端点返回 200

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::validToken_succeeds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-023 伪造 token 访问受保护端点返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/AuthJourneyTest.java::invalidToken_returns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-024 b2b_admin 查看牧场列表（≥2 个牧场）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFarms_atLeast2`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-025 b2b_admin 查看牧场详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_getFarmDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-026 b2b_admin 查看牧场 1 的成员列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFarmMembers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-027 b2b_admin 查看 Dashboard 汇总数据

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_dashboardSummary`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-028 b2b_admin 查看地图概览

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_mapOverview`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-029 b2b_admin 不能访问 Admin 合同列表（返回 403）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listContracts_returns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-030 b2b_admin 不能访问 Admin 分润期间列表（返回 403）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listRevenuePeriods_returns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-031 b2b_admin 查看 App 端合同（/contracts/me）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_viewMyContracts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-032 b2b_admin 查看 App 端分润期间

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_viewRevenuePeriods`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-033 b2b_admin 查看 Admin 订阅列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listSubscriptions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-034 b2b_admin 查看 Admin 功能门控列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listFeatureGates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-035 b2b_admin 查看 Admin 订阅服务列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_listSubscriptionServices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-036 b2b_admin 不能创建其他租户的用户

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_cannotCreateUserForOtherTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-037 b2b_admin 不能访问 platform_admin 独占端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_cannotAccessPlatformAdminEndpoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-038 b2b_admin 可以创建牧场（owner 或 b2b_admin 均可）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/B2BAdminJourneyTest.java::b2bAdmin_canCreateFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-039 highRiskHead_detectedThroughRealScheduler

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::highRiskHead_detectedThroughRealScheduler`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-JRY-040 repeatedEvaluation_deduplicatesTicket

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::repeatedEvaluation_deduplicatesTicket`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-JRY-041 riskFall_releasesTicketAndClearsColumn

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::riskFall_releasesTicketAndClearsColumn`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-JRY-042 lowRiskHead_writesNothing

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::lowRiskHead_writesNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-JRY-043 lockedGate_skipsEvaluation

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::lockedGate_skipsEvaluation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-RCH-001、REQ-RCH-002

### TC-JRY-044 ticketSource_followsTelemetrySource

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CalvingPredictionJourneyTest.java::ticketSource_followsTelemetrySource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-JRY-045 owner 查看当前订阅（premium）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-046 owner 查看套餐列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewPlans`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-047 owner 查看用量

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewUsage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-048 owner 查看合同（/contracts/me）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewMyContracts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-049 owner 查看分润期间（/revenue/periods）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_viewRevenuePeriods`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-050 owner checkout 升级订阅

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_checkoutUpgrade`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-051 owner checkout 不带 billingCycle 也能成功（App 端无周期概念）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_checkoutWithoutBillingCycle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-052 owner PUT /subscription/tier 降级订阅

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_downgradeTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-053 owner POST /subscription/cancel 取消订阅

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cancelSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-054 platform_admin 创建合同成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_createContract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-055 platform_admin 查看合同列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listContracts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-056 platform_admin 更新合同状态

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_updateContractStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-057 platform_admin 查看分润期间列表（≥3 条）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listRevenuePeriods`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-058 platform_admin 查看分润期间详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_getRevenuePeriodDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-059 platform_admin 触发分润计算

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_calculateRevenue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-060 platform_admin 查看订阅服务列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listSubscriptionServices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-061 platform_admin 查看功能门控列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_listFeatureGates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-062 platform_admin 查看订阅详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::admin_getSubscriptionDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-063 owner 不能访问 Admin 合同端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminContracts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-064 owner 不能访问 Admin 分润端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminRevenue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-065 owner 不能访问 Admin 订阅服务管理

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::owner_cannotAccessAdminSubscriptionServices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-066 worker 可以查看订阅信息（无角色限制）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/CommerceJourneyTest.java::worker_canViewSubscription`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-067 GET /me 返回当前用户信息

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::getMe_returnsUserInfo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-068 PUT /me 更新用户信息

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::putMe_updatesProfile`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-069 GET /tenants/me 返回当前租户信息

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::getTenantsMe_returnsTenantInfo`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-070 platform_admin GET /tenants/me 无租户归属返回 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::platformAdmin_tenantsMe_noTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-071 owner 查看 Farm 1 Dashboard 汇总

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_dashboardSummary_farm1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-072 owner 查看 Farm 2 Dashboard 汇总

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_dashboardSummary_farm2`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-073 Dashboard 数据与牧场关联正确

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::dashboardData_matchesFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-074 owner 查看 Farm 1 地图概览

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_mapOverview_farm1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-JRY-075 owner 查看 Farm 2 地图概览

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::owner_mapOverview_farm2`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-JRY-076 Farm 1 牲畜 50 头，Farm 2 牲畜 10 头

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::livestockCount_diffBetweenFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-077 Farm 1 围栏 ≥4 个，Farm 2 围栏 =2 个

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::fenceCount_diffBetweenFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-078 Farm 1 告警 ≥18 条，Farm 2 告警 =5 条

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::alertCount_diffBetweenFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001

### TC-JRY-079 不存在的农场返回 404/403

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DashboardMeJourneyTest.java::nonexistentFarm_returnsError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-080 种子迁移：两条现行白名单存在且启用（行为不变迁移）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::seedRulesShouldExistAndBeEnabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-005、REQ-IDT-007、REQ-RCH-001、REQ-RCH-002

### TC-JRY-081 CRUD：创建/重名 409/停用/更新忽略改名/删除/删除不存在 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::crudShouldWork`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-082 权限：OWNER/WORKER 403，B2B_ADMIN 可读写

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::roleGateShouldBlockNonPlatformAdmins`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-083 审计：写操作落 audit_logs

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::auditTrailShouldBeRecorded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-084 preflight 联动：停用/删除规则 → PENDING_TB_DEVICE，恢复 → READY_TO_INGEST

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceProfileRuleJourneyTest.java::preflightShouldRespectRuleLifecycle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-085 删除设备 → 全局过滤 404 → 同 EUI 重新添加复活原记录（同 id、status=INVENTORY）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldSoftDeleteAndReviveByEui`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-086 同 deviceCode 重新添加已删设备 → 新建记录（部分索引放行，新 id）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldCreateNewRecordForSameDeviceCode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-087 EUI 撞活跃设备 → DUPLICATE_RESOURCE（非 500）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldRejectDuplicateEuiOnActiveDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-088 跨租户删除设备 → 404（不暴露存在性）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DeviceSoftDeleteJourneyTest.java::shouldReturn404ForCrossTenantDelete`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-089 datagenPointsProduceSourceTaggedEvents

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::datagenPointsProduceSourceTaggedEvents`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-090 patchLabelFlipsWhitelistAndValidates

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::patchLabelFlipsWhitelistAndValidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-091 manualPostCreatesConfirmedRowAndRejectsFutureAndNoDevice

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::manualPostCreatesConfirmedRowAndRejectsFutureAndNoDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-092 recalcPreservesManualRowsLabelsAndRestoresLabeledRows

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::recalcPreservesManualRowsLabelsAndRestoresLabeledRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-093 candidateRowsFollowCountingDataContract

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::candidateRowsFollowCountingDataContract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-CMC-005、REQ-RCH-001

### TC-JRY-094 feverAlertActiveExcludesDetection

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::feverAlertActiveExcludesDetection`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-010

### TC-JRY-095 defervescenceBufferExtendsExclusion

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingEventJourneyTest.java::defervescenceBufferExtendsExclusion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-096 platformAdminRecalculatesSingleDevice

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::platformAdminRecalculatesSingleDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-097 platformAdminRecalculatesAllFarms

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::platformAdminRecalculatesAllFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-IDT-001、REQ-IDT-003

### TC-JRY-098 b2bAdminRecalculatesSingleDevice

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::b2bAdminRecalculatesSingleDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-099 ownerAndWorkerAreForbidden

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::ownerAndWorkerAreForbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-100 invertedMissingAndMalformedRangesAreRejected

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::invertedMissingAndMalformedRangesAreRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-101 futureToIsRejected

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::futureToIsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-102 unknownDeviceIsRejectedWith404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingRecalculateAdminApiTest.java::unknownDeviceIsRejectedWith404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-103 summaryEndpointsServeTracingTableShapes

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::summaryEndpointsServeTracingTableShapes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-PLT-001、REQ-PLT-002

### TC-JRY-104 eventsListHonorsClosedRangeAndOrdersNewestFirst

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::eventsListHonorsClosedRangeAndOrdersNewestFirst`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-105 eventsListServesDerivedLowConfidenceFlag

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::eventsListServesDerivedLowConfidenceFlag`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-106 peerComparisonReturns403ForNonPremiumTier

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::peerComparisonReturns403ForNonPremiumTier`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-CMC-001、REQ-CMC-002

### TC-JRY-107 peerComparisonDegradesToInsufficientPeersWithoutQualifiedGroup

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::peerComparisonDegradesToInsufficientPeersWithoutQualifiedGroup`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-RCH-001、REQ-RCH-002

### TC-JRY-108 endpointsRejectLivestockOfAnotherFarmOrUnknown

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/DrinkingSummaryJourneyTest.java::endpointsRejectLivestockOfAnotherFarmOrUnknown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-010、REQ-HLT-011、REQ-IDT-001、REQ-IDT-003

### TC-JRY-109 migrationBackfillsLegacyVersion

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::migrationBackfillsLegacyVersion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001

### TC-JRY-110 normalizedRowExplainedEndToEnd

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::normalizedRowExplainedEndToEnd`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001

### TC-JRY-111 capsuleRowDistanceNotParticipated

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::capsuleRowDistanceNotParticipated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001

### TC-JRY-112 noScoreRow_degradesGracefully

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusExplanationJourneyTest.java::noScoreRow_degradesGracefully`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001

### TC-JRY-113 confirmWritesEventAndLabel

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::confirmWritesEventAndLabel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-114 rejectionWritesRejectedLabel

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::rejectionWritesRejectedLabel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-115 flipSupersedesAndKeepsHistory

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::flipSupersedesAndKeepsHistory`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-116 idempotentRepeatNoNewRows

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::idempotentRepeatNoNewRows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-117 breedingLinksDerivedLabels

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::breedingLinksDerivedLabels`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-118 evaluationSkipsRejected

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusFeedbackJourneyTest.java::evaluationSkipsRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-119 normalizedScoringLandsRow

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::normalizedScoringLandsRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-120 capsuleOnlyScoringDropsDistanceWeight

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::capsuleOnlyScoringDropsDistanceWeight`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-121 starvedCurrentWindowWritesNothing

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::starvedCurrentWindowWritesNothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-122 legacyModeRollsBackToShortWindowFormula

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::legacyModeRollsBackToShortWindowFormula`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-123 readClampKeepsScoringOnClippedWindow

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::readClampKeepsScoringOnClippedWindow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-124 snapshotMirrorsFreshScore

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/EstrusNormalizedScoringJourneyTest.java::snapshotMirrorsFreshScore`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-RCH-001

### TC-JRY-125 owner 查看自己的牧场列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarms_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-126 owner 查看牧场 1 牲畜 total=50

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarm1Livestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-127 owner 查看牧场 2 牲畜 total=10

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarm2Livestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-128 owner 查看牧场围栏

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFences_forFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-129 owner 创建围栏成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFence_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-130 owner 删除围栏成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_deleteFence_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-131 owner 更新围栏名称和颜色

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_updateFence_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-132 worker 不能创建围栏

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::worker_cannotCreateFence_returnsForbidden`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-133 owner 创建新牧场成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFarm_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-134 owner 创建重复名称牧场失败

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_createFarm_duplicateName_returnsError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-135 b2b_admin 查看牧场列表成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::b2bAdmin_listFarms_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-136 owner 查看牧场成员列表（种子数据已分配 owner + worker）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_listFarmMembers_returnsSeedMembers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-137 owner 添加牧场成员成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_addMember_returnsCreated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-138 owner 重复添加成员返回 409

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_addMember_duplicate_returns409`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-139 owner 移除牧场成员成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FarmRanchJourneyTest.java::owner_removeMember_returnsOk`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-140 owner 列出围栏区域（可为空）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::ownerListZones`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-141 无 token 返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::noAuthReturns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-142 owner 创建围栏区域成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::ownerCreateZone`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-143 worker 不能创建围栏区域

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/FenceZoneJourneyTest.java::workerCannotCreate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-144 当牲畜在围栏外时，应创建告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldCreateAlertWhenLivestockOutsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-145 当牲畜在围栏内时，不应创建告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldNotCreateAlertWhenLivestockInsideFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-146 越出多个围栏时，应为每个围栏创建告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldCreateMultipleAlertsWhenBreachingMultipleFences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-147 告警应包含正确的围栏ID

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldIncludeCorrectFenceIdInAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-148 已禁用的围栏不应触发告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldNotAlertForDisabledFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-149 设备无安装记录时，应静默跳过

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenNoActiveInstallation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005

### TC-JRY-150 牲畜不存在时，应静默跳过

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenLivestockNotFound`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IOT-005

### TC-JRY-151 牧场无围栏时，应静默跳过

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::shouldSkipWhenFarmHasNoFences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-152 FenceBreachDetector 正确检测围栏外的点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::detectorShouldFindBreachedFences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-153 FenceBreachDetector 正确确认围栏内的点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java::detectorShouldConfirmInsideFences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-154 pilotFirstYearFree_expiryDowngrade_renewalRestoreJourney

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/HostedFirstYearFreeJourneyTest.java::pilotFirstYearFree_expiryDowngrade_renewalRestoreJourney`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-JRY-155 individualBaselineLearningJourney

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/IndividualBaselineLearningJourneyTest.java::individualBaselineLearningJourney`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-020、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-156 完整客户旅程 — 4 角色登录 + 数据验证 + 权限边界

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/JourneyIntegrationTest.java::fullCustomerJourney`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-157 offlineLicense_hostBinding_expiry_renewalJourney

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OnPremLicenseJourneyTest.java::offlineLicense_hostBinding_expiry_renewalJourney`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-JRY-158 livestock/{id}：本牧场 200，跨牧场 404（两方向）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::livestockDetail_crossFarmIs404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-159 livestock/{id}/gps-logs：本牧场 200，跨牧场 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::gpsHistory_crossFarmIs404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-160 gps-logs/latest：只返回本牧场牲畜的位置，不再泄漏其它牧场/租户

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::latestGps_isScopedToFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-161 fences/{id}：本牧场 200，跨牧场 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::fenceDetail_crossFarmIs404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-162 alerts/{id}：本牧场 200，跨牧场 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::alertDetail_crossFarmIs404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-IDT-001

### TC-JRY-163 devices/{id}：本租户 200，他租户设备 403，不存在 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::deviceDetail_crossTenantIs403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-164 不存在的牧场路径：牧场门先行 404，不触及资源校验

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OpenApiOwnershipJourneyTest.java::unknownFarm_is404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-165 owner 查看牧场 1 牲畜列表 total=50

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listLivestock_farm1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-166 owner 查看牧场 2 牲畜列表 total=10

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listLivestock_farm2`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-167 owner 查看牲畜详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_getLivestockDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-168 owner 创建牲畜成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_createLivestock_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-169 owner 更新牲畜信息成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_updateLivestock_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-170 owner 牲畜列表返回完整数据

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_livestockListAll`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-171 owner 查看牧场设备列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listDevices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-172 owner 查看设备详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_getDeviceDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-173 owner 注册新设备

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_registerDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-174 owner 查看安装记录列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listInstallations`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-175 owner 查看设备 License 列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_listDeviceLicenses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-JRY-176 owner 查看最新 GPS 日志

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_latestGpsLogs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-177 owner 查看指定牲畜 GPS 日志

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/OwnerLivestockDeviceJourneyTest.java::owner_livestockGpsLogs`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-178 crudHappyPath

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::crudHappyPath`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-179 postIsIdempotentOnSameTriple

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::postIsIdempotentOnSameTriple`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-180 futureDateRejectedWithEnglishMessage

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::futureDateRejectedWithEnglishMessage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-181 noteLongerThan500Rejected

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::noteLongerThan500Rejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-182 livestockFromAnotherFarmRejected

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::livestockFromAnotherFarmRejected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003

### TC-JRY-183 alertConfirmRowsCannotBeEditedOrDeleted

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::alertConfirmRowsCannotBeEditedOrDeleted`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-HLT-005

### TC-JRY-184 manualIllnessWithoutRecoveryStaysOpen

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::manualIllnessWithoutRecoveryStaysOpen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-185 manualIllnessWithRecoveryClosesAndFiltersByRange

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::manualIllnessWithRecoveryClosesAndFiltersByRange`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-186 dispositionWindowsMergeByStatus

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::dispositionWindowsMergeByStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-187 entryDateIsShanghaiMidnightInUtc

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::entryDateIsShanghaiMidnightInUtc`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-188 listMergesActiveDispositionRowAndProjectsStage

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::listMergesActiveDispositionRowAndProjectsStage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-189 currentStageFollowsSeededCalvingThenDryOff

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PhysiologyEventJourneyTest.java::currentStageFollowsSeededCalvingThenDryOff`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-HLT-005、REQ-HLT-033

### TC-JRY-190 grantCreatesTrialSubscriptionPersistedInDatabase

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::grantCreatesTrialSubscriptionPersistedInDatabase`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-JRY-191 regrantAlignsToSharedCampaignDeadline

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::regrantAlignsToSharedCampaignDeadline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-RCH-001

### TC-JRY-192 activeSubscriptionTenantIsRejectedWithStateConflict

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/PilotLicenseJourneyTest.java::activeSubscriptionTenantIsRejectedWithStateConflict`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-006

### TC-JRY-193 owner 获取 ranch-overview 成功，包含六个顶层字段

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::ownerGetsRanchOverview`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-194 overallStats 字段完整且类型正确

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::overallStatsFieldsCorrect`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-195 fences 列表非空且格式正确

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::fencesFormatCorrect`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-196 livestockMarkers 包含位置和健康状态

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::livestockMarkersHavePositionAndHealth`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-JRY-197 alerts 不含 AUTO_RESOLVED 状态

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::alertsExcludesArchived`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-198 pendingTasks 的 severity 合法

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::pendingTasksSeverityValid`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-JRY-199 worker 也能访问 ranch-overview

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::workerCanAccess`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-200 无 token 返回 401

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::noTokenReturns401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-001、REQ-RCH-002

### TC-JRY-201 跨租户 farmId 返回 403

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::crossTenantFarmReturns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-202 ranch-overview 包含 fenceZones 字段

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::overviewContainsFenceZones`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-203 fenceAlertSummary 和 healthAlertSummary 字段存在

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/RanchOverviewIntegrationTest.java::alertSummariesPresent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-204 alert change persists an outbox hint in the business transaction

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::successfulBusinessChangeWritesOutbox`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-JRY-205 rolling back the business transaction also removes its outbox hint

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::businessRollbackRemovesOutboxHint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-JRY-206 repeated entity changes merge into one pending final notification

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::pendingEntityEventsCoalesce`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-JRY-207 locked pending rows are skipped by another dispatcher

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/SignalOutboxJourneyTest.java::concurrentDispatchersDoNotConsumeTheSameRow`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-JRY-208 simulationEvaluationJourney

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/SimulationEvaluationJourneyTest.java::simulationEvaluationJourney`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-209 viewCollapsesDualSourceAndExcludesDatagen

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::viewCollapsesDualSourceAndExcludesDatagen`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-JRY-210 viewSurvivorPrefersAgenticPlatform

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::viewSurvivorPrefersAgenticPlatform`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-JRY-211 linkDiagnosticsStillReadsRawTable

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TelemetryCanonicalViewJourneyTest.java::linkDiagnosticsStillReadsRawTable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-JRY-212 platform_admin → 创建租户 → 创建用户 → 新用户登录 → 查询验证

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::fullOnboardingChain`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-213 创建租户缺少 name 返回 400

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createTenant_missingName_returns400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-214 更新租户成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenant_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-215 更新租户 phase 为 batch

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantPhase_toBatch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-216 查询不存在的租户返回 404

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::getNonexistentTenant_returns404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-217 查询租户下的牧场列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::listTenantFarms_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-218 创建用户重复手机号返回 409

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createUser_duplicatePhone_returns409`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-219 创建用户无效 role 返回 400

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::createUser_invalidRole_returns400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-220 重置用户密码后可用新密码登录

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::resetPassword_thenLoginWithNew`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-221 b2b_admin 不能创建租户返回 403

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::b2bAdmin_cannotCreateTenant_returns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-222 owner 不能创建用户返回 403

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotCreateUser_returns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-223 worker 不能创建用户返回 403

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::worker_cannotCreateUser_returns403`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-224 platform_admin 查看 API Key 列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_listApiKeys`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-225 platform_admin 创建 API Key

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_createApiKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-226 platform_admin 更新 API Key 状态（禁用）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::platformAdmin_disableApiKey`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-227 owner 不能访问 API Key 管理端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotAccessApiKeyAdmin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-JRY-228 platform_admin 更新租户状态（stub: active → disabled）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantStatus_disabled`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-229 更新租户状态无效值返回 400

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::updateTenantStatus_invalidStatus_returns400`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-230 owner 不能更新租户状态

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TenantOnboardingJourneyTest.java::owner_cannotUpdateTenantStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IDT-005、REQ-IDT-007

### TC-JRY-231 owner 查看牧场瓦片状态

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-232 owner 查看瓦片源（返回 List）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileSource`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-233 owner 查看离线地图（Testcontainers 无 mbtiles 文件，返回 404）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_offlineMap_returns404`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-234 owner 记录瓦片下载日志

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_tileDownloadLog`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-235 platform_admin 查看瓦片管理状态（TileController 返回裸 List）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_tileStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-236 platform_admin 查看瓦片区域列表（返回 List）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listRegions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-237 platform_admin 查看瓦片生成任务（返回 List）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listTasks`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-238 platform_admin 查看牧场瓦片状态汇总（farm-tasks）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_listFarmTasks`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-JRY-239 platform_admin 创建瓦片区域

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_createRegion`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-240 platform_admin 创建瓦片生成任务

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::admin_createTask`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-241 worker 不能访问 Admin 瓦片端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::worker_cannotAccessAdminTiles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-242 owner 不能访问 Admin 瓦片端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::owner_cannotAccessAdminTiles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-243 b2b_admin 可以访问 Admin 瓦片端点（@PreAuthorize 包含 B2B_ADMIN）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/TileJourneyTest.java::b2bAdmin_canAccessAdminTiles`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-RCH-002、REQ-RCH-006

### TC-JRY-244 worker 查看牧场列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listFarms`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-245 worker 查看牧场 1 牲畜列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-246 worker 查看围栏列表（只读）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listFences`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-247 worker 查看告警列表

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_listAlerts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-248 worker 查看告警详情

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_getAlertDetail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-249 worker 查看 Dashboard

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_viewDashboard`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-250 worker 查看地图概览

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_viewMapOverview`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-JRY-251 worker GET /me 返回正确角色信息

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_getMe_returnsWorkerRole`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-252 worker PUT /me 更新名称成功

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_updateMe_success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-253 worker 可以 markRead ACTIVE 告警

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_canAcknowledge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-254 worker 不能创建牲畜

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateLivestock`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-255 worker 不能创建围栏

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-256 worker 不能删除围栏

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotDeleteFence`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-JRY-257 worker 可以处理告警（handle）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_canHandleAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-258 worker 不能归档告警（archive）

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotArchiveAlert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-RCH-001

### TC-JRY-259 worker 不能注册设备

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotRegisterDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-JRY-260 worker 不能访问 Admin 端点

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessAdmin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-261 worker 不能管理租户

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessTenant`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-JRY-262 worker 不能查看 Admin 合同

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessContracts`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-263 worker 不能查看 Admin 分润

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessRevenue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-005、REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-JRY-264 worker 不能查看 Admin 订阅

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotAccessSubscriptions`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-RCH-001、REQ-RCH-002

### TC-JRY-265 worker 不能创建牧场

- 优先级：P0
- 前置条件：部署完成后环境可用；种子数据已加载
- 步骤：运行来源测试 `smart-livestock-server/src/test/java/com/smartlivestock/integration/WorkerJourneyTest.java::worker_cannotCreateFarm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

