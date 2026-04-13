const overview = {
  pastureBanner: {
    headline: '当前演示牧区',
    detail: '本分区含 50 头演示个体；下方牲畜总数等指标为集团孪生汇总口径。',
  },
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

function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hashCodeStr(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h >>> 0;
}

function reduceTemperatureToHourlyMean(points) {
  const groups = new Map();
  for (const p of points) {
    const d = new Date(p.timestamp);
    const k = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours());
    if (!groups.has(k)) groups.set(k, []);
    groups.get(k).push(p.temperature);
  }
  const keys = [...groups.keys()].sort((a, b) => a - b);
  return keys.map((k) => ({
    temperature: +(groups.get(k).reduce((s, x) => s + x, 0) / groups.get(k).length).toFixed(2),
    timestamp: new Date(k).toISOString(),
  }));
}

function buildThirtyMinuteTempSeries(livestockId, baselineTemp, status) {
  const rng = mulberry32((hashCodeStr(livestockId) + 42) >>> 0);
  const records = [];
  const start = Date.UTC(2026, 3, 1);
  const end = Date.UTC(2026, 3, 8);
  for (let t = start; t < end; t += 30 * 60 * 1000) {
    const d = new Date(t);
    const hour = d.getUTCHours();
    const circadian = hour >= 8 && hour <= 18 ? 0.2 : -0.1;
    const noise = (rng() - 0.5) * 0.2;
    let temp = baselineTemp + circadian + noise;
    if (status === 'critical') {
      const spike = (t - Date.UTC(2026, 3, 5, 10)) / (1000 * 60 * 60);
      if (spike >= 0 && spike < 48) {
        const progress = spike / 48;
        const envelope = progress < 0.3 ? progress / 0.3 : 1 - (progress - 0.3) / 0.7;
        temp += 1.5 * envelope;
      }
    } else if (status === 'warning') {
      const spike = (t - Date.UTC(2026, 3, 6, 14)) / (1000 * 60 * 60);
      if (spike >= 0 && spike < 24) {
        const progress = spike / 24;
        const envelope = progress < 0.3 ? progress / 0.3 : 1 - (progress - 0.3) / 0.7;
        temp += 0.6 * envelope;
      }
    }
    records.push({
      temperature: +temp.toFixed(2),
      timestamp: d.toISOString(),
    });
  }
  return reduceTemperatureToHourlyMean(records);
}

function reduceMotilityToHourlyMean(points) {
  const freqG = new Map();
  const intG = new Map();
  for (const p of points) {
    const d = new Date(p.timestamp);
    const k = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours());
    if (!freqG.has(k)) {
      freqG.set(k, []);
      intG.set(k, []);
    }
    freqG.get(k).push(p.frequency);
    intG.get(k).push(p.intensity);
  }
  const keys = [...freqG.keys()].sort((a, b) => a - b);
  return keys.map((k) => ({
    frequency: +(freqG.get(k).reduce((s, x) => s + x, 0) / freqG.get(k).length).toFixed(2),
    intensity: +(intG.get(k).reduce((s, x) => s + x, 0) / intG.get(k).length).toFixed(2),
    timestamp: new Date(k).toISOString(),
  }));
}

function buildThirtyMinuteMotilitySeries(livestockId, healthLevel) {
  const rng = mulberry32((hashCodeStr(`${livestockId}_${healthLevel}`) + 42) >>> 0);
  const records = [];
  const start = Date.UTC(2026, 3, 1);
  const end = Date.UTC(2026, 3, 8);
  for (let t = start; t < end; t += 30 * 60 * 1000) {
    const d = new Date(t);
    const hour = d.getUTCHours();
    let baseRpm;
    if ((hour >= 6 && hour < 10) || (hour >= 16 && hour < 20)) {
      baseRpm = 1.1 + rng() * 0.45;
    } else if (hour >= 23 || hour < 5) {
      baseRpm = 0.72 + rng() * 0.32;
    } else {
      baseRpm = 0.92 + rng() * 0.42;
    }
    let freq = baseRpm + (rng() - 0.5) * 0.14;
    if (healthLevel === 'critical') {
      freq *= 0.06 + rng() * 0.14;
      if (rng() < 0.38) {
        freq = 0;
      }
    } else if (healthLevel === 'warning') {
      freq *= 0.38 + rng() * 0.22;
    }
    freq = Math.min(2.2, Math.max(0, freq));
    const intensity = freq > 0.12 ? 0.45 + rng() * 0.45 : 0;
    records.push({
      frequency: +freq.toFixed(2),
      intensity: +intensity.toFixed(2),
      timestamp: d.toISOString(),
    });
  }
  return reduceMotilityToHourlyMean(records);
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
      recent72h: buildThirtyMinuteTempSeries(id, base, status),
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
    let healthLevel;
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
    result.push({
      livestockId: id,
      motilityBaseline: +base.toFixed(2),
      status,
      advice,
      recent24h: buildThirtyMinuteMotilitySeries(id, healthLevel),
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
