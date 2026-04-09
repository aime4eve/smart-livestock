import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/devices/data/live_devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/data/mock_devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockDevicesRepository();
    case AppMode.live:
      return const LiveDevicesRepository();
  }
});

class DevicesController extends Notifier<DevicesViewData> {
  @override
  DevicesViewData build() {
    return ref.watch(devicesRepositoryProvider).load(
          viewState: ViewState.normal,
          filter: null,
        );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(devicesRepositoryProvider).load(
          viewState: viewState,
          filter: state.filter,
        );
  }

  void setFilter(DeviceStatus? filter) {
    state = ref.read(devicesRepositoryProvider).load(
          viewState: state.viewState,
          filter: filter,
        );
  }
}

final devicesControllerProvider =
    NotifierProvider<DevicesController, DevicesViewData>(
  DevicesController.new,
);
