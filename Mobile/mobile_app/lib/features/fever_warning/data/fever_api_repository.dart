import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/domain/fever_repository.dart';

class FeverApiRepository implements FeverRepository {
  const FeverApiRepository();

  @override
  Future<List<FeverListItem>> fetchFeverList() async {
    final data = await ApiClient.instance.farmGet('/health/fever');
    final items = data['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FeverListItem.fromJson)
        .toList();
  }

  @override
  Future<FeverDetailData> fetchFeverDetail(String livestockId) async {
    final data = await ApiClient.instance.farmGet('/health/fever/$livestockId');
    return FeverDetailData.fromJson(data);
  }

 @override
 Future<List<DailyFeverHour>> fetchFeverDuration(String livestockId) async {
   final data = await ApiClient.instance.farmGet('/health/fever/$livestockId/duration');
    final items = (data['value'] ?? data['items']) as List? ?? [];
   return items
       .whereType<Map<String, dynamic>>()
       .map(DailyFeverHour.fromJson)
       .toList();
 }
}
