import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

class FarmInfo {
  const FarmInfo({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;
}

class FarmSwitcherState {
  const FarmSwitcherState({
    required this.farms,
    this.activeFarmId,
  });

  const FarmSwitcherState.empty() : this(farms: const []);

  final List<FarmInfo> farms;
  final String? activeFarmId;

  bool get hasMultipleFarms => farms.length > 1;

  bool get hasFarms => farms.isNotEmpty;
}

class FarmSwitcherController extends Notifier<FarmSwitcherState> {
  @override
  FarmSwitcherState build() {
    final mode = ref.watch(appModeProvider);
    final session = ref.watch(sessionControllerProvider);
    switch (mode) {
      case AppMode.mock:
        return _mockState(session.role, session.activeFarmTenantId);
      case AppMode.live:
        return _liveState(session.activeFarmTenantId);
    }
  }

  void switchFarm(String farmId) {
    final exists = state.farms.any((farm) => farm.id == farmId);
    if (!exists) return;
    state = FarmSwitcherState(farms: state.farms, activeFarmId: farmId);
    ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
  }

  FarmSwitcherState _mockState(DemoRole? role, String? activeFarmId) {
    if (role != DemoRole.owner && role != DemoRole.worker) {
      return const FarmSwitcherState.empty();
    }
    const farms = [
      FarmInfo(id: 'tenant_001', name: '青山牧场', status: 'active'),
      FarmInfo(id: 'tenant_007', name: '河谷牧场', status: 'active'),
    ];
    return FarmSwitcherState(
      farms: farms,
      activeFarmId: _resolveActiveFarmId(farms, activeFarmId ?? 'tenant_001'),
    );
  }

  FarmSwitcherState _liveState(String? sessionActiveFarmId) {
    final data = ApiCache.instance.myFarms;
    if (data == null) return const FarmSwitcherState.empty();

    final rawFarms = data['farms'];
    if (rawFarms is! List) return const FarmSwitcherState.empty();

    final farms = rawFarms
        .whereType<Map<String, dynamic>>()
        .map(_parseFarmInfo)
        .whereType<FarmInfo>()
        .toList();
    if (farms.isEmpty) return const FarmSwitcherState.empty();

    final cacheActiveFarmId = data['activeFarmId'];
    final activeFarmId = _resolveActiveFarmId(
      farms,
      sessionActiveFarmId ??
          (cacheActiveFarmId is String ? cacheActiveFarmId : null),
    );
    return FarmSwitcherState(farms: farms, activeFarmId: activeFarmId);
  }

  FarmInfo? _parseFarmInfo(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return FarmInfo(
      id: id,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  String? _resolveActiveFarmId(List<FarmInfo> farms, String? activeFarmId) {
    if (activeFarmId != null && farms.any((farm) => farm.id == activeFarmId)) {
      return activeFarmId;
    }
    return farms.isEmpty ? null : farms.first.id;
  }
}

final farmSwitcherControllerProvider =
    NotifierProvider<FarmSwitcherController, FarmSwitcherState>(
  FarmSwitcherController.new,
);
