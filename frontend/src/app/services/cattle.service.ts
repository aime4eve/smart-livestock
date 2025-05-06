import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, catchError, throwError, of } from 'rxjs';
import { Cattle } from '../models/cattle';
import { Sensor, generateSensorData } from '../models/sensor';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CattleService {
  // 使用类型断言直接解决问题
  private apiUrl: string = (environment as any).apiUrl;
  
  constructor(private http: HttpClient) { }

  // 获取请求头
  private getHeaders(): HttpHeaders {
    const token = localStorage.getItem('token');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });
    
    return token ? headers.set('Authorization', `Bearer ${token}`) : headers;
  }

  // 处理API错误
  private handleError(error: any, message: string) {
    console.error('API错误', error);
    // 由于是开发测试阶段，我们使用模拟数据而不是抛出错误
    console.warn('使用模拟数据替代API数据');
    return of(null); // 返回null而不是抛出错误
  }

  /**
   * 获取所有牛只数据
   */
  getAllCattle(): Observable<Cattle[]> {
    // 由于是开发测试阶段，我们返回模拟数据
    return of([
      { id: '1', position: [28.2282, 112.9388], healthStatus: 'healthy', lastUpdate: new Date().toISOString() },
      { id: '2', position: [28.2350, 112.9450], healthStatus: 'warning', lastUpdate: new Date().toISOString() },
      { id: '3', position: [28.2180, 112.9320], healthStatus: 'critical', lastUpdate: new Date().toISOString() },
      { id: '4', position: [28.2420, 112.9280], healthStatus: 'healthy', lastUpdate: new Date().toISOString() },
      { id: '5', position: [28.2150, 112.9500], healthStatus: 'healthy', lastUpdate: new Date().toISOString() }
    ]);
    
    // 实际API调用（目前注释掉，使用模拟数据）
    /*
    return this.http.get<Cattle[]>(`${this.apiUrl}/cattle`, { headers: this.getHeaders() })
      .pipe(
        catchError(err => {
          console.error('获取牛只数据失败:', err);
          return throwError(() => new Error('无法加载牛只数据，请稍后再试'));
        })
      );
    */
  }

  /**
   * 获取单个牛只信息
   * @param id 牛只ID
   */
  getCattleById(id: string): Observable<Cattle> {
    // 使用模拟数据
    return of({ 
      id, 
      position: [28.2282, 112.9388], 
      healthStatus: 'healthy', 
      lastUpdate: new Date().toISOString() 
    });
    
    /*
    return this.http.get<Cattle>(`${this.apiUrl}/cattle/${id}`, { headers: this.getHeaders() })
      .pipe(
        catchError(err => {
          console.error('获取牛只详情失败:', err);
          return throwError(() => new Error('无法加载牛只详情，请稍后再试'));
        })
      );
    */
  }

  /**
   * 获取牛只传感器数据
   * @param id 牛只ID
   * @param period 时间周期(小时)，默认1小时
   */
  getCattleSensorData(id: string, period: number = 1): Observable<Sensor> {
    // 使用模拟数据
    return of(this.getMockSensorData(id));
    
    /*
    return this.http.get<Sensor>(`${this.apiUrl}/cattle/${id}/sensors`, { 
      headers: this.getHeaders(),
      params: { period: period.toString() }
    }).pipe(
      catchError(err => {
        console.error('获取传感器数据失败:', err);
        return throwError(() => new Error('无法加载传感器数据，请稍后再试'));
      })
    );
    */
  }

  /**
   * 模拟生成传感器数据（用于开发测试）
   */
  getMockSensorData(cattleId: string): Sensor {
    return generateSensorData(cattleId);
  }
}
