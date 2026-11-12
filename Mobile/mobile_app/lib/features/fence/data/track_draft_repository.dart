import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';

/// Fence quota carried by the candidates endpoint (plan ruling B1): the
/// only client-side quota pre-check data source.
class FenceQuota {
  const FenceQuota({required this.current, this.limit});

  /// Existing fence count of the active farm.
  final int current;

  /// Plan/license fence cap; null means unlimited (enterprise).
  final int? limit;

  bool get isFull => limit != null && current >= limit!;
}

/// One tracker candidate row of the track-draft wizard step 1.
class TrackDraftDeviceCandidate {
  const TrackDraftDeviceCandidate({
    required this.deviceId,
    required this.name,
    this.earTag,
    this.lastFixAt,
    required this.pointCount,
  });

  final int deviceId;
  final String name;
  final String? earTag;

  /// Latest fix timestamp; null when the device never reported.
  final DateTime? lastFixAt;

  /// Track points in the last `days` window (estimate for merging).
  final int pointCount;
}

/// Payload of GET /fences/track-draft/candidates.
class TrackDraftCandidates {
  const TrackDraftCandidates({required this.devices, required this.fenceQuota});

  final List<TrackDraftDeviceCandidate> devices;
  final FenceQuota fenceQuota;
}

/// Payload of POST /fences/track-draft/source.
class TrackDraftSourceResult {
  const TrackDraftSourceResult({
    required this.points,
    required this.totalRaw,
    required this.truncated,
    required this.sampledStride,
  });

  /// Merged + server-sampled track points (recordedAt ascending).
  /// `accuracyM` null is mapped to 0 (trusted) in this layer, spec §4.1.
  final List<TrackPoint> points;

  /// Server-side raw count before sampling.
  final int totalRaw;

  /// True when sampling kicked in (totalRaw > transport cap).
  final bool truncated;

  /// Applied sampling stride (1 = no sampling).
  final int sampledStride;
}

/// Repository contract for the track-draft wizard (spec §4.1/§4.2).
abstract class TrackDraftRepository {
  Future<TrackDraftCandidates> candidates({int days = 30});

  Future<TrackDraftSourceResult> source({
    required List<int> deviceIds,
    required DateTime startTime,
    required DateTime endTime,
  });
}

class TrackDraftApiRepository implements TrackDraftRepository {
  const TrackDraftApiRepository();

  @override
  Future<TrackDraftCandidates> candidates({int days = 30}) async {
    final data =
        await ApiClient.instance.farmGet('/fences/track-draft/candidates?days=$days');
    final devicesRaw = data['devices'];
    final devices = <TrackDraftDeviceCandidate>[
      if (devicesRaw is List)
        for (final m in devicesRaw.whereType<Map<String, dynamic>>())
          TrackDraftDeviceCandidate(
            deviceId: (m['deviceId'] as num?)?.toInt() ?? 0,
            name: m['name'] as String? ?? '',
            earTag: m['earTag'] as String?,
            lastFixAt: DateTime.tryParse(m['lastFixAt'] as String? ?? ''),
            pointCount: (m['pointCount'] as num?)?.toInt() ?? 0,
          ),
    ];
    final quotaRaw = data['fenceQuota'];
    var quota = const FenceQuota(current: 0);
    if (quotaRaw is Map<String, dynamic>) {
      quota = FenceQuota(
        current: (quotaRaw['current'] as num?)?.toInt() ?? 0,
        limit: (quotaRaw['limit'] as num?)?.toInt(),
      );
    }
    return TrackDraftCandidates(devices: devices, fenceQuota: quota);
  }

  @override
  Future<TrackDraftSourceResult> source({
    required List<int> deviceIds,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final data = await ApiClient.instance.farmPost(
      '/fences/track-draft/source',
      body: {
        'deviceIds': deviceIds,
        'startTime': _isoWithOffset(startTime),
        'endTime': _isoWithOffset(endTime),
      },
    );
    final pointsRaw = data['points'];
    final points = <TrackPoint>[
      if (pointsRaw is List)
        for (final m in pointsRaw.whereType<Map<String, dynamic>>())
          TrackPoint(
            lat: (m['lat'] as num?)?.toDouble() ?? 0,
            lng: (m['lng'] as num?)?.toDouble() ?? 0,
            // Contract: accuracyM null → 0 (trusted), mapped in this layer.
            accuracyMeters: (m['accuracyM'] as num?)?.toDouble() ?? 0,
            timestamp: DateTime.tryParse(m['recordedAt'] as String? ?? ''),
          ),
    ];
    return TrackDraftSourceResult(
      points: points,
      totalRaw: (data['totalRaw'] as num?)?.toInt() ?? points.length,
      truncated: data['truncated'] == true,
      sampledStride: (data['sampledStride'] as num?)?.toInt() ?? 1,
    );
  }

  /// ISO-8601 with explicit local offset (contract requires the offset;
  /// Dart's toIso8601String omits it for local times).
  static String _isoWithOffset(DateTime t) {
    final off = t.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final abs = off.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '${t.toIso8601String()}$sign$hh:$mm';
  }
}

final trackDraftRepositoryProvider = Provider<TrackDraftRepository>(
  (ref) => const TrackDraftApiRepository(),
);
