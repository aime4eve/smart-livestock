import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantCreatePage extends ConsumerStatefulWidget {
  const TenantCreatePage({super.key});

  @override
  ConsumerState<TenantCreatePage> createState() => _TenantCreatePageState();
}

class _TenantCreatePageState extends ConsumerState<TenantCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController(text: '100');
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final mode = ref.read(appModeProvider);
    if (mode.isLive) {
      final role = ref.read(sessionControllerProvider).role?.name ?? 'ops';
      final result = await ApiCache.instance.createTenantRemote(role, {
        'name': _nameCtrl.text.trim(),
        'licenseTotal': int.parse(_licenseCtrl.text),
      });
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ?? '创建失败'),
        ));
        setState(() => _submitting = false);
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('租户创建成功')),
    );
    context.go('/ops/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('page-tenant-create'),
      appBar: AppBar(title: const Text('创建租户')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('tenant-create-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '租户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入租户名称' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('tenant-create-license'),
                controller: _licenseCtrl,
                decoration: const InputDecoration(
                  labelText: '初始 License',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return '请输入非负整数';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: const Key('tenant-create-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '提交中…' : '创建'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
