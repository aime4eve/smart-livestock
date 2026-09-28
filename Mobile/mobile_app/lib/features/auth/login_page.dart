import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/l10n/locale_controller.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/auth/app_download_launcher.dart';
import 'package:hkt_livestock_agentic/features/auth/data/deployment_info.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:http/http.dart' as http;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

/// Injected by every build script as --dart-define=APP_VERSION
/// ("<majorVersion>-b<build.number>", single source: backend build files).
/// Empty on untagged debug builds — the footer is hidden then.
const String _appVersion = String.fromEnvironment('APP_VERSION');

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  /// Version of the downloadable packages (from /downloads/versions.json),
  /// null while unavailable — the caption stays hidden then, links keep working.
  String? _packageVersion;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _loadPackageVersion();
  }

  /// Best-effort fetch of the download manifest; any failure leaves the
  /// caption hidden. Never blocks login.
  Future<void> _loadPackageVersion() async {
    try {
      final uri =
          Uri.parse('${Uri.base.origin}/downloads/versions.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;
      final version =
          (jsonDecode(res.body) as Map<String, dynamic>)['version']
                  ?.toString() ??
              '';
      if (mounted && version.isNotEmpty) {
        setState(() => _packageVersion = version);
      }
    } catch (_) {
      // Manifest is optional decoration — silent degrade.
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCredentialLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final ok = await ref
          .read(sessionControllerProvider.notifier)
          .login(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoginCheckInput),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.commonLoadFailed}: $e'),
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
    final l10n = AppLocalizations.of(context)!;
    final deploymentInfo = ref.watch(deploymentInfoProvider);
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
                      // Language switch
                      Align(
                        alignment: Alignment.centerRight,
                        child: _LanguageToggle(ref: ref),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      HighfiCard(
                        key: const Key('login-hero-card'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n.authAppTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                ),
                                if (_appVersion.isNotEmpty) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'v$_appVersion',
                                    key: const Key('login-app-version'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.authLoginDescription,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // License-mode display (NIX-184): driven by the
                            // public deployment-info endpoint; hidden entirely
                            // when it is unavailable so login never blocks.
                            deploymentInfo.when(
                              skipLoadingOnReload: true,
                              data: (info) => info == null
                                  ? const SizedBox.shrink()
                                  : _LicenseModeBadge(info: info),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HighfiCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.authLoginFormTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                key: const Key('login-phone'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                decoration: InputDecoration(
                                  labelText: l10n.authPhoneLabel,
                                  hintText: l10n.authPhoneHint,
                                  prefixIcon: const Icon(Icons.phone_android),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return l10n.authPhoneHint;
                                  if (!RegExp(r'^1\d{10}$').hasMatch(v.trim())) {
                                    return l10n.authPhoneInvalid;
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
                                decoration: InputDecoration(
                                  labelText: l10n.authPasswordLabel,
                                  hintText: l10n.authPasswordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return l10n.authPasswordHint;
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
                                      : Text(l10n.authLoginButton),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Compact app-download row (prototype 方案B): web only —
                      // native users already have the app installed.
                      if (kIsWeb) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _AppDownloadRow(version: _packageVersion),
                      ],
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

/// License-mode badge + banner, mirroring the reviewed prototype
/// (docs/marketing/nix-184-login-license-mode-prototype.html).
class _LicenseModeBadge extends StatelessWidget {
  const _LicenseModeBadge({required this.info});
  final DeploymentInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!info.isOnprem) {
      return HighfiStatusChip(
        key: const Key('license-mode-chip'),
        label: l10n.authModeHosted,
        color: AppColors.success,
        icon: Icons.cloud_outlined,
      );
    }
    final status = info.runtimeStatus;
    // NIX-191: a fresh install has no state row (null) until the scheduler's
    // first tick — that IS the bootstrap/pending state for the deployer.
    final (chipColor, bannerColor, bannerText) = switch (status) {
      'PENDING_ACTIVATION' || null => (
          AppColors.warning,
          AppColors.warning,
          l10n.authModePendingBanner,
        ),
      'EXPIRED' => (
          AppColors.danger,
          AppColors.danger,
          l10n.authModeExpiredBanner,
        ),
      'SUSPENDED' => (
          AppColors.danger,
          AppColors.danger,
          l10n.authModeSuspendedBanner,
        ),
      _ => (AppColors.info, null, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighfiStatusChip(
          key: const Key('license-mode-chip'),
          // Keep the label short: HighfiStatusChip does not wrap, and the
          // "offline license active" nuance is carried by the banner states.
          label: l10n.authModeOnprem,
          color: chipColor,
          icon: Icons.dns_outlined,
        ),
        if (bannerText != null && bannerColor != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            key: Key('license-mode-banner-$status'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: bannerColor == AppColors.warning
                  ? const Color(0xFFF7ECDC)
                  : const Color(0xFFF6E4E2),
              border: Border(
                left: BorderSide(color: bannerColor, width: 4),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text(
              bannerText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.5),
            ),
          ),
          // NIX-191: one-tap enrollment info copy for the zero-account
          // bootstrap state — the deployer never types the raw API URL.
          if (status == 'PENDING_ACTIVATION' || status == null) ...[
            const SizedBox(height: AppSpacing.sm),
            _CopyEnrollmentButton(),
          ],
        ],
      ],
    );
  }
}

class _CopyEnrollmentButton extends StatefulWidget {
  @override
  State<_CopyEnrollmentButton> createState() => _CopyEnrollmentButtonState();
}

class _CopyEnrollmentButtonState extends State<_CopyEnrollmentButton> {
  bool _busy = false;

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final data = await ApiClient.instance.get(
        '/deployment-license/enrollment',
      );
      final installationId = data['installationId']?.toString() ?? '';
      final fingerprintHash = data['fingerprintHash']?.toString() ?? '';
      if (installationId.isEmpty || fingerprintHash.isEmpty) {
        throw const FormatException('empty enrollment payload');
      }
      await Clipboard.setData(ClipboardData(
        text: '安装ID: $installationId\n指纹: $fingerprintHash',
      ));
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.loginEnrollmentCopied),
        backgroundColor: AppColors.success,
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.loginEnrollmentFailed),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const Key('copy-enrollment'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: _busy
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.copy_all_outlined, size: 16),
      label: Text(l10n.loginCopyEnrollmentInfo),
      onPressed: _busy ? null : _copy,
    );
  }
}

class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final label = current?.languageCode == 'en' ? '中文' : 'EN';
    final target = current?.languageCode == 'en'
        ? const Locale('zh')
        : const Locale('en');
    return TextButton(
      onPressed: () =>
          ref.read(localeControllerProvider.notifier).setLocale(target),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// Compact single-line download entry under the login card (prototype
/// docs/prototypes/2026-09-28-login-app-download-prototype.html, 方案B).
/// Packages are served by nginx from /downloads/ on every environment;
/// the link pointing at the device's own platform gets a heavier weight.
class _AppDownloadRow extends StatelessWidget {
  const _AppDownloadRow({required this.version});

  final String? version;

  static const _apkPath = '/downloads/hkt-livestock-latest.apk';
  static const _ipaPath = '/downloads/hkt-livestock-latest.ipa';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        );
    final origin = Uri.base.origin;

    return Wrap(
      key: const Key('login-download-row'),
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          l10n.loginDownloadAppLabel,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        _DownloadLink(
          key: const Key('download-android'),
          label: l10n.loginDownloadAndroid,
          icon: Icons.android_outlined,
          url: '$origin$_apkPath',
          emphasized: defaultTargetPlatform == TargetPlatform.android,
        ),
        Text('·', style: captionStyle),
        _DownloadLink(
          key: const Key('download-ios'),
          label: l10n.loginDownloadIos,
          icon: Icons.phone_iphone,
          url: '$origin$_ipaPath',
          emphasized: defaultTargetPlatform == TargetPlatform.iOS,
        ),
        if (version != null) Text('v$version', style: captionStyle),
      ],
    );
  }
}

class _DownloadLink extends StatelessWidget {
  const _DownloadLink({
    super.key,
    required this.label,
    required this.icon,
    required this.url,
    required this.emphasized,
  });

  final String label;
  final IconData icon;
  final String url;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => launchAppDownload(url),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: const Size(0, 32),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
