import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/tenant/data/live_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockTenantRepository();
    case AppMode.live:
      return LiveTenantRepository();
  }
});

class TenantListController extends Notifier<TenantListViewData> {
  @override
  TenantListViewData build() {
    return ref.watch(tenantRepositoryProvider).loadList(const TenantListQuery());
  }

  void _reload(TenantListQuery query) {
    state = ref.read(tenantRepositoryProvider).loadList(query);
  }

  void setSearch(String? value) {
    _reload(state.query.copyWith(
      search: value,
      page: 1,
      clearSearch: value == null || value.isEmpty,
    ));
  }

  void setStatus(TenantStatus? status) {
    _reload(state.query.copyWith(
      status: status,
      page: 1,
      clearStatus: status == null,
    ));
  }

  void setSort(TenantSort sort, SortOrder order) {
    _reload(state.query.copyWith(sort: sort, order: order, page: 1));
  }

  void setPage(int page) {
    _reload(state.query.copyWith(page: page));
  }

  void refresh() {
    _reload(state.query);
  }
}

final tenantListControllerProvider =
    NotifierProvider<TenantListController, TenantListViewData>(
  TenantListController.new,
);
