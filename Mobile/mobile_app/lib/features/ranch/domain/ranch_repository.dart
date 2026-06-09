import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';

abstract class RanchRepository {
  Future<RanchOverview> loadOverview();
}
