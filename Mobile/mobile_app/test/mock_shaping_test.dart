import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

void main() {
  group('shapeListItems', () {
    test('locked feature returns locked result for insufficient tier', () {
      final items = List.generate(
        5,
        (i) => <String, dynamic>{'id': 'a_$i', 'title': 'Alert $i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.basic,
        featureKeys: [FeatureFlags.trajectory],
      );

      expect(result.locked, isTrue);
      expect(result.retainedCount, equals(0));
      expect(result.originalCount, equals(5));
    });

    test('non-locked feature returns all items for sufficient tier', () {
      final items = List.generate(
        5,
        (i) => <String, dynamic>{'id': 'a_$i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.premium,
        featureKeys: [FeatureFlags.gpsLocation],
      );

      expect(result.locked, isFalse);
      expect(result.retainedCount, equals(5));
    });

    test('limit feature truncates items for lowest tier', () {
      final items = List.generate(
        10,
        (i) => <String, dynamic>{'id': 'f_$i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.basic,
        featureKeys: [FeatureFlags.fence],
      );

      expect(result.locked, isFalse);
      expect(result.retainedCount, equals(3));
      expect(result.originalCount, equals(10));
    });
  });
}
