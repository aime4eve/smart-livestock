import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/calving/domain/calving_repository.dart';

class CalvingApiRepository implements CalvingRepository {
  const CalvingApiRepository();

  @override
  Future<List<CalvingPredictionItem>> fetchCalvingPredictions() async {
    // Envelope is unwrapped by ApiClient: data = {items: [...]}, riskScore
    // descending, backend default limit=200.
    final data = await ApiClient.instance.farmGet('/livestock/calving-predictions');
    final items = data['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CalvingPredictionItem.fromJson)
        .toList();
  }
}
