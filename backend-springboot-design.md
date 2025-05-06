# 智慧畜牧系统 - Spring Boot后端设计方案

## 技术栈选择

### 后端框架
- **Spring Boot**: 2.7.13（LTS版本，确保长期稳定性）
- **Java版本**: Java 11（LTS版本，广泛支持）
- **构建工具**: Maven

### 数据库相关
- **数据库**: PostgreSQL 14
- **ORM框架**: Spring Data JPA + Hibernate
- **数据库迁移**: Flyway
- **连接池**: HikariCP (Spring Boot默认)

### API与文档
- **API风格**: RESTful
- **API文档**: SpringDoc OpenAPI 1.6.15 (Swagger UI)
- **序列化**: Jackson

### 安全
- **认证框架**: Spring Security
- **令牌**: JWT (JSON Web Token)
- **密码加密**: BCrypt

### 测试
- **单元测试**: JUnit 5
- **Mock框架**: Mockito
- **测试容器**: Testcontainers (用于集成测试)

### 工具库
- **日志**: SLF4J + Logback
- **工具类**: Lombok, Apache Commons
- **监控**: Spring Boot Actuator
- **时间处理**: Java Time API

## 项目结构

```
com.smartlivestock
├── SmartLivestockApplication.java      # 应用入口
├── config/                             # 配置类
│   ├── WebConfig.java                  # Web配置
│   ├── SecurityConfig.java             # 安全配置
│   ├── SwaggerConfig.java              # API文档配置
│   └── AuditConfig.java                # 审计配置
├── controller/                         # REST控制器
│   ├── AuthController.java             # 认证相关
│   ├── CattleController.java           # 牛只相关
│   ├── DeviceController.java           # 设备相关
│   └── dto/                            # 数据传输对象
│       ├── request/                    # 请求DTO
│       └── response/                   # 响应DTO
├── service/                            # 业务逻辑
│   ├── AuthService.java                # 认证服务
│   ├── CattleService.java              # 牛只服务
│   ├── DeviceService.java              # 设备服务
│   └── impl/                           # 实现类
├── repository/                         # 数据访问层
│   ├── UserRepository.java             # 用户仓库
│   ├── CattleRepository.java           # 牛只仓库
│   ├── SensorDataRepository.java       # 传感器数据仓库
│   └── DeviceRepository.java           # 设备仓库
├── entity/                             # 实体类
│   ├── User.java                       # 用户实体
│   ├── Cattle.java                     # 牛只实体
│   ├── SensorData.java                 # 传感器数据实体 
│   ├── Device.java                     # 设备实体
│   └── enums/                          # 枚举类
│       ├── HealthStatus.java           # 健康状态枚举
│       └── Role.java                   # 角色枚举
├── security/                           # 安全相关
│   ├── JwtTokenProvider.java           # JWT提供者
│   ├── JwtAuthenticationFilter.java    # JWT过滤器
│   └── UserDetailsServiceImpl.java     # 用户详情服务
├── exception/                          # 异常处理
│   ├── GlobalExceptionHandler.java     # 全局异常处理
│   ├── ApiError.java                   # API错误模型
│   └── custom/                         # 自定义异常
├── util/                               # 工具类
├── event/                              # 事件处理
└── migration/                          # 数据迁移工具
```

## 数据库设计

### 表结构

#### users 表
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'viewer',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### cattle 表
```sql
CREATE TABLE cattle (
    id BIGSERIAL PRIMARY KEY,
    cattle_id VARCHAR(50) NOT NULL UNIQUE,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    health_status VARCHAR(20) NOT NULL DEFAULT 'healthy',
    device_id BIGINT REFERENCES devices(id),
    last_update TIMESTAMP,
    age INTEGER,
    weight DECIMAL(7, 2),
    breed VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### sensor_data 表
```sql
CREATE TABLE sensor_data (
    id BIGSERIAL PRIMARY KEY,
    cattle_id BIGINT NOT NULL REFERENCES cattle(id),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    stomach_temperature DECIMAL(5, 2) NOT NULL,
    peristaltic_count INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### devices 表
```sql
CREATE TABLE devices (
    id BIGSERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    last_online TIMESTAMP,
    battery_level INTEGER,
    firmware_version VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 索引设计
```sql
-- cattle表索引
CREATE INDEX idx_cattle_cattle_id ON cattle(cattle_id);
CREATE INDEX idx_cattle_health_status ON cattle(health_status);
CREATE INDEX idx_cattle_device_id ON cattle(device_id);

-- sensor_data表索引
CREATE INDEX idx_sensor_data_cattle_id ON sensor_data(cattle_id);
CREATE INDEX idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX idx_sensor_data_cattle_timestamp ON sensor_data(cattle_id, timestamp);
```

## API设计

### 认证API
- POST /api/auth/login - 用户登录
- POST /api/auth/register - 用户注册（仅管理员）
- GET /api/auth/profile - 获取当前用户信息

### 牛只管理API
- GET /api/cattle - 获取所有牛只基础信息
- GET /api/cattle/:id - 获取单个牛只详情
- POST /api/cattle - 添加新牛只
- PUT /api/cattle/:id - 更新牛只信息
- DELETE /api/cattle/:id - 删除牛只信息

### 传感器数据API
- GET /api/cattle/:id/sensors - 获取牛只传感器数据
- POST /api/cattle/:id/sensors - 添加传感器数据
- GET /api/cattle/:id/health - 获取健康评估信息

### 设备管理API
- GET /api/devices - 获取所有设备
- GET /api/devices/:id - 获取单个设备详情
- POST /api/devices - 添加新设备
- PUT /api/devices/:id - 更新设备信息
- DELETE /api/devices/:id - 删除设备

## 安全设计

### 认证流程
1. 用户提交用户名/密码到/api/auth/login
2. 服务器验证凭据并生成JWT令牌
3. 客户端在后续请求的Authorization头中携带令牌
4. 服务器通过JwtAuthenticationFilter验证令牌

### 授权控制
- 使用基于角色的访问控制(RBAC)
- 定义三种角色: ROLE_ADMIN, ROLE_MANAGER, ROLE_VIEWER
- 使用@PreAuthorize注解控制方法级别权限

## 数据迁移策略

### 迁移工具
创建专用的数据迁移工具，执行以下步骤：
1. 从MongoDB读取数据
2. 转换数据模型
3. 写入PostgreSQL
4. 验证数据完整性

### 迁移步骤
1. 导出用户数据
2. 导出设备数据
3. 导出牛只基本信息
4. 导出历史传感器数据

## 部署与监控

### 部署选项
- Docker容器化部署
- Kubernetes对于更复杂环境
- 支持CI/CD流水线集成

### 监控与日志
- 使用Spring Boot Actuator暴露健康检查和监控端点
- 集成ELK或Grafana进行日志和指标监控
- 配置健康检查API用于负载均衡器

## 未来拓展考虑
- 支持消息队列(如Kafka)用于事件驱动架构
- 微服务拆分可能性
- 缓存层(Redis)用于高频访问数据 