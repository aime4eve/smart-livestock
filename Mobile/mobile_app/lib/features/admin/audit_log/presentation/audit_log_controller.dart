import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/admin/audit_log/data/audit_log_api_repository.dart';
import 'package:smart_livestock_demo/features/admin/audit_log/domain/audit_log_models.dart';

final auditLogRepositoryProvider = Provider<AuditLogApiRepository>(
  (_) => const AuditLogApiRepository(),
);

class AuditLogFilter {
  const AuditLogFilter({
    this.action,
    this.startTime,
    this.endTime,
  });
  final String? action;
  final String? startTime;
  final String? endTime;
}

class AuditLogController extends AsyncNotifier<AuditLogListResult> {
  @override
  Future<AuditLogListResult> build() async {
    return ref.read(auditLogRepositoryProvider).load();
  }

  Future<void> refresh({AuditLogFilter? filter, int page = 1}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(auditLogRepositoryProvider).load(
      page: page,
      action: filter?.action,
      startTime: filter?.startTime,
      endTime: filter?.endTime,
    ));
  }
}

final auditLogControllerProvider =
    AsyncNotifierProvider<AuditLogController, AuditLogListResult>(
  AuditLogController.new,
);
