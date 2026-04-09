import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

class MockDevicesRepository implements DevicesRepository {
  const MockDevicesRepository();

  @override
  DevicesViewData load(
      {required ViewState viewState, required DeviceStatus? filter}) {
    const all = DemoSeed.devices;
    final filtered =
        filter == null ? all : all.where((d) => d.status == filter).toList();
    return DevicesViewData(
      viewState: viewState,
      devices: viewState == ViewState.normal ? filtered : [],
      filter: filter,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无设备',
        ViewState.error => '设备列表加载失败（演示）',
        ViewState.forbidden => '无权限查看设备（演示）',
        ViewState.offline => '离线设备快照（演示）',
        ViewState.normal => null,
      },
    );
  }
}
