import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';

class TbDeviceWizardState {
  const TbDeviceWizardState({
    this.preflight,
    this.result,
    this.loading = false,
    this.error,
  });

  final TbDevicePreflight? preflight;
  final TbDeviceProvisionResult? result;
  final bool loading;
  final String? error;
}

class TbDeviceWizardController extends FarmScopedNotifier<TbDeviceWizardState> {
  @override
  TbDeviceWizardState build() {
    watchActiveFarmId();
    return const TbDeviceWizardState();
  }

  Future<void> preflight(String eui) async {
    state = const TbDeviceWizardState(loading: true);
    try {
      final preflight = await ref.read(devicesRepositoryProvider)
          .preflightTbDevice(eui.trim().toLowerCase());
      state = TbDeviceWizardState(preflight: preflight);
    } catch (e) {
      state = TbDeviceWizardState(error: e.toString());
    }
  }

  Future<void> provision({
    required TbDevicePreflight preflight,
    required String deviceCode,
    required String? livestockId,
  }) async {
    final candidate = preflight.selectedCandidate;
    if (candidate == null) return;
    state = TbDeviceWizardState(preflight: preflight, loading: true);
    try {
      final result = await ref.read(devicesRepositoryProvider)
          .provisionTbDevice(
            eui: preflight.eui,
            deviceCode: deviceCode.trim(),
            deviceType: candidate.deviceType,
            livestockId: livestockId,
          );
      state = TbDeviceWizardState(preflight: preflight, result: result);
    } catch (e) {
      state = TbDeviceWizardState(
        preflight: preflight,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const TbDeviceWizardState();
  }
}

final tbDeviceWizardControllerProvider =
    NotifierProvider<TbDeviceWizardController, TbDeviceWizardState>(
  TbDeviceWizardController.new,
);
