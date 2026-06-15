import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/twin_overview/domain/twin_overview_repository.dart';

class TwinOverviewApiRepository implements TwinOverviewRepository {
  const TwinOverviewApiRepository();

  @override
  Future<HealthOverviewResponse> load() async {
    final data = await ApiClient.instance.farmGet('/health/overview');
    return HealthOverviewResponse.fromJson(data);
  }
}
