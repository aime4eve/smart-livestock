import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

abstract class EstrusRepository {
  EstrusViewData load([ViewState desiredState = ViewState.normal]);
  EstrusScore? loadDetail(String livestockId);
}
