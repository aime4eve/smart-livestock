import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/subscription_health_banner.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-324 fidelity D2: banner severity colours must follow the spec §2
/// matrix — RENEWAL_FAILED/SUSPENDED warn orange, EXPIRING_SOON escalating
/// 14 info → 7 warn → 3 danger, TRIAL escalating via level when ≤14 days,
/// CANCELLED/EXPIRED danger red. Healthy renders nothing.
void main() {
  Widget harness(SubscriptionHealth health) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionHealthBanner(
            health: health,
            onRenew: () {},
          ),
        ),
      );

  const info = Color(0xFFE2EDF4);
  const warn = Color(0xFFF7EDDD);
  const danger = Color(0xFFF7E5E2);

  SubscriptionHealth h(String status, {int? level}) => SubscriptionHealth(
        healthStatus: status,
        level: level,
        trialActive: false,
        effectiveTier: 'premium',
        daysToExpiry: 5,
        degraded: false,
        terminatedAt: null,
        exportWindow: null,
      );

  Color? backgroundOf(WidgetTester tester) {
    final finder = find.byKey(const Key('subscription-health-banner'));
    expect(finder, findsOneWidget);
    final container = tester.widget<Container>(finder);
    return (container.decoration as BoxDecoration?)?.color;
  }

  testWidgets('spec §2 severity matrix colours', (tester) async {
    final cases = <(String, int?, Color)>[
      ('RENEWAL_FAILED', null, warn),
      ('SUSPENDED', null, warn),
      ('EXPIRING_SOON', 14, info),
      ('EXPIRING_SOON', 7, warn),
      ('EXPIRING_SOON', 3, danger),
      ('TRIAL', null, info),
      ('TRIAL', 3, danger),
      ('CANCELLED', null, danger),
      ('EXPIRED', null, danger),
    ];
    for (final (status, level, expected) in cases) {
      await tester.pumpWidget(harness(h(status, level: level)));
      expect(backgroundOf(tester), expected,
          reason: '$status level=$level should render $expected');
    }
  });

  testWidgets('healthy renders no banner', (tester) async {
    await tester.pumpWidget(harness(h('HEALTHY')));
    expect(find.byKey(const Key('subscription-health-banner')), findsNothing);
  });

  testWidgets('suspended has no primary CTA; expired has renew CTA',
      (tester) async {
    await tester.pumpWidget(harness(h('SUSPENDED')));
    expect(find.byKey(const Key('subscription-health-banner-cta')),
        findsNothing);
    await tester.pumpWidget(harness(h('EXPIRED')));
    expect(find.byKey(const Key('subscription-health-banner-cta')),
        findsOneWidget);
  });
}
