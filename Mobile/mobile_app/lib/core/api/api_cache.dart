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

class ApiCache {
  ApiCache._();
  static final ApiCache instance = ApiCache._();

  bool _initialized = false;
  bool get initialized => _initialized;
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
    final data = await _get('/tenants/$tenantId/devices', headers);
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
    final data = await _get('/tenants/$tenantId/logs', headers);
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
    final data = await _get('/tenants/$tenantId/stats', headers);
    if (data != null) {
      _tenantStatsCache[tenantId] = data;
    }
  }

  DeviceItem? _parseDeviceItem(Map<String, dynamic> json) {
    try {
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
        id: json['id'] as String? ?? '',
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
      return TenantLogEntry(
        id: json['id'] as String? ?? '',
        action: json['action'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        operator: json['operator'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
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
      final results = await Future.wait([
        initGet('/dashboard/summary'),
        initGet('/map/trajectories?animalId=animal_001&range=24h'),
        initGet('/alerts?pageSize=100'),
        initGet('/fences?pageSize=100'),
        initGet('/tenants?pageSize=100'),
        initGet('/profile'),
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

      if (results.every((data) => data == null)) {
        _initialized = false;
        _lastLiveSource = null;
        _tenantTrends = null;
        return;
      }
      _lastLiveSource = 'api';

      final dashData = results[0];
      if (dashData != null) {
        _dashboardMetrics =
            List<Map<String, dynamic>>.from(dashData['metrics'] ?? []);
      }

      final mapData = results[1];
      if (mapData != null) {
        _animals = List<Map<String, dynamic>>.from(mapData['animals'] ?? []);
        _mapTrajectoryPoints =
            List<Map<String, dynamic>>.from(mapData['points'] ?? []);
      }

      final alertsData = results[2];
      if (alertsData != null) {
        _alerts = List<Map<String, dynamic>>.from(alertsData['items'] ?? []);
      }

      final fencesData = results[3];
      if (fencesData != null) {
        _fences = List<Map<String, dynamic>>.from(fencesData['items'] ?? []);
      }

      final tenantsData = results[4];
      if (tenantsData != null) {
        _tenants = List<Map<String, dynamic>>.from(tenantsData['items'] ?? []);
      }

      _profile = results[5];

      _twinOverview = results[6];

      final feverData = results[7];
      if (feverData != null) {
        _feverList = List<Map<String, dynamic>>.from(feverData['items'] ?? []);
      }

      final digestiveData = results[8];
      if (digestiveData != null) {
        _digestiveList =
            List<Map<String, dynamic>>.from(digestiveData['items'] ?? []);
      }

      final estrusData = results[9];
      if (estrusData != null) {
        _estrusList =
            List<Map<String, dynamic>>.from(estrusData['items'] ?? []);
      }

      _epidemicSummary = results[10];

      final contactsData = results[11];
      if (contactsData != null) {
        _epidemicContacts =
            List<Map<String, dynamic>>.from(contactsData['items'] ?? []);
      }

      final devicesData = results[12];
      if (devicesData != null) {
        _devices = List<Map<String, dynamic>>.from(devicesData['items'] ?? []);
      }

      _subscriptionCurrent = results[13];
      _subscriptionFeatures = results[14];

      final plansData = results[15];
      if (plansData != null) {
        _subscriptionPlans =
            List<Map<String, dynamic>>.from(plansData['items'] ?? []);
      }

      _subscriptionUsage = results[16];

      if (role == DemoRole.owner.wireName || role == DemoRole.worker.wireName) {
        final myFarms = await initGet('/farm/my-farms');
        if (!_isCurrentGeneration(generation)) return;
        _myFarms = myFarms;
        final activeFarmId = myFarms?['activeFarmId'];
        if (role == DemoRole.owner.wireName &&
            activeFarmId is String &&
            activeFarmId.isNotEmpty) {
          final workers = await initGet('/farms/$activeFarmId/workers');
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
    final data = await _get('/tenants?pageSize=100', headers);
    if (data != null) {
      _tenants = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
  }

  Future<void> refreshTenantTrends(String role, String tenantId) async {
    final data = await _get('/tenants/$tenantId/trends', _headers(role));
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
        .get(Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
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
          Uri.parse('${resolveApiBaseUrl()}/tenants'),
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
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
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
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id/status'),
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
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id/license'),
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
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
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
    final fencesData = await _get('/fences?pageSize=100', headers);
    if (fencesData != null) {
      _fences = List<Map<String, dynamic>>.from(fencesData['items'] ?? []);
    }
    final mapData = await _get(
      '/map/trajectories?animalId=animal_001&range=24h',
      headers,
    );
    if (mapData != null) {
      _animals = List<Map<String, dynamic>>.from(mapData['animals'] ?? []);
      _mapTrajectoryPoints =
          List<Map<String, dynamic>>.from(mapData['points'] ?? []);
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
          Uri.parse('${resolveApiBaseUrl()}/fences/$id'),
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
          Uri.parse('${resolveApiBaseUrl()}/fences'),
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
          Uri.parse('${resolveApiBaseUrl()}/fences/$id'),
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
