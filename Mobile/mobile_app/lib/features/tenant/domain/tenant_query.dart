import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

enum TenantSort { name, licenseUsage }

enum SortOrder { asc, desc }

class TenantListQuery {
  const TenantListQuery({
    this.search,
    this.status,
    this.sort = TenantSort.name,
    this.order = SortOrder.asc,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? search;
  final TenantStatus? status;
  final TenantSort sort;
  final SortOrder order;
  final int page;
  final int pageSize;

  TenantListQuery copyWith({
    String? search,
    TenantStatus? status,
    TenantSort? sort,
    SortOrder? order,
    int? page,
    int? pageSize,
    bool clearSearch = false,
    bool clearStatus = false,
  }) {
    return TenantListQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      sort: sort ?? this.sort,
      order: order ?? this.order,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
