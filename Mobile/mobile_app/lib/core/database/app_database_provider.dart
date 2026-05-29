import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/database/app_database.dart';
import 'package:smart_livestock_demo/core/analytics/tile_analytics.dart';
import 'package:smart_livestock_demo/features/offline_tiles/presentation/offline_tile_manager.dart';
import 'package:smart_livestock_demo/features/offline_fences/data/fence_sync_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.instance;
  ref.onDispose(() => db.dispose());
  return db;
});

final fenceSyncServiceProvider = Provider<FenceSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FenceSyncService(db, ApiClient.instance);
});

final offlineTileManagerProvider = Provider<OfflineTileManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final baseUrl = ApiClient.instance.baseUrl;
  return OfflineTileManager(db, baseUrl, {});
});

final tileAnalyticsProvider = Provider<TileAnalytics>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final baseUrl = ApiClient.instance.baseUrl;
  return TileAnalytics(db, baseUrl, {});
});
