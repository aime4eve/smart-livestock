# 智慧畜牧系统（Smart Livestock）功能说明文档

> 版本：v1.0 · 生成日期：2026-06-01  
> 基于全量前后端代码分析

---

## 目录

1. [系统概览](#1-系统概览)
2. [限界上下文与功能模块](#2-限界上下文与功能模块)
3. [已实现功能清单](#3-已实现功能清单)
4. [前后端对接状态矩阵](#4-前后端对接状态矩阵)
5. [未实现功能与实现建议](#5-未实现功能与实现建议)

---

## 1. 系统概览

智慧畜牧系统是面向牧场主的牲畜管理平台，通过 IoT 设备（GPS 追踪器、瘤胃胶囊、加速度计）实现定位、健康预警和行为分析。

### 1.1 技术架构

| 端 | 技术栈 | 部署位置 |
|---|--------|---------|
| **后端** | Spring Boot 3.3 + Java 17 + PostgreSQL 16 + Redis 7 + RocketMQ 5.1 | 172.22.1.123:18080 (Docker) |
| **移动端（Flutter）** | Flutter + Riverpod + Go Router + flutter_map | Android / iOS / Web |
| **开发者门户** | Vue 3 + Vite + Pinia | 静态站点 |
| **PC 端** | Angular 17 + Leaflet + Chart.js（静态 JSON 数据，不活跃） | — |

### 1.2 限界上下文总览

| 限界上下文 | 阶段 | Controller 数 | 状态 |
|-----------|------|-------------|------|
| Identity（身份与租户） | Phase 1 | 9 | ✅ 已完成 |
| Ranch（牧场管理） | Phase 1 | 8 | ✅ 已完成 |
| IoT（设备管理） | Phase 1 | 7 | ✅ 已完成 |
| Commerce（商业计费） | Phase 2a | 7 | ✅ 已完成 |
| Health（健康分析） | Phase 2b | 5 | ✅ 已完成 |
| Analytics + Portal（统计与开发者门户） | Phase 2c | 4 | ✅ 已完成 |
| Shared（公共基础设施） | Phase 1 | 1 | ✅ 已完成 |

### 1.3 数据库表

共 23 个 Flyway 迁移，30+ 张表：

| 表名 | 限界上下文 | 迁移版本 |
|------|-----------|---------|
| tenants | Identity | V1 |
| farms | Identity | V1 |
| users | Identity | V1 |
| user_farm_assignments | Identity | V1 |
| api_keys | Identity | V1（V22 扩展） |
| livestock | Ranch | V2 |
| fences / fence_versions | Ranch | V2 |
| alerts | Ranch | V2 |
| devices | IoT | V3 |
| device_licenses | IoT | V3 |
| installations | IoT | V3 |
| gps_logs | IoT | V3 |
| subscriptions | Commerce | V6 |
| contracts | Commerce | V6 |
| revenue_periods | Commerce | V6 |
| subscription_services | Commerce | V6 |
| feature_gates | Commerce | V6 |
| notifications | Commerce | V6 |
| tile_regions / tile_tasks / farm_tile_tasks / tile_download_logs | Ranch | V13 |
| audit_logs | Shared | V18 |
| temperature_logs / rumen_motility_logs / estrus_scores / health_snapshots / contact_traces | Health | V20 |
| api_call_logs / api_usage_daily | Analytics | V22 |

---

## 2. 限界上下文与功能模块

### 2.1 Identity（身份与租户管理）

负责多租户隔离、用户管理、角色权限、认证授权和牧场归属。

#### 后端 API（9 个 Controller，~25 个端点）

| 端点 | 方法 | 路径 | 说明 |
|-----|------|------|------|
| AuthController | POST | `/api/v1/auth/login` | 手机号+密码登录，返回 JWT |
| | POST | `/api/v1/auth/refresh` | 刷新 access token |
| | POST | `/api/v1/auth/logout` | 登出（客户端丢弃 token） |
| MeController | GET | `/api/v1/me` | 获取当前用户信息 |
| | PUT | `/api/v1/me` | 更新用户资料（姓名、手机号） |
| | PUT | `/api/v1/me/password` | 修改密码（需验证旧密码） |
| TenantController | GET | `/api/v1/tenants/me` | 获取当前租户信息 |
| | PUT | `/api/v1/tenants/me` | 更新租户信息 |
| FarmController | GET | `/api/v1/farms` | 列出租户下所有牧场 |
| | POST | `/api/v1/farms` | 创建牧场（owner 角色可创建） |
| | GET | `/api/v1/farms/{farmId}` | 获取牧场详情 |
| | PUT | `/api/v1/farms/{farmId}` | 更新牧场 |
| | GET | `/api/v1/farms/{farmId}/members` | 列出牧场成员 |
| | POST | `/api/v1/farms/{farmId}/members` | 添加成员到牧场 |
| | DELETE | `/api/v1/farms/{farmId}/members/{userId}` | 移除牧场成员 |
| TenantAdminController | GET | `/api/v1/admin/tenants` | 管理员列出所有租户 |
| | GET | `/api/v1/admin/tenants/{id}` | 获取租户详情 |
| | POST | `/api/v1/admin/tenants` | 创建租户 |
| | PUT | `/api/v1/admin/tenants/{id}` | 更新租户 |
| | PUT | `/api/v1/admin/tenants/{id}/status` | 启用/禁用租户 |
| UserAdminController | GET | `/api/v1/admin/users` | 管理员列出所有用户 |
| | GET | `/api/v1/admin/users/{userId}` | 获取用户详情 |
| | POST | `/api/v1/admin/users` | 创建用户 |
| | PUT | `/api/v1/admin/users/{userId}` | 更新用户 |
| | PUT | `/api/v1/admin/users/{userId}/status` | 启用/禁用用户 |
| | POST | `/api/v1/admin/users/{userId}/reset-password` | 重置用户密码 |
| FarmAdminController | GET | `/api/v1/admin/farms` | 管理员列出所有牧场 |
| | GET | `/api/v1/admin/farms/{farmId}` | 获取牧场详情 |
| ApiKeyAdminController | GET | `/api/v1/admin/api-keys` | 管理员列出 API Keys |
| | POST | `/api/v1/admin/api-keys` | 创建 API Key |
| | PUT | `/api/v1/admin/api-keys/{keyId}/status` | 更新 Key 状态 |
| | DELETE | `/api/v1/admin/api-keys/{keyId}` | 删除 Key |
| DashboardAdminController | GET | `/api/v1/admin/dashboard` | 平台概览（租户数/牧场数/用户数） |
| AuditLogController | GET | `/api/v1/admin/audit-logs` | 查询审计日志 |

#### 角色体系（5 种角色）

| 角色 | 权限范围 | Shell 类型 |
|------|---------|-----------|
| platform_admin | 租户全量管理 + 用户管理 + 合同 + 分润 + 订阅服务 + API Key 审批 | 纯 Scaffold |
| b2b_admin | 概览 + 牧场管理 + 合同信息 + 对账 + 牧工管理 | NavigationRail |
| owner | 全部页面 + 后台管理 + 牧工管理 + 订阅管理 | 底部导航栏 |
| worker | 看板/地图/告警/我的/围栏，仅确认告警 | 底部导航栏 |
| api_consumer | API 访问（开发者门户） | — |

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| 登录（手机号+密码） | ✅ AuthController | ✅ LoginPage | ✅ 已对接 |
| Token 刷新 | ✅ `/auth/refresh` | ❌ 未调用 | ⚠️ 前端未实现自动刷新 |
| 获取当前用户 | ✅ MeController | ✅ MineApiRepository | ✅ 已对接 |
| 修改资料 | ✅ `/me` PUT | ✅ MineApiRepository | ✅ 已对接 |
| 修改密码 | ✅ `/me/password` | ✅ MineApiRepository | ✅ 已对接 |
| 获取租户信息 | ✅ `/tenants/me` | ✅ MineApiRepository | ✅ 已对接 |
| 管理租户列表 | ✅ TenantAdminController | ✅ AdminApiRepository | ✅ 已对接 |
| 创建租户 | ✅ `/admin/tenants` POST | ✅ AdminApiRepository | ✅ 已对接 |
| 启停租户 | ✅ `/admin/tenants/{id}/status` | ✅ AdminApiRepository | ✅ 已对接 |
| 管理用户列表 | ✅ UserAdminController | ✅ AdminApiRepository | ✅ 已对接 |
| 创建用户 | ✅ `/admin/users` POST | ✅ AdminApiRepository | ✅ 已对接 |
| 启停用户 | ✅ `/admin/users/{id}/status` | ✅ AdminApiRepository | ✅ 已对接 |
| 重置密码 | ✅ `/admin/users/{id}/reset-password` | ✅ AdminApiRepository | ✅ 已对接 |
| 列出牧场 | ✅ FarmController | ✅ FarmSwitcherController | ✅ 已对接 |
| 创建牧场 | ✅ FarmController | ✅ FarmCreationWizard | ✅ 已对接 |
| 牧场成员管理 | ✅ FarmController | ✅ WorkerApiRepository | ✅ 已对接 |
| API Key 管理（管理员） | ✅ ApiKeyAdminController | ✅ AdminApiRepository | ✅ 已对接 |
| 平台 Dashboard | ✅ DashboardAdminController | ✅ AdminApiRepository | ✅ 已对接 |
| 审计日志查询 | ✅ AuditLogController | ❌ 无前端页面 | ⚠️ 后端已实现，前端缺失 |
| 管理员管理牧场 | ✅ FarmAdminController | ✅ AdminApiRepository | ✅ 已对接 |

---

### 2.2 Ranch（牧场管理）

负责牲畜、围栏、告警、仪表盘、地图、瓦片管理。

#### 后端 API（8 个 Controller，~30 个端点）

| Controller | 方法 | 路径 | 说明 |
|-----------|------|------|------|
| LivestockController | GET | `/farms/{farmId}/livestock` | 列出牲畜（分页+过滤） |
| | POST | `/farms/{farmId}/livestock` | 添加牲畜 |
| | GET | `/farms/{farmId}/livestock/{id}` | 牲畜详情 |
| | PUT | `/farms/{farmId}/livestock/{id}` | 更新牲畜 |
| | DELETE | `/farms/{farmId}/livestock/{id}` | 删除牲畜 |
| FenceController | GET | `/farms/{farmId}/fences` | 列出围栏 |
| | POST | `/farms/{farmId}/fences` | 创建围栏 |
| | GET | `/farms/{farmId}/fences/{id}` | 围栏详情 |
| | PUT | `/farms/{farmId}/fences/{id}` | 更新围栏 |
| | PUT | `/farms/{farmId}/fences/{id}/force` | 强制更新围栏 |
| | DELETE | `/farms/{farmId}/fences/{id}` | 删除围栏 |
| AlertController | GET | `/farms/{farmId}/alerts` | 列出告警（分页+过滤） |
| | GET | `/farms/{farmId}/alerts/{id}` | 告警详情 |
| | POST | `/farms/{farmId}/alerts/{id}/acknowledge` | 确认告警 |
| | POST | `/farms/{farmId}/alerts/{id}/handle` | 处理告警 |
| | POST | `/farms/{farmId}/alerts/{id}/archive` | 归档告警 |
| | POST | `/farms/{farmId}/alerts/batch-handle` | 批量处理告警 |
| DashboardController | GET | `/farms/{farmId}/dashboard/summary` | 仪表盘概览 |
| MapController | GET | `/farms/{farmId}/map/overview` | 地图概览 |
| TileController | GET | `/admin/tiles/status` | 瓦片任务状态 |
| | GET | `/farms/{farmId}/offline-map` | 离线地图 |
| TileAppController | GET | `/farms/{farmId}/tile-status` | 牧场瓦片状态 |
| | GET | `/farms/{farmId}/tile-source` | 瓦片源 |
| | POST | `/farms/{farmId}/tile-download-log` | 下载日志 |
| TileAdminController | GET | `/admin/tiles/regions` | 管理瓦片区域 |
| | POST | `/admin/tiles/regions` | 创建区域 |
| | GET/POST | `/admin/tiles/tasks` | 管理/创建瓦片任务 |
| | PUT | `/admin/tiles/tasks/{id}/status` | 更新任务状态 |
| AnalyticsController | POST | `/analytics/events` | 接收分析事件 |

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| 牲畜列表 | ✅ | ✅ LivestockApiRepository | ✅ 已对接 |
| 添加牲畜 | ✅ | ✅ LivestockApiRepository | ✅ 已对接 |
| 牲畜详情 | ✅ | ✅ LivestockApiRepository | ✅ 已对接 |
| 更新牲畜 | ✅ | ✅ LivestockApiRepository | ✅ 已对接 |
| 删除牲畜 | ✅ | ✅ LivestockApiRepository | ✅ 已对接 |
| 围栏列表 | ✅ | ✅ FenceApiRepository | ✅ 已对接 |
| 创建围栏 | ✅ | ✅ FenceApiRepository + FarmCreationWizard | ✅ 已对接 |
| 围栏详情 | ✅ | ✅ FenceApiRepository | ✅ 已对接 |
| 更新围栏 | ✅ | ✅ FenceApiRepository | ✅ 已对接 |
| 删除围栏 | ✅ | ✅ FenceApiRepository | ✅ 已对接 |
| 强制更新围栏 | ✅ `PUT /fences/{id}/force` | ❌ 未调用 | ⚠️ 前端未对接 |
| 告警列表 | ✅ | ✅ AlertsApiRepository | ✅ 已对接 |
| 确认/处理/归档告警 | ✅ | ✅ AlertsApiRepository | ✅ 已对接 |
| 批量处理告警 | ✅ | ✅ AlertsApiRepository | ✅ 已对接 |
| 仪表盘概览 | ✅ | ✅ DashboardApiRepository | ✅ 已对接 |
| 地图概览 | ✅ | ✅ MapApiRepository | ✅ 已对接 |
| 瓦片管理（App） | ✅ | ✅ OfflineTileManagement | ✅ 已对接 |
| 瓦片管理（Admin） | ✅ TileAdminController | ❌ 无前端页面 | ⚠️ 后端已实现，前端缺失 |
| 分析事件上报 | ✅ AnalyticsController | ❌ 未调用 | ⚠️ 前端未对接 |
| 离线围栏同步 | ✅ 后端 API 已就绪 | ✅ FenceSyncService | ✅ 已对接 |
| 离线牲畜缓存 | N/A（纯客户端） | ✅ LivestockPositionCache | ✅ 已实现 |

---

### 2.3 IoT（设备管理）

负责设备注册、License、安装、GPS 日志。

#### 后端 API（7 个 Controller，~20 个端点）

| Controller | 方法 | 路径 | 说明 |
|-----------|------|------|------|
| DeviceController | GET | `/farms/{farmId}/devices` | 列出设备 |
| | POST | `/farms/{farmId}/devices` | 注册设备 |
| | GET | `/farms/{farmId}/devices/{id}` | 设备详情 |
| | PUT | `/farms/{farmId}/devices/{id}` | 更新设备 |
| | PUT | `/farms/{farmId}/devices/{id}/activate` | 激活设备 |
| | PUT | `/farms/{farmId}/devices/{id}/decommission` | 退役设备 |
| DeviceLicenseController | GET | `/device-licenses` | 列出 License |
| | GET | `/device-licenses/{id}` | License 详情 |
| | POST | `/device-licenses` | 创建 License |
| | PUT | `/device-licenses/{id}/revoke` | 撤销 License |
| InstallationController | GET | `/farms/{farmId}/installations` | 列出安装记录 |
| | POST | `/farms/{farmId}/installations` | 创建安装记录 |
| | GET | `/farms/{farmId}/installations/{id}` | 安装详情 |
| | PUT | `/farms/{farmId}/installations/{id}/uninstall` | 卸载 |
| GpsLogController | GET | `/farms/{farmId}/gps-logs/latest` | 最新 GPS |
| | GET | `/farms/{farmId}/livestock/{id}/gps-logs` | 牲畜 GPS 历史 |
| OpenDeviceController | GET | `/api/v1/open/farms/{farmId}/devices` | Open API: 设备列表 |
| OpenDeviceRegisterController | POST | `/api/v1/open/devices/register` | Open API: 设备注册 |
| OpenGpsController | GET | `/api/v1/open/farms/{farmId}/gps-logs/latest` | Open API: GPS |

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| 设备列表 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 注册设备 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 设备详情 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 更新设备 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 激活设备 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 退役设备 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| License 列表 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| 安装记录 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| GPS 最新位置 | ✅ | ✅ DevicesApiRepository + MapApiRepository | ✅ 已对接 |
| GPS 历史 | ✅ | ✅ DevicesApiRepository | ✅ 已对接 |
| License 创建/撤销 | ✅ | ❌ 前端未调用 | ⚠️ 前端未对接 |
| 安装/卸载操作 | ✅ | ❌ 前端未调用 | ⚠️ 前端未对接 |
| Open API（设备/GPS） | ✅ | ❌ 前端无直接调用 | ✅ 通过 API Key + 开发者门户 |

---

### 2.4 Commerce（商业计费）

负责订阅管理、合同管理、分润对账、Tier 配额引擎、FeatureGate。

#### 后端 API（7 个 Controller，~30 个端点）

| Controller | 方法 | 路径 | 说明 |
|-----------|------|------|------|
| SubscriptionController | GET | `/subscription` | 获取当前订阅 |
| | GET | `/subscription/plans` | 获取套餐列表 |
| | POST | `/subscription/checkout` | 订阅结算 |
| | PUT | `/subscription/tier` | 升级/降级 |
| | POST | `/subscription/cancel` | 取消订阅 |
| | GET | `/subscription/usage` | 使用量统计 |
| CommerceController | GET | `/contracts/me` | B端查看合同 |
| | GET | `/revenue/periods` | B端查看分润 |
| | POST | `/revenue/periods/{id}/confirm` | B端确认分润 |
| AdminSubscriptionController | GET | `/admin/subscriptions` | 管理订阅列表 |
| | GET | `/admin/subscriptions/{id}` | 订阅详情 |
| | PUT | `/admin/subscriptions/{id}/status` | 变更订阅状态 |
| AdminContractController | GET | `/admin/contracts` | 合同列表 |
| | POST | `/admin/contracts` | 创建合同 |
| | GET | `/admin/contracts/{id}` | 合同详情 |
| | PUT | `/admin/contracts/{id}` | 更新合同 |
| | POST | `/admin/contracts/{id}/sign` | 签约 |
| | PUT | `/admin/contracts/{id}/status` | 变更合同状态 |
| AdminRevenueController | GET | `/admin/revenue/periods` | 分润周期列表 |
| | GET | `/admin/revenue/periods/{id}` | 周期详情 |
| | POST | `/admin/revenue/calculate` | 触发计算 |
| | POST | `/admin/revenue/periods/{id}/confirm` | 平台确认 |
| | POST | `/admin/revenue/periods/{id}/recalculate` | 重新计算 |
| AdminFeatureGateController | GET | `/admin/feature-gates` | 列出功能门控 |
| | PUT | `/admin/feature-gates/{id}` | 更新功能门控 |
| AdminServiceController | GET | `/admin/subscription-services` | 列出授权服务 |
| | POST | `/admin/subscription-services` | 创建授权服务 |
| | GET | `/admin/subscription-services/{id}` | 服务详情 |
| | PUT | `/admin/subscription-services/{id}/status` | 变更状态 |
| | PUT | `/admin/subscription-services/{id}/quota` | 调整配额 |

#### 订阅 Tier 体系

| Tier | 价格 | 包含牲畜数 | 超额价格 |
|------|------|-----------|---------|
| BASIC | 免费 | 50 | ¥2/头/月 |
| STANDARD | ¥298/月 | 200 | ¥1.5/头/月 |
| PREMIUM | ¥698/月 | 1000 | ¥1/头/月 |
| ENTERPRISE | ¥1998/月 | 10000 | ¥0.5/头/月 |

#### FeatureGate 配额

23 个 feature flag 控制：牲畜上限、围栏上限、设备上限、GPS 频率、数据保留天数、高级分析、离线地图、API 访问等。

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| 获取当前订阅 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 套餐列表 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 订阅结算 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 升级/降级 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 取消订阅 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 使用量 | ✅ | ✅ SubscriptionApiRepository | ✅ 已对接 |
| 合同管理（Admin） | ✅ | ✅ ContractApiRepository | ✅ 已对接 |
| 签约 | ✅ | ✅ ContractApiRepository | ✅ 已对接 |
| 合同状态变更 | ✅ | ✅ ContractApiRepository | ✅ 已对接 |
| 分润列表（Admin） | ✅ | ✅ RevenueApiRepository | ✅ 已对接 |
| 分润详情 | ✅ | ✅ RevenueApiRepository | ✅ 已对接 |
| 触发计算/确认/重算 | ✅ | ✅ RevenueApiRepository | ✅ 已对接 |
| 订阅管理（Admin） | ✅ | ✅ SubscriptionServiceApiRepository | ✅ 已对接 |
| 授权服务 CRUD | ✅ | ✅ SubscriptionServiceApiRepository | ✅ 已对接 |
| B端查看合同 | ✅ CommerceController | ❌ 前端调 `/b2b/contract` | ❌ 路径不匹配 |
| B端查看分润 | ✅ CommerceController | ❌ 前端调 `/revenue/periods` | ⚠️ 部分路径匹配 |
| 功能门控（Admin） | ✅ AdminFeatureGateController | ❌ 前端未调用 | ⚠️ 前端未对接 |
| 授权服务列表（Admin） | ✅ 但返回空 | ✅ 调用但无数据 | ⚠️ 后端 stub |

---

### 2.5 Health（健康分析）

负责温度监测、蠕动分析、发情识别、疫病防控。

#### 后端 API（5 个 Controller，9 个端点）

| Controller | 方法 | 路径 | 说明 |
|-----------|------|------|------|
| HealthOverviewController | GET | `/farms/{farmId}/health/overview` | 健康概览 |
| FeverController | GET | `/farms/{farmId}/health/fever` | 发热预警列表 |
| | GET | `/farms/{farmId}/health/fever/{livestockId}` | 牲畜发热详情 |
| DigestiveController | GET | `/farms/{farmId}/health/digestive` | 消化管理列表 |
| | GET | `/farms/{farmId}/health/digestive/{livestockId}` | 牲畜消化详情 |
| EstrusController | GET | `/farms/{farmId}/health/estrus` | 发情识别列表 |
| | GET | `/farms/{farmId}/health/estrus/{livestockId}` | 牲畜发情详情 |
| EpidemicController | GET | `/farms/{farmId}/health/epidemic` | 疫病防控列表 |

#### 数据表

| 表 | 说明 |
|---|------|
| temperature_logs | 瘤胃温度时序（按月分区，delta 生成列） |
| rumen_motility_logs | 瘤胃蠕动时序（按月分区） |
| estrus_scores | 发情评分 |
| health_snapshots | 健康快照 |
| contact_traces | 接触追踪 |

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| 健康概览 | ✅ | ❌ 前端 TwinOverviewPage 仅用本地数据 | ⚠️ 前端未对接 |
| 发热预警 | ✅ | ✅ FeverApiRepository | ✅ 已对接 |
| 发热详情 | ✅ | ✅ FeverApiRepository | ✅ 已对接 |
| 消化管理 | ✅ | ✅ DigestiveApiRepository | ✅ 已对接 |
| 消化详情 | ✅ | ✅ DigestiveApiRepository | ✅ 已对接 |
| 发情识别 | ✅ | ✅ EstrusApiRepository | ✅ 已对接 |
| 发情详情 | ✅ | ✅ EstrusApiRepository | ✅ 已对接 |
| 疫病防控 | ✅ | ✅ EpidemicApiRepository | ✅ 已对接 |

---

### 2.6 Analytics + Portal（统计与开发者门户）

负责 API Key 自管理、频率限制、统计聚合、趋势分析。

#### 后端 API（4 个 Controller，~15 个端点）

| Controller | 方法 | 路径 | 说明 |
|-----------|------|------|------|
| PortalAppController | GET | `/portal/keys` | 列出我的 API Keys |
| | POST | `/portal/keys` | 创建 Key |
| | PUT | `/portal/keys/{keyId}` | 更新 Key |
| | PUT | `/portal/keys/{keyId}/status` | 启停 Key |
| | DELETE | `/portal/keys/{keyId}` | 删除 Key |
| | GET | `/portal/keys/{keyId}/usage` | Key 使用量 |
| | GET | `/portal/keys/dashboard` | 使用概览 |
| AnalyticsAppController | GET | `/analytics/usage/overview` | 用量概览 |
| | GET | `/analytics/usage/trend` | 用量趋势 |
| | GET | `/analytics/usage/api-keys/{id}/overview` | Key 用量 |
| | GET | `/analytics/usage/api-keys/{id}/trend` | Key 趋势 |
| PortalAdminController | GET | `/admin/portal/keys` | 管理所有 Key |
| | PUT | `/admin/portal/keys/{id}/rate-limit` | 调整限流 |
| | PUT | `/admin/portal/keys/{id}/scopes` | 调整权限 |
| | POST | `/admin/portal/keys/{id}/approve` | 审批 Key |
| | GET | `/admin/portal/keys/stats` | Key 统计 |
| AnalyticsAdminController | GET | `/admin/analytics/tenants/{id}/usage/overview` | 租户用量 |
| | GET | `/admin/analytics/tenants/{id}/usage/trend` | 租户趋势 |
| | POST | `/admin/analytics/aggregate` | 触发聚合 |

#### 前端对接状态

| 功能 | 后端 | 前端 | 状态 |
|------|------|------|------|
| API Key 自管理（owner） | ✅ PortalAppController | ✅ ApiAuthorizationApiRepository | ✅ 已对接 |
| Key Dashboard | ✅ `/portal/keys/dashboard` | ✅ ApiAuthorizationApiRepository | ✅ 已对接 |
| 用量概览/趋势 | ✅ AnalyticsAppController | ❌ 前端未调用 | ⚠️ 前端未对接 |
| 管理员 Portal 审批 | ✅ PortalAdminController | ❌ 前端未调用 | ⚠️ 前端未对接 |
| 管理员 Analytics | ✅ AnalyticsAdminController | ❌ 前端未调用 | ⚠️ 前端未对接 |
| 开发者门户（独立 Vue 应用） | N/A（调后端 API） | ✅ Vue 独立应用 | ✅ 已对接 |

---

### 2.7 Shared（公共基础设施）

| 功能 | 说明 |
|------|------|
| JWT 认证 | JwtAuthenticationFilter + JwtTokenProvider |
| 多租户隔离 | TenantContext + TenantScope |
| 安全配置 | Spring Security + 角色鉴权 |
| 审计日志 | AuditLogEventListener 监听所有 DomainEvent |
| 统一异常处理 | GlobalExceptionHandler |
| 统一响应格式 | ApiResponse(code, message, requestId, data) |
| 密码哈希 | BCrypt via PasswordHasher |
| 健康检查 | GET /health |

---

## 3. 已实现功能清单

### 3.1 移动端页面（42 条路由）

| 路由 | 页面 | 角色 | 对接状态 |
|------|------|------|---------|
| `/login` | 登录页 | 全部 | ✅ |
| `/twin` | 数智孪生总览 | owner/worker | ⚠️ 本地数据 |
| `/dashboard` | 仪表盘 | owner/worker | ✅ |
| `/alerts` | 告警列表 | owner/worker | ✅ |
| `/mine` | 个人中心 | owner/worker | ✅ |
| `/fence` | 围栏管理 | owner/worker | ✅ |
| `/devices` | 设备管理 | owner | ✅ |
| `/livestock/:id` | 牲畜详情 | owner/worker | ✅ |
| `/fence/form` | 围栏表单 | owner/worker | ✅ |
| `/stats` | 数据统计 | owner | ⚠️ 纯本地 |
| `/twin/fever` | 发热预警 | owner | ✅ |
| `/twin/fever/:id` | 发热详情 | owner | ✅ |
| `/twin/digestive` | 消化管理 | owner | ✅ |
| `/twin/digestive/:id` | 消化详情 | owner | ✅ |
| `/twin/estrus` | 发情识别 | owner | ✅ |
| `/twin/estrus/:id` | 发情详情 | owner | ✅ |
| `/twin/epidemic` | 疫病防控 | owner | ✅ |
| `/subscription` | 订阅管理 | owner | ✅ |
| `/subscription/plans` | 套餐选择 | owner | ✅ |
| `/subscription/checkout` | 确认支付 | owner | ✅ |
| `/mine/workers` | 牧工管理 | owner | ✅ |
| `/mine/api-auth` | API 授权管理 | owner | ✅ |
| `/farm/create` | 创建牧场向导 | owner | ✅ |
| `/offline/tiles` | 离线地图管理 | owner | ✅ |
| `/fence/conflict` | 围栏冲突 | owner | ✅ |
| `/admin` | 后台管理 | platform_admin | ✅ |
| `/ops/admin` | 平台后台 | platform_admin | ✅ |
| `/admin/contracts` | 合同管理 | platform_admin | ✅ |
| `/admin/revenue` | 对账看板 | platform_admin | ✅ |
| `/admin/subscriptions` | 订阅服务管理 | platform_admin | ✅ |
| `/admin/api-auth` | API 授权审批 | platform_admin | ✅ |
| `/b2b/admin` | B端控制台 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/farms` | 牧场管理 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/contract` | 合同信息 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/revenue` | 对账 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/revenue/:id` | 对账详情 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/workers` | 牧工管理 | b2b_admin | ❌ 后端缺失 |
| `/b2b/admin/workers/:farmId` | 牧工详情 | b2b_admin | ❌ 后端缺失 |

### 3.2 开发者门户（Vue 独立应用）

| 页面 | 说明 | 状态 |
|------|------|------|
| 登录 | API Key 认证登录 | ✅ |
| 注册 | 开发者注册 | ✅ |
| Dashboard | 使用概览 | ✅ |
| API Keys | Key 管理 | ✅ |
| Endpoints | API 端点文档 | ✅ |
| Authorizations | 授权记录 | ✅ |
| Settings | 设置 | ✅ |

---

## 4. 前后端对接状态矩阵

### 4.1 严重问题：后端完全缺失的 API

| 前端调用的路径 | 后端状态 | 影响 |
|-------------|---------|------|
| `GET /b2b/dashboard` | ❌ 不存在 | b2b_admin 概览页无法加载 |
| `GET /b2b/contract` | ❌ 不存在 | b2b_admin 合同页无法加载 |
| `GET /b2b/farms` | ❌ 不存在 | b2b_admin 牧场列表无法加载 |
| `GET /b2b/farms/{id}/workers` | ❌ 不存在 | b2b_admin 牧工管理无法加载 |
| `POST /b2b/farms/{id}/workers` | ❌ 不存在 | b2b_admin 分配牧工失败 |
| `DELETE /b2b/farms/{id}/workers/{wid}` | ❌ 不存在 | b2b_admin 移除牧工失败 |
| `GET /b2b/available-workers` | ❌ 不存在 | b2b_admin 可用牧工列表无法加载 |
| `GET /b2b/users` | ❌ 不存在 | b2b_admin 用户列表无法加载 |
| `PUT /farms/{id}/owner` | ❌ 不存在 | b2b_admin 变更牧场主失败 |

### 4.2 前端已对接但后端实现不完整的 API

| 路径 | 问题 | 影响 |
|------|------|------|
| `GET /farms/{farmId}/members` | 后端返回空列表 | 牧场成员管理无数据 |
| `GET /admin/subscription-services` | 后端返回空列表 | 订阅服务管理无数据 |
| `PUT /farms/{farmId}` | 后端未真正更新 | 牧场信息修改不生效 |

### 4.3 后端已实现但前端未对接的 API

| 路径 | 后端 Controller | 前端状态 |
|------|---------------|---------|
| `POST /auth/refresh` | AuthController | ❌ 未调用 |
| `PUT /farms/{farmId}/fences/{id}/force` | FenceController | ❌ 未调用 |
| `POST /analytics/events` | AnalyticsController | ❌ 未调用 |
| `GET /admin/feature-gates` | AdminFeatureGateController | ❌ 未调用 |
| `GET /admin/audit-logs` | AuditLogController | ❌ 无前端页面 |
| `POST /device-licenses` | DeviceLicenseController | ❌ 未调用 |
| `PUT /device-licenses/{id}/revoke` | DeviceLicenseController | ❌ 未调用 |
| `POST /farms/{farmId}/installations` | InstallationController | ❌ 未调用 |
| `PUT /farms/{farmId}/installations/{id}/uninstall` | InstallationController | ❌ 未调用 |
| `GET /analytics/usage/overview` | AnalyticsAppController | ❌ 未调用 |
| `GET /analytics/usage/trend` | AnalyticsAppController | ❌ 未调用 |
| `GET /admin/portal/keys` | PortalAdminController | ❌ 未调用 |
| `PUT /admin/portal/keys/{id}/rate-limit` | PortalAdminController | ❌ 未调用 |
| `POST /admin/portal/keys/{id}/approve` | PortalAdminController | ❌ 未调用 |
| `GET /admin/analytics/tenants/{id}/usage/*` | AnalyticsAdminController | ❌ 未调用 |
| `GET /farms/{farmId}/health/overview` | HealthOverviewController | ❌ 未调用 |
| `GET /admin/tiles/regions` | TileAdminController | ❌ 无前端页面 |
| `POST /admin/tiles/regions` | TileAdminController | ❌ 无前端页面 |
| `GET /admin/tiles/tasks` | TileAdminController | ❌ 无前端页面 |

### 4.4 前端有页面但仅用本地数据的功能

| 页面 | 说明 |
|------|------|
| TwinOverviewPage (`/twin`) | 数智孪生总览，使用本地 demo_seed 数据 |
| StatsPage (`/stats`) | 数据统计，使用本地计算数据 |

---

## 5. 未实现功能与实现建议

### 附录 A：后端缺失 — B2B Admin API（高优先级）

**问题**：前端 b2b_admin 角色有完整的 UI（概览/牧场/合同/对账/牧工管理），但后端完全没有对应的 B2bController，导致 b2b_admin 角色登录后所有页面返回 404。

**建议实现方案**：

1. **创建 B2bController** (`/api/v1/b2b`)，注入现有的 ApplicationService，聚合跨上下文数据：
   - `GET /b2b/dashboard` — 聚合 FarmApplicationService + LivestockApplicationService + AlertApplicationService + DeviceApplicationService，返回 B端概览
   - `GET /b2b/contract` — 从 SubscriptionQueryService 查询合同 + 订阅服务
   - `GET /b2b/farms` — 列出当前租户所有牧场（含 worker 数/牲畜数/设备数）
   - `GET /b2b/farms/{id}/workers` — 查询牧场成员
   - `POST /b2b/farms/{id}/workers` — 分配牧工
   - `DELETE /b2b/farms/{id}/workers/{wid}` — 移除牧工
   - `GET /b2b/available-workers` — 列出租户内未分配的 worker
   - `GET /b2b/users` — 列出租户内用户
   - `PUT /farms/{id}/owner` — 变更牧场主

2. **权限控制**：限制 `B2B_ADMIN` 角色访问，且只能操作自己租户数据。

3. **数据来源**：复用现有 ApplicationService，不需要新建表。B2bController 是一个聚合门面（Facade），将 Identity + Ranch + Commerce 数据组装为 B端视图。

---

### 附录 B：前端缺失 — Token 自动刷新（中优先级）

**问题**：后端已实现 `POST /auth/refresh`，但前端未调用。JWT 过期后用户被强制登出。

**建议实现方案**：

1. 在 `ApiClient` 中添加 401 拦截逻辑：当收到 `AUTH_EXPIRED` 错误码时，自动调用 `/auth/refresh` 换取新 token。
2. 使用 `JwtDecoder` 检查 token 过期时间，在过期前 5 分钟主动刷新。
3. 刷新失败时才真正执行 logout。

---

### 附录 C：前端缺失 — 审计日志页面（低优先级）

**问题**：后端 `GET /admin/audit-logs` 已完整实现（支持分页+过滤），但前端无展示页面。

**建议实现方案**：

1. 在 `features/admin/` 下新增 `audit_log` 模块。
2. 创建 `AuditLogApiRepository`，调用 `/admin/audit-logs`。
3. 创建 `AuditLogPage`，包含时间范围选择、租户/用户/操作类型过滤器。
4. 添加路由到 `platformAdmin` 的子路由中。

---

### 附录 D：后端 Stub — 牧场成员查询（中优先级）

**问题**：`GET /farms/{farmId}/members` 返回空列表，导致牧工管理页面无数据。

**建议实现方案**：

1. 在 `FarmController.listMembers()` 中注入 `UserFarmAssignmentRepository` 和 `UserRepository`。
2. 通过 `assignmentRepository.findByFarmId(farmId)` 查找所有 ACTIVE 成员。
3. 关联 `UserRepository` 获取用户信息，返回完整的成员列表。

---

### 附录 E：后端 Stub — 授权服务列表（低优先级）

**问题**：`GET /admin/subscription-services` 总返回空列表。

**建议实现方案**：

1. 在 `SubscriptionServiceRepository` 中新增 `findAll()` 方法。
2. 更新 `AdminServiceController.listServices()` 调用 `findAll()` 替代硬编码空列表。

---

### 附录 F：前端未对接 — 功能门控管理（低优先级）

**问题**：后端 `AdminFeatureGateController` 提供了查询和更新 FeatureGate 的接口，但前端未调用。

**建议实现方案**：

1. 在 admin 模块中新增 FeatureGate 管理页面。
2. 调用 `GET /admin/feature-gates` 获取列表。
3. 提供 `PUT /admin/feature-gates/{id}` 修改配额参数。

---

### 附录 G：前端未对接 — 用量分析（低优先级）

**问题**：后端 Analytics App 端点已完整实现，但前端未调用。

**建议实现方案**：

1. 将 StatsPage 从本地数据改为调用 `GET /analytics/usage/overview` 和 `GET /analytics/usage/trend`。
2. 在 TwinOverviewPage 中集成 HealthOverview 数据：调用 `GET /farms/{farmId}/health/overview`。

---

### 附录 H：前端未对接 — 分析事件上报（低优先级）

**问题**：后端 `POST /analytics/events` 已实现，支持 8 种事件类型（瓦片下载/同步/离线编辑等），但前端未上报。

**建议实现方案**：

1. 在 FenceSyncService 操作后上报 `fence_sync_conflict` / `fence_offline_edit` 事件。
2. 在 TileProvider 操作后上报 `tile_download_completed` / `tile_cache_hit` 等事件。

---

### 附录 I：后端 Stub — 牧场更新（低优先级）

**问题**：`PUT /farms/{farmId}` 未真正更新牧场信息。

**建议实现方案**：

1. 在 `FarmApplicationService` 中新增 `updateFarm()` 方法。
2. 更新 FarmController 传入 body 参数并调用更新。

---

### 附录 J：PC 端状态说明

**当前状态**：PC 端（Angular）使用静态 JSON 数据，不连接后端。含首页、地图监控、牛只管理、设备管理四个页面。该项目处于不活跃维护状态。

**如需激活 PC 端**：
1. 对接后端 API 替换 JSON 数据源。
2. 新增登录认证（JWT）。
3. 按角色实现路由守卫。

---

### 附录 K：Open API（第三方开发者接口）

**已实现的后端端点**：

| 端点 | 说明 |
|------|------|
| `GET /api/v1/open/farms/{farmId}/livestock` | 牲畜列表 |
| `GET /api/v1/open/farms/{farmId}/livestock/{id}` | 牲畜详情 |
| `GET /api/v1/open/farms/{farmId}/fences` | 围栏列表 |
| `GET /api/v1/open/farms/{farmId}/fences/{id}` | 围栏详情 |
| `GET /api/v1/open/farms/{farmId}/alerts` | 告警列表 |
| `GET /api/v1/open/farms/{farmId}/alerts/{id}` | 告警详情 |
| `GET /api/v1/open/farms/{farmId}/devices` | 设备列表 |
| `GET /api/v1/open/farms/{farmId}/devices/{id}` | 设备详情 |
| `POST /api/v1/open/devices/register` | 设备注册 |
| `GET /api/v1/open/farms/{farmId}/gps-logs/latest` | 最新 GPS |

**认证方式**：API Key（X-API-Key header），频率限制（RPM + 日配额）。

---

## 附录：数据统计

| 指标 | 数量 |
|------|------|
| 后端 Controller | 41 |
| 后端 API 端点 | ~130 |
| 后端 Java 文件 | ~312 |
| 后端测试类 | ~58 |
| 数据库表 | 30+ |
| Flyway 迁移 | 23 |
| 前端功能模块 | 29 |
| 前端路由 | 42 |
| 前端 Repository 文件 | 28 |
| 角色类型 | 5 |
| 订阅 Tier | 4 |
| Feature Gate | 23 |
| 前后端完全对接的端点 | ~85 |
| 后端缺失（B2B） | ~9 |
| 前端未对接（已实现） | ~19 |
| 后端实现不完整（Stub） | ~3 |
