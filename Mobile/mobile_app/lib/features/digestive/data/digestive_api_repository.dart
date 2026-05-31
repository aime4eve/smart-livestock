import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';
import 'package:smart_livestock_demo/features/digestive/domain/digestive_repository.dart';

class DigestiveApiRepository implements DigestiveRepository {
  const DigestiveApiRepository();

  @override
  Future<List<DigestiveListItem>> fetchDigestiveList() async {
    final data = await ApiClient.instance.farmGet('/health/digestive');
    final items = data['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(DigestiveListItem.fromJson)
        .toList();
  }

  @override
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId) async {
    final data = await ApiClient.instance.farmGet('/health/digestive/$livestockId');
    return DigestiveDetailData.fromJson(data);
  }
}
