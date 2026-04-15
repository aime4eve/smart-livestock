import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  test('少于三个点的几何无效', () {
    expect(
      FenceController.validateDraftGeometry(const [
        LatLng(0, 0),
        LatLng(1, 1),
      ]),
      '边界至少需要 3 个点',
    );
  });

  test('连续重复点的几何无效', () {
    expect(
      FenceController.validateDraftGeometry(const [
        LatLng(0, 0),
        LatLng(0, 0),
        LatLng(1, 0),
      ]),
      '边界不能有连续重复点',
    );
  });

  test('零面积几何无效', () {
    expect(
      FenceController.validateDraftGeometry(const [
        LatLng(0, 0),
        LatLng(1, 1),
        LatLng(2, 2),
      ]),
      '边界面积必须大于 0',
    );
  });

  test('自交几何无效', () {
    expect(
      FenceController.validateDraftGeometry(const [
        LatLng(0, 0),
        LatLng(3, 3),
        LatLng(0, 3),
        LatLng(2, 0),
      ]),
      '边界不能自交',
    );
  });

  test('仅当前编辑会话可应用保存结果', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(fenceControllerProvider.notifier);
    final fenceId = container.read(fenceControllerProvider).fences.first.id;

    controller.startEditing(fenceId);
    final originalSession = container.read(fenceControllerProvider).editSession!;
    final insertedPoint = LatLng(
      (originalSession.points[0].latitude + originalSession.points[1].latitude) / 2,
      (originalSession.points[0].longitude + originalSession.points[1].longitude) / 2,
    );
    controller.insertDraftVertex(0, insertedPoint);

    final dirtySession = container.read(fenceControllerProvider).editSession!;
    controller.markSavingEdit();

    expect(
      controller.saveEditingIfCurrent(
        sessionInstanceId: dirtySession.sessionInstanceId + 1,
        fenceId: dirtySession.fenceId,
      ),
      isFalse,
    );
    expect(container.read(fenceControllerProvider).editSession, isNotNull);

    expect(
      controller.saveEditingIfCurrent(
        sessionInstanceId: dirtySession.sessionInstanceId,
        fenceId: dirtySession.fenceId,
      ),
      isTrue,
    );
    expect(container.read(fenceControllerProvider).editSession, isNull);
    expect(
      container
          .read(fenceControllerProvider)
          .fences
          .firstWhere((fence) => fence.id == fenceId)
          .points
          .length,
      dirtySession.points.length,
    );
  });
}
