import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Opens the "back-fill missed drinking event" bottom sheet (spec §15.2:
/// POST .../drinking-events/manual — source=MANUAL, label=CONFIRMED).
void showDrinkingManualSheet(BuildContext context, String livestockId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceAlt,
    barrierColor: const Color(0x59263126), // rgba(38,49,38,.35)
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => DrinkingManualSheet(livestockId: livestockId),
  );
}

/// Missed-event back-fill sheet (NIX-256 4b). Lightweight form per the
/// plan: wall-clock time input `yyyy-MM-dd HH:mm` (Asia/Shanghai) + note.
class DrinkingManualSheet extends ConsumerStatefulWidget {
  const DrinkingManualSheet({super.key, required this.livestockId});

  final String livestockId;

  @override
  ConsumerState<DrinkingManualSheet> createState() =>
      _DrinkingManualSheetState();
}

class _DrinkingManualSheetState extends ConsumerState<DrinkingManualSheet> {
  late final TextEditingController _timeCtrl;
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timeCtrl = TextEditingController(text: _formatWallClock(now));
  }

  static String _formatWallClock(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// The wire format is exactly `yyyy-MM-dd HH:mm` (DrinkingManualRequest);
  /// DateTime.parse alone would silently accept other ISO shapes the
  /// backend rejects, so validate the shape explicitly first.
  DateTime? _parseWallClock(String value) {
    final trimmed = value.trim();
    final shape = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');
    if (!shape.hasMatch(trimmed)) return null;
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parseWallClock(_timeCtrl.text);
    if (parsed == null) {
      setState(() => _timeError = l10n.healthDrinkingManualTimeInvalid);
      return;
    }
    if (parsed.isAfter(DateTime.now())) {
      setState(() => _timeError = l10n.healthDrinkingManualTimeFuture);
      return;
    }
    setState(() {
      _saving = true;
      _timeError = null;
    });
    try {
      await ref
          .read(drinkingEventsControllerProvider(widget.livestockId).notifier)
          .addManual(
            eventStartAt: _timeCtrl.text.trim(),
            note: _noteCtrl.text.trim(),
          );
      // addManual already refreshed rows + summaries.
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      // Backend validation / 409: toString() returns the server-side i18n
      // message, safe to show as-is.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (_) {
      // Network/timeout and other non-API failures must not leak raw
      // technical strings (lesson #25).
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.healthDrinkingSaveFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // grip 36×4 r2 --border (same sheet language as physiology)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.healthDrinkingManualSheetTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('drinking-manual-time'),
                controller: _timeCtrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.healthDrinkingManualTimeLabel,
                  labelStyle: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  hintText: l10n.healthDrinkingManualTimeHint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  errorText: _timeError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.drinking),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('drinking-manual-note'),
                controller: _noteCtrl,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: l10n.healthDrinkingManualNoteHint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.drinking),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: const Key('drinking-manual-save'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            l10n.commonSave,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
