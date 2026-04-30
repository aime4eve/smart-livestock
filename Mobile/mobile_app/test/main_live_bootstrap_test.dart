import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live ApiCache initialization is awaited before runApp', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, isNot(contains('unawaited(')));
    expect(source.indexOf('await ApiCache.instance.initWithRoleAuth'), isNot(-1));
    expect(source.indexOf('runApp('), isNot(-1));
    expect(
      source.indexOf('await ApiCache.instance.initWithRoleAuth'),
      lessThan(source.indexOf('runApp(')),
    );
  });
}
