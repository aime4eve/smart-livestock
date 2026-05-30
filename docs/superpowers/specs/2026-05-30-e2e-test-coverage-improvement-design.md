# E2E 测试覆盖度完善设计

> 基于第三轮审计报告（`docs/e2e-test-coverage-audit.md`），规划 P0+P1 旅程缺口补全 + 断言质量修复。
> 目标：覆盖度从 ~65% 提升至 ~80%。

---

## 1. 背景

当前 10 个旅程测试文件、~121 个 @Test，覆盖 5 条用户旅程的约 65%。主要问题：

- **P0 缺口**：b2b_admin 创建牧场未测试、牧工管理完全空白、API 授权审批无测试
- **P0 矛盾**：`owner_createFarm_success` 测试通过，但旅程文档规定 owner 不应创建牧场
- **P1 缺口**：围栏编辑、健康预警、订阅升级、租户启停、worker /me、瓦片端点（10 个已实现）均无测试
- **断言质量**：~15 处 `isIn(403,401)`、~8 处 `isIn(200,201)`、3 处条件跳过、1 处 `isBetween(200,500)`

## 2. 策略

按旅程组织、分 Phase 递进。每个 Task 前置"验证 API 实际行为"步骤，断言写确定值。

核心原则：**先确认 API 契约再写断言**，不写模糊断言。

---

## 3. Phase 1：权限矛盾确认

### 目标

确认 `POST /api/v1/farms` 的权限配置是否符合 `customer-journey.md` 的定义。

### 步骤

1. 读取 `SecurityConfig` 中 `/farms` 的权限规则
2. 读取 `FarmController.createFarm()` 的方法注解
3. 对比客户旅程文档中"牧场不由 owner 自行创建"的约束
4. 得出结论：
   - **方向 X**：后端有漏洞 → 修 SecurityConfig，`FarmRanchJourneyTest.owner_createFarm_success` 改为断言 403
   - **方向 Y**：文档过时 → 更新 `customer-journey.md`，保留 owner 创建牧场测试

### 交付物

确认结论（不写新代码，只读现有代码）。后续所有 Task 基于此结论。

---

## 4. Phase 2：P0 测试补全

### Task 1: B2BAdminJourneyTest — 创建牧场 + 分配 owner

**前置验证**：
- 确认 `POST /farms` 在 b2b_admin 身份下实际返回 201 还是 403
- 确认创建牧场请求体字段（name / latitude / longitude / areaHectares?）
- 确认是否存在"分配牧场给 owner"的 API

**新增测试**（3-4 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | b2b_admin 创建牧场成功 | `POST /farms` | 201 |
| 2 | owner 可查看 b2b_admin 创建的牧场 | `GET /farms` | 包含新牧场 |
| 3 | b2b_admin 不能为其他租户创建牧场 | `POST /farms`（跨租户） | 403 |
| 4 | 分配牧场给 owner（如有 API） | `POST /farms/{id}/assign` 或类似 | 待确认 |

### Task 2: WorkerManagementJourneyTest — 牧工管理

**前置验证**：
- 查找 WorkerManagement 相关 Controller，确认端点是否存在
- 如端点未实现，则记录为缺口，测试标注为"待 Phase 2b 实现"

**新增测试**（3-5 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | owner 查看牧工列表 | `GET /farms/{farmId}/workers` | 200 |
| 2 | owner 添加牧工 | `POST /farms/{farmId}/workers` | 201 |
| 3 | owner 移除牧工 | `DELETE /farms/{farmId}/workers/{userId}` | 200/204 |
| 4 | b2b_admin 查看旗下牧工 | `GET /b2b/workers` 或类似 | 200 |
| 5 | worker 不能访问牧工管理 | 同上 | 403 |

### Task 3: API 授权审批（追加到 TenantOnboardingJourneyTest）

**前置验证**：
- 查看 `ApiKeyAdminController` 确认审批端点是否存在
- CLAUDE.md 标注"API Key 是 stub"，需确认 stub 实现程度

**新增测试**（2-3 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | platform_admin 查看 API Key 列表 | `GET /admin/api-keys` | 200 |
| 2 | platform_admin 审批 API Key | `PUT /admin/api-keys/{id}/approve` | 200（或记录 stub） |
| 3 | owner 不能审批 API Key | 同上 | 403 |

---

## 5. Phase 3：P1 测试补全

### Task 4: FarmRanchJourneyTest — 围栏编辑

**前置验证**：确认 `FenceController` 是否有 PUT 端点，确认更新请求体字段。

**新增测试**（2-3 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | owner 更新围栏名称和颜色 | `PUT /farms/{farmId}/fences/{fenceId}` | 200 + 字段变更 |
| 2 | owner 更新围栏顶点 | `PUT /farms/{farmId}/fences/{fenceId}` | 200 |
| 3 | worker 不能更新围栏 | 同上 | 403 |

### Task 5: OwnerLivestockDeviceJourneyTest — 健康预警

**前置验证**：查看 `HealthController` 端点列表，确认 Health Phase 2b 实现程度。

**新增测试**（1-2 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | owner 查看健康评分 | `GET /farms/{farmId}/health/scores` | 待确认（可能 stub） |
| 2 | owner 查看健康预警列表 | `GET /farms/{farmId}/health/alerts` | 待确认 |

### Task 6: CommerceJourneyTest — 订阅升级

**前置验证**：
- 确认 `CommerceController` 有哪些变更 tier 的端点
- 确认 `SubscriptionApplicationService` 是否有 changeTier 方法

**新增测试**（2-3 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | owner 请求 tier 变更 | `POST /subscription/change` 或类似 | 待确认 |
| 2 | 变更后 tier 验证 | `GET /subscription` | 新 tier 值 |
| 3 | basic → standard 功能门控变化 | 功能门控验证 | 待确认 |

### Task 7: TenantOnboardingJourneyTest — 租户启停

**前置验证**：
- 确认 `TenantAdminController` 是否有 enable/disable 端点
- 确认禁用状态对登录的实际影响

**新增测试**（2-3 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | platform_admin 禁用租户 | `PUT /admin/tenants/{id}/disable` 或类似 | 200 |
| 2 | 禁用后该租户用户无法登录 | `POST /auth/login` | 401/403 |
| 3 | platform_admin 重新启用租户 | `PUT /admin/tenants/{id}/enable` 或类似 | 200 |

### Task 8: WorkerJourneyTest — GET /me

**新增测试**（2 个 @Test）：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | worker GET /me 返回正确信息 | `GET /me` | 200, role=WORKER |
| 2 | worker PUT /me 更新名称 | `PUT /me` | 待确认是否允许 |

### Task 9: 瓦片端点测试

**前置验证**：
- 确认 10 个瓦片端点的实际返回结构
- 区分 App 端（`TileAppController` 3 端点）和 Admin 端（`TileAdminController` 5 端点）权限

**新增测试**（5-7 个 @Test），追加到 `DashboardMeJourneyTest` 或新建 `TileJourneyTest`：

| # | 测试 | 端点 | 预期 |
|---|------|------|------|
| 1 | owner 查看牧场瓦片状态 | `GET /farms/{farmId}/tile-status` | 200 |
| 2 | owner 查看瓦片源 | `GET /farms/{farmId}/tile-source` | 200 |
| 3 | owner 查看离线地图信息 | `GET /farms/{farmId}/offline-map` | 200 |
| 4 | platform_admin 查看瓦片管理状态 | `GET /admin/tiles/status` | 200 |
| 5 | platform_admin 查看区域列表 | `GET /admin/tiles/regions` | 200 |
| 6 | platform_admin 查看生成任务 | `GET /admin/tiles/tasks` | 200 |
| 7 | worker 不能访问瓦片管理 | `GET /admin/tiles/regions` | 403 |

---

## 6. Phase 4：断言质量修复

### Task 10: 全量断言清理

**修复规则**：

| 当前模式 | 修复方式 |
|---------|---------|
| `isIn(403, 401)` | 确认实际返回码，改为确定值。403 和 401 语义不同，不可混用 |
| `isIn(200, 201)` | 确认端点实际返回，改为确定值 |
| `isIn(200, 204)` | 同上 |
| `isBetween(200, 500)` | 确认实际成功码，改为确定值 |
| `if (resp != 200) return` | 改为确定值断言。如该角色确认无权限，改为断言 403 |

**不改的**：
- 登录失败场景中 `isIn(400, 401)`（空密码可能触发不同验证层，400 和 401 都合理）
- 已有的确定值断言

**执行方式**：
1. 扫描全部 10 个测试文件，定位所有模糊断言（约 25 处）
2. 逐处用代码阅读确认 API 实际行为
3. 改为确定值断言
4. 运行 `./gradlew test` 确认全部通过

---

## 7. 交付物总览

| Phase | Task | 新增 @Test | 修改处 | 依赖 |
|-------|------|-----------|--------|------|
| 1 | 权限矛盾确认 | 0 | 0 或 1（修正测试/文档） | 无 |
| 2 | Task 1: b2b_admin 牧场 | 3-4 | 0 | Phase 1 |
| 2 | Task 2: 牧工管理 | 3-5 | 0 | 前置验证 |
| 2 | Task 3: API 授权审批 | 2-3 | 0 | 前置验证 |
| 3 | Task 4: 围栏编辑 | 2-3 | 0 | 前置验证 |
| 3 | Task 5: 健康预警 | 1-2 | 0 | 前置验证 |
| 3 | Task 6: 订阅升级 | 2-3 | 0 | 前置验证 |
| 3 | Task 7: 租户启停 | 2-3 | 0 | 前置验证 |
| 3 | Task 8: worker GET /me | 2 | 0 | 无 |
| 3 | Task 9: 瓦片端点 | 5-7 | 0 | 前置验证 |
| 4 | Task 10: 断言清理 | 0 | ~25 | 无（可并行） |
| **合计** | | **~25-35** | **~25** | |

**预期覆盖度**：65% → ~80%

## 8. 风险与降级

| 风险 | 应对 |
|------|------|
| 前置验证发现端点未实现 | 记录为缺口，跳过该 Task，不写 stub 测试 |
| 前置验证发现 API 行为与文档不一致 | 以实际实现为准写断言，标注文档需更新 |
| 牧工管理后端完全未实现 | Task 2 整体跳过，记录为 Phase 2b 待实现 |
| 测试因数据状态失败 | 确保 `@DirtiesContext` 或在测试内创建独立数据 |
