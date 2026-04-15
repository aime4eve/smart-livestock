import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_operations.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';

void main() {
  group('FenceEditOperations', () {
    test('insertVertex inserts point after the given edge start index', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
      );

      final updated = FenceEditOperations.insertVertex(
        session: session,
        edgeStartIndex: 0,
        point: const LatLng(10.5, 20.5),
      );

      expect(updated.points.length, 4);
      expect(updated.points[0], const LatLng(10, 20));
      expect(updated.points[1], const LatLng(10.5, 20.5));
      expect(updated.points[2], const LatLng(11, 21));
      expect(updated.points[3], const LatLng(12, 22));
    });

    test('insertVertex supports insertion on closing edge', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
      );

      final updated = FenceEditOperations.insertVertex(
        session: session,
        edgeStartIndex: 2,
        point: const LatLng(9.5, 19.5),
      );

      expect(updated.points.length, 4);
      expect(updated.points[0], const LatLng(10, 20));
      expect(updated.points[1], const LatLng(11, 21));
      expect(updated.points[2], const LatLng(12, 22));
      expect(updated.points[3], const LatLng(9.5, 19.5));
    });

    test('insertVertex throws RangeError for invalid index', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
      );

      expect(
        () => FenceEditOperations.insertVertex(
          session: session,
          edgeStartIndex: -1,
          point: const LatLng(10.5, 20.5),
        ),
        throwsRangeError,
      );
      expect(
        () => FenceEditOperations.insertVertex(
          session: session,
          edgeStartIndex: 3,
          point: const LatLng(10.5, 20.5),
        ),
        throwsRangeError,
      );
    });

    test('removeVertex removes point at the given index', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
          LatLng(13, 23),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
          LatLng(13, 23),
        ],
      );

      final updated = FenceEditOperations.removeVertex(
        session: session,
        vertexIndex: 1,
      );

      expect(updated.points.length, 3);
      expect(updated.points[0], const LatLng(10, 20));
      expect(updated.points[1], const LatLng(12, 22));
      expect(updated.points[2], const LatLng(13, 23));
    });

    test('removeVertex no-op when only three points', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
      );

      final updated = FenceEditOperations.removeVertex(
        session: session,
        vertexIndex: 1,
      );

      expect(updated.points, session.points);
      expect(updated.hasChanges, isFalse);
    });

    test('removeVertex throws RangeError for invalid index', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
          LatLng(13, 23),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
          LatLng(13, 23),
        ],
      );

      expect(
        () => FenceEditOperations.removeVertex(
          session: session,
          vertexIndex: -1,
        ),
        throwsRangeError,
      );
      expect(
        () => FenceEditOperations.removeVertex(
          session: session,
          vertexIndex: 4,
        ),
        throwsRangeError,
      );
    });

    test('translate translates all points by provided delta', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
        ],
      );

      final updated = FenceEditOperations.translate(
        session: session,
        latitudeDelta: 0.25,
        longitudeDelta: -0.5,
      );

      expect(updated.points.length, 2);
      expect(updated.points[0], const LatLng(10.25, 19.5));
      expect(updated.points[1], const LatLng(11.25, 20.5));
    });

    test('session keeps defensive immutable copies of input lists', () {
      final sourceOriginal = <LatLng>[
        const LatLng(10, 20),
        const LatLng(11, 21),
        const LatLng(12, 22),
      ];
      final sourcePoints = <LatLng>[
        const LatLng(10, 20),
        const LatLng(11, 21),
        const LatLng(12, 22),
      ];
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: sourceOriginal,
        points: sourcePoints,
      );

      sourceOriginal.add(const LatLng(13, 23));
      sourcePoints[0] = const LatLng(99, 99);

      expect(session.originalPoints.length, 3);
      expect(session.originalPoints[0], const LatLng(10, 20));
      expect(session.points[0], const LatLng(10, 20));
      expect(() => session.points.add(const LatLng(1, 1)), throwsUnsupportedError);
      expect(
        () => session.originalPoints.add(const LatLng(1, 1)),
        throwsUnsupportedError,
      );
    });

    test('session hasChanges reflects point edits', () {
      final session = FenceEditSession(
        fenceId: 'f-1',
        originalPoints: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
        points: const [
          LatLng(10, 20),
          LatLng(11, 21),
          LatLng(12, 22),
        ],
      );

      expect(session.hasChanges, isFalse);

      final translated = FenceEditOperations.translate(
        session: session,
        latitudeDelta: 0.1,
        longitudeDelta: 0.0,
      );

      expect(translated.hasChanges, isTrue);
    });
  });
}
