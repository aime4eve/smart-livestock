import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, catchError, throwError, of, map, forkJoin, BehaviorSubject, tap } from 'rxjs';
import { Cattle, CattleDTO, CattleQueryParams, PagedResult, HealthStatus } from '../models/cattle';
import { Sensor } from '../models/sensor';
import { environment } from '../../environments/environment';
import { LocationService } from './location.service';
import { SensorService } from './sensor.service';

// 定义胶囊安装记录类型
export interface CapsuleInstallation {
  install_id: number;
  cattle_id: number;
  capsule_id: string;
  install_time: string;
  operator: string;
}

@Injectable({
  providedIn: 'root'
})
export class CattleService {
  // 使用类型断言直接解决问题
  private apiUrl: string = (environment as any).apiUrl;
  
  // JSON文件路径 - 从assets目录加载
  private jsonDataUrl = 'assets/data/cattle.json';
  private capsuleInstallationUrl = 'assets/data/capsule_installation.json';
  
  // 保存原始地图数据的缓存，提高效率
  private cattleMapCache: Cattle[] = [];
  
  // 存储从JSON文件加载的数据
  private cattleData: CattleDTO[] = [];
  private capsuleInstallations: CapsuleInstallation[] = [];
  private dataLoaded = false;
  private capsuleDataLoaded = false;
  
  // 用于跟踪数据加载状态的Subject
  private dataLoadingSubject = new BehaviorSubject<boolean>(false);
  
  // 用于缓存已加载的数据
  private dataCache = new BehaviorSubject<CattleDTO[]>([]);
  
  // 胶囊安装记录缓存
  private capsuleInstallationCache = new BehaviorSubject<CapsuleInstallation[]>([]);
  
  constructor(
    private http: HttpClient,
    private locationService: LocationService,
    private sensorService: SensorService
  ) {
    console.log('CattleService已创建');
    // 初始化时加载数据
    this.loadCapsuleInstallationData();
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

  // 加载胶囊安装数据
  private loadCapsuleInstallationData(): void {
    if (this.capsuleDataLoaded) {
      console.log('胶囊安装数据已加载，跳过加载操作');
      return;
    }

    console.log('开始加载胶囊安装数据，URL:', this.capsuleInstallationUrl);
    
    // 添加时间戳避免缓存
    const urlWithTimestamp = `${this.capsuleInstallationUrl}?t=${new Date().getTime()}`;
    
    this.http.get<CapsuleInstallation[]>(urlWithTimestamp)
      .subscribe({
        next: (data) => {
          if (data && Array.isArray(data)) {
            this.capsuleInstallations = data;
            this.capsuleDataLoaded = true;
            console.log('胶囊安装数据加载成功，共加载', this.capsuleInstallations.length, '条记录');
            
            // 如果牛只数据已加载，更新胶囊状态
            if (this.dataLoaded && this.cattleData.length > 0) {
              this.updateCattleWithCapsuleInfo();
            }
          } else {
            console.error('返回的胶囊安装数据不是数组格式:', data);
            this.capsuleInstallations = [];
          }
        },
        error: (error) => {
          console.error('加载胶囊安装数据失败:', error);
          this.capsuleInstallations = [];
          this.capsuleDataLoaded = false;
        }
      });
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
            
            // 如果胶囊数据已加载，更新牛只的胶囊状态
            if (this.capsuleDataLoaded && this.capsuleInstallations.length > 0) {
              this.updateCattleWithCapsuleInfo();
            }
            
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
              created_at: "2023-05-10T08:30:22",
              hasCapsule: "否"
            },
            {
              cattle_id: 2,
              breed: "荷斯坦(模拟)",
              birth_date: "2020-07-22",
              weight: 578.90,
              gender: "母牛",
              created_at: "2023-05-12T14:15:36",
              hasCapsule: "否"
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

  // 更新牛只数据的胶囊信息
  private updateCattleWithCapsuleInfo(): void {
    // 创建胶囊安装Map，便于快速查找
    const capsuleMap = new Map<number, string>();
    this.capsuleInstallations.forEach(installation => {
      capsuleMap.set(installation.cattle_id, installation.capsule_id);
    });

    // 更新牛只数据中的胶囊状态
    this.cattleData.forEach(cattle => {
      const capsuleId = capsuleMap.get(cattle.cattle_id);
      cattle.hasCapsule = capsuleId ? "是" : "否";
    });

    console.log('牛只胶囊信息更新完成');
    
    // 更新缓存
    this.dataCache.next(this.cattleData);
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
    const index = this.cattleData.findIndex(c => c.cattle_id === cattle.cattle_id);
    if (index === -1) {
      return throwError(() => new Error('未找到牛只记录'));
    }
    
    // 更新本地数据
    this.cattleData[index] = { ...cattle };
    
    // 更新缓存
    this.dataCache.next([...this.cattleData]);
    
    return of(cattle);
  }

  /**
   * 保存胶囊安装记录
   */
  saveCapsuleInstallation(installation: {
    cattle_id: number;
    capsule_id: string;
    install_time: string;
    operator: string;
  }): Observable<any> {
    console.log('保存胶囊安装记录', installation);
    
    // 生成新的安装记录ID
    const newInstallId = this.capsuleInstallations.length > 0 
      ? Math.max(...this.capsuleInstallations.map(i => i.install_id)) + 1 
      : 1;
    
    const newInstallation: CapsuleInstallation = {
      install_id: newInstallId,
      cattle_id: installation.cattle_id,
      capsule_id: installation.capsule_id,
      install_time: installation.install_time,
      operator: installation.operator
    };
    
    // 添加到本地缓存
    this.capsuleInstallations.push(newInstallation);
    
    // 更新牛只胶囊状态
    const cattleIndex = this.cattleData.findIndex(c => c.cattle_id === installation.cattle_id);
    if (cattleIndex !== -1) {
      this.cattleData[cattleIndex].hasCapsule = '是';
      this.dataCache.next(this.cattleData);
    }
    
    // 模拟API调用
    return of(newInstallation);
  }
  
  // 查询牛只胶囊安装记录
  getCapsuleInstallation(cattleId: number): Observable<CapsuleInstallation | null> {
    console.log('查询牛只与胶囊的关联关系:', cattleId);
    
    // 如果已经加载了数据，直接从本地缓存查询
    if (this.capsuleDataLoaded && this.capsuleInstallations.length > 0) {
      console.log('使用本地缓存数据查询胶囊安装记录');
      // 查找该牛只的最新安装记录
      const installation = this.capsuleInstallations
        .filter(inst => inst.cattle_id === cattleId)
        .sort((a, b) => {
          // 按照安装时间倒序排序，获取最新的安装记录
          const timeA = new Date(a.install_time).getTime();
          const timeB = new Date(b.install_time).getTime();
          return timeB - timeA;
        })[0] || null;
        
      console.log('查询结果:', installation);
      return of(installation);
    }
    
    // 如果数据尚未加载，则先加载数据再查询
    console.log('数据尚未加载，先加载再查询');
    
    // 使用已有的loadCapsuleInstallationData方法刷新数据
    this.loadCapsuleInstallationData();
    
    // 等待数据加载完成再返回结果
    // 由于现有的loadCapsuleInstallationData是void返回，这里使用setTimeout模拟异步等待
    return new Observable<CapsuleInstallation | null>(observer => {
      setTimeout(() => {
        const installation = this.capsuleInstallations
          .filter(inst => inst.cattle_id === cattleId)
          .sort((a, b) => {
            const timeA = new Date(a.install_time).getTime();
            const timeB = new Date(b.install_time).getTime();
            return timeB - timeA;
          })[0] || null;
        
        observer.next(installation);
        observer.complete();
      }, 500); // 等待500ms，确保数据加载完成
    });
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
