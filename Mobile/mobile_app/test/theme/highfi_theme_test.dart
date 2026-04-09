import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('DemoApp applies the high-fidelity theme tokens', (tester) async {
    await tester.pumpWidget(const DemoApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.useMaterial3, isTrue);
    expect(app.theme?.colorScheme.primary, const Color(0xFF2F6B3B));
    expect(app.theme?.colorScheme.surface, const Color(0xFFF8F6F0));
  });
}
