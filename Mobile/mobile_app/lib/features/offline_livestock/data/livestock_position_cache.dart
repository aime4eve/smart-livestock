import 'package:smart_livestock_demo/core/database/app_database.dart';

class LivestockPositionCache {
  final AppDatabase _db;

  LivestockPositionCache(this._db);

  void refreshFromServer(List<Map<String, dynamic>> positions) {
    for (final pos in positions) {
      final livestockId = pos['livestockId'];
      if (livestockId is! int) continue;
      final lat = pos['latitude'];
      final lng = pos['longitude'];
      if (lat is! num || lng is! num) continue;
      _db.upsertLivestockPosition(
        livestockId: livestockId,
        name: pos['name'] as String?,
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        recordedAt: pos['recordedAt'] as String? ?? DateTime.now().toIso8601String(),
        fenceId: pos['fenceId'] as int?,
      );
    }
  }

  List<Map<String, dynamic>> getAllPositions() => _db.getLivestockPositions();
}
