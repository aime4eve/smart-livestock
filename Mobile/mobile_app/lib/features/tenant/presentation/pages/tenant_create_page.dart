import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/core/utils/timezone_options.dart';
import 'package:hkt_livestock_agentic/features/admin/presentation/admin_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Platform-admin tenant creation form (backend POST /admin/tenants).
/// Ruling 2026-10-12: opening a tenant for a HOSTED customer starts here;
/// the pilot license is granted from the tenant detail page afterwards.
class TenantCreatePage extends ConsumerStatefulWidget {
  const TenantCreatePage({super.key});

  @override
  ConsumerState<TenantCreatePage> createState() => _TenantCreatePageState();
}

class _TenantCreatePageState extends ConsumerState<TenantCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _creating = false;
  late String? _timezone = optionForOffset(activeTzOffsetMinutes())?.name;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final tenant = await ref.read(adminRepositoryProvider).createTenant({
        'name': _nameCtrl.text.trim(),
        'contactName': _contactNameCtrl.text.trim(),
        'contactPhone': _contactPhoneCtrl.text.trim(),
        if (_timezone != null) 'timezone': _timezone,
      });
      if (!mounted) return;
      ref.invalidate(tenantListControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        key: const Key('tenant-create-success'),
        content: Text('${l10n.tenantCreateSuccess}(${tenant.name})'),
        backgroundColor: const Color(0xFF2E7D32),
      ));
      context.go('/ops/admin');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        key: const Key('tenant-create-error'),
        content: Text('${l10n.tenantCreateFailed} $e'),
        backgroundColor: const Color(0xFFD32F2F),
      ));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tenantCreateTitle)),
      body: SingleChildScrollView(
        key: const Key('page-tenant-create'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('create-tenant-name'),
                controller: _nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.tenantCreateNameLabel,
                  hintText: l10n.tenantCreateNameHint,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.tenantCreateNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('create-tenant-contact-name'),
                controller: _contactNameCtrl,
                decoration:
                    InputDecoration(labelText: l10n.tenantCreateContactNameLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('create-tenant-contact-phone'),
                controller: _contactPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: l10n.tenantCreateContactPhoneLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('create-tenant-timezone'),
                initialValue: _timezone,
                decoration: InputDecoration(
                    labelText: l10n.tenantTimezoneLabel,
                    helperText: l10n.tenantTimezoneHelper),
                items: timezoneDropdownItems(selected: _timezone),
                onChanged: (v) => setState(() => _timezone = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: const Key('tenant-create-submit'),
                onPressed: _creating ? null : _submit,
                child: _creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.tenantCreateSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
