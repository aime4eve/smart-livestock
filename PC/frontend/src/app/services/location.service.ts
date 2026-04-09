import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, catchError, map, BehaviorSubject } from 'rxjs';
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
  
  // JSON文件路径 - 从assets目录加载
  private jsonDataUrl = 'assets/data/location_log.json';
  
  // 位置数据缓存
  private locationCache: Map<number, LocationLog> = new Map();
  
  // 数据加载状态
  private dataLoaded = false;
  private dataLoadingSubject = new BehaviorSubject<boolean>(false);
  private dataCache: BehaviorSubject<LocationLog[]> = new BehaviorSubject<LocationLog[]>([]);
  
  constructor(private http: HttpClient) {
    console.log('LocationService 已初始化');
    // 初始化时预先加载位置数据
    this.loadLocationData();
  }

  /**
   * 加载位置数据并缓存
   */
  private loadLocationData(): void {
    // 如果数据已经加载或正在加载中，则跳过
    if (this.dataLoaded || this.dataLoadingSubject.value) {
      console.log('位置数据已加载或正在加载中，跳过加载操作');
      return;
    }
    
    // 标记为正在加载
    this.dataLoadingSubject.next(true);
    
    console.log('开始加载位置数据，URL:', this.jsonDataUrl);
    
    this.http.get<LocationLog[]>(this.jsonDataUrl)
      .subscribe({
        next: (data) => {
          console.log('成功获取到位置数据，返回数据类型:', typeof data);
          console.log('返回数据条数:', data?.length);
          
          if (data && Array.isArray(data)) {
            // 更新缓存Map，方便按牛只ID查找
            data.forEach(location => {
              this.locationCache.set(location.cattle_id, location);
            });
            
            // 更新数据缓存
            this.dataCache.next(data);
            this.dataLoaded = true;
            
            console.log('位置数据加载成功，共加载', data.length, '条记录');
            console.log('数据示例:', data.length > 0 ? data[0] : '无数据');
          } else {
            console.error('返回的数据不是数组格式:', data);
            this.dataCache.next([]);
          }
          
          // 标记加载完成
          this.dataLoadingSubject.next(false);
        },
        error: (error) => {
          console.error('加载位置数据失败:', error);
          this.dataLoaded = false;
          
          // 标记加载失败
          this.dataLoadingSubject.next(false);
          
          // 更新缓存为空数组
          this.dataCache.next([]);
        }
      });
  }

  /**
   * 获取所有位置记录
   */
  getAllLocations(): Observable<LocationLog[]> {
    console.log('getAllLocations 方法被调用');
    
    // 如果数据已加载，直接返回
    if (this.dataLoaded) {
      console.log('位置数据已加载，直接返回缓存数据，条数:', this.dataCache.value.length);
      return of(this.dataCache.value);
    }
    
    // 如果数据正在加载，等待加载完成
    if (this.dataLoadingSubject.value) {
      console.log('位置数据正在加载中，等待加载完成...');
      return this.dataCache.asObservable();
    }
    
    // 如果还没开始加载，加载数据
    console.log('位置数据未加载，开始加载数据...');
    this.loadLocationData();
    return this.dataCache.asObservable();
  }

  /**
   * 根据牛只ID获取最新位置
   */
  getLocationByCattleId(cattleId: number): Observable<LocationLog | undefined> {
    console.log('getLocationByCattleId 方法被调用，ID:', cattleId);
    
    // 如果缓存中有数据，直接返回
    if (this.locationCache.has(cattleId)) {
      console.log('从缓存中找到位置数据，牛只ID:', cattleId);
      return of(this.locationCache.get(cattleId));
    }
    
    // 否则确保数据已加载，再查找
    return this.getAllLocations().pipe(
      map(locations => {
        const location = locations.find(loc => loc.cattle_id === cattleId);
        if (location) {
          // 更新缓存
          this.locationCache.set(cattleId, location);
          console.log('已找到并缓存位置数据，牛只ID:', cattleId);
        } else {
          console.log('未找到位置数据，牛只ID:', cattleId);
        }
        return location;
      })
    );
  }
  
  /**
   * 重新加载位置数据
   */
  reloadData(): Observable<boolean> {
    console.log('强制重新加载位置数据...');
    this.dataLoaded = false;
    this.locationCache.clear();
    this.loadLocationData();
    
    return this.dataLoadingSubject.pipe(
      map(isLoading => !isLoading && this.dataCache.value.length > 0)
    );
  }
}