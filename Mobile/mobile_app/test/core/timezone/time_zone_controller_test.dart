import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkt_livestock_agentic/core/timezone/time_zone_controller.dart';

void main() {
  group('isChinaTimeZone', () {
    test('Asia/Shanghai and other UTC+8 China ids → true', () {
      expect(isChinaTimeZone('Asia/Shanghai'), isTrue);
      expect(isChinaTimeZone('Asia/Hong_Kong'), isTrue);
      expect(isChinaTimeZone('Asia/Taipei'), isTrue);
    });

    test('non-China ids → false', () {
      expect(isChinaTimeZone('UTC'), isFalse);
      expect(isChinaTimeZone('Europe/London'), isFalse);
      expect(isChinaTimeZone('America/New_York'), isFalse);
      expect(isChinaTimeZone('Australia/Sydney'), isFalse);
    });

    test('null id (follow system) uses UTC+8 offset heuristic', () {
      expect(isChinaTimeZone(null),
          DateTime.now().timeZoneOffset == const Duration(hours: 8));
    });
  });

  group('TimeZoneController', () {
    test('setTimeZone persists and updates state', () async {
      SharedPreferences.setMockInitialValues(<String, String>{});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(timeZoneControllerProvider.notifier);
      expect(container.read(timeZoneControllerProvider), isNull);
      expect(controller.useChinaTileSource,
          DateTime.now().timeZoneOffset == const Duration(hours: 8));

      await controller.setTimeZone('Asia/Shanghai');
      expect(container.read(timeZoneControllerProvider), 'Asia/Shanghai');
      expect(controller.useChinaTileSource, isTrue);

      await controller.setTimeZone('America/New_York');
      expect(controller.useChinaTileSource, isFalse);

      await controller.setTimeZone(null);
      expect(container.read(timeZoneControllerProvider), isNull);
    });

    test('restore reads persisted value', () async {
      SharedPreferences.setMockInitialValues(
          <String, String>{'app_time_zone': 'UTC'});
      expect(await TimeZoneController.restore(), 'UTC');
    });
  });
}
