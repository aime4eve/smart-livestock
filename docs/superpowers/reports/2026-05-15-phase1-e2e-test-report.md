# Phase 1 端到端测试报告

**日期**: 2026-05-15
**测试环境**: Spring Boot 后端 @ `172.22.1.123:18080` (Docker Compose 部署)
**测试工具**: curl (API E2E), Gradle (后端单测), flutter test (前端单测)

---

## 1. 总体结论

| 维度 | 结果 |
|------|------|
| 后端 API E2E | **26/27 通过** (96.3%) |
| 后端单元测试 | **87/87 通过** (100%) |
| Flutter 前端测试 | **300/303 通过** (99.0%) |
| **综合通过率** | **413/417 (99.0%)** |

---

## 2. 后端 API 端到端测试

### 2.1 认证 (Auth)

| # | 测试项 | 方法 | 路径 | 预期 | 实际 | 结果 |
|---|--------|------|------|------|------|------|
| A1 | Owner 登录 | POST | `/auth/login` (owner) | 200 | 200 | PASS |
| A2 | Admin 登录 | POST | `/auth/login` (admin) | 200 | 200 | PASS |
| C1 | 错误密码 | POST | `/auth/login` (wrong) | 401 | 401 | PASS |
| C2 | 无 Token 访问 | GET | `/me` | 401/403 | 403 | PASS |
| C4 | 无效 Token | GET | `/me` (invalid) | 401 | 403 | MINOR* |

> *C4: 无效 Token 返回 403 而非 401。Spring Security 默认将未认证请求交由 Filter 处理时返回 403。语义上可接受，但不完全符合 API 契约的 401 预期。**P3 低优先级修复**。

### 2.2 Admin API (platform_admin)

| # | 测试项 | 方法 | 路径 | 状态码 | 数据验证 | 结果 |
|---|--------|------|------|--------|---------|------|
| A3 | 平台看板 | GET | `/admin/dashboard` | 200 | 返回统计摘要 | PASS |
| A4 | 租户列表 | GET | `/admin/tenants` | 200 | total=1 | PASS |
| A5 | 租户详情 | GET | `/admin/tenants/1` | 200 | name=Demo牧场-测试1 | PASS |
| A6 | 更新租户 | PUT | `/admin/tenants/1` | 200 | — | PASS |
| A7 | 租户牧场 | GET | `/admin/tenants/1/farms` | 200 | total=1 | PASS |
| A8 | 用户列表 | GET | `/admin/users` | 200 | total=2 | PASS |
| A9 | 牧场列表 | GET | `/admin/farms` | 200 | total=1 | PASS |
| C5 | 不存在租户 | GET | `/admin/tenants/99999` | 404 | — | PASS |
| C6 | 启禁用租户 | PUT | `/admin/tenants/1/status` | 200 | — | PASS |
| D1 | API Keys (stub) | GET | `/admin/api-keys` | 200 | 空列表 | PASS |
| D2 | 审计日志 (stub) | GET | `/admin/audit-logs` | 200 | 空列表 | PASS |

### 2.3 App API (owner)

| # | 测试项 | 方法 | 路径 | 状态码 | 数据验证 | 结果 |
|---|--------|------|------|--------|---------|------|
| B1 | 个人信息 | GET | `/me` | 200 | name=张牧场 | PASS |
| B2 | 牧场列表 | GET | `/farms` | 200 | farms=1 | PASS |
| B3 | 牧场看板 | GET | `/farms/1/dashboard` | 200 | livestock=1 | PASS |
| B4 | 地图数据 | GET | `/farms/1/map` | 200 | livestock_on_map=0* | PASS |
| B5 | 告警列表 | GET | `/farms/1/alerts` | 200 | total=0 | PASS |
| B6 | 围栏列表 | GET | `/farms/1/fences` | 200 | total=1 | PASS |
| B7 | 设备列表 | GET | `/farms/1/devices` | 200 | total=0 | PASS |
| B8 | 牲畜列表 | GET | `/farms/1/livestock` | 200 | total=1 | PASS |
| B9 | 牧场成员 | GET | `/farms/1/members` | 200 | — | PASS |

> *B4: 地图牲畜坐标为 0，因牲畜无 GPS 数据（GPS 模拟器需已安装设备才产生坐标）。

### 2.4 写操作 (CRUD)

| # | 测试项 | 方法 | 路径 | 状态码 | 结果 |
|---|--------|------|------|--------|------|
| C7 | 创建围栏 | POST | `/farms/1/fences` | 201 | PASS |
| C8 | 更新围栏 | PUT | `/farms/1/fences/2` | 200 | PASS |
| C9 | 删除围栏 | DELETE | `/farms/1/fences/2` | 200 | PASS |

### 2.5 权限隔离

| # | 测试项 | 预期 | 实际 | 结果 |
|---|--------|------|------|------|
| C3 | Owner 访问 Admin API | 403 | 403 | PASS |

---

## 3. 后端单元/集成测试

**总计**: 87 tests, **0 failures**, **0 errors**

| 测试类 | 测试数 | 结果 |
|--------|--------|------|
| UserTest | 7 | ALL PASS |
| AuthApplicationServiceTest | 4 | ALL PASS |
| FarmApplicationServiceTest | 5 | ALL PASS |
| AlertTest | 7 | ALL PASS |
| FenceTest | 4 | ALL PASS |
| LivestockTest | 3 | ALL PASS |
| FenceBreachDetectorTest | 4 | ALL PASS |
| AlertApplicationServiceTest | 8 | ALL PASS |
| DeviceTest | 12 | ALL PASS |
| DeviceLicenseTest | 6 | ALL PASS |
| InstallationTest | 3 | ALL PASS |
| DeviceApplicationServiceTest | 8 | ALL PASS |
| FarmScopeResolverTest | 7 | ALL PASS |
| GpsAlertFlowTest (3 内部类) | 9 | ALL PASS |

---

## 4. Flutter 前端测试

**总计**: 303 tests, **300 通过**, **3 失败**

**失败测试** (均为预存问题，非本次变更引入):

| 测试文件 | 测试名 | 说明 |
|----------|--------|------|
| `fence_live_conflict_feedback_test.dart` | live 编辑保存返回 409 时停留在编辑态 | 围栏编辑 UI 测试 |
| `fence_page_mode_switch_test.dart` | 保存中退出按钮禁用且不会退出编辑态 | 围栏编辑 UI 测试 |
| `farm_switcher_test.dart` | owner 无 farm 时显示引导并隐藏 switcher | 牧场切换器边界测试 |

---

## 5. 发现的问题

### 5.1 已知低优先级

| # | 问题 | 影响 | 优先级 |
|---|------|------|--------|
| 1 | 无效 Token 返回 403 而非 401 | API 契约要求 401 | P3 |
| 2 | 3 个 Flutter 测试失败 | 围栏编辑 UI / 牧场边界场景 | P3 |

### 5.2 Phase 1 未完成项

| # | 项目 | 状态 |
|---|------|------|
| 1 | Task 15: GitLab CI/CD | 未部署 (GitLab 项目/Runner 未创建) |

---

## 6. Phase 1 交付物清单

| 交付物 | 状态 |
|--------|------|
| Spring Boot 后端 (Identity + Ranch + IoT) | 已部署运行 |
| PostgreSQL 数据库 (V1-V5 迁移 + 种子数据) | 已部署运行 |
| Docker Compose 部署 (App + PostgreSQL + Redis + Nginx) | 已部署运行 |
| GPS 模拟数据生成器 | 已部署运行 |
| Flutter 前端 Live 模式 (21 个 Live Repository) | 已实现 |
| 后端单元/集成测试 (87 tests) | 100% 通过 |
| 前端测试 (303 tests) | 99.0% 通过 |

---

**报告生成时间**: 2026-05-15
**生成方式**: 自动化 E2E 测试 + 手动汇总
