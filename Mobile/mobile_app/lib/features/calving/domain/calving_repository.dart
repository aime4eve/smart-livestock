import 'package:hkt_livestock_agentic/core/models/health_models.dart';

/// Calving prediction list data source (NIX-389), mirroring the estrus
/// repository shape. Gating is server-side: a locked calving_warning gate
/// surfaces as a 403 from the API.
abstract class CalvingRepository {
  Future<List<CalvingPredictionItem>> fetchCalvingPredictions();
}
