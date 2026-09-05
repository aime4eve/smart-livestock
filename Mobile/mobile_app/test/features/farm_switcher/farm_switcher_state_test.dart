import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';

void main() {
  const farm1 = FarmInfo(
    id: '1',
    name: 'Main Ranch',
    latitude: 28.229,
    longitude: 112.938,
  );
  const farm3 = FarmInfo(
    id: '3',
    name: 'Nix-lievstocks',
    latitude: -32.0,
    longitude: -62.5,
  );

  group('FarmSwitcherState.activeFarm', () {
    test('returns the farm matching activeFarmId with its coordinates', () {
      const state = FarmSwitcherState(farms: [farm1, farm3], activeFarmId: '3');
      expect(state.activeFarm, same(farm3));
      expect(state.activeFarm!.latitude, -32.0);
      expect(state.activeFarm!.longitude, -62.5);
    });

    test('falls back to first farm when activeFarmId matches nothing', () {
      const state = FarmSwitcherState(farms: [farm1, farm3], activeFarmId: '9');
      expect(state.activeFarm, same(farm1));
    });

    test('returns null when no farms loaded', () {
      const state = FarmSwitcherState.empty();
      expect(state.activeFarm, isNull);
    });
  });
}
