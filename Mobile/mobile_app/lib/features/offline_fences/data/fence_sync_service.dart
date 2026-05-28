import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_livestock_demo/core/database/app_database.dart';

class FenceSyncService {
  final AppDatabase _db;
  final String _apiBaseUrl;
  final Map<String, String> _headers;

  FenceSyncService(this._db, this._apiBaseUrl, this._headers);

  Future<void> cacheFencesFromServer(int farmId) async {
    final uri = Uri.parse('$_apiBaseUrl/farms/$farmId/fences?pageSize=100');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return;

    final body = jsonDecode(response.body);
    final data = body['data'] ?? body;
    final items = (data is Map ? data['items'] : null) as List? ?? [];

    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final remoteId = map['id'] as int?;
      final version = map['version'] as int? ?? 1;
      if (remoteId == null) continue;

      final existing = _db.getCachedFenceByRemoteId(remoteId);
      if (existing != null && (existing['synced'] as int) == 1) {
        if (version > (existing['version'] as int)) {
          _db.insertCachedFence(
            remoteId: remoteId,
            farmId: farmId,
            name: map['name'] as String? ?? '',
            fenceType: map['fenceType'] as String? ?? 'sub',
            vertices: jsonEncode(map['vertices'] ?? []),
            status: map['active'] == true ? 'active' : 'disabled',
            version: version,
            synced: true,
          );
        }
        continue;
      }

      _db.insertCachedFence(
        remoteId: remoteId,
        farmId: farmId,
        name: map['name'] as String? ?? '',
        fenceType: map['fenceType'] as String? ?? 'sub',
        vertices: jsonEncode(map['vertices'] ?? []),
        status: map['active'] == true ? 'active' : 'disabled',
        version: version,
        synced: true,
      );
    }
  }

  Future<void> pushUnsyncedFences(int farmId) async {
    final unsynced = _db.getUnsyncedFences();
    for (final fence in unsynced) {
      if ((fence['farm_id'] as int) != farmId) continue;
      try {
        if ((fence['local_delete_flag'] as int) == 1) {
          if (fence['remote_id'] != null) {
            await http.delete(
              Uri.parse('$_apiBaseUrl/farms/$farmId/fences/${fence['remote_id']}'),
              headers: _headers,
            );
          }
          _db.deleteCachedFence(fence['id'] as int);
          continue;
        }

        final body = {
          'name': fence['name'],
          'vertices': jsonDecode(fence['vertices'] as String),
          'color': '#4C9A5F',
          'fenceType': fence['fence_type'],
        };

        if (fence['remote_id'] == null) {
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/farms/$farmId/fences'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          if (response.statusCode == 201) {
            final created = jsonDecode(response.body)['data'];
            _db.markFenceSynced(fence['id'] as int);
          }
        } else {
          body['expectedVersion'] = fence['version'];
          final remoteId = fence['remote_id'];
          final response = await http.put(
            Uri.parse('$_apiBaseUrl/farms/$farmId/fences/$remoteId'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
          if (response.statusCode == 200) {
            _db.markFenceSynced(fence['id'] as int);
          }
        }
      } catch (_) {
        // Skip, try next
      }
    }
  }

  Future<void> sync(int farmId) async {
    await pushUnsyncedFences(farmId);
    await cacheFencesFromServer(farmId);
  }

  int getUnsyncedCount(int farmId) {
    final all = _db.getUnsyncedFences();
    return all.where((f) => (f['farm_id'] as int) == farmId).length;
  }
}
