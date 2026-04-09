import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class DashboardViewData {
  const DashboardViewData({
    required this.viewState,
    required this.metrics,
    this.message,
  });

  final ViewState viewState;
  final List<DashboardMetric> metrics;
  final String? message;
}

abstract class DashboardRepository {
  DashboardViewData load(ViewState viewState);
}
