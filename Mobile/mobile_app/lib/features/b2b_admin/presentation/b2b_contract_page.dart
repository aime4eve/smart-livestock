import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/confirm_dialog.dart';

class B2bContractPage extends ConsumerWidget {
  const B2bContractPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bContractControllerProvider);
    final theme = Theme.of(context);

    return switch (data.viewState) {
      ViewState.loading => const Center(child: CircularProgressIndicator()),
      ViewState.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.error)),
              if (data.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(data.message!,
                      style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ViewState.empty => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('暂无数据', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.forbidden => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('无权限访问', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.offline => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('网络不可用', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.normal => _ContractContent(data: data),
    };
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _ContractContent extends StatelessWidget {
  const _ContractContent({required this.data});

  final B2bContractData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          _buildPageHeader(context),
          const SizedBox(height: AppSpacing.lg),

          // Main info card (gray-blue gradient)
          _buildMainInfoCard(context),
          const SizedBox(height: AppSpacing.lg),

          // Expiry reminder bar
          if (data.expiresAt != null)
            _ExpiryReminderBar(expiresAt: data.expiresAt!),
          if (data.expiresAt != null)
            const SizedBox(height: AppSpacing.lg),

          // Contract terms section
          _buildContractTermsSection(context),
          const SizedBox(height: AppSpacing.lg),

          // Subscription service status (only for licensed billing)
          if (data.billingModel == 'licensed') ...[
            _buildSubscriptionStatusSection(context),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Quick actions
          _buildQuickActions(context),
        ],
      ),
    );
  }

  // --- Page header ---
  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text('合同信息',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- Main info card (gradient) ---
  Widget _buildMainInfoCard(BuildContext context) {
    final statusColor = _statusColor(data.status);
    final statusText = _statusText(data.status);

    return Container(
      key: const Key('b2b-contract-main-card'),
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
          // Partner name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  data.partnerName ?? '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (data.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: AppSpacing.md),

          // Bottom row: 3 items
          Row(
            children: [
              _HeroInfoItem(
                label: '编号',
                value: data.contractId ?? '-',
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroInfoItem(
                label: '签约人',
                value: data.signedBy ?? '-',
              ),
              const SizedBox(width: AppSpacing.xl),
              _HeroInfoItem(
                label: '计费模式',
                value: _billingModelText(data.billingModel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Contract terms section ---
  Widget _buildContractTermsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('b2b-contract-terms-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF607D8B)),
              const SizedBox(width: AppSpacing.sm),
              Text('合同条款',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _TermCard(
                  icon: Icons.workspace_premium_outlined,
                  label: '套餐等级',
                  value: _tierText(data.effectiveTier),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TermCard(
                  icon: Icons.percent,
                  label: '分润比例',
                  value: data.revenueShareRatio != null
                      ? '${(data.revenueShareRatio! * 100).toStringAsFixed(0)}%'
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TermCard(
                  icon: Icons.play_arrow,
                  label: '生效日期',
                  value: _formatDate(data.startedAt),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TermCard(
                  icon: Icons.schedule,
                  label: '到期日期',
                  value: _formatDate(data.expiresAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Subscription service status section ---
  Widget _buildSubscriptionStatusSection(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = _serviceStatusColor(data.serviceStatus);
    final statusLabel = _serviceStatusText(data.serviceStatus);

    return Container(
      key: const Key('b2b-contract-subscription-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined,
                  size: 18, color: Color(0xFF607D8B)),
              const SizedBox(width: AppSpacing.sm),
              Text('订阅服务状态',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Status indicator
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(statusLabel,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              if (data.serviceTier != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.serviceTier!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 grid
          Row(
            children: [
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.cloud_outlined,
                  label: '部署方式',
                  value: _deploymentTypeText(data.deploymentType),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.devices_outlined,
                  label: '设备配额',
                  value: data.deviceQuota != null
                      ? '${data.deviceQuota}'
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.favorite_outline,
                  label: '心跳',
                  value: _formatDate(data.lastHeartbeatAt),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SubInfoItem(
                  icon: Icons.timer_outlined,
                  label: '到期时间',
                  value: _formatDate(data.serviceExpiresAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Quick actions ---
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            key: const Key('b2b-contract-action-contact'),
            icon: Icons.headset_mic_outlined,
            title: '联系平台',
            subtitle: '咨询续签或变更',
            onTap: () {
              B2bConfirmDialog.show(
                context,
                title: '功能开发中',
                subtitle: '在线客服功能即将上线',
                confirmLabel: '知道了',
                cancelLabel: '关闭',
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionCard(
            key: const Key('b2b-contract-action-download'),
            icon: Icons.download_outlined,
            title: '下载合同',
            subtitle: '导出 PDF（占位）',
            onTap: () {
              B2bConfirmDialog.show(
                context,
                title: '功能开发中',
                subtitle: '合同 PDF 下载功能即将上线',
                confirmLabel: '知道了',
                cancelLabel: '关闭',
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helpers ---
  static String _statusText(String? status) => switch (status) {
        'active' => '生效中',
        'suspended' => '已暂停',
        'expired' => '已过期',
        _ => status ?? '-',
      };

  static Color _statusColor(String? status) => switch (status) {
        'active' => const Color(0xFF81C784),
        'suspended' => const Color(0xFFFFCC80),
        'expired' => const Color(0xFFEF9A9A),
        _ => const Color(0xFFBDBDBD),
      };

  static String _billingModelText(String? model) => switch (model) {
        'revenue_share' => '分润模式',
        'licensed' => '授权模式',
        _ => model ?? '-',
      };

  static String _tierText(String? tier) => switch (tier) {
        'standard' => '标准版',
        'premium' => '高级版',
        'enterprise' => '企业版',
        _ => tier ?? '-',
      };

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return isoDate.substring(0, 10);
    } catch (_) {
      return '-';
    }
  }

  static String _deploymentTypeText(String? type) => switch (type) {
        'cloud' => '云端',
        'on_premise' => '本地部署',
        _ => type ?? '-',
      };

  static Color _serviceStatusColor(String? status) => switch (status) {
        'running' => const Color(0xFF4CAF50),
        'degraded' => const Color(0xFFFFC107),
        'down' => const Color(0xFFF44336),
        _ => const Color(0xFFBDBDBD),
      };

  static String _serviceStatusText(String? status) => switch (status) {
        'running' => '正常运行',
        'degraded' => '性能降级',
        'down' => '服务中断',
        _ => status ?? '未知',
      };
}

// ---------------------------------------------------------------------------
// Expiry reminder bar
// ---------------------------------------------------------------------------

class _ExpiryReminderBar extends StatelessWidget {
  const _ExpiryReminderBar({required this.expiresAt});

  final String expiresAt;

  int get _remainingDays {
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (_) {
      return 0;
    }
  }

  Color get _buttonColor {
    final days = _remainingDays;
    if (days <= 30) return const Color(0xFFE53935);
    if (days <= 90) return const Color(0xFFEF6C00);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final days = _remainingDays;
    final dateStr =
        expiresAt.length >= 10 ? expiresAt.substring(0, 10) : expiresAt;

    return Container(
      key: const Key('b2b-contract-expiry-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event, size: 20, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),

          // Label + date + remaining
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '合同到期日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF455A64),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days > 0
                      ? '$dateStr  ·  剩余 $days 天'
                      : '$dateStr  ·  已过期',
                  style: TextStyle(
                    fontSize: 14,
                    color: days > 0
                        ? const Color(0xFF1565C0)
                        : const Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Contact button
          SizedBox(
            height: 32,
            child: FilledButton(
              key: const Key('b2b-contract-renew-btn'),
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('联系续签',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _HeroInfoItem extends StatelessWidget {
  const _HeroInfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF607D8B)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubInfoItem extends StatelessWidget {
  const _SubInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF607D8B)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF455A64),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 28, color: const Color(0xFF607D8B)),
              const SizedBox(height: AppSpacing.sm),
              Text(title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
