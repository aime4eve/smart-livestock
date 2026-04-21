import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';

class TenantCard extends StatelessWidget {
  const TenantCard({
    super.key,
    required this.tenant,
    required this.onTap,
  });

  final Tenant tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usageRatio = tenant.licenseUsage.clamp(0.0, 1.0);
    return HighfiCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('tenant-card-${tenant.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tenant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  HighfiStatusChip(
                    label: tenant.status == TenantStatus.active ? '启用中' : '已禁用',
                    color: tenant.status == TenantStatus.active
                        ? AppColors.success
                        : AppColors.danger,
                    icon: tenant.status == TenantStatus.active
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'License ${tenant.licenseUsed} / ${tenant.licenseTotal}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
