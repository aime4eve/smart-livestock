import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/locked_overlay.dart';

Widget _testChild() => const SizedBox(
      key: Key('test-child'),
      width: 400,
      height: 400,
      child: Text('Normal Content'),
    );

void main() {
  group('LockedOverlay', () {
    testWidgets('shows child when locked is false', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: false,
            child: _testChild(),
          ),
        ),
      ));

      expect(find.byKey(const Key('test-child')), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('shows overlay when locked is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            upgradeTier: 'premium',
            child: _testChild(),
          ),
        ),
      ));

      expect(find.byKey(const Key('test-child')), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.textContaining('高级版'), findsWidgets);
    });

    testWidgets('shows upgrade button when onUpgrade provided and not device locked',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            upgradeTier: 'standard',
            onUpgrade: () {},
            child: _testChild(),
          ),
        ),
      ));

      // Both the lock message and the button contain "升级到标准版"
      expect(find.textContaining('升级到标准版'), findsAtLeast(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows device icon when deviceLocked is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            deviceLocked: true,
            deviceMessage: '需要安装瘤胃胶囊',
            child: _testChild(),
          ),
        ),
      ));

      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
      expect(find.text('需要安装瘤胃胶囊'), findsOneWidget);
    });

    testWidgets('device locked shows default message when deviceMessage is null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            deviceLocked: true,
            child: _testChild(),
          ),
        ),
      ));

      expect(find.text('该功能需要安装相应设备'), findsOneWidget);
    });

    testWidgets('device locked does NOT show upgrade button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            deviceLocked: true,
            upgradeTier: 'premium',
            onUpgrade: () {},
            child: _testChild(),
          ),
        ),
      ));

      // Should show device icon, not lock icon
      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
      // Upgrade button should not appear when device locked
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows correct label for enterprise upgrade tier', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            upgradeTier: 'enterprise',
            onUpgrade: () {},
            child: _testChild(),
          ),
        ),
      ));

      expect(find.textContaining('企业版'), findsWidgets);
    });

    testWidgets('child is rendered with reduced opacity when locked', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LockedOverlay(
            locked: true,
            upgradeTier: 'premium',
            child: _testChild(),
          ),
        ),
      ));

      final opacityFinder = find.byType(Opacity);
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.35);
    });
  });
}
