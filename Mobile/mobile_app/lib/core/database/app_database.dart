import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class TileMetas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get regionName => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get md5 => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get status => text().withDefault(const Constant('downloading'))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  DateTimeColumn get regionGeneratedAt => dateTime().nullable()();
}

class FarmTilePins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get farmId => integer()();
  IntColumn get tileMetaId => integer().references(TileMetas, #id)();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [TileMetas, FarmTilePins])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<TileMeta>> getTileMetas() => select(tileMetas).get();

  Future<TileMeta?> getTileMetaByRegion(String regionName) {
    return (select(tileMetas)..where((t) => t.regionName.equals(regionName)))
        .getSingleOrNull();
  }

  Future<void> insertTileMeta(TileMetasCompanion entry) {
    return into(tileMetas).insertOnConflictUpdate(entry);
  }

  Future<void> updateTileMetaStatus(int id, String status) {
    return (update(tileMetas)..where((t) => t.id.equals(id)))
        .write(TileMetasCompanion(status: Value(status)));
  }

  Future<void> updateTileMetaLastAccessed(int id) {
    return (update(tileMetas)..where((t) => t.id.equals(id)))
        .write(TileMetasCompanion(lastAccessedAt: Value(DateTime.now())));
  }

  Future<List<FarmTilePin>> getFarmTilePins(int farmId) {
    return (select(farmTilePins)..where((t) => t.farmId.equals(farmId))).get();
  }

  Future<void> insertFarmTilePin(FarmTilePinsCompanion entry) {
    return into(farmTilePins).insertOnConflictUpdate(entry);
  }

  Future<void> deleteFarmTilePins(int farmId) {
    return (delete(farmTilePins)..where((t) => t.farmId.equals(farmId))).go();
  }

  Future<void> setPin(int farmId, int tileMetaId, bool pinned) {
    final existing = await (select(farmTilePins)
          ..where((t) =>
              t.farmId.equals(farmId) & t.tileMetaId.equals(tileMetaId)))
        .getSingleOrNull();
    if (existing != null) {
      await (update(farmTilePins)..where((t) => t.id.equals(existing.id)))
          .write(FarmTilePinsCompanion(pinned: Value(pinned)));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'smart_livestock.db'));
    return NativeDatabase.createInBackground(file);
  });
}
