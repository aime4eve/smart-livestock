import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_logs_controller.dart';

void main() {
  test('Logs Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantLogsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.logs.isNotEmpty, isTrue);
    expect(data.total, greaterThanOrEqualTo(data.logs.length));
  });

  test('Logs Controller 日志条目有非空字段', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantLogsControllerProvider('tenant_001'));
    for (final log in data.logs) {
      expect(log.id.isNotEmpty, isTrue);
      expect(log.action.isNotEmpty, isTrue);
      expect(log.operator.isNotEmpty, isTrue);
    }
  });
}
