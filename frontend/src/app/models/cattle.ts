// 牛只数据接口定义

export type HealthStatus = 'healthy' | 'warning' | 'critical';

export interface Cattle {
  id: string;
  position: [number, number]; // 经纬度坐标
  healthStatus: HealthStatus;
  lastUpdate: string; // ISO日期字符串
}
