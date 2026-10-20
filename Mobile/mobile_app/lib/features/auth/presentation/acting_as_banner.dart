import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_decoder.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_storage.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Mount scope for the acting-as banner (design 2026-10-19 §4.7): wraps the
/// shell content of a context session. Renders nothing for regular users.
class SuperContextBannerScope extends ConsumerWidget {
  const SuperContextBannerScope({super.key, required this.child, this.dense = true});

  final Widget child;

  /// dense = desktop shells' single line; the ranch shell shows the audit
  /// subtext as a second line (UI spec §2.4).
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.impersonated) return child;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ActingAsBanner(dense: dense),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class ActingAsBanner extends ConsumerWidget {
  const ActingAsBanner({super.key, required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    final roleLabel = _roleLabel(l10n, session.role);
    final tenantName = session.impersonatedTenantName;

    return Container(
      key: const Key('acting-as-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 15, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantName == null
                      ? '${l10n.superBannerTag} · ${l10n.superBannerActingAsPlatform(roleLabel)}'
                      : '${l10n.superBannerTag} · ${l10n.superBannerActingAs(tenantName, roleLabel)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AppColors.warning),
                ),
                if (!dense)
                  Text(l10n.superBannerAuditSubtext,
                      style: TextStyle(
                          fontSize: 9.5,
                          height: 1.4,
                          color: AppColors.warning.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniButton(
            key: const Key('acting-as-switch'),
            label: l10n.superBannerSwitch,
            filled: false,
            onTap: () => _onSwitchTap(context, ref),
          ),
          const SizedBox(width: 6),
          _MiniButton(
            key: const Key('acting-as-exit'),
            label: l10n.superBannerExit,
            filled: true,
            onTap: () => ref.read(sessionControllerProvider.notifier).exitContext(),
          ),
        ],
      ),
    );
  }

  Future<void> _onSwitchTap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    // Storage failures (e.g. missing plugin in tests) count as "no usable
    // root token" — the safe answer is to prompt a re-login.
    String? rootToken;
    try {
      rootToken = await JwtStorage.instance.getRootToken();
    } catch (_) {}
    final payload = rootToken == null ? null : JwtDecoder.tryDecode(rootToken);
    if (!context.mounted) return;
    final alive = payload != null && !JwtDecoder.isExpired(payload);
    if (!alive) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.superBannerSwitchExpired),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (context.mounted) {
      showQuickSwitchSheet(context);
    }
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppColors.warning;
    final background = filled ? AppColors.warning : Colors.white;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.55)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: foreground)),
        ),
      ),
    );
  }
}

/// Quick-switch sheet (UI spec §2.5, ruling #3): direct jump across contexts
/// with the root token — platform row + recent history, full picker entry,
/// and full logout. Passwordless within the token lifetime (ruling #2).
Future<void> showQuickSwitchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const _QuickSwitchSheet(),
  );
}

class _QuickSwitchSheet extends ConsumerStatefulWidget {
  const _QuickSwitchSheet();

  @override
  ConsumerState<_QuickSwitchSheet> createState() => _QuickSwitchSheetState();
}

class _QuickSwitchSheetState extends ConsumerState<_QuickSwitchSheet> {
  List<Map<String, dynamic>> _recents = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await JwtStorage.instance.getRecentContexts();
    if (mounted) setState(() => _recents = recents);
  }

  Future<void> _switchTo(String role, int? tenantId, String? tenantName) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await ref.read(sessionControllerProvider.notifier).enterContext(
          role: role,
          tenantId: tenantId,
          tenantName: tenantName,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    final currentRole = _roleLabel(l10n, session.role);
    final currentTenant = session.impersonatedTenantName;
    final currentValue = currentTenant == null
        ? currentRole
        : '$currentTenant · $currentRole';
    final currentKey = '${session.role?.wireName.toUpperCase()}@${session.tenantId}';

    return Container(
      key: const Key('quick-switch-sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.superSwitchTitle,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l10n.superSwitchCurrent(currentValue),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _QuickRow(
              key: const Key('quick-switch-platform'),
              color: AppColors.rolePlatform,
              title: l10n.superPickerRolePlatformAdmin,
              subtitle: l10n.superPickerScopePlatform,
              busy: _busy,
              onTap: () => _switchTo('PLATFORM_ADMIN', null, null),
            ),
            for (final recent in _recents)
              if ('${recent['role']}@${recent['tenantId']}' != currentKey)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _QuickRow(
                    key: Key('quick-switch-recent-${recent['role']}-${recent['tenantId']}'),
                    color: _roleColor(recent['role'] as String? ?? ''),
                    title: recent['tenantName'] == null
                        ? _wireRoleLabel(l10n, recent['role'] as String? ?? '')
                        : '${recent['tenantName']} · ${_wireRoleLabel(l10n, recent['role'] as String? ?? '')}',
                    subtitle: l10n.superSwitchRecent,
                    busy: _busy,
                    onTap: () => _switchTo(
                      recent['role'] as String,
                      recent['tenantId'] as int?,
                      recent['tenantName'] as String?,
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            _QuickRow(
              key: const Key('quick-switch-more'),
              color: AppColors.info,
              title: l10n.superSwitchMore,
              subtitle: l10n.superSwitchMoreSub,
              dashed: true,
              busy: _busy,
              onTap: () async {
                await ref
                    .read(sessionControllerProvider.notifier)
                    .exitContext();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('quick-switch-logout-all'),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(sessionControllerProvider.notifier).logout();
              },
              child: Text(l10n.superSwitchLogoutAll,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger)),
            ),
            Text(l10n.superSwitchExpiryHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dashed = false,
    this.busy = false,
  });

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dashed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: dashed ? AppColors.info : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: dashed
                                ? AppColors.info
                                : AppColors.textPrimary)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Role display helpers — mirrors the picker mapping (context_picker_page);
// roles are a fixed set so the duplication cannot drift silently.

String _roleLabel(AppLocalizations l10n, UserRole? role) {
  switch (role) {
    case UserRole.platformAdmin:
      return l10n.superPickerRolePlatformAdmin;
    case UserRole.b2bAdmin:
      return l10n.superPickerRoleB2bAdmin;
    case UserRole.owner:
      return l10n.superPickerRoleOwner;
    case UserRole.worker:
      return l10n.superPickerRoleWorker;
    default:
      return role?.name ?? '';
  }
}

String _wireRoleLabel(AppLocalizations l10n, String wire) {
  switch (wire) {
    case 'PLATFORM_ADMIN':
      return l10n.superPickerRolePlatformAdmin;
    case 'B2B_ADMIN':
      return l10n.superPickerRoleB2bAdmin;
    case 'OWNER':
      return l10n.superPickerRoleOwner;
    case 'WORKER':
      return l10n.superPickerRoleWorker;
    default:
      return wire;
  }
}

Color _roleColor(String wire) {
  switch (wire) {
    case 'PLATFORM_ADMIN':
      return AppColors.rolePlatform;
    case 'B2B_ADMIN':
      return AppColors.roleB2b;
    case 'OWNER':
      return AppColors.roleOwner;
    case 'WORKER':
      return AppColors.roleWorker;
    default:
      return AppColors.textSecondary;
  }
}
