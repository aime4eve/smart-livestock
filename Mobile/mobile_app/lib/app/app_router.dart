import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/demo_shell.dart';
import 'package:smart_livestock_demo/app/expiry_popup_handler.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/auth/login_page.dart';
import 'package:smart_livestock_demo/features/pages/admin_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_contract_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_dashboard_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_farm_list_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_revenue_detail_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_worker_detail_page.dart';
import 'package:smart_livestock_demo/features/pages/alerts_page.dart';
import 'package:smart_livestock_demo/features/pages/dashboard_page.dart';
import 'package:smart_livestock_demo/features/pages/devices_page.dart';
import 'package:smart_livestock_demo/features/pages/digestive_detail_page.dart';
import 'package:smart_livestock_demo/features/pages/digestive_page.dart';
import 'package:smart_livestock_demo/features/pages/epidemic_page.dart';
import 'package:smart_livestock_demo/features/pages/estrus_detail_page.dart';
import 'package:smart_livestock_demo/features/pages/estrus_page.dart';
import 'package:smart_livestock_demo/features/pages/fence_form_page.dart';
import 'package:smart_livestock_demo/features/pages/fence_page.dart';
import 'package:smart_livestock_demo/features/pages/fever_detail_page.dart';
import 'package:smart_livestock_demo/features/pages/fever_warning_page.dart';
import 'package:smart_livestock_demo/features/pages/livestock_detail_page.dart';
import 'package:smart_livestock_demo/features/pages/mine_page.dart';
import 'package:smart_livestock_demo/features/pages/stats_page.dart';
import 'package:smart_livestock_demo/features/pages/twin_overview_page.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_checkout_page.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_plan_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_create_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_edit_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_list_page.dart';
import 'package:smart_livestock_demo/features/worker_management/presentation/worker_list_page.dart';
import 'package:smart_livestock_demo/features/admin/presentation/contracts_page.dart';
import 'package:smart_livestock_demo/features/admin/presentation/revenue_page.dart';
import 'package:smart_livestock_demo/features/admin/presentation/subscriptions_page.dart';
import 'package:smart_livestock_demo/features/admin/presentation/api_auth_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_revenue_page.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/worker_management_page.dart';
import 'package:smart_livestock_demo/features/mine/presentation/api_auth_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final appMode = ref.watch(appModeProvider);
  final refreshListenable = ValueNotifier<int>(0);
  ref
    ..onDispose(refreshListenable.dispose)
    ..listen(sessionControllerProvider, (_, __) {
      refreshListenable.value++;
    });

  return GoRouter(
    initialLocation: AppRoute.login.path,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: kDebugMode && appMode.isLive,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.uri.path;

      if (!session.isLoggedIn) {
        return location == AppRoute.login.path ? null : AppRoute.login.path;
      }

      final role = session.role!;
      if (role == DemoRole.platformAdmin) {
        return location.startsWith(AppRoute.platformAdmin.path) ||
                location.startsWith('/admin/')
            ? null
            : AppRoute.platformAdmin.path;
      }

      if (role == DemoRole.b2bAdmin) {
        return location.startsWith(AppRoute.b2bAdmin.path)
            ? null
            : AppRoute.b2bAdmin.path;
      }

      if (location == AppRoute.login.path ||
          location.startsWith(AppRoute.platformAdmin.path)) {
        return AppRoute.twin.path;
      }

      if (location == AppRoute.admin.path && !session.canAccessAdminTab) {
        return AppRoute.twin.path;
      }

      if (location == AppRoute.workerManagement.path &&
          role != DemoRole.owner) {
        return AppRoute.twin.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.routeName,
        builder: (context, state) => Consumer(
          builder: (context, ref, child) {
            return LoginPage(
              onSubmit: (selectedRole) {
                ref
                    .read(sessionControllerProvider.notifier)
                    .login(selectedRole);
              },
              onTokenSubmit: (token) {
                ref
                    .read(sessionControllerProvider.notifier)
                    .loginWithToken(token);
              },
            );
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ExpiryPopupHandler(
            child: DemoShell(
              location: state.uri.path,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoute.twin.path,
            name: AppRoute.twin.routeName,
            builder: (context, state) => const TwinOverviewPage(),
            routes: [
              GoRoute(
                path: 'fever',
                name: AppRoute.twinFever.routeName,
                builder: (context, state) => const FeverWarningPage(),
                routes: [
                  GoRoute(
                    path: ':livestockId',
                    name: AppRoute.twinFeverDetail.routeName,
                    builder: (context, state) {
                      final id = state.pathParameters['livestockId']!;
                      return FeverDetailPage(livestockId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'digestive',
                name: AppRoute.twinDigestive.routeName,
                builder: (context, state) => const DigestivePage(),
                routes: [
                  GoRoute(
                    path: ':livestockId',
                    name: AppRoute.twinDigestiveDetail.routeName,
                    builder: (context, state) {
                      final id = state.pathParameters['livestockId']!;
                      return DigestiveDetailPage(livestockId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'estrus',
                name: AppRoute.twinEstrus.routeName,
                builder: (context, state) => const EstrusPage(),
                routes: [
                  GoRoute(
                    path: ':livestockId',
                    name: AppRoute.twinEstrusDetail.routeName,
                    builder: (context, state) {
                      final id = state.pathParameters['livestockId']!;
                      return EstrusDetailPage(livestockId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'epidemic',
                name: AppRoute.twinEpidemic.routeName,
                builder: (context, state) => const EpidemicPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.alerts.path,
            name: AppRoute.alerts.routeName,
            builder: (context, state) => Consumer(
              builder: (context, ref, child) {
                final role = ref.watch(sessionControllerProvider).role!;
                return AlertsPage(role: role);
              },
            ),
          ),
          GoRoute(
            path: AppRoute.mine.path,
            name: AppRoute.mine.routeName,
            builder: (context, state) => const MinePage(),
          ),
          GoRoute(
            path: AppRoute.workerManagement.path,
            name: AppRoute.workerManagement.routeName,
            builder: (context, state) => const WorkerListPage(),
          ),
          GoRoute(
            path: AppRoute.fence.path,
            name: AppRoute.fence.routeName,
            builder: (context, state) => const FencePage(),
          ),
          GoRoute(
            path: AppRoute.fenceForm.path,
            name: AppRoute.fenceForm.routeName,
            builder: (context, state) {
              final id = state.uri.queryParameters['id'];
              return FenceFormPage(fenceId: id);
            },
          ),
          GoRoute(
            path: AppRoute.admin.path,
            name: AppRoute.admin.routeName,
            builder: (context, state) => const AdminPage(),
          ),
          GoRoute(
            path: AppRoute.platformAdmin.path,
            name: AppRoute.platformAdmin.routeName,
            builder: (context, state) => const TenantListPage(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'ops-tenant-create',
                builder: (context, state) => const TenantCreatePage(),
              ),
              GoRoute(
                path: ':id',
                name: 'ops-tenant-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TenantDetailPage(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'ops-tenant-edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return TenantEditPage(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.livestockDetail.path,
            name: AppRoute.livestockDetail.routeName,
            builder: (context, state) {
              final earTag = state.uri.pathSegments.last;
              return LivestockDetailPage(earTag: earTag);
            },
          ),
          GoRoute(
            path: AppRoute.devices.path,
            name: AppRoute.devices.routeName,
            builder: (context, state) => const DevicesPage(),
          ),
          GoRoute(
            path: AppRoute.stats.path,
            name: AppRoute.stats.routeName,
            builder: (context, state) => const StatsPage(),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'legacy-dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoute.b2bAdmin.path,
            name: AppRoute.b2bAdmin.routeName,
            builder: (context, state) => const B2bDashboardPage(),
            routes: [
              GoRoute(
                path: 'farms',
                name: AppRoute.b2bAdminFarms.routeName,
                builder: (context, state) => const B2bFarmListPage(),
              ),
              GoRoute(
                path: 'contract',
                name: AppRoute.b2bAdminContract.routeName,
                builder: (context, state) => const B2bContractPage(),
              ),
              GoRoute(
                path: 'revenue',
                name: AppRoute.b2bAdminRevenue.routeName,
                builder: (context, state) => const B2bRevenuePage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: AppRoute.b2bAdminRevenueDetail.routeName,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return B2bRevenueDetailPage(periodId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'workers',
                name: AppRoute.b2bWorkerManagement.routeName,
                builder: (context, state) => const B2bWorkerManagementPage(),
                routes: [
                  GoRoute(
                    path: ':farmId',
                    name: AppRoute.b2bWorkerDetail.routeName,
                    builder: (context, state) {
                      final farmId = state.pathParameters['farmId']!;
                      return B2bWorkerDetailPage(farmId: farmId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.platformContracts.path,
            name: AppRoute.platformContracts.routeName,
            builder: (context, state) => const ContractsPage(),
          ),
          GoRoute(
            path: AppRoute.platformRevenue.path,
            name: AppRoute.platformRevenue.routeName,
            builder: (context, state) => const RevenuePage(),
          ),
          GoRoute(
            path: AppRoute.platformSubscriptions.path,
            name: AppRoute.platformSubscriptions.routeName,
            builder: (context, state) => const SubscriptionsPage(),
          ),
          GoRoute(
            path: AppRoute.platformApiAuth.path,
            name: AppRoute.platformApiAuth.routeName,
            builder: (context, state) => const ApiAuthPage(),
          ),
          GoRoute(
            path: AppRoute.mineApiAuth.path,
            name: AppRoute.mineApiAuth.routeName,
            builder: (context, state) => const MineApiAuthPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.subscriptionPlan.path,
        name: AppRoute.subscriptionPlan.routeName,
        builder: (context, state) => const SubscriptionPlanPage(),
      ),
      GoRoute(
        path: AppRoute.subscription.path,
        name: AppRoute.subscription.routeName,
        builder: (context, state) => const SubscriptionPlanPage(),
      ),
      GoRoute(
        path: AppRoute.checkout.path,
        name: AppRoute.checkout.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const SubscriptionPlanPage();
          return SubscriptionCheckoutPage(
            tier: extra['tier'] as SubscriptionTier,
            livestockCount: extra['livestockCount'] as int,
          );
        },
      ),
    ],
  );
});
