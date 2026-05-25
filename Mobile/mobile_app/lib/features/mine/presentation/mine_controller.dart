import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/mine/data/mine_api_repository.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

final mineRepositoryProvider = Provider<MineRepository>((ref) {
  return const MineApiRepository();
});

class MineController extends AsyncNotifier<MineViewData> {
  @override
  Future<MineViewData> build() async {
    return ref.read(mineRepositoryProvider).load();
  }
}

final mineControllerProvider = AsyncNotifierProvider<MineController, MineViewData>(
  MineController.new,
);
