import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/digestive/domain/digestive_repository.dart';

class MockDigestiveRepository implements DigestiveRepository {
  const MockDigestiveRepository();

  @override
  DigestiveViewData load([ViewState desiredState = ViewState.normal]) {
    return DigestiveViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? TwinSeed.digestiveItems : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无消化管理数据',
        ViewState.error => '消化数据加载失败（演示）',
        ViewState.forbidden => '无权限查看消化数据（演示）',
        ViewState.offline => '离线：展示已缓存蠕动数据（演示）',
        ViewState.normal => null,
      },
    );
  }

  @override
  DigestiveHealth? loadDetail(String livestockId) {
    for (final d in TwinSeed.digestiveItems) {
      if (d.livestockId == livestockId) return d;
    }
    return null;
  }
}
