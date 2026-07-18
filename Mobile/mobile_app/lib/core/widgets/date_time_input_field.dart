import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Unified date-time input field combining direct keyboard input and visual
/// date+time picker selection.
///
/// Supports:
/// - Direct keyboard input in `yyyy-MM-dd HH:mm` format
/// - Clicking the calendar icon to open `showDatePicker` → `showTimePicker`
/// - Validation with red error underline on invalid input
/// - Auto-formatting on blur
class DateTimeInputField extends StatefulWidget {
  const DateTimeInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.minDate,
    this.maxDate,
  });

  /// The field label (should already be an AppLocalizations string).
  final String label;

  /// Current value, or null to show an empty field.
  final DateTime? value;

  /// Called when a valid DateTime is selected or typed.
  final ValueChanged<DateTime> onChanged;

  /// If true, the field is visually required and empty values show an error.
  final bool isRequired;

  /// Earliest selectable date in the date picker.
  final DateTime? minDate;

  /// Latest selectable date in the date picker.
  final DateTime? maxDate;

  @override
  State<DateTimeInputField> createState() => _DateTimeInputFieldState();
}

class _DateTimeInputFieldState extends State<DateTimeInputField> {
  static const _displayFormat = 'yyyy-MM-dd HH:mm';
  static const _parseFormats = [
    'yyyy-MM-dd HH:mm',
    'yyyy/MM/dd HH:mm',
    'yyyy-MM-dd HH:mm:ss',
    'yyyy/MM/dd HH:mm:ss',
  ];

  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  String? _errorText;

 @override
 void initState() {
   super.initState();
   _ctrl = TextEditingController(text: _formatValue(widget.value));
   _focus = FocusNode()..addListener(_onFocusChange);
 }

  @override
  void didUpdateWidget(DateTimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text from external value changes only when the field is not being
    // actively edited (no focus).
    if (oldWidget.value != widget.value && !_focus.hasFocus) {
      _ctrl.text = _formatValue(widget.value);
      setState(() => _errorText = null);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _formatValue(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat(_displayFormat).format(dt);
  }

  // ── Focus handling ──────────────────────────────────────────

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      _formatOnBlur();
    }
  }

  void _formatOnBlur() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _validateEmpty();
      return;
    }
    final parsed = _tryParse(text);
    if (parsed != null) {
      setState(() => _errorText = null);
      _ctrl.text = _formatValue(parsed);
      widget.onChanged(parsed);
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorText = l10n.gpsQualityDateFormatError);
    }
  }

  // ── Parse helpers ───────────────────────────────────────────

  DateTime? _tryParse(String text) {
    for (final f in _parseFormats) {
      try {
        final parsed = DateFormat(f).parse(text);
        return DateTime(
          parsed.year, parsed.month, parsed.day,
          parsed.hour, parsed.minute,
        );
      } catch (_) {}
    }
    return null;
  }

  void _validateEmpty() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _errorText = widget.isRequired ? l10n.gpsQualityRequiredField : null;
    });
  }

  // ── Picker ──────────────────────────────────────────────────

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: widget.minDate ?? DateTime(now.year - 1),
      lastDate: widget.maxDate ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.value ?? now),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    _ctrl.text = _formatValue(selected);
    setState(() => _errorText = null);
    widget.onChanged(selected);
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: _displayFormat,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        errorText: _errorText,
        suffixIcon: IconButton(
          icon: Icon(
            Icons.event,
            size: 18,
            color: _errorText != null
                ? theme.colorScheme.error
                : AppColors.primary,
          ),
          onPressed: _pick,
          tooltip: _displayFormat,
        ),
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: _onTextChanged,
    );
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      _validateEmpty();
      return;
    }
    final parsed = _tryParse(text);
    if (parsed != null) {
      setState(() => _errorText = null);
      widget.onChanged(parsed);
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorText = l10n.gpsQualityDateFormatError);
    }
  }
}
