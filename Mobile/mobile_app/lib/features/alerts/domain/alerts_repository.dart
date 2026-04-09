import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

enum AlertStage {
  pending,
  acknowledged,
  handled,
  archived,
}

class AlertsViewData {
  const AlertsViewData({
    required this.viewState,
    required this.role,
    required this.stage,
    required this.title,
    required this.subtitle,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final DemoRole role;
  final AlertStage stage;
  final String title;
  final String subtitle;
  final List<AlertItem> items;
  final String? message;
}

abstract class AlertsRepository {
  AlertsViewData load({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  });
}
