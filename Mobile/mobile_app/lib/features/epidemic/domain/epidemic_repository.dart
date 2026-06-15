import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class EpidemicRepository {
  Future<EpidemicData> fetchEpidemicOverview();
  Future<ContactNetworkResponse> fetchContactNetwork(String livestockId);
  Future<void> markDiseased(String livestockId, String diseaseType);
  Future<void> unmarkDiseased(String livestockId);
}
