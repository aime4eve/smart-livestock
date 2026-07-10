import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';

/// Base class for all farm-scoped [Notifier]s.
///
/// Watches [sessionControllerProvider.select((s) => s.activeFarmId)]
/// so the controller rebuilds automatically when the user switches farms.
///
/// Every controller that reads farm-scoped data (via [ApiClient.farmGet],
/// [ApiClient.farmPost], etc.) must extend this instead of [Notifier].
abstract class FarmScopedNotifier<StateT> extends Notifier<StateT> {
  /// Returns the currently active farm ID, and declares a dependency
  /// so that [build()] is re-invoked whenever the farm changes.
  String? watchActiveFarmId() {
    return ref.watch(sessionControllerProvider.select((s) => s.activeFarmId));
  }
}

/// Base class for all farm-scoped [AsyncNotifier]s.
///
/// Same as [FarmScopedNotifier] but for async build methods.
abstract class FarmScopedAsyncNotifier<StateT> extends AsyncNotifier<StateT> {
  String? watchActiveFarmId() {
    return ref.watch(sessionControllerProvider.select((s) => s.activeFarmId));
  }
}
