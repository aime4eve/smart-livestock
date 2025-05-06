import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, catchError, throwError, of, map, forkJoin } from 'rxjs';
import { Cattle, CattleDTO, CattleQueryParams, PagedResult, HealthStatus } from '../models/cattle';
import { Sensor, generateSensorData } from '../models/sensor';
import { environment } from '../../environments/environment';
import { LocationService } from './location.service';

@Injectable({
  providedIn: 'root'
})
export class CattleService {
  // 使用类型断言直接解决问题
  private apiUrl: string = (environment as any).apiUrl;
  
  // 保存原始地图数据的缓存，提高效率
  private cattleMapCache: Cattle[] = [];
  
  constructor(
    private http: HttpClient,
    private locationService: LocationService
  ) {
    console.log('CattleService 已初始化');
    // 初始化时预先生成一些地图数据
    this.generateMapData();
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

  /**
   * 生成地图使用的牛只数据
   * 这是为了保持地图数据的一致性
   */
  private generateMapData(): void {
    console.log('生成地图数据');
    
    // 获取牛只基本信息和位置信息
    forkJoin({
      cattle: this.getAllCattleDTO(),
      locations: this.locationService.getAllLocations()
    }).subscribe(result => {
      // 位置数据Map，方便查找
      const locationMap = new Map();
      result.locations.forEach(loc => {
        locationMap.set(loc.cattle_id, loc);
      });
      
      // 转换数据并更新缓存
      this.cattleMapCache = result.cattle.map(dto => 
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
    let lat = 28.22 + (Math.random() * 0.05);
    let lng = 112.93 + (Math.random() * 0.05);
    
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
    
    // 否则重新获取数据并生成地图数据
    return forkJoin({
      cattle: this.getAllCattleDTO(),
      locations: this.locationService.getAllLocations()
    }).pipe(
      map(result => {
        // 位置数据Map，方便查找
        const locationMap = new Map();
        result.locations.forEach(loc => {
          locationMap.set(loc.cattle_id, loc);
        });
        
        // 转换数据并更新缓存
        const mappedData = result.cattle.map(dto => 
          this.convertDTOToCattle(dto, locationMap.get(dto.cattle_id))
        );
        
        // 更新缓存
        this.cattleMapCache = [...mappedData];
        return mappedData;
      })
    );
  }
  
  /**
   * 获取所有牛只数据（DTO格式）
   */
  getAllCattleDTO(): Observable<CattleDTO[]> {
    console.log('getAllCattleDTO 方法被调用');
    // 由于我们处于开发阶段，暂时直接返回模拟数据
    const mockData: CattleDTO[] = [
      {
        cattle_id: 1,
        breed: "安格斯",
        birth_date: "2021-03-15",
        weight: 623.45,
        gender: "公牛",
        created_at: "2023-05-10T08:30:22"
      },
      {
        cattle_id: 2,
        breed: "荷斯坦",
        birth_date: "2020-07-22",
        weight: 578.90,
        gender: "母牛",
        created_at: "2023-05-12T14:15:36"
      },
      {
        cattle_id: 3,
        breed: "海福特",
        birth_date: "2022-01-05",
        weight: 432.20,
        gender: "公牛",
        created_at: "2023-05-14T10:45:18"
      },
      {
        cattle_id: 4,
        breed: "夏洛莱",
        birth_date: "2021-11-30",
        weight: 545.75,
        gender: "母牛",
        created_at: "2023-05-18T09:22:41"
      },
      {
        cattle_id: 5,
        breed: "利木赞",
        birth_date: "2020-09-18",
        weight: 612.30,
        gender: "公牛",
        created_at: "2023-06-01T11:05:37"
      },
      {
        cattle_id: 6,
        breed: "西门塔尔",
        birth_date: "2022-02-28",
        weight: 389.65,
        gender: "母牛",
        created_at: "2023-06-05T16:30:48"
      },
      {
        cattle_id: 7,
        breed: "布拉曼",
        birth_date: "2021-05-10",
        weight: 567.80,
        gender: "公牛",
        created_at: "2023-06-10T13:12:29"
      },
      {
        cattle_id: 8,
        breed: "娟姗",
        birth_date: "2020-12-03",
        weight: 498.50,
        gender: "母牛",
        created_at: "2023-06-15T10:40:15"
      },
      {
        cattle_id: 9,
        breed: "南德文",
        birth_date: "2021-08-25",
        weight: 534.25,
        gender: "公牛",
        created_at: "2023-06-20T08:55:33"
      },
      {
        cattle_id: 10,
        breed: "短角",
        birth_date: "2022-04-17",
        weight: 410.70,
        gender: "母牛",
        created_at: "2023-06-25T15:18:52"
      }
    ];
    console.log('返回模拟DTO数据，共', mockData.length, '条记录');
    return of(mockData);
    
    // 实际开发中应使用以下API调用
    /*
    return this.http.get<CattleDTO[]>(`${this.apiUrl}/api/cattle`)
      .pipe(
        catchError(err => {
          console.error('获取牛只数据失败:', err);
          return throwError(() => new Error('无法加载牛只数据，请稍后再试'));
        })
      );
    */
  }

  /**
   * 获取分页和过滤后的牛群数据
   * @param params 查询参数
   */
  getFilteredCattle(params: CattleQueryParams = {}): Observable<PagedResult<CattleDTO>> {
    console.log('getFilteredCattle 方法被调用，参数:', params);
    const page = params.page || 1;
    const pageSize = params.page_size || 7;
    
    return this.getAllCattleDTO().pipe(
      map(allCattle => {
        console.log('获取到所有牛只数据，开始过滤，总数据量:', allCattle.length);
        // 应用过滤条件
        let filteredCattle = this.filterCattle(allCattle, params);
        console.log('过滤后数据量:', filteredCattle.length);
        
        // 计算分页
        const total = filteredCattle.length;
        const totalPages = Math.ceil(total / pageSize);
        const start = (page - 1) * pageSize;
        const end = start + pageSize;
        const items = filteredCattle.slice(start, end);
        console.log(`分页信息: 第${page}页，每页${pageSize}条，当前页数据量:${items.length}`);
        
        const result = {
          items,
          total,
          page,
          page_size: pageSize,
          total_pages: totalPages
        };
        console.log('返回结果:', result);
        return result;
      })
    );
  }
  
  /**
   * 根据查询条件过滤牛群数据
   */
  private filterCattle(cattle: CattleDTO[], params: CattleQueryParams): CattleDTO[] {
    console.log('filterCattle 方法被调用，参数:', params);
    return cattle.filter(cow => {
      // 品种过滤
      if (params.breed && !cow.breed.includes(params.breed)) {
        return false;
      }
      
      // 性别过滤
      if (params.gender && cow.gender !== params.gender) {
        return false;
      }
      
      // 体重范围过滤
      if (params.weight_min && cow.weight < params.weight_min) {
        return false;
      }
      if (params.weight_max && cow.weight > params.weight_max) {
        return false;
      }
      
      // 出生日期范围过滤
      if (params.birth_date_start && new Date(cow.birth_date) < new Date(params.birth_date_start)) {
        return false;
      }
      if (params.birth_date_end && new Date(cow.birth_date) > new Date(params.birth_date_end)) {
        return false;
      }
      
      // 创建时间范围过滤
      if (params.created_at_start && new Date(cow.created_at) < new Date(params.created_at_start)) {
        return false;
      }
      if (params.created_at_end && new Date(cow.created_at) > new Date(params.created_at_end)) {
        return false;
      }
      
      return true;
    });
  }

  /**
   * 获取单个牛只信息
   * @param id 牛只ID
   */
  getCattleById(id: string): Observable<Cattle | undefined> {
    console.log('getCattleById 方法被调用，ID:', id);
    
    // 先尝试从缓存中查找
    if (this.cattleMapCache.length > 0) {
      const cachedCattle = this.cattleMapCache.find(c => c.id === id);
      if (cachedCattle) {
        console.log('从缓存中找到牛只信息');
        return of(cachedCattle);
      }
    }
    
    return this.getAllCattleDTO().pipe(
      map(cattleDTOs => {
        const foundCattleDTO = cattleDTOs.find(cow => cow.cattle_id.toString() === id);
        console.log('根据ID查找牛只DTO:', foundCattleDTO ? '找到' : '未找到');
        return foundCattleDTO ? this.convertDTOToCattle(foundCattleDTO) : undefined;
      })
    );
  }
  
  /**
   * 根据ID获取牛只DTO信息
   */
  getCattleDTOById(id: number): Observable<CattleDTO | undefined> {
    console.log('getCattleDTOById 方法被调用，ID:', id);
    return this.getAllCattleDTO().pipe(
      map(cattleDTOs => {
        const foundCattleDTO = cattleDTOs.find(cow => cow.cattle_id === id);
        console.log('根据ID查找牛只DTO:', foundCattleDTO ? '找到' : '未找到');
        return foundCattleDTO;
      })
    );
  }
  
  /**
   * 添加新牛只记录
   * @param cattle 牛只数据
   */
  addCattle(cattle: CattleDTO): Observable<CattleDTO> {
    console.log('addCattle 方法被调用，数据:', cattle);
    // 由于是前端模拟，我们只能返回输入数据
    console.log('添加牛只记录（模拟）:', cattle);
    return of(cattle);
    
    // 真实API调用（目前注释掉，使用模拟数据）
    /*
    return this.http.post<CattleDTO>(`${this.apiUrl}/api/cattle`, cattle, { headers: this.getHeaders() })
      .pipe(
        catchError(err => {
          console.error('添加牛只失败:', err);
          return throwError(() => new Error('无法添加牛只记录，请稍后再试'));
        })
      );
    */
  }
  
  /**
   * 更新牛只记录
   * @param cattle 牛只数据
   */
  updateCattle(cattle: CattleDTO): Observable<CattleDTO> {
    console.log('updateCattle 方法被调用，数据:', cattle);
    // 由于是前端模拟，我们只能返回输入数据
    console.log('更新牛只记录（模拟）:', cattle);
    return of(cattle);
    
    // 真实API调用（目前注释掉，使用模拟数据）
    /*
    return this.http.put<CattleDTO>(`${this.apiUrl}/api/cattle/${cattle.cattle_id}`, cattle, { headers: this.getHeaders() })
      .pipe(
        catchError(err => {
          console.error('更新牛只失败:', err);
          return throwError(() => new Error('无法更新牛只记录，请稍后再试'));
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
    console.log('getCattleSensorData 方法被调用，ID:', id, 'period:', period);
    // 使用模拟数据
    return of(this.getMockSensorData(id));
  }

  /**
   * 模拟生成传感器数据（用于开发测试）
   */
  getMockSensorData(cattleId: string): Sensor {
    console.log('getMockSensorData 方法被调用，ID:', cattleId);
    return generateSensorData(cattleId);
  }
}
