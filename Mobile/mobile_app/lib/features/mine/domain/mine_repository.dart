import 'package:smart_livestock_demo/core/models/view_state.dart';

class MineViewData {
  const MineViewData({
    required this.viewState,
    required this.normalText,
    this.message,
  });

  final ViewState viewState;
  final String normalText;
  final String? message;
}

abstract class MineRepository {
  MineViewData load(ViewState viewState);
}
