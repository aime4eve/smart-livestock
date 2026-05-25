import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

class LiveFeverRepository implements FeverRepository {
  const LiveFeverRepository();

  @override
  FeverViewData load([ViewState desiredState = ViewState.normal]) {
    return FeverViewData(
      viewState: desiredState,
      items: const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发热预警数据',
        ViewState.error => '发热数据加载失败',
        ViewState.forbidden => '无权限查看发热预警',
        ViewState.offline => '离线：展示已缓存体温数据',
        ViewState.normal => '功能开发中，敬请期待',
      },
    );
  }

  @override
  TemperatureBaseline? loadDetail(String livestockId) {
    return null;
  }
}
