import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'roaming_trim.dart';
import 'track_draft_params.dart';
import 'track_point.dart';

/// 包络生成方式。
enum HullMethod {
  /// 凹包 α-shape（保留 L/U 形凹角）。
  concave,

  /// 凸包兜底（走位稀疏导致凹包碎片化时使用）。
  convex,

  /// 凹包 + 外轮廓面积贡献精简：在凹包基础上迭代删除"移除后环面积变化
  /// < tolPct"的顶点（固定初始环面积为基准），产出更简洁的围栏草图。
  concaveSimplified,
}

/// `generationMetadata.hullMethod` 序列化键（与 controller/UI 的显示名映射
/// 共用同一事实源，避免散落的三元表达式）。
extension HullMethodMetadataKey on HullMethod {
  String get metadataKey => switch (this) {
        HullMethod.concave => 'concave',
        HullMethod.convex => 'convex',
        HullMethod.concaveSimplified => 'concave_simplified',
      };
}

/// 多候选包络（预览三算法切换，spec 修订 v2.1）：同一份清洗后的点集跑三种
/// 包络策略，各自独立抽稀与失败判定；[isAvailable] 为 false 的候选在预览
/// 界面置灰不可选。
class TrackEnvelopeCandidate {
  const TrackEnvelopeCandidate({required this.method, required this.result});

  /// 候选算法标识（与 [TrackToEnvelopeResult.method] 一致）。
  final HullMethod method;

  /// 该算法的完整管线结果（失败时 [TrackToEnvelopeResult.failure] 非 null）。
  final TrackToEnvelopeResult result;

  bool get isAvailable => result.isSuccess;
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
    required this.roamingTrimmed,
    required this.trimmedPoints,
    required this.accuracyDropped,
    required this.speedDropped,
    required this.remainingValid,
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

  /// 漫游截断剔除的点数（默认参数组恒为 0）。
  final int roamingTrimmed;

  /// 漫游截断剔除的点集（仅供预览琥珀叠加展示，不进包络）。
  final List<TrackPoint> trimmedPoints;

  /// Points dropped by the accuracy filter (diagnostics for the preview
  /// failure strip; 0 for results built before the filter stage ran).
  final int accuracyDropped;

  /// Points dropped by the implied-speed outlier filter (diagnostics).
  final int speedDropped;

  /// Points surviving the cleaning stages at the moment the pipeline
  /// finished (success) or bailed out (failure diagnostics).
  final int remainingValid;

  bool get isSuccess => failure == null;
  int get vertexCount => vertices.length;

  factory TrackToEnvelopeResult.failed(
    EnvelopeFailure failure,
    int rawCount, {
    int accuracyDropped = 0,
    int speedDropped = 0,
    int roamingTrimmed = 0,
    int outliersDropped = 0,
    int remainingValid = 0,
  }) =>
      TrackToEnvelopeResult._(
        failure: failure,
        vertices: const [],
        method: HullMethod.convex,
        ringsDropped: 0,
        outliersDropped: outliersDropped,
        rawCount: rawCount,
        roamingTrimmed: roamingTrimmed,
        trimmedPoints: const [],
        accuracyDropped: accuracyDropped,
        speedDropped: speedDropped,
        remainingValid: remainingValid,
      );
}

/// 清洗段产物（convert 与 buildTrackDraftCandidates 共享一次执行）：
/// 清洗统计三候选一致，不重复计算。
class _CleanedTrack {
  const _CleanedTrack({
    required this.points,
    required this.pts,
    required this.lat0,
    required this.lng0,
    required this.mPerDegLng,
    required this.accuracyDropped,
    required this.speedDropped,
    required this.roamingTrimmed,
    required this.trimmedPoints,
    required this.outliersDropped,
  });

  /// MAD 清洗后的有效点（保持行走原始顺序）。
  final List<TrackPoint> points;

  /// 米制投影坐标（1cm 量化 + 0.5m 保序去重后）。
  final List<(double, double)> pts;

  /// 投影原点与经度比例（逆投影共用）。
  final double lat0;
  final double lng0;
  final double mPerDegLng;

  final int accuracyDropped;
  final int speedDropped;
  final int roamingTrimmed;
  final List<TrackPoint> trimmedPoints;
  final int outliersDropped;
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
  /// 面积贡献精简容差（占初始环面积比例）：删除某顶点后环面积相对固定
  /// 基准的变化 < 该比例时该顶点可删（concaveSimplified 候选专用）。作为
  /// [TrackDraftParams.areaTrimPct] 两参数组的默认值；实际消费的是参数
  /// 字段，此处仅作单一事实源。
  static const double areaContributionTolPct = 0.005;

  static const double _mPerDegLat = 111320.0;

  static TrackToEnvelopeResult convert(List<TrackPoint> raw,
      {TrackDraftParams? params}) {
    // Default bundle == current GPX/RTK values: bit-identical output.
    final p = params ?? const TrackDraftParams.gpxDefault();
    final (failure, cleaned) = _cleanSegments(raw, p);
    if (failure != null || cleaned == null) {
      return failure ??
          TrackToEnvelopeResult.failed(EnvelopeFailure.tooFewPoints, raw.length);
    }
    final pts = cleaned.pts;

    // 6) 凹包收紧：以凸包为起点，反复把"距某条边 ≤ lMax 的最远内部点"
    //    插入对应边，包络逐步向真实边界收紧（保留 L/U 形凹角）。每插入
    //    一点顶点数 +1，天然可终止；纯自写实现，VM/JS 行为一致。
    //    （原 delaunay 包 α-shape 方案在 dart2js 产物上对病态输入死循环，
    //    已弃用——见工单 NIX-213 死循环事故。）
    final hull = _convexHullIndices(pts);
    if (hull.length < 3 || _ringAreaOf(hull, pts) < p.minAreaM2) {
      return TrackToEnvelopeResult.failed(
        EnvelopeFailure.degenerate,
        raw.length,
        accuracyDropped: cleaned.accuracyDropped,
        speedDropped: cleaned.speedDropped,
        roamingTrimmed: cleaned.roamingTrimmed,
        outliersDropped: cleaned.outliersDropped,
        remainingValid: pts.length,
      );
    }
    final medianAccuracy = _median(cleaned.points.map((q) => q.accuracyMeters));
    final lMax = math.max(p.lMaxBaseM, 3 * medianAccuracy);
    final tightened = _tightenHull(pts, hull, lMax, p.maxInsertions);
    final method =
        tightened.length > hull.length ? HullMethod.concave : HullMethod.convex;

    // 7) Douglas-Peucker 抽稀 + 顶点上限迭代
    final ringCoords = [for (final i in tightened) pts[i]];
    final simplified = _simplifyRing(ringCoords, p);

    // 9) 逆投影回 WGS-84
    final vertices = _projectBack(simplified, cleaned);

    return TrackToEnvelopeResult._(
      failure: null,
      vertices: vertices,
      method: method,
      ringsDropped: 0,
      outliersDropped: cleaned.outliersDropped,
      rawCount: raw.length,
      roamingTrimmed: cleaned.roamingTrimmed,
      trimmedPoints: cleaned.trimmedPoints,
      accuracyDropped: cleaned.accuracyDropped,
      speedDropped: cleaned.speedDropped,
      remainingValid: cleaned.points.length,
    );
  }

  /// 三候选包络（预览算法切换，spec 修订 v2.1）：清洗段只跑一次（与
  /// [convert] 完全同序），三候选共享同一份清洗统计；各自独立 DP 抽稀与
  /// 失败判定（顶点 <3 或面积 <minAreaM2 → 该候选标 failure，不抛）。
  /// 固定返回顺序 [concaveSimplified, concave, convex]。
  static List<TrackEnvelopeCandidate> buildTrackDraftCandidates(
      List<TrackPoint> raw,
      {TrackDraftParams? params}) {
    const order = [
      HullMethod.concaveSimplified,
      HullMethod.concave,
      HullMethod.convex,
    ];
    final p = params ?? const TrackDraftParams.gpxDefault();
    final (failure, cleaned) = _cleanSegments(raw, p);
    if (failure != null || cleaned == null) {
      final shared = failure ??
          TrackToEnvelopeResult.failed(EnvelopeFailure.tooFewPoints, raw.length);
      return [
        for (final m in order) TrackEnvelopeCandidate(method: m, result: shared),
      ];
    }
    final pts = cleaned.pts;

    final hull = _convexHullIndices(pts);
    if (hull.length < 3 || _ringAreaOf(hull, pts) < p.minAreaM2) {
      // 凸包即退化：三候选同败，共享清洗诊断。
      final shared = TrackToEnvelopeResult.failed(
        EnvelopeFailure.degenerate,
        raw.length,
        accuracyDropped: cleaned.accuracyDropped,
        speedDropped: cleaned.speedDropped,
        roamingTrimmed: cleaned.roamingTrimmed,
        outliersDropped: cleaned.outliersDropped,
        remainingValid: pts.length,
      );
      return [
        for (final m in order) TrackEnvelopeCandidate(method: m, result: shared),
      ];
    }

    final medianAccuracy = _median(cleaned.points.map((q) => q.accuracyMeters));
    final lMax = math.max(p.lMaxBaseM, 3 * medianAccuracy);
    final tightened = _tightenHull(pts, hull, lMax, p.maxInsertions);

    // concaveSimplified 独立输入：先做网格抽稀再收紧。密集 GPS 簇会让
    // 边界在簇内深绕行（进→出→进的自交形态），逐点面积贡献精简删不动
    // （删任一单点都跨掉大块面积）——网格把簇压到每格 1 点（保留离质心
    // 最远的点=保外轮廓），绕行从源头消失。精细/凸包分支不受影响。
    List<(double, double)> simplifiedPts = pts;
    var simplifiedRing = tightened;
    if (p.clusterCellM != null) {
      final thinned = _gridThinPoints(pts, p.clusterCellM!);
      if (thinned.length >= 3) {
        final subHull = _convexHullIndices(thinned);
        if (subHull.length >= 3 &&
            _ringAreaOf(subHull, thinned) >= p.minAreaM2) {
          simplifiedPts = thinned;
          simplifiedRing = _tightenHull(thinned, subHull, lMax, p.maxInsertions);
        }
      }
    }

    return [
      _finishCandidate(
        method: HullMethod.concaveSimplified,
        baseRing: simplifiedRing,
        pts: simplifiedPts,
        cleaned: cleaned,
        rawCount: raw.length,
        p: p,
        areaSimplify: true,
      ),
      _finishCandidate(
        method: HullMethod.concave,
        baseRing: tightened,
        pts: pts,
        cleaned: cleaned,
        rawCount: raw.length,
        p: p,
      ),
      _finishCandidate(
        method: HullMethod.convex,
        baseRing: hull,
        pts: pts,
        cleaned: cleaned,
        rawCount: raw.length,
        p: p,
      ),
    ];
  }

  /// 单候选收尾：DP 抽稀（+可选面积贡献精简）→ 退化判定（顶点 <3 或
  /// 面积 <minAreaM2 → 标 failure）→ 逆投影。DP 输出经下标追溯回 [pts]
  /// 顶点，与 convert 的坐标版抽稀逐位一致。
  static TrackEnvelopeCandidate _finishCandidate({
    required HullMethod method,
    required List<int> baseRing,
    required List<(double, double)> pts,
    required _CleanedTrack cleaned,
    required int rawCount,
    required TrackDraftParams p,
    bool areaSimplify = false,
  }) {
    final baseCoords = [for (final i in baseRing) pts[i]];
    final keptPositions = _simplifyRingIndices(baseCoords, p);
    var ring = [for (final pos in keptPositions) baseRing[pos]];
    if (areaSimplify) {
      ring = simplifyByAreaContribution(ring, pts, p.areaTrimPct);
    }
    if (ring.length < 3 || _ringAreaOf(ring, pts) < p.minAreaM2) {
      return TrackEnvelopeCandidate(
        method: method,
        result: TrackToEnvelopeResult.failed(
          EnvelopeFailure.degenerate,
          rawCount,
          accuracyDropped: cleaned.accuracyDropped,
          speedDropped: cleaned.speedDropped,
          roamingTrimmed: cleaned.roamingTrimmed,
          outliersDropped: cleaned.outliersDropped,
          remainingValid: pts.length,
        ),
      );
    }
    final vertices = [
      for (final i in ring)
        LatLng(
          cleaned.lat0 + pts[i].$2 / _mPerDegLat,
          cleaned.lng0 + pts[i].$1 / cleaned.mPerDegLng,
        ),
    ];
    return TrackEnvelopeCandidate(
      method: method,
      result: TrackToEnvelopeResult._(
        failure: null,
        vertices: vertices,
        method: method,
        ringsDropped: 0,
        outliersDropped: cleaned.outliersDropped,
        rawCount: rawCount,
        roamingTrimmed: cleaned.roamingTrimmed,
        trimmedPoints: cleaned.trimmedPoints,
        accuracyDropped: cleaned.accuracyDropped,
        speedDropped: cleaned.speedDropped,
        remainingValid: cleaned.points.length,
      ),
    );
  }

  /// 面积贡献精简（concaveSimplified 候选专用；纯同步、无 IO）：以初始环
  /// 的 |面积| 为固定基准（每次迭代不重置，防止基准逐步缩小导致失真），
  /// 迭代删除 ΔArea 最小且 < [tolPct] 的顶点；环长 ≤3 或最小 ΔArea ≥
  /// tolPct 时终止。O(n²) 每轮 × 最多 n 轮；调用方输入经 DP 上限后
  /// ≤100 顶点，开销可忽略。公开仅供单测直接断言精简行为。
  static List<int> simplifyByAreaContribution(
      List<int> ring, List<(double, double)> pts, double tolPct) {
    if (ring.length <= 3) return List.of(ring);
    final baseArea = _ringAreaOf(ring, pts);
    if (baseArea <= 0) return List.of(ring); // 退化环不精简
    final current = List<int>.from(ring);
    while (current.length > 3) {
      var bestPos = -1;
      var bestDelta = double.infinity;
      for (var i = 0; i < current.length; i++) {
        final without = [
          for (var k = 0; k < current.length; k++)
            if (k != i) current[k],
        ];
        final delta =
            (_ringAreaOf(without, pts) - baseArea).abs() / baseArea;
        if (delta < bestDelta) {
          bestDelta = delta;
          bestPos = i;
        }
      }
      if (bestPos < 0 || bestDelta >= tolPct) break;
      current.removeAt(bestPos);
    }
    return current;
  }

  // ── 清洗段（convert / buildTrackDraftCandidates 共用） ──────────────

  /// 清洗段：精度过滤 → 速度离群 → 漫游截断（仅 quantile 非 null）→
  /// MAD → 米制投影。代码自 convert 原样抽出，两条入口逐位一致；成功
  /// 返回 (null, cleaned)，中途失败返回 (失败结果, null)。
  static (TrackToEnvelopeResult?, _CleanedTrack?) _cleanSegments(
      List<TrackPoint> raw, TrackDraftParams p) {
    // 1) 精度过滤
    // Local (not the closure-captured parameter) so type promotion holds
    // inside the filtering closures below.
    var points =
        raw.where((pt) => pt.accuracyMeters <= p.accuracyThresholdM).toList();
    final accuracyDropped = raw.length - points.length;

    // 2) 速度离群剔除（仅当来源带时间戳；按采样时序处理）
    var speedDropped = 0;
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
                  p.speedOutlierMps) {
            continue; // 跳点：丢弃
          }
        }
        filtered.add(cur);
      }
      speedDropped = points.length - filtered.length;
      points = filtered;
    }

    // 3) 95% 漫游截断（仅动物轨迹参数组；精度过滤+速度离群之后、MAD 之前）。
    var roamingTrimmed = 0;
    var trimmedPoints = const <TrackPoint>[];
    final quantile = p.roamingQuantile;
    if (quantile != null) {
      final trim = RoamingTrim.trim(points, quantile);
      roamingTrimmed = trim.trimmed.length;
      trimmedPoints = trim.trimmed;
      points = trim.kept;
    }

    if (points.length < 3) {
      return (
        TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints,
          raw.length,
          accuracyDropped: accuracyDropped,
          speedDropped: speedDropped,
          roamingTrimmed: roamingTrimmed,
          remainingValid: points.length,
        ),
        null,
      );
    }

    // 4) MAD 统计清洗：距中心 > 中位数 + max(5×MAD, 15m) 的点视为漂移。
    //    原地漂移堆出的点即使未被清洗也属内部点，不影响外包络。
    final scrubbedCount = points.length;
    points = _scrubOutliers(points, p);
    final outliersDropped = scrubbedCount - points.length;
    if (points.length < 3) {
      return (
        TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints,
          raw.length,
          accuracyDropped: accuracyDropped,
          speedDropped: speedDropped,
          roamingTrimmed: roamingTrimmed,
          outliersDropped: outliersDropped,
          remainingValid: points.length,
        ),
        null,
      );
    }

    // 5) 局部米制投影（原点=中位数中心；float32 三角剖分需要米制小数值）。
    //    坐标量化到 1cm + 保序去重：吸收亚毫米/厘米级近重合点（RTK 停留
    //    漂移），防止剖分产生退化三角。
    //    ⚠️ 保持行走原始顺序：delaunay 包在 dart2js 下对"排序后/打乱后"的
    //    特定输入序会死循环（实测该数据 VM 31ms 正常、JS 挂死），行走序
    //    5ms 正常——顺序即产品真实输入形态，不排序。
    final lat0 = _median(points.map((q) => q.lat));
    final lng0 = _median(points.map((q) => q.lng));
    final mPerDegLng = _mPerDegLat * math.cos(lat0 * math.pi / 180.0);
    final pts = <(double, double)>[];
    for (final q in points) {
      final rec = (
        ((q.lng - lng0) * mPerDegLng * 100).roundToDouble() / 100,
        ((q.lat - lat0) * _mPerDegLat * 100).roundToDouble() / 100,
      );
      // 最小间距过滤（≥0.5m）：delaunay 包的 JS 版对近重合点会死循环
      // （真实 RTK 数据实测），1cm 量化不足以根除，直接保证间距下限。
      // 不用 Record Set：dart2js 下其迭代顺序不保证与插入一致。对包络
      // 精度影响 ≤0.5m，远小于 2m 的抽稀容差。
      if (pts.isEmpty) {
        pts.add(rec);
        continue;
      }
      final last = pts.last;
      final dx = rec.$1 - last.$1;
      final dy = rec.$2 - last.$2;
      if (dx * dx + dy * dy >= 0.25) pts.add(rec);
    }
    if (pts.length < 3) {
      return (
        TrackToEnvelopeResult.failed(
          EnvelopeFailure.tooFewPoints,
          raw.length,
          accuracyDropped: accuracyDropped,
          speedDropped: speedDropped,
          roamingTrimmed: roamingTrimmed,
          outliersDropped: outliersDropped,
          remainingValid: pts.length,
        ),
        null,
      );
    }

    return (
      null,
      _CleanedTrack(
        points: points,
        pts: pts,
        lat0: lat0,
        lng0: lng0,
        mPerDegLng: mPerDegLng,
        accuracyDropped: accuracyDropped,
        speedDropped: speedDropped,
        roamingTrimmed: roamingTrimmed,
        trimmedPoints: trimmedPoints,
        outliersDropped: outliersDropped,
      ),
    );
  }

  /// 逆投影回 WGS-84（环坐标 → 经纬度，共享投影原点与比例）。
  static List<LatLng> _projectBack(
      List<(double, double)> ring, _CleanedTrack cleaned) => [
        for (final q in ring)
          LatLng(
            cleaned.lat0 + q.$2 / _mPerDegLat,
            cleaned.lng0 + q.$1 / cleaned.mPerDegLng,
          ),
      ];

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

  static List<TrackPoint> _scrubOutliers(
      List<TrackPoint> points, TrackDraftParams params) {
    final lat0 = _median(points.map((p) => p.lat));
    final lng0 = _median(points.map((p) => p.lng));
    final dists = points
        .map((p) => haversineM(lat0, lng0, p.lat, p.lng))
        .toList(growable: false);
    final med = _median(dists);
    final mad = _median(dists.map((d) => (d - med).abs()));
    final threshold =
        med + math.max(params.madMultiplier * mad, params.madFloorM);
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

  // ── 环面积 / Douglas-Peucker ─────────────────────────────

  /// 网格抽稀：[cellM] 米网格每格保留离全点集质心最远的 1 点（外轮廓
  /// 优先），输出按坐标排序保证确定性。格以质心为原点对齐——小于一格
  /// 的点集整体落在同一格（thinned=1 → 上层 fallback 原路径），不会因
  /// 坐标负零界被人为切成多格。只作用于 concaveSimplified 候选的输入
  /// （见 buildTrackDraftCandidates 内注释）。
  static List<(double, double)> _gridThinPoints(
      List<(double, double)> pts, double cellM) {
    var sx = 0.0;
    var sy = 0.0;
    for (final q in pts) {
      sx += q.$1;
      sy += q.$2;
    }
    final cx = sx / pts.length;
    final cy = sy / pts.length;
    final best = <(int, int), (double, double)>{};
    final bestDistSq = <(int, int), double>{};
    for (final q in pts) {
      final dx = q.$1 - cx;
      final dy = q.$2 - cy;
      final key = ((dx / cellM).floor(), (dy / cellM).floor());
      final d = dx * dx + dy * dy;
      final cur = bestDistSq[key];
      if (cur == null || d > cur) {
        bestDistSq[key] = d;
        best[key] = q;
      }
    }
    final out = best.values.toList();
    out.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
    return out;
  }

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

  /// Douglas-Peucker 抽稀 + 顶点上限迭代（convert / candidates 共用）。
  static List<(double, double)> _simplifyRing(
          List<(double, double)> ringCoords, TrackDraftParams p) =>
      [for (final i in _simplifyRingIndices(ringCoords, p)) ringCoords[i]];

  /// 上面的下标版：返回 [ringCoords] 中被保留的位置，供 candidates 把
  /// 抽稀结果追溯回原环顶点（面积精简需要在 [pts] 下标空间进行）。
  static List<int> _simplifyRingIndices(
      List<(double, double)> ringCoords, TrackDraftParams p) {
    var epsilon = p.simplifyEpsilonM;
    var kept = _douglasPeuckerIndices(ringCoords, epsilon);
    while (kept.length > p.maxVertices && epsilon < 50) {
      epsilon *= 1.5;
      kept = _douglasPeuckerIndices(ringCoords, epsilon);
    }
    if (kept.length < 3) {
      return List<int>.generate(ringCoords.length, (i) => i);
    }
    return kept;
  }

  /// DP 保留位置版：返回 [pts] 中被保留的下标；映射回坐标即抽稀后的环。
  static List<int> _douglasPeuckerIndices(
      List<(double, double)> pts, double epsilon) {
    if (pts.length < 3) {
      return List<int>.generate(pts.length, (i) => i);
    }
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
        if (keep[i]) i,
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
