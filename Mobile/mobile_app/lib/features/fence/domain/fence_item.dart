import 'dart:math';

import 'package:latlong2/latlong.dart';

enum FenceType { polygon, circle, rectangle }

class FenceItem {
  const FenceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.alarmEnabled,
    required this.active,
    required this.areaHectares,
    required this.livestockCount,
    required this.colorValue,
    required this.points,
  });

  final String id;
  final String name;
  final FenceType type;
  final bool alarmEnabled;
  final bool active;
  final double areaHectares;
  final int livestockCount;
  final int colorValue;
  final List<LatLng> points;

  static const defaultColors = [
    0xFF4C9A5F,
    0xFF4A7F9D,
    0xFFD28A2D,
    0xFF9B59B6,
  ];

  static List<LatLng> defaultPointsForType(FenceType type, LatLng center) {
    const d = 0.001;
    return switch (type) {
      FenceType.rectangle => [
        LatLng(center.latitude + d, center.longitude - d),
        LatLng(center.latitude + d, center.longitude + d),
        LatLng(center.latitude - d, center.longitude + d),
        LatLng(center.latitude - d, center.longitude - d),
      ],
      FenceType.circle => [
        for (var i = 0; i < 12; i++)
          LatLng(
            center.latitude + d * cos(i * pi / 6),
            center.longitude + d * sin(i * pi / 6),
          ),
      ],
      FenceType.polygon => [
        LatLng(center.latitude + d * 1.2, center.longitude),
        LatLng(center.latitude + d * 0.4, center.longitude + d),
        LatLng(center.latitude - d * 0.8, center.longitude + d * 0.6),
        LatLng(center.latitude - d, center.longitude - d * 0.3),
        LatLng(center.latitude - d * 0.2, center.longitude - d),
      ],
    };
  }

  FenceItem copyWith({
    String? id,
    String? name,
    FenceType? type,
    bool? alarmEnabled,
    bool? active,
    double? areaHectares,
    int? livestockCount,
    int? colorValue,
    List<LatLng>? points,
  }) {
    return FenceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      active: active ?? this.active,
      areaHectares: areaHectares ?? this.areaHectares,
      livestockCount: livestockCount ?? this.livestockCount,
      colorValue: colorValue ?? this.colorValue,
      points: points ?? this.points,
    );
  }
}
