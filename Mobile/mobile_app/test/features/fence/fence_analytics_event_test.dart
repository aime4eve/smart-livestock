import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_analytics.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  test('startEditing 成功时记录 fence_edit_enter 且 payload 正确', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');

    expect(sink.events.length, 1);
    expect(sink.events.single.name, FenceAnalyticsEventName.fenceEditEnter);
    expect(
      sink.events.single.parameters,
      {FenceAnalyticsParamKey.fenceId: 'fence_pasture_a'},
    );
  });

  test('startEditing 无效 fenceId 时不记录 fence_edit_enter', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('missing');

    expect(sink.events, isEmpty);
  });

  test('saveEditing 时记录 fence_edit_save', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    sink.events.clear();
    controller.saveEditing();

    expect(sink.events.length, 1);
    expect(
      sink.events.single.name,
      FenceAnalyticsEventName.fenceEditSaveSuccess,
    );
    expect(
      sink.events.single.parameters,
      {FenceAnalyticsParamKey.fenceId: 'fence_pasture_a'},
    );
  });

  test('cancelEditing 时记录 fence_edit_cancel', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    sink.events.clear();
    controller.cancelEditing();

    expect(sink.events.length, 1);
    expect(
      sink.events.single.name,
      FenceAnalyticsEventName.fenceEditExitWithoutSave,
    );
    expect(
      sink.events.single.parameters,
      {FenceAnalyticsParamKey.fenceId: 'fence_pasture_a'},
    );
  });

  test('saveEditing 无 session 时不记录事件', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.saveEditing();

    expect(sink.events, isEmpty);
  });

  test('cancelEditing 无 session 时不记录事件', () {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = _SingleFenceRepository(_fenceA);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
        fenceAnalyticsSinkProvider.overrideWithValue(sink),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.cancelEditing();

    expect(sink.events, isEmpty);
  });
}

class _SingleFenceRepository implements FenceRepository {
  _SingleFenceRepository(this._fence);

  final FenceItem _fence;

  @override
  List<FenceItem> loadAll() => [_fence];
}

const _fenceA = FenceItem(
  id: 'fence_pasture_a',
  name: '放牧A区',
  type: FenceType.rectangle,
  alarmEnabled: true,
  active: true,
  areaHectares: 1,
  livestockCount: 1,
  colorValue: 0xFF4C9A5F,
  points: [
    LatLng(28.0, 112.0),
    LatLng(28.0, 112.1),
    LatLng(28.1, 112.1),
    LatLng(28.1, 112.0),
  ],
);
