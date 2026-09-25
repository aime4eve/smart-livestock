import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench_repository.dart';

class AlertWorkbenchApiRepository implements AlertWorkbenchRepository {
  const AlertWorkbenchApiRepository();

  @override
  Future<AlertWorkbenchData> load({
    String bucket = 'all',
    Set<String> asset = const {'all'},
    String? fenceId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final assets = asset.isEmpty ? 'all' : asset.join(',');
    var path = '/alerts/workbench'
        '?bucket=${Uri.encodeQueryComponent(bucket)}'
        '&asset=${Uri.encodeQueryComponent(assets)}'
        '&page=$page&pageSize=$pageSize';
    if (fenceId != null && fenceId.isNotEmpty) {
      path += '&fenceId=${Uri.encodeQueryComponent(fenceId)}';
    }
    final data = await ApiClient.instance.farmGet(path);
    return AlertWorkbenchJson.fromMap(data);
  }
}
