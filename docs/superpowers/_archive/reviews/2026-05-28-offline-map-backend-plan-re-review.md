# 离线地图后端实施计划 — 复审报告（第二次）

> **评审对象**: [2026-05-27-offline-map-backend-plan.md](../plans/2026-05-27-offline-map-backend-plan.md)（修正后版本）
> **关联规格**: [2026-05-27-offline-map-fence-integration-design.md](../specs/2026-05-27-offline-map-fence-integration-design.md)
> **评审日期**: 2026-05-28
> **上次评审**: [2026-05-27-offline-map-backend-plan-review.md](2026-05-27-offline-map-backend-plan-review.md)

---

## 修正验证总表

| # | 原问题 | 优先级 | 修正状态 | 验证说明 |
|---|--------|--------|---------|---------|
| 1 | Flyway 版本号 V15 跳跃 | P0 | ✅ 已修正 | 改为 V13，当前最新迁移为 V12，V13 为下一个正确编号。标注"执行前确认无其他 V13 迁移已存在" |
| 2 | JPA 适配器 3 文件→4 文件模式 | P0 | ✅ 已修正 | File Structure 和 Task 2 Step 5 均改为 `entity/XxxJpaEntity.java` + `SpringDataXxxRepository.java` + `mapper/XxxMapper.java` + `XxxRepositoryImpl.java` 四文件模式，与 Fence 适配器一致 |
| 3 | EntityBase 不存在 | P0 | ✅ 已修正 | 改为 `extends Entity`，注明使用 `com.smartlivestock.shared.domain.Entity` |
| 4 | 覆盖率阈值 3 级→2 级 | P1 | ✅ 已修正 | Task 6 Step 2 恢复完整三级分支（≥50% / 30%-50% / <30%），`FarmTileStatusDto` 增加 `coverageRatio` + `coverageWarning` 字段 |
| 5 | 过滤器顺序 before→after | P1 | ✅ 已修正 | 改为 `addFilterAfter(apiKeyAuthFilter, JwtAuthenticationFilter.class)`，Modified Files 表明确标注 "after JWT filter" |
| 6 | TileController 重构缺具体步骤 | P1 | ✅ 已修正 | Task 6 新增 Step 5，包含 6 项具体重构说明（regions.json→DB、单点→bbox、文件扫描→DB、文件下载路径、端点迁移决策、路径冲突检查） |
| 7 | FarmApplicationService 依赖注入 | P1 | ✅ 已修正 | Task 7 Step 2 明确列出 3 个新依赖（`FenceRepository`、`TileAdminService`、`TileCoverageCalculator`），分析了循环依赖风险，注明测试需 mock 新依赖 |
| 8 | ErrorCode 命名 | P1 | ✅ 已修正 | 使用现有 `STATE_CONFLICT`，注明项目使用简单枚举无构造参数 |

**8/8 原有问题全部修正。**

---

## 复审发现的新问题

### P1 — 应当修正

#### 9. 409 响应体缺少扩展字段的实际实现路径

**规格 §5.3 要求**：409 Conflict 响应体包含：

```json
{
  "serverVersion": 3,
  "serverVertices": [...],
  "lastModifiedBy": "张三 (worker)",
  "lastModifiedAt": "2026-05-27T14:30:00Z"
}
```

**计划现状**：Task 1 Step 5 用注释描述了期望的 409 响应体格式，但 **没有可执行的步骤来实现它**。注释说 "The FenceController should catch STATE_CONFLICT and return 409 with body..."，但 Step 6（FenceController 更新）没有实现这个 catch 逻辑。

**根本原因**：现有异常处理框架不支持带 data 的错误响应：

- `ApiException` 只有 `(ErrorCode, String message)` 构造函数，无 data 字段
- `GlobalExceptionHandler.handleApiException()` 调用 `ApiResponse.error(code, message, requestId)` — data 始终为 null
- Fence 实体无 `updatedBy` 字段（`FenceJpaEntity` 有 `updatedAt` 但无 `updatedBy`）

**建议**：在 Task 1 中增加一个可执行步骤，选择以下方案之一：

**方案 A（推荐）**：扩展 ApiException 支持 data：

```java
// ApiException 增加构造函数
public ApiException(ErrorCode code, String message, Object data) {
    super(message);
    this.code = code;
    this.data = data;
}

// GlobalExceptionHandler 中增加 data 的传递
```

**方案 B**：FenceController 中直接 try-catch，不经过 GlobalExceptionHandler：

```java
try {
    FenceDto result = fenceApplicationService.updateFence(id, command);
    return ResponseEntity.ok(ApiResponse.ok(result));
} catch (ApiException e) {
    if (e.getCode() == ErrorCode.STATE_CONFLICT) {
        Fence current = fenceRepository.findById(id).orElseThrow();
        Map<String, Object> conflictData = Map.of(
            "serverVersion", current.getVersion(),
            "serverVertices", current.getVertices(),
            "lastModifiedAt", current.getUpdatedAt()
        );
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(ApiResponse.error(ErrorCode.STATE_CONFLICT, e.getMessage(), conflictData));
    }
    throw e;
}
```

同时需要决定 `lastModifiedBy` 字段的处理方式：当前 Fence 无审计字段记录修改者。可以：
- 暂时不返回 `lastModifiedBy`（在 response body 中省略或返回 null）
- 或在 V13 迁移中给 fences 表增加 `updated_by` 列

### P2 — 建议改进

#### 10. §9 可观测性仍未在 Self-Review 中提及

规格 §9 定义了可观测性（客户端埋点 + `POST /api/v1/analytics/events` 端点 + analytics_events 表 + 运维看板指标）。上次评审已指出（P2-11），修正后 Self-Review 的 Spec Coverage 表仍无 §9 条目。

**建议**：在 Self-Review 表末尾增加一行：

```
| §9 可观测性 | 未覆盖（deferred 到 Flutter 客户端 Plan） |
```

这样后续执行者不会遗忘。

#### 11. TileAdminController POST /regions 的 upsert 语义未明确实现方式

Task 6 Step 3 写了 `POST /regions → upsert region`，但未说明 upsert 的实现方式（`INSERT ... ON CONFLICT DO UPDATE`、先查后存、还是 `save()` 依赖 JPA merge）。import_mbtiles.sh 重复导入同一文件时 UNIQUE(name) 约束会导致普通 INSERT 失败。

**建议**：在 Task 6 Step 3 中补充说明，例如 "使用 `findByName()` 查询，存在则更新否则新建" 或 "使用 JPA merge + UNIQUE 约束的 DataIntegrityViolationException 处理"。

#### 12. TileGenerationTask getter/setter 仍为省略形式

Task 2 Step 2 的 `TileGenerationTask.java` 末尾仍为 `// Getters/setters for all fields (same pattern as TileRegion)...`，而 TileRegion 给出了完整 getter/setter。执行时 agent 可能遗漏字段。

**建议**：给出完整代码，或改为 `// 以下省略，参照 TileRegion 的 getter/setter 模式为每个字段生成`，更显式。

---

## 规格覆盖度检查（更新）

| 规格章节 | 计划对应 | 状态 |
|---------|---------|------|
| §3.1 4 张新表 | Task 1 | ✅ |
| §3.2 Fence version + fence_type | Task 1 | ✅ |
| §3.3 bbox 交集匹配 | Task 6 | ✅ |
| §3.4 覆盖率阈值（3 级） | Task 3 + 6 | ✅ 已恢复完整 3 级 |
| §4.1 API Key 认证 | Task 4 + 5 | ✅ |
| §4.2 API Key 管理 UI | Deferred | ✅ 合理 |
| §5.1 瓦片管理 API (9 个) | Task 6 | ✅ |
| §5.2 Farm 创建瓦片检测 | Task 7 | ✅ 依赖注入已补全 |
| §5.3 围栏更新 409 | Task 1 | ⚠️ ErrorCode 修正 ✅，但 409 响应体扩展字段无实际实现步骤（见新 P1-9）|
| §6.1 generate_mbtiles.py | Task 8 | ✅ |
| §6.2 import_mbtiles.sh | Task 9 | ✅ |
| §7-8 Flutter | 未覆盖 | ✅ 计划范围明确 |
| §9 可观测性 | 未覆盖 | ⚠️ Self-Review 未提及（见 P2-10）|

---

## 结论

上次评审的 8 个问题（3 P0 + 5 P1）已全部修正，修正质量高。复审新发现 **1 个 P1**（409 响应体扩展字段缺实现路径）和 **3 个 P2**。建议补充 P1 的实现步骤后即可开始执行。

---

*复审完成: 2026-05-28*
