import 'package:smart_livestock_demo/core/models/demo_role.dart';

class RolePermission {
  const RolePermission._();

  static bool canEditFence(DemoRole role) {
    return role == DemoRole.owner;
  }

  static bool canAddFence(DemoRole role) => canEditFence(role);

  static bool canDeleteFence(DemoRole role) => canEditFence(role);

  static bool canAcknowledgeAlert(DemoRole role) {
    return role == DemoRole.owner || role == DemoRole.worker;
  }

  static bool canHandleAlert(DemoRole role) => role == DemoRole.owner;

  static bool canArchiveAlert(DemoRole role) => role == DemoRole.owner;

  static bool canBatchAlerts(DemoRole role) => role == DemoRole.owner;

  static bool canTwinBreedingAction(DemoRole role) => role == DemoRole.owner;

  static bool canManageTenants(DemoRole role) =>
      role == DemoRole.owner || role == DemoRole.platformAdmin;

  static bool canCreateTenant(DemoRole role) => canManageTenants(role);

  static bool canEditTenant(DemoRole role) => canManageTenants(role);

  static bool canDeleteTenant(DemoRole role) => canManageTenants(role);

  static bool canToggleTenantStatus(DemoRole role) => canManageTenants(role);

  static bool canAdjustLicense(DemoRole role) => canManageTenants(role);

  static bool canManageSubscription(DemoRole role) =>
      role == DemoRole.owner;

  static bool canViewContract(DemoRole role) => role == DemoRole.b2bAdmin;

  static bool canCreateFarm(DemoRole role) =>
      role == DemoRole.b2bAdmin || role == DemoRole.platformAdmin;

  static bool canViewB2bDashboard(DemoRole role) => role == DemoRole.b2bAdmin;

  static bool canManageContracts(DemoRole role) =>
      role == DemoRole.platformAdmin;

  static bool canViewRevenue(DemoRole role) =>
      role == DemoRole.platformAdmin || role == DemoRole.b2bAdmin;

  static bool canCalculateRevenue(DemoRole role) =>
      role == DemoRole.platformAdmin;

  static bool canManageSubscriptionServices(DemoRole role) =>
      role == DemoRole.platformAdmin;

  static bool canReviewApiAuthorizations(DemoRole role) =>
      role == DemoRole.platformAdmin || role == DemoRole.owner;

  static bool canManageSubfarmWorkers(DemoRole role) =>
      role == DemoRole.b2bAdmin;
}
