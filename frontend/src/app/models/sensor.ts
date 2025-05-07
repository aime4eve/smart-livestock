// 传感器数据类型定义
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Sensor {
  cattleId: string;
  timestamps: string[];
  stomachTemperatures: number[];
  peristalticCounts: number[];
}

// 温度日志接口
export interface TemperatureLog {
  log_id: number;
  capsule_id: string;
  temperature: number;
  log_time: string;
}

// 蠕动日志接口
export interface PeristalticLog {
  log_id: number;
  capsule_id: string;
  peristalsis_count: number;
  log_time: string;
}
