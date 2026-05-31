import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/epidemic/domain/epidemic_repository.dart';

class EpidemicApiRepository implements EpidemicRepository {
  const EpidemicApiRepository();

  @override
  Future<EpidemicData> fetchEpidemicOverview() async {
    final data = await ApiClient.instance.farmGet('/health/epidemic');
    return EpidemicData.fromJson(data);
  }
}
