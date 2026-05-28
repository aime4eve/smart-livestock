import 'package:smart_livestock_demo/core/database/app_database.dart';

class LivestockPositionCache {
  final AppDatabase _db;

  LivestockPositionCache(this._db);

  void refreshFromServer(List<Map<String, dynamic>> positions) {
    for (final pos in positions) {
      _db.upsertLivestockPosition(
        livestockId: pos['livestockId'] as int,
        name: pos['name'] as String?,
        latitude: (pos['latitude'] as num).toDouble(),
        longitude: (pos['longitude'] as num).toDouble(),
        recordedAt: pos['recordedAt'] as String? ?? DateTime.now().toIso8601String(),
        fenceId: pos['fenceId'] as int?,
      );
    }
  }

  List<Map<String, dynamic>> getAllPositions() => _db.getLivestockPositions();
}
