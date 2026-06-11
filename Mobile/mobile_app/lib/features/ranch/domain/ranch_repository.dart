import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';

abstract class RanchRepository {
  Future<RanchOverview> loadOverview();
  Future<void> markRead(String alertId);
  Future<void> dismiss(String alertId);
  Future<void> batchRead(List<String> alertIds);
}
