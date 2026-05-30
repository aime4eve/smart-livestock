import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';

void main() {
  testWidgets('demo app boot smoke test', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [initialSessionProvider.overrideWithValue(AppSession.loggedOut)],
      child: const DemoApp(),
    ));
    expect(find.text('智慧畜牧'), findsOneWidget);
  });
}
