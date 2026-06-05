import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

class TwinOverviewApiRepository implements TwinOverviewRepository {
  const TwinOverviewApiRepository();

  @override
  Future<HealthOverviewResponse> load() async {
    final data = await ApiClient.instance.farmGet('/health/overview');
    return HealthOverviewResponse.fromJson(data);
  }
}
