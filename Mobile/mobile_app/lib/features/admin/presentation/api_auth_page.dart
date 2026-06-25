import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/api_authorization/domain/api_authorization_repository.dart';
import 'package:hkt_livestock_agentic/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class ApiAuthPage extends ConsumerStatefulWidget {
  const ApiAuthPage({super.key});

  @override
  ConsumerState<ApiAuthPage> createState() => _ApiAuthPageState();
}

class _ApiAuthPageState extends ConsumerState<ApiAuthPage> {
  UsageOverview? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      final overview = await ref
          .read(apiAuthorizationControllerProvider.notifier)
          .loadDashboard(_fmt(from), _fmt(now));
      if (mounted) setState(() => _dashboard = overview);
    } catch (_) {}
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(apiAuthorizationControllerProvider);
    final controller = ref.read(apiAuthorizationControllerProvider.notifier);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
        key: const Key('page-api-auth'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, controller),
            const SizedBox(height: AppSpacing.md),
            if (_dashboard != null) _buildDashboard(context),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  key: const Key('apikey-create'),
                  onPressed: () => _showCreateDialog(context, controller),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.adminApiAuthCreateKey),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (data.isEmpty)
              SizedBox(height: 200, child: Center(child: Text(l10n.adminApiAuthNoKeys)))
            else
              ...data.items.map((key) => _ApiKeyCard(
                    keyItem: key,
                    onStatusChange: (id, status) async {
                      await controller.updateStatus(id, status);
                      _loadDashboard();
                    },
                    onRevoke: (id) async {
                      await controller.revoke(id);
                      _loadDashboard();
                    },
                  )),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
    );
  }

  Widget _buildHeader(BuildContext context, ApiAuthorizationController controller) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mineApiAuthTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.adminApiAuthDescription, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          key: const Key('apikey-refresh'),
          onPressed: () {
            controller.refresh();
            _loadDashboard();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final d = _dashboard!;
    return HighfiCard(
      key: const Key('usage-dashboard'),
      child: Row(
        children: [
          _statBox(context, '总调用', '${d.totalCalls}', Icons.api),
          _statBox(context, '成功', '${d.successCalls}', Icons.check_circle, AppColors.success),
          _statBox(context, '失败', '${d.errorCalls}', Icons.error, AppColors.danger),
          _statBox(context, '平均响应', '${d.avgResponseMs.toStringAsFixed(0)}ms', Icons.speed),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String label, String value, IconData icon, [Color? color]) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, ApiAuthorizationController controller) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final selectedScopes = <String>{
      'livestock:read', 'fence:read', 'alert:read', 'device:read', 'gps:read'
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.adminApiAuthCreateKey),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtl, decoration: InputDecoration(labelText: l10n.adminApiAuthName)),
                const SizedBox(height: 8),
                TextField(controller: descCtl, decoration: InputDecoration(labelText: l10n.adminApiAuthDescriptionOptional)),
                const SizedBox(height: 12),
                Text(l10n.adminApiAuthScopes, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 4),
                ..._allScopes.map((s) => CheckboxListTile(
                      dense: true,
                      value: selectedScopes.contains(s),
                      title: Text(s, style: const TextStyle(fontSize: 13)),
                      onChanged: (v) => setDialogState(() {
                        if (v == true) {
                          selectedScopes.add(s);
                        } else {
                          selectedScopes.remove(s);
                        }
                      }),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
            ElevatedButton(
              onPressed: () async {
                if (nameCtl.text.trim().isEmpty) return;
                final result = await controller.createApiKey({
                  'name': nameCtl.text.trim(),
                  'description': descCtl.text.trim(),
                  'scopes': selectedScopes.join(','),
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result != null) _showRawKeyDialog(context, result);
                }
              },
              child: Text(l10n.adminApiAuthCreate),
            ),
          ],
        ),
      ),
    );
  }

  void _showRawKeyDialog(BuildContext context, ApiKeyCreateResult result) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminApiAuthKeyCreated),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminApiAuthKeyWarning, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 12),
            SelectableText(result.fullKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 8),
            Text('${l10n.adminApiAuthPrefixLabel}: ${result.info.prefix}'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.adminApiAuthSaved)),
        ],
      ),
    );
  }

  static const _allScopes = [
    'livestock:read', 'fence:read', 'alert:read', 'device:read',
    'device:register', 'gps:read', 'health:read',
  ];
}

class _ApiKeyCard extends ConsumerWidget {
  const _ApiKeyCard({
    required this.keyItem,
    required this.onStatusChange,
    required this.onRevoke,
  });

  final ApiKeyItem keyItem;
  final Future<void> Function(String id, String status) onStatusChange;
  final Future<void> Function(String id) onRevoke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = keyItem.status == 'ACTIVE' || keyItem.status == 'active';
    final statusColor = isActive ? AppColors.success : AppColors.danger;
    final statusLabel = isActive ? '启用' : (keyItem.status ?? '未知');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('apikey-${keyItem.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    keyItem.name ?? keyItem.prefix ?? 'API Key',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                HighfiStatusChip(
                  label: statusLabel,
                  color: statusColor,
                  icon: isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (keyItem.prefix != null) Text('前缀: ${keyItem.prefix}'),
            if (keyItem.description != null && keyItem.description!.isNotEmpty)
              Text('描述: ${keyItem.description}'),
            if (keyItem.scopeList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: keyItem.scopeList.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (keyItem.requestsPerMinute != null)
                  Text('RPM: ${keyItem.requestsPerMinute}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                if (keyItem.dailyQuota != null)
                  Text('日配额: ${keyItem.dailyQuota}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (keyItem.createdAt != null)
              Text('创建: ${keyItem.createdAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive) ...[
                  TextButton.icon(
                    key: Key('disable-${keyItem.id}'),
                    onPressed: () => onStatusChange(keyItem.id, 'disabled'),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('禁用'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    key: Key('revoke-${keyItem.id}'),
                    onPressed: () => onRevoke(keyItem.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('删除'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ],
                if (!isActive)
                  TextButton.icon(
                    key: Key('enable-${keyItem.id}'),
                    onPressed: () => onStatusChange(keyItem.id, 'active'),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('启用'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
