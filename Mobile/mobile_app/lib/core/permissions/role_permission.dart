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
}
