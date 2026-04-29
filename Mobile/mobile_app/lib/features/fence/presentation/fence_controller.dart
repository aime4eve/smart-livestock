import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/data/live_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_operations.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_analytics.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

final fenceRepositoryProvider = Provider<FenceRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockFenceRepository();
    case AppMode.live:
      return const LiveFenceRepository();
  }
});

class FenceController extends Notifier<FenceState> {
  int _nextSessionInstanceId = 1;

  @override
  FenceState build() {
    final fences = _loadShapedFences(watchRepository: true);
    return FenceState(
      fences: fences,
      viewState: fences.isEmpty ? ViewState.empty : ViewState.normal,
    );
  }

  List<FenceItem> _loadShapedFences({required bool watchRepository}) {
    var fences = watchRepository
        ? ref.watch(fenceRepositoryProvider).loadAll()
        : ref.read(fenceRepositoryProvider).loadAll();
    final appMode = ref.watch(appModeProvider);
    if (appMode.isLive || fences.isEmpty) return fences;

    final tier = ref.watch(subscriptionControllerProvider).tier;
    final itemMaps = fences
        .map((f) => <String, dynamic>{
              'id': f.id,
              'name': f.name,
            })
        .toList();
    final result = shapeListItems(
      items: itemMaps,
      tier: tier,
      featureKeys: [FeatureFlags.fence],
    );
    if (result.retainedCount < fences.length) {
      fences = fences.take(result.retainedCount).toList();
    }
    return fences;
  }

  void select(String? id) {
    state = state.copyWith(selectedFenceId: id);
  }

  void add(FenceItem item) {
    state = state.copyWith(
      fences: [...state.fences, item],
      viewState: ViewState.normal,
    );
  }

  void update(FenceItem item) {
    state = state.copyWith(
      fences: [
        for (final f in state.fences)
          if (f.id == item.id) item else f,
      ],
    );
  }

  void delete(String id) {
    final newFences = state.fences.where((f) => f.id != id).toList();
    final shouldClearEdit = state.editSession != null &&
        !newFences.any((f) => f.id == state.editSession!.fenceId);
    state = state.copyWith(
      fences: newFences,
      selectedFenceId:
          state.selectedFenceId == id ? null : state.selectedFenceId,
      viewState: newFences.isEmpty ? ViewState.empty : state.viewState,
      clearEditSession: shouldClearEdit,
      clearEditMode: shouldClearEdit,
    );
  }

  void reloadFromRepository() {
    final fences = _loadShapedFences(watchRepository: false);
    var selected = state.selectedFenceId;
    if (selected != null && !fences.any((f) => f.id == selected)) {
      selected = null;
    }
    final shouldClearEdit = state.editSession != null &&
        !fences.any((f) => f.id == state.editSession!.fenceId);
    state = state.copyWith(
      fences: fences,
      selectedFenceId: selected,
      viewState: fences.isEmpty ? ViewState.empty : ViewState.normal,
      clearEditSession: shouldClearEdit,
      clearEditMode: shouldClearEdit,
    );
  }

  void startEditing(String fenceId) {
    if (_isSaving) return;
    FenceItem? targetFence;
    for (final fence in state.fences) {
      if (fence.id == fenceId) {
        targetFence = fence;
        break;
      }
    }
    if (targetFence == null) return;

    ref
        .read(fenceAnalyticsSinkProvider)
        .emitEvent(FenceAnalyticsEvent.fenceEditEnter(fenceId));

    final originalPoints = List<LatLng>.from(targetFence.points);
    state = state.copyWith(
      selectedFenceId: fenceId,
      editSession: FenceEditSession(
        fenceId: fenceId,
        originalPoints: originalPoints,
        points: List<LatLng>.from(originalPoints),
        sessionInstanceId: _nextSessionInstanceId++,
        tool: FenceEditTool.moveVertex,
        undoStack: const [],
        redoStack: const [],
      ),
      editMode: FenceEditMode.editIdle,
    );
  }

  void selectEditTool(FenceEditTool tool) {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null || session.tool == tool) return;
    state = state.copyWith(
      editSession: session.copyWith(tool: tool),
    );
  }

  void moveDraftVertex(int vertexIndex, LatLng nextPoint) {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null) return;
    if (vertexIndex < 0 || vertexIndex >= session.points.length) return;
    _applySessionChange(
      FenceEditOperations.moveVertex(
        session: session,
        vertexIndex: vertexIndex,
        point: nextPoint,
      ),
    );
  }

  void insertDraftVertex(int edgeStartIndex, LatLng point) {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null) return;
    if (edgeStartIndex < 0 || edgeStartIndex >= session.points.length) return;
    _applySessionChange(
      FenceEditOperations.insertVertex(
        session: session,
        edgeStartIndex: edgeStartIndex,
        point: point,
      ),
    );
  }

  void removeDraftVertex(int vertexIndex) {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null) return;
    if (vertexIndex < 0 || vertexIndex >= session.points.length) return;
    _applySessionChange(
      FenceEditOperations.removeVertex(
        session: session,
        vertexIndex: vertexIndex,
      ),
    );
  }

  void translateDraft(double latitudeDelta, double longitudeDelta) {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null) return;
    if (latitudeDelta == 0 && longitudeDelta == 0) return;
    _applySessionChange(
      FenceEditOperations.translate(
        session: session,
        latitudeDelta: latitudeDelta,
        longitudeDelta: longitudeDelta,
      ),
    );
  }

  void undoEdit() {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null || session.undoStack.isEmpty) return;

    final previousPoints = session.undoStack.last;
    final nextUndoStack =
        session.undoStack.take(session.undoStack.length - 1).toList();
    final nextSession = session.copyWith(
      points: previousPoints,
      undoStack: nextUndoStack,
      redoStack: [...session.redoStack, session.points],
    );
    state = state.copyWith(
      editSession: nextSession,
      editMode: nextSession.hasChanges
          ? FenceEditMode.editDirty
          : FenceEditMode.editIdle,
    );
  }

  void redoEdit() {
    if (_isSaving) return;
    final session = state.editSession;
    if (session == null || session.redoStack.isEmpty) return;

    final nextPoints = session.redoStack.last;
    final nextRedoStack =
        session.redoStack.take(session.redoStack.length - 1).toList();
    final nextSession = session.copyWith(
      points: nextPoints,
      undoStack: [...session.undoStack, session.points],
      redoStack: nextRedoStack,
    );
    state = state.copyWith(
      editSession: nextSession,
      editMode: nextSession.hasChanges
          ? FenceEditMode.editDirty
          : FenceEditMode.editIdle,
    );
  }

  void markSavingEdit() {
    if (state.editSession == null) return;
    state = state.copyWith(editMode: FenceEditMode.saving);
  }

  void restoreEditingAfterSaveFailure() {
    final session = state.editSession;
    if (session == null) return;
    state = state.copyWith(
      editMode:
          session.hasChanges ? FenceEditMode.editDirty : FenceEditMode.editIdle,
    );
  }

  bool restoreEditingAfterSaveFailureIfCurrent({
    required int sessionInstanceId,
    required String fenceId,
  }) {
    if (!_matchesEditingSession(
      sessionInstanceId: sessionInstanceId,
      fenceId: fenceId,
    )) {
      return false;
    }
    restoreEditingAfterSaveFailure();
    return true;
  }

  void cancelEditing() {
    if (_isSaving) return;
    if (state.editSession == null) return;
    ref.read(fenceAnalyticsSinkProvider).emitEvent(
          FenceAnalyticsEvent.fenceEditExitWithoutSave(
            state.editSession!.fenceId,
          ),
        );
    state = state.copyWith(
      clearEditSession: true,
      clearEditMode: true,
    );
  }

  void discardEditing() {
    if (_isSaving) return;
    cancelEditing();
  }

  void saveEditing() {
    final session = state.editSession;
    if (session == null) return;

    ref.read(fenceAnalyticsSinkProvider).emitEvent(
          FenceAnalyticsEvent.fenceEditSaveSuccess(session.fenceId),
        );

    state = state.copyWith(
      fences: [
        for (final fence in state.fences)
          if (fence.id == session.fenceId)
            fence.copyWith(points: List<LatLng>.from(session.points))
          else
            fence,
      ],
      selectedFenceId: session.fenceId,
      clearEditSession: true,
      clearEditMode: true,
    );
  }

  bool saveEditingIfCurrent({
    required int sessionInstanceId,
    required String fenceId,
  }) {
    if (!_matchesEditingSession(
      sessionInstanceId: sessionInstanceId,
      fenceId: fenceId,
    )) {
      return false;
    }
    saveEditing();
    return true;
  }

  bool canSaveSession(FenceEditSession? session) {
    if (session == null || !session.hasChanges || _isSaving) {
      return false;
    }
    return validateDraftGeometry(session.points) == null;
  }

  static String? validateDraftGeometry(List<LatLng> points) {
    if (points.length < 3) {
      return '边界至少需要 3 个点';
    }
    for (var i = 0; i < points.length; i++) {
      final next = points[(i + 1) % points.length];
      if (points[i] == next) {
        return '边界不能有连续重复点';
      }
    }
    if (_polygonArea(points).abs() <= 1e-12) {
      return '边界面积必须大于 0';
    }
    if (_hasSelfIntersection(points)) {
      return '边界不能自交';
    }
    return null;
  }

  void _applySessionChange(FenceEditSession nextSession) {
    final currentSession = state.editSession;
    if (currentSession == null) return;
    if (_samePoints(currentSession.points, nextSession.points)) {
      if (currentSession.tool != nextSession.tool) {
        state = state.copyWith(editSession: nextSession);
      }
      return;
    }

    final withHistory = nextSession.copyWith(
      undoStack: [...currentSession.undoStack, currentSession.points],
      redoStack: const [],
    );
    state = state.copyWith(
      editSession: withHistory,
      editMode: withHistory.hasChanges
          ? FenceEditMode.editDirty
          : FenceEditMode.editIdle,
    );
  }

  bool _samePoints(List<LatLng> left, List<LatLng> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  bool _matchesEditingSession({
    required int sessionInstanceId,
    required String fenceId,
  }) {
    final session = state.editSession;
    return state.editMode == FenceEditMode.saving &&
        session != null &&
        session.fenceId == fenceId &&
        session.sessionInstanceId == sessionInstanceId;
  }

  bool get _isSaving => state.editMode == FenceEditMode.saving;

  static double _polygonArea(List<LatLng> points) {
    var doubleArea = 0.0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      doubleArea += (current.longitude * next.latitude) -
          (next.longitude * current.latitude);
    }
    return doubleArea / 2;
  }

  static bool _hasSelfIntersection(List<LatLng> points) {
    if (points.length < 4) {
      return false;
    }
    for (var i = 0; i < points.length; i++) {
      final a1 = points[i];
      final a2 = points[(i + 1) % points.length];
      for (var j = i + 1; j < points.length; j++) {
        if (_edgesShareVertex(i, j, points.length)) {
          continue;
        }
        final b1 = points[j];
        final b2 = points[(j + 1) % points.length];
        if (_segmentsIntersect(a1, a2, b1, b2)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _edgesShareVertex(int left, int right, int edgeCount) {
    final leftNext = (left + 1) % edgeCount;
    final rightNext = (right + 1) % edgeCount;
    return left == right ||
        left == rightNext ||
        leftNext == right ||
        leftNext == rightNext;
  }

  static bool _segmentsIntersect(
    LatLng a1,
    LatLng a2,
    LatLng b1,
    LatLng b2,
  ) {
    final o1 = _orientation(a1, a2, b1);
    final o2 = _orientation(a1, a2, b2);
    final o3 = _orientation(b1, b2, a1);
    final o4 = _orientation(b1, b2, a2);

    if (o1 != o2 && o3 != o4) {
      return true;
    }

    if (o1 == 0 && _isOnSegment(a1, b1, a2)) {
      return true;
    }
    if (o2 == 0 && _isOnSegment(a1, b2, a2)) {
      return true;
    }
    if (o3 == 0 && _isOnSegment(b1, a1, b2)) {
      return true;
    }
    if (o4 == 0 && _isOnSegment(b1, a2, b2)) {
      return true;
    }

    return false;
  }

  static int _orientation(LatLng p, LatLng q, LatLng r) {
    final cross = ((q.longitude - p.longitude) * (r.latitude - q.latitude)) -
        ((q.latitude - p.latitude) * (r.longitude - q.longitude));
    if (cross.abs() <= 1e-12) {
      return 0;
    }
    return cross > 0 ? 1 : 2;
  }

  static bool _isOnSegment(LatLng start, LatLng point, LatLng end) {
    return point.longitude <= _max(start.longitude, end.longitude) + 1e-12 &&
        point.longitude + 1e-12 >= _min(start.longitude, end.longitude) &&
        point.latitude <= _max(start.latitude, end.latitude) + 1e-12 &&
        point.latitude + 1e-12 >= _min(start.latitude, end.latitude);
  }

  static double _min(double left, double right) => left < right ? left : right;

  static double _max(double left, double right) => left > right ? left : right;
}

final fenceControllerProvider =
    NotifierProvider<FenceController, FenceState>(FenceController.new);
