import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-191: accounts whose initial password came from the issuing tool are
/// locked here until they set a personal password (>= 10 chars, letters and
/// digits). The backend rejects every other API with
/// PASSWORD_CHANGE_REQUIRED until the change succeeds.
class ForcedPasswordChangePage extends ConsumerStatefulWidget {
  const ForcedPasswordChangePage({super.key});

  @override
  ConsumerState<ForcedPasswordChangePage> createState() =>
      _ForcedPasswordChangePageState();
}

class _ForcedPasswordChangePageState
    extends ConsumerState<ForcedPasswordChangePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.forcedChangeMismatch),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.put('/me/password', body: {
        'oldPassword': _currentController.text,
        'newPassword': _newController.text,
      });
      if (!mounted) return;
      ref.read(sessionControllerProvider.notifier).markPasswordChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.forcedChangeSuccess),
        backgroundColor: AppColors.success,
      ));
      final role = ref.read(sessionControllerProvider).role;
      context.go(role == UserRole.platformAdmin
          ? AppRoute.platformAdmin.path
          : AppRoute.ranch.path);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.forcedChangeTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(l10n.forcedChangeHint,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('forced-current'),
                        controller: _currentController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.forcedChangeCurrent),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.forcedChangeRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('forced-new'),
                        controller: _newController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.forcedChangeNew),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.length < 10 ||
                              !value.contains(RegExp(r'[A-Za-z]')) ||
                              !value.contains(RegExp(r'[0-9]'))) {
                            return l10n.errorPasswordWeak;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('forced-confirm'),
                        controller: _confirmController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: l10n.forcedChangeConfirm),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.forcedChangeRequired : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('forced-submit'),
                        onPressed: _submitting ? null : _submit,
                        child: Text(l10n.forcedChangeSubmit),
                      ),
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
}
