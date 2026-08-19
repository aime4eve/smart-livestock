import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/presentation/datagen_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DatagenConsolePage extends ConsumerStatefulWidget {
  const DatagenConsolePage({super.key});

  @override
  ConsumerState<DatagenConsolePage> createState() =>
      _DatagenConsolePageState();
}

class _DatagenConsolePageState extends ConsumerState<DatagenConsolePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String _rangeType = 'LAST_24_HOURS';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(
        () => ref.read(datagenControllerProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(datagenControllerProvider);
    final console = state.console;

    return Scaffold(
      key: const Key('datagen-console-page'),
      backgroundColor: AppColors.surface,
      body: state.isLoading && console == null
          ? const Center(child: CircularProgressIndicator())
          : state.farms.isEmpty
              ? _EmptyPanel(message: l10n.datagenConsoleNoOperations)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(context, state),
                      const SizedBox(height: 16),
                      _filters(context, state),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.primary,
                              tabs: [
                                Tab(text: l10n.datagenConsoleTabStatus),
                                Tab(text: l10n.datagenConsoleTabDevices),
                                Tab(text: l10n.datagenConsoleTabClear),
                                Tab(text: l10n.datagenConsoleTabOperations),
                              ],
                            ),
                            SizedBox(
                              height: 620,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _StatusTab(console: console),
                                  _DevicesTab(console: console),
                                  _ClearTab(
                                    console: console,
                                    rangeType: _rangeType,
                                    previewResult: state.previewResult,
                                    clearResult: state.clearResult,
                                    isClearing: state.isClearing,
                                    fromController: _fromController,
                                    toController: _toController,
                                    onRangeChanged: (value) =>
                                        setState(() => _rangeType = value),
                                    onPreview: () => _previewClear(),
                                    onClear: () => _showClearDialog(context),
                                  ),
                                  _OperationsTab(operations:
                                      console?.operations ?? const []),
                                ],
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

  Widget _header(BuildContext context, DatagenConsoleState state) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = state.console?.enabled ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.datagenConsoleTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(l10n.datagenConsoleSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.successSoft
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              enabled
                  ? l10n.datagenConsoleRunning
                  : l10n.datagenConsoleStopped,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppColors.successStrong
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: enabled,
            onChanged: state.isSwitching
                ? null
                : (_) => ref
                    .read(datagenControllerProvider.notifier)
                    .toggleRun(),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context, DatagenConsoleState state) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        final children = [
          DropdownButtonFormField<int>(
            initialValue: state.selectedFarmId,
            decoration: InputDecoration(
              labelText: l10n.datagenConsoleSelectFarm,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: state.farms
                .map((farm) => DropdownMenuItem(
                      value: farm.farmId,
                      child: Text(farm.farmName),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(datagenControllerProvider.notifier)
                    .selectFarm(value);
              }
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: state.deviceTypeFilter,
            decoration: InputDecoration(
              labelText: l10n.datagenConsoleDeviceType,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                  value: 'ALL', child: Text(l10n.datagenConsoleAll)),
              DropdownMenuItem(
                  value: 'TRACKER', child: Text(l10n.datagenConsoleTracker)),
              DropdownMenuItem(
                  value: 'CAPSULE', child: Text(l10n.datagenConsoleCapsule)),
            ],
            onChanged: (value) => ref
                .read(datagenControllerProvider.notifier)
                .setFilter(deviceType: value),
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.datagenConsoleSearchHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => ref
                .read(datagenControllerProvider.notifier)
                .setFilter(search: value),
          ),
        ];
        return narrow
            ? Column(children: [
                for (final child in children) ...[child, const SizedBox(height: 8)]
              ])
            : Row(
                children: [
                  Expanded(flex: 2, child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: children[2]),
                ],
              );
      }),
    );
  }

  Future<void> _previewClear() async {
    await ref.read(datagenControllerProvider.notifier).previewClear(
          rangeType: _rangeType,
          from: _customFrom(),
          to: _customTo(),
        );
  }

  DateTime? _customFrom() => DateTime.tryParse(_fromController.text);
  DateTime? _customTo() => DateTime.tryParse(_toController.text);

  Future<void> _showClearDialog(BuildContext context) async {
    final controller = TextEditingController();
    final dialogL10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final snackL10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogL10n.datagenConsoleConfirmClearTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dialogL10n.datagenConsoleCrossFarmLimit),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: dialogL10n.datagenConsoleConfirmClearWordHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogL10n.commonCancel),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => FilledButton(
              onPressed: controller.text.trim() == '清空'
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(dialogL10n.datagenConsoleConfirmClearAction),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(datagenControllerProvider.notifier).clear(
          rangeType: _rangeType,
          confirmText: controller.text.trim(),
          from: _customFrom(),
          to: _customTo(),
        );
    final result = ref.read(datagenControllerProvider).clearResult;
    if (result != null && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(snackL10n.datagenConsoleClearDone(result.totalDeleted)),
      ));
    }
  }
}

class _StatusTab extends ConsumerStatefulWidget {
  const _StatusTab({required this.console});

  final DatagenConsoleData? console;

  @override
  ConsumerState<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends ConsumerState<_StatusTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trackerInterval;
  late final TextEditingController _capsuleInterval;
  late final TextEditingController _fenceProbability;
  late final TextEditingController _fenceMin;
  late final TextEditingController _fenceMax;
  late final TextEditingController _healthProbability;
  late final TextEditingController _feverMin;
  late final TextEditingController _feverMax;
  late final TextEditingController _motilityMin;
  late final TextEditingController _motilityMax;

  @override
  void initState() {
    super.initState();
    _trackerInterval = TextEditingController();
    _capsuleInterval = TextEditingController();
    _fenceProbability = TextEditingController();
    _fenceMin = TextEditingController();
    _fenceMax = TextEditingController();
    _healthProbability = TextEditingController();
    _feverMin = TextEditingController();
    _feverMax = TextEditingController();
    _motilityMin = TextEditingController();
    _motilityMax = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _StatusTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.console != widget.console) _syncControllers();
  }

  @override
  void dispose() {
    _trackerInterval.dispose();
    _capsuleInterval.dispose();
    _fenceProbability.dispose();
    _fenceMin.dispose();
    _fenceMax.dispose();
    _healthProbability.dispose();
    _feverMin.dispose();
    _feverMax.dispose();
    _motilityMin.dispose();
    _motilityMax.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final rules = widget.console?.rules ?? _defaultRules();
    _trackerInterval.text = _minutesText(rules.trackerIntervalSeconds);
    _capsuleInterval.text = _minutesText(rules.capsuleIntervalSeconds);
    _fenceProbability.text = _percentText(rules.fenceExcursionProbability);
    _fenceMin.text = rules.fenceExcursionMinMinutes.toString();
    _fenceMax.text = rules.fenceExcursionMaxMinutes.toString();
    _healthProbability.text = _percentText(rules.healthEventProbability);
    _feverMin.text = _hoursText(rules.feverDurationMinMinutes);
    _feverMax.text = _hoursText(rules.feverDurationMaxMinutes);
    _motilityMin.text = _hoursText(rules.motilityDurationMinMinutes);
    _motilityMax.text = _hoursText(rules.motilityDurationMaxMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(datagenControllerProvider);
    final stats = widget.console?.stats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final count = constraints.maxWidth > 950 ? 4 : 2;
          return GridView.count(
            crossAxisCount: count,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _MetricCard(
                label: l10n.datagenConsoleStatSelectedDevices,
                value: '${stats?.selectedTotal ?? 0}',
              ),
              _MetricCard(
                label: l10n.datagenConsoleStatNextBatch,
                value: _nextBatch(),
              ),
              _MetricCard(
                label: l10n.datagenConsoleStatTodayRows,
                value: '${(stats?.todayTelemetryRows ?? 0) +
                    (stats?.todayGpsRows ?? 0) +
                    (stats?.todayHealthRows ?? 0)}',
              ),
              _MetricCard(
                label: l10n.datagenConsoleStatLastGenerated,
                value: _time(stats?.lastGeneratedAt) ?? l10n.datagenConsoleNever,
              ),
            ],
          );
        }),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.datagenConsoleConfigTitle,
          actions: [
            OutlinedButton(
              onPressed: state.isSavingRules ? null : _resetDefaults,
              child: Text(l10n.datagenConsoleRulesReset),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state.isSavingRules ? null : _saveRules,
              child: state.isSavingRules
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.datagenConsoleRulesSave),
            ),
          ],
          child: Form(
            key: _formKey,
            child: LayoutBuilder(builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 900 ? 330.0 : null;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _numberField(
                      label: l10n.datagenConsoleConfigTracker,
                      controller: _trackerInterval,
                      suffix: l10n.datagenConsoleRulesUnitMinutes,
                      min: 1,
                      max: 60,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _numberField(
                      label: l10n.datagenConsoleConfigCapsule,
                      controller: _capsuleInterval,
                      suffix: l10n.datagenConsoleRulesUnitMinutes,
                      min: 5,
                      max: 120,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _numberField(
                      label: l10n.datagenConsoleRulesFenceProbability,
                      controller: _fenceProbability,
                      suffix: l10n.datagenConsoleRulesUnitPercent,
                      min: 0,
                      max: 20,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _rangeField(
                      label: l10n.datagenConsoleRulesFenceDuration,
                      minController: _fenceMin,
                      maxController: _fenceMax,
                      suffix: l10n.datagenConsoleRulesUnitMinutes,
                      min: 5,
                      max: 120,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _numberField(
                      label: l10n.datagenConsoleRulesHealthProbability,
                      controller: _healthProbability,
                      suffix: l10n.datagenConsoleRulesUnitPercent,
                      min: 0,
                      max: 10,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _rangeField(
                      label: l10n.datagenConsoleRulesFever,
                      minController: _feverMin,
                      maxController: _feverMax,
                      suffix: l10n.datagenConsoleRulesUnitHours,
                      min: 2,
                      max: 24,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _rangeField(
                      label: l10n.datagenConsoleRulesMotility,
                      minController: _motilityMin,
                      maxController: _motilityMax,
                      suffix: l10n.datagenConsoleRulesUnitHours,
                      min: 2,
                      max: 24,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        _Notice(
          text: AppLocalizations.of(context)!.datagenConsoleRulesNote,
          color: AppColors.infoStrong,
          background: AppColors.infoSoft,
        ),
      ],
    );
  }

  String _nextBatch() {
    final last = widget.console?.stats.lastGeneratedAt;
    if (last == null) return '-';
    final rules = widget.console!.rules;
    final intervalSeconds = widget.console!.stats.selectedTrackerCount > 0
        ? rules.trackerIntervalSeconds
        : rules.capsuleIntervalSeconds;
    return _time(last.add(Duration(seconds: intervalSeconds))) ?? '-';
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required num min,
    required num max,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) => _isValidNumber(value, min, max)
            ? null
            : AppLocalizations.of(context)!.datagenConsoleInvalidRules,
      );

  Widget _rangeField({
    required String label,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String suffix,
    required num min,
    required num max,
  }) =>
      Row(
        children: [
          Expanded(child: _numberField(
            label: label,
            controller: minController,
            suffix: suffix,
            min: min,
            max: max,
          )),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-')),
          Expanded(child: _numberField(
            label: '',
            controller: maxController,
            suffix: suffix,
            min: min,
            max: max,
          )),
        ],
      );

  bool _isValidNumber(String? value, num min, num max) {
    final number = num.tryParse(value ?? '');
    return number != null && number >= min && number <= max;
  }

  DatagenRules _defaultRules() => const DatagenRules(
        trackerIntervalSeconds: 300,
        capsuleIntervalSeconds: 900,
        fenceExcursionProbability: 0.02,
        fenceExcursionMinMinutes: 10,
        fenceExcursionMaxMinutes: 30,
        healthEventProbability: 0.005,
        feverDurationMinMinutes: 240,
        feverDurationMaxMinutes: 480,
        motilityDurationMinMinutes: 480,
        motilityDurationMaxMinutes: 720,
      );

  void _resetDefaults() {
    _setTextFromRules(_defaultRules());
  }

  void _setTextFromRules(DatagenRules rules) {
    _trackerInterval.text = _minutesText(rules.trackerIntervalSeconds);
    _capsuleInterval.text = _minutesText(rules.capsuleIntervalSeconds);
    _fenceProbability.text = _percentText(rules.fenceExcursionProbability);
    _fenceMin.text = rules.fenceExcursionMinMinutes.toString();
    _fenceMax.text = rules.fenceExcursionMaxMinutes.toString();
    _healthProbability.text = _percentText(rules.healthEventProbability);
    _feverMin.text = _hoursText(rules.feverDurationMinMinutes);
    _feverMax.text = _hoursText(rules.feverDurationMaxMinutes);
    _motilityMin.text = _hoursText(rules.motilityDurationMinMinutes);
    _motilityMax.text = _hoursText(rules.motilityDurationMaxMinutes);
  }

  Future<void> _saveRules() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rules = _readRules();
    if (rules == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.datagenConsoleInvalidRules),
      ));
      return;
    }
    await ref.read(datagenControllerProvider.notifier).saveRules(rules);
  }

  DatagenRules? _readRules() {
    final trackerMinutes = int.tryParse(_trackerInterval.text);
    final capsuleMinutes = int.tryParse(_capsuleInterval.text);
    final fencePercent = double.tryParse(_fenceProbability.text);
    final fenceMin = int.tryParse(_fenceMin.text);
    final fenceMax = int.tryParse(_fenceMax.text);
    final healthPercent = double.tryParse(_healthProbability.text);
    final feverMinHours = double.tryParse(_feverMin.text);
    final feverMaxHours = double.tryParse(_feverMax.text);
    final motilityMinHours = double.tryParse(_motilityMin.text);
    final motilityMaxHours = double.tryParse(_motilityMax.text);
    if (trackerMinutes == null || capsuleMinutes == null ||
        fencePercent == null || fenceMin == null || fenceMax == null ||
        healthPercent == null || feverMinHours == null ||
        feverMaxHours == null || motilityMinHours == null ||
        motilityMaxHours == null || fenceMin > fenceMax ||
        feverMinHours > feverMaxHours || motilityMinHours > motilityMaxHours) {
      return null;
    }
    return DatagenRules(
      trackerIntervalSeconds: trackerMinutes * 60,
      capsuleIntervalSeconds: capsuleMinutes * 60,
      fenceExcursionProbability: fencePercent / 100,
      fenceExcursionMinMinutes: fenceMin,
      fenceExcursionMaxMinutes: fenceMax,
      healthEventProbability: healthPercent / 100,
      feverDurationMinMinutes: (feverMinHours * 60).round(),
      feverDurationMaxMinutes: (feverMaxHours * 60).round(),
      motilityDurationMinMinutes: (motilityMinHours * 60).round(),
      motilityDurationMaxMinutes: (motilityMaxHours * 60).round(),
    );
  }

  String _minutesText(int seconds) {
    final value = seconds / 60;
    return value == value.roundToDouble() ? value.round().toString() : value.toString();
  }

  String _hoursText(int minutes) {
    final value = minutes / 60;
    return value == value.roundToDouble() ? value.round().toString() : value.toString();
  }

  String _percentText(double probability) {
    final value = probability * 100;
    return value == value.roundToDouble() ? value.round().toString() : value.toString();
  }
}

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab({required this.console});

  final DatagenConsoleData? console;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(datagenControllerProvider);
    final controller = ref.read(datagenControllerProvider.notifier);
    final all = console?.devices ?? const <DatagenDevice>[];
    final filtered = all.where((device) {
      final typeOk = state.deviceTypeFilter == 'ALL' ||
          device.deviceType == state.deviceTypeFilter;
      final query = state.search.toLowerCase();
      final searchOk = query.isEmpty ||
          device.deviceCode.toLowerCase().contains(query) ||
          device.devEui.toLowerCase().contains(query) ||
          device.livestockCode.toLowerCase().contains(query);
      return typeOk && searchOk;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(l10n.datagenConsoleSelectedCount(
                  state.selectedDeviceIds.length)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => controller.selectAllFiltered(filtered, true),
                child: Text(l10n.datagenConsoleSelectFiltered),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => controller.selectAllFiltered(filtered, false),
                child: Text(l10n.datagenConsoleClearSelection),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: state.isSavingDevices ? null : controller.saveDevices,
                child: state.isSavingDevices
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.datagenConsoleSaveRange),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.datagenConsoleColDevice)),
                  DataColumn(label: Text(l10n.datagenConsoleColType)),
                  DataColumn(label: Text(l10n.datagenConsoleColLivestock)),
                  DataColumn(label: Text(l10n.datagenConsoleColRuntime)),
                  DataColumn(label: Text(l10n.datagenConsoleColFrequency)),
                  DataColumn(
                      label: Text(l10n.datagenConsoleColLastGenerated)),
                ],
                rows: filtered
                    .map((device) => DataRow(
                          selected:
                              state.selectedDeviceIds.contains(device.deviceId),
                          cells: [
                            DataCell(
                              Tooltip(
                                message: device.eligible
                                    ? device.devEui
                                    : l10n.datagenConsoleDevicesRequired,
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: state.selectedDeviceIds
                                          .contains(device.deviceId),
                                      onChanged: device.eligible
                                          ? (value) => controller.toggleDevice(
                                              device.deviceId, value ?? false)
                                          : null,
                                    ),
                                    Text(device.deviceCode),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(_deviceType(l10n, device.deviceType))),
                            DataCell(Text(device.livestockCode)),
                            DataCell(_RuntimeTag(status: device.runtimeStatus)),
                            DataCell(Text(device.deviceType == 'TRACKER'
                                ? '${rules.trackerIntervalSeconds ~/ 60} ${l10n.datagenConsoleRulesUnitMinutes}'
                                : '${rules.capsuleIntervalSeconds ~/ 60} ${l10n.datagenConsoleRulesUnitMinutes}')),
                            DataCell(Text(_time(device.lastGeneratedAt) ??
                                l10n.datagenConsoleNever)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _deviceType(AppLocalizations l10n, String deviceType) =>
      switch (deviceType) {
        'TRACKER' => l10n.datagenConsoleTracker,
        'CAPSULE' => l10n.datagenConsoleCapsule,
        _ => deviceType,
      };

  DatagenRules get rules =>
      console?.rules ??
      const DatagenRules(
        trackerIntervalSeconds: 300,
        capsuleIntervalSeconds: 900,
        fenceExcursionProbability: 0.02,
        fenceExcursionMinMinutes: 10,
        fenceExcursionMaxMinutes: 30,
        healthEventProbability: 0.005,
        feverDurationMinMinutes: 240,
        feverDurationMaxMinutes: 480,
        motilityDurationMinMinutes: 480,
        motilityDurationMaxMinutes: 720,
      );
}

class _ClearTab extends StatelessWidget {
  const _ClearTab({
    required this.console,
    required this.rangeType,
    required this.previewResult,
    required this.clearResult,
    required this.isClearing,
    required this.fromController,
    required this.toController,
    required this.onRangeChanged,
    required this.onPreview,
    required this.onClear,
  });

  final DatagenConsoleData? console;
  final String rangeType;
  final DatagenClearResult? previewResult;
  final DatagenClearResult? clearResult;
  final bool isClearing;
  final TextEditingController fromController;
  final TextEditingController toController;
  final ValueChanged<String> onRangeChanged;
  final VoidCallback onPreview;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = clearResult ?? previewResult;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: l10n.datagenConsoleClearData,
          child: RadioGroup<String>(
            groupValue: rangeType,
            onChanged: (value) {
              if (value != null) onRangeChanged(value);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'LAST_24_HOURS',
                  title: Text(l10n.datagenConsoleRange24h),
                ),
                RadioListTile<String>(
                  value: 'LAST_7_DAYS',
                  title: Text(l10n.datagenConsoleRange7d),
                ),
                RadioListTile<String>(
                  value: 'ALL',
                  title: Text(l10n.datagenConsoleRangeAll),
                ),
                RadioListTile<String>(
                  value: 'CUSTOM',
                  title: Text(l10n.datagenConsoleRangeCustom),
                ),
                if (rangeType == 'CUSTOM') ...[
                  TextField(
                    controller: fromController,
                    decoration:
                        InputDecoration(labelText: l10n.datagenConsoleFrom),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: toController,
                    decoration:
                        InputDecoration(labelText: l10n.datagenConsoleTo),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: l10n.datagenConsolePreview,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result != null) ...[
                _summaryRow(
                    l10n.datagenConsoleDeletedTotal, '${result.totalDeleted}'),
                _summaryRow(l10n.datagenConsoleUnattributableRows,
                    '${result.unattributableHealthRows + result.unattributableAlertRows}'),
              ],
              _Notice(
                text: l10n.datagenConsoleCrossFarmLimit,
                color: AppColors.warningStrong,
                background: AppColors.warningSoft,
              ),
              const SizedBox(height: 8),
              _Notice(
                text: l10n.datagenConsoleRunningCannotClear,
                color: AppColors.dangerStrong,
                background: AppColors.dangerSoft,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: onPreview, child: Text(l10n.datagenConsolePreview)),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        console?.enabled == true || isClearing ? null : onClear,
                    child: isClearing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.datagenConsoleClearData),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _OperationsTab extends StatelessWidget {
  const _OperationsTab({required this.operations});

  final List<DatagenOperation> operations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (operations.isEmpty) {
      return _EmptyPanel(message: l10n.datagenConsoleNoOperations);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: operations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final operation = operations[index];
        return ListTile(
          dense: true,
          title: Text(_operationLabel(l10n, operation.summaryKey)),
          subtitle: Text(
              '${_time(operation.occurredAt) ?? '-'} · ${_roleLabel(l10n, operation.operatorRole)}'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  String _operationLabel(AppLocalizations l10n, String key) => switch (key) {
        'datagenConsoleOperationStart' => l10n.datagenConsoleOperationStart,
        'datagenConsoleOperationStop' => l10n.datagenConsoleOperationStop,
        'datagenConsoleOperationUpdateDevices' =>
          l10n.datagenConsoleOperationUpdateDevices,
        'datagenConsoleOperationUpdateRules' =>
          l10n.datagenConsoleOperationUpdateRules,
        'datagenConsoleOperationClear' => l10n.datagenConsoleOperationClear,
        _ => key,
      };

  String _roleLabel(AppLocalizations l10n, String role) =>
      switch (role.toUpperCase()) {
        'PLATFORM_ADMIN' => l10n.datagenConsoleRolePlatform,
        'B2B_ADMIN' => l10n.datagenConsoleRoleB2b,
        _ => role,
      };
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.actions});

  final String title;
  final List<Widget>? actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  if (actions != null) ...[
                    const SizedBox(width: 8),
                    ...actions!,
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 12, color: color)),
      );
}

class _RuntimeTag extends StatelessWidget {
  const _RuntimeTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final online = status.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: online ? AppColors.successSoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.isEmpty
            ? '-'
            : online
                ? AppLocalizations.of(context)!.datagenConsoleRuntimeOnline
                : AppLocalizations.of(context)!.datagenConsoleRuntimeOffline,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: online
              ? AppColors.successStrong
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: Text(message)),
      );
}

String? _time(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
