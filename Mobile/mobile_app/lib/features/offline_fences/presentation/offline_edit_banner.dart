import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/database/app_database.dart';

final _appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final unsyncedCountProvider = FutureProvider.family<int, int>((ref, farmId) async {
  final db = ref.watch(_appDatabaseProvider);
  final all = db.getUnsyncedFences();
  return all.where((f) => (f['farm_id'] as int) == farmId).length;
});

class OfflineEditBanner extends ConsumerWidget {
  final int farmId;
  const OfflineEditBanner({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unsyncedCountProvider(farmId));
    return countAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          key: const Key('offline-edit-banner'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Text(
            '$count 个围栏待同步',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            textAlign: TextAlign.center,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
