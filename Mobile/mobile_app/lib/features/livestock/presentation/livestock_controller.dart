import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/livestock/data/livestock_api_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';

final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  return const LivestockApiRepository();
});

class LivestockListController extends FarmScopedAsyncNotifier<LivestockListData> {
  static const _pageSize = 20;
  String _keyword = '';
  int _page = 1;
  int _totalPages = 1;

  int get totalPages => _totalPages;
  int get currentPage => _page;
  int get pageSize => _pageSize;

  @override
  Future<LivestockListData> build() async {
    watchActiveFarmId();
    _page = 1;
    return _fetch();
  }

  Future<LivestockListData> _fetch() async {
    final data = await ref.read(livestockRepositoryProvider).loadAll(
          page: _page,
          pageSize: _pageSize,
          keyword: _keyword.isNotEmpty ? _keyword : null,
        );
    _totalPages = (data.total / _pageSize).ceil().clamp(1, 9999);
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> search(String keyword) async {
    _keyword = keyword;
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      _fetch,
    );
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _page) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final livestockListControllerProvider =
    AsyncNotifierProvider<LivestockListController, LivestockListData>(
  LivestockListController.new,
);

class LivestockDetailController extends AsyncNotifier<LivestockDetail> {
  LivestockDetailController(this.id);

  final String id;

  @override
  Future<LivestockDetail> build() async {
    return ref.read(livestockRepositoryProvider).loadDetail(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(livestockRepositoryProvider).loadDetail(id),
    );
  }
}

final livestockDetailControllerProvider = AsyncNotifierProvider.family<
    LivestockDetailController, LivestockDetail, String>(
  LivestockDetailController.new,
);
