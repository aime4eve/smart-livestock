# Mock Server → Spring Boot 迁移指南

> **适用对象**: Flutter 前端、Vue 3 PC 端开发人员
> **迁移窗口**: Spring Boot Phase 1 上线 → Mock Server 下线
> **Mock Server 最终状态**: 保留作为 Demo 演示和 Phase 2a 功能参考，不再演进

---

## 1. 迁移概览

| 维度 | Mock Server（旧） | Spring Boot（新） |
|------|-----------------|-----------------|
| API 前缀 | `/api/v1/` | `/api/v1/`（不变） |
| 认证 | role-based mock token | `phone + password` → JWT |
| Farm Scope | header `x-active-farm` | 路径 `/farms/{farmId}/`（优先）或 header（兼容过渡） |
| 牧场切换 | `POST /farm/switch-farm` | 客户端 GoRouter 导航 |
| 用户信息 | `GET /profile` | `GET /me`（归一） |
| 牲畜操作 | 无（Demo 预置数据） | CRUD `/farms/{farmId}/livestock/*` |
| 设备路径 | `GET /devices` | `GET /farms/{farmId}/devices` |
| 围栏路径 | `GET /fences` | `GET /farms/{farmId}/fences` |
| 告警路径 | `POST /alerts/{id}/acknowledge` | `POST /farms/{farmId}/alerts/{id}/acknowledge` |
| 数字孪生 | `/twin/*` | Phase 2（`/farms/{farmId}/twin/*`） |
| 订阅/合同/分润 | `/subscription/*`、`/contracts/*`、`/revenue/*` | Phase 2 Commerce |
| Open API | tier-based（free/growth/scale） | 统一 11 端点，无 tier |
| HTTPS | 无 | Nginx 终止 TLS |

---

## 2. Flutter 端迁移清单

### 2.1 认证流程

| 变更 | 旧代码 | 新代码 |
|------|--------|--------|
| 登录请求体 | `{ role: "owner" }` | `{ phone: "13800138000", password: "..." }` |
| Token 获取 | 响应中 `accessToken` 固定 `mock-token-owner` | 真实 JWT（需存储 accessToken + refreshToken） |
| Token 刷新 | 无（mock token 永不过期） | 拦截 401 → `POST /auth/refresh` → 重试原请求 |
| Token 存储 | `ApiAuthTokens` 手动设置 | 登录后自动存储，`apiHeaders()` 自动注入 |

### 2.2 API 路径变更

| 旧路径 | 新路径 | 影响文件 |
|--------|--------|---------|
| `GET /dashboard/summary` | `GET /farms/{farmId}/dashboard/summary` | `api_cache.dart` 预加载列表 |
| `GET /map/trajectories?animalId=&range=` | `GET /farms/{farmId}/map/overview` | `api_cache.dart`，响应结构有变化 |
| `GET /alerts?pageSize=100` | `GET /farms/{farmId}/alerts?pageSize=100` | `api_cache.dart`、`live_alerts_repository.dart` |
| `GET /fences?pageSize=100` | `GET /farms/{farmId}/fences?pageSize=100` | `api_cache.dart`、`live_fence_repository.dart` |
| `GET /devices?pageSize=200` | `GET /farms/{farmId}/devices?pageSize=200` | `api_cache.dart`、`live_device_repository.dart` |
| `GET /profile` | `GET /me` | `api_cache.dart`（兼容：`/profile` 可保留重定向到 `/me`） |
| `GET /farm/my-farms` | `GET /farms` | `api_cache.dart`，响应中新增 `livestockCount`、`deviceCount` 等字段 |
| `POST /farm/switch-farm` | 无（改为 GoRouter 导航） | `farm_switcher_controller.dart` |
| `POST /fences` | `POST /farms/{farmId}/fences` | `api_cache.dart`（createFenceRemote、updateFenceRemote） |
| `PUT /fences/{id}` | `PUT /farms/{farmId}/fences/{id}` | 同上 |
| `DELETE /fences/{id}` | `DELETE /farms/{farmId}/fences/{id}` | 同上 |
| `POST /alerts/{id}/acknowledge` | `POST /farms/{farmId}/alerts/{id}/acknowledge` | `live_alerts_repository.dart` |
| `POST /subscription/checkout` | 无（Phase 2） | 暂时保留 Mock 模式的订阅流程 |
| `GET /twin/overview` | 无（Phase 2） | 暂时保留 Mock 模式的数字孪生数据 |

### 2.3 结构变更

| 变更 | 说明 |
|------|------|
| **GoRouter 路由** | 所有农场级别路由从 `/{page}` 改为 `/{farmId}/{page}`。`FarmSwitcherController` 不再调用 API，改为本地状态 + `GoRouter.go()` |
| **ApiCache 预加载** | 预加载列表从 17 个端点减少为 Phase 1 范围内的约 7 个（dashboard、map、alerts、fences、devices、me、farms）。不再预加载 twin、subscription、b2b 端点 |
| **Live Repository 新增** | 新增 `LiveLivestockRepository`（牲畜 CRUD）、`LiveInstallationRepository`（安装记录）、`LiveGpsLogRepository`（GPS 查询） |
| **Device 模型扩展** | `DeviceItem` 增加 `status`（生命周期）和 `runtimeStatus`（运行时）字段。旧枚举值（`online/offline/lowBattery`）映射到新 `runtimeStatus` |
| **枚举值容错** | 所有 Dart 枚举解析增加 `default` 分支容错，确保服务端新增枚举值不导致崩溃 |

### 2.4 不需要变更的

- `APP_MODE=mock` 分支（继续使用 `DemoSeed` 本地数据，不受后端切换影响）
- `DemoRole` 枚举和 `RolePermission` 静态方法
- UI Widget（界面不变，仅数据源从 ApiCache 切换到新 API 响应格式）
- 主题 token（`AppColors`、`AppSpacing`、`AppTypography`）

---

## 3. PC 端（Vue 3）迁移要点

PC 端从零构建，无旧代码迁移负担。直接按新契约对接：

- 认证：统一使用 `POST /api/v1/auth/login` + JWT
- Admin 功能：对接 `/api/v1/admin/*` 全部 21 个端点
- 农场资源浏览：platform_admin 可复用 App API 端点（`/api/v1/farms/{farmId}/...`）
- **CORS**: Nginx 配置允许 Vue 3 开发服务器来源（`http://localhost:5173`）的跨域请求

---

## 4. 初始种子数据

Spring Boot 首次启动时通过 Flyway `V4__seed_data.sql` 预置以下数据，密码使用 BCrypt 哈希存储：

| 实体 | 字段 | 值 |
|------|------|------|
| **platform_admin** | phone / password / role | `13800000000` / `Admin@123` / `platform_admin` |
| **SAMPLE 租户** | name / phase | `Demo牧场` / `sample` |
| **owner 用户** | phone / password / role / tenant_id | `13800138000` / `Owner@123` / `owner` / 1 |
| **demo API Key** | prefix / scopes / rate_limit | `sl_test_` / `["livestock:read","fence:read","alert:read","device:read","gps:read"]` / 60 |

---

## 5. 并行运行期

Spring Boot Phase 1 上线后，Mock Server 与 Spring Boot 短暂并行：

| 模式 | 后端 | 用途 |
|------|------|------|
| `APP_MODE=mock` | 无（本地 DemoSeed） | Flutter 独立开发，不依赖任何后端 |
| `APP_MODE=live` → Spring Boot | Spring Boot :8080 | Phase 1 功能测试和验收 |
| `APP_MODE=live` → Mock Server | Mock Server :3001 | Phase 2a Demo 演示（订阅、数字孪生） |

Flutter 通过 `--dart-define=API_BASE_URL` 在 Mock Server 和 Spring Boot 之间切换。

---

## 6. Mock Server 下线检查清单

- [ ] 所有 App API 端点（49 个）在 Spring Boot 中实现并通过契约测试
- [ ] 所有 Admin API 端点（21 个）在 Spring Boot 中实现
- [ ] 所有 Open API 端点（11 个）在 Spring Boot 中实现
- [ ] Flutter `APP_MODE=live` 模式下全部页面功能正常
- [ ] Flutter `FarmSwitcherController` 已切换到 path-based 模式
- [ ] Flutter `ApiCache` 预加载列表已更新为新端点
- [ ] Vue 3 PC 端 Admin 功能可用
- [ ] 第三方开发者使用新 Open API 完成至少一个集成验证
- [ ] `x-active-farm` header 使用率降至零（监控日志确认）
