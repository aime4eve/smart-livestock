import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps a child widget with periodic auto-refresh + app lifecycle awareness.
///
/// Used to poll health detail pages without converting them to StatefulWidget.
/// Timer pauses when the app goes to background and resumes (with an immediate
/// tick) when it returns to the foreground.
///
/// Note: on Flutter web, navigating away disposes the widget and cancels the
/// timer automatically. If this is ever used on native mobile with
/// Navigator.push (which keeps the previous route alive), extend with RouteAware
/// to pause when the route is not topmost.
class AutoRefreshListener extends StatefulWidget {
  const AutoRefreshListener({
    super.key,
    required this.interval,
    required this.onTick,
    required this.child,
  });

  final Duration interval;
  final VoidCallback onTick;
  final Widget child;

  @override
  State<AutoRefreshListener> createState() => _AutoRefreshListenerState();
}

class _AutoRefreshListenerState extends State<AutoRefreshListener>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) widget.onTick();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      widget.onTick(); // immediate refresh on resume
    } else {
      _stopTimer();
    }
  }

  @override
  void didUpdateWidget(covariant AutoRefreshListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
