class TileRegion {
  const TileRegion({
    required this.id,
    required this.name,
    this.minLon = 0.0,
    this.minLat = 0.0,
    this.maxLon = 0.0,
    this.maxLat = 0.0,
    this.minZoom = 11,
    this.maxZoom = 15,
    this.fileName,
    this.fileSize = 0,
    this.status,
  });

  final int id;
  final String name;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final int minZoom;
  final int maxZoom;
  final String? fileName;
  final int fileSize;
  final String? status;

  String get fileSizeLabel {
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class TileTask {
  const TileTask({
    required this.id,
    this.regionName,
    this.minLon = 0.0,
    this.minLat = 0.0,
    this.maxLon = 0.0,
    this.maxLat = 0.0,
    this.status,
    this.tileCount = 0,
    this.fileSizeMb = 0.0,
    this.errorMessage,
    this.progress,
    this.startedAt,
    this.finishedAt,
  });

  final int id;
  final String? regionName;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final String? status;
  final int tileCount;
  final double fileSizeMb;
  final String? errorMessage;
  final String? progress;
  final String? startedAt;
  final String? finishedAt;

  /// 从 progress 文本解析全局百分比 0.0-1.0，用于进度条。
  ///
  /// worker 进度格式（全局累计，跨 zoom 层不回零）：
  ///   "global 1234/5678 (22%) | z16 100/88908 (0%)"
  /// 优先取 "global" 段的百分比；回退到文本里第一个 "(N%)"。
  double? get progressValue {
    final text = progress ?? '';
    final globalMatch =
        RegExp(r'global\s+\d+/\d+\s+\((\d+)%\)').firstMatch(text);
    final m = globalMatch ?? RegExp(r'\((\d+)%\)').firstMatch(text);
    if (m == null) return null;
    return int.parse(m.group(1)!) / 100.0;
  }
}

class FarmTileStatus {
  const FarmTileStatus({
    required this.farmId,
    required this.farmName,
    this.tileStatus,
    this.regionName,
    this.lastDownloadAt,
  });

  final int farmId;
  final String farmName;
  final String? tileStatus;
  final String? regionName;
  final String? lastDownloadAt;
}
