import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/data/generators/estrus_score_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/gps_trajectory_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/motility_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/temperature_generator.dart';

void main() {
  group('GpsTrajectoryGenerator', () {
    test('generates 168 points for 7 days at 1h interval', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      final points = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: const [
          LatLng(28.2305, 112.9400),
          LatLng(28.2340, 112.9400),
          LatLng(28.2340, 112.9440),
          LatLng(28.2305, 112.9440),
        ],
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(points.length, 168);
    });

    test('all points stay within fence bounding box', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      final points = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: const [
          LatLng(28.2305, 112.9400),
          LatLng(28.2340, 112.9400),
          LatLng(28.2340, 112.9440),
          LatLng(28.2305, 112.9440),
        ],
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      for (final p in points) {
        expect(p.lat, greaterThanOrEqualTo(28.2305));
        expect(p.lat, lessThanOrEqualTo(28.2340));
        expect(p.lng, greaterThanOrEqualTo(112.9400));
        expect(p.lng, lessThanOrEqualTo(112.9440));
      }
    });

    test('results are cached for identical earTag, fence, and range', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      const fence = [
        LatLng(28.2305, 112.9400),
        LatLng(28.2340, 112.9440),
      ];
      final a = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final b = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(identical(a, b), isTrue);
    });

    test('different time ranges use separate cache entries', () {
      final gen = GpsTrajectoryGenerator(seed: 42);
      const fence = [
        LatLng(28.2305, 112.9400),
        LatLng(28.2340, 112.9440),
      ];
      final end = DateTime.utc(2026, 4, 8, 10);
      final day24 = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: end.subtract(const Duration(hours: 24)),
        end: end,
      );
      final week7 = gen.generate(
        earTag: 'SL-2024-001',
        fenceBoundary: fence,
        start: end.subtract(const Duration(days: 7)),
        end: end,
      );
      expect(day24.length, 24);
      expect(week7.length, 168);
      expect(identical(day24, week7), isFalse);
    });
  });

  group('TemperatureGenerator', () {
    test('generates 336 records for 7 days at 30min interval', () {
      final gen = TemperatureGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        baselineTemp: 38.5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(records.length, 336);
    });

    test('temperatures stay in reasonable range (36-42°C)', () {
      final gen = TemperatureGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        baselineTemp: 38.5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      for (final r in records) {
        expect(r.temperature, greaterThan(36.0));
        expect(r.temperature, lessThan(42.0));
      }
    });
  });

  group('MotilityGenerator', () {
    test('generates 336 records for 7 days at 30min interval', () {
      final gen = MotilityGenerator(seed: 42);
      final records = gen.generate(
        livestockId: '0001',
        healthLevel: 'normal',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(records.length, 336);
    });

    test('abnormal cows have lower motility', () {
      final gen = MotilityGenerator(seed: 42);
      final normal = gen.generate(
        livestockId: '0001',
        healthLevel: 'normal',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final abnormal = gen.generate(
        livestockId: '0002',
        healthLevel: 'critical',
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final avgNormal =
          normal.map((r) => r.frequency).reduce((a, b) => a + b) /
              normal.length;
      final avgAbnormal =
          abnormal.map((r) => r.frequency).reduce((a, b) => a + b) /
              abnormal.length;
      expect(avgAbnormal, lessThan(avgNormal));
    });
  });

  group('EstrusScoreGenerator', () {
    test('generates 7 points for 7 days', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0012',
        inEstrus: true,
        cycleDay: 17,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      expect(scores.length, 7);
    });

    test('estrus cow peaks above 70', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0012',
        inEstrus: true,
        cycleDay: 17,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      expect(maxScore, greaterThan(70.0));
    });

    test('non-estrus cow stays below 40', () {
      final gen = EstrusScoreGenerator(seed: 42);
      final scores = gen.generate(
        livestockId: '0005',
        inEstrus: false,
        cycleDay: 5,
        start: DateTime.utc(2026, 4, 1),
        end: DateTime.utc(2026, 4, 8),
      );
      final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      expect(maxScore, lessThan(40.0));
    });
  });
}
