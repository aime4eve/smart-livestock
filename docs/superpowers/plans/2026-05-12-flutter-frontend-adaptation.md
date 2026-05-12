# Flutter 前端适配 Spring Boot 后端

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 Flutter App 的 Live 模式连接 Spring Boot 后端（172.22.1.123:18080），替换 Mock Server。Phase 1 端点（auth/dashboard/map/alerts/fences/livestock/devices）走真实后端，非 Phase 1 功能优雅降级。

**Context:** Spring Boot 后端 MVP Phase 1 已部署（PR #41），81 个端点，三端隔离。Flutter 端当前 Live 模式连 Node.js Mock Server（localhost:3001），使用 `{ role }` 登录拿 mock token。

**关键差异（Mock Server → Spring Boot）：**

| 维度 | Mock Server | Spring Boot |
|------|-------------|-------------|
| 认证 | `POST /auth/login { role }` → mock-token-{role} | `POST /auth/login { phone, password }` → JWT |
| 牧场作用域 | header `activeFarmTenantId` | 路径 `/farms/{farmId}/...`（写操作）|
| Dashboard | `GET /dashboard/summary` | `GET /farms/{farmId}/dashboard` |
| Map | `GET /map/trajectories` | `GET /farms/{farmId}/map` |
| Alerts | `GET /alerts` | `GET /farms/{farmId}/alerts` |
| Fences | `GET /fences` | `GET /farms/{farmId}/fences` |
| Profile | `GET /profile` | `GET /me` |
| Farms | `GET /farm/my-farms` | `GET /farms` |
| 响应格式 | `{ code, message, data }` | `{ code, message, requestId, data }` ✅ 兼容 |

**种子账号（Spring Boot V4 seed）：**
- owner: phone `13800138000`, password `Owner@123`
- platform_admin: phone `13800000000`, password `Admin@123`

**非 Phase 1 功能降级策略：** 这些端点在 Spring Boot 不存在（twin/subscription/b2b/contract/revenue/epidemic/estrus/fever/digestive），ApiCache 请求时返回 null → 仓库返回空状态 → UI 显示"暂无数据"或"即将开放"。

---

## Issue 索引表

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | #40 | Flutter 适配 Spring Boot 后端 |

## 完成记录表

| 完成日期 | Issue | PR | 备注 |

---

## Task 1: Auth 层重写 — phone+password 登录 + JWT 管理

**Files:**
- Modify: `lib/core/api/api_auth.dart`
- Modify: `lib/core/api/api_cache.dart`（auth 相关方法）
- Modify: `lib/app/session/app_session.dart`
- Modify: `lib/app/session/session_controller.dart`

**Spring Boot 登录响应：**
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "uuid",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 2,
      "username": "owner",
      "name": "牧场主",
      "phone": "13800138000",
      "role": "OWNER",
      "tenantId": 1,
      "active": true
    }
  }
}
```

- [ ] **Step 1: 修改 `ApiCache._authenticateRole`**

将 `{ role }` 改为 `{ phone, password }`，解析新响应格式提取 JWT token + user info。

```dart
// api_cache.dart — 修改 _authenticateRole
Future<ApiAuthTokens?> _authenticateRole(String role) async {
  // 不再使用 role 登录，改用 credentials
  // 此方法保留但不再在 live→Spring Boot 模式使用
  ...
}
```

新增方法 `authenticateWithCredentials`：
```dart
Future<AuthResult?> authenticateWithCredentials({
  required String phone,
  required String password,
}) async {
  final response = await _httpClient.post(
    Uri.parse('${resolveApiBaseUrl()}/auth/login'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone, 'password': password}),
  );
  if (response.statusCode != 200) return null;
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  if (body['code'] != 'OK') return null;
  final data = body['data'] as Map<String, dynamic>?;
  if (data == null) return null;
  final token = data['token'] as String?;
  final user = data['user'] as Map<String, dynamic>?;
  if (token == null || user == null) return null;
  return AuthResult(
    accessToken: token,
    user: user,
  );
}
```

新增 `AuthResult` 类：
```dart
class AuthResult {
  const AuthResult({required this.accessToken, required this.user});
  final String accessToken;
  final Map<String, dynamic> user;
}
```

- [ ] **Step 2: 更新 `AppSession`**

新增字段：`userId`, `userName`, `phone`, `tenantId`（从 JWT 登录响应提取），保留 `role` 但改为从 user JSON 解析。

- [ ] **Step 3: 更新 `SessionController`**

新增 `loginWithCredentials(phone, password)` 方法，调用 `ApiCache.authenticateWithCredentials`，存储 JWT + user info 到 session state。

保留 `login(DemoRole role)` 用于 mock 模式。

- [ ] **Step 4: 更新 `apiHeaders`**

确保 Authorization header 使用真实 JWT token，不再 fallback 到 mock token。

- [ ] **Step 5: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(flutter): rewrite auth layer — phone+password login with JWT token management"
```

---

## Task 2: ApiCache 端点映射 — Spring Boot 路径 + Farm Scope

**Files:**
- Modify: `lib/core/api/api_cache.dart`

**核心变更：** `_initForGeneration` 中的预加载端点路径全部改为 Spring Boot 路径。新增 `_activeFarmId` 追踪当前牧场。

- [ ] **Step 1: 添加 `activeFarmId` 追踪**

```dart
String? _activeFarmId;

String? get activeFarmId => _activeFarmId;

set activeFarmId(String? id) => _activeFarmId = id;
```

- [ ] **Step 2: 修改 `_initForGeneration` 端点路径**

```dart
// 旧（Mock Server）:
initGet('/dashboard/summary'),
initGet('/map/trajectories?animalId=animal_001&range=24h'),
initGet('/alerts?pageSize=100'),
initGet('/fences?pageSize=100'),
initGet('/tenants?pageSize=100'),
initGet('/profile'),

// 新（Spring Boot）:
initGet('/farms/$_activeFarmId/dashboard'),
initGet('/farms/$_activeFarmId/map'),
initGet('/farms/$_activeFarmId/alerts?pageSize=100'),
initGet('/farms/$_activeFarmId/fences?pageSize=100'),
// tenants 是 admin 端点，role=platform_admin 时才请求
initGet('/me'),
```

**非 Phase 1 端点（twin/subscription/b2b 等）：** 保留旧路径但 try-catch 包裹，请求失败返回 null，不影响初始化完成。注释标记 `// Phase 2`。

- [ ] **Step 3: 修改 `initWithRoleAuth` → `initWithCredentials`**

新流程：authenticate → 拿到 user + token → 获取 farms 列表 → 设置 activeFarmId → init 预加载。

- [ ] **Step 4: 修改 fence CRUD 方法**

```dart
// createFenceRemote: POST /fences → POST /farms/{farmId}/fences
// updateFenceRemote: PUT /fences/{id} → PUT /farms/{farmId}/fences/{id}
// deleteFenceRemote: DELETE /fences/{id} → DELETE /farms/{farmId}/fences/{id}
// refreshFencesAndMap: 同理添加 farmId
```

- [ ] **Step 5: 修改 tenant 相关方法**

tenant CRUD 走 `/admin/tenants` 前缀（仅 platform_admin 角色）。

- [ ] **Step 6: 修改 `resolveApiBaseUrl` 默认值**

```dart
// 旧: 'http://localhost:3001/api/v1'
// 新: 'http://172.22.1.123:18080/api/v1'  // nginx proxy
```

或保持空字符串，通过 `--dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1` 注入。

- [ ] **Step 7: 验证编译通过**

Run: `flutter analyze`

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(flutter): remap ApiCache endpoints to Spring Boot — farm scope, new paths"
```

---

## Task 3: 登录页面改造 — 手机号+密码表单

**Files:**
- Modify: `lib/features/auth/` 下的登录相关文件
- 可能新增: `lib/features/auth/login_page.dart`（如果当前是角色选择页）

**当前状态：** 登录页是一个角色选择器（点击 owner/worker/admin 图标），对应 Mock Server 的 `{ role }` 登录。

**目标：** Live 模式下显示手机号+密码输入表单，调用 `SessionController.loginWithCredentials`。Mock 模式保留角色选择器。

- [ ] **Step 1: 读取当前登录页代码，理解 UI 结构**

- [ ] **Step 2: 在登录页添加 AppMode 分支**

```dart
// login_page.dart
@override
Widget build(BuildContext context) {
  final appMode = ref.watch(appModeProvider);
  return switch (appMode) {
    AppMode.mock => _RoleSelectionView(...),
    AppMode.live => _CredentialLoginForm(...),
  };
}
```

- [ ] **Step 3: 实现 `_CredentialLoginForm`**

- 手机号输入框（`TextFormField` + phone validator）
- 密码输入框（`TextFormField` + obscureText）
- 登录按钮（调用 `sessionController.loginWithCredentials`）
- 错误提示（Toast/SnackBar）
- 加载状态（CircularProgressIndicator）

- [ ] **Step 4: 验证 Mock 模式不受影响**

Run: `flutter test --name="login"`
Mock 模式仍使用角色选择器。

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(flutter): add phone+password login form for Live mode"
```

---

## Task 4: Farm Switcher 适配 — 路径注入 farmId

**Files:**
- Modify: `lib/features/farm_switcher/farm_switcher_controller.dart`
- Modify: `lib/core/api/api_cache.dart`（farm 列表端点）

**变更：**
- `GET /farm/my-farms` → `GET /farms`（Spring Boot 返回当前用户关联的 farm 列表）
- `activeFarmId` 设置时同步到 `ApiCache.activeFarmId`，确保后续 API 调用包含 farmId

- [ ] **Step 1: 更新 `_liveState` 的数据源**

`GET /farm/my-farms` → `GET /farms`，解析响应中的 farm 列表。Spring Boot 返回格式：
```json
{
  "code": "OK",
  "data": {
    "items": [
      { "id": 1, "name": "Demo牧场", "tenantId": 1, ... }
    ],
    "total": 1
  }
}
```

- [ ] **Step 2: `switchFarm` 同步 activeFarmId 到 ApiCache**

```dart
void switchFarm(String farmId) {
  ...
  ApiCache.instance.activeFarmId = farmId;
}
```

- [ ] **Step 3: 初始 farm 加载流程**

登录成功后 → 获取 farm 列表 → 取第一个 farm 作为 activeFarmId → 同步到 ApiCache → 触发预加载。

- [ ] **Step 4: 验证**

Run: `flutter test`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(flutter): adapt farm switcher for Spring Boot — path-based farm scope"
```

---

## Task 5: Live Repository 响应格式适配

**Files:**
- Modify: `lib/features/dashboard/data/live_dashboard_repository.dart`
- Modify: `lib/features/alerts/data/live_alerts_repository.dart`
- Modify: `lib/features/fence/data/live_fence_repository.dart`
- Modify: `lib/features/devices/data/live_devices_repository.dart`
- Modify: `lib/features/livestock/data/live_livestock_repository.dart`
- Modify: `lib/features/mine/data/live_mine_repository.dart`

**核心变更：** Spring Boot 返回的字段名可能与 Mock Server 不同。需要检查每个 live repo 的 JSON 解析逻辑，确保与 Spring Boot 响应对齐。

**已知差异：**
- ID: Mock Server 用 string id（如 `"tenant_001"`），Spring Boot 用 long id（如 `1`，序列化为字符串）
- 时间戳: 格式可能不同
- 分页: 都用 `{ items, page, pageSize, total }` ✅ 兼容
- 响应 envelope: 都用 `{ code, message, data }` ✅ 兼容（Spring Boot 多了 `requestId`）

- [ ] **Step 1: 逐个检查并修改 live repository 的 JSON 解析**

每个 repo 检查 `cache.xxx` 的字段名是否与 Spring Boot controller 返回的 DTO 字段名对齐。如果 ApiCache 已经做了字段映射（在 Task 2），live repo 可能不需要改。

- [ ] **Step 2: 确认 mine（profile）仓库**

`GET /me` 返回的 user DTO 字段（id, username, name, phone, role, tenantId, active）需与 mine repo 解析对齐。

- [ ] **Step 3: 确认 devices 仓库**

`GET /devices` 返回设备列表，字段名对齐。

- [ ] **Step 4: 运行全部测试**

Run: `flutter test`

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(flutter): adapt live repositories for Spring Boot response format"
```

---

## Task 6: 非 Phase 1 功能优雅降级

**Files:**
- Modify: `lib/core/api/api_cache.dart`（非 Phase 1 端点 try-catch）

**目标：** twin/subscription/b2b/contract/revenue/epidemic/estrus/fever/digestive 这些端点在 Spring Boot 不存在，请求 404 时 ApiCache 返回空数据而非抛异常。

- [ ] **Step 1: 在 `_initForGeneration` 中对非 Phase 1 端点添加 try-catch**

```dart
// Phase 1 端点（必须成功）
final phase1Results = await Future.wait([
  initGet('/farms/$_activeFarmId/dashboard'),
  initGet('/farms/$_activeFarmId/map'),
  ...
]);

// Phase 2 端点（允许失败）
try {
  final twinOverview = await initGet('/twin/overview');
  _twinOverview = twinOverview;
} catch (_) {
  _twinOverview = null;
}
```

- [ ] **Step 2: 各 live repo 在缓存为空时返回空状态（非错误）**

检查 `LiveXxxRepository.load()` 在 `cache.twinOverview == null` 时是否返回 `ViewState.empty` 而非 `ViewState.error`。

- [ ] **Step 3: 验证**

Run: `flutter test`

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(flutter): graceful degradation for non-Phase-1 features"
```

---

## Task 7: Bootstrap 流程重构 — main.dart 启动引导

**Files:**
- Modify: `lib/main.dart`

**当前流程（Live 模式）：**
```
main() → ApiCache.instance.init(role) → runApp(DemoApp)
```

**新流程（Live 模式连 Spring Boot）：**
```
main() → runApp(DemoApp)
  → LoginPage → 用户输入手机号+密码
  → SessionController.loginWithCredentials(phone, password)
    → ApiCache.authenticateWithCredentials → 拿到 JWT + user
    → ApiCache.loadFarms → 拿到 farm 列表
    → ApiCache.activeFarmId = first farm
    → ApiCache.init(user) → 预加载 Phase 1 端点
  → 进入主页面
```

**关键变化：** 预加载从 `main()` 移到登录成功后。`main()` 不再阻塞等待 API 调用。

- [ ] **Step 1: 修改 `main.dart`，Live 模式不再在启动时调用 `ApiCache.init`**

- [ ] **Step 2: 预加载流程移到 `SessionController.loginWithCredentials` 内**

登录成功 → 加载 farms → 设置 activeFarmId → init 预加载。

- [ ] **Step 3: 验证编译 + 运行**

Run: `flutter analyze && flutter test`

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(flutter): move bootstrap preload to post-login — async init with Spring Boot"
```

---

## Task 8: 端到端验证 — 连接 172.22.1.123

**目标：** Flutter Web Live 模式连接 Spring Boot 后端，验证完整登录→看板→围栏→告警流程。

- [ ] **Step 1: 启动 Flutter Web Live 模式**

```bash
cd Mobile/mobile_app
flutter run -d chrome \
  --dart-define=APP_MODE=live \
  --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
```

- [ ] **Step 2: 验证登录**

用 `13800138000` / `Owner@123` 登录，确认拿到 JWT token。

- [ ] **Step 3: 验证 Dashboard/Map/Fences/Alerts**

确认数据从 Spring Boot 后端正确加载并展示。

- [ ] **Step 4: 验证非 Phase 1 功能降级**

确认 twin/subscription 等页面不报错，显示空状态。

- [ ] **Step 5: 更新计划文档完成记录**

- [ ] **Step 6: Commit + PR**

---

## 依赖关系图

```
Task 1 (Auth 层重写) ──→ Task 2 (ApiCache 端点映射) ──→ Task 5 (Live Repo 适配)
                         │                                  │
                         └──→ Task 4 (Farm Switcher)        │
                                                            ↓
Task 3 (登录页面) ←── Task 1 ──→ Task 7 (Bootstrap 重构)
                                                            │
Task 6 (优雅降级) ←── Task 2                                ↓
                                                     Task 8 (E2E 验证)
```

**可并行路径：**
- Task 3 (登录页面) 和 Task 2 (ApiCache) 可并行
- Task 4, 5, 6 在 Task 2 完成后可并行
- Task 8 是最终验证，依赖所有其他 task
