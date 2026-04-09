import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

abstract class TwinOverviewRepository {
  TwinOverviewViewData load([ViewState desiredState = ViewState.normal]);
}
