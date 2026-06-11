import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_repository.dart';

class RanchApiRepository implements RanchRepository {
  const RanchApiRepository();

  @override
  Future<RanchOverview> loadOverview() async {
    final data = await ApiClient.instance.farmGet('/ranch-overview');
    return RanchOverview.fromJson(data);
  }

  @override
  Future<void> markRead(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/read');
  }

  @override
  Future<void> dismiss(String alertId) async {
    await ApiClient.instance.farmPost('/alerts/$alertId/dismiss');
  }

  @override
  Future<void> batchRead(List<String> alertIds) async {
    await ApiClient.instance
        .farmPost('/alerts/batch-read', body: {'alertIds': alertIds});
  }
}
