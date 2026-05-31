import 'package:smart_livestock_demo/core/models/health_models.dart';

abstract class FeverRepository {
  Future<List<FeverListItem>> fetchFeverList();
  Future<FeverDetailData> fetchFeverDetail(String livestockId);
}
