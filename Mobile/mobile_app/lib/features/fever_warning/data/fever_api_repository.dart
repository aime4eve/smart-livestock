import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

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
}
