import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/epidemic_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Canonical disease presets for the mark-diseased flow (spec §5.1).
///
/// [MarkDiseasedDiseaseOption.key] is the value submitted to
/// POST /epidemic/mark — kept identical to the V31 seed vocabulary
/// ("口蹄疫疑似" …) so stored `disease_type` renders verbatim in the
/// workbench; the backend does not enum-validate it, the frontend owns
/// this list. `label` resolves the localized chip text. Exposed for
/// reuse by the alert-entry prefill (Task 7, prototype P5).
class MarkDiseasedDiseaseOption {
  const MarkDiseasedDiseaseOption(this.key, this.label);
  final String key;
  final String Function(AppLocalizations l10n) label;
}

/// Disease chip presets (order matches prototype P1/P2).
/// Top-level `final` (not `const`) because closure literals are not
/// constant expressions in Dart.
final List<MarkDiseasedDiseaseOption> markDiseasedDiseaseOptions = [
  MarkDiseasedDiseaseOption('口蹄疫疑似', (l10n) => l10n.markDiseasedFootMouth),
  MarkDiseasedDiseaseOption('牛结核疑似', (l10n) => l10n.markDiseasedTuberculosis),
  MarkDiseasedDiseaseOption('布病疑似', (l10n) => l10n.markDiseasedBrucellosis),
  MarkDiseasedDiseaseOption('腹泻类疾病', (l10n) => l10n.markDiseasedDiarrhea),
  MarkDiseasedDiseaseOption(
    markDiseasedOtherKey,
    (l10n) => l10n.markDiseasedOther,
  ),
];

/// Sentinel key of the "Other" preset. When selected, the required
/// free-text input replaces the preset as the submitted diseaseType.
const String markDiseasedOtherKey = '其他';

/// Shared mark-diseased bottom sheet (spec §5.1, prototype P1/P2):
/// pick one disease preset (or "Other" + required custom name), confirm,
/// then jump straight to the epidemic workbench scoped to this source.
class MarkDiseasedSheet extends ConsumerStatefulWidget {
  const MarkDiseasedSheet({
    super.key,
    required this.livestockId,
    required this.livestockCode,
    this.subtitle,
  });

  final String livestockId;
  final String livestockCode;

  /// Extra "who" info rendered after the code, e.g. "母牛 · 3 号围栏"
  /// (detail page) or "母牛 · 3 号围栏（来自告警）" (alert entry).
  final String? subtitle;

  /// Opens the sheet. Callers keep ownership of navigation/toasts after
  /// success — the sheet pops itself and pushes the workbench.
  static Future<void> show(
    BuildContext context, {
    required String livestockId,
    required String livestockCode,
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Prototype scrim: rgba(38,49,38,.45).
      barrierColor: const Color(0x73263126),
      backgroundColor: AppColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => MarkDiseasedSheet(
        livestockId: livestockId,
        livestockCode: livestockCode,
        subtitle: subtitle,
      ),
    );
  }

  @override
  ConsumerState<MarkDiseasedSheet> createState() => _MarkDiseasedSheetState();
}

class _MarkDiseasedSheetState extends ConsumerState<MarkDiseasedSheet> {
  final _otherController = TextEditingController();
  String? _selected;
  bool _busy = false;

  bool get _isOtherSelected => _selected == markDiseasedOtherKey;

  bool get _canSubmit =>
      _selected != null &&
      (!_isOtherSelected || _otherController.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _otherController.addListener(_onOtherChanged);
  }

  @override
  void dispose() {
    _otherController.removeListener(_onOtherChanged);
    _otherController.dispose();
    super.dispose();
  }

  void _onOtherChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_busy || !_canSubmit) return;
    final l10n = AppLocalizations.of(context)!;
    final diseaseType = _isOtherSelected
        ? _otherController.text.trim()
        : _selected!;
    // Capture app-level handles before awaiting: this sheet's context is
    // stale once popped, but the toast and the workbench push must outlive it.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(epidemicRepositoryProvider)
          .markDiseased(widget.livestockId, diseaseType);
      if (!mounted) return;
      final message = result.contactsGenerated > 0
          ? l10n.markDiseasedDone(result.contactsGenerated)
          : l10n.markDiseasedNoGps;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
      router.push('/twin/epidemic?sourceLivestockId=${widget.livestockId}');
    } catch (_) {
      // Keep the sheet open so the user can retry; never surface the raw
      // exception text to the user (AGENTS #25).
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.markDiseasedFailedTryAgain)),
      );
    } finally {
      // Busy guard MUST reset even on the early-return / error paths —
      // a leaked busy flag leaves the confirm button disabled forever.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final who = (widget.subtitle == null || widget.subtitle!.isEmpty)
        ? widget.livestockCode
        : '${widget.livestockCode} · ${widget.subtitle}';

    return Padding(
      // Keep the input visible when the soft keyboard opens.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        // Prototype sheet padding: 18px 16px 26px.
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle: 36×4, border color, radius 2.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title: 15 / w700, centered.
            Text(
              l10n.markDiseasedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // Who line: 11 / secondary, centered.
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Text(
                who,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Disease group title: 11 / w700, 8px below.
            Text(
              l10n.markDiseasedDiseaseLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Disease chips: pill, 12px, single-select.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in markDiseasedDiseaseOptions)
                  _buildChip(l10n, option),
              ],
            ),
            // Required custom name input, only when "Other" is selected.
            if (_isOtherSelected) ...[
              const SizedBox(height: 10),
              _buildOtherInput(l10n),
            ],
            // Info hint bar: info-soft bg / info text, radius 8, 10px/1.6.
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.markDiseasedHint,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.6,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Buttons: cancel (neutral) / confirm (danger), height 42, 13px.
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _NeutralButton(
                      label: l10n.commonCancel,
                      onTap: _busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DangerButton(
                      label: l10n.markDiseasedConfirm,
                      busy: _busy,
                      enabled: _canSubmit,
                      onTap: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(AppLocalizations l10n, MarkDiseasedDiseaseOption option) {
    final selected = _selected == option.key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _busy
          ? null
          : () => setState(() {
              _selected = option.key;
            }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.dangerSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          // 1.5px border on both states keeps chip metrics stable.
          border: Border.all(
            width: 1.5,
            color: selected ? AppColors.danger : Colors.transparent,
          ),
        ),
        child: Text(
          option.label(l10n),
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.danger : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherInput(AppLocalizations l10n) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _otherController,
        enabled: !_busy,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: l10n.markDiseasedOtherHint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Neutral action button (surface-muted bg / secondary text).
class _NeutralButton extends StatelessWidget {
  const _NeutralButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action button (danger bg / white text); dims when disabled
/// (prototype `btn:disabled` opacity .45) and shows a small spinner while
/// the submit is in flight.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: Material(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: active ? onTap : null,
          child: SizedBox(
            height: 42,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
