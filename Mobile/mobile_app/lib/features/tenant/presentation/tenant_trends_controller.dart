import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantTrendsController extends Notifier<TenantTrendsViewData> {
  TenantTrendsController(this.id);

  final String id;

  @override
  TenantTrendsViewData build() {
    return ref.watch(tenantRepositoryProvider).loadTrends(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadTrends(id);
  }
}

final tenantTrendsControllerProvider = NotifierProvider.family<
    TenantTrendsController, TenantTrendsViewData, String>(
  TenantTrendsController.new,
);
