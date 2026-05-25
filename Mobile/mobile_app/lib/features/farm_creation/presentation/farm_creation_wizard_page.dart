import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
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
  int _fenceCount = 0;

  void _onStep1Complete(String farmId, String farmName) {
    setState(() {
      _step = 2;
      _createdFarmId = farmId;
      _createdFarmName = farmName;
    });
  }

  void _onStep2Complete(int count) {
    setState(() {
      _fenceCount = count;
      _step = 3;
    });
  }

  void _onStep2Skip() {
    setState(() => _step = 3);
  }

  Future<void> _startDashboard() async {
    ref.read(farmDataReadyProvider.notifier).reset();
    ref.read(farmDataReadyProvider.notifier).markReady();
    if (mounted) context.go('/twin');
  }

  void _showBackConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('牧场已创建。退出后将进入主页面，您可以稍后设置围栏。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('继续设置')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startDashboard();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 1) {
          _showBackConfirmDialog(context);
        }
      },
      child: Scaffold(
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
              fenceCount: _fenceCount,
              onStart: _startDashboard,
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
