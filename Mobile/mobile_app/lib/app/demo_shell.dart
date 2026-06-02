import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
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
        role == UserRole.platformAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('平台管理'),
          actions: [
            IconButton(
              key: const Key('platform-admin-logout'),
              icon: const Icon(Icons.logout),
              tooltip: '退出登录',
              onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: child,
      );
    }

    if (role == UserRole.b2bAdmin) {
      return _B2bAdminShell(child: child);
    }

    final showFarmContext =
        role == UserRole.owner || role == UserRole.worker;
    final farmState =
        showFarmContext ? ref.watch(farmSwitcherControllerProvider) : null;
    // Trigger farm loading when owner/worker logs in and farms haven't been loaded yet
    if (showFarmContext && farmState != null && !farmState.hasFarms && !farmState.isLoading) {
      Future.microtask(() {
        ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
      });
    }
    final body = farmState != null && !farmState.hasFarms && !farmState.isLoading
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

  List<_NavItem> _buildBusinessNavItems(UserRole role) {
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
    if (role == UserRole.owner) {
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
          '暂无关联牧场，请联系管理员为您分配牧场。',
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

class _B2bAdminShell extends ConsumerWidget {
  const _B2bAdminShell({required this.child});
  final Widget child;

  static const _sidebarWidth = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // ── Grouped sidebar ──
          Container(
            width: _sidebarWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                right: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Text(
                    'B端控制台',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF37474F),
                    ),
                  ),
                ),

                // ── Section: operations ──
                const _SidebarGroupLabel(label: '运营管理'),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: '概览',
                  selected: _isSelected(context, 0),
                  onTap: () => context.go(AppRoute.b2bAdmin.path),
                ),
                _SidebarItem(
                  icon: Icons.agriculture_outlined,
                  label: '牧场管理',
                  selected: _isSelected(context, 1),
                  onTap: () => context.go(AppRoute.b2bAdminFarms.path),
                ),

                // ── Section: business ──
                const _SidebarGroupLabel(label: '商务管理'),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  label: '合同信息',
                  selected: _isSelected(context, 2),
                  onTap: () => context.go(AppRoute.b2bAdminContract.path),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: '对账',
                  selected: _isSelected(context, 3),
                  onTap: () => context.go(AppRoute.b2bAdminRevenue.path),
                ),

                const Spacer(),

                // ── Bottom: user + logout ──
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.userName ?? 'B端管理员',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _SidebarItem(
                  icon: Icons.logout,
                  label: '退出登录',
                  selected: false,
                  textColor: const Color(0xFFC2564B),
                  onTap: () =>
                      ref.read(sessionControllerProvider.notifier).logout(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // ── Content ──
          Expanded(child: child),
        ],
      ),
    );
  }

  bool _isSelected(BuildContext context, int index) {
    final uri = GoRouterState.of(context).uri;
    final location = uri.toString();
    return switch (index) {
      // Overview: selected when on /b2b/admin without sub-route
      0 => location.startsWith('/b2b/admin') &&
          !location.startsWith('/b2b/admin/farms') &&
          !location.startsWith('/b2b/admin/contract') &&
          !location.startsWith('/b2b/admin/revenue'),
      // Farm management: selected when on /b2b/admin/farms/*
      1 => location.startsWith('/b2b/admin/farms'),
      2 => location.startsWith('/b2b/admin/contract'),
      3 => location.startsWith('/b2b/admin/revenue'),
      _ => false,
    };
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = textColor ??
        (selected ? const Color(0xFF1565C0) : const Color(0xFF616161));
    final bgColor = selected ? const Color(0xFFE3F2FD) : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
