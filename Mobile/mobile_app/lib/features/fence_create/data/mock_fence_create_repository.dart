import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence_create/domain/fence_create_repository.dart';

class MockFenceCreateRepository implements FenceCreateRepository {
  const MockFenceCreateRepository();

  @override
  FenceCreateViewData load({required ViewState viewState}) {
    return FenceCreateViewData(
      viewState: viewState,
      name: '',
      fenceType: FenceType.rectangle,
      enterAlert: true,
      leaveAlert: true,
      areaHectares: 2.3,
      message: viewState == ViewState.error ? '保存失败（演示）' : null,
    );
  }
}
