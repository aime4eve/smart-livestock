import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/demo_app.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/l10n/locale_controller.dart';

void main() {
  testWidgets('demo app boot smoke test', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(AppSession.loggedOut),
        // Force zh locale so the test is deterministic regardless of CI system locale.
        initialLocaleProvider.overrideWithValue(const Locale('zh')),
      ],
      child: const DemoApp(),
    ));
    expect(find.text('智慧畜牧'), findsOneWidget);
  });
}
