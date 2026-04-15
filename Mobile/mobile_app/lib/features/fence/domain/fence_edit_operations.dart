import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';

class FenceEditOperations {
  const FenceEditOperations._();

  static FenceEditSession moveVertex({
    required FenceEditSession session,
    required int vertexIndex,
    required LatLng point,
  }) {
    RangeError.checkValidIndex(vertexIndex, session.points, 'vertexIndex');
    final nextPoints = [...session.points];
    nextPoints[vertexIndex] = point;
    return session.copyWith(points: nextPoints);
  }

  static FenceEditSession insertVertex({
    required FenceEditSession session,
    required int edgeStartIndex,
    required LatLng point,
  }) {
    RangeError.checkValidIndex(edgeStartIndex, session.points, 'edgeStartIndex');
    final nextPoints = [...session.points];
    final insertIndex = edgeStartIndex == session.points.length - 1
        ? nextPoints.length
        : edgeStartIndex + 1;
    nextPoints.insert(insertIndex, point);
    return session.copyWith(points: nextPoints);
  }

  static FenceEditSession removeVertex({
    required FenceEditSession session,
    required int vertexIndex,
  }) {
    RangeError.checkValidIndex(vertexIndex, session.points, 'vertexIndex');
    if (session.points.length <= 3) return session;
    final nextPoints = [...session.points]..removeAt(vertexIndex);
    return session.copyWith(points: nextPoints);
  }

  static FenceEditSession translate({
    required FenceEditSession session,
    required double latitudeDelta,
    required double longitudeDelta,
  }) {
    final nextPoints = session.points
        .map(
          (point) => LatLng(
            point.latitude + latitudeDelta,
            point.longitude + longitudeDelta,
          ),
        )
        .toList();
    return session.copyWith(points: nextPoints);
  }
}
