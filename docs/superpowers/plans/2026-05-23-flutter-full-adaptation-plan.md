# Flutter 前端全量适配 Spring Boot 后端 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter App 彻底移除 Mock 模式，全面对接 Spring Boot 真实后端（Phase 1 + Commerce），所有模块走真实 API 数据。

**Architecture:** 替换当前 `ApiCache` 同步预加载架构为异步 `ApiClient` 按需请求。Repository 接口从同步改为 `Future<>` 返回类型。UI 层采用 Riverpod `AsyncValue` 处理 loading/error/data 三态。认证改为手机号+密码 JWT 登录，角色权限从 `DemoRole` 枚举迁移为后端 role 字符串。

**Tech Stack:** Flutter 3.x + Dart + flutter_riverpod + go_router + flutter_secure_storage + http

**Spec:** [2026-05-23-flutter-full-adaptation-design.md](../specs/2026-05-23-flutter-full-adaptation-design.md)

---

## File Structure

### 新建文件

| 文件 | 职责 |
|------|------|
| `lib/core/api/api_client.dart` | 异步 HTTP 客户端：JWT 自动注入、响应解包、错误映射、401 清除 token+throw |
| `lib/core/api/api_exception.dart` | 自定义异常：AuthException、ForbiddenException、QuotaExceededException、ServerException |
| `lib/core/api/jwt_storage.dart` | JWT 安全存储（flutter_secure_storage），token 持久化与读取 |
| `lib/core/models/user_role.dart` | UserRole 枚举（替代 DemoRole），角色权限判断方法 |
| `lib/app/session/app_session.dart` | 新 AppSession（覆盖旧版本），不再依赖 DemoRole |
| `lib/features/dashboard/data/dashboard_api_repository.dart` | 异步 Dashboard repository 实现 |
| `lib/features/alerts/data/alerts_api_repository.dart` | 异步 Alerts repository 实现 |
| `lib/features/fence/data/fence_api_repository.dart` | 异步 Fence repository 实现 |
| `lib/features/livestock/data/livestock_api_repository.dart` | 异步 Livestock repository 实现 |
| `lib/features/devices/data/devices_api_repository.dart` | 异步 Devices repository 实现 |
| `lib/features/subscription/data/subscription_api_repository.dart` | 异步 Subscription repository 实现 |
| `lib/features/contract_management/data/contract_api_repository.dart` | 异步 Contract repository 实现 |
| `lib/features/revenue/data/revenue_api_repository.dart` | 异步 Revenue repository 实现 |
| `lib/features/worker_management/data/worker_api_repository.dart` | 异步 Worker repository 实现 |
| `lib/features/admin/data/admin_api_repository.dart` | 异步 Admin repository 实现 |
| `lib/features/mine/data/mine_api_repository.dart` | 异步 Mine/Profile repository 实现 |
| `lib/widgets/coming_soon_page.dart` | 未实现模块通用占位页面 |
| `smart-livestock-server/.../V9__seed_ranch_data.sql` | Ranch 种子数据 |
| `smart-livestock-server/.../V10__seed_iot_data.sql` | IoT 种子数据 |
| `smart-livestock-server/.../V11__seed_commerce_data.sql` | Commerce 种子数据 |
| `smart-livestock-server/.../V12__seed_twin_data.sql` | Twin 概览种子数据 |

### 修改文件

| 文件 | 变更 |
|------|------|
| `lib/features/auth/login_page.dart` | 移除 Mock 角色选择，仅保留手机号+密码表单 |
| `lib/features/farm_switcher/farm_switcher_controller.dart` | 移除 mock 状态，纯 API 加载 |
| `lib/features/subscription/presentation/subscription_controller.dart` | Feature flag 改为从后端 subscription/usage 获取 |
| `lib/features/subscription/presentation/widgets/locked_overlay.dart` | 从后端配额判断锁定状态 |
| `lib/app/app_router.dart` | 更新 auth guard，使用新 AppSession |
| `lib/app/demo_shell.dart` | 移除 AppMode 分支，更新角色路由逻辑 |
| `lib/app/demo_app.dart` | 移除 AppMode 参数 |
| `lib/main.dart` | 移除 mock 预加载，简化启动流程 |
| `lib/core/models/subscription_tier.dart` | FeatureFlags 改为从后端 subscription/usage 获取配额 |
| `lib/core/permissions/role_permission.dart` | 使用新 UserRole 替代 DemoRole |
| 所有模块 `domain/*_repository.dart` | 接口方法改为 `Future<>` 返回类型 |
| 所有模块 `presentation/*_controller.dart` | 适配异步 repository 调用 |
| `docs/api-contracts/api-overview.md` | §5 路由模式更新为控制器管理 |

### 删除文件

| 文件/目录 | 原因 |
|-----------|------|
| `lib/core/api/api_cache.dart` | 替换为 ApiClient |
| `lib/core/api/api_auth.dart` | JWT 逻辑移入 ApiClient |
| `lib/core/api/api_role.dart` | DemoRole 相关，删除 |
| `lib/core/api/api_http_client.dart` | 合并到 ApiClient |
| `lib/core/models/demo_role.dart` | 替换为 UserRole |
| `lib/core/models/demo_models.dart` | 重命名为 `core_models.dart`（Task 2a 处理） |
| `lib/core/data/demo_seed.dart` | Mock 种子数据 |
| `lib/core/data/apply_mock_shaping.dart` | Mock 功能门控 |
| `lib/core/mock/` 目录 | Mock 基础设施 |
| 所有 `*_mock_repository.dart` 文件（24 个） | Mock 实现 |
| 所有 `*_live_repository.dart` 文件 | 替换为 `*_api_repository.dart` |
| `lib/app/app_mode.dart` | 移除 AppMode 枚举 |
| `Mobile/backend/` 目录 | 整个 Mock Server |

---

## Issue 索引表

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | 待创建 | Flutter 全量适配 Spring Boot 后端 |

## 完成记录表

| 完成日期 | Issue | PR | 备注 |
|---------|-------|----|------|

---

## Task 1: ApiClient 基础设施

**Files:**
- Create: `lib/core/api/api_exception.dart`
- Create: `lib/core/api/jwt_storage.dart`
- Create: `lib/core/api/api_client.dart`

- [ ] **Step 1: 创建 `api_exception.dart`**

```dart
// lib/core/api/api_exception.dart

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException({required this.message, this.statusCode, this.code});
}

class AuthException extends ApiException {
  const AuthException({super.message = '认证失败', super.statusCode, super.code});
}

class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = '无权限访问', super.statusCode, super.code});
}

class QuotaExceededException extends ApiException {
  const QuotaExceededException({super.message = '配额不足', super.statusCode, super.code});
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = '资源不存在', super.statusCode, super.code});
}

class ConflictException extends ApiException {
  const ConflictException({super.message = '数据冲突', super.statusCode, super.code});
}

class ValidationException extends ApiException {
  const ValidationException({super.message = '数据校验失败', super.statusCode, super.code});
}

class ServerException extends ApiException {
  const ServerException({super.message = '服务器异常', super.statusCode, super.code});
}

class NetworkException extends ApiException {
  const NetworkException({super.message = '网络连接失败', super.statusCode});
}
```

- [ ] **Step 2: 添加 flutter_secure_storage 依赖并创建 `jwt_storage.dart`**

Run: `cd Mobile/mobile_app && flutter pub add flutter_secure_storage`

```dart
// lib/core/api/jwt_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JwtStorage {
  JwtStorage._();
  static final JwtStorage instance = JwtStorage._();

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
```

- [ ] **Step 3: 创建 `api_client.dart`**

```dart
// lib/core/api/api_client.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'jwt_storage.dart';

typedef OnAuthFailure = void Function();

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String _baseUrl = kIsWeb
      ? 'http://127.0.0.1:18080/api/v1'
      : 'http://localhost:18080/api/v1';
  String? _activeFarmId;
  OnAuthFailure? onAuthFailure;

  String get baseUrl => _baseUrl;
  String? get activeFarmId => _activeFarmId;

  void setBaseUrl(String url) => _baseUrl = url;
  void setActiveFarmId(String? id) => _activeFarmId = id;
  Future<String?> getStoredToken() => JwtStorage.instance.getAccessToken();

  Future<Map<String, String>> _headers() async {
    final token = await JwtStorage.instance.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<void> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> farmGet(String suffix) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return get('/farms/$_activeFarmId$suffix');
  }

  Future<Map<String, dynamic>> farmPost(String suffix, {Object? body}) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return post('/farms/$_activeFarmId$suffix', body: body);
  }

  Future<Map<String, dynamic>> farmPut(String suffix, {Object? body}) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return put('/farms/$_activeFarmId$suffix', body: body);
  }

  Future<void> farmDelete(String suffix) async {
    if (_activeFarmId == null) throw StateError('No active farm');
    return delete('/farms/$_activeFarmId$suffix');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // 401: clear token + notify auth failure + throw immediately
    if (response.statusCode == 401) {
      JwtStorage.instance.clear();
      onAuthFailure?.call();
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw AuthException(
        message: body?['message'] as String? ?? '认证失败',
        statusCode: 401,
        code: body?['code'] as String?,
      );
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 400) {
        throw ServerException(message: '服务器异常', statusCode: response.statusCode);
      }
      return {};
    }

    final code = body['code'] as String?;
    final message = body['message'] as String? ?? '';

    if (response.statusCode >= 500) {
      throw ServerException(message: message, statusCode: response.statusCode, code: code);
    }

    switch (response.statusCode) {
      case 403:
        if (code == 'TENANT_DISABLED') {
          throw ForbiddenException(message: '租户已禁用', statusCode: 403, code: code);
        }
        if (code == 'QUOTA_EXCEEDED') {
          throw QuotaExceededException(message: message, statusCode: 403, code: code);
        }
        throw ForbiddenException(message: message, statusCode: 403, code: code);
      case 404:
        throw NotFoundException(message: message, statusCode: 404, code: code);
      case 409:
        throw ConflictException(message: message, statusCode: 409, code: code);
    }

    if (response.statusCode >= 400) {
      throw ValidationException(message: message, statusCode: response.statusCode, code: code);
    }

    if (code != 'OK' && code != 'CREATED') {
      throw ApiException(message: message, statusCode: response.statusCode, code: code);
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return {};
    return {'value': data};
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthException(
        message: body['message'] as String? ?? '登录失败',
        statusCode: response.statusCode,
        code: body['code'] as String?,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    final user = data['user'] as Map<String, dynamic>;

    await JwtStorage.instance.saveAccessToken(token);
    return user;
  }

  Future<void> logout() async {
    await JwtStorage.instance.clear();
  }
}
```

- [ ] **Step 4: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze lib/core/api/api_client.dart lib/core/api/api_exception.dart lib/core/api/jwt_storage.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add Mobile/mobile_app/lib/core/api/api_client.dart Mobile/mobile_app/lib/core/api/api_exception.dart Mobile/mobile_app/lib/core/api/jwt_storage.dart Mobile/mobile_app/pubspec.yaml Mobile/mobile_app/pubspec.lock
git commit -m "feat(flutter): add async ApiClient, ApiException, JwtStorage"
```

---

## Task 2: Auth 层重写 + 移除 Mock 模式

**Files:**
- Create: `lib/core/models/user_role.dart`
- Modify: `lib/app/session/app_session.dart`（覆盖旧文件）
- Modify: `lib/app/session/session_controller.dart`（覆盖旧文件）
- Modify: `lib/features/auth/login_page.dart`（覆盖旧文件）
- Modify: `lib/app/app_router.dart`
- Modify: `lib/app/demo_app.dart`
- Modify: `lib/app/demo_shell.dart`
- Modify: `lib/app/expiry_popup_handler.dart`
- Modify: `lib/main.dart`
- Delete: `lib/core/models/demo_role.dart`
- Delete: `lib/app/app_mode.dart`

- [ ] **Step 1: 创建 `user_role.dart`**

```dart
// lib/core/models/user_role.dart

enum UserRole {
  owner,
  worker,
  platformAdmin,
  b2bAdmin,
  apiConsumer;

  static UserRole fromString(String value) {
    return switch (value.toUpperCase()) {
      'OWNER' => UserRole.owner,
      'WORKER' => UserRole.worker,
      'PLATFORM_ADMIN' => UserRole.platformAdmin,
      'B2B_ADMIN' => UserRole.b2bAdmin,
      'API_CONSUMER' => UserRole.apiConsumer,
      _ => UserRole.worker,
    };
  }

  String get wireName => switch (this) {
    UserRole.platformAdmin => 'platform_admin',
    UserRole.b2bAdmin => 'b2b_admin',
    UserRole.apiConsumer => 'api_consumer',
    _ => name,
  };

  bool get canAccessAdminTab => this == UserRole.owner;
  bool get isPlatformAdmin => this == UserRole.platformAdmin;
  bool get isB2bAdmin => this == UserRole.b2bAdmin;
  bool get isApiConsumer => this == UserRole.apiConsumer;
  bool get isOwner => this == UserRole.owner;
  bool get isWorker => this == UserRole.worker;

  Set<String> get visibleTabs => switch (this) {
    UserRole.owner => {'dashboard', 'map', 'alerts', 'fences', 'livestock', 'devices', 'stats', 'twin', 'subscription', 'mine', 'admin'},
    UserRole.worker => {'dashboard', 'map', 'alerts', 'fences', 'mine'},
    UserRole.platformAdmin => {'admin'},
    UserRole.b2bAdmin => {'b2b'},
    UserRole.apiConsumer => {},
  };
}
```

- [ ] **Step 2: 创建新 `app_session.dart`（覆盖旧文件 `lib/app/session/app_session.dart`）**

```dart
// lib/app/session/app_session.dart

import 'package:smart_livestock_demo/core/models/user_role.dart';

class AppSession {
  const AppSession._({
    this.role,
    this.accessToken,
    this.userId,
    this.userName,
    this.phone,
    this.tenantId,
    this.username,
    this.activeFarmId,
  });

  static const loggedOut = AppSession._();

  const AppSession.authenticated({
    required this.role,
    required this.accessToken,
    this.userId,
    this.userName,
    this.phone,
    this.tenantId,
    this.username,
  });

  final UserRole? role;
  final String? accessToken;
  final int? userId;
  final String? userName;
  final String? phone;
  final int? tenantId;
  final String? username;
  final String? activeFarmId;

  bool get isLoggedIn => role != null;

  AppSession copyWith({String? activeFarmId}) {
    return AppSession._(
      role: role,
      accessToken: accessToken,
      userId: userId,
      userName: userName,
      phone: phone,
      tenantId: tenantId,
      username: username,
      activeFarmId: activeFarmId ?? this.activeFarmId,
    );
  }
}
```

- [ ] **Step 3: 重写 `session_controller.dart`（覆盖旧 `lib/app/session/session_controller.dart`）**

```dart
// lib/app/session/session_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class SessionController extends Notifier<AppSession> {
  @override
  AppSession build() => AppSession.loggedOut;

  Future<bool> login({required String phone, required String password}) async {
    try {
      final user = await ApiClient.instance.login(phone: phone, password: password);
      final roleStr = user['role'] as String? ?? '';
      final role = UserRole.fromString(roleStr);

      state = AppSession.authenticated(
        role: role,
        accessToken: await ApiClient.instance.getStoredToken() ?? '',
        userId: user['id'] as int?,
        userName: user['name'] as String?,
        phone: user['phone'] as String?,
        tenantId: user['tenantId'] as int?,
        username: user['username'] as String?,
      );

      // Load farms after successful login (for owner/worker roles)
      if (role == UserRole.owner || role == UserRole.worker) {
        await ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      }

      return true;
    } on AuthException {
      return false;
    } catch (e) {
      debugPrint('Login failed: $e');
      return false;
    }
  }

  void updateActiveFarm(String farmId) {
    state = state.copyWith(activeFarmId: farmId);
    ApiClient.instance.setActiveFarmId(farmId);
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    state = AppSession.loggedOut;
    ApiClient.instance.setActiveFarmId(null);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
```

- [ ] **Step 4: 简化 `login_page.dart` — 移除 Mock 角色选择，仅保留手机号+密码表单**

移除 `_buildMockForm()`、`_RoleButton`、`onSubmit`/`onTokenSubmit` 回调、`_selectedRole` 状态。仅保留 `_buildCredentialForm()` 中的手机号+密码表单。移除 `import demo_role.dart` 和 `import app_mode.dart`。页面构造函数改为 `const LoginPage({super.key})`（无回调参数）。

- [ ] **Step 5: 更新 `app_router.dart` — 移除 AppMode，使用新 AppSession**

修改 `redirect` 函数：
- 移除 `ref.watch(appModeProvider)` 引用
- `session.isLoggedIn` 逻辑不变（`role != null`）
- 替换 `DemoRole` 引用为 `UserRole`
- 替换 `session.isPlatformAdmin` 为 `session.role == UserRole.platformAdmin`
- 替换 `session.isB2bAdmin` 为 `session.role == UserRole.b2bAdmin`

- [ ] **Step 6: 更新 `demo_app.dart` — 移除 AppMode 参数**

移除 `appMode` 参数和 `appModeProvider` watch。移除 `AppMode` 分支。

- [ ] **Step 7: 更新 `demo_shell.dart` — 使用 UserRole.visibleTabs**

移除 `AppMode.mock` 分支。底部导航栏根据 `session.role?.visibleTabs` 生成 tab 列表。

- [ ] **Step 8: 简化 `main.dart` + 设置 onAuthFailure**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';

void main() {
  final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (apiBaseUrl.isNotEmpty) {
    ApiClient.instance.setBaseUrl(apiBaseUrl);
  }
  runApp(const ProviderScope(child: DemoApp()));
}
```

移除 `APP_MODE` 编译参数处理。

注意：`ApiClient.instance.onAuthFailure` 需要在 Widget 树内设置（因为需要访问 `ProviderScope`）。在 `DemoApp` 的 `initState` 中设置：

```dart
// lib/app/demo_app.dart 中 initState 添加:
@override
void initState() {
  super.initState();
  ApiClient.instance.onAuthFailure = () {
    // SessionController.logout 会清除 session state，
    // GoRouter redirect 监听 session 变化自动跳转到 /login。
    // 但 onAuthFailure 可能不在 ProviderScope 上下文内，
    // 所以这里通过 GlobalKey 或 WidgetsBinding 实现。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 通过 Riverpod container 直接操作 session
    });
  };
}
```

实际最简方案：`DemoApp` 不做特殊处理。`ApiClient._handleResponse` 中的 `onAuthFailure?.call()` 仅清除 JwtStorage token。GoRouter 的 `refreshListenable` 监听 session 变化。当 401 发生时，下次 API 请求因无 token 而再次 401 → 用户看到错误 → 手动登出 → 跳 login。如需即时跳转，在 `app_router.dart` 的 `navigatorKey` 上 push 一个 `/login` 路由。

推荐方案：删除 `onAuthFailure` 回调，改为在 `_handleResponse` 的 401 分支中直接不 throw 而是返回空 data，让 UI 层 `AsyncValue.when(error:)` 显示错误。用户点击重试 → 发现未登录 → 手动登出。

- [ ] **Step 9: 删除旧文件**

```bash
rm Mobile/mobile_app/lib/core/models/demo_role.dart
rm Mobile/mobile_app/lib/app/app_mode.dart
rm Mobile/mobile_app/lib/core/api/api_auth.dart
rm Mobile/mobile_app/lib/core/api/api_role.dart
```

- [ ] **Step 10: 全局修复 import**

搜索所有引用 `demo_role`、`DemoRole`、`app_mode`、`AppMode`、`appModeProvider` 的文件并逐一修复。

```bash
cd Mobile/mobile_app && grep -rl "demo_role\|DemoRole\|app_mode\|AppMode\|appModeProvider" lib/ | head -30
```

每个文件：
- `import demo_role.dart` → `import user_role.dart`
- `DemoRole.xxx` → `UserRole.xxx`
- `import app_mode.dart` → 删除
- `AppMode.xxx` 分支 → 仅保留 live 分支内容
- `appModeProvider` 引用 → 删除

- [ ] **Step 11: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: 可能仍有 ApiCache 引用错误，在后续 Task 中修复

- [ ] **Step 12: Commit**

```bash
git add -A Mobile/mobile_app/lib/
git commit -m "feat(flutter): rewrite auth — remove DemoRole/AppMode, add UserRole + phone/password login"
```

---

## Task 2a: 模型迁移 + 测试修复

> 在 Task 2 删除 DemoRole/AppMode 后、Task 4 异步化之前，必须处理 demo_models.dart 中的共享类型和 18 个失效测试。

**Files:**
- Modify: `lib/core/models/demo_models.dart` → 重命名为 `lib/core/models/core_models.dart`
- Modify: 所有 `import demo_models.dart` 的文件（24 个 lib/ + 3 个 test/）
- Delete: 18 个失效测试文件（或按类型重写）
- Create: 替换后的测试文件

- [ ] **Step 1: 重命名 `demo_models.dart` → `core_models.dart`**

```bash
cd Mobile/mobile_app
git mv lib/core/models/demo_models.dart lib/core/models/core_models.dart
```

然后全局替换 import：

```bash
find lib/ test/ -name "*.dart" -exec sed -i '' "s|smart_livestock_demo/core/models/demo_models|smart_livestock_demo/core/models/core_models|g" {} +
```

- [ ] **Step 2: 验证重命名后编译通过**

Run: `flutter analyze`
Expected: No import errors for demo_models

- [ ] **Step 3: 删除直接依赖已删除类型的测试文件**

以下测试文件的核心测试对象（DemoRole/AppMode/ApiCache/MockRepository）已被删除，需直接删除：

```bash
rm test/api_auth_test.dart           # 测试 apiHeaders(DemoRole)
rm test/api_base_url_test.dart       # 测试 resolveApiBaseUrl + APP_MODE
rm test/api_cache_role_scope_test.dart # 测试 ApiCache role scoping
rm test/api_live_contract_test.dart  # 测试 ApiCache live 合同接口
rm test/app_mode_switch_test.dart    # 测试 AppMode mock↔live 切换
rm test/mock_repository_state_test.dart # 测试 MockRepository 状态
rm test/main_live_bootstrap_test.dart # 测试 main.dart live bootstrap (ApiCache.init)
rm test/seed_data_test.dart          # 测试 demo_seed 数据完整性
rm test/farm_switcher_controller_test.dart # 测试 FarmSwitcher._mockState
rm test/features/farm_switcher/farm_switcher_test.dart # 测试 mock farm switcher
rm test/features/fence/fence_live_conflict_feedback_test.dart # 测试 live ApiCache fence
rm test/features/fence/fence_page_mode_switch_test.dart # 测试 AppMode mock↔live
rm test/role_visibility_test.dart    # 测试 DemoRole 路由可见性
rm test/app_session_test.dart        # 测试 AppSession + DemoRole
rm test/features/b2b_admin/b2b_pages_test.dart # 测试 mock B2B
rm test/features/subscription/subscription_controller_test.dart # 测试 mock subscription
rm test/features/tenant/live_tenant_repository_test.dart # 测试 live ApiCache tenant
rm test/features/worker_management/worker_repository_test.dart # 测试 mock worker repo
```

- [ ] **Step 4: 验证测试可运行**

Run: `flutter test`
Expected: 所有剩余测试通过（部分测试可能需要修复 import，如 `live_devices_repository_test.dart` 和 `mock_repository_override_test.dart` 引用了 `demo_models`）

- [ ] **Step 5: 修复剩余受影响的测试**

检查 `test/live_devices_repository_test.dart` 和 `test/mock_repository_override_test.dart`：
- `demo_models` import 已在 Step 1 自动替换为 `core_models`
- 如有 `DemoRole`/`ApiCache` 引用则删除或更新

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor(flutter): rename demo_models → core_models, remove stale tests"
```

---

## Task 3: Farm Switcher 改造

**Files:**
- Modify: `lib/features/farm_switcher/farm_switcher_controller.dart`
- Modify: `lib/features/farm_switcher/farm_switcher_widget.dart`

- [ ] **Step 1: 重写 `farm_switcher_controller.dart`**

```dart
// lib/features/farm_switcher/farm_switcher_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';

class FarmInfo {
  const FarmInfo({required this.id, required this.name, required this.status});
  final String id;
  final String name;
  final String status;
}

class FarmSwitcherState {
  const FarmSwitcherState({
    required this.farms,
    this.activeFarmId,
    this.isLoading = false,
    this.error,
  });
  const FarmSwitcherState.empty()
      : farms = const [],
        activeFarmId = null,
        isLoading = false,
        error = null;

  final List<FarmInfo> farms;
  final String? activeFarmId;
  final bool isLoading;
  final String? error;

  bool get hasMultipleFarms => farms.length > 1;
  bool get hasFarms => farms.isNotEmpty;
}

class FarmSwitcherController extends Notifier<FarmSwitcherState> {
  @override
  FarmSwitcherState build() {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const FarmSwitcherState.empty();
    // Farm loading is triggered by SessionController.login() calling loadFarms().
    // This build() only reads the current state — no side effects.
    return const FarmSwitcherState(isLoading: true);
  }

  /// Called by SessionController.login() after successful authentication.
  Future<void> loadFarms() async {
    state = const FarmSwitcherState(isLoading: true);
    try {
      final data = await ApiClient.instance.get('/farms');
      final items = data['items'] as List<dynamic>? ?? [];
      final farms = items.whereType<Map<String, dynamic>>().map((json) {
        final rawId = json['id'];
        return FarmInfo(
          id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
          name: json['name'] as String? ?? '',
          status: json['status'] as String? ?? 'active',
        );
      }).toList();

      if (farms.isEmpty) {
        state = const FarmSwitcherState.empty();
        return;
      }

      final session = ref.read(sessionControllerProvider);
      final activeFarmId = session.activeFarmId ?? farms.first.id;

      if (ApiClient.instance.activeFarmId == null) {
        ApiClient.instance.setActiveFarmId(activeFarmId);
      }

      state = FarmSwitcherState(farms: farms, activeFarmId: activeFarmId);
    } on AuthException {
      state = const FarmSwitcherState.empty();
    } catch (e) {
      state = const FarmSwitcherState(error: '加载牧场失败');
    }
  }

  void switchFarm(String farmId) {
    final exists = state.farms.any((farm) => farm.id == farmId);
    if (!exists) return;
    state = FarmSwitcherState(farms: state.farms, activeFarmId: farmId);
    ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
  }
}

final farmSwitcherControllerProvider =
    NotifierProvider<FarmSwitcherController, FarmSwitcherState>(
  FarmSwitcherController.new,
);
```

- [ ] **Step 2: 更新 `farm_switcher_widget.dart`**

移除 `AppMode.mock` 分支和 `DemoRole` 引用。widget 直接使用 `farmSwitcherControllerProvider`。

- [ ] **Step 3: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No errors in farm_switcher

- [ ] **Step 4: Commit**

```bash
git add Mobile/mobile_app/lib/features/farm_switcher/
git commit -m "feat(flutter): rewrite farm switcher — async loading, controller-managed activeFarmId"
```

---

## Task 4: Dashboard 异步化（示范模块）

> 此 Task 建立异步 repository + AsyncNotifier 的标准模式。后续模块遵循相同模式。

**Files:**
- Modify: `lib/features/dashboard/domain/dashboard_repository.dart`
- Create: `lib/features/dashboard/data/dashboard_api_repository.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_controller.dart`
- Modify: `lib/features/pages/dashboard_page.dart`
- Delete: `lib/features/dashboard/data/mock_dashboard_repository.dart`
- Delete: `lib/features/dashboard/data/live_dashboard_repository.dart`

- [ ] **Step 1: 改造 Repository 接口为异步**

```dart
// lib/features/dashboard/domain/dashboard_repository.dart

import 'package:smart_livestock_demo/core/models/demo_models.dart';

class DashboardViewData {
  const DashboardViewData({required this.metrics, this.message});
  final List<DashboardMetric> metrics;
  final String? message;
  static const empty = DashboardViewData(metrics: [], message: '暂无看板数据');
}

abstract class DashboardRepository {
  Future<DashboardViewData> load();
}
```

注意：移除 `ViewState` 参数（loading 状态由 `AsyncValue` 管理）。

- [ ] **Step 2: 创建异步 API Repository 实现**

```dart
// lib/features/dashboard/data/dashboard_api_repository.dart

import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

class DashboardApiRepository implements DashboardRepository {
  const DashboardApiRepository();

  @override
  Future<DashboardViewData> load() async {
    final data = await ApiClient.instance.farmGet('/dashboard/summary');

    final metricsRaw = data['metrics'];
    if (metricsRaw is List) {
      final metrics = metricsRaw.whereType<Map<String, dynamic>>().map((m) {
        final key = m['key'];
        return DashboardMetric(
          widgetKey: 'dashboard-metric-${key is int ? key : key ?? ''}',
          title: m['title'] as String? ?? '',
          value: m['value']?.toString() ?? '',
        );
      }).toList();
      return DashboardViewData(metrics: metrics);
    }

    // Flat Spring Boot format
    final entries = <String, String>{
      'livestockCount': '牲畜总数',
      'onlineDeviceCount': '在线设备',
      'activeAlertCount': '活跃告警',
      'fenceCount': '围栏数',
    };
    final metrics = <DashboardMetric>[];
    for (final e in entries.entries) {
      final raw = data[e.key];
      if (raw != null) {
        metrics.add(DashboardMetric(
          widgetKey: 'dashboard-metric-${e.key}',
          title: e.value,
          value: raw.toString(),
        ));
      }
    }
    final health = data['healthSummary'] as Map<String, dynamic>?;
    if (health != null) {
      for (final (key, label) in [('healthy', '健康'), ('warning', '关注'), ('critical', '异常')]) {
        final raw = health[key];
        if (raw != null) {
          metrics.add(DashboardMetric(
            widgetKey: 'dashboard-metric-health-$key',
            title: label,
            value: raw.toString(),
          ));
        }
      }
    }
    return DashboardViewData(metrics: metrics);
  }
}
```

- [ ] **Step 3: 改造 Controller 为 AsyncNotifier**

```dart
// lib/features/dashboard/presentation/dashboard_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/dashboard/data/dashboard_api_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (_) => const DashboardApiRepository(),
);

class DashboardController extends AsyncNotifier<DashboardViewData> {
  @override
  Future<DashboardViewData> build() async {
    return ref.read(dashboardRepositoryProvider).load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).load());
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardViewData>(DashboardController.new);
```

- [ ] **Step 4: 更新 Dashboard 页面 UI**

在 `dashboard_page.dart` 中替换原有同步数据读取为：

```dart
ref.watch(dashboardControllerProvider).when(
  data: (data) => _buildContent(data),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('加载失败: $e')),
);
```

- [ ] **Step 5: 删除旧实现**

```bash
rm Mobile/mobile_app/lib/features/dashboard/data/mock_dashboard_repository.dart
rm Mobile/mobile_app/lib/features/dashboard/data/live_dashboard_repository.dart
```

- [ ] **Step 6: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No errors in dashboard module

- [ ] **Step 7: Commit**

```bash
git add -A Mobile/mobile_app/lib/features/dashboard/
git commit -m "feat(flutter): async Dashboard repository — ApiClient, AsyncNotifier pattern"
```

---

## Task 5: Map 异步化

**Files:**
- Create: `lib/features/livestock/data/map_api_repository.dart`
- Modify: map 相关 domain/repository 接口
- Delete: map 相关 mock/live repository

- [ ] **Step 1: 改造 Map Repository 接口为异步**

```dart
// 新建或复用 livestock 模块中的 map domain

class MapAnimal {
  const MapAnimal({
    required this.id,
    this.livestockCode,
    this.lat,
    this.lng,
    this.healthStatus = 'healthy',
    this.alertCount = 0,
  });
  final String id;
  final String? livestockCode;
  final double? lat;
  final double? lng;
  final String healthStatus;
  final int alertCount;
}

class GpsPoint {
  const GpsPoint({this.lat, this.lng, this.timestamp});
  final double? lat;
  final double? lng;
  final String? timestamp;
}

class MapOverviewData {
  const MapOverviewData({required this.animals, this.fences, this.trajectories});
  final List<MapAnimal> animals;
  final List<MapFence>? fences;
  final List<GpsPoint>? trajectories;
}

abstract class MapRepository {
  Future<MapOverviewData> loadOverview();
  Future<List<GpsPoint>> loadLatestPositions();
  Future<List<GpsPoint>> loadTrajectory(String livestockId, {int hours = 24});
}
```

- [ ] **Step 2: 创建 MapApiRepository**

```dart
// lib/features/livestock/data/map_api_repository.dart

import 'package:smart_livestock_demo/core/api/api_client.dart';
// import map domain types

class MapApiRepository implements MapRepository {
  const MapApiRepository();

  @override
  Future<MapOverviewData> loadOverview() async {
    final data = await ApiClient.instance.farmGet('/map/overview');

    // Spring Boot returns { livestock: [...], fences: [...], alerts: [...] }
    final livestockRaw = data['livestock'] as List<dynamic>? ?? [];
    final animals = livestockRaw.whereType<Map<String, dynamic>>().map((m) {
      final rawId = m['id'];
      return MapAnimal(
        id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
        livestockCode: m['livestockCode'] ?? m['earTag'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        healthStatus: m['healthStatus'] as String? ?? 'healthy',
        alertCount: m['alertCount'] as int? ?? 0,
      );
    }).toList();

    final fencesRaw = data['fences'] as List<dynamic>? ?? [];
    // Parse fences using same logic as FenceApiRepository

    return MapOverviewData(animals: animals);
  }

  @override
  Future<List<GpsPoint>> loadLatestPositions() async {
    final data = await ApiClient.instance.farmGet('/gps-logs/latest');
    final items = data['items'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map((m) => GpsPoint(
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      timestamp: m['timestamp'] as String?,
    )).toList();
  }

  @override
  Future<List<GpsPoint>> loadTrajectory(String livestockId, {int hours = 24}) async {
    final data = await ApiClient.instance.farmGet('/livestock/$livestockId/gps-logs?hours=$hours');
    final items = data['items'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map((m) => GpsPoint(
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      timestamp: m['timestamp'] as String?,
    )).toList();
  }
}
```

- [ ] **Step 3: 更新 Map 页面 Controller + UI（AsyncValue 模式，同 Task 4）**

- [ ] **Step 4: 删除旧 mock/live map repository + 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`

- [ ] **Step 5: Commit**

```bash
git add -A Mobile/mobile_app/lib/features/ && git commit -m "feat(flutter): async Map repository — farm-scoped map overview"
```

---

## Task 6: Alerts 异步化

**Files:**
- Modify: `lib/features/alerts/domain/alerts_repository.dart`
- Create: `lib/features/alerts/data/alerts_api_repository.dart`
- Delete: mock + live alerts repository

- [ ] **Step 1: 改造 Alerts Repository 接口**

```dart
abstract class AlertsRepository {
  Future<AlertsListData> loadAlerts({int page = 1, int pageSize = 20, String? status});
  Future<AlertDetail> loadDetail(String alertId);
  Future<void> acknowledge(String alertId);
  Future<void> handle(String alertId);
  Future<void> archive(String alertId);
  Future<void> batchHandle(List<String> alertIds);
}
```

- [ ] **Step 2: 创建 AlertsApiRepository**

端点映射（对照 `AlertController`）：
- `farmGet('/alerts?page=$page&pageSize=$pageSize')` → loadAlerts
- `farmGet('/alerts/$alertId')` → loadDetail
- `farmPost('/alerts/$alertId/acknowledge')` → acknowledge
- `farmPost('/alerts/$alertId/handle')` → handle
- `farmPost('/alerts/$alertId/archive')` → archive
- `farmPost('/alerts/batch-handle', body: {'alertIds': alertIds})` → batchHandle

- [ ] **Step 3: 更新 Controller + UI (AsyncValue) + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Alerts repository — CRUD + state machine + pagination"
```

---

## Task 7: Fences 异步化

**Files:**
- Modify: `lib/features/fence/domain/fence_repository.dart`
- Create: `lib/features/fence/data/fence_api_repository.dart`
- Delete: mock + live fence repository

- [ ] **Step 1: 改造 Fence Repository 接口**

```dart
abstract class FenceRepository {
  Future<List<FenceItem>> loadAll();
  Future<FenceItem> loadDetail(String fenceId);
  Future<FenceItem> create(Map<String, dynamic> body);
  Future<FenceItem> update(String fenceId, Map<String, dynamic> body);
  Future<void> delete(String fenceId);
}
```

- [ ] **Step 2: 创建 FenceApiRepository**

端点映射（对照 `FenceController`）：
- `farmGet('/fences?pageSize=100')` → loadAll
- `farmGet('/fences/$fenceId')` → loadDetail
- `farmPost('/fences', body: body)` → create
- `farmPut('/fences/$fenceId', body: body)` → update
- `farmDelete('/fences/$fenceId')` → delete

注意：Spring Boot 返回 `vertices: [{lng, lat}]` 格式，需转换为前端 `coordinates: [[lng, lat]]` 格式（此转换逻辑可从现有 `ApiCache._normalizeFenceItem` 迁移过来）。

- [ ] **Step 3: 更新 Fence 页面 Controller + UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Fence repository — CRUD with farm scope"
```

---

## Task 8: Livestock 异步化

**Files:**
- Modify: `lib/features/livestock/domain/livestock_repository.dart`
- Create: `lib/features/livestock/data/livestock_api_repository.dart`
- Delete: mock + live livestock repository

- [ ] **Step 1: 改造接口**

```dart
abstract class LivestockRepository {
  Future<LivestockListData> loadAll({int page = 1, int pageSize = 20, String? status});
  Future<LivestockDetail> loadDetail(String id);
  Future<LivestockDetail> create(Map<String, dynamic> body);
  Future<LivestockDetail> update(String id, Map<String, dynamic> body);
  Future<void> delete(String id);
}
```

- [ ] **Step 2: 创建 LivestockApiRepository**

端点：`farmGet('/livestock?page=$page&pageSize=$pageSize')` 等。

- [ ] **Step 3: 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Livestock repository — CRUD with pagination"
```

---

## Task 9: Devices 异步化

**Files:**
- Modify: `lib/features/devices/domain/devices_repository.dart`
- Create: `lib/features/devices/data/devices_api_repository.dart`
- Delete: mock + live devices repository

- [ ] **Step 1: 改造接口**

```dart
abstract class DevicesRepository {
  Future<DevicesListData> loadDevices({int page = 1, int pageSize = 20});
  Future<DeviceDetail> loadDetail(String id);
  Future<DeviceDetail> create(Map<String, dynamic> body);
  Future<DeviceDetail> update(String id, Map<String, dynamic> body);
  Future<void> activate(String id);
  Future<void> decommission(String id);
  Future<List<DeviceLicense>> loadLicenses();
  Future<DeviceLicense> loadLicenseDetail(String id);
  Future<List<Installation>> loadInstallations();
  Future<List<GpsPoint>> loadLatestGps();
  Future<List<GpsPoint>> loadGpsHistory(String livestockId);
}
```

- [ ] **Step 2: 创建 DevicesApiRepository**

注意混合路径：
- 设备 CRUD：`farmGet('/devices')` 等
- License：`get('/device-licenses')`（租户级，无 farm scope）
- GPS：`farmGet('/gps-logs/latest')`、`farmGet('/livestock/$livestockId/gps-logs')`

- [ ] **Step 3: 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Devices repository — device + license + installation + GPS"
```

---

## Task 10: Subscription 异步化 + Feature Flag 迁移

**Files:**
- Modify: `lib/features/subscription/domain/subscription_repository.dart`
- Create: `lib/features/subscription/data/subscription_api_repository.dart`
- Modify: `lib/features/subscription/presentation/subscription_controller.dart`
- Modify: `lib/features/subscription/presentation/widgets/locked_overlay.dart`
- Modify: `lib/core/models/subscription_tier.dart`
- Delete: mock + live subscription repository
- Delete: `lib/core/data/apply_mock_shaping.dart`

- [ ] **Step 1: 改造 Subscription Repository 接口**

```dart
abstract class SubscriptionRepository {
  Future<SubscriptionStatus> loadCurrent();
  Future<List<SubscriptionPlan>> loadPlans();
  Future<SubscriptionStatus> checkout({required String tier, required int livestockCount});
  Future<SubscriptionStatus> changeTier(String tier);
  Future<void> cancel();
  Future<SubscriptionUsage> loadUsage();
}
```

- [ ] **Step 2: 创建 SubscriptionApiRepository**

端点映射（对照 `SubscriptionController`）：
- `get('/subscription')` → loadCurrent
- `get('/subscription/plans')` → loadPlans
- `post('/subscription/checkout', body: ...)` → checkout
- `put('/subscription/tier', body: {'tier': tier})` → changeTier
- `post('/subscription/cancel')` → cancel
- `get('/subscription/usage')` → loadUsage

- [ ] **Step 3: 迁移 Feature Flag — LockedOverlay 从后端配额判断**

更新 `LockedOverlay`：登录后调一次 `GET /subscription` 获取 tier，缓存在 `SubscriptionController` 中。`LockedOverlay` 读取 tier + usage 配额，检查对应 feature 是否可用。不可用 → 显示锁定提示 + 升级链接。

删除 `apply_mock_shaping.dart` 及所有 `shapeListItems` 调用。

- [ ] **Step 4: 删除旧文件 + 验证编译 + Commit**

```bash
git commit -m "feat(flutter): async Subscription repository + migrate feature flags to backend quotas"
```

---

## Task 11: Contract + Revenue 异步化

**Files:**
- Modify: `lib/features/contract_management/domain/contract_management_repository.dart`
- Create: `lib/features/contract_management/data/contract_api_repository.dart`
- Modify: `lib/features/revenue/domain/revenue_repository.dart`
- Create: `lib/features/revenue/data/revenue_api_repository.dart`
- Delete: mock + live contract/revenue repositories

- [ ] **Step 1: 改造 Contract Repository**

```dart
abstract class ContractRepository {
  // App 端（CommerceController）
  Future<ContractDetail> loadMyContract();
  Future<List<RevenuePeriod>> loadRevenuePeriods();
  Future<void> confirmRevenuePeriod(String periodId);

  // Admin 端（AdminContractController）
  Future<List<ContractSummary>> loadAllContracts();
  Future<ContractDetail> createContract(Map<String, dynamic> body);
  Future<ContractDetail> loadContractDetail(String id);
  Future<ContractDetail> updateDraft(String id, Map<String, dynamic> body);
  Future<ContractDetail> signContract(String id);
  Future<void> updateContractStatus(String id, String status);
}
```

端点映射：
- `get('/contracts/me')` → loadMyContract
- `get('/revenue/periods')` → loadRevenuePeriods
- `post('/revenue/periods/$periodId/confirm')` → confirmRevenuePeriod
- `get('/admin/contracts')` → loadAllContracts
- `post('/admin/contracts', body: body)` → createContract
- `get('/admin/contracts/$id')` → loadContractDetail
- `put('/admin/contracts/$id', body: body)` → updateDraft
- `post('/admin/contracts/$id/sign')` → signContract
- `put('/admin/contracts/$id/status', body: {'status': status})` → updateContractStatus

- [ ] **Step 2: 改造 Revenue Repository**

```dart
abstract class RevenueRepository {
  Future<List<RevenuePeriod>> loadAllPeriods();
  Future<RevenuePeriodDetail> loadPeriodDetail(String id);
  Future<void> triggerCalculation(String contractId);
  Future<void> confirmPeriod(String periodId);
  Future<void> recalculatePeriod(String periodId);
}
```

端点映射（`AdminRevenueController`）：
- `get('/admin/revenue/periods')` → loadAllPeriods
- `get('/admin/revenue/periods/$id')` → loadPeriodDetail
- `post('/admin/revenue/calculate', body: {'contractId': contractId})` → triggerCalculation
- `post('/admin/revenue/periods/$id/confirm')` → confirmPeriod
- `post('/admin/revenue/periods/$id/recalculate')` → recalculatePeriod

- [ ] **Step 3: 创建 API 实现 + 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Contract + Revenue repositories — commerce endpoints"
```

---

## Task 12: B2B Admin + Worker Management 异步化

**Files:**
- Modify: `lib/features/b2b_admin/` domain/data
- Modify: `lib/features/worker_management/domain/worker_repository.dart`
- Create: `lib/features/worker_management/data/worker_api_repository.dart`
- Delete: mock + live B2B/worker repositories

- [ ] **Step 1: 改造 B2B Repository**

```dart
abstract class B2bRepository {
  Future<B2bOverview> loadOverview(); // 复用 contracts/me + revenue/periods
  Future<List<FarmInfo>> loadFarms();
  Future<void> createFarm(Map<String, dynamic> body);
  Future<List<WorkerInfo>> loadWorkers(String farmId);
}
```

- [ ] **Step 2: 改造 Worker Repository**

```dart
abstract class WorkerRepository {
  Future<List<WorkerInfo>> loadMembers(String farmId);
  Future<WorkerInfo> addMember(String farmId, Map<String, dynamic> body);
  Future<void> removeMember(String farmId, String userId);
}
```

端点：
- `farmGet('/members')` → loadMembers
- `farmPost('/members', body: body)` → addMember
- `farmDelete('/members/$userId')` → removeMember

- [ ] **Step 3: 创建 API 实现 + 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async B2B Admin + Worker Management repositories"
```

---

## Task 13: Admin Subscription Management 异步化

**Files:**
- Modify: `lib/features/subscription_service_management/domain/`
- Create: `lib/features/subscription_service_management/data/subscription_service_api_repository.dart`
- Delete: mock + live subscription service repositories

- [ ] **Step 1: 改造接口**

```dart
abstract class SubscriptionServiceRepository {
  Future<List<SubscriptionSummary>> loadSubscriptions({String? status, String? tier, int page = 1, int pageSize = 20});
  Future<SubscriptionDetail> loadSubscriptionDetail(String id);
  Future<void> updateSubscriptionStatus(String id, String status);
  Future<List<ServiceInfo>> loadServices();
  Future<ServiceInfo> createService(Map<String, dynamic> body);
  Future<ServiceInfo> loadServiceDetail(String id);
  Future<void> updateServiceStatus(String id, String status);
  Future<void> updateServiceQuota(String id, Map<String, dynamic> quota);
}
```

端点映射（`AdminSubscriptionController` + `AdminServiceController`）：
- `get('/admin/subscriptions')` → loadSubscriptions
- `get('/admin/subscriptions/$id')` → loadSubscriptionDetail
- `put('/admin/subscriptions/$id/status', body: {'status': status})` → updateSubscriptionStatus
- `get('/admin/subscription-services')` → loadServices
- `post('/admin/subscription-services', body: body)` → createService
- `get('/admin/subscription-services/$id')` → loadServiceDetail
- `put('/admin/subscription-services/$id/status', body: {'status': status})` → updateServiceStatus
- `put('/admin/subscription-services/$id/quota', body: quota)` → updateServiceQuota

- [ ] **Step 2: 创建 API 实现 + 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Admin Subscription Management — 8 admin endpoints"
```

---

## Task 14: Admin 后台 + API Key

**Files:**
- Modify: `lib/features/admin/domain/admin_repository.dart`
- Create: `lib/features/admin/data/admin_api_repository.dart`
- Delete: mock + live admin repositories

- [ ] **Step 1: 改造 Admin Repository**

```dart
abstract class AdminRepository {
  // Tenants
  Future<List<TenantSummary>> loadTenants({int page = 1, int pageSize = 20});
  Future<TenantDetail> loadTenantDetail(String tenantId);
  Future<TenantDetail> createTenant(Map<String, dynamic> body);
  Future<void> updateTenantStatus(String tenantId, String status);

  // Users
  Future<List<UserSummary>> loadUsers({int page = 1, int pageSize = 20});
  Future<UserDetail> loadUserDetail(String userId);
  Future<UserDetail> createUser(Map<String, dynamic> body);
  Future<void> resetPassword(String userId, String newPassword);

  // Farms
  Future<List<FarmSummary>> loadFarms({int page = 1, int pageSize = 20});
  Future<FarmDetail> loadFarmDetail(String farmId);

  // API Keys
  Future<List<ApiKeyInfo>> loadApiKeys();
  Future<ApiKeyCreateResult> createApiKey(Map<String, dynamic> body);
  Future<void> updateApiKeyStatus(String keyId, String status);
  Future<void> revokeApiKey(String keyId);
}

class ApiKeyCreateResult {
  const ApiKeyCreateResult({required this.info, required this.fullKey});
  final ApiKeyInfo info;
  final String fullKey;
}
```

端点映射：
- `get('/admin/tenants')` → loadTenants
- `get('/admin/tenants/$id')` → loadTenantDetail
- `post('/admin/tenants', body: body)` → createTenant
- `put('/admin/tenants/$id/status', body: {'status': status})` → updateTenantStatus
- `get('/admin/users')` → loadUsers
- `get('/admin/users/$id')` → loadUserDetail
- `post('/admin/users', body: body)` → createUser
- `post('/admin/users/$id/reset-password', body: {'newPassword': newPassword})` → resetPassword
- `get('/admin/farms')` → loadFarms
- `get('/admin/farms/$id')` → loadFarmDetail
- `get('/admin/api-keys')` → loadApiKeys
- `post('/admin/api-keys', body: body)` → createApiKey
- `put('/admin/api-keys/$id/status', body: {'status': status})` → updateApiKeyStatus
- `delete('/admin/api-keys/$id')` → revokeApiKey

- [ ] **Step 2: 创建 AdminApiRepository**

注意所有端点前缀为 `/admin/`（非 farm-scoped）。

- [ ] **Step 3: API Key 创建弹窗**

创建 Key 成功后显示完整 key 的弹窗，提示"仅此一次显示"。

- [ ] **Step 4: 更新 Admin UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Admin repository — tenant/user/farm + API Key management"
```

---

## Task 15: Profile/Me + Farm Creation

**Files:**
- Modify: `lib/features/mine/domain/mine_repository.dart`
- Create: `lib/features/mine/data/mine_api_repository.dart`
- Modify: `lib/features/farm_creation/` — 向导适配
- Delete: mock + live mine repositories

- [ ] **Step 1: 改造 Mine Repository**

```dart
abstract class MineRepository {
  Future<UserProfile> loadProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> body);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<TenantInfo> loadTenantInfo();
}
```

端点：`get('/me')`、`put('/me')`、`put('/me/password')`、`get('/tenants/me')`

- [ ] **Step 2: 改造 Farm Creation**

3 步向导适配 `POST /farms`。创建成功后自动设为 activeFarmId 并跳转 dashboard：

```dart
Future<String> createFarm({
  required String name,
  required double latitude,
  required double longitude,
  required double areaHectares,
}) async {
  final data = await ApiClient.instance.post('/farms', body: {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'areaHectares': areaHectares,
  });
  final rawId = data['id'];
  final farmId = rawId is int ? rawId.toString() : (rawId as String);
  ApiClient.instance.setActiveFarmId(farmId);
  return farmId;
}
```

- [ ] **Step 3: 更新 UI + 删除旧文件 + 验证 + Commit**

```bash
git commit -m "feat(flutter): async Profile/Me + Farm Creation — POST /farms wizard"
```

---

## Task 16: 种子数据迁移

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V9__seed_ranch_data.sql`
- Create: `smart-livestock-server/src/main/resources/db/migration/V10__seed_iot_data.sql`
- Create: `smart-livestock-server/src/main/resources/db/migration/V11__seed_commerce_data.sql`
- Create: `smart-livestock-server/src/main/resources/db/migration/V12__seed_twin_data.sql`

- [ ] **Step 1: 创建 V9 — Ranch 种子数据**

从 Mock Server `seed.js` + `fenceStore.js` 提取 demo 数据，生成 SQL INSERT 语句。

数据来源：`Mobile/backend/data/seed.js` 和 `Mobile/backend/data/fenceStore.js`

```sql
-- V9__seed_ranch_data.sql
-- 注意：不指定 id，让 PostgreSQL sequence 自动生成，避免与 V4 种子数据（id 1~5）冲突。
-- 牲畜（tenant_id=1, farm_id=1）
INSERT INTO livestock (tenant_id, farm_id, livestock_code, ear_tag, breed, gender, birth_date, weight, health_status, status, created_at)
VALUES
  (1, 1, 'LS001', 'ET001', '安格斯', 'MALE', '2024-03-15', 450.0, 'healthy', 'active', NOW()),
  ...
;
-- 围栏
INSERT INTO fences (tenant_id, farm_id, name, fence_type, status, color, created_at)
VALUES
  (1, 1, '主牧场围栏', 'polygon', 'active', '#FF0000', NOW()),
  ...
;
-- 告警（livestock_id/fence_id 使用子查询获取，不硬编码）
INSERT INTO alerts (tenant_id, farm_id, type, severity, status, message, livestock_id, fence_id, created_at)
SELECT 1, 1, 'FENCE_BREACH', 'warning', 'pending', '牲畜 LS001 离开围栏', l.id, f.id, NOW()
FROM livestock l JOIN fences f ON f.farm_id = 1
WHERE l.livestock_code = 'LS001' AND f.name = '主牧场围栏'
LIMIT 1;
```

- [ ] **Step 2: 创建 V10 — IoT 种子数据**

设备、DeviceLicense、Installation、GPS 日志。

- [ ] **Step 3: 创建 V11 — Commerce 种子数据**

为 tenant_id=1 创建 basic tier 订阅 + 合同 + 分润周期。

- [ ] **Step 4: 创建 V12 — Twin 概览种子数据**

牧区统计摘要、场景配置。

- [ ] **Step 5: 本地验证迁移**

Run: `cd smart-livestock-server && docker compose down -v && docker compose up -d postgres && sleep 3 && docker compose up -d app`
Expected: 所有 V1-V12 迁移成功执行

- [ ] **Step 6: 验证种子数据**

用 `13800138000` / `password123` 登录，确认 Dashboard/Map/Fences 数据正常。

- [ ] **Step 7: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V9__seed_ranch_data.sql smart-livestock-server/src/main/resources/db/migration/V10__seed_iot_data.sql smart-livestock-server/src/main/resources/db/migration/V11__seed_commerce_data.sql smart-livestock-server/src/main/resources/db/migration/V12__seed_twin_data.sql
git commit -m "feat(server): add seed data migrations V9-V12 — ranch, IoT, commerce, twin"
```

---

## Task 17: 清理 — 删除所有 Mock 代码

**Files:**
- Delete: `Mobile/backend/` 整个目录
- Delete: 所有剩余的 `*_mock_repository.dart`
- Delete: 所有 `*_live_repository.dart`
- Delete: `lib/core/data/demo_seed.dart`
- Delete: `lib/core/data/twin_seed.dart`
- Delete: `lib/core/data/twin_series_downsample.dart`
- Delete: `lib/core/data/generators/`
- Delete: `lib/core/mock/`
- Delete: `lib/core/api/api_cache.dart`
- Delete: `lib/core/models/demo_models.dart`
- Delete: `Mobile/dev.sh`

- [ ] **Step 1: 查找所有待删除文件**

```bash
find Mobile/mobile_app/lib -name "*mock*" -o -name "*live_*" -o -name "demo_seed*" -o -name "twin_seed*" -o -name "apply_mock*" | sort
find Mobile/mobile_app/lib/core/data/generators -type f
find Mobile/mobile_app/lib/core/mock -type f
```

- [ ] **Step 2: 逐一删除文件**

确认所有 import 已在前面的 Task 中清理。

- [ ] **Step 3: 删除 Mock Server**

```bash
rm -rf Mobile/backend/
```

- [ ] **Step 4: 验证编译通过**

Run: `cd Mobile/mobile_app && flutter analyze`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore(flutter): delete all mock infrastructure — Mock Server, mock repos, ApiCache, demo seed"
```

---

## Task 18: 未实现模块占位 + 文档更新

**Files:**
- Create: `lib/widgets/coming_soon_page.dart`
- Modify: `lib/features/fever_warning/presentation/` — 占位
- Modify: `lib/features/digestive/presentation/` — 占位
- Modify: `lib/features/estrus/presentation/` — 占位
- Modify: `lib/features/epidemic/presentation/` — 占位
- Modify: `lib/features/stats/presentation/` — 占位
- Modify: `lib/features/twin_overview/presentation/` — 占位
- Modify: `lib/features/api_authorization/presentation/` — 占位
- Modify: `docs/api-contracts/api-overview.md` — 更新 §5

- [ ] **Step 1: 创建通用占位组件**

```dart
// lib/widgets/coming_soon_page.dart

import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.info),
            const SizedBox(height: AppSpacing.lg),
            Text('功能开发中，敬请期待', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 为每个未实现模块替换页面内容**

将 fever_warning、digestive、estrus、epidemic、stats、twin_overview、api_authorization 的页面替换为 `ComingSoonPage(title: '模块名')`。保留路由和导航入口。

- [ ] **Step 3: 更新 `api-overview.md` §5 路由模式**

将 `/{farmId}/dashboard` 路由模式更新为控制器管理模式：路由不加 farmId 前缀，`FarmController` 持 `activeFarmId`，API 路径自动注入。

- [ ] **Step 4: 验证编译 + Commit**

```bash
git commit -m "feat(flutter): placeholder pages for Health/Analytics/API Portal + update api-overview routing"
```

---

## 依赖关系图

```
Task 1 (ApiClient) ──→ Task 2 (Auth + Remove Mock) ──→ Task 2a (模型迁移+测试修复)
         │                                                     │
         └─────────────────────────────────────────────────────→ Task 3 (Farm Switcher)
                                                                    │
          Task 4 (Dashboard 示范) ←─────────────────────────────────┘
                ↓
          Task 5-9 (Map/Alerts/Fences/Livestock/Devices)
                ↓
          Task 10 (Subscription + Feature Flags)
                ↓
          Task 11-13 (Contract/Revenue/B2B/Worker/Admin Subscription)
                ↓
          Task 14-15 (Admin + Profile/Farm Creation)
                ↓
          Task 16 (种子数据) ←── 可与前端 Task 并行
                ↓
          Task 17 (删除 Mock) → Task 18 (占位 + 文档)
```

**可并行路径：**
- Task 1 → 2 → 2a → 3 必须顺序执行（基础设施 + 测试修复）
- Task 4-9 可在 Task 3 完成后并行（每个模块独立 PR）
- Task 10-13 依赖 Task 4 模式（遵循相同的异步 repository 模式）
- Task 16（种子数据）可与前端 Task 并行（纯后端 SQL）
- Task 17-18 必须在所有其他 Task 之后执行
