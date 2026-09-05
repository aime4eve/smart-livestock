import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';

/// Public deployment descriptor from `GET /api/v1/deployment-info`
/// (unauthenticated; consumed by the login screen badge).
class DeploymentInfo {
  final String mode; // HOSTED | ONPREM
  final String? runtimeStatus; // ONPREM only: PENDING_ACTIVATION/VALID/EXPIRED/SUSPENDED

  const DeploymentInfo({required this.mode, this.runtimeStatus});

  bool get isOnprem => mode == 'ONPREM';
}

/// Fetches the deployment info before login. Any failure (old backend,
/// network) degrades to null so the badge is hidden and login never blocks.
final deploymentInfoProvider =
    FutureProvider<DeploymentInfo?>((ref) async {
  try {
    final data = await ApiClient.instance.get('/deployment-info');
    return DeploymentInfo(
      mode: data['mode'] as String,
      runtimeStatus: data['runtimeStatus'] as String?,
    );
  } catch (_) {
    return null;
  }
});
