import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/status_dashboard_card.dart';

void main() {
  group('StatusDashboardCard', () {
    testWidgets('renders title and count when alertCount > 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusDashboardCard(
            icon: Icons.fence,
            title: '围栏告警',
            alertCount: 3,
            subtitle: '越界 2  接近 1',
            accentColor: AppColors.warning,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('围栏告警'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('越界 2  接近 1'), findsOneWidget);
    });

    testWidgets('does not show count badge when alertCount is 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusDashboardCard(
            icon: Icons.favorite,
            title: '健康告警',
            alertCount: 0,
            subtitle: '牲畜健康',
            accentColor: AppColors.danger,
            onTap: () {},
          ),
        ),
      ));
      expect(find.text('健康告警'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusDashboardCard(
            icon: Icons.fence,
            title: 'Test',
            alertCount: 1,
            subtitle: 'sub',
            accentColor: AppColors.warning,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('dashboard-card-Test')));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
