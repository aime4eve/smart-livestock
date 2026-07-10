import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/livestock_map_marker.dart';

void main() {
  group('livestockHealthColor', () {
    test('NORMAL returns success green', () {
      expect(livestockHealthColor('NORMAL', ''), AppColors.success);
    });

    test('WARNING + FEVER returns danger red', () {
      expect(livestockHealthColor('WARNING', 'FEVER'), AppColors.danger);
    });

    test('CRITICAL + FEVER returns danger red', () {
      expect(livestockHealthColor('CRITICAL', 'FEVER'), AppColors.danger);
    });

    test('WARNING + DIGESTIVE returns warning orange', () {
      expect(livestockHealthColor('WARNING', 'DIGESTIVE'), AppColors.warning);
    });

    test('CRITICAL + DIGESTIVE returns warning orange', () {
      expect(livestockHealthColor('CRITICAL', 'DIGESTIVE'), AppColors.warning);
    });

    test('WARNING + ESTRUS returns estrus pink', () {
      expect(livestockHealthColor('WARNING', 'ESTRUS'), AppColors.estrus);
    });

    test('WARNING + EPIDEMIC returns info blue', () {
      expect(livestockHealthColor('WARNING', 'EPIDEMIC'), AppColors.info);
    });

    test('abnormal with unknown alert type returns danger', () {
      expect(livestockHealthColor('WARNING', 'SOMETHING_ELSE'), AppColors.danger);
    });

    test('abnormal with empty alert returns danger', () {
      expect(livestockHealthColor('CRITICAL', ''), AppColors.danger);
    });
  });

  group('LivestockMapMarker widget', () {
    testWidgets('renders livestock code label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivestockMapMarker(
              livestockCode: 'SL-2024-001',
              healthStatus: 'NORMAL',
              primaryAlert: '',
              fenceStatus: 'SAFE',
            ),
          ),
        ),
      );
      expect(find.text('001'), findsOneWidget);
    });

    testWidgets('handles empty code gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivestockMapMarker(
              livestockCode: '',
              healthStatus: 'NORMAL',
              primaryAlert: '',
              fenceStatus: 'SAFE',
            ),
          ),
        ),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });
}
