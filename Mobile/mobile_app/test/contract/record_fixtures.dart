/// 录制真实后端 API 响应为 fixture 文件。
///
/// 用法: dart test/contract/record_fixtures.dart
///
/// 前提: 后端服务运行在 http://172.22.1.123:18080
library;

import 'dart:convert';
import 'dart:io';

const _baseUrl = 'http://172.22.1.123:18080/api/v1';
const _fixtureDir = 'test/fixtures/api';

// 种子用户凭据
const _ownerPhone = '13800138000';
const _ownerPassword = '123';

Future<void> main() async {
  final dir = Directory(_fixtureDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // 1. 登录获取 token
  print('🔑 登录 owner...');
  final loginBody = jsonEncode({
    'phone': _ownerPhone,
    'password': _ownerPassword,
  });
  final loginResp = await _post('/auth/login', loginBody);
  final loginData = loginResp['data'] as Map<String, dynamic>;
  final token = loginData['accessToken'] as String;
  print('   ✅ token 获取成功');

  // 2. 获取 farmId
  print('🏠 获取牧场列表...');
  final farmsResp = await _get('/farms', token);
  final farmsData = farmsResp['data'] as Map<String, dynamic>;
  final farmItems = (farmsData['items'] as List).cast<Map<String, dynamic>>();
  final farmId = farmItems.first['id'];
  print('   ✅ 使用 farmId=$farmId');

  // 3. 录制各端点
  await _record('me.json', await _get('/me', token));
  await _record('farms_list.json', farmsResp);
  await _record('fences_list.json',
      await _get('/farms/$farmId/fences?pageSize=100', token));
  await _record('livestock_list.json',
      await _get('/farms/$farmId/livestock?pageSize=100', token));
  await _record('alerts_list.json',
      await _get('/farms/$farmId/alerts?pageSize=100', token));
  await _record('dashboard_summary.json',
      await _get('/farms/$farmId/dashboard/summary', token));
  await _record('devices_list.json',
      await _get('/farms/$farmId/devices?pageSize=100', token));
  await _record('subscription_status.json', await _get('/subscription', token));
  await _record('subscription_plans.json', await _get('/subscription/plans', token));
  await _record('gps_logs_latest.json',
      await _get('/farms/$farmId/gps-logs/latest', token));
  await _record('map_overview.json',

      await _get('/farms/$farmId/map/overview', token));

  // 牧场总览（Issue #51 合并孪生+围栏+告警）
  await _record('ranch_overview.json',
      await _get('/farms/$farmId/ranch-overview', token));

  // 4. 录制 detail（需要先获取 id）
  final fencesResp = await _get('/farms/$farmId/fences?pageSize=100', token);
  final fenceItems =
      ((fencesResp['data'] as Map<String, dynamic>)['items'] as List)
          .cast<Map<String, dynamic>>();
  if (fenceItems.isNotEmpty) {
    final fenceId = fenceItems.first['id'];
    await _record(
        'fence_detail.json', await _get('/farms/$farmId/fences/$fenceId', token));
  }

  print('\n✅ 全部 fixture 录制完成: $_fixtureDir/');
}

Future<void> _record(String name, Map<String, dynamic> data) async {
  final file = File('$_fixtureDir/$name');
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
  print('   📝 $name (${data['code']})');
}

Future<Map<String, dynamic>> _get(String path, String token) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse('$_baseUrl$path'));
    req.headers.set('Authorization', 'Bearer $token');
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _post(String path, String body) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse('$_baseUrl$path'));
    req.headers.contentType = ContentType.json;
    req.write(body);
    final resp = await req.close();
    final respBody = await resp.transform(utf8.decoder).join();
    return jsonDecode(respBody) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}
