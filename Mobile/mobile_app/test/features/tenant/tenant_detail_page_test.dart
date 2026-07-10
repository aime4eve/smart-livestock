import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/features/tenant/presentation/pages/tenant_detail_page.dart';

class _FakeAdminRepository implements AdminRepository {
  final TenantDetail? tenantDetail;
  final AdminListResult<UserSummary>? users;
  final Object? loadError;
  final Object? createError;

  _FakeAdminRepository({
    this.tenantDetail,
    this.users,
    this.loadError,
    this.createError,
  });

  @override
  Future<TenantDetail> loadTenantDetail(String id) async {
    if (loadError != null) throw loadError!;
    return tenantDetail!;
  }

  @override
  Future<AdminListResult<UserSummary>> loadUsers({
    int page = 1,
    int pageSize = 20,
    String? tenantId,
    String? role,
    String? keyword,
  }) async {
    if (loadError != null) throw loadError!;
    return users!;
  }

  @override
  Future<UserSummary> createUser(Map<String, dynamic> body) async {
    if (createError != null) throw createError!;
    return UserSummary(
      id: '99',
      name: body['name'] as String,
      phone: body['phone'] as String,
      role: body['role'] as String,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TenantDetail _testTenant() => const TenantDetail(
      id: '1',
      name: '测试租户',
      contactName: '张三',
      contactPhone: '13800000001',
      phase: 'ACTIVE',
      status: 'active',
      farmCount: 2,
      userCount: 3,
      deviceCount: 5,
    );

AdminListResult<UserSummary> _testUsers() => const AdminListResult(
      items: [
        UserSummary(
          id: '10',
          name: '李B2B',
          phone: '13900139000',
          role: 'B2B_ADMIN',
          status: 'active',
        ),
        UserSummary(
          id: '11',
          name: '王牧主',
          phone: '13800138000',
          role: 'OWNER',
          status: 'active',
        ),
        UserSummary(
          id: '12',
          name: '赵牧工',
          phone: '13700137000',
          role: 'WORKER',
          status: 'disabled',
        ),
      ],
      total: 3,
    );

void main() {
  group('TenantDetailPage', () {
    testWidgets('加载并显示租户信息和用户列表', (tester) async {
      final repo = _FakeAdminRepository(
        tenantDetail: _testTenant(),
        users: _testUsers(),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '1'),
        ),
      ));
      await tester.pumpAndSettle();

      // Tenant info
      expect(find.text('测试租户'), findsOneWidget);
      expect(find.text('联系人: 张三'), findsOneWidget);
      expect(find.text('联系电话: 13800000001'), findsOneWidget);
      expect(find.text('阶段: ACTIVE'), findsOneWidget);
      expect(find.text('牧场: 2 · 用户: 3 · 设备: 5'), findsOneWidget);

      // User list
      expect(find.text('用户列表 (3)'), findsOneWidget);
      expect(find.text('李B2B'), findsOneWidget);
      expect(find.text('王牧主'), findsOneWidget);
      expect(find.text('赵牧工'), findsOneWidget);

      // Role chips
      expect(find.text('B2B_ADMIN'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('WORKER'), findsOneWidget);

      // Action buttons
      expect(find.byKey(const Key('tenant-create-user')), findsOneWidget);
      expect(find.byKey(const Key('tenant-users-refresh')), findsOneWidget);
    });

    testWidgets('加载失败显示错误态和重试按钮', (tester) async {
      final repo = _FakeAdminRepository(
        loadError: Exception('网络错误'),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '999'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('点击新增用户打开 dialog', (tester) async {
      final repo = _FakeAdminRepository(
        tenantDetail: _testTenant(),
        users: _testUsers(),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '1'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tenant-create-user')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create-user-dialog')), findsOneWidget);
      expect(find.byKey(const Key('create-user-phone')), findsOneWidget);
      expect(find.byKey(const Key('create-user-name')), findsOneWidget);
      expect(find.byKey(const Key('create-user-password')), findsOneWidget);
      expect(find.byKey(const Key('create-user-role')), findsOneWidget);
      expect(find.byKey(const Key('create-user-confirm')), findsOneWidget);
    });

    testWidgets('创建用户表单校验手机号', (tester) async {
      final repo = _FakeAdminRepository(
        tenantDetail: _testTenant(),
        users: _testUsers(),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '1'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tenant-create-user')));
      await tester.pumpAndSettle();

      // Submit empty form
      await tester.tap(find.byKey(const Key('create-user-confirm')));
      await tester.pump();

      expect(find.text('手机号不能为空'), findsOneWidget);

      // Enter invalid phone
      await tester.enterText(
          find.byKey(const Key('create-user-phone')), '123');
      await tester.tap(find.byKey(const Key('create-user-confirm')));
      await tester.pump();

      expect(find.text('请输入正确的11位手机号'), findsOneWidget);
    });

    testWidgets('用户启停按钮显示正确状态', (tester) async {
      final repo = _FakeAdminRepository(
        tenantDetail: _testTenant(),
        users: _testUsers(),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '1'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toggle-user-10')), findsOneWidget);
      expect(find.byKey(const Key('toggle-user-12')), findsOneWidget);
    });

    testWidgets('无用户时显示空状态', (tester) async {
      final repo = _FakeAdminRepository(
        tenantDetail: _testTenant(),
        users: const AdminListResult<UserSummary>(items: [], total: 0),
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: TenantDetailPage(id: '1'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('暂无用户'), findsOneWidget);
      expect(find.text('用户列表 (0)'), findsOneWidget);
    });
  });
}
