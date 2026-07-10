import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/devices/data/devices_api_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return const DevicesApiRepository();
});

class DevicesController extends FarmScopedAsyncNotifier<DevicesListData> {
  static const _pageSize = 20;
  String _keyword = '';
  int _page = 1;
  int _totalPages = 1;

  int get totalPages => _totalPages;
  int get currentPage => _page;
  int get pageSize => _pageSize;

  @override
  Future<DevicesListData> build() async {
    watchActiveFarmId();
    _page = 1;
    return _fetch();
  }

  Future<DevicesListData> _fetch() async {
    final data = await ref.read(devicesRepositoryProvider).loadDevices(
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
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _page) return;
    _page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, DevicesListData>(
  DevicesController.new,
);
