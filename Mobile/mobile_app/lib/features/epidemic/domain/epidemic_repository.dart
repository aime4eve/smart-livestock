import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class EpidemicRepository {
  Future<EpidemicData> fetchEpidemicOverview();
  Future<ContactNetworkResponse> fetchContactNetwork(String livestockId);
  Future<EpidemicWorkbenchData> fetchWorkbench({
    String? sourceLivestockId,
    required int windowHours,
    int maxDepth,
  });
  Future<int> createDisposition({
    required String livestockId,
    required String sourceLivestockId,
    required String actionCode,
    int? eventId,
  });
  Future<void> completeDisposition(int dispositionId);
  Future<void> markDiseased(String livestockId, String diseaseType);
  Future<void> unmarkDiseased(String livestockId);
}
