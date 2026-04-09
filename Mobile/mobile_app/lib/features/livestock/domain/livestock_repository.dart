import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class LivestockViewData {
  const LivestockViewData({
    required this.viewState,
    required this.detail,
    this.message,
  });

  final ViewState viewState;
  final LivestockDetail? detail;
  final String? message;
}

abstract class LivestockRepository {
  LivestockViewData load(
      {required ViewState viewState, required String earTag});
}
