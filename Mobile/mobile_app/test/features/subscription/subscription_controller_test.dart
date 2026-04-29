import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

void main() {
  group('SubscriptionController (mock mode)', () {
    test('build returns trial status by default', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      final status = container.read(subscriptionControllerProvider);
      expect(status.status, 'trial');
      expect(status.tier, SubscriptionTier.premium);
    });

    test('checkout changes tier to standard and sets active', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      container
          .read(subscriptionControllerProvider.notifier)
          .checkout(SubscriptionTier.standard, 100);

      final status = container.read(subscriptionControllerProvider);
      expect(status.status, 'active');
      expect(status.tier, SubscriptionTier.standard);
      expect(status.livestockCount, 100);
    });

    test('checkout to premium sets correct tier', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      container
          .read(subscriptionControllerProvider.notifier)
          .checkout(SubscriptionTier.premium, 500);

      final status = container.read(subscriptionControllerProvider);
      expect(status.tier, SubscriptionTier.premium);
      expect(status.status, 'active');
    });

    test('cancel sets status to cancelled', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      container
          .read(subscriptionControllerProvider.notifier)
          .checkout(SubscriptionTier.standard, 50);
      container.read(subscriptionControllerProvider.notifier).cancel();

      final status = container.read(subscriptionControllerProvider);
      expect(status.status, 'cancelled');
    });

    test('renew updates livestockCount and extends period', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      container
          .read(subscriptionControllerProvider.notifier)
          .checkout(SubscriptionTier.standard, 50);
      container
          .read(subscriptionControllerProvider.notifier)
          .renew(80);

      final status = container.read(subscriptionControllerProvider);
      expect(status.status, 'active');
      expect(status.livestockCount, 80);
      expect(status.currentPeriodEnd, isNotNull);
    });
  });

  group('subscriptionPlansProvider', () {
    test('returns 4 plans in mock mode', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      final plans = container.read(subscriptionPlansProvider);
      expect(plans.length, 4);
      expect(plans[0].tier, SubscriptionTier.basic);
      expect(plans[1].tier, SubscriptionTier.standard);
      expect(plans[2].tier, SubscriptionTier.premium);
      expect(plans[3].tier, SubscriptionTier.enterprise);
    });
  });

  group('subscriptionFeaturesProvider', () {
    test('returns all 20 features in mock mode', () {
      final container = ProviderContainer(
        overrides: [appModeProvider.overrideWith((ref) => AppMode.mock)],
      );
      addTearDown(container.dispose);

      final features = container.read(subscriptionFeaturesProvider);
      expect(features.length, 20);
      expect(features.containsKey('gps_location'), true);
      expect(features.containsKey('health_score'), true);
    });
  });
}
