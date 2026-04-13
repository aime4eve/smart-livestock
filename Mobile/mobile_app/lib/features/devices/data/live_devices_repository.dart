import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/devices/data/mock_devices_repository.dart';
import 'package:smart_livestock_demo/features/devices/domain/devices_repository.dart';

class LiveDevicesRepository implements DevicesRepository {
  const LiveDevicesRepository();

  static const MockDevicesRepository _fallback = MockDevicesRepository();

  static DeviceItem? parseDeviceMap(Map<String, dynamic> m) {
    try {
      final typeStr = m['type'] as String;
      final type = switch (typeStr) {
        'gps' => DeviceType.gps,
        'rumenCapsule' => DeviceType.rumenCapsule,
        'accelerometer' => DeviceType.accelerometer,
        _ => throw const FormatException('type'),
      };
      final statusStr = m['status'] as String;
      final status = switch (statusStr) {
        'online' => DeviceStatus.online,
        'offline' => DeviceStatus.offline,
        'lowBattery' => DeviceStatus.lowBattery,
        _ => throw const FormatException('status'),
      };
      return DeviceItem(
        id: m['id'] as String,
        name: m['name'] as String,
        type: type,
        status: status,
        boundEarTag: m['boundEarTag'] as String,
        batteryPercent: (m['batteryPercent'] as num?)?.toInt(),
        signalStrength: m['signalStrength'] as String?,
        lastSync: m['lastSync'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  DevicesViewData load({
    required ViewState viewState,
    required DeviceStatus? filter,
  }) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.devices.isEmpty) {
      return _fallback.load(viewState: viewState, filter: filter);
    }
    final all = cache.devices
        .map(parseDeviceMap)
        .whereType<DeviceItem>()
        .toList();
    final filtered =
        filter == null ? all : all.where((d) => d.status == filter).toList();
    return DevicesViewData(
      viewState: viewState,
      devices: viewState == ViewState.normal ? filtered : [],
      filter: filter,
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无设备',
        ViewState.error => '设备列表加载失败',
        ViewState.forbidden => '无权限查看设备',
        ViewState.offline => '离线设备快照',
        ViewState.normal => null,
      },
    );
  }
}
