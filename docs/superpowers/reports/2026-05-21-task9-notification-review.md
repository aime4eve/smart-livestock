# Code Review: Task 9 — Notification + EventListener

**Reviewed**: 2026-05-21
**Branch**: feat/flutter-springboot-adaptation
**Range**: c9096b9..aa08e86 (2 commits, 5 files, +471 lines)
**Decision**: APPROVE with comments

---

## Summary

Task 9 实现了平台级统一通知系统，包含 Notification JPA 实体、Spring Data Repository、NotificationService、30 个事件监听器，以及 DomainEventPublisher 工具类。代码整洁，模式一致，`@TransactionalEventListener(AFTER_COMMIT)` 正确隔离了通知写入与业务事务。无安全漏洞，无 CRITICAL 问题。

---

## Findings

### CRITICAL — None

### HIGH — None

### MEDIUM

**M1. Javadoc 与实际行为不一致**
- **File**: `NotificationEventListener.java:38-44`
- **Issue**: Javadoc 说 "Uses Spring's synchronous @EventListener — events are processed in the same transaction as the publisher"，但实际已改为 `@TransactionalEventListener(phase = AFTER_COMMIT)`，即事件在事务提交**之后**处理，不在同一事务中。
- **Fix**: 更新 Javadoc 为 "Uses Spring's `@TransactionalEventListener(AFTER_COMMIT)` — notifications are created after the business transaction commits, preventing notification failures from rolling back the originating operation."

**M2. ✅ 已修复 — `onGpsLogUpdated` 空监听器违反 YAGNI**
- **File**: `NotificationEventListener.java:262-294`
- **Issue**: `onGpsLogUpdated` 注册了 `@TransactionalEventListener` 但方法体仅打印 trace 日志，不做任何通知。GPS 更新事件频率高且永远不需要生成通知——注册一个空壳方法违反 YAGNI，会让未来读者困惑"这里应该做什么"。
- **Fix**: 已移除 `onGpsLogUpdated` 监听器及 import。其余 4 个非 Commerce 监听器保留（事件频率低、debug 日志有价值，未来可通过事件 enrichment 补充 tenantId）。

**M3. 无单元测试**
- **Files**: 所有 5 个新文件
- **Issue**: 通知系统没有任何测试。特别是 `NotificationEventListener` 中 30 个事件到中文 title/content 的映射逻辑完全未验证。`DomainEventPublisher.publishDomainEvents()` 的事件派发+清理逻辑也未测试。
- **Fix**: 至少添加以下测试：
  - `NotificationServiceTest`: 验证 `createNotification` 正确设置各字段
  - `NotificationEventListenerTest`: 验证 2-3 个代表性事件的 title/content 生成
  - `DomainEventPublisherTest`: 验证 `publishDomainEvents` 调用 `ApplicationEventPublisher.publishEvent` 后调用 `clearDomainEvents`

**M4. `findUnreadByTenant` / `findByTenant` 返回无界列表**
- **File**: `NotificationService.java:30-36` / `SpringDataNotificationRepository.java:9-11`
- **Issue**: 查询方法返回 `List<NotificationJpaEntity>`，无分页支持。活跃租户可能有数千条通知，全部加载会导致内存和性能问题。
- **Fix**: 改用 `Pageable` 参数或 `Limit` 查询。MVP 阶段可接受，但应在 TODO 中标注。当前不阻塞。

### LOW

**L1. `isRead` 字段初始化冗余**
- **File**: `NotificationJpaEntity.java:38` + `NotificationService.java:26`
- **Issue**: `NotificationJpaEntity` 声明时已初始化 `isRead = false`，`NotificationService.createNotification` 又显式 `setIsRead(false)`。两处初始化重复。
- **Fix**: 移除 `NotificationService.java:26` 的 `entity.setIsRead(false)`。

**L2. 事件 type 字符串未定义为常量**
- **File**: `NotificationEventListener.java`（多处）
- **Issue**: `"subscription_created"`、`"contract_signed"` 等通知类型以字符串字面量散布在 30 个方法中。如果后续需要按 type 查询或过滤，拼写错误风险较高。
- **Fix**: 可提取为 `NotificationTypes` 常量类或枚举。MVP 阶段可接受。

**L3. `NotificationService.createNotification` 的 `@Transactional` 语义**
- **File**: `NotificationService.java:17`
- **Issue**: 因为 `@TransactionalEventListener(AFTER_COMMIT)` 在提交后执行（无活跃事务），`@Transactional` 会启动新事务。这本身是正确的，但注释或命名上未体现这一语义——未来维护者可能困惑于"为什么一个简单的 save 需要 `@Transactional`"。
- **Fix**: 无需改动，但了解这一语义有助于后续维护。

---

## Validation Results

| Check | Result |
|---|---|
| Compilation | Pass (`./gradlew compileJava`) |
| Tests | Pass (`./gradlew test` — 全部现有测试通过) |
| DDL Alignment | Pass — `NotificationJpaEntity` 字段与 V6 DDL 完全对齐 |
| Pattern Compliance | Pass — JPA 实体无 Lombok、`SpringData*Repository` 命名、`@Column` 注解风格均与已有代码一致 |

---

## Files Reviewed

| File | Change | Lines |
|---|---|---|
| `platform/messaging/NotificationJpaEntity.java` | Added | 86 |
| `platform/messaging/SpringDataNotificationRepository.java` | Added | 12 |
| `platform/messaging/NotificationService.java` | Added | 37 |
| `platform/messaging/NotificationEventListener.java` | Added | 296 |
| `shared/domain/DomainEventPublisher.java` | Added | 40 |

---

## Recommendations

1. **必须修**: M1（Javadoc 与行为不一致）— 1 分钟修复
2. **建议修**: M2（移除 `onGpsLogUpdated`）— 1 分钟修复
3. **建议补**: M3（核心路径测试）— 可在后续测试补丁中完成
4. **可推迟**: M4（分页）、L1-L3 — 不阻塞 Task 10
