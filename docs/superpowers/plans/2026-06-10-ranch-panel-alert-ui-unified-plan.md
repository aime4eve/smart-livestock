# 牧场面板告警 UI 统一实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将告警系统从 4-state 处理流程重构为通知中心模型（已读/未读/自动解除/忽略），重写 Flutter 底部面板为四层钻取架构。

**Architecture:** 后端 7 个 Task（Spring Boot）+ 前端 12 个 Task（Flutter），按依赖顺序分三阶段执行。

**Tech Stack:** 后端 Spring Boot 3.3 + Java 17 + JTS 1.19 + Flyway；前端 Flutter 3.x / flutter_riverpod / flutter_map / fl_chart

**Spec:** `docs/superpowers/specs/2026-06-10-ranch-panel-alert-ui-design.md`

**前端参考（详细代码片段）:** `docs/superpowers/plans/2026-06-10-ranch-panel-alert-ui-frontend.md`

---

## 阶段一：后端基座（Task 1-7）

前端开发依赖后端 API 合约，后端先行。

### Task 1 — Flyway V26 迁移

**归属**：后端 `smart-livestock-server/`
**依赖**：无（当前迁移到 V25）
**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V26__alert_notification_model.sql`

**内容：**

```sql
-- 1. alert_read_status: per-user read tracking
CREATE TABLE alert_read_status (
    id            BIGSERIAL PRIMARY KEY,
    alert_id      BIGINT NOT NULL REFERENCES alerts(id),
    user_id       BIGINT NOT NULL REFERENCES users(id),
    read_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(alert_id, user_id)
);
CREATE INDEX idx_alert_read_user ON alert_read_status(user_id);
CREATE INDEX idx_alert_read_alert ON alert_read_status(alert_id);

-- 2. fence_zones: key monitoring areas inside fences
CREATE TABLE fence_zones (
    id            BIGSERIAL PRIMARY KEY,
    fence_id      BIGINT NOT NULL REFERENCES fences(id),
    farm_id       BIGINT NOT NULL,
    name          VARCHAR(100) NOT NULL,
    zone_type     VARCHAR(30) NOT NULL,
    vertices      JSONB NOT NULL,
    alert_radius  INTEGER DEFAULT 20,
    severity      VARCHAR(10) DEFAULT 'INFO',
    active        BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX idx_fence_zones_fence ON fence_zones(fence_id);
CREATE INDEX idx_fence_zones_farm ON fence_zones(farm_id);

-- 3. alerts table extensions
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS resolved_type VARCHAR(20);
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE;

-- 4. fences table extensions
ALTER TABLE fences ADD COLUMN IF NOT EXISTS buffer_distance INTEGER DEFAULT 50;
ALTER TABLE fences ADD COLUMN IF NOT EXISTS buffer_polygon JSONB;

-- 5. Data migration: old 4-state → new 3-state
UPDATE alerts SET status = 'ACTIVE' WHERE status IN ('PENDING', 'ACKNOWLEDGED');
UPDATE alerts SET status = 'DISMISSED', resolved_type = 'MANUAL_DISMISS',
    resolved_at = COALESCE(handled_at, acknowledged_at, NOW())
    WHERE status = 'HANDLED';
UPDATE alerts SET status = 'AUTO_RESOLVED', resolved_type = 'AUTO',
    resolved_at = COALESCE(handled_at, acknowledged_at, NOW())
    WHERE status = 'ARCHIVED';

-- 6. Backfill alert_read_status from acknowledged_by
INSERT INTO alert_read_status (alert_id, user_id, read_at)
SELECT id, acknowledged_by, COALESCE(acknowledged_at, NOW())
FROM alerts WHERE acknowledged_by IS NOT NULL
ON CONFLICT DO NOTHING;

-- 7. Rename BEHAVIOR_ABNORMAL → DIGESTIVE_ABNORMAL
UPDATE alerts SET type = 'DIGESTIVE_ABNORMAL' WHERE type = 'BEHAVIOR_ABNORMAL';

-- NOTE: old columns (acknowledged_by, acknowledged_at, handled_by, handled_at) retained
-- for backward compatibility during frontend migration window.
```

**验证：** `./gradlew compileJava` + 部署后 `flyway info` 确认 V26 成功

- [ ] Step 1: Create V26 migration file
- [ ] Step 2: Run `./gradlew compileJava` to verify
- [ ] Step 3: Commit

---

### Task 2 — Alert 领域模型重构

**归属**：后端
**依赖**：Task 1

**Files:**
- Modify: `ranch/domain/model/AlertStatus.java` — 枚举改为 `{ACTIVE, DISMISSED, AUTO_RESOLVED}`
- Modify: `ranch/domain/model/AlertType.java` — 新增 `FENCE_APPROACH`, `ZONE_APPROACH`；重命名 `BEHAVIOR_ABNORMAL` → `DIGESTIVE_ABNORMAL`
- Modify: `ranch/domain/model/Alert.java` — 删除旧方法，新增 dismiss/autoResolve，新增 resolvedType/resolvedAt
- Modify: `ranch/infrastructure/persistence/entity/AlertJpaEntity.java` — 同步新字段
- Modify: `ranch/infrastructure/persistence/mapper/AlertMapper.java` — 映射新字段
- Modify: `ranch/application/dto/AlertDto.java` — 新增 read, resolvedType, resolvedAt, distance, direction
- Modify: `ranch/domain/repository/AlertRepository.java` — 新增查询方法
- Modify: `ranch/application/AlertApplicationService.java` — markRead/dismiss/autoResolve/batchRead
- Rewrite: `test/.../AlertTest.java` — 新状态机测试
- Update: `test/.../AlertApplicationServiceTest.java`

**关键变更：**

`AlertStatus` 枚举：
```java
public enum AlertStatus {
    ACTIVE,
    DISMISSED,
    AUTO_RESOLVED
}
```

`AlertType` 枚举：
```java
public enum AlertType {
    FENCE_BREACH,
    FENCE_APPROACH,    // 新增
    ZONE_APPROACH,     // 新增
    TEMPERATURE_ABNORMAL,
    DIGESTIVE_ABNORMAL, // 原 BEHAVIOR_ABNORMAL
    ESTRUS,
    EPIDEMIC
}
```

`Alert` 实体关键方法：
```java
// 删除: acknowledge(), handle(), archive()
// 删除字段: acknowledgedBy, acknowledgedAt, handledBy, handledAt
// 新增字段:
private String resolvedType;  // "AUTO" / "MANUAL_DISMISS"
private Instant resolvedAt;

// 新增方法:
public void dismiss(Long userId) {
    if (status != AlertStatus.ACTIVE) throw STATE_CONFLICT;
    this.status = AlertStatus.DISMISSED;
    this.resolvedType = "MANUAL_DISMISS";
    this.resolvedAt = Instant.now();
}

public void autoResolve() {
    if (status != AlertStatus.ACTIVE) return; // 幂等
    this.status = AlertStatus.AUTO_RESOLVED;
    this.resolvedType = "AUTO";
    this.resolvedAt = Instant.now();
}
```

`AlertDto` 新字段：
```java
public record AlertDto(
    Long id, Long farmId, Long livestockId, Long fenceId,
    String type, String status, String severity, String message,
    boolean read,           // 新增: per-user
    String resolvedType,    // 新增
    Instant resolvedAt,     // 新增
    Double distance,        // 新增: 围栏距离
    String direction        // 新增: 越界方向
) { ... }
```

**验证：** 重写 `AlertTest`（ACTIVE→DISMISSED、ACTIVE→AUTO_RESOLVED、非法转换拒绝）+ `./gradlew test --tests "*.ranch.*"`

- [ ] Step 1: Update AlertStatus enum
- [ ] Step 2: Update AlertType enum
- [ ] Step 3: Refactor Alert entity (delete old methods/fields, add new)
- [ ] Step 4: Update AlertJpaEntity + AlertMapper + AlertDto
- [ ] Step 5: Update AlertRepository + AlertApplicationService
- [ ] Step 6: Rewrite AlertTest
- [ ] Step 7: Run `./gradlew test --tests "*.ranch.*"`
- [ ] Step 8: Commit

---

### Task 3 — alert_read_status per-user 已读

**归属**：后端
**依赖**：Task 2

**Files:**
- Create: `ranch/infrastructure/persistence/entity/AlertReadStatusJpaEntity.java`
- Create: `ranch/infrastructure/persistence/SpringDataAlertReadStatusRepository.java`
- Modify: `ranch/application/AlertApplicationService.java` — markRead/batchRead 实现
- Modify: `ranch/application/dto/AlertDto.java` — read 字段填充逻辑
- Create: `test/.../AlertReadStatusTest.java`

**关键实现：**

```java
// AlertReadStatusJpaEntity
@Entity
@Table(name = "alert_read_status", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"alert_id", "user_id"})
})
public class AlertReadStatusJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "alert_id") private Long alertId;
    @Column(name = "user_id") private Long userId;
    @Column(name = "read_at") private Instant readAt;
    // getters/setters + @PrePersist
}
```

markRead 实现：
```java
public void markRead(Long alertId, Long userId) {
    if (!alertReadStatusRepo.existsByAlertIdAndUserId(alertId, userId)) {
        AlertReadStatusJpaEntity entity = new AlertReadStatusJpaEntity();
        entity.setAlertId(alertId);
        entity.setUserId(userId);
        alertReadStatusRepo.save(entity);
    }
}
```

AlertDto.read 填充（在列表/详情查询时）：
```java
// 查询当前用户已读的 alertId 集合
Set<Long> readAlertIds = alertReadStatusRepo
    .findByUserIdAndAlertIdIn(userId, alertIds)
    .stream().map(AlertReadStatusJpaEntity::getAlertId).collect(toSet());
// 填充 read 字段
```

**验证：** 新增 `AlertReadStatusTest`（多用户隔离、重复标记幂等）

- [ ] Step 1: Create AlertReadStatusJpaEntity + Spring Data repo
- [ ] Step 2: Implement markRead/batchRead in AlertApplicationService
- [ ] Step 3: Wire read field into AlertDto population
- [ ] Step 4: Write AlertReadStatusTest
- [ ] Step 5: Run `./gradlew test --tests "*.ranch.*"`
- [ ] Step 6: Commit

---

### Task 4 — AlertController + API 合约更新

**归属**：后端
**依赖**：Task 3

**Files:**
- Modify: `ranch/interfaces/AlertController.java` — 端点重映射 + 新端点
- Create: `ranch/interfaces/FenceZoneController.java` — fence_zones CRUD
- Update: `test/.../AlertStateMachineJourneyTest.java`

**修改端点：**

| 旧路径 | 新路径 | 变化 |
|--------|--------|------|
| `POST /alerts/{id}/acknowledge` | `POST /alerts/{id}/read` | markRead |
| `POST /alerts/{id}/handle` | `POST /alerts/{id}/dismiss` | dismiss |
| `POST /alerts/{id}/archive` | 保留（内部调 autoResolve） | — |
| `GET /alerts` | `GET /alerts` | 响应增加 read/resolvedType/resolvedAt |

**新增端点：**

| 路径 | 说明 |
|------|------|
| `POST /alerts/batch-read` | 批量标已读，body: `{ "alertIds": [...] }` |
| `GET /fence-zones` | 列出围栏重点区域 |
| `POST /fence-zones` | 创建重点区域 |

**旧端点兼容：** `/acknowledge` → 内部重定向到 markRead，`/handle` → 内部重定向到 dismiss。给前端迁移窗口。

**验证：** Controller 测试 + JourneyTest 更新

- [ ] Step 1: Remap AlertController endpoints
- [ ] Step 2: Add backward-compatible redirects for old endpoints
- [ ] Step 3: Create FenceZoneController
- [ ] Step 4: Update AlertStateMachineJourneyTest
- [ ] Step 5: Run `./gradlew test`
- [ ] Step 6: Commit

---

### Task 5 — Dashboard API 扩展

**归属**：后端
**依赖**：Task 3

**Files:**
- Modify: `ranch/interfaces/DashboardController.java`
- Modify: `ranch/application/AlertApplicationService.java` — 新增按类型分组计数方法

**Dashboard 响应新增字段：**
```json
{
  "inFenceRate": 0.98,
  "fenceAlertSummary": {
    "FENCE_BREACH": 1,
    "FENCE_APPROACH": 2,
    "ZONE_APPROACH": 0
  },
  "healthAlertSummary": {
    "TEMPERATURE_ABNORMAL": 2,
    "DIGESTIVE_ABNORMAL": 0,
    "ESTRUS": 3,
    "EPIDEMIC": 0
  }
}
```

**inFenceRate 计算**：查所有牲畜最新 GPS → 对每个围栏调 `Fence.contains()` → `围栏内数 / 有 GPS 数`

**ranch-overview 端点**同步返回新字段。

**验证：** DashboardController 单元测试

- [ ] Step 1: Add summary methods to AlertApplicationService
- [ ] Step 2: Extend DashboardController.summary() with new fields
- [ ] Step 3: Add inFenceRate calculation
- [ ] Step 4: Write tests
- [ ] Step 5: Commit

---

### Task 6 — 围栏缓冲带检测 + 自动解除

**归属**：后端
**依赖**：Task 2

**Files:**
- Modify: `ranch/domain/service/FenceBreachDetector.java` — 新增缓冲带检测 + 回到安全区检测
- Modify: `ranch/infrastructure/mq/GpsLogEventConsumer.java` — 扩展逻辑
- Modify: `ranch/application/FenceApplicationService.java` — buffer polygon 预计算
- Modify: `build.gradle` — 添加 JTS 依赖
- Update: `test/.../FenceBreachDetectorTest.java`

**JTS 依赖：**
```gradle
implementation 'org.locationtech.jts:jts-core:1.19.0'
```

**FenceBreachDetector 扩展：**
```java
// 新增方法
public List<Fence> findApproachingFences(List<Fence> fences, GpsCoordinate point) {
    // 检测点是否在 fence 的 buffer_polygon 内
}

public List<Fence> findReturnedToSafe(List<Fence> fences, GpsCoordinate point) {
    // 检测之前越界的牲畜是否回到围栏内
}
```

**GpsLogEventConsumer 扩展逻辑：**
```
收到 GPS → 查牲畜所属围栏
  → 之前在围栏外，现在回到围栏内 → autoResolve 该牲畜的 FENCE_BREACH/FENCE_APPROACH 告警
  → 之前在围栏内，现在进入缓冲带 → 创建 FENCE_APPROACH 告警 (WARNING)
  → 现在越过围栏 → 创建 FENCE_BREACH 告警 (CRITICAL)
```

**buffer polygon 预计算**：围栏创建/编辑时，用 JTS `Geometry.buffer(50m)` 计算并持久化到 `fences.buffer_polygon`。

**验证：** `FenceBreachDetectorTest` 新增缓冲带检测 + 自动解除场景

- [ ] Step 1: Add JTS dependency to build.gradle
- [ ] Step 2: Extend FenceBreachDetector with buffer detection
- [ ] Step 3: Add buffer polygon pre-computation to FenceApplicationService
- [ ] Step 4: Extend GpsLogEventConsumer with approach/return logic
- [ ] Step 5: Write tests
- [ ] Step 6: Run `./gradlew test --tests "*.ranch.*"`
- [ ] Step 7: Commit

---

### Task 7 — 健康告警自动解除

**归属**：后端
**依赖**：Task 2

**Files:**
- Modify: `health/domain/port/RanchCommandPort.java` — 新增 `resolveAlert()`
- Modify: `health/infrastructure/acl/RanchCommandPortImpl.java` — 实现
- Modify: Health ApplicationService — 写入指标时检测恢复正常 → 调用 resolveAlert

**关键实现：**

```java
// RanchCommandPort 新增
void resolveAlert(Long livestockId, String alertType);

// RanchCommandPortImpl 实现
@Override
public void resolveAlert(Long livestockId, String alertType) {
    List<Alert> activeAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
        livestockId, AlertType.valueOf(alertType), AlertStatus.ACTIVE);
    for (Alert alert : activeAlerts) {
        alert.autoResolve();
        alertRepository.save(alert);
    }
}
```

**触发时机**：Health 上下文写入新指标时，若指标回到正常范围（体温恢复、蠕动正常），调用 `resolveAlert()`。

**验证：** 集成测试覆盖（健康指标恢复 → 告警自动解除）

- [ ] Step 1: Add resolveAlert to RanchCommandPort + impl
- [ ] Step 2: Wire auto-resolve trigger in Health ApplicationService
- [ ] Step 3: Write integration test
- [ ] Step 4: Commit

---

## 阶段二：前端模型层（Task 8-11）

后端 API 合约定型后，前端先扩展模型，用 Mock 数据验证。

### Task 8 — 扩展数据模型 + Mock 固件

**归属**：前端
**依赖**：Task 4（API 合约定型）
**参考**：前端参考文档 Task 1，补充 resolvedAt、FenceZoneData、fenceZones

**Files:**
- Modify: `lib/features/ranch/domain/ranch_models.dart`
- Create: `test/fixtures/ranch_overview_mock.json`
- Create: `test/features/ranch/ranch_models_test.dart`

**模型扩展：**

`RanchOverviewStats` 增加：
```dart
final double inFenceRate;
// fromJson: (m['inFenceRate'] as num?)?.toDouble() ?? 0.0,
```

`RanchAlertData` 增加新字段 + copyWith：
```dart
final bool read;
final double? distance;
final String? direction;
final String? resolvedType;
final String? resolvedAt;

RanchAlertData copyWith({bool? read, double? distance, String? direction,
    String? resolvedType, String? resolvedAt}) {
  return RanchAlertData(
    id: id, type: type, severity: severity, status: status,
    message: message, livestockId: livestockId, fenceId: fenceId,
    occurredAt: occurredAt, read: read ?? this.read,
    distance: distance ?? this.distance, direction: direction ?? this.direction,
    resolvedType: resolvedType ?? this.resolvedType,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}
```

新增 `FenceZoneData`：
```dart
class FenceZoneData {
  const FenceZoneData({
    required this.id, required this.fenceId, required this.name,
    required this.zoneType, required this.alertRadius, required this.severity,
  });
  final String id;
  final String fenceId;
  final String name;
  final String zoneType;
  final int alertRadius;
  final String severity;

  factory FenceZoneData.fromJson(Map<String, dynamic> m) { ... }
}
```

`RanchOverview` 增加：
```dart
final Map<String, int> fenceAlertSummary;
final Map<String, int> healthAlertSummary;
final List<FenceZoneData> fenceZones;
```

Mock 固件：`test/fixtures/ranch_overview_mock.json` 包含完整新字段数据。

**验证：** TDD 红绿循环 — `flutter test test/features/ranch/ranch_models_test.dart`

- [ ] Step 1: Write model tests (expect failure)
- [ ] Step 2: Run tests, confirm FAIL
- [ ] Step 3: Implement model extensions
- [ ] Step 4: Create mock JSON fixture
- [ ] Step 5: Run tests, confirm PASS
- [ ] Step 6: Run `flutter test` full regression
- [ ] Step 7: Commit

---

### Task 9 — 扩展 Repository 层

**归属**：前端
**依赖**：Task 8
**参考**：前端参考文档 Task 2

**Files:**
- Modify: `lib/features/ranch/domain/ranch_repository.dart`
- Modify: `lib/features/ranch/data/ranch_api_repository.dart`

```dart
abstract class RanchRepository {
  Future<RanchOverview> loadOverview();
  Future<void> markRead(String alertId);
  Future<void> dismiss(String alertId);
  Future<void> batchRead(List<String> alertIds);
}
```

```dart
class RanchApiRepository implements RanchRepository {
  @override
  Future<void> markRead(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/read', null);
  }
  @override
  Future<void> dismiss(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/dismiss', null);
  }
  @override
  Future<void> batchRead(List<String> alertIds) async {
    await ApiClient.instance.farmPost('/alerts/batch-read', {'alertIds': alertIds});
  }
}
```

**验证：** `flutter analyze lib/features/ranch/`

- [ ] Step 1: Add abstract methods to RanchRepository
- [ ] Step 2: Implement in RanchApiRepository
- [ ] Step 3: Run `flutter analyze`
- [ ] Step 4: Commit

---

### Task 10 — 重构 alerts 模块

**归属**：前端
**依赖**：Task 9

**Files:**
- Modify: `lib/features/alerts/domain/alerts_repository.dart`
- Modify: `lib/features/alerts/data/alerts_api_repository.dart`
- Modify: `lib/features/alerts/presentation/alerts_controller.dart`
- Modify: `lib/core/models/core_models.dart`

**变更：**
- `AlertStage` 枚举：`{pending, acknowledged, handled, archived}` → `{active, dismissed, autoResolved}`
- `AlertItem` 的 `stage` 字段同步更新
- `AlertsRepository` 方法：`acknowledge` → `markRead`，`handle` → `dismiss`，删除 `archive`，新增 `batchRead`
- `AlertsApiRepository` API 路径对齐新端点
- `AlertsController` 方法同步重命名
- 全局搜索 `AlertStage`、`acknowledge`、`handle` 确认无遗漏引用

**验证：** `flutter analyze` + `flutter test`

- [ ] Step 1: Update AlertStage enum + AlertItem
- [ ] Step 2: Update AlertsRepository + AlertsApiRepository
- [ ] Step 3: Update AlertsController
- [ ] Step 4: Global search for stale references
- [ ] Step 5: Run `flutter analyze` + `flutter test`
- [ ] Step 6: Commit

---

### Task 11 — 扩展 Controller（钻取状态）

**归属**：前端
**依赖**：Task 9
**参考**：前端参考文档 Task 3，附加以下修正

**Files:**
- Modify: `lib/features/ranch/presentation/ranch_controller.dart`

**关键设计决策：**

1. **钻取状态在 `build()` 开头重置**（牧场切换时自动回到 dashboard）
2. **乐观更新使用 copyWith**（避免手动构造 RanchOverview）
3. **钻取状态与 AsyncData 共处同一 Notifier**（若未来复杂化再提取独立 StateProvider）

```dart
enum RanchDrillLevel { dashboard, list, detail }

class RanchController extends FarmScopedAsyncNotifier<RanchOverview> {
  RanchDrillLevel _drillLevel = RanchDrillLevel.dashboard;
  String? _selectedCategory;
  String? _selectedAlertId;

  @override
  Future<RanchOverview> build() async {
    watchActiveFarmId();
    _drillLevel = RanchDrillLevel.dashboard;  // 重置
    _selectedCategory = null;
    _selectedAlertId = null;
    return ref.read(ranchRepositoryProvider).loadOverview();
  }

  void showDashboard() { _drillLevel = RanchDrillLevel.dashboard; ... }
  void showCategoryList(String category) { _drillLevel = RanchDrillLevel.list; ... }
  void showAlertDetail(String alertId) {
    _drillLevel = RanchDrillLevel.detail;
    markRead(alertId);  // fire-and-forget
    ...
  }

  Future<void> markRead(String alertId) async {
    await ref.read(ranchRepositoryProvider).markRead(alertId);
    // Optimistic update via copyWith
    final overview = state.value;
    if (overview != null) {
      final updated = overview.copyWith(
        alerts: overview.alerts.map((a) =>
          a.id == alertId ? a.copyWith(read: true) : a).toList());
      state = AsyncData(updated);
    }
  }

  Future<void> dismiss(String alertId) async { ... refresh(); }
  Future<void> batchRead(List<String> alertIds) async { ... refresh(); }
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(ranchRepositoryProvider).loadOverview());
    _drillLevel = RanchDrillLevel.dashboard;
    _selectedCategory = null;
    _selectedAlertId = null;
  }
}
```

**注意：** `RanchOverview` 和 `RanchAlertData` 需确保有 `copyWith` 方法。

**验证：** `flutter analyze`

- [ ] Step 1: Add drill-down state + methods to RanchController
- [ ] Step 2: Ensure RanchOverview/RanchAlertData have copyWith
- [ ] Step 3: Run `flutter analyze`
- [ ] Step 4: Commit

---

## 阶段三：前端 UI 层（Task 12-19）

模型层就绪后，构建 UI 组件并整合。

### Task 12 — StatusDashboardCard + AlertCard 组件

**归属**：前端
**依赖**：Task 11
**参考**：前端参考文档 Task 4，附加角色门控

**Files:**
- Create: `lib/features/ranch/presentation/widgets/status_dashboard_card.dart`
- Create: `lib/features/ranch/presentation/widgets/alert_card.dart`
- Create: `test/features/ranch/status_dashboard_card_test.dart`
- Create: `test/features/ranch/alert_card_test.dart`

**StatusDashboardCard**：count ≤ 0 → `SizedBox.shrink()`，否则显示图标+标签+数量

**AlertCard**：未读（加粗+实心色点）vs 已读（opacity 0.7+空心圈）
- 新增 `showDismiss` 参数用于角色门控（worker 不显示忽略操作）
- 颜色映射 `_typeColor` / `_severityColor` switch 表达式

**验证：** Widget 测试通过

- [ ] Step 1: Implement StatusDashboardCard
- [ ] Step 2: Implement AlertCard (with showDismiss param)
- [ ] Step 3: Write StatusDashboardCard test (count=0 hidden)
- [ ] Step 4: Write AlertCard test (unread/read visual)
- [ ] Step 5: Run tests
- [ ] Step 6: Commit

---

### Task 13 — DeviceInfoLine + AutoResolvedSection 组件

**归属**：前端
**依赖**：无
**参考**：前端参考文档 Task 5

**Files:**
- Create: `lib/features/ranch/presentation/widgets/device_info_line.dart`
- Create: `lib/features/ranch/presentation/widgets/auto_resolved_section.dart`

**DeviceInfoLine**：灰色小字 + 故障升级色。MVP 阶段设备参数为 placeholder，标注 TODO，后端 AlertDto 扩展 `deviceStatus` 后替换。

**AutoResolvedSection**：折叠区，点击展开已自动解除告警，标"无需处理"。

- [ ] Step 1: Implement DeviceInfoLine (with TODO placeholder notes)
- [ ] Step 2: Implement AutoResolvedSection
- [ ] Step 3: Run `flutter analyze`
- [ ] Step 4: Commit

---

### Task 14 — 重写 HealthBottomSheet（核心 Task）

**归属**：前端
**依赖**：Task 12、Task 13
**参考**：前端参考文档 Task 6，附加角色门控

**Files:**
- Rewrite: `lib/features/ranch/presentation/widgets/health_bottom_sheet.dart` (779行 → 钻取式)
- Create: `test/features/ranch/health_bottom_sheet_test.dart`

**四层钻取架构：**

```
① peek 条：头数 · 归栏率 · 健康率（去掉旧的未读告警数、统计卡片）
② 仪表盘：围栏情况卡片组 + 健康情况卡片组（0 隐藏）
③ 列表：该类别告警列表（未读优先 + 已读淡化 + 自动解除折叠）
④ 详情：根据告警类型弹出不同的 detail sheet
```

snap 三级手势保留（peek/half/full）。根据 `RanchController.drillLevel` 切换渲染内容。

**角色门控：**
- "全部已读"按钮：owner/b2b_admin 可见，worker 隐藏
- Worker 的 alert card 不显示 dismiss 操作

**验证：** `test/features/ranch/health_bottom_sheet_test.dart`（四层渲染 + 钻取切换）

- [ ] Step 1: Rewrite HealthBottomSheet with drill-down architecture
- [ ] Step 2: Add role-based gating (batch-read, dismiss)
- [ ] Step 3: Write widget test
- [ ] Step 4: Run `flutter analyze`
- [ ] Step 5: Commit

---

### Task 15 — FenceAlertDetailSheet（空间型详情）

**归属**：前端
**依赖**：Task 14
**参考**：前端参考文档 Task 7，附加角色门控

**Files:**
- Create: `lib/features/ranch/presentation/widgets/fence_alert_detail_sheet.dart`
- Create: `test/features/ranch/fence_alert_detail_test.dart`

**要素：**
- 小地图（FlutterMap）+ 围栏 + 缓冲带 + 牲畜位置标注
- 空间信息行（围栏名、距离 Xm、方向、发生时间）
- DeviceInfoLine（placeholder）
- 能力边界说明（"系统能通知你牛已越界，需线下赶回"）
- "大地图定位"按钮 + "忽略此告警"按钮（owner/b2b_admin 可见）
- 点开自动调 `markRead`

**验证：** Widget 测试

- [ ] Step 1: Implement FenceAlertDetailSheet
- [ ] Step 2: Add role-based gating for dismiss button
- [ ] Step 3: Write widget test
- [ ] Step 4: Run `flutter analyze`
- [ ] Step 5: Commit

---

### Task 16 — 健康告警详情页改造

**归属**：前端
**依赖**：Task 14
**参考**：前端参考文档 Task 8

**Files:**
- Modify: `lib/features/pages/fever_detail_page.dart`
- Modify: `lib/features/pages/digestive_detail_page.dart`
- Modify: `lib/features/pages/estrus_detail_page.dart`

**每个页面添加：**
- DeviceInfoLine（placeholder，标注 TODO）
- 能力边界说明（"系统能通知你体温异常，需线下排查"）
- "忽略此告警"按钮（owner/b2b_admin 可见）
- 点开自动标已读

- [ ] Step 1: Enhance fever_detail_page.dart
- [ ] Step 2: Enhance digestive_detail_page.dart
- [ ] Step 3: Enhance estrus_detail_page.dart
- [ ] Step 4: Run `flutter analyze`
- [ ] Step 5: Commit

---

### Task 17 — 缓冲带地图图层 + 牲畜标注变色

**归属**：前端
**依赖**：Task 15
**参考**：前端参考文档 Task 9，附加纬度修正

**Files:**
- Create: `lib/features/ranch/presentation/widgets/fence_buffer_layer.dart`
- Modify: `lib/features/pages/ranch_page.dart`

**FenceBufferLayer**：围栏外侧缓冲带渲染（橙色半透明多边形 + 虚线边框）

**缓冲带近似算法（MVP）：**
- 纬度方向 50m ≈ 0.00045°
- 经度方向需除以 cos(28°) ≈ 0.88 → 0.00051°
- 标注为 MVP 近似，后端 `buffer_polygon` 上线后替换

**牲畜 Marker 变色逻辑（ranch_page.dart）：**
- 围栏外 → 红色（覆盖健康色）
- 缓冲带 → 橙色（覆盖健康色）
- 围栏内 → 使用健康状态色

- [ ] Step 1: Implement FenceBufferLayer
- [ ] Step 2: Add marker coloring logic to ranch_page.dart
- [ ] Step 3: Run `flutter analyze`
- [ ] Step 4: Manual verification on map rendering
- [ ] Step 5: Commit

---

### Task 18 — LivestockDetailSheet 新状态标签

**归属**：前端
**依赖**：Task 10
**参考**：前端参考文档 Task 10

**Files:**
- Modify: `lib/features/ranch/presentation/widgets/livestock_detail_sheet.dart`

**状态映射（含旧值兼容）：**
```dart
String _statusLabel(String status) => switch (status) {
  'ACTIVE' => '活跃',
  'DISMISSED' => '已忽略',
  'AUTO_RESOLVED' => '已自动解除',
  // Legacy compatibility
  'PENDING' => '活跃', 'ACKNOWLEDGED' => '活跃',
  'HANDLED' => '已忽略', 'ARCHIVED' => '已自动解除',
  _ => status,
};
```

- [ ] Step 1: Update status labels + colors
- [ ] Step 2: Run `flutter analyze`
- [ ] Step 3: Commit

---

### Task 19 — 全局回归 + 验证

**归属**：前端
**依赖**：Task 14-18 全部完成

**内容：**
- `flutter test` 全量通过
- `flutter analyze` 无 issue
- 后端 `./gradlew test` 全量通过
- 端到端冒烟验证（spec 第 14 节 7 条验收标准）

**验收标准：**
1. owner 打开牧场 Tab，peek 条显示 `头数 · 归栏率 · 健康率`，无重复信息
2. 上划展开，看到围栏情况 + 健康情况两组卡片，数量 0 的隐藏
3. 点击卡片进入该类别告警列表，未读/已读视觉区分清晰
4. 点击告警项进入详情（围栏=地图型 / 健康=图表型），自动标记已读
5. 围栏地图显示缓冲带环 + 重点区域圈，牲畜标注按区域变色
6. 设备信息低调显示，不抢视觉焦点
7. 自动解除的告警在折叠区可回溯

**Worker 角色冒烟：** 无"忽略"按钮、无"全部已读"

- [ ] Step 1: Run `./gradlew test` (backend)
- [ ] Step 2: Run `flutter test` (frontend)
- [ ] Step 3: Run `flutter analyze` (frontend)
- [ ] Step 4: End-to-end smoke test (owner + worker)
- [ ] Step 5: Final commit

---

## 依赖关系图

```
阶段一（后端）
  Task 1 (V26)
    ├── Task 2 (Alert 模型) ──┬── Task 3 (read_status) ──┬── Task 4 (API)
    │                         │                          └── Task 5 (Dashboard)
    │                         ├── Task 6 (缓冲带+自动解除)
    │                         └── Task 7 (健康自动解除)

阶段二（前端模型）           ← Task 4 完成后开始
  Task 8 (模型+Mock) → Task 9 (Repository) ──┬── Task 10 (alerts 模块)
    │                                          └── Task 11 (Controller)

阶段三（前端 UI）            ← Task 11 完成后开始
  Task 12 (卡片组件)
  Task 13 (辅助组件)
    └── Task 14 (HealthBottomSheet 重写) ──┬── Task 15 (围栏详情)
    │                                       ├── Task 16 (健康详情)
    │                                       └── Task 17 (缓冲带图层)
  Task 10 ──→ Task 18 (LivestockDetailSheet)
  Task 14-18 ──→ Task 19 (全局回归)
```

---

## 假设

- **Flyway V26**：当前最高 V25，V26 为下一个可用版本
- **JTS 依赖**：缓冲带预计算需 `org.locationtech.jts:jts-core:1.19.0`
- **旧 API 兼容期**：`/acknowledge`→`/read`、`/handle`→`/dismiss` 旧端点保留 redirect，Task 10 完成后可清理
- **设备信息 placeholder**：DeviceInfoLine 的 battery/signal 为 MVP 假数据，后端 AlertDto 扩展 `deviceStatus` 后替换
- **缓冲带精度**：前端 MVP 用经纬度偏移近似（含纬度修正 cos(28°)），后端 `buffer_polygon` 上线后替换
- **PostGIS 不引入**：<500 头牛 + <10 围栏，应用层 ray-casting 足够
