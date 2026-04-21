import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/data/tenant_dto.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

void main() {
  test('TenantDto 完整 JSON 解析为 Tenant', () {
    final t = TenantDto.fromJson({
      'id': 'tenant_001',
      'name': '测试牧场',
      'status': 'active',
      'licenseUsed': 10,
      'licenseTotal': 100,
    });
    expect(t, isNotNull);
    expect(t!.name, '测试牧场');
    expect(t.status, TenantStatus.active);
    expect(t.licenseUsage, closeTo(0.1, 1e-9));
  });

  test('TenantDto 非法 status 返回 null', () {
    final t = TenantDto.fromJson({
      'id': 'x',
      'name': 'x',
      'status': 'xxx',
      'licenseUsed': 0,
      'licenseTotal': 0,
    });
    expect(t, isNull);
  });
}
