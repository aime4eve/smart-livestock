import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_snooze_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NIX-334: the snooze record binds to (level, period end) so it lapses on
/// its own — level drop 14→7, renewal moving the period end, or a state
/// switch must all re-show the banner without any timer or manual clear.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final expiring14 = SubscriptionHealth(
    healthStatus: 'EXPIRING_SOON',
    level: 14,
    trialActive: false,
    effectiveTier: 'premium',
    daysToExpiry: 14,
    degraded: false,
  );
  final periodEnd = DateTime.utc(2026, 11, 10);

  test('record round-trips through its encoded form', () {
    final record = SubscriptionSnoozeRecord(
        level: 14, periodEnd: periodEnd.toIso8601String());
    final decoded = SubscriptionSnoozeRecord.decode(record.encode());
    expect(decoded?.level, 14);
    expect(decoded?.periodEnd, periodEnd.toIso8601String());
    expect(SubscriptionSnoozeRecord.decode(null), isNull);
    expect(SubscriptionSnoozeRecord.decode('garbage'), isNull);
    expect(SubscriptionSnoozeRecord.decode('x|no-level'), isNull);
  });

  test('suppresses only the same level AND period end', () {
    final record = SubscriptionSnoozeRecord(
        level: 14, periodEnd: periodEnd.toIso8601String());

    expect(record.suppresses(expiring14, periodEnd), isTrue);
    // Threshold crossed 14 → 7: the user asked to be reminded at 7 days.
    expect(
        record.suppresses(
            SubscriptionHealth(
                healthStatus: 'EXPIRING_SOON',
                level: 7,
                trialActive: false,
                effectiveTier: 'premium',
                degraded: false),
            periodEnd),
        isFalse);
    // Renewal moved the period end.
    expect(record.suppresses(expiring14, periodEnd.add(const Duration(days: 30))),
        isFalse);
    // Any non-EXPIRING_SOON state never suppresses.
    expect(
        record.suppresses(
            SubscriptionHealth(
                healthStatus: 'RENEWAL_FAILED',
                trialActive: false,
                effectiveTier: 'premium',
                degraded: false),
            periodEnd),
        isFalse);
  });

  test('snooze persists across a fresh provider/container (app restart)',
      () async {
    SharedPreferences.setMockInitialValues({});

    final first = ProviderContainer();
    addTearDown(first.dispose);
    await first.read(subscriptionSnoozeProvider('t9').future);
    await first
        .read(subscriptionSnoozeProvider('t9').notifier)
        .snooze(level: 14, periodEnd: periodEnd);

    // A second container simulates the next app start reading the same
    // SharedPreferences store.
    final second = ProviderContainer();
    addTearDown(second.dispose);
    final restored =
        await second.read(subscriptionSnoozeProvider('t9').future);
    expect(restored, isNotNull);
    expect(restored!.suppresses(expiring14, periodEnd), isTrue);
  });

  test('snoozes are keyed per tenant', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(subscriptionSnoozeProvider('t1').future);
    await container
        .read(subscriptionSnoozeProvider('t1').notifier)
        .snooze(level: 7, periodEnd: periodEnd);

    expect(
        await container.read(subscriptionSnoozeProvider('t2').future), isNull);
  });
}
