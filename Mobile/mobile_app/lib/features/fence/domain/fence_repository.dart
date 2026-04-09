import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class FenceViewData {
  const FenceViewData({
    required this.viewState,
    required this.role,
    required this.fenceTitle,
    required this.fenceSubtitle,
    required this.editSaved,
    this.message,
  });

  final ViewState viewState;
  final DemoRole role;
  final String fenceTitle;
  final String fenceSubtitle;
  final bool editSaved;
  final String? message;
}

abstract class FenceRepository {
  FenceViewData load({
    required ViewState viewState,
    required DemoRole role,
    required bool editSaved,
  });
}
