import 'package:latlong2/latlong.dart';

enum FenceEditTool { moveVertex, insertVertex, deleteVertex, translate }

class FenceEditSession {
  factory FenceEditSession({
    required String fenceId,
    required List<LatLng> originalPoints,
    required List<LatLng> points,
    int sessionInstanceId = 0,
    FenceEditTool tool = FenceEditTool.moveVertex,
    List<List<LatLng>> undoStack = const [],
    List<List<LatLng>> redoStack = const [],
  }) {
    return FenceEditSession._(
      fenceId: fenceId,
      originalPoints: List<LatLng>.unmodifiable(originalPoints),
      points: List<LatLng>.unmodifiable(points),
      sessionInstanceId: sessionInstanceId,
      tool: tool,
      undoStack: _freezePointStack(undoStack),
      redoStack: _freezePointStack(redoStack),
    );
  }

  const FenceEditSession._({
    required this.fenceId,
    required this.originalPoints,
    required this.points,
    required this.sessionInstanceId,
    required this.tool,
    required this.undoStack,
    required this.redoStack,
  });

  final String fenceId;
  final List<LatLng> originalPoints;
  final List<LatLng> points;
  final int sessionInstanceId;
  final FenceEditTool tool;
  final List<List<LatLng>> undoStack;
  final List<List<LatLng>> redoStack;

  bool get hasChanges => !_samePoints(originalPoints, points);
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  FenceEditSession copyWith({
    String? fenceId,
    List<LatLng>? originalPoints,
    List<LatLng>? points,
    int? sessionInstanceId,
    FenceEditTool? tool,
    List<List<LatLng>>? undoStack,
    List<List<LatLng>>? redoStack,
  }) {
    return FenceEditSession(
      fenceId: fenceId ?? this.fenceId,
      originalPoints: originalPoints ?? this.originalPoints,
      points: points ?? this.points,
      sessionInstanceId: sessionInstanceId ?? this.sessionInstanceId,
      tool: tool ?? this.tool,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  static bool _samePoints(List<LatLng> left, List<LatLng> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static List<List<LatLng>> _freezePointStack(List<List<LatLng>> stack) {
    return List<List<LatLng>>.unmodifiable([
      for (final points in stack) List<LatLng>.unmodifiable(points),
    ]);
  }
}
