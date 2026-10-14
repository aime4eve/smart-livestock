import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/timezone_options.dart';
import 'package:hkt_livestock_agentic/features/admin/domain/admin_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TenantDetailPage extends ConsumerStatefulWidget {
  const TenantDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends ConsumerState<TenantDetailPage> {
  TenantDetail? _tenant;
  List<UserSummary> _users = [];
  String? get _tenantTimezone => _tenant?.timezone;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final tenantDetail = repo.loadTenantDetail(widget.id);
      final userList = repo.loadUsers(tenantId: widget.id);
      final results = await Future.wait<dynamic>([tenantDetail, userList]);
      if (!mounted) return;
      setState(() {
        _tenant = results[0] as TenantDetail;
        _users = (results[1] as AdminListResult<UserSummary>).items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tenantDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tenantDetailTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $_error'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final tenant = _tenant!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tenantDetailTitle)),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Tenant info ---
          HighfiCard(
            key: const Key('tenant-detail-info'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(tenant.name,
                          style: theme.textTheme.titleLarge),
                    ),
                    Icon(
                      tenant.status == 'active'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: tenant.status == 'active'
                          ? AppColors.success
                          : AppColors.danger,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (tenant.contactName != null)
                  Text('联系人: ${tenant.contactName}'),
                if (tenant.contactPhone != null)
                  Text('联系电话: ${tenant.contactPhone}'),
                Row(
                  children: [
                    Text('时区: ${tenant.timezone ?? "未设置(跟随平台默认)"}'),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      key: const Key('tenant-edit-timezone'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showEditTimezoneDialog(context),
                      tooltip: '修改时区',
                    ),
                  ],
                ),
                Text('阶段: ${tenant.phase ?? "-"}'),
                Text(
                    '牧场: ${tenant.farmCount} · 用户: ${tenant.userCount} · 设备: ${tenant.deviceCount}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Pilot license (ruling 2026-10-12: per-tenant deadline) ---
          HighfiCard(
            key: const Key('tenant-detail-pilot'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tenantPilotCardTitle,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.tenantPilotCardDesc,
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const Key('tenant-detail-pilot-grant'),
                  onPressed: () => _showGrantPilotDialog(context),
                  icon: const Icon(Icons.verified),
                  label: Text(l10n.tenantPilotGrantButton),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- User list ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('用户列表 (${_users.length})',
                  style: theme.textTheme.titleMedium),
              Row(
                children: [
                  IconButton(
                    key: const Key('tenant-users-refresh'),
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    key: const Key('tenant-create-user'),
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('新增用户'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_users.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('暂无用户')),
            )
          else
            ..._users.map((user) => _UserCard(
                  user: user,
                  onStatusToggle: () => _toggleUserStatus(user),
                )),
        ],
        ),
      ),
    );
  }

  void _showEditTimezoneDialog(BuildContext context) {
    String? selected = _tenantTimezone;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('edit-timezone-dialog'),
          title: const Text('修改时区'),
          content: DropdownButtonFormField<String>(
            key: const Key('edit-timezone-dropdown'),
            initialValue: selected,
            decoration: const InputDecoration(labelText: '所在时区'),
            items: [null, ...kTimezoneOptions.map((o) => o.name)]
                .map((tz) => DropdownMenuItem<String>(
                      value: tz,
                      child: Text(tz == null
                          ? '未设置(跟随平台默认)'
                          : kTimezoneOptions
                              .firstWhere((o) => o.name == tz,
                                  orElse: () => TimezoneOption(tz, 0, tz))
                              .label),
                    ))
                .toList(),
            onChanged: (v) => setDialogState(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('edit-timezone-confirm'),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      try {
                        await ref.read(adminRepositoryProvider).updateTenant(
                              widget.id,
                              {'timezone': selected},
                            );
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(
                          content: Text('时区已更新'),
                          backgroundColor: Color(0xFF2E7D32),
                        ));
                        _loadData();
                      } catch (e) {
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(SnackBar(
                          content: Text('更新失败: $e'),
                          backgroundColor: const Color(0xFFD32F2F),
                        ));
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrantPilotDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    bool granting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('grant-pilot-dialog'),
          title: Text(AppLocalizations.of(context)!.tenantPilotDialogTitle),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.tenantPilotDialogDesc,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  ListTile(
                    key: const Key('grant-pilot-deadline'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(selectedDate == null
                        ? AppLocalizations.of(context)!.tenantPilotDeadlineNone
                        : AppLocalizations.of(context)!.tenantPilotDeadlineChosen(
                            selectedDate!.toIso8601String().substring(0, 10),
                            _tenantTimezone ?? 'UTC')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: now.add(const Duration(days: 365)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: granting ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('grant-pilot-confirm'),
              onPressed: granting
                  ? null
                  : () => _handleGrantPilot(
                        ctx,
                        formKey,
                        selectedDate,
                        () => setDialogState(() => granting = true),
                        () => setDialogState(() => granting = false),
                      ),
              child: granting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(AppLocalizations.of(context)!.tenantPilotGrantButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGrantPilot(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    DateTime? selectedDate,
    VoidCallback setGranting,
    VoidCallback clearGranting,
  ) async {
    if (!formKey.currentState!.validate()) return;
    setGranting();
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(dialogCtx);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final grant = await ref
          .read(adminRepositoryProvider)
          .grantPilotLicense(
              widget.id,
              selectedDate?.toIso8601String().substring(0, 10));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        key: const Key('grant-pilot-success'),
        content: Text('${l10n.tenantPilotGrantSuccessPrefix}${grant.trialEndsAt}'),
        backgroundColor: const Color(0xFF2E7D32),
      ));
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        key: const Key('grant-pilot-error'),
        content: Text('${l10n.tenantPilotGrantFailedPrefix} $e'),
        backgroundColor: const Color(0xFFD32F2F),
      ));
    } finally {
      clearGranting();
    }
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final phoneCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'B2B_ADMIN';
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('create-user-dialog'),
          title: const Text('新增用户'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('create-user-phone'),
                    controller: phoneCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '手机号 *',
                      hintText: '请输入11位手机号',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '手机号不能为空';
                      if (!RegExp(r'^1\d{10}$').hasMatch(v.trim())) {
                        return '请输入正确的11位手机号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('create-user-name'),
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '姓名 *',
                      hintText: '请输入姓名',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '姓名不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('create-user-password'),
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码 *',
                      hintText: '请输入密码',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '密码不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('create-user-role'),
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: '角色'),
                    items: const [
                      DropdownMenuItem(
                          value: 'B2B_ADMIN', child: Text('B端管理员')),
                      DropdownMenuItem(
                          value: 'OWNER', child: Text('牧场主')),
                      DropdownMenuItem(
                          value: 'WORKER', child: Text('牧工')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedRole = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: creating ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('create-user-confirm'),
              onPressed: creating
                  ? null
                  : () => _handleCreateUser(
                        ctx,
                        formKey,
                        phoneCtrl,
                        accountCtrl,
                        emailCtrl,
                        usernameCtrl,
                        nameCtrl,
                        passwordCtrl,
                        selectedRole,
                        () => setDialogState(() => creating = true),
                        () => setDialogState(() => creating = false),
                      ),
              child: creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateUser(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    TextEditingController phoneCtrl,
    TextEditingController accountCtrl,
    TextEditingController emailCtrl,
    TextEditingController usernameCtrl,
    TextEditingController nameCtrl,
    TextEditingController passwordCtrl,
    String role,
    VoidCallback setCreating,
    VoidCallback clearCreating,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setCreating();

    final navigator = Navigator.of(dialogCtx);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final phone = phoneCtrl.text.trim();
      final account = accountCtrl.text.trim();
      final email = emailCtrl.text.trim();
      if (phone.isEmpty && account.isEmpty && email.isEmpty) {
        throw '用户账号/手机号/邮箱至少填写一项';
      }
      await ref.read(adminRepositoryProvider).createUser({
        'name': nameCtrl.text.trim(),
        'password': passwordCtrl.text,
        'role': role,
        'tenantId': int.parse(widget.id),
        if (phone.isNotEmpty) 'phone': phone,
        if (account.isNotEmpty) 'account': account,
        if (email.isNotEmpty) 'email': email,
        if (usernameCtrl.text.trim().isNotEmpty)
          'username': usernameCtrl.text.trim(),
      });

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('用户「${nameCtrl.text.trim()}」创建成功'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('创建失败: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      clearCreating();
    }
  }

  Future<void> _toggleUserStatus(UserSummary user) async {
    final newStatus = user.status == 'active' ? 'disabled' : 'active';
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateUserStatus(user.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('用户「${user.name}」已${newStatus == 'active' ? '启用' : '停用'}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onStatusToggle});
  final UserSummary user;
  final VoidCallback onStatusToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('user-${user.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role ?? '-',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('手机号: ${user.phone ?? "-"}'),
                  if (user.account != null && user.account!.isNotEmpty)
                    Text('账号: ${user.account}'),
                  if (user.email != null && user.email!.isNotEmpty)
                    Text('邮箱: ${user.email}'),
                ],
              ),
            ),
            IconButton(
              key: Key('toggle-user-${user.id}'),
              onPressed: onStatusToggle,
              icon: Icon(
                user.status == 'active'
                    ? Icons.toggle_on
                    : Icons.toggle_off,
                color: user.status == 'active'
                    ? AppColors.success
                    : AppColors.danger,
              ),
              tooltip: user.status == 'active' ? '停用' : '启用',
            ),
          ],
        ),
      ),
    );
  }
}
