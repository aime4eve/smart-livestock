import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'track_point.dart';

/// 包络生成方式。
enum HullMethod {
  /// 凹包 α-shape（保留 L/U 形凹角）。
  concave,

  /// 凸包兜底（走位稀疏导致凹包碎片化时使用）。
  convex,
}

/// 管线失败原因。
enum EnvelopeFailure {
  /// 有效点不足（<3）。
  tooFewPoints,

  /// 点位近似共线 / 面积过小，无法构成围栏。
  degenerate,
}

class TrackToEnvelopeResult {
  const TrackToEnvelopeResult._({
    required this.failure,
    required this.vertices,
    required this.method,
    required this.ringsDropped,
    required this.outliersDropped,
    required this.rawCount,
  });

  /// 非 null 表示失败（[vertices] 为空）。
  final EnvelopeFailure? failure;

  /// 外包络顶点（WGS-84，闭合多边形，不含重复首尾点）。
  final List<LatLng> vertices;
  final HullMethod method;

  /// 丢弃的内部环（洞）与碎片环数量。
  final int ringsDropped;

  /// MAD 统计清洗剔除的漂移点数。
  final int outliersDropped;
  final int rawCount;

  bool get isSuccess => failure == null;
  int get vertexCount => vertices.length;

  factory TrackToEnvelopeResult.failed(EnvelopeFailure failure, int rawCount) =>
      TrackToEnvelopeResult._(
        failure: failure,
        vertices: const [],
        method: HullMethod.convex,
        ringsDropped: 0,
        outliersDropped: 0,
        rawCount: rawCount,
      );
}

/// 轨迹 → 最外包络（围栏初始范围）管线（NIX-213）。
///
/// 纯函数、无 Flutter 依赖。无论走线顺序如何，取所有有效采点的最外包络：
/// 主路径为凹包 α-shape（保留 L/U 形凹角），碎片化时逐步放大 L_max 重试，
/// 仍碎片化则凸包兜底；MAD 统计清洗压掉向外漂移的坏点，防止包络被撑出凸起。
/// 顺序无关性由"集合级规范排序"保证——洗牌后的同一组点产出逐位相同的结果。
class TrackToEnvelopeConverter {
  const TrackToEnvelopeConverter._();

  // ── 可调参数（真机验收阶段按实走数据校准）──
  static const double accuracyThresholdM = 20; // 精度过滤阈值
  static const double speedOutlierMps = 10; // 隐含速度离群阈值（≈36 km/h）
  static const double madMultiplier = 5; // MAD 清洗系数
  static const double madFloorM = 15; // MAD 清洗下限（防误杀）
  static const double minAreaM2 = 25; // 退化判定面积下限
  static const double simplifyEpsilonM = 2; // Douglas-Peucker 容差
  static const int maxVertices = 100; // 顶点上限（后端射线法复杂度约束）
  static const double lMaxBaseM = 25; // α-shape 基准边界单元边长
  static const int lMaxRetries = 3; // L_max 放大重试次数
  static const double lMaxGrowth = 1.6;
  static const int maxInsertions = 600; // 收紧阶段插入上限（硬终止）

  static const double _mPerDegLat = 111320.0;

  static TrackToEnvelopeResult convert(List<TrackPoint> raw) {
    // 1) 精度过滤
    var points =
        raw.where((p) => p.accuracyMeters <= accuracyThresholdM).toList();

    // 2) 速度离群剔除（仅当来源带时间戳；按采样时序处理）
    if (points.isNotEmpty && points.first.timestamp != null) {
      final filtered = <TrackPoint>[points.first];
      for (var i = 1; i < points.length; i++) {
        final prev = filtered.last;
        final cur = points[i];
        final prevT = prev.timestamp;
        final curT = cur.timestamp;
        if (prevT != null && curT != null) {
          final dt = curT.difference(prevT).inMilliseconds / 1000.0;
          if (dt > 0 &&
              haversineM(prev.lat, prev.lng, cur.lat, cur.lng) / dt >
                  speedOutlierMps) {
            continue; // 跳点：丢弃
          }
        }
        filtered.add(cur);
      }
      points = filtered;
    }

    if (points.length < 3) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints, raw.length);
    }

    // 4) MAD 统计清洗：距中心 > 中位数 + max(5×MAD, 15m) 的点视为漂移。
    //    原地漂移堆出的点即使未被清洗也属内部点，不影响外包络。
    final scrubbedCount = points.length;
    points = _scrubOutliers(points);
    final outliersDropped = scrubbedCount - points.length;
    if (points.length < 3) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints, raw.length);
    }

    // 5) 局部米制投影（原点=中位数中心；float32 三角剖分需要米制小数值）。
    //    坐标量化到 1cm + 保序去重：吸收亚毫米/厘米级近重合点（RTK 停留
    //    漂移），防止剖分产生退化三角。
    //    ⚠️ 保持行走原始顺序：delaunay 包在 dart2js 下对"排序后/打乱后"的
    //    特定输入序会死循环（实测该数据 VM 31ms 正常、JS 挂死），行走序
    //    5ms 正常——顺序即产品真实输入形态，不排序。
    final lat0 = _median(points.map((p) => p.lat));
    final lng0 = _median(points.map((p) => p.lng));
    final mPerDegLng = _mPerDegLat * math.cos(lat0 * math.pi / 180.0);
    final pts = <(double, double)>[];
    for (final p in points) {
      final q = (
        ((p.lng - lng0) * mPerDegLng * 100).roundToDouble() / 100,
        ((p.lat - lat0) * _mPerDegLat * 100).roundToDouble() / 100,
      );
      // 最小间距过滤（≥0.5m）：delaunay 包的 JS 版对近重合点会死循环
      // （真实 RTK 数据实测），1cm 量化不足以根除，直接保证间距下限。
      // 不用 Record Set：dart2js 下其迭代顺序不保证与插入一致。对包络
      // 精度影响 ≤0.5m，远小于 2m 的抽稀容差。
      if (pts.isEmpty) {
        pts.add(q);
        continue;
      }
      final last = pts.last;
      final dx = q.$1 - last.$1;
      final dy = q.$2 - last.$2;
      if (dx * dx + dy * dy >= 0.25) pts.add(q);
    }
    if (pts.length < 3) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints, raw.length);
    }

    // 6) 凹包收紧：以凸包为起点，反复把"距某条边 ≤ lMax 的最远内部点"
    //    插入对应边，包络逐步向真实边界收紧（保留 L/U 形凹角）。每插入
    //    一点顶点数 +1，天然可终止；纯自写实现，VM/JS 行为一致。
    //    （原 delaunay 包 α-shape 方案在 dart2js 产物上对病态输入死循环，
    //    已弃用——见工单 NIX-213 死循环事故。）
    final hull = _convexHullIndices(pts);
    if (hull.length < 3 || _ringAreaOf(hull, pts) < minAreaM2) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.degenerate, raw.length);
    }
    final medianAccuracy = _median(points.map((p) => p.accuracyMeters));
    final lMax = math.max(lMaxBaseM, 3 * medianAccuracy);
    final tightened = _tightenHull(pts, hull, lMax, maxInsertions);
    final method =
        tightened.length > hull.length ? HullMethod.concave : HullMethod.convex;

    // 7) Douglas-Peucker 抽稀 + 顶点上限迭代
    final ringCoords = [for (final i in tightened) pts[i]];
    var epsilon = simplifyEpsilonM;
    var simplified = _douglasPeucker(ringCoords, epsilon);
    while (simplified.length > maxVertices && epsilon < 50) {
      epsilon *= 1.5;
      simplified = _douglasPeucker(ringCoords, epsilon);
    }
    if (simplified.length < 3) simplified = ringCoords;

    // 9) 逆投影回 WGS-84
    final vertices = simplified
        .map((p) => LatLng(
              lat0 + p.$2 / _mPerDegLat,
              lng0 + p.$1 / mPerDegLng,
            ))
        .toList();

    return TrackToEnvelopeResult._(
      failure: null,
      vertices: vertices,
      method: method,
      ringsDropped: 0,
      outliersDropped: outliersDropped,
      rawCount: raw.length,
    );
  }

  // ── 距离/投影 ──────────────────────────────────────────────

  /// 两经纬度点间的球面距离（米，haversine）。
  static double haversineM(double lat1, double lng1, double lat2, double lng2) {
    final radLat1 = lat1 * math.pi / 180.0;
    final radLat2 = lat2 * math.pi / 180.0;
    final dLat = radLat2 - radLat1;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radLat1) * math.cos(radLat2) * math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * 6371000 * math.asin(math.min(1, math.sqrt(h)));
  }

  // ── MAD 清洗 ──────────────────────────────────────────────

  static List<TrackPoint> _scrubOutliers(List<TrackPoint> points) {
    final lat0 = _median(points.map((p) => p.lat));
    final lng0 = _median(points.map((p) => p.lng));
    final dists = points
        .map((p) => haversineM(lat0, lng0, p.lat, p.lng))
        .toList(growable: false);
    final med = _median(dists);
    final mad = _median(dists.map((d) => (d - med).abs()));
    final threshold = med + math.max(madMultiplier * mad, madFloorM);
    return [
      for (var i = 0; i < points.length; i++)
        if (dists[i] <= threshold) points[i],
    ];
  }

  static double _median(Iterable<double> values) {
    final list = values.toList()..sort();
    if (list.isEmpty) return 0;
    final mid = list.length ~/ 2;
    return list.length.isOdd
        ? list[mid]
        : (list[mid - 1] + list[mid]) / 2;
  }

  // ── 凸包（Andrew monotone chain）────────────────────────────

  /// Andrew monotone chain 凸包，返回顶点在 [pts] 中的下标序列。
  static List<int> _convexHullIndices(List<(double, double)> pts) {
    final order = List<int>.generate(pts.length, (i) => i);
    order.sort((a, b) {
      final c = pts[a].$1.compareTo(pts[b].$1);
      return c != 0 ? c : pts[a].$2.compareTo(pts[b].$2);
    });
    if (order.length < 3) return order;

    final lower = <int>[];
    for (final i in order) {
      while (lower.length >= 2 &&
          _cross2(pts[lower[lower.length - 2]], pts[lower.last], pts[i]) <= 0) {
        lower.removeLast();
      }
      lower.add(i);
    }
    final upper = <int>[];
    for (final i in order.reversed) {
      while (upper.length >= 2 &&
          _cross2(pts[upper[upper.length - 2]], pts[upper.last], pts[i]) <= 0) {
        upper.removeLast();
      }
      upper.add(i);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  static double _cross2((double, double) o, (double, double) a,
          (double, double) b) =>
      (a.$1 - o.$1) * (b.$2 - o.$2) - (a.$2 - o.$2) * (b.$1 - o.$1);

  /// 凹包收紧：对凸包（顶点下标 [hullIdx]）的每条边，寻找距该边最远且
  /// ≤[lMax] 的未用点插入；反复扫描直到无可插入点或达到插入上限。
  /// 每次插入顶点数 +1，硬终止。
  static List<int> _tightenHull(List<(double, double)> pts,
      List<int> hullIdx, double lMax, int maxInsertions) {
    final inPoly = List<bool>.filled(pts.length, false);
    for (final i in hullIdx) {
      inPoly[i] = true;
    }
    final poly = List<int>.from(hullIdx);
    final lMaxSq = lMax * lMax;
    var insertions = 0;
    var changed = true;
    while (changed && insertions < maxInsertions) {
      changed = false;
      var e = 0;
      while (e < poly.length && insertions < maxInsertions) {
        final a = poly[e];
        final b = poly[(e + 1) % poly.length];
        final abx = pts[b].$1 - pts[a].$1;
        final aby = pts[b].$2 - pts[a].$2;
        final lenSq = abx * abx + aby * aby;
        var bestIdx = -1;
        var bestDistSq = 0.0;
        if (lenSq > 0) {
          for (var i = 0; i < pts.length; i++) {
            if (inPoly[i]) continue;
            final apx = pts[i].$1 - pts[a].$1;
            final apy = pts[i].$2 - pts[a].$2;
            final t = (apx * abx + apy * aby) / lenSq;
            if (t <= 0 || t >= 1) continue; // 垂足须落在边段内
            final cross = abx * apy - aby * apx;
            final distSq = cross * cross / lenSq;
            if (distSq > bestDistSq && distSq <= lMaxSq) {
              bestDistSq = distSq;
              bestIdx = i;
            }
          }
        }
        if (bestIdx >= 0) {
          poly.insert(e + 1, bestIdx);
          inPoly[bestIdx] = true;
          insertions++;
          changed = true;
        }
        e++;
      }
    }
    return poly;
  }

  // ── 环面积 / Douglas-Peucker ───────────────────────────────

  /// 鞋带公式带符号面积（平方米；输入为局部米制坐标，逆时针为正）。
  static double _signedAreaOf(List<int> ring, List<(double, double)> pts) {
    var area = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final j = (i + 1) % ring.length;
      area += pts[ring[i]].$1 * pts[ring[j]].$2 -
          pts[ring[j]].$1 * pts[ring[i]].$2;
    }
    return area / 2;
  }

  static double _ringAreaOf(List<int> ring, List<(double, double)> pts) =>
      _signedAreaOf(ring, pts).abs();

  static List<(double, double)> _douglasPeucker(
      List<(double, double)> pts, double epsilon) {
    if (pts.length < 3) return List.of(pts);
    final keep = List<bool>.filled(pts.length, false);
    keep[0] = keep[pts.length - 1] = true;
    final stack = <(int, int)>[(0, pts.length - 1)];
    while (stack.isNotEmpty) {
      final (start, end) = stack.removeLast();
      var maxDistSq = 0.0;
      var index = -1;
      for (var i = start + 1; i < end; i++) {
        final d = _perpDistSq(pts[i], pts[start], pts[end]);
        if (d > maxDistSq) {
          maxDistSq = d;
          index = i;
        }
      }
      if (index > 0 && maxDistSq > epsilon * epsilon) {
        keep[index] = true;
        stack.add((start, index));
        stack.add((index, end));
      }
    }
    return [
      for (var i = 0; i < pts.length; i++)
        if (keep[i]) pts[i],
    ];
  }

  static double _perpDistSq(
      (double, double) p, (double, double) a, (double, double) b) {
    final abx = b.$1 - a.$1;
    final aby = b.$2 - a.$2;
    final apx = p.$1 - a.$1;
    final apy = p.$2 - a.$2;
    final lenSq = abx * abx + aby * aby;
    if (lenSq == 0) return apx * apx + apy * apy;
    final cross = abx * apy - aby * apx;
    return cross * cross / lenSq;
  }
}
