import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

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
    if (role == null || role == DemoRole.ops) {
      return Scaffold(body: child);
    }

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
      body: child,
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
