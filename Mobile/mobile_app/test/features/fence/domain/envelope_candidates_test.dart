import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_params.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_point.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';

/// 多候选包络单测（spec 修订 v2.1）：simplifyByAreaContribution 精简行为
/// （锯齿删除/固定基准/环长地板）与 buildTrackDraftCandidates 三候选
/// （排序/可用性/顶点数关系/清洗统计共享/默认参数组与 convert 逐位一致）。
void main() {
  const anchorLat = 28.20;
  const anchorLng = 112.90;
  final mPerDegLng = 111320.0 * cos(anchorLat * pi / 180.0);

  /// 米制偏移 → 轨迹点（可信、无时间戳）。
  TrackPoint m(double x, double y, {double accuracy = 0}) => TrackPoint(
        lat: anchorLat + y / 111320.0,
        lng: anchorLng + x / mPerDegLng,
        accuracyMeters: accuracy,
      );

  /// 米制坐标元组（simplifyByAreaContribution 直测用）。
  (double, double) t(double x, double y) => (x, y);

  /// 有符号鞋带面积（米制坐标）。
  double signedArea(List<(double, double)> ring) {
    var area = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final j = (i + 1) % ring.length;
      area += ring[i].$1 * ring[j].$2 - ring[j].$1 * ring[i].$2;
    }
    return area / 2;
  }

  /// 恒等下标环（坐标即点表时的 ring 参数）与下标 → 坐标映射。
  List<int> identityRing(int n) => List<int>.generate(n, (i) => i);
  List<(double, double)> coordsOf(List<int> idx, List<(double, double)> pts) =>
      [for (final i in idx) pts[i]];

  group('simplifyByAreaContribution', () {
    test('dense sawtooth on a square is deleted down to the corners', () {
      // 200×200 方环 + 顶边 19 个单侧 1m 矮齿：单点删除面积变化 ≈10㎡ ≪
      // 0.5%×基准，全部矮齿可删；四角变化巨大必保留。（不用 ±交替锯齿：
      // 交替凸凹在固定基准下会互相抵消，末段单点删除变化反超 tol，
      // 贪心单点删除会正确地提前终止。）
      final ring = <(double, double)>[
        t(0, 0),
        t(200, 0),
        t(200, 200),
      ];
      for (var x = 190; x >= 10; x -= 10) {
        ring.add(t(x.toDouble(), 201.0));
      }
      ring.add(t(0, 200));

      final simplified = TrackToEnvelopeConverter.simplifyByAreaContribution(
          identityRing(ring.length), ring, 0.005);

      expect(
          coordsOf(simplified, ring),
          [t(0, 0), t(200, 0), t(200, 200), t(0, 200)]);
      // 固定基准不变式：精简后面积相对初始环 |变化| ≤ tolPct。
      final base = signedArea(ring).abs();
      final finalArea = signedArea(coordsOf(simplified, ring)).abs();
      expect((finalArea - base).abs() / base, lessThanOrEqualTo(0.005));
    });

    test('cumulative shrink never exceeds tolPct of the ORIGINAL area '
        '(fixed baseline)', () {
      // 顶边一排 10 个 1.25m 矮齿：单齿 ΔArea ≈ 12.5㎡ < 0.5%×基准，
      // 若基准逐次重置则会一路删光（累计 >0.5% 失真）；固定基准下删到
      // 累计逼近 tolPct 即停。断言：未删光 + 面积收缩 ≤ tolPct。
      final ring = <(double, double)>[
        t(0, 0),
        t(100, 0),
        t(100, 100),
      ];
      for (var x = 90; x >= 10; x -= 10) {
        ring.add(t(x.toDouble(), 101.25));
      }
      ring.add(t(0, 100));

      final base = signedArea(ring).abs();
      final simplified = TrackToEnvelopeConverter.simplifyByAreaContribution(
          identityRing(ring.length), ring, 0.005);

      expect(simplified.length, lessThan(ring.length)); // 至少删了一个矮齿
      final finalArea = signedArea(coordsOf(simplified, ring)).abs();
      final shrink = (base - finalArea) / base;
      expect(shrink, lessThanOrEqualTo(0.005));
    });

    test('ring length floor: a triangle is returned unchanged', () {
      final tri = <(double, double)>[t(0, 0), t(100, 0), t(0, 100)];
      final out = TrackToEnvelopeConverter.simplifyByAreaContribution(
          identityRing(3), tri, 0.9);
      expect(out.length, 3);
      expect(out, identityRing(3));
    });

    test('input ring is not mutated', () {
      final ring = <(double, double)>[
        t(0, 0),
        t(100, 0),
        t(100, 100),
        t(50, 99),
        t(0, 100),
      ];
      final idx = identityRing(ring.length);
      final snapshot = List.of(ring);
      TrackToEnvelopeConverter.simplifyByAreaContribution(idx, ring, 0.005);
      expect(ring, snapshot);
    });
  });

  group('buildTrackDraftCandidates', () {
    /// 400×300 矩形走位 + 每约 8m ±4m 锯齿（确定性，无随机）：DP(2m) 保留
    /// 锯齿，面积贡献精简(0.5%)删除锯齿 → 简化候选顶点数显著更少。
    List<TrackPoint> sawtoothRect() {
      final pts = <TrackPoint>[];
      void edge((double, double) a, (double, double) b, (double, double) normal) {
        final dx = b.$1 - a.$1;
        final dy = b.$2 - a.$2;
        final steps = (sqrt(dx * dx + dy * dy) / 8).floor();
        for (var k = 0; k < steps; k++) {
          final tt = k / steps;
          final off = k.isOdd ? 4.0 : -4.0;
          pts.add(m(
            a.$1 + dx * tt + normal.$1 * off,
            a.$2 + dy * tt + normal.$2 * off,
          ));
        }
      }

      edge((-200, -150), (200, -150), (0, 1));
      edge((200, -150), (200, 150), (1, 0));
      edge((200, 150), (-200, 150), (0, 1));
      edge((-200, 150), (-200, -150), (1, 0));
      return pts;
    }

    test('order is fixed and sawtooth vertices are pruned by the simplified '
        'candidate', () {
      final pts = sawtoothRect();
      final cands =
          TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);

      expect(
        cands.map((c) => c.method).toList(),
        [HullMethod.concaveSimplified, HullMethod.concave, HullMethod.convex],
      );
      for (final c in cands) {
        expect(c.isAvailable, isTrue, reason: '${c.method}: ${c.result.failure}');
      }
      // 简化候选顶点数严格少于精细候选；凸包面积不小于凹包。
      expect(cands[0].result.vertexCount, lessThan(cands[1].result.vertexCount));

      double ringArea(TrackEnvelopeCandidate c) {
        var area = 0.0;
        final vs = c.result.vertices;
        for (var i = 0; i < vs.length; i++) {
          final j = (i + 1) % vs.length;
          area += vs[i].longitude * vs[j].latitude -
              vs[j].longitude * vs[i].latitude;
        }
        return (area / 2).abs() * 111320.0 * mPerDegLng;
      }

      expect(ringArea(cands[2]), greaterThanOrEqualTo(ringArea(cands[1])));
    });

    test('cleaning stats are shared verbatim across the three candidates',
        () {
      final pts = sawtoothRect();
      final cands =
          TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);

      final a = cands[0].result;
      for (final c in cands.skip(1)) {
        expect(c.result.rawCount, a.rawCount);
        expect(c.result.accuracyDropped, a.accuracyDropped);
        expect(c.result.speedDropped, a.speedDropped);
        expect(c.result.roamingTrimmed, a.roamingTrimmed);
        expect(c.result.outliersDropped, a.outliersDropped);
        expect(c.result.remainingValid, a.remainingValid);
        expect(c.result.trimmedPoints.length, a.trimmedPoints.length);
      }
    });

    test('default-params candidates are bit-identical to a single convert()',
        () {
      // 抖动矩形（固定种子）：convert 走收紧（concave）路径。
      final rng = Random(42);
      final pts = <TrackPoint>[];
      void walk((double, double) a, (double, double) b) {
        final dx = b.$1 - a.$1;
        final dy = b.$2 - a.$2;
        final len = sqrt(dx * dx + dy * dy);
        final n = (len / 3).floor();
        for (var k = 0; k < n; k++) {
          final tt = k / n;
          final jx = (rng.nextDouble() - 0.5) * 2 * 2.5;
          final jy = (rng.nextDouble() - 0.5) * 2 * 2.5;
          pts.add(m(a.$1 + dx * tt + jx, a.$2 + dy * tt + jy));
        }
      }

      walk((-200, -150), (200, -150));
      walk((200, -150), (200, 150));
      walk((200, 150), (-200, 150));
      walk((-200, 150), (-200, -150));

      final single = TrackToEnvelopeConverter.convert(pts);
      final cands =
          TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);
      expect(single.isSuccess, isTrue, reason: '${single.failure}');
      expect(single.method, HullMethod.concave);

      final match = cands[1]; // concave slot == the convert() path
      expect(match.isAvailable, isTrue);
      expect(match.result.vertexCount, single.vertexCount);
      for (var i = 0; i < single.vertices.length; i++) {
        expect(match.result.vertices[i].latitude, single.vertices[i].latitude);
        expect(
            match.result.vertices[i].longitude, single.vertices[i].longitude);
      }
      expect(match.result.rawCount, single.rawCount);
      expect(match.result.outliersDropped, single.outliersDropped);
      expect(match.result.accuracyDropped, single.accuracyDropped);
      expect(match.result.speedDropped, single.speedDropped);
      expect(match.result.roamingTrimmed, single.roamingTrimmed);
      expect(match.result.remainingValid, single.remainingValid);
    });

    test('tiny square with an interior point: concave candidates fail while '
        'convex stays available', () {
      // ≈26㎡ 凸包（过退化门）+ 中心内点：收紧把环挖到 ≈19.5㎡ < 25㎡，
      // concave / concaveSimplified 双双标失败；convex 保持可用。
      final pts = [
        m(0, 0),
        m(5.1, 0),
        m(5.1, 5.1),
        m(0, 5.1),
        m(2.55, 2.55),
      ];
      final cands =
          TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);

      expect(cands[0].isAvailable, isFalse);
      expect(cands[0].result.failure, EnvelopeFailure.degenerate);
      expect(cands[1].isAvailable, isFalse);
      expect(cands[2].isAvailable, isTrue);
      expect(cands[2].result.vertices.length, 4);
      // 清洗统计三候选一致（含失败候选）。
      expect(cands[0].result.remainingValid, cands[2].result.remainingValid);
    });

    test('all candidates fail on a collinear track (shared diagnostics)', () {
      final pts = [for (var i = 0; i < 30; i++) m(i * 10.0 - 150, 0)];
      final single = TrackToEnvelopeConverter.convert(pts);
      final cands =
          TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);

      expect(single.failure, EnvelopeFailure.degenerate);
      for (final c in cands) {
        expect(c.isAvailable, isFalse);
        expect(c.result.failure, EnvelopeFailure.degenerate);
        expect(c.result.remainingValid, single.remainingValid);
        expect(c.result.rawCount, single.rawCount);
      }
    });

    test('animal-track params: roaming trim stats ride on every candidate',
        () {
      // 57 点 50m 圆环 + 3 个 ~800m 远漫游点：floor(60×0.95)=57 保留。
      final cluster = <TrackPoint>[
        for (var i = 0; i < 57; i++)
          m(50 * cos(2 * pi * i / 57), 50 * sin(2 * pi * i / 57)),
      ];
      final pts = [...cluster, m(800, 0), m(0, 800), m(-800, -800)];

      final animal = TrackToEnvelopeConverter.buildTrackDraftCandidates(pts,
          params: const TrackDraftParams.animalTrack());
      for (final c in animal) {
        expect(c.result.roamingTrimmed, 3);
        expect(c.result.trimmedPoints.length, 3);
      }

      // 默认参数组：截断段整体禁用。
      final gpx = TrackToEnvelopeConverter.buildTrackDraftCandidates(pts);
      for (final c in gpx) {
        expect(c.result.roamingTrimmed, 0);
        expect(c.result.trimmedPoints, isEmpty);
      }
    });

    test('dense cluster: simplified candidate sheds the detour that '
        'area-trim alone cannot (grid thinning)', () {
      // 400m 方形边界 40 点（每边 11 点含角，占多数使漫游截断裁不到外
      // 轮廓）+ 中心 15m 半径内 20 点密集簇（真实形态：牛群聚集/回落打
      // 点让凹包边界在簇内深绕行，逐点面积精简删不动）。
      final pts = <TrackPoint>[
        for (var i = 0; i <= 10; i++) m(-200 + 40.0 * i, -200),
        for (var i = 0; i <= 10; i++) m(-200 + 40.0 * i, 200),
        for (var i = 1; i < 10; i++) m(-200, -200 + 40.0 * i),
        for (var i = 1; i < 10; i++) m(200, -200 + 40.0 * i),
        // 密集簇贴着右边界（真实绕行形态：簇点距边 ≤15m < lMax 40m，
        // tightenHull 逐点插入产生深绕行；簇若在场地中央则永不触发）。
        for (var i = 0; i < 20; i++)
          m(
            200 + 15 * cos(2 * pi * i / 20) * (1 + (i % 5) / 20),
            15 * sin(2 * pi * i / 20) * (1 + (i % 3) / 15),
          ),
      ];

      final cs = TrackToEnvelopeConverter.buildTrackDraftCandidates(pts,
          params: const TrackDraftParams.animalTrack());
      final simplified = cs.firstWhere((c) => c.method == HullMethod.concaveSimplified);
      final fine = cs.firstWhere((c) => c.method == HullMethod.concave);
      final convex = cs.firstWhere((c) => c.method == HullMethod.convex);

      expect(simplified.isAvailable, isTrue, reason: 'grid-thinned input must still form a viable hull');
      expect(simplified.result.vertices.length, lessThan(fine.result.vertices.length),
          reason: 'simplified must visibly shed the cluster detour vertices');
      expect(
        simplified.result.vertices.length,
        lessThanOrEqualTo((fine.result.vertices.length * 0.6).ceil()),
        reason: 'the difference must be visible, not marginal',
      );
      // 外轮廓保形：简化面积不低于精细的 85%（只删簇内绕行，不缩场地）。
      double areaOf(List<dynamic> vs) {
        var s = 0.0;
        for (var i = 0; i < vs.length; i++) {
          final j = (i + 1) % vs.length;
          s += (vs[i].latitude as double) * (vs[j].longitude as double) -
              (vs[j].latitude as double) * (vs[i].longitude as double);
        }
        return (s / 2).abs();
      }

      final simplifiedArea = areaOf(simplified.result.vertices);
      final fineArea = areaOf(fine.result.vertices);
      expect(simplifiedArea, greaterThanOrEqualTo(fineArea * 0.85));
      // 凸包仍是最大包络。
      expect(areaOf(convex.result.vertices), greaterThanOrEqualTo(simplifiedArea));
    });
  });
}
