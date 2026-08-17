import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/data/datagen_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';

final datagenApiRepositoryProvider = Provider<DatagenApiRepository>(
  (ref) => const DatagenApiRepository(),
);

@immutable
class DatagenConsoleState {
  const DatagenConsoleState({
    this.farms = const [],
    this.console,
    this.selectedFarmId,
    this.selectedDeviceIds = const <int>{},
    this.deviceTypeFilter = 'ALL',
    this.search = '',
    this.isLoading = false,
    this.isSwitching = false,
    this.isSavingDevices = false,
    this.isClearing = false,
    this.previewResult,
    this.clearResult,
    this.error,
  });

  final List<DatagenFarm> farms;
  final DatagenConsoleData? console;
  final int? selectedFarmId;
  final Set<int> selectedDeviceIds;
  final String deviceTypeFilter;
  final String search;
  final bool isLoading;
  final bool isSwitching;
  final bool isSavingDevices;
  final bool isClearing;
  final DatagenClearResult? previewResult;
  final DatagenClearResult? clearResult;
  final String? error;

  DatagenConsoleState copyWith({
    List<DatagenFarm>? farms,
    DatagenConsoleData? console,
    int? selectedFarmId,
    Set<int>? selectedDeviceIds,
    String? deviceTypeFilter,
    String? search,
    bool? isLoading,
    bool? isSwitching,
    bool? isSavingDevices,
    bool? isClearing,
    DatagenClearResult? previewResult,
    DatagenClearResult? clearResult,
    String? error,
    bool clearError = false,
    bool clearPreview = false,
    bool discardClearResult = false,
  }) =>
      DatagenConsoleState(
        farms: farms ?? this.farms,
        console: console ?? this.console,
        selectedFarmId: selectedFarmId ?? this.selectedFarmId,
        selectedDeviceIds: selectedDeviceIds ?? this.selectedDeviceIds,
        deviceTypeFilter: deviceTypeFilter ?? this.deviceTypeFilter,
        search: search ?? this.search,
        isLoading: isLoading ?? this.isLoading,
        isSwitching: isSwitching ?? this.isSwitching,
        isSavingDevices: isSavingDevices ?? this.isSavingDevices,
        isClearing: isClearing ?? this.isClearing,
        previewResult: clearPreview ? null : previewResult ?? this.previewResult,
        clearResult: discardClearResult
            ? null
            : clearResult ?? this.clearResult,
        error: clearError && error == null
            ? null
            : error ?? this.error,
      );
}

class DatagenController extends Notifier<DatagenConsoleState> {
  @override
  DatagenConsoleState build() => const DatagenConsoleState();

  DatagenApiRepository get _repository =>
      ref.read(datagenApiRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearPreview: true,
      discardClearResult: true,
    );
    try {
      final farms = await _repository.loadFarms();
      final nextFarm = farms.firstOrNull;
      state = state.copyWith(farms: farms, selectedFarmId: nextFarm?.farmId);
      if (nextFarm != null) {
        await _loadConsole(nextFarm.farmId);
      }
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectFarm(int farmId) async {
    state = state.copyWith(
      selectedFarmId: farmId,
      clearError: true,
      clearPreview: true,
      discardClearResult: true,
    );
    await _loadConsole(farmId);
  }

  void setFilter({String? deviceType, String? search}) {
    state = state.copyWith(
      deviceTypeFilter: deviceType,
      search: search,
      clearError: true,
    );
  }

  void toggleDevice(int deviceId, bool selected) {
    final next = {...state.selectedDeviceIds};
    selected ? next.add(deviceId) : next.remove(deviceId);
    state = state.copyWith(selectedDeviceIds: next, clearError: true);
  }

  void selectAllFiltered(List<DatagenDevice> devices, bool selected) {
    final eligible = devices.where((device) => device.eligible).map(
          (device) => device.deviceId,
        );
    final next = {...state.selectedDeviceIds};
    selected ? next.addAll(eligible) : next.removeAll(eligible);
    state = state.copyWith(selectedDeviceIds: next, clearError: true);
  }

  Future<void> toggleRun() async {
    final console = state.console;
    final farmId = state.selectedFarmId;
    if (console == null || farmId == null) return;
    final enabled = !console.enabled;
    if (enabled && state.selectedDeviceIds.isEmpty) {
      state = state.copyWith(
        error: 'error.datagen.devicesRequired',
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isSwitching: true, clearError: true);
    try {
      final next = await _repository.updateControl(
        farmId: farmId,
        enabled: enabled,
        deviceIds: state.selectedDeviceIds.toList(),
      );
      state = state.copyWith(console: next, discardClearResult: true);
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    } finally {
      state = state.copyWith(isSwitching: false);
    }
  }

  Future<void> saveDevices() async {
    final farmId = state.selectedFarmId;
    final enabled = state.console?.enabled ?? false;
    if (farmId == null) return;
    if (enabled && state.selectedDeviceIds.isEmpty) {
      state = state.copyWith(
        error: 'error.datagen.devicesRequired',
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isSavingDevices: true, clearError: true);
    try {
      final next = await _repository.updateControl(
        farmId: farmId,
        enabled: enabled,
        deviceIds: state.selectedDeviceIds.toList(),
      );
      state = state.copyWith(console: next, discardClearResult: true);
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    } finally {
      state = state.copyWith(isSavingDevices: false);
    }
  }

  Future<void> previewClear({
    required String rangeType,
    DateTime? from,
    DateTime? to,
  }) async {
    final farmId = state.selectedFarmId;
    if (farmId == null) return;
    try {
      final result = await _repository.previewClear(
        farmId: farmId,
        rangeType: rangeType,
        from: from,
        to: to,
      );
      state = state.copyWith(previewResult: result, clearError: true);
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    }
  }

  Future<void> clear({
    required String rangeType,
    required String confirmText,
    DateTime? from,
    DateTime? to,
  }) async {
    final farmId = state.selectedFarmId;
    if (farmId == null) return;
    state = state.copyWith(isClearing: true, clearError: true);
    try {
      final result = await _repository.clear(
        farmId: farmId,
        rangeType: rangeType,
        confirmText: confirmText,
        from: from,
        to: to,
      );
      final console = await _repository.loadConsole(farmId);
      state = state.copyWith(console: console, clearResult: result);
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    } finally {
      state = state.copyWith(isClearing: false);
    }
  }

  Future<void> _loadConsole(int farmId) async {
    state = state.copyWith(isLoading: true);
    try {
      final console = await _repository.loadConsole(farmId);
      state = state.copyWith(
        console: console,
        selectedDeviceIds: console.devices
            .where((device) => device.selected)
            .map((device) => device.deviceId)
            .toSet(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString(), clearError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final datagenControllerProvider =
    NotifierProvider<DatagenController, DatagenConsoleState>(
  DatagenController.new,
);
