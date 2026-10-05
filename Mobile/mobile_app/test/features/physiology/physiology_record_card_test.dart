// NIX-256 M7 row-level edit / delete entry points on the physiology
// record card: the actions exist on MANUAL rows only (DISPOSITION /
// ALERT_CONFIRM rows carry no actions — the backend answers 409), the
// edit sheet reopens prefilled with the type chip locked, and the delete
// path goes through a confirm dialog before touching the repository.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_repository.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/physiology_controller.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/widgets/physiology_record_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakePhysiologyRepository implements PhysiologyRepository {
  final List<int> updatedEventIds = [];
  final List<int> deletedEventIds = [];
  String? lastUpdateNote;

  @override
  Future<PhysiologyEventListResponse> listEvents(String livestockId) async {
    return PhysiologyEventListResponse(
      items: [
        PhysiologyEventItem(
          id: 31,
          livestockId: livestockId,
          eventType: PhysiologyEventType.illness,
          source: PhysiologySource.manual,
          note: 'observed at pen 3',
          // 03:00 UTC renders as the same calendar day in both UTC and
          // Asia/Shanghai test environments.
          occurredAt: DateTime.utc(2026, 10, 1, 3),
          active: false,
        ),
        PhysiologyEventItem(
          id: null,
          livestockId: livestockId,
          eventType: PhysiologyEventType.illness,
          source: PhysiologySource.disposition,
          refId: 88,
          occurredAt: DateTime.utc(2026, 9, 20, 3),
          active: true,
        ),
        PhysiologyEventItem(
          id: 33,
          livestockId: livestockId,
          eventType: PhysiologyEventType.recovery,
          source: PhysiologySource.alertConfirm,
          occurredAt: DateTime.utc(2026, 9, 18, 3),
          active: false,
        ),
      ],
    );
  }

  @override
  Future<PhysiologyEventItem> createEvent({
    required String livestockId,
    required PhysiologyEventType eventType,
    required DateTime occurredAt,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PhysiologyEventItem> updateEvent({
    required String livestockId,
    required int eventId,
    required DateTime occurredAt,
    String? note,
  }) async {
    updatedEventIds.add(eventId);
    lastUpdateNote = note;
    return PhysiologyEventItem(
      id: eventId,
      livestockId: livestockId,
      eventType: PhysiologyEventType.illness,
      source: PhysiologySource.manual,
      occurredAt: occurredAt,
      active: false,
    );
  }

  @override
  Future<void> deleteEvent({
    required String livestockId,
    required int eventId,
  }) async {
    deletedEventIds.add(eventId);
  }
}

Future<void> _pumpCard(WidgetTester tester, _FakePhysiologyRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        physiologyRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: 'farm-1',
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhysiologyRecordCard(livestockId: '12'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('edit / delete actions render on MANUAL rows only', (tester) async {
    final repo = _FakePhysiologyRepository();
    await _pumpCard(tester, repo);

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byKey(const Key('physiology-edit-31')), findsOneWidget);
    expect(find.byKey(const Key('physiology-delete-31')), findsOneWidget);

    // DISPOSITION projection (id null) and ALERT_CONFIRM row 33 carry no
    // actions — the backend rejects those with 409.
    expect(find.byIcon(Icons.edit), findsNWidgets(1));
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(1));
  });

  testWidgets('edit opens the sheet prefilled and saves via updateEvent',
      (tester) async {
    final repo = _FakePhysiologyRepository();
    await _pumpCard(tester, repo);

    await tester.tap(find.byKey(const Key('physiology-edit-31')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('physiology-edit-sheet-title')),
        findsOneWidget);

    // Note prefilled from the row.
    final noteField = tester.widget<TextField>(
      find.byKey(const Key('physiology-entry-note')),
    );
    expect(noteField.controller!.text, 'observed at pen 3');

    // Type chip is locked: tapping another chip is a no-op (updateEvent
    // carries no type — the type is immutable server-side).
    await tester.tap(
      find.byKey(const ValueKey('physiology-type-chip-calving')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('physiology-entry-save')));
    await tester.pumpAndSettle();

    expect(repo.updatedEventIds, [31]);
    expect(repo.lastUpdateNote, 'observed at pen 3');
    // sheet popped
    expect(
      find.byKey(const ValueKey('physiology-edit-sheet-title')),
      findsNothing,
    );
  });

  testWidgets('clearing the note sends an explicit empty string (N17)',
      (tester) async {
    final repo = _FakePhysiologyRepository();
    await _pumpCard(tester, repo);

    await tester.tap(find.byKey(const Key('physiology-edit-31')));
    await tester.pumpAndSettle();

    // Overwrite the prefilled note with empty content and save.
    await tester.enterText(find.byKey(const Key('physiology-entry-note')), '');
    await tester.tap(find.byKey(const Key('physiology-entry-save')));
    await tester.pumpAndSettle();

    // The sheet must pass the trimmed empty string through: the backend
    // contract (c836b14e) treats '' as "clear the note", so converting it
    // to null (omitted) anywhere on the way would silently keep the old
    // value.
    expect(repo.updatedEventIds, [31]);
    expect(repo.lastUpdateNote, '');
  });

  testWidgets('illness footnote is shown for the illness type only (n-h)',
      (tester) async {
    final repo = _FakePhysiologyRepository();
    await _pumpCard(tester, repo);

    // Create mode: the default type is pregnancy check — no hint.
    await tester.tap(find.byKey(const Key('physiology-add-record')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('physiology-illness-hint')), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey('physiology-type-chip-illness')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('physiology-illness-hint')), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('physiology-type-chip-calving')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('physiology-illness-hint')), findsNothing);
  });

  testWidgets('delete asks for confirmation before touching the repository',
      (tester) async {
    final repo = _FakePhysiologyRepository();
    await _pumpCard(tester, repo);

    await tester.tap(find.byKey(const Key('physiology-delete-31')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('physiology-delete-dialog-title')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('physiology-delete-dialog-message')),
        findsOneWidget);

    // Cancel path leaves the repository untouched.
    await tester.tap(find.byKey(const Key('physiology-delete-cancel')));
    await tester.pumpAndSettle();
    expect(repo.deletedEventIds, isEmpty);

    // Confirm path calls deleteEvent with the row id.
    await tester.tap(find.byKey(const Key('physiology-delete-31')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('physiology-delete-confirm')));
    await tester.pumpAndSettle();

    expect(repo.deletedEventIds, [31]);
    // dialog closed
    expect(
      find.byKey(const ValueKey('physiology-delete-dialog-title')),
      findsNothing,
    );
  });
}
