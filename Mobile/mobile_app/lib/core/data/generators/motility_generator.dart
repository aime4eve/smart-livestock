import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class MotilityGenerator {
  MotilityGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<MotilityRecord>> _cache = {};

  List<MotilityRecord> generate({
    required String livestockId,
    required String healthLevel,
    required DateTime start,
    required DateTime end,
  }) {
    final key = '${livestockId}_$healthLevel';
    return _cache.putIfAbsent(key, () => _doGenerate(
          livestockId: livestockId,
          healthLevel: healthLevel,
          start: start,
          end: end,
        ));
  }

  List<MotilityRecord> _doGenerate({
    required String livestockId,
    required String healthLevel,
    required DateTime start,
    required DateTime end,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final records = <MotilityRecord>[];

    final healthFactor = switch (healthLevel) {
      'critical' => 0.3,
      'warning' => 0.55,
      _ => 1.0,
    };

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;

      double baseFreq;
      if ((hour >= 6 && hour < 8) || (hour >= 17 && hour < 19)) {
        baseFreq = 3.0 + rng.nextDouble() * 2.0;
      } else if ((hour >= 9 && hour < 12) || (hour >= 20 && hour < 23)) {
        baseFreq = 1.0 + rng.nextDouble() * 1.0;
      } else {
        baseFreq = 0.3 + rng.nextDouble() * 0.5;
      }

      final freq = baseFreq * healthFactor;
      final intensity = freq > 0.1 ? 0.5 + rng.nextDouble() * 0.4 : 0.0;

      records.add(MotilityRecord(
        livestockId: livestockId,
        frequency: double.parse(freq.toStringAsFixed(2)),
        intensity: double.parse(intensity.toStringAsFixed(2)),
        timestamp: t,
      ));

      t = t.add(const Duration(minutes: 30));
    }

    return records;
  }
}
