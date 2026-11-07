import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-389 Task 3: platform-level locked-tile presentation policy card
/// (GET/PUT /admin/platform/display-settings, PLATFORM_ADMIN only; the
/// policy shapes every tenant's health tiles, so it is deliberately not
/// farm-scoped). A segmented two-choice control saves immediately on
/// selection — the same direct-write pattern as FeatureGateCard's quick
/// switch — and rolls back the selection when the PUT fails.
class LockedTilePolicyCard extends StatefulWidget {
  const LockedTilePolicyCard({super.key});

  @override
  State<LockedTilePolicyCard> createState() => _LockedTilePolicyCardState();
}

class _LockedTilePolicyCardState extends State<LockedTilePolicyCard> {
  static const _endpoint = '/admin/platform/display-settings';
  static const String showLocked = 'SHOW_LOCKED';
  static const String hide = 'HIDE';

  String? _policy;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final data = await ApiClient.instance.get(_endpoint);
      if (!mounted) return;
      setState(() {
        _policy = (data['lockedTilePolicy'] ?? showLocked).toString();
        _loadFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(AppLocalizations l10n, String policy) async {
    if (_saving || policy == _policy) return;
    final previous = _policy;
    setState(() {
      _saving = true;
      _policy = policy; // optimistic local update
    });
    String toast;
    try {
      final data = await ApiClient.instance
          .put(_endpoint, body: {'lockedTilePolicy': policy});
      // Echo the backend-confirmed value as the single source of truth.
      if (mounted) {
        setState(() => _policy = (data['lockedTilePolicy'] ?? policy).toString());
      }
      toast = l10n.platformLockedTilePolicySaved;
    } on ApiException catch (e) {
      // The backend's localized validation message wins (invalid policy).
      if (mounted) setState(() => _policy = previous);
      toast = e.message;
    } catch (_) {
      if (mounted) setState(() => _policy = previous);
      toast = l10n.platformLockedTilePolicySaveFailed;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toast)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: const Key('locked-tile-policy-card'),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.platformLockedTilePolicy,
              key: const Key('locked-tile-policy-title'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_loadFailed) ...[
              Text(l10n.commonLoadFailed,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.danger)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.commonRetry,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ] else
              SegmentedButton<String>(
                key: const Key('locked-tile-policy-segments'),
                segments: [
                  ButtonSegment(
                      value: showLocked,
                      label: Text(l10n.platformLockedTilePolicyShow)),
                  ButtonSegment(
                      value: hide,
                      label: Text(l10n.platformLockedTilePolicyHide)),
                ],
                selected: {_policy ?? showLocked},
                onSelectionChanged:
                    _saving ? null : (s) => _select(l10n, s.first),
              ),
          ],
        ),
      ),
    );
  }
}
