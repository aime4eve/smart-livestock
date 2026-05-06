# MVP Phase 1 实施计划 — 核心底座

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Spring Boot MVP 后端的 Identity + Ranch + IoT 三个限界上下文，用 DDD 洋葱架构 + 充血模型 + TDD。

**Architecture:** 每个限界上下文按 domain → application → infrastructure → interfaces 四层洋葱架构组织。领域模型为纯 POJO，通过 Mapper 与 JPA Entity 分离。跨上下文通过 RocketMQ 领域事件解耦。

**Tech Stack:** Spring Boot 3.x, Java 17, Gradle, PostgreSQL 16, Redis 7, RocketMQ 5.1, Flyway, JPA/Hibernate, Spring Security + JWT, JUnit 5, Testcontainers

**Spec:** `docs/superpowers/specs/2026-05-06-mvp-backend-design.md`

**前置阻塞:** Task 0（多端 API 契约重设计）是独立 brainstorming 任务，阻塞 Task 11（API Controllers）。Task 1-10 可并行推进，不依赖 API 契约。

---

## Issue 索引表

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #40 | 构建 MVP |

## 完成记录表

| 完成日期 | Issue | PR | 备注 |

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

## Task 0: 多端 API 契约重设计（前置阻塞）

**状态: BLOCKED — 需独立 brainstorming 完成**

**阻塞范围:** Task 11（API Controllers + DTO）依赖此任务产出。Task 1-10（domain + persistence + application + security + deployment）不依赖。

**输入:**
- 领域上下文设计：规格第 1 节
- App 端实际代码：`Mobile/mobile_app/lib/features/*/domain/*_repository.dart`
- 现有 API 契约：`Mobile/docs/api-contracts/`
- Farm Scope 硬约束：规格第 4.7 节

**产出:** 新的 API 契约文档，覆盖 App端(Flutter) + PC端(Vue 3) + 第三方开发者(Open API)

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

- [ ] **Step 1: 创建 Gradle 项目结构**

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

- [ ] **Step 2: 创建应用入口**

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

- [ ] **Step 3: 创建 application.yml**

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
  expiration: ${JWT_EXPIRATION:86400000}
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

- [ ] **Step 4: 创建共享内核 — AggregateRoot + DomainEvent + Entity**

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

- [ ] **Step 5: 创建 ErrorCode 枚举 + ApiException**

`src/main/java/com/smartlivestock/shared/common/ErrorCode.java`:
```java
package com.smartlivestock.shared.common;

public enum ErrorCode {
    OK,
    BAD_REQUEST,
    AUTH_UNAUTHORIZED,
    FORBIDDEN,
    NOT_FOUND,
    CONFLICT,
    VALIDATION_ERROR,
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

- [ ] **Step 6: 验证项目编译**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 7: Commit**

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

- [ ] **Step 1: V1 — Identity 表**

`src/main/resources/db/migration/V1__create_identity_tables.sql`:
```sql
-- tenants
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    phase VARCHAR(10) NOT NULL DEFAULT 'SAMPLE',
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
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_farm UNIQUE (user_id, farm_id)
);
CREATE INDEX idx_ufa_farm_id ON user_farm_assignments(farm_id);
```

- [ ] **Step 2: V2 — Ranch 表**

`src/main/resources/db/migration/V2__create_ranch_tables.sql`:
```sql
-- livestock
CREATE TABLE livestock (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    tag_id VARCHAR(50) NOT NULL UNIQUE,
    breed VARCHAR(50),
    gender VARCHAR(10) CHECK (gender IN ('公', '母')),
    birth_date DATE,
    weight DECIMAL(7,2),
    health_status VARCHAR(20) NOT NULL DEFAULT 'healthy',
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
    status VARCHAR(20) NOT NULL DEFAULT 'active',
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
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    severity VARCHAR(10) NOT NULL DEFAULT 'warning',
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

- [ ] **Step 3: V3 — IoT 表**

`src/main/resources/db/migration/V3__create_iot_tables.sql`:
```sql
-- devices
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'INVENTORY',
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

-- gps_logs
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

- [ ] **Step 4: Commit**

```bash
git add src/main/resources/db/migration/
git commit -m "feat(server): add Flyway migrations V1-V3 — identity, ranch, iot tables"
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

- [ ] **Step 1: RED — 写 User 测试**

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

- [ ] **Step 2: Run test to verify it fails**

Run: `cd smart-livestock-server && ./gradlew test --tests "UserTest"`
Expected: FAIL (class not found)

- [ ] **Step 3: GREEN — 实现枚举 + User + Tenant + Farm**

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

- [ ] **Step 4: Run tests to verify they pass**

Run: `./gradlew test --tests "UserTest"`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

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

- [ ] **Step 1: RED — 写 Alert 状态机测试**

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

- [ ] **Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "AlertTest"`
Expected: FAIL

- [ ] **Step 3: RED — 写 Fence contains 测试**

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

- [ ] **Step 4: RED — 写 FenceBreachDetector 测试**

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

- [ ] **Step 5: GREEN — 实现所有 Ranch 领域模型**

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
            throw new ApiException(ErrorCode.CONFLICT, "只有 pending 状态的告警可以确认");
        }
        this.status = AlertStatus.ACKNOWLEDGED;
        this.acknowledgedBy = userId;
        this.acknowledgedAt = Instant.now();
    }

    public void handle(Long userId) {
        if (status != AlertStatus.ACKNOWLEDGED) {
            throw new ApiException(ErrorCode.CONFLICT, "只有 acknowledged 状态的告警可以处理");
        }
        this.status = AlertStatus.HANDLED;
        this.handledBy = userId;
        this.handledAt = Instant.now();
    }

    public void archive(Long userId) {
        if (status != AlertStatus.HANDLED) {
            throw new ApiException(ErrorCode.CONFLICT, "只有 handled 状态的告警可以归档");
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
                        .divide(yi.subtract(yj), 15, BigDecimal.ROUND_HALF_UP)
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
    private String tagId;
    private String breed;
    private String gender;
    private LocalDate birthDate;
    private BigDecimal weight;
    private HealthStatus healthStatus;
    private BigDecimal lastLatitude;
    private BigDecimal lastLongitude;
    private Instant lastPositionAt;

    public Livestock(Long farmId, String tagId) {
        this.farmId = farmId;
        this.tagId = tagId;
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
    public String getTagId() { return tagId; }
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
    Optional<Livestock> findByTagId(String tagId);
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

- [ ] **Step 6: Run all Ranch tests**

Run: `./gradlew test --tests "ranch.*"`
Expected: PASS

- [ ] **Step 7: Commit**

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
// DeviceLicense.isExpired(): Instant.now().isAfter(expiresAt)
// DeviceLicense.revoke(): status → REVOKED
// Installation.remove(): 设置 removedAt = Instant.now()
```

- [ ] **Step 1: RED — 写测试**
- [ ] **Step 2: Run tests to verify failure**
- [ ] **Step 3: GREEN — 实现 Device, DeviceLicense, Installation, GpsLog + 枚举 + 事件 + Repository 接口**
- [ ] **Step 4: Run tests to verify pass**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(iot): add domain models — Device, DeviceLicense, Installation, GpsLog with TDD tests"
```

---

## Task 6: FarmScope 解析器（TDD）

**Files:**
- Create: `src/test/java/com/smartlivestock/shared/scope/FarmScopeResolverTest.java`
- Create: `src/main/java/com/smartlivestock/shared/scope/FarmScopeType.java`
- Create: `src/main/java/com/smartlivestock/shared/scope/FarmScopeResolver.java`

- [ ] **Step 1: RED — 写 FarmScopeResolver 测试**

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
            .hasMessageContaining("422");
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

- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: GREEN — 实现 FarmScopeType + FarmScopeResolver**

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
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "写操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId == null) {
            throw new ApiException(ErrorCode.BAD_REQUEST,
                "写操作必须通过 /farms/{farmId}/... 路径指定牧场");
        }
        return pathFarmId;
    }

    private Long resolveRead(Long pathFarmId, Long headerFarmId) {
        if (pathFarmId != null && headerFarmId != null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "读操作禁止同时提供 path farmId 和 header x-active-farm");
        }
        if (pathFarmId != null) return pathFarmId;
        if (headerFarmId != null) return headerFarmId;
        throw new ApiException(ErrorCode.BAD_REQUEST,
            "读操作需要通过 path 或 header 指定牧场");
    }
}
```

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(shared): add FarmScopeResolver with strict path/header validation — TDD"
```

---

## Task 7: Persistence 层（所有上下文）

**Files:** 每个 JPA Entity + Spring Data Repository + Mapper + Repository Impl（共约 40 个文件，见文件结构总览）

此 Task 为重复性工作，每个聚合根遵循相同模式。以下以 Identity 的 Tenant 为例展示完整流程，其余按相同模式复制。

- [ ] **Step 1: 实现 Tenant 的 JPA Entity**

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

- [ ] **Step 2: 实现 Spring Data Repository**

`src/main/java/com/smartlivestock/identity/infrastructure/persistence/SpringDataTenantRepository.java`:
```java
package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataTenantRepository extends JpaRepository<TenantJpaEntity, Long> {
}
```

- [ ] **Step 3: 实现 Mapper**

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
        if (jpa.getPhase() != null && jpa.getPhase().equals("BATCH")) {
            domain.transitionToBatch();
        }
        return domain;
    }
}
```

- [ ] **Step 4: 实现 Repository Adapter**

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

- [ ] **Step 5: 对 User, Farm, UserFarmAssignment 重复 Step 1-4**
- [ ] **Step 6: 对 Ranch 上下文 (Livestock, Fence, Alert) 重复 Step 1-4**
- [ ] **Step 7: 对 IoT 上下文 (Device, DeviceLicense, Installation, GpsLog) 重复 Step 1-4**
- [ ] **Step 8: 验证 Flyway + JPA 启动成功**

Run: `./gradlew bootRun` (需要本地 PostgreSQL 或用 Testcontainers)
Expected: Application starts, Flyway runs V1-V3, no validation errors

- [ ] **Step 9: Commit**

```bash
git commit -m "feat: add persistence layer for all contexts — JPA entities, mappers, repository adapters"
```

---

## Task 8: Application Services 层

**Files:** 7 个 ApplicationService + Command/DTO 类

- [ ] **Step 1: 实现 AuthApplicationService**

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
        User user = userRepository.findByUsername(command.username())
            .orElseThrow(() -> new ApiException(ErrorCode.AUTH_UNAUTHORIZED, "用户名或密码错误"));
        if (!user.isActive()) {
            throw new ApiException(ErrorCode.AUTH_UNAUTHORIZED, "用户已停用");
        }
        if (!passwordHasher.matches(command.password(), user.getPasswordHash())) {
            throw new ApiException(ErrorCode.AUTH_UNAUTHORIZED, "用户名或密码错误");
        }
        user.recordLogin();
        userRepository.save(user);
        String token = jwtTokenProvider.generateToken(user.getId(), user.getTenantId(), user.getRole().name());
        return new AuthTokenDto(token, UserDto.from(user));
    }
}
```

- [ ] **Step 2: 实现 TenantApplicationService, FarmApplicationService**
- [ ] **Step 3: 实现 LivestockApplicationService, FenceApplicationService, AlertApplicationService**
- [ ] **Step 4: 实现 DeviceApplicationService, DeviceLicenseApplicationService, InstallationApplicationService, GpsLogApplicationService**
- [ ] **Step 5: 实现 Command 和 DTO 类**
- [ ] **Step 6: Commit**

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

- [ ] **Step 1: 实现 JwtTokenProvider**

生成/解析 JWT token。Payload 含 `sub`(userId), `tid`(tenantId), `role`。

- [ ] **Step 2: 实现 JwtAuthenticationFilter**

从 Authorization header 提取 token，解析后设置 SecurityContext。

- [ ] **Step 3: 实现 SecurityConfig**

配置 Spring Security：公开 `/api/v1/auth/login`，其余需认证。

- [ ] **Step 4: 实现 PasswordHasher**

BCrypt 封装，供 AuthApplicationService 使用。

- [ ] **Step 5: 实现 TenantContext**

ThreadLocal 持有当前请求的 tenantId，由 Filter 设置。

- [ ] **Step 6: 实现 GlobalExceptionHandler + ApiResponse**

统一错误响应格式：`{ code, message, requestId }`

- [ ] **Step 7: 验证登录流程可端到端运行**

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(security): add JWT auth, BCrypt, SecurityConfig, TenantContext, GlobalExceptionHandler"
```

---

## Task 10: 跨上下文事件桥接

**Files:**
- Create: `src/main/java/com/smartlivestock/shared/messaging/RocketMQEventPublisher.java`
- Create: `src/main/java/com/smartlivestock/shared/messaging/Topics.java`
- Create: `src/main/java/com/smartlivestock/iot/infrastructure/event/SpringEventPublisher.java`
- Create: `src/main/java/com/smartlivestock/ranch/infrastructure/event/GpsLogEventHandler.java`

- [ ] **Step 1: 实现 Spring Event → RocketMQ 桥接**

Application Service 发布 Spring ApplicationEvent → SpringEventPublisher 监听 → 转发到 RocketMQ Topic。

- [ ] **Step 2: 实现 GpsLogEventHandler**

Ranch 上下文消费 `gps-log-updated` Topic：
1. 收到 GPS 坐标 + livestockId
2. 查询该 livestock 关联的所有 active fence
3. FenceBreachDetector 判定越界
4. 若越界，创建 Alert

- [ ] **Step 3: 验证事件流可端到端运行**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add cross-context event bridge — RocketMQ publisher, GPS→Alert flow"
```

---

## Task 11: API Controllers（BLOCKED by Task 0）

**状态: BLOCKED — 等待多端 API 契约重设计完成**

**Files:** 所有 Context 的 Controller 类

依赖 Task 0（API 契约重设计）产出最终 API 契约后，实现：
- Identity: AuthController, TenantController, FarmController
- Ranch: LivestockController, FenceController, AlertController
- IoT: DeviceController, InstallationController

每个 Controller 使用 FarmScopeResolver 强制作用域规则。

---

## Task 12: 集成测试

**Files:**
- Create: `src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java`
- Create: 其他集成测试（见规格 6.4-6.5）

- [ ] **Step 1: 实现 GpsAlertFlowTest — GPS 上报→越界→自动生成告警**

端到端集成测试，验证 IoT → RocketMQ → Ranch 完整事件流。

- [ ] **Step 2: 实现其他集成测试**

使用 Testcontainers（PostgreSQL + Redis），验证 ApplicationService 层的事务和持久化。

- [ ] **Step 3: Run all tests**

Run: `./gradlew test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

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

- [ ] **Step 1: 编写 Dockerfile**

多阶段构建：Gradle build → JRE 运行。

- [ ] **Step 2: 编写 docker-compose.yml**

包含 PostgreSQL 16 + Redis 7 + RocketMQ 5.1 (namesrv + broker) + App + Nginx。完整配置见规格第 5 节。

- [ ] **Step 3: 编写 Nginx 配置**

反向代理 `/api/v1/` → app:8080。

- [ ] **Step 4: 本地验证 `docker-compose up`**

- [ ] **Step 5: Commit**

```bash
git commit -m "ops: add Docker Compose deployment — PostgreSQL, Redis, RocketMQ, Nginx"
```

---

## Task 14: GPS 模拟数据生成器

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/service/GpsSimulator.java`

- [ ] **Step 1: 实现 GpsSimulator**

定时任务（@Scheduled），为已安装的设备生成模拟 GPS 坐标：
- 读取所有 active device 的 installation
- 基于牧场中心点 + 随机偏移生成 GPS 坐标
- 调用 GpsLogApplicationService 批量上报

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(iot): add GPS simulator for Phase 1 mock data generation"
```

---

## Task 15: GitLab 仓库 + CI/CD

**Files:**
- Create: `.gitlab-ci.yml`

- [ ] **Step 1: 在内网 GitLab 创建仓库**

推送 smart-livestock-server 到 `172.22.1.123` 的 GitLab。

- [ ] **Step 2: 编写 .gitlab-ci.yml**

Pipeline: build → test → docker build → deploy (SSH)。

- [ ] **Step 3: 验证 Pipeline 运行**

- [ ] **Step 4: Commit**

```bash
git commit -m "ops: add GitLab CI/CD pipeline"
```

---

## Task 16: Flutter 前端适配（可选，不阻塞后端）

**Files:** Flutter 端 `mobile_app/lib/core/api/` 下的文件

- [ ] **Step 1: 修改 API_BASE_URL**

从 `localhost:3001/api` 改为 `172.22.1.123:8080/api/v1`

- [ ] **Step 2: 适配 Live Repository**

根据最终 API 契约调整 Live Repository 的请求/响应格式。

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(flutter): adapt Live Repository for Spring Boot backend"
```

---

## 依赖关系图

```
Task 0 (API 契约重设计) ─── BLOCKS ──→ Task 11 (API Controllers)

Task 1 (项目初始化) ──→ Task 2 (Flyway) ──→ Task 7 (Persistence)
                     │
                     ├──→ Task 3 (Identity Domain) ──→ Task 7 ──→ Task 8 (App Services)
                     ├──→ Task 4 (Ranch Domain)     ──→ Task 7 ──→ Task 8
                     ├──→ Task 5 (IoT Domain)       ──→ Task 7 ──→ Task 8
                     └──→ Task 6 (FarmScope)        ──→ Task 9 (Security)

Task 8 ──→ Task 10 (Event Bridge) ──→ Task 12 (Integration Tests)
Task 9 ──→ Task 11 (BLOCKED by Task 0)

Task 7+8+9 ──→ Task 13 (Docker Compose)
Task 10 ──→ Task 14 (GPS Simulator)
Task 13 ──→ Task 15 (GitLab CI/CD)
Task 11 ──→ Task 16 (Flutter 适配)
```

**可并行路径：**
- Task 0 (API 契约) 与 Task 1-10 可并行
- Task 3, 4, 5, 6 可并行（各自独立的领域模型）
- Task 13, 14, 15 在 Task 7-10 完成后可并行
