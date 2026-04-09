import 'package:smart_livestock_demo/core/models/twin_models.dart';

class TwinSeed {
  const TwinSeed._();

  static DateTime _t(int year, int month, int day, int h, [int m = 0]) =>
      DateTime.utc(year, month, day, h, m);

  static List<TemperatureRecord> _buildTemps(
    String id,
    double baseline,
    String status,
  ) {
    final end = _t(2026, 4, 7, 10, 0);
    final records = <TemperatureRecord>[];
    for (var i = 0; i < 48; i++) {
      final ts = end.subtract(Duration(hours: 47 - i));
      double temp = baseline + (i % 4) * 0.04;
      if (status == 'critical' && i > 30) {
        temp += 0.8 + i * 0.02;
      } else if (status == 'warning' && i > 35) {
        temp += 0.45;
      }
      records.add(
        TemperatureRecord(livestockId: id, temperature: temp, timestamp: ts),
      );
    }
    return records;
  }

  static List<MotilityRecord> _buildMotility(
    String id,
    double baseline,
    String status,
  ) {
    final end = _t(2026, 4, 7, 10, 0);
    final records = <MotilityRecord>[];
    for (var i = 0; i < 24; i++) {
      final ts = end.subtract(Duration(hours: 23 - i));
      double f = baseline + (i % 3) * 0.05;
      double inten = 0.75;
      if (status == 'critical' && i > 18) {
        f = 0;
        inten = 0;
      } else if (status == 'warning') {
        f *= 0.55;
      }
      records.add(
        MotilityRecord(
          livestockId: id,
          frequency: f,
          intensity: inten,
          timestamp: ts,
        ),
      );
    }
    return records;
  }

  static List<EstrusTrendPoint> _trend7d(int base) {
    return List.generate(7, (i) {
      final s = base + i * 11;
      return EstrusTrendPoint(
        score: s.toDouble(),
        timestamp: _t(2026, 4, 1 + i, 10, 0),
      );
    });
  }

  static final List<TemperatureBaseline> feverBaselines = [
    TemperatureBaseline(
      livestockId: '3872',
      baselineTemp: 38.6,
      threshold: 39.1,
      recent72h: _buildTemps('3872', 38.6, 'critical'),
      status: 'critical',
      conclusion: '温度升高+活动量下降，高概率感染，建议隔离检查',
    ),
    TemperatureBaseline(
      livestockId: '5621',
      baselineTemp: 38.5,
      threshold: 39.0,
      recent72h: _buildTemps('5621', 38.5, 'warning'),
      status: 'warning',
      conclusion: '体温轻度升高，建议持续观察饮水与采食',
    ),
    TemperatureBaseline(
      livestockId: '3400',
      baselineTemp: 38.4,
      threshold: 38.9,
      recent72h: _buildTemps('3400', 38.4, 'normal'),
      status: 'normal',
      conclusion: '体温稳定，未见异常波动',
    ),
    TemperatureBaseline(
      livestockId: '3401',
      baselineTemp: 38.5,
      threshold: 39.0,
      recent72h: _buildTemps('3401', 38.45, 'normal'),
      status: 'normal',
      conclusion: '个体状态良好',
    ),
    TemperatureBaseline(
      livestockId: '3402',
      baselineTemp: 38.3,
      threshold: 38.8,
      recent72h: _buildTemps('3402', 38.35, 'normal'),
      status: 'normal',
      conclusion: '未见发热迹象',
    ),
  ];

  static final List<DigestiveHealth> digestiveItems = [
    DigestiveHealth(
      livestockId: '1205',
      motilityBaseline: 1.5,
      status: 'critical',
      advice: '蠕动完全停止，疑似瘤胃臌气，需立即处理',
      recent24h: _buildMotility('1205', 1.45, 'critical'),
    ),
    DigestiveHealth(
      livestockId: '3403',
      motilityBaseline: 1.4,
      status: 'warning',
      advice: '蠕动频率下降，建议检查饲粮与饮水',
      recent24h: _buildMotility('3403', 1.35, 'warning'),
    ),
    DigestiveHealth(
      livestockId: '3404',
      motilityBaseline: 1.5,
      status: 'normal',
      advice: '蠕动节律正常',
      recent24h: _buildMotility('3404', 1.48, 'normal'),
    ),
    DigestiveHealth(
      livestockId: '3405',
      motilityBaseline: 1.45,
      status: 'normal',
      advice: '消化系统运行稳定',
      recent24h: _buildMotility('3405', 1.46, 'normal'),
    ),
  ];

  static final List<EstrusScore> estrusItems = [
    EstrusScore(
      livestockId: '2158',
      score: 92,
      stepIncreasePercent: 320,
      tempDelta: 0.4,
      distanceDelta: 3.5,
      timestamp: _t(2026, 4, 7, 9, 58),
      advice: '步数增加320%，建议6小时内配种',
      trend7d: _trend7d(12),
    ),
    EstrusScore(
      livestockId: '2160',
      score: 78,
      stepIncreasePercent: 180,
      tempDelta: 0.2,
      distanceDelta: 2.1,
      timestamp: _t(2026, 4, 7, 8, 12),
      advice: '发情信号增强，建议12小时内关注配种窗口',
      trend7d: _trend7d(20),
    ),
    EstrusScore(
      livestockId: '2162',
      score: 42,
      stepIncreasePercent: 40,
      tempDelta: 0.05,
      distanceDelta: 0.4,
      timestamp: _t(2026, 4, 6, 16, 0),
      advice: '暂未达到配种建议阈值',
      trend7d: _trend7d(8),
    ),
  ];

  static final HerdHealthMetrics epidemicMetrics = HerdHealthMetrics(
    avgTemperature: 38.7,
    avgActivity: 72.5,
    abnormalRate: 0.9,
    totalLivestock: 3847,
    abnormalCount: 35,
  );

  static final List<ContactTrace> epidemicContacts = [
    ContactTrace(
      fromId: '3872',
      toId: '3901',
      lastContact: _t(2026, 4, 7, 8, 30),
      proximity: 5.2,
    ),
    ContactTrace(
      fromId: '3901',
      toId: '3920',
      lastContact: _t(2026, 4, 7, 7, 10),
      proximity: 8.1,
    ),
    ContactTrace(
      fromId: '3872',
      toId: '3400',
      lastContact: _t(2026, 4, 6, 18, 0),
      proximity: 12.0,
    ),
  ];

  static TwinOverviewStats get overviewStats => TwinOverviewStats(
        totalLivestock: 3847,
        healthyRate: 99.1,
        alertCount: 35,
        criticalCount: 3,
        deviceOnlineRate: 97.8,
        livestockCaption: '牛 2,156 / 羊 1,691',
        alertCaption: '紧急 3 / 一般 32',
        healthCaption: '健康个体 3,812',
        deviceCaption: '传感器 1,247 在线',
        healthTrend: '+0.3%',
        livestockTrend: '+12 本周新增',
      );

  static TwinSceneSummary get sceneSummary => TwinSceneSummary(
        fever: SceneSummaryFever(abnormalCount: 3, criticalCount: 2),
        digestive: SceneSummaryDigestive(abnormalCount: 1, watchCount: 5),
        estrus: SceneSummaryEstrus(highScoreCount: 2, breedingAdvice: true),
        epidemic: SceneSummaryEpidemic(status: 'normal', abnormalRate: 0.9),
      );

  static List<TwinPendingTask> get pendingTasks => [
        const TwinPendingTask(
          id: 'pt1',
          title: '牛#3872 体温紧急',
          subtitle: '较基线升高 1.2°C · 建议立即复核',
          routePath: '/twin/fever/3872',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt2',
          title: '牛#1205 蠕动停止',
          subtitle: '消化系统 · 需现场处置',
          routePath: '/twin/digestive/1205',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt3',
          title: '牛#2158 发情高分',
          subtitle: '评分 92 · 建议6小时内配种',
          routePath: '/twin/estrus/2158',
          severity: 'warning',
        ),
      ];
}
