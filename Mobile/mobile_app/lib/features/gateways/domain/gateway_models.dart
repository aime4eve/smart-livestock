/// Gateway registry models (NIX-219). Parsed from
/// GET /api/v1/farms/{farmId}/gateways and the mark-position response.
library;

class GatewayDiscoveryItem {
  const GatewayDiscoveryItem({
    required this.gatewayId,
    required this.lastSeen,
    required this.frames,
    required this.avgRssi,
    required this.registered,
    this.latitude,
    this.longitude,
    this.markedAt,
  });

  final String gatewayId;
  final DateTime? lastSeen;
  final int frames;
  final double? avgRssi;
  final bool registered;
  final double? latitude;
  final double? longitude;
  final DateTime? markedAt;

  /// F3 tier dot: stable / weak / edge / unknown (30-day average RSSI).
  String get linkTier {
    if (avgRssi == null) return 'unknown';
    if (avgRssi! < -100) return 'edge';
    if (avgRssi! < -90) return 'weak';
    return 'stable';
  }

  /// Short display tail, e.g. b83b8fffff000183 -> …000183.
  String get shortId => gatewayId.length <= 6 ? gatewayId : '…${gatewayId.substring(gatewayId.length - 6)}';

  factory GatewayDiscoveryItem.fromJson(Map<String, dynamic> j) {
    DateTime? parse(Object? v) =>
        v == null || v.toString().isEmpty ? null : DateTime.tryParse(v.toString());
    return GatewayDiscoveryItem(
      gatewayId: j['gatewayId'] as String,
      lastSeen: parse(j['lastSeen']),
      frames: (j['frames'] as num?)?.toInt() ?? 0,
      avgRssi: (j['avgRssi'] as num?)?.toDouble(),
      registered: j['registered'] == true,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      markedAt: parse(j['markedAt']),
    );
  }
}

class MarkPositionResult {
  const MarkPositionResult({
    required this.overwritten,
    required this.gatewayId,
    required this.latitude,
    required this.longitude,
  });

  final bool overwritten;
  final String gatewayId;
  final double latitude;
  final double longitude;
}
