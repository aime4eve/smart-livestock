import 'package:smart_livestock_demo/core/models/twin_models.dart';

class TwinSeriesDownsample {
  const TwinSeriesDownsample._();

  static DateTime _hourStartUtc(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour);

  static List<TemperatureRecord> hourlyMeanTemperature(
    List<TemperatureRecord> input, {
    int maxPoints = 200,
  }) {
    if (input.isEmpty) return input;
    final id = input.first.livestockId;
    final buckets = <DateTime, List<double>>{};
    for (final r in input) {
      final k = _hourStartUtc(r.timestamp);
      (buckets[k] ??= []).add(r.temperature);
    }
    final keys = buckets.keys.toList()..sort();
    final merged = <TemperatureRecord>[];
    for (final k in keys) {
      final xs = buckets[k]!;
      final mean = xs.reduce((a, b) => a + b) / xs.length;
      merged.add(
        TemperatureRecord(
          livestockId: id,
          temperature: double.parse(mean.toStringAsFixed(2)),
          timestamp: k,
        ),
      );
    }
    if (merged.length <= maxPoints) return merged;
    return _uniformCapTemperature(merged, maxPoints);
  }

  static List<TemperatureRecord> _uniformCapTemperature(
    List<TemperatureRecord> list,
    int maxPoints,
  ) {
    if (list.length <= maxPoints) return list;
    if (maxPoints < 2) {
      return [list.last];
    }
    final id = list.first.livestockId;
    final step = (list.length - 1) / (maxPoints - 1);
    final out = <TemperatureRecord>[];
    for (var i = 0; i < maxPoints; i++) {
      final idx = (i * step).floor().clamp(0, list.length - 1);
      final r = list[idx];
      out.add(
        TemperatureRecord(
          livestockId: id,
          temperature: r.temperature,
          timestamp: r.timestamp,
        ),
      );
    }
    return out;
  }

  static List<MotilityRecord> hourlyMeanMotility(
    List<MotilityRecord> input, {
    int maxPoints = 200,
  }) {
    if (input.isEmpty) return input;
    final id = input.first.livestockId;
    final freqBuckets = <DateTime, List<double>>{};
    final intBuckets = <DateTime, List<double>>{};
    for (final r in input) {
      final k = _hourStartUtc(r.timestamp);
      (freqBuckets[k] ??= []).add(r.frequency);
      (intBuckets[k] ??= []).add(r.intensity);
    }
    final keys = freqBuckets.keys.toList()..sort();
    final merged = <MotilityRecord>[];
    for (final k in keys) {
      final fs = freqBuckets[k]!;
      final ins = intBuckets[k]!;
      final fMean = fs.reduce((a, b) => a + b) / fs.length;
      final iMean = ins.reduce((a, b) => a + b) / ins.length;
      merged.add(
        MotilityRecord(
          livestockId: id,
          frequency: double.parse(fMean.toStringAsFixed(2)),
          intensity: double.parse(iMean.toStringAsFixed(2)),
          timestamp: k,
        ),
      );
    }
    if (merged.length <= maxPoints) return merged;
    return _uniformCapMotility(merged, maxPoints);
  }

  static List<MotilityRecord> _uniformCapMotility(
    List<MotilityRecord> list,
    int maxPoints,
  ) {
    if (list.length <= maxPoints) return list;
    if (maxPoints < 2) {
      return [list.last];
    }
    final id = list.first.livestockId;
    final step = (list.length - 1) / (maxPoints - 1);
    final out = <MotilityRecord>[];
    for (var i = 0; i < maxPoints; i++) {
      final idx = (i * step).floor().clamp(0, list.length - 1);
      final r = list[idx];
      out.add(
        MotilityRecord(
          livestockId: id,
          frequency: r.frequency,
          intensity: r.intensity,
          timestamp: r.timestamp,
        ),
      );
    }
    return out;
  }
}
