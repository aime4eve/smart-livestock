import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/fence/data/track_draft_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_desktop_panel.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_wizard_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'track_draft_controller_test.dart'
    show
        FakeTrackDraftRepository,
        linePoints,
        squarePoints,
        tinySquareWithInterior;

ProviderScope _scope(FakeTrackDraftRepository repo, Widget child) =>
    ProviderScope(
      overrides: [
        trackDraftRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: 'test-farm-1',
          ),
        ),
      ],
      child: child,
    );

Future<void> _pumpWizard(
  WidgetTester tester,
  FakeTrackDraftRepository repo, {
  void Function(TrackDraftCompletion)? onConfirmed,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _scope(
      repo,
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: TrackDraftWizardPage(onConfirmed: onConfirmed),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectDeviceAndAdvance(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('track-draft-device-row-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('track-draft-device-next')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('stale device row shows amber warning and 65% opacity',
      (tester) async {
    await _pumpWizard(tester, FakeTrackDraftRepository());

    final row = find.byKey(const Key('track-draft-device-row-2'));
    expect(row, findsOneWidget);
    // Still dimmed to 65% but tappable (spec §3.2).
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: row, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.65);
    // Amber bold ⚠ text inside the row.
    final staleText = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('⚠'),
      ),
    );
    expect(staleText, findsOneWidget);

    // The fresh row is not dimmed.
    final freshRow = find.byKey(const Key('track-draft-device-row-1'));
    final freshOpacity = tester.widget<Opacity>(
      find.ancestor(of: freshRow, matching: find.byType(Opacity)),
    );
    expect(freshOpacity.opacity, 1.0);
  });

  testWidgets('quota full disables the next button and shows the hint',
      (tester) async {
    await _pumpWizard(
      tester,
      FakeTrackDraftRepository(
        quota: const FenceQuota(current: 20, limit: 20),
      ),
    );
    await tester.tap(find.byKey(const Key('track-draft-device-row-1')));
    await tester.pumpAndSettle();

    final next = tester.widget<FilledButton>(
      find.byKey(const Key('track-draft-device-next')),
    );
    expect(next.onPressed, isNull);
    expect(find.byKey(const Key('track-draft-quota-hint')), findsOneWidget);
  });

  testWidgets('range over 30 days shows warning and disables generate',
      (tester) async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    await _pumpWizard(tester, repo);
    await _selectDeviceAndAdvance(tester);

    // Drive a 40-day custom range through the shared controller.
    final element = tester.element(
      find.byKey(const Key('track-draft-range-picker')),
    );
    final container = ProviderScope.containerOf(element);
    final controller = container.read(trackDraftControllerProvider.notifier);
    final now = DateTime.now();
    controller.setCustomRange(now.subtract(const Duration(days: 40)), now);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('track-draft-range-warning')), findsOneWidget);
    final generate = tester.widget<FilledButton>(
      find.byKey(const Key('track-draft-generate')),
    );
    expect(generate.onPressed, isNull);
  });

  testWidgets('full wizard flow: device → range → preview → confirm',
      (tester) async {
    TrackDraftCompletion? captured;
    final repo = FakeTrackDraftRepository(
      sourcePoints: squarePoints(),
      totalRaw: 16088,
    );
    await _pumpWizard(tester, repo, onConfirmed: (r) => captured = r);
    await _selectDeviceAndAdvance(tester);

    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('track-draft-preview-map')), findsOneWidget);
    expect(find.byKey(const Key('track-draft-stat-strip')), findsOneWidget);
    expect(find.byKey(const Key('track-draft-legend')), findsOneWidget);
    expect(find.byKey(const Key('track-draft-source-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('track-draft-confirm')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.vertices.length, greaterThanOrEqualTo(3));
    expect(captured!.metadata['method'], 'DEVICE_TRACK');
  });

  testWidgets('failure branch: noData', (tester) async {
    await _pumpWizard(tester, FakeTrackDraftRepository(sourcePoints: const []));
    await _selectDeviceAndAdvance(tester);
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const Key('track-draft-fail-title')),
    );
    expect(title.data, '该时间段无轨迹数据');
  });

  testWidgets('failure branch: tooFew', (tester) async {
    await _pumpWizard(
      tester,
      FakeTrackDraftRepository(sourcePoints: const [
        TrackPoint(lat: 28.2, lng: 112.9, accuracyMeters: 5),
        TrackPoint(lat: 28.21, lng: 112.9, accuracyMeters: 5),
      ]),
    );
    await _selectDeviceAndAdvance(tester);
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const Key('track-draft-fail-title')),
    );
    expect(title.data, '有效轨迹点不足（需 ≥3 个且面积 ≥25㎡）');
    // Cleaning-detail strip stays visible on failure (spec §3.5).
    expect(find.byKey(const Key('track-draft-stat-strip')), findsOneWidget);
  });

  testWidgets('failure branch: degenerate + only exit back to editing',
      (tester) async {
    await _pumpWizard(
      tester,
      FakeTrackDraftRepository(sourcePoints: linePoints()),
    );
    await _selectDeviceAndAdvance(tester);
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const Key('track-draft-fail-title')),
    );
    expect(title.data, '活动范围近似一条线，无法围合成围栏');

    await tester.tap(find.byKey(const Key('track-draft-fail-back')));
    await tester.pumpAndSettle();
    // Back on the range step with criteria retained.
    expect(find.byKey(const Key('track-draft-range-picker')), findsOneWidget);
  });

  testWidgets('wide layout renders the desktop panel with left 360px panel',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        FakeTrackDraftRepository(),
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: TrackDraftFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrackDraftDesktopPanel), findsOneWidget);
    expect(find.byKey(const Key('track-draft-generate')), findsOneWidget);
    expect(find.byKey(const Key('track-draft-preview-empty')), findsOneWidget);
  });

  testWidgets(
      'desktop panel shows the generation source card after a preview and '
      'hides it before one exists (review 中3, fidelity §8 ③)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        FakeTrackDraftRepository(sourcePoints: squarePoints()),
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: TrackDraftFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Hidden while no successful preview exists.
    expect(
      find.byKey(const Key('track-draft-desktop-source-card')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('track-draft-device-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    // Shown once the preview lands, in the left panel next to the map.
    expect(find.byKey(const Key('track-draft-preview-map')), findsOneWidget);
    expect(
      find.byKey(const Key('track-draft-desktop-source-card')),
      findsOneWidget,
    );
    // Title carries the "saved with the fence" note and the card lists the
    // device (device row renders the same name, so match within the card).
    expect(find.text('生成来源（将随围栏保存）'), findsOneWidget);
    final card = find.byKey(const Key('track-draft-desktop-source-card'));
    expect(
      find.descendant(of: card, matching: find.text('Tracker A-012')),
      findsOneWidget,
    );
  });

  testWidgets('narrow layout renders the mobile wizard', (tester) async {
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        FakeTrackDraftRepository(),
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: TrackDraftFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrackDraftWizardPage), findsOneWidget);
    expect(find.byKey(const Key('track-draft-device-next')), findsOneWidget);
  });

  testWidgets(
      'hull switcher chips render selected/unselected states and the stat '
      'strip method cell follows the switch (spec 修订 v2.1)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _scope(
        FakeTrackDraftRepository(sourcePoints: squarePoints()),
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: TrackDraftFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('track-draft-device-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    BoxDecoration chipDecoration(String key) => tester
        .widget<Container>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Container),
          ),
        )
        .decoration! as BoxDecoration;
    Color chipBg(String key) => chipDecoration(key).color!;

    // Default selection: 凹包·简化 solid primary; the other two unselected.
    expect(chipBg('track-draft-hull-concave-simplified'), AppColors.primary);
    expect(chipBg('track-draft-hull-concave'), AppColors.surfaceAlt);
    expect(chipBg('track-draft-hull-convex'), AppColors.surfaceAlt);
    // Chip label + the 5th stat-strip cell show the selected algorithm.
    expect(find.text('凹包·简化'), findsNWidgets(2));
    expect(find.text('凹包·精细'), findsOneWidget);

    await tester.tap(find.byKey(const Key('track-draft-hull-convex')));
    await tester.pumpAndSettle();

    // Selection moved; the stat strip method cell follows (chip + cell).
    expect(chipBg('track-draft-hull-convex'), AppColors.primary);
    expect(chipBg('track-draft-hull-concave-simplified'), AppColors.surfaceAlt);
    expect(find.text('凸包'), findsNWidgets(2));
    expect(find.text('凹包·简化'), findsOneWidget); // chip only now

    final element = tester.element(find.byKey(const Key('track-draft-hull-convex')));
    final state = ProviderScope.containerOf(element)
        .read(trackDraftControllerProvider);
    expect(state.selectedHullMethod, HullMethod.convex);
    expect(state.preview!.envelope.method, HullMethod.convex);
    expect(state.previewStale, isFalse);
  });

  testWidgets(
      'unavailable hull chips are greyed out and reject selection '
      '(spec 修订 v2.1)', (tester) async {
    await _pumpWizard(
      tester,
      FakeTrackDraftRepository(sourcePoints: tinySquareWithInterior()),
    );
    await _selectDeviceAndAdvance(tester);
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();

    BoxDecoration chipDecoration(String key) => tester
        .widget<Container>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Container),
          ),
        )
        .decoration! as BoxDecoration;
    Color chipBg(String key) => chipDecoration(key).color!;

    // Concave dips below the area floor → disabled (border bg); grid
    // thinning rescues the simplified candidate (default selection landed
    // on it), convex stays available.
    expect(chipBg('track-draft-hull-concave'), AppColors.border);
    expect(chipBg('track-draft-hull-concave-simplified'), AppColors.primary);
    expect(chipBg('track-draft-hull-convex'), isNot(AppColors.primary));

    await tester.tap(find.byKey(const Key('track-draft-hull-concave')));
    await tester.pumpAndSettle();

    // Rejected: selection stays on the simplified default.
    expect(chipBg('track-draft-hull-concave-simplified'), AppColors.primary);
    expect(chipBg('track-draft-hull-concave'), AppColors.border);
  });

  testWidgets(
      'advanced params section collapses by default and expands with three '
      'sliders + restore (spec §5.7)', (tester) async {
    await _pumpWizard(tester, FakeTrackDraftRepository());
    await _selectDeviceAndAdvance(tester);

    // Collapsed by default: only the header row exists.
    expect(
      find.byKey(const Key('track-draft-advanced-toggle')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('track-draft-slider-roaming')), findsNothing);
    expect(find.byKey(const Key('track-draft-slider-cluster')), findsNothing);
    expect(find.byKey(const Key('track-draft-slider-area')), findsNothing);
    expect(find.byKey(const Key('track-draft-params-restore')), findsNothing);

    await tester.tap(find.byKey(const Key('track-draft-advanced-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('track-draft-slider-roaming')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('track-draft-slider-cluster')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('track-draft-slider-area')), findsOneWidget);
    expect(
      find.byKey(const Key('track-draft-params-restore')),
      findsOneWidget,
    );
    // Defaults render as slider value labels; the note is present.
    expect(find.text('5%'), findsOneWidget);
    expect(find.text('30 米'), findsOneWidget);
    expect(find.text('0.5%'), findsOneWidget);
    expect(find.text('以上参数作用于凹包类候选；凸包不受影响'), findsOneWidget);

    // Collapse again hides the sliders (local UI fold state only).
    await tester.tap(find.byKey(const Key('track-draft-advanced-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('track-draft-slider-roaming')), findsNothing);
  });

  testWidgets(
      'dragging a slider pushes params to the controller and marks the '
      'preview stale; restore returns to the defaults', (tester) async {
    final repo = FakeTrackDraftRepository(sourcePoints: squarePoints());
    await _pumpWizard(tester, repo);
    await _selectDeviceAndAdvance(tester);

    // Produce a preview first, then return to editing so the advanced
    // section can stale an existing preview (spec §5.4).
    final element = tester.element(
      find.byKey(const Key('track-draft-range-picker')),
    );
    final container = ProviderScope.containerOf(element);
    final controller = container.read(trackDraftControllerProvider.notifier);
    await controller.generate();
    controller.backToEditing();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('track-draft-advanced-toggle')));
    await tester.pumpAndSettle();

    final quantileBefore =
        container.read(trackDraftControllerProvider).params.roamingQuantile;
    await tester.ensureVisible(
      find.byKey(const Key('track-draft-slider-roaming')),
    );
    await tester.drag(
      find.byKey(const Key('track-draft-slider-roaming')),
      const Offset(180, 0),
    );
    await tester.pumpAndSettle();

    final paramsAfter = container.read(trackDraftControllerProvider).params;
    expect(paramsAfter.roamingQuantile, isNot(quantileBefore));
    expect(container.read(trackDraftControllerProvider).previewStale, isTrue);
    // The dragged-away default label is gone.
    expect(find.text('5%'), findsNothing);

    // Restore (same intent path as the controller test) rewrites the
    // defaults and keeps the preview stale — a criteria change either way.
    await tester.ensureVisible(
      find.byKey(const Key('track-draft-params-restore')),
    );
    await tester.tap(find.byKey(const Key('track-draft-params-restore')));
    await tester.pumpAndSettle();

    final restored = container.read(trackDraftControllerProvider);
    expect(restored.params.roamingQuantile, quantileBefore);
    expect(restored.previewStale, isTrue);
    expect(find.text('5%'), findsOneWidget);
  });
}
