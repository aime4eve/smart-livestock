import 'package:latlong2/latlong.dart';

/// 一条轨迹采点（GPS 实时采集与外部 GPX 解析的统一输入，NIX-213）。
class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    this.accuracyMeters = 0,
    this.timestamp,
  });

  final double lat;
  final double lng;

  /// GPS 水平精度（米）。外部 GPX 来源无精度信息时为 0（视为可信）。
  final double accuracyMeters;

  /// 采样时间；GPX 来源可能没有 → null（速度离群剔除将按点对跳过）。
  final DateTime? timestamp;

  LatLng toLatLng() => LatLng(lat, lng);
}
