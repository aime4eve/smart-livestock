import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

class ExpiryPopupHandler extends ConsumerStatefulWidget {
  final Widget child;
  const ExpiryPopupHandler({super.key, required this.child});

  @override
  ConsumerState<ExpiryPopupHandler> createState() => _ExpiryPopupHandlerState();
}

class _ExpiryPopupHandlerState extends ConsumerState<ExpiryPopupHandler> {
  bool _hasShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
  }

  void _checkExpiry() {
    if (_hasShown || !mounted) return;
    final status = ref.read(subscriptionControllerProvider);
    final days = status.daysUntilExpiry;
    if (days >= 0 && days <= 7) {
      _hasShown = true;
      _showDialog(days);
    }
  }

  void _showDialog(int daysLeft) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('expiry-dialog'),
        title: const Text('订阅即将到期'),
        content: Text('您的订阅将在 $daysLeft 天后到期，请及时续费以免功能受限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoute.subscriptionPlan.path);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surfaceAlt,
            ),
            child: const Text('前往续费'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
