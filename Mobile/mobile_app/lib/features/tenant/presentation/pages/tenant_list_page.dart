import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/widgets/tenant_card.dart';
import 'package:smart_livestock_demo/widgets/pagination_bar.dart';

class TenantListPage extends ConsumerStatefulWidget {
  const TenantListPage({super.key});

  @override
  ConsumerState<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends ConsumerState<TenantListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(tenantListControllerProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(tenantListControllerProvider);
    final ctrl = ref.read(tenantListControllerProvider.notifier);
    return Scaffold(
      key: const Key('page-tenant-list'),
      appBar: AppBar(
        title: const Text('租户管理'),
        actions: [
          IconButton(
            key: const Key('tenant-create-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/ops/admin/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('tenant-search-input'),
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜索租户名称',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<TenantStatus?>(
                  key: const Key('tenant-status-filter'),
                  value: data.query.status,
                  hint: const Text('全部'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部')),
                    DropdownMenuItem(
                        value: TenantStatus.active, child: Text('启用')),
                    DropdownMenuItem(
                        value: TenantStatus.disabled, child: Text('禁用')),
                  ],
                  onChanged: ctrl.setStatus,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(data, ctrl)),
        ],
      ),
    );
  }

  Widget _buildBody(TenantListViewData data, TenantListController ctrl) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '加载失败',
          description: data.message ?? '请稍后再试',
          icon: Icons.error_outline,
        );
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无租户',
          description: '可点击右上角 + 创建新租户',
          icon: Icons.inbox_outlined,
        );
      case ViewState.forbidden:
        return const HighfiEmptyErrorState(
          title: '无权访问',
          description: '当前角色无法访问租户管理',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return const HighfiEmptyErrorState(
          title: '离线',
          description: '网络未连接，请稍后重试',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                key: const Key('tenant-list'),
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: data.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final t = data.tenants[idx];
                  return TenantCard(
                    tenant: t,
                    onTap: () => context.go('/ops/admin/${t.id}'),
                  );
                },
              ),
            ),
            PaginationBar(
              page: data.query.page,
              pageCount: data.pageCount,
              onPageChanged: ctrl.setPage,
            ),
          ],
        );
    }
  }
}
