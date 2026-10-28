import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_plan_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-324 fidelity D1: the health banner's renew CTA must preselect the
/// state machine's target tier on checkout — TRIAL converts to premium;
/// every other revivable state (renewal_failed/expired/…) renews the row's
/// own tier. The pre-fix regression hardcoded basic for all states.
class _FakeRepo implements SubscriptionRepository {
  _FakeRepo(this._status);

  final SubscriptionStatus _status;

  @override
  Future<SubscriptionStatus> loadCurrent() async => _status;

  @override
  Future<List<PlanInfo>> loadPlans() async => const [];

  @override
  Future<SubscriptionStatus> checkout(
          {required String tier, required int livestockCount}) async =>
      _status;

  @override
  Future<SubscriptionStatus> changeTier(String tier) async => _status;

  @override
  Future<void> cancel() async {}

  @override
  Future<SubscriptionUsage> loadUsage() async =>
      SubscriptionUsage(livestockCount: _status.livestockCount);
}

void main() {
  SubscriptionStatus statusWith(
    SubscriptionTier tier,
    String healthStatus,
  ) =>
      SubscriptionStatus(
        id: '1',
        tenantId: '1',
        tier: tier,
        status: 'x',
        livestockCount: 120,
        health: SubscriptionHealth(
          healthStatus: healthStatus,
          trialActive: false,
          effectiveTier: 'premium',
          daysToExpiry: 5,
          degraded: false,
        ),
      );

  Future<Object?> pumpAndTapCta(WidgetTester tester, SubscriptionStatus s) async {
    Object? capturedExtra;
    final router = GoRouter(
      initialLocation: AppRoute.subscriptionPlan.path,
      routes: [
        GoRoute(
          path: AppRoute.subscriptionPlan.path,
          builder: (_, __) => const SubscriptionPlanPage(),
        ),
        GoRoute(
          path: AppRoute.checkout.path,
          builder: (_, state) {
            capturedExtra = state.extra;
            return const Scaffold(body: SizedBox());
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(_FakeRepo(s)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('subscription-health-banner-cta')));
    await tester.pumpAndSettle();
    return capturedExtra;
  }

  testWidgets('TRIAL converts to premium regardless of row tier',
      (tester) async {
    final extra =
        await pumpAndTapCta(tester, statusWith(SubscriptionTier.basic, 'TRIAL'));
    expect((extra! as Map)['tier'], SubscriptionTier.premium);
  });

  testWidgets('RENEWAL_FAILED renews the row tier, not basic (D1 regression)',
      (tester) async {
    final extra = await pumpAndTapCta(
        tester, statusWith(SubscriptionTier.premium, 'RENEWAL_FAILED'));
    expect((extra! as Map)['tier'], SubscriptionTier.premium);
  });

  testWidgets('EXPIRED keeps row tier', (tester) async {
    final extra = await pumpAndTapCta(
        tester, statusWith(SubscriptionTier.premium, 'EXPIRED'));
    expect((extra! as Map)['tier'], SubscriptionTier.premium);
  });

  testWidgets('basic row renewing stays basic', (tester) async {
    final extra = await pumpAndTapCta(
        tester, statusWith(SubscriptionTier.basic, 'EXPIRING_SOON'));
    expect((extra! as Map)['tier'], SubscriptionTier.basic);
  });
}
