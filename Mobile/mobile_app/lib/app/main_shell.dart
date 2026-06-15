import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_widget.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
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
    // Only render child (e.g. RanchPage) once farms are loaded and activeFarmId is set.
    // Rendering too early causes farmGet() to throw StateError('No active farm').
    // If farmState is null (not farm-scoped role) or farms loaded → show child.
    // If still loading → show spinner. If load finished with no farms → show guidance.
    final Widget body;
    if (farmState == null || farmState.hasFarms) {
      body = child;
    } else if (farmState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = const _FarmEmptyGuidance();
    }
    final showShellAppBar =
        showFarmContext && location != AppRoute.fence.path && location != AppRoute.ranch.path;
    final navItems = _buildBusinessNavItems(role, context);
    final currentIndex = navItems.indexWhere((item) {
      if (item.route == AppRoute.ranch) {
        return location == AppRoute.ranch.path ||
            location.startsWith('${AppRoute.ranch.path}/') ||
            location == AppRoute.twin.path ||
            location.startsWith('${AppRoute.twin.path}/') ||
            location == AppRoute.fence.path ||
            location.startsWith('${AppRoute.fence.path}/') ||
            location == AppRoute.alerts.path;
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

  List<_NavItem> _buildBusinessNavItems(UserRole role, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <_NavItem>[
      _NavItem(
        key: const Key('nav-ranch'),
        icon: Icons.map,
        label: l10n.navRanch,
        route: AppRoute.ranch,
      ),
      _NavItem(
        key: const Key('nav-mine'),
        icon: Icons.person,
        label: l10n.navMine,
        route: AppRoute.mine,
      ),
    ];
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

  static const _sidebarWidth = 56.0;

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
            child: Column(children: [
                const SizedBox(height: 8),
                _IconSidebarItem(
                  icon: Icons.dashboard_outlined,
                  tooltip: '概览',
                  selected: _isSelected(context, 0),
                  onTap: () => context.go(AppRoute.b2bAdmin.path),
                ),
                _IconSidebarItem(
                  icon: Icons.agriculture_outlined,
                  tooltip: '牧场管理',
                  selected: _isSelected(context, 1),
                  onTap: () => context.go(AppRoute.b2bAdminFarms.path),
                ),
                _IconSidebarItem(
                  icon: Icons.description_outlined,
                  tooltip: '合同信息',
                  selected: _isSelected(context, 2),
                  onTap: () => context.go(AppRoute.b2bAdminContract.path),
                ),
                _IconSidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  tooltip: '对账',
                  selected: _isSelected(context, 3),
                  onTap: () => context.go(AppRoute.b2bAdminRevenue.path),
                ),

                const Spacer(),

                const Divider(height: 1, indent: 8, endIndent: 8),
                _IconSidebarItem(
                  icon: Icons.logout,
                  tooltip: '退出登录',
                  selected: false,
                  color: const Color(0xFFC2564B),
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

class _IconSidebarItem extends StatelessWidget {
  const _IconSidebarItem({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (selected ? const Color(0xFF1565C0) : const Color(0xFF616161));
    final bgColor = selected ? const Color(0xFFE3F2FD) : Colors.transparent;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(icon, size: 20, color: effectiveColor),
          ),
        ),
      ),
    );
  }
}
