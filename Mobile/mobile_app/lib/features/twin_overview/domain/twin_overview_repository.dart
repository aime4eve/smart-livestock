import 'package:hkt_livestock_agentic/core/models/health_models.dart';

abstract class TwinOverviewRepository {
  Future<HealthOverviewResponse> load();
}
