import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/estrus/domain/estrus_repository.dart';

class EstrusApiRepository implements EstrusRepository {
  const EstrusApiRepository();

  @override
  Future<List<EstrusListItem>> fetchEstrusList() async {
    final data = await ApiClient.instance.farmGet('/health/estrus');
    final items = data['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(EstrusListItem.fromJson)
        .toList();
  }

  @override
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId) async {
    final data = await ApiClient.instance.farmGet('/health/estrus/$livestockId');
    return EstrusDetailData.fromJson(data);
  }
}
