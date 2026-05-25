import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/admin/data/admin_api_repository.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return const AdminApiRepository();
});

class AdminController extends AsyncNotifier<AdminViewData> {
  @override
  Future<AdminViewData> build() async {
    return ref.read(adminRepositoryProvider).load();
  }
}

final adminControllerProvider = AsyncNotifierProvider<AdminController, AdminViewData>(
  AdminController.new,
);
