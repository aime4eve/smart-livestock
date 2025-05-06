// 传感器数据类型定义

export interface CattleSensorData {
  cattleId: string;
  timestamps: string[];
  stomachTemperatures: number[];
  peristalticCounts: number[];
}

/**
 * 生成最近1小时传感器数据
 * @param cattleId 牛的ID
 * @param baseTemp 基准体温
 * @param basePeristaltic 基准蠕动次数
 * @returns 模拟传感器数据对象
 */
export function generateSensorData(
  cattleId: string = '',
  baseTemp: number = 38.5,
  basePeristaltic: number = 4
): CattleSensorData {
  const now = new Date();
  return {
    cattleId: cattleId,
    timestamps: Array.from({ length: 60 }, (_, i) => {
      const d = new Date(now.getTime() - (60 - i) * 60000);
      return d.toISOString();
    }),
    stomachTemperatures: Array.from({ length: 60 }, (_, i) => 
      (baseTemp + Math.random() * 0.5 - 0.2).toFixed(1)
    ).map(Number),
    peristalticCounts: Array.from({ length: 60 }, (_, i) =>
      Math.floor(basePeristaltic + Math.random() * 3 - 1)
    )
  };
}