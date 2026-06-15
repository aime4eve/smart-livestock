import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/digestive/data/digestive_api_repository.dart';
import 'package:hkt_livestock_agentic/features/digestive/domain/digestive_repository.dart';

final digestiveRepositoryProvider = Provider<DigestiveRepository>((ref) {
  return const DigestiveApiRepository();
});

class DigestiveListController extends FarmScopedAsyncNotifier<List<DigestiveListItem>> {
  @override
  Future<List<DigestiveListItem>> build() async {
    watchActiveFarmId();
    return ref.read(digestiveRepositoryProvider).fetchDigestiveList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(digestiveRepositoryProvider).fetchDigestiveList(),
    );
  }
}

final digestiveListControllerProvider =
    AsyncNotifierProvider<DigestiveListController, List<DigestiveListItem>>(
  DigestiveListController.new,
);

class DigestiveDetailController extends AsyncNotifier<DigestiveDetailData> {
  DigestiveDetailController(this.livestockId);
  final String livestockId;

  @override
  Future<DigestiveDetailData> build() async {
    return ref.read(digestiveRepositoryProvider).fetchDigestiveDetail(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(digestiveRepositoryProvider).fetchDigestiveDetail(livestockId),
    );
  }
}

final digestiveDetailControllerProvider = AsyncNotifierProvider.family<
    DigestiveDetailController, DigestiveDetailData, String>(
  DigestiveDetailController.new,
);
