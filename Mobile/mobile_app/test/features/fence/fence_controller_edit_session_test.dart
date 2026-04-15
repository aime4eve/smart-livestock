import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  test('startEditing 后设置 selectedFenceId 与 editSession 关键字段', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(fenceControllerProvider);
    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');

    final state = container.read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_a');
    expect(state.editSession, isNotNull);
    expect(state.editSession!.fenceId, 'fence_pasture_a');
    expect(state.editSession!.originalPoints, before.fences.first.points);
    expect(state.editSession!.points, before.fences.first.points);
    expect(state.editMode, FenceEditMode.editIdle);
  });

  test('moveDraftVertex 后进入 editDirty 且不污染 originalPoints', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    final before = container.read(fenceControllerProvider).editSession!;
    final originalFirstPoint = before.originalPoints.first;
    controller.moveDraftVertex(0, const LatLng(28.2400, 112.9500));

    final state = container.read(fenceControllerProvider);
    expect(state.editSession, isNotNull);
    expect(state.editMode, FenceEditMode.editDirty);
    expect(
      state.editSession!.points.first,
      const LatLng(28.2400, 112.9500),
    );
    expect(
      state.editSession!.originalPoints.first,
      originalFirstPoint,
    );
  });

  test('insert/remove/translate 与 undo/redo 会更新真实草稿', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');

    controller.selectEditTool(FenceEditTool.insertVertex);
    controller.insertDraftVertex(0, const LatLng(28.05, 112.05));

    var state = container.read(fenceControllerProvider);
    expect(state.editSession, isNotNull);
    expect(state.editMode, FenceEditMode.editDirty);
    expect(state.editSession!.points.length, 5);
    expect(state.editSession!.points[1], const LatLng(28.05, 112.05));

    controller.selectEditTool(FenceEditTool.deleteVertex);
    controller.removeDraftVertex(1);
    state = container.read(fenceControllerProvider);
    expect(state.editSession!.points.length, 4);
    expect(state.editSession!.points, isNot(contains(const LatLng(28.05, 112.05))));

    final beforeTranslate = state.editSession!.points;
    controller.selectEditTool(FenceEditTool.translate);
    controller.translateDraft(0.02, -0.01);
    state = container.read(fenceControllerProvider);
    expect(state.editSession!.points.first, isNot(beforeTranslate.first));

    controller.undoEdit();
    state = container.read(fenceControllerProvider);
    expect(state.editSession!.points, beforeTranslate);

    controller.redoEdit();
    state = container.read(fenceControllerProvider);
    expect(state.editSession!.points.first, isNot(beforeTranslate.first));
  });

  test('removeDraftVertex 至少保留 3 个点', () {
    final repo = _MutableFenceRepository(fences: [
      const FenceItem(
        id: 'triangle',
        name: '三角区',
        type: FenceType.polygon,
        alarmEnabled: true,
        active: true,
        areaHectares: 1,
        livestockCount: 1,
        colorValue: 0xFF4C9A5F,
        points: [
          LatLng(28.0, 112.0),
          LatLng(28.1, 112.1),
          LatLng(28.2, 112.0),
        ],
      ),
    ]);
    final container = ProviderContainer(
      overrides: [fenceRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('triangle');
    controller.removeDraftVertex(1);

    final state = container.read(fenceControllerProvider);
    expect(state.editSession!.points.length, 3);
    expect(state.editMode, FenceEditMode.editIdle);
  });

  test('select(null) 可清空 selectedFenceId', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.select('fence_pasture_a');
    expect(container.read(fenceControllerProvider).selectedFenceId, isNotNull);

    controller.select(null);
    expect(container.read(fenceControllerProvider).selectedFenceId, isNull);
  });

  test('startEditing 无效 fenceId 时保持原状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    final before = container.read(fenceControllerProvider);
    controller.startEditing('not-exists');
    final after = container.read(fenceControllerProvider);

    expect(after.selectedFenceId, before.selectedFenceId);
    expect(after.editSession, before.editSession);
    expect(after.editMode, before.editMode);
  });

  test('moveDraftVertex 无 session 时忽略', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.moveDraftVertex(0, const LatLng(28.2400, 112.9500));
    final state = container.read(fenceControllerProvider);

    expect(state.editSession, isNull);
    expect(state.editMode, isNull);
  });

  test('moveDraftVertex 索引越界时忽略', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    final before = container.read(fenceControllerProvider).editSession!;

    controller.moveDraftVertex(-1, const LatLng(28.2400, 112.9500));
    controller.moveDraftVertex(999, const LatLng(28.2400, 112.9500));
    final after = container.read(fenceControllerProvider).editSession!;

    expect(after.points, before.points);
    expect(container.read(fenceControllerProvider).editMode, FenceEditMode.editIdle);
  });

  test('delete 删除编辑中的 fence 时清理 editSession 与 editMode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    controller.delete('fence_pasture_a');
    final state = container.read(fenceControllerProvider);

    expect(state.editSession, isNull);
    expect(state.editMode, isNull);
  });

  test('reloadFromRepository 若编辑 fence 消失则清理编辑状态', () {
    final repo = _MutableFenceRepository(fences: [
      _fenceA,
      _fenceB,
    ]);
    final container = ProviderContainer(
      overrides: [
        fenceRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    controller.startEditing('fence_pasture_a');
    expect(container.read(fenceControllerProvider).editSession, isNotNull);

    repo.fences = [_fenceB];
    controller.reloadFromRepository();
    final state = container.read(fenceControllerProvider);

    expect(state.viewState, ViewState.normal);
    expect(state.selectedFenceId, isNull);
    expect(state.editSession, isNull);
    expect(state.editMode, isNull);
  });
}

class _MutableFenceRepository implements FenceRepository {
  _MutableFenceRepository({required this.fences});

  List<FenceItem> fences;

  @override
  List<FenceItem> loadAll() => fences;
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

const _fenceB = FenceItem(
  id: 'fence_pasture_b',
  name: '放牧B区',
  type: FenceType.rectangle,
  alarmEnabled: true,
  active: true,
  areaHectares: 1,
  livestockCount: 1,
  colorValue: 0xFF4C9A5F,
  points: [
    LatLng(29.0, 113.0),
    LatLng(29.0, 113.1),
    LatLng(29.1, 113.1),
    LatLng(29.1, 113.0),
  ],
);
