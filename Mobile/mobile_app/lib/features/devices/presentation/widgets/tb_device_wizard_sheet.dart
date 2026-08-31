import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/tb_device_wizard_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum _WizardStep { input, confirm, result }

const _noLivestock = '__none__';

enum _LivestockSort { code, health, location }

enum _DeviceBindingFilter { all, withoutDevice, withDevice }

enum _LocationFilter { all, known, unknown }

class TbDeviceWizardSheet extends ConsumerStatefulWidget {
  const TbDeviceWizardSheet({super.key});

  @override
  ConsumerState<TbDeviceWizardSheet> createState() =>
      _TbDeviceWizardSheetState();
}

class _TbDeviceWizardSheetState extends ConsumerState<TbDeviceWizardSheet> {
  final _euiController = TextEditingController();
  final _deviceCodeController = TextEditingController();
  final List<LivestockSummary> _livestock = [];
  int _livestockTotal = 0;
  String? _selectedLivestockId;
  bool _livestockLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLivestock());
  }

  @override
  void dispose() {
    _euiController.dispose();
    _deviceCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadLivestock() async {
    try {
      final loaded = <String, LivestockSummary>{};
      var total = 0;
      // Keep the picker responsive for herds around 1,000 head while still
      // avoiding an unbounded request against the livestock API.
      for (var page = 1; page <= 10; page++) {
        final data = await ref
            .read(livestockRepositoryProvider)
            .loadAll(page: page, pageSize: 200);
        total = data.total;
        for (final item in data.items) {
          loaded[item.id] = item;
        }
        if (loaded.length >= total || data.items.isEmpty) break;
      }
      if (mounted) {
        final items = loaded.values.toList()
          ..sort((a, b) => a.livestockCode.compareTo(b.livestockCode));
        setState(() {
          _livestock
            ..clear()
            ..addAll(items);
          _livestockTotal = total;
          _livestockLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _livestockLoading = false);
    }
  }

  Future<void> _preflight() async {
    final controller = ref.read(tbDeviceWizardControllerProvider.notifier);
    await controller.preflight(_euiController.text);
    final preflight = ref.read(tbDeviceWizardControllerProvider).preflight;
    if (preflight != null && mounted) {
      final candidate = preflight.selectedCandidate;
      if (candidate != null) {
        _deviceCodeController.text =
            'TB-${preflight.nsProjectId ?? 0}-${preflight.eui}';
      }
    }
  }

  Future<void> _provision(TbDevicePreflight preflight) async {
    await ref
        .read(tbDeviceWizardControllerProvider.notifier)
        .provision(
          preflight: preflight,
          deviceCode: _deviceCodeController.text,
          livestockId: _selectedLivestockId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(tbDeviceWizardControllerProvider);
    final step = state.result == null
        ? (state.preflight == null ? _WizardStep.input : _WizardStep.confirm)
        : _WizardStep.result;

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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.tbWizardTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StepIndicator(step: step),
            const SizedBox(height: AppSpacing.lg),
            if (state.error != null) ...[
              _MessageTile(
                message: state.error!,
                backgroundColor: AppColors.dangerSoft,
                foregroundColor: AppColors.danger,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            switch (step) {
              _WizardStep.input => _InputStep(
                controller: _euiController,
                loading: state.loading,
                onEuiChanged: (_) => setState(() {}),
                onPreflight: _preflight,
              ),
              _WizardStep.confirm => _ConfirmStep(
                preflight: state.preflight!,
                deviceCodeController: _deviceCodeController,
                livestock: _livestock,
                livestockTotal: _livestockTotal,
                livestockLoading: _livestockLoading,
                selectedLivestockId: _selectedLivestockId,
                loading: state.loading,
                onLivestockChanged: (value) =>
                    setState(() => _selectedLivestockId = value),
                onRecheck: _preflight,
                onProvision: () => _provision(state.preflight!),
              ),
              _WizardStep.result => _ResultStep(result: state.result!),
            },
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _WizardStep step;

  @override
  Widget build(BuildContext context) {
    final currentIndex = step.index;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const Expanded(child: Divider(height: 1)),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= currentIndex
                  ? AppColors.primary
                  : AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${i + 1}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: i <= currentIndex
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InputStep extends StatelessWidget {
  const _InputStep({
    required this.controller,
    required this.loading,
    required this.onEuiChanged,
    required this.onPreflight,
  });

  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onEuiChanged;
  final VoidCallback onPreflight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('tb-wizard-eui'),
          controller: controller,
          onChanged: onEuiChanged,
          decoration: InputDecoration(
            labelText: l10n.tbWizardEuiLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('tb-wizard-preflight'),
          onPressed: loading || controller.text.trim().isEmpty
              ? null
              : onPreflight,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(l10n.tbWizardPreflightAction),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.preflight,
    required this.deviceCodeController,
    required this.livestock,
    required this.livestockTotal,
    required this.livestockLoading,
    required this.selectedLivestockId,
    required this.loading,
    required this.onLivestockChanged,
    required this.onRecheck,
    required this.onProvision,
  });

  final TbDevicePreflight preflight;
  final TextEditingController deviceCodeController;
  final List<LivestockSummary> livestock;
  final int livestockTotal;
  final bool livestockLoading;
  final String? selectedLivestockId;
  final bool loading;
  final ValueChanged<String?> onLivestockChanged;
  final VoidCallback onRecheck;
  final VoidCallback onProvision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidate = preflight.selectedCandidate;
    final activeLivestockId = preflight.activeInstallationLivestockId;
    final installationConflict = activeLivestockId != null &&
        selectedLivestockId != null &&
        selectedLivestockId != activeLivestockId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreflightCard(preflight: preflight),
        if (preflight.candidates.length > 1) ...[
          _MessageTile(
            message: l10n.tbWizardAmbiguousWarning,
            backgroundColor: AppColors.warningSoft,
            foregroundColor: AppColors.warningStrong,
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (candidate != null && candidate.profileValid) ...[
          TextField(
            key: const Key('tb-wizard-code'),
            controller: deviceCodeController,
            decoration: InputDecoration(
              labelText: l10n.deviceFormFieldCode,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _LivestockPicker(
            key: const Key('tb-wizard-livestock'),
            livestock: livestock,
            total: livestockTotal,
            loading: livestockLoading,
            selectedLivestockId: selectedLivestockId,
            onSelected: onLivestockChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if ((selectedLivestockId ?? _noLivestock) == _noLivestock)
            _MessageTile(
              message: l10n.tbWizardNoLivestockNote,
              backgroundColor: AppColors.warningSoft,
              foregroundColor: AppColors.warningStrong,
              icon: Icons.info_outline,
            ),
          if (activeLivestockId != null)
            _MessageTile(
              message: l10n.tbWizardInstalledLivestockWarning(activeLivestockId),
              backgroundColor: installationConflict
                  ? AppColors.dangerSoft
                  : AppColors.warningSoft,
              foregroundColor: installationConflict
                  ? AppColors.danger
                  : AppColors.warningStrong,
              icon: installationConflict
                  ? Icons.block
                  : Icons.info_outline,
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onRecheck,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tbWizardRecheck),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
	              Expanded(
	                child: FilledButton.icon(
	                  key: const Key('tb-wizard-provision'),
	                  onPressed: loading || installationConflict
	                      ? null
	                      : onProvision,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt),
                  label: Text(l10n.tbWizardProvisionAction),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LivestockPicker extends StatefulWidget {
  const _LivestockPicker({
    super.key,
    required this.livestock,
    required this.total,
    required this.loading,
    required this.selectedLivestockId,
    required this.onSelected,
  });

  final List<LivestockSummary> livestock;
  final int total;
  final bool loading;
  final String? selectedLivestockId;
  final ValueChanged<String?> onSelected;

  @override
  State<_LivestockPicker> createState() => _LivestockPickerState();
}

class _LivestockPickerState extends State<_LivestockPicker> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  Breed? _breedFilter;
  LivestockHealth? _healthFilter;
  _DeviceBindingFilter _deviceFilter = _DeviceBindingFilter.all;
  _LocationFilter _locationFilter = _LocationFilter.all;
  _LivestockSort _sort = _LivestockSort.code;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() {});
    });
  }

  List<LivestockSummary> get _filteredLivestock {
    final query = _searchController.text.trim().toLowerCase();
    final result = widget.livestock.where((item) {
      if (_breedFilter != null && item.breed != _breedFilter) return false;
      if (_healthFilter != null && item.health != _healthFilter) return false;
      if (_deviceFilter == _DeviceBindingFilter.withoutDevice &&
          item.deviceCodes.isNotEmpty) {
        return false;
      }
      if (_deviceFilter == _DeviceBindingFilter.withDevice &&
          item.deviceCodes.isEmpty) {
        return false;
      }
      final hasLocation = item.lat != null && item.lng != null;
      if (_locationFilter == _LocationFilter.known && !hasLocation) {
        return false;
      }
      if (_locationFilter == _LocationFilter.unknown && hasLocation) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        item.livestockCode,
        item.id,
        item.gender ?? '',
        for (final code in item.deviceCodes) code,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    int healthRank(LivestockHealth health) => switch (health) {
      LivestockHealth.abnormal => 0,
      LivestockHealth.watch => 1,
      LivestockHealth.healthy => 2,
    };

    switch (_sort) {
      case _LivestockSort.code:
        result.sort((a, b) => a.livestockCode.compareTo(b.livestockCode));
      case _LivestockSort.health:
        result.sort((a, b) {
          final byHealth = healthRank(a.health).compareTo(healthRank(b.health));
          return byHealth != 0
              ? byHealth
              : a.livestockCode.compareTo(b.livestockCode);
        });
      case _LivestockSort.location:
        result.sort((a, b) {
          final aLocation = a.lat != null && a.lng != null;
          final bLocation = b.lat != null && b.lng != null;
          if (aLocation != bLocation) return aLocation ? -1 : 1;
          return a.livestockCode.compareTo(b.livestockCode);
        });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredLivestock;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tbWizardLivestockLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('tb-wizard-livestock-search'),
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.tbWizardLivestockSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            label: l10n.livestockBreed,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _FilterChip(
                  label: l10n.tbWizardFilterAll,
                  selected: _breedFilter == null,
                  onTap: () => setState(() => _breedFilter = null),
                ),
                for (final breed in Breed.values)
                  _FilterChip(
                    label: _breedText(context, breed),
                    selected: _breedFilter == breed,
                    onTap: () => setState(() => _breedFilter = breed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _FilterGroup(
            label: l10n.tbWizardFilterHealth,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _FilterChip(
                  label: l10n.tbWizardFilterAll,
                  selected: _healthFilter == null,
                  onTap: () => setState(() => _healthFilter = null),
                ),
                for (final health in LivestockHealth.values)
                  _FilterChip(
                    label: _healthText(context, health),
                    selected: _healthFilter == health,
                    onTap: () => setState(() => _healthFilter = health),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _FilterGroup(
            label: l10n.tbWizardFilterConditions,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _FilterChip(
                  label: l10n.tbWizardFilterAllDevices,
                  selected: _deviceFilter == _DeviceBindingFilter.all,
                  onTap: () =>
                      setState(() => _deviceFilter = _DeviceBindingFilter.all),
                ),
                _FilterChip(
                  label: l10n.tbWizardFilterWithoutDevice,
                  selected: _deviceFilter == _DeviceBindingFilter.withoutDevice,
                  onTap: () => setState(
                    () => _deviceFilter = _DeviceBindingFilter.withoutDevice,
                  ),
                ),
                _FilterChip(
                  label: l10n.tbWizardFilterWithDevice,
                  selected: _deviceFilter == _DeviceBindingFilter.withDevice,
                  onTap: () => setState(
                    () => _deviceFilter = _DeviceBindingFilter.withDevice,
                  ),
                ),
                _FilterChip(
                  label: l10n.tbWizardFilterHasLocation,
                  selected: _locationFilter == _LocationFilter.known,
                  onTap: () =>
                      setState(() => _locationFilter = _LocationFilter.known),
                ),
                _FilterChip(
                  label: l10n.tbWizardFilterNoLocation,
                  selected: _locationFilter == _LocationFilter.unknown,
                  onTap: () =>
                      setState(() => _locationFilter = _LocationFilter.unknown),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                l10n.tbWizardLivestockCount(filtered.length, widget.total),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              for (final sort in _LivestockSort.values) ...[
                if (sort != _LivestockSort.values.first)
                  const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: _sortText(context, sort),
                  selected: _sort == sort,
                  onTap: () => setState(() => _sort = sort),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.tbWizardLivestockNoMatch,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _LivestockTile(
                      title: l10n.tbWizardNoLivestock,
                      subtitle: l10n.tbWizardNoLivestockNote,
                      selected:
                          (widget.selectedLivestockId ?? _noLivestock) ==
                          _noLivestock,
                      onTap: () => widget.onSelected(null),
                    );
                  }
                  final item = filtered[index - 1];
                  return _LivestockTile(
                    title: item.livestockCode,
                    subtitle: _livestockSubtitle(context, item),
                    selected: widget.selectedLivestockId == item.id,
                    hasLocation: item.lat != null && item.lng != null,
                    onLocate: item.lat != null && item.lng != null
                        ? () => _showLocation(context, item)
                        : null,
                    onTap: () => widget.onSelected(item.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showLocation(BuildContext context, LivestockSummary item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LivestockLocationSheet(item: item),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: child),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _LivestockTile extends StatelessWidget {
  const _LivestockTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.hasLocation = false,
    this.onLocate,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool hasLocation;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: hasLocation
          ? IconButton(
              tooltip: AppLocalizations.of(context)!.tbWizardLocate,
              icon: const Icon(Icons.my_location),
              onPressed: onLocate,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _LivestockLocationSheet extends StatelessWidget {
  const _LivestockLocationSheet({required this.item});

  final LivestockSummary item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final point = LatLng(item.lat!, item.lng!);
    return SizedBox(
      height: 420,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tbWizardLocationTitle(item.livestockCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.selfHostedTileUrl,
                      userAgentPackageName: 'com.smartlivestock.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${item.lat!.toStringAsFixed(6)}, ${item.lng!.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreflightCard extends StatelessWidget {
  const _PreflightCard({required this.preflight});

  final TbDevicePreflight preflight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidate = preflight.selectedCandidate;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _DetailRow(label: l10n.tbWizardEuiLabel, value: preflight.eui),
          _DetailRow(
            label: l10n.tbWizardNsProject,
            value: preflight.nsProjectId?.toString() ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardTbDevice,
            value: candidate?.tbDeviceId ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardProfile,
            value: candidate?.profileName ?? l10n.tbWizardMissing,
          ),
          _DetailRow(
            label: l10n.tbWizardLatestTelemetry,
            value: preflight.latestTelemetryAt ?? l10n.tbWizardNoTelemetry,
          ),
          _DetailRow(
            label: l10n.tbWizardStatus,
            value: _statusText(context, preflight.status),
            trailing: _StatusBadge(status: preflight.status),
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.result});

  final TbDeviceProvisionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed = result.livestockId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.5,
          children: [
            _ResultTile(
              title: l10n.tbWizardResultDevice,
              value: result.localDeviceId,
              done: true,
            ),
            _ResultTile(
              title: l10n.tbWizardResultBinding,
              value: result.bindingStatus,
              done: result.bindingStatus == 'RESOLVED',
            ),
            _ResultTile(
              title: l10n.tbWizardResultActivation,
              value: result.deviceStatus,
              done: result.deviceStatus == 'ACTIVE',
            ),
            _ResultTile(
              title: l10n.tbWizardResultInstallation,
              value: installed ? l10n.tbWizardInstalled : l10n.tbWizardSkipped,
              done: installed,
            ),
            _ResultTile(
              title: l10n.tbWizardResultFence,
              value: installed ? l10n.tbWizardEnabled : l10n.tbWizardDisabled,
              done: installed,
            ),
            _ResultTile(
              title: l10n.tbWizardResultHealth,
              value: installed ? l10n.tbWizardEnabled : l10n.tbWizardDisabled,
              done: installed,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MessageTile(
          message: _triggerText(context, result.firstTelemetryTrigger),
          backgroundColor: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? AppColors.successSoft
              : AppColors.infoSoft,
          foregroundColor: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? AppColors.successStrong
              : AppColors.infoStrong,
          icon: result.firstTelemetryTrigger == 'TB_TRIGGERED'
              ? Icons.check_circle_outline
              : Icons.schedule,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.value,
    required this.done,
  });

  final String title;
  final String value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.remove_circle_outline,
                size: 14,
                color: done ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => AppColors.success,
      'PENDING_NS' ||
      'PENDING_TB_DEVICE' ||
      'PENDING_TELEMETRY' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    'PENDING_NS' => l10n.tbWizardStatusPendingNs,
    'PENDING_TB_DEVICE' => l10n.tbWizardStatusPendingTbDevice,
    'PENDING_TELEMETRY' => l10n.tbWizardStatusPendingTelemetry,
    'READY_TO_INGEST' => l10n.tbWizardStatusReady,
    'PENDING_INSTALLATION' => l10n.tbWizardStatusPendingInstallation,
    'ACTIVE' => l10n.tbWizardStatusActive,
    _ => l10n.tbWizardStatusUnknown(status),
  };
}

String _breedText(BuildContext context, Breed breed) {
  final l10n = AppLocalizations.of(context)!;
  return switch (breed) {
    Breed.angus => l10n.livestockBreedAngus,
    Breed.wagyu => l10n.livestockBreedWagyu,
    Breed.simmental => l10n.livestockBreedSimmental,
    Breed.limousin => l10n.livestockBreedLimousin,
    Breed.other => l10n.livestockBreedOther,
  };
}

String _healthText(BuildContext context, LivestockHealth health) {
  final l10n = AppLocalizations.of(context)!;
  return switch (health) {
    LivestockHealth.healthy => l10n.livestockHealthHealthy,
    LivestockHealth.watch => l10n.livestockHealthWatch,
    LivestockHealth.abnormal => l10n.livestockHealthAbnormal,
  };
}

String _sortText(BuildContext context, _LivestockSort sort) {
  final l10n = AppLocalizations.of(context)!;
  return switch (sort) {
    _LivestockSort.code => l10n.tbWizardSortCode,
    _LivestockSort.health => l10n.tbWizardSortHealth,
    _LivestockSort.location => l10n.tbWizardSortLocation,
  };
}

String _livestockSubtitle(BuildContext context, LivestockSummary item) {
  final l10n = AppLocalizations.of(context)!;
  final breed = _breedText(context, item.breed);
  final health = _healthText(context, item.health);
  final gender = item.gender?.toUpperCase() == 'MALE'
      ? l10n.livestockGenderMale
      : item.gender?.toUpperCase() == 'FEMALE'
      ? l10n.livestockGenderFemale
      : l10n.tbWizardGenderUnknown;
  final hasLocation = item.lat != null && item.lng != null;
  final location = hasLocation
      ? '${item.lat!.toStringAsFixed(4)}, ${item.lng!.toStringAsFixed(4)}'
      : l10n.tbWizardLocationUnknown;
  return l10n.tbWizardLivestockSubtitle(
    breed,
    health,
    gender,
    item.deviceCodes.length,
    location,
  );
}

String _triggerText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context)!;
  return switch (status) {
    'TB_TRIGGERED' => l10n.tbWizardTriggerDone,
    'TB_TRIGGER_SKIPPED_DISABLED' => l10n.tbWizardTriggerDisabled,
    'TB_TRIGGER_BINDING_NOT_FOUND' => l10n.tbWizardTriggerBindingMissing,
    'TB_TRIGGER_FAILED' => l10n.tbWizardTriggerFailed,
    _ => l10n.tbWizardStatusUnknown(status),
  };
}
