import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSubmit});

  final ValueChanged<DemoRole> onSubmit;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  DemoRole _selectedRole = DemoRole.worker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F2E5), AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '围绕虚拟围栏、实时定位与告警闭环的高保真演示入口。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const HighfiStatusChip(
                          label: 'Mock 模式',
                          color: AppColors.info,
                          icon: Icons.cloud_done_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  HighfiCard(
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
                              buttonKey: const Key('role-ops'),
                              label: 'ops',
                              selected: _selectedRole == DemoRole.ops,
                              onTap: () =>
                                  setState(() => _selectedRole = DemoRole.ops),
                            ),
                          ],
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
                  ),
                ],
              ),
            ),
          ),
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
