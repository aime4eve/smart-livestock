import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main() does not call ApiCache.initWithRoleAuth — bootstrap is deferred to post-login', () {
    final source = File('lib/main.dart').readAsStringSync();

    // main() should not import or call ApiCache at all.
    expect(source, isNot(contains('ApiCache')));
    expect(source, isNot(contains('initWithRoleAuth')));
    // runApp should be present.
    expect(source.indexOf('runApp('), isNot(-1));
  });

  test('loginWithCredentials triggers ApiCache.init after setting session', () {
    final source = File('lib/app/session/session_controller.dart').readAsStringSync();

    // loginWithCredentials should call cache.init with tokens.
    expect(source, contains('await cache.init('));
    expect(source, contains('ApiAuthTokens(accessToken: result.accessToken)'));
    // Session state is set before init (withCredentials appears before init).
    final withCredentialsPos = source.indexOf('AppSession.withCredentials(');
    final initPos = source.indexOf('await cache.init(');
    expect(withCredentialsPos, isNot(-1));
    expect(initPos, isNot(-1));
    expect(withCredentialsPos, lessThan(initPos));
  });
}
