import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_edit_overlay.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_edit_toolbar.dart';

void main() {
  testWidgets('进入编辑态后显示 overlay 与保存按钮', (tester) async {
    final mapController = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FenceEditOverlay(
                mapController: mapController,
                points: const [
                  LatLng(28.0, 112.0),
                  LatLng(28.0, 112.1),
                  LatLng(28.1, 112.1),
                  LatLng(28.1, 112.0),
                ],
                activeTool: FenceEditTool.moveVertex,
                onMoveVertex: _noopMove,
                onInsertVertex: _noopInsert,
                onRemoveVertex: _noopRemove,
                onTranslate: _noopTranslate,
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: FenceEditToolbar(
                  activeTool: FenceEditTool.moveVertex,
                  onSave: _noop,
                  onExit: _noop,
                  onUndo: _noop,
                  onRedo: _noop,
                  onSelectTool: _noopSelect,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('fence-edit-overlay')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-save')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-move')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-insert')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-delete')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-translate')), findsOneWidget);
  });

  testWidgets('非编辑态不显示 overlay 与 toolbar', (tester) async {
    final mapController = MapController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FenceEditOverlay(
                isEditing: false,
                mapController: mapController,
                points: const [],
                activeTool: FenceEditTool.moveVertex,
                onMoveVertex: _noopMove,
                onInsertVertex: _noopInsert,
                onRemoveVertex: _noopRemove,
                onTranslate: _noopTranslate,
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: FenceEditToolbar(
                  activeTool: FenceEditTool.moveVertex,
                  onSave: _noop,
                  onExit: _noop,
                  onUndo: _noop,
                  onRedo: _noop,
                  onSelectTool: _noopSelect,
                  isEditing: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('fence-edit-overlay')), findsNothing);
    expect(find.byKey(const Key('fence-edit-toolbar')), findsNothing);
    expect(find.byKey(const Key('fence-edit-save')), findsNothing);
    expect(find.byKey(const Key('fence-edit-exit')), findsNothing);
    expect(find.byKey(const Key('fence-edit-undo')), findsNothing);
    expect(find.byKey(const Key('fence-edit-redo')), findsNothing);
  });

  testWidgets('canUndo 与 canRedo 为 false 时按钮禁用', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FenceEditToolbar(
              activeTool: FenceEditTool.moveVertex,
              onSave: _noop,
              onExit: _noop,
              onUndo: _noop,
              onRedo: _noop,
              onSelectTool: _noopSelect,
              canUndo: false,
              canRedo: false,
            ),
          ),
        ),
      ),
    );

    final IconButton undoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-undo')),
    );
    final IconButton redoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-redo')),
    );

    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNull);
  });
}

void _noop() {}
void _noopSelect(FenceEditTool _) {}
void _noopMove(int _, LatLng __) {}
void _noopInsert(int _, LatLng __) {}
void _noopRemove(int _) {}
void _noopTranslate(double _, double __) {}
