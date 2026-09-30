import 'package:hkt_livestock_agentic/core/models/health_models.dart';

/// Outcome of registering a disposition task: [created] distinguishes a fresh
/// registration from the idempotent "already has an active task" response, so
/// the UI can phrase the toast correctly.
class DispositionRegistration {
  const DispositionRegistration({required this.created, required this.id});
  final bool created;
  final int id;
}

abstract class EpidemicRepository {
  Future<EpidemicData> fetchEpidemicOverview();
  Future<ContactNetworkResponse> fetchContactNetwork(String livestockId);
  Future<EpidemicWorkbenchData> fetchWorkbench({
    String? sourceLivestockId,
    required int windowHours,
    int maxDepth,
  });
  Future<DispositionRegistration> createDisposition({
    required String livestockId,
    required String sourceLivestockId,
    required String actionCode,
    int? eventId,
  });
  Future<void> completeDisposition(int dispositionId);
  Future<void> cancelDisposition(int dispositionId, {String? reason});
  Future<MarkDiseasedResult> markDiseased(
    String livestockId,
    String diseaseType, {
    int? windowHours,
  });
  Future<void> unmarkDiseased(String livestockId);
}
