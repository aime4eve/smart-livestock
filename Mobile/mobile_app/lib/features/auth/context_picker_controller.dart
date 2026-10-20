import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';

/// Selectable entry role from GET /auth/entry-contexts (design 2026-10-19
/// §4.3). [role] is the wire name, e.g. 'OWNER'.
class EntryRoleOption {
  const EntryRoleOption({required this.role, required this.tenantScoped});
  final String role;
  final bool tenantScoped;
}

/// Tenant option for the picker's second step. [status] is active|disabled
/// (deleted tenants never appear); [trialExpired] mirrors the switch gate so
/// the row can be greyed out client-side.
class TenantOption {
  const TenantOption({
    required this.id,
    required this.name,
    required this.status,
    required this.phase,
    required this.timezone,
    required this.farmCount,
    required this.trialExpired,
  });

  final int id;
  final String name;
  final String status;
  final String phase;
  final String? timezone;
  final int farmCount;
  final bool trialExpired;

  bool get disabled => status == 'disabled';
  bool get enterable => !trialExpired;
}

class ContextPickerState {
  const ContextPickerState({
    this.loading = false,
    this.loadFailed = false,
    this.roles = const [],
    this.tenants = const [],
    this.selectedRole,
    this.selectedTenant,
    this.switching = false,
  });

  final bool loading;
  final bool loadFailed;
  final List<EntryRoleOption> roles;
  final List<TenantOption> tenants;
  final EntryRoleOption? selectedRole;
  final TenantOption? selectedTenant;
  final bool switching;

  ContextPickerState copyWith({
    bool? loading,
    bool? loadFailed,
    List<EntryRoleOption>? roles,
    List<TenantOption>? tenants,
    EntryRoleOption? selectedRole,
    bool clearSelectedRole = false,
    TenantOption? selectedTenant,
    bool clearSelectedTenant = false,
    bool? switching,
  }) {
    return ContextPickerState(
      loading: loading ?? this.loading,
      loadFailed: loadFailed ?? this.loadFailed,
      roles: roles ?? this.roles,
      tenants: tenants ?? this.tenants,
      selectedRole:
          clearSelectedRole ? null : (selectedRole ?? this.selectedRole),
      selectedTenant:
          clearSelectedTenant ? null : (selectedTenant ?? this.selectedTenant),
      switching: switching ?? this.switching,
    );
  }
}

class ContextPickerController extends Notifier<ContextPickerState> {
  @override
  ContextPickerState build() {
    Future.microtask(load);
    return const ContextPickerState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, loadFailed: false);
    try {
      final data = await ApiClient.instance.entryContexts();
      final roles = (data['roles'] as List? ?? const [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            return EntryRoleOption(
              role: m['role'] as String,
              tenantScoped: m['tenantScoped'] == true,
            );
          })
          .toList();
      final tenants = (data['tenants'] as List? ?? const [])
          .map((e) {
            final m = e as Map<String, dynamic>;
            return TenantOption(
              id: (m['id'] as num).toInt(),
              name: m['name'] as String? ?? '',
              status: m['status'] as String? ?? 'active',
              phase: m['phase'] as String? ?? '',
              timezone: m['timezone'] as String?,
              farmCount: (m['farmCount'] as num? ?? 0).toInt(),
              trialExpired: m['trialExpired'] == true,
            );
          })
          .toList();
      state = state.copyWith(loading: false, roles: roles, tenants: tenants);
    } catch (_) {
      state = state.copyWith(loading: false, loadFailed: true);
    }
  }

  void selectRole(EntryRoleOption role) {
    state = state.copyWith(selectedRole: role, clearSelectedTenant: true);
  }

  void selectTenant(TenantOption tenant) {
    state = state.copyWith(selectedTenant: tenant);
  }

  /// Issues the context switch via the session controller. Returns null on
  /// success, otherwise a user-facing error message.
  Future<String?> confirmEnter() async {
    final role = state.selectedRole;
    if (role == null) return '';
    final tenant = state.selectedTenant;
    state = state.copyWith(switching: true);
    final error = await ref.read(sessionControllerProvider.notifier)
        .enterContext(
          role: role.role,
          tenantId: role.tenantScoped ? tenant?.id : null,
          tenantName: role.tenantScoped ? tenant?.name : null,
        );
    state = state.copyWith(switching: false);
    return error;
  }
}

final contextPickerControllerProvider =
    NotifierProvider<ContextPickerController, ContextPickerState>(
        ContextPickerController.new);
