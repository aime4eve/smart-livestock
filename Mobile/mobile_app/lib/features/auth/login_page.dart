import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.onSubmit, this.onTokenSubmit});

  final ValueChanged<DemoRole> onSubmit;
  final ValueChanged<String>? onTokenSubmit;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  DemoRole _selectedRole = DemoRole.worker;

  // Live-mode form state
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCredentialLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final ok = await ref
          .read(sessionControllerProvider.notifier)
          .loginWithCredentials(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登录失败，请检查手机号和密码'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F2E5), AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HighfiCard(
                        key: const Key('login-hero-card'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '智慧畜牧',
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              appMode.isMock
                                  ? '围绕虚拟围栏、实时定位与告警闭环的高保真演示入口。'
                                  : '登录您的牧场账户，管理牲畜、围栏与告警。',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            HighfiStatusChip(
                              label:
                                  appMode.isMock ? 'Mock 模式' : 'Live 模式',
                              color: appMode.isMock
                                  ? AppColors.info
                                  : AppColors.success,
                              icon: appMode.isMock
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      switch (appMode) {
                        AppMode.mock => _buildMockForm(),
                        AppMode.live => _buildCredentialForm(),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockForm() {
    return HighfiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择演示角色',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _RoleButton(
                buttonKey: const Key('role-worker'),
                label: 'worker',
                selected: _selectedRole == DemoRole.worker,
                onTap: () =>
                    setState(() => _selectedRole = DemoRole.worker),
              ),
              _RoleButton(
                buttonKey: const Key('role-owner'),
                label: 'owner',
                selected: _selectedRole == DemoRole.owner,
                onTap: () =>
                    setState(() => _selectedRole = DemoRole.owner),
              ),
              _RoleButton(
                buttonKey: const Key('role-platform-admin'),
                label: '平台管理员',
                selected: _selectedRole == DemoRole.platformAdmin,
                onTap: () => setState(
                  () => _selectedRole = DemoRole.platformAdmin,
                ),
              ),
              _RoleButton(
                buttonKey: const Key('role-b2b-admin'),
                label: 'B端客户',
                selected: _selectedRole == DemoRole.b2bAdmin,
                onTap: () =>
                    setState(() => _selectedRole = DemoRole.b2bAdmin),
              ),
              _RoleButton(
                buttonKey: const Key('role-api-consumer'),
                label: 'API客户',
                selected: _selectedRole == DemoRole.apiConsumer,
                onTap: () =>
                    setState(() => _selectedRole = DemoRole.apiConsumer),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('token-input'),
            decoration: const InputDecoration(
              labelText: '直接输入 Token',
              hintText: 'mock-token-xxx',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: widget.onTokenSubmit,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('login-submit'),
              onPressed: () => widget.onSubmit(_selectedRole),
              child: const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialForm() {
    return HighfiCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '账号登录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('login-phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号',
                prefixIcon: Icon(Icons.phone_android),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入手机号';
                if (!RegExp(r'^1\d{10}$').hasMatch(v.trim())) {
                  return '请输入正确的11位手机号';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('login-password'),
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                prefixIcon: Icon(Icons.lock_outline),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入密码';
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleCredentialLogin(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('login-submit'),
                onPressed: _isSubmitting ? null : _handleCredentialLogin,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primarySoft : null,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(label),
    );
  }
}
