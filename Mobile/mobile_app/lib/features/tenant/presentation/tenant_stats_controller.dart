import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantStatsController extends Notifier<TenantStatsViewData> {
  TenantStatsController(this.id);

  final String id;

  @override
  TenantStatsViewData build() {
    return ref.watch(tenantRepositoryProvider).loadStats(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadStats(id);
  }
}

final tenantStatsControllerProvider = NotifierProvider.family<
    TenantStatsController, TenantStatsViewData, String>(
  TenantStatsController.new,
);
