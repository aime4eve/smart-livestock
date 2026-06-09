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
}
