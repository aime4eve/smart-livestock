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
  return apiHeaders(
    role: DemoRole.values.byName(role),
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

  List<DeviceItem>? tenantDevices(String tenantId) => _tenantDevicesCache[tenantId];
  List<TenantLogEntry>? tenantLogs(String tenantId) => _tenantLogsCache[tenantId];
  Map<String, dynamic>? tenantStats(String tenantId) => _tenantStatsCache[tenantId];

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
      expiresAt: expiresAtRaw is String ? DateTime.tryParse(expiresAtRaw) : null,
    );
    _roleTokens[role] = tokens;
    return tokens;
  }

  Future<void> initWithRoleAuth(String role) async {
    try {
      final tokens = await authenticateRole(role);
      if (tokens == null) {
        _clearLiveData();
        debugPrint('ApiCache auth failed for role: $role');
        return;
      }
      await init(role, tokens: tokens);
    } catch (e) {
      _clearLiveData();
      debugPrint('ApiCache auth failed for role: $role, $e');
    }
  }

  Future<void> init(
    String role, {
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

    try {
      final results = await Future.wait([
        _get('/dashboard/summary', headers),
        _get('/map/trajectories?animalId=animal_001&range=24h', headers),
        _get('/alerts?pageSize=100', headers),
        _get('/fences?pageSize=100', headers),
        _get('/tenants?pageSize=100', headers),
        _get('/profile', headers),
        _get('/twin/overview', headers),
        _get('/twin/fever/list', headers),
        _get('/twin/digestive/list', headers),
        _get('/twin/estrus/list', headers),
        _get('/twin/epidemic/summary', headers),
        _get('/twin/epidemic/contacts', headers),
        _get('/devices?pageSize=200', headers),
      ]);

      if (results.every((data) => data == null)) {
        _initialized = false;
        _lastLiveSource = null;
        return;
      }

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

      _initialized = true;
    } catch (e) {
      _clearLiveData();
      debugPrint('ApiCache init failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> headers,
  ) async {
    final response = await _httpClient.get(
      Uri.parse('${resolveApiBaseUrl()}$path'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] == 'OK') {
        _lastLiveSource = 'api';
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
  }

  @visibleForTesting
  void debugReset() {
    _clearLiveData();
    _httpClient = const DefaultApiHttpClient();
    _roleTokens.clear();
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
}
