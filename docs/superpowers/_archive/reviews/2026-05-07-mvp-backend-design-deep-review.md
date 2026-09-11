# MVP 后端设计规格深度评审

> **评审日期**: 2026-05-07
> **评审文档**: `docs/superpowers/specs/2026-05-06-mvp-backend-design.md`
> **评审范围**: 后端架构、DDD 分层、数据库 Schema、安全模型、基础设施层、跨上下文事件
> **对照基线**: Mobile/backend/ (Node.js Mock Server)、API 契约文档 (2026-05-07-multi-client-api-contract-design.md)
> **注**: PC 端将全新重写，旧 PC/ 目录下的 Spring Boot 2.x 设计不作为约束或参照系。
> **前置评审**: 已有 `2026-05-07-mvp-specs-review.md` 覆盖两文档间对比和代码交叉验证。本文档补充后端架构专项深度评审。

---

## 一、评审定位

已有综合评审覆盖了以下问题（不再重复）：
- P0 B1: code 字段类型冲突（字符串 vs 数字）
- P0 B2: ID 类型冲突（BIGSERIAL vs UUID v4）
- P1 H1: 设备 API 路径不一致
- P1 H2: GPS 数据写入通道冲突
- P1 H3: 后端设计缺少 Admin/Open 端点
- P1 H4: device_licenses 农场归属
- P1 H5/H6: 端点数量对齐、设备运行时状态

本评审聚焦后端架构内聚性：DDD 实施可行性、基础设施层设计完整性、数据库 Schema 质量、安全架构、事务边界——这些是综合评审未深入覆盖的区域。

---

## 二、架构设计评审

### 2.1 洋葱架构的实施复杂度

规格 §3.1 采用严格 port/adapter 模式的洋葱架构：

```
interfaces → application → domain ← infrastructure (port/adapter)
```

方向正确，但规格未充分估计该架构在 Phase 1（11 张表、3 个限界上下文）下的文件量爆炸问题。每个聚合根在持久化链路需要 domain model + JPA entity + Mapper + repository interface + repository impl 共 5 个文件，11 张表约 55 个持久化相关文件。如果 Phase 2 扩展到全部 5 个上下文，文件数将进一步倍增。

**具体风险**:
1. 规格 §3.3 充血模型示例使用了 `registerEvent()` 方法——这需要一个事件收集机制（类似 DomainEvents 模式），但规格未说明是使用 Spring Data 的 `AbstractAggregateRoot` 还是手动实现。
2. 如果团队不熟悉 DDD port/adapter 模式，TDD 节奏（纯 POJO 单元测试 → 集成测试 → API 测试）存在学习曲线。

**可选降级方案**: 评估 Spring Data JDBC（天然支持聚合根，`CrudRepository` 直接返回 domain object，省去 entity 和 mapper 层）。或允许 domain model 直接加 JPA 注解（牺牲理论纯度换速度），Phase 2 再分离。是否采纳取决于团队对 DDD 严格度的偏好。

### 2.2 分层约束的强制执行

规格 §3.4 声明："infrastructure 不能被 domain 层 import；interfaces 不能直接访问 infrastructure"。

**缺失**: 规格未说明如何强制执行这些约束。在 Spring Boot 单模块项目中，包级约束只能靠团队纪律或 ArchUnit 测试。

**建议**: 补充一条——"使用 ArchUnit 测试强制执行分层依赖规则，CI 中集成 ArchUnit 检查"。

### 2.3 共享内核的职责边界

规格 §3.2 定义 `shared/` 包含 Security、Cache、Messaging、TenantContext、ApiResponse 等。共享内核在 DDD 中是敏感区域——放太多东西会退化为"公共工具包"。

| 组件 | 应放 shared/？| 理由 |
|------|------------|------|
| `AggregateRoot.java` | ✅ 是 | 所有上下文的领域模型基类 |
| `DomainEvent.java` | ✅ 是 | 领域事件基类 |
| `JwtTokenProvider.java` | ✅ 是 | 认证是跨上下文关注点 |
| `TenantContext.java` | ✅ 是 | 多租户隔离是全局关注点 |
| `ApiResponse.java` | ⚠️ 持疑 | 属于 interfaces 层，放 shared 会让 domain 层可视 |
| `RedisCacheService.java` | ⚠️ 持疑 | cache 能力应由 infrastructure 层提供 |
| `RocketMQEventPublisher.java` | ⚠️ 持疑 | 消息能力应由 infrastructure 层提供 |

**建议**: `shared/` 严格只放 domain 层可安全引用的基类（AggregateRoot、DomainEvent、Entity）。Security、Cache、Messaging 应放在 `shared/infrastructure/` 子包下，明确为 infrastructure 层组件。

---

## 三、基础设施层设计评审

### 3.1 基础设施层缺失的组件

规格 §3.2 目录树中的 `shared/` 包含了若干 infrastructure 组件，但各上下文内部的 `infrastructure/` 结构不完整。以下是规格当前列出与应补足的对比：

| 组件 | 当前规格 | 应补充 |
|------|---------|--------|
| **数据库连接池配置** | 无 | HikariCP 配置（pool size、timeout、leak detection） |
| **Flyway 迁移脚本** | ✅ V1~V3 | 需验证脚本与 DDL 的一致性 |
| **JPA 实体** | ✅ 每上下文有 JpaEntity | — |
| **Mapper (Entity ↔ Domain)** | ✅ 每上下文有 Mapper | — |
| **事务配置** | 无 | `@EnableTransactionManagement` + 事务边界定义 |
| **事件发布器 (infra)** | ✅ SpringEventPublisher | 仅 IoT 有，Ranch 也需要消费 GPS 事件的 handler |
| **OpenAPI 文档** | 无 | SpringDoc 配置（Phase 1 可降低优先级） |
| **Actuator 健康检查** | 无 | `/actuator/health` 端点，Docker Compose 依赖 |
| **CORS 配置** | 无 | Vue 3 PC 端需要跨域访问 |
| **异常处理** | ✅ ApiException + GlobalExceptionHandler | 需要定义所有业务异常与 code 枚举的映射表 |
| **请求日志/追踪** | 无 | requestId 的生成/传播/日志输出策略 |
| **数据库初始化** | 无 | `application.yml` 中 ddl-auto 策略需明确 |

**评审结论**: 基础设施层设计是 **规格最大的空白区**。规格 §7（待完成事项）未列出"基础设施层完整设计"作为独立任务项，这是一个**高优先级缺陷**。

**建议**: 补充一个专项的"基础设施层设计"章节或独立文档，覆盖以上全部缺失组件。作为实施前置条件。

### 3.2 事件系统的 Phase 1 范围与实现方式

规格 §2.6 中 RocketMQ Topics 表显示 Phase 1 仅使用 1 个 Topic：`gps-log-updated`。

**问题**: 为 1 个 Topic 引入完整的 RocketMQ 集群是基础设施过度投资。规格未讨论同进程异步替代方案。

**评估**:
- Spring Application Events + `@Async` 可以覆盖 Phase 1 的 1 个 Topic 需求
- 如果 Phase 2 必然需要 RocketMQ（IoT 真实接入后消息量增大），则在 Phase 1 用 Spring Events 做轻量替代、Phase 2 再引入 RocketMQ，可以实现"先跑通业务、后加基础设施"的渐进策略
- 代价：Phase 2 切换时需将 Spring Events 替换为 RocketMQ，需要在 Application Service 层通过接口（EventPublisher port）隔离

**建议**: 明确 Phase 1 事件实现方案。推荐：定义 `EventPublisher` 接口（port，在 domain/repository/ 同层），Phase 1 用 `SpringEventPublisher` 实现（基于 `ApplicationEventPublisher`），Phase 2 切换为 `RocketMQEventPublisher` 实现。在规格中成文。

### 3.3 消息 Schema 与序列化

规格定义了 RocketMQ Topic 清单但未定义消息体 Schema。

**缺失**:
- `gps-log-updated` 事件的消息体结构（device_id, lat, lng, accuracy, recorded_at, ...）
- 序列化格式（JSON vs Protobuf vs Avro）
- 消息 Schema 版本管理策略

**建议**: 为 Phase 1 的 `gps-log-updated` Topic 补充消息体 Schema 定义。Phase 2 的 Topic 在设计时再补充。

---

## 四、数据库 Schema 深度评审

### 4.1 DDL 与 Flyway 迁移的一致性风险

规格 §2 定义了 11 张表的 Schema（DDL），§3.2 目录树中声明 Flyway 迁移脚本为 V1~V3。

**问题**: 规格以 prose 表格描述 DDL，但 Flyway 执行的是实际 SQL 文件。两种格式之间的转换容易出现偏差。

**已验证的潜在偏差**:

| 表 | 规格定义 | 注释 |
|----|---------|------|
| `tenants` | `phase VARCHAR(10) DEFAULT 'SAMPLE'` | CHECK 约束未在 prose 中写明 |
| `users` | `role VARCHAR(30)` | CHECK 约束未写明，但 §1.2 定义了 5 种 Role 值对象 |
| `fences` | `vertices JSONB NOT NULL` | `{lat, lng}` 顺序与 API 契约 `{lng, lat}` 不一致 |
| `livestock` | `gender VARCHAR(10) CHECK IN ('公','母')` | 中文字符 CHECK，考虑用英文枚举值（male/female）保持 DB 语言一致性 |
| `alerts` | `type VARCHAR(30), status VARCHAR(20), severity VARCHAR(10)` | 三个枚举字段均无 CHECK 约束声明 |
| `gps_logs` | `(device_id, recorded_at DESC)` 索引 | 缺少覆盖 `livestock_id`（通过 device→installation→livestock 关联）的查询路径 |

**建议**: 
1. Flyway 脚本写入前，从 prose DDL 到 SQL 做一次完整的交叉校验
2. 所有枚举列增加 CHECK 约束
3. `fences.vertices` JSON 结构统一为 GeoJSON 格式 `{type: "Polygon", coordinates: [[[lng, lat], ...]]}`
4. `gps_logs` 评估是否需要额外的联合索引（`device_id, recorded_at` 已覆盖主要查询，但若需按 livestock 查 GPS 历史需通过 installation 表 JOIN）

### 4.2 索引策略评审

规格 §2.3 中 `gps_logs` 声明了 `(device_id, recorded_at DESC)` 索引，但其他 10 张表均未声明索引。

**缺失的索引**:

| 表 | 建议索引 | 理由 |
|----|---------|------|
| `users` | `(tenant_id)` | 租户下用户列表是高频查询 |
| `users` | `(username)` UNIQUE | DDL 已有 UNIQUE，自动创建索引 |
| `user_farm_assignments` | `(farm_id)` | 牧场成员列表（`GET /farms/{farmId}/members`） |
| `user_farm_assignments` | `(user_id)` | 校验用户对牧场的访问权限 |
| `livestock` | `(farm_id)` | 牧场下牲畜列表 |
| `livestock` | `(tag_id)` UNIQUE | DDL 已有 UNIQUE |
| `fences` | `(farm_id)` | 牧场下围栏列表 |
| `alerts` | `(farm_id, status)` | 牧场告警列表 + 按状态筛选 |
| `alerts` | `(livestock_id)` | 按牲畜查告警历史 |
| `alerts` | `(created_at DESC)` | 按时间倒序（告警列表默认排序） |
| `devices` | `(tenant_id)` | 租户下设备列表 |
| `device_licenses` | `(tenant_id)` | 租户下许可证列表 |
| `installations` | `(device_id)` | 按设备查安装历史 |
| `installations` | `(livestock_id)` | 按牲畜查安装历史 |
| `installations` | EXCLUDE 约束 | 同一设备不能有两条 `removed_at IS NULL` 记录——规格已提到但不完整，应使用 `EXCLUDE USING GIST (device_id WITH =, tstzrange(installed_at, COALESCE(removed_at, 'infinity')) WITH &&)` |

**评审结论**: 除 `gps_logs` 外，规格对所有表的索引策略是空白。这对 Phase 1 的小数据量可能不致命，但对于完整的设计文档是不可接受的遗漏。

**建议**: 为每张表补充索引声明，并在 Flyway 迁移脚本中一并实现。

### 4.3 外键约束与跨上下文引用

规格 §2.4 表总览中 `installations.livestock_id` 标注为"跨上下文引用，无 FK 约束"。这是 DDD 的务实选择——避免限界上下文之间的数据库耦合。

**评审**: 这个决策正确。但需要补充应用层的一致性保障机制。

**建议**: 在 `InstallationApplicationService` 的设计中明确：
1. 安装时通过 Ranch Context 的 `LivestockRepository.exists(farmId, livestockId)` 校验牲畜存在性
2. 牲畜被软删除时，通过领域事件 `LivestockRemovedEvent` 通知 IoT Context 自动卸载关联设备
3. 这些规则应在安装/卸载的 `ApplicationService` 层实现，不应放到 Controller 层

### 4.4 时间字段与审计

规格 Schema 中每张表都有 `created_at` / `updated_at`，但 `alerts` 表额外还有 `acknowledged_at`、`handled_at` 等业务时间戳——这是正确的建模。但 `updated_at` 的更新策略未说明。

| 场景 | `updated_at` 行为 |
|------|------------------|
| 告警状态变更 | 应更新 |
| GPS 位置更新（缓存在 livestock） | 应更新 |
| 设备心跳更新 `last_online_at` | 不应更新（`updated_at` 表示元数据变更，非运行时状态） |

**建议**: 在基础设施层设计中明确 `updated_at` 的更新触发规则。推荐使用 JPA `@PreUpdate` 自动更新，但对运行时状态字段（`last_online_at`、`last_latitude` 等）使用独立的 `@Query` 更新，绕过 `@PreUpdate` 钩子。

### 4.5 Schema 设计总结

MVP 规格的 Schema 设计覆盖 11 张表，具备以下关键特征：

- **全局 tenant_id 隔离** — 所有业务表通过 tenant_id 或 farm_id 归属租户
- **多牧场模型** — farms 表 + user_farm_assignments 关系表支持一人多牧场
- **完整告警状态机** — alerts 表含四阶段状态流转和业务时间戳
- **设备-许可证分离** — devices 与 device_licenses 独立生命周期
- **时序数据分表** — gps_logs 与 P2 的 temperature_logs、peristaltic_log 分开
- **五级角色模型** — owner/worker/platform_admin/b2b_admin/api_consumer

整体而言，是从 Demo 单应用视角向多租户 SaaS 平台视角的合理升级。

---

## 五、安全架构评审

### 5.1 认证链不完整

规格 §4.2 定义了 JWT payload 结构 `{ sub, tid, role, iat, exp }`，§3.2 定义了 `shared/security/` 包。但以下安全组件未在设计中出现：

| 组件 | 状态 | 说明 |
|------|------|------|
| **JWT 密钥管理** | ❌ 缺失 | 密钥存储位置（环境变量/配置文件/Vault）、轮换策略 |
| **Token 黑名单** | ⚠️ 部分 | Redis `jwt:blacklist:{token}` key pattern 在 §5.2 中提到，但未说明 refresh token 轮换时的旧 token 失效机制 |
| **密码策略** | ❌ 缺失 | 最小长度、复杂度要求、BCrypt cost factor |
| **登录失败锁定** | ❌ 缺失 | N 次失败后锁定账户、锁定时长 |
| **CSRF 防护** | ❌ 缺失 | REST API 使用 JWT Bearer Token 通常不需要 CSRF，但需在 SecurityConfig 中显式 disable |
| **API Key 生成算法** | ❌ 缺失 | 规格提到格式 `sl_live_<random>`，但未指定随机源（`SecureRandom` 或 UUID v4）和存储方式（SHA-256 hash） |

**建议**: 补充一个"安全设计"子章节，覆盖以上全部项目。最低限度需明确：密钥管理、密码策略、登录锁定、API Key 生成与存储。

### 5.2 租户数据隔离的 SQL 注入风险

规格 §4.6 设计要点中提到"Query 层自动追加租户条件"。这暗示在 Repository 或 JPA 层面自动过滤 tenant_id。

**风险**: 如果"自动追加"是通过拼接 SQL 字符串实现，存在 SQL 注入风险。如果通过 Hibernate `@Filter` 注解实现，需要验证所有实体都正确配置。

**建议**: 
1. 明确"自动追加租户条件"的实现方式（推荐 Hibernate `@Filter` + AOP 拦截器自动设置 `tenant_id` 参数）
2. 在所有集成测试中验证租户隔离：user A 的查询不应返回 user B 的数据
3. 在 `TenantContext` 中确保 `tenant_id` 来源于 JWT（不可由客户端传入）

### 5.3 Farm Scope 安全评审

规格 §4.7 的 Farm Scope 硬约束设计质量很高。从安全视角补充两个缺失的边界条件：

1. **URI 注入攻击**: 如果 farmId 路径参数被恶意构造（如 `../` 路径遍历），`FarmScopeResolver` 应拒绝非数字/非 UUID 格式的 farmId。Spring Boot 默认的路径变量解析通常安全，但建议在 Resolver 中加 `Long.parseLong()` 或 UUID 格式校验作为防御。

2. **跨租户 farmId 访问**: owner A 尝试访问 owner B 的 `/farms/{farmIdB}/livestock`——FarmScope 校验应包含"farmId 归属 tenantId 等于 JWT 中的 tid"。规格 §4.7 提到了这个场景，但未给出具体的校验步骤（至少需要查 farms 表的 tenant_id）。

---

## 六、事务与一致性评审

### 6.1 事务边界模糊

规格 §3.4 声明 application 层负责"事务管理"，但未定义事务边界规则。

**缺失的事务语义**:

| 操作 | 事务边界 |
|------|---------|
| 创建告警 + 发布 `AlertCreatedEvent` | 事件应在事务提交后发布（避免事务回滚后事件已发出） |
| 安装设备到牲畜 | `INSERT installation` + 可选更新 `devices.status = ACTIVE` |
| 激活设备许可证 | 更新 `device_licenses.status` + 发布 `LicenseActivatedEvent` |

**建议**: 补充事务策略：
1. Application Service 方法上使用 `@Transactional`
2. 领域事件使用 `TransactionPhase.AFTER_COMMIT` 发布
3. 跨上下文操作（如 GPS → 越界检测 → Alert）使用最终一致性（RocketMQ），不做分布式事务
4. 明确 Repository 接口不开启独立事务——事务由 Application Service 统一管理

### 6.2 installations 表的跨上下文引用一致性

`installations.livestock_id` 不使用 FK 约束。一致性保障措施需要明确：

**建议在 InstallationApplicationService 中实现**:
```java
// 安装时的校验步骤
1. device = deviceRepository.findById(deviceId) — 设备存在
2. device.status == ACTIVE — 设备已激活
3. livestock = livestockRepository.findByFarmIdAndId(farmId, livestockId) — 牲畜存在且属于当前农场（跨上下文调用 Ranch 的 Repository port）
4. 安装在同一牲畜上无重复（同一牲畜不能同时安装多个设备，或根据业务需求决定）
```

---

## 七、可测试性评审

### 7.1 领域模型测试覆盖

规格 §6.3 列出了 8 个领域模型测试类。从 DDD 视角评估覆盖是否充分：

| 领域模型 | 建议测试 | 规格是否覆盖 |
|---------|---------|------------|
| `Tenant` | phase 变更规则（SAMPLE→BATCH 条件） | ❌ 缺失 |
| `Farm` | 软删除前置条件（有依赖数据时拒绝） | ❌ 缺失 |
| `User` | ✅ 密码匹配、角色判断 | ✅ 覆盖 |
| `UserFarmAssignment` | 同一用户+牧场不能重复分配 | ❌ 缺失 |
| `Livestock` | 健康状态变更规则 | ✅ 覆盖 |
| `Fence` | 多边形编辑后越界检测自动失效 | ❌ 缺失（contains 测试覆盖了点判定但未覆盖围栏修改后的行为） |
| `Alert` | ✅ 四阶段状态机 + 非法跳转 | ✅ 覆盖 |
| `FenceBreachDetector` | ✅ GPS + 围栏越界判定 | ✅ 覆盖 |
| `Device` | ✅ 生命周期状态转换 | ✅ 覆盖 |
| `DeviceLicense` | 许可证在过期设备上的行为 | ⚠️ 部分（过期/有效/撤销覆盖，但未覆盖与 Device 状态的联动） |
| `Installation` | 重复安装约束、拆卸后重新安装 | ✅ 覆盖 |

**建议**: 补充 Tenant、Farm、UserFarmAssignment 的领域模型测试。DeviceLicense 增加与 Device 状态联动的测试（如已退役设备的许可证应自动失效）。

### 7.2 集成测试的数据隔离

规格 §6.4 应用层集成测试使用 Testcontainers。这是一个正确的选择，但需注意：

1. **性能**: 11 张表的 Flyway 迁移 + Testcontainers PostgreSQL 启动约需 10-15 秒/测试类。如果每个 ApplicationService 独立一个测试类，总启动时间可能达到 2-3 分钟。
2. **数据隔离**: 使用 `@Transactional` 回滚 vs `@Sql` 清理 vs Testcontainers 容器复用。

**建议**: 在测试策略中补充：使用 Testcontainers 的 `singleton` 容器模式（所有测试类共享一个 PostgreSQL 容器），每个测试类用 `@Transactional` + 回滚隔离，避免重复启动容器。

### 7.3 API 端到端测试中的认证模拟

规格 §6.5 的 API 测试使用 MockMvc。JWT 认证在测试中的模拟方式需要明确：

- 直接注入 `SecurityContext` 设置已认证用户？
- 还是使用真实的 JWT token（测试用密钥签名）？
- 推荐方式：使用 `@WithMockUser` 或自定义 `@WithMockJwt` 注解设置 `sub`、`tid`、`role`

---

## 八、与 Mock Server 的衔接评审

### 8.1 哪些 Mock Server 模式应保留

Mock Server 在 Demo 阶段积累了一些值得继承到 Spring Boot 的设计模式：

| 模式 | Mock Server 实现 | Spring Boot 建议 |
|------|-----------------|-----------------|
| **中间件链** | `auth → farmContext → shaping` 顺序不可变 | Spring Security Filter Chain 中实现相同顺序 |
| **requestId 生成与传播** | 取 `X-Request-Id` header 或自动生成 UUID | 复制此模式到 Spring Boot 的 `Filter` |
| **envelope 统一包装** | `envelopeMiddleware` 统一响应格式 | 使用 `@ControllerAdvice` + `ResponseBodyAdvice` 实现 |
| **告警状态机 409** | `alertStore` 中状态校验 + 409 返回 | 在 `Alert` 领域模型中通过充血方法校验，Controller 层捕获异常返回 409 |
| **功能门控中间件** | `shapingMiddleware` 基于 tier 限制 | Phase 1 用 `@ConditionalOnProperty` + `TenantPhase` 判断替代 |

### 8.2 与 Mock Server 的行为差异

Mock Server 当前服务的是 Phase 2a Demo（包含订阅、合同、分润、数字孪生等功能），而 MVP Spring Boot 的 Phase 1 范围是核心底座（Identity + Ranch + IoT）。两者端点集合不重叠。

**结论**: Mock Server 适合作为 Phase 2 功能集的参考实现和 Demo 演示工具。Phase 1 Spring Boot 实现时不需对齐 Mock Server 的 Phase 2a 端点（subscription、contract、revenue、twin 等）。

---

## 九、问题汇总与优先级

### P0 — 阻断实施

| 编号 | 问题 | 建议 |
|------|------|------|
| I1 | 基础设施层设计空白 | 补充独立的基础设施层设计文档，覆盖 §三 全部缺失组件 |
| I2 | 索引策略缺失（10 张表无索引声明） | 为所有表补充索引设计 |
| I3 | 安全设计不完整 | 补充密钥管理、密码策略、登录锁定、租户隔离实现方案 |

### P1 — 影响质量

| 编号 | 问题 | 建议 |
|------|------|------|
| I4 | 事务边界未定义 | 补充事务策略（Application Service 统一管理、AFTER_COMMIT 发布事件） |
| I5 | 事件系统 Phase 1 方案不明确 | 推荐 Spring Events（port/adapter 隔离，Phase 2 切换 RocketMQ） |
| I6 | DDL CHECK 约束缺失 | 所有枚举列增加 CHECK 约束 |
| I7 | 消息 Schema 未定义 | 补充 `gps-log-updated` 事件的消息体结构 |
| I8 | `gps_logs` 缺少 livestock 相关查询路径索引 | 评估是否需要额外的 JOIN 优化索引 |

### P2 — 改进

| 编号 | 问题 | 建议 |
|------|------|------|
| I9 | 分层约束无强制执行机制 | 补充 ArchUnit 测试 |
| I10 | 共享内核职责边界不清 | ApiResponse、RedisCacheService 不应入 shared/ |
| I11 | `updated_at` 更新策略不明确 | 定义触发规则（元数据变更 vs 运行时状态） |
| I12 | 领域模型测试覆盖缺口 | 补充 Tenant、Farm、UserFarmAssignment 的测试 |
| I13 | 跨上下文引用一致性保障成文不充分 | 在 InstallationApplicationService 中写明校验步骤 |
| I14 | 时间戳类型不统一 | 规格用 `TIMESTAMP`，JDBC 映射为 `LocalDateTime`；建议统一为 `TIMESTAMPTZ`（`OffsetDateTime`） |

---

## 十、总体评估

规格文档在 **DDD 建模** 层面质量较高——限界上下文划分合理、聚合根识别正确、领域事件流向清晰、充血模型示例精准。主要的不足集中在**落地的工程细节**：基础设施层半空白、索引策略缺失、安全设计不完整、事务边界模糊。

**核心建议**: 在进入编码前，优先完成基础设施层设计的补全（至少覆盖 §三 标记的全部缺失组件），其次补全索引策略和安全设计，然后可以进入 TDD 编码阶段。
