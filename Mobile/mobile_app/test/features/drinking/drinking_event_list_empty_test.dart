import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_event_list.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Regression pin for the integration-testing finding (2026-10-06): the
/// manual back-fill entry must stay reachable in the EMPTY state — a day
/// with zero detected events is exactly when a missed bout needs
/// back-filling. Write roles see the button next to the empty copy;
/// non-write roles see neither.
class _EmptyRepo implements DrinkingRepository {
  @override
  Future<List<DrinkingEvent>> listEvents(String livestockId,
      {String? from, String? to}) async {
    return const [];
  }

  @override
  Future<DrinkingSummary> summary(String livestockId,
      {String? date, required int days}) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkingEvent> updateLabel(
      {required String livestockId, required int eventId, required DrinkingLabel label}) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkingEvent> createManual(
      {required String livestockId, required String eventStartAt, String? note}) {
    throw UnimplementedError();
  }
}

Widget _harness(UserRole role) {
  return ProviderScope(
    overrides: [
      drinkingRepositoryProvider.overrideWithValue(_EmptyRepo()),
      initialSessionProvider.overrideWithValue(
        AppSession.authenticated(
          role: role,
          accessToken: 'token',
          activeFarmId: 'farm-1',
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: SingleChildScrollView(
          child: DrinkingEventList(livestockId: '4', events: []),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('empty state keeps the manual back-fill entry for writers',
      (tester) async {
    await tester.pumpWidget(_harness(UserRole.owner));
    await tester.pumpAndSettle();

    expect(find.textContaining('今日未检出饮水事件'), findsOneWidget);
    expect(find.byKey(const Key('drinking-add-manual')), findsOneWidget);
  });

  testWidgets('empty state hides the entry for non-write roles',
      (tester) async {
    await tester.pumpWidget(_harness(UserRole.platformAdmin));
    await tester.pumpAndSettle();

    expect(find.textContaining('今日未检出饮水事件'), findsOneWidget);
    expect(find.byKey(const Key('drinking-add-manual')), findsNothing);
  });
}
