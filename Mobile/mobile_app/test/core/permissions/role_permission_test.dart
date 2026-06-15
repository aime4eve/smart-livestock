import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';

void main() {
  final allRoles = UserRole.values;

  group('围栏权限', () {
    for (final role in allRoles) {
      test('$role 编辑围栏 ${RolePermission.canEditFence(role)}', () {
        expect(RolePermission.canEditFence(role), role == UserRole.owner);
      });
      test('$role 添加围栏 ${RolePermission.canAddFence(role)}', () {
        expect(RolePermission.canAddFence(role), role == UserRole.owner);
      });
      test('$role 删除围栏 ${RolePermission.canDeleteFence(role)}', () {
        expect(RolePermission.canDeleteFence(role), role == UserRole.owner);
      });
    }
  });

  group('告警权限', () {
    for (final role in allRoles) {
      final canAck = role == UserRole.owner || role == UserRole.worker;
      test('$role 确认告警 $canAck', () {
        expect(RolePermission.canAcknowledgeAlert(role), canAck);
      });

      test('$role 处理告警 ${role == UserRole.owner}', () {
        expect(RolePermission.canHandleAlert(role), role == UserRole.owner);
      });

      test('$role 归档告警 ${role == UserRole.owner}', () {
        expect(RolePermission.canArchiveAlert(role), role == UserRole.owner);
      });

      test('$role 批量告警 ${role == UserRole.owner}', () {
        expect(RolePermission.canBatchAlerts(role), role == UserRole.owner);
      });
    }
  });

  group('租户权限', () {
    for (final role in allRoles) {
      final canManage = role == UserRole.owner || role == UserRole.platformAdmin;
      test('$role 管理租户 $canManage', () {
        expect(RolePermission.canManageTenants(role), canManage);
      });
      test('$role 创建租户 $canManage', () {
        expect(RolePermission.canCreateTenant(role), canManage);
      });
      test('$role 编辑租户 $canManage', () {
        expect(RolePermission.canEditTenant(role), canManage);
      });
      test('$role 删除租户 $canManage', () {
        expect(RolePermission.canDeleteTenant(role), canManage);
      });
      test('$role 切换租户状态 $canManage', () {
        expect(RolePermission.canToggleTenantStatus(role), canManage);
      });
      test('$role 调整License $canManage', () {
        expect(RolePermission.canAdjustLicense(role), canManage);
      });
    }
  });

  group('订阅权限', () {
    for (final role in allRoles) {
      test('$role 管理订阅 ${role == UserRole.owner}', () {
        expect(RolePermission.canManageSubscription(role), role == UserRole.owner);
      });
    }
  });

  group('牧场权限', () {
    for (final role in allRoles) {
      final canCreate = role == UserRole.b2bAdmin || role == UserRole.platformAdmin;
      test('$role 创建牧场 $canCreate', () {
        expect(RolePermission.canCreateFarm(role), canCreate);
      });
    }
  });

  group('B端权限', () {
    for (final role in allRoles) {
      test('$role 查看B端看板 ${role == UserRole.b2bAdmin}', () {
        expect(RolePermission.canViewB2bDashboard(role), role == UserRole.b2bAdmin);
      });
      test('$role 查看合同 ${role == UserRole.b2bAdmin}', () {
        expect(RolePermission.canViewContract(role), role == UserRole.b2bAdmin);
      });
      test('$role 管理旗下牧工 ${role == UserRole.b2bAdmin}', () {
        expect(RolePermission.canManageSubfarmWorkers(role), role == UserRole.b2bAdmin);
      });
    }
  });

  group('平台权限', () {
    for (final role in allRoles) {
      test('$role 管理合同 ${role == UserRole.platformAdmin}', () {
        expect(RolePermission.canManageContracts(role), role == UserRole.platformAdmin);
      });
      final canViewRevenue = role == UserRole.platformAdmin || role == UserRole.b2bAdmin;
      test('$role 查看对账 $canViewRevenue', () {
        expect(RolePermission.canViewRevenue(role), canViewRevenue);
      });
      test('$role 计算分润 ${role == UserRole.platformAdmin}', () {
        expect(RolePermission.canCalculateRevenue(role), role == UserRole.platformAdmin);
      });
      test('$role 管理订阅服务 ${role == UserRole.platformAdmin}', () {
        expect(RolePermission.canManageSubscriptionServices(role), role == UserRole.platformAdmin);
      });
    }
  });

  group('API授权权限', () {
    for (final role in allRoles) {
      final canReview = role == UserRole.platformAdmin || role == UserRole.owner;
      test('$role 审批API授权 $canReview', () {
        expect(RolePermission.canReviewApiAuthorizations(role), canReview);
      });
    }
  });

  group('数智孪生权限', () {
    for (final role in allRoles) {
      test('$role 繁育操作 ${role == UserRole.owner}', () {
        expect(RolePermission.canTwinBreedingAction(role), role == UserRole.owner);
      });
    }
  });
}
