import 'package:smart_livestock_demo/core/models/health_models.dart';

abstract class DigestiveRepository {
  Future<List<DigestiveListItem>> fetchDigestiveList();
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId);
}
