# Plan A 代码质量评审报告

**日期**: 2026-05-28
**范围**: Plan A (Backend + Tooling) 已落地代码 — 3 个提交 `b089793`, `476070a`, `d46673a`
**评审方式**: 3 个专业 agent 并行评审（Java 代码、安全/认证、Tooling + 测试）
**关联 Plan**: `docs/superpowers/plans/2026-05-27-offline-map-backend-plan.md`
**关联 Spec**: `docs/superpowers/specs/2026-05-27-offline-map-fence-integration-design.md`

---

## 评审结论

**状态: 阻断 — 发现 10 个严重问题、10 个高优先级问题，必须在合并前修复。**

严重问题集中在两个方面：
1. **安全缺陷**（5 个）：admin 端点无权限、API Key filter 静默放行、Open API permitAll、授权空实现、tenantId 硬编码
2. **数据正确性**（3 个）：乐观锁形同虚设、UNIQUE 约束违反、分支逻辑错误

---

## 严重问题（10 个）

### S1. Fence 乐观锁仅在 Java 层检查，数据库层无强制执行

**文件**: `ranch/infrastructure/persistence/entity/FenceJpaEntity.java`

`version` 字段缺少 `@Version` 注解。当前 `FenceApplicationService.updateFence()` 先 `findById` 加载，Java 层比较 `expectedVersion`，然后手动 `setVersion(getVersion() + 1)`，最后 `save()`。

JPA `save()` 生成的 SQL 是 `UPDATE fences SET ... WHERE id = ?`，**WHERE 子句不包含 version 条件**。两个并发请求都通过 Java 层检查后都能成功写入，后写覆盖前写，数据丢失。

**影响**: 多客户端同时编辑围栏时静默丢失更新，乐观锁机制形同虚设。

**修复**:

```java
// FenceJpaEntity.java
@Version
private int version;

// 同时删除 FenceApplicationService 中的手动 setVersion()
// 和 FenceMapper.updateEntity() 中的 version 赋值
```

JPA 会自动在 UPDATE 的 WHERE 中加入 `AND version = ?`，并发冲突时抛 `OptimisticLockException`，转为 409 响应。

---

### S2. `handleFarmTileDetection` 分支逻辑错误

**文件**: `ranch/application/TileAdminService.java` 第 89-100 行

```java
boolean coverageWarning = coverageRatio >= 0.3 && coverageRatio < 0.5;

if (intersecting.isEmpty() || coverageRatio < 0.3) {
    // 创建 custom generation task
    ...
    return new FarmTileStatusDto(farmId, regions, coverageRatio, coverageRatio < 0.3);
}
```

三个问题：

1. **`coverageWarning` 永远不被使用** — 当 `coverageRatio` 在 0.3-0.5 之间且 `intersecting` 为空时，`coverageWarning=true` 但被 early return 丢弃
2. **有交叉区域 + 低覆盖率时丢弃已有匹配** — `intersecting` 非空但 `coverageRatio < 0.3` 时，走入创建自定义任务分支，已有的交叉区域信息被忽略。Spec 要求：仍应为交叉区域创建 farm_tile_task，同时创建自定义生成任务
3. **`needsGeneration` 标志语义不清** — `coverageRatio < 0.3` 作为 needsGeneration，但当 `intersecting.isEmpty() && coverageRatio >= 0.3` 时为 false，但确实需要生成

**修复**: 按Spec §3.4 重新实现分支逻辑：

```
覆盖率 ≥ 50%: 匹配 tile_regions → 创建 farm_tile_tasks(status=ready)
覆盖率 30%-50%: 匹配 + 创建 farm_tile_tasks + coverageWarning=true
覆盖率 < 30%: 不匹配现有 tile_regions，创建 tile_generation_tasks(is_custom_region=true)
无交叉区域: 创建 tile_generation_tasks
```

---

### S3. `handleFarmTileDetection` 每次调用都创建 FarmTileTask，违反 UNIQUE 约束

**文件**: `ranch/application/TileAdminService.java` 第 102-107 行

```java
for (TileRegion region : intersecting) {
    FarmTileTask farmTask = new FarmTileTask(farmId, region.getId());
    farmTileTaskRepository.save(farmTask);
}
```

`farm_tile_tasks` 表有 `UNIQUE(farm_id, region_id)` 约束，但代码每次调用直接 `new` + `save`，未检查是否已存在。第二次调用同一 farm+region 组合时抛 `DataIntegrityViolationException`。

Repository 接口已有 `findByFarmIdAndRegionId()` 方法但未被使用。

**修复**:

```java
for (TileRegion region : intersecting) {
    if (farmTileTaskRepository.findByFarmIdAndRegionId(farmId, region.getId()).isEmpty()) {
        FarmTileTask farmTask = new FarmTileTask(farmId, region.getId());
        farmTask.setStatus("ready".equals(region.getStatus()) ? "ready" : "pending");
        farmTileTaskRepository.save(farmTask);
    }
}
```

---

### S4. `/api/v1/open/**` 配置 `permitAll()` 绕过认证

**文件**: `shared/security/SecurityConfig.java` 第 46-49 行

```java
.requestMatchers("/api/v1/open/**", "/health").permitAll()
```

Spring Security 对 `permitAll()` 路径不强制认证。虽然 Open Controller 内部手动调用 `apiKeyAuthService.requireApiKey(request)`，但如果任何 Controller 忘记调用，该端点完全无认证暴露。

**修复**: 将 Open API 改为 `.authenticated()`，让 `ApiKeyAuthFilter` 成为统一认证入口。

---

### S5. ApiKeyAuthFilter Key 无效时静默放行

**文件**: `shared/security/ApiKeyAuthFilter.java` 第 46-49 行

```java
} catch (Exception e) {
    filterChain.doFilter(request, response);
    return;
}
```

当 `X-API-Key` header 存在但验证失败（key 无效/已吊销/hash 不匹配），filter 捕获异常后静默放行，不返回 401。结合 S4（Open API permitAll），无效 Key 的请求可完全放行。

**修复**: 区分"无 API Key header"（放行，交给后续认证）和"有 header 但无效"（拒绝）：

```java
if (apiKey != null && !apiKey.isBlank()) {
    if (SecurityContextHolder.getContext().getAuthentication() == null) {
        try {
            ApiKey validatedKey = apiKeyService.validateApiKey(apiKey.trim());
            // ... 设置 auth
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":\"AUTH_API_KEY_INVALID\",\"message\":\"无效的 API Key\"}");
            return;
        }
    }
}
```

---

### S6. TileAdminController / TileAppController 无任何权限检查

**文件**: `ranch/interfaces/TileAdminController.java` 全文

`TileAdminController` 路径 `/api/v1/admin/tiles/` 是管理端点，但没有任何 `requirePlatformAdmin()` 或 Spring Security 注解。`SecurityConfig` 中该路径只要求 `authenticated()`，任何已认证用户（含 worker）可执行管理操作。

`TileAppController` 的 `/api/v1/farms/{farmId}/tile-*` 端点也未验证当前用户是否有权访问该 farmId。

**修复**: 在 SecurityConfig 中添加：

```java
.requestMatchers("/api/v1/admin/**").hasRole("PLATFORM_ADMIN")
```

或为每个方法添加 `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`。

---

### S7. OpenDeviceRegisterController.resolveTenantId() 硬编码 tenantId=1L

**文件**: `iot/interfaces/open/OpenDeviceRegisterController.java` 第 103-111 行

```java
private Long resolveTenantId(String apiKey) {
    if (apiKey != null && apiKey.startsWith("sl_test_")) return 1L;
    return 1L;
}
```

所有设备注册请求归入 tenantId=1L（Demo 租户），多租户隔离失效。

**修复**: 从 `ApiKey` 的 `tenantId` 字段解析，而非硬编码。

---

### S8. ApiKeyAuthService 授权检查是空实现

**文件**: `shared/security/ApiKeyAuthService.java` 第 35-41 行

```java
public void validateFarmAccess(String apiKey, Long farmId) { /* empty */ }
public void requireDeviceRegisterScope(String apiKey) { /* empty */ }
```

所有 Open API 端点调用了这两个方法，但都是空操作。任何持有有效 API Key 的用户可访问任何 farmId 的数据。

**修复**: 实现 key → tenantId → farm 归属检查和 scope 校验。

---

### S9. TileController.findMatchingMbtiles 吞掉所有异常

**文件**: `ranch/interfaces/TileController.java` 第 93 行

```java
} catch (Exception ignored) { }
```

regions.json 格式损坏、磁盘 I/O 错误、类型转换失败全部被忽略，客户端只收到 404，无法排查问题。

**修复**: 至少 `log.warn("Failed to read regions.json for farm {}", farm.getId(), e);`

---

### S10. import_mbtiles.sh 存在命令注入和 JSON 注入风险

**文件**: `tooling/import_mbtiles.sh` 第 78 行、第 86 行

1. 第 78 行：Python 单引号内嵌 `$meta` 变量，文件名含单引号时注入 Python 代码
2. 第 86 行：curl JSON body 中 `$base` 等变量直接拼接，文件名含双引号时破坏 JSON

**修复**: 用 `sys.argv` 传递文件名，用 Python 或 `jq` 构造 JSON：

```bash
# 安全的 MD5 读取
expected=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["md5"])' "$meta")

# 安全的 JSON 构造
payload=$(python3 -c 'import json,sys; print(json.dumps({"name":sys.argv[1],"minLon":float(sys.argv[2]),...}))' \
    "$base" "$min_lon" "$min_lat" "$max_lon" "$max_lat" "$base.mbtiles" "$size" "$md5hash")
```

---

## 高优先级问题（10 个）

### H1. `advanceFarmTileTasks` 全表扫描 + N+1

**文件**: `TileAdminService.java` 第 168-178 行

`farmTileTaskRepository.findAll().stream().filter()` 全表加载到内存再逐条 save。

**修复**: 在 `SpringDataFarmTileTaskRepository` 添加批量更新 query：

```java
@Modifying
@Query("UPDATE FarmTileTaskJpaEntity t SET t.status = 'ready', t.completedAt = NOW() WHERE t.regionId = :regionId AND t.status = 'pending'")
int markReadyByRegionId(@Param("regionId") Long regionId);
```

### H2. 5 个只读方法缺少 `@Transactional(readOnly = true)`

**文件**: `TileAdminService.java` — `listRegions()`, `listTasks()`, `getTask()`, `getFarmTileStatus()`, `getFarmTileSources()`

对比 `FenceApplicationService` 中同名方法都正确标记了。

### H3. 状态字段用裸字符串而非枚举

**涉及文件**: `TileRegion.java`, `TileGenerationTask.java`, `FarmTileTask.java`, `TileAdminService.java`

状态值 `"pending"`, `"ready"`, `"done"`, `"failed"`, `"running"` 全部用字符串字面量，无编译期检查。项目 Commerce 限界上下文已使用枚举（`SubscriptionStatus` 等），应保持一致。

### H4. FenceController 所有方法不验证 farmId 与 fenceId 的归属关系

**文件**: `ranch/interfaces/FenceController.java`

`farmId` 路径参数被接收但未使用。用户可用自己的 farmId + 他人的 fenceId 读取/修改/删除他人围栏。

### H5. TileAppController.logDownload() 接受客户端传入 userId

**文件**: `ranch/interfaces/TileAppController.java` 第 37-38 行

客户端自行上报 userId，服务端未验证是否为当前认证用户。

**修复**: 从 `SecurityContext` 提取 userId。

### H6. FarmApplicationService.createFarm 单事务跨两个限界上下文

**文件**: `identity/application/FarmApplicationService.java` 第 36-53 行

单个 `@Transactional` 同时操作 Identity（Farm）和 Ranch（Fence + Tile）。瓦片检测失败会回滚 Farm 创建，但 Farm 创建本身是有效的。

**修复**: 将瓦片检测逻辑放到事务提交后执行（`ApplicationEventPublisher` 或捕获异常仅记录日志）。

### H7. ApiKeyAuthFilter 未设置 TenantContext

**文件**: `shared/security/ApiKeyAuthFilter.java` 第 42-45 行

JWT 认证后 principal 是 userId 且设置了 `TenantContext`，但 API Key 认证后 principal 是 `apiKey.getId()`，未设置 `TenantContext`。依赖租户上下文的业务逻辑将失败。

### H8. ApiKeyAdminController.updateApiKeyStatus 状态转换逻辑不一致

**文件**: `identity/interfaces/admin/ApiKeyAdminController.java` 第 84-101 行

`status=active` 分支什么都不做但返回 `status=REVOKED`。没有"恢复已吊销 Key"的逻辑。

### H9. generate_mbtiles.py 不区分 401/403 和 5xx

**文件**: `tooling/generate_mbtiles.py`

`_api_call` 捕获 `HTTPError` 后统一处理，不区分认证失败（应立即退出）和服务端错误（可重试）。

### H10. import_mbtiles.sh 无 API Key 时 exit 0

**文件**: `tooling/import_mbtiles.sh` 第 69-70 行

CI/CD pipeline 会误认为 DB sync 成功，实际上被跳过了。

---

## 中等问题（15 个）

| # | 文件 | 问题 |
|---|------|------|
| M1 | 所有 Controller | `@RequestBody Map<String, Object>` 缺少输入验证，NPE/CCE 返回 500 而非 400 |
| M2 | `ApiKeyApplicationService.java:60-61` | 每次请求 UPDATE lastUsedAt，高频 API 下写瓶颈 |
| M3 | `TileRegionRepositoryImpl.java` | Mapper 始终 `new JpaEntity` + `setId`，更新时走 merge（SELECT + UPDATE） |
| M4 | `FarmController.java` / `FenceController.java` | `parseVertices()` 完全重复，应提取共享方法 |
| M5 | `TileController.java:23-24` | `/data/mbtiles` 硬编码，应使用 `@Value` 注入 |
| M6 | `TileController.java:59` | `findMatchingMbtiles` 返回值未做路径遍历检查 |
| M7 | `FenceApplicationService.java:66-76` | `forceUpdateFence` 无权限控制，绕过乐观锁 |
| M8 | `ApiKey.java` + `ApiKeyAdminController` | 状态用字符串且大小写不一致（`ACTIVE` vs `active`） |
| M9 | `TileCoverageCalculatorTest.java` | 缺边界测试（null vertices、空列表、阈值 0.3/0.5） |
| M10 | `TileAdminServiceTest.java` | 未测试 `updateTaskStatus`、`upsertRegion`、重复调用约束冲突 |
| M11 | `FenceApplicationService` | 无测试文件，乐观锁和版本冲突完全无测试覆盖 |
| M12 | `import_mbtiles.sh` | `stat`/`md5` macOS/Linux 兼容写法重复 3 次，应提取变量 |
| M13 | `generate_mbtiles.py` | sqlite3 连接未用 context manager，异常时可能泄漏 |
| M14 | `import_mbtiles.sh:48-49` | 内联 Python `except Exception: pass` 吞掉解析错误 |
| M15 | `ApiKeyApplicationServiceTest.java` | 仅 4 个测试，缺过期/吊销/null 参数等关键场景 |

---

## 修复优先级建议

### P0 — 必须立即修复（阻塞合并）

| 问题 | 工作量 | 说明 |
|------|--------|------|
| S1: Fence @Version | 0.5h | 加注解 + 删手动 setVersion |
| S3: FarmTileTask 去重 | 0.5h | 加 findByFarmIdAndRegionId 检查 |
| S4+S5: 安全 filter | 1h | Open API 改 authenticated + 无效 Key 返回 401 |
| S6: admin 权限 | 0.5h | SecurityConfig 加 hasRole |
| S9: 异常吞掉 | 0.2h | 加 log.warn |

### P1 — 本迭代内修复

| 问题 | 工作量 | 说明 |
|------|--------|------|
| S2: 分支逻辑重构 | 2h | 重写 handleFarmTileDetection |
| S7: tenantId 硬编码 | 1h | 从 ApiKey 解析 tenantId |
| S8: 授权空实现 | 2h | 实现 validateFarmAccess + requireScope |
| S10: shell 注入 | 1h | 改用 sys.argv + jq |
| H1: 全表扫描 | 0.5h | 加 batch update query |
| H4: farmId 归属检查 | 1h | 所有 fence 端点验证归属 |

### P2 — 下一迭代改进

H2-H3, H6-H10, M1-M15

---

## 已评审文件清单

| 文件 | 状态 |
|------|------|
| `V13__create_tile_tables_and_fence_version.sql` | ✅ 正确 |
| `Fence.java` | ⚠️ 缺 @Version 映射 |
| `FenceJpaEntity.java` | 🔴 缺 @Version |
| `FenceApplicationService.java` | 🔴 手动 setVersion，forceUpdate 无权限 |
| `FenceController.java` | 🔴 farmId 未验证归属 |
| `TileRegion.java` | ✅ 正确 |
| `TileGenerationTask.java` | ⚠️ 状态用字符串 |
| `FarmTileTask.java` | ⚠️ 状态用字符串 |
| `TileDownloadLog.java` | ✅ 正确 |
| `TileCoverageCalculator.java` | ✅ 正确 |
| `TileAdminService.java` | 🔴 分支逻辑 + 去重 + 全表扫描 + 缺 readOnly |
| `TileAdminController.java` | 🔴 无权限检查 |
| `TileAppController.java` | 🔴 userId 伪造 |
| `TileController.java` | 🔴 吞异常 + 硬编码路径 |
| `ApiKey.java` | ⚠️ 状态/角色用字符串 |
| `ApiKeyApplicationService.java` | ⚠️ lastUsedAt 写瓶颈 |
| `ApiKeyAuthFilter.java` | 🔴 静默放行 + 缺 TenantContext |
| `ApiKeyAdminController.java` | 🔴 状态转换 bug |
| `ApiKeyAuthService.java` | 🔴 授权空实现 |
| `SecurityConfig.java` | 🔴 Open API permitAll |
| `FarmApplicationService.java` | ⚠️ 跨限界上下文事务 |
| `generate_mbtiles.py` | ⚠️ 不区分 401/5xx |
| `import_mbtiles.sh` | 🔴 命令注入 + JSON 注入 |

---

*评审人: 3× AI Agent (java-reviewer, security-reviewer, python-reviewer)*
*生成时间: 2026-05-28*
