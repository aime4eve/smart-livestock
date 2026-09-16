import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';

/// 服务端 GPX 解析预览结果（NIX-213，借鉴 GPS 质量轨迹导入契约）。
class FenceTrackParseResult {
  const FenceTrackParseResult({
    required this.defaultName,
    required this.rawPointCount,
    required this.pointCount,
    required this.removedDuplicates,
    required this.invalidPoints,
    required this.lengthMeters,
    required this.metadataWarning,
    required this.trackPoints,
  });

  final String defaultName;
  final int rawPointCount;
  final int pointCount;
  final int removedDuplicates;
  final int invalidPoints;
  final double lengthMeters;
  final String? metadataWarning;

  /// 清洗后的轨迹点（WGS-84，供客户端包络管线）。
  final List<TrackPoint> trackPoints;

  factory FenceTrackParseResult.fromMap(Map<String, dynamic> map) {
    final rawPoints = (map['trackPoints'] as List? ?? const []);
    return FenceTrackParseResult(
      defaultName: map['defaultName'] as String? ?? '',
      rawPointCount: (map['rawPointCount'] as num?)?.toInt() ?? 0,
      pointCount: (map['pointCount'] as num?)?.toInt() ?? 0,
      removedDuplicates: (map['removedDuplicates'] as num?)?.toInt() ?? 0,
      invalidPoints: (map['invalidPoints'] as num?)?.toInt() ?? 0,
      lengthMeters: (map['lengthMeters'] as num?)?.toDouble() ?? 0,
      metadataWarning: map['metadataWarning'] as String?,
      trackPoints: [
        for (final p in rawPoints)
          if (p is Map<String, dynamic>)
            TrackPoint(
              lat: (p['lat'] as num).toDouble(),
              lng: (p['lng'] as num).toDouble(),
            ),
      ],
    );
  }
}

/// POST /fences/track-parse：无状态解析，不落库；围栏本体仍走 POST /fences。
Future<FenceTrackParseResult> parseFenceTrackGpx(
    List<int> bytes, String fileName) async {
  final data = await ApiClient.instance.farmUploadFile(
    '/fences/track-parse',
    bytes,
    fileName,
  );
  return FenceTrackParseResult.fromMap(data);
}
