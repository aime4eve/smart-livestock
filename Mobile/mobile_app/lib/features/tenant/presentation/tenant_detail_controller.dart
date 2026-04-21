import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantDetailController
    extends FamilyNotifier<TenantDetailViewData, String> {
  @override
  TenantDetailViewData build(String id) {
    return ref.watch(tenantRepositoryProvider).loadDetail(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadDetail(arg);
  }
}

final tenantDetailControllerProvider = NotifierProvider.family<
    TenantDetailController, TenantDetailViewData, String>(
  TenantDetailController.new,
);
