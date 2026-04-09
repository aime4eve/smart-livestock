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
    fever: { abnormalCount: 3, criticalCount: 2 },
    digestive: { abnormalCount: 1, watchCount: 5 },
    estrus: { highScoreCount: 2, breedingAdvice: true },
    epidemic: { status: 'normal', abnormalRate: 0.9 },
  },
  pendingTasks: [
    {
      id: 'pt1',
      title: '牛#3872 体温紧急',
      subtitle: '较基线升高 1.2°C · 建议立即复核',
      routePath: '/twin/fever/3872',
      severity: 'critical',
    },
    {
      id: 'pt2',
      title: '牛#1205 蠕动停止',
      subtitle: '消化系统 · 需现场处置',
      routePath: '/twin/digestive/1205',
      severity: 'critical',
    },
    {
      id: 'pt3',
      title: '牛#2158 发情高分',
      subtitle: '评分 92 · 建议6小时内配种',
      routePath: '/twin/estrus/2158',
      severity: 'warning',
    },
  ],
};

function tempPoint(t, temp) {
  return { temperature: temp, timestamp: t };
}

const feverListItems = [
  {
    livestockId: '3872',
    baselineTemp: 38.6,
    threshold: 39.1,
    status: 'critical',
    conclusion: '温度升高+活动量下降，高概率感染，建议隔离检查',
    recent72h: [
      tempPoint('2026-04-05T10:00:00Z', 38.5),
      tempPoint('2026-04-06T10:00:00Z', 39.2),
      tempPoint('2026-04-07T10:00:00Z', 39.8),
    ],
  },
  {
    livestockId: '5621',
    baselineTemp: 38.5,
    threshold: 39.0,
    status: 'warning',
    conclusion: '体温轻度升高，建议持续观察饮水与采食',
    recent72h: [
      tempPoint('2026-04-05T10:00:00Z', 38.4),
      tempPoint('2026-04-07T10:00:00Z', 38.95),
    ],
  },
];

const digestiveListItems = [
  {
    livestockId: '1205',
    motilityBaseline: 1.5,
    status: 'critical',
    advice: '蠕动完全停止，疑似瘤胃臌气，需立即处理',
    recent24h: [
      { frequency: 1.4, intensity: 0.8, timestamp: '2026-04-06T12:00:00Z' },
      { frequency: 0, intensity: 0, timestamp: '2026-04-07T10:00:00Z' },
    ],
  },
];

const estrusListItems = [
  {
    livestockId: '2158',
    score: 92,
    stepIncreasePercent: 320,
    tempDelta: 0.4,
    distanceDelta: 3.5,
    timestamp: '2026-04-07T09:58:00Z',
    advice: '步数增加320%，建议6小时内配种',
    trend7d: [
      { score: 12, timestamp: '2026-04-01T10:00:00Z' },
      { score: 45, timestamp: '2026-04-04T10:00:00Z' },
      { score: 92, timestamp: '2026-04-07T10:00:00Z' },
    ],
  },
];

const epidemicSummary = {
  avgTemperature: 38.7,
  avgActivity: 72.5,
  abnormalRate: 0.9,
  totalLivestock: 3847,
  abnormalCount: 35,
};

const epidemicContacts = [
  {
    fromId: '3872',
    toId: '3901',
    lastContact: '2026-04-07T08:30:00Z',
    proximity: 5.2,
  },
];

module.exports = {
  overview,
  feverListItems,
  digestiveListItems,
  estrusListItems,
  epidemicSummary,
  epidemicContacts,
};
