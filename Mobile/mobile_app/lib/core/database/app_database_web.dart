class AppDatabase {
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  AppDatabase._();

  static Future<AppDatabase> createAsync() async {
    _instance = AppDatabase._();
    return _instance!;
  }

  dynamic get rawDb => null;

  List<Map<String, dynamic>> getCachedFencesByFarm(int farmId) => [];
  List<Map<String, dynamic>> getUnsyncedFences() => [];
  Map<String, dynamic>? getCachedFenceByRemoteId(int remoteId) => null;

  void insertCachedFence({
    int? remoteId,
    required int farmId,
    required String name,
    String fenceType = 'sub',
    required String vertices,
    String status = 'active',
    int version = 1,
    bool synced = false,
    bool localDeleteFlag = false,
    DateTime? lastLocalModifiedAt,
  }) {}

  void markFenceSynced(int id) {}
  void deleteCachedFence(int id) {}
  void deleteCachedFencesByFarm(int farmId) {}

  List<Map<String, dynamic>> getTileMetas() => [];
  Map<String, dynamic>? getTileMetaByRegion(String regionName) => null;

  void insertTileMeta({
    required String regionName,
    required String fileName,
    required int fileSize,
    String? md5,
    required String filePath,
    String status = 'downloading',
  }) {}

  int getStorageUsed() => 0;

  void insertAnalyticsEvent(String eventType, String payload) {}
  List<Map<String, dynamic>> getUnreportedEvents() => [];
  void markEventsReported(List<int> ids) {}

  void upsertLivestockPosition({
    required int livestockId,
    String? name,
    required double latitude,
    required double longitude,
    required String recordedAt,
    int? fenceId,
  }) {}

  List<Map<String, dynamic>> getLivestockPositions() => [];

  void dispose() {
    _instance = null;
  }
}
