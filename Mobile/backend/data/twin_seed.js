const overview = {
  stats: {
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
  },
  sceneSummary: {
    fever: { abnormalCount: 5, criticalCount: 3 },
    digestive: { abnormalCount: 2, watchCount: 3 },
    estrus: { highScoreCount: 2, breedingAdvice: true },
    epidemic: { status: 'normal', abnormalRate: 6.0 },
  },
  pendingTasks: [
    { id: 'pt1', title: '牛#0048 体温紧急', subtitle: '较基线升高 1.2°C · 建议立即复核', routePath: '/twin/fever/0048', severity: 'critical' },
    { id: 'pt2', title: '牛#0049 蠕动停止', subtitle: '消化系统 · 需现场处置', routePath: '/twin/digestive/0049', severity: 'critical' },
    { id: 'pt3', title: '牛#0012 发情高分', subtitle: '评分 92 · 建议6小时内配种', routePath: '/twin/estrus/0012', severity: 'warning' },
  ],
};

function tempPoint(t, temp) {
  return { temperature: temp, timestamp: t };
}

function buildFeverList() {
  const result = [];
  for (let i = 1; i <= 30; i++) {
    const id = i.toString().padStart(4, '0');
    const base = 38.0 + (i % 6) * 0.25;
    let status;
    let conclusion;
    if (i >= 28) {
      status = 'critical';
      conclusion = '温度升高+活动量下降，高概率感染，建议隔离检查';
    } else if (i >= 26) {
      status = 'warning';
      conclusion = '体温轻度升高，建议持续观察饮水与采食';
    } else {
      status = 'normal';
      conclusion = '体温稳定，未见异常波动';
    }
    result.push({
      livestockId: id,
      baselineTemp: +base.toFixed(1),
      threshold: +(base + 0.5).toFixed(1),
      status,
      conclusion,
      recent72h: [
        tempPoint('2026-04-05T10:00:00Z', base),
        tempPoint('2026-04-06T10:00:00Z', status === 'critical' ? base + 1.0 : base + 0.1),
        tempPoint(
          '2026-04-07T10:00:00Z',
          status === 'critical' ? base + 1.5 : status === 'warning' ? base + 0.5 : base + 0.05,
        ),
      ],
    });
  }
  return result;
}

const feverListItems = buildFeverList();

function buildDigestiveList() {
  const result = [];
  for (let i = 1; i <= 30; i++) {
    const id = i.toString().padStart(4, '0');
    const base = 1.3 + (i % 5) * 0.05;
    let status;
    let advice;
    if (i >= 29) {
      status = 'critical';
      advice = '蠕动完全停止，疑似瘤胃臌气，需立即处理';
    } else if (i >= 26) {
      status = 'warning';
      advice = '蠕动频率下降，建议检查饲粮与饮水';
    } else {
      status = 'normal';
      advice = '蠕动节律正常';
    }
    result.push({
      livestockId: id,
      motilityBaseline: +base.toFixed(2),
      status,
      advice,
      recent24h: [
        {
          frequency: status === 'critical' ? 0 : base,
          intensity: status === 'critical' ? 0 : 0.8,
          timestamp: '2026-04-07T10:00:00Z',
        },
      ],
    });
  }
  return result;
}

const digestiveListItems = buildDigestiveList();

const estrusListItems = [
  {
    livestockId: '0012',
    score: 92,
    stepIncreasePercent: 320,
    tempDelta: 0.4,
    distanceDelta: 3.5,
    timestamp: '2026-04-07T09:58:00Z',
    advice: '步数显著增加，建议6小时内配种',
    trend7d: [
      { score: 15, timestamp: '2026-04-01T10:00:00Z' },
      { score: 50, timestamp: '2026-04-04T10:00:00Z' },
      { score: 92, timestamp: '2026-04-07T10:00:00Z' },
    ],
  },
  {
    livestockId: '0024',
    score: 78,
    stepIncreasePercent: 180,
    tempDelta: 0.2,
    distanceDelta: 2.1,
    timestamp: '2026-04-07T08:12:00Z',
    advice: '发情信号增强，建议12小时内关注配种窗口',
    trend7d: [
      { score: 20, timestamp: '2026-04-01T10:00:00Z' },
      { score: 45, timestamp: '2026-04-04T10:00:00Z' },
      { score: 78, timestamp: '2026-04-07T10:00:00Z' },
    ],
  },
  {
    livestockId: '0028',
    score: 85,
    stepIncreasePercent: 240,
    tempDelta: 0.3,
    distanceDelta: 2.8,
    timestamp: '2026-04-07T07:30:00Z',
    advice: '步数显著增加，建议6小时内配种',
    trend7d: [
      { score: 12, timestamp: '2026-04-01T10:00:00Z' },
      { score: 55, timestamp: '2026-04-04T10:00:00Z' },
      { score: 85, timestamp: '2026-04-07T10:00:00Z' },
    ],
  },
];

const epidemicSummary = {
  avgTemperature: 38.7,
  avgActivity: 72.5,
  abnormalRate: 6.0,
  totalLivestock: 50,
  abnormalCount: 3,
};

const epidemicContacts = [
  { fromId: '0048', toId: '0049', lastContact: '2026-04-07T08:30:00Z', proximity: 5.2 },
  { fromId: '0049', toId: '0050', lastContact: '2026-04-07T07:10:00Z', proximity: 8.1 },
];

module.exports = {
  overview,
  feverListItems,
  digestiveListItems,
  estrusListItems,
  epidemicSummary,
  epidemicContacts,
};
