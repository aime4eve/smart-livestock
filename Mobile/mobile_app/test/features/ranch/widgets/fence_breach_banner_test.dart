import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_breach_banner.dart';

void main() {
  group('FenceBreachBanner', () {
    testWidgets('renders breach and approach counts when alerts exist',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: FenceBreachBanner(
            breachCount: 2,
            approachCount: 1,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('越界 2 头'), findsOneWidget);
      expect(find.text('接近 1 头'), findsOneWidget);
    });

    testWidgets('renders nothing when both counts are zero', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: FenceBreachBanner(
            breachCount: 0,
            approachCount: 0,
            onTap: () {},
          ),
        ),
      ));
      expect(find.byKey(const Key('ranch-fence-breach-banner')), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: FenceBreachBanner(
            breachCount: 3,
            approachCount: 0,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('ranch-fence-breach-banner')));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
