import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('demo app boot smoke test', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('智慧畜牧'), findsOneWidget);
  });
}
