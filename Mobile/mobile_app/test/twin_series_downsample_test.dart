import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/data/twin_series_downsample.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';

void main() {
  test('hourlyMeanTemperature 合并同一小时多点为均值', () {
    const id = '0001';
    final input = [
      TemperatureRecord(
        livestockId: id,
        temperature: 38.0,
        timestamp: _t(2026, 4, 7, 10, 0),
      ),
      TemperatureRecord(
        livestockId: id,
        temperature: 40.0,
        timestamp: _t(2026, 4, 7, 10, 30),
      ),
    ];
    final out = TwinSeriesDownsample.hourlyMeanTemperature(input);
    expect(out.length, 1);
    expect(out.single.temperature, 39.0);
    expect(out.single.timestamp, _t(2026, 4, 7, 10, 0));
  });

  test('hourlyMeanTemperature 在超过 maxPoints 时均匀截断', () {
    const id = '0001';
    final input = <TemperatureRecord>[
      for (var i = 0; i < 300; i++)
        TemperatureRecord(
          livestockId: id,
          temperature: 38.0,
          timestamp: DateTime.utc(2026, 4, 1).add(Duration(hours: i)),
        ),
    ];
    final out = TwinSeriesDownsample.hourlyMeanTemperature(input, maxPoints: 50);
    expect(out.length, lessThanOrEqualTo(50));
    expect(out.first.livestockId, id);
  });

  test('hourlyMeanMotility 合并同一小时', () {
    const id = '0001';
    final input = [
      MotilityRecord(
        livestockId: id,
        frequency: 1.0,
        intensity: 0.5,
        timestamp: _t(2026, 4, 7, 10, 0),
      ),
      MotilityRecord(
        livestockId: id,
        frequency: 1.4,
        intensity: 0.7,
        timestamp: _t(2026, 4, 7, 10, 30),
      ),
    ];
    final out = TwinSeriesDownsample.hourlyMeanMotility(input);
    expect(out.length, 1);
    expect(out.single.frequency, 1.2);
    expect(out.single.intensity, 0.6);
  });

  test('空序列返回空', () {
    expect(TwinSeriesDownsample.hourlyMeanTemperature([]), isEmpty);
    expect(TwinSeriesDownsample.hourlyMeanMotility([]), isEmpty);
  });
}

DateTime _t(int y, int m, int d, int h, int min) =>
    DateTime.utc(y, m, d, h, min);
