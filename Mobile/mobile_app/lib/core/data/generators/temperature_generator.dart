import 'dart:math';

import 'package:smart_livestock_demo/core/models/twin_models.dart';

class AbnormalTempEvent {
  const AbnormalTempEvent({
    required this.time,
    required this.peakDelta,
    required this.durationHours,
  });

  final DateTime time;
  final double peakDelta;
  final int durationHours;
}

class TemperatureGenerator {
  TemperatureGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<TemperatureRecord>> _cache = {};

  List<TemperatureRecord> generate({
    required String livestockId,
    required double baselineTemp,
    required DateTime start,
    required DateTime end,
    List<AbnormalTempEvent> abnormalEvents = const [],
  }) {
    return _cache.putIfAbsent(livestockId, () => _doGenerate(
          livestockId: livestockId,
          baselineTemp: baselineTemp,
          start: start,
          end: end,
          abnormalEvents: abnormalEvents,
        ));
  }

  List<TemperatureRecord> _doGenerate({
    required String livestockId,
    required double baselineTemp,
    required DateTime start,
    required DateTime end,
    required List<AbnormalTempEvent> abnormalEvents,
  }) {
    final rng = Random(seed + livestockId.hashCode);
    final records = <TemperatureRecord>[];

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;
      final circadian = (hour >= 8 && hour <= 18) ? 0.2 : -0.1;
      final noise = (rng.nextDouble() - 0.5) * 0.2;
      var temp = baselineTemp + circadian + noise;

      for (final event in abnormalEvents) {
        final hoursAfter = t.difference(event.time).inMinutes / 60.0;
        if (hoursAfter >= 0 && hoursAfter < event.durationHours) {
          final progress = hoursAfter / event.durationHours;
          final envelope =
              progress < 0.3 ? progress / 0.3 : 1.0 - (progress - 0.3) / 0.7;
          temp += event.peakDelta * envelope;
        }
      }

      records.add(TemperatureRecord(
        livestockId: livestockId,
        temperature: double.parse(temp.toStringAsFixed(2)),
        timestamp: t,
      ));

      t = t.add(const Duration(minutes: 30));
    }

    return records;
  }
}
