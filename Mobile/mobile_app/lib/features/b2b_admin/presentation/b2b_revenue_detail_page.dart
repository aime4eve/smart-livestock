import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/currency_formatter.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/presentation/widgets/async_fallback_views.dart';
import 'package:hkt_livestock_agentic/features/b2b_admin/presentation/widgets/confirm_dialog.dart';
import 'package:hkt_livestock_agentic/features/revenue/domain/revenue_repository.dart';
import 'package:hkt_livestock_agentic/features/revenue/presentation/b2b_revenue_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(b2bRevenueControllerProvider);

    return asyncData.when(
      data: (data) {
        final period = ref
            .read(b2bRevenueControllerProvider.notifier)
            .findPeriod(widget.periodId);
        if (period == null) {
          return const Scaffold(
            body: B2bEmptyView(key: Key('b2b-revenue-detail-empty')),
          );
        }
        return _buildContent(context, period);
      },
      loading: () => const Scaffold(
        body: Center(
          key: Key('b2b-revenue-detail-loading'),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: B2bErrorView(
          key: const Key('b2b-revenue-detail-error'),
          message: e.toString(),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RevenuePeriod period) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SingleChildScrollView(
        key: const Key('page-b2b-revenue-detail'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BreadcrumbBar(
              key: const Key('b2b-revenue-detail-breadcrumb'),
              periodLabel: period.periodLabel,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _HeroCard(
              key: const Key('b2b-revenue-detail-hero'),
              totalRevenue: period.totalRevenue,
              partnerShare: period.partnerShare,
              revenueShareRatio: period.revenueShareRatio ?? 0.0,
            ),
            const SizedBox(height: AppSpacing.lg),
            _ConfirmationBar(
              key: const Key('b2b-revenue-detail-confirmation'),
              platformConfirmed: period.platformConfirmed,
              partnerConfirmed: period.partnerConfirmed,
              isConfirming: _confirming,
              onConfirm: () => _handleConfirm(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await B2bConfirmDialog.show(
      context,
      title: '确认对账',
      subtitle: '确认后将无法撤回，请核实数据无误后操作',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _confirming = true);

    final ok = await ref
        .read(b2bRevenueControllerProvider.notifier)
        .confirmAsPartner(widget.periodId);

    if (!mounted) return;

    setState(() => _confirming = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.b2bRevenueDetailConfirmOk),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.b2bRevenueDetailConfirmFailed),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        InkWell(
          key: const Key('b2b-revenue-detail-back'),
          onTap: onBack,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios,
                  size: 14, color: Theme.of(context).hintColor),
              Text(l10n.b2bRevenueTitle,
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 14)),
            ],
          ),
        ),
        Text(' > $periodLabel ${l10n.b2bRevenueDetailTitle}',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    super.key,
    required this.totalRevenue,
    required this.partnerShare,
    required this.revenueShareRatio,
  });

  final double totalRevenue;
  final double partnerShare;
  final double revenueShareRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF607D8B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
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
          Text(
            formatCurrency(totalRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(l10n.b2bRevenueDetailDeviceFee,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _HeroStatItem(
                label: '合作方分润',
                value: formatCurrency(partnerShare),
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroStatItem(
                label: '分润比例',
                value: '${(revenueShareRatio * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
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

  bool get _canPartnerConfirm => platformConfirmed && !partnerConfirmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(l10n.b2bRevenueDetailConfirmStatus,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
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
              if (_canPartnerConfirm)
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
                      : Text(l10n.b2bRevenueDetailConfirmButton),
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
        Text(label,
            style: TextStyle(
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
