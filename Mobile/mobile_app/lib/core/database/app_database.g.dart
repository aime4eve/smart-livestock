// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a minimal stub for development. Run build_runner to generate real code:
// dart run build_runner build --delete-conflicting-outputs

part of 'app_database.dart';

class _$TileMetas extends TileMetas with UpdateCompanionable {
  _$TileMetas({
    required this.id,
    required this.regionName,
    required this.fileName,
    required this.fileSize,
    this.md5,
    required this.filePath,
    required this.status,
    this.downloadedAt,
    this.lastAccessedAt,
    this.regionGeneratedAt,
  });

  @override
  final int id;
  final String regionName;
  final String fileName;
  final int fileSize;
  final String? md5;
  final String filePath;
  final String status;
  final DateTime? downloadedAt;
  final DateTime? lastAccessedAt;
  final DateTime? regionGeneratedAt;

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return {};
  }
}

class _$FarmTilePins extends FarmTilePins with UpdateCompanionable {
  _$FarmTilePins({
    required this.id,
    required this.farmId,
    required this.tileMetaId,
    required this.pinned,
  });

  @override
  final int id;
  final int farmId;
  final int tileMetaId;
  final bool pinned;

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return {};
  }
}

class _AppDatabase extends AppDatabase {}
