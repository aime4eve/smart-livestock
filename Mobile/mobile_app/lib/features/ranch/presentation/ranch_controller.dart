import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/features/ranch/data/ranch_api_repository.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_repository.dart';

final ranchRepositoryProvider = Provider<RanchRepository>(
  (_) => const RanchApiRepository(),
);

class RanchController extends FarmScopedAsyncNotifier<RanchOverview> {
  @override
  Future<RanchOverview> build() async {
    watchActiveFarmId();
    return ref.read(ranchRepositoryProvider).loadOverview();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ranchRepositoryProvider).loadOverview(),
    );
  }
}

final ranchControllerProvider =
    AsyncNotifierProvider<RanchController, RanchOverview>(
  RanchController.new,
);
