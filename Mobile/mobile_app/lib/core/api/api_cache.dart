import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

const String _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String resolveApiBaseUrl() {
  if (_apiBaseUrlFromEnv.isNotEmpty) {
    return _apiBaseUrlFromEnv;
  }
  return kIsWeb
      ? 'http://127.0.0.1:3001/api/v1'
      : 'http://localhost:3001/api/v1';
}

Map<String, String> _headers(
  String role, {
  ApiAuthTokens? tokens,
  bool allowMockTokenFallback = false,
  Map<String, ApiAuthTokens> roleTokens = const {},
}) {
  final demoRole = demoRoleFromWireName(role);
  return apiHeaders(
    role: demoRole,
    tokens: tokens ?? roleTokens[role],
    allowMockTokenFallback: allowMockTokenFallback,
  );
}

String fenceSaveErrorMessageForStatusCode(int? statusCode) {
  switch (statusCode) {
    case 409:
      return '围栏已被其他人更新，请刷新后重试';
    case 422:
      return '数据校验失败，请检查后重试';
    default:
      return '保存失败，请稍后重试';
  }
}

class FenceSaveResult {
  const FenceSaveResult({required this.ok, this.statusCode});

  final bool ok;
  final int? statusCode;
}

class TenantWriteResult {
  const TenantWriteResult({
    required this.ok,
    this.tenant,
    this.errorCode,
    this.statusCode,
    this.message,
  });
  final bool ok;
  final Map<String, dynamic>? tenant;
  final String? errorCode;
  final int? statusCode;
  final String? message;
}

class AuthResult {
  const AuthResult({required this.accessToken, required this.user});
  final String accessToken;
  final Map<String, dynamic> user;
}

class ApiCache {
  ApiCache._();
  static final ApiCache instance = ApiCache._();

  bool _initialized = false;
  bool get initialized => _initialized;

  String? _activeFarmId;
  String? get activeFarmId => _activeFarmId;
  set activeFarmId(String? id) => _activeFarmId = id;

  Future<Map<String, dynamic>?> fetchFarms(String role, {ApiAuthTokens? tokens}) async {
    final headers = _headers(role, tokens: tokens, roleTokens: _roleTokens);
    return await _get('/farms', headers);
  }

  bool hasRoleData(String role) {
    if (!_initialized) return false;
    if (role == 'b2b_admin') return _b2bDashboard != null;
    return true;
  }
  String? _lastLiveSource;
  String? get lastLiveSource => _lastLiveSource;
  ApiHttpClient _httpClient = const DefaultApiHttpClient();
  final Map<String, ApiAuthTokens> _roleTokens = {};
  int _initGeneration = 0;

  List<Map<String, dynamic>> _dashboardMetrics = [];
  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _mapTrajectoryPoints = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _fences = [];
  List<Map<String, dynamic>> _tenants = [];
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? _twinOverview;
  List<Map<String, dynamic>> _feverList = [];
  List<Map<String, dynamic>> _digestiveList = [];
  List<Map<String, dynamic>> _estrusList = [];
  Map<String, dynamic>? _epidemicSummary;
  List<Map<String, dynamic>> _epidemicContacts = [];
  List<Map<String, dynamic>> _devices = [];

  final Map<String, List<DeviceItem>> _tenantDevicesCache = {};
  final Map<String, List<TenantLogEntry>> _tenantLogsCache = {};
  final Map<String, Map<String, dynamic>> _tenantStatsCache = {};
  Map<String, Map<String, dynamic>>? _tenantTrends;

  Map<String, dynamic>? _subscriptionCurrent;
  List<Map<String, dynamic>>? _subscriptionPlans;
  Map<String, dynamic>? _subscriptionFeatures;
  Map<String, dynamic>? _subscriptionUsage;
  Map<String, dynamic>? _myFarms;
  Map<String, dynamic>? _workers;
  String? _workersFarmId;
  Map<String, dynamic>? _b2bDashboard;
  Map<String, dynamic>? _b2bContract;

  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _revenue = [];
  List<Map<String, dynamic>> _subscriptionServices = [];
  List<Map<String, dynamic>> _apiKeys = [];
  List<Map<String, dynamic>> _apiAuthorizations = [];

  List<Map<String, dynamic>> get dashboardMetrics => _dashboardMetrics;
  List<Map<String, dynamic>> get animals => _animals;
  List<Map<String, dynamic>> get mapTrajectoryPoints => _mapTrajectoryPoints;
  List<Map<String, dynamic>> get alerts => _alerts;
  List<Map<String, dynamic>> get fences => _fences;
  List<Map<String, dynamic>> get tenants => _tenants;
  Map<String, dynamic>? get profile => _profile;

  Map<String, dynamic>? get twinOverview => _twinOverview;
  List<Map<String, dynamic>> get feverList => _feverList;
  List<Map<String, dynamic>> get digestiveList => _digestiveList;
  List<Map<String, dynamic>> get estrusList => _estrusList;
  Map<String, dynamic>? get epidemicSummary => _epidemicSummary;
  List<Map<String, dynamic>> get epidemicContacts => _epidemicContacts;
  List<Map<String, dynamic>> get devices => _devices;

  List<DeviceItem>? tenantDevices(String tenantId) =>
      _tenantDevicesCache[tenantId];
  List<TenantLogEntry>? tenantLogs(String tenantId) =>
      _tenantLogsCache[tenantId];
  Map<String, dynamic>? tenantStats(String tenantId) =>
      _tenantStatsCache[tenantId];
  Map<String, Map<String, dynamic>>? get tenantTrends => _tenantTrends;

  Map<String, dynamic>? get subscriptionCurrent => _subscriptionCurrent;
  List<Map<String, dynamic>>? get subscriptionPlans => _subscriptionPlans;
  Map<String, dynamic>? get subscriptionFeatures => _subscriptionFeatures;
  Map<String, dynamic>? get subscriptionUsage => _subscriptionUsage;
  Map<String, dynamic>? get myFarms => _myFarms;
  Map<String, dynamic>? get workers => _workers;
  String? get workersFarmId => _workersFarmId;
  Map<String, dynamic>? get b2bDashboard => _b2bDashboard;
  Map<String, dynamic>? get b2bContract => _b2bContract;

  List<Map<String, dynamic>> get contracts => _contracts;
  List<Map<String, dynamic>> get revenue => _revenue;
  List<Map<String, dynamic>> get subscriptionServices => _subscriptionServices;
  List<Map<String, dynamic>> get apiKeys => _apiKeys;
  List<Map<String, dynamic>> get apiAuthorizations => _apiAuthorizations;

  /// Updates the cached subscription state (used by LiveSubscriptionRepository after writes).
  void updateSubscriptionCurrent(Map<String, dynamic>? value) {
    _subscriptionCurrent = value;
  }

  bool addWorkerAssignment({
    required String farmId,
    required String id,
    required String userId,
    required String userName,
    required String role,
    required String assignedAt,
  }) {
    final current = _workers;
    final rawItems = current?['items'];
    if (!_canMutateWorkers(farmId) || current == null || rawItems is! List) {
      return false;
    }
    final duplicate = rawItems.whereType<Map<String, dynamic>>().any(
          (item) => item['userId'] == userId,
        );
    if (duplicate) return false;

    final items = List<dynamic>.from(rawItems)
      ..add({
        'id': id,
        'userId': userId,
        'userName': userName,
        'role': role,
        'assignedAt': assignedAt,
      });
    _workers = _withWorkerItems(current, items);
    return true;
  }

  bool removeWorkerAssignment(String assignmentId) {
    final current = _workers;
    final rawItems = current?['items'];
    if (!_hasWorkersCache || current == null || rawItems is! List) {
      return false;
    }
    final items = List<dynamic>.from(rawItems);
    final before = items.length;
    items.removeWhere((item) => item is Map && item['id'] == assignmentId);
    if (items.length == before) return false;

    _workers = _withWorkerItems(current, items);
    return true;
  }

  bool _canMutateWorkers(String farmId) {
    return _hasWorkersCache && _workersFarmId == farmId;
  }

  bool get _hasWorkersCache {
    return _initialized && _lastLiveSource == 'api' && _workers != null;
  }

  Map<String, dynamic> _withWorkerItems(
    Map<String, dynamic> current,
    List<dynamic> items,
  ) {
    final updated = Map<String, dynamic>.from(current);
    updated['items'] = items;
    updated['total'] = items.length;
    return updated;
  }

  Future<bool> checkoutSubscriptionRemote(
    String role, {
    required String tier,
    required int livestockCount,
    String? idempotencyKey,
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final body = <String, dynamic>{
      'tier': tier,
      'livestockCount': livestockCount,
    };
    if (idempotencyKey != null) body['idempotencyKey'] = idempotencyKey;

    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/subscription/checkout'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['code'] == 'OK') {
        _subscriptionCurrent = decoded['data'] as Map<String, dynamic>?;
        return true;
      }
    }
    return false;
  }

  Future<bool> cancelSubscriptionRemote(
    String role, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/subscription/cancel'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['code'] == 'OK') {
        _subscriptionCurrent = decoded['data'] as Map<String, dynamic>?;
        return true;
      }
    }
    return false;
  }

  Future<bool> renewSubscriptionRemote(
    String role, {
    required int livestockCount,
    String? idempotencyKey,
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final body = <String, dynamic>{'livestockCount': livestockCount};
    if (idempotencyKey != null) body['idempotencyKey'] = idempotencyKey;

    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/subscription/renew'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['code'] == 'OK') {
        _subscriptionCurrent = decoded['data'] as Map<String, dynamic>?;
        return true;
      }
    }
    return false;
  }

  Future<void> fetchTenantDevices(
    String role,
    String tenantId, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    final data = await _get('/admin/tenants/$tenantId/devices', headers);
    if (data != null && data['items'] is List) {
      _tenantDevicesCache[tenantId] = (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_parseDeviceItem)
          .whereType<DeviceItem>()
          .toList();
    }
  }

  Future<void> fetchTenantLogs(
    String role,
    String tenantId, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    final data = await _get('/admin/tenants/$tenantId/logs', headers);
    if (data != null && data['items'] is List) {
      _tenantLogsCache[tenantId] = (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_parseTenantLogEntry)
          .whereType<TenantLogEntry>()
          .toList();
    }
  }

  Future<void> fetchTenantStats(
    String role,
    String tenantId, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    final data = await _get('/admin/tenants/$tenantId/stats', headers);
    if (data != null) {
      _tenantStatsCache[tenantId] = data;
    }
  }

  DeviceItem? _parseDeviceItem(Map<String, dynamic> json) {
    try {
      final rawId = json['id'];
      final typeStr = json['type'] as String? ?? '';
      final statusStr = json['status'] as String? ?? '';
      final type = switch (typeStr) {
        'gps' => DeviceType.gps,
        'rumenCapsule' => DeviceType.rumenCapsule,
        _ => DeviceType.accelerometer,
      };
      final status = switch (statusStr) {
        'online' => DeviceStatus.online,
        'offline' => DeviceStatus.offline,
        _ => DeviceStatus.lowBattery,
      };
      return DeviceItem(
        id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
        name: json['name'] as String? ?? '',
        type: type,
        status: status,
        boundEarTag: json['boundEarTag'] as String? ?? '',
        batteryPercent: json['batteryPercent'] as int?,
        signalStrength: json['signalStrength'] as String?,
        lastSync: json['lastSync'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  TenantLogEntry? _parseTenantLogEntry(Map<String, dynamic> json) {
    try {
      final rawId = json['id'];
      return TenantLogEntry(
        id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
        action: json['action'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        operator: json['operator'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

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
    return AuthResult(accessToken: token, user: user);
  }

  Future<ApiAuthTokens?> authenticateRole(String role) async {
    final tokens = await _authenticateRole(role);
    if (tokens != null) {
      _roleTokens[role] = tokens;
    }
    return tokens;
  }

  Future<ApiAuthTokens?> _authenticateRole(String role) async {
    final response = await _httpClient.post(
      Uri.parse('${resolveApiBaseUrl()}/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode != 200) {
      return null;
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 'OK') {
      return null;
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final accessToken = data['accessToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      return null;
    }
    final expiresAtRaw = data['expiresAt'];
    final tokens = ApiAuthTokens(
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
      expiresAt:
          expiresAtRaw is String ? DateTime.tryParse(expiresAtRaw) : null,
    );
    return tokens;
  }

  Future<void> initWithRoleAuth(String role) async {
    final generation = _startInitGeneration();
    try {
      final tokens = await _authenticateRole(role);
      if (!_isCurrentGeneration(generation)) return;
      if (tokens == null) {
        _clearLiveData();
        debugPrint('ApiCache auth failed for role: $role');
        return;
      }
      _roleTokens[role] = tokens;
      await _initForGeneration(role, generation, tokens: tokens);
    } catch (e) {
      if (_isCurrentGeneration(generation)) {
        _clearLiveData();
      }
      debugPrint('ApiCache auth failed for role: $role, $e');
    }
  }

  Future<void> init(
    String role, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final generation = _startInitGeneration();
    await _initForGeneration(
      role,
      generation,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
    );
  }

  Future<void> _initForGeneration(
    String role,
    int generation, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    _clearLiveData();
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    Future<Map<String, dynamic>?> initGet(String path) =>
        _get(path, headers, markLiveSource: false);

    try {
      final farmId = _activeFarmId;
      final hasFarmScope = farmId != null && farmId.isNotEmpty;

      // Phase 1 farm-scoped endpoints (skip if no active farm — e.g. platform_admin)
      List<Map<String, dynamic>?> farmScopedResults = [];
      if (hasFarmScope) {
        farmScopedResults = await Future.wait([
          initGet('/farms/$farmId/dashboard'),
          initGet('/farms/$farmId/map'),
          initGet('/farms/$farmId/alerts?pageSize=100'),
          initGet('/farms/$farmId/fences?pageSize=100'),
        ]);
      }

      // Non-farm-scoped endpoints (always loaded)
      final globalResults = await Future.wait([
        initGet('/admin/tenants?pageSize=100'),
        initGet('/me'),
        initGet('/twin/overview'),
        initGet('/twin/fever/list'),
        initGet('/twin/digestive/list'),
        initGet('/twin/estrus/list'),
        initGet('/twin/epidemic/summary'),
        initGet('/twin/epidemic/contacts'),
        initGet('/devices?pageSize=200'),
        initGet('/subscription/current'),
        initGet('/subscription/features'),
        initGet('/subscription/plans'),
        initGet('/subscription/usage'),
      ]);

      if (!_isCurrentGeneration(generation)) return;

      // Check if anything loaded at all
      final allResults = [...farmScopedResults, ...globalResults];
      if (allResults.every((data) => data == null)) {
        _initialized = false;
        _lastLiveSource = null;
        _tenantTrends = null;
        return;
      }
      _lastLiveSource = 'api';

      // Farm-scoped: [0]=dashboard, [1]=map, [2]=alerts, [3]=fences
      if (hasFarmScope && farmScopedResults.isNotEmpty) {
        final dashData = farmScopedResults[0];
        if (dashData != null) {
          final metricsRaw = dashData['metrics'];
          if (metricsRaw is List) {
            _dashboardMetrics =
                List<Map<String, dynamic>>.from(metricsRaw);
          } else {
            _dashboardMetrics = _normalizeDashboardMetrics(dashData);
          }
        }

        final mapData = farmScopedResults[1];
        if (mapData != null) {
          final animalsRaw = mapData['animals'];
          if (animalsRaw is List) {
            _animals = List<Map<String, dynamic>>.from(animalsRaw);
            _mapTrajectoryPoints =
                List<Map<String, dynamic>>.from(mapData['points'] ?? []);
          } else {
            _animals = _normalizeMapAnimals(mapData);
            _mapTrajectoryPoints = <Map<String, dynamic>>[];
          }
        }

        final alertsData = farmScopedResults[2];
        if (alertsData != null) {
          final items = alertsData['items'] is List
              ? List<Map<String, dynamic>>.from(alertsData['items'] ?? [])
              : <Map<String, dynamic>>[];
          _alerts = items.map(_normalizeAlertItem).toList();
        }

        final fencesData = farmScopedResults[3];
        if (fencesData != null) {
          final items = fencesData['items'] is List
              ? List<Map<String, dynamic>>.from(fencesData['items'] ?? [])
              : <Map<String, dynamic>>[];
          _fences = items.map(_normalizeFenceItem).toList();
        }
      }

      // Global: [0]=tenants, [1]=me, [2]=twin/overview, [3]=fever, [4]=digestive,
      //         [5]=estrus, [6]=epidemic/summary, [7]=epidemic/contacts,
      //         [8]=devices, [9]=subscription/current, [10]=subscription/features,
      //         [11]=subscription/plans, [12]=subscription/usage
      final tenantsData = globalResults[0];
      if (tenantsData != null) {
        _tenants = List<Map<String, dynamic>>.from(tenantsData['items'] ?? []);
      }

      _profile = _normalizeProfile(globalResults[1]);

      _twinOverview = globalResults[2];

      final feverData = globalResults[3];
      if (feverData != null) {
        _feverList = List<Map<String, dynamic>>.from(feverData['items'] ?? []);
      }

      final digestiveData = globalResults[4];
      if (digestiveData != null) {
        _digestiveList =
            List<Map<String, dynamic>>.from(digestiveData['items'] ?? []);
      }

      final estrusData = globalResults[5];
      if (estrusData != null) {
        _estrusList =
            List<Map<String, dynamic>>.from(estrusData['items'] ?? []);
      }

      _epidemicSummary = globalResults[6];

      final contactsData = globalResults[7];
      if (contactsData != null) {
        _epidemicContacts =
            List<Map<String, dynamic>>.from(contactsData['items'] ?? []);
      }

      final devicesData = globalResults[8];
      if (devicesData != null) {
        final items = devicesData['items'] is List
            ? List<Map<String, dynamic>>.from(devicesData['items'] ?? [])
            : <Map<String, dynamic>>[];
        _devices = items.map(_normalizeDeviceItem).toList();
      }

      _subscriptionCurrent = globalResults[9];
      _subscriptionFeatures = globalResults[10];

      final plansData = globalResults[11];
      if (plansData != null) {
        _subscriptionPlans =
            List<Map<String, dynamic>>.from(plansData['items'] ?? []);
      }

      _subscriptionUsage = globalResults[12];

      if (role == DemoRole.owner.wireName || role == DemoRole.worker.wireName) {
        final myFarms = await initGet('/farms');
        if (!_isCurrentGeneration(generation)) return;
        _myFarms = myFarms;
        final activeFarmId = myFarms?['activeFarmId'];
        if (role == DemoRole.owner.wireName &&
            activeFarmId is String &&
            activeFarmId.isNotEmpty) {
          final workers = await initGet('/farms/$activeFarmId/members');
          if (!_isCurrentGeneration(generation)) return;
          _workers = workers;
          _workersFarmId = workers == null ? null : activeFarmId;
        }
      }

      if (role == DemoRole.b2bAdmin.wireName) {
        final b2bDashboard = await initGet('/b2b/dashboard');
        if (!_isCurrentGeneration(generation)) return;
        final b2bContract = await initGet('/b2b/contract/current');
        if (!_isCurrentGeneration(generation)) return;
        _b2bDashboard = b2bDashboard;
        _b2bContract = b2bContract;

        final revenueData = await initGet('/revenue/periods');
        if (!_isCurrentGeneration(generation)) return;
        if (revenueData != null) {
          _revenue = List<Map<String, dynamic>>.from(
            revenueData['items'] ?? [],
          );
        }
      }

      _initialized = true;
    } catch (e) {
      if (_isCurrentGeneration(generation)) {
        _clearLiveData();
      }
      debugPrint('ApiCache init failed: $e');
    }
  }

  int _startInitGeneration() {
    _initGeneration += 1;
    return _initGeneration;
  }

  bool _isCurrentGeneration(int generation) => generation == _initGeneration;

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> headers,
    {
    bool markLiveSource = true,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('${resolveApiBaseUrl()}$path'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] == 'OK') {
        if (markLiveSource) {
          _lastLiveSource = 'api';
        }
        return body['data'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Future<void> refreshTenants(
    String role, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    final data = await _get('/admin/tenants?pageSize=100', headers);
    if (data != null) {
      _tenants = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
  }

  Future<void> refreshTenantTrends(String role, String tenantId) async {
    final data = await _get('/admin/tenants/$tenantId/trends', _headers(role));
    if (data != null) {
      _tenantTrends ??= {};
      _tenantTrends![tenantId] = data;
    }
  }

  Future<Map<String, dynamic>?> fetchTenantDetail(
    String role,
    String id, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .get(Uri.parse('${resolveApiBaseUrl()}/admin/tenants/$id'),
            headers: _headers(
              role,
              tokens: tokens,
              allowMockTokenFallback: allowMockTokenFallback,
              roleTokens: _roleTokens,
            ))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] == 'OK') {
        return body['data'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Future<TenantWriteResult> createTenantRemote(
    String role,
    Map<String, dynamic> body, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/admin/tenants'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> updateTenantRemote(
    String role,
    String id,
    Map<String, dynamic> body, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .put(
          Uri.parse('${resolveApiBaseUrl()}/admin/tenants/$id'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> toggleTenantStatusRemote(
    String role,
    String id,
    String status, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/admin/tenants/$id/status'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> adjustTenantLicenseRemote(
    String role,
    String id,
    int licenseTotal, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/admin/tenants/$id/license'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode({'licenseTotal': licenseTotal}),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> deleteTenantRemote(
    String role,
    String id, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .delete(
          Uri.parse('${resolveApiBaseUrl()}/admin/tenants/$id'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  TenantWriteResult _parseTenantWrite(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['code'] == 'OK') {
        final data = body['data'];
        return TenantWriteResult(
          ok: true,
          tenant: data is Map<String, dynamic> ? data : null,
        );
      }
      return TenantWriteResult(
        ok: false,
        errorCode: body['code'] as String?,
        statusCode: response.statusCode,
        message: body['message'] as String?,
      );
    } catch (_) {
      return TenantWriteResult(ok: false, statusCode: response.statusCode);
    }
  }

  Future<bool> createB2bFarmRemote(
    String role,
    Map<String, dynamic> body, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/b2b/farms'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['code'] == 'OK') {
        final dashboardData = await _get(
          '/b2b/dashboard',
          _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
        );
        if (dashboardData != null) {
          _b2bDashboard = dashboardData;
        }
        return true;
      }
      return false;
    }
    return false;
  }

  Future<bool> confirmRevenuePeriodRemote(String role, String periodId) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/revenue/periods/$periodId/confirm'),
          headers: _headers(role, roleTokens: _roleTokens),
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['code'] == 'OK';
    }
    return false;
  }

  Future<void> refreshRevenuePeriods(String role) async {
    final data = await _get(
      '/revenue/periods',
      _headers(role, roleTokens: _roleTokens),
    );
    if (data != null) {
      _revenue = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
  }

  Future<void> refreshFencesAndMap(
    String role, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final headers = _headers(
      role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
      roleTokens: _roleTokens,
    );
    final fencesData = await _get('/farms/$_activeFarmId/fences?pageSize=100', headers);
    if (fencesData != null) {
      final items = fencesData['items'] is List
          ? List<Map<String, dynamic>>.from(fencesData['items'] ?? [])
          : <Map<String, dynamic>>[];
      _fences = items.map(_normalizeFenceItem).toList();
    }
    final mapData = await _get(
      '/farms/$_activeFarmId/map',
      headers,
    );
    if (mapData != null) {
      final animalsRaw = mapData['animals'];
      if (animalsRaw is List) {
        _animals = List<Map<String, dynamic>>.from(animalsRaw);
        _mapTrajectoryPoints =
            List<Map<String, dynamic>>.from(mapData['points'] ?? []);
      } else {
        _animals = _normalizeMapAnimals(mapData);
        _mapTrajectoryPoints = <Map<String, dynamic>>[];
      }
    }
  }

  Future<bool> deleteFenceRemote(
    String role,
    String id, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    final response = await http
        .delete(
          Uri.parse('${resolveApiBaseUrl()}/farms/$_activeFarmId/fences/$id'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['code'] == 'OK';
    }
    return false;
  }

  Future<bool> createFenceRemote(
    String role,
    Map<String, dynamic> body, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    if (createFenceRemoteOverride != null) {
      final result = await createFenceRemoteOverride!(role, body);
      lastFenceSaveStatusCode = result.ok ? null : result.statusCode;
      return result.ok;
    }
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/farms/$_activeFarmId/fences'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    lastFenceSaveStatusCode = response.statusCode;
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = decoded['code'] == 'OK';
      if (ok) {
        lastFenceSaveStatusCode = null;
      }
      return ok;
    }
    return false;
  }

  Future<bool> updateFenceRemote(
    String role,
    String id,
    Map<String, dynamic> body, {
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) async {
    if (updateFenceRemoteOverride != null) {
      final result = await updateFenceRemoteOverride!(role, id, body);
      lastFenceSaveStatusCode = result.ok ? null : result.statusCode;
      return result.ok;
    }
    final response = await http
        .put(
          Uri.parse('${resolveApiBaseUrl()}/farms/$_activeFarmId/fences/$id'),
          headers: _headers(
            role,
            tokens: tokens,
            allowMockTokenFallback: allowMockTokenFallback,
            roleTokens: _roleTokens,
          ),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    lastFenceSaveStatusCode = response.statusCode;
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final ok = decoded['code'] == 'OK';
      if (ok) {
        lastFenceSaveStatusCode = null;
      }
      return ok;
    }
    return false;
  }

  @visibleForTesting
  Future<FenceSaveResult> Function(String role, Map<String, dynamic> body)?
      createFenceRemoteOverride;

  @visibleForTesting
  Future<FenceSaveResult> Function(
    String role,
    String id,
    Map<String, dynamic> body,
  )? updateFenceRemoteOverride;

  @visibleForTesting
  static Map<String, String> headersForTesting({
    required DemoRole role,
    ApiAuthTokens? tokens,
    bool allowMockTokenFallback = false,
  }) {
    return apiHeaders(
      role: role,
      tokens: tokens,
      allowMockTokenFallback: allowMockTokenFallback,
    );
  }

  int? lastFenceSaveStatusCode;

  // ---------------------------------------------------------------------------
  // Normalization helpers: transform Spring Boot responses into the same shape
  // the Mock Server produces, so live repos work without per-repo changes.
  // If a field already matches Mock format, it passes through unchanged.
  // ---------------------------------------------------------------------------

  static String _stringId(dynamic v) {
    if (v is int) return v.toString();
    if (v is String) return v;
    return '';
  }

  /// Mock Server returns `{ metrics: [{key, title, value}] }`.
  /// Spring Boot returns flat `{ livestockCount, onlineDeviceCount, ... }`.
  static List<Map<String, dynamic>> _normalizeDashboardMetrics(
    Map<String, dynamic> data,
  ) {
    final list = <Map<String, dynamic>>[];
    final entries = <String, String>{
      'livestockCount': '牲畜总数',
      'onlineDeviceCount': '在线设备',
      'activeAlertCount': '活跃告警',
      'fenceCount': '围栏数',
    };
    for (final e in entries.entries) {
      final raw = data[e.key];
      if (raw != null) {
        list.add({
          'key': e.key,
          'title': e.value,
          'value': _stringId(raw),
        });
      }
    }
    final health = data['healthSummary'] as Map<String, dynamic>?;
    if (health != null) {
      final healthy = health['healthy'];
      final warning = health['warning'];
      final critical = health['critical'];
      if (healthy != null) {
        list.add({
          'key': 'healthHealthy',
          'title': '健康',
          'value': _stringId(healthy),
        });
      }
      if (warning != null) {
        list.add({
          'key': 'healthWarning',
          'title': '关注',
          'value': _stringId(warning),
        });
      }
      if (critical != null) {
        list.add({
          'key': 'healthCritical',
          'title': '异常',
          'value': _stringId(critical),
        });
      }
    }
    return list;
  }

  /// Mock Server returns `{ animals: [...], points: [...] }`.
  /// Spring Boot returns `{ livestock: [...], fences: [...], alerts: [...] }`.
  static List<Map<String, dynamic>> _normalizeMapAnimals(
    Map<String, dynamic> data,
  ) {
    final livestockRaw = data['livestock'] as List<dynamic>? ?? [];
    return livestockRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return <String, dynamic>{
        'id': _stringId(m['id']),
        'livestockCode': m['livestockCode'] ?? m['earTag'] ?? '',
        'lat': m['lat'],
        'lng': m['lng'],
        'healthStatus': m['healthStatus'] ?? 'healthy',
        'alertCount': m['alertCount'] ?? 0,
        // Keep original fields too for compatibility
        for (final entry in m.entries)
          if (!const {'id'}.contains(entry.key)) entry.key: entry.value,
      };
    }).toList();
  }

  /// Normalize a single alert item.
  /// Mock: { id, title, occurredAt, level, type, stage }
  /// Spring Boot: { id, type, status, severity, message, createdAt, livestockCode, fenceName, ... }
  static Map<String, dynamic> _normalizeAlertItem(Map<String, dynamic> m) {
    return <String, dynamic>{
      'id': _stringId(m['id']),
      // title: Mock has it directly; Spring Boot uses 'message'
      'title': m['title'] ?? m['message'] ?? '',
      // occurredAt: Mock uses this; Spring Boot uses 'createdAt'
      'occurredAt': m['occurredAt'] ?? m['createdAt'] ?? '',
      // level: Mock uses 'level'; Spring Boot uses 'severity'
      'level': m['level'] ?? m['severity'] ?? 'warning',
      // stage: Mock uses 'stage'; Spring Boot uses 'status'
      'stage': m['stage'] ?? m['status'] ?? 'pending',
      'type': m['type'] ?? 'unknown',
      // extra Spring Boot fields preserved for downstream use
      if (m['livestockCode'] != null) 'livestockCode': m['livestockCode'],
      if (m['fenceName'] != null) 'fenceName': m['fenceName'],
      for (final entry in m.entries)
        if (!const {
          'id',
          'title',
          'occurredAt',
          'level',
          'stage',
          'type',
        }.contains(entry.key))
          entry.key: entry.value,
    };
  }

  /// Normalize a single fence item.
  /// Mock: { id, name, type, coordinates: [[lng, lat], ...], alarmEnabled, status }
  /// Spring Boot: { id, name, vertices: [{lng, lat}, ...], color, status }
  static Map<String, dynamic> _normalizeFenceItem(Map<String, dynamic> m) {
    // If 'coordinates' already present (Mock format), pass through
    if (m['coordinates'] != null) {
      return <String, dynamic>{
        'id': _stringId(m['id']),
        for (final entry in m.entries)
          if (entry.key != 'id') entry.key: entry.value,
      };
    }
    // Convert Spring Boot 'vertices' to Mock 'coordinates'
    final vertices = m['vertices'] as List<dynamic>?;
    List<List<double>>? coordinates;
    if (vertices != null) {
      coordinates = vertices.map((v) {
        final vm = v as Map<String, dynamic>;
        return <double>[
          (vm['lng'] as num).toDouble(),
          (vm['lat'] as num).toDouble(),
        ];
      }).toList();
    }
    return <String, dynamic>{
      'id': _stringId(m['id']),
      'name': m['name'] ?? '未命名',
      'type': m['type'] ?? 'polygon',
      if (coordinates != null) 'coordinates': coordinates,
      'alarmEnabled': m['alarmEnabled'] ?? true,
      'status': m['status'] ?? 'active',
      for (final entry in m.entries)
        if (!const {
          'id',
          'name',
          'type',
          'vertices',
          'alarmEnabled',
          'status',
        }.contains(entry.key))
          entry.key: entry.value,
    };
  }

  /// Normalize a single device item.
  /// Mock: { id, name, type, status, boundEarTag, batteryPercent, signalStrength, lastSync }
  /// Spring Boot: { id, deviceCode, deviceType, status, runtimeStatus, batteryLevel, lastOnlineAt, ... }
  static Map<String, dynamic> _normalizeDeviceItem(Map<String, dynamic> m) {
    // If 'type' is already present and 'deviceType' is not, assume Mock format
    if (m['type'] != null && m['deviceType'] == null) {
      return <String, dynamic>{
        'id': _stringId(m['id']),
        for (final entry in m.entries)
          if (entry.key != 'id') entry.key: entry.value,
      };
    }
    // Map Spring Boot fields to Mock field names
    final deviceType = m['deviceType'] ?? m['type'] ?? '';
    final runtimeStatus = m['runtimeStatus'] ?? '';
    return <String, dynamic>{
      'id': _stringId(m['id']),
      'name': m['name'] ?? m['deviceCode'] ?? '',
      'type': _normalizeDeviceType(deviceType),
      'status': _normalizeDeviceStatus(runtimeStatus),
      'boundEarTag': m['boundEarTag'] ?? m['installedLivestockCode'] ?? '',
      'batteryPercent': m['batteryPercent'] ?? m['batteryLevel'],
      'signalStrength': m['signalStrength'],
      'lastSync': m['lastSync'] ?? m['lastOnlineAt'],
    };
  }

  /// Map Spring Boot deviceType to Mock type values: gps, rumenCapsule, accelerometer
  static String _normalizeDeviceType(String deviceType) {
    return switch (deviceType) {
      'device_tracker' || 'tracker' || 'gps' => 'gps',
      'rumen_capsule' || 'rumenCapsule' || 'capsule' => 'rumenCapsule',
      'accelerometer' => 'accelerometer',
      _ => 'gps',
    };
  }

  /// Map Spring Boot runtimeStatus to Mock status values: online, offline, lowBattery
  static String _normalizeDeviceStatus(String runtimeStatus) {
    return switch (runtimeStatus) {
      'online' => 'online',
      'offline' => 'offline',
      'low_battery' || 'lowBattery' => 'lowBattery',
      _ => 'offline',
    };
  }

  /// Normalize profile from /me endpoint.
  /// Mock: { name, tenantName, role, ... }
  /// Spring Boot: { id, username, name, phone, role, tenantId }
  static Map<String, dynamic>? _normalizeProfile(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final normalized = Map<String, dynamic>.from(raw);
    // Ensure 'name' exists (both formats have it)
    normalized['name'] ??= normalized['username'] ?? '未知用户';
    // Ensure 'tenantName' exists for UI
    normalized['tenantName'] ??= normalized['tenantName'] ?? '未知牧场';
    // Ensure 'role' exists
    normalized['role'] ??= '';
    return normalized;
  }

  void _clearLiveData() {
    _initialized = false;
    _lastLiveSource = null;
    _dashboardMetrics = [];
    _animals = [];
    _mapTrajectoryPoints = [];
    _alerts = [];
    _fences = [];
    _tenants = [];
    _profile = null;
    _twinOverview = null;
    _feverList = [];
    _digestiveList = [];
    _estrusList = [];
    _epidemicSummary = null;
    _epidemicContacts = [];
    _devices = [];
    _subscriptionCurrent = null;
    _subscriptionPlans = null;
    _subscriptionFeatures = null;
    _subscriptionUsage = null;
    _myFarms = null;
    _workers = null;
    _workersFarmId = null;
    _b2bDashboard = null;
    _b2bContract = null;
    _contracts = [];
    _revenue = [];
    _subscriptionServices = [];
    _apiKeys = [];
    _apiAuthorizations = [];
    _tenantDevicesCache.clear();
    _tenantLogsCache.clear();
    _tenantStatsCache.clear();
  }

  @visibleForTesting
  void debugReset() {
    _clearLiveData();
    _httpClient = const DefaultApiHttpClient();
    _roleTokens.clear();
    _tenantTrends = null;
    _initGeneration += 1;
  }

  @visibleForTesting
  void debugSetHttpClient(ApiHttpClient client) {
    _httpClient = client;
  }

  @visibleForTesting
  void debugSetInitialized(bool value) {
    _initialized = value;
    _lastLiveSource = value ? 'api' : null;
  }

  @visibleForTesting
  void debugSetTenants(List<Map<String, dynamic>> value) {
    _tenants = value;
  }

  @visibleForTesting
  void debugSetFences(List<Map<String, dynamic>> value) {
    _fences = value;
  }

  @visibleForTesting
  void debugSetAnimals(List<Map<String, dynamic>> value) {
    _animals = value;
  }

  @visibleForTesting
  void debugSetMyFarms(Map<String, dynamic>? value) {
    _myFarms = value;
  }
}
