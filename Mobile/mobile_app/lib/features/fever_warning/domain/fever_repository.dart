import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class FeverRepository {
  Future<List<FeverListItem>> fetchFeverList();
  Future<FeverDetailData> fetchFeverDetail(String livestockId);
}
