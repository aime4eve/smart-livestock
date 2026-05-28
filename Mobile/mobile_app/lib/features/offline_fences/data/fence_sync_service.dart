import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';
import 'package:smart_livestock_demo/core/database/app_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/offline_fences/domain/cached_fence.dart';

typedef ConflictCallback = void Function(FenceConflict conflict, int localRowId);

class FenceSyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;

  FenceSyncService(this._db, this._apiClient);

  Future<void> cacheFencesFromServer(int farmId) async {
    int page = 1;
    const pageSize = 100;
    List<dynamic> allItems = [];

    while (true) {
      final data = await _apiClient.farmGet('/fences?page=$page&pageSize=$pageSize');
      final items = data['items'] as List? ?? [];
      allItems.addAll(items);
      final total = data['total'] as int? ?? 0;
      if (allItems.length >= total || items.length < pageSize) break;
      page++;
    }

    for (final item in allItems) {
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

  Future<void> pushUnsyncedFences(
    int farmId, {
    ConflictCallback? onConflict,
  }) async {
    final unsynced = _db.getUnsyncedFences();
    for (final fence in unsynced) {
      if ((fence['farm_id'] as int) != farmId) continue;
      try {
        if ((fence['local_delete_flag'] as int) == 1) {
          if (fence['remote_id'] != null) {
            await _apiClient.farmDelete('/fences/${fence['remote_id']}');
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
          final created = await _apiClient.farmPost('/fences', body: body);
          final newRemoteId = created['id'] as int?;
          if (newRemoteId != null) {
            _db.rawDb.execute(
              'UPDATE cached_fences SET remote_id = ?, synced = 1 WHERE id = ?',
              [newRemoteId, fence['id']],
            );
          } else {
            _db.markFenceSynced(fence['id'] as int);
          }
        } else {
          body['expectedVersion'] = fence['version'];
          final remoteId = fence['remote_id'] as int;
          try {
            await _apiClient.farmPut('/fences/$remoteId', body: body);
            _db.markFenceSynced(fence['id'] as int);
          } on ConflictException catch (e) {
            final conflictData = e.data ?? {};
            final serverVersion = conflictData['serverVersion'] as int? ?? (fence['version'] as int);
            final serverVerticesRaw = conflictData['serverVertices'] as List? ?? [];
            final serverVertices = serverVerticesRaw
                .whereType<Map<String, dynamic>>()
                .map((v) => LatLng(
                  (v['lat'] as num).toDouble(),
                  (v['lng'] as num).toDouble(),
                ))
                .toList();
            final localVertices = (jsonDecode(fence['vertices'] as String) as List)
                .whereType<Map<String, dynamic>>()
                .map((v) => LatLng(
                  (v['lat'] as num).toDouble(),
                  (v['lng'] as num).toDouble(),
                ))
                .toList();
            final localFence = CachedFenceData(
              id: fence['id'] as int,
              remoteId: remoteId,
              farmId: farmId,
              name: fence['name'] as String,
              fenceType: fence['fence_type'] as String? ?? 'sub',
              vertices: localVertices,
              status: fence['status'] as String? ?? 'active',
              version: fence['version'] as int? ?? 1,
              synced: false,
              updatedAt: DateTime.now(),
            );
            final conflict = FenceConflict(
              localFence: localFence,
              serverVersion: serverVersion,
              serverVertices: serverVertices,
            );
            if (onConflict != null) {
              onConflict(conflict, fence['id'] as int);
            }
          }
        }
      } catch (e) {
        debugPrint('FenceSyncService: push failed: $e');
      }
    }
  }

  Future<void> sync(int farmId, {ConflictCallback? onConflict}) async {
    await pushUnsyncedFences(farmId, onConflict: onConflict);
    await cacheFencesFromServer(farmId);
  }

  int getUnsyncedCount(int farmId) {
    final all = _db.getUnsyncedFences();
    return all.where((f) => (f['farm_id'] as int) == farmId).length;
  }
}

final fenceSyncServiceProvider = Provider<FenceSyncService>((ref) {
  return FenceSyncService(AppDatabase.instance, ApiClient.instance);
});
