import 'package:smart_livestock_demo/core/models/user_role.dart';

class RolePermission {
  const RolePermission._();

  static bool canEditFence(UserRole role) {
    return role == UserRole.owner;
  }

  static bool canAddFence(UserRole role) => canEditFence(role);

  static bool canDeleteFence(UserRole role) => canEditFence(role);

  static bool canAcknowledgeAlert(UserRole role) {
    return role == UserRole.owner || role == UserRole.worker;
  }

  static bool canHandleAlert(UserRole role) => role == UserRole.owner;

  static bool canArchiveAlert(UserRole role) => role == UserRole.owner;

  static bool canBatchAlerts(UserRole role) => role == UserRole.owner;

  static bool canTwinBreedingAction(UserRole role) => role == UserRole.owner;

  static bool canManageTenants(UserRole role) =>
      role == UserRole.owner || role == UserRole.platformAdmin;

  static bool canCreateTenant(UserRole role) => canManageTenants(role);

  static bool canEditTenant(UserRole role) => canManageTenants(role);

  static bool canDeleteTenant(UserRole role) => canManageTenants(role);

  static bool canToggleTenantStatus(UserRole role) => canManageTenants(role);

  static bool canAdjustLicense(UserRole role) => canManageTenants(role);

  static bool canManageSubscription(UserRole role) =>
      role == UserRole.owner;

  static bool canViewContract(UserRole role) => role == UserRole.b2bAdmin;

  static bool canCreateFarm(UserRole role) =>
      role == UserRole.b2bAdmin || role == UserRole.platformAdmin;

  static bool canViewB2bDashboard(UserRole role) => role == UserRole.b2bAdmin;

  static bool canManageContracts(UserRole role) =>
      role == UserRole.platformAdmin;

  static bool canViewRevenue(UserRole role) =>
      role == UserRole.platformAdmin || role == UserRole.b2bAdmin;

  static bool canCalculateRevenue(UserRole role) =>
      role == UserRole.platformAdmin;

  static bool canManageSubscriptionServices(UserRole role) =>
      role == UserRole.platformAdmin;

  static bool canReviewApiAuthorizations(UserRole role) =>
      role == UserRole.platformAdmin || role == UserRole.owner;

  static bool canManageSubfarmWorkers(UserRole role) =>
      role == UserRole.b2bAdmin;
}
