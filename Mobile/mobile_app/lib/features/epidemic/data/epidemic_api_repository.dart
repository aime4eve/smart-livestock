import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/epidemic/domain/epidemic_repository.dart';

class EpidemicApiRepository implements EpidemicRepository {
  const EpidemicApiRepository();

  @override
  Future<EpidemicData> fetchEpidemicOverview() async {
    final data = await ApiClient.instance.farmGet('/health/epidemic');
    return EpidemicData.fromJson(data);
  }
}
