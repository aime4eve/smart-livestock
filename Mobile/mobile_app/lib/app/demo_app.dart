import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_router.dart';
import 'package:smart_livestock_demo/core/theme/app_theme.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _DemoAppView());
  }
}

class _DemoAppView extends ConsumerWidget {
  const _DemoAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
    );
  }
}
