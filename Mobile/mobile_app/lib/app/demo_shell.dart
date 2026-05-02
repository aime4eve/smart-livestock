import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_widget.dart';

class DemoShell extends ConsumerWidget {
  const DemoShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final role = session.role;
    if (role == null ||
        role == DemoRole.platformAdmin) {
      return Scaffold(body: child);
    }

    if (role == DemoRole.b2bAdmin) {
      return _B2bAdminShell(child: child);
    }

    final showFarmContext =
        role == DemoRole.owner || role == DemoRole.worker;
    final farmState =
        showFarmContext ? ref.watch(farmSwitcherControllerProvider) : null;
    final body = farmState != null && !farmState.hasFarms
        ? const _FarmEmptyGuidance()
        : child;
    final showShellAppBar =
        showFarmContext && location != AppRoute.fence.path;
    final navItems = _buildBusinessNavItems(role);
    final currentIndex = navItems.indexWhere((item) {
      if (item.route == AppRoute.twin) {
        return location == AppRoute.twin.path ||
            location.startsWith('${AppRoute.twin.path}/');
      }
      return location == item.route.path;
    });
    final selectedIndex = currentIndex >= 0 ? currentIndex : 0;

    return Scaffold(
      appBar: showShellAppBar
          ? AppBar(
              actions: const [
                FarmSwitcher(),
                SizedBox(width: AppSpacing.sm),
              ],
            )
          : null,
      body: body,
      bottomNavigationBar: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < navItems.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilledButton.tonal(
                    key: navItems[i].key,
                    onPressed: () => context.go(navItems[i].route.path),
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedIndex == i
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(navItems[i].icon, size: 18),
                        const SizedBox(width: 6),
                        Text(navItems[i].label),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_NavItem> _buildBusinessNavItems(DemoRole role) {
    final items = <_NavItem>[
      const _NavItem(
        key: Key('nav-twin'),
        icon: Icons.account_tree_outlined,
        label: '孪生',
        route: AppRoute.twin,
      ),
      const _NavItem(
        key: Key('nav-fence'),
        icon: Icons.map,
        label: '围栏',
        route: AppRoute.fence,
      ),
      const _NavItem(
        key: Key('nav-alerts'),
        icon: Icons.warning_amber,
        label: '告警',
        route: AppRoute.alerts,
      ),
      const _NavItem(
        key: Key('nav-mine'),
        icon: Icons.person,
        label: '我的',
        route: AppRoute.mine,
      ),
    ];
    if (role == DemoRole.owner) {
      items.add(
        const _NavItem(
          key: Key('nav-admin'),
          icon: Icons.admin_panel_settings,
          label: '后台',
          route: AppRoute.admin,
        ),
      );
    }
    return items;
  }
}

class _FarmEmptyGuidance extends StatelessWidget {
  const _FarmEmptyGuidance();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('farm-empty-guidance'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          '请创建您的第一个牧场',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.route,
  });

  final Key key;
  final IconData icon;
  final String label;
  final AppRoute route;
}

class _B2bAdminShell extends StatelessWidget {
  const _B2bAdminShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _calculateIndex(context),
            onDestinationSelected: (index) => _navigate(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('概览'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.agriculture),
                label: Text('牧场'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                label: Text('合同'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: Text('对账'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_2_outlined),
                label: Text('牧工管理'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/farms')) return 1;
    if (location.contains('/contract')) return 2;
    if (location.contains('/revenue')) return 3;
    if (location.contains('/workers')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoute.b2bAdmin.path);
      case 1:
        context.go(AppRoute.b2bAdminFarms.path);
      case 2:
        context.go(AppRoute.b2bAdminContract.path);
      case 3:
        context.go(AppRoute.b2bAdminRevenue.path);
      case 4:
        context.go(AppRoute.b2bWorkerManagement.path);
    }
  }
}
