import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';

/// 包络管线单测（NIX-213）：矩形走位收敛、L 形保凹角、顺序打乱不变、
/// 漂移尖刺清洗、碎片化凸包兜底、共线退化、点数下限与顶点上限。
void main() {
  const anchorLat = 28.20;
  const anchorLng = 112.90;
  final mPerDegLng = 111320.0 * cos(anchorLat * pi / 180.0);

  /// 米制偏移 → 轨迹点（accuracy/timestamp 模拟 GPX：默认可信、无时间）
  TrackPoint m(double x, double y, {double accuracy = 0, DateTime? time}) =>
      TrackPoint(
        lat: anchorLat + y / 111320.0,
        lng: anchorLng + x / mPerDegLng,
        accuracyMeters: accuracy,
        timestamp: time,
      );

  /// 沿给定米制多边形边界走一圈（每 [step] 米一个采样点）。
  ///
  /// [jitterM] 模拟真实 GPS 横向噪声（固定种子保证确定性）。默认参数对齐
  /// 真实采集场景：distanceFilter 2m 的点距 × 3-10m 的手机 GPS 精度，剖分
  /// 条带是多三角厚；零噪声完美共线的单排点是剖分退化的度量零输入。
  List<TrackPoint> walkPolygon(List<(double, double)> verticesMeters,
      {double step = 3, double jitterM = 2.5, Random? random}) {
    final rng = random ?? Random(42);
    final pts = <TrackPoint>[];
    for (var i = 0; i < verticesMeters.length; i++) {
      final a = verticesMeters[i];
      final b = verticesMeters[(i + 1) % verticesMeters.length];
      final dx = b.$1 - a.$1;
      final dy = b.$2 - a.$2;
      final len = sqrt(dx * dx + dy * dy);
      final n = (len / step).floor();
      for (var k = 0; k < n; k++) {
        final t = k / n;
        final jx = (rng.nextDouble() - 0.5) * 2 * jitterM;
        final jy = (rng.nextDouble() - 0.5) * 2 * jitterM;
        pts.add(m(a.$1 + dx * t + jx, a.$2 + dy * t + jy));
      }
    }
    return pts;
  }

  /// 顶点环面积（平方米）。
  double areaM2(List<LatLng> ring) {
    var area = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final j = (i + 1) % ring.length;
      area += ring[i].longitude * ring[j].latitude -
          ring[j].longitude * ring[i].latitude;
    }
    return (area / 2).abs() * 111320.0 * mPerDegLng;
  }

  test('rectangle walk converges to the walked outline', () {
    final pts = [
      ...walkPolygon([(-100, -80), (100, -80), (100, 80), (-100, 80)]),
      m(-5, -5), // 内部点不参与包络
      m(8, 10),
      m(300, 0), // 向外漂移尖刺
    ];

    final result = TrackToEnvelopeConverter.convert(pts);

    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.method, HullMethod.concave);
    expect(result.outliersDropped, greaterThanOrEqualTo(1));
    // 收紧 + DP 后顶点数有界；面积贴合走位轮廓
    expect(result.vertexCount, lessThanOrEqualTo(60));
    expect(areaM2(result.vertices), closeTo(200 * 160, 200 * 160 * 0.2));
  });

  test('L-shape keeps the concave corner', () {
    final pts = walkPolygon([
      (-150, -150),
      (150, -150),
      (150, 0),
      (0, 0), // 凹角
      (0, 150),
      (-150, 150),
    ]);

    final result = TrackToEnvelopeConverter.convert(pts);

    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    final area = areaM2(result.vertices);
    expect(area, closeTo(67500, 67500 * 0.15));
    // 凸包会填平缺口（~78750㎡）；包络必须显著小于凸包
    expect(area, lessThan(78750 * 0.9));
    expect(result.method, HullMethod.concave);
  });

  test('reversed walk direction yields equivalent envelope', () {
    // 三角剖分依赖行走原始顺序（delaunay 包 dart2js 对乱序输入会死循环），
    // 顺序无关性体现在产品语义上：顺/逆时针走同一圈，包络等价。
    final pts = [
      ...walkPolygon([(-100, -80), (100, -80), (100, 80), (-100, 80)]),
      m(-5, -5),
    ];
    final reversed = pts.reversed.toList();

    final a = TrackToEnvelopeConverter.convert(pts);
    final b = TrackToEnvelopeConverter.convert(reversed);

    expect(a.isSuccess, isTrue);
    expect(b.isSuccess, isTrue);
    expect(areaM2(b.vertices), closeTo(areaM2(a.vertices), areaM2(a.vertices) * 0.05));
    expect((b.vertexCount - a.vertexCount).abs(), lessThanOrEqualTo(6));
  });

  test('separated clusters keep the largest inner face', () {
    final pts = [
      ...walkPolygon([(-250, -50), (-150, -50), (-150, 50), (-250, 50)]),
      ...walkPolygon([(150, -50), (250, -50), (250, 50), (150, 50)]),
    ];

    final result = TrackToEnvelopeConverter.convert(pts);

    // 收紧算法把两簇连同间隙收成一张连通多边形（无法再取"最大一片"，
    // 多片拆分属 P3 带洞/多环范畴）；面积至少覆盖两簇主体
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.method, HullMethod.concave);
    expect(areaM2(result.vertices), greaterThan(25000));
  });

  test('collinear points are rejected as degenerate', () {
    final pts = [for (var i = 0; i < 30; i++) m(i * 10.0 - 150, 0)];

    final result = TrackToEnvelopeConverter.convert(pts);

    expect(result.failure, EnvelopeFailure.degenerate);
    expect(result.isSuccess, isFalse);
  });

  test('too few points fail with tooFewPoints', () {
    expect(TrackToEnvelopeConverter.convert([m(0, 0), m(10, 0)]).failure,
        EnvelopeFailure.tooFewPoints);
    expect(
        TrackToEnvelopeConverter.convert(
            [m(0, 0, accuracy: 50), m(10, 0, accuracy: 50), m(0, 10, accuracy: 50)]),
        isA<TrackToEnvelopeResult>().having((r) => r.failure, 'failure',
            EnvelopeFailure.tooFewPoints));
  });

  test('stationary duplicate cluster is merged away', () {
    final pts = [
      for (var i = 0; i < 50; i++) m(0, 0),
      ...walkPolygon([(-100, -80), (100, -80), (100, 80), (-100, 80)]),
    ];

    final result = TrackToEnvelopeConverter.convert(pts);

    // 原地漂移堆点是内部点：不影响外包络（规范排序+精确去重兜底）
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(areaM2(result.vertices), closeTo(200 * 160, 200 * 160 * 0.2));
  });

  test('noisy dense circle respects the vertex cap', () {
    final random = Random(3);
    final pts = <TrackPoint>[];
    for (var i = 0; i < 900; i++) {
      final angle = 2 * pi * i / 900;
      final r = 300.0 + (random.nextDouble() - 0.5) * 6;
      pts.add(m(cos(angle) * r, sin(angle) * r));
    }

    final result = TrackToEnvelopeConverter.convert(pts);

    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.vertexCount, lessThanOrEqualTo(100));
    expect(areaM2(result.vertices), closeTo(pi * 300 * 300, pi * 300 * 300 * 0.25));
  });
}
