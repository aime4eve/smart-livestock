import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/livestock/data/livestock_api_repository.dart';

void main() {
  group('LivestockApiRepository._livestockSummaryFromMap', () {
    test('full summary with all fields', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': 'liv-1',
        'livestockCode': 'SL-2024-001',
        'breed': 'ANGUS',
        'healthStatus': 'HEALTHY',
        'fenceId': 'fence-1',
        'lastLatitude': 28.246,
        'lastLongitude': 112.852,
        'gender': 'MALE',
        'birthDate': '2024-03-15',
        'weight': 450.5,
      });

      expect(s.id, 'liv-1');
      expect(s.livestockCode, 'SL-2024-001');
      expect(s.breed, Breed.angus);
      expect(s.health, LivestockHealth.healthy);
      expect(s.fenceId, 'fence-1');
      expect(s.lat, 28.246);
      expect(s.lng, 112.852);
      expect(s.gender, 'MALE');
      expect(s.birthDate, DateTime(2024, 3, 15));
      expect(s.weight, 450.5);
    });

    test('int id converted to string', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': 42,
        'healthStatus': 'WARNING',
      });
      expect(s.id, '42');
      expect(s.health, LivestockHealth.watch);
    });

    test('CRITICAL health maps to abnormal', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'healthStatus': 'CRITICAL',
      });
      expect(s.health, LivestockHealth.abnormal);
    });

    test('null healthStatus defaults to healthy', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
      });
      expect(s.health, LivestockHealth.healthy);
    });

    test('lowercase healthStatus still maps correctly', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'healthStatus': 'warning',
      });
      expect(s.health, LivestockHealth.watch);
    });

    test('earTag fallback from earTag when livestockCode absent', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'earTag': 'EAR-001',
      });
      expect(s.livestockCode, 'EAR-001');
    });

    test('unknown breed maps to Breed.other', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'breed': 'HEREFORD',
      });
      expect(s.breed, Breed.other);
    });

    test('null breed maps to Breed.other', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'breed': null,
      });
      expect(s.breed, Breed.other);
    });

    test('int fenceId converted to string', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'fenceId': 5,
      });
      expect(s.fenceId, '5');
    });

    test('null coords are null', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
      });
      expect(s.lat, isNull);
      expect(s.lng, isNull);
    });

    test('invalid birthDate string produces null DateTime', () {
      final s = LivestockApiRepository.livestockSummaryFromMapForTest({
        'id': '1',
        'birthDate': 'not-a-date',
      });
      expect(s.birthDate, isNull);
    });
  });

  group('LivestockApiRepository._livestockDetailFromMap', () {
    test('full detail with all fields', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': 'liv-1',
        'livestockCode': 'SL-2024-001',
        'breed': 'WAGYU',
        'ageMonths': 30,
        'weightKg': 520.0,
        'healthStatus': 'WARNING',
        'fenceId': 'fence-2',
        'bodyTemp': 39.2,
        'activityLevel': '活跃',
        'ruminationFreq': '45/min',
        'lastLatitude': 28.246,
        'lastLongitude': 112.852,
      });

      expect(d.livestockId, 'liv-1');
      expect(d.livestockCode, 'SL-2024-001');
      expect(d.breed, Breed.wagyu);
      expect(d.ageMonths, 30);
      expect(d.weightKg, 520.0);
      expect(d.health, LivestockHealth.watch);
      expect(d.fenceId, 'fence-2');
      expect(d.devices, isEmpty);
      expect(d.bodyTemp, 39.2);
      expect(d.activityLevel, '活跃');
      expect(d.ruminationFreq, '45/min');
      expect(d.lastLocation, contains('28.246'));
      expect(d.lastLocation, contains('112.852'));
    });

    test('weight fallback from weight when weightKg absent', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
        'weight': 300,
      });
      expect(d.weightKg, 300.0);
    });

    test('missing ageMonths defaults to 24', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
      });
      expect(d.ageMonths, 24);
    });

    test('missing bodyTemp defaults to 38.5', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
      });
      expect(d.bodyTemp, 38.5);
    });

    test('missing activityLevel defaults to 正常', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
      });
      expect(d.activityLevel, '正常');
    });

    test('missing ruminationFreq defaults to --', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
      });
      expect(d.ruminationFreq, '--');
    });

    test('missing location shows dashes', () {
      final d = LivestockApiRepository.livestockDetailFromMapForTest({
        'id': '1',
      });
      expect(d.lastLocation, contains('--'));
    });
  });
}
