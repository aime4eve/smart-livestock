import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

abstract class TenantRepository {
  TenantListViewData loadList(TenantListQuery query);
  TenantDetailViewData loadDetail(String id);
}
