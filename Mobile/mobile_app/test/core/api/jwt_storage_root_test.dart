import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_storage.dart';

void main() {
  // Native secure storage is unavailable in tests; back the platform
  // channel with an in-memory map (kIsWeb is false under `flutter test`).
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'readAll':
          return Map<String, String>.of(store);
        case 'deleteAll':
          store.clear();
          return null;
      }
      return null;
    });
  });

  group('超管双 token 与最近切换存储（2026-10-19 §4.2）', () {
    test('root token/user 存取与 clearRoot 只清 root', () async {
      await JwtStorage.instance.saveAccessToken('ctx-token');
      await JwtStorage.instance.saveUserInfo({'id': 6, 'role': 'OWNER'});
      await JwtStorage.instance.saveRootToken('root-token');
      await JwtStorage.instance.saveRootUserInfo({
        'id': 6,
        'role': 'SUPER_ADMIN',
        'mustChangePassword': false
      });

      expect(await JwtStorage.instance.getRootToken(), 'root-token');
      final rootInfo = await JwtStorage.instance.getRootUserInfo();
      expect(rootInfo!['role'], 'SUPER_ADMIN');

      await JwtStorage.instance.clearRoot();
      expect(await JwtStorage.instance.getRootToken(), isNull);
      expect(await JwtStorage.instance.getRootUserInfo(), isNull);
      // Active session untouched by clearRoot.
      expect(await JwtStorage.instance.getAccessToken(), 'ctx-token');
    });

    test('logout clear() 清全部五类 key（含 root 与最近切换）', () async {
      await JwtStorage.instance.saveAccessToken('ctx-token');
      await JwtStorage.instance.saveRootToken('root-token');
      await JwtStorage.instance.saveRootUserInfo({'id': 6});
      await JwtStorage.instance
          .saveRecentContexts([
        {'role': 'OWNER', 'tenantId': 2, 'tenantName': '南非-市场'}
      ]);
      await JwtStorage.instance.saveActiveFarmId('3');

      await JwtStorage.instance.clear();

      expect(await JwtStorage.instance.getAccessToken(), isNull);
      expect(await JwtStorage.instance.getRootToken(), isNull);
      expect(await JwtStorage.instance.getRootUserInfo(), isNull);
      expect(await JwtStorage.instance.getRecentContexts(), isEmpty);
      expect(await JwtStorage.instance.getActiveFarmId(), isNull);
    });

    test('recent contexts 损坏数据安全回退为空', () async {
      await JwtStorage.instance.saveRecentContexts([
        {'role': 'OWNER', 'tenantId': 2, 'tenantName': '南非-市场'},
        {'role': 'PLATFORM_ADMIN', 'tenantId': null, 'tenantName': null},
      ]);
      final recents = await JwtStorage.instance.getRecentContexts();
      expect(recents.length, 2);
      expect(recents.first['role'], 'OWNER');

      // Corrupt payload must not throw — falls back to empty list.
      store['super_recent_contexts'] = 'not-json{{{';
      expect(await JwtStorage.instance.getRecentContexts(), isEmpty);
    });
  });
}
