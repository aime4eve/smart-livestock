import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LivestockFormSheet extends ConsumerStatefulWidget {
  const LivestockFormSheet({super.key, this.existing});

  final LivestockSummary? existing;

  @override
  ConsumerState<LivestockFormSheet> createState() => _LivestockFormSheetState();
}

class _LivestockFormSheetState extends ConsumerState<LivestockFormSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _weightCtrl;
  Breed _breed = Breed.other;
  String _gender = 'MALE';
  DateTime? _birthDate;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.existing?.earTag ?? '');
    _weightCtrl = TextEditingController();
    // Pre-fill fields from existing data when editing.
   final existing = widget.existing;
   if (existing != null) {
      _breed = existing.breed;
      _gender = existing.gender ?? 'MALE';
      _birthDate = existing.birthDate;
      if (existing.weight != null) {
        _weightCtrl.text = existing.weight!.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isEdit ? l10n.livestockEdit : l10n.livestockAddNew,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Code
            TextField(
              key: const Key('livestock-form-code'),
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: l10n.livestockFormFieldCode,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Breed
            DropdownButtonFormField<Breed>(
              key: const Key('livestock-form-breed'),
              initialValue: _breed,
              decoration: InputDecoration(
                labelText: l10n.livestockFormFieldBreed,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: Breed.angus, child: Text(l10n.livestockBreedAngus)),
                DropdownMenuItem(value: Breed.wagyu, child: Text(l10n.livestockBreedWagyu)),
                DropdownMenuItem(value: Breed.simmental, child: Text(l10n.livestockBreedSimmental)),
                DropdownMenuItem(value: Breed.limousin, child: Text(l10n.livestockBreedLimousin)),
                DropdownMenuItem(value: Breed.other, child: Text(l10n.livestockBreedOther)),
              ],
              onChanged: (v) => setState(() => _breed = v ?? Breed.other),
            ),
            const SizedBox(height: AppSpacing.md),
            // Gender
            Text(l10n.livestockFormFieldGender,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'MALE', label: Text(l10n.livestockGenderMale)),
                ButtonSegment(value: 'FEMALE', label: Text(l10n.livestockGenderFemale)),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            // Birth Date
            ListTile(
              key: const Key('livestock-form-birthdate'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.livestockFormFieldBirthDate),
              subtitle: Text(_birthDate != null
                  ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
                  : '--'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime(2024, 1, 1),
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _birthDate = picked);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Weight
            TextField(
              key: const Key('livestock-form-weight'),
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.livestockFormFieldWeight,
                suffixText: 'kg',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('livestock-form-submit'),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.commonConfirm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'livestockCode': _codeCtrl.text.trim(),
      'breed': _breed.name.toUpperCase(),
      'gender': _gender,
      'birthDate': _birthDate != null
          ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
          : null,
      'weight': _weightCtrl.text.isNotEmpty ? _weightCtrl.text.trim() : null,
    };
    try {
      final repo = ref.read(livestockRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.existing!.id, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.livestockUpdateSuccess)));
          Navigator.of(context).pop();
        }
      } else {
        await repo.create(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.livestockCreateSuccess)));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
