import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/features/devices/data/devices_api_repository.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return const DevicesApiRepository();
});

class DevicesController extends FarmScopedAsyncNotifier<DevicesListData> {
  @override
  Future<DevicesListData> build() async {
    watchActiveFarmId();
    return ref.read(devicesRepositoryProvider).loadDevices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(devicesRepositoryProvider).loadDevices(),
    );
  }
}

final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, DevicesListData>(
  DevicesController.new,
);
