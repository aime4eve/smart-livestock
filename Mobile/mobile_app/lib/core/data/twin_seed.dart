import 'package:smart_livestock_demo/core/data/generators/estrus_score_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/motility_generator.dart';
import 'package:smart_livestock_demo/core/data/generators/temperature_generator.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';

class TwinSeed {
  const TwinSeed._();

  static final _tempGen = TemperatureGenerator(seed: 42);
  static final _motilityGen = MotilityGenerator(seed: 42);
  static final _estrusGen = EstrusScoreGenerator(seed: 42);

  static final DateTime _start = DateTime.utc(2026, 4, 1);
  static final DateTime _end = DateTime.utc(2026, 4, 8);

  static final List<TemperatureBaseline> feverBaselines =
      _buildFeverBaselines();

  static final List<DigestiveHealth> digestiveItems = _buildDigestiveItems();

  static final List<EstrusScore> estrusItems = _buildEstrusItems();

  static final HerdHealthMetrics epidemicMetrics = HerdHealthMetrics(
    avgTemperature: 38.7,
    avgActivity: 72.5,
    abnormalRate: 6.0,
    totalLivestock: 50,
    abnormalCount: 3,
  );

  static final List<ContactTrace> epidemicContacts = [
    ContactTrace(
      fromId: '0048',
      toId: '0049',
      lastContact: DateTime.utc(2026, 4, 7, 8, 30),
      proximity: 5.2,
    ),
    ContactTrace(
      fromId: '0049',
      toId: '0050',
      lastContact: DateTime.utc(2026, 4, 7, 7, 10),
      proximity: 8.1,
    ),
    ContactTrace(
      fromId: '0048',
      toId: '0001',
      lastContact: DateTime.utc(2026, 4, 6, 18, 0),
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
        fever: SceneSummaryFever(abnormalCount: 5, criticalCount: 3),
        digestive: SceneSummaryDigestive(abnormalCount: 2, watchCount: 3),
        estrus: SceneSummaryEstrus(highScoreCount: 2, breedingAdvice: true),
        epidemic: SceneSummaryEpidemic(status: 'normal', abnormalRate: 6.0),
      );

  static List<TwinPendingTask> get pendingTasks => [
        const TwinPendingTask(
          id: 'pt1',
          title: '牛#0048 体温紧急',
          subtitle: '较基线升高 1.2°C · 建议立即复核',
          routePath: '/twin/fever/0048',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt2',
          title: '牛#0049 蠕动停止',
          subtitle: '消化系统 · 需现场处置',
          routePath: '/twin/digestive/0049',
          severity: 'critical',
        ),
        const TwinPendingTask(
          id: 'pt3',
          title: '牛#0012 发情高分',
          subtitle: '评分 92 · 建议6小时内配种',
          routePath: '/twin/estrus/0012',
          severity: 'warning',
        ),
      ];

  static List<TemperatureBaseline> _buildFeverBaselines() {
    final result = <TemperatureBaseline>[];
    for (var i = 1; i <= 30; i++) {
      final id = i.toString().padLeft(4, '0');
      final baseTemp = 38.0 + (i % 6) * 0.25;

      String status;
      String conclusion;
      List<AbnormalTempEvent> events;

      if (i >= 28) {
        status = 'critical';
        conclusion = '温度升高+活动量下降，高概率感染，建议隔离检查';
        events = [
          AbnormalTempEvent(
            time: DateTime.utc(2026, 4, 5, 10),
            peakDelta: 1.5,
            durationHours: 48,
          ),
        ];
      } else if (i >= 26) {
        status = 'warning';
        conclusion = '体温轻度升高，建议持续观察饮水与采食';
        events = [
          AbnormalTempEvent(
            time: DateTime.utc(2026, 4, 6, 14),
            peakDelta: 0.6,
            durationHours: 24,
          ),
        ];
      } else {
        status = 'normal';
        conclusion = '体温稳定，未见异常波动';
        events = [];
      }

      result.add(TemperatureBaseline(
        livestockId: id,
        baselineTemp: double.parse(baseTemp.toStringAsFixed(1)),
        threshold: double.parse((baseTemp + 0.5).toStringAsFixed(1)),
        recent72h: _tempGen.generate(
          livestockId: id,
          baselineTemp: baseTemp,
          start: _start,
          end: _end,
          abnormalEvents: events,
        ),
        status: status,
        conclusion: conclusion,
      ));
    }
    return result;
  }

  static List<DigestiveHealth> _buildDigestiveItems() {
    final result = <DigestiveHealth>[];
    for (var i = 1; i <= 30; i++) {
      final id = i.toString().padLeft(4, '0');
      final baseMot = 1.12 + (i % 5) * 0.07;

      String status;
      String advice;
      String healthLevel;

      if (i >= 29) {
        status = 'critical';
        advice = '蠕动完全停止，疑似瘤胃臌气，需立即处理';
        healthLevel = 'critical';
      } else if (i >= 26) {
        status = 'warning';
        advice = '蠕动频率下降，建议检查饲粮与饮水';
        healthLevel = 'warning';
      } else {
        status = 'normal';
        advice = '蠕动节律正常';
        healthLevel = 'normal';
      }

      result.add(DigestiveHealth(
        livestockId: id,
        motilityBaseline: double.parse(baseMot.toStringAsFixed(2)),
        status: status,
        advice: advice,
        recent24h: _motilityGen.generate(
          livestockId: id,
          healthLevel: healthLevel,
          start: _start,
          end: _end,
        ),
      ));
    }
    return result;
  }

  static List<EstrusScore> _buildEstrusItems() {
    final estrusCows = [
      (id: '0012', cycleDay: 17),
      (id: '0024', cycleDay: 18),
      (id: '0028', cycleDay: 19),
    ];
    final result = <EstrusScore>[];

    for (final cow in estrusCows) {
      final trend = _estrusGen.generate(
        livestockId: cow.id,
        inEstrus: true,
        cycleDay: cow.cycleDay,
        start: _start,
        end: _end,
      );
      final lastScore = trend.last;

      result.add(EstrusScore(
        livestockId: cow.id,
        score: lastScore.score.round(),
        stepIncreasePercent: 180 + (cow.id.hashCode % 200),
        tempDelta: 0.2 + (cow.id.hashCode % 3) * 0.1,
        distanceDelta: 1.5 + (cow.id.hashCode % 30) * 0.1,
        timestamp: _end.subtract(const Duration(hours: 2)),
        advice: lastScore.score > 80
            ? '步数显著增加，建议6小时内配种'
            : '发情信号增强，建议12小时内关注配种窗口',
        trend7d: trend,
      ));
    }

    return result;
  }
}
