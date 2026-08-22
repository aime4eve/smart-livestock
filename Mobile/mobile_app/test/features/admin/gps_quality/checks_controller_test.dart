import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

class _FakeRepository extends GpsQualityApiRepository {
  _FakeRepository(this.pages);

  final List<QualityCheckListResult> pages;
  final calls =
      <({String? status, String? eui, int? deviceId, int page, int size})>[];

  @override
  Future<QualityCheckListResult> fetchChecks({
    String? status,
    String? eui,
    int? deviceId,
    int page = 0,
    int size = 200,
  }) async {
    calls.add((
      status: status,
      eui: eui,
      deviceId: deviceId,
      page: page,
      size: size,
    ));
    return pages[page];
  }
}

QualityCheck _check(int id, String deviceCode) => QualityCheck(
  id: id,
  deviceCode: deviceCode,
  deviceId: id,
  checkType: 'LINE',
  startedAt: DateTime(2026, 8, 21, 18),
  status: 'READY',
);

void main() {
  test(
    'search sends filters to the server and resets to the first page',
    () async {
      final repo = _FakeRepository([
        QualityCheckListResult(
          items: [_check(1, 'GPS-0095690a00008c5a')],
          page: 0,
          pageSize: 200,
          total: 1,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [gpsQualityApiRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final controller = container.read(checksProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.fetchFiltered(status: 'READY', eui: '0095690a00008c5a');

      expect(repo.calls.last.status, 'READY');
      expect(repo.calls.last.eui, '0095690a00008c5a');
      expect(repo.calls.last.page, 0);
      expect(repo.calls.last.size, 200);
      expect(
        container.read(checksProvider).value!.items.single.deviceCode,
        'GPS-0095690a00008c5a',
      );
    },
  );

  test('load more appends the next page and keeps filters', () async {
    final repo = _FakeRepository([
      QualityCheckListResult(
        items: [_check(1, 'GPS-A')],
        page: 0,
        pageSize: 1,
        total: 2,
      ),
      QualityCheckListResult(
        items: [_check(2, 'GPS-B')],
        page: 1,
        pageSize: 1,
        total: 2,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [gpsQualityApiRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final controller = container.read(checksProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.fetchFiltered(eui: '0095690a00008c5a');
    await controller.loadMore();

    expect(repo.calls.last.eui, '0095690a00008c5a');
    expect(repo.calls.last.page, 1);
    expect(container.read(checksProvider).value!.items.map((c) => c.id), [
      1,
      2,
    ]);
  });
}
