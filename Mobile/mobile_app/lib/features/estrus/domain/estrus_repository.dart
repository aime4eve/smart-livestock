import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class EstrusRepository {
  Future<List<EstrusListItem>> fetchEstrusList();
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId);
}
