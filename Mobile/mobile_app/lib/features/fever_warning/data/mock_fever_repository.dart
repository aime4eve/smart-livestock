import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

class MockFeverRepository implements FeverRepository {
  const MockFeverRepository();

  @override
  FeverViewData load([ViewState desiredState = ViewState.normal]) {
    return FeverViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? TwinSeed.feverBaselines : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发热预警数据',
        ViewState.error => '发热数据加载失败（演示）',
        ViewState.forbidden => '无权限查看发热预警（演示）',
        ViewState.offline => '离线：展示已缓存体温数据（演示）',
        ViewState.normal => null,
      },
    );
  }

  @override
  TemperatureBaseline? loadDetail(String livestockId) {
    for (final b in TwinSeed.feverBaselines) {
      if (b.livestockId == livestockId) return b;
    }
    return null;
  }
}
