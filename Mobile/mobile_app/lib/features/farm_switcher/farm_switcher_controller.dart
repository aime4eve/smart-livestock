import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';

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
  static const bool _emptyFarmDemo =
      bool.fromEnvironment('EMPTY_FARM_DEMO', defaultValue: false);

  @override
  FarmSwitcherState build() {
    final session = ref.watch(sessionControllerProvider);
    return _liveState(session.activeFarmId);
  }


  Future<void> loadFarms() async {
    // Force re-read of the current session and rebuild state.
    // In the live-only world the cache is populated during login.
    ref.invalidateSelf();
  }
  void switchFarm(String farmId) {
    final exists = state.farms.any((farm) => farm.id == farmId);
    if (!exists) return;
    state = FarmSwitcherState(farms: state.farms, activeFarmId: farmId);
    ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
    ApiCache.instance.activeFarmId = farmId;
  }

  FarmSwitcherState _mockState(UserRole? role, String? activeFarmId) {
    if (_emptyFarmDemo) {
      return const FarmSwitcherState.empty();
    }
    if (role != UserRole.owner && role != UserRole.worker) {
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

    // Spring Boot returns { items: [...], total: N }
    // ApiCache._initForGeneration stores farm endpoint response in _myFarms
    List<dynamic> rawFarms;
    if (data['items'] is List) {
      rawFarms = data['items'] as List;
    } else if (data['farms'] is List) {
      rawFarms = data['farms'] as List; // Mock Server compat
    } else {
      return const FarmSwitcherState.empty();
    }

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

    // Sync active farm to ApiCache for downstream path injection
    if (activeFarmId != null) {
      ApiCache.instance.activeFarmId = activeFarmId;
    }

    return FarmSwitcherState(farms: farms, activeFarmId: activeFarmId);
  }

  FarmInfo? _parseFarmInfo(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : (rawId is String ? rawId : null);
    if (id == null || id.isEmpty) return null;
    return FarmInfo(
      id: id,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
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

class FarmDataReadyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void markReady() => state = true;
  void reset() => state = false;
}

final farmDataReadyProvider =
    NotifierProvider<FarmDataReadyNotifier, bool>(FarmDataReadyNotifier.new);
