import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';

enum SignalSyncMode { livestock, map }

/// Declares a page's interest in Signal updates. Polling stops when every
/// scoped page has been disposed.
class SignalSyncScope extends ConsumerStatefulWidget {
  const SignalSyncScope({super.key, required this.mode, required this.child});

  final SignalSyncMode mode;
  final Widget child;

  @override
  ConsumerState<SignalSyncScope> createState() => _SignalSyncScopeState();
}

class _SignalSyncScopeState extends ConsumerState<SignalSyncScope>
    with WidgetsBindingObserver {
  Object? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SignalSyncScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(signalSyncControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      controller.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final controller = ref.read(signalSyncControllerProvider.notifier);
    _subscription = widget.mode == SignalSyncMode.map
        ? controller.subscribeMap()
        : controller.subscribeLivestock();
    controller.resume();
  }

  void _unsubscribe() {
    if (_subscription == null) return;
    ref.read(signalSyncControllerProvider.notifier).unsubscribe(_subscription!);
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
