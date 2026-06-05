import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/audit_log/domain/audit_log_models.dart';
import 'package:smart_livestock_demo/features/admin/audit_log/presentation/audit_log_controller.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _selectedAction;
  DateTimeRange? _dateRange;
  int _currentPage = 1;

  static const _actionOptions = <String>[
    'TENANT_CREATED',
    'TENANT_UPDATED',
    'TENANT_STATUS_CHANGED',
    'USER_CREATED',
    'USER_UPDATED',
    'USER_STATUS_CHANGED',
    'FARM_CREATED',
    'SUBSCRIPTION_UPGRADED',
    'SUBSCRIPTION_CANCELLED',
    'CONTRACT_SIGNED',
    'API_KEY_CREATED',
    'API_KEY_REVOKED',
  ];

  @override
  Widget build(BuildContext context) {
    final asyncLogs = ref.watch(auditLogControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('审计日志')),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: asyncLogs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('$e', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (result) => _buildList(result),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('audit-log-filter-action'),
                value: _selectedAction,
                decoration: const InputDecoration(
                  labelText: '操作类型',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ..._actionOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                ],
                onChanged: (v) => setState(() => _selectedAction = v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                _dateRange != null
                    ? '${_formatDate(_dateRange!.start)} ~ ${_formatDate(_dateRange!.end)}'
                    : '时间范围',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _applyFilter,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('查询'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AuditLogListResult result) {
    if (result.isEmpty) {
      return const Center(child: Text('暂无审计日志'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            key: const Key('audit-log-list'),
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final entry = result.items[index];
              return _AuditLogTile(entry: entry);
            },
          ),
        ),
        _buildPagination(result),
      ],
    );
  }

  Widget _buildPagination(AuditLogListResult result) {
    final totalPages = (result.total / result.pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_currentPage / $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
          const Spacer(),
          Text('共 ${result.total} 条', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _applyFilter() {
    _currentPage = 1;
    ref.read(auditLogControllerProvider.notifier).refresh(
      filter: AuditLogFilter(
        action: _selectedAction,
        startTime: _dateRange?.start.toIso8601String(),
        endTime: _dateRange?.end.toIso8601String(),
      ),
    );
  }

  void _goToPage(int page) {
    _currentPage = page;
    ref.read(auditLogControllerProvider.notifier).refresh(
      page: page,
      filter: AuditLogFilter(
        action: _selectedAction,
        startTime: _dateRange?.start.toIso8601String(),
        endTime: _dateRange?.end.toIso8601String(),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry});
  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      title: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(entry.occurredAt, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Chip(
              label: Text(entry.action, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(entry.tenantId ?? '-', style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 1,
            child: Text(entry.userId ?? '-', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(context, '事件ID', entry.eventId),
              _detailRow(context, '事件类型', entry.eventType),
              if (entry.details != null && entry.details!.isNotEmpty)
                _detailRow(context, '详情', entry.details.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
