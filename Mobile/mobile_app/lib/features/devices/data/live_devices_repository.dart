import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

class LiveDevicesRepository implements DevicesRepository {
  const LiveDevicesRepository();

  @override
  DevicesViewData load(
      {required ViewState viewState, required DeviceStatus? filter}) {
    return DevicesViewData(viewState: viewState, devices: [], filter: filter);
  }
}
