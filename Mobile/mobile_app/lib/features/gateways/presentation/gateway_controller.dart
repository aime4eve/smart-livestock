import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';

import '../../../core/api/farm_scoped_controller.dart';
import '../data/gateway_api_repository.dart';
import '../domain/gateway_models.dart';

final gatewayRepositoryProvider =
    Provider<GatewayApiRepository>((ref) => const GatewayApiRepository());

/// Farm-scoped gateway discovery list (NIX-219 F1). Rebuilds on farm switch.
class GatewayListController extends FarmScopedAsyncNotifier<List<GatewayDiscoveryItem>> {
  @override
  Future<List<GatewayDiscoveryItem>> build() {
    final farmId = watchActiveFarmId();
    if (farmId == null) {
      return Future.value(const []);
    }
    return ref.read(gatewayRepositoryProvider).discover(farmId);
  }

  Future<void> refresh() async {
    final farmId = ref.read(sessionControllerProvider.select((s) => s.activeFarmId));
    if (farmId == null) return;
    state = const AsyncValue<List<GatewayDiscoveryItem>>.loading();
    state = await AsyncValue.guard(
        () => ref.read(gatewayRepositoryProvider).discover(farmId));
  }
}

final gatewayListControllerProvider = AsyncNotifierProvider<GatewayListController,
    List<GatewayDiscoveryItem>>(GatewayListController.new);

/// F8 coverage diagnostics (farm-scoped, rebuilds on farm switch).
class CoverageDiagnosticController
    extends FarmScopedAsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() {
    final farmId = watchActiveFarmId();
    if (farmId == null) {
      return Future.value(const {});
    }
    return ref.read(gatewayRepositoryProvider).coverageDiagnostics(farmId);
  }

  Future<void> refresh() async {
    final farmId = ref.read(sessionControllerProvider.select((s) => s.activeFarmId));
    if (farmId == null) return;
    state = const AsyncValue<Map<String, dynamic>>.loading();
    state = await AsyncValue.guard(
        () => ref.read(gatewayRepositoryProvider).coverageDiagnostics(farmId));
  }
}

final coverageDiagnosticControllerProvider = AsyncNotifierProvider<
    CoverageDiagnosticController, Map<String, dynamic>>(
    CoverageDiagnosticController.new);
