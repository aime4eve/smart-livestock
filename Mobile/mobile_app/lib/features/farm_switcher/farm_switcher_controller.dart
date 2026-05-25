import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';

class FarmInfo {
  const FarmInfo({required this.id, required this.name});
  final String id;
  final String name;
}

class FarmSwitcherState {
  const FarmSwitcherState({
    required this.farms,
    this.activeFarmId,
    this.isLoading = false,
    this.error,
  });
  const FarmSwitcherState.empty()
      : farms = const [],
        activeFarmId = null,
        isLoading = false,
        error = null;

  final List<FarmInfo> farms;
  final String? activeFarmId;
  final bool isLoading;
  final String? error;

  bool get hasMultipleFarms => farms.length > 1;
  bool get hasFarms => farms.isNotEmpty;
}

class FarmSwitcherController extends Notifier<FarmSwitcherState> {
  @override
  FarmSwitcherState build() {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const FarmSwitcherState.empty();
    return const FarmSwitcherState(farms: [], isLoading: true);
  }

  Future<void> loadFarms() async {
    state = const FarmSwitcherState(farms: [], isLoading: true);
    try {
      final data = await ApiClient.instance.get('/farms');
      final items = data['items'] as List<dynamic>? ?? [];
      final farms = items.whereType<Map<String, dynamic>>().map((json) {
        final rawId = json['id'];
        return FarmInfo(
          id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
          name: json['name'] as String? ?? '',
        );
      }).toList();

      if (farms.isEmpty) {
        state = const FarmSwitcherState.empty();
        return;
      }

      final session = ref.read(sessionControllerProvider);
      final activeFarmId = session.activeFarmId ?? farms.first.id;

      ApiClient.instance.setActiveFarmId(activeFarmId);
      if (session.activeFarmId == null) {
        ref.read(sessionControllerProvider.notifier).updateActiveFarm(activeFarmId);
      }

      state = FarmSwitcherState(farms: farms, activeFarmId: activeFarmId);
    } on AuthException {
      state = const FarmSwitcherState.empty();
    } catch (e) {
      state = const FarmSwitcherState(farms: [], error: '加载牧场失败');
    }
  }

  void switchFarm(String farmId) {
    final exists = state.farms.any((farm) => farm.id == farmId);
    if (!exists) return;
    state = FarmSwitcherState(farms: state.farms, activeFarmId: farmId);
    ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
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
