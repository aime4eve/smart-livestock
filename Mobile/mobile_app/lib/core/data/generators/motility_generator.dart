import 'package:smart_livestock_demo/core/data/generators/time_series_generator.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';

class MotilityGenerator extends TimeSeriesGenerator<MotilityRecord> {
  MotilityGenerator({super.seed});

  List<MotilityRecord> generate({
    required String livestockId,
    required String healthLevel,
    required DateTime start,
    required DateTime end,
  }) {
    final key = '${livestockId}_$healthLevel';
    return memoized(key, () => _doGenerate(
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
    final rng = rngForEntity(livestockId);
    final records = <MotilityRecord>[];

    var t = start;
    while (t.isBefore(end)) {
      final hour = t.hour;

      double baseRpm;
      if ((hour >= 6 && hour < 10) || (hour >= 16 && hour < 20)) {
        baseRpm = 1.1 + rng.nextDouble() * 0.45;
      } else if (hour >= 23 || hour < 5) {
        baseRpm = 0.72 + rng.nextDouble() * 0.32;
      } else {
        baseRpm = 0.92 + rng.nextDouble() * 0.42;
      }

      var freq = baseRpm + (rng.nextDouble() - 0.5) * 0.14;
      if (healthLevel == 'critical') {
        freq *= 0.06 + rng.nextDouble() * 0.14;
        if (rng.nextDouble() < 0.38) {
          freq = 0;
        }
      } else if (healthLevel == 'warning') {
        freq *= 0.38 + rng.nextDouble() * 0.22;
      }
      freq = freq.clamp(0.0, 2.2);

      final intensity =
          freq > 0.12 ? 0.45 + rng.nextDouble() * 0.45 : 0.0;

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
