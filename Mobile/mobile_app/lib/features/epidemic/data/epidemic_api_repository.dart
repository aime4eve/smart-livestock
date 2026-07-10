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

  @override
  Future<ContactNetworkResponse> fetchContactNetwork(String livestockId) async {
    final data = await ApiClient.instance.farmGet('/health/epidemic/contacts/$livestockId');
    return ContactNetworkResponse.fromJson(data);
  }

  @override
  Future<void> markDiseased(String livestockId, String diseaseType) async {
    await ApiClient.instance.farmPost(
      '/health/epidemic/mark',
      body: {'livestockId': livestockId, 'diseaseType': diseaseType},
    );
  }

  @override
  Future<void> unmarkDiseased(String livestockId) async {
    await ApiClient.instance.farmDelete('/health/epidemic/mark/$livestockId');
  }
}
