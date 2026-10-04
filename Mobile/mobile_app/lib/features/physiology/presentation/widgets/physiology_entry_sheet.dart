import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/physiology_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Opens the "new physiology record" bottom sheet with the dim overlay
/// specified by the prototype (rgba(38,49,38,.35), C7).
void showPhysiologyEntrySheet(BuildContext context, String livestockId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceAlt,
    barrierColor: const Color(0x59263126), // rgba(38,49,38,.35)
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => PhysiologyEntrySheet(livestockId: livestockId),
  );
}

/// Physiology record entry sheet (NIX-256, spec: physiology-entry-sheet.md).
///
/// Semantics: recording「发病」has no end-date field — the window is closed
/// later by logging a separate「康复」event (spec §8 A1, append-only).
class PhysiologyEntrySheet extends ConsumerStatefulWidget {
  const PhysiologyEntrySheet({super.key, required this.livestockId});

  final String livestockId;

  @override
  ConsumerState<PhysiologyEntrySheet> createState() =>
      _PhysiologyEntrySheetState();
}

class _PhysiologyEntrySheetState extends ConsumerState<PhysiologyEntrySheet> {
  // Prototype default selection: 妊娠检查 (pregnancy check).
  PhysiologyEventType _type = PhysiologyEventType.pregnancyCheck;
  DateTime _date = DateTime.now();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2010),
      // Future dates are rejected (B3): the picker simply cannot go past
      // today; the backend re-validates and its message is shown on error.
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(physiologyEventsControllerProvider(widget.livestockId).notifier)
          .createEvent(
            eventType: _type,
            occurredAt: _date,
            note: _noteCtrl.text.trim(),
          );
      // createEvent() already invalidates the list provider.
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      // Backend validation / 409 conflict: toString() returns the
      // server-side i18n message, safe to show as-is.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (_) {
      // Network/timeout and other non-API failures must not leak raw
      // technical strings (lesson #25) — show a generic message instead.
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.healthPhysiologySaveFailed),
          ),
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
              // grip 36×4 r2 --border
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
                l10n.healthPhysiologySheetTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              // type-grid: single-select chips (wrap, gap 6)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in {
                    PhysiologyEventType.calving:
                        '🐮 ${l10n.healthPhysiologyEventCalving}',
                    PhysiologyEventType.breeding:
                        '❤️ ${l10n.healthPhysiologyEventBreeding}',
                    PhysiologyEventType.pregnancyCheck:
                        '🤰 ${l10n.healthPhysiologyEventPregnancyCheck}',
                    PhysiologyEventType.dryOff:
                        '⏸️ ${l10n.healthPhysiologyEventDryOff}',
                    PhysiologyEventType.illness:
                        '💊 ${l10n.healthPhysiologyEventIllness}',
                    PhysiologyEventType.recovery:
                        '✅ ${l10n.healthPhysiologyEventRecovery}',
                  }.entries)
                    _TypeChip(
                      label: entry.value,
                      selected: entry.key == _type,
                      onTap: () => setState(() => _type = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // date-row: label + right-aligned value, bordered r8
              InkWell(
                key: const Key('physiology-entry-date'),
                borderRadius: BorderRadius.circular(8),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.healthPhysiologyOccurredDate,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _wireDate(_date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // note-box: min-height 52, ≤500 chars
              TextField(
                key: const Key('physiology-entry-note'),
                controller: _noteCtrl,
                maxLength: 500,
                minLines: 2,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  counterText: '',
                  hintText: l10n.healthPhysiologyNoteHint,
                  hintStyle: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(minHeight: 52),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // save-btn: brand green, r8, padding 10×0
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: const Key('physiology-entry-save'),
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
              const SizedBox(height: 9),
              Text(
                l10n.healthPhysiologyIllnessNote,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _wireDate(DateTime localDate) {
    final y = localDate.year.toString().padLeft(4, '0');
    final m = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Single-select event type chip (type-grid .chip).
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          // .chip.sel: bg --primary + #fff only (no border);
          // .chip.idle: bg --surface + secondary + border 1 --border.
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? null
              : Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
