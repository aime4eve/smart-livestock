import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/farm_creation/presentation/wizard_step_basic_info.dart';
import 'package:smart_livestock_demo/features/farm_creation/presentation/wizard_step_complete.dart';
import 'package:smart_livestock_demo/features/farm_creation/presentation/wizard_step_fence_drawing.dart';

class FarmCreationWizardPage extends ConsumerStatefulWidget {
  const FarmCreationWizardPage({super.key});

  @override
  ConsumerState<FarmCreationWizardPage> createState() =>
      _FarmCreationWizardPageState();
}

class _FarmCreationWizardPageState
    extends ConsumerState<FarmCreationWizardPage> {
  int _step = 1;
  String? _createdFarmId;
  String? _createdFarmName;

  void _onStep1Complete(String farmId, String farmName) {
    setState(() {
      _step = 2;
      _createdFarmId = farmId;
      _createdFarmName = farmName;
    });
  }

  void _onStep2Complete() {
    setState(() => _step = 3);
  }

  void _onStep2Skip() {
    setState(() => _step = 3);
  }

  Future<void> _startDashboard() async {
    final session = ref.read(sessionControllerProvider);
    final cache = ApiCache.instance;
    try {
      final tokens = ApiAuthTokens(accessToken: session.accessToken!);
      await cache.init(
        session.role!.wireName,
        tokens: tokens,
        allowMockTokenFallback: false,
      );
      ref.read(farmDataReadyProvider.notifier).markReady();
    } catch (_) {
      // Graceful degradation — still navigate to dashboard
    }
    if (mounted) context.go('/twin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建牧场')),
      body: switch (_step) {
        1 => WizardStepBasicInfo(onComplete: _onStep1Complete),
        2 => WizardStepFenceDrawing(
            farmId: _createdFarmId!,
            onComplete: _onStep2Complete,
            onSkip: _onStep2Skip,
          ),
        3 => WizardStepComplete(
            farmName: _createdFarmName ?? '',
            fenceCount: 0,
            onStart: _startDashboard,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
