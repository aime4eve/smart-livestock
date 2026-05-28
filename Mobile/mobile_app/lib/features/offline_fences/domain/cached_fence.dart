import 'dart:convert';
import 'package:latlong2/latlong.dart';

class CachedFenceData {
  final int? id;
  final int? remoteId;
  final int farmId;
  final String name;
  final String fenceType;
  final List<LatLng> vertices;
  final String status;
  final int version;
  final bool synced;
  final bool localDeleteFlag;
  final DateTime updatedAt;
  final DateTime? lastLocalModifiedAt;

  CachedFenceData({
    this.id,
    this.remoteId,
    required this.farmId,
    required this.name,
    this.fenceType = 'sub',
    required this.vertices,
    this.status = 'active',
    this.version = 1,
    this.synced = false,
    this.localDeleteFlag = false,
    required this.updatedAt,
    this.lastLocalModifiedAt,
  });

  String get verticesJson => jsonEncode(vertices.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList());

  static List<LatLng> parseVertices(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => LatLng((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble())).toList();
  }
}

class FenceConflict {
  final CachedFenceData localFence;
  final int serverVersion;
  final List<LatLng> serverVertices;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  FenceConflict({
    required this.localFence,
    required this.serverVersion,
    required this.serverVertices,
    this.lastModifiedBy,
    this.lastModifiedAt,
  });
}
