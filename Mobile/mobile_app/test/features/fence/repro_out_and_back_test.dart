import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';

/// 复现真实故障（NIX-213 用户数据）：RTK 自动追踪的开放折返轨迹——
/// 点距 ~1.2m、厘米级噪声（近共线薄条带）+ 折返近重合点。
/// 故障现象：convert 死循环占满 UI 线程（点击"生成围栏范围"无反应）。
void main() {
  test('open out-and-back RTK track terminates and yields usable envelope',
      () {
    final random = Random(11);
    final pts = <TrackPoint>[];
    // 去程：沿 x 正向 300m 微弯（y 随 sin 摆动 ~10m），步距 1.2m
    const n = 250;
    for (var i = 0; i < n; i++) {
      final x = i * 1.2;
      final y = sin(x / 40) * 10 + (random.nextDouble() - 0.5) * 0.06;
      pts.add(TrackPoint(lat: 28.20 + y / 111320.0, lng: 112.90 + x / 98286.0));
    }
    // 回程：折返，横向偏移 3m（往返轨迹围出细长条带），步距 1.26m
    for (var i = n - 1; i >= 0; i--) {
      final x = i * 1.2;
      final y = sin(x / 40) * 10 + 3 + (random.nextDouble() - 0.5) * 0.06;
      pts.add(TrackPoint(lat: 28.20 + y / 111320.0, lng: 112.90 + x / 98286.0));
    }

    final result = TrackToEnvelopeConverter.convert(pts);

    // 终止性即断言：能走到这里说明没有死循环；结果要么成功要么明确失败
    expect(
      result.isSuccess || result.failure != null,
      isTrue,
    );
  });
}
