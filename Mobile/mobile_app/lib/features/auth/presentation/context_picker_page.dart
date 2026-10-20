import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/auth/context_picker_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Super-admin entry-context picker (design 2026-10-19 §4.7, UI spec §2.1-2.3):
/// step 1 = role cards, step 2 = tenant list for tenant-scoped roles, then a
/// bottom confirm sheet (normal / disabled-tenant warning variants).
class ContextPickerPage extends ConsumerStatefulWidget {
  const ContextPickerPage({super.key});

  @override
  ConsumerState<ContextPickerPage> createState() => _ContextPickerPageState();
}

class _ContextPickerPageState extends ConsumerState<ContextPickerPage> {
  int _step = 0;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final picker = ref.watch(contextPickerControllerProvider);
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: _step == 1,
        title: Text(
          _step == 0 ? l10n.superPickerTitle : l10n.superTenantTitle,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        actions: [
          if (_step == 1 && picker.selectedRole != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _RoleChip(role: picker.selectedRole!.role),
              ),
            ),
        ],
      ),
      body: picker.loading
          ? const Center(child: CircularProgressIndicator())
          : picker.loadFailed
              ? _LoadFailedView(onRetry: () =>
                  ref.read(contextPickerControllerProvider.notifier).load())
              : _step == 0
                  ? _buildRoleStep(l10n, picker, session)
                  : _buildTenantStep(l10n, picker),
    );
  }

  // ── Step 1: role cards (UI spec §2.1) ─────────────────────────────

  Widget _buildRoleStep(
      AppLocalizations l10n, ContextPickerState picker, AppSession session) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _WhoCard(session: session),
                const SizedBox(height: 10),
                _NoteBox(
                  icon: Icons.info_outline,
                  iconColor: AppColors.info,
                  background: AppColors.infoSoft,
                  text: l10n.superPickerAuditNote,
                  textColor: AppColors.info,
                ),
                const SizedBox(height: 10),
                for (final role in picker.roles) ...[
                  _RoleCard(
                    role: role,
                    selected: picker.selectedRole?.role == role.role,
                    onTap: () => _onRoleTapped(role),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.superPickerSubtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                TextButton(
                  key: const Key('super-picker-logout'),
                  onPressed: () async {
                    await ref.read(sessionControllerProvider.notifier).logout();
                  },
                  child: Text(l10n.superPickerLogout,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onRoleTapped(EntryRoleOption role) {
    final controller = ref.read(contextPickerControllerProvider.notifier);
    controller.selectRole(role);
    if (role.tenantScoped) {
      setState(() => _step = 1);
    } else {
      _showConfirmSheet();
    }
  }

  // ── Step 2: tenant list (UI spec §2.2) ────────────────────────────

  Widget _buildTenantStep(AppLocalizations l10n, ContextPickerState picker) {
    final query = _search.trim().toLowerCase();
    final tenants = query.isEmpty
        ? picker.tenants
        : picker.tenants
            .where((t) => t.name.toLowerCase().contains(query))
            .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              key: const Key('super-tenant-search'),
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: l10n.superTenantSearchHint,
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              children: [
                for (final tenant in tenants) ...[
                  _TenantCard(
                    tenant: tenant,
                    selected:
                        picker.selectedTenant?.id == tenant.id,
                    onTap: tenant.enterable
                        ? () {
                            ref
                                .read(contextPickerControllerProvider.notifier)
                                .selectTenant(tenant);
                            _showConfirmSheet();
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.superTenantCount(picker.tenants.length),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm sheet (UI spec §2.3) ──────────────────────────────────

  void _showConfirmSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final l10n = AppLocalizations.of(sheetContext)!;
            final picker = ref.watch(contextPickerControllerProvider);
            final tenant = picker.selectedTenant;
            final disabledTenant = tenant?.disabled ?? false;
            return _ConfirmSheet(
              l10n: l10n,
              picker: picker,
              disabledTenant: disabledTenant,
              onCancel: () => Navigator.of(sheetContext).pop(),
              onEnter: () async {
                final error = await ref
                    .read(contextPickerControllerProvider.notifier)
                    .confirmEnter();
                if (!sheetContext.mounted) return;
                // Pop first so an error snackbar is never hidden behind the
                // modal barrier.
                Navigator.of(sheetContext).pop();
                if (error != null) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.danger),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────

class _WhoCard extends StatelessWidget {
  const _WhoCard({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final display =
        (session.username?.isNotEmpty == true) ? session.username! : (session.userName ?? '');
    final initial = display.isEmpty ? 'A' : display.characters.first;
    return Container(
      key: const Key('super-who-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14263A26), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(display,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      text: l10n.superPickerBadge,
                      color: AppColors.rolePlatform,
                      background: AppColors.rolePlatformSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(l10n.superPickerSubtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 10.5, height: 1.5, color: textColor)),
          ),
        ],
      ),
    );
  }
}

class _RoleVisual {
  final String Function(AppLocalizations) label;
  final String Function(AppLocalizations) description;
  final Color color;
  final Color soft;
  final IconData icon;
  const _RoleVisual(this.label, this.description, this.color, this.soft, this.icon);
}

_RoleVisual? _roleVisual(String role) {
  switch (role) {
    case 'PLATFORM_ADMIN':
      return _RoleVisual(
          (l) => l.superPickerRolePlatformAdmin,
          (l) => l.superPickerDescPlatformAdmin,
          AppColors.rolePlatform,
          AppColors.rolePlatformSoft,
          Icons.settings_outlined);
    case 'B2B_ADMIN':
      return _RoleVisual(
          (l) => l.superPickerRoleB2bAdmin,
          (l) => l.superPickerDescB2bAdmin,
          AppColors.roleB2b,
          AppColors.roleB2bSoft,
          Icons.dashboard_outlined);
    case 'OWNER':
      return _RoleVisual(
          (l) => l.superPickerRoleOwner,
          (l) => l.superPickerDescOwner,
          AppColors.roleOwner,
          AppColors.roleOwnerSoft,
          Icons.agriculture_outlined);
    case 'WORKER':
      return _RoleVisual(
          (l) => l.superPickerRoleWorker,
          (l) => l.superPickerDescWorker,
          AppColors.roleWorker,
          AppColors.roleWorkerSoft,
          Icons.construction_outlined);
  }
  return null;
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final EntryRoleOption role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = _roleVisual(role.role);
    if (visual == null) return const SizedBox.shrink();
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('super-role-${role.role}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14263A26),
                  blurRadius: 10,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(visual.icon, size: 17, color: visual.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visual.label(l10n),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(visual.description(l10n),
                        style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _StatusChip(
                text: role.tenantScoped
                    ? l10n.superPickerScopeTenant
                    : l10n.superPickerScopePlatform,
                color: role.tenantScoped ? visual.color : AppColors.info,
                background:
                    role.tenantScoped ? visual.soft : AppColors.infoSoft,
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 11, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = _roleVisual(role);
    if (visual == null) return const SizedBox.shrink();
    return _StatusChip(
        text: visual.label(l10n),
        color: visual.color,
        background: visual.soft);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.selected,
    required this.onTap,
  });

  final TenantOption tenant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final barColor = !tenant.enterable
        ? AppColors.border
        : tenant.disabled
            ? AppColors.warning
            : selected
                ? AppColors.primary
                : AppColors.border;
    final phaseLabel = tenant.phase == 'BATCH'
        ? l10n.superTenantPhaseBatch
        : l10n.superTenantPhaseTrial;
    return Opacity(
      opacity: tenant.enterable ? 1 : 0.55,
      child: Material(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('super-tenant-${tenant.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: barColor, width: 4),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14263A26),
                    blurRadius: 10,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(tenant.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 6),
                          if (tenant.trialExpired)
                            _StatusChip(
                              text: l10n.superTenantTrialExpired,
                              color: AppColors.danger,
                              background: AppColors.dangerSoft,
                            )
                          else if (tenant.disabled)
                            _StatusChip(
                              text: l10n.superTenantStatusDisabled,
                              color: AppColors.warning,
                              background: AppColors.warningSoft,
                            )
                          else
                            _StatusChip(
                              text: l10n.superTenantStatusActive,
                              color: AppColors.success,
                              background: AppColors.successSoft,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (tenant.disabled)
                            '⚠ ${l10n.superTenantDisabledHint}',
                          phaseLabel,
                          l10n.superTenantFarms(tenant.farmCount),
                          if (tenant.timezone != null) tenant.timezone!,
                          if (tenant.trialExpired)
                            l10n.superTenantNotEnterable,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (tenant.enterable)
                  _RadioDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.l10n,
    required this.picker,
    required this.disabledTenant,
    required this.onCancel,
    required this.onEnter,
  });

  final AppLocalizations l10n;
  final ContextPickerState picker;
  final bool disabledTenant;
  final VoidCallback onCancel;
  final Future<void> Function() onEnter;

  @override
  Widget build(BuildContext context) {
    final role = picker.selectedRole!;
    final tenant = picker.selectedTenant;
    final visual = _roleVisual(role.role)!;
    final roleLabel = visual.label(l10n);
    final tenantLabel = tenant?.name ?? '';
    return Container(
      key: const Key('super-confirm-sheet'),
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
            Text(l10n.superConfirmTitle,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (tenant != null) ...[
                    Text(tenantLabel,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Text('·',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                  Text(roleLabel,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: visual.color)),
                  if (disabledTenant && tenant != null)
                    _StatusChip(
                      text: l10n.superTenantStatusDisabled,
                      color: AppColors.warning,
                      background: AppColors.warningSoft,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.superConfirmBody(tenantLabel.isEmpty ? roleLabel : tenantLabel,
                  roleLabel),
              style: const TextStyle(
                  fontSize: 11, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (disabledTenant) ...[
              _NoteBox(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                background: AppColors.warningSoft,
                text: l10n.superConfirmDisabledWarning,
                textColor: AppColors.warning,
              ),
              const SizedBox(height: 10),
            ],
            _NoteBox(
              icon: Icons.info_outline,
              iconColor: AppColors.info,
              background: AppColors.infoSoft,
              text: l10n.superConfirmAuditNote,
              textColor: AppColors.info,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.superActionCancel,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('super-confirm-enter'),
                    onPressed: picker.switching ? null : () => onEnter(),
                    style: FilledButton.styleFrom(
                      backgroundColor: disabledTenant
                          ? AppColors.warning
                          : AppColors.primary,
                      disabledBackgroundColor: disabledTenant
                          ? AppColors.warning.withValues(alpha: 0.5)
                          : AppColors.primary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: picker.switching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            disabledTenant
                                ? l10n.superConfirmEnterAnyway
                                : l10n.superConfirmEnter,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _LoadFailedView extends StatelessWidget {
  const _LoadFailedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 28, color: AppColors.danger),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
