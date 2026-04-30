import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_detail_controller.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

class TenantEditPage extends ConsumerStatefulWidget {
  const TenantEditPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends ConsumerState<TenantEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _submitting = false;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    if (ref.read(appModeProvider).isLive) {
      final role = ref.read(sessionControllerProvider).role?.wireName ??
          'platform_admin';
      final r = await ApiCache.instance.updateTenantRemote(role, widget.id, {
        'name': _nameCtrl.text.trim(),
      });
      if (!mounted) return;
      if (!r.ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(r.message ?? '更新失败')));
        setState(() => _submitting = false);
        return;
      }
      await ApiCache.instance.refreshTenants(role);
    }
    ref.read(tenantListControllerProvider.notifier).refresh();
    ref.read(tenantDetailControllerProvider(widget.id).notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('租户信息已更新')));
    context.go('/ops/admin/${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(tenantDetailControllerProvider(widget.id));
    if (!_inited && detail.tenant != null) {
      _nameCtrl.text = detail.tenant!.name;
      _inited = true;
    }
    return Scaffold(
      key: Key('page-tenant-edit-${widget.id}'),
      appBar: AppBar(title: const Text('编辑租户')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('tenant-edit-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '租户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入租户名称' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: const Key('tenant-edit-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? '保存中…' : '保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
