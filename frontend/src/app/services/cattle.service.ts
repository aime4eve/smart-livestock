import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, catchError, throwError, of, map, forkJoin, BehaviorSubject } from 'rxjs';
import { Cattle, CattleDTO, CattleQueryParams, PagedResult, HealthStatus } from '../models/cattle';
import { Sensor } from '../models/sensor';
import { environment } from '../../environments/environment';
import { LocationService } from './location.service';
import { SensorService } from './sensor.service';

@Injectable({
  providedIn: 'root'
})
export class CattleService {
  // 使用类型断言直接解决问题
  private apiUrl: string = (environment as any).apiUrl;
  
  // JSON文件路径 - 从assets目录加载
  private jsonDataUrl = 'assets/data/cattle.json';
  
  // 保存原始地图数据的缓存，提高效率
  private cattleMapCache: Cattle[] = [];
  
  // 存储从JSON文件加载的数据
  private cattleData: CattleDTO[] = [];
  private dataLoaded = false;
  
  // 用于跟踪数据加载状态的Subject
  private dataLoadingSubject = new BehaviorSubject<boolean>(false);
  
  // 用于缓存已加载的数据
  private dataCache: BehaviorSubject<CattleDTO[]> = new BehaviorSubject<CattleDTO[]>([]);
  
  constructor(
    private http: HttpClient,
    private locationService: LocationService,
    private sensorService: SensorService
  ) {
    console.log('CattleService 已初始化');
    // 初始化时加载数据
    this.loadCattleData();
  }

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
  
  // 从JSON文件加载数据
  private loadCattleData(): void {
    // 如果数据已经加载或正在加载中，则跳过
    if (this.dataLoaded || this.dataLoadingSubject.value) {
      console.log('牛只数据已加载或正在加载中，跳过加载操作');
      return;
    }
    
    // 标记为正在加载
    this.dataLoadingSubject.next(true);
    
    console.log('开始加载牛只数据，URL:', this.jsonDataUrl);
    
    // 确保路径正确 - 检查当前URL
    const baseHref = document.querySelector('base')?.getAttribute('href') || '/';
    console.log('应用基础路径:', baseHref);
    console.log('当前页面URL:', window.location.href);
    
    // 添加时间戳避免缓存
    const urlWithTimestamp = `${this.jsonDataUrl}?t=${new Date().getTime()}`;
    console.log('添加时间戳后的请求URL:', urlWithTimestamp);
    
    this.http.get<CattleDTO[]>(urlWithTimestamp)
      .subscribe({
        next: (data) => {
          console.log('成功获取到牛只数据，返回数据类型:', typeof data);
          console.log('返回数据条数:', data?.length);
          console.log('原始响应数据:', JSON.stringify(data).substring(0, 200) + '...');
          
          if (data && Array.isArray(data)) {
            this.cattleData = data;
            this.dataLoaded = true;
            
            // 更新缓存
            this.dataCache.next(this.cattleData);
            
            // 数据加载完成后，初始化地图数据
            this.generateMapData();
            
            console.log('牛只数据加载成功，共加载', this.cattleData.length, '条记录');
            console.log('数据示例:', this.cattleData.length > 0 ? this.cattleData[0] : '无数据');
          } else {
            console.error('返回的数据不是数组格式:', data);
            this.cattleData = [];
            this.dataCache.next([]);
          }
          
          // 标记加载完成
          this.dataLoadingSubject.next(false);
        },
        error: (error) => {
          console.error('加载牛只数据失败, 错误详情:', error);
          console.error('错误状态:', error.status);
          console.error('错误消息:', error.message);
          console.error('请求URL:', urlWithTimestamp);
          
          this.dataLoaded = false;
          this.cattleData = [];
          
          // 标记加载失败
          this.dataLoadingSubject.next(false);
          
          // 更新缓存为空数组
          this.dataCache.next([]);
          
          // 尝试使用模拟数据作为备份
          console.log('尝试使用备用模拟数据');
          const mockData: CattleDTO[] = [
            {
              cattle_id: 1,
              breed: "安格斯(模拟)",
              birth_date: "2021-03-15",
              weight: 623.55,
              gender: "公牛",
              created_at: "2023-05-10T08:30:22"
            },
            {
              cattle_id: 2,
              breed: "荷斯坦(模拟)",
              birth_date: "2020-07-22",
              weight: 578.90,
              gender: "母牛",
              created_at: "2023-05-12T14:15:36"
            }
          ];
          
          // 使用模拟数据
          this.cattleData = mockData;
          this.dataLoaded = true;
          this.dataCache.next(this.cattleData);
          console.log('已加载模拟备用数据，共', this.cattleData.length, '条');
        }
      });
  }
  
  // 确保数据已加载
  private ensureDataLoaded(): Observable<CattleDTO[]> {
    // 如果数据已加载，直接返回数据
    if (this.dataLoaded) {
      console.log('牛只数据已加载，直接返回缓存数据，条数:', this.cattleData.length);
      return of(this.cattleData);
    }
    
    // 如果数据正在加载中，等待加载完成
    if (this.dataLoadingSubject.value) {
      console.log('牛只数据正在加载中，等待加载完成...');
      return this.dataCache.pipe(
        map(data => {
          console.log('等待结束，获取到牛只数据条数:', data.length);
          return data;
        })
      );
    }
    
    // 如果数据未加载且不在加载中，开始加载
    console.log('牛只数据未加载，开始加载数据...');
    this.loadCattleData();
    
    return this.dataCache.pipe(
      map(data => {
        console.log('加载结束，获取到牛只数据条数:', data.length);
        return data;
      })
    );
  }

  /**
   * 生成地图使用的牛只数据
   * 这是为了保持地图数据的一致性
   */
  private generateMapData(): void {
    console.log('生成地图数据');
    
    // 获取位置信息
    this.locationService.getAllLocations().subscribe(locations => {
      // 位置数据Map，方便查找
      const locationMap = new Map();
      locations.forEach(loc => {
        locationMap.set(loc.cattle_id, loc);
      });
      
      // 转换数据并更新缓存
      this.cattleMapCache = this.cattleData.map(dto => 
        this.convertDTOToCattle(dto, locationMap.get(dto.cattle_id))
      );
      
      console.log('地图数据生成完成，共', this.cattleMapCache.length, '条');
    });
  }

  /**
   * 将CattleDTO转换为Cattle
   * 用于保持与原有组件的兼容性
   */
  private convertDTOToCattle(dto: CattleDTO, location?: any): Cattle {
    // 默认位置数据（如果没有位置记录，则使用随机位置）
    let lat = 28.2458 + (Math.random() * 0.05);
    let lng = 112.8519 + (Math.random() * 0.05);
    
    // 如果有真实位置数据，则使用
    if (location) {
      lat = location.latitude;
      lng = location.longitude;
    }
    
    // 确定健康状态（模拟数据）
    let healthStatus: HealthStatus = 'healthy';
    if (dto.cattle_id % 3 === 1) {
      healthStatus = 'warning';
    } else if (dto.cattle_id % 5 === 0) {
      healthStatus = 'critical';
    }
    
    return {
      id: dto.cattle_id.toString(),
      position: [lat, lng], // Leaflet使用[纬度, 经度]顺序
      healthStatus: healthStatus,
      lastUpdate: location ? location.log_time : dto.created_at
    };
  }

  /**
   * 获取所有牛只数据（原始格式）
   * 主要供地图组件使用
   */
  getAllCattle(): Observable<Cattle[]> {
    console.log('getAllCattle 方法被调用');
    
    // 如果缓存中有数据，直接返回
    if (this.cattleMapCache.length > 0) {
      console.log('返回缓存的地图数据，共', this.cattleMapCache.length, '条');
      return of([...this.cattleMapCache]);
    }
    
    // 否则确保数据加载后再生成地图数据
    return this.ensureDataLoaded().pipe(
      map(data => {
        // 如果地图数据还没生成，先生成
        if (this.cattleMapCache.length === 0) {
          this.generateMapData();
        }
        
        // 防止地图数据为空的情况
        if (this.cattleMapCache.length === 0) {
          console.log('地图数据为空，生成临时数据');
          this.cattleMapCache = data.map(dto => {
            // 生成临时的地图数据
            return {
              id: dto.cattle_id.toString(),
              position: [28.2458 + (Math.random() * 0.05), 112.8519 + (Math.random() * 0.05)],
              healthStatus: 'healthy',
              lastUpdate: dto.created_at
            };
          });
        }
        
        return [...this.cattleMapCache];
      })
    );
  }
  
  /**
   * 获取所有牛只数据（DTO格式）
   */
  getAllCattleDTO(): Observable<CattleDTO[]> {
    console.log('getAllCattleDTO 方法被调用');
    return this.ensureDataLoaded();
  }

  /**
   * 获取分页和过滤后的牛群数据
   * @param params 查询参数
   */
  getFilteredCattle(params: CattleQueryParams = {}): Observable<PagedResult<CattleDTO>> {
    console.log('getFilteredCattle 方法被调用，参数:', JSON.stringify(params));
    
    return this.ensureDataLoaded().pipe(
      map(allData => {
        console.log('获取到原始数据条数:', allData.length);
        
        // 过滤数据
        const filteredData = this.filterCattle(allData, params);
        console.log('过滤后数据条数:', filteredData.length);
        
        // 正确计算分页信息 - 确保页码从1开始
        const page = params.page || 1;  // 默认第1页，而非第0页
        const pageSize = params.page_size || 10;
        
        // 计算正确的数据切片起始和结束索引
        const start = (page - 1) * pageSize;  // 页码从1开始，所以需要减1
        const end = start + pageSize;
        
        console.log(`分页信息: 页码=${page}, 每页条数=${pageSize}, 起始索引=${start}, 结束索引=${end}`);
        
        // 确保起始索引有效
        if (start >= filteredData.length) {
          console.warn('请求的页码超出数据范围，返回空数据');
          return {
            items: [],
            total: filteredData.length,
            page: page,
            page_size: pageSize,
            total_pages: Math.max(1, Math.ceil(filteredData.length / pageSize))
          };
        }
        
        // 分页数据
        const paginatedData = filteredData.slice(start, end);
        console.log('分页后的数据条数:', paginatedData.length);
        console.log('分页数据示例:', paginatedData.length > 0 ? paginatedData[0] : '无数据');
        
        return {
          items: paginatedData,
          total: filteredData.length,
          page: page,
          page_size: pageSize,
          total_pages: Math.max(1, Math.ceil(filteredData.length / pageSize))
        };
      })
    );
  }

  /**
   * 过滤牛只数据
   * 根据查询参数过滤
   */
  private filterCattle(cattle: CattleDTO[], params: CattleQueryParams): CattleDTO[] {
    return cattle.filter(c => {
      // 品种过滤
      if (params.breed && !c.breed.includes(params.breed)) {
        return false;
      }
      
      // 性别过滤
      if (params.gender && c.gender !== params.gender) {
        return false;
      }
      
      // 体重范围过滤
      if (params.weight_min !== undefined && c.weight < params.weight_min) {
        return false;
      }
      if (params.weight_max !== undefined && c.weight > params.weight_max) {
        return false;
      }
      
      // 出生日期范围过滤
      if (params.birth_date_start && c.birth_date < params.birth_date_start) {
        return false;
      }
      if (params.birth_date_end && c.birth_date > params.birth_date_end) {
        return false;
      }
      
      // 创建日期范围过滤
      if (params.created_at_start && c.created_at < params.created_at_start) {
        return false;
      }
      if (params.created_at_end && c.created_at > params.created_at_end) {
        return false;
      }
      
      return true;
    });
  }

  /**
   * 根据ID获取牛只数据（原始格式）
   * 主要供地图组件使用
   */
  getCattleById(id: string): Observable<Cattle | undefined> {
    console.log('getCattleById 方法被调用，ID:', id);
    
    // 先从缓存中查找
    if (this.cattleMapCache.length > 0) {
      const found = this.cattleMapCache.find(c => c.id === id);
      if (found) {
        return of(found);
      }
    }
    
    // 如果缓存中没有，先获取DTO数据，再转换
    return this.getCattleDTOById(Number(id)).pipe(
      map(dto => {
        if (!dto) return undefined;
        
        // 转换为Cattle类型
        return this.convertDTOToCattle(dto);
      })
    );
  }

  /**
   * 根据ID获取牛只数据（DTO格式）
   */
  getCattleDTOById(id: number): Observable<CattleDTO | undefined> {
    console.log('getCattleDTOById 方法被调用，ID:', id);
    
    return this.ensureDataLoaded().pipe(
      map(allData => {
        return allData.find(c => c.cattle_id === id);
      })
    );
  }

  /**
   * 添加新的牛只数据
   */
  addCattle(cattle: CattleDTO): Observable<CattleDTO> {
    console.log('addCattle 方法被调用');
    
    return this.ensureDataLoaded().pipe(
      map(allData => {
        // 生成新的ID
        const maxId = Math.max(...allData.map(c => c.cattle_id), 0);
        const newCattle: CattleDTO = {
          ...cattle,
          cattle_id: maxId + 1,
          created_at: new Date().toISOString()
        };
        
        // 添加到数据集
        this.cattleData.push(newCattle);
        
        // 更新缓存
        this.dataCache.next(this.cattleData);
        
        // 重新生成地图数据
        this.generateMapData();
        
        return newCattle;
      })
    );
  }

  /**
   * 更新牛只数据
   */
  updateCattle(cattle: CattleDTO): Observable<CattleDTO> {
    console.log('updateCattle 方法被调用');
    
    return this.ensureDataLoaded().pipe(
      map(allData => {
        const index = this.cattleData.findIndex(c => c.cattle_id === cattle.cattle_id);
        
        if (index !== -1) {
          // 更新数据
          this.cattleData[index] = cattle;
          
          // 更新缓存
          this.dataCache.next(this.cattleData);
          
          // 重新生成地图数据
          this.generateMapData();
        }
        
        return cattle;
      })
    );
  }

  /**
   * 获取牛只传感器数据
   */
  getCattleSensorData(id: string, period: number = 1): Observable<Sensor> {
    console.log('获取牛只传感器数据, ID:', id);
    return this.sensorService.getSensorData(id);
  }

  /**
   * 获取模拟的传感器数据 - 已弃用，使用SensorService.getSensorData代替
   * 保留此方法是为了兼容旧代码
   */
  private getMockSensorData(cattleId: string): Sensor {
    console.warn('getMockSensorData已弃用，请使用SensorService.getSensorData');
    // 创建默认传感器数据
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
   * 重新加载数据
   */
  reloadData(): Observable<boolean> {
    console.log('强制重新加载牛只数据...');
    this.dataLoaded = false;
    this.cattleMapCache = [];
    this.loadCattleData();
    
    return this.dataLoadingSubject.pipe(
      map(isLoading => !isLoading && this.dataLoaded)
    );
  }
}
