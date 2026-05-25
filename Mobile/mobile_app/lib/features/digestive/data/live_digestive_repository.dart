import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/digestive/domain/digestive_repository.dart';

class LiveDigestiveRepository implements DigestiveRepository {
  const LiveDigestiveRepository();

  @override
  DigestiveViewData load([ViewState desiredState = ViewState.normal]) {
    return DigestiveViewData(
      viewState: desiredState,
      items: const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无消化管理数据',
        ViewState.error => '消化数据加载失败',
        ViewState.forbidden => '无权限查看消化数据',
        ViewState.offline => '离线：展示已缓存蠕动数据',
        ViewState.normal => '功能开发中，敬请期待',
      },
    );
  }

  @override
  DigestiveHealth? loadDetail(String livestockId) {
    return null;
  }
}
