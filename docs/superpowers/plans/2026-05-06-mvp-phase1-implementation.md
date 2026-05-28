# MVP Phase 1 实施计划 — 核心底座

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Spring Boot MVP 后端的 Identity + Ranch + IoT 三个限界上下文，用 DDD 洋葱架构 + 充血模型 + TDD。

**Architecture:** 每个限界上下文按 domain → application → infrastructure → interfaces 四层洋葱架构组织。领域模型为纯 POJO，通过 Mapper 与 JPA Entity 分离。跨上下文通过 RocketMQ 领域事件解耦。

**Tech Stack:** Spring Boot 3.x, Java 17, Gradle, PostgreSQL 16, Redis 7, RocketMQ 5.1, Flyway, JPA/Hibernate, Spring Security + JWT, JUnit 5, Testcontainers

**Spec:** `docs/superpowers/specs/2026-05-06-mvp-backend-design.md`（领域模型 + DB Schema）+ `docs/api-contracts/api-overview.md`（API 契约，81 端点 + 17 错误码 + Farm Scope）

**前置阻塞:** Task 0（多端 API 契约重设计）已完成，Task 11（API Controllers）解除阻塞。Task 1-10 可并行推进。

---

## Issue 索引表

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #40 | 构建 MVP |

## 完成记录表

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-05-11 | #40 | — | Task 1: 项目初始化 + 共享内核 (`17f0c2b`) |
| 2026-05-11 | #40 | — | Task 2: Flyway V1-V4 迁移脚本 + 种子数据 (`25c0c5e`) |
| 2026-05-11 | #40 | — | Task 3: Identity 领域模型 TDD (`3a9e66d`) |
| 2026-05-11 | #40 | — | Task 4: Ranch 领域模型 TDD (`9dbb7d9`) |
| 2026-05-11 | #40 | — | Task 5: IoT 领域模型 TDD (`7556561`) |
| 2026-05-11 | #40 | — | Task 6: FarmScopeResolver TDD (`dcdd0d4`) |
| 2026-05-11 | #40 | — | Task 7: Persistence 层 — JPA Entity + Mapper + Repository (`b7a5269`) |
| 2026-05-11 | #40 | — | Task 8: Application Services 层 (`46581d4`) |
| 2026-05-11 | #40 | — | Task 9: Security + JWT (`c203328`) |
| 2026-05-11 | #40 | — | Task 9.5: Redis Cache 基础设施 (`34d84d1`) |
| 2026-05-11 | #40 | — | Task 10: 跨上下文事件桥接 (`f9e5bbc`) |
| 2026-05-12 | #40 | — | Task 11: API Controllers — App 49 + Admin 21 + Open 11 (`a3a9383`+`b5acba2`+`a8df560`) |
| 2026-05-12 | #40 | — | Task 12: 集成测试 (`83f9765`) |
| 2026-05-12 | #40 | — | Task 13: Docker Compose 部署 (`0facf27`) |
| 2026-05-12 | #40 | — | Task 14: GPS 模拟数据生成器 (`5052375`) |
| 2026-05-12 | #40 | — | 部署修复: 端口映射 / Dockerfile / BCrypt / @Component (`7094f70`+`d94456a`+`7b370fc`) |
| 2026-05-15 | #40 | — | Task 16: Flutter 前端适配完成 — 21 个 Live Repo + path-based farm scope + livestock/stats 数据解析 |

---

## 文件结构总览

```
smart-livestock-server/                          # 新建项目根目录
├── build.gradle
├── settings.gradle
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── infrastructure/
│   ├── nginx/nginx.conf
│   └── postgres/init.sql
└── src/
    ├── main/
    │   ├── java/com/smartlivestock/
    │   │   ├── SmartLivestockApplication.java
    │   │   ├── shared/
    │   │   │   ├── domain/AggregateRoot.java
    │   │   │   ├── domain/DomainEvent.java
    │   │   │   ├── domain/Entity.java
    │   │   │   ├── common/ApiException.java
    │   │   │   ├── common/ApiResponse.java
    │   │   │   ├── common/GlobalExceptionHandler.java
    │   │   │   ├── common/ErrorCode.java
    │   │   │   ├── security/JwtTokenProvider.java
    │   │   │   ├── security/JwtAuthenticationFilter.java
    │   │   │   ├── security/SecurityConfig.java
    │   │   │   ├── security/PasswordHasher.java
    │   │   │   ├── tenant/TenantContext.java
    │   │   │   ├── scope/FarmScopeResolver.java
    │   │   │   ├── scope/FarmScopeType.java
    │   │   │   ├── cache/RedisCacheService.java
    │   │   │   ├── cache/CacheKeys.java
    │   │   │   ├── messaging/RocketMQEventPublisher.java
    │   │   │   └── messaging/Topics.java
    │   │   ├── identity/
    │   │   │   ├── domain/model/Tenant.java
    │   │   │   ├── domain/model/User.java
    │   │   │   ├── domain/model/Farm.java
    │   │   │   ├── domain/model/Role.java
    │   │   │   ├── domain/model/TenantPhase.java
    │   │   │   ├── domain/repository/TenantRepository.java
    │   │   │   ├── domain/repository/UserRepository.java
    │   │   │   ├── domain/repository/FarmRepository.java
    │   │   │   ├── domain/event/TenantPhaseChangedEvent.java
    │   │   │   ├── application/service/AuthApplicationService.java
    │   │   │   ├── application/service/TenantApplicationService.java
    │   │   │   ├── application/service/FarmApplicationService.java
    │   │   │   ├── application/command/LoginCommand.java
    │   │   │   ├── application/command/CreateTenantCommand.java
    │   │   │   ├── application/command/CreateFarmCommand.java
    │   │   │   ├── application/dto/AuthTokenDto.java
    │   │   │   ├── application/dto/UserDto.java
    │   │   │   ├── application/dto/TenantDto.java
    │   │   │   ├── application/dto/FarmDto.java
    │   │   │   ├── infrastructure/persistence/entity/TenantJpaEntity.java
    │   │   │   ├── infrastructure/persistence/entity/UserJpaEntity.java
    │   │   │   ├── infrastructure/persistence/entity/FarmJpaEntity.java
    │   │   │   ├── infrastructure/persistence/entity/UserFarmAssignmentJpaEntity.java
    │   │   │   ├── infrastructure/persistence/mapper/TenantMapper.java
    │   │   │   ├── infrastructure/persistence/mapper/UserMapper.java
    │   │   │   ├── infrastructure/persistence/mapper/FarmMapper.java
    │   │   │   ├── infrastructure/persistence/JpaTenantRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/JpaUserRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/JpaFarmRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/SpringDataTenantRepository.java
    │   │   │   ├── infrastructure/persistence/SpringDataUserRepository.java
    │   │   │   └── infrastructure/persistence/SpringDataFarmRepository.java
    │   │   ├── ranch/
    │   │   │   ├── domain/model/Livestock.java
    │   │   │   ├── domain/model/Fence.java
    │   │   │   ├── domain/model/Alert.java
    │   │   │   ├── domain/model/AlertStatus.java
    │   │   │   ├── domain/model/AlertType.java
    │   │   │   ├── domain/model/HealthStatus.java
    │   │   │   ├── domain/model/Severity.java
    │   │   │   ├── domain/model/GpsCoordinate.java
    │   │   │   ├── domain/service/FenceBreachDetector.java
    │   │   │   ├── domain/repository/LivestockRepository.java
    │   │   │   ├── domain/repository/FenceRepository.java
    │   │   │   ├── domain/repository/AlertRepository.java
    │   │   │   ├── domain/event/FenceBreachDetectedEvent.java
    │   │   │   ├── domain/event/AlertStatusChangedEvent.java
    │   │   │   ├── application/service/LivestockApplicationService.java
    │   │   │   ├── application/service/FenceApplicationService.java
    │   │   │   ├── application/service/AlertApplicationService.java
    │   │   │   ├── application/command/CreateFenceCommand.java
    │   │   │   ├── application/command/UpdateFenceCommand.java
    │   │   │   ├── application/command/AcknowledgeAlertCommand.java
    │   │   │   ├── application/command/HandleAlertCommand.java
    │   │   │   ├── application/command/ArchiveAlertCommand.java
    │   │   │   ├── infrastructure/persistence/entity/LivestockJpaEntity.java
    │   │   │   ├── infrastructure/persistence/entity/FenceJpaEntity.java
    │   │   │   ├── infrastructure/persistence/entity/AlertJpaEntity.java
    │   │   │   ├── infrastructure/persistence/mapper/LivestockMapper.java
    │   │   │   ├── infrastructure/persistence/mapper/FenceMapper.java
    │   │   │   ├── infrastructure/persistence/mapper/AlertMapper.java
    │   │   │   ├── infrastructure/persistence/JpaLivestockRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/JpaFenceRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/JpaAlertRepositoryImpl.java
    │   │   │   ├── infrastructure/persistence/SpringDataLivestockRepository.java
    │   │   │   ├── infrastructure/persistence/SpringDataFenceRepository.java
    │   │   │   ├── infrastructure/persistence/SpringDataAlertRepository.java
    │   │   │   └── infrastructure/event/GpsLogEventHandler.java
    │   │   └── iot/
    │   │       ├── domain/model/Device.java
    │   │       ├── domain/model/DeviceLicense.java
    │   │       ├── domain/model/Installation.java
    │   │       ├── domain/model/GpsLog.java
    │   │       ├── domain/model/DeviceType.java
    │   │       ├── domain/model/DeviceStatus.java
    │   │       ├── domain/model/LicenseStatus.java
    │   │       ├── domain/repository/DeviceRepository.java
    │   │       ├── domain/repository/DeviceLicenseRepository.java
    │   │       ├── domain/repository/InstallationRepository.java
    │   │       ├── domain/repository/GpsLogRepository.java
    │   │       ├── domain/event/GpsLogUpdatedEvent.java
    │   │       ├── domain/event/DeviceActivatedEvent.java
    │   │       ├── domain/event/LicenseExpiredEvent.java
    │   │       ├── application/service/DeviceApplicationService.java
    │   │       ├── application/service/DeviceLicenseApplicationService.java
    │   │       ├── application/service/InstallationApplicationService.java
    │   │       ├── application/service/GpsLogApplicationService.java
    │   │       ├── application/command/RegisterDeviceCommand.java
    │   │       ├── application/command/ActivateLicenseCommand.java
    │   │       ├── application/command/InstallDeviceCommand.java
    │   │       ├── infrastructure/persistence/entity/DeviceJpaEntity.java
    │   │       ├── infrastructure/persistence/entity/DeviceLicenseJpaEntity.java
    │   │       ├── infrastructure/persistence/entity/InstallationJpaEntity.java
    │   │       ├── infrastructure/persistence/entity/GpsLogJpaEntity.java
    │   │       ├── infrastructure/persistence/mapper/DeviceMapper.java
    │   │       ├── infrastructure/persistence/mapper/DeviceLicenseMapper.java
    │   │       ├── infrastructure/persistence/mapper/InstallationMapper.java
    │   │       ├── infrastructure/persistence/mapper/GpsLogMapper.java
    │   │       ├── infrastructure/persistence/JpaDeviceRepositoryImpl.java
    │   │       ├── infrastructure/persistence/JpaDeviceLicenseRepositoryImpl.java
    │   │       ├── infrastructure/persistence/JpaInstallationRepositoryImpl.java
    │   │       ├── infrastructure/persistence/JpaGpsLogRepositoryImpl.java
    │   │       ├── infrastructure/persistence/SpringDataDeviceRepository.java
    │   │       ├── infrastructure/persistence/SpringDataDeviceLicenseRepository.java
    │   │       ├── infrastructure/persistence/SpringDataInstallationRepository.java
    │   │       ├── infrastructure/persistence/SpringDataGpsLogRepository.java
    │   │       └── infrastructure/event/SpringEventPublisher.java
    │   └── resources/
    │       ├── application.yml
    │       ├── application-test.yml
    │       └── db/migration/
    │           ├── V1__create_identity_tables.sql
    │           ├── V2__create_ranch_tables.sql
    │           └── V3__create_iot_tables.sql
    └── test/
        └── java/com/smartlivestock/
            ├── shared/scope/FarmScopeResolverTest.java
            ├── identity/domain/model/UserTest.java
            ├── ranch/domain/model/AlertTest.java
            ├── ranch/domain/model/FenceTest.java
            ├── ranch/domain/service/FenceBreachDetectorTest.java
            ├── iot/domain/model/DeviceTest.java
            ├── iot/domain/model/DeviceLicenseTest.java
            ├── iot/domain/model/InstallationTest.java
            ├── identity/application/service/AuthApplicationServiceTest.java
            ├── ranch/application/service/AlertApplicationServiceTest.java
            ├── ranch/application/service/FenceApplicationServiceTest.java
            ├── iot/application/service/DeviceApplicationServiceTest.java
            └── integration/GpsAlertFlowTest.java
```

---

## Task 0: 多端 API 契约重设计（已完成）

**状态: COMPLETED**

**产出:** [多端统一 API 契约设计](../../api-contracts/api-overview.md) — 81 个端点，三端隔离于 `/api/v1/`、`/api/v1/admin/`、`/api/v1/open/`

**关键决策（已通过评审确认）:**
- 响应 code 字段：全字符串枚举（`"OK"` 表示成功，`"AUTH_TOKEN_EXPIRED"` 等表示错误），与现有 Mock Server + Flutter 代码一致
- ID 格式：BIGSERIAL 自增整数，JSON 序列化为字符串对外暴露
- 分页：页码式分页（`page`/`pageSize`）
- 设备模型：双维度状态 — 生命周期 `status`（INVENTORY/ACTIVE/OFFLINE/DECOMMISSIONED）+ 运行时 `runtimeStatus`（online/offline/low_battery）

---

## Task 1: 项目初始化 + 共享内核

**Files:**
- Create: `smart-livestock-server/build.gradle`
- Create: `smart-livestock-server/settings.gradle`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/SmartLivestockApplication.java`
- Create: `smart-livestock-server/src/main/resources/application.yml`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/shared/domain/AggregateRoot.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/shared/domain/DomainEvent.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/shared/domain/Entity.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/shared/common/ApiException.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/shared/common/ErrorCode.java`

- [x] **Step 1: 创建 Gradle 项目结构**

在仓库根目录创建 `smart-livestock-server/` 子目录，初始化 Gradle 项目。

`build.gradle`:
```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.5'
}

group = 'com.smartlivestock'
version = '0.1.0-SNAPSHOT'
sourceCompatibility = '17'

dependencies {
    // Spring Boot
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'

    // Database
    runtimeOnly 'org.postgresql:postgresql'
    implementation 'org.flywaydb:flyway-core'
    implementation 'org.flywaydb:flyway-database-postgresql'

    // JWT
    implementation 'io.jsonwebtoken:jjwt-api:0.12.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.12.5'
    runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.12.5'

    // RocketMQ
    implementation 'org.apache.rocketmq:rocketmq-spring-boot-starter:2.3.0'

    // Utility
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    // Test
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
    testImplementation 'org.testcontainers:testcontainers:1.19.8'
    testImplementation 'org.testcontainers:postgresql:1.19.8'
    testImplementation 'org.testcontainers:junit-jupiter:1.19.8'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

`settings.gradle`:
```gradle
rootProject.name = 'smart-livestock-server'
```

- [x] **Step 2: 创建应用入口**

`src/main/java/com/smartlivestock/SmartLivestockApplication.java`:
```java
package com.smartlivestock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class SmartLivestockApplication {
    public static void main(String[] args) {
        SpringApplication.run(SmartLivestockApplication.class, args);
    }
}
```

- [x] **Step 3: 创建 application.yml**

`src/main/resources/application.yml`:
```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:smart_livestock}
    username: ${DB_USER:postgres}
    password: ${DB_PASSWORD:postgres}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}

rocketmq:
  name-server: ${ROCKETMQ_NAME_SERVER:localhost:9876}

jwt:
  secret: ${JWT_SECRET:default-secret-change-in-production}
  access-expiration: ${JWT_ACCESS_EXPIRATION:3600000}
  refresh-expiration: ${JWT_REFRESH_EXPIRATION:604800000}
```

`src/main/resources/application-test.yml`:
```yaml
spring:
  datasource:
    url: jdbc:tc:postgresql:16:///smart_livestock_test
  jpa:
    hibernate:
      ddl-auto: validate
  data:
    redis:
      host: localhost
      port: 6379
```

- [x] **Step 4: 创建共享内核 — AggregateRoot + DomainEvent + Entity**

`src/main/java/com/smartlivestock/shared/domain/DomainEvent.java`:
```java
package com.smartlivestock.shared.domain;

import java.time.Instant;
import java.util.UUID;

public abstract class DomainEvent {
    private final String eventId;
    private final Instant occurredAt;

    protected DomainEvent() {
        this.eventId = UUID.randomUUID().toString();
        this.occurredAt = Instant.now();
    }

    public String getEventId() { return eventId; }
    public Instant getOccurredAt() { return occurredAt; }
}
```

`src/main/java/com/smartlivestock/shared/domain/Entity.java`:
```java
package com.smartlivestock.shared.domain;

import java.util.Objects;

public abstract class Entity {
    private Long id;

    public Long getId() { return id; }
    void setId(Long id) { this.id = id; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Entity that = (Entity) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
```

`src/main/java/com/smartlivestock/shared/domain/AggregateRoot.java`:
```java
package com.smartlivestock.shared.domain;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public abstract class AggregateRoot extends Entity {
    private final List<DomainEvent> domainEvents = new ArrayList<>();

    protected void registerEvent(DomainEvent event) {
        domainEvents.add(event);
    }

    public List<DomainEvent> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    public void clearDomainEvents() {
        domainEvents.clear();
    }
}
```

- [x] **Step 5: 创建 ErrorCode 枚举 + ApiException**

`src/main/java/com/smartlivestock/shared/common/ErrorCode.java`:
```java
package com.smartlivestock.shared.common;

/**
 * 业务错误码枚举，与 API 契约 §2.3 对齐。
 * 序列化时 name() 输出大写 snake_case 字符串（如 "AUTH_TOKEN_EXPIRED"）。
 */
public enum ErrorCode {
    // 成功
    OK,
    // 400
    VALIDATION_ERROR,
    BAD_REQUEST,
    // 401
    AUTH_TOKEN_EXPIRED,
    AUTH_INVALID_TOKEN,
    AUTH_API_KEY_INVALID,
    AUTH_API_KEY_EXPIRED,
    // 403
    AUTH_FORBIDDEN,
    TENANT_DISABLED,
    QUOTA_EXCEEDED,
    LICENSE_EXPIRED,
    // 404
    RESOURCE_NOT_FOUND,
    // 409
    STATE_CONFLICT,
    DUPLICATE_RESOURCE,
    DEVICE_NOT_ACTIVE,
    // 410
    RESOURCE_DELETED,
    // 422
    FARM_SCOPE_CONFLICT,
    // 429
    RATE_LIMIT_EXCEEDED,
    // 500
    INTERNAL_ERROR
}
```

`src/main/java/com/smartlivestock/shared/common/ApiException.java`:
```java
package com.smartlivestock.shared.common;

public class ApiException extends RuntimeException {
    private final ErrorCode code;

    public ApiException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    public ErrorCode getCode() { return code; }
}
```

- [x] **Step 6: 验证项目编译**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [x] **Step 7: Commit**

```bash
git add smart-livestock-server/
git commit -m "feat(server): initialize Spring Boot project with shared kernel — AggregateRoot, DomainEvent, ErrorCode, ApiException"
```

---

## Task 2: Flyway 迁移脚本

**Files:**
- Create: `src/main/resources/db/migration/V1__create_identity_tables.sql`
- Create: `src/main/resources/db/migration/V2__create_ranch_tables.sql`
- Create: `src/main/resources/db/migration/V3__create_iot_tables.sql`

- [x] **Step 1: V1 — Identity 表**

`src/main/resources/db/migration/V1__create_identity_tables.sql`:
```sql
-- tenants
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    phase VARCHAR(10) NOT NULL DEFAULT 'SAMPLE',
    CONSTRAINT chk_tenants_phase CHECK (phase IN ('SAMPLE', 'BATCH')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- farms
CREATE TABLE farms (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    area_hectares DECIMAL(10,2),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_farms_tenant_id ON farms(tenant_id);

-- users
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(30) NOT NULL,
    CONSTRAINT chk_users_role CHECK (role IN ('OWNER', 'WORKER', 'PLATFORM_ADMIN', 'B2B_ADMIN', 'API_CONSUMER')),
    tenant_id BIGINT REFERENCES tenants(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_role ON users(role);

-- user_farm_assignments (replaces workers table)
CREATE TABLE user_farm_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    role VARCHAR(30) NOT NULL,
    CONSTRAINT chk_ufa_role CHECK (role IN ('OWNER', 'WORKER')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_ufa_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_farm UNIQUE (user_id, farm_id)
);
CREATE INDEX idx_ufa_farm_id ON user_farm_assignments(farm_id);
```

- [x] **Step 2: V2 — Ranch 表**

`src/main/resources/db/migration/V2__create_ranch_tables.sql`:
```sql
-- livestock
CREATE TABLE livestock (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_code VARCHAR(50) NOT NULL,
    breed VARCHAR(50),
    gender VARCHAR(10) CONSTRAINT chk_livestock_gender CHECK (gender IN ('MALE', 'FEMALE')),
    birth_date DATE,
    weight DECIMAL(7,2),
    health_status VARCHAR(20) NOT NULL DEFAULT 'HEALTHY',
    CONSTRAINT chk_livestock_health CHECK (health_status IN ('HEALTHY', 'WARNING', 'CRITICAL')),
    last_latitude DECIMAL(10,7),
    last_longitude DECIMAL(10,7),
    last_position_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_livestock_farm_id ON livestock(farm_id);
CREATE INDEX idx_livestock_health ON livestock(health_status);

-- fences
CREATE TABLE fences (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    name VARCHAR(100) NOT NULL,
    vertices JSONB NOT NULL,
    color VARCHAR(7),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_fences_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_fences_farm_id ON fences(farm_id);

-- alerts
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT REFERENCES livestock(id),
    fence_id BIGINT REFERENCES fences(id),
    type VARCHAR(30) NOT NULL,
    CONSTRAINT chk_alerts_type CHECK (type IN ('FENCE_BREACH', 'TEMPERATURE_ABNORMAL', 'BEHAVIOR_ABNORMAL', 'ESTRUS', 'EPIDEMIC')),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT chk_alerts_status CHECK (status IN ('PENDING', 'ACKNOWLEDGED', 'HANDLED', 'ARCHIVED')),
    severity VARCHAR(10) NOT NULL DEFAULT 'WARNING',
    CONSTRAINT chk_alerts_severity CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
    message TEXT,
    acknowledged_by BIGINT REFERENCES users(id),
    acknowledged_at TIMESTAMP,
    handled_by BIGINT REFERENCES users(id),
    handled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_alerts_farm_id ON alerts(farm_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_type ON alerts(type);
```

- [x] **Step 3: V3 — IoT 表**

`src/main/resources/db/migration/V3__create_iot_tables.sql`:
```sql
-- devices
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL,
    CONSTRAINT chk_devices_type CHECK (device_type IN ('EAR_TAG', 'TRACKER', 'CAPSULE', 'ACCELEROMETER')),
    status VARCHAR(20) NOT NULL DEFAULT 'INVENTORY',
    CONSTRAINT chk_devices_status CHECK (status IN ('INVENTORY', 'ACTIVE', 'OFFLINE', 'DECOMMISSIONED')),
    battery_level INTEGER,
    firmware_version VARCHAR(50),
    dev_eui VARCHAR(16),
    last_online_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_devices_tenant_id ON devices(tenant_id);
CREATE INDEX idx_devices_status ON devices(status);

-- device_licenses
CREATE TABLE device_licenses (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL UNIQUE REFERENCES devices(id),
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    license_key VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT chk_dl_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
    activated_at TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_dl_tenant_id ON device_licenses(tenant_id);

-- installations
-- Note: livestock_id is a cross-context reference, no FK constraint.
-- Consistency is enforced at the application layer.
CREATE TABLE installations (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    livestock_id BIGINT NOT NULL,
    installed_at TIMESTAMP NOT NULL,
    removed_at TIMESTAMP,
    operator_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_installations_active ON installations(device_id)
    WHERE removed_at IS NULL;
CREATE INDEX idx_installations_livestock ON installations(livestock_id);

-- gps_logs: JOIN path to livestock is gps_logs → devices → installations (WHERE removed_at IS NULL) → livestock
CREATE TABLE gps_logs (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,
    accuracy DECIMAL(6,2),
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_gps_logs_device_time ON gps_logs(device_id, recorded_at DESC);
```

- [x] **Step 4: V4 — 种子数据**

创建 `src/main/resources/db/migration/V4__seed_data.sql`，按 API 契约 §7 预置：
- platform_admin 用户（`phone: "13800000000"`, `password: "Admin@123"`）
- SAMPLE 租户（`name: "Demo牧场"`, `phase: SAMPLE`）
- owner 用户（`phone: "13800138000"`, `password: "Owner@123"`，归属 SAMPLE 租户）
- demo API Key（`sl_test_` 前缀，绑定 SAMPLE 租户）

所有密码使用 BCrypt 哈希，不可明文存储。

- [x] **Step 4.1: 软删除策略约定**

Phase 1 的 DELETE 端点统一使用 `deleted_at TIMESTAMPTZ` 列实现软删除，不将 DELETED 混入 status 枚举。理由：status 枚举表达领域状态（ACTIVE/DISABLED/INVENTORY 等），删除是生命周期管理，两者语义不同。

编码时需在 V2（farms、livestock）和 V3（devices）迁移脚本中为这三张表追加：
- `deleted_at TIMESTAMPTZ` 列（DEFAULT NULL）
- 部分唯一索引，例如 `UNIQUE (tenant_id, name) WHERE deleted_at IS NULL`，确保未删除记录的唯一性约束

其余表（alerts、gps_logs、installations、device_licenses）Phase 1 无删除操作，不加此列。

- [x] **Step 5: Commit**
```

---

## Task 3: Identity 领域模型（TDD）

**Files:**
- Create: `src/test/java/com/smartlivestock/identity/domain/model/UserTest.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/model/Role.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/model/TenantPhase.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/model/Tenant.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/model/User.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/model/Farm.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/event/TenantPhaseChangedEvent.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/repository/TenantRepository.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/repository/UserRepository.java`
- Create: `src/main/java/com/smartlivestock/identity/domain/repository/FarmRepository.java`

- [x] **Step 1: RED — 写 User 测试**

`src/test/java/com/smartlivestock/identity/domain/model/UserTest.java`:
```java
package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class UserTest {

    @Test
    void shouldCreateUserWithRequiredFields() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        assertThat(user.getUsername()).isEqualTo("zhangsan");
        assertThat(user.getName()).isEqualTo("张三");
        assertThat(user.getRole()).isEqualTo(Role.OWNER);
        assertThat(user.getTenantId()).isEqualTo(1L);
        assertThat(user.isActive()).isTrue();
    }

    @Test
    void shouldNotActivateInactiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThatThrownBy(user::activate)
            .isInstanceOf(ApiException.class)
            .extracting(e -> ((ApiException) e).getCode())
            .isEqualTo(ErrorCode.BAD_REQUEST);
    }

    @Test
    void shouldDeactivateActiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThat(user.isActive()).isFalse();
    }

    @Test
    void shouldNotDeactivateInactiveUser() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        user.deactivate();
        assertThatThrownBy(user::deactivate)
            .isInstanceOf(ApiException.class);
    }

    @Test
    void shouldRecordLastLogin() {
        User user = new User("zhangsan", "hashed_password", "张三", Role.OWNER, 1L);
        assertThat(user.getLastLoginAt()).isNull();
        user.recordLogin();
        assertThat(user.getLastLoginAt()).isNotNull();
    }

    @Test
    void shouldCheckRole() {
        User owner = new User("a", "p", "n", Role.OWNER, 1L);
        User worker = new User("b", "p", "n", Role.WORKER, 1L);
        assertThat(owner.isOwner()).isTrue();
        assertThat(worker.isOwner()).isFalse();
        assertThat(worker.isWorker()).isTrue();
    }

    @Test
    void shouldHavePlatformAdminWithNullTenant() {
        User admin = new User("admin", "p", "平台管理员", Role.PLATFORM_ADMIN, null);
        assertThat(admin.getTenantId()).isNull();
        assertThat(admin.getRole()).isEqualTo(Role.PLATFORM_ADMIN);
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd smart-livestock-server && ./gradlew test --tests "UserTest"`
Expected: FAIL (class not found)

- [x] **Step 3: GREEN — 实现枚举 + User + Tenant + Farm**

`src/main/java/com/smartlivestock/identity/domain/model/Role.java`:
```java
package com.smartlivestock.identity.domain.model;

public enum Role {
    OWNER, WORKER, PLATFORM_ADMIN, B2B_ADMIN, API_CONSUMER
}
```

`src/main/java/com/smartlivestock/identity/domain/model/TenantPhase.java`:
```java
package com.smartlivestock.identity.domain.model;

public enum TenantPhase {
    SAMPLE, BATCH
}
```

`src/main/java/com/smartlivestock/identity/domain/model/Tenant.java`:
```java
package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

public class Tenant extends AggregateRoot {
    private String name;
    private String contactName;
    private String contactPhone;
    private TenantPhase phase;

    public Tenant(String name) {
        this.name = name;
        this.phase = TenantPhase.SAMPLE;
    }

    public void transitionToBatch() {
        if (this.phase == TenantPhase.BATCH) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "租户已是 BATCH 阶段");
        }
        this.phase = TenantPhase.BATCH;
    }

    /** Reconstitute phase from persistence — does NOT fire domain events. */
    public void reconstitutePhase(TenantPhase phase) {
        this.phase = phase;
    }

    public String getName() { return name; }
    public String getContactName() { return contactName; }
    public String getContactPhone() { return contactPhone; }
    public TenantPhase getPhase() { return phase; }

    public void setContactName(String contactName) { this.contactName = contactName; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }
}
```

`src/main/java/com/smartlivestock/identity/domain/model/User.java`:
```java
package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

import java.time.Instant;

public class User extends AggregateRoot {
    private String username;
    private String passwordHash;
    private String name;
    private String phone;
    private Role role;
    private Long tenantId;
    private boolean active;
    private Instant lastLoginAt;

    public User(String username, String passwordHash, String name, Role role, Long tenantId) {
        this.username = username;
        this.passwordHash = passwordHash;
        this.name = name;
        this.role = role;
        this.tenantId = tenantId;
        this.active = true;
    }

    public void recordLogin() {
        this.lastLoginAt = Instant.now();
    }

    public void deactivate() {
        if (!active) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "用户已是停用状态");
        }
        this.active = false;
    }

    public void activate() {
        if (active) {
            throw new ApiException(ErrorCode.BAD_REQUEST, "用户已是启用状态");
        }
        this.active = true;
    }

    public boolean isOwner() { return role == Role.OWNER; }
    public boolean isWorker() { return role == Role.WORKER; }
    public boolean isPlatformAdmin() { return role == Role.PLATFORM_ADMIN; }

    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getName() { return name; }
    public String getPhone() { return phone; }
    public Role getRole() { return role; }
    public Long getTenantId() { return tenantId; }
    public boolean isActive() { return active; }
    public Instant getLastLoginAt() { return lastLoginAt; }

    public void setPhone(String phone) { this.phone = phone; }
}
```

`src/main/java/com/smartlivestock/identity/domain/model/Farm.java`:
```java
package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;

public class Farm extends AggregateRoot {
    private Long tenantId;
    private String name;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal areaHectares;

    public Farm(Long tenantId, String name) {
        this.tenantId = tenantId;
        this.name = name;
    }

    public Long getTenantId() { return tenantId; }
    public String getName() { return name; }
    public BigDecimal getLatitude() { return latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public BigDecimal getAreaHectares() { return areaHectares; }

    public void setName(String name) { this.name = name; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public void setAreaHectares(BigDecimal areaHectares) { this.areaHectares = areaHectares; }
}
```

`src/main/java/com/smartlivestock/identity/domain/event/TenantPhaseChangedEvent.java`:
```java
package com.smartlivestock.identity.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class TenantPhaseChangedEvent extends DomainEvent {
    private final Long tenantId;
    private final String newPhase;

    public TenantPhaseChangedEvent(Long tenantId, String newPhase) {
        this.tenantId = tenantId;
        this.newPhase = newPhase;
    }

    public Long getTenantId() { return tenantId; }
    public String getNewPhase() { return newPhase; }
}
```

`src/main/java/com/smartlivestock/identity/domain/repository/TenantRepository.java`:
```java
package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.Tenant;
import java.util.Optional;

public interface TenantRepository {
    Tenant save(Tenant tenant);
    Optional<Tenant> findById(Long id);
    boolean existsById(Long id);
}
```

`src/main/java/com/smartlivestock/identity/domain/repository/UserRepository.java`:
```java
package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.User;
import java.util.Optional;
import java.util.List;

public interface UserRepository {
    User save(User user);
    Optional<User> findById(Long id);
    Optional<User> findByPhone(String phone);
    Optional<User> findByUsername(String username);
    List<User> findByTenantId(Long tenantId);
}
```

`src/main/java/com/smartlivestock/identity/domain/repository/FarmRepository.java`:
```java
package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.Farm;
import java.util.List;
import java.util.Optional;

public interface FarmRepository {
    Farm save(Farm farm);
    Optional<Farm> findById(Long id);
    List<Farm> findByTenantId(Long tenantId);
    void deleteById(Long id);
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `./gradlew test --tests "UserTest"`
Expected: PASS (7 tests)

- [x] **Step 5: Commit**

```bash
git add src/main/java/com/smartlivestock/identity/ src/test/java/com/smartlivestock/identity/
git commit -m "feat(identity): add domain models — Tenant, User, Farm, Role, TenantPhase with TDD tests"
```

---

## Task 4: Ranch 领域模型（TDD）

**Files:**
- Create: `src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java`
- Create: `src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java`
- Create: `src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/AlertStatus.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/AlertType.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/HealthStatus.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/Severity.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/GpsCoordinate.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/Alert.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/Fence.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/model/Livestock.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/service/FenceBreachDetector.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/event/FenceBreachDetectedEvent.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/event/AlertStatusChangedEvent.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/repository/LivestockRepository.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/repository/FenceRepository.java`
- Create: `src/main/java/com/smartlivestock/ranch/domain/repository/AlertRepository.java`

- [x] **Step 1: RED — 写 Alert 状态机测试**

`src/test/java/com/smartlivestock/ranch/domain/model/AlertTest.java`:
```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class AlertTest {

    @Test
    void shouldCreatePendingAlert() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.PENDING);
        assertThat(alert.getFarmId()).isEqualTo(1L);
    }

    @Test
    void shouldTransitionPendingToAcknowledged() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        alert.acknowledge(100L);
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ACKNOWLEDGED);
        assertThat(alert.getAcknowledgedBy()).isEqualTo(100L);
        assertThat(alert.getAcknowledgedAt()).isNotNull();
    }

    @Test
    void shouldTransitionAcknowledgedToHandled() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        alert.acknowledge(100L);
        alert.handle(200L);
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.HANDLED);
        assertThat(alert.getHandledBy()).isEqualTo(200L);
    }

    @Test
    void shouldTransitionHandledToArchived() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        alert.acknowledge(100L);
        alert.handle(200L);
        alert.archive(100L);
        assertThat(alert.getStatus()).isEqualTo(AlertStatus.ARCHIVED);
    }

    @Test
    void shouldRejectAcknowledgeTwice() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        alert.acknowledge(100L);
        assertThatThrownBy(() -> alert.acknowledge(100L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("pending");
    }

    @Test
    void shouldRejectHandleOnPending() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        assertThatThrownBy(() -> alert.handle(200L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("acknowledged");
    }

    @Test
    void shouldRejectArchiveOnNonHandled() {
        Alert alert = new Alert(1L, AlertType.FENCE_BREACH, Severity.WARNING, "越界告警");
        assertThatThrownBy(() -> alert.archive(100L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("handled");
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "AlertTest"`
Expected: FAIL

- [x] **Step 3: RED — 写 Fence contains 测试**

`src/test/java/com/smartlivestock/ranch/domain/model/FenceTest.java`:
```java
package com.smartlivestock.ranch.domain.model;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class FenceTest {

    // 长沙附近矩形围栏
    private Fence createSquareFence() {
        List<GpsCoordinate> vertices = List.of(
            new GpsCoordinate("28.245", "112.850"),
            new GpsCoordinate("28.250", "112.850"),
            new GpsCoordinate("28.250", "112.855"),
            new GpsCoordinate("28.245", "112.855")
        );
        return new Fence(1L, "测试围栏", vertices);
    }

    @Test
    void shouldContainPointInsideFence() {
        Fence fence = createSquareFence();
        GpsCoordinate inside = new GpsCoordinate("28.2475", "112.8525");
        assertThat(fence.contains(inside)).isTrue();
    }

    @Test
    void shouldNotContainPointOutsideFence() {
        Fence fence = createSquareFence();
        GpsCoordinate outside = new GpsCoordinate("28.260", "112.860");
        assertThat(fence.contains(outside)).isFalse();
    }

    @Test
    void shouldContainPointOnEdge() {
        Fence fence = createSquareFence();
        GpsCoordinate onEdge = new GpsCoordinate("28.245", "112.852");
        assertThat(fence.contains(onEdge)).isTrue();
    }
}
```

- [x] **Step 4: RED — 写 FenceBreachDetector 测试**

`src/test/java/com/smartlivestock/ranch/domain/service/FenceBreachDetectorTest.java`:
```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class FenceBreachDetectorTest {

    private final FenceBreachDetector detector = new FenceBreachDetector();

    private Fence createSquareFence() {
        List<GpsCoordinate> vertices = List.of(
            new GpsCoordinate("28.245", "112.850"),
            new GpsCoordinate("28.250", "112.850"),
            new GpsCoordinate("28.250", "112.855"),
            new GpsCoordinate("28.245", "112.855")
        );
        return new Fence(1L, "测试围栏", vertices);
    }

    @Test
    void shouldDetectBreachWhenOutsideFence() {
        Fence fence = createSquareFence();
        GpsCoordinate outside = new GpsCoordinate("28.260", "112.860");
        assertThat(detector.isBreaching(fence, outside)).isTrue();
    }

    @Test
    void shouldNotDetectBreachWhenInsideFence() {
        Fence fence = createSquareFence();
        GpsCoordinate inside = new GpsCoordinate("28.2475", "112.8525");
        assertThat(detector.isBreaching(fence, inside)).isFalse();
    }

    @Test
    void shouldFindBreachedFenceFromMultiple() {
        Fence inside = createSquareFence();
        List<GpsCoordinate> outerVertices = List.of(
            new GpsCoordinate("28.240", "112.845"),
            new GpsCoordinate("28.255", "112.845"),
            new GpsCoordinate("28.255", "112.860"),
            new GpsCoordinate("28.240", "112.860")
        );
        Fence outer = new Fence(2L, "外层围栏", outerVertices);

        GpsCoordinate point = new GpsCoordinate("28.260", "112.860");
        List<Fence> breached = detector.findBreachedFences(List.of(inside, outer), point);
        assertThat(breached).hasSize(2);
    }
}
```

- [x] **Step 5: GREEN — 实现所有 Ranch 领域模型**

`src/main/java/com/smartlivestock/ranch/domain/model/GpsCoordinate.java`:
```java
package com.smartlivestock.ranch.domain.model;

import java.math.BigDecimal;

public record GpsCoordinate(BigDecimal latitude, BigDecimal longitude) {
    public GpsCoordinate(String lat, String lng) {
        this(new BigDecimal(lat), new BigDecimal(lng));
    }
}
```

`src/main/java/com/smartlivestock/ranch/domain/model/AlertStatus.java`:
```java
package com.smartlivestock.ranch.domain.model;

public enum AlertStatus {
    PENDING, ACKNOWLEDGED, HANDLED, ARCHIVED
}
```

`src/main/java/com/smartlivestock/ranch/domain/model/AlertType.java`:
```java
package com.smartlivestock.ranch.domain.model;

public enum AlertType {
    FENCE_BREACH, TEMPERATURE_ABNORMAL, BEHAVIOR_ABNORMAL, ESTRUS, EPIDEMIC
}
```

`src/main/java/com/smartlivestock/ranch/domain/model/HealthStatus.java`:
```java
package com.smartlivestock.ranch.domain.model;

public enum HealthStatus { HEALTHY, WARNING, CRITICAL }
```

`src/main/java/com/smartlivestock/ranch/domain/model/Severity.java`:
```java
package com.smartlivestock.ranch.domain.model;

public enum Severity { INFO, WARNING, CRITICAL }
```

`src/main/java/com/smartlivestock/ranch/domain/model/Alert.java`:
```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

public class Alert extends AggregateRoot {
    private Long farmId;
    private Long livestockId;
    private Long fenceId;
    private AlertType type;
    private AlertStatus status;
    private Severity severity;
    private String message;
    private Long acknowledgedBy;
    private Instant acknowledgedAt;
    private Long handledBy;
    private Instant handledAt;

    public Alert(Long farmId, AlertType type, Severity severity, String message) {
        this.farmId = farmId;
        this.type = type;
        this.severity = severity;
        this.message = message;
        this.status = AlertStatus.PENDING;
    }

    public void acknowledge(Long userId) {
        if (status != AlertStatus.PENDING) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "只有 pending 状态的告警可以确认");
        }
        this.status = AlertStatus.ACKNOWLEDGED;
        this.acknowledgedBy = userId;
        this.acknowledgedAt = Instant.now();
    }

    public void handle(Long userId) {
        if (status != AlertStatus.ACKNOWLEDGED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "只有 acknowledged 状态的告警可以处理");
        }
        this.status = AlertStatus.HANDLED;
        this.handledBy = userId;
        this.handledAt = Instant.now();
    }

    public void archive(Long userId) {
        if (status != AlertStatus.HANDLED) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "只有 handled 状态的告警可以归档");
        }
        this.status = AlertStatus.ARCHIVED;
    }

    // getters
    public Long getFarmId() { return farmId; }
    public Long getLivestockId() { return livestockId; }
    public Long getFenceId() { return fenceId; }
    public AlertType getType() { return type; }
    public AlertStatus getStatus() { return status; }
    public Severity getSeverity() { return severity; }
    public String getMessage() { return message; }
    public Long getAcknowledgedBy() { return acknowledgedBy; }
    public Instant getAcknowledgedAt() { return acknowledgedAt; }
    public Long getHandledBy() { return handledBy; }
    public Instant getHandledAt() { return handledAt; }

    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public void setFenceId(Long fenceId) { this.fenceId = fenceId; }
}
```

`src/main/java/com/smartlivestock/ranch/domain/model/Fence.java`:
```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.util.List;

public class Fence extends AggregateRoot {
    private Long farmId;
    private String name;
    private List<GpsCoordinate> vertices;
    private String color;
    private boolean active;

    public Fence(Long farmId, String name, List<GpsCoordinate> vertices) {
        this.farmId = farmId;
        this.name = name;
        this.vertices = vertices;
        this.active = true;
    }

    public boolean contains(GpsCoordinate point) {
        int n = vertices.size();
        if (n < 3) return false;

        boolean inside = false;
        for (int i = 0, j = n - 1; i < n; j = i++) {
            BigDecimal yi = vertices.get(i).latitude();
            BigDecimal xi = vertices.get(i).longitude();
            BigDecimal yj = vertices.get(j).latitude();
            BigDecimal xj = vertices.get(j).longitude();

            boolean cross = ((yi.compareTo(point.latitude()) > 0) != (yj.compareTo(point.latitude()) > 0))
                && point.longitude().compareTo(
                    xj.subtract(xi).multiply(point.latitude().subtract(yj))
                        .divide(yi.subtract(yj), 15, java.math.RoundingMode.HALF_UP)
                        .add(xj)
                ) < 0;
            if (cross) inside = !inside;
        }
        return inside;
    }

    // getters and setters
    public Long getFarmId() { return farmId; }
    public String getName() { return name; }
    public List<GpsCoordinate> getVertices() { return vertices; }
    public String getColor() { return color; }
    public boolean isActive() { return active; }
    public void setName(String name) { this.name = name; }
    public void setVertices(List<GpsCoordinate> vertices) { this.vertices = vertices; }
    public void setColor(String color) { this.color = color; }
    public void disable() { this.active = false; }
    public void enable() { this.active = true; }
}
```

`src/main/java/com/smartlivestock/ranch/domain/model/Livestock.java`:
```java
package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public class Livestock extends AggregateRoot {
    private Long farmId;
    private String livestockCode;
    private String breed;
    private String gender;
    private LocalDate birthDate;
    private BigDecimal weight;
    private HealthStatus healthStatus;
    private BigDecimal lastLatitude;
    private BigDecimal lastLongitude;
    private Instant lastPositionAt;

    public Livestock(Long farmId, String livestockCode) {
        this.farmId = farmId;
        this.livestockCode = livestockCode;
        this.healthStatus = HealthStatus.HEALTHY;
    }

    public void updatePosition(BigDecimal lat, BigDecimal lng) {
        this.lastLatitude = lat;
        this.lastLongitude = lng;
        this.lastPositionAt = Instant.now();
    }

    public void markWarning() { this.healthStatus = HealthStatus.WARNING; }
    public void markCritical() { this.healthStatus = HealthStatus.CRITICAL; }
    public void markHealthy() { this.healthStatus = HealthStatus.HEALTHY; }

    // getters and setters
    public Long getFarmId() { return farmId; }
    public String getLivestockCode() { return livestockCode; }
    public String getBreed() { return breed; }
    public String getGender() { return gender; }
    public LocalDate getBirthDate() { return birthDate; }
    public BigDecimal getWeight() { return weight; }
    public HealthStatus getHealthStatus() { return healthStatus; }
    public BigDecimal getLastLatitude() { return lastLatitude; }
    public BigDecimal getLastLongitude() { return lastLongitude; }
    public Instant getLastPositionAt() { return lastPositionAt; }
    public void setBreed(String breed) { this.breed = breed; }
    public void setGender(String gender) { this.gender = gender; }
    public void setBirthDate(LocalDate birthDate) { this.birthDate = birthDate; }
    public void setWeight(BigDecimal weight) { this.weight = weight; }
}
```

`src/main/java/com/smartlivestock/ranch/domain/service/FenceBreachDetector.java`:
```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;
import java.util.stream.Collectors;

public class FenceBreachDetector {

    public boolean isBreaching(Fence fence, GpsCoordinate point) {
        return !fence.contains(point);
    }

    public List<Fence> findBreachedFences(List<Fence> fences, GpsCoordinate point) {
        return fences.stream()
            .filter(f -> f.isActive())
            .filter(f -> isBreaching(f, point))
            .collect(Collectors.toList());
    }
}
```

`src/main/java/com/smartlivestock/ranch/domain/event/FenceBreachDetectedEvent.java`:
```java
package com.smartlivestock.ranch.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class FenceBreachDetectedEvent extends DomainEvent {
    private final Long fenceId;
    private final Long livestockId;

    public FenceBreachDetectedEvent(Long fenceId, Long livestockId) {
        this.fenceId = fenceId;
        this.livestockId = livestockId;
    }

    public Long getFenceId() { return fenceId; }
    public Long getLivestockId() { return livestockId; }
}
```

`src/main/java/com/smartlivestock/ranch/domain/event/AlertStatusChangedEvent.java`:
```java
package com.smartlivestock.ranch.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class AlertStatusChangedEvent extends DomainEvent {
    private final Long alertId;
    private final String newStatus;

    public AlertStatusChangedEvent(Long alertId, String newStatus) {
        this.alertId = alertId;
        this.newStatus = newStatus;
    }

    public Long getAlertId() { return alertId; }
    public String getNewStatus() { return newStatus; }
}
```

Repository interfaces (follow Identity pattern):

`src/main/java/com/smartlivestock/ranch/domain/repository/LivestockRepository.java`:
```java
package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Livestock;
import java.util.List;
import java.util.Optional;

public interface LivestockRepository {
    Livestock save(Livestock livestock);
    Optional<Livestock> findById(Long id);
    List<Livestock> findByFarmId(Long farmId);
    Optional<Livestock> findByLivestockCode(String livestockCode);
    void deleteById(Long id);
}
```

`src/main/java/com/smartlivestock/ranch/domain/repository/FenceRepository.java`:
```java
package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Fence;
import java.util.List;
import java.util.Optional;

public interface FenceRepository {
    Fence save(Fence fence);
    Optional<Fence> findById(Long id);
    List<Fence> findByFarmId(Long farmId);
    void deleteById(Long id);
}
```

`src/main/java/com/smartlivestock/ranch/domain/repository/AlertRepository.java`:
```java
package com.smartlivestock.ranch.domain.repository;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import java.util.List;
import java.util.Optional;

public interface AlertRepository {
    Alert save(Alert alert);
    Optional<Alert> findById(Long id);
    List<Alert> findByFarmId(Long farmId);
    List<Alert> findByFarmIdAndStatus(Long farmId, AlertStatus status);
}
```

- [x] **Step 6: Run all Ranch tests**

Run: `./gradlew test --tests "ranch.*"`
Expected: PASS

- [x] **Step 7: Commit**

```bash
git add src/main/java/com/smartlivestock/ranch/ src/test/java/com/smartlivestock/ranch/
git commit -m "feat(ranch): add domain models — Alert, Fence, Livestock, FenceBreachDetector with TDD tests"
```

---

## Task 5: IoT 领域模型（TDD）

**Files:**
- Create: `src/test/java/com/smartlivestock/iot/domain/model/DeviceTest.java`
- Create: `src/test/java/com/smartlivestock/iot/domain/model/DeviceLicenseTest.java`
- Create: `src/test/java/com/smartlivestock/iot/domain/model/InstallationTest.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/DeviceType.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/DeviceStatus.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/LicenseStatus.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/Device.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/DeviceLicense.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/Installation.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/model/GpsLog.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/event/GpsLogUpdatedEvent.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/event/DeviceActivatedEvent.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/event/LicenseExpiredEvent.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/repository/DeviceRepository.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/repository/DeviceLicenseRepository.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/repository/InstallationRepository.java`
- Create: `src/main/java/com/smartlivestock/iot/domain/repository/GpsLogRepository.java`

遵循 Task 3/4 的 TDD 模式：先写测试 → 确认失败 → 实现领域模型 → 确认通过 → 提交。

**测试覆盖要求：**

| 测试类 | 测试用例 |
|--------|---------|
| `DeviceTest` | 创建设备(INVENTORY)、INVENTORY→ACTIVE、ACTIVE→OFFLINE、非法状态转换拒绝 |
| `DeviceLicenseTest` | 许可证有效期判断(isValid/isExpired)、撤销、过期后状态 |
| `InstallationTest` | 安装到牲畜、拆除(设置removedAt)、不允许重复激活安装 |

**领域模型关键规则：**

```java
// Device 状态转换: INVENTORY → ACTIVE → OFFLINE → DECOMMISSIONED
// 只有 INVENTORY 可以 activate()
// 只有 ACTIVE 可以 markOffline()
// Device 还有运行时状态 runtimeStatus（online/offline/low_battery），由心跳更新

// DeviceLicense.isExpired(): Instant.now().isAfter(expiresAt)
// DeviceLicense.revoke(): status → REVOKED
// Installation.remove(): 设置 removedAt = Instant.now()
```

- [x] **Step 1: RED — 写测试**
- [x] **Step 2: Run tests to verify failure**
- [x] **Step 3: GREEN — 实现 Device, DeviceLicense, Installation, GpsLog + 枚举 + 事件 + Repository 接口**
- [x] **Step 4: Run tests to verify pass**
- [x] **Step 5: Commit**

```bash
git commit -m "feat(iot): add domain models — Device, DeviceLicense, Installation, GpsLog with TDD tests"
```

---

## Task 6: FarmScope 解析器（TDD）

**Files:**
- Create: `src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java`
- Create: `src/main/java/com/smartlivestock/shared/scope/FarmScopeType.java`
- Create: `src/main/java/com/smartlivestock/shared/scope/FarmScopeResolver.java`

- [x] **Step 1: RED — 写 FarmScopeResolver 测试**

`src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java`:
```java
package com.smartlivestock.shared.scope;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class FarmScopeResolverTest {

    private final FarmScopeResolver resolver = new FarmScopeResolver();

    // === Write scope ===

    @Test
    void shouldResolveWriteScopeFromPath() {
        Long farmId = resolver.resolve(FarmScopeType.WRITE, 1L, null);
        assertThat(farmId).isEqualTo(1L);
    }

    @Test
    void shouldRejectWriteScopeWithOnlyHeader() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.WRITE, null, 1L))
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("path");
    }

    @Test
    void shouldRejectWriteScopeWithBothSources() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.WRITE, 1L, 2L))
            .isInstanceOf(ApiException.class)
            .extracting(e -> ((ApiException) e).getCode())
            .isEqualTo(ErrorCode.FARM_SCOPE_CONFLICT);
    }

    // === Read scope ===

    @Test
    void shouldResolveReadScopeFromPath() {
        Long farmId = resolver.resolve(FarmScopeType.READ, 1L, null);
        assertThat(farmId).isEqualTo(1L);
    }

    @Test
    void shouldResolveReadScopeFromHeaderOnly() {
        Long farmId = resolver.resolve(FarmScopeType.READ, null, 2L);
        assertThat(farmId).isEqualTo(2L);
    }

    @Test
    void shouldRejectReadScopeWithBothSources() {
        assertThatThrownBy(() -> resolver.resolve(FarmScopeType.READ, 1L, 2L))
            .isInstanceOf(ApiException.class);
    }

    // === No scope ===

    @Test
    void shouldReturnNullForNoScope() {
        Long farmId = resolver.resolve(FarmScopeType.NONE, null, null);
        assertThat(farmId).isNull();
    }
}
```

- [x] **Step 2: Run test to verify failure**
- [x] **Step 3: GREEN — 实现 FarmScopeType + FarmScopeResolver**

`src/main/java/com/smartlivestock/shared/scope/FarmScopeType.java`:
```java
package com.smartlivestock.shared.scope;

public enum FarmScopeType {
    WRITE, READ, NONE
}
```

`src/main/java/com/smartlivestock/shared/scope/FarmScopeResolver.java`:
```java
package com.smartlivestock.shared.scope;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;

public class FarmScopeResolver {

    public Long resolve(FarmScopeType type, Long pathFarmId, Long headerFarmId) {
        return switch (type) {
            case WRITE -> resolveWrite(pathFarmId, headerFarmId);
            case READ -> resolveRead(pathFarmId, headerFarmId);
            case NONE -> null;
        };
    }

    private Long resolveWrite(Long pathFarmId, Long headerFarmId) {
        if (pathFarmId != null && headerFarmId != null) {
            throw new ApiException(ErrorCode.FARM_SCOPE_CONFLICT,
                "写操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "写操作必须通过 /farms/{farmId}/... 路径指定牧场");
        }
        return pathFarmId;
    }

    private Long resolveRead(Long pathFarmId, Long headerFarmId) {
        if (pathFarmId != null && headerFarmId != null) {
            throw new ApiException(ErrorCode.FARM_SCOPE_CONFLICT,
                "读操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId != null) return pathFarmId;
        if (headerFarmId != null) return headerFarmId;
        throw new ApiException(ErrorCode.VALIDATION_ERROR,
            "读操作需要通过 path 或 header 指定牧场");
    }
}
```

- [x] **Step 4: Run tests**
- [x] **Step 5: Commit**

```bash
git commit -m "feat(shared): add FarmScopeResolver with strict path/header validation — TDD"
```

---

## Task 7: Persistence 层（所有上下文）

**Files:** 每个 JPA Entity + Spring Data Repository + Mapper + Repository Impl（共约 40 个文件，见文件结构总览）

此 Task 为重复性工作，每个聚合根遵循相同模式。以下以 Identity 的 Tenant 为例展示完整流程，其余按相同模式复制。

- [x] **Step 1: 实现 Tenant 的 JPA Entity**

`src/main/java/com/smartlivestock/identity/infrastructure/persistence/entity/TenantJpaEntity.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "tenants")
public class TenantJpaEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    @Column(name = "contact_name")
    private String contactName;
    @Column(name = "contact_phone")
    private String contactPhone;
    private String phase;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = Instant.now(); updatedAt = Instant.now(); }
    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }

    // getters and setters
}
```

- [x] **Step 2: 实现 Spring Data Repository**

`src/main/java/com/smartlivestock/identity/infrastructure/persistence/SpringDataTenantRepository.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataTenantRepository extends JpaRepository<TenantJpaEntity, Long> {
}
```

- [x] **Step 3: 实现 Mapper**

`src/main/java/com/smartlivestock/identity/infrastructure/persistence/mapper/TenantMapper.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.model.TenantPhase;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;

public class TenantMapper {
    public static TenantJpaEntity toJpaEntity(Tenant domain) {
        TenantJpaEntity jpa = new TenantJpaEntity();
        jpa.setId(domain.getId());
        jpa.setName(domain.getName());
        jpa.setContactName(domain.getContactName());
        jpa.setContactPhone(domain.getContactPhone());
        jpa.setPhase(domain.getPhase().name());
        return jpa;
    }

    public static Tenant toDomain(TenantJpaEntity jpa) {
        Tenant domain = new Tenant(jpa.getName());
        domain.setId(jpa.getId());
        domain.setContactName(jpa.getContactName());
        domain.setContactPhone(jpa.getContactPhone());
        if (jpa.getPhase() != null) {
            domain.reconstitutePhase(TenantPhase.valueOf(jpa.getPhase()));
        }
        return domain;
    }
}
```

- [x] **Step 4: 实现 Repository Adapter**

`src/main/java/com/smartlivestock/identity/infrastructure/persistence/JpaTenantRepositoryImpl.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.mapper.TenantMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaTenantRepositoryImpl implements TenantRepository {
    private final SpringDataTenantRepository springDataRepo;

    @Override
    public Tenant save(Tenant tenant) {
        return TenantMapper.toDomain(springDataRepo.save(TenantMapper.toJpaEntity(tenant)));
    }

    @Override
    public Optional<Tenant> findById(Long id) {
        return springDataRepo.findById(id).map(TenantMapper::toDomain);
    }

    @Override
    public boolean existsById(Long id) {
        return springDataRepo.existsById(id);
    }
}
```

- [x] **Step 5: 对 User, Farm, UserFarmAssignment 重复 Step 1-4**
- [x] **Step 6: 对 Ranch 上下文 (Livestock, Fence, Alert) 重复 Step 1-4**
- [x] **Step 7: 对 IoT 上下文 (Device, DeviceLicense, Installation, GpsLog) 重复 Step 1-4**
- [x] **Step 8: 验证 Flyway + JPA 启动成功**

Run: `./gradlew bootRun` (需要本地 PostgreSQL 或用 Testcontainers)
Expected: Application starts, Flyway runs V1-V3, no validation errors

- [x] **Step 9: Commit**

```bash
git commit -m "feat: add persistence layer for all contexts — JPA entities, mappers, repository adapters"
```

---

## Task 8: Application Services 层

**Files:** 7 个 ApplicationService + Command/DTO 类

- [x] **Step 1: 实现 AuthApplicationService**

`src/main/java/com/smartlivestock/identity/application/service/AuthApplicationService.java`:
```java
package com.smartlivestock.identity.application.service;

import com.smartlivestock.identity.application.command.LoginCommand;
import com.smartlivestock.identity.application.dto.AuthTokenDto;
import com.smartlivestock.identity.application.dto.UserDto;
import com.smartlivestock.identity.domain.model.User;
import com.smartlivestock.identity.domain.repository.UserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.JwtTokenProvider;
import com.smartlivestock.shared.security.PasswordHasher;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthApplicationService {
    private final UserRepository userRepository;
    private final PasswordHasher passwordHasher;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional(readOnly = true)
    public AuthTokenDto login(LoginCommand command) {
        User user = userRepository.findByPhone(command.phone())
            .orElseThrow(() -> new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "手机号或密码错误"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "用户已停用");
        }
        if (!passwordHasher.matches(command.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "手机号或密码错误");
        }
        user.recordLogin();
        userRepository.save(user);
        String token = jwtTokenProvider.generateToken(user.getId(), user.getTenantId(), user.getRole().name());
        return new AuthTokenDto(token, UserDto.from(user));
    }
}
```

- [x] **Step 2: 实现 TenantApplicationService, FarmApplicationService**
- [x] **Step 3: 实现 LivestockApplicationService, FenceApplicationService, AlertApplicationService**
- [x] **Step 4: 实现 DeviceApplicationService, DeviceLicenseApplicationService, InstallationApplicationService, GpsLogApplicationService**
- [x] **Step 5: 实现 Command 和 DTO 类**
- [x] **Step 6: Commit**

```bash
git commit -m "feat: add application services for all contexts — auth, tenant, farm, livestock, fence, alert, device, license, installation, gps"
```

---

## Task 9: Security + JWT

**Files:**
- Create: `src/main/java/com/smartlivestock/shared/security/JwtTokenProvider.java`
- Create: `src/main/java/com/smartlivestock/shared/security/JwtAuthenticationFilter.java`
- Create: `src/main/java/com/smartlivestock/shared/security/SecurityConfig.java`
- Create: `src/main/java/com/smartlivestock/shared/security/PasswordHasher.java`
- Create: `src/main/java/com/smartlivestock/shared/tenant/TenantContext.java`
- Create: `src/main/java/com/smartlivestock/shared/common/GlobalExceptionHandler.java`
- Create: `src/main/java/com/smartlivestock/shared/common/ApiResponse.java`

- [x] **Step 1: 实现 JwtTokenProvider**

生成/解析 JWT token。Payload 含 `sub`(userId), `tid`(tenantId), `role`。

- [x] **Step 2: 实现 JwtAuthenticationFilter**

从 Authorization header 提取 token，解析后设置 SecurityContext。

- [x] **Step 3: 实现 SecurityConfig**

配置 Spring Security：公开 `/api/v1/auth/login`，其余需认证。

- [x] **Step 4: 实现 PasswordHasher**

BCrypt 封装，供 AuthApplicationService 使用。

- [x] **Step 5: 实现 TenantContext**

ThreadLocal 持有当前请求的 tenantId，由 Filter 设置。

- [x] **Step 6: 实现 GlobalExceptionHandler + ApiResponse**

统一错误响应格式：`{ code, message, requestId }`

- [x] **Step 7: 验证登录流程可端到端运行**

- [x] **Step 8: Commit**

```bash
git commit -m "feat(security): add JWT auth, BCrypt, SecurityConfig, TenantContext, GlobalExceptionHandler"
```

---

## Task 9.5: Redis Cache 基础设施

**Files:**
- Create: `src/main/java/com/smartlivestock/shared/cache/RedisCacheService.java`
- Create: `src/main/java/com/smartlivestock/shared/cache/CacheKeys.java`

- [x] **Step 1: 实现 CacheKeys**

`src/main/java/com/smartlivestock/shared/cache/CacheKeys.java`:
```java
package com.smartlivestock.shared.cache;

public class CacheKeys {
    public static String livestockPosition(Long id) { return "livestock:position:" + id; }
    public static String farmMembers(Long farmId) { return "farm:" + farmId + ":members"; }
    public static String deviceOnline(Long id) { return "device:online:" + id; }
    public static String jwtBlacklist(String token) { return "jwt:blacklist:" + token; }
    public static String rateLimit(Long userId, String endpoint) {
        return "ratelimit:" + userId + ":" + endpoint;
    }
}
```

- [x] **Step 2: 实现 RedisCacheService**

`src/main/java/com/smartlivestock/shared/cache/RedisCacheService.java`:
```java
package com.smartlivestock.shared.cache;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RedisCacheService {
    private final StringRedisTemplate redis;

    public void set(String key, String value, Duration ttl) {
        redis.opsForValue().set(key, value, ttl);
    }

    public String get(String key) {
        return redis.opsForValue().get(key);
    }

    public void setHash(String key, Map<String, String> fields) {
        redis.opsForHash().putAll(key, fields);
    }

    public String getHashField(String key, String field) {
        return (String) redis.opsForHash().get(key, field);
    }

    public void addToSet(String key, String... values) {
        redis.opsForSet().add(key, values);
    }

    public Set<String> getSet(String key) {
        return redis.opsForSet().members(key);
    }

    public void delete(String key) {
        redis.delete(key);
    }

    public boolean setIfAbsent(String key, String value, Duration ttl) {
        return Boolean.TRUE.equals(redis.opsForValue().setIfAbsent(key, value, ttl));
    }
}
```

- [x] **Step 3: Commit**

```bash
git commit -m "feat(shared): add Redis cache infrastructure — CacheKeys, RedisCacheService"
```

---

## Task 10: 跨上下文事件桥接

**Files:**
- Create: `src/main/java/com/smartlivestock/shared/messaging/RocketMQEventPublisher.java`
- Create: `src/main/java/com/smartlivestock/shared/messaging/Topics.java`
- Create: `src/main/java/com/smartlivestock/iot/infrastructure/event/SpringEventPublisher.java`
- Create: `src/main/java/com/smartlivestock/ranch/infrastructure/event/GpsLogEventHandler.java`

- [x] **Step 1: 实现 Spring Event → RocketMQ 桥接**

Application Service 发布 Spring ApplicationEvent → SpringEventPublisher 监听 → 转发到 RocketMQ Topic。

- [x] **Step 2: 实现 GpsLogEventHandler**

Ranch 上下文消费 `gps-log-updated` Topic：
1. 收到 GPS 坐标 + livestockId
2. 查询该 livestock 关联的所有 active fence
3. FenceBreachDetector 判定越界
4. 若越界，创建 Alert

**跨上下文引用一致性约定：** 跨上下文无 FK 约束的引用（如 `installations.livestock_id`），由 ApplicationService 在执行操作前通过本上下文的 Repository 查询验证存在性。不存在则抛出 `RESOURCE_NOT_FOUND`。不跨上下文直连 Repository，一致性通过 Anti-Corruption Layer 查询接口保证。

- [x] **Step 3: 验证事件流可端到端运行**

- [x] **Step 4: Commit**

```bash
git commit -m "feat: add cross-context event bridge — RocketMQ publisher, GPS→Alert flow"
```

---

## Task 11: API Controllers

**状态: 解除阻塞 — API 契约设计已完成**

**Files:** 所有 Context 的 Controller 类

基于 [多端统一 API 契约总览](../../api-contracts/api-overview.md) 实现三端 Controller：

**App API (`/api/v1/`) — 49 端点:**
- Identity: AuthController (login/refresh/logout), MeController (/me, /me/password), TenantController (/tenants/me), FarmController (/farms CRUD + members)
- Ranch: LivestockController, FenceController, AlertController (含状态转换 + batch-handle)
- IoT: DeviceController, DeviceLicenseController (/device-licenses，租户级，不走 Farm Scope), InstallationController, GpsLogController
- Read Models: DashboardController, MapController

**Admin API (`/api/v1/admin/`) — 21 端点:**
- TenantAdminController, UserAdminController, FarmAdminController, DashboardAdminController, AuditLogController, ApiKeyAdminController

**Open API (`/api/v1/open/`) — 11 端点:**
- OpenLivestockController, OpenFenceController, OpenAlertController, OpenDeviceController, OpenGpsController, OpenDeviceRegisterController

每个 Controller 使用 FarmScopeResolver 强制作用域规则。错误码使用更新后的 ErrorCode 枚举（对齐契约 §2.3）。

---

## Task 12: 集成测试

**Files:**
- Create: `src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java`
- Create: 其他集成测试（见规格 6.4-6.5）

- [x] **Step 1: 实现 GpsAlertFlowTest — GPS 上报→越界→自动生成告警**

端到端集成测试，验证 IoT → RocketMQ → Ranch 完整事件流。

- [x] **Step 2: 实现其他集成测试**

使用 Testcontainers（PostgreSQL + Redis），验证 ApplicationService 层的事务和持久化。

- [x] **Step 3: Run all tests**

Run: `./gradlew test`
Expected: ALL PASS

- [x] **Step 4: Commit**

```bash
git commit -m "test: add integration tests — GPS→Alert flow, ApplicationService integration"
```

---

## Task 13: Docker Compose + 部署

**Files:**
- Create: `smart-livestock-server/docker-compose.yml`
- Create: `smart-livestock-server/Dockerfile`
- Create: `smart-livestock-server/.env.example`
- Create: `smart-livestock-server/infrastructure/nginx/nginx.conf`

- [x] **Step 1: 编写 Dockerfile**

多阶段构建：Gradle build → JRE 运行。

- [x] **Step 2: 编写 docker-compose.yml**

包含 PostgreSQL 16 + Redis 7 + RocketMQ 5.1 (namesrv + broker) + App + Nginx。完整配置见规格第 5 节。

- [x] **Step 3: 编写 Nginx 配置**

反向代理 `/api/v1/` → app:8080。

- [x] **Step 4: 本地验证 `docker-compose up`**

- [x] **Step 5: Commit**

```bash
git commit -m "ops: add Docker Compose deployment — PostgreSQL, Redis, RocketMQ, Nginx"
```

---

## Task 14: GPS 模拟数据生成器

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/service/GpsSimulator.java`

- [x] **Step 1: 实现 GpsSimulator**

定时任务（@Scheduled），为已安装的设备生成模拟 GPS 坐标：
- 读取所有 active device 的 installation
- 基于牧场中心点 + 随机偏移生成 GPS 坐标
- 调用 GpsLogApplicationService 批量上报

- [x] **Step 2: Commit**

```bash
git commit -m "feat(iot): add GPS simulator for Phase 1 mock data generation"
```

---

## Task 15: GitLab 仓库 + CI/CD

**代码托管策略：双远程模式**

- **GitHub** (`github.com/aime4eve/smart-livestock`): 代码主仓库，PR/Issue 协作
- **GitLab** (`172.22.1.123`): CI/CD Pipeline + 内网 Docker 部署

**当前 GitLab 状态（已探明）：**

| 项目 | 状态 |
|------|------|
| 目标群组 `hkt-agentic/solutions/smart-agriculture/smart-livestock` | **已存在** (id=238) |
| 群组下现有项目 | `frontend`（有内容）、`docs`（空）、`shared-components`（空） |
| `smart-livestock-server` 项目 | **不存在，需创建** |
| 活跃 GitLab Runner | **无，需部署**（无 Runner 则 CI/CD Pipeline 无法执行） |
| GitLab API 自动化脚本 | `gitlab-automation/` 中已有（python-gitlab），token 已配置 |

**前置依赖:** Task 13（Docker Compose）完成后才能验证 CI/CD 部署步骤。

**Files:**
- Create: `.gitlab-ci.yml`
- Create: GitLab Runner 部署配置
- 复用: `/Users/hkt/wzy/产品设计/hkt-agent-ss/系统架构/gitlab-automation/` 中的 GitLab API 工具

- [ ] **Step 0: 部署 GitLab Runner（前置阻塞）**

CI/CD Pipeline 需要 Runner 执行 Job。在能访问 Docker 的机器上（推荐 `172.22.1.123` 本机）部署：

```bash
# 在 172.22.1.123 上以 Docker 方式启动 Runner
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

# 注册 Runner（URL 和 token 从 GitLab Admin → CI/CD → Runners 获取）
docker exec -it gitlab-runner gitlab-runner register \
  --url http://172.22.1.123 \
  --registration-token <REGISTRATION_TOKEN> \
  --executor docker \
  --docker-image alpine:3.19 \
  --description "smart-livestock-runner"
```

Runner 使用 `docker` executor，与 `.gitlab-ci.yml` 中 `image: eclipse-temurin:17-jdk` 兼容。

- [ ] **Step 1: 在 GitLab 创建 smart-livestock-server 项目**

目标位置：`hkt-agentic/solutions/smart-agriculture/smart-livestock/smart-livestock-server`

群组已存在（id=238），只需创建项目。使用自动化脚本：

```bash
cd "/Users/hkt/wzy/产品设计/hkt-agent-ss/系统架构/gitlab-automation"
# 在 data/gitlab-structure.yml 的 smart-livestock 群组下 projects 列表中添加：
#   projects:
#   - path: smart-livestock-server
#     description: MVP Phase 1 Spring Boot 后端 — Identity + Ranch + IoT
#     v57_ref: §3.5.2
#     phase: P6
# 然后执行：
python3 scripts/gitlab_manager.py --phase P6 --execute
```

或直接用 API 一次性创建：
```bash
curl --request POST "http://172.22.1.123/api/v4/projects" \
  --header "PRIVATE-TOKEN: glpat-pVIUWLG6CNj4rOZHuUBmq286MQp1OmEH.01.0w0hcplhu" \
  --data "name=smart-livestock-server&namespace_id=238&visibility=private"
```

- [ ] **Step 2: 配置双远程推送**

```bash
cd smart-livestock-server
# GitHub 已是 origin（Task 1 创建项目时设置）
git remote add gitlab \
  http://172.22.1.123/hkt-agentic/solutions/smart-agriculture/smart-livestock/smart-livestock-server.git
# 推送到 GitLab
git push -u gitlab master
```

推送策略：`git push origin master`（GitHub）+ `git push gitlab master`（触发 CI/CD）。

- [ ] **Step 3: 编写 .gitlab-ci.yml**

```yaml
stages:
  - build
  - test
  - docker
  - deploy

variables:
  DOCKER_REGISTRY: 172.22.1.123:5000
  IMAGE_NAME: smart-livestock-server
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

build:
  stage: build
  image: eclipse-temurin:17-jdk
  script:
    - ./gradlew compileJava
  cache:
    key: gradle-$CI_COMMIT_REF_SLUG
    paths:
      - .gradle/
      - build/

test:
  stage: test
  image: eclipse-temurin:17-jdk
  services:
    - postgres:16
    - redis:7
  variables:
    DB_HOST: postgres
    DB_PORT: 5432
    DB_NAME: smart_livestock_test
    DB_USER: postgres
    DB_PASSWORD: postgres
    REDIS_HOST: redis
    REDIS_PORT: 6379
  script:
    - ./gradlew test
  artifacts:
    reports:
      junit: build/test-results/test/TEST-*.xml

docker-build:
  stage: docker
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
    - docker push $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
  only:
    - master

deploy:
  stage: deploy
  image: alpine:3.19
  before_script:
    - apk add --no-cache openssh-client sshpass
  script:
    - sshpass -p $SSH_PASSWORD ssh -o StrictHostKeyChecking=no root@172.22.1.123 "
        cd /opt/smart-livestock &&
        IMAGE_TAG=$IMAGE_TAG docker compose up -d"
  only:
    - master
  when: manual
```

- [ ] **Step 4: 配置 GitLab CI Variables**

在 GitLab Project `Settings → CI/CD → Variables` 中添加：

| Variable | 说明 |
|----------|------|
| `SSH_PASSWORD` | 部署服务器 SSH 密码 |
| `DOCKER_REGISTRY` | 内网 Docker Registry（若非默认 5000 端口） |

- [ ] **Step 5: 验证**

```bash
git push gitlab master  # 触发 Pipeline
# 在 GitLab CI/CD → Pipelines 查看 build → test → docker 阶段
# 手动触发 deploy 阶段，验证 Docker Compose 部署
```

- [ ] **Step 6: Commit**

```bash
git commit -m "ops: add GitLab CI/CD pipeline — build, test, docker, deploy to 172.22.1.123"
```

```yaml
# smart-livestock-server CI/CD
# 触发条件：master 分支 push、MR

stages:
  - build
  - test
  - docker
  - deploy

variables:
  DOCKER_REGISTRY: 172.22.1.123:5000
  IMAGE_NAME: smart-livestock-server
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

build:
  stage: build
  image: eclipse-temurin:17-jdk
  script:
    - ./gradlew compileJava
  cache:
    key: gradle-$CI_COMMIT_REF_SLUG
    paths:
      - .gradle/
      - build/

test:
  stage: test
  image: eclipse-temurin:17-jdk
  services:
    - postgres:16
    - redis:7
  variables:
    DB_HOST: postgres
    DB_PORT: 5432
    DB_NAME: smart_livestock_test
    DB_USER: postgres
    DB_PASSWORD: postgres
    REDIS_HOST: redis
    REDIS_PORT: 6379
  script:
    - ./gradlew test
  artifacts:
    reports:
      junit: build/test-results/test/TEST-*.xml

docker-build:
  stage: docker
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
    - docker push $DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
  only:
    - master

deploy:
  stage: deploy
  image: alpine:3.19
  before_script:
    - apk add --no-cache openssh-client sshpass
  script:
    - sshpass -p $SSH_PASSWORD ssh -o StrictHostKeyChecking=no root@172.22.1.123 "
        cd /opt/smart-livestock &&
        IMAGE_TAG=$IMAGE_TAG docker compose up -d"
  only:
    - master
  when: manual
```

应用配置 `application.yml` 中的 `DB_HOST`、`REDIS_HOST` 等通过 Docker Compose 环境变量注入（`.env` 文件），不在 CI 配置中硬编码。

- [ ] **Step 4: 配置 GitLab CI Variables**

在 GitLab Project `Settings → CI/CD → Variables` 中添加：
| Variable | 说明 |
|----------|------|
| `SSH_PASSWORD` | 部署服务器 SSH 密码 |
| `DOCKER_REGISTRY` | 内网 Docker Registry 地址 |

- [ ] **Step 5: 验证 Pipeline**

推送代码到 GitLab，检查 Pipeline 四个阶段均通过，确认 Docker Compose 部署成功。

- [ ] **Step 6: Commit**

```bash
git commit -m "ops: add GitLab CI/CD pipeline — build, test, docker, deploy to 172.22.1.123"
```

---

## Task 16: Flutter 前端适配

**状态: COMPLETED**（跨多个 commit 逐步完成）

**完成记录:**

| 完成日期 | Commit | 变更内容 |
|----------|--------|---------|
| 2026-05-12 | `100b335` | 切换 Flutter 默认 API URL 到 Spring Boot (`localhost:18080/api/v1`) |
| 2026-05-12 | `c877a67` | Farm Switcher 适配 Spring Boot — path-based farm scope |
| 2026-05-12 | `b7ee072` | 适配所有 Live Repos 为 Spring Boot 格式 + 非 Phase 1 功能优雅降级 |
| 2026-05-13 | `e5851ca` | 所有写操作通过 injectable `_httpClient` 统一路由 |
| 2026-05-14 | `d8d7d5c` | Live 模式写操作补充 JWT token + 围栏保存请求体格式修复 |
| 2026-05-14 | `027926a` | platform_admin 登录后可用操作界面修复 |
| 2026-05-15 | — | `live_livestock_repository.dart` 从 stub 改为解析 ApiCache 真实数据 |
| 2026-05-15 | — | `live_stats_repository.dart` 从 stub 改为从 ApiCache 构建 health/alert/device 统计 |

- [x] **Step 1: 修改 API_BASE_URL**

默认已切换到 `localhost:18080/api/v1`，可通过 `--dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1` 覆盖。

- [x] **Step 2: 适配 Live Repository**

全部 21 个 Live Repository 已实现。核心业务（dashboard、alerts、fences、devices、tenants、livestock、stats）完整使用 ApiCache 数据；Phase 2 功能（合同、订阅服务、API 授权）写操作降级到 mock。响应格式通过 `_normalizeXxx()` 方法适配 Spring Boot 与 Mock Server 差异。

- [x] **Step 3: FarmSwitcherController 重构**

已从 header-based (`x-active-farm`) 迁移到 path-based (`/farms/{farmId}/*`)。`ApiCache.activeFarmId` 管理 client-side 状态。

- [x] **Step 4: Commit**

所有变更已通过 flutter analyze + 300/303 tests 验证（3 个预存失败与本次改动无关）。

---

## 依赖关系图

```
Task 0 (API 契约重设计) ── COMPLETED ──→ Task 11 (API Controllers)

Task 1 (项目初始化) ──→ Task 2 (Flyway) ──→ Task 7 (Persistence)
                     │
                     ├──→ Task 3 (Identity Domain) ──→ Task 7 ──→ Task 8 (App Services)
                     ├──→ Task 4 (Ranch Domain)     ──→ Task 7 ──→ Task 8
                     ├──→ Task 5 (IoT Domain)       ──→ Task 7 ──→ Task 8
                     └──→ Task 6 (FarmScope)        ──→ Task 9 (Security)

Task 8 ──→ Task 10 (Event Bridge) ──→ Task 12 (Integration Tests)
Task 9 ──→ Task 11 (API Controllers)

Task 7+8+9 ──→ Task 13 (Docker Compose)
Task 10 ──→ Task 14 (GPS Simulator)
Task 13 ──→ Task 15 (GitLab CI/CD) ── NOT STARTED
Task 11 ──→ Task 16 (Flutter 适配) ── COMPLETED
```

**可并行路径：**
- Task 3, 4, 5, 6 可并行（各自独立的领域模型）
- Task 11 与 Task 10, 13, 14 可并行（Controller 与事件桥接/部署独立）
- Task 13, 14, 15 在 Task 7-10 完成后可并行
