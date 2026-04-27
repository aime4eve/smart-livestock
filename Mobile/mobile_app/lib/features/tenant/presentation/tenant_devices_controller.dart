import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantDevicesController extends Notifier<TenantDevicesViewData> {
  TenantDevicesController(this.id);

  final String id;

  @override
  TenantDevicesViewData build() {
    return ref.watch(tenantRepositoryProvider).loadDevices(id);
  }

  void refresh() {
    state = ref.read(tenantRepositoryProvider).loadDevices(id);
  }
}

final tenantDevicesControllerProvider = NotifierProvider.family<
    TenantDevicesController, TenantDevicesViewData, String>(
  TenantDevicesController.new,
);
