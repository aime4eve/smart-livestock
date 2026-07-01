import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/l10n/locale_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/features/mine/presentation/mine_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/subscription_status_card.dart';

class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncProfile = ref.watch(mineControllerProvider);
    final role = ref.watch(sessionControllerProvider).role;
    
    return SingleChildScrollView(
      key: const Key('page-mine'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          asyncProfile.when(
            data: (profile) => _buildProfileSection(profile, context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
          ),
          
          if (role == UserRole.owner) ...[
            const SizedBox(height: AppSpacing.lg),
            const SubscriptionStatusCard(),
            const SizedBox(height: AppSpacing.xl),
            
            // 业务管理功能
            _buildBusinessManagement(context),
            const SizedBox(height: AppSpacing.xl),
            
            // 高级管理功能  
            _buildAdvancedManagement(context),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          // 设置
          _buildSettingsSection(context, ref),
          const SizedBox(height: AppSpacing.xl),
          
          // 退出登录
          _buildLogoutSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileSection(profile, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighfiCard(
          key: const Key('mine-profile-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l10n.navMine,
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  HighfiStatusChip(
                    label: profile.active == true ? l10n.mineAccountNormal : l10n.mineAccountDisabled,
                    color: profile.active == true ? AppColors.success : AppColors.danger,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (profile.displayName != null)
                Text(l10n.mineProfileName(profile.displayName!),
                    style: Theme.of(context).textTheme.bodyMedium),
              if (profile.phone != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.mineProfilePhone(profile.phone!),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (profile.role != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.mineProfileRole(profile.role!),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // Personal devices & tools
        Text(
          l10n.minePersonalDevices,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
       HighfiCard(
          child: ListTile(
            key: const Key('mine-livestock-mgmt'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pets),
            title: Text(l10n.livestockListTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.livestockList.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        HighfiCard(
          child: ListTile(
            key: const Key('mine-device-mgmt'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.devices),
            title: Text(l10n.mineDevicesTitle),
            subtitle: Text(l10n.mineDeviceManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.devices.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        HighfiCard(
          child: ListTile(
            key: const Key('mine-offline-maps'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined),
            title: Text(l10n.mineOfflineMapTitle),
            subtitle: Text(l10n.mineOfflineMapDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.offlineTileManagement.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        HighfiCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.headset_mic_outlined),
            title: Text(l10n.mineHelpSupportTitle),
            subtitle: Text(l10n.mineHelpSupportDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: implement Help & Support page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.mineHelpSupportComingSoon)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessManagement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mineBusinessManagement,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // Subscription Management
        HighfiCard(
          child: ListTile(
            key: const Key('mine-subscription-manage'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium),
            title: Text(l10n.mineSubscriptionTitle),
            subtitle: Text(l10n.mineSubscriptionManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.subscriptionPlan.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Revenue Board
        HighfiCard(
          child: ListTile(
            key: const Key('mine-revenue'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l10n.mineRevenueBoardTitle),
            subtitle: Text(l10n.mineRevenueBoardDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformRevenue.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Subscription Service Management
        HighfiCard(
          child: ListTile(
            key: const Key('mine-subscriptions'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.subscriptions_outlined),
            title: Text(l10n.mineSubscriptionServiceTitle),
            subtitle: Text(l10n.mineSubscriptionServiceDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformSubscriptions.path),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedManagement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mineAdvancedManagement,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),

        // Worker Management
        HighfiCard(
          child: ListTile(
            key: const Key('mine-worker-management'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(l10n.mineWorkerTitle),
            subtitle: Text(l10n.mineWorkerManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.workerManagement.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // API Authorization
        HighfiCard(
          child: ListTile(
            key: const Key('mine-api-auth'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.api),
            title: Text(l10n.mineApiAuthTitle),
            subtitle: Text(l10n.mineApiAuthManagementDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.mineApiAuth.path),
          ),
        ),
      ],
    );
  }


  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeControllerProvider);
    String currentLabel;
    if (locale == null) {
      currentLabel = l10n.settingsLanguageSystem;
    } else if (locale.languageCode == 'zh') {
      currentLabel = l10n.settingsLanguageZh;
    } else {
      currentLabel = l10n.settingsLanguageEn;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          child: ListTile(
            key: const Key('mine-language-setting'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currentLabel),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showLanguagePicker(context, ref, locale),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, Locale? current) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          RadioListTile<Locale?>(
            value: const Locale('zh'),
            groupValue: current,
            title: Text(l10n.settingsLanguageZh),
            onChanged: (v) => _applyLocale(ctx, ref, v),
          ),
          RadioListTile<Locale?>(
            value: const Locale('en'),
            groupValue: current,
            title: Text(l10n.settingsLanguageEn),
            onChanged: (v) => _applyLocale(ctx, ref, v),
          ),
          RadioListTile<Locale?>(
            value: null,
            groupValue: current,
            title: Text(l10n.settingsLanguageSystem),
            onChanged: (v) => _applyLocale(ctx, ref, v),
          ),
        ],
      ),
    );
  }

  void _applyLocale(BuildContext context, WidgetRef ref, Locale? locale) {
    Navigator.pop(context);
    ref.read(localeControllerProvider.notifier).setLocale(locale);
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      child: ListTile(
        key: const Key('mine-logout'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.logout, color: AppColors.danger),
        title: Text(l10n.commonLogout,
            style: const TextStyle(color: AppColors.danger)),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.commonConfirmLogout),
              content: Text(l10n.commonConfirmLogoutMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                  child: Text(l10n.commonLogoutButton,
                      style: const TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
