import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/license/data/deployment_license_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/license/domain/deployment_license_models.dart';

final deploymentLicenseRepositoryProvider = Provider<DeploymentLicenseApiRepository>(
  (ref) => const DeploymentLicenseApiRepository(),
);

/// Standalone mode loader for surfaces that only need mode awareness
/// (e.g. the hosted pilot-license entry on the subscriptions page).
final licenseModeProvider = FutureProvider<LicenseModeInfo>((ref) async {
  return ref.watch(deploymentLicenseRepositoryProvider).loadMode();
});

/// View state of the deployment-license page: deployment mode, tenant
/// dropdown, per-tenant enrollment info and current license/runtime status,
/// plus the outcome of the last import.
@immutable
class DeploymentLicenseViewState {
  const DeploymentLicenseViewState({
    this.mode,
    this.tenants = const [],
    this.selectedTenantId,
    this.enrollment,
    this.current,
    this.lastImport,
  });

  final LicenseModeInfo? mode;
  final List<DeploymentTenantOption> tenants;
  final int? selectedTenantId;
  final EnrollmentInfo? enrollment;
  final DeploymentLicenseStatus? current;

  /// Result of the last successful import (drives the success banner).
  final ImportLicenseResult? lastImport;

  bool get isOnprem => mode?.isOnprem ?? false;
  bool get isHosted => mode?.isHosted ?? false;

  DeploymentLicenseViewState copyWith({
    LicenseModeInfo? mode,
    List<DeploymentTenantOption>? tenants,
    int? selectedTenantId,
    EnrollmentInfo? enrollment,
    DeploymentLicenseStatus? current,
    ImportLicenseResult? lastImport,
    bool clearLastImport = false,
  }) =>
      DeploymentLicenseViewState(
        mode: mode ?? this.mode,
        tenants: tenants ?? this.tenants,
        selectedTenantId: selectedTenantId ?? this.selectedTenantId,
        enrollment: enrollment ?? this.enrollment,
        current: current ?? this.current,
        lastImport: clearLastImport ? null : (lastImport ?? this.lastImport),
      );
}

/// Controller of the deployment-license page. Platform-global surface:
/// a plain AsyncNotifier, deliberately NOT farm-scoped.
class DeploymentLicenseController
    extends AsyncNotifier<DeploymentLicenseViewState> {
  @override
  Future<DeploymentLicenseViewState> build() async {
    final repo = ref.read(deploymentLicenseRepositoryProvider);
    final mode = await repo.loadMode();
    final tenants = await repo.loadTenants();
    var view = DeploymentLicenseViewState(mode: mode, tenants: tenants);
    // ONPREM only: preselect the first tenant so enrollment/status render
    // immediately. HOSTED needs no tenant context.
    if (mode.isOnprem && tenants.isNotEmpty) {
      view = await _loadTenantDetail(view, tenants.first.id);
    }
    return view;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Switch the dropdown selection and reload enrollment + current status.
  Future<void> selectTenant(int tenantId) async {
    final view = state.value ?? const DeploymentLicenseViewState();
    if (view.selectedTenantId == tenantId) return;
    state = AsyncData(view.copyWith(clearLastImport: true));
    try {
      final updated = await _loadTenantDetail(view, tenantId);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Import the picked `.sllicense` envelope for the selected tenant, then
  /// refresh enrollment/status so the cards reflect the new runtime state.
  /// Rethrows on failure (page shows a failure SnackBar).
  Future<ImportLicenseResult> importLicense(
    List<int> bytes,
    String fileName,
  ) async {
    final view = state.value;
    final tenantId = view?.selectedTenantId;
    if (view == null || tenantId == null) {
      throw StateError('No tenant selected');
    }
    final repo = ref.read(deploymentLicenseRepositoryProvider);
    final result = await repo.importLicense(tenantId, bytes, fileName);
    final updated = await _loadTenantDetail(
      view.copyWith(clearLastImport: true),
      tenantId,
    );
    state = AsyncData(updated.copyWith(lastImport: result));
    return result;
  }

  Future<DeploymentLicenseViewState> _loadTenantDetail(
    DeploymentLicenseViewState view,
    int tenantId,
  ) async {
    final repo = ref.read(deploymentLicenseRepositoryProvider);
    final results = await Future.wait([
      repo.loadEnrollment(tenantId),
      repo.loadCurrent(tenantId),
    ]);
    return view.copyWith(
      selectedTenantId: tenantId,
      enrollment: results[0] as EnrollmentInfo,
      current: results[1] as DeploymentLicenseStatus,
    );
  }
}

final deploymentLicenseControllerProvider = AsyncNotifierProvider<
    DeploymentLicenseController, DeploymentLicenseViewState>(
  DeploymentLicenseController.new,
);
