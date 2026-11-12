import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/fence/data/track_draft_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_analytics.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';

/// Fake repository with controllable candidates/source responses.
class FakeTrackDraftRepository implements TrackDraftRepository {
  FakeTrackDraftRepository({
    List<TrackDraftDeviceCandidate>? devices,
    FenceQuota quota = const FenceQuota(current: 3, limit: 20),
    this.sourcePoints = const [],
    this.totalRaw = 0,
  })  : candidatesResult = TrackDraftCandidates(
          devices: devices ?? _defaultDevices,
          fenceQuota: quota,
        );

  static final _defaultDevices = [
    TrackDraftDeviceCandidate(
      deviceId: 1,
      name: 'Tracker A-012',
      earTag: 'N0342',
      lastFixAt: DateTime.now().subtract(const Duration(minutes: 2)),
      pointCount: 7986,
    ),
    TrackDraftDeviceCandidate(
      deviceId: 2,
      name: 'Tracker A-013',
      earTag: 'N0355',
      lastFixAt: DateTime.now().subtract(const Duration(days: 3)),
      pointCount: 2130,
    ),
  ];

  TrackDraftCandidates candidatesResult;
  List<TrackPoint> sourcePoints;
  int totalRaw;
  Completer<TrackDraftSourceResult>? sourceGate;

  @override
  Future<TrackDraftCandidates> candidates({int days = 30}) async =>
      candidatesResult;

  @override
  Future<TrackDraftSourceResult> source({
    required List<int> deviceIds,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final gate = sourceGate;
    if (gate != null) return gate.future;
    return Future.value(TrackDraftSourceResult(
      points: sourcePoints,
      totalRaw: totalRaw == 0 ? sourcePoints.length : totalRaw,
      truncated: false,
      sampledStride: 1,
    ));
  }
}

/// 8 points forming a ~100m square → successful envelope.
List<TrackPoint> squarePoints() {
  const lat = 28.2;
  const lng = 112.9;
  const d = 0.001; // ≈100m
  return [
    const TrackPoint(lat: lat, lng: lng, accuracyMeters: 5),
    const TrackPoint(lat: lat, lng: lng + d / 2, accuracyMeters: 5),
    const TrackPoint(lat: lat, lng: lng + d, accuracyMeters: 5),
    const TrackPoint(lat: lat + d / 2, lng: lng + d, accuracyMeters: 5),
    const TrackPoint(lat: lat + d, lng: lng + d, accuracyMeters: 5),
    const TrackPoint(lat: lat + d, lng: lng + d / 2, accuracyMeters: 5),
    const TrackPoint(lat: lat + d, lng: lng, accuracyMeters: 5),
    const TrackPoint(lat: lat + d / 2, lng: lng, accuracyMeters: 5),
  ];
}

/// 6 nearly collinear points → degenerate envelope (area ≈ 0).
List<TrackPoint> linePoints() => [
      for (var i = 0; i < 6; i++)
        TrackPoint(lat: 28.2 + i * 0.00001, lng: 112.9, accuracyMeters: 5),
    ];

/// Chamfered ~7.2m square (dense boundary sampling) + a deep interior
/// point stack (spec 修订 v2.1 mixed availability). Robust under the
/// animalTrack bundle (95% roaming trim drops ~3 boundary samples; the
/// octagon hull ≈50㎡ passes the degenerate gate, the tightened ring
/// collapses to ≈23㎡ < 25㎡ → concave/concaveSimplified unavailable,
/// convex stays available). Deterministic — no RNG.
List<TrackPoint> tinySquareWithInterior() {
  const s = 7.2; // square side
  const c = 0.64; // corner chamfer
  const step = 0.592;
  const n = 10; // points per edge: (s - 2c) / step
  TrackPoint at(double x, double y) => TrackPoint(
        lat: 28.2 + y / 111320.0,
        lng: 112.9 + x / (111320.0 * 0.8813),
        accuracyMeters: 5,
      );
  final pts = <TrackPoint>[];
  for (var k = 0; k <= n; k++) {
    pts.add(at(c + step * k, 0)); // bottom edge (0.64,0)→(6.56,0)
  }
  pts.add(at(s, c)); // bottom-right chamfer apex
  for (var k = 1; k <= n; k++) {
    pts.add(at(s, c + step * k)); // right edge
  }
  pts.add(at(s - c, s)); // top-right chamfer apex
  for (var k = 1; k <= n; k++) {
    pts.add(at(s - c - step * k, s)); // top edge
  }
  pts.add(at(0, s - c)); // top-left chamfer apex
  for (var k = 1; k <= n; k++) {
    pts.add(at(0, s - c - step * k)); // left edge
  }
  // Deep interior stack: pulls the tightened ring below the 25㎡ floor.
  pts
    ..add(at(3.6, 3.6))
    ..add(at(3.6, 2.2))
    ..add(at(3.6, 1.2))
    ..add(at(3.6, 0.45));
  return pts;
}

void main() {
  Future<ProviderContainer> setup(
    FakeTrackDraftRepository repo, {
    InMemoryFenceAnalyticsSink? analytics,
  }) async {
    final container = ProviderContainer(
      overrides: [
        trackDraftRepositoryProvider.overrideWithValue(repo),
        if (analytics != null)
          fenceAnalyticsSinkProvider.overrideWithValue(analytics),
        // Mandatory: farm-scoped controllers need a valid activeFarmId.
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: 'test-farm-1',
          ),
        ),
      ],
    );
    container.read(trackDraftControllerProvider);
    // Let build()'s candidates microtask complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return container;
  }

  Future<void> toPreviewing(ProviderContainer container) async {
    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();
  }

  test('initial: editing + candidates + default 14d quick range', () async {
    final container = await setup(FakeTrackDraftRepository());
    addTearDown(container.dispose);

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.editing);
    expect(state.candidates.length, 2);
    expect(state.fenceQuota!.current, 3);
    expect(state.quickDays, 14);
    expect(state.hasRange, isTrue);
  });

  test('editing → loading → previewing with preview payload', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);

    await toPreviewing(container);

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.previewing);
    expect(state.preview, isNotNull);
    expect(state.preview!.envelope.isSuccess, isTrue);
    expect(state.preview!.envelope.vertexCount, greaterThanOrEqualTo(3));
    expect(state.previewStale, isFalse);
    expect(state.preview!.areaM2, greaterThan(25));
  });

  test('parameter changes mark an existing preview stale', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    await toPreviewing(container);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(2);
    expect(container.read(trackDraftControllerProvider).previewStale, isTrue);

    // Regenerate clears the stale flag.
    await controller.generate();
    expect(container.read(trackDraftControllerProvider).previewStale, isFalse);

    controller.setQuickRange(7);
    expect(container.read(trackDraftControllerProvider).previewStale, isTrue);
  });

  test('loading retains the previous preview until the new one lands',
      () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    await toPreviewing(container);
    final oldPreview = container.read(trackDraftControllerProvider).preview;

    final controller = container.read(trackDraftControllerProvider.notifier);
    repo.sourceGate = Completer<TrackDraftSourceResult>();
    final pending = controller.generate();

    // Loading state with the old preview still attached (spec §5.4).
    var state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.loading);
    expect(identical(state.preview, oldPreview), isTrue);

    repo.sourceGate!.complete(TrackDraftSourceResult(
      points: squarePoints(),
      totalRaw: 8,
      truncated: false,
      sampledStride: 1,
    ));
    await pending;
    state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.previewing);
    expect(identical(state.preview, oldPreview), isFalse);
  });

  test('failed(noData) when the source returns zero points', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: const []);
    final container = await setup(repo);
    addTearDown(container.dispose);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.failed);
    expect(state.failReason, TrackDraftFailReason.noData);
  });

  test('failed(tooFew) when fewer than 3 valid points remain', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: [
      const TrackPoint(lat: 28.2, lng: 112.9, accuracyMeters: 5),
      const TrackPoint(lat: 28.21, lng: 112.9, accuracyMeters: 5),
    ]);
    final container = await setup(repo);
    addTearDown(container.dispose);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.failed);
    expect(state.failReason, TrackDraftFailReason.tooFew);
    // Cleaning diagnostics ride along for the failure stat strip.
    expect(state.preview!.envelope.remainingValid, 2);
  });

  test('failed(degenerate) for a nearly collinear track', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: linePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.failed);
    expect(state.failReason, TrackDraftFailReason.degenerate);
  });

  test('failed → editing is the only inbound edge and keeps the criteria',
      () async {
    final repo = FakeTrackDraftRepository(sourcePoints: const []);
    final container = await setup(repo);
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);

    controller.toggleDevice(1);
    controller.setQuickRange(7);
    await controller.generate();
    expect(
        container.read(trackDraftControllerProvider).phase,
        TrackDraftPhase.failed);

    controller.backToEditing();
    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.editing);
    expect(state.selectedDeviceIds, [1]);
    expect(state.quickDays, 7);
    expect(state.failReason, isNull);

    // backToEditing from editing is a no-op (no other inbound edge).
    controller.backToEditing();
    expect(container.read(trackDraftControllerProvider).phase,
        TrackDraftPhase.editing);
  });

  test('previewing → editing (调整条件) keeps devices and range', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    await toPreviewing(container);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.backToEditing();
    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.editing);
    expect(state.selectedDeviceIds, [1]);
    expect(state.quickDays, 14);
  });

  test('quota full blocks device-step proceed and generate', () async {
    final repo = FakeTrackDraftRepository(
      quota: const FenceQuota(current: 20, limit: 20),
    );
    final container = await setup(repo);
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);

    controller.toggleDevice(1);
    expect(container.read(trackDraftControllerProvider).quotaFull, isTrue);
    expect(controller.canProceedFromDevices, isFalse);
    expect(container.read(trackDraftControllerProvider).canGenerate, isFalse);

    await controller.generate();
    expect(container.read(trackDraftControllerProvider).phase,
        TrackDraftPhase.editing);
  });

  test('unlimited quota (limit null) never blocks', () async {
    final repo = FakeTrackDraftRepository(
      quota: const FenceQuota(current: 999),
    );
    final container = await setup(repo);
    addTearDown(container.dispose);

    expect(container.read(trackDraftControllerProvider).quotaFull, isFalse);
  });

  test('range over 30 days blocks generate', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);

    controller.toggleDevice(1);
    final now = DateTime.now();
    controller.setCustomRange(
      now.subtract(const Duration(days: 40)),
      now,
    );
    final state = container.read(trackDraftControllerProvider);
    expect(state.rangeTooLong, isTrue);
    expect(state.canGenerate, isFalse);
    await controller.generate();
    expect(container.read(trackDraftControllerProvider).phase,
        TrackDraftPhase.editing);
  });

  test('buildCompletion emits vertices + generation metadata', () async {
    final repo = FakeTrackDraftRepository(
      sourcePoints: squarePoints(),
      totalRaw: 16088,
    );
    final container = await setup(repo);
    addTearDown(container.dispose);
    await toPreviewing(container);

    final controller = container.read(trackDraftControllerProvider.notifier);
    final result = controller.buildCompletion();
    expect(result, isNotNull);
    expect(result!.vertices.length, greaterThanOrEqualTo(3));
    final meta = result.metadata;
    expect(meta['method'], 'DEVICE_TRACK');
    expect(meta['deviceIds'], [1]);
    expect(meta['rawPointCount'], 16088);
    expect(meta['usedPoints'], isA<int>());
    expect(meta['outlierTrimmed'], isA<int>());
    // Default selection is the simplified hull (spec 修订 v2.1); switching
    // candidates below also flips this key through the controller.
    expect(
        ['concave', 'convex', 'concave_simplified'],
        contains(meta['hullMethod']));
    expect(meta['startTime'], isA<String>());
    expect(meta['endTime'], isA<String>());
  });

  test('buildCompletion is null before a successful preview', () async {
    final container = await setup(FakeTrackDraftRepository());
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);
    expect(controller.buildCompletion(), isNull);
  });

  test('generate success emits trackDraftGenerateSuccess with counts (低2)',
      () async {
    final sink = InMemoryFenceAnalyticsSink();
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo, analytics: sink);
    addTearDown(container.dispose);

    await toPreviewing(container);

    final gen = sink.events.singleWhere(
      (e) => e.name == FenceAnalyticsEventName.trackDraftGenerateSuccess,
    );
    expect(gen.parameters?[FenceAnalyticsParamKey.deviceCount], 1);
    expect(
      gen.parameters?[FenceAnalyticsParamKey.pointCount],
      greaterThan(0),
    );
  });

  test('failed generate emits no trackDraftGenerateSuccess (低2)', () async {
    final sink = InMemoryFenceAnalyticsSink();
    final container = await setup(
      FakeTrackDraftRepository(sourcePoints: const []),
      analytics: sink,
    );
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();

    expect(
      sink.events.where(
        (e) => e.name == FenceAnalyticsEventName.trackDraftGenerateSuccess,
      ),
      isEmpty,
    );
  });

  test('farm switch mid-generation drops the stale result (低1)', () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);

    repo.sourceGate = Completer<TrackDraftSourceResult>();
    final pending = controller.generate();
    expect(
      container.read(trackDraftControllerProvider).phase,
      TrackDraftPhase.loading,
    );

    // Switch farms while the fetch is in flight: the farm-scoped provider
    // rebuilds into a fresh editing state.
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() => ApiClient.instance.setActiveFarmId(null));
    container.read(sessionControllerProvider.notifier).updateActiveFarm(
          'test-farm-2',
        );
    expect(
      container.read(trackDraftControllerProvider).phase,
      TrackDraftPhase.editing,
    );

    repo.sourceGate!.complete(TrackDraftSourceResult(
      points: squarePoints(),
      totalRaw: 8,
      truncated: false,
      sampledStride: 1,
    ));
    await pending;

    // The stale continuation must not pollute the rebuilt state.
    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.editing);
    expect(state.preview, isNull);
  });

  test('generate populates three hull candidates, default 凹包·简化 (v2.1)',
      () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);

    await toPreviewing(container);

    final state = container.read(trackDraftControllerProvider);
    expect(
      state.hullCandidates.map((c) => c.method).toList(),
      [HullMethod.concaveSimplified, HullMethod.concave, HullMethod.convex],
    );
    // Default selection: first available candidate in priority order.
    expect(state.selectedHullMethod, HullMethod.concaveSimplified);
    expect(state.preview!.envelope.method, HullMethod.concaveSimplified);
    expect(state.previewStale, isFalse);
  });

  test('selectHullMethod swaps the preview in place; stale untouched (v2.1)',
      () async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);
    await toPreviewing(container);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.selectHullMethod(HullMethod.convex);

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.previewing);
    expect(state.selectedHullMethod, HullMethod.convex);
    expect(state.preview!.envelope.method, HullMethod.convex);
    expect(state.preview!.envelope.vertexCount, greaterThanOrEqualTo(3));
    expect(state.previewStale, isFalse);

    // The persisted metadata key follows the selection through the
    // controller (UI never assembles hullMethod itself).
    final completion = controller.buildCompletion();
    expect(completion!.metadata['hullMethod'], 'convex');

    // Selecting the already-selected method is a no-op.
    final before = state.preview;
    controller.selectHullMethod(HullMethod.convex);
    expect(
        identical(
            container.read(trackDraftControllerProvider).preview, before),
        isTrue);
  });

  test('unavailable hull candidates cannot be selected (v2.1)', () async {
    final repo =
        FakeTrackDraftRepository(sourcePoints: tinySquareWithInterior());
    final container = await setup(repo);
    addTearDown(container.dispose);

    await toPreviewing(container);

    final state = container.read(trackDraftControllerProvider);
    // Mixed availability: grid thinning rescues the simplified candidate on
    // this tiny shape (clean corner resample ≥ area floor), the detailed
    // concave still dips below it, convex survives. (Updated 2026-11-12:
    // clusterCellM=30 landed — see envelope_candidates_test dense-cluster.)
    expect(state.hullCandidates[0].isAvailable, isTrue);
    expect(state.hullCandidates[1].isAvailable, isFalse);
    expect(state.hullCandidates[2].isAvailable, isTrue);
    // Default selection is the first available (concaveSimplified).
    expect(state.selectedHullMethod, HullMethod.concaveSimplified);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.selectHullMethod(HullMethod.concave);
    final after = container.read(trackDraftControllerProvider);
    expect(after.selectedHullMethod, HullMethod.concaveSimplified);
    expect(after.preview!.envelope.method, HullMethod.concaveSimplified);
  });

  test('all candidates failed → failed(degenerate) with cleaning stats',
      () async {
    final repo = FakeTrackDraftRepository(sourcePoints: linePoints());
    final container = await setup(repo);
    addTearDown(container.dispose);

    final controller = container.read(trackDraftControllerProvider.notifier);
    controller.toggleDevice(1);
    await controller.generate();

    final state = container.read(trackDraftControllerProvider);
    expect(state.phase, TrackDraftPhase.failed);
    expect(state.failReason, TrackDraftFailReason.degenerate);
    for (final c in state.hullCandidates) {
      expect(c.isAvailable, isFalse);
    }
    // Failure-strip diagnostics ride on the shared candidate result.
    expect(state.preview!.envelope.failure, EnvelopeFailure.degenerate);
    expect(state.preview!.envelope.rawCount, linePoints().length);
  });
}
