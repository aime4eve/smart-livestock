import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantLogsController extends Notifier<TenantLogsViewData> {
  TenantLogsController(this.id);

  final String id;

  @override
  TenantLogsViewData build() {
    return ref.watch(tenantRepositoryProvider).loadLogs(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadLogs(id);
  }
}

final tenantLogsControllerProvider = NotifierProvider.family<
    TenantLogsController, TenantLogsViewData, String>(
  TenantLogsController.new,
);
