import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class DigestiveRepository {
  Future<List<DigestiveListItem>> fetchDigestiveList();
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId);
}
