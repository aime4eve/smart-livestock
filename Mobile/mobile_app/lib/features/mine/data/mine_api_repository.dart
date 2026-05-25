import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

class MineApiRepository implements MineRepository {
  const MineApiRepository();

  @override
  Future<MineViewData> load() async {
    try {
      final data = await ApiClient.instance.get('/me');
      final name = data['name'] as String? ?? data['phone'] as String? ?? '用户';
      return MineViewData(normalText: '欢迎，$name');
    } catch (_) {
      return const MineViewData(normalText: '我的');
    }
  }
}
