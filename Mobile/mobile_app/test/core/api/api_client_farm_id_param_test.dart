import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';

/// 方向 4：ApiClient.farm* 的 {String? farmId} 参数语义测试。
/// farmId 显式传入时应优先于全局 _activeFarmId 拼 URL，且不修改全局状态
/// （让 b2b_worker_detail 等跨农场操作无需 save/restore，杜绝异常残留 bug）。
void main() {
  setUp(() {
    // ApiClient 是全局单例，activeFarmId 跨测试残留，每个测试前重置。
    ApiClient.instance.setActiveFarmId(null);
  });

  test('farmGet(farmId) 全局为 null 时使用 farmId，不抛 StateError', () async {
    ApiClient.instance.setActiveFarmId(null);
    // farmId='F2' → 用 F2 拼 URL；请求会因无后端抛 SocketException，但绝不是 StateError
    // （若实现错误地忽略 farmId 用全局 null，会在请求前抛 StateError → 测试失败）。
    await expectLater(
      ApiClient.instance.farmGet('/x', farmId: 'F2'),
      throwsA(isNot(isA<StateError>())),
    );
  });

  test('farmGet 无 farmId 且全局 null 时抛 StateError("No active farm")', () async {
    ApiClient.instance.setActiveFarmId(null);
    await expectLater(
      ApiClient.instance.farmGet('/x'),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'No active farm'),
      ),
    );
  });

  test('farmGet(farmId) 不修改全局 _activeFarmId', () async {
    ApiClient.instance.setActiveFarmId('G1');
    try {
      await ApiClient.instance.farmGet('/x', farmId: 'F2');
    } catch (_) {}
    expect(ApiClient.instance.activeFarmId, 'G1');
  });

  test('farmPost body + farmId 共存，不污染全局', () async {
    ApiClient.instance.setActiveFarmId('G1');
    try {
      await ApiClient.instance.farmPost('/x', body: {'a': 1}, farmId: 'F2');
    } catch (_) {}
    expect(ApiClient.instance.activeFarmId, 'G1');
  });
}
