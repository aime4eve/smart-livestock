import 'package:smart_livestock_demo/core/models/view_state.dart';

class AdminViewData {
  const AdminViewData({
    required this.viewState,
    required this.tenantTitle,
    required this.tenantSubtitle,
    required this.licenseAdjusted,
    this.message,
  });

  final ViewState viewState;
  final String tenantTitle;
  final String tenantSubtitle;
  final bool licenseAdjusted;
  final String? message;
}

abstract class AdminRepository {
  AdminViewData load({
    required ViewState viewState,
    required bool licenseAdjusted,
  });
}
