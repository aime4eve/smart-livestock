import 'package:smart_livestock_demo/core/models/health_models.dart';

abstract class TwinOverviewRepository {
  Future<HealthOverviewResponse> load();
}
