import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/demo_shell.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/auth/login_page.dart';
import 'package:smart_livestock_demo/features/pages/admin_page.dart';
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
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_create_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_detail_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_edit_page.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/pages/tenant_list_page.dart';

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
      if (role == DemoRole.ops) {
        return location.startsWith(AppRoute.opsAdmin.path)
            ? null
            : AppRoute.opsAdmin.path;
      }

      if (location == AppRoute.login.path ||
          location.startsWith(AppRoute.opsAdmin.path)) {
        return AppRoute.twin.path;
      }

      if (location == AppRoute.admin.path && !session.canAccessAdminTab) {
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
            );
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DemoShell(
            location: state.uri.path,
            child: child,
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
            path: AppRoute.opsAdmin.path,
            name: AppRoute.opsAdmin.routeName,
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
        ],
      ),
    ],
  );
});
