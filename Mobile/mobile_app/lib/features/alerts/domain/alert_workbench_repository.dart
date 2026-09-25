import 'alert_workbench.dart';

abstract class AlertWorkbenchRepository {
  Future<AlertWorkbenchData> load({
    String bucket = 'all',
    Set<String> asset = const {'all'},
    String? fenceId,
    int page = 1,
    int pageSize = 50,
  });
}
