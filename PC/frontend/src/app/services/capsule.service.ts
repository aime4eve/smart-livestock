import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, from, BehaviorSubject } from 'rxjs';
import { map, switchMap, tap, catchError, first } from 'rxjs/operators';
import { Capsule, CapsuleQueryParams } from '../models/capsule';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CapsuleService {
  // 使用更安全的方式定义apiUrl
  private apiUrl = environment.apiUrl ? `${environment.apiUrl}/capsules` : '/api/capsules';
  
  // JSON文件路径 - 从assets目录加载
  private jsonDataUrl = 'assets/data/capsule.json';
  
  // 存储从JSON文件加载的数据
  private capsules: Capsule[] = [];
  private dataLoaded = false;
  
  // 用于跟踪数据加载状态的Subject
  private dataLoadingSubject = new BehaviorSubject<boolean>(false);
  
  // 用于缓存已加载的数据
  private dataCache: BehaviorSubject<Capsule[]> = new BehaviorSubject<Capsule[]>([]);

  constructor(private http: HttpClient) {
    // 初始化时加载数据
    console.log('CapsuleService 初始化...');
    this.loadCapsuleData();
  }

  // 从JSON文件加载数据
  private loadCapsuleData(): void {
    // 如果数据已经加载或正在加载中，则跳过
    if (this.dataLoaded || this.dataLoadingSubject.value) {
      console.log('数据已加载或正在加载中，跳过加载操作');
      return;
    }
    
    // 标记为正在加载
    this.dataLoadingSubject.next(true);
    
    // 记录完整的JSON文件URL
    const fullUrl = this.getFullUrl(this.jsonDataUrl);
    console.log('尝试加载胶囊数据，URL:', fullUrl);
    
    this.http.get<Capsule[]>(this.jsonDataUrl)
      .subscribe({
        next: (data) => {
          console.log('成功获取到胶囊数据，返回数据类型:', typeof data);
          console.log('返回数据条数:', data?.length);
          
          if (data && Array.isArray(data)) {
            this.capsules = data;
            this.dataLoaded = true;
            
            // 更新缓存
            this.dataCache.next(this.capsules);
            
            console.log('胶囊数据加载成功，共加载', this.capsules.length, '条记录');
            console.log('数据示例:', this.capsules.length > 0 ? this.capsules[0] : '无数据');
          } else {
            console.error('返回的数据不是数组格式:', data);
            this.capsules = [];
            this.dataCache.next([]);
          }
          
          // 标记加载完成
          this.dataLoadingSubject.next(false);
        },
        error: (error) => {
          console.error('加载胶囊数据失败, 详细错误:', error);
          console.error('请求URL:', fullUrl);
          this.dataLoaded = false;
          this.capsules = [];
          
          // 标记加载失败
          this.dataLoadingSubject.next(false);
          
          // 更新缓存为空数组
          this.dataCache.next([]);
        }
      });
  }

  // 获取完整URL（用于调试）
  private getFullUrl(relativeUrl: string): string {
    // 创建一个a标签来解析相对URL
    const link = document.createElement('a');
    link.href = relativeUrl;
    return link.href;
  }

  // 确保数据已加载
  private ensureDataLoaded(): Observable<Capsule[]> {
    // 如果数据已加载，直接返回数据
    if (this.dataLoaded) {
      console.log('数据已加载，直接返回缓存数据，条数:', this.capsules.length);
      return of(this.capsules);
    }
    
    // 如果数据正在加载中，等待加载完成
    if (this.dataLoadingSubject.value) {
      console.log('数据正在加载中，等待加载完成...');
      return this.dataCache.pipe(
        first(data => data.length > 0 || !this.dataLoadingSubject.value),
        tap(data => console.log('等待结束，获取到数据条数:', data.length))
      );
    }
    
    // 如果数据未加载且不在加载中，开始加载
    console.log('数据未加载，开始加载数据...');
    this.loadCapsuleData();
    
    return this.dataCache.pipe(
      first(data => data.length > 0 || !this.dataLoadingSubject.value),
      tap(data => console.log('加载结束，获取到数据条数:', data.length))
    );
  }

  // 获取胶囊列表，支持分页和查询条件
  getCapsules(queryParams: CapsuleQueryParams = {}): Observable<{data: Capsule[], total: number}> {
    console.log('getCapsules 被调用，参数:', queryParams);
    
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        console.log('ensureDataLoaded 返回的数据条数:', allCapsules.length);
        
        // 使用加载的数据进行过滤和分页
        let filteredCapsules = [...allCapsules];
        
        if (queryParams.capsule_id) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.capsule_id.includes(queryParams.capsule_id || ''));
        }
        if (queryParams.production_batch) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.production_batch.includes(queryParams.production_batch || ''));
        }
        if (queryParams.activation_date) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.activation_date.includes(queryParams.activation_date || ''));
        }
        if (queryParams.expiration_date) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.expiration_date.includes(queryParams.expiration_date || ''));
        }
        if (queryParams.status) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.status === queryParams.status);
        }
        if (queryParams.created_at) {
          filteredCapsules = filteredCapsules.filter(c => 
            c.created_at.includes(queryParams.created_at || ''));
        }
        
        const total = filteredCapsules.length;
        const page = queryParams.page || 0;
        const pageSize = queryParams.pageSize || 20;
        
        // 分页
        const startIndex = page * pageSize;
        const endIndex = startIndex + pageSize;
        const paginatedCapsules = filteredCapsules.slice(startIndex, endIndex);
        
        console.log(`查询结果: 过滤后总数=${total}, 当前页=${page}, 页大小=${pageSize}, 返回数据条数=${paginatedCapsules.length}`);
        
        return {
          data: paginatedCapsules,
          total: total
        };
      })
    );
  }

  // 获取单个胶囊信息
  getCapsule(id: string): Observable<Capsule | null> {
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        const capsule = allCapsules.find(c => c.capsule_id === id);
        return capsule || null;
      })
    );
  }

  // 创建新胶囊
  createCapsule(capsule: Capsule): Observable<Capsule> {
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        this.capsules.push(capsule);
        // 更新缓存
        this.dataCache.next(this.capsules);
        return capsule;
      })
    );
  }

  // 更新胶囊信息
  updateCapsule(capsule: Capsule): Observable<Capsule> {
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        const index = this.capsules.findIndex(c => c.capsule_id === capsule.capsule_id);
        if (index !== -1) {
          this.capsules[index] = capsule;
          // 更新缓存
          this.dataCache.next(this.capsules);
        }
        return capsule;
      })
    );
  }

  // 删除胶囊
  deleteCapsule(id: string): Observable<boolean> {
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        const index = this.capsules.findIndex(c => c.capsule_id === id);
        if (index !== -1) {
          this.capsules.splice(index, 1);
          // 更新缓存
          this.dataCache.next(this.capsules);
          return true;
        }
        return false;
      })
    );
  }

  // 获取库存状态的胶囊
  getInventoryCapsules(): Observable<Capsule[]> {
    console.log('获取库存状态的胶囊');
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        const inventoryCapsules = allCapsules.filter(c => c.status === '库存');
        console.log(`找到${inventoryCapsules.length}个库存状态的胶囊`);
        return inventoryCapsules;
      })
    );
  }

  // 根据ID获取胶囊
  getCapsuleById(id: string): Observable<Capsule | null> {
    console.log('根据ID获取胶囊:', id);
    return this.ensureDataLoaded().pipe(
      map(allCapsules => {
        const capsule = allCapsules.find(c => c.capsule_id === id);
        console.log('查询结果:', capsule || '未找到');
        return capsule || null;
      })
    );
  }

  // 重新加载数据
  reloadData(): Observable<boolean> {
    console.log('强制重新加载数据...');
    this.dataLoaded = false;
    this.loadCapsuleData();
    
    return this.dataLoadingSubject.pipe(
      first(isLoading => !isLoading),
      map(() => this.dataLoaded)
    );
  }
} 