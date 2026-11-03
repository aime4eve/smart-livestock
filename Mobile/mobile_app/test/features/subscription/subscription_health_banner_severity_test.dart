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
  Widget harness(SubscriptionHealth health, {bool snooze = false}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubscriptionHealthBanner(
            health: health,
            onRenew: () {},
            onSnooze: snooze ? () {} : null,
          ),
        ),
      );

  const info = Color(0xFFE2EDF4);
  const warn = Color(0xFFF7EDDD);
  const danger = Color(0xFFF7E5E2);

  SubscriptionHealth h(String status,
          {int? level,
          bool snooze = false,
          bool? snoozeAllowed,
          String? severity}) =>
      SubscriptionHealth(
        healthStatus: status,
        level: level,
        trialActive: false,
        effectiveTier: 'premium',
        daysToExpiry: 5,
        degraded: false,
        terminatedAt: null,
        exportWindow: null,
        snoozeAllowed: snoozeAllowed,
        severity: severity,
      );

  Color? backgroundOf(WidgetTester tester) {
    final finder = find.byKey(const Key('subscription-health-banner'));
    expect(finder, findsOneWidget);
    final container = tester.widget<Container>(finder);
    return (container.decoration as BoxDecoration?)?.color;
  }

  testWidgets('spec §2 severity matrix colours (backend-decided severity)',
      (tester) async {
    final cases = <(String, String?, Color)>[
      ('RENEWAL_FAILED', null, warn),
      ('SUSPENDED', null, warn),
      ('EXPIRING_SOON', 'info', info),
      ('EXPIRING_SOON', 'warn', warn),
      ('EXPIRING_SOON', 'danger', danger),
      // Backend now emits severity for every level-bearing verdict —
      // TRIAL (trialEndsAt expiring) escalates like EXPIRING_SOON.
      ('TRIAL', 'info', info),
      ('TRIAL', 'warn', warn),
      ('TRIAL', 'danger', danger),
      ('CANCELLED', null, danger),
      ('EXPIRED', null, danger),
    ];
    for (final (status, severity, expected) in cases) {
      final hasLevel = status == 'TRIAL' || status == 'EXPIRING_SOON';
      await tester.pumpWidget(harness(h(status,
          level: hasLevel ? 10 : null, severity: severity)));
      expect(backgroundOf(tester), expected,
          reason: '$status severity=$severity should render $expected');
    }
  });

  testWidgets('missing severity falls back to info (safe direction when '
      'thresholds are custom)', (tester) async {
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', level: 10)));
    expect(backgroundOf(tester), info);
    await tester.pumpWidget(harness(h('TRIAL', level: 10)));
    expect(backgroundOf(tester), info);
    // Unknown severity name also lands on info.
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', severity: 'critical')));
    expect(backgroundOf(tester), info);
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

  testWidgets('fromJson parses severity (nullable, default null)',
      (tester) async {
    expect(
      SubscriptionHealth.fromJson({
        'healthStatus': 'EXPIRING_SOON',
        'level': 10,
        'trialActive': false,
        'effectiveTier': 'premium',
        'daysToExpiry': 4,
        'degraded': false,
        'severity': 'warn',
      }).severity,
      'warn',
    );
    expect(
      SubscriptionHealth.fromJson({
        'healthStatus': 'EXPIRING_SOON',
        'level': 5,
        'trialActive': false,
        'effectiveTier': 'premium',
        'daysToExpiry': 2,
        'degraded': false,
      }).severity,
      isNull,
    );
  });

  testWidgets('NIX-334 snooze gating is backend-decided via snoozeAllowed: '
      'shown only for EXPIRING_SOON with snoozeAllowed=true', (tester) async {
    const snoozeKey = Key('subscription-health-banner-snooze');
    // Backend verdict true → button shows regardless of the level number
    // (thresholds are platform-configurable, e.g. 30/10/5).
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', level: 30, snoozeAllowed: true),
            snooze: true));
    expect(find.byKey(snoozeKey), findsOneWidget);
    // Backend verdict false (last configured tier) → hidden even if a
    // legacy hardcoded check would have shown it.
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', level: 5, snoozeAllowed: false),
            snooze: true));
    expect(find.byKey(snoozeKey), findsNothing);
    // Missing field (backend predating the contract) → hidden.
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', level: 14), snooze: true));
    expect(find.byKey(snoozeKey), findsNothing);
    // Non-EXPIRING_SOON states never show it.
    await tester.pumpWidget(
        harness(h('RENEWAL_FAILED', snoozeAllowed: true), snooze: true));
    expect(find.byKey(snoozeKey), findsNothing);
    await tester.pumpWidget(
        harness(h('EXPIRED', snoozeAllowed: true), snooze: true));
    expect(find.byKey(snoozeKey), findsNothing);
    // No callback wired → no button even when allowed.
    await tester.pumpWidget(
        harness(h('EXPIRING_SOON', level: 14, snoozeAllowed: true)));
    expect(find.byKey(snoozeKey), findsNothing);
    // TRIAL keeps its colour escalation but never offers 稍后提醒
    // (snoozeAllowed stays EXPIRING_SOON-only per the contract).
    await tester.pumpWidget(
        harness(h('TRIAL', level: 10, snoozeAllowed: true), snooze: true));
    expect(find.byKey(snoozeKey), findsNothing);
  });

  testWidgets('fromJson parses snoozeAllowed (nullable, default null)',
      (tester) async {
    expect(
      SubscriptionHealth.fromJson({
        'healthStatus': 'EXPIRING_SOON',
        'level': 10,
        'trialActive': false,
        'effectiveTier': 'premium',
        'daysToExpiry': 4,
        'degraded': false,
        'snoozeAllowed': true,
      }).snoozeAllowed,
      isTrue,
    );
    expect(
      SubscriptionHealth.fromJson({
        'healthStatus': 'EXPIRING_SOON',
        'level': 5,
        'trialActive': false,
        'effectiveTier': 'premium',
        'daysToExpiry': 2,
        'degraded': false,
      }).snoozeAllowed,
      isNull,
    );
  });
}
