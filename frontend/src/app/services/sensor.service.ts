import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { Sensor, TemperatureLog, PeristalticLog } from '../models/sensor';

@Injectable({
  providedIn: 'root'
})
export class SensorService {
  constructor(private http: HttpClient) {
    console.log('SensorService 已初始化');
  }

  /**
   * 生成默认的传感器数据（当无法获取真实数据时使用）
   * @param cattleId 牛只ID
   * @returns 默认的传感器数据对象
   */
  private createDefaultSensorData(cattleId: string): Sensor {
    const now = new Date();
    return {
      cattleId: cattleId,
      timestamps: Array.from({ length: 60 }, (_, i) => {
        const d = new Date(now.getTime() - (60 - i) * 60000);
        return d.toISOString();
      }),
      stomachTemperatures: Array.from({ length: 60 }, () => 
        Number((38.5 + Math.random() * 0.5 - 0.2).toFixed(1))
      ),
      peristalticCounts: Array.from({ length: 60 }, () =>
        Math.floor(4 + Math.random() * 3 - 1)
      )
    };
  }

  /**
   * 从真实的传感器日志数据获取传感器数据
   * @param cattleId 牛只ID
   * @returns 包含真实温度和蠕动数据的传感器对象
   */
  getSensorData(cattleId: string): Observable<Sensor> {
    console.log('获取真实传感器数据');
    
    // 创建一个新的Observable，手动处理数据转换
    return new Observable<Sensor>(observer => {
      // 先获取温度数据
      this.http.get<TemperatureLog[]>('/assets/data/temperature_log.json').subscribe({
        next: (tempData: TemperatureLog[]) => {
          try {
            // 如果没有温度数据，返回默认数据
            if (!tempData || tempData.length === 0) {
              console.warn('没有找到温度日志数据，使用默认数据');
              observer.next(this.createDefaultSensorData(cattleId));
              observer.complete();
              return;
            }

            // 对温度数据按时间排序
            const sortedTempData = [...tempData].sort((a, b) => 
              new Date(a.log_time).getTime() - new Date(b.log_time).getTime()
            );
            
            // 获取最近60条温度数据
            const recentTempData = sortedTempData.slice(-60);
            console.log(`找到${recentTempData.length}条温度记录`);
            
            // 获取蠕动数据
            this.http.get<PeristalticLog[]>('/assets/data/peristalsis_log.json').subscribe({
              next: (peristalticData: PeristalticLog[]) => {
                try {
                  // 如果没有蠕动数据，使用模拟蠕动数据
                  if (!peristalticData || peristalticData.length === 0) {
                    console.warn('没有找到蠕动日志数据，使用默认蠕动数据');
                    
                    // 创建传感器数据对象，温度数据使用真实数据，蠕动数据使用默认数据
                    const sensorData: Sensor = {
                      cattleId: cattleId,
                      timestamps: recentTempData.map(log => log.log_time),
                      stomachTemperatures: recentTempData.map(log => log.temperature),
                      peristalticCounts: Array.from({ length: recentTempData.length }, () => 
                        Math.floor(4 + Math.random() * 3 - 1)
                      )
                    };
                    
                    observer.next(sensorData);
                    observer.complete();
                    return;
                  }
                  
                  // 对蠕动数据按时间排序
                  const sortedPeristalticData = [...peristalticData].sort((a, b) => 
                    new Date(a.log_time).getTime() - new Date(b.log_time).getTime()
                  );
                  
                  // 获取最近60条蠕动数据
                  const recentPeristalticData = sortedPeristalticData.slice(-60);
                  console.log(`找到${recentPeristalticData.length}条蠕动记录`);
                  
                  // 使用温度数据的时间戳作为基准
                  const timestamps = recentTempData.map(log => log.log_time);
                  
                  // 将蠕动数据与时间戳对齐
                  const peristalticCounts = timestamps.map(timestamp => {
                    // 找到对应时间的蠕动记录
                    const peristalticLog = recentPeristalticData.find(log => log.log_time === timestamp);
                    // 如果找到则使用其值，否则返回0
                    return peristalticLog ? peristalticLog.peristalsis_count : 0;
                  });
                  
                  // 创建包含真实温度和蠕动数据的传感器对象
                  const sensorData: Sensor = {
                    cattleId: cattleId,
                    timestamps: timestamps,
                    stomachTemperatures: recentTempData.map(log => log.temperature),
                    peristalticCounts: peristalticCounts
                  };
                  
                  observer.next(sensorData);
                  observer.complete();
                } catch (error) {
                  console.error('处理蠕动数据失败:', error);
                  // 错误时仍使用真实温度数据，但蠕动数据使用默认数据
                  const sensorData: Sensor = {
                    cattleId: cattleId,
                    timestamps: recentTempData.map(log => log.log_time),
                    stomachTemperatures: recentTempData.map(log => log.temperature),
                    peristalticCounts: Array.from({ length: recentTempData.length }, () => 
                      Math.floor(4 + Math.random() * 3 - 1)
                    )
                  };
                  
                  observer.next(sensorData);
                  observer.complete();
                }
              },
              error: (error) => {
                console.error('获取蠕动数据失败:', error);
                // 错误时仍使用真实温度数据，但蠕动数据使用默认数据
                const sensorData: Sensor = {
                  cattleId: cattleId,
                  timestamps: recentTempData.map(log => log.log_time),
                  stomachTemperatures: recentTempData.map(log => log.temperature),
                  peristalticCounts: Array.from({ length: recentTempData.length }, () => 
                    Math.floor(4 + Math.random() * 3 - 1)
                  )
                };
                
                observer.next(sensorData);
                observer.complete();
              }
            });
          } catch (error) {
            console.error('处理温度数据失败:', error);
            // 错误时返回完全默认数据
            observer.next(this.createDefaultSensorData(cattleId));
            observer.complete();
          }
        },
        error: (error) => {
          console.error('获取温度数据失败:', error);
          // 错误时返回完全默认数据
          observer.next(this.createDefaultSensorData(cattleId));
          observer.complete();
        }
      });
    });
  }
} 