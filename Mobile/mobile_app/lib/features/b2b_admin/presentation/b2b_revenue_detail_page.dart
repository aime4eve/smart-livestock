import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/confirm_dialog.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';
import 'package:smart_livestock_demo/features/revenue/presentation/revenue_controller.dart';

class B2bRevenueDetailPage extends ConsumerStatefulWidget {
  const B2bRevenueDetailPage({super.key, required this.periodId});

  final String periodId;

  @override
  ConsumerState<B2bRevenueDetailPage> createState() =>
      _B2bRevenueDetailPageState();
}

class _B2bRevenueDetailPageState extends ConsumerState<B2bRevenueDetailPage> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final data = ref
        .read(revenueControllerProvider.notifier)
        .getPeriodDetail(widget.periodId);

    return switch (data.viewState) {
      ViewState.loading => const Scaffold(
          body: Center(
            key: Key('b2b-revenue-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        ),
      ViewState.error => Scaffold(
          body: _ErrorView(
            key: const Key('b2b-revenue-detail-error'),
            message: data.message ?? '加载失败',
          ),
        ),
      ViewState.empty => const Scaffold(
          body: _DetailEmptyView(
            key: Key('b2b-revenue-detail-empty'),
          ),
        ),
      ViewState.forbidden => const Scaffold(
          body: _ForbiddenView(
            key: Key('b2b-revenue-detail-forbidden'),
          ),
        ),
      ViewState.offline => const Scaffold(
          body: _OfflineView(
            key: Key('b2b-revenue-detail-offline'),
          ),
        ),
      ViewState.normal => _buildContent(context, data),
    };
  }

  Widget _buildContent(BuildContext context, RevenueDetailViewData data) {
    final period = data.period;
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        key: const Key('page-b2b-revenue-detail'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Breadcrumb bar ---
            _BreadcrumbBar(
              key: const Key('b2b-revenue-detail-breadcrumb'),
              periodLabel: period?.periodLabel ?? '',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Period summary hero card ---
            _HeroCard(
              key: const Key('b2b-revenue-detail-hero'),
              totalDeviceFee: data.totalDeviceFee,
              partnerShare: period?.partnerShare ?? 0,
              revenueShareRatio: data.revenueShareRatio,
              calculatedAt: data.calculatedAt,
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Confirmation status bar ---
            _ConfirmationBar(
              key: const Key('b2b-revenue-detail-confirmation'),
              platformConfirmed: data.platformConfirmed,
              partnerConfirmed: data.partnerConfirmed,
              isConfirming: _confirming,
              onConfirm: () => _handleConfirm(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Farm breakdown table ---
            Text('牧场明细', style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: AppSpacing.sm),
            _FarmBreakdownTable(
              key: const Key('b2b-revenue-detail-farm-table'),
              farmDetails: data.farmDetails,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final confirmed = await B2bConfirmDialog.show(
      context,
      title: '确认对账',
      subtitle: '确认后将无法撤回，请核实数据无误后操作',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _confirming = true);

    final ok = await ref
        .read(revenueControllerProvider.notifier)
        .confirmPeriod(widget.periodId);

    if (!mounted) return;

    setState(() => _confirming = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('对账确认成功'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('确认失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    super.key,
    required this.periodLabel,
    required this.onBack,
  });

  final String periodLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          key: const Key('b2b-revenue-detail-back'),
          onTap: onBack,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, size: 14,
                  color: Theme.of(context).hintColor),
              Text('对账', style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 14,
              )),
            ],
          ),
        ),
        Text(' > $periodLabel 对账明细', style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    super.key,
    required this.totalDeviceFee,
    required this.partnerShare,
    required this.revenueShareRatio,
    this.calculatedAt,
  });

  final double totalDeviceFee;
  final double partnerShare;
  final double revenueShareRatio;
  final String? calculatedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF607D8B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4037474F),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total device fee
          Text(
            _formatCurrency(totalDeviceFee),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text('设备费用合计',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: AppSpacing.lg),
          // Stats row
          Row(
            children: [
              _HeroStatItem(
                label: '合作方分润',
                value: _formatCurrency(partnerShare),
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroStatItem(
                label: '分润比例',
                value: '${(revenueShareRatio * 100).toInt()}%',
              ),
              const SizedBox(width: AppSpacing.xl),
              if (calculatedAt != null)
                _HeroStatItem(
                  label: '计算时间',
                  value: calculatedAt!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
        )),
      ],
    );
  }
}

class _ConfirmationBar extends StatelessWidget {
  const _ConfirmationBar({
    super.key,
    required this.platformConfirmed,
    required this.partnerConfirmed,
    required this.isConfirming,
    required this.onConfirm,
  });

  final bool platformConfirmed;
  final bool partnerConfirmed;
  final bool isConfirming;
  final VoidCallback onConfirm;

  bool get _allConfirmed => platformConfirmed && partnerConfirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认状态', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ConfirmIndicator(
                key: const Key('b2b-platform-confirm'),
                label: '平台已确认',
                confirmed: platformConfirmed,
              ),
              const SizedBox(width: AppSpacing.xl),
              _ConfirmIndicator(
                key: const Key('b2b-partner-confirm'),
                label: '合作方已确认',
                confirmed: partnerConfirmed,
              ),
              const Spacer(),
              if (!_allConfirmed)
                FilledButton(
                  key: const Key('b2b-confirm-btn'),
                  onPressed: isConfirming ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认对账'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmIndicator extends StatelessWidget {
  const _ConfirmIndicator({
    super.key,
    required this.label,
    required this.confirmed,
  });

  final String label;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          confirmed ? Icons.check_circle_outline : Icons.pending_outlined,
          size: 18,
          color: confirmed
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 13,
          color: confirmed
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }
}

class _FarmBreakdownTable extends StatelessWidget {
  const _FarmBreakdownTable({
    super.key,
    required this.farmDetails,
  });

  final List<RevenueFarmDetail> farmDetails;

  @override
  Widget build(BuildContext context) {
    final totalDeviceFee = farmDetails.fold<double>(
      0, (sum, f) => sum + f.deviceFee,
    );
    final totalShareAmount = farmDetails.fold<double>(
      0, (sum, f) => sum + f.shareAmount,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          // Header row
          const _TableRow(
            key: Key('b2b-farm-table-header'),
            cells: [
              _TableCell(
                label: '牧场名称',
                isHeader: true,
                flex: 3,
              ),
              _TableCell(
                label: '牲畜数',
                isHeader: true,
                flex: 2,
                alignRight: true,
              ),
              _TableCell(
                label: '设备单价',
                isHeader: true,
                flex: 3,
                alignRight: true,
              ),
              _TableCell(
                label: '设备费用',
                isHeader: true,
                flex: 3,
                alignRight: true,
              ),
              _TableCell(
                label: '分润金额',
                isHeader: true,
                flex: 3,
                alignRight: true,
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1),
          // Data rows
          ...farmDetails.asMap().entries.map((entry) {
            final index = entry.key;
            final farm = entry.value;
            return Column(
              children: [
                _TableRow(
                  key: Key('b2b-farm-row-$index'),
                  cells: [
                    _TableCell(
                      label: farm.farmName,
                      flex: 3,
                    ),
                    _TableCell(
                      label: '${farm.livestockCount}',
                      flex: 2,
                      alignRight: true,
                    ),
                    _TableCell(
                      label: _formatCurrency(farm.deviceUnitPrice),
                      flex: 3,
                      alignRight: true,
                    ),
                    _TableCell(
                      label: _formatCurrency(farm.deviceFee),
                      flex: 3,
                      alignRight: true,
                    ),
                    _TableCell(
                      label: _formatCurrency(farm.shareAmount),
                      flex: 3,
                      alignRight: true,
                    ),
                  ],
                ),
                if (index < farmDetails.length - 1)
                  const Divider(height: 1, indent: 12, endIndent: 12),
              ],
            );
          }),
          // Totals row
          const Divider(height: 1, thickness: 1),
          _TotalRow(
            key: const Key('b2b-farm-table-totals'),
            totalDeviceFee: totalDeviceFee,
            totalShareAmount: totalShareAmount,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    super.key,
    required this.totalDeviceFee,
    required this.totalShareAmount,
  });

  final double totalDeviceFee;
  final double totalShareAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Span: 牧场名称 (flex 3) + 牲畜数 (flex 2) + 设备单价 (flex 3) = 8
          const Expanded(
            flex: 8,
            child: Text('合计',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          // 设备费用 (flex 3)
          Expanded(
            flex: 3,
            child: Text(
              _formatCurrency(totalDeviceFee),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          // 分润金额 (flex 3)
          Expanded(
            flex: 3,
            child: Text(
              _formatCurrency(totalShareAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({super.key, required this.cells});

  final List<_TableCell> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: cells,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.label,
    this.isHeader = false,
    this.alignRight = false,
    this.flex = 1,
  });

  final String label;
  final bool isHeader;
  final bool alignRight;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
          )
        : const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          );

    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: style,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ViewState fallback views
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text('加载失败', style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          )),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _DetailEmptyView extends StatelessWidget {
  const _DetailEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('暂无数据', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ForbiddenView extends StatelessWidget {
  const _ForbiddenView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('无权限访问', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('网络不可用', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  final digits = intPart.split('').reversed.toList();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formattedInt = buffer.toString().split('').reversed.join();

  return '¥$formattedInt.$decPart';
}
