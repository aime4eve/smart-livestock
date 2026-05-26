import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/mine/data/mine_api_repository.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

final mineRepositoryProvider = Provider<MineRepository>((ref) {
  return const MineApiRepository();
});

class MineController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return ref.read(mineRepositoryProvider).loadProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(mineRepositoryProvider).loadProfile());
  }

  Future<bool> updateProfile(Map<String, dynamic> body) async {
    try {
      final profile = await ref.read(mineRepositoryProvider).updateProfile(body);
      state = AsyncData(profile);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await ref.read(mineRepositoryProvider).changePassword(oldPassword, newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final mineControllerProvider = AsyncNotifierProvider<MineController, UserProfile>(
  MineController.new,
);
