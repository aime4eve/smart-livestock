# 离线地图后端实施计划 — 评审报告

> **评审对象**: [2026-05-27-offline-map-backend-plan.md](../plans/2026-05-27-offline-map-backend-plan.md)
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **评审日期**: 2026-05-27

---

## 总结

计划覆盖了规格文档 §3-§6 的核心内容，10 个 Task 拆分粒度合理，依赖顺序正确。代码示例详尽，测试步骤完整，Self-Review 覆盖率矩阵有助于验收。但存在 **3 个 P0 问题**（Flyway 版本跳跃、JPA 适配器命名/结构不匹配现有代码模式、EntityBase 不存在）和 **5 个 P1 问题**（覆盖率阈值逻辑退化、SecurityConfig 过滤器顺序与规格矛盾、TileController 重构无具体步骤、FarmApplicationService 新依赖注入缺失、ErrorCode 命名冲突），需要在执行前修正。

**结论**: 修正 P0 + P1 后可开始执行。

---

## P0 — 必须修正

### 1. Flyway 迁移版本号跳跃

**现状**: 代码库最新迁移为 `V9__seed_ranch_data.sql`（`smart-livestock-server/src/main/resources/db/migration/` 目录下）。

**问题**: 计划使用 `V15__create_tile_tables_and_fence_version.sql`，中间跳过了 V10-V14。Flyway 要求版本号严格递增，如果存在缺失的中间版本号，Flyway 不会报错但会导致混乱——后续其他开发者可能使用 V10-V14，造成冲突。

**建议**: 改为 `V10__create_tile_tables_and_fence_version.sql`（即当前最大版本号 +1）。在计划中注明"执行前确认无其他 V10 迁移已存在"。

### 2. JPA 适配器命名与结构不匹配现有代码模式

**现状**: 代码库中 Fence 的 JPA 适配器采用 4 文件模式：

```
ranch/infrastructure/persistence/
├── entity/FenceJpaEntity.java          ← @Entity
├── SpringDataFenceRepository.java      ← Spring Data JpaRepository 接口
├── mapper/FenceMapper.java             ← toDomain() / toJpaEntity() / updateEntity()
└── JpaFenceRepositoryImpl.java         ← 实现 domain repository 接口
```

**问题**: 计划 File Structure 和 Task 2 Step 5 采用 3 文件模式：

```
JpaTileRegion.java              ← 应为 entity/TileRegionJpaEntity.java
TileRegionJpaRepository.java    ← 应为 SpringDataTileRegionRepository.java
TileRegionRepositoryImpl.java   ← OK，但缺少 Mapper
```

- `JpaTileRegion.java` 放在 `infrastructure/persistence/` 根目录，不符合现有 `entity/` 子目录约定
- 缺少 `mapper/TileRegionMapper.java`，计划中 `toDomain()` / `fromDomain()` 方法直接写在 Entity 上，不符合现有分离模式
- 代码中 `findIntersecting` JPQL 查询写在 `TileRegionJpaRepository` 上，但现有模式是复杂查询写在 Spring Data 接口、由 RepositoryImpl 委托调用

**建议**:
- 重命名为 `entity/TileRegionJpaEntity.java`，与 `FenceJpaEntity.java` 风格一致
- 创建 `mapper/TileRegionMapper.java`，包含 `toDomain()` / `toJpaEntity()` / `updateEntity()` 静态方法
- Spring Data 接口命名为 `SpringDataTileRegionRepository.java`
- 对 TileGenerationTask、FarmTileTask、TileDownloadLog、ApiKey 四个实体同样调整
- 更新 File Structure 章节中的路径列表

### 3. EntityBase 类不存在

**问题**: Task 2 Step 3 说"Both extend `EntityBase` (not AggregateRoot — these are not aggregate roots)"，但代码库中只有：

```java
// shared/domain/Entity.java
public abstract class Entity {
    private Long id;
    // getId(), setId(), equals(), hashCode()
}

// shared/domain/AggregateRoot.java
public abstract class AggregateRoot extends Entity {
    private final List<DomainEvent> domainEvents = new ArrayList<>();
    // ...
}
```

不存在 `EntityBase`。FarmTileTask 和 TileDownloadLog 应继承 `Entity`（不是 AggregateRoot，判断正确），但类名写错了。

**建议**: 将 `EntityBase` 全部改为 `Entity`。

---

## P1 — 应当修正

### 4. 覆盖率阈值逻辑从 3 级退化为 2 级

**规格 §3.4 和 §5.2 定义**:

| 覆盖率 | 处理策略 |
|--------|---------|
| ≥ 50% | 正常匹配 tile_regions，直接下载 |
| 30%-50% | 正常匹配 + 显示覆盖率警告 |
| < 30% | 创建 tile_generation_tasks (is_custom_region=true) |

**计划 Task 6 Step 2 实现**:

```
If no match or coverageRatio < 0.3 → create generation task
Otherwise → create farm_tile_task(status=ready)
```

**问题**: 30%-50% 警告区间被合并到"正常匹配"中，丢失了以下规格要求：
- 管理员 UI 显示"覆盖率较低"警告
- 客户端显示警告提示
- 管理员可选择继续或创建自定义区域

**建议**: TileAdminService.handleFarmTileDetection() 应实现完整三级分支：

```java
if (coverageRatio >= 0.5) {
    // 正常匹配 → status=ready
} else if (coverageRatio >= 0.3) {
    // 匹配 → status=ready，但 FarmTileStatusDto 增加 coverageWarning=true
    // 管理员可通过 POST /admin/tiles/tasks 手动创建自定义区域
} else {
    // < 30% → 创建 tile_generation_tasks + farm_tile_tasks(status=pending)
}
```

FarmTileStatusDto 应增加 `coverageRatio` 和 `coverageWarning` 字段。

### 5. SecurityConfig 过滤器顺序与规格矛盾

**规格 §4.1**: "新增 ApiKeyAuthFilter，在 JWT filter **之后**检查 X-API-Key header"

**计划 Task 4 Step 5**: `.addFilterBefore(apiKeyAuthFilter, JwtAuthenticationFilter.class)` — 放在 JWT filter **之前**

**影响**: 虽然 Step 4 说了"Only runs if no existing auth"，使得两种顺序功能上都能工作，但：
- 放在 JWT 之前意味着每个请求都先经过 API Key 检查逻辑（即使没有 X-API-Key header 也会执行 filter 逻辑判断），增加不必要的开销
- 与规格文档矛盾，后续维护时容易困惑

**建议**: 改用 `addFilterAfter(apiKeyAuthFilter, JwtAuthenticationFilter.class)` 或等价方式，使 ApiKeyAuthFilter 位于 JWT filter 之后。同时在 filter 中检查 `SecurityContextHolder.getContext().getAuthentication() != null` 时直接返回。

### 6. TileController.java 重构无具体步骤

**现状**: File Structure 修改表列出 `TileController.java — Refactor to use tile_region DB instead of file scanning`。Task 6 Step 4 仅有一句话："Modify: ranch/interfaces/TileController.java (simplify to delegate to DB)"。

**问题**: 现有 TileController 有明确的业务逻辑：
- 从 `/data/mbtiles/regions.json` 文件读取区域列表
- 用农场中心点匹配区域（单点匹配，非 bbox 交集）
- 文件系统扫描 MBTiles 状态
- 文件下载（`/farms/{farmId}/offline-map`）

重构需要：
- 替换 `regions.json` 文件读取为 `TileAdminService` 查询
- 替换单点匹配为 bbox 交集匹配
- 替换文件系统状态扫描为 DB 查询
- 保留文件下载端点但改为从 DB 获取文件路径
- 新增的 TileAppController 和 TileAdminController 的端点可能与现有端点路径冲突

**建议**: 增加一个完整的 Task（或扩展 Task 6），包含：
1. TileController 重构的具体代码变更
2. 明确哪些端点迁移到 TileAdminController / TileAppController
3. 现有端点 (`/admin/tiles/status`, `/farms/{farmId}/offline-map`) 的去留决策
4. 路径冲突检查（TileAppController 的 `/api/v1/farms/{farmId}/tile-status` vs 现有 FarmController 的路径）

### 7. FarmApplicationService 新依赖注入缺失

**现状**: FarmApplicationService 通过 `@RequiredArgsConstructor` 注入 4 个依赖：

```java
private final FarmRepository farmRepository;
private final TenantRepository tenantRepository;
private final UserRepository userRepository;
private final UserFarmAssignmentRepository assignmentRepository;
```

**问题**: Task 7 在 `createFarm()` 中增加了：
- 创建边界围栏 → 需要注入 `FenceApplicationService`（或 `FenceRepository`）
- 调用 `handleFarmTileDetection()` → 需要注入 `TileAdminService`（或 `TileCoverageCalculator`）
- 创建 Farm 时接收 `boundaryVertices` → 需要修改 `CreateFarmCommand` record

计划 Step 3 展示了 `createFarm()` 的修改代码，但没有：
- 列出需要注入的新依赖
- 说明如何处理构造函数变化对现有测试的影响
- 说明循环依赖风险（如果 FenceApplicationService 和 FarmApplicationService 互相依赖）

**建议**:
- 明确注入 `FenceApplicationService`（或直接注入 `FenceRepository` 避免循环依赖）和 `TileAdminService`
- 检查是否存在循环依赖，如有，考虑引入 `ApplicationEventPublisher` 解耦（创建完成后发事件，TileAdminService 监听）
- 更新 FarmApplicationServiceTest 以 mock 新依赖

### 8. ErrorCode 命名需确认

**计划 Task 1 Step 5**: `throw new ApiException(ErrorCode.CONFLICT, ...)`，并说"Add `ErrorCode.CONFLICT(409, "CONFLICT", "版本冲突")` to the ErrorCode enum"。

**问题**: ErrorCode 枚举中已有 `STATE_CONFLICT` 和 `FARM_SCOPE_CONFLICT`，但不是 `CONFLICT`。且 ErrorCode 是简单枚举（无构造参数），不是计划暗示的带 `(int, String, String)` 的枚举。

实际 ErrorCode 定义：
```java
public enum ErrorCode {
    OK, VALIDATION_ERROR, BAD_REQUEST, AUTH_TOKEN_EXPIRED, ...
    STATE_CONFLICT, FARM_SCOPE_CONFLICT, ...
    INTERNAL_ERROR
}
```

**建议**:
- 使用现有 `STATE_CONFLICT` 而非新增 `CONFLICT`，保持一致
- 如果确需新增，确保了解项目中 ApiException 如何将 ErrorCode 映射到 HTTP 状态码（是否有 `@EnumValue` 或 switch 映射）
- FenceDto 的 409 响应体格式需要与规格 §5.3 一致（含 `serverVersion`, `serverVertices`, `lastModifiedBy`, `lastModifiedAt`），计划中的异常只抛了 message，没有返回这些扩展字段

---

## P2 — 建议改进

### 9. ApiKeyAdminController keyId 类型变更的向后兼容性

**现状**: `@PathVariable String keyId` 用于 DELETE 和 PUT status 端点。

**计划 Task 5**: 改为 `@PathVariable Long keyId`。

**影响**: 如果已有前端（platform_admin UI）调用这些端点时传字符串 ID，会 404。

**建议**: 在 Task 5 中注明这是 Breaking Change，确认前端尚未对接或同步更新前端。也可以先保留 String 类型，在 Service 层转换。

### 10. import_mbtiles.sh POST /admin/tiles/regions 的幂等性

**问题**: 脚本使用 `POST /admin/tiles/regions` 创建 region，但重复导入相同 MBTiles 文件时，`name` 的 UNIQUE 约束会报错。

**建议**: TileAdminController 的 `POST /regions` 端点应实现 upsert 语义（`INSERT ... ON CONFLICT (name) DO UPDATE SET ...`），或在脚本中先 DELETE 再 POST。计划 Task 6 Step 3 应明确说明此端点的幂等行为。

### 11. 规格中的 Analytics 端点未覆盖

**规格 §9.2**: 需要 `POST /api/v1/analytics/events` 端点 + `analytics_events` 表。

**计划**: Self-Review 的 Spec Coverage 表中没有提及 §9，也没有在 Deferred 列表中说明。

**建议**: 在 Self-Review 中增加一行说明 §9 可观测性 deferred 到后续 Plan（Flutter 客户端需要此端点才能上报事件）。

### 12. Tooling 脚本的错误处理

**import_mbtiles.sh**: `bounds=$(python3 -c ...)` 如果 MBTiles 文件没有 `bounds` metadata（不是所有 MBTiles 都有），`IFS=',' read` 会得到空值，`curl` 的 JSON body 中 `$min_lon` 等变量为空，导致 API 返回 400。

**建议**: 在 `[ -z "$bounds" ] && continue` 之前增加 bounds 格式验证（确保包含 4 个逗号分隔的数字），并增加 curl 失败时的重试逻辑。

### 13. FenceVersionTest 与 FenceApplicationService 构造函数

**计划 Task 1 Step 7**: `new FenceApplicationService(fenceRepository)` — 当前 `FenceApplicationService` 使用 `@RequiredArgsConstructor` 只有 `fenceRepository` 一个依赖，所以测试构造可以工作。

**注意**: Task 1 Step 5 增加了 `forceUpdateFence` 方法但未引入新依赖，所以构造函数不变。但如果后续 Task 向 FenceApplicationService 添加了新依赖（如事件发布器），此测试需要更新。建议在 Task 1 中加一条注释说明此假设。

---

## 规格覆盖度检查

| 规格章节 | 计划对应 | 状态 |
|---------|---------|------|
| §3.1 4 张新表 | Task 1 | ✅ 完整，含索引 |
| §3.2 Fence version + fence_type | Task 1 | ✅ 含乐观锁 |
| §3.3 bbox 交集匹配 | Task 6 | ✅ TileRegion.intersectsBbox |
| §3.4 覆盖率阈值 | Task 3 + 6 | ⚠️ 三级退化为二级（见 P1-4）|
| §4.1 API Key 认证 | Task 4 + 5 | ✅ SHA-256 + Filter + CRUD |
| §4.2 API Key 管理 UI | Self-Review 标注 Deferred | ✅ 合理延期 |
| §5.1 瓦片管理 API (9 个) | Task 6 | ✅ 覆盖全部 |
| §5.2 Farm 创建瓦片检测 | Task 7 | ⚠️ 依赖注入未说明（见 P1-7）|
| §5.3 围栏更新 409 | Task 1 | ⚠️ 409 响应体缺少扩展字段（见 P2-8）|
| §6.1 generate_mbtiles.py | Task 8 | ✅ 完整 |
| §6.2 import_mbtiles.sh | Task 9 | ✅ 基本完整 |
| §7 Flutter 离线瓦片 | 未覆盖 | ✅ 计划明确仅覆盖 Backend + Tooling |
| §8 Flutter 离线围栏 | 未覆盖 | ✅ 同上 |
| §9 可观测性 | 未覆盖 | ⚠️ Self-Review 未提及（见 P2-11）|

---

## 代码质量

**优点**:
- SQL 迁移使用 `IF NOT EXISTS` 防御重复执行
- 测试用例覆盖正常/异常/边界场景（如 `expectedVersion=null` 跳过检查）
- Tooling 优先使用环境变量传 API Key，避免 `ps aux` 泄露
- coverageRatio 的 Shoelace 公式实现简洁正确
- Task 2 Step 5 的 `findIntersecting` JPQL 正确表达了 bbox 交集

**待改进**:
- Task 2 Step 2 的 TileGenerationTask 只有注释 `// Getters/setters for all fields (same pattern as TileRegion)...`，应给出完整代码或明确"参照 TileRegion 模式生成"
- Task 6 Step 2 的 TileAdminService 描述为自然语言，缺少方法签名和核心逻辑的代码示例（如 handleFarmTileDetection 的分支逻辑）
- import_mbtiles.sh 中 `stat -f%z`（macOS）在 Linux 服务器上不适用，虽有 fallback 但注释应注明目标平台

---

## 修正优先级汇总

| 优先级 | 编号 | 问题 | 修正工作量 |
|--------|------|------|-----------|
| P0 | 1 | Flyway 版本号 V15 → V10 | 小 |
| P0 | 2 | JPA 适配器 3 文件 → 4 文件模式 | 中 |
| P0 | 3 | EntityBase → Entity | 小 |
| P1 | 4 | 覆盖率 2 级 → 3 级 | 小 |
| P1 | 5 | 过滤器顺序 before → after | 小 |
| P1 | 6 | TileController 重构补充具体步骤 | 中 |
| P1 | 7 | FarmApplicationService 依赖注入 | 小 |
| P1 | 8 | ErrorCode 命名 + 409 响应体扩展 | 小 |
| P2 | 9-13 | 向后兼容、幂等性、Analytics 等 | 各小 |

---

*评审完成: 2026-05-27*
