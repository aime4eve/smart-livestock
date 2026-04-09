import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

class LiveLivestockRepository implements LivestockRepository {
  const LiveLivestockRepository();

  @override
  LivestockViewData load(
      {required ViewState viewState, required String earTag}) {
    return LivestockViewData(viewState: viewState, detail: null);
  }
}
