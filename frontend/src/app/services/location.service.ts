import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, catchError, map } from 'rxjs';
import { environment } from '../../environments/environment';

// 位置日志数据接口
export interface LocationLog {
  log_id: number;
  cattle_id: number;
  latitude: number;
  longitude: number;
  log_time: string;
}

@Injectable({
  providedIn: 'root'
})
export class LocationService {
  // 使用类型断言直接解决问题
  private apiUrl: string = (environment as any).apiUrl;
  
  // 位置数据缓存
  private locationCache: Map<number, LocationLog> = new Map();
  
  constructor(private http: HttpClient) {
    console.log('LocationService 已初始化');
    // 初始化时预先加载位置数据
    this.loadLocationData();
  }

  /**
   * 加载位置数据并缓存
   */
  private loadLocationData(): void {
    console.log('加载位置数据');
    this.getAllLocations().subscribe(locations => {
      locations.forEach(location => {
        this.locationCache.set(location.cattle_id, location);
      });
      console.log('位置数据加载完成，共', this.locationCache.size, '条');
    });
  }

  /**
   * 获取所有位置记录
   */
  getAllLocations(): Observable<LocationLog[]> {
    // 由于我们处于开发阶段，暂时直接返回模拟数据
    const mockData: LocationLog[] = [
      {
        "log_id": 1,
        "cattle_id": 1,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T08:32:45"
      },
      {
        "log_id": 2,
        "cattle_id": 2,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T09:15:27"
      },
      {
        "log_id": 3,
        "cattle_id": 3,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T08:45:19"
      },
      {
        "log_id": 4,
        "cattle_id": 4,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T10:03:51"
      },
      {
        "log_id": 5,
        "cattle_id": 5,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T09:37:22"
      },
      {
        "log_id": 6,
        "cattle_id": 6,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T11:22:08"
      },
      {
        "log_id": 7,
        "cattle_id": 7,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T10:48:33"
      },
      {
        "log_id": 8,
        "cattle_id": 8,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T09:51:47"
      },
      {
        "log_id": 9,
        "cattle_id": 9,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T08:17:39"
      },
      {
        "log_id": 10,
        "cattle_id": 10,
        "latitude": 28.2458 + ((Math.random() * 0.0016) - 0.0008), // 随机范围[28.2450,28.2466]
        "longitude": 112.8519 + ((Math.random() * 0.0018) - 0.0009), // 随机范围[112.8510,112.8528]
        "log_time": "2023-09-15T11:05:14"
      }
    ];
    console.log('返回模拟位置数据，共', mockData.length, '条记录');
    return of(mockData);
    
    // 实际开发中应使用以下API调用
    /*
    return this.http.get<LocationLog[]>(`${this.apiUrl}/api/locations`)
      .pipe(
        catchError(err => {
          console.error('获取位置数据失败:', err);
          // 返回空数组而不是抛出错误
          return of([]);
        })
      );
    */
  }

  /**
   * 根据牛只ID获取最新位置
   */
  getLocationByCattleId(cattleId: number): Observable<LocationLog | undefined> {
    // 如果缓存中有数据，直接返回
    if (this.locationCache.has(cattleId)) {
      return of(this.locationCache.get(cattleId));
    }
    
    // 否则重新获取所有数据
    return this.getAllLocations().pipe(
      map(locations => {
        const location = locations.find(loc => loc.cattle_id === cattleId);
        if (location) {
          this.locationCache.set(cattleId, location);
        }
        return location;
      })
    );
  }
}