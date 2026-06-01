# 智慧畜牧后端功能清单

> 基于 smart-livestock-server 代码分析，更新时间 2026-06-01

## 一、全局概览

| 维度 | 数量 |
|------|------|
| 限界上下文 | 7（Identity / Ranch / IoT / Commerce / Health / Analytics / Shared） |
| Java 文件 | 381 |
| Controller | 39 |
| API 端点 | ~121 |
| 领域模型 | 59 个（聚合根 + 值对象 + 枚举） |
| 领域服务 | 6 |
| 应用服务 | 16 |
| 数据库表 | 30+（23 个 Flyway 迁移） |
| 领域事件 | 31 |
| 过滤器/拦截器 | 10 |
| 定时任务 | 1 |

---

## 二、架构分层（DDD 洋葱架构）

```
interfaces/          ← REST Controller + DTO
  ├── admin/         ← 平台管理 API（/api/v1/admin/*）
  ├── app/           ← 业务 App API（/api/v1/*）
  └── open/          ← Open API（/api/v1/open/*，API Key 认证）
application/
  ├── service/       ← 应用服务（用例编排、事务管理）
  ├── command/       ← 写操作命令对象
  ├── dto/           ← 查询/返回 DTO
  ├── query/         ← 读操作查询服务
  ├── job/           ← 定时任务
  └── port/          ← 应用端口接口
domain/
  ├── model/         ← 聚合根、实体、值对象（纯业务，零框架依赖）
  │   └── event/     ← 领域事件
  ├── repository/    ← Repository 接口（port）
  └── service/       ← 领域服务（跨聚合编排）
infrastructure/
  ├── persistence/   ← JPA 实现（adapter）
  │   ├── entity/    ← JPA Entity
  │   ├── mapper/    ← Domain ↔ Entity 转换
  │   └── jpa/       ← Spring Data JPA Repository
  └── event/         ← 事件发布实现
```

---

## 三、限界上下文功能清单

### 3.1 Identity（身份与租户）

#### 领域模型
- **Tenant**：租户聚合根（名称、联系人、阶段 TenantPhase、状态）
- **User**：用户聚合根（手机号、密码 BCrypt、角色 Role、状态）
- **Farm**：牧场聚合根（名称、坐标、面积、关联租户）
- **ApiKey**：API 密钥（前缀、密钥哈希、作用域、状态）
- **AuditLog**：审计日志（操作者、操作类型、目标、时间戳）
- **UserFarmAssignment**：用户-牧场分配关系

#### 枚举
- `Role`：platform_admin / b2b_admin / owner / worker / api_consumer
- `TenantPhase`：trial / active / suspended / terminated

#### API 端点

**认证（AuthController）** — `/api/v1/auth`
| 方法 | 路径 | 功能 |
|------|------|------|
| POST | /login | 手机号+密码登录，返回 JWT |
| POST | /refresh | JWT 续签 |
| POST | /logout | 登出 |

**当前用户（MeController）** — `/api/v1`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /me | 获取当前用户信息 |
| PUT | /me | 更新当前用户信息 |
| PUT | /me/password | 修改密码 |

**租户自服务（TenantController）** — `/api/v1/tenants`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /me | 获取当前租户信息 |
| PUT | /me | 更新当前租户信息 |

**牧场（FarmController）** — `/api/v1`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /farms | 列出用户关联牧场 |
| POST | /farms | 创建牧场 |
| GET | /farms/{farmId} | 获取牧场详情 |
| PUT | /farms/{farmId} | 更新牧场信息 |
| GET | /farms/{farmId}/members | 获取牧场成员列表 |
| POST | /farms/{farmId}/members | 添加牧场成员 |
| DELETE | /farms/{farmId}/members/{userId} | 移除牧场成员 |

**平台管理-租户（TenantAdminController）** — `/api/v1/admin/tenants`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询租户列表 |
| POST | / | 创建租户 |
| GET | /{tenantId} | 获取租户详情 |
| PUT | /{tenantId} | 更新租户信息 |
| GET | /{tenantId}/farms | 获取租户下牧场列表 |
| PUT | /{tenantId}/status | 变更租户状态（启用/停用） |
| PUT | /{tenantId}/phase | 变更租户阶段 |

**平台管理-用户（UserAdminController）** — `/api/v1/admin/users`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询用户列表（支持租户/角色/状态筛选） |
| POST | / | 创建用户 |
| GET | /{userId} | 获取用户详情 |
| PUT | /{userId} | 更新用户信息 |
| PUT | /{userId}/status | 变更用户状态（启用/停用） |
| POST | /{userId}/reset-password | 重置用户密码 |

**平台管理-牧场（FarmAdminController）** — `/api/v1/admin/farms`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询牧场列表（支持租户/状态筛选） |
| POST | / | 创建牧场（管理员） |
| GET | /{farmId} | 获取牧场详情 |
| PUT | /{farmId}/status | 变更牧场状态 |

**平台管理-API Key（ApiKeyAdminController）** — `/api/v1/admin/api-keys`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询 API Key 列表 |
| POST | / | 创建 API Key |
| PUT | /{keyId}/status | 变更 Key 状态（启用/停用） |
| DELETE | /{keyId} | 删除 API Key |

**平台管理-审计日志（AuditLogController）** — `/api/v1/admin/audit-logs`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询审计日志 |

**平台管理-仪表板（DashboardAdminController）** — `/api/v1/admin/dashboard`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 获取管理仪表板统计数据（租户数/用户数/牧场数/设备数等） |

#### 领域事件
- `TenantPhaseChangedEvent`

---

### 3.2 Ranch（牧场业务）

#### 领域模型
- **Livestock**：牲畜聚合根（耳标号、品种、体重、月龄、健康状态）
- **Fence**：围栏聚合根（名称、顶点列表、颜色、状态、版本号）
- **Alert**：告警聚合根（类型、严重度、状态、关联围栏/牲畜）
- **GpsCoordinate**：坐标值对象
- **TileRegion / TileGenerationTask / FarmTileTask / TileDownloadLog**：瓦片相关

#### 枚举
- `HealthStatus`：healthy / watch / abnormal
- `AlertStatus`：pending / acknowledged / handled / archived
- `AlertType`：fence_breach / battery_low / signal_lost / device_offline
- `Severity`：P0 / P1 / P2

#### 领域服务
- **FenceBreachDetector**：围栏越界检测（射线法判断牲畜是否在围栏外）
- **TileCoverageCalculator**：瓦片覆盖范围计算

#### API 端点

**牲畜（LivestockController）** — `/api/v1/farms/{farmId}/livestock`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询牲畜列表 |
| POST | / | 新增牲畜 |
| GET | /{livestockId} | 获取牲畜详情 |
| PUT | /{livestockId} | 更新牲畜信息 |
| DELETE | /{livestockId} | 删除牲畜 |

**围栏（FenceController）** — `/api/v1/farms/{farmId}/fences`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询围栏列表 |
| POST | / | 创建围栏 |
| GET | /{fenceId} | 获取围栏详情 |
| PUT | /{fenceId} | 更新围栏（含乐观锁版本校验） |
| PUT | /{fenceId}/force | 强制更新围栏（忽略版本冲突） |
| DELETE | /{fenceId} | 删除围栏 |

**告警（AlertController）** — `/api/v1/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /alerts | 分页查询告警列表（支持类型/状态/严重度筛选） |
| GET | /alerts/{alertId} | 获取告警详情 |
| POST | /alerts/{alertId}/acknowledge | 确认告警 |
| POST | /alerts/{alertId}/handle | 处理告警 |
| POST | /alerts/{alertId}/archive | 归档告警 |
| POST | /alerts/batch-handle | 批量处理告警 |

**仪表板（DashboardController）** — `/api/v1/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /dashboard / /dashboard/summary | 获取牧场仪表板数据 |

**地图（MapController）** — `/api/v1/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /map / /map/overview | 获取地图概览数据（牲畜位置+围栏） |

**瓦片-应用端（TileAppController）** — `/api/v1/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /tile-status | 查询瓦片下载状态 |
| GET | /tile-source | 获取瓦片源信息 |
| POST | /tile-download-log | 记录瓦片下载日志 |

**瓦片-管理端（TileAdminController）** — `/api/v1/admin/tiles`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /regions | 查询瓦片区域列表 |
| POST | /regions | 创建瓦片区域 |
| GET | /tasks | 查询瓦片生成任务 |
| GET | /tasks/{id} | 获取任务详情 |
| POST | /tasks | 创建瓦片生成任务 |
| PUT | /tasks/{id}/status | 更新任务状态 |
| GET | /farm-tasks | 查询牧场瓦片任务 |

**瓦片-通用（TileController）** — `/api/v1`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /admin/tiles/status | 瓦片服务状态检查 |
| GET | /farms/{farmId}/offline-map | 离线地图数据 |

**分析事件（AnalyticsController）** — `/api/v1/analytics`
| 方法 | 路径 | 功能 |
|------|------|------|
| POST | /events | 接收分析事件（前端埋点） |

#### 领域事件
- `AlertStatusChangedEvent`
- `FenceBreachDetectedEvent`（围栏越界检测→自动创建告警）

#### 事件处理器
- `GpsLogEventHandler`：GPS 日志更新后触发围栏越界检测

---

### 3.3 IoT（设备管理）

#### 领域模型
- **Device**：设备聚合根（序列号、类型、状态、电池/信号）
- **DeviceLicense**：设备许可证（关联设备、状态、有效期）
- **Installation**：安装记录（设备↔牲畜绑定）
- **GpsLog**：GPS 日志（经纬度、速度、时间戳）

#### 枚举
- `DeviceType`：gps / rumen_capsule / accelerometer
- `DeviceStatus`：online / offline / low_battery / decommissioned
- `LicenseStatus`：active / expired / revoked

#### API 端点

**设备（DeviceController）** — `/api/v1/farms/{farmId}/devices`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询设备列表 |
| POST | / | 注册新设备 |
| GET | /{deviceId} | 获取设备详情 |
| PUT | /{deviceId} | 更新设备信息 |
| PUT | /{deviceId}/activate | 激活设备 |
| PUT | /{deviceId}/decommission | 停用设备 |

**设备许可证（DeviceLicenseController）** — `/api/v1/device-licenses`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询许可证列表 |
| GET | /{licenseId} | 获取许可证详情 |
| POST | / | 创建许可证 |
| PUT | /{licenseId}/revoke | 吊销许可证 |

**安装记录（InstallationController）** — `/api/v1/farms/{farmId}/installations`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询安装记录 |
| POST | / | 创建安装（设备绑定到牲畜） |
| GET | /{installationId} | 获取安装记录详情 |
| PUT | /{installationId}/uninstall | 卸载设备 |

**GPS 日志（GpsLogController）** — `/api/v1/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /gps-logs/latest | 获取最新 GPS 位置 |
| GET | /livestock/{livestockId}/gps-logs | 获取牲畜 GPS 历史轨迹 |

**Open API-设备（OpenDeviceController）** — `/api/v1/open/farms/{farmId}/devices`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 查询设备列表（第三方） |
| GET | /{deviceId} | 获取设备详情（第三方） |

**Open API-设备注册（OpenDeviceRegisterController）** — `/api/v1/open/devices`
| 方法 | 路径 | 功能 |
|------|------|------|
| POST | /register | 注册设备（第三方） |

**Open API-GPS（OpenGpsController）** — `/api/v1/open/farms/{farmId}`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /gps-logs/latest | 获取最新 GPS 位置（第三方） |
| GET | /livestock/{livestockId}/gps-logs | 获取牲畜 GPS 历史（第三方） |

#### 领域事件
- `DeviceActivatedEvent`
- `GpsLogUpdatedEvent`
- `LicenseExpiredEvent`

---

### 3.4 Commerce（商业化）

#### 领域模型
- **Subscription**：订阅聚合根（租户、tier、状态、计费周期）
- **Contract**：合同聚合根（B端合作合同，签约方、分成比例、状态）
- **RevenuePeriod**：分润周期（起止时间、平台/合作方金额、结算状态）
- **SubscriptionService**：订阅服务（激活的服务实例、心跳、配额）
- **FeatureGate**：功能门控（gate 类型、阈值、关联 tier）
- **SubscriptionTier**：basic / standard / premium / enterprise

#### 枚举
- `SubscriptionStatus`：trial / active / past_due / suspended / cancelled
- `ContractStatus`：draft / active / suspended / terminated
- `RevenueSettlementStatus`：pending / partner_confirmed / platform_confirmed / settled
- `GateType`：hard / soft（硬门控/软门控）
- `SubscriptionServiceStatus`：provisioned / activating / active / degraded / revoked

#### 应用服务
- **SubscriptionApplicationService**：订阅生命周期管理
- **ContractApplicationService**：合同 CRUD + 签约/终止
- **RevenueApplicationService**：分润计算与结算
- **QuotaApplicationService**：配额检查与扣减

#### 查询服务
- **SubscriptionQueryService**
- **RevenueQueryService**

#### API 端点

**订阅-应用端（SubscriptionController）** — `/api/v1/subscription`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 获取当前订阅状态 |
| GET | /plans | 获取订阅套餐列表 |
| POST | /checkout | 订阅结账（选择套餐→创建订阅） |
| PUT | /tier | 变更订阅 tier |
| POST | /cancel | 取消订阅 |
| GET | /usage | 获取用量统计 |

**商业-应用端（CommerceController）** — `/api/v1`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /contracts/me | 获取我的合同信息 |
| GET | /revenue/periods | 获取分润周期列表 |
| POST | /revenue/periods/{id}/confirm | 合作方确认分润 |

**合同管理（AdminContractController）** — `/api/v1/admin/contracts`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询合同列表 |
| POST | / | 创建合同 |
| GET | /{id} | 获取合同详情 |
| PUT | /{id} | 更新合同 |
| POST | /{id}/sign | 签署合同 |
| PUT | /{id}/status | 变更合同状态 |

**订阅管理（AdminSubscriptionController）** — `/api/v1/admin/subscriptions`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询订阅列表 |
| GET | /{id} | 获取订阅详情 |
| PUT | /{id}/status | 变更订阅状态 |

**分润管理（AdminRevenueController）** — `/api/v1/admin/revenue`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /periods | 分页查询分润周期 |
| GET | /periods/{id} | 获取分润周期详情 |
| POST | /calculate | 计算分润 |
| POST | /periods/{id}/confirm | 平台确认分润 |
| POST | /periods/{id}/recalculate | 重算分润 |

**功能门控（AdminFeatureGateController）** — `/api/v1/admin/feature-gates`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 获取功能门控列表 |
| PUT | /{id} | 更新功能门控配置 |

**订阅服务（AdminServiceController）** — `/api/v1/admin/subscription-services`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 分页查询订阅服务列表 |
| POST | / | 创建订阅服务 |
| GET | /{id} | 获取服务详情 |
| PUT | /{id}/status | 变更服务状态 |
| PUT | /{id}/quota | 调整服务配额 |

#### 定时任务
- **CommerceScheduler**：订阅续费检查、过期订阅处理

#### 领域事件（16 个）
- 合同：Created / Expired / Reactivated / Suspended / Terminated
- 分润：PeriodCreated / PartnerConfirmed / PlatformConfirmed / Settled
- 订阅服务：Provisioned / Activated / HeartbeatLost / HeartbeatRecovered
- 订阅：Cancelled / RenewalFailed

---

### 3.5 Health（健康分析）

#### 领域模型
- **TemperatureLog**：体温日志（温度、状态）
- **RumenMotilityLog**：瘤胃蠕动日志（蠕动次数/分钟、动力状态）
- **ActivityLog**：活动量日志（步数、活动状态）
- **HealthSnapshot**：健康快照（综合评分）
- **EstrusScore**：发情评分（分数、等级）
- **ContactTrace**：接触追踪（疫病关联）

#### 枚举
- `TempStatus`：NORMAL / ELEVATED / FEVER / CRITICAL
- `MotilityStatus`：NORMAL / LOW / HIGH / ABSENT
- `ActivityStatus`：NORMAL / LOW / HIGH

#### 领域服务
- **FeverAnalysisService**：体温异常检测
- **DigestiveAnalysisService**：消化功能分析（蠕动异常）
- **EstrusAnalysisService**：发情识别评分
- **EpidemicAnalysisService**：疫病群体分析

#### API 端点

**健康总览（HealthOverviewController）** — `/api/v1/farms/{farmId}/health`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /overview | 获取牧场健康总览 |

**发热预警（FeverController）** — `/api/v1/farms/{farmId}/health`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /fever | 获取发热预警列表 |
| GET | /fever/{livestockId} | 获取单头牲畜发热详情 |

**消化分析（DigestiveController）** — `/api/v1/farms/{farmId}/health`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /digestive | 获取消化分析列表 |
| GET | /digestive/{livestockId} | 获取单头牲畜消化详情 |

**发情识别（EstrusController）** — `/api/v1/farms/{farmId}/health`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /estrus | 获取发情识别列表 |
| GET | /estrus/{livestockId} | 获取单头牲畜发情详情 |

**疫病防控（EpidemicController）** — `/api/v1/farms/{farmId}/health`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /epidemic | 获取疫病防控概览 |

---

### 3.6 Analytics + API Portal（分析统计与开发者门户）

#### 领域模型
- **ApiCallLog**：API 调用日志（Key、端点、状态码、耗时）
- **ApiUsageDaily**：每日使用量聚合（按 Key + 日期）

#### 应用服务
- **AnalyticsApplicationService**：分析查询服务
- **AsyncApiCallLogService**：异步 API 调用日志采集
- **UsageAggregationService**：使用量聚合服务

#### API 端点

**使用量-应用端（AnalyticsAppController）** — `/api/v1/analytics/usage`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /overview | 获取当前租户使用量概览 |
| GET | /trend | 获取使用量趋势 |
| GET | /api-keys/{apiKeyId}/overview | 获取单个 Key 使用量概览 |
| GET | /api-keys/{apiKeyId}/trend | 获取单个 Key 使用量趋势 |

**使用量-管理端（AnalyticsAdminController）** — `/api/v1/admin/analytics`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /tenants/{tenantId}/usage/overview | 获取指定租户使用量概览 |
| GET | /tenants/{tenantId}/usage/trend | 获取指定租户使用量趋势 |
| POST | /aggregate | 触发手动聚合 |

**API Portal-应用端（PortalAppController）** — `/api/v1/portal/keys`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 获取我的 API Key 列表 |
| POST | / | 创建 API Key（租户自助） |
| PUT | /{keyId} | 更新 Key 信息 |
| PUT | /{keyId}/status | 变更 Key 状态（启用/停用） |
| DELETE | /{keyId} | 删除 Key |
| GET | /{keyId}/usage | 获取 Key 使用量 |
| GET | /dashboard | 获取 Portal 仪表板数据 |

**API Portal-管理端（PortalAdminController）** — `/api/v1/admin/portal/keys`
| 方法 | 路径 | 功能 |
|------|------|------|
| GET | / | 查询所有 API Key 列表 |
| PUT | /{keyId}/rate-limit | 设置 Key 频率限制 |
| PUT | /{keyId}/scopes | 设置 Key 作用域 |
| POST | /{keyId}/approve | 审批 Key 申请 |
| GET | /stats | 获取 Portal 统计数据 |

---

### 3.7 Shared（共享基础设施）

#### 安全
- **SecurityConfig**：Spring Security 配置（JWT 无状态 + CORS + CSRF 禁用）
- **JwtAuthenticationFilter**：JWT 令牌解析与认证
- **ApiKeyAuthFilter**：API Key 认证（Open API 路由）
- **BCrypt 密码编码**

#### 拦截器
| 拦截器 | 功能 |
|--------|------|
| **RequestIdFilter** | 生成请求 ID，注入响应头 |
| **FarmScopeInterceptor** | 提取 activeFarmId，验证用户是否关联该牧场 |
| **ScopeInterceptor** | 租户范围校验 |
| **RateLimitInterceptor** | API 频率限制（Redis + Lua 原子计数） |
| **QuotaInterceptor** | 配额检查（订阅 tier 限制） |
| **ApiCallLogInterceptor** | 异步记录 API 调用日志 |

#### 事件监听
- **AuditLogEventListener**：审计日志事件监听（自动记录关键操作）
- **NotificationEventListener**：通知事件监听

#### 缓存
- **RedisCacheService**：Redis 缓存服务

#### 领域事件（跨限界上下文）
- 订阅：Created / Expired / Suspended / Reactivated / TierChanged
- 合同：Signed
- 服务：Degraded / QuotaAdjusted / Revoked

#### 健康检查
- **HealthController**：`GET /health` 服务存活探针

---

## 四、API 端点分类统计

| 分类 | 前缀 | 端点数 | 说明 |
|------|------|--------|------|
| **App API** | `/api/v1/` | ~64 | 业务应用端（JWT 认证） |
| **Admin API** | `/api/v1/admin/` | ~38 | 平台管理端 |
| **Open API** | `/api/v1/open/` | ~8 | 第三方开放接口（API Key 认证） |
| **Portal API** | `/api/v1/portal/` | ~7 | 开发者门户（租户自助管理 Key） |
| **Auth** | `/api/v1/auth/` | 3 | 认证（login/refresh/logout） |
| **Health** | `/health` | 1 | 服务健康检查 |
| **合计** | | **~121** | |

---

## 五、数据库表（30+ 张）

| 迁移 | 表名 | 限界上下文 | 说明 |
|------|------|-----------|------|
| V1 | tenants | Identity | 租户 |
| V1 | farms | Identity | 牧场 |
| V1 | users | Identity | 用户 |
| V1 | user_farm_assignments | Identity | 用户-牧场分配 |
| V1 | api_keys | Identity | API 密钥 |
| V2 | livestock | Ranch | 牲畜 |
| V2 | fences | Ranch | 围栏 |
| V2 | alerts | Ranch | 告警 |
| V3 | devices | IoT | 设备 |
| V3 | device_licenses | IoT | 设备许可证 |
| V3 | installations | IoT | 安装记录 |
| V3 | gps_logs | IoT | GPS 日志 |
| V6 | subscriptions | Commerce | 订阅 |
| V6 | contracts | Commerce | 合同 |
| V6 | revenue_periods | Commerce | 分润周期 |
| V6 | subscription_services | Commerce | 订阅服务 |
| V6 | feature_gates | Commerce | 功能门控 |
| V6 | notifications | Commerce | 通知 |
| V13 | tile_regions | Ranch | 瓦片区域 |
| V13 | tile_generation_tasks | Ranch | 瓦片生成任务 |
| V13 | farm_tile_tasks | Ranch | 牧场瓦片任务 |
| V13 | tile_download_logs | Ranch | 瓦片下载日志 |
| V18 | audit_logs | Shared | 审计日志 |
| V20 | temperature_logs | Health | 体温日志 |
| V20 | rumen_motility_logs | Health | 瘤胃蠕动日志 |
| V20 | activity_logs | Health | 活动量日志 |
| V20 | health_snapshots | Health | 健康快照 |
| V20 | estrus_scores | Health | 发情评分 |
| V20 | contact_traces | Health | 接触追踪 |
| V22 | api_call_logs | Analytics | API 调用日志 |
| V22 | api_usage_daily | Analytics | 每日使用量 |

---

## 六、关键业务规则

### 围栏越界检测
- GPS 日志更新时触发 `FenceBreachDetector`
- 射线法（Ray Casting）判断牲畜坐标是否在围栏多边形外
- 越界→发布 `FenceBreachDetectedEvent`→自动创建 P0 告警

### 告警状态机
```
pending → acknowledged → handled → archived
```
- 服务端校验非法跳转返回 409 CONFLICT
- 支持批量处理

### 订阅配额引擎
- `QuotaApplicationService` + `QuotaInterceptor`
- 创建牲畜/围栏/设备时自动检查 tier 配额
- FeatureGate 支持 hard/soft 两种门控类型

### 合同与分润
- 合同签署→自动创建订阅
- 分润周期计算：平台分成 + 合作方分成
- 双向确认流程：合作方确认 → 平台确认 → 结算

### API 频率限制
- `RateLimitService`：Redis + Lua 原子计数
- SHA-256 哈希 Key，防止滥用
- 按 API Key 粒度限流

### 审计日志
- `AuditLogEventListener` 监听关键操作
- 自动记录：操作者、操作类型、目标对象、时间戳

---

## 七、种子数据

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| platform_admin | 13800000000 | 123 | 平台管理员 |
| b2b_admin | 13900139000 | 123 | B端管理员（Demo 租户） |
| owner | 13800138000 | 123 | 牧场主（Demo 租户主牧场） |
| worker | — | — | 牧工（seed 数据） |

---

## 八、部署架构

```
Docker Compose
├── app          ← Spring Boot（端口 18080）
├── postgresql   ← PostgreSQL 16
├── redis        ← Redis 7
└── nginx        ← 反向代理 + 静态瓦片
```
