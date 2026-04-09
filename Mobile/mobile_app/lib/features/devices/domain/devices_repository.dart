import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class DevicesViewData {
  const DevicesViewData({
    required this.viewState,
    required this.devices,
    required this.filter,
    this.message,
  });

  final ViewState viewState;
  final List<DeviceItem> devices;
  final DeviceStatus? filter;
  final String? message;
}

abstract class DevicesRepository {
  DevicesViewData load({
    required ViewState viewState,
    required DeviceStatus? filter,
  });
}
