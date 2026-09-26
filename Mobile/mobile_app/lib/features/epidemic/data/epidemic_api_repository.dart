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
  Future<EpidemicWorkbenchData> fetchWorkbench({
    String? sourceLivestockId,
    required int windowHours,
    int maxDepth = 2,
  }) async {
    final query = <String>[
      'windowHours=$windowHours',
      'maxDepth=$maxDepth',
      if (sourceLivestockId?.isNotEmpty == true) 'sourceLivestockId=$sourceLivestockId',
    ].join('&');
    final data = await ApiClient.instance.farmGet('/health/epidemic/workbench?$query');
    return EpidemicWorkbenchData.fromJson(data);
  }

  @override
  Future<int> createDisposition({
    required String livestockId,
    required String sourceLivestockId,
    required String actionCode,
    int? eventId,
  }) async {
    final data = await ApiClient.instance.farmPost(
      '/health/epidemic/dispositions',
      body: {
        'livestockId': int.tryParse(livestockId),
        'sourceLivestockId': int.tryParse(sourceLivestockId),
        'actionCode': actionCode,
        if (eventId != null) 'eventId': eventId,
      },
    );
    return (data['id'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> completeDisposition(int dispositionId) async {
    await ApiClient.instance.farmPost('/health/epidemic/dispositions/$dispositionId/complete');
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
