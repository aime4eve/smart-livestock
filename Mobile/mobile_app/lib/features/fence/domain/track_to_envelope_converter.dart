import 'dart:math' as math;
import 'dart:typed_data';

import 'package:delaunay/delaunay.dart';
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

    // 5) 规范排序 + 精确去重：同一组点洗牌后产出逐位相同的结果
    points.sort((a, b) {
      final c = a.lng.compareTo(b.lng);
      return c != 0 ? c : a.lat.compareTo(b.lat);
    });
    final unique = <TrackPoint>[points.first];
    for (final p in points.skip(1)) {
      final last = unique.last;
      if (last.lat != p.lat || last.lng != p.lng) unique.add(p);
    }
    points = unique;
    if (points.length < 3) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints, raw.length);
    }

    // 6) 局部米制投影（原点=中位数中心；float32 三角剖分需要米制小数值）
    final lat0 = _median(points.map((p) => p.lat));
    final lng0 = _median(points.map((p) => p.lng));
    final mPerDegLng = _mPerDegLat * math.cos(lat0 * math.pi / 180.0);
    final pts = points
        .map((p) => ((p.lng - lng0) * mPerDegLng, (p.lat - lat0) * _mPerDegLat))
        .toList();

    // 7) 退化检查：凸包面积过小（近似共线/原地转圈）
    final hull = _convexHull(pts);
    if (hull.length < 3 || _ringArea(hull) < minAreaM2) {
      return TrackToEnvelopeResult.failed(
          EnvelopeFailure.degenerate, raw.length);
    }

    // 8) 凹包 α-shape：面遍历产出两种环——逆时针（正面积）为复杂体内面
    //    （即围栏轮廓），顺时针（负面积）为外侧面（凸包侧）。取最大内面；
    //    走位稀疏导致内面不闭合（与外面连通）时凸包兜底。多个内面 = 多片
    //    区域或凹角伪影面，取最大并计数丢弃。
    final medianAccuracy = _median(points.map((p) => p.accuracyMeters));
    var lMax = math.max(lMaxBaseM, 3 * medianAccuracy);
    List<(double, double)>? inner;
    var ringsDropped = 0;
    for (var attempt = 0; attempt <= lMaxRetries; attempt++) {
      final rings = _alphaShapeRings(pts, lMax);
      final innerRings =
          rings?.where((r) => _signedArea(r) > 0).toList() ?? const [];
      if (innerRings.isNotEmpty) {
        innerRings.sort((a, b) => _ringArea(b).compareTo(_ringArea(a)));
        inner = innerRings.first;
        // 只把"面积可比"的丢弃环计为多片区域；凹角伪影小面不告警
        final keptArea = _ringArea(innerRings.first);
        ringsDropped = innerRings
            .skip(1)
            .where((r) => _ringArea(r) >= 0.05 * keptArea)
            .length;
        break;
      }
      if (attempt == lMaxRetries) break; // 凸包兜底
      lMax *= lMaxGrowth;
    }
    final ring = inner ?? hull;
    final method = inner != null ? HullMethod.concave : HullMethod.convex;

    // 9) Douglas-Peucker 抽稀 + 顶点上限迭代
    var epsilon = simplifyEpsilonM;
    var simplified = _douglasPeucker(ring, epsilon);
    while (simplified.length > maxVertices && epsilon < 50) {
      epsilon *= 1.5;
      simplified = _douglasPeucker(ring, epsilon);
    }
    if (simplified.length < 3) simplified = ring;

    // 10) 逆投影回 WGS-84
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
      ringsDropped: ringsDropped,
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

  static List<(double, double)> _convexHull(List<(double, double)> pts) {
    final sorted = [...pts]..sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });
    if (sorted.length < 3) return sorted;

    final lower = <(double, double)>[];
    for (final p in sorted) {
      while (lower.length >= 2 && _cross2(lower[lower.length - 2],
              lower[lower.length - 1], p) <=
          0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <(double, double)>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 && _cross2(upper[upper.length - 2],
              upper[upper.length - 1], p) <=
          0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  static double _cross2((double, double) o, (double, double) a,
          (double, double) b) =>
      (a.$1 - o.$1) * (b.$2 - o.$2) - (a.$2 - o.$2) * (b.$1 - o.$1);

  // ── 凹包 α-shape ──────────────────────────────────────────

  /// Delaunay 剖分 → 保留最长边 ≤[lMax] 的三角形 → 复杂体的外边界环。
  ///
  /// 边界提取用半边面遍历（而非顶点贪心行走）：外轮廓是一个完整面，凹角处
  /// 跨角的伪影小三角形自然成为独立小面，被"取最大环"规则丢弃；洞同理。
  /// 无法剖分时返回 null。
  static List<List<(double, double)>>? _alphaShapeRings(
      List<(double, double)> pts, double lMax) {
    if (pts.length < 3) return null;
    final coords = Float32List(pts.length * 2);
    for (var i = 0; i < pts.length; i++) {
      coords[2 * i] = pts[i].$1;
      coords[2 * i + 1] = pts[i].$2;
    }
    final delaunay = Delaunay(coords);
    delaunay.update();
    final tris = delaunay.triangles;
    if (tris.isEmpty) return null;

    final triangleCount = tris.length ~/ 3;
    final kept = List<bool>.filled(triangleCount, false);
    for (var t = 0; t < triangleCount; t++) {
      final a = tris[3 * t], b = tris[3 * t + 1], c = tris[3 * t + 2];
      final maxEdgeSq = _max(
        _distSq(coords[2 * a], coords[2 * a + 1], coords[2 * b],
            coords[2 * b + 1]),
        _distSq(coords[2 * b], coords[2 * b + 1], coords[2 * c],
            coords[2 * c + 1]),
        _distSq(coords[2 * c], coords[2 * c + 1], coords[2 * a],
            coords[2 * a + 1]),
      );
      kept[t] = maxEdgeSq <= lMax * lMax;
    }

    // 有向边 → 半边下标；twin = 方向相反的那条半边
    final dirToEdge = <int, int>{};
    for (var e = 0; e < tris.length; e++) {
      dirToEdge[_edgeKey(tris[e], tris[_nextHalfedge(e)])] = e;
    }

    // 半边在 α 复杂体边界上 ⟺ 所在三角形被保留，且对面三角形被剔除或不存在
    final isBoundary = List<bool>.filled(tris.length, false);
    for (var e = 0; e < tris.length; e++) {
      if (!kept[e ~/ 3]) continue;
      final twin = dirToEdge[_edgeKey(tris[_nextHalfedge(e)], tris[e])];
      if (twin == null || !kept[twin ~/ 3]) isBoundary[e] = true;
    }

    // 面遍历：从边界半边出发，绕顶点经相邻保留三角形旋转（twin+next），
    // 直到遇到下一条边界半边——这是三角剖分面追踪的标准走法。
    final visited = List<bool>.filled(tris.length, false);
    final rings = <List<(double, double)>>[];
    for (var e = 0; e < tris.length; e++) {
      if (!isBoundary[e] || visited[e]) continue;
      final ringIdx = <int>[];
      var cur = e;
      do {
        visited[cur] = true;
        ringIdx.add(tris[cur]);
        cur = _advanceAlongFace(tris, kept, dirToEdge, cur);
      } while (cur != e);
      if (ringIdx.length >= 3) {
        rings.add([
          for (final i in ringIdx) (coords[2 * i], coords[2 * i + 1]),
        ]);
      }
    }
    return rings;
  }

  /// 从面边界半边 [cur] 推进到同一面上的下一条边界半边。
  ///
  /// 先转到同三角形的下一条半边；若它不是边界边，则跨 twin 进入相邻保留
  /// 三角形继续绕同一顶点旋转，直到命中边界边。
  static int _advanceAlongFace(
      Uint32List tris,
      List<bool> kept,
      Map<int, int> dirToEdge,
      int cur) {
    var cand = _nextHalfedge(cur);
    while (!isBoundaryHalfedge(tris, kept, dirToEdge, cand)) {
      final twin = dirToEdge[_edgeKey(tris[_nextHalfedge(cand)], tris[cand])];
      if (twin == null || !kept[twin ~/ 3]) {
        // 理论不可达（非边界 ⟹ twin 保留）；兜底返回避免死循环
        return cand;
      }
      cand = _nextHalfedge(twin);
    }
    return cand;
  }

  static bool isBoundaryHalfedge(Uint32List tris, List<bool> kept,
      Map<int, int> dirToEdge, int e) {
    if (!kept[e ~/ 3]) return false;
    final twin = dirToEdge[_edgeKey(tris[_nextHalfedge(e)], tris[e])];
    return twin == null || !kept[twin ~/ 3];
  }

  static int _nextHalfedge(int e) => (e % 3 == 2) ? e - 2 : e + 1;

  static int _edgeKey(int a, int b) => a * 100000 + b;

  static double _distSq(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = ay - by;
    return dx * dx + dy * dy;
  }

  static double _max(double a, double b, double c) =>
      math.max(a, math.max(b, c));

  // ── 环面积 / Douglas-Peucker ───────────────────────────────

  /// 鞋带公式带符号面积（平方米；输入为局部米制坐标，逆时针为正）。
  static double _signedArea(List<(double, double)> ring) {
    var area = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final j = (i + 1) % ring.length;
      area += ring[i].$1 * ring[j].$2 - ring[j].$1 * ring[i].$2;
    }
    return area / 2;
  }

  /// 鞋带公式面积（平方米；输入已是局部米制坐标）。
  static double _ringArea(List<(double, double)> ring) =>
      _signedArea(ring).abs();

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
