import 'package:smart_livestock_demo/core/models/health_models.dart';

abstract class EstrusRepository {
  Future<List<EstrusListItem>> fetchEstrusList();
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId);
}
