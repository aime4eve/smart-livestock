import '../../../core/api/api_client.dart';
import '../domain/gateway_models.dart';

/// Gateway registry API (NIX-219): discovery + global-unique position marking,
/// plus the F10 admin reconciliation overview.
class GatewayApiRepository {
  const GatewayApiRepository();

  Future<List<GatewayDiscoveryItem>> discover(String farmId) async {
    // Backend returns a bare array -> ApiClient wraps it as {'value': [...]}.
    final data = await ApiClient.instance.farmGet('/gateways', farmId: farmId);
    final items = data['value'] as List? ?? const [];
    return items
        .map((e) => GatewayDiscoveryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MarkPositionResult> markPosition(
    String farmId,
    String gatewayId, {
    required double latitude,
    required double longitude,
  }) async {
    final data = await ApiClient.instance.farmPut(
      '/gateways/$gatewayId/position',
      body: {'latitude': latitude, 'longitude': longitude},
      farmId: farmId,
    );
    final payload = (data['data'] as Map?) ?? const {};
    return MarkPositionResult(
      overwritten: payload['overwritten'] == true,
      gatewayId: (payload['gatewayId'] as String?) ?? gatewayId,
      latitude: (payload['latitude'] as num?)?.toDouble() ?? latitude,
      longitude: (payload['longitude'] as num?)?.toDouble() ?? longitude,
    );
  }

  /// F10 admin overview: GET /api/v1/admin/gateways/overview.
  Future<Map<String, dynamic>> adminOverview() =>
      ApiClient.instance.get('/admin/gateways/overview');

  /// F8 coverage diagnostics: GET /api/v1/farms/{farmId}/coverage-diagnostics.
  Future<Map<String, dynamic>> coverageDiagnostics(String farmId) =>
      ApiClient.instance.farmGet('/coverage-diagnostics', farmId: farmId);
}
