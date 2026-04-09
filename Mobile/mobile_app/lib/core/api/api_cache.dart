import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3001/api',
);

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

  Future<void> init(String role) async {
    final token = 'mock-token-$role';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

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

      _initialized = true;
    } catch (e) {
      debugPrint('ApiCache init failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> headers,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl$path'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] == 'OK') {
        return body['data'] as Map<String, dynamic>?;
      }
    }
    return null;
  }
}
