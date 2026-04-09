import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence_create/domain/fence_create_repository.dart';

class LiveFenceCreateRepository implements FenceCreateRepository {
  const LiveFenceCreateRepository();

  @override
  FenceCreateViewData load({required ViewState viewState}) {
    return FenceCreateViewData(
      viewState: viewState,
      name: '',
      fenceType: FenceType.rectangle,
      enterAlert: true,
      leaveAlert: true,
    );
  }
}
