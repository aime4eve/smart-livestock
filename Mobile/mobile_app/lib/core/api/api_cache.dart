import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String resolveApiBaseUrl() {
  if (_apiBaseUrlFromEnv.isNotEmpty) {
    return _apiBaseUrlFromEnv;
  }
  return kIsWeb ? 'http://127.0.0.1:3001/api' : 'http://localhost:3001/api';
}

Map<String, String> _headers(String role) {
  return {
    'Authorization': 'Bearer mock-token-$role',
    'Content-Type': 'application/json',
  };
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

  Future<void> init(String role) async {
    final headers = _headers(role);

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

      final dashData = results[0];
      if (dashData != null) {
        _dashboardMetrics =
            List<Map<String, dynamic>>.from(dashData['metrics'] ?? []);
      }

      final mapData = results[1];
      if (mapData != null) {
        _animals =
            List<Map<String, dynamic>>.from(mapData['animals'] ?? []);
        _mapTrajectoryPoints =
            List<Map<String, dynamic>>.from(mapData['points'] ?? []);
      }

      final alertsData = results[2];
      if (alertsData != null) {
        _alerts =
            List<Map<String, dynamic>>.from(alertsData['items'] ?? []);
      }

      final fencesData = results[3];
      if (fencesData != null) {
        _fences =
            List<Map<String, dynamic>>.from(fencesData['items'] ?? []);
      }

      final tenantsData = results[4];
      if (tenantsData != null) {
        _tenants =
            List<Map<String, dynamic>>.from(tenantsData['items'] ?? []);
      }

      _profile = results[5];

      _twinOverview = results[6];

      final feverData = results[7];
      if (feverData != null) {
        _feverList =
            List<Map<String, dynamic>>.from(feverData['items'] ?? []);
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
        _devices =
            List<Map<String, dynamic>>.from(devicesData['items'] ?? []);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('ApiCache init failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> headers,
  ) async {
    final response = await http
        .get(
          Uri.parse('${resolveApiBaseUrl()}$path'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] == 'OK') {
        return body['data'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  Future<void> refreshTenants(String role) async {
    final headers = _headers(role);
    final data = await _get('/tenants?pageSize=100', headers);
    if (data != null) {
      _tenants = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }
  }

  Future<Map<String, dynamic>?> fetchTenantDetail(String role, String id) async {
    final response = await http
        .get(Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
            headers: _headers(role))
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
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/tenants'),
          headers: _headers(role),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> updateTenantRemote(
    String role,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
          headers: _headers(role),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> toggleTenantStatusRemote(
    String role,
    String id,
    String status,
  ) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id/status'),
          headers: _headers(role),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> adjustTenantLicenseRemote(
    String role,
    String id,
    int licenseTotal,
  ) async {
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id/license'),
          headers: _headers(role),
          body: jsonEncode({'licenseTotal': licenseTotal}),
        )
        .timeout(const Duration(seconds: 20));
    return _parseTenantWrite(response);
  }

  Future<TenantWriteResult> deleteTenantRemote(String role, String id) async {
    final response = await http
        .delete(
          Uri.parse('${resolveApiBaseUrl()}/tenants/$id'),
          headers: _headers(role),
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

  Future<void> refreshFencesAndMap(String role) async {
    final headers = _headers(role);
    final fencesData = await _get('/fences?pageSize=100', headers);
    if (fencesData != null) {
      _fences =
          List<Map<String, dynamic>>.from(fencesData['items'] ?? []);
    }
    final mapData = await _get(
      '/map/trajectories?animalId=animal_001&range=24h',
      headers,
    );
    if (mapData != null) {
      _animals =
          List<Map<String, dynamic>>.from(mapData['animals'] ?? []);
      _mapTrajectoryPoints =
          List<Map<String, dynamic>>.from(mapData['points'] ?? []);
    }
  }

  Future<bool> deleteFenceRemote(String role, String id) async {
    final response = await http
        .delete(
          Uri.parse('${resolveApiBaseUrl()}/fences/$id'),
          headers: _headers(role),
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
    Map<String, dynamic> body,
  ) async {
    if (createFenceRemoteOverride != null) {
      final result = await createFenceRemoteOverride!(role, body);
      lastFenceSaveStatusCode = result.ok ? null : result.statusCode;
      return result.ok;
    }
    final response = await http
        .post(
          Uri.parse('${resolveApiBaseUrl()}/fences'),
          headers: _headers(role),
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
    Map<String, dynamic> body,
  ) async {
    if (updateFenceRemoteOverride != null) {
      final result = await updateFenceRemoteOverride!(role, id, body);
      lastFenceSaveStatusCode = result.ok ? null : result.statusCode;
      return result.ok;
    }
    final response = await http
        .put(
          Uri.parse('${resolveApiBaseUrl()}/fences/$id'),
          headers: _headers(role),
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

  int? lastFenceSaveStatusCode;

  @visibleForTesting
  void debugReset() {
    _initialized = false;
    _tenants = [];
  }

  @visibleForTesting
  void debugSetInitialized(bool value) {
    _initialized = value;
  }

  @visibleForTesting
  void debugSetTenants(List<Map<String, dynamic>> value) {
    _tenants = value;
  }
}
