# 智慧畜牧系统 - PostgreSQL数据库设计方案

## 数据模型迁移策略

从MongoDB文档型数据库迁移到PostgreSQL关系型数据库需要仔细设计表结构和关系。以下是详细设计方案：

## 数据表设计

### 1. users表（用户信息）

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
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

-- 索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**映射说明：**
- 直接映射MongoDB中的User模型
- 添加了`created_at`和`updated_at`用于审计
- 密码字段将存储加密后的密码哈希

### 2. devices表（设备信息）

```sql
CREATE TABLE devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL UNIQUE,
    device_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    last_online TIMESTAMP,
    battery_level INTEGER,
    firmware_version VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_status ON devices(status);
```

**映射说明：**
- 在MongoDB中，设备信息是作为牛只属性的一部分
- 在关系型数据库中，需要单独建表并通过外键关联

### 3. cattle表（牛只基本信息）

```sql
CREATE TABLE cattle (
    id SERIAL PRIMARY KEY,
    cattle_id VARCHAR(50) NOT NULL UNIQUE,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    health_status VARCHAR(20) NOT NULL DEFAULT 'healthy',
    device_id INTEGER REFERENCES devices(id),
    last_update TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_cattle_cattle_id ON cattle(cattle_id);
CREATE INDEX idx_cattle_health_status ON cattle(health_status);
CREATE INDEX idx_cattle_device_id ON cattle(device_id);
CREATE INDEX idx_cattle_position ON cattle USING GIST (point(longitude, latitude));
```

**映射说明：**
- 拆分了MongoDB中的Cattle模型，只保留基本信息
- 位置信息使用两个单独的字段存储
- 添加了空间索引以支持位置查询

### 4. cattle_metadata表（牛只元数据）

```sql
CREATE TABLE cattle_metadata (
    id SERIAL PRIMARY KEY,
    cattle_id INTEGER NOT NULL REFERENCES cattle(id),
    age INTEGER,
    weight DECIMAL(7, 2),
    breed VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cattle_metadata UNIQUE (cattle_id)
);

-- 索引
CREATE INDEX idx_cattle_metadata_cattle_id ON cattle_metadata(cattle_id);
```

**映射说明：**
- 对应MongoDB中Cattle模型的metadata字段
- 一对一关系，每只牛只有一条元数据记录

### 5. sensor_data表（传感器数据）

```sql
CREATE TABLE sensor_data (
    id SERIAL PRIMARY KEY,
    cattle_id INTEGER NOT NULL REFERENCES cattle(id),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    stomach_temperature DECIMAL(5, 2) NOT NULL,
    peristaltic_count INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_sensor_data_cattle_id ON sensor_data(cattle_id);
CREATE INDEX idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX idx_sensor_data_cattle_timestamp ON sensor_data(cattle_id, timestamp);
```

**映射说明：**
- 对应MongoDB中Cattle模型的嵌套sensorData数组
- 在关系型数据库中，使用一对多关系表示

### 6. 分区表设计（可选）

对于传感器数据表，可以考虑使用分区表以提高性能：

```sql
CREATE TABLE sensor_data (
    id SERIAL PRIMARY KEY,
    cattle_id INTEGER NOT NULL REFERENCES cattle(id),
    timestamp TIMESTAMP NOT NULL,
    stomach_temperature DECIMAL(5, 2) NOT NULL,
    peristaltic_count INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (timestamp);

-- 创建月度分区
CREATE TABLE sensor_data_y2023m01 PARTITION OF sensor_data
    FOR VALUES FROM ('2023-01-01') TO ('2023-02-01');
CREATE TABLE sensor_data_y2023m02 PARTITION OF sensor_data
    FOR VALUES FROM ('2023-02-01') TO ('2023-03-01');
-- ... 更多分区
```

## 数据类型映射

| MongoDB类型     | PostgreSQL类型   | 说明                                |
|----------------|-----------------|-------------------------------------|
| ObjectId       | SERIAL/UUID     | 主键识别符                           |
| String         | VARCHAR/TEXT    | 文本数据                             |
| Number (int)   | INTEGER         | 整数                                |
| Number (float) | DECIMAL/NUMERIC | 精确小数                             |
| Boolean        | BOOLEAN         | 布尔值                               |
| Date           | TIMESTAMP       | 日期时间                             |
| Array          | 关联表           | 使用一对多关系替代数组                 |
| Embedded Doc   | 关联表/JSONB     | 使用一对一关系或JSON字段              |

## 数据约束和完整性

为确保数据完整性，以下约束已添加到数据库设计中：

1. **主键约束**：每张表都有自增主键
2. **外键约束**：确保相关表之间的参照完整性
3. **唯一约束**：用户名、邮箱、牛只ID等关键标识符
4. **非空约束**：必填字段
5. **默认值**：为状态类字段设置默认值
6. **CHECK约束**：可添加数值范围限制（如：体温范围）

## 数据迁移流程

1. **初始化Schema**：创建所有表结构
2. **迁移设备数据**：从牛只记录提取设备信息并插入devices表
3. **迁移牛只基本信息**：将MongoDB中的牛只基本信息转换到cattle表
4. **迁移牛只元数据**：将metadata字段数据插入cattle_metadata表
5. **迁移传感器数据**：将嵌套的传感器数据数组转换为sensor_data表中的行记录
6. **迁移用户数据**：转换用户信息到users表
7. **验证数据完整性**：确保所有数据都已正确迁移
8. **创建索引**：为优化查询性能创建必要的索引

## 数据库配置建议

```
# PostgreSQL配置推荐
max_connections = 100
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 4
effective_io_concurrency = 2
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
```

## 性能优化考虑

1. **索引策略**：已为常用查询条件创建索引
2. **分区表**：对大数据量的传感器数据使用分区表
3. **连接优化**：设计减少多表连接的复杂度
4. **查询优化**：预先设计常用查询的执行计划
5. **缓存策略**：可考虑使用Redis缓存热点数据

## 扩展性考虑

此设计允许以下扩展：
1. 添加更多设备类型和传感器类型
2. 增加新的牛只属性，只需扩展cattle_metadata表
3. 添加地理空间查询功能
4. 实现时序数据分析
5. 未来可考虑添加牛只健康状况历史记录表 