import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/admin/data/live_admin_repository.dart';
import 'package:smart_livestock_demo/features/admin/data/mock_admin_repository.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockAdminRepository();
    case AppMode.live:
      return const LiveAdminRepository();
  }
});

class AdminController extends Notifier<AdminViewData> {
  @override
  AdminViewData build() {
    return ref.watch(adminRepositoryProvider).load(
      viewState: ViewState.normal,
      licenseAdjusted: false,
    );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(adminRepositoryProvider).load(
      viewState: viewState,
      licenseAdjusted: state.licenseAdjusted,
    );
  }

  void markLicenseAdjusted() {
    state = ref.read(adminRepositoryProvider).load(
      viewState: state.viewState,
      licenseAdjusted: true,
    );
  }
}

final adminControllerProvider = NotifierProvider<AdminController, AdminViewData>(
  AdminController.new,
);
